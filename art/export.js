// Shared by the art pages: save a canvas to data/images/ through art/server.js.
// crop: trim to the visible (non-transparent) pixels; flip: mirror left-right.
export async function savePNG(src, name, { crop = true, flip = false } = {}) {
  const w = src.width, h = src.height;
  const tmp = document.createElement('canvas'); tmp.width = w; tmp.height = h;
  const g = tmp.getContext('2d'); g.drawImage(src, 0, 0);
  let x0 = 0, y0 = 0, x1 = w - 1, y1 = h - 1;
  if (crop) {
    const d = g.getImageData(0, 0, w, h).data;
    x0 = w; y0 = h; x1 = -1; y1 = -1;
    for (let y = 0; y < h; y++) for (let x = 0; x < w; x++)
      if (d[(y * w + x) * 4 + 3] > 0) {
        if (x < x0) x0 = x; if (x > x1) x1 = x;
        if (y < y0) y0 = y; if (y > y1) y1 = y;
      }
    if (x1 < 0) { x0 = 0; y0 = 0; x1 = 0; y1 = 0; }
  }
  const out = document.createElement('canvas');
  out.width = x1 - x0 + 1; out.height = y1 - y0 + 1;
  const o = out.getContext('2d');
  if (flip) { o.translate(out.width, 0); o.scale(-1, 1); }
  o.drawImage(tmp, x0, y0, out.width, out.height, 0, 0, out.width, out.height);
  const blob = await new Promise(r => out.toBlob(r, 'image/png'));
  const res = await fetch('/save?name=' + name, { method: 'POST', body: blob });
  if (!res.ok) throw new Error('save failed: ' + name);
  return [out.width, out.height];
}
