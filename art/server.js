// Tiny local server for the art pages.
//   node art/server.js
// Serves the art/ folder at http://localhost:8765/ and lets a page save a
// rendered PNG into data/images/ with:  POST /save?name=<file>.png  (body = PNG bytes)
const http = require('http');
const fs = require('fs');
const path = require('path');

const ART = __dirname;
const OUT = path.join(__dirname, '..', 'data', 'images');
const TYPES = { '.html': 'text/html', '.js': 'text/javascript', '.png': 'image/png' };

http.createServer((req, res) => {
  const url = new URL(req.url, 'http://localhost');
  if (req.method === 'POST' && url.pathname === '/save') {
    const name = url.searchParams.get('name') || '';
    if (!/^[a-z0-9_]+\.png$/.test(name)) { res.writeHead(400); return res.end('bad name'); }
    const chunks = [];
    req.on('data', c => chunks.push(c));
    req.on('end', () => {
      fs.mkdirSync(OUT, { recursive: true });
      fs.writeFileSync(path.join(OUT, name), Buffer.concat(chunks));
      console.log('saved', name);
      res.writeHead(200); res.end('ok');
    });
    return;
  }
  const file = path.join(ART, path.normalize(url.pathname === '/' ? '/index.html' : url.pathname));
  if (!file.startsWith(ART) || !fs.existsSync(file)) { res.writeHead(404); return res.end('not found'); }
  res.writeHead(200, { 'Content-Type': TYPES[path.extname(file)] || 'application/octet-stream' });
  fs.createReadStream(file).pipe(res);
}).listen(8765, '127.0.0.1', () => console.log('art server on http://localhost:8765/'));
