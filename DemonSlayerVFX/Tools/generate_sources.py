#!/usr/bin/env python3
"""
Demon Slayer VFX Pack - générateur des SOURCES (textures + maillages)
=====================================================================
Produit, sans Unreal, toutes les sources importées ensuite par
Unreal/ue_setup_pack.py dans le projet ADK nanos world :

  Source/Textures/<Dossier>/T_VFX_*.png   masques, bruits tuilables, flipbooks
                                          (sub-UV), traînées, distorsion
  Source/Meshes/SM_VFX_*.obj              coupes en arc, vague, anneaux, vortex,
                                          dragon (tête + segment), pics, pétale...

Conventions (importantes pour les matériaux) :
  - Textures en NIVEAUX DE GRIS (la couleur vient du matériau / de Niagara) :
    R = G = B = masque, A = masque. Importées en "Masks" (pas de sRGB).
  - Bruits et traînées TUILABLES (panning sans couture).
  - Flipbooks : grille N x N, lecture ligne par ligne (SubUV Animation de Niagara).
  - Maillages : unités Unreal (cm), +X = avant, +Z = haut. Écrits en OBJ
    "Y haut" (convention OBJ) : OBJ(x, y, z) = UE(X, Z, -Y).
  - UV des coupes : U le long de l'arc (0 = queue, 1 = tête du coup),
    V dans l'épaisseur (0 = intérieur, 1 = extérieur).

Utilisation :  python generate_sources.py [dossier_sortie]
Dépendances :  numpy, pillow, scipy
"""
import math
import os
import sys

import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter, map_coordinates

ROOT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "Source")
TEX = os.path.join(ROOT, "Textures")
MESH = os.path.join(ROOT, "Meshes")
RNG = np.random.default_rng(1337)


# ===========================================================================
# Outils image
# ===========================================================================

def grid(n):
    yy, xx = np.mgrid[0:n, 0:n].astype(np.float32)
    X = (xx + 0.5) / n * 2 - 1
    Y = 1 - (yy + 0.5) / n * 2
    return X, Y


def ss(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0 + 1e-9), 0, 1)
    return t * t * (3 - 2 * t)


def save_mask(folder, name, mask, size=None):
    """Masque niveaux de gris -> PNG RGBA (RGB = A = masque)."""
    m = np.clip(mask, 0, 1)
    if size and m.shape[0] != size:
        m = np.asarray(Image.fromarray((m * 255).astype(np.uint8)).resize((size, size), Image.LANCZOS)) / 255.0
    v = (m * 255).astype(np.uint8)
    img = np.dstack([v, v, v, v])
    path = os.path.join(TEX, folder)
    os.makedirs(path, exist_ok=True)
    Image.fromarray(img, "RGBA").save(os.path.join(path, name + ".png"), optimize=True)


def save_rgb(folder, name, rgb):
    path = os.path.join(TEX, folder)
    os.makedirs(path, exist_ok=True)
    Image.fromarray((np.clip(rgb, 0, 1) * 255).astype(np.uint8), "RGB").save(os.path.join(path, name + ".png"), optimize=True)


def tile_noise(n, cells, seed, octaves=5, persistence=0.5):
    """Bruit de valeur TUILABLE (fBm) : grilles périodiques interpolées."""
    rng = np.random.default_rng(seed)
    out = np.zeros((n, n), np.float32)
    amp, total = 1.0, 0.0
    for o in range(octaves):
        c = cells * (2 ** o)
        g = rng.random((c, c)).astype(np.float32)
        g = np.pad(g, ((0, 1), (0, 1)), mode="wrap")
        coords = (np.arange(n) / n * c).astype(np.float32)
        cy, cx = np.meshgrid(coords, coords, indexing="ij")
        layer = map_coordinates(g, [cy, cx], order=3, mode="wrap")
        out += layer * amp
        total += amp
        amp *= persistence
    out /= total
    return (out - out.min()) / (out.max() - out.min() + 1e-9)


def tile_voronoi(n, points, seed):
    """Voronoï tuilable (distance au point le plus proche, 9 copies)."""
    rng = np.random.default_rng(seed)
    pts = rng.random((points, 2))
    yy, xx = np.mgrid[0:n, 0:n].astype(np.float32) / n
    d = np.full((n, n), 10.0, np.float32)
    d2 = np.full((n, n), 10.0, np.float32)
    for px, py in pts:
        for ox in (-1, 0, 1):
            for oy in (-1, 0, 1):
                dist = np.sqrt((xx - px - ox) ** 2 + (yy - py - oy) ** 2)
                d2 = np.where(dist < d, d, np.minimum(d2, dist))
                d = np.minimum(d, dist)
    return d / d.max(), (d2 - d) / ((d2 - d).max() + 1e-9)


def polyline_mask(X, Y, pts, width):
    out = np.zeros_like(X)
    for (x0, y0), (x1, y1) in zip(pts[:-1], pts[1:]):
        dx, dy = x1 - x0, y1 - y0
        l2 = dx * dx + dy * dy + 1e-9
        t = np.clip(((X - x0) * dx + (Y - y0) * dy) / l2, 0, 1)
        d = np.sqrt((X - x0 - dx * t) ** 2 + (Y - y0 - dy * t) ** 2)
        out = np.maximum(out, np.exp(-(d / width) ** 2))
    return out


def jagged(rng, p0, p1, segs, amp):
    pts = []
    for i in range(segs + 1):
        t = i / segs
        x = p0[0] + (p1[0] - p0[0]) * t
        y = p0[1] + (p1[1] - p0[1]) * t
        if 0 < i < segs:
            nx, ny = -(p1[1] - p0[1]), p1[0] - p0[0]
            ln = math.hypot(nx, ny) + 1e-9
            o = rng.uniform(-amp, amp)
            x += nx / ln * o
            y += ny / ln * o
        pts.append((x, y))
    return pts


def flipbook(folder, name, frames, cell, frame_fn):
    """Assemble frames x frames images (cell px) en atlas (lecture ligne par ligne)."""
    atlas = np.zeros((frames * cell, frames * cell), np.float32)
    total = frames * frames
    for i in range(total):
        r, c = divmod(i, frames)
        atlas[r * cell:(r + 1) * cell, c * cell:(c + 1) * cell] = frame_fn(i / (total - 1), i)
    save_mask(folder, name, atlas)


# ===========================================================================
# Textures
# ===========================================================================

def textures():
    N = 512
    X, Y = grid(N)
    R = np.sqrt(X * X + Y * Y)
    A = np.arctan2(Y, X)

    # ---------------------------------------------------------------- Noise
    save_mask("Noise", "T_VFX_Noise_Perlin", tile_noise(N, 4, 1))
    save_mask("Noise", "T_VFX_Noise_Cloud", tile_noise(N, 3, 2, octaves=6, persistence=0.55))
    f1, edges = tile_voronoi(N, 24, 3)
    save_mask("Noise", "T_VFX_Noise_Voronoi", 1 - f1)
    save_mask("Noise", "T_VFX_Noise_Caustics", 1 - ss(0.0, 0.08, edges))
    streak = tile_noise(N, 2, 4, octaves=4)
    streak = np.asarray(Image.fromarray((streak * 255).astype(np.uint8)).resize((N, N // 16)).resize((N, N), Image.BICUBIC)) / 255.0
    save_mask("Noise", "T_VFX_Noise_Streaks", ss(0.35, 0.85, streak))
    erosion = tile_noise(N, 6, 5, octaves=5)
    save_mask("Noise", "T_VFX_Noise_Erosion", erosion)

    # ---------------------------------------------------------------- Masks
    save_mask("Masks", "T_VFX_Mask_SoftCircle", (1 - ss(0, 1, R)) ** 1.5)
    save_mask("Masks", "T_VFX_Mask_HardCircle", 1 - ss(0.86, 0.92, R))
    save_mask("Masks", "T_VFX_Mask_Ring", np.exp(-((R - 0.78) / 0.07) ** 2))
    save_mask("Masks", "T_VFX_Mask_Shockwave", np.exp(-((R - 0.8) / 0.03) ** 2) + np.exp(-((R - 0.74) / 0.12) ** 2) * 0.35)
    spikes = 16
    lens = RNG.uniform(0.45, 1.0, spikes)
    idx = ((A + np.pi) / (2 * np.pi) * spikes).astype(int) % spikes
    frac = ((A + np.pi) / (2 * np.pi) * spikes) % 1
    tri = 1 - np.abs(frac - 0.5) * 2
    save_mask("Masks", "T_VFX_Mask_Star", np.maximum((R < 0.12 + (lens[idx] - 0.12) * tri ** 3).astype(np.float32) * 0.9, (1 - ss(0, 0.35, R))))
    save_mask("Masks", "T_VFX_Mask_Spark", np.exp(-(X / 0.9) ** 6 - (Y / 0.06) ** 2) * (1 - ss(0.2, 1.0, np.abs(X))) + np.exp(-(R / 0.08) ** 2))
    save_mask("Masks", "T_VFX_Mask_Droplet", (np.sqrt((X / 0.45) ** 2 + ((Y + 0.25 * np.maximum(0, Y)) / 0.8) ** 2) < 1).astype(np.float32) * (0.6 + 0.4 * (1 - R)))
    save_mask("Masks", "T_VFX_Mask_Gradient_U", np.tile(np.linspace(0, 1, N, dtype=np.float32), (N, 1)))
    # traînée de coupe : U = le long (tête lumineuse à droite), V = épaisseur
    u = (X + 1) / 2
    v = (Y + 1) / 2
    slash = (u ** 1.8) * np.exp(-((v - 0.5) / 0.22) ** 2) + (u ** 4) * np.exp(-((v - 0.5) / 0.05) ** 2)
    save_mask("Masks", "T_VFX_Mask_SlashTrail", slash / slash.max())
    # pétale, feuille, éclat de glace
    lx = (X + 1) / 2
    w = 0.55 * np.sin(np.pi * np.clip(lx, 0, 1)) ** 0.7
    save_mask("Masks", "T_VFX_Mask_Petal", ((np.abs(Y) < w) & (lx > 0) & (lx < 1)).astype(np.float32) * (0.7 + 0.3 * lx))
    w = 0.35 * np.sin(np.pi * np.clip(lx, 0, 1))
    leaf = ((np.abs(Y) < w)).astype(np.float32) * (1 - 0.5 * (np.abs(Y) < 0.015))
    save_mask("Masks", "T_VFX_Mask_Leaf", leaf)
    shard = ((np.abs(X) < 0.35 * (1 - (Y + 1) / 2)) & (Y > -1)).astype(np.float32) * (0.6 + 0.4 * (X > 0))
    save_mask("Masks", "T_VFX_Mask_Shard", shard)
    # sceau circulaire (arts sanguinaires)
    sig = np.exp(-((R - 0.92) / 0.012) ** 2) + np.exp(-((R - 0.8) / 0.01) ** 2)
    for k in range(6):
        a1, a2 = math.radians(k * 60 + 90), math.radians(k * 60 + 210)
        sig = np.maximum(sig, polyline_mask(X, Y, [(0.8 * math.cos(a1), 0.8 * math.sin(a1)), (0.8 * math.cos(a2), 0.8 * math.sin(a2))], 0.01))
    sig = np.maximum(sig, ((np.abs(np.sin(A * 18)) > 0.92) & (R > 0.82) & (R < 0.9)).astype(np.float32))
    save_mask("Masks", "T_VFX_Mask_Sigil", sig)

    # ---------------------------------------------------------------- Trails (tuilables en U)
    n_trail = tile_noise(N, 3, 10)
    save_mask("Trails", "T_VFX_Trail_Energy", np.exp(-((Y) / 0.1) ** 2) + 0.5 * np.exp(-((Y) / 0.35) ** 2))
    flow = np.sin(Y * 22 + n_trail * 6) * 0.5 + 0.5
    save_mask("Trails", "T_VFX_Trail_Water", (1 - ss(0.75, 1.0, np.abs(Y))) * (0.45 + 0.55 * ss(0.55, 0.95, flow)))
    licks = tile_noise(N, 4, 11, octaves=4)
    save_mask("Trails", "T_VFX_Trail_Fire", (1 - ss(0.2, 0.9, np.abs(Y) + (licks - 0.5) * 0.7)) * (0.6 + 0.4 * licks))
    wind = np.zeros_like(X)
    for k in range(9):
        y0 = RNG.uniform(-0.8, 0.8)
        wind = np.maximum(wind, np.exp(-((Y - y0 - 0.05 * np.sin(X * math.pi * 2 + k)) / RNG.uniform(0.01, 0.03)) ** 2))
    save_mask("Trails", "T_VFX_Trail_Wind", wind)
    smoke_trail = tile_noise(N, 3, 12, octaves=6)
    save_mask("Trails", "T_VFX_Trail_Mist", (1 - ss(0.3, 1.0, np.abs(Y))) * smoke_trail)
    # éclair : 4 variantes empilées (sub-UV 1 x 4)
    rows = []
    for k in range(4):
        rng = np.random.default_rng(20 + k)
        h = N // 4
        Xs, Ys = np.meshgrid(np.linspace(-1, 1, N), np.linspace(1, -1, h))
        pts = jagged(rng, (-1.0, 0.0), (1.0, 0.0), 16, 0.35)
        core = polyline_mask(Xs, Ys, pts, 0.03)
        glow = polyline_mask(Xs, Ys, pts, 0.18) * 0.5
        for _ in range(3):
            i = rng.integers(2, 14)
            bx, by = pts[i]
            br = jagged(rng, (bx, by), (bx + rng.uniform(0.2, 0.5), by + rng.uniform(-0.7, 0.7)), 5, 0.12)
            core = np.maximum(core, polyline_mask(Xs, Ys, br, 0.02) * 0.8)
        rows.append(np.maximum(core, glow))
    save_mask("Trails", "T_VFX_Trail_Lightning_1x4", np.vstack(rows))

    # ---------------------------------------------------------------- Flipbooks (Particles)
    cell = 128
    Xc, Yc = grid(cell)
    Rc = np.sqrt(Xc * Xc + Yc * Yc)
    base_noise = tile_noise(cell, 3, 30, octaves=5)
    base_noise2 = tile_noise(cell, 5, 31, octaves=4)

    def smoke(t, i):
        r = 0.35 + 0.55 * t
        n = np.roll(base_noise, int(t * 30), axis=0)
        shape = 1 - ss(r * 0.5, r, Rc + (n - 0.5) * 0.45)
        return shape * (0.4 + 0.6 * n) * (1 - t) ** 0.8

    def fire(t, i):
        n = np.roll(base_noise, int(t * cell), axis=0)
        n2 = np.roll(base_noise2, int(t * cell * 1.7), axis=0)
        width = 0.55 * (1 - (Yc + 1) / 2) ** 0.7 * (1 - 0.4 * t)
        xs = Xc + (n - 0.5) * 0.5 * ((Yc + 1) / 2)
        shape = 1 - ss(width * 0.4, width + 1e-3, np.abs(xs))
        return shape * (0.55 + 0.45 * n2) * ss(-1, -0.7, Yc) * (1 - t ** 3)

    def lightning(t, i):
        rng = np.random.default_rng(60 + i)
        pts = jagged(rng, (rng.uniform(-0.3, 0.3), 1.0), (rng.uniform(-0.3, 0.3), -1.0), 9, 0.4)
        core = polyline_mask(Xc, Yc, pts, 0.03)
        glow = polyline_mask(Xc, Yc, pts, 0.16) * 0.5
        return np.maximum(core, glow)

    def explosion(t, i):
        n = np.roll(base_noise, int(t * 20), axis=1)
        r = 0.2 + 0.75 * t ** 0.6
        ringv = 1 - ss(r * 0.6, r, Rc + (n - 0.5) * 0.35)
        hollow = ss(r * 0.2 * t, r * 0.7 * t + 0.05, Rc)
        return ringv * (0.5 + 0.5 * n) * (1 - t ** 2) * (0.4 + 0.6 * hollow)

    def mist(t, i):
        n = np.roll(np.roll(base_noise, int(t * 40), axis=1), int(t * 15), axis=0)
        return (1 - ss(0.2, 1.0, Rc)) * n * (0.3 + 0.7 * np.sin(np.pi * t))

    flipbook("Particles", "T_VFX_Flip_Smoke_8x8", 8, cell, smoke)
    flipbook("Particles", "T_VFX_Flip_Fire_8x8", 8, cell, fire)
    flipbook("Particles", "T_VFX_Flip_Explosion_8x8", 8, cell, explosion)
    flipbook("Particles", "T_VFX_Flip_Splash_4x4", 4, cell * 2, _splash_big)
    flipbook("Particles", "T_VFX_Flip_Lightning_4x4", 4, cell, lightning)
    flipbook("Particles", "T_VFX_Flip_Mist_4x4", 4, cell, mist)

    # ---------------------------------------------------------------- Distortion (normales)
    def normal_from_height(h, strength):
        gy, gx = np.gradient(h)
        nx, ny = -gx * strength, -gy * strength
        nz = np.ones_like(h)
        ln = np.sqrt(nx * nx + ny * ny + nz * nz)
        return np.dstack([nx / ln * 0.5 + 0.5, ny / ln * 0.5 + 0.5, nz / ln * 0.5 + 0.5])
    save_rgb("Distortion", "T_VFX_Distortion_Noise_N", normal_from_height(tile_noise(N, 4, 70, octaves=4), 40))
    save_rgb("Distortion", "T_VFX_Distortion_Ring_N", normal_from_height(np.exp(-((R - 0.75) / 0.12) ** 2), 25))


def _splash_big(t, i):
    cell = 256
    Xc, Yc = grid(cell)
    crown = np.zeros_like(Xc)
    rng = np.random.default_rng(41)
    for k in range(22):
        ang = rng.uniform(0.1, math.pi - 0.1)
        speed = rng.uniform(0.6, 1.0)
        dist = (0.1 + 0.85 * t) * speed
        cx = math.cos(ang) * dist
        cy = -0.75 + math.sin(ang) * dist * 1.5 - 1.2 * (t * speed) ** 2
        s = 0.05 * (1 - t * 0.5) * rng.uniform(0.6, 1.3)
        crown = np.maximum(crown, (((Xc - cx) / s) ** 2 + ((Yc - cy) / (s * 1.5)) ** 2 < 1).astype(np.float32))
    sheet = (np.abs(Xc) < 0.2 + 0.7 * t) & (Yc < -0.72 + 0.45 * math.sin(math.pi * min(1, t * 1.4)) * (1 - np.abs(Xc) ** 2))
    return np.maximum(crown, sheet.astype(np.float32) * (1 - t)) * (1 - ss(0.8, 1.0, t))


# ===========================================================================
# Maillages (OBJ)
# ===========================================================================

class Mesh:
    def __init__(self, name):
        self.name, self.v, self.vt, self.vn, self.f = name, [], [], [], []

    def vert(self, p, uv, n):
        """p, n en repère Unreal (X avant, Y droite, Z haut)."""
        self.v.append((p[0], p[2], -p[1]))
        nl = math.sqrt(n[0] ** 2 + n[1] ** 2 + n[2] ** 2) or 1
        self.vn.append((n[0] / nl, n[2] / nl, -n[1] / nl))
        self.vt.append((uv[0], 1 - uv[1]))
        return len(self.v)

    def quad(self, a, b, c, d):
        self.f.append((a, b, c))
        self.f.append((a, c, d))

    def grid(self, cols, rows, fn, double=False):
        """fn(u, v) -> (position, normale). Surface (cols x rows) avec UV = (u, v)."""
        idx = {}
        for j in range(rows + 1):
            for i in range(cols + 1):
                u, v = i / cols, j / rows
                p, n = fn(u, v)
                idx[i, j] = self.vert(p, (u, v), n)
        for j in range(rows):
            for i in range(cols):
                self.quad(idx[i, j], idx[i + 1, j], idx[i + 1, j + 1], idx[i, j + 1])
        if double:
            back = {}
            for (i, j), k in idx.items():
                p = self.v[k - 1]
                n = self.vn[k - 1]
                self.v.append(p)
                self.vn.append((-n[0], -n[1], -n[2]))
                self.vt.append(self.vt[k - 1])
                back[i, j] = len(self.v)
            for j in range(rows):
                for i in range(cols):
                    self.quad(back[i, j], back[i, j + 1], back[i + 1, j + 1], back[i + 1, j])

    def save(self):
        os.makedirs(MESH, exist_ok=True)
        with open(os.path.join(MESH, self.name + ".obj"), "w") as fh:
            fh.write(f"# Demon Slayer VFX Pack - {self.name} (unites : cm, +X avant, +Z haut dans Unreal)\n")
            fh.write(f"o {self.name}\n")
            for p in self.v:
                fh.write("v %.4f %.4f %.4f\n" % p)
            for t in self.vt:
                fh.write("vt %.5f %.5f\n" % t)
            for n in self.vn:
                fh.write("vn %.5f %.5f %.5f\n" % n)
            for a, b, c in self.f:
                fh.write(f"f {a}/{a}/{a} {b}/{b}/{b} {c}/{c}/{c}\n")
        return len(self.v), len(self.f)


def slash_arc(name, degrees, r_in, r_out, tilt=0.0, taper=True, cols=48):
    """Bande en arc dans le plan horizontal, centrée sur le lanceur, ouverte vers +X."""
    m = Mesh(name)
    half = math.radians(degrees) / 2

    def fn(u, v):
        a = -half + u * 2 * half
        prof = math.sin(math.pi * min(1, u * 1.15)) ** 0.6 if taper else 1
        r = r_in + (r_out - r_in) * (v * max(prof, 0.05) + (1 - max(prof, 0.05)) * 0.5)
        x, y = math.cos(a) * r, math.sin(a) * r
        z = math.sin(a) * tilt * r
        return (x, y, z), (0, 0, 1)
    m.grid(cols, 4, fn, double=True)
    return m.save()


def ring_flat(name, r_in, r_out, cols=64):
    m = Mesh(name)

    def fn(u, v):
        a = u * 2 * math.pi
        r = r_in + (r_out - r_in) * v
        return (math.cos(a) * r, math.sin(a) * r, 0), (0, 0, 1)
    m.grid(cols, 2, fn, double=True)
    return m.save()


def cylinder_twist(name, radius_bottom, radius_top, height, twist_deg, cols=32, rows=12):
    """Vortex : cylindre ouvert torsadé (U autour, V en hauteur), double face."""
    m = Mesh(name)

    def fn(u, v):
        a = u * 2 * math.pi + math.radians(twist_deg) * v
        r = radius_bottom + (radius_top - radius_bottom) * v
        p = (math.cos(a) * r, math.sin(a) * r, v * height)
        return p, (math.cos(a), math.sin(a), 0)
    m.grid(cols, rows, fn, double=True)
    return m.save()


def wave_curl(name, width, height, cols=24, rows=40):
    """Vague déferlante : profil enroulé (V) extrudé sur la largeur (U = Y)."""
    m = Mesh(name)
    profile = []
    for i in range(rows + 1):
        t = i / rows
        if t < 0.55:   # dos de la vague : du sol (x = -0.5) vers la crête
            k = t / 0.55
            x, z = -0.5 + k * 0.75, k ** 1.4 * 0.95
        else:          # enroulement vers l'avant puis vers le bas
            k = (t - 0.55) / 0.45
            ang = math.radians(90 - k * 230)
            rad = 0.32 * (1 - 0.45 * k)
            x, z = 0.25 + math.cos(ang) * rad, 0.63 + math.sin(ang) * rad
        profile.append((x * height, z * height))

    def fn(u, v):
        i = min(int(v * rows), rows - 1)
        k = v * rows - i
        x = profile[i][0] * (1 - k) + profile[i + 1][0] * k
        z = profile[i][1] * (1 - k) + profile[i + 1][1] * k
        edge = 1 - 0.35 * abs(u - 0.5) * 2         # bords plus bas
        y = (u - 0.5) * width
        return (x * edge, y, z * edge), (-1, 0, 0.3)
    m.grid(cols, rows, fn, double=True)
    return m.save()


def sphere(name, radius, cols=24, rows=16):
    m = Mesh(name)

    def fn(u, v):
        th, ph = u * 2 * math.pi, v * math.pi
        n = (math.sin(ph) * math.cos(th), math.sin(ph) * math.sin(th), math.cos(ph))
        return (n[0] * radius, n[1] * radius, n[2] * radius), n
    m.grid(cols, rows, fn)
    return m.save()


def cone(name, radius, height, cols=24, open_base=True):
    m = Mesh(name)

    def fn(u, v):
        a = u * 2 * math.pi
        r = radius * (1 - v)
        return (math.cos(a) * r, math.sin(a) * r, v * height), (math.cos(a), math.sin(a), radius / height)
    m.grid(cols, 6, fn, double=open_base)
    return m.save()


def spike(name, radius, height, sides=5):
    """Pic de glace : pyramide à facettes (normales plates par face)."""
    m = Mesh(name)
    tip = (0, 0, height)
    for i in range(sides):
        a0, a1 = 2 * math.pi * i / sides, 2 * math.pi * (i + 1) / sides
        p0 = (math.cos(a0) * radius, math.sin(a0) * radius, 0)
        p1 = (math.cos(a1) * radius, math.sin(a1) * radius, 0)
        am = (a0 + a1) / 2
        n = (math.cos(am) * height, math.sin(am) * height, radius)
        a = m.vert(p0, (i / sides, 0), n)
        b = m.vert(p1, ((i + 1) / sides, 0), n)
        c = m.vert(tip, ((i + 0.5) / sides, 1), n)
        m.f.append((a, b, c))
    return m.save()


def loft(name, sections, cols=20):
    """Surface lissée passant par des sections elliptiques [(x, ry, rz, zoff)] le long de X."""
    m = Mesh(name)
    rows = len(sections) - 1

    def fn(u, v):
        i = min(int(v * rows), rows - 1)
        k = v * rows - i
        s0, s1 = sections[i], sections[i + 1]
        x = s0[0] + (s1[0] - s0[0]) * k
        ry = s0[1] + (s1[1] - s0[1]) * k
        rz = s0[2] + (s1[2] - s0[2]) * k
        zo = s0[3] + (s1[3] - s0[3]) * k
        a = u * 2 * math.pi
        return (x, math.cos(a) * ry, zo + math.sin(a) * rz), (0, math.cos(a), math.sin(a))
    m.grid(cols, rows * 4, fn)
    return m


def dragon_head(name):
    """Tête de dragon stylisée (vers +X) : museau, mâchoire, crinière, cornes."""
    m = loft(name, [
        (-120, 55, 60, 0), (-60, 70, 70, 10), (0, 62, 55, 8), (60, 45, 38, 0),
        (120, 34, 26, -6), (165, 22, 16, -10), (190, 6, 5, -12),
    ], cols=24)
    # cornes (deux cônes inclinés vers l'arrière)
    for side in (1, -1):
        base = len(m.v)
        for i in range(13):
            t = i / 12
            a = t * 2 * math.pi
            for k in range(2):
                r = 12 * (1 - k)
                x = -40 - k * 110
                y = side * (35 + k * 50) + math.cos(a) * r
                z = 50 + k * 70 + math.sin(a) * r
                m.vert((x, y, z), (t, k), (0, math.cos(a), math.sin(a)))
        for i in range(12):
            a0 = base + i * 2 + 1
            m.quad(a0, a0 + 2, a0 + 3, a0 + 1)
    return m.save()


def dragon_segment(name):
    """Segment de corps : croissant épais vrillé (s'enchaîne le long d'une trajectoire)."""
    m = Mesh(name)

    def fn(u, v):
        a = (u - 0.5) * math.pi * 1.4
        r = 70 + 40 * v
        twist = (u - 0.5) * 0.8
        x = (u - 0.5) * 160
        y = math.sin(a) * r * math.cos(twist)
        z = math.cos(a) * r * 0.6 + math.sin(twist) * 30
        return (x, y, z), (0, math.sin(a), math.cos(a))
    m.grid(24, 6, fn, double=True)
    return m.save()


def petal(name, length=30, width=14):
    m = Mesh(name)

    def fn(u, v):
        x = u * length
        w = width * math.sin(math.pi * u) ** 0.7
        y = (v - 0.5) * w
        z = math.sin(math.pi * u) * 4 + ((v - 0.5) ** 2) * 6
        return (x, y, z), (0, 0, 1)
    m.grid(10, 4, fn, double=True)
    return m.save()


def meshes():
    out = {}
    out["SM_VFX_Slash_Arc_120"] = slash_arc("SM_VFX_Slash_Arc_120", 120, 120, 200)
    out["SM_VFX_Slash_Arc_180"] = slash_arc("SM_VFX_Slash_Arc_180", 180, 130, 210)
    out["SM_VFX_Slash_Arc_270"] = slash_arc("SM_VFX_Slash_Arc_270", 270, 140, 215)
    out["SM_VFX_Slash_Arc_360"] = slash_arc("SM_VFX_Slash_Arc_360", 359, 150, 220, taper=False, cols=64)
    out["SM_VFX_Slash_Crescent_Tilted"] = slash_arc("SM_VFX_Slash_Crescent_Tilted", 160, 110, 220, tilt=0.35)
    out["SM_VFX_Ring_Flat"] = ring_flat("SM_VFX_Ring_Flat", 80, 100)
    out["SM_VFX_Ring_Thick"] = ring_flat("SM_VFX_Ring_Thick", 40, 100)
    out["SM_VFX_Vortex_Cylinder"] = cylinder_twist("SM_VFX_Vortex_Cylinder", 60, 140, 400, 180)
    out["SM_VFX_Vortex_Cone"] = cylinder_twist("SM_VFX_Vortex_Cone", 30, 180, 500, 300)
    out["SM_VFX_Wave_Curl"] = wave_curl("SM_VFX_Wave_Curl", 600, 400)
    out["SM_VFX_Sphere"] = sphere("SM_VFX_Sphere", 50)
    out["SM_VFX_Cone_Open"] = cone("SM_VFX_Cone_Open", 50, 120)
    out["SM_VFX_Spike_Ice"] = spike("SM_VFX_Spike_Ice", 25, 160)
    out["SM_VFX_Dragon_Head"] = dragon_head("SM_VFX_Dragon_Head")
    out["SM_VFX_Dragon_Segment"] = dragon_segment("SM_VFX_Dragon_Segment")
    out["SM_VFX_Petal"] = petal("SM_VFX_Petal")
    return out


if __name__ == "__main__":
    textures()
    stats = meshes()
    count = sum(len(fs) for _, _, fs in os.walk(TEX))
    print(f"Textures : {count} fichiers dans {TEX}")
    for name, (verts, tris) in stats.items():
        print(f"  {name:30s} {verts:6d} sommets {tris:6d} triangles")
