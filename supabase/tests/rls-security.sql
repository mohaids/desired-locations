-- Run after the migration as postgres in the Supabase SQL editor.
-- Actual Postgres RLS tests: two generated identities, real table, forced API roles.
-- ALL users, rows and policy changes created below are rolled back.
begin;
create temporary table elsewhere_test_context(a uuid, b uuid, place_id uuid);
insert into elsewhere_test_context values(gen_random_uuid(),gen_random_uuid(),gen_random_uuid());
grant select on elsewhere_test_context to authenticated, anon;
insert into auth.users(id, email)
select a, a::text||'@example.invalid' from elsewhere_test_context
union all select b, b::text||'@example.invalid' from elsewhere_test_context;

do $$
begin
 if not (select relrowsecurity and relforcerowsecurity from pg_class where oid='public.travel_places'::regclass) then
   raise exception 'FAIL: RLS must be enabled and forced';
 end if;
 if has_table_privilege('anon','public.travel_places','select,insert,update,delete') then
   raise exception 'FAIL: anonymous role has table privileges';
 end if;
 if has_column_privilege('authenticated','public.travel_places','user_id','update') then
   raise exception 'FAIL: ownership is mutable';
 end if;
end $$;

set local role authenticated;
select set_config('request.jwt.claim.sub',a::text,true),
 set_config('request.jwt.claims',json_build_object('sub',a,'role','authenticated')::text,true)
from elsewhere_test_context;

-- A can create, see and edit an owned record.
insert into public.travel_places(id,user_id,title,location,lat,lng,note,links)
 select place_id,a,'RLS TEST','TEST ONLY',43.7,11.2,'temporary',
 array['https://example.com/inspiration'] from elsewhere_test_context;
do $$
declare n integer;
begin
 select count(*) into n from public.travel_places where id=(select place_id from elsewhere_test_context);
 if n<>1 then raise exception 'FAIL: owner cannot read their place'; end if;
 update public.travel_places set note='owner updated' where id=(select place_id from elsewhere_test_context);
 get diagnostics n=row_count;
 if n<>1 then raise exception 'FAIL: owner cannot update their place'; end if;
 begin
  update public.travel_places set user_id=(select b from elsewhere_test_context)
   where id=(select place_id from elsewhere_test_context);
  raise exception 'FAIL: owner changed ownership';
 exception when insufficient_privilege then null;
 end;
 begin
  insert into public.travel_places(user_id,title,location,lat,lng)
   select b,'spoof','TEST',0,0 from elsewhere_test_context;
  raise exception 'FAIL: spoofed-owner insert succeeded';
 exception when insufficient_privilege then null;
 end;
 begin
  insert into public.travel_places(title,location,lat,lng,links)
   values('bad link','TEST',0,0,array['javascript:alert(1)']);
  raise exception 'FAIL: unsafe link accepted';
 exception when check_violation then null;
 end;
 begin
  insert into public.travel_places(title,location,lat,lng,links)
   values('three links','TEST',0,0,array['https://example.com/a','https://example.com/b','https://example.com/c']);
  raise exception 'FAIL: three links accepted';
 exception when check_violation then null;
 end;
 begin
  insert into public.travel_places(title,location,lat,lng) values(' ','TEST',0,0);
  raise exception 'FAIL: blank title accepted';
 exception when check_violation then null;
 end;
 begin
  insert into public.travel_places(title,location,lat,lng) values('bad latitude','TEST',86,0);
  raise exception 'FAIL: invalid latitude accepted';
 exception when check_violation then null;
 end;
end $$;

-- B cannot read, update or delete A's record.
select set_config('request.jwt.claim.sub',b::text,true),
 set_config('request.jwt.claims',json_build_object('sub',b,'role','authenticated')::text,true)
from elsewhere_test_context;
do $$
declare n integer;
begin
 select count(*) into n from public.travel_places where id=(select place_id from elsewhere_test_context);
 if n<>0 then raise exception 'FAIL: another user read A record'; end if;
 update public.travel_places set note='intruder' where id=(select place_id from elsewhere_test_context);
 get diagnostics n=row_count;
 if n<>0 then raise exception 'FAIL: another user updated A record'; end if;
 delete from public.travel_places where id=(select place_id from elsewhere_test_context);
 get diagnostics n=row_count;
 if n<>0 then raise exception 'FAIL: another user deleted A record'; end if;
 -- B can own a separate record; this is not merely a table that blocks everyone.
 insert into public.travel_places(title,location,lat,lng) values('B owned','TEST',0,0);
 if not exists(select 1 from public.travel_places where title='B owned') then
   raise exception 'FAIL: B cannot read own record';
 end if;
end $$;

reset role;
-- Even an accidental broad permissive policy must not defeat the restrictive guard.
create policy elsewhere_test_allow_all on public.travel_places for select to authenticated using (true);
set local role authenticated;
do $$
begin
 if exists(select 1 from public.travel_places where id=(select place_id from elsewhere_test_context)) then
  raise exception 'FAIL: permissive policy bypassed ownership guard';
 end if;
end $$;

-- An unauthenticated API caller cannot read or write the table.
reset role;
set local role anon;
select set_config('request.jwt.claim.sub','',true),set_config('request.jwt.claims','{}',true);
do $$
begin
 begin perform count(*) from public.travel_places; raise exception 'FAIL: anon read succeeded';
 exception when insufficient_privilege then null; end;
 begin insert into public.travel_places(title,location,lat,lng)values('anon','TEST',0,0);
 raise exception 'FAIL: anon insert succeeded'; exception when insufficient_privilege then null; end;
 begin update public.travel_places set note='anon'; raise exception 'FAIL: anon update succeeded';
 exception when insufficient_privilege then null; end;
 begin delete from public.travel_places; raise exception 'FAIL: anon delete succeeded';
 exception when insufficient_privilege then null; end;
end $$;

-- A can delete their own record after all denial tests.
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub',a::text,true),
 set_config('request.jwt.claims',json_build_object('sub',a,'role','authenticated')::text,true)
from elsewhere_test_context;
do $$
declare n integer;
begin
 if not exists(select 1 from public.travel_places where id=(select place_id from elsewhere_test_context) and note='owner updated') then
  raise exception 'FAIL: owner record changed during denial tests';
 end if;
 delete from public.travel_places where id=(select place_id from elsewhere_test_context);
 get diagnostics n=row_count;
 if n<>1 then raise exception 'FAIL: owner cannot delete own record'; end if;
end $$;
reset role;
rollback;
select 'PASS: ownership CRUD, cross-user isolation, anonymous denial, immutable owner, data constraints, restrictive guard. Test changes rolled back.' as security_result;

