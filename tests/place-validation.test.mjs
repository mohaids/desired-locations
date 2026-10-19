import test from 'node:test';
import assert from 'node:assert/strict';
import {validatePlace} from '../src/place-validation.mjs';
const place={title:' Florence ',location:'Tuscany, Italy',lat:43.77,lng:11.26,note:'A museum to revisit',links:JSON.stringify(['https://youtube.com/shorts/example','https://example.com']),category:'culture'};
test('preserves notes and two inspiration links',()=>{const p=validatePlace(place);assert.equal(p.title,'Florence');assert.equal(p.note,place.note);assert.equal(p.links.length,2)});
test('rejects executable, relative, protocol-relative and malformed URLs',()=>{for(const link of ['javascript:alert(1)','data:text/html,test','/path','//example.com','https://','https:///'])assert.throws(()=>validatePlace({...place,links:JSON.stringify([link])}))});
test('rejects extra links, wrong types and malformed JSON',()=>{for(const links of ['{','null','{}','[3]','["https://a.com","https://b.com","https://c.com"]'])assert.throws(()=>validatePlace({...place,links}))});
test('rejects non-finite coordinates and out-of-map points',()=>{for(const lat of [NaN,Infinity,-Infinity,85.1,-85.1])assert.throws(()=>validatePlace({...place,lat}));for(const lng of [181,-181,NaN])assert.throws(()=>validatePlace({...place,lng}))});
test('enforces title, note, location and category constraints',()=>{for(const change of [{title:' '},{title:'x'.repeat(161)},{note:'x'.repeat(5001)},{location:' '},{location:'x'.repeat(401)},{category:'anything'}])assert.throws(()=>validatePlace({...place,...change}))});
test('empty optional links are removed',()=>assert.deepEqual(validatePlace({...place,links:'["  ","https://example.com"]'}).links,['https://example.com']));

