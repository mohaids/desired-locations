// Public project configuration. This key is designed for browser use; RLS protects records.
export const SUPABASE_URL=import.meta.env.VITE_SUPABASE_URL||'https://pxdatyqupodiwnsrnxpn.supabase.co';
export const SUPABASE_PUBLISHABLE_KEY=import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY||'sb_publishable_hHikvWhD-frrFUN7xBOImg_TbPcylD2';
export const APP_PATH=import.meta.env.BASE_URL;
export const AUTH_REDIRECT_URL=new URL(APP_PATH,window.location.origin).href;

