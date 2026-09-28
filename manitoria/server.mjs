import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=path.dirname(fileURLToPath(import.meta.url));
const mime={'.html':'text/html; charset=utf-8','.js':'text/javascript; charset=utf-8','.css':'text/css; charset=utf-8','.png':'image/png','.svg':'image/svg+xml','.json':'application/json'};
const port=Number(process.env.PORT||4177);
http.createServer((req,res)=>{let url;try{url=decodeURIComponent(new URL(req.url,'http://localhost').pathname)}catch{res.writeHead(400).end();return}const rel=url==='/'?'index.html':url.slice(1),file=path.resolve(root,rel);if(file!==root&&!file.startsWith(root+path.sep)){res.writeHead(403).end();return}fs.stat(file,(err,st)=>{if(err||!st.isFile()){res.writeHead(404).end('Not found');return}res.writeHead(200,{'Content-Type':mime[path.extname(file)]||'application/octet-stream','Cache-Control':'no-cache','X-Content-Type-Options':'nosniff'});fs.createReadStream(file).pipe(res)})}).listen(port,'127.0.0.1',()=>console.log(`Manitoria is ready at http://127.0.0.1:${port}`));
