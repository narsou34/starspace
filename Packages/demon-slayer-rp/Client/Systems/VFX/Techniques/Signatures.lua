--[[
    Demon Slayer RP - Signatures visuelles des techniques (client)
    ------------------------------------------------------------------
    Pour que deux techniques d'un même souffle ne se ressemblent jamais,
    chaque technique a un "Look" (Techniques/Looks.lua) :
      Planes     orientations successives des croissants (combo, coupes)
                 "flat" | "tilted" | "rising" | "falling" | "diagonal" | "diagonal2"
      Scale      taille des croissants (1 = normal)
      Multi      nombre de croissants parallèles par coup (griffes)
      Big        ultime : croissants géants + couches supplémentaires
      Orb, OrbSize        tête des projectiles
      OnRelease  signature jouée au moment du coup (fin de préparation)
      OnBurst    signature jouée à chaque explosion / impact programmé
      OnDash     signature jouée à chaque élan (départ -> arrivée)

    Une signature = fonction(ctx, x, y, z, opts) qui compose des formes
    peintes (VFX.Toon) : piliers de flammes, tornades, pluie d'éclairs, pics
    de glace, papillons, tempête de pétales, sceaux, ondes sonores...
]]

local VFX = DS.VFX
local Toon = VFX.Toon
local TMath = DS.TechMath

local Sig = {}
VFX.Signatures = Sig

local function toonOf(ctx) return VFX.ToonOf(ctx.element) end

local function around(x, y, radius, count, phase)
    local pts = {}
    for i = 1, count do
        local a = (phase or 0) + (i / count) * 2 * math.pi
        pts[i] = { x + math.cos(a) * radius, y + math.sin(a) * radius }
    end
    return pts
end

-- ---------------------------------------------------------------------------
-- Feu / soleil
-- ---------------------------------------------------------------------------

--- Colonne de flammes qui jaillit du sol.
function Sig.fire_pillar(ctx, x, y, z, opts)
    opts = opts or {}
    local h = opts.height or 420
    Toon.Pillar("Fire_Tongue", x, y, z - 90, { radius = opts.radius or 110, height = h, count = 3, spin = 120,
        life = opts.life or 0.9, scale = 0.3, grow = 1.1, alpha = 0.95, lod = ctx.lod })
    Toon.Ground("Ring_Broken", x, y, z - 88, { size = (opts.radius or 110) * 3, color = toonOf(ctx).Tint,
        glow = 2, life = 0.6, scale = 0.3, grow = 1.4, lod = ctx.lod })
    Toon.Scatter({ "Fire_Tongue" }, x, y, z, { count = 4, spread = 140, size = 60, height = 260, rise = 120, lod = ctx.lod })
end

--- Ligne de feu horizontale laissée par un élan (Feu inconnu).
function Sig.fire_line(ctx, x, y, z, opts)
    local fx, fy = ctx.fx, ctx.fy
    for i = 1, 5 do
        local d = i * 130
        Toon.Wall("Fire_Tongue", x - fx * d, y - fy * d, z - 20, math.deg(math.atan(fy, fx)), {
            size = 160, aspect = 1.2, life = 0.7, delay = i * 0.03, scale = 0.4, grow = 1.0, sideways = false, lod = ctx.lod,
            priority = i <= 2 and "main" or "secondary" })
    end
end

--- Rugissement du tigre : énorme boule de feu + mur de flammes face au lanceur.
function Sig.tiger_roar(ctx, x, y, z)
    local px, py, pz = ctx:Point(160, 0, 40)
    Toon.Sprite("Fire_Ball", { x = px, y = py, z = pz, size = 380, scale = 0.3, grow = 1.0, life = 0.5, fadeOut = 0.3, priority = "main" })
    Toon.Wall("Fire_Tongue", px, py, pz - 60, ctx.yaw, { size = 420, aspect = 1.1, life = 0.55, scale = 0.4, grow = 1.15 })
    Toon.Sprite("Impact_Star_Sharp", { x = px, y = py, z = pz, size = 300, color = { 1, 0.6, 0.15 }, glow = 2.5, life = 0.2, grow = 1.8 })
end

--- Purgatoire : anneau de piliers de flammes + croissant géant + sceau au sol.
function Sig.inferno(ctx, x, y, z)
    Toon.Ground("Ring_Broken", x, y, z - 88, { size = 900, color = { 1, 0.5, 0.1 }, glow = 2.4, life = 1.4, scale = 0.2, grow = 1.2, priority = "main" })
    for i, p in ipairs(around(x, y, 380, 6, ctx.yaw)) do
        Toon.Pillar("Fire_Tongue", p[1], p[2], z - 90, { radius = 90, height = 520, count = 2, spin = 160, life = 1.2,
            delay = i * 0.05, scale = 0.2, grow = 1.0 })
    end
    Toon.Crescent("Slash_Flame", { x, y, z + 60 }, { ctx.fx, ctx.fy }, { plane = "flat", radius = 650, life = 1.0, sweep = 180, sweepTime = 0.2, priority = "main" })
end

--- Soleil : sceau solaire au sol + halo.
function Sig.sun_seal(ctx, x, y, z)
    Toon.Ground("Sigil", x, y, z - 88, { size = 520, color = { 1, 0.75, 0.25 }, glow = 2.6, life = 1.0, spin = 60, scale = 0.4, grow = 1.0, priority = "main" })
    Toon.Sprite("Orb_Soft", { x = x, y = y, z = z, size = 420, color = { 1, 0.7, 0.2 }, glow = 2, alpha = 0.5, life = 0.6, grow = 1.4 })
end

-- ---------------------------------------------------------------------------
-- Tonnerre
-- ---------------------------------------------------------------------------

--- Éclair couché qui relie le départ et l'arrivée d'un élan.
function Sig.bolt_line(ctx, x, y, z, opts)
    opts = opts or {}
    local fx, fy = ctx.fx, ctx.fy
    local length = opts.length or 700
    Toon.Card("Bolt", {
        x = x + fx * length / 2, y = y + fy * length / 2, z = z - 30,
        right = { -fy, fx, 0 }, up = { fx, fy, 0.2 }, size = 180, aspect = length / 180,
        glow = 2.8, life = 0.35, fadeIn = 0.01, fadeOut = 0.25, priority = "main", lod = ctx.lod,
    })
    Toon.Sprite("Bolt", { x = x + fx * length, y = y + fy * length, z = z + 150, size = 420, glow = 3, life = 0.25,
        fadeIn = 0.01, priority = "main", lod = ctx.lod })
end

--- Pluie d'éclairs autour d'un point.
function Sig.bolt_rain(ctx, x, y, z, opts)
    opts = opts or {}
    for i, p in ipairs(around(x, y, opts.radius or 220, opts.count or 5, math.random() * 6)) do
        Toon.Sprite("Bolt", { x = p[1], y = p[2], z = z + 160, size = 380, glow = 3, life = 0.22, fadeIn = 0.01,
            delay = i * 0.06, priority = i <= 2 and "main" or "secondary", lod = ctx.lod })
        Toon.Ground("Ring_Shock", p[1], p[2], z - 88, { size = 160, color = { 1, 0.9, 0.3 }, glow = 2.5, life = 0.3, delay = i * 0.06, lod = ctx.lod })
    end
end

--- Cercle d'éclairs autour du lanceur.
function Sig.bolt_ring(ctx, x, y, z)
    Toon.Ground("Ring_Shock", x, y, z - 88, { size = 520, color = { 1, 0.9, 0.3 }, glow = 3, life = 0.4, scale = 0.3, grow = 1.3, priority = "main" })
    Sig.bolt_rain(ctx, x, y, z, { radius = 260, count = 4 })
end

--- Honoikazuchi no Kami : dragon de foudre (croissants enchaînés) + éclairs.
function Sig.thunder_god(ctx, x, y, z)
    local fx, fy = ctx.fx, ctx.fy
    for i = 1, 6 do
        local d = i * 150
        Toon.Crescent("Slash_Thunder", { x + fx * d, y + fy * d, z + 40 + math.sin(i) * 40 }, { fx, fy },
            { plane = (i % 2 == 0) and "diagonal" or "diagonal2", radius = 260, life = 0.6, delay = i * 0.04, sweep = 40,
              priority = i <= 3 and "main" or "secondary" })
    end
    Sig.bolt_line(ctx, x, y, z, { length = 950 })
    Sig.bolt_rain(ctx, x + fx * 950, y + fy * 950, z, { radius = 260, count = 6 })
end

-- ---------------------------------------------------------------------------
-- Vent / brume
-- ---------------------------------------------------------------------------

function Sig.tornado(ctx, x, y, z, opts)
    opts = opts or {}
    local tint = toonOf(ctx).Tint
    Toon.Pillar("Swirl_Band", x, y, z - 90, { radius = opts.radius or 160, height = opts.height or 520, count = 3, spin = 420,
        color = tint, glow = 1.6, alpha = 0.85, life = opts.life or 1.1, scale = 0.4, grow = 1.05, lod = ctx.lod })
    Toon.Ground("Spiral_Dense", x, y, z - 88, { size = (opts.radius or 160) * 3, color = tint, glow = 1.5,
        life = opts.life or 1.1, spin = 300, scale = 0.5, grow = 1.0, lod = ctx.lod })
    Toon.Scatter({ "Leaf" }, x, y, z, { count = 6, spread = 220, size = 40, height = 380, rise = 200, lod = ctx.lod })
end

function Sig.typhoon(ctx, x, y, z)
    Sig.tornado(ctx, x, y, z, { radius = 300, height = 800, life = 2.2 })
    for i, p in ipairs(around(x, y, 420, 3, ctx.yaw)) do
        Sig.tornado(ctx, p[1], p[2], z, { radius = 120, height = 420, life = 1.6 })
    end
end

function Sig.mist_veil(ctx, x, y, z, opts)
    opts = opts or {}
    for i, p in ipairs(around(x, y, opts.radius or 140, opts.count or 6, math.random() * 6)) do
        Toon.Sprite("Cloud", { x = p[1], y = p[2], z = z - 30 + math.random() * 80, size = opts.size or 260,
            alpha = 0.75, life = opts.life or 1.2, fadeIn = 0.1, scale = 0.6, grow = 1.4, rise = 20,
            priority = i <= 2 and "main" or "secondary", lod = ctx.lod })
    end
end

function Sig.mist_dome(ctx, x, y, z)
    Sig.mist_veil(ctx, x, y, z, { radius = 380, count = 10, size = 420, life = 4 })
    Toon.Ground("Cloud", x, y, z - 85, { size = 1200, alpha = 0.6, life = 4, spin = 20, scale = 0.6, grow = 1.0, priority = "main" })
end

-- ---------------------------------------------------------------------------
-- Glace / sang / ombre / fleurs / insecte / son / amour
-- ---------------------------------------------------------------------------

--- Pics de glace qui sortent du sol en cercle.
function Sig.ice_spikes(ctx, x, y, z, opts)
    opts = opts or {}
    Toon.Ground("Ice_Crystal", x, y, z - 88, { size = (opts.radius or 160) * 3, life = 1.4, spin = 15, scale = 0.3, grow = 1.0, lod = ctx.lod })
    for i, p in ipairs(around(x, y, opts.radius or 160, opts.count or 6, math.random() * 6)) do
        local yaw = math.deg(math.atan(p[2] - y, p[1] - x))
        Toon.Wall("Ice_Shard", p[1], p[2], z - 40, yaw, { size = 150, aspect = 1.8, life = 1.3, scale = 0.2, grow = 1.0,
            delay = i * 0.03, priority = i <= 3 and "main" or "secondary", lod = ctx.lod })
    end
end

function Sig.ice_bodhisattva(ctx, x, y, z)
    Toon.Ground("Ice_Crystal", x, y, z - 88, { size = 1300, life = 2.5, spin = 10, scale = 0.2, grow = 1.0, priority = "main" })
    Sig.ice_spikes(ctx, x, y, z, { radius = 420, count = 8 })
    Toon.Wall("Ice_Crystal", x - ctx.fx * 150, y - ctx.fy * 150, z + 350, ctx.yaw, { size = 700, life = 2.0, scale = 0.3, grow = 1.0, alpha = 0.85 })
end

function Sig.blood_burst(ctx, x, y, z)
    Toon.Ground("Sigil", x, y, z - 88, { size = 520, color = { 1, 0.1, 0.15 }, glow = 2.4, life = 0.9, spin = -90, scale = 0.4, grow = 1.1, priority = "main" })
    Toon.Sprite("Blood_Splat", { x = x, y = y, z = z + 30, size = 300, life = 0.5, scale = 0.4, grow = 1.3 })
    Toon.Scatter({ "Blood_Splat" }, x, y, z, { count = 6, spread = 220, size = 50, lod = ctx.lod })
end

function Sig.blood_awakening(ctx, x, y, z)
    Toon.Ground("Sigil", x, y, z - 88, { size = 600, color = { 1, 0.1, 0.15 }, glow = 2.6, life = 2.0, spin = 120, scale = 0.3, grow = 1.0, priority = "main", follow = ctx.caster })
    Toon.Pillar("Swirl_Band", x, y, z - 90, { radius = 120, height = 360, color = { 1, 0.15, 0.2 }, glow = 2, life = 1.2, spin = 300, follow = ctx.caster })
end

function Sig.ink_veil(ctx, x, y, z)
    for i, p in ipairs(around(x, y, 120, 5, math.random() * 6)) do
        Toon.Sprite("Ink_Splash", { x = p[1], y = p[2], z = z, size = 200, alpha = 0.9, life = 0.8, scale = 0.4, grow = 1.3,
            delay = i * 0.03, priority = i <= 2 and "main" or "secondary", lod = ctx.lod })
    end
end

function Sig.eternal_night(ctx, x, y, z)
    Toon.Ground("Spiral_Dense", x, y, z - 85, { size = 1300, color = { 0.45, 0.1, 0.8 }, glow = 1.6, life = 5, spin = 45, scale = 0.3, grow = 1.0, priority = "main", follow = ctx.caster })
    Sig.ink_veil(ctx, x, y, z)
end

function Sig.bloom(ctx, x, y, z, opts)
    opts = opts or {}
    Toon.Ground("Flower_Bloom", x, y, z - 86, { size = opts.size or 360, life = opts.life or 1.0, spin = 40, scale = 0.2, grow = 1.0, lod = ctx.lod, priority = "main" })
    Toon.Scatter({ "Petal" }, x, y, z, { count = opts.petals or 8, spread = 260, size = 40, height = 260, rise = 60, lod = ctx.lod })
end

function Sig.petal_storm(ctx, x, y, z, opts)
    opts = opts or {}
    local seconds = opts.life or 3
    for i = 1, math.floor(seconds * 4) do
        Timer.SetTimeout(function()
            local cx, cy, cz = x, y, z
            if ctx.caster and ctx.caster:IsValid() and opts.follow then
                local loc = ctx.caster:GetLocation(); cx, cy, cz = loc.X, loc.Y, loc.Z
            end
            Toon.Scatter({ "Petal" }, cx, cy, cz, { count = 5, spread = opts.radius or 380, size = 45, height = 300, rise = 40, lod = ctx.lod })
        end, i * 250)
    end
end

function Sig.butterflies(ctx, x, y, z, opts)
    opts = opts or {}
    Toon.Scatter({ "Butterfly" }, x, y, z + 40, { count = opts.count or 6, spread = opts.spread or 260, size = 55,
        height = 220, rise = 80, life = 1.4, lod = ctx.lod })
end

function Sig.wisteria(ctx, x, y, z)
    Toon.Ground("Flower_Bloom", x, y, z - 86, { size = 900, life = 4, spin = 20, scale = 0.3, grow = 1.0, priority = "main" })
    Sig.butterflies(ctx, x, y, z, { count = 10, spread = 480 })
end

function Sig.sound_rings(ctx, x, y, z, opts)
    opts = opts or {}
    for i = 1, opts.count or 3 do
        Toon.Ground("Ring_Shock", x, y, z - 85, { size = 500, color = { 1, 0.4, 0.9 }, glow = 2.2, life = 0.5,
            delay = (i - 1) * 0.1, scale = 0.2, grow = 1.3, lod = ctx.lod, priority = i == 1 and "main" or "secondary" })
    end
    Toon.Wall("Sound_Wave", x, y, z + 40, ctx.yaw, { size = 300, life = 0.4, scale = 0.6, grow = 1.6, lod = ctx.lod })
end

function Sig.score(ctx, x, y, z)
    Toon.Ground("Sigil", x, y, z - 88, { size = 500, color = { 1, 0.45, 0.9 }, glow = 2.2, life = 3, spin = 30, scale = 0.4, grow = 1.0, priority = "main", follow = ctx.caster })
end

function Sig.rocks(ctx, x, y, z)
    Toon.Scatter({ "Rock" }, x, y, z - 40, { count = 7, spread = 240, size = 60, height = 260, lod = ctx.lod })
    Toon.Ground("Ring_Broken", x, y, z - 88, { size = 420, color = { 0.85, 0.75, 0.6 }, glow = 1.2, life = 0.7, scale = 0.3, grow = 1.2 })
end

-- Pack Niagara : système dédié qui remplace la signature (rôle, taille, durée)
local SIG_PACK = {
    tiger_roar = { "Dragon", 1.0 }, inferno = { "Explosion", 1.6 }, fire_pillar = { "Burst", 1.0 }, fire_line = { "Dash", 1.0 },
    sun_seal = { "Burst", 1.2 }, thunder_god = { "Explosion", 1.6 }, bolt_rain = { "Burst", 1.0 }, bolt_ring = { "Burst", 1.0 },
    bolt_line = { "Dash", 1.0 }, tornado = { "Tornado", 1.0 }, typhoon = { "Tornado", 2.2 }, mist_veil = { "Zone", 0.6 },
    mist_dome = { "Zone", 1.6 }, ice_spikes = { "Spikes", 1.0 }, ice_bodhisattva = { "Explosion", 1.8 },
    blood_burst = { "Burst", 1.0 }, blood_awakening = { "Zone", 1.0 }, ink_veil = { "Zone", 0.6 }, eternal_night = { "Zone", 1.8 },
    bloom = { "Burst", 1.0 }, petal_storm = { "Zone", 1.2 }, butterflies = { "Burst", 0.6 }, wisteria = { "Zone", 1.6 },
    sound_rings = { "Burst", 1.0 }, score = { "Zone", 1.0 }, rocks = { "Impact", 1.2 },
}

--- Joue une signature par son nom (sans erreur si elle n'existe pas).
--- Avec le pack Niagara installé, le système dédié de l'élément la remplace.
function VFX.PlaySignature(name, ctx, x, y, z, opts)
    local packed = name and SIG_PACK[name]
    if packed and VFX.Pack.Enabled() then
        local fx, fy = ctx.fx or 1, ctx.fy or 0
        local dist = (opts and opts.length) or 900
        if VFX.Pack.Play(packed[1], ctx.element, x, y, z, { yaw = ctx.yaw, scale = packed[2], direction = { fx, fy, 0 },
                endPoint = { x + fx * dist, y + fy * dist, z }, life = 3.5, lod = ctx.lod }) then
            return
        end
    end
    local fn = name and Sig[name]
    if fn then fn(ctx, x, y, z, opts) end
end

return Sig
