import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
const read=p=>readFileSync(new URL('../'+p,import.meta.url),'utf8');
test('Pages deployment preserves repository subpath',()=>{assert.match(read('vite.config.ts'),/base:\s*'\/desired-locations\/'/);assert.match(read('src/config.ts'),/new URL\(APP_PATH,window.location.origin\)/);assert.match(read('src/Notebook.tsx'),/href=\{APP_PATH\}/)});
test('replacement has no old server endpoints or ChatGPT auth routes',()=>{for(const p of ['src/Notebook.tsx','src/App.tsx','src/data.ts'])assert.doesNotMatch(read(p),/\/api\/places|\/api\/search|signin-with-chatgpt|signout-with-chatgpt|cloudflare:workers/)});
test('no privileged key is configured',()=>{assert.doesNotMatch(read('src/config.ts'),/sb_secret_|eyJ/);assert.match(read('src/config.ts'),/sb_publishable_/)});

