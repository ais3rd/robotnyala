// Shared by the art pages: render a robot as a flat 2D sprite sheet and save it
// to data/images/ through art/server.js.
import * as THREE from 'three';

export async function savePNG(canvas, name) {
  const blob = await new Promise(r => canvas.toBlob(r, 'image/png'));
  const res = await fetch('/save?name=' + name, { method: 'POST', body: blob });
  if (!res.ok) throw new Error('save failed: ' + name);
  return [canvas.width, canvas.height];
}

const hex = s => [1, 3, 5].map(i => parseInt(s.slice(i, i + 2), 16));

// The game's two cameras see the robots from different heights, so each robot gets two sheets:
// <name>.png from 3 deg below (crouched operator camera) and <name>_high.png from 12 deg above (3/4 camera).
export async function exportViews(opts) {
  return [await exportSheet({ ...opts, pitch: -3 }),
          await exportSheet({ ...opts, pitch: 12, name: opts.name.replace('.png', '_high.png') })];
}

// Sheet: rows = 8 view directions (0 = front, 2 = robot's left, 4 = back, 6 = robot's right),
// columns = frames. Orthographic, looking `pitch` degrees down (negative = up: -3 matches the
// game's crouched operator camera), one crop box for every cell
// (so the feet stay put), colours snapped to `palette`, 1-pixel dark outline.
// pose(i) puts the robot in frame i (from its rest pose); the robot faces +Z at rotation 0.
export async function exportSheet({ renderer, scene, root, frameCount, pose, palette, name,
                                    FW = 200, FH = 270, span = 5.3, pitch = -3, outline = [10, 12, 15] }) {
  renderer.setSize(FW, FH, false);
  const aspect = FW / FH, lookY = span / 2 - 0.25, p = THREE.MathUtils.degToRad(pitch);
  const cam = new THREE.OrthographicCamera(-span * aspect / 2, span * aspect / 2, span / 2, -span / 2, 0.1, 100);
  cam.position.set(0, lookY + Math.sin(p) * 20, Math.cos(p) * 20);
  cam.lookAt(0, lookY, 0);
  const pal = palette.map(hex);

  const cells = [];
  for (let dir = 0; dir < 8; dir++) for (let f = 0; f < frameCount; f++) {
    pose(f);
    root.rotation.y = -dir * Math.PI / 4;          // turns the robot's left (+X) toward the camera at dir 2
    root.position.y = 0; root.updateMatrixWorld(true);
    root.position.y = -new THREE.Box3().setFromObject(root).min.y;
    renderer.render(scene, cam);
    const c = document.createElement('canvas'); c.width = FW; c.height = FH;
    c.getContext('2d').drawImage(renderer.domElement, 0, 0);
    cells.push(c);
  }

  let x0 = FW, y0 = FH, x1 = -1, y1 = -1;
  for (const c of cells) {
    const d = c.getContext('2d').getImageData(0, 0, FW, FH).data;
    for (let y = 0; y < FH; y++) for (let x = 0; x < FW; x++) if (d[(y * FW + x) * 4 + 3] >= 128) {
      if (x < x0) x0 = x; if (x > x1) x1 = x; if (y < y0) y0 = y; if (y > y1) y1 = y;
    }
  }
  x0 -= 1; y0 -= 1; x1 += 1;                        // room for the outline (not below the feet)
  const bw = x1 - x0 + 1, bh = y1 - y0 + 1;
  const sheet = document.createElement('canvas');
  sheet.width = bw * frameCount; sheet.height = bh * 8;
  const g = sheet.getContext('2d');
  cells.forEach((c, i) => g.drawImage(c, x0, y0, bw, bh, (i % frameCount) * bw, Math.floor(i / frameCount) * bh, bw, bh));

  // palette snap + hard alpha, then outline (never across cell borders)
  const w = sheet.width, h = sheet.height, img = g.getImageData(0, 0, w, h), d = img.data;
  const solid = new Uint8Array(w * h);
  for (let i = 0; i < w * h; i++) {
    if (d[i * 4 + 3] < 128) { d[i * 4 + 3] = 0; continue; }
    solid[i] = 1;
    let best = pal[0], bd = 1e9;
    for (const q of pal) {
      const dr = d[i * 4] - q[0], dg = d[i * 4 + 1] - q[1], db = d[i * 4 + 2] - q[2];
      const dist = dr * dr * 0.3 + dg * dg * 0.59 + db * db * 0.11;
      if (dist < bd) { bd = dist; best = q; }
    }
    d[i * 4] = best[0]; d[i * 4 + 1] = best[1]; d[i * 4 + 2] = best[2]; d[i * 4 + 3] = 255;
  }
  const cell = (x, y) => Math.floor(x / bw) + Math.floor(y / bh) * frameCount;
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
    const i = y * w + x; if (solid[i]) continue;
    const near = (xx, yy) => xx >= 0 && yy >= 0 && xx < w && yy < h && cell(xx, yy) === cell(x, y) && solid[yy * w + xx];
    if (near(x - 1, y) || near(x + 1, y) || near(x, y - 1) || near(x, y + 1)) {
      d[i * 4] = outline[0]; d[i * 4 + 1] = outline[1]; d[i * 4 + 2] = outline[2]; d[i * 4 + 3] = 255;
    }
  }
  g.putImageData(img, 0, 0);
  await savePNG(sheet, name);
  return { sheet, cellW: bw, cellH: bh, width: w, height: h };
}
