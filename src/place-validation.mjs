export const CATEGORIES=['culture','nature','food','stay','other'];
export function validatePlace(place){
 if(typeof place.title!=='string'||!place.title.trim()||place.title.trim().length>160)throw new Error('Enter a place name of up to 160 characters.');
 if(typeof place.location!=='string'||!place.location.trim()||place.location.length>400)throw new Error('Enter a location of up to 400 characters.');
 if(!Number.isFinite(place.lat)||Math.abs(place.lat)>85||!Number.isFinite(place.lng)||Math.abs(place.lng)>180)throw new Error('Choose a valid point on the map.');
 if(typeof place.note!=='string'||place.note.length>5000)throw new Error('Notes must be under 5,000 characters.');
 if(!CATEGORIES.includes(place.category))throw new Error('Choose a category.');
 let links;try{links=JSON.parse(place.links);}catch{throw new Error('Please check your inspiration links.');}
 if(!Array.isArray(links)||links.length>2||links.some(link=>typeof link!=='string'))throw new Error('Add at most two inspiration links.');
 links=links.map(link=>link.trim()).filter(Boolean);
 for(const link of links){try{if(link.length>2000||!(link.toLowerCase().startsWith('https://')||link.toLowerCase().startsWith('http://'))||!['https:','http:'].includes(new URL(link).protocol))throw Error();}catch{throw new Error('Use a complete http or https link.');}}
 return {title:place.title.trim(),location:place.location.trim(),lat:place.lat,lng:place.lng,note:place.note,category:place.category,links};
}


