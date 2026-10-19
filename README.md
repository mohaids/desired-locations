# Elsewhere travel atlas

A static React app for GitHub Pages, with Google sign-in and per-user storage in Supabase. The dark map interface preserves location search, dropped pins, notes, categories, up to two inspiration links, and editing/deleting saved places.

Repository: https://github.com/mohaids/desired-locations

Expected production address after successful Pages deployment: https://mohaids.github.io/desired-locations/

## Complete Supabase setup

1. Open the SQL editor for this project: https://supabase.com/dashboard/project/pxdatyqupodiwnsrnxpn/sql/new
2. Run the complete file `supabase/migrations/202610190001_travel_places.sql` once. It creates `public.travel_places`, its constraints/index, explicit grants, four owner policies, and a restrictive ownership guard. Automatic RLS alone does not grant access or create these policies. The migration does not alter an existing table or insert travel records.
3. In a new SQL editor query, run the complete `supabase/tests/rls-security.sql`. It must end with the PASS result. It uses two temporary test identities and checks actual Postgres permissions/RLS. The whole transaction rolls back its users, records and temporary policy. If an assertion fails, roll back the transaction before continuing.
4. Under Authentication → URL Configuration, set **Site URL** to `https://mohaids.github.io/desired-locations/` and add that exact URL to **Redirect URLs**. For local testing only, also add `http://127.0.0.1:5174/desired-locations/`.
5. Under Authentication → Sign In / Providers → Google, enable Google. Enter the Google OAuth client ID and client secret directly in Supabase, then save. Do not put the secret in this repository, an environment variable beginning with VITE_, or chat.
6. In Google Cloud → Google Auth Platform → Clients, create/use a **Web application** OAuth client:
   - Authorized JavaScript origin: `https://mohaids.github.io` (no repository path).
   - Authorized redirect URI: `https://pxdatyqupodiwnsrnxpn.supabase.co/auth/v1/callback`.
   - Local origin when testing: `http://127.0.0.1:5174`.
   - Configure the consent audience. While the Google app is in Testing, add the intended Google accounts as test users. Use only the normal openid, email and profile scopes.
7. Sign in using two different Google accounts after deployment. Save a place in account A, confirm account B cannot see it, and confirm a second browser/device signed into A sees it.

Google OAuth redirects first to Supabase's callback, then to the exact GitHub Pages root above. No server callback route is required on GitHub Pages. The browser client uses PKCE and initializes the returning session on that same root.

At preparation time, the Supabase authorization endpoint returned **Unsupported provider: provider is not enabled** for Google. Enabling the provider is required before sign-in can complete. The production database migration and security test have not been executed from this restricted session.

## Publish to GitHub Pages

Use the replacement repository-scoped credential already stored in Windows Credential Manager at `git:https://github.com`, username `mohaids`. Git reads that credential internally through the configured credential helper; no OAuth/device login or broader repository authorization is required. Do not print, paste, export, or put the token in a source file, command argument, or Git remote URL. Keep any previously shared token revoked.

The publishing helper disables interactive credential prompts and uses username `mohaids`. If the cached credential cannot be used, it stops instead of starting a broader sign-in flow. Run the helper in your own Windows PowerShell account, which owns the saved credential.

In the repository, open **Settings → Pages → Build and deployment → Source → GitHub Actions**. The included `.github/workflows/pages.yml` runs tests, builds the app, uploads only `dist/`, and deploys on a push to `main`.

For a newly created empty remote repository, the helper below clones the exact repository, copies only the app source, installs/builds/tests, commits and pushes. It refuses to overwrite an existing checkout or integrate a repository with commits. Choose a new checkout path outside the extracted source folder:

```powershell
powershell -File .\scripts\publish.ps1 -CheckoutPath "C:\Users\ibu\Documents\Codex\desired-locations-publish"
```

For an existing non-empty remote repository, inspect and merge this source in a normal authenticated clone instead. Preserve its history; do not force-push. Copy all root files and the `.github`, `public`, `src`, `supabase`, `scripts`, and `tests` folders. Commit and push the reviewed changes to the repository's main branch, then check the **Actions** tab for a successful Pages deployment.

The local source is prepared; no successful GitHub push or Pages deployment was verified in the restricted authoring session.

## Local development and checks

Requires Node 22.12+ (Node 24 is used in CI).

```text
npm ci
npm test
npm run build
npm run dev -- --port 5174
```

Open `http://127.0.0.1:5174/desired-locations/`. The Vite base is deliberately `/desired-locations/`; links and Google return URLs use that same base.

After applying the database migration, `npm run check:anonymous` makes a read-only request using the public key and requires anonymous table access to be denied. This is a smoke check, not a substitute for the two-user SQL security test.

The frontend validation and deployment-boundary tests, TypeScript checks, and static production build passed locally. Authenticated CRUD, Postgres RLS, cross-device persistence and GitHub Pages remain to be verified after external setup.

## Storage and privacy

Supabase stores records durably in Postgres. Each row is owned by `auth.uid()`; every policy is scoped to the signed-in authenticated role. Anonymous users have no table privileges. The client cannot update ownership, record IDs or creation timestamps. The restrictive guard also prevents a later broad permissive policy from overriding ownership.

Only the Supabase authentication session and PKCE verifier use browser auth storage. Travel records are not stored in localStorage or this repository. The supplied `sb_publishable_` key and project URL are intentionally public. There is no service-role key, database password or Google client secret in the frontend. `.env.example` contains only public configuration.

The original hosted app and database are untouched. Existing records are not copied into this repository or automatically linked to Google identities. ChatGPT user IDs and Google/Supabase user IDs differ; an authenticated export/import with explicit account mapping would be needed to transfer old records.

## External services

The official Supabase browser client is pinned to 2.118.0 and loaded from jsDelivr. Leaflet 1.9.4 is loaded from unpkg; map tiles come from OpenStreetMap. If these services are unavailable, the UI reports a loading error and provides retry guidance.

Location search calls Photon directly from the browser on explicit form submission; no private key or server proxy is used. This request sends the entered location query to Photon, without cookies or a referrer. The provider is a shared public service and may throttle or change availability. The app keeps manual map pinning available if search fails. Verify the CORS/search flow from the deployed GitHub Pages origin before relying on it. If the provider stops allowing browser requests, use a Supabase Edge Function with restricted CORS and rate limiting; never put a private geocoding key in the static app.

References: [Supabase Google setup](https://supabase.com/docs/guides/auth/social-login/auth-google), [Supabase RLS](https://supabase.com/docs/guides/database/postgres/row-level-security), [Vite Pages deployment](https://vite.dev/guide/static-deploy), [Photon API and usage](https://photon.komoot.io/).


