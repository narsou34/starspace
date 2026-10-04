#!/usr/bin/env python3
"""
Génère les textures "anime" des VFX (RGBA, PNG) pour Demon Slayer RP.
Convention des croissants (Slash_*) : image carrée, centre = lanceur,
l'arc occupe la moitié +U (droite de l'image), de -90° (bas) à +90° (haut) ;
il est plus épais vers +60° (bord d'attaque) et s'effile vers -90° (queue).
"""
import sys, os, math
import numpy as np
from PIL import Image, ImageFilter
from scipy.ndimage import zoom, gaussian_filter

OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), '..', 'Client', 'Textures')
os.makedirs(OUT, exist_ok=True)
N = 512
rng = np.random.default_rng(7)

yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
X = (xx - N / 2) / (N / 2)            # -1..1 (droite = +)
Y = (N / 2 - yy) / (N / 2)            # -1..1 (haut = +)
R = np.sqrt(X * X + Y * Y)
A = np.degrees(np.arctan2(Y, X))      # -180..180, 0 = droite

def noise(scale, seed, octaves=4):
    r = np.random.default_rng(seed)
    out = np.zeros((N, N), np.float32); amp = 1; tot = 0
    for o in range(octaves):
        s = max(2, int(scale * 2 ** o))
        g = r.random((s + 1, s + 1)).astype(np.float32)
        z = zoom(g, (N / s), order=3)[:N, :N]
        out += z * amp; tot += amp; amp *= 0.5
    return out / tot

def ss(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0 + 1e-9), 0, 1)
    return t * t * (3 - 2 * t)

def ramp(t, stops):
    """stops : [(pos, (r,g,b)), ...] -> image RGB"""
    t = np.clip(t, 0, 1)
    out = np.zeros(t.shape + (3,), np.float32)
    for i in range(len(stops) - 1):
        p0, c0 = stops[i]; p1, c1 = stops[i + 1]
        m = (t >= p0) & (t <= p1)
        k = ((t - p0) / (p1 - p0 + 1e-9))[..., None]
        out[m] = (np.array(c0) * (1 - k) + np.array(c1) * k)[m]
    return out

def save(name, rgb, alpha, blur=0.6):
    alpha = np.clip(alpha, 0, 1)
    if blur: alpha = gaussian_filter(alpha, blur)
    img = np.dstack([np.clip(rgb, 0, 1), alpha])
    Image.fromarray((img * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, name + ".png"), optimize=True)

def hexc(h):
    h = h.lstrip("#"); return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))

# ---------------------------------------------------------------------------
# Croissant de base : renvoie (masque, u = position le long de l'arc 0..1,
# v = position dans l'épaisseur 0 (intérieur) .. 1 (extérieur))
# ---------------------------------------------------------------------------
def crescent(r_in=0.55, r_out=0.92, a0=-95, a1=95, peak=0.75, wobble=None):
    u = np.clip((A - a0) / (a1 - a0), 0, 1)
    inside = (A >= a0) & (A <= a1) & (X > -0.05)
    prof = np.sin(np.pi * np.clip(u, 0, 1) ** (math.log(0.5) / math.log(peak)))  # épaisseur max à `peak`
    thick = (r_out - r_in) * prof
    outer = r_out + (wobble if wobble is not None else 0)
    inner = outer - thick
    v = np.clip((R - inner) / (thick + 1e-6), 0, 1)
    m = inside * ss(inner - 0.012, inner + 0.012, R) * (1 - ss(outer - 0.012, outer + 0.012, R))
    return m.astype(np.float32), u.astype(np.float32), v.astype(np.float32), prof

# ===========================================================================
# 1. Croissants par élément
# ===========================================================================
def slash_water():
    n = noise(6, 1)
    wob = (np.sin(np.radians(A) * 9) * 0.015 + (n - 0.5) * 0.04)
    m, u, v, prof = crescent(0.5, 0.93, wobble=wob)
    # bandes d'écoulement ukiyo-e (lignes parallèles à l'arc)
    stripes = 0.5 + 0.5 * np.sin((R * 70) + n * 6)
    body = ramp(v, [(0, hexc("ffffff")), (0.18, hexc("bfefff")), (0.45, hexc("3fb5ff")), (0.8, hexc("1557d6")), (1, hexc("0a2f8f"))])
    body = body * (0.85 + 0.15 * stripes[..., None])
    # écume : boucles blanches sur le bord extérieur
    foam = np.zeros((N, N), np.float32)
    for k in range(9):
        ang = -70 + k * 19 + rng.uniform(-4, 4)
        rr = 0.86 + 0.03 * math.sin(k)
        cx, cy = rr * math.cos(math.radians(ang)), rr * math.sin(math.radians(ang))
        d = np.sqrt((X - cx) ** 2 + (Y - cy) ** 2)
        size = 0.035 + 0.03 * math.sin(math.pi * (k + 1) / 10)
        ring = np.exp(-((d - size) / 0.008) ** 2) * (np.degrees(np.arctan2(Y - cy, X - cx)) % 360 < 290)
        foam = np.maximum(foam, ring)
    rgb = body * (1 - foam[..., None]) + foam[..., None]
    alpha = np.maximum(m * (0.55 + 0.45 * (1 - v) + 0.2), foam * (A > -95) * (A < 95)) 
    # contour sombre (style trait d'encre)
    edge = m * ss(0.82, 1.0, v) * 0.9
    rgb = rgb * (1 - edge[..., None] * 0.55)
    save("Slash_Water", rgb, np.clip(alpha, 0, 1))

def slash_flame():
    n = noise(5, 2); n2 = noise(12, 3)
    tongues = (np.maximum(0, np.sin(np.radians(A) * 14 + n * 5)) ** 2) * 0.12 + (n2 - 0.5) * 0.05
    m, u, v, prof = crescent(0.5, 0.86, wobble=tongues)
    rgb = ramp(1 - v + (n2 - 0.5) * 0.3, [(0, hexc("7a0a00")), (0.25, hexc("e02d00")), (0.55, hexc("ff8a00")), (0.8, hexc("ffd34d")), (1, hexc("fffbe6"))])
    alpha = m * (0.6 + 0.4 * (1 - v)) * (0.75 + 0.25 * n2)
    save("Slash_Flame", rgb, alpha)

def slash_sun():
    n = noise(5, 12); n2 = noise(10, 13)
    tongues = (np.maximum(0, np.sin(np.radians(A) * 10 + n * 4)) ** 3) * 0.1
    m, u, v, prof = crescent(0.48, 0.88, wobble=tongues)
    rgb = ramp(1 - v + (n2 - 0.5) * 0.2, [(0, hexc("8a1c00")), (0.3, hexc("ff5a00")), (0.6, hexc("ffb000")), (0.85, hexc("fff0a0")), (1, hexc("ffffff"))])
    ring = np.exp(-((R - 0.5) / 0.01) ** 2) * (A > -90) * (A < 90)
    rgb = rgb * (1 - ring[..., None]) + ring[..., None] * np.array(hexc("ffe680"))
    save("Slash_Sun", rgb, np.maximum(m * (0.65 + 0.35 * (1 - v)), ring * 0.9))

def bolt_mask(points, width, jag=0.0):
    out = np.zeros((N, N), np.float32)
    for (x0, y0), (x1, y1) in zip(points[:-1], points[1:]):
        dx, dy = x1 - x0, y1 - y0
        L2 = dx * dx + dy * dy + 1e-9
        t = np.clip(((X - x0) * dx + (Y - y0) * dy) / L2, 0, 1)
        d = np.sqrt((X - (x0 + dx * t)) ** 2 + (Y - (y0 + dy * t)) ** 2)
        out = np.maximum(out, np.exp(-(d / width) ** 2))
    return out

def jagged(p0, p1, segs, amp, seed):
    r = np.random.default_rng(seed)
    pts = []
    for i in range(segs + 1):
        t = i / segs
        x = p0[0] + (p1[0] - p0[0]) * t; y = p0[1] + (p1[1] - p0[1]) * t
        if 0 < i < segs:
            nx, ny = -(p1[1] - p0[1]), (p1[0] - p0[0]); l = math.hypot(nx, ny) + 1e-9
            o = r.uniform(-amp, amp); x += nx / l * o; y += ny / l * o
        pts.append((x, y))
    return pts

def slash_thunder():
    core = np.zeros((N, N), np.float32); glow = np.zeros((N, N), np.float32)
    for k, rr in enumerate([0.62, 0.74, 0.86]):
        pts = []
        for i in range(19):
            ang = -85 + i * 10 + rng.uniform(-3, 3)
            r = rr + rng.uniform(-0.05, 0.05)
            pts.append((r * math.cos(math.radians(ang)), r * math.sin(math.radians(ang))))
        w = 0.008 + 0.006 * (k == 1)
        core = np.maximum(core, bolt_mask(pts, w))
        glow = np.maximum(glow, bolt_mask(pts, w * 5) * 0.6)
        # branches
        for j in range(3):
            i = rng.integers(3, 16); (bx, by) = pts[i]
            ex, ey = bx * 1.15 + rng.uniform(-.08, .08), by * 1.15 + rng.uniform(-.08, .08)
            br = jagged((bx, by), (ex, ey), 4, 0.03, 100 + k * 10 + j)
            core = np.maximum(core, bolt_mask(br, 0.005) * 0.9)
            glow = np.maximum(glow, bolt_mask(br, 0.025) * 0.4)
    rgb = ramp(core, [(0, hexc("ffb800")), (0.5, hexc("ffe95c")), (1, hexc("ffffff"))])
    save("Slash_Thunder", rgb, np.maximum(core, glow), blur=0.4)

def slash_wind():
    n = noise(8, 4)
    a = np.zeros((N, N), np.float32)
    for k in range(7):
        r0 = 0.55 + k * 0.055
        a0 = -80 + rng.uniform(0, 40); a1 = 90 - rng.uniform(0, 50)
        w = 0.006 + 0.004 * rng.random()
        band = np.exp(-((R - r0 - (n - 0.5) * 0.02) / w) ** 2) * (A > a0) * (A < a1)
        fade = ss(a0, a0 + 40, A) * (1 - ss(a1 - 10, a1, A))
        a = np.maximum(a, band * fade)
    rgb = ramp(a, [(0, hexc("5fe3b0")), (0.6, hexc("c8ffe8")), (1, hexc("ffffff"))])
    save("Slash_Wind", rgb, a * 0.95, blur=0.5)

def slash_mist():
    n = noise(4, 5, 5)
    m, u, v, prof = crescent(0.45, 0.95)
    soft = gaussian_filter(m, 10) * (0.5 + 0.8 * n)
    rgb = ramp(n, [(0, hexc("aab4c2")), (0.6, hexc("dfe6ee")), (1, hexc("ffffff"))])
    save("Slash_Mist", rgb, np.clip(soft * 1.2, 0, 0.85), blur=2)

def slash_ice():
    m, u, v, prof = crescent(0.55, 0.85)
    spikes = np.zeros((N, N), np.float32)
    for k in range(14):
        ang = -80 + k * 12 + rng.uniform(-3, 3)
        base = 0.8; L = 0.08 + 0.1 * rng.random()
        ca, sa = math.cos(math.radians(ang)), math.sin(math.radians(ang))
        # triangle : distance au segment radial, largeur décroissante
        t = np.clip(((X - base * ca) * ca + (Y - base * sa) * sa) / L, 0, 1)
        d = np.abs(-(X - base * ca) * sa + (Y - base * sa) * ca)
        spikes = np.maximum(spikes, (d < 0.025 * (1 - t)) * (((X - base * ca) * ca + (Y - base * sa) * sa) > 0) * (t < 1))
    mm = np.maximum(m, spikes.astype(np.float32))
    facets = noise(10, 6, 1)
    rgb = ramp(1 - v * 0.8 + (facets - 0.5) * 0.5, [(0, hexc("2a7bd6")), (0.4, hexc("8fd8ff")), (0.8, hexc("e6fbff")), (1, hexc("ffffff"))])
    save("Slash_Ice", rgb, mm * 0.92)

def slash_blood():
    n = noise(6, 7)
    m, u, v, prof = crescent(0.55, 0.88, wobble=(n - 0.5) * 0.05)
    drops = np.zeros((N, N), np.float32)
    for k in range(25):
        ang = rng.uniform(-80, 80); r = rng.uniform(0.9, 1.0); s = rng.uniform(0.008, 0.02)
        cx, cy = r * math.cos(math.radians(ang)), r * math.sin(math.radians(ang))
        drops = np.maximum(drops, ((X - cx) ** 2 + (Y - cy) ** 2 < s * s).astype(np.float32))
    rgb = ramp(1 - v, [(0, hexc("3d0006")), (0.4, hexc("a3000f")), (0.8, hexc("ff2a3a")), (1, hexc("ffd0d4"))])
    save("Slash_Blood", rgb, np.maximum(m * 0.95, drops))

def slash_shadow():
    n = noise(5, 8)
    m, u, v, prof = crescent(0.5, 0.9, wobble=(n - 0.5) * 0.08)
    wisps = gaussian_filter(m, 6) * (n > 0.45)
    rgb = ramp(v + (n - 0.5) * 0.4, [(0, hexc("d9a6ff")), (0.25, hexc("8a2be2")), (0.6, hexc("2b0a45")), (1, hexc("050008"))])
    save("Slash_Shadow", rgb, np.clip(np.maximum(m * 0.95, wisps * 0.8), 0, 1))

def petal_mask(cx, cy, ang, L, W):
    ca, sa = math.cos(ang), math.sin(ang)
    lx = (X - cx) * ca + (Y - cy) * sa; ly = -(X - cx) * sa + (Y - cy) * ca
    t = np.clip(lx / L, 0, 1)
    w = W * np.sin(np.pi * t) ** 0.7 * (1 - 0.35 * (t > 0.85) * (np.abs(ly) < W * 0.15))
    return ((lx > 0) & (lx < L) & (np.abs(ly) < w)).astype(np.float32), t

def slash_flower():
    m, u, v, prof = crescent(0.6, 0.82)
    pet = np.zeros((N, N), np.float32); col = np.zeros((N, N), np.float32)
    for k in range(26):
        ang = math.radians(rng.uniform(-85, 85)); r = rng.uniform(0.6, 0.98)
        pm, t = petal_mask(r * math.cos(ang), r * math.sin(ang), rng.uniform(0, 6.28), 0.07, 0.03)
        pet = np.maximum(pet, pm); col = np.where(pm > 0, t, col)
    rgb = ramp(np.maximum(col, (1 - v) * m), [(0, hexc("ff4f9a")), (0.5, hexc("ff9cc8")), (1, hexc("fff0f6"))])
    save("Slash_Flower", rgb, np.maximum(m * 0.75, pet))

def slash_sound():
    a = np.zeros((N, N), np.float32); c = np.zeros((N, N), np.float32)
    for k in range(5):
        r0 = 0.55 + k * 0.08
        band = np.exp(-((R - r0) / 0.012) ** 2) * (A > -85 + k * 6) * (A < 85 - k * 6)
        a = np.maximum(a, band); c = np.where(band > 0.3, k / 4, c)
    m, u, v, prof = crescent(0.55, 0.9)
    rgb = ramp(c, [(0, hexc("ffd84d")), (0.5, hexc("ff4fd8")), (1, hexc("8a3bff"))])
    save("Slash_Sound", rgb, np.maximum(a, m * 0.35))

def slash_love():
    n = noise(6, 9)
    m, u, v, prof = crescent(0.55, 0.9, wobble=np.sin(np.radians(A) * 6) * 0.03)
    rgb = ramp(1 - v + (n - 0.5) * 0.2, [(0, hexc("c2185b")), (0.5, hexc("ff6fb1")), (0.9, hexc("ffd1e8")), (1, hexc("ffffff"))])
    save("Slash_Love", rgb, m * 0.92)

def slash_insect():
    m, u, v, prof = crescent(0.6, 0.86)
    veins = (np.abs(np.sin(np.radians(A) * 24)) < 0.08) * m
    rgb = ramp(1 - v, [(0, hexc("6a3ccf")), (0.5, hexc("b48cff")), (1, hexc("f3e9ff"))])
    rgb = rgb * (1 - veins[..., None] * 0.6)
    save("Slash_Insect", rgb, m * 0.9)

def slash_serpent():
    n = noise(8, 10)
    wob = np.sin(np.radians(A) * 5) * 0.06
    m, u, v, prof = crescent(0.58, 0.82, wobble=wob)
    scales = (np.sin(R * 120) * np.sin(np.radians(A) * 60) > 0.6) * m
    rgb = ramp(1 - v, [(0, hexc("4b2a7a")), (0.5, hexc("a983e0")), (1, hexc("f1e6ff"))])
    rgb = rgb * (1 - scales[..., None] * 0.3)
    save("Slash_Serpent", rgb, m * 0.92)

def slash_stone():
    n = noise(6, 11, 2)
    m, u, v, prof = crescent(0.55, 0.9, wobble=(np.round(n * 6) / 6 - 0.5) * 0.06)
    rgb = ramp(1 - v + (n - 0.5) * 0.5, [(0, hexc("3b342c")), (0.5, hexc("8a7d6b")), (0.9, hexc("d9cfbf")), (1, hexc("fff4d6"))])
    save("Slash_Stone", rgb, m)

def slash_beast():
    a = np.zeros((N, N), np.float32)
    for k, r0 in enumerate([0.62, 0.74, 0.86]):
        m, u, v, prof = crescent(r0 - 0.06, r0, a0=-80 + k * 8, a1=85 - k * 5)
        a = np.maximum(a, m)
    rgb = ramp(a, [(0, hexc("6c8fb5")), (1, hexc("e6f2ff"))])
    save("Slash_Beast", rgb, a)

def slash_white():
    m, u, v, prof = crescent(0.55, 0.9)
    rgb = ramp(1 - v, [(0, (0.75, 0.75, 0.75)), (1, (1, 1, 1))])
    save("Slash_Neutral", rgb, m * (0.6 + 0.4 * (1 - v)))

# ===========================================================================
# 2. Formes
# ===========================================================================
def wave_curl():
    """Vague ukiyo-e vue de côté : base à gauche, crête qui s'enroule vers la droite."""
    n = noise(6, 20)
    xs = (X + 1) / 2  # 0..1
    crest = 0.05 + 0.75 * ss(0.0, 0.75, xs) - 0.25 * ss(0.8, 1.0, xs)
    body = (Y + 1) / 2 < crest + (n - 0.5) * 0.04
    # boucle d'enroulement
    cx, cy, cr = 0.55, 0.45, 0.32
    d = np.sqrt((X - cx) ** 2 + (Y - cy) ** 2)
    hole = (d < cr) & (Y < 0.65) & (X > 0.25)
    curl = (d > cr - 0.12) & (d < cr + 0.02) & (np.degrees(np.arctan2(Y - cy, X - cx)) > -40)
    m = (body & ~hole) | curl
    m = m & (X > -0.98)
    m = m.astype(np.float32)
    h = (Y + 1) / 2
    rgb = ramp(h + (n - 0.5) * 0.2, [(0, hexc("08246b")), (0.35, hexc("1455c9")), (0.7, hexc("3fb5ff")), (0.9, hexc("c9f2ff")), (1, hexc("ffffff"))])
    stripes = (np.sin((Y * 40) + X * 8 + n * 8) > 0.75)
    rgb = rgb * (1 - 0.18 * stripes[..., None])
    # écume : doigts blancs sur la crête
    foam = np.zeros((N, N), np.float32)
    for k in range(14):
        t = rng.uniform(0.25, 0.95)
        fx = t * 2 - 1; fy = (0.05 + 0.75 * ss(0, 0.75, t) - 0.25 * ss(0.8, 1, t)) * 2 - 1
        d2 = np.sqrt((X - fx) ** 2 + (Y - fy) ** 2)
        foam = np.maximum(foam, (d2 < rng.uniform(0.02, 0.05)).astype(np.float32))
    edge = gaussian_filter(m, 3); edge = m * (edge < 0.85)
    rgb = rgb * (1 - foam[..., None]) + foam[..., None]
    rgb = rgb * (1 - edge[..., None] * 0.5)
    save("Wave_Curl", rgb, np.maximum(m, foam))

def ring(name, width, color_in, color_out, broken=False, seed=21):
    n = noise(10, seed)
    a = np.exp(-((R - 0.8) / width) ** 2)
    if broken: a = a * (n > 0.4)
    inner = np.exp(-((R - 0.8) / (width * 3)) ** 2) * 0.35
    rgb = ramp(np.clip((R - 0.6) / 0.35, 0, 1), [(0, hexc(color_in)), (1, hexc(color_out))])
    save(name, rgb, np.maximum(a, inner))

def spiral(name, arms, color_in, color_out, tight=3.0, seed=22):
    n = noise(6, seed)
    theta = np.arctan2(Y, X)
    s = np.sin(arms * theta + tight * np.log(R + 1e-3) * 4 + n * 2)
    a = ss(0.2, 0.9, s) * ss(0.05, 0.2, R) * (1 - ss(0.85, 1.0, R))
    rgb = ramp(R, [(0, hexc(color_in)), (1, hexc(color_out))])
    save(name, rgb, a * 0.9)

def impact_star(name, spikes, color, seed=23):
    r = np.random.default_rng(seed)
    theta = np.arctan2(Y, X)
    lens = r.uniform(0.45, 1.0, spikes)
    idx = ((theta + np.pi) / (2 * np.pi) * spikes).astype(int) % spikes
    frac = ((theta + np.pi) / (2 * np.pi) * spikes) % 1
    tri = 1 - np.abs(frac - 0.5) * 2
    limit = 0.18 + (lens[idx] - 0.18) * tri ** 2.5
    m = (R < limit).astype(np.float32)
    core = 1 - ss(0.05, 0.35, R)
    rgb = ramp(core, [(0, hexc(color)), (1, (1, 1, 1))])
    save(name, rgb, m)

def soft_orb(name, c_core, c_edge):
    a = (1 - ss(0.0, 1.0, R)) ** 1.6
    rgb = ramp(1 - R, [(0, hexc(c_edge)), (0.7, hexc(c_core)), (1, (1, 1, 1))])
    save(name, rgb, a, blur=0)

def fireball():
    n = noise(5, 30)
    rr = R + (n - 0.5) * 0.35 + np.maximum(0, -Y) * 0.0 - np.maximum(0, Y) * 0.25 * n
    a = 1 - ss(0.45, 0.8, rr)
    rgb = ramp(1 - rr, [(0, hexc("b31600")), (0.3, hexc("ff6a00")), (0.6, hexc("ffc93d")), (1, hexc("ffffff"))])
    save("Fire_Ball", rgb, a)

def flame_tongue():
    n = noise(4, 31); n2 = noise(9, 32)
    xs = X + (n - 0.5) * 0.35 * ((Y + 1) / 2)
    width = 0.55 * (1 - (Y + 1) / 2) ** 0.8
    m = (np.abs(xs) < width) & (Y > -0.95)
    m = m.astype(np.float32) * (0.6 + 0.4 * n2)
    t = 1 - np.abs(xs) / (width + 1e-3)
    rgb = ramp(t * (1 - (Y + 1) / 2 * 0.6), [(0, hexc("c21a00")), (0.35, hexc("ff6a00")), (0.7, hexc("ffd34d")), (1, hexc("ffffff"))])
    save("Fire_Tongue", rgb, m * ss(-1, -0.8, Y))

def bolt_sprite():
    core = np.zeros((N, N), np.float32); glow = np.zeros((N, N), np.float32)
    pts = jagged((0, 0.98), (0, -0.98), 12, 0.25, 40)
    core = np.maximum(core, bolt_mask(pts, 0.018)); glow = np.maximum(glow, bolt_mask(pts, 0.09) * 0.55)
    for j in range(4):
        i = rng.integers(2, 10); bx, by = pts[i]
        br = jagged((bx, by), (bx + rng.uniform(-0.6, 0.6), by - rng.uniform(0.2, 0.5)), 5, 0.08, 50 + j)
        core = np.maximum(core, bolt_mask(br, 0.01)); glow = np.maximum(glow, bolt_mask(br, 0.05) * 0.4)
    rgb = ramp(core, [(0, hexc("ffc400")), (0.5, hexc("fff176")), (1, (1, 1, 1))])
    save("Bolt", rgb, np.maximum(core, glow), blur=0.4)

def cloud():
    n = noise(3, 41, 5)
    a = (1 - ss(0.3, 1.0, R + (n - 0.5) * 0.6)) * (0.6 + 0.4 * n)
    rgb = ramp(n, [(0, hexc("b7c2cf")), (1, (1, 1, 1))])
    save("Cloud", rgb, a * 0.9, blur=2)

def ink_splash():
    n = noise(5, 42)
    theta = np.arctan2(Y, X)
    arms = 0.45 + 0.4 * np.maximum(0, np.sin(theta * 7 + n * 3)) ** 3 + (n - 0.5) * 0.2
    m = (R < arms).astype(np.float32)
    drops = np.zeros((N, N), np.float32)
    for k in range(16):
        ang = rng.uniform(0, 6.28); r = rng.uniform(0.75, 0.95); s = rng.uniform(0.02, 0.05)
        drops = np.maximum(drops, ((X - r * math.cos(ang)) ** 2 + (Y - r * math.sin(ang)) ** 2 < s * s).astype(np.float32))
    rgb = ramp(R, [(0, hexc("120020")), (0.6, hexc("3a0b5e")), (1, hexc("9b4dff"))])
    save("Ink_Splash", rgb, np.maximum(m, drops))

def water_splash():
    n = noise(6, 43)
    theta = np.degrees(np.arctan2(Y, X))
    crown = (Y > -0.6) & (np.abs(X) < 0.9)
    spikes = 0.15 + 0.7 * np.maximum(0, np.sin(np.radians(X * 360 * 1.6) + n * 2)) ** 2
    h = (Y + 0.6)
    m = crown & (h < spikes * (1 - np.abs(X) ** 2) + 0.15)
    m = m.astype(np.float32)
    drops = np.zeros((N, N), np.float32)
    for k in range(18):
        x = rng.uniform(-0.8, 0.8); y = rng.uniform(0.2, 0.95); s = rng.uniform(0.015, 0.04)
        drops = np.maximum(drops, ((X - x) ** 2 + ((Y - y) * 0.7) ** 2 < s * s).astype(np.float32))
    rgb = ramp((Y + 1) / 2, [(0, hexc("1455c9")), (0.5, hexc("5fd0ff")), (1, (1, 1, 1))])
    save("Water_Splash", rgb, np.maximum(m * 0.95, drops))

def petal_sprite():
    pm, t = petal_mask(-0.8, 0, 0, 1.6, 0.55)
    rgb = ramp(t, [(0, hexc("ff3d8b")), (0.6, hexc("ff9cc8")), (1, hexc("fff0f6"))])
    save("Petal", rgb, pm)

def flower_bloom():
    theta = np.arctan2(Y, X)
    petals = 0.35 + 0.55 * np.abs(np.cos(theta * 2.5)) ** 0.8
    m = (R < petals).astype(np.float32)
    rgb = ramp(R / petals, [(0, hexc("ffe066")), (0.25, hexc("ff4f9a")), (0.8, hexc("ff9cc8")), (1, hexc("ffe1ee"))])
    edge = (R > petals - 0.04) & (R < petals)
    rgb = rgb * (1 - edge[..., None] * 0.35)
    save("Flower_Bloom", rgb, m)

def ice_crystal():
    a = np.zeros((N, N), np.float32)
    for k in range(6):
        ang = math.radians(k * 60)
        ca, sa = math.cos(ang), math.sin(ang)
        lx = X * ca + Y * sa; ly = -X * sa + Y * ca
        a = np.maximum(a, ((lx > 0) & (lx < 0.95) & (np.abs(ly) < 0.09 * (1 - lx))).astype(np.float32))
        for b in (0.4, 0.65):
            for s in (1, -1):
                bx, by = lx - b, ly
                ang2 = math.radians(50 * s)
                l2 = bx * math.cos(ang2) + by * math.sin(ang2)
                w2 = -bx * math.sin(ang2) + by * math.cos(ang2)
                a = np.maximum(a, ((l2 > 0) & (l2 < 0.25) & (np.abs(w2) < 0.04 * (1 - l2 / 0.25))).astype(np.float32))
    rgb = ramp(1 - R, [(0, hexc("5fb6ff")), (0.6, hexc("c9f0ff")), (1, (1, 1, 1))])
    save("Ice_Crystal", rgb, a)

def ice_shard():
    lx = (Y + 1) / 2
    w = 0.25 * (1 - lx) ** 0.9
    m = (np.abs(X) < w) & (lx < 0.98)
    facet = X > 0
    rgb = np.where(facet[..., None], np.array(hexc("bfefff")), np.array(hexc("5fb6ff")))
    rgb = rgb * (0.8 + 0.2 * lx[..., None]) + (np.abs(X) < 0.01)[..., None] * 0.3
    save("Ice_Shard", rgb, m.astype(np.float32))

def butterfly():
    theta = np.arctan2(Y, np.abs(X))
    upper = (R < 0.85 * (0.4 + 0.6 * np.abs(np.sin(theta * 1.0 + 0.6)))) & (Y > -0.05)
    lower = (R < 0.6 * (0.5 + 0.5 * np.abs(np.sin(theta)))) & (Y <= 0)
    m = (upper | lower) & (np.abs(X) > 0.03)
    body = (np.abs(X) < 0.035) & (np.abs(Y) < 0.45)
    rgb = ramp(R, [(0, hexc("2b1a5e")), (0.3, hexc("8f5bff")), (0.75, hexc("d9c2ff")), (1, (1, 1, 1))])
    veins = (np.abs(np.sin(theta * 8)) < 0.08) & m
    rgb = rgb * (1 - veins[..., None] * 0.5)
    rgb = np.where(body[..., None], np.array(hexc("1a1030")), rgb)
    save("Butterfly", rgb, (m | body).astype(np.float32))

def speed_lines():
    theta = np.degrees(np.arctan2(Y, X))
    r = np.random.default_rng(60)
    a = np.zeros((N, N), np.float32)
    for k in range(40):
        ang = r.uniform(-180, 180); w = r.uniform(0.4, 1.5); r0 = r.uniform(0.35, 0.7)
        a = np.maximum(a, (np.abs(theta - ang) < w) * ss(r0, r0 + 0.15, R) * (1 - ss(0.9, 1.0, R)))
    save("Speed_Lines", np.ones((N, N, 3)), a * 0.9, blur=0.5)

def tornado_band():
    n = noise(8, 61)
    a = np.zeros((N, N), np.float32)
    for k in range(9):
        y0 = rng.uniform(-0.9, 0.9); w = rng.uniform(0.01, 0.035)
        tilt = rng.uniform(0.15, 0.35)
        band = np.exp(-((Y - y0 - X * tilt + (n - 0.5) * 0.05) / w) ** 2)
        a = np.maximum(a, band * ss(-1, -0.6, X) * (1 - ss(0.6, 1, X)))
    rgb = ramp(a, [(0, (0.8, 0.8, 0.8)), (1, (1, 1, 1))])
    save("Swirl_Band", rgb, a)

def sigil():
    a = np.exp(-((R - 0.92) / 0.01) ** 2) + np.exp(-((R - 0.8) / 0.008) ** 2)
    theta = np.arctan2(Y, X)
    # étoile à 6 branches inscrite
    for k in range(6):
        a1 = math.radians(k * 60 + 90); a2 = math.radians(k * 60 + 90 + 120)
        p0 = (0.8 * math.cos(a1), 0.8 * math.sin(a1)); p1 = (0.8 * math.cos(a2), 0.8 * math.sin(a2))
        a = np.maximum(a, bolt_mask([p0, p1], 0.008))
    marks = (np.abs(np.sin(theta * 18)) > 0.92) * (R > 0.82) * (R < 0.9)
    a = np.clip(np.maximum(a, marks.astype(np.float32)), 0, 1)
    rgb = ramp(a, [(0, (0.85, 0.85, 0.85)), (1, (1, 1, 1))])
    save("Sigil", rgb, a)

def leaf_debris():
    pm, t = petal_mask(-0.85, 0, 0.2, 1.7, 0.4)
    rgb = ramp(t, [(0, hexc("3f8f5a")), (1, hexc("b8f5c8"))])
    save("Leaf", rgb, pm)

def rock_chunk():
    n = noise(3, 70, 2)
    theta = np.arctan2(Y, X)
    poly = 0.65 + 0.2 * np.round(np.sin(theta * 3 + 1) * 2) / 2 + (n - 0.5) * 0.2
    m = (R < poly).astype(np.float32)
    rgb = ramp(n + (Y + 1) / 4, [(0, hexc("3b342c")), (0.6, hexc("8a7d6b")), (1, hexc("d9cfbf"))])
    save("Rock", rgb, m)

def blood_splat():
    n = noise(6, 71)
    theta = np.arctan2(Y, X)
    arms = 0.4 + 0.45 * np.maximum(0, np.sin(theta * 9 + n * 4)) ** 4 + (n - 0.5) * 0.15
    m = (R < arms).astype(np.float32)
    rgb = ramp(R / 0.8, [(0, hexc("ff2a3a")), (0.6, hexc("a3000f")), (1, hexc("3d0006"))])
    save("Blood_Splat", rgb, m)

def sound_wave():
    theta = np.degrees(np.arctan2(Y, X))
    a = np.zeros((N, N), np.float32)
    for k in range(4):
        r0 = 0.3 + k * 0.18
        a = np.maximum(a, np.exp(-((R - r0) / 0.02) ** 2) * (np.abs(theta) < 55 - k * 5))
    rgb = ramp(R, [(0, hexc("fff176")), (0.5, hexc("ff4fd8")), (1, hexc("8a3bff"))])
    save("Sound_Wave", rgb, a)

# ---- versions améliorées ----
from scipy.ndimage import map_coordinates
from PIL import ImageDraw

def polar_noise(ka, kr, seed, octaves=4, stretch=1.0):
    """Bruit échantillonné en coordonnées polaires : traînées qui suivent l'arc."""
    base = noise(8, seed, octaves)
    th = (A + 180) / 360  # 0..1
    cu = (th * ka * N) % N
    cr = (R * kr * N / stretch) % N
    return map_coordinates(base, [cr, cu], order=1, mode="wrap").astype(np.float32)

def glow(mask, radius, strength):
    return np.clip(gaussian_filter(mask, radius) * strength, 0, 1)

def crescent2(r_in, r_out, a0=-115, a1=100, peak=0.78, wobble=0):
    return crescent(r_in, r_out, a0, a1, peak, wobble)

def slash_water():
    flow = polar_noise(3, 1.2, 101)
    wob = (flow - 0.5) * 0.06
    m, u, v, prof = crescent2(0.42, 0.95, wobble=wob)
    streak = polar_noise(6, 9, 102, 2)
    lines = (streak > 0.62) * m * ss(0.15, 0.6, v)
    body = ramp(v + (flow - 0.5) * 0.25, [(0, hexc("ffffff")), (0.15, hexc("c9f4ff")), (0.4, hexc("4cc3ff")), (0.75, hexc("1660e0")), (1, hexc("0a2a85"))])
    body = body * (1 - lines[..., None] * 0.35) + lines[..., None] * np.array(hexc("ffffff")) * 0.35
    foam = np.zeros((N, N), np.float32)
    for k in range(12):
        ang = -95 + k * 16 + rng.uniform(-4, 4)
        rr = 0.9 + 0.04 * math.sin(k * 1.7)
        cx, cy = rr * math.cos(math.radians(ang)), rr * math.sin(math.radians(ang))
        d = np.sqrt((X - cx) ** 2 + (Y - cy) ** 2)
        size = 0.03 + 0.035 * math.sin(math.pi * (k + 1) / 13)
        ang_rel = (np.degrees(np.arctan2(Y - cy, X - cx)) - ang) % 360
        ring = np.exp(-((d - size) / 0.009) ** 2) * (ang_rel < 280)
        foam = np.maximum(foam, ring)
    edge = m * ss(0.85, 1.0, v)
    rgb = body * (1 - edge[..., None] * 0.45)
    rgb = rgb * (1 - foam[..., None]) + foam[..., None]
    halo = glow(m, 9, 0.5) * (1 - m)
    rgb = np.where((m > 0.01)[..., None] | (foam > 0.01)[..., None], rgb, np.array(hexc("7fd6ff")))
    alpha = np.maximum.reduce([m * (0.8 + 0.2 * (1 - v)), foam, halo])
    save("Slash_Water", rgb, alpha)

def slash_flame():
    licks = polar_noise(5, 2.5, 201, 4)
    fine = polar_noise(14, 6, 202, 2)
    wob = (np.maximum(0, licks - 0.45) ** 1.2) * 0.35
    m, u, v, prof = crescent2(0.45, 0.82, wobble=wob)
    soft = m * (0.55 + 0.45 * fine)
    heat = np.clip(1 - v + (fine - 0.5) * 0.35, 0, 1)
    rgb = ramp(heat, [(0, hexc("6b0800")), (0.2, hexc("d42000")), (0.45, hexc("ff6a00")), (0.7, hexc("ffb627")), (0.88, hexc("fff0a8")), (1, hexc("ffffff"))])
    halo = glow(m, 10, 0.45) * (1 - m)
    rgb = np.where((m > 0.01)[..., None], rgb, np.array(hexc("ff7a1a")))
    save("Slash_Flame", rgb, np.maximum(soft, halo))

def slash_sun():
    licks = polar_noise(4, 2, 211, 4)
    wob = (np.maximum(0, licks - 0.5) ** 1.3) * 0.25
    m, u, v, prof = crescent2(0.42, 0.86, wobble=wob)
    heat = np.clip(1 - v + (licks - 0.5) * 0.25, 0, 1)
    rgb = ramp(heat, [(0, hexc("8a1c00")), (0.3, hexc("ff4d00")), (0.6, hexc("ffae00")), (0.85, hexc("fff3b0")), (1, hexc("ffffff"))])
    halo = glow(m, 12, 0.6) * (1 - m)
    rgb = np.where((m > 0.01)[..., None], rgb, np.array(hexc("ffc23d")))
    save("Slash_Sun", rgb, np.maximum(m * (0.75 + 0.25 * (1 - v)), halo))

def slash_sound():
    a = np.zeros((N, N), np.float32); c = np.zeros((N, N), np.float32)
    for k in range(5):
        r0 = 0.55 + k * 0.085
        band = np.exp(-((R - r0) / 0.014) ** 2) * ss(-95 + k * 8, -75 + k * 8, A) * (1 - ss(75 - k * 8, 95 - k * 8, A))
        a = np.maximum(a, band); c = np.where(band > 0.2, k / 4, c)
    rgb = ramp(c, [(0, hexc("fff176")), (0.5, hexc("ff4fd8")), (1, hexc("8a3bff"))])
    halo = glow(a, 6, 0.6)
    save("Slash_Sound", rgb, np.maximum(a, halo * 0.6))

def wave_curl():
    """Grande vague ukiyo-e (côté) : le dos monte de gauche à droite, la crête s'enroule."""
    S = 1024
    img = Image.new("L", (S, S), 0); dr = ImageDraw.Draw(img)
    def P(x, y): return ((x + 1) / 2 * S, (1 - (y + 1) / 2) * S)
    pts = [P(-1, -1), P(-1, -0.7)]
    for i in range(41):  # dos de la vague
        t = i / 40
        x = -1 + t * 1.35; y = -0.7 + 1.45 * (t ** 1.6)
        pts.append(P(x, y))
    for i in range(1, 31):  # enroulement de la crête (spirale vers l'intérieur)
        t = i / 30
        ang = math.radians(100 - t * 260)
        rad = 0.42 * (1 - 0.55 * t)
        cx, cy = 0.35, 0.33
        pts.append(P(cx + rad * math.cos(ang) * 1.0, cy + rad * math.sin(ang)))
    for i in range(1, 21):  # intérieur du tube, revient vers le bas à droite
        t = i / 20
        pts.append(P(0.42 + t * 0.55, 0.12 - t * 1.12))
    pts.append(P(1, -1))
    dr.polygon(pts, fill=255)
    m = np.asarray(img.resize((N, N), Image.LANCZOS)).astype(np.float32) / 255
    n = noise(6, 301)
    h = (Y + 1) / 2
    flow = np.sin(Y * 30 + X * 12 + n * 7)
    rgb = ramp(h * 0.9 + (n - 0.5) * 0.15, [(0, hexc("061d5c")), (0.35, hexc("0f47b8")), (0.65, hexc("2f9bff")), (0.85, hexc("9fe3ff")), (1, hexc("ffffff"))])
    rgb = rgb * (1 - 0.22 * (flow > 0.7)[..., None]) + (flow > 0.92)[..., None] * 0.25
    # griffes d'écume le long de la crête
    foam = np.zeros((N, N), np.float32)
    for i in range(22):
        t = i / 21
        ang = math.radians(100 - t * 200)
        rad = 0.44 * (1 - 0.45 * t)
        fx, fy = 0.35 + rad * math.cos(ang), 0.33 + rad * math.sin(ang)
        dx, dy = math.cos(ang), math.sin(ang)
        L = 0.06 + 0.05 * rng.random()
        tt = np.clip(((X - fx) * dx + (Y - fy) * dy) / L, 0, 1)
        d = np.abs(-(X - fx) * dy + (Y - fy) * dx)
        claw = (d < 0.018 * (1 - tt)) & (((X - fx) * dx + (Y - fy) * dy) > -0.01) & (tt < 1)
        foam = np.maximum(foam, claw.astype(np.float32))
        foam = np.maximum(foam, (((X - fx) ** 2 + (Y - fy) ** 2) < 0.022 ** 2).astype(np.float32))
    edge = m * (gaussian_filter(m, 2.5) < 0.8)
    rgb = rgb * (1 - edge[..., None] * 0.55)
    rgb = rgb * (1 - foam[..., None]) + foam[..., None]
    drops = np.zeros((N, N), np.float32)
    for k in range(25):
        x = rng.uniform(0.1, 0.95); y = rng.uniform(0.55, 0.98); s = rng.uniform(0.008, 0.02)
        drops = np.maximum(drops, ((X - x) ** 2 + (Y - y) ** 2 < s * s).astype(np.float32))
    rgb = rgb * (1 - drops[..., None]) + drops[..., None]
    save("Wave_Curl", rgb, np.maximum.reduce([m, foam, drops]))

def butterfly():
    a = np.zeros((N, N), np.float32); t = np.zeros((N, N), np.float32)
    for side in (1, -1):
        for (cx, cy, rx, ry, rot) in [(0.42, 0.3, 0.42, 0.3, 35), (0.3, -0.3, 0.28, 0.22, -30)]:
            ca, sa = math.cos(math.radians(rot)), math.sin(math.radians(rot))
            lx = ((X - side * cx) * ca + (Y - cy) * sa * side)
            ly = (-(X - side * cx) * sa * side + (Y - cy) * ca)
            e = (lx / rx) ** 2 + (ly / ry) ** 2
            a = np.maximum(a, (e < 1).astype(np.float32)); t = np.maximum(t, np.clip(1 - e, 0, 1) * (e < 1))
    body = ((X / 0.04) ** 2 + (Y / 0.5) ** 2 < 1)
    veins = (np.abs(np.sin(np.arctan2(Y, np.abs(X)) * 9)) < 0.07) & (a > 0)
    rgb = ramp(t, [(0, hexc("3a1f8a")), (0.25, hexc("8f5bff")), (0.7, hexc("d6c2ff")), (1, (1, 1, 1))])
    rgb = rgb * (1 - veins[..., None] * 0.5)
    rgb = np.where(body[..., None], np.array(hexc("1a1030")), rgb)
    save("Butterfly", rgb, np.maximum(a, body.astype(np.float32)))


def slash_flame():
    licks = polar_noise(5, 2.5, 201, 3)
    fine = gaussian_filter(polar_noise(10, 4, 202, 2), 2)
    wob = (np.maximum(0, licks - 0.42) ** 1.1) * 0.3
    m, u, v, prof = crescent2(0.45, 0.82, wobble=wob)
    soft = m * (0.8 + 0.2 * fine)
    heat = np.clip(1 - v * 1.1 + (fine - 0.5) * 0.25, 0, 1)
    rgb = ramp(heat, [(0, hexc("8a0e00")), (0.2, hexc("e02800")), (0.45, hexc("ff7000")), (0.7, hexc("ffb627")), (0.88, hexc("fff0a8")), (1, hexc("ffffff"))])
    halo = glow(m, 10, 0.5) * (1 - m)
    rgb = np.where((m > 0.01)[..., None], rgb, np.array(hexc("ff7a1a")))
    save("Slash_Flame", rgb, np.maximum(soft, halo), blur=1.0)

def wave_curl():
    n = noise(6, 301)
    cx, cy = 0.28, 0.3
    d = np.sqrt((X - cx) ** 2 + (Y - cy) ** 2)
    ang = np.degrees(np.arctan2(Y - cy, X - cx))      # -180..180
    # dos : monte de (-1,-0.75) jusqu'au sommet du tube
    back = (Y < -0.75 + 1.6 * ss(-1.0, 0.25, X) ** 1.3 + (n - 0.5) * 0.03) & (X < cx + 0.05)
    # tube : anneau qui passe par le haut et retombe à droite (angle 150 -> -40)
    tube_w = 0.17
    a01 = np.clip((150 - ang) / 190, 0, 1)            # 0 au départ (gauche) .. 1 au bout (droite)
    r_out = 0.55 - 0.18 * a01
    tube = (d < r_out) & (d > r_out - tube_w * (1 - 0.6 * a01)) & (ang < 150) & (ang > -40)
    # pied de la vague à droite sous le tube
    foot = (Y < -0.75 + 0.5 * (1 - ss(0.3, 1.0, X))) & (X >= cx)
    base = Y < -0.72
    m = (back | tube | foot | base).astype(np.float32)
    h = (Y + 1) / 2
    flow = np.sin(Y * 28 + X * 10 + n * 7)
    rgb = ramp(h + (n - 0.5) * 0.15, [(0, hexc("061d5c")), (0.35, hexc("0f47b8")), (0.6, hexc("2f9bff")), (0.82, hexc("9fe3ff")), (1, hexc("ffffff"))])
    rgb = rgb * (1 - 0.22 * (flow > 0.72)[..., None])
    # intérieur du tube plus clair (eau translucide)
    inner = tube & (d < r_out - tube_w * 0.55 * (1 - 0.6 * a01))
    rgb = np.where(inner[..., None], rgb * 0.75 + np.array(hexc("bdefff")) * 0.25, rgb)
    # griffes d'écume sur le bord extérieur du tube
    foam = np.zeros((N, N), np.float32)
    for i in range(26):
        t = i / 25
        a = math.radians(150 - t * 190)
        rr = 0.55 - 0.18 * t
        fx, fy = cx + rr * math.cos(a), cy + rr * math.sin(a)
        dx, dy = math.cos(a - 0.5), math.sin(a - 0.5)   # griffes inclinées vers l'avant
        L = 0.05 + 0.06 * rng.random() * (0.4 + t)
        proj = (X - fx) * dx + (Y - fy) * dy
        tt = np.clip(proj / L, 0, 1)
        dd = np.abs(-(X - fx) * dy + (Y - fy) * dx)
        foam = np.maximum(foam, ((dd < 0.02 * (1 - tt)) & (proj > -0.01) & (tt < 1)).astype(np.float32))
    drops = np.zeros((N, N), np.float32)
    for k in range(28):
        a = math.radians(rng.uniform(-40, 120)); rr = rng.uniform(0.58, 0.75)
        x, y, s = cx + rr * math.cos(a), cy + rr * math.sin(a), rng.uniform(0.008, 0.022)
        drops = np.maximum(drops, ((X - x) ** 2 + (Y - y) ** 2 < s * s).astype(np.float32))
    edge = m * (gaussian_filter(m, 2.5) < 0.8)
    rgb = rgb * (1 - edge[..., None] * 0.6)
    rgb = rgb * (1 - foam[..., None]) + foam[..., None]
    rgb = rgb * (1 - drops[..., None]) + drops[..., None]
    save("Wave_Curl", rgb, np.maximum.reduce([m, foam, drops]))

def calibration():
    """Flèche vers la DROITE de l'image (+U) et barre en HAUT : sert à vérifier
    l'orientation des cartes en jeu (commande console ds_vfxcalib)."""
    a = np.zeros((N, N), np.float32)
    a = np.maximum(a, ((np.abs(Y) < 0.06) & (X > -0.7) & (X < 0.5)).astype(np.float32))
    a = np.maximum(a, ((X >= 0.45) & (X < 0.9) & (np.abs(Y) < (0.9 - X) * 0.9)).astype(np.float32))
    top = (Y > 0.7) & (Y < 0.85) & (np.abs(X) < 0.7)
    rgb = np.zeros((N, N, 3), np.float32); rgb[...] = (1, 0.2, 0.2)
    rgb[top] = (0.2, 1, 0.3)
    a = np.maximum(a, top.astype(np.float32))
    frame = (np.abs(X) > 0.95) | (np.abs(Y) > 0.95)
    rgb[frame] = (1, 1, 1); a = np.maximum(a, frame.astype(np.float32))
    save("Calibration", rgb, a, blur=0)

for f in [slash_water, slash_flame, slash_sun, slash_thunder, slash_wind, slash_mist, slash_ice, slash_blood,
          slash_shadow, slash_flower, slash_sound, slash_love, slash_insect, slash_serpent, slash_stone,
          slash_beast, slash_white, wave_curl, fireball, flame_tongue, bolt_sprite, cloud, ink_splash,
          water_splash, petal_sprite, flower_bloom, ice_crystal, ice_shard, butterfly, speed_lines,
          tornado_band, sigil, leaf_debris, rock_chunk, blood_splat, sound_wave]:
    f()
ring("Ring_Shock", 0.03, "ffffff", "ffffff")
ring("Ring_Broken", 0.05, "ffffff", "dddddd", broken=True)
spiral("Spiral", 3, "ffffff", "cccccc")
spiral("Spiral_Dense", 5, "ffffff", "dddddd", tight=4, seed=24)
impact_star("Impact_Star", 14, "ffffff")
impact_star("Impact_Star_Sharp", 22, "fff7d6", seed=25)
soft_orb("Orb_Soft", "ffffff", "bbbbbb")
calibration()
print("ok", len(os.listdir(OUT)))
