-- Apply with the Supabase SQL editor (postgres) or Supabase migrations.
-- Schema-only: no real or example travel records are inserted.
begin;
create function public.elsewhere_valid_links(value text[])
returns boolean language sql immutable set search_path = pg_catalog
as $$
 select coalesce(array_ndims(value), 1) = 1
   and cardinality(value) <= 2
   and not exists (
     select 1 from unnest(value) as item
     where item is null or length(item) > 2000
       or item !~* '^https?://[^[:space:]]+$'
   );
$$;
revoke all on function public.elsewhere_valid_links(text[]) from public;
grant execute on function public.elsewhere_valid_links(text[]) to authenticated;

create table public.travel_places (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 title text not null check (length(btrim(title)) between 1 and 160),
 location text not null check (length(btrim(location)) between 1 and 400),
 lat double precision not null check (lat between -85 and 85),
 lng double precision not null check (lng between -180 and 180),
 note text not null default '' check (length(note) <= 5000),
 links text[] not null default '{}'::text[] check (public.elsewhere_valid_links(links)),
 category text not null default 'culture' check (category in ('culture','nature','food','stay','other')),
 created_at timestamptz not null default now()
);
create index travel_places_user_created_idx on public.travel_places(user_id, created_at desc);
alter table public.travel_places enable row level security;
alter table public.travel_places force row level security;

-- Explicit grants. Public/browser keys never receive direct table privileges.
revoke all privileges on table public.travel_places from public, anon, authenticated;
grant usage on schema public to authenticated;
grant select, insert, delete on table public.travel_places to authenticated;
-- Ownership, primary key and timestamp cannot be changed through the client.
grant update (title, location, lat, lng, note, links, category) on public.travel_places to authenticated;

create policy travel_places_select_own on public.travel_places
 for select to authenticated using ((select auth.uid()) = user_id);
create policy travel_places_insert_own on public.travel_places
 for insert to authenticated with check ((select auth.uid()) = user_id);
create policy travel_places_update_own on public.travel_places
 for update to authenticated using ((select auth.uid()) = user_id)
 with check ((select auth.uid()) = user_id);
create policy travel_places_delete_own on public.travel_places
 for delete to authenticated using ((select auth.uid()) = user_id);
-- A restrictive guard keeps ownership enforced if a permissive policy is later added.
create policy travel_places_owner_guard on public.travel_places as restrictive
 for all to authenticated using ((select auth.uid()) = user_id)
 with check ((select auth.uid()) = user_id);
commit;

