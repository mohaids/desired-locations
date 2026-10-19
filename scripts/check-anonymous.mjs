// Read-only deployment check. A publishable key must NOT return private rows.
const url=process.env.SUPABASE_URL||'https://pxdatyqupodiwnsrnxpn.supabase.co';
const key=process.env.SUPABASE_PUBLISHABLE_KEY||'sb_publishable_hHikvWhD-frrFUN7xBOImg_TbPcylD2';
try{const response=await fetch(url+'/rest/v1/travel_places?select=id&limit=1',{headers:{apikey:key},signal:AbortSignal.timeout(10000)});const data=await response.json();if(response.status===401||response.status===403){console.log('PASS: unauthenticated database access denied. This does not replace the two-user SQL test.');}else if(data.code==='PGRST205'){console.error('SETUP REQUIRED: apply the travel_places migration.');process.exitCode=2;}else{console.error('FAIL: expected access denial; HTTP '+response.status+'. Check explicit table grants and run the SQL security tests.');process.exitCode=1;}}catch{console.error('UNVERIFIED: cannot reach the Supabase project from this environment.');process.exitCode=2;}

