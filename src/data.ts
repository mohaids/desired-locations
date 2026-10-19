import { getSupabase } from './supabase';
import { validatePlace } from './place-validation.mjs';
export type Place={id?:string;title:string;location:string;lat:number;lng:number;note:string;links:string;category:string;createdAt?:string};
function fromRow(row:any):Place{return {id:row.id,title:row.title,location:row.location,lat:row.lat,lng:row.lng,note:row.note,links:JSON.stringify(row.links),category:row.category,createdAt:row.created_at};}
function fail(error:{code?:string;message:string}):never{
 if(['PGRST205','42P01'].includes(error.code||''))throw new Error('Your notebook database is not set up yet. The project owner needs to complete database setup.');
 if(['PGRST301','PGRST303'].includes(error.code||''))throw new Error('Your session expired. Please sign out and sign in again.');
 throw new Error('The notebook could not be updated. Check your connection and try again.');
}
export async function listPlaces(userId:string):Promise<Place[]>{const db=await getSupabase();const {data,error}=await db.from('travel_places').select('*').eq('user_id',userId).order('created_at',{ascending:false});if(error)fail(error);return data.map(fromRow);}
export async function savePlace(draft:Place,userId:string):Promise<Place>{const values=validatePlace(draft);const db=await getSupabase();const query=draft.id?db.from('travel_places').update(values).eq('id',draft.id).eq('user_id',userId):db.from('travel_places').insert({...values,user_id:userId});const {data,error}=await query.select('*').single();if(error)fail(error);return fromRow(data);}
export async function deletePlace(id:string,userId:string):Promise<void>{const db=await getSupabase();const {error}=await db.from('travel_places').delete().eq('id',id).eq('user_id',userId).select('id').single();if(error)fail(error);}
export async function searchLocations(query:string,signal?:AbortSignal){
 const url=new URL('https://photon.komoot.io/api/');url.search=new URLSearchParams({q:query,limit:'6',lang:'en'}).toString();
 const r=await fetch(url,{signal,credentials:'omit',referrerPolicy:'no-referrer'});if(!r.ok)throw new Error('Location search is unavailable. Click the map to drop a pin instead.');
 const data=await r.json();return (data.features||[]).filter((f:any)=>Number.isFinite(f.geometry?.coordinates?.[0])&&Number.isFinite(f.geometry?.coordinates?.[1])&&Math.abs(f.geometry.coordinates[1])<=85).map((f:any)=>({title:f.properties.name||query,location:[f.properties.city,f.properties.state,f.properties.country].filter(Boolean).join(', ')||f.properties.name||query,lng:f.geometry.coordinates[0],lat:f.geometry.coordinates[1]}));
}

