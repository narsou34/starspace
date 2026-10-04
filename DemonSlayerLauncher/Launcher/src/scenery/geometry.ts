/**
 * Génération procédurale (déterministe) des éléments de décor :
 * crêtes de montagnes, pins, maisons, bambous, étoiles.
 * Tout est calculé une seule fois au chargement du module.
 */
export const W = 1600;
export const H = 900;

export function rng(seed: number) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

export interface Ridge {
  path: string;
  yAt: (x: number) => number;
}

/** Crête montagneuse : somme de bruits « ridged » (pics marqués). */
export function ridge(seed: number, base: number, amp: number, freq = 1): Ridge {
  const r = rng(seed);
  const waves = [0, 1, 2].map((i) => ({
    f: (0.0022 + r() * 0.002) * freq * (1 + i * 1.9),
    p: r() * 10,
    w: [0.62, 0.28, 0.1][i]!,
  }));
  const yAt = (x: number) => {
    let v = 0;
    for (const wv of waves) v += wv.w * Math.pow(1 - Math.abs(Math.sin(x * wv.f + wv.p)), 1.7);
    return base - amp * v;
  };
  let d = `M0 ${H} L0 ${yAt(0).toFixed(1)}`;
  for (let x = 8; x <= W; x += 8) d += ` L${x} ${yAt(x).toFixed(1)}`;
  d += ` L${W} ${H} Z`;
  return { path: d, yAt };
}

/** Pins en silhouette posés sur une crête. */
export function pines(seed: number, line: Ridge, count: number, scale = 1): string {
  const r = rng(seed);
  let d = '';
  for (let i = 0; i < count; i++) {
    const x = r() * W;
    const y = line.yAt(x) + 6;
    const h = (40 + r() * 70) * scale;
    const w = h * (0.32 + r() * 0.1);
    for (let k = 0; k < 3; k++) {
      const top = y - h + k * h * 0.22;
      const half = (w / 2) * (0.6 + k * 0.25);
      d += `M${(x - half).toFixed(1)} ${(top + h * 0.42).toFixed(1)} L${x.toFixed(1)} ${top.toFixed(1)} L${(x + half).toFixed(1)} ${(top + h * 0.42).toFixed(1)} Z `;
    }
    d += `M${x - 2} ${y} L${x - 2} ${y - h * 0.2} L${x + 2} ${y - h * 0.2} L${x + 2} ${y} Z `;
  }
  return d;
}

export interface Star {
  x: number;
  y: number;
  r: number;
  twinkle: boolean;
  delay: number;
}

export function stars(seed: number, count: number, maxY = 480): Star[] {
  const r = rng(seed);
  return Array.from({ length: count }, () => ({
    x: r() * W,
    y: r() * maxY,
    r: r() * 1.4 + 0.3,
    twinkle: r() < 0.35,
    delay: r() * 6,
  }));
}

export interface House {
  body: string;
  roof: string;
  windows: { x: number; y: number; w: number; h: number }[];
}

/** Rangée de maisons japonaises (toits à avant-toits relevés). */
export function village(seed: number, baseY: number, from = 0, to = W, scale = 1): House[] {
  const r = rng(seed);
  const houses: House[] = [];
  let x = from - 20;
  while (x < to) {
    const w = (70 + r() * 70) * scale;
    const h = (46 + r() * 50) * scale;
    const top = baseY - h;
    const eave = 14 * scale;
    const rise = (20 + r() * 12) * scale;
    houses.push({
      body: `M${x} ${baseY} L${x} ${top} L${x + w} ${top} L${x + w} ${baseY} Z`,
      roof: `M${x - eave} ${top + 4} Q${x + w * 0.1} ${top - 2} ${x + w * 0.22} ${top - rise} L${x + w * 0.78} ${top - rise} Q${x + w * 0.9} ${top - 2} ${x + w + eave} ${top + 4} Z`,
      windows: Array.from({ length: 1 + Math.floor(r() * 3) }, (_, i) => ({
        x: x + 10 * scale + i * 22 * scale,
        y: top + h * 0.35,
        w: 12 * scale,
        h: 16 * scale,
      })).filter((wd) => wd.x + wd.w < x + w - 6),
    });
    x += w + (8 + r() * 30) * scale;
  }
  return houses;
}

/** Pagode à plusieurs niveaux. */
export function pagoda(cx: number, baseY: number, tiers = 5, scale = 1): string {
  let d = '';
  let y = baseY;
  for (let i = 0; i < tiers; i++) {
    const w = (120 - i * 16) * scale;
    const h = (34 - i * 2) * scale;
    d += `M${cx - w / 2 + 10} ${y} L${cx - w / 2 + 10} ${y - h} L${cx + w / 2 - 10} ${y - h} L${cx + w / 2 - 10} ${y} Z `;
    const ry = y - h;
    const ew = w / 2 + 22 * scale;
    d += `M${cx - ew} ${ry + 6} Q${cx - w / 2} ${ry - 2} ${cx - w / 2 + 14} ${ry - 16 * scale} L${cx + w / 2 - 14} ${ry - 16 * scale} Q${cx + w / 2} ${ry - 2} ${cx + ew} ${ry + 6} Z `;
    y = ry - 16 * scale;
  }
  d += `M${cx - 2} ${y} L${cx - 2} ${y - 50 * scale} L${cx + 2} ${y - 50 * scale} L${cx + 2} ${y} Z`;
  return d;
}

export interface Stalk {
  x: number;
  w: number;
  nodes: number[];
  lean: number;
}

export function bamboo(seed: number, count: number, wMin: number, wMax: number): Stalk[] {
  const r = rng(seed);
  return Array.from({ length: count }, () => {
    const nodes: number[] = [];
    for (let y = H - 40 - r() * 60; y > -40; y -= 70 + r() * 50) nodes.push(y);
    return { x: r() * W, w: wMin + r() * (wMax - wMin), nodes, lean: (r() - 0.5) * 40 };
  });
}

/** Silhouette d'un torii. */
export function torii(cx: number, baseY: number, s = 1): string {
  const pw = 22 * s;
  const span = 300 * s;
  const h = 330 * s;
  const left = cx - span / 2;
  const right = cx + span / 2;
  const top = baseY - h;
  return [
    // piliers légèrement inclinés
    `M${left - pw / 2} ${baseY} L${left + 6 * s - pw / 2} ${top + 40 * s} L${left + 6 * s + pw / 2} ${top + 40 * s} L${left + pw / 2} ${baseY} Z`,
    `M${right - pw / 2} ${baseY} L${right - 6 * s - pw / 2} ${top + 40 * s} L${right - 6 * s + pw / 2} ${top + 40 * s} L${right + pw / 2} ${baseY} Z`,
    // kasagi (linteau supérieur courbé)
    `M${left - 70 * s} ${top + 8 * s} Q${cx} ${top + 28 * s} ${right + 70 * s} ${top + 8 * s} L${right + 62 * s} ${top + 30 * s} Q${cx} ${top + 46 * s} ${left - 62 * s} ${top + 30 * s} Z`,
    // shimaki
    `M${left - 40 * s} ${top + 40 * s} L${right + 40 * s} ${top + 40 * s} L${right + 36 * s} ${top + 56 * s} L${left - 36 * s} ${top + 56 * s} Z`,
    // nuki (traverse)
    `M${left - 34 * s} ${top + 112 * s} L${right + 34 * s} ${top + 112 * s} L${right + 34 * s} ${top + 130 * s} L${left - 34 * s} ${top + 130 * s} Z`,
    // gakuzuka (plaque centrale)
    `M${cx - 9 * s} ${top + 56 * s} L${cx + 9 * s} ${top + 56 * s} L${cx + 9 * s} ${top + 112 * s} L${cx - 9 * s} ${top + 112 * s} Z`,
  ].join(' ');
}
