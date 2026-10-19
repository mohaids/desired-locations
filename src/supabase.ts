import { SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY } from './config';
export type Session={user:{id:string;email?:string;user_metadata?:{full_name?:string;name?:string}}};
export type SupabaseError={message:string;code?:string};
// The official pinned UMD client is loaded once. Database records are never cached locally.
// Only the Supabase auth session and PKCE verifier use the browser's auth storage.
export type SupabaseClient={auth:{getSession:()=>Promise<{data:{session:Session|null};error:SupabaseError|null}>;onAuthStateChange:(callback:(event:string,session:Session|null)=>void)=>{data:{subscription:{unsubscribe:()=>void}}};signInWithOAuth:(options:{provider:'google';options:{redirectTo:string}})=>Promise<{error:SupabaseError|null}>;signOut:(options:{scope:'local'})=>Promise<{error:SupabaseError|null}>};from:(table:string)=>any};
let clientPromise:Promise<SupabaseClient>|undefined;
export function getSupabase():Promise<SupabaseClient>{
 if(clientPromise)return clientPromise;
 clientPromise=new Promise((resolve,reject)=>{
 const ready=()=>{const sdk=(window as any).supabase;if(!sdk){reject(new Error('The sign-in service could not load. Please refresh.'));return;}resolve(sdk.createClient(SUPABASE_URL,SUPABASE_PUBLISHABLE_KEY,{auth:{flowType:'pkce',detectSessionInUrl:true,persistSession:true,autoRefreshToken:true,storageKey:'elsewhere-supabase-auth'}}));};
 if((window as any).supabase){ready();return;}
 const script=document.createElement('script');script.src='https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.118.0/dist/umd/supabase.js';script.crossOrigin='anonymous';script.onload=ready;script.onerror=()=>reject(new Error('The sign-in service could not load. Check your connection and refresh.'));document.head.appendChild(script);
 });return clientPromise;
}

