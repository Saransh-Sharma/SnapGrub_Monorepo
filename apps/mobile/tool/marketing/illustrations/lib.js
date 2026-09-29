(function () {
// Shared drawing primitives for SnapGrub food illustrations.
// Everything draws in a 1000×1000 unit space; the page scales to the canvas.
// Deterministic: all randomness flows from a seeded PRNG.

function rng(seed) {
  let a = seed >>> 0;
  const next = () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
  next.range = (lo, hi) => lo + (hi - lo) * next();
  next.pick = (arr) => arr[Math.floor(next() * arr.length)];
  next.gauss = () => (next() + next() + next() - 1.5) / 1.5;
  return next;
}

function hashSeed(text) {
  let h = 2166136261;
  for (const ch of text) h = Math.imul(h ^ ch.charCodeAt(0), 16777619);
  return h >>> 0;
}

// ---------------------------------------------------------------------------
// Colour helpers
// ---------------------------------------------------------------------------

function toRgb(hex) {
  const v = hex.replace('#', '');
  return [0, 2, 4].map((i) => parseInt(v.slice(i, i + 2), 16));
}
const toHex = (rgb) =>
  '#' + rgb.map((c) => Math.max(0, Math.min(255, Math.round(c))).toString(16).padStart(2, '0')).join('');

const mix = (a, b, t) => {
  const ra = toRgb(a), rb = toRgb(b);
  return toHex(ra.map((c, i) => c + (rb[i] - c) * t));
};
const lighten = (c, t) => mix(c, '#ffffff', t);
const darken = (c, t) => mix(c, '#1a120c', t);
const alpha = (c, a) => {
  const [r, g, b] = toRgb(c);
  return `rgba(${r},${g},${b},${a})`;
};

// Light comes from the top-left in every illustration.
const LIGHT = { x: -0.55, y: -0.7 };

// ---------------------------------------------------------------------------
// Paths
// ---------------------------------------------------------------------------

/** Irregular closed blob around (cx, cy). Returns an array of points. */
function blobPoints(r, cx, cy, rx, ry, wobble = 0.12, n = 14, rot = 0) {
  const pts = [];
  for (let i = 0; i < n; i++) {
    const a = rot + (i / n) * Math.PI * 2;
    const k = 1 + (r() - 0.5) * 2 * wobble;
    pts.push([cx + Math.cos(a) * rx * k, cy + Math.sin(a) * ry * k]);
  }
  return pts;
}

/** Smooth closed Catmull-Rom path through points. */
function smoothPath(ctx, pts) {
  const n = pts.length;
  ctx.beginPath();
  for (let i = 0; i < n; i++) {
    const p0 = pts[(i - 1 + n) % n], p1 = pts[i], p2 = pts[(i + 1) % n], p3 = pts[(i + 2) % n];
    if (i === 0) ctx.moveTo(p1[0], p1[1]);
    const c1 = [p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6];
    const c2 = [p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6];
    ctx.bezierCurveTo(c1[0], c1[1], c2[0], c2[1], p2[0], p2[1]);
  }
  ctx.closePath();
}

function roundRect(ctx, x, y, w, h, r) {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.arcTo(x + w, y, x + w, y + h, r);
  ctx.arcTo(x + w, y + h, x, y + h, r);
  ctx.arcTo(x, y + h, x, y, r);
  ctx.arcTo(x, y, x + w, y, r);
  ctx.closePath();
}

// ---------------------------------------------------------------------------
// Shading
// ---------------------------------------------------------------------------

/** Radial gradient that reads as a lit, rounded form. */
function volumeFill(ctx, cx, cy, rad, base, { hi = 0.28, lo = 0.28 } = {}) {
  const g = ctx.createRadialGradient(
    cx + LIGHT.x * rad * 0.45, cy + LIGHT.y * rad * 0.45, rad * 0.05,
    cx, cy, rad * 1.15);
  g.addColorStop(0, lighten(base, hi));
  g.addColorStop(0.55, base);
  g.addColorStop(1, darken(base, lo));
  return g;
}

function fillBlob(ctx, pts, base, opts = {}) {
  const xs = pts.map((p) => p[0]), ys = pts.map((p) => p[1]);
  const cx = (Math.min(...xs) + Math.max(...xs)) / 2;
  const cy = (Math.min(...ys) + Math.max(...ys)) / 2;
  const rad = Math.max(Math.max(...xs) - Math.min(...xs), Math.max(...ys) - Math.min(...ys)) / 2;
  smoothPath(ctx, pts);
  ctx.fillStyle = opts.flat ? base : volumeFill(ctx, cx, cy, rad, base, opts);
  ctx.fill();
  if (opts.edge) {
    ctx.strokeStyle = opts.edge;
    ctx.lineWidth = opts.edgeWidth ?? 2;
    ctx.stroke();
  }
}

/** Soft drop shadow under an object (offset away from the light). */
function contactShadow(ctx, cx, cy, rx, ry, strength = 0.28, spread = 1.12) {
  ctx.save();
  const g = ctx.createRadialGradient(cx + 18, cy + 26, 0, cx + 18, cy + 26, Math.max(rx, ry) * spread);
  g.addColorStop(0, `rgba(60,40,25,${strength})`);
  g.addColorStop(0.72, `rgba(60,40,25,${strength * 0.45})`);
  g.addColorStop(1, 'rgba(60,40,25,0)');
  ctx.fillStyle = g;
  ctx.beginPath();
  ctx.ellipse(cx + 18, cy + 26, rx * spread, ry * spread, 0, 0, Math.PI * 2);
  ctx.fill();
  ctx.restore();
}

/** Small specular sparkle on glossy things (sauce, egg yolk, fish). */
function gloss(ctx, x, y, w, h, a = 0.55, rot = -0.6) {
  ctx.save();
  ctx.translate(x, y);
  ctx.rotate(rot);
  const g = ctx.createRadialGradient(0, 0, 0, 0, 0, w);
  g.addColorStop(0, `rgba(255,255,255,${a})`);
  g.addColorStop(1, 'rgba(255,255,255,0)');
  ctx.fillStyle = g;
  ctx.beginPath();
  ctx.ellipse(0, 0, w, h, 0, 0, Math.PI * 2);
  ctx.fill();
  ctx.restore();
}

// ---------------------------------------------------------------------------
// Tableware
// ---------------------------------------------------------------------------

/** Flat plate. Returns the radius of the usable well. */
function plate(ctx, cx, cy, r, { color = '#FBF7EF', rim = 0.2 } = {}) {
  contactShadow(ctx, cx, cy, r, r, 0.3);
  // Outer rim.
  ctx.beginPath();
  ctx.arc(cx, cy, r, 0, Math.PI * 2);
  const g = ctx.createLinearGradient(cx - r, cy - r, cx + r, cy + r);
  g.addColorStop(0, lighten(color, 0.5));
  g.addColorStop(0.5, color);
  g.addColorStop(1, darken(color, 0.1));
  ctx.fillStyle = g;
  ctx.fill();
  // Well.
  const w = r * (1 - rim);
  ctx.beginPath();
  ctx.arc(cx, cy, w, 0, Math.PI * 2);
  const wg = ctx.createRadialGradient(cx + w * 0.2, cy + w * 0.25, w * 0.1, cx, cy, w);
  wg.addColorStop(0, color);
  wg.addColorStop(0.85, darken(color, 0.035));
  wg.addColorStop(1, darken(color, 0.1));
  ctx.fillStyle = wg;
  ctx.fill();
  // Rim highlight arc.
  ctx.save();
  ctx.lineCap = 'round';
  ctx.strokeStyle = 'rgba(255,255,255,0.75)';
  ctx.lineWidth = r * 0.02;
  ctx.beginPath();
  ctx.arc(cx, cy, r * (1 - rim / 2), Math.PI * 1.05, Math.PI * 1.55);
  ctx.stroke();
  ctx.restore();
  return w;
}

/** Deep bowl seen from above. Returns radius of the food surface. */
function bowl(ctx, cx, cy, r, { color = '#F5EFE4', inner = null, rim = 0.09 } = {}) {
  contactShadow(ctx, cx, cy, r, r, 0.34, 1.1);
  ctx.beginPath();
  ctx.arc(cx, cy, r, 0, Math.PI * 2);
  const g = ctx.createLinearGradient(cx - r, cy - r, cx + r, cy + r);
  g.addColorStop(0, lighten(color, 0.55));
  g.addColorStop(0.55, color);
  g.addColorStop(1, darken(color, 0.16));
  ctx.fillStyle = g;
  ctx.fill();
  const w = r * (1 - rim);
  ctx.beginPath();
  ctx.arc(cx, cy, w, 0, Math.PI * 2);
  const ig = ctx.createRadialGradient(cx + w * 0.3, cy + w * 0.35, w * 0.1, cx, cy, w);
  const inside = inner ?? darken(color, 0.06);
  ig.addColorStop(0, lighten(inside, 0.1));
  ig.addColorStop(0.8, inside);
  ig.addColorStop(1, darken(inside, 0.25));
  ctx.fillStyle = ig;
  ctx.fill();
  ctx.save();
  ctx.lineCap = 'round';
  ctx.strokeStyle = 'rgba(255,255,255,0.8)';
  ctx.lineWidth = r * 0.018;
  ctx.beginPath();
  ctx.arc(cx, cy, r * (1 - rim / 2), Math.PI * 1.08, Math.PI * 1.5);
  ctx.stroke();
  ctx.restore();
  return w * 0.96;
}

/** Inner-edge shadow on a food surface inside a bowl (sells depth). */
function bowlDepth(ctx, cx, cy, r, a = 0.28) {
  ctx.save();
  ctx.beginPath();
  ctx.arc(cx, cy, r, 0, Math.PI * 2);
  ctx.clip();
  const g = ctx.createRadialGradient(cx + r * 0.25, cy + r * 0.3, r * 0.55, cx, cy, r * 1.05);
  g.addColorStop(0, 'rgba(40,25,15,0)');
  g.addColorStop(1, `rgba(40,25,15,${a})`);
  ctx.fillStyle = g;
  ctx.fillRect(cx - r, cy - r, r * 2, r * 2);
  ctx.restore();
}

// ---------------------------------------------------------------------------
// Scatter & food micro-shapes
// ---------------------------------------------------------------------------

/** Uniform points inside a circle (optionally avoiding sub-regions). */
function scatterInCircle(r, cx, cy, radius, n, avoid = []) {
  const pts = [];
  let guard = 0;
  while (pts.length < n && guard++ < n * 30) {
    const a = r() * Math.PI * 2;
    const d = Math.sqrt(r()) * radius;
    const x = cx + Math.cos(a) * d, y = cy + Math.sin(a) * d;
    if (avoid.some((z) => Math.hypot(x - z[0], y - z[1]) < z[2])) continue;
    pts.push([x, y]);
  }
  return pts;
}

function grain(ctx, x, y, len, wid, angle, color) {
  ctx.save();
  ctx.translate(x, y);
  ctx.rotate(angle);
  const g = ctx.createLinearGradient(0, -wid, 0, wid);
  g.addColorStop(0, lighten(color, 0.35));
  g.addColorStop(1, darken(color, 0.12));
  ctx.fillStyle = g;
  ctx.beginPath();
  ctx.ellipse(0, 0, len, wid, 0, 0, Math.PI * 2);
  ctx.fill();
  ctx.restore();
}

/** A bed of rice grains filling a circle. */
function riceBed(ctx, r, cx, cy, radius, { color = '#F6F1E6', density = 1 } = {}) {
  // Base mound.
  ctx.beginPath();
  ctx.arc(cx, cy, radius, 0, Math.PI * 2);
  ctx.fillStyle = volumeFill(ctx, cx, cy, radius, darken(color, 0.04), { hi: 0.2, lo: 0.2 });
  ctx.fill();
  const n = Math.floor(radius * radius * 0.028 * density);
  for (const [x, y] of scatterInCircle(r, cx, cy, radius * 0.98, n)) {
    grain(ctx, x, y, 7.5, 3.1, r() * Math.PI, r() < 0.15 ? darken(color, 0.06) : color);
  }
}

function leaf(ctx, x, y, len, wid, angle, color, { vein = true, curl = 0.2 } = {}) {
  ctx.save();
  ctx.translate(x, y);
  ctx.rotate(angle);
  ctx.beginPath();
  ctx.moveTo(-len / 2, 0);
  ctx.bezierCurveTo(-len / 4, -wid * (1 + curl), len / 4, -wid, len / 2, 0);
  ctx.bezierCurveTo(len / 4, wid * (1 - curl), -len / 4, wid, -len / 2, 0);
  const g = ctx.createLinearGradient(0, -wid, 0, wid);
  g.addColorStop(0, lighten(color, 0.22));
  g.addColorStop(1, darken(color, 0.18));
  ctx.fillStyle = g;
  ctx.fill();
  if (vein) {
    ctx.strokeStyle = alpha(lighten(color, 0.45), 0.7);
    ctx.lineWidth = Math.max(1.2, wid * 0.08);
    ctx.beginPath();
    ctx.moveTo(-len / 2 + 2, 0);
    ctx.quadraticCurveTo(0, -wid * 0.15, len / 2 - 2, 0);
    ctx.stroke();
  }
  ctx.restore();
}

/** Rounded cube (poke, tofu, croutons, cheese). */
function cube(ctx, x, y, s, angle, color, { round = 0.22, top = 0.3 } = {}) {
  ctx.save();
  ctx.translate(x, y);
  ctx.rotate(angle);
  // Shadow side.
  roundRect(ctx, -s / 2 + s * 0.07, -s / 2 + s * 0.1, s, s, s * round);
  ctx.fillStyle = darken(color, 0.32);
  ctx.fill();
  roundRect(ctx, -s / 2, -s / 2, s, s, s * round);
  const g = ctx.createLinearGradient(-s / 2, -s / 2, s / 2, s / 2);
  g.addColorStop(0, lighten(color, top));
  g.addColorStop(1, darken(color, 0.08));
  ctx.fillStyle = g;
  ctx.fill();
  ctx.restore();
}

function dot(ctx, x, y, rad, color, shade = true) {
  ctx.beginPath();
  ctx.arc(x, y, rad, 0, Math.PI * 2);
  ctx.fillStyle = shade ? volumeFill(ctx, x, y, rad, color, { hi: 0.35, lo: 0.3 }) : color;
  ctx.fill();
}

function drizzle(ctx, r, pts, color, width) {
  ctx.save();
  ctx.lineCap = 'round';
  ctx.lineJoin = 'round';
  ctx.strokeStyle = color;
  ctx.lineWidth = width;
  ctx.beginPath();
  ctx.moveTo(pts[0][0], pts[0][1]);
  for (let i = 1; i < pts.length - 1; i++) {
    const mx = (pts[i][0] + pts[i + 1][0]) / 2, my = (pts[i][1] + pts[i + 1][1]) / 2;
    ctx.quadraticCurveTo(pts[i][0], pts[i][1], mx, my);
  }
  ctx.stroke();
  // Glossy inner line.
  ctx.strokeStyle = 'rgba(255,255,255,0.35)';
  ctx.lineWidth = width * 0.3;
  ctx.stroke();
  ctx.restore();
}

/** Zig-zag drizzle across a region (sauces, honey). */
function zigzag(r, x0, y0, x1, y1, count, amp) {
  const pts = [];
  for (let i = 0; i <= count; i++) {
    const t = i / count;
    const side = i % 2 === 0 ? -1 : 1;
    pts.push([x0 + (x1 - x0) * t + side * amp * (0.8 + r() * 0.4), y0 + (y1 - y0) * t + r.gauss() * 6]);
  }
  return pts;
}

// ---------------------------------------------------------------------------
// Surface & finishing
// ---------------------------------------------------------------------------

function table(ctx, r, surface) {
  const g = ctx.createLinearGradient(0, 0, 1000, 1000);
  g.addColorStop(0, lighten(surface, 0.12));
  g.addColorStop(1, darken(surface, 0.06));
  ctx.fillStyle = g;
  ctx.fillRect(0, 0, 1000, 1000);
  // Linen weave: faint cross-hatched threads.
  ctx.save();
  ctx.globalAlpha = 0.05;
  ctx.strokeStyle = darken(surface, 0.4);
  ctx.lineWidth = 1;
  for (let i = 0; i < 1000; i += 6) {
    ctx.beginPath();
    ctx.moveTo(i + r.gauss() * 1.5, 0);
    ctx.lineTo(i + r.gauss() * 1.5, 1000);
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(0, i + r.gauss() * 1.5);
    ctx.lineTo(1000, i + r.gauss() * 1.5);
    ctx.stroke();
  }
  ctx.restore();
  // Window light from the top-left.
  const light = ctx.createRadialGradient(180, 120, 40, 260, 220, 900);
  light.addColorStop(0, 'rgba(255,250,240,0.55)');
  light.addColorStop(1, 'rgba(255,250,240,0)');
  ctx.fillStyle = light;
  ctx.fillRect(0, 0, 1000, 1000);
}

/** Linen napkin corner peeking in (adds editorial styling). */
function napkin(ctx, r, x, y, w, h, angle, color) {
  ctx.save();
  ctx.translate(x, y);
  ctx.rotate(angle);
  contactShadow(ctx, 0, 0, w / 2, h / 2, 0.12, 1.05);
  roundRect(ctx, -w / 2, -h / 2, w, h, 8);
  const g = ctx.createLinearGradient(-w / 2, -h / 2, w / 2, h / 2);
  g.addColorStop(0, lighten(color, 0.25));
  g.addColorStop(1, darken(color, 0.06));
  ctx.fillStyle = g;
  ctx.fill();
  ctx.strokeStyle = alpha(darken(color, 0.25), 0.35);
  ctx.lineWidth = 2;
  ctx.setLineDash([5, 6]);
  roundRect(ctx, -w / 2 + 14, -h / 2 + 14, w - 28, h - 28, 4);
  ctx.stroke();
  ctx.restore();
}

/** Film grain + vignette pass over the whole illustration (pixel space). */
function finish(ctx, r, size) {
  const img = ctx.getImageData(0, 0, size, size);
  const d = img.data;
  for (let i = 0; i < d.length; i += 4) {
    const n = (r() - 0.5) * 14;
    d[i] += n;
    d[i + 1] += n;
    d[i + 2] += n;
  }
  ctx.putImageData(img, 0, 0);
  const v = ctx.createRadialGradient(size * 0.45, size * 0.42, size * 0.35, size / 2, size / 2, size * 0.78);
  v.addColorStop(0, 'rgba(40,25,10,0)');
  v.addColorStop(1, 'rgba(40,25,10,0.16)');
  ctx.fillStyle = v;
  ctx.fillRect(0, 0, size, size);
}

  window.SG = { rng, hashSeed, mix, lighten, darken, alpha, LIGHT, blobPoints, smoothPath, roundRect, volumeFill, fillBlob, contactShadow, gloss, plate, bowl, bowlDepth, scatterInCircle, grain, riceBed, leaf, cube, dot, drizzle, zigzag, table, napkin, finish };
})();
