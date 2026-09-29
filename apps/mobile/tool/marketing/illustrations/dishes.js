// SnapGrub food illustrations — one draw function per dish, 1000×1000 units.
(function () {
  const {
    lighten, darken, alpha, mix, blobPoints, smoothPath, fillBlob, roundRect,
    contactShadow, gloss, plate, bowl, bowlDepth, scatterInCircle, grain,
    riceBed, leaf, cube, dot, drizzle, zigzag, volumeFill, napkin,
  } = window.SG;

  const TAU = Math.PI * 2;
  const C = {
    porcelain: '#EFE6D8', linen: '#E7DDCD', sage: '#D6E0D2', blush: '#F0DCCF',
    slate: '#D5DBE2', stone: '#E2D8C9', butter: '#F2E6C8',
    salmon: '#F08A5D', avocado: '#9DBE52', avocadoSkin: '#3E5A22',
    blueberry: '#3B4677', raspberry: '#D6445C', strawberry: '#D93A3F',
    greens: '#6E9E3C', darkGreens: '#3F6B2A', rice: '#F7F2E7', nori: '#1F2A22',
    yolk: '#F3A92C', white: '#FBF8F2', chili: '#C8321F', basil: '#3E7A2E',
    honey: '#E3A03A', cream: '#F4EEE3',
  };

  // Helpers --------------------------------------------------------------

  function blueberries(ctx, r, pts, rad = 14) {
    for (const [x, y] of pts) {
      dot(ctx, x, y, rad * r.range(0.85, 1.12), C.blueberry);
      // Crown.
      ctx.fillStyle = alpha('#1B2140', 0.8);
      ctx.beginPath();
      ctx.arc(x + rad * 0.15, y + rad * 0.1, rad * 0.22, 0, TAU);
      ctx.fill();
      ctx.fillStyle = 'rgba(200,210,255,0.28)';
      ctx.beginPath();
      ctx.arc(x - rad * 0.35, y - rad * 0.4, rad * 0.35, 0, TAU);
      ctx.fill();
    }
  }

  function raspberry(ctx, r, x, y, rad) {
    contactShadow(ctx, x, y, rad, rad, 0.2, 1.1);
    for (let i = 0; i < 16; i++) {
      const a = r() * TAU, d = Math.sqrt(r()) * rad * 0.72;
      dot(ctx, x + Math.cos(a) * d, y + Math.sin(a) * d, rad * 0.32, C.raspberry);
    }
    dot(ctx, x, y, rad * 0.18, darken(C.raspberry, 0.3), false);
  }

  function strawberryHalf(ctx, r, x, y, s, angle) {
    ctx.save();
    ctx.translate(x, y);
    ctx.rotate(angle);
    contactShadow(ctx, 0, 0, s * 0.55, s * 0.6, 0.18);
    ctx.beginPath();
    ctx.moveTo(0, -s * 0.62);
    ctx.bezierCurveTo(s * 0.62, -s * 0.62, s * 0.55, s * 0.2, 0, s * 0.62);
    ctx.bezierCurveTo(-s * 0.55, s * 0.2, -s * 0.62, -s * 0.62, 0, -s * 0.62);
    ctx.fillStyle = volumeFill(ctx, 0, 0, s * 0.62, C.strawberry, { hi: 0.2, lo: 0.25 });
    ctx.fill();
    // Cut face: pale core.
    ctx.beginPath();
    ctx.moveTo(0, -s * 0.45);
    ctx.bezierCurveTo(s * 0.35, -s * 0.4, s * 0.3, s * 0.15, 0, s * 0.42);
    ctx.bezierCurveTo(-s * 0.3, s * 0.15, -s * 0.35, -s * 0.4, 0, -s * 0.45);
    ctx.fillStyle = '#F7B4A8';
    ctx.fill();
    ctx.strokeStyle = 'rgba(255,245,240,0.8)';
    ctx.lineWidth = s * 0.05;
    ctx.beginPath();
    ctx.moveTo(0, -s * 0.38);
    ctx.lineTo(0, s * 0.28);
    ctx.stroke();
    ctx.fillStyle = '#4F8B3A';
    for (let i = 0; i < 5; i++) {
      leaf(ctx, (i - 2) * s * 0.1, -s * 0.66, s * 0.3, s * 0.08, -Math.PI / 2 + (i - 2) * 0.45, '#4F8B3A', { vein: false });
    }
    ctx.restore();
  }

  function sesame(ctx, r, cx, cy, radius, n, colors = ['#F5EBD2', '#2B2520']) {
    for (const [x, y] of scatterInCircle(r, cx, cy, radius, n)) {
      grain(ctx, x, y, 4.5, 2.4, r() * Math.PI, r.pick(colors));
    }
  }

  function specks(ctx, r, cx, cy, radius, n, color, size = 2.2) {
    ctx.fillStyle = color;
    for (const [x, y] of scatterInCircle(r, cx, cy, radius, n)) {
      ctx.beginPath();
      ctx.arc(x, y, size * r.range(0.6, 1.3), 0, TAU);
      ctx.fill();
    }
  }

  function avocadoSlice(ctx, x, y, len, wid, angle) {
    ctx.save();
    ctx.translate(x, y);
    ctx.rotate(angle);
    ctx.beginPath();
    ctx.moveTo(-len / 2, 0);
    ctx.bezierCurveTo(-len / 3, -wid * 1.25, len / 3, -wid * 1.25, len / 2, 0);
    ctx.bezierCurveTo(len / 3, -wid * 0.35, -len / 3, -wid * 0.35, -len / 2, 0);
    const g = ctx.createLinearGradient(0, -wid * 1.1, 0, 0);
    g.addColorStop(0, C.avocadoSkin);
    g.addColorStop(0.18, '#7FA238');
    g.addColorStop(0.5, C.avocado);
    g.addColorStop(1, '#E1E48C');
    ctx.fillStyle = g;
    ctx.fill();
    ctx.restore();
  }

  function avocadoFan(ctx, r, x, y, n, len, wid, angle, spread = 0.12) {
    for (let i = 0; i < n; i++) {
      avocadoSlice(ctx, x + Math.cos(angle + Math.PI / 2) * i * wid * 0.55,
        y + Math.sin(angle + Math.PI / 2) * i * wid * 0.55, len, wid, angle + (i - n / 2) * spread * 0.2);
    }
  }

  function friedEgg(ctx, r, x, y, s) {
    contactShadow(ctx, x, y, s, s * 0.9, 0.16);
    fillBlob(ctx, blobPoints(r, x, y, s, s * 0.88, 0.14, 12), C.white, { hi: 0.05, lo: 0.08 });
    const yx = x + s * 0.08, yy = y - s * 0.06;
    ctx.beginPath();
    ctx.arc(yx, yy, s * 0.36, 0, TAU);
    ctx.fillStyle = volumeFill(ctx, yx, yy, s * 0.36, C.yolk, { hi: 0.25, lo: 0.2 });
    ctx.fill();
    gloss(ctx, yx - s * 0.12, yy - s * 0.12, s * 0.12, s * 0.07, 0.7);
  }

  function softEggHalf(ctx, r, x, y, s, angle) {
    ctx.save();
    ctx.translate(x, y);
    ctx.rotate(angle);
    contactShadow(ctx, 0, 0, s * 0.62, s * 0.5, 0.16);
    ctx.beginPath();
    ctx.ellipse(0, 0, s * 0.62, s * 0.48, 0, 0, TAU);
    ctx.fillStyle = volumeFill(ctx, 0, 0, s * 0.6, '#FBF5EA', { hi: 0.1, lo: 0.12 });
    ctx.fill();
    ctx.beginPath();
    ctx.ellipse(s * 0.04, 0, s * 0.33, s * 0.27, 0, 0, TAU);
    ctx.fillStyle = volumeFill(ctx, 0, 0, s * 0.33, '#F29A27', { hi: 0.25, lo: 0.1 });
    ctx.fill();
    gloss(ctx, -s * 0.08, -s * 0.08, s * 0.12, s * 0.06, 0.8);
    ctx.restore();
  }

  function mintSprig(ctx, r, x, y, s, angle) {
    for (let i = 0; i < 3; i++) {
      leaf(ctx, x + Math.cos(angle + i * 2.1) * s * 0.35, y + Math.sin(angle + i * 2.1) * s * 0.35,
        s, s * 0.34, angle + i * 2.1, '#5E9E47');
    }
  }

  function lemonWedge(ctx, x, y, s, angle, color = '#F2D03B') {
    ctx.save();
    ctx.translate(x, y);
    ctx.rotate(angle);
    contactShadow(ctx, 0, 0, s * 0.6, s * 0.35, 0.16);
    ctx.beginPath();
    ctx.moveTo(-s * 0.6, 0);
    ctx.quadraticCurveTo(0, -s * 0.72, s * 0.6, 0);
    ctx.closePath();
    ctx.fillStyle = darken(color, 0.1);
    ctx.fill();
    ctx.beginPath();
    ctx.moveTo(-s * 0.52, -s * 0.02);
    ctx.quadraticCurveTo(0, -s * 0.6, s * 0.52, -s * 0.02);
    ctx.closePath();
    ctx.fillStyle = lighten(color, 0.3);
    ctx.fill();
    ctx.strokeStyle = 'rgba(255,255,255,0.7)';
    ctx.lineWidth = 2;
    for (let i = 1; i < 4; i++) {
      ctx.beginPath();
      ctx.moveTo(0, -s * 0.02);
      const a = Math.PI + (i / 4) * Math.PI;
      ctx.lineTo(Math.cos(a) * s * 0.5, Math.sin(a) * s * 0.45);
      ctx.stroke();
    }
    ctx.restore();
  }

  function broccoli(ctx, r, x, y, s) {
    contactShadow(ctx, x, y, s, s, 0.18);
    ctx.save();
    ctx.strokeStyle = '#9CBF63';
    ctx.lineWidth = s * 0.35;
    ctx.lineCap = 'round';
    ctx.beginPath();
    ctx.moveTo(x, y);
    ctx.lineTo(x + s * 0.6, y + s * 0.8);
    ctx.stroke();
    ctx.restore();
    for (let i = 0; i < 22; i++) {
      const a = r() * TAU, d = Math.sqrt(r()) * s * 0.75;
      dot(ctx, x + Math.cos(a) * d, y + Math.sin(a) * d, s * r.range(0.2, 0.32), mix(C.darkGreens, '#5C8C34', r()));
    }
    specks(ctx, r, x, y, s * 0.8, 30, alpha('#A7C96A', 0.6), 2.4);
  }

  function chopsticks(ctx, x, y, len, angle, color = '#C99A61') {
    ctx.save();
    ctx.translate(x, y);
    ctx.rotate(angle);
    for (const dy of [-12, 12]) {
      ctx.save();
      ctx.translate(0, dy);
      ctx.rotate(dy * 0.004);
      contactShadow(ctx, 0, 0, len / 2, 8, 0.15, 1.02);
      const g = ctx.createLinearGradient(0, -7, 0, 7);
      g.addColorStop(0, lighten(color, 0.3));
      g.addColorStop(1, darken(color, 0.2));
      ctx.fillStyle = g;
      ctx.beginPath();
      ctx.moveTo(-len / 2, -7);
      ctx.lineTo(len / 2, -3.5);
      ctx.lineTo(len / 2, 3.5);
      ctx.lineTo(-len / 2, 7);
      ctx.closePath();
      ctx.fill();
      ctx.restore();
    }
    ctx.restore();
  }

  function ramekin(ctx, x, y, rad, fill, { swirl = null } = {}) {
    const w = bowl(ctx, x, y, rad, { color: '#F6F0E6', rim: 0.14 });
    ctx.beginPath();
    ctx.arc(x, y, w, 0, TAU);
    ctx.fillStyle = volumeFill(ctx, x, y, w, fill, { hi: 0.18, lo: 0.2 });
    ctx.fill();
    if (swirl) {
      ctx.strokeStyle = swirl;
      ctx.lineWidth = w * 0.09;
      ctx.lineCap = 'round';
      ctx.beginPath();
      for (let t = 0; t < 14; t += 0.1) {
        const rr = w * 0.08 * t * 0.55;
        const px = x + Math.cos(t) * rr, py = y + Math.sin(t) * rr;
        t === 0 ? ctx.moveTo(px, py) : ctx.lineTo(px, py);
      }
      ctx.stroke();
    }
    gloss(ctx, x - w * 0.3, y - w * 0.35, w * 0.35, w * 0.12, 0.5);
    bowlDepth(ctx, x, y, w, 0.2);
    return w;
  }

  // Dishes ---------------------------------------------------------------

  const DISHES = {};

  DISHES['overnight-oats'] = {
    surface: C.sage,
    draw(ctx, r) {
      napkin(ctx, r, 820, 820, 380, 300, 0.4, '#FBF7EF');
      const cx = 480, cy = 470, R = 330;
      contactShadow(ctx, cx, cy, R, R, 0.3);
      // Glass jar rim.
      ctx.beginPath();
      ctx.arc(cx, cy, R, 0, TAU);
      const g = ctx.createLinearGradient(cx - R, cy - R, cx + R, cy + R);
      g.addColorStop(0, 'rgba(240,248,250,0.95)');
      g.addColorStop(0.5, 'rgba(206,222,226,0.9)');
      g.addColorStop(1, 'rgba(160,180,186,0.95)');
      ctx.fillStyle = g;
      ctx.fill();
      const w = R * 0.9;
      // Oats surface.
      ctx.beginPath();
      ctx.arc(cx, cy, w, 0, TAU);
      ctx.fillStyle = volumeFill(ctx, cx, cy, w, '#E9DABE', { hi: 0.2, lo: 0.2 });
      ctx.fill();
      for (const [x, y] of scatterInCircle(r, cx, cy, w * 0.95, 360)) {
        grain(ctx, x, y, r.range(8, 13), r.range(5, 8), r() * Math.PI, mix('#E2CFA7', '#F1E6CE', r()));
      }
      // Yogurt dollop.
      fillBlob(ctx, blobPoints(r, cx - 60, cy - 40, 120, 105, 0.1), '#F8F4EC', { hi: 0.1, lo: 0.1 });
      // Banana coins.
      for (const [x, y] of [[cx + 150, cy - 110], [cx + 175, cy + 20], [cx + 90, cy + 130]]) {
        contactShadow(ctx, x, y, 42, 42, 0.18);
        dot(ctx, x, y, 44, '#F2E1A4');
        specks(ctx, r, x, y, 12, 6, alpha('#8A6A3A', 0.6), 2);
      }
      blueberries(ctx, r, [[cx - 120, cy + 110], [cx - 160, cy + 60], [cx - 60, cy + 150], [cx + 20, cy + 60], [cx - 200, cy - 40]], 19);
      raspberry(ctx, r, cx - 30, cy + 200, 32);
      raspberry(ctx, r, cx + 40, cy - 190, 30);
      specks(ctx, r, cx, cy, w * 0.9, 90, '#2B2A28', 2.2);
      mintSprig(ctx, r, cx - 70, cy - 60, 40, 0.8);
      // Glass rim highlight.
      ctx.strokeStyle = 'rgba(255,255,255,0.9)';
      ctx.lineWidth = 7;
      ctx.beginPath();
      ctx.arc(cx, cy, R * 0.95, Math.PI * 1.05, Math.PI * 1.45);
      ctx.stroke();
      bowlDepth(ctx, cx, cy, w, 0.22);
    },
  };

  DISHES['flat-white'] = {
    surface: C.stone,
    draw(ctx, r) {
      const cx = 470, cy = 500;
      plate(ctx, cx, cy, 360, { color: '#F8F3EA', rim: 0.28 });
      // Handle.
      ctx.save();
      ctx.translate(cx + 250, cy + 40);
      ctx.rotate(0.25);
      contactShadow(ctx, 0, 0, 70, 30, 0.2);
      roundRect(ctx, -30, -34, 120, 68, 34);
      ctx.fillStyle = volumeFill(ctx, 30, 0, 70, '#F6F1E8', { hi: 0.25, lo: 0.2 });
      ctx.fill();
      roundRect(ctx, 0, -14, 64, 28, 14);
      ctx.fillStyle = darken('#F6F1E8', 0.12);
      ctx.fill();
      ctx.restore();
      // Cup.
      contactShadow(ctx, cx, cy, 230, 230, 0.28);
      ctx.beginPath();
      ctx.arc(cx, cy, 235, 0, TAU);
      ctx.fillStyle = volumeFill(ctx, cx, cy, 235, '#F7F2E9', { hi: 0.3, lo: 0.15 });
      ctx.fill();
      const w = 205;
      ctx.beginPath();
      ctx.arc(cx, cy, w, 0, TAU);
      const cg = ctx.createRadialGradient(cx, cy, 20, cx, cy, w);
      cg.addColorStop(0, '#C9905F');
      cg.addColorStop(0.75, '#A9683B');
      cg.addColorStop(1, '#6C3D22');
      ctx.fillStyle = cg;
      ctx.fill();
      // Rosetta latte art: stacked crescents + stem.
      ctx.save();
      ctx.beginPath();
      ctx.arc(cx, cy, w * 0.97, 0, TAU);
      ctx.clip();
      const foam = '#F6ECDD';
      for (let i = 0; i < 7; i++) {
        const y = cy - 120 + i * 34, sw = 150 - i * 14;
        ctx.beginPath();
        ctx.moveTo(cx - sw, y + 10);
        ctx.quadraticCurveTo(cx, y - 46, cx + sw, y + 10);
        ctx.quadraticCurveTo(cx, y - 18, cx - sw, y + 10);
        ctx.fillStyle = foam;
        ctx.fill();
      }
      ctx.beginPath();
      ctx.ellipse(cx, cy + 128, 46, 38, 0, 0, TAU);
      ctx.fill();
      ctx.strokeStyle = foam;
      ctx.lineWidth = 7;
      ctx.beginPath();
      ctx.moveTo(cx, cy - 150);
      ctx.lineTo(cx, cy + 150);
      ctx.stroke();
      ctx.restore();
      gloss(ctx, cx - 110, cy - 120, 60, 20, 0.35);
      // Little cookie on the saucer.
      const kx = cx - 250, ky = cy + 190;
      contactShadow(ctx, kx, ky, 58, 58, 0.2);
      fillBlob(ctx, blobPoints(r, kx, ky, 58, 56, 0.06), '#D29A56', { hi: 0.25, lo: 0.25 });
      specks(ctx, r, kx, ky, 40, 9, '#5B3521', 5);
    },
  };

  DISHES['avocado-toast'] = {
    surface: C.porcelain,
    draw(ctx, r) {
      napkin(ctx, r, 150, 170, 360, 300, -0.35, '#DCE5D6');
      const cx = 510, cy = 520;
      const w = plate(ctx, cx, cy, 390);
      // Toast.
      const toast = blobPoints(r, cx - 10, cy + 10, 285, 215, 0.025, 18, 0.2);
      contactShadow(ctx, cx - 10, cy + 10, 285, 215, 0.25);
      fillBlob(ctx, toast, '#9E642E', { hi: 0.25, lo: 0.25 });
      const crumb = blobPoints(r, cx - 10, cy + 10, 262, 194, 0.025, 18, 0.2);
      fillBlob(ctx, crumb, '#E9C98D', { hi: 0.15, lo: 0.15 });
      for (const [x, y] of scatterInCircle(r, cx - 10, cy + 10, 200, 60)) {
        ctx.fillStyle = alpha('#B5864B', 0.45);
        ctx.beginPath();
        ctx.ellipse(x, y, r.range(3, 10), r.range(2, 6), r() * 3, 0, TAU);
        ctx.fill();
      }
      // Smashed avocado base.
      fillBlob(ctx, blobPoints(r, cx - 20, cy + 20, 200, 150, 0.18, 18), '#A9C65C', { hi: 0.2, lo: 0.2 });
      specks(ctx, r, cx - 20, cy + 20, 160, 70, alpha('#6F8E2E', 0.5), 4);
      // Fanned slices.
      avocadoFan(ctx, r, cx - 120, cy - 30, 6, 170, 42, 0.5, 0.2);
      // Egg.
      friedEgg(ctx, r, cx + 110, cy + 50, 110);
      specks(ctx, r, cx, cy + 20, 230, 40, C.chili, 3);
      sesame(ctx, r, cx, cy + 20, 230, 40, ['#2B2520', '#F5EBD2']);
      for (let i = 0; i < 6; i++) {
        leaf(ctx, cx + 60 + r.gauss() * 60, cy - 90 + r.gauss() * 40, 34, 12, r() * TAU, '#6BA046');
      }
    },
  };

  DISHES['greek-yogurt-bowl'] = {
    surface: C.blush,
    draw(ctx, r) {
      const cx = 500, cy = 500;
      const w = bowl(ctx, cx, cy, 380, { color: '#E9EEF1' });
      ctx.beginPath();
      ctx.arc(cx, cy, w, 0, TAU);
      ctx.fillStyle = volumeFill(ctx, cx, cy, w, '#FAF7F1', { hi: 0.05, lo: 0.1 });
      ctx.fill();
      // Swirl texture.
      ctx.strokeStyle = 'rgba(220,210,195,0.6)';
      ctx.lineWidth = 3;
      for (let i = 0; i < 5; i++) {
        ctx.beginPath();
        ctx.arc(cx + 20, cy + 10, 60 + i * 45, 0.4 + i * 0.3, 2.4 + i * 0.4);
        ctx.stroke();
      }
      // Granola pile.
      for (const [x, y] of scatterInCircle(r, cx - 110, cy + 90, 150, 55)) {
        const c = r.pick(['#C58A45', '#B27634', '#D9A660', '#9C6630']);
        fillBlob(ctx, blobPoints(r, x, y, r.range(12, 24), r.range(10, 18), 0.3, 7, r() * 3), c, { hi: 0.3, lo: 0.3 });
      }
      for (const [x, y] of scatterInCircle(r, cx - 110, cy + 90, 150, 25)) {
        grain(ctx, x, y, 9, 5, r() * 3, '#EBD8A9');
      }
      strawberryHalf(ctx, r, cx + 120, cy - 110, 110, 0.4);
      strawberryHalf(ctx, r, cx + 190, cy + 20, 100, 1.3);
      strawberryHalf(ctx, r, cx + 40, cy - 190, 90, -0.3);
      blueberries(ctx, r, [[cx + 90, cy + 120], [cx + 140, cy + 160], [cx + 40, cy + 170], [cx - 30, cy - 60], [cx + 10, cy - 20], [cx + 190, cy + 120]], 20);
      drizzle(ctx, r, zigzag(r, cx - 230, cy - 170, cx + 200, cy + 210, 9, 60), alpha(C.honey, 0.9), 11);
      mintSprig(ctx, r, cx - 60, cy - 150, 46, 2.2);
      bowlDepth(ctx, cx, cy, w, 0.18);
    },
  };

  DISHES['poke-bowl'] = {
    surface: C.slate,
    draw(ctx, r) {
      chopsticks(ctx, 780, 880, 560, -0.55);
      const cx = 480, cy = 480;
      const w = bowl(ctx, cx, cy, 410, { color: '#2F3438', inner: '#252A2E', rim: 0.07 });
      riceBed(ctx, r, cx, cy, w * 0.96);
      // Salmon cubes (upper left).
      for (const [x, y] of scatterInCircle(r, cx - 150, cy - 110, 150, 24)) {
        cube(ctx, x, y, 60, r() * 1.2, C.salmon, { top: 0.25 });
        ctx.strokeStyle = 'rgba(255,230,215,0.8)';
        ctx.lineWidth = 3;
        ctx.beginPath();
        ctx.moveTo(x - 20, y - 8);
        ctx.quadraticCurveTo(x, y + 4, x + 20, y - 14);
        ctx.stroke();
      }
      gloss(ctx, cx - 180, cy - 150, 90, 26, 0.35);
      // Avocado (upper right).
      avocadoFan(ctx, r, cx + 120, cy - 190, 7, 200, 46, 1.95, 0.15);
      // Edamame (lower right).
      for (const [x, y] of scatterInCircle(r, cx + 150, cy + 120, 125, 60)) {
        grain(ctx, x, y, 19, 14, r() * 3, mix('#86BA45', '#A6CF62', r()));
      }
      // Mango (lower left).
      for (const [x, y] of scatterInCircle(r, cx - 160, cy + 140, 110, 16)) {
        cube(ctx, x, y, 48, r() * 1.2, '#F6B63D', { top: 0.3 });
      }
      // Cucumber (bottom centre).
      for (let i = 0; i < 5; i++) {
        const a = Math.PI * 0.35 + i * 0.16;
        const x = cx + Math.cos(a) * 250 - 70, y = cy + Math.sin(a) * 250 - 10;
        contactShadow(ctx, x, y, 34, 34, 0.15);
        dot(ctx, x, y, 36, '#4E7B2F');
        dot(ctx, x, y, 31, '#D8E8B8', false);
        specks(ctx, r, x, y, 13, 7, '#9DB37A', 2.4);
      }
      // Centre: pickled ginger rosette + nori squares.
      for (let i = 0; i < 9; i++) {
        const a = i * TAU / 9;
        leaf(ctx, cx + 10 + Math.cos(a) * 26, cy + 10 + Math.sin(a) * 26, 64, 26, a, '#F4B6A6', { vein: false });
      }
      dot(ctx, cx + 10, cy + 10, 16, '#F7C4B6', false);
      for (let i = 0; i < 3; i++) {
        ctx.save();
        ctx.translate(cx + 70 + i * 26, cy - 10 + i * 20);
        ctx.rotate(0.3 + i * 0.5);
        ctx.fillStyle = C.nori;
        ctx.fillRect(-26, -26, 52, 52);
        ctx.fillStyle = 'rgba(90,110,80,0.25)';
        ctx.fillRect(-26, -26, 52, 10);
        ctx.restore();
      }
      for (const [x, y] of scatterInCircle(r, cx, cy, 300, 22)) {
        ctx.strokeStyle = mix('#4E9A3A', '#9CCB6A', r());
        ctx.lineWidth = 3;
        ctx.beginPath();
        ctx.arc(x, y, 4.5, 0, TAU);
        ctx.stroke();
      }
      sesame(ctx, r, cx, cy, w * 0.9, 160);
      drizzle(ctx, r, zigzag(r, cx - 260, cy - 190, cx - 40, cy - 20, 7, 34), alpha('#F3A36A', 0.95), 8);
      bowlDepth(ctx, cx, cy, w, 0.3);
    },
  };

  DISHES['chicken-shawarma-wrap'] = {
    surface: C.butter,
    draw(ctx, r) {
      napkin(ctx, r, 860, 170, 320, 280, 0.5, '#F6F0E4');
      const cx = 500, cy = 530;
      plate(ctx, cx, cy, 400);
      function wrapHalf(x, y, angle) {
        ctx.save();
        ctx.translate(x, y);
        ctx.rotate(angle);
        contactShadow(ctx, 0, 0, 220, 110, 0.22);
        // Tortilla body.
        roundRect(ctx, -220, -105, 360, 210, 100);
        ctx.fillStyle = volumeFill(ctx, -40, 0, 230, '#E6C58E', { hi: 0.2, lo: 0.2 });
        ctx.fill();
        for (let i = 0; i < 14; i++) {
          ctx.fillStyle = alpha('#9B6A34', r.range(0.3, 0.6));
          ctx.beginPath();
          ctx.ellipse(-200 + r() * 320, -80 + r() * 160, r.range(6, 16), r.range(4, 9), r() * 3, 0, TAU);
          ctx.fill();
        }
        // Cut face.
        ctx.beginPath();
        ctx.ellipse(140, 0, 72, 105, 0, 0, TAU);
        ctx.fillStyle = '#EAD2A6';
        ctx.fill();
        ctx.save();
        ctx.beginPath();
        ctx.ellipse(140, 0, 62, 94, 0, 0, TAU);
        ctx.clip();
        ctx.fillStyle = '#F6EFE2';
        ctx.fillRect(60, -100, 160, 200);
        for (let i = 0; i < 26; i++) {
          const kind = r();
          const px = 140 + r.gauss() * 36, py = r.gauss() * 58;
          if (kind < 0.45) fillBlob(ctx, blobPoints(r, px, py, 16, 12, 0.3, 7), '#C88947', { hi: 0.3, lo: 0.3 });
          else if (kind < 0.7) leaf(ctx, px, py, 36, 10, r() * 3, '#7DB24A', { vein: false });
          else if (kind < 0.85) dot(ctx, px, py, 10, '#E0533B');
          else dot(ctx, px, py, 8, '#9A4E8A');
        }
        ctx.restore();
        ctx.restore();
      }
      wrapHalf(cx - 60, cy - 90, -0.35);
      wrapHalf(cx + 40, cy + 110, 2.75);
      // Garlic sauce ramekin + pickled turnips.
      ramekin(ctx, cx + 230, cy - 170, 80, '#F8F5EE');
      for (let i = 0; i < 4; i++) {
        ctx.save();
        ctx.translate(cx - 250 + i * 30, cy + 210 + i * 8);
        ctx.rotate(i * 0.3);
        contactShadow(ctx, 0, 0, 26, 14, 0.15);
        roundRect(ctx, -30, -12, 60, 24, 6);
        ctx.fillStyle = volumeFill(ctx, 0, 0, 30, '#E0659A', { hi: 0.3, lo: 0.2 });
        ctx.fill();
        ctx.restore();
      }
    },
  };

  DISHES['caesar-salad'] = {
    surface: C.linen,
    draw(ctx, r) {
      const cx = 500, cy = 500;
      const w = bowl(ctx, cx, cy, 400, { color: '#F7F3EB' });
      ctx.beginPath();
      ctx.arc(cx, cy, w, 0, TAU);
      ctx.fillStyle = '#6F9A3C';
      ctx.fill();
      for (let i = 0; i < 40; i++) {
        const a = r() * TAU, d = Math.sqrt(r()) * w * 0.82;
        const col = mix('#5E8F33', '#B7D57A', r());
        leaf(ctx, cx + Math.cos(a) * d, cy + Math.sin(a) * d, r.range(120, 190), r.range(40, 60), r() * TAU, col, { curl: 0.35 });
      }
      for (const [x, y] of scatterInCircle(r, cx, cy, w * 0.7, 14)) {
        cube(ctx, x, y, r.range(34, 44), r() * 2, '#DDA75A', { top: 0.35, round: 0.3 });
        specks(ctx, r, x, y, 14, 5, '#8E5A22', 2.4);
      }
      for (const [x, y] of scatterInCircle(r, cx, cy, w * 0.75, 16)) {
        ctx.save();
        ctx.translate(x, y);
        ctx.rotate(r() * 3);
        ctx.fillStyle = alpha('#F5E7B8', 0.95);
        ctx.beginPath();
        ctx.moveTo(-30, -6);
        ctx.lineTo(28, -12);
        ctx.lineTo(32, 6);
        ctx.lineTo(-26, 10);
        ctx.closePath();
        ctx.fill();
        ctx.restore();
      }
      drizzle(ctx, r, zigzag(r, cx - 220, cy - 120, cx + 200, cy + 140, 8, 50), alpha('#F4ECD9', 0.95), 12);
      specks(ctx, r, cx, cy, w * 0.85, 80, '#2D2A26', 2.2);
      lemonWedge(ctx, cx + 230, cy + 210, 120, -0.6);
      bowlDepth(ctx, cx, cy, w, 0.25);
    },
  };

  DISHES['sushi-set'] = {
    surface: C.porcelain,
    draw(ctx, r) {
      chopsticks(ctx, 520, 900, 640, 0.08);
      ctx.save();
      ctx.translate(500, 460);
      ctx.rotate(-0.08);
      contactShadow(ctx, 0, 0, 420, 250, 0.3);
      roundRect(ctx, -420, -250, 840, 500, 26);
      const sg = ctx.createLinearGradient(-420, -250, 420, 250);
      sg.addColorStop(0, '#4A4845');
      sg.addColorStop(1, '#2B2A28');
      ctx.fillStyle = sg;
      ctx.fill();
      // Nigiri.
      const fish = ['#F28A5E', '#C8313B', '#F28A5E'];
      for (let i = 0; i < 3; i++) {
        const x = -250 + i * 150, y = -80;
        ctx.save();
        ctx.translate(x, y);
        ctx.rotate(-0.2);
        contactShadow(ctx, 0, 0, 62, 110, 0.35);
        roundRect(ctx, -52, -100, 104, 200, 50);
        ctx.fillStyle = C.rice;
        ctx.fill();
        roundRect(ctx, -62, -112, 124, 224, 56);
        ctx.fillStyle = volumeFill(ctx, 0, 0, 110, fish[i], { hi: 0.25, lo: 0.2 });
        ctx.fill();
        if (fish[i] === '#F28A5E') {
          ctx.strokeStyle = 'rgba(255,235,222,0.85)';
          ctx.lineWidth = 5;
          for (let k = -2; k <= 2; k++) {
            ctx.beginPath();
            ctx.moveTo(-50, k * 40 - 10);
            ctx.quadraticCurveTo(0, k * 40 + 10, 50, k * 40 - 18);
            ctx.stroke();
          }
        }
        gloss(ctx, -20, -50, 30, 70, 0.4, 0);
        ctx.restore();
      }
      // Maki rolls.
      for (let i = 0; i < 6; i++) {
        const x = 170 + (i % 2) * 110, y = -150 + Math.floor(i / 2) * 110;
        contactShadow(ctx, x, y, 50, 50, 0.35);
        dot(ctx, x, y, 50, C.nori, false);
        dot(ctx, x, y, 43, C.rice, false);
        for (const [gx, gy] of scatterInCircle(r, x, y, 40, 30)) grain(ctx, gx, gy, 5, 2.4, r() * 3, '#F2ECDF');
        dot(ctx, x, y, 17, i % 2 ? '#F28A5E' : '#7FB24C');
      }
      // Ginger + wasabi.
      for (let i = 0; i < 5; i++) leaf(ctx, -250 + i * 12, 150 + i * 6, 70, 32, 0.4 + i * 0.5, '#F5B7A8', { vein: false });
      fillBlob(ctx, blobPoints(r, -80, 160, 38, 30, 0.25), '#8DB84A', { hi: 0.3, lo: 0.3 });
      ctx.restore();
      // Soy dish.
      const w = bowl(ctx, 800, 810, 95, { color: '#F4EFE6' });
      ctx.beginPath();
      ctx.arc(800, 810, w, 0, TAU);
      ctx.fillStyle = '#3A1F12';
      ctx.fill();
      gloss(ctx, 780, 790, 30, 10, 0.5);
    },
  };

  DISHES['salmon-greens'] = {
    surface: C.sage,
    draw(ctx, r) {
      const cx = 500, cy = 510;
      plate(ctx, cx, cy, 410);
      riceBed(ctx, r, cx - 150, cy + 110, 150);
      sesame(ctx, r, cx - 150, cy + 110, 120, 30, ['#2B2520']);
      // Greens bed.
      for (let i = 0; i < 16; i++) {
        leaf(ctx, cx + 150 + r.gauss() * 60, cy + 140 + r.gauss() * 50, r.range(70, 110), r.range(26, 36), r() * TAU, mix('#4F8A34', '#9CC65E', r()));
      }
      broccoli(ctx, r, cx + 200, cy - 30, 70);
      broccoli(ctx, r, cx + 110, cy + 60, 60);
      // Salmon fillet.
      ctx.save();
      ctx.translate(cx - 60, cy - 110);
      ctx.rotate(-0.25);
      contactShadow(ctx, 0, 0, 200, 110, 0.3);
      roundRect(ctx, -200, -105, 400, 210, 70);
      ctx.fillStyle = volumeFill(ctx, 0, 0, 220, '#EE8B63', { hi: 0.2, lo: 0.2 });
      ctx.fill();
      ctx.strokeStyle = 'rgba(255,225,205,0.85)';
      ctx.lineWidth = 7;
      for (let k = -3; k <= 3; k++) {
        ctx.beginPath();
        ctx.moveTo(k * 55 - 30, -100);
        ctx.quadraticCurveTo(k * 55 + 10, 0, k * 55 - 20, 100);
        ctx.stroke();
      }
      // Seared crust.
      roundRect(ctx, -200, -105, 400, 70, 60);
      ctx.fillStyle = 'rgba(150,70,30,0.55)';
      ctx.fill();
      gloss(ctx, -60, -20, 90, 22, 0.35, 0);
      ctx.restore();
      lemonWedge(ctx, cx - 250, cy - 200, 110, -0.9);
      for (let i = 0; i < 5; i++) leaf(ctx, cx - 30 + r.gauss() * 30, cy - 170 + r.gauss() * 20, 26, 10, r() * 3, '#3E7A2E');
    },
  };

  DISHES['dal-rice'] = {
    surface: C.linen,
    draw(ctx, r) {
      const cx = 520, cy = 520;
      plate(ctx, cx, cy, 420, { color: '#E8ECE8' });
      riceBed(ctx, r, cx + 120, cy + 110, 185);
      // Roti half.
      ctx.save();
      ctx.translate(cx - 150, cy + 220);
      contactShadow(ctx, 0, 0, 170, 90, 0.2);
      ctx.beginPath();
      ctx.arc(0, 0, 170, Math.PI, TAU);
      ctx.closePath();
      ctx.fillStyle = volumeFill(ctx, 0, -60, 170, '#E3BC7C', { hi: 0.2, lo: 0.2 });
      ctx.fill();
      for (let i = 0; i < 16; i++) {
        ctx.fillStyle = alpha('#7E4F22', r.range(0.35, 0.6));
        ctx.beginPath();
        ctx.ellipse(r.gauss() * 90, -r() * 140, r.range(6, 14), r.range(4, 8), r() * 3, 0, TAU);
        ctx.fill();
      }
      ctx.restore();
      // Katori of dal.
      const kx = cx - 110, ky = cy - 90;
      const w = bowl(ctx, kx, ky, 210, { color: '#C9CFD3', rim: 0.08 });
      ctx.beginPath();
      ctx.arc(kx, ky, w, 0, TAU);
      ctx.fillStyle = volumeFill(ctx, kx, ky, w, '#E5A932', { hi: 0.25, lo: 0.15 });
      ctx.fill();
      // Ghee sheen + tadka.
      for (const [x, y] of scatterInCircle(r, kx, ky, w * 0.85, 14)) {
        ctx.fillStyle = 'rgba(255,220,120,0.55)';
        ctx.beginPath();
        ctx.ellipse(x, y, r.range(8, 20), r.range(5, 12), 0, 0, TAU);
        ctx.fill();
      }
      specks(ctx, r, kx - 20, ky - 10, w * 0.5, 40, '#2B1E14', 3.4);
      specks(ctx, r, kx - 20, ky - 10, w * 0.5, 20, '#8B5A2B', 3);
      for (let i = 0; i < 3; i++) leaf(ctx, kx - 40 + i * 30, ky - 30 + i * 18, 44, 16, 0.4 + i, '#3F6B2A');
      for (let i = 0; i < 2; i++) {
        ctx.save();
        ctx.translate(kx + 40 + i * 40, ky + 30);
        ctx.rotate(0.6 + i);
        roundRect(ctx, -28, -7, 56, 14, 7);
        ctx.fillStyle = '#B8261A';
        ctx.fill();
        ctx.restore();
      }
      for (let i = 0; i < 7; i++) leaf(ctx, kx + r.gauss() * 60, ky + r.gauss() * 60, 24, 14, r() * 3, '#5E9E47');
      bowlDepth(ctx, kx, ky, w, 0.25);
      lemonWedge(ctx, cx + 270, cy - 210, 100, 0.7, '#B7D45A');
    },
  };

  DISHES['margherita-pizza'] = {
    surface: C.stone,
    draw(ctx, r) {
      const cx = 500, cy = 500;
      // Wooden board.
      contactShadow(ctx, cx, cy, 440, 440, 0.3);
      ctx.beginPath();
      ctx.arc(cx, cy, 440, 0, TAU);
      const wg = ctx.createLinearGradient(0, 60, 1000, 940);
      wg.addColorStop(0, '#C79A66');
      wg.addColorStop(1, '#9E7345');
      ctx.fillStyle = wg;
      ctx.fill();
      ctx.strokeStyle = 'rgba(110,75,40,0.25)';
      ctx.lineWidth = 2;
      for (let i = 0; i < 26; i++) {
        ctx.beginPath();
        ctx.ellipse(cx + 30, cy - 20, 60 + i * 15, 25 + i * 14, 0.3, 0, TAU);
        ctx.stroke();
      }
      // Crust.
      const R = 390;
      ctx.beginPath();
      ctx.arc(cx, cy, R, 0, TAU);
      ctx.fillStyle = volumeFill(ctx, cx, cy, R, '#DCA761', { hi: 0.25, lo: 0.2 });
      ctx.fill();
      for (let i = 0; i < 38; i++) {
        const a = r() * TAU, d = R * r.range(0.86, 0.98);
        ctx.fillStyle = alpha('#3B2314', r.range(0.35, 0.75));
        ctx.beginPath();
        ctx.ellipse(cx + Math.cos(a) * d, cy + Math.sin(a) * d, r.range(6, 16), r.range(4, 10), a, 0, TAU);
        ctx.fill();
      }
      // Sauce.
      const S = R * 0.82;
      fillBlob(ctx, blobPoints(r, cx, cy, S, S, 0.03, 24), '#C8412D', { hi: 0.15, lo: 0.2 });
      specks(ctx, r, cx, cy, S * 0.95, 80, alpha('#8E2415', 0.6), 4);
      // Mozzarella pools.
      for (const [x, y] of scatterInCircle(r, cx, cy, S * 0.78, 9)) {
        const pts = blobPoints(r, x, y, r.range(46, 72), r.range(42, 66), 0.2, 12);
        fillBlob(ctx, pts, '#FBF3E3', { hi: 0.05, lo: 0.1 });
        ctx.save();
        smoothPath(ctx, pts);
        ctx.strokeStyle = 'rgba(214,150,60,0.55)';
        ctx.lineWidth = 5;
        ctx.stroke();
        ctx.restore();
      }
      // Basil.
      for (const [x, y] of scatterInCircle(r, cx, cy, S * 0.7, 8)) {
        leaf(ctx, x, y, r.range(60, 90), r.range(30, 40), r() * TAU, C.basil);
        gloss(ctx, x - 6, y - 6, 16, 6, 0.4);
      }
      // Slice cuts.
      ctx.strokeStyle = 'rgba(60,30,15,0.35)';
      ctx.lineWidth = 3;
      for (let i = 0; i < 4; i++) {
        const a = i * Math.PI / 4 + 0.2;
        ctx.beginPath();
        ctx.moveTo(cx + Math.cos(a) * R, cy + Math.sin(a) * R);
        ctx.lineTo(cx - Math.cos(a) * R, cy - Math.sin(a) * R);
        ctx.stroke();
      }
      drizzle(ctx, r, zigzag(r, cx - 200, cy - 180, cx + 160, cy + 200, 6, 40), 'rgba(214,170,40,0.45)', 6);
    },
  };

  DISHES['ramen'] = {
    surface: C.slate,
    draw(ctx, r) {
      const cx = 490, cy = 490;
      const w = bowl(ctx, cx, cy, 420, { color: '#1F2327', inner: '#2A2E33', rim: 0.07 });
      ctx.beginPath();
      ctx.arc(cx, cy, w, 0, TAU);
      ctx.fillStyle = volumeFill(ctx, cx, cy, w, '#D9A158', { hi: 0.18, lo: 0.2 });
      ctx.fill();
      // Noodles (lower half).
      ctx.save();
      ctx.beginPath();
      ctx.arc(cx, cy, w, 0, TAU);
      ctx.clip();
      ctx.lineCap = 'round';
      ctx.beginPath();
      ctx.ellipse(cx - 10, cy + 150, 300, 150, -0.08, 0, TAU);
      ctx.clip();
      for (let i = 0; i < 46; i++) {
        ctx.strokeStyle = mix('#E6C473', '#F8E6AE', r());
        ctx.lineWidth = r.range(7, 10);
        ctx.beginPath();
        const y0 = cy + 20 + r() * 270, ph = r() * TAU, amp = r.range(8, 22);
        for (let x = cx - 330; x <= cx + 320; x += 12) {
          const y = y0 + Math.sin((x / 60) + ph) * amp;
          x === cx - 330 ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
        }
        ctx.stroke();
      }
      ctx.restore();
      // Fat droplets.
      for (const [x, y] of scatterInCircle(r, cx, cy - 60, w * 0.6, 30)) {
        ctx.strokeStyle = 'rgba(255,235,190,0.6)';
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.arc(x, y, r.range(4, 12), 0, TAU);
        ctx.stroke();
      }
      // Chashu slices.
      for (const [x, y] of [[cx - 170, cy - 120], [cx - 60, cy - 190]]) {
        contactShadow(ctx, x, y, 90, 80, 0.2);
        fillBlob(ctx, blobPoints(r, x, y, 95, 85, 0.08), '#B9785A', { hi: 0.25, lo: 0.2 });
        fillBlob(ctx, blobPoints(r, x, y, 70, 62, 0.1), '#E9B99C', { hi: 0.15, lo: 0.15 });
        ctx.strokeStyle = 'rgba(255,240,230,0.7)';
        ctx.lineWidth = 4;
        ctx.beginPath();
        for (let t = 0; t < 9; t += 0.1) {
          const rr = t * 6;
          const px = x + Math.cos(t) * rr, py = y + Math.sin(t) * rr;
          t === 0 ? ctx.moveTo(px, py) : ctx.lineTo(px, py);
        }
        ctx.stroke();
      }
      softEggHalf(ctx, r, cx + 140, cy - 130, 150, 0.4);
      softEggHalf(ctx, r, cx + 200, cy - 20, 140, 1.1);
      // Nori sheets tucked at the back edge.
      for (const [dx, a] of [[-240, -0.5], [-150, -0.3]]) {
        ctx.save();
        ctx.translate(cx + dx, cy - 250);
        ctx.rotate(a);
        ctx.fillStyle = C.nori;
        ctx.fillRect(-70, -90, 140, 170);
        ctx.fillStyle = 'rgba(80,100,70,0.3)';
        ctx.fillRect(-70, -90, 140, 20);
        ctx.restore();
      }
      // Scallions + bamboo + sesame.
      for (const [x, y] of scatterInCircle(r, cx - 30, cy + 30, 170, 34)) {
        ctx.strokeStyle = mix('#5FA046', '#B9DB7C', r());
        ctx.lineWidth = 3.5;
        ctx.beginPath();
        ctx.arc(x, y, 5, 0, TAU);
        ctx.stroke();
      }
      for (let i = 0; i < 5; i++) {
        ctx.save();
        ctx.translate(cx + 80 + i * 18, cy + 160 + i * 6);
        ctx.rotate(0.4);
        roundRect(ctx, -34, -9, 68, 18, 6);
        ctx.fillStyle = '#E4C27A';
        ctx.fill();
        ctx.restore();
      }
      sesame(ctx, r, cx, cy, w * 0.8, 60, ['#F5EBD2']);
      bowlDepth(ctx, cx, cy, w, 0.32);
      chopsticks(ctx, cx + 60, cy + 60, 820, -0.72, '#2B2A28');
    },
  };

  DISHES['berry-smoothie'] = {
    surface: C.blush,
    draw(ctx, r) {
      const cx = 470, cy = 470, R = 300;
      contactShadow(ctx, cx, cy, R, R, 0.3);
      ctx.beginPath();
      ctx.arc(cx, cy, R, 0, TAU);
      ctx.fillStyle = 'rgba(235,242,246,0.95)';
      ctx.fill();
      const w = R * 0.9;
      ctx.beginPath();
      ctx.arc(cx, cy, w, 0, TAU);
      ctx.fillStyle = volumeFill(ctx, cx, cy, w, '#B84B82', { hi: 0.25, lo: 0.2 });
      ctx.fill();
      // Foam swirls.
      ctx.strokeStyle = 'rgba(255,215,235,0.45)';
      ctx.lineWidth = 5;
      for (let i = 0; i < 4; i++) {
        ctx.beginPath();
        ctx.arc(cx - 20, cy + 10, 50 + i * 50, 0.2 + i, 2 + i);
        ctx.stroke();
      }
      raspberry(ctx, r, cx + 80, cy - 70, 36);
      blueberries(ctx, r, [[cx - 70, cy + 80], [cx - 30, cy + 110], [cx + 20, cy + 90]], 18);
      for (const [x, y] of scatterInCircle(r, cx - 60, cy - 60, 70, 18)) {
        grain(ctx, x, y, 9, 6, r() * 3, '#D8AE6C');
      }
      mintSprig(ctx, r, cx + 40, cy + 20, 44, 1.2);
      // Straw.
      ctx.save();
      ctx.translate(cx + 90, cy - 120);
      ctx.rotate(-0.9);
      contactShadow(ctx, 160, 0, 170, 16, 0.2);
      roundRect(ctx, 0, -16, 360, 32, 16);
      const sg = ctx.createLinearGradient(0, -16, 0, 16);
      sg.addColorStop(0, '#F4B5C9');
      sg.addColorStop(1, '#D97C9A');
      ctx.fillStyle = sg;
      ctx.fill();
      ctx.restore();
      dot(ctx, cx + 90, cy - 120, 18, '#C95F82');
      dot(ctx, cx + 90, cy - 120, 11, '#7A2344', false);
      ctx.strokeStyle = 'rgba(255,255,255,0.9)';
      ctx.lineWidth = 6;
      ctx.beginPath();
      ctx.arc(cx, cy, R * 0.95, Math.PI * 1.05, Math.PI * 1.45);
      ctx.stroke();
      // Loose berries on the table.
      raspberry(ctx, r, 810, 760, 34);
      raspberry(ctx, r, 870, 690, 30);
      blueberries(ctx, r, [[760, 850], [820, 880], [880, 820]], 20);
      strawberryHalf(ctx, r, 180, 820, 110, 0.6);
    },
  };

  DISHES['apple-peanut-butter'] = {
    surface: C.sage,
    draw(ctx, r) {
      const cx = 500, cy = 520;
      plate(ctx, cx, cy, 410, { color: '#FAF6EE' });
      // Apple slices fanned radially around the dip.
      const ax = cx + 10, ay = cy + 10;
      for (let i = 0; i < 10; i++) {
        const a = i * TAU / 10 + 0.15;
        ctx.save();
        ctx.translate(ax + Math.cos(a) * 250, ay + Math.sin(a) * 250);
        ctx.rotate(a + Math.PI / 2);
        contactShadow(ctx, 0, 0, 58, 110, 0.14);
        // Red skin edge (outer side).
        ctx.beginPath();
        ctx.moveTo(0, -118);
        ctx.bezierCurveTo(-78, -70, -78, 70, 0, 118);
        ctx.bezierCurveTo(-30, 60, -30, -60, 0, -118);
        ctx.fillStyle = i % 3 === 0 ? '#9DBA3F' : '#C8373B';
        ctx.fill();
        // Cream flesh.
        ctx.beginPath();
        ctx.moveTo(0, -112);
        ctx.bezierCurveTo(-66, -66, -66, 66, 0, 112);
        ctx.bezierCurveTo(40, 60, 40, -60, 0, -112);
        ctx.fillStyle = volumeFill(ctx, -10, 0, 100, '#F6EACB', { hi: 0.2, lo: 0.12 });
        ctx.fill();
        // Seed pocket.
        ctx.fillStyle = 'rgba(150,110,60,0.3)';
        ctx.beginPath();
        ctx.ellipse(10, 0, 9, 22, 0, 0, TAU);
        ctx.fill();
        ctx.restore();
      }
      ramekin(ctx, cx + 10, cy + 10, 140, '#B97B3E', { swirl: 'rgba(230,180,120,0.8)' });
      specks(ctx, r, cx + 10, cy + 10, 80, 16, '#7A4A22', 3);
    },
  };

  DISHES['dark-chocolate'] = {
    surface: C.stone,
    draw(ctx, r) {
      // Parchment.
      ctx.save();
      ctx.translate(500, 500);
      ctx.rotate(-0.12);
      contactShadow(ctx, 0, 0, 420, 360, 0.22);
      fillBlob(ctx, blobPoints(r, 0, 0, 440, 380, 0.04, 20), '#F3ECDD', { hi: 0.15, lo: 0.08 });
      ctx.restore();
      function square(x, y, s, a, broken = false) {
        ctx.save();
        ctx.translate(x, y);
        ctx.rotate(a);
        contactShadow(ctx, 0, 0, s / 2, s / 2, 0.3);
        if (broken) {
          ctx.beginPath();
          ctx.moveTo(-s / 2, -s / 2);
          ctx.lineTo(s / 2, -s / 2);
          ctx.lineTo(s / 2, s * 0.1);
          ctx.lineTo(s * 0.2, s * 0.3);
          ctx.lineTo(-s * 0.1, s / 2);
          ctx.lineTo(-s / 2, s / 2);
          ctx.closePath();
        } else {
          roundRect(ctx, -s / 2, -s / 2, s, s, 8);
        }
        ctx.fillStyle = '#3E2217';
        ctx.fill();
        roundRect(ctx, -s / 2 + 12, -s / 2 + 12, s - 24, s - 24, 6);
        const g = ctx.createLinearGradient(-s / 2, -s / 2, s / 2, s / 2);
        g.addColorStop(0, '#7A4A34');
        g.addColorStop(0.5, '#54301F');
        g.addColorStop(1, '#3A2016');
        ctx.fillStyle = g;
        ctx.fill();
        gloss(ctx, -s * 0.2, -s * 0.2, s * 0.25, s * 0.06, 0.25);
        ctx.restore();
      }
      const s = 130;
      for (let i = 0; i < 3; i++) for (let j = 0; j < 4; j++) square(260 + j * (s + 6), 300 + i * (s + 6), s, -0.12);
      square(770, 700, s, 0.5, true);
      square(640, 790, s, -0.9, true);
      square(250, 760, s * 0.8, 1.2, true);
      specks(ctx, r, 500, 520, 380, 90, alpha('#5C3522', 0.55), 2.6);
      // Sea salt flakes.
      for (const [x, y] of scatterInCircle(r, 500, 480, 300, 26)) {
        ctx.fillStyle = 'rgba(255,255,255,0.85)';
        ctx.beginPath();
        ctx.moveTo(x, y - 5);
        ctx.lineTo(x + 5, y);
        ctx.lineTo(x, y + 4);
        ctx.lineTo(x - 5, y);
        ctx.closePath();
        ctx.fill();
      }
      // Almonds.
      for (const [x, y, a] of [[800, 250, 0.4], [860, 330, 1.4], [170, 560, -0.6]]) {
        ctx.save();
        ctx.translate(x, y);
        ctx.rotate(a);
        contactShadow(ctx, 0, 0, 34, 20, 0.2);
        ctx.beginPath();
        ctx.ellipse(0, 0, 36, 20, 0, 0, TAU);
        ctx.fillStyle = volumeFill(ctx, 0, 0, 36, '#B57446', { hi: 0.3, lo: 0.3 });
        ctx.fill();
        ctx.restore();
      }
    },
  };

  DISHES['hero-plate'] = {
    surface: C.porcelain,
    draw(ctx, r) {
      napkin(ctx, r, 150, 860, 380, 300, 0.3, '#DCE5D6');
      const cx = 510, cy = 480;
      const w = bowl(ctx, cx, cy, 420, { color: '#F4EEE3' });
      // Quinoa base.
      ctx.beginPath();
      ctx.arc(cx, cy, w, 0, TAU);
      ctx.fillStyle = volumeFill(ctx, cx, cy, w, '#E4D2A8', { hi: 0.15, lo: 0.15 });
      ctx.fill();
      for (const [x, y] of scatterInCircle(r, cx, cy, w * 0.95, 700)) {
        grain(ctx, x, y, 4.2, 3.4, r() * 3, r.pick(['#EFE2C2', '#E2CE9E', '#D8C08E', '#C9534A']));
      }
      // Sweet potato (top left).
      for (const [x, y] of scatterInCircle(r, cx - 150, cy - 130, 130, 16)) {
        cube(ctx, x, y, 66, r() * 1.4, '#E98A3A', { top: 0.25 });
        ctx.fillStyle = 'rgba(120,50,20,0.35)';
        ctx.beginPath();
        ctx.arc(x + 12, y + 10, 9, 0, TAU);
        ctx.fill();
      }
      // Kale (top right).
      for (let i = 0; i < 20; i++) {
        leaf(ctx, cx + 160 + r.gauss() * 60, cy - 140 + r.gauss() * 50, r.range(100, 140), r.range(40, 52), r() * TAU, mix('#2F5F2A', '#5B8E3C', r()), { curl: 0.5 });
      }
      // Chickpeas (bottom left).
      for (const [x, y] of scatterInCircle(r, cx - 150, cy + 150, 120, 32)) {
        dot(ctx, x, y, 21, '#D9A45B');
        ctx.strokeStyle = 'rgba(150,95,40,0.5)';
        ctx.lineWidth = 2.4;
        ctx.beginPath();
        ctx.arc(x + 4, y, 11, 1.2, 2.8);
        ctx.stroke();
      }
      specks(ctx, r, cx - 150, cy + 150, 110, 30, '#B5402A', 3);
      // Pickled red cabbage (bottom right).
      for (let i = 0; i < 44; i++) {
        ctx.strokeStyle = mix('#6E2461', '#B85AA3', r());
        ctx.lineWidth = 8;
        ctx.lineCap = 'round';
        const x = cx + 160 + r.gauss() * 60, y = cy + 150 + r.gauss() * 55;
        const a = r() * TAU;
        ctx.beginPath();
        ctx.moveTo(x, y);
        ctx.quadraticCurveTo(x + Math.cos(a) * 34, y + Math.sin(a) * 12, x + Math.cos(a) * 64, y + Math.sin(a) * 34);
        ctx.stroke();
      }
      // Avocado fan + jammy egg in the centre.
      avocadoFan(ctx, r, cx + 40, cy + 10, 7, 220, 48, -0.25, 0.18);
      softEggHalf(ctx, r, cx - 40, cy - 10, 180, 0.3);
      drizzle(ctx, r, zigzag(r, cx - 260, cy + 70, cx + 240, cy - 90, 9, 44), alpha('#F2E7CF', 0.95), 12);
      sesame(ctx, r, cx, cy, w * 0.85, 110);
      for (let i = 0; i < 8; i++) leaf(ctx, cx + r.gauss() * 140, cy + r.gauss() * 140, 30, 13, r() * TAU, '#6BA046');
      bowlDepth(ctx, cx, cy, w, 0.25);
    },
  };

  window.DISHES = DISHES;
})();
