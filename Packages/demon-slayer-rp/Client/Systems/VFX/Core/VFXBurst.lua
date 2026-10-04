--[[
    Demon Slayer RP - VFX_Burst : coupes, éclairs, flashs, gerbes (client)
    ------------------------------------------------------------------
      VFX.Burst.Flash(element, x, y, z, size)          éclair lumineux bref (blanc + couleur)
      VFX.Burst.Spray(element, x, y, z, yaw, opts)     gerbe directionnelle colorée
      VFX.Burst.Sphere(element, x, y, z, opts)         explosion de particules colorées
      VFX.Burst.Ring(element, x, y, z, size)           onde de choc au sol
      VFX.Burst.Beam(element, from, to, opts)          rayon / ligne d'énergie (P_Beam)
      VFX.Burst.Lightning(element, from, to, opts)     éclairs ramifiés et clignotants

      VFX.Slash(element, caster, opts)                 COUPE en arc qui suit le mouvement de la lame
      VFX.Thrust(element, x, y, z, yaw, length, opts)  estoc : trait droit + gerbe à la pointe

    Une coupe = ruban large coloré + fil central blanc qui parcourent l'arc
    en ~0,12 s, couches propres à l'élément au milieu de l'arc, puis flash et
    gerbe tangente à la fin du mouvement, et son de l'élément.
]]

local VFX = DS.VFX
local U = DS.VFXUtils
local TMath = DS.TechMath

local Burst = {}
VFX.Burst = Burst

local OMNI = "nanos-world::P_OmnidirectionalBurst"
local DIRECTIONAL = "nanos-world::P_DirectionalBurst"
local BEAM = "nanos-world::P_Beam"

function Burst.Flash(element, x, y, z, size)
    size = size or 1
    VFX.Spawn(OMNI, x, y, z, {
        life = 0.4, priority = "main",
        params = { Color = Color(8, 8, 8, 1), SpawnCount = 18 * size, SphereRadius = 6, VelocityStrengthMax = 260 * size, VelocityStrengthMin = 80 },
    })
    VFX.Spawn(OMNI, x, y, z, {
        life = 0.6, priority = "secondary",
        params = { Color = VFX.Glow(element, "Highlight", 1.4), SpawnCount = 30 * size, SphereRadius = 10 * size,
                   VelocityStrengthMax = 420 * size, VelocityStrengthMin = 120 },
    })
end

function Burst.Spray(element, x, y, z, yaw, opts)
    opts = opts or {}
    local lod = opts.lod or U.Lod(x, y, z)
    return VFX.Spawn(DIRECTIONAL, x, y, z, {
        yaw = yaw, pitch = opts.pitch or 0, life = opts.life or 0.9, priority = opts.priority or "secondary", lod = lod,
        params = {
            Color = VFX.Glow(element, opts.color or "Accent"),
            SpawnCount = (opts.count or 30) * lod,
            VelocityStrengthMax = opts.speed or 600, VelocityStrengthMin = (opts.speed or 600) * 0.35,
        },
    })
end

function Burst.Sphere(element, x, y, z, opts)
    opts = opts or {}
    local lod = opts.lod or U.Lod(x, y, z)
    return VFX.Spawn(OMNI, x, y, z, {
        life = opts.life or 1.0, priority = opts.priority or "secondary", lod = lod,
        params = {
            Color = VFX.Glow(element, opts.color or "Core"),
            SpawnCount = (opts.count or 50) * lod,
            SphereRadius = opts.radius or 20,
            VelocityStrengthMax = opts.speed or 450, VelocityStrengthMin = (opts.speed or 450) * 0.3,
        },
    })
end

function Burst.Ring(element, x, y, z, size)
    local ring = element.Impact and element.Impact.Ring
    if ring then
        VFX.Spawn(ring, x, y, z, { scale = size or 1, life = 1.2, priority = "secondary" })
    end
end

function Burst.Beam(element, from, to, opts)
    opts = opts or {}
    return VFX.Spawn(BEAM, from[1], from[2], from[3], {
        life = opts.life or 0.25, priority = opts.priority or "secondary",
        params = {
            BeamColor = VFX.Glow(element, opts.color or "Highlight", opts.glow or 2),
            BeamEnd = Vector(to[1], to[2], to[3]),
            BeamWidth = opts.width or 6,
            JitterAmount = opts.jitter or 0.1,
        },
    })
end

--- Éclairs : plusieurs rayons ramifiés, qui clignotent (3 vagues en 120 ms).
function Burst.Lightning(element, from, to, opts)
    opts = opts or {}
    local bolts = opts.bolts or 3
    for wave = 0, 2 do
        Timer.SetTimeout(function()
            for _ = 1, bolts do
                local mid = {
                    (from[1] + to[1]) / 2 + (math.random() - 0.5) * (opts.spread or 120),
                    (from[2] + to[2]) / 2 + (math.random() - 0.5) * (opts.spread or 120),
                    (from[3] + to[3]) / 2 + (math.random() - 0.5) * (opts.spread or 120) * 0.6,
                }
                Burst.Beam(element, from, mid, { width = opts.width or 5, jitter = 0.6, life = 0.12, priority = "secondary" })
                Burst.Beam(element, mid, to, { width = (opts.width or 5) * 0.7, jitter = 0.6, life = 0.12, priority = "detail" })
            end
        end, wave * 45)
    end
end

-- ===========================================================================
-- Coupes
-- ===========================================================================

--[[
    VFX.Slash(element, caster, opts)
      opts : yaw (défaut : orientation du lanceur), x, y, z (centre), radius (180),
             from / to (angles relatifs, défaut -75 -> 75), upFrom / upTo (hauteurs :
             diagonale), duration (0.12 s), width, scale (taille globale), lod
]]
function VFX.Slash(element, caster, opts)
    opts = opts or {}
    local x, y, z, yaw = opts.x, opts.y, opts.z, opts.yaw
    if (not x) and caster and caster:IsValid() then
        local loc = caster:GetLocation()
        x, y, z = loc.X, loc.Y, loc.Z
        yaw = yaw or caster:GetRotation().Yaw
    end
    if not x then return end
    yaw = yaw or 0
    local scale = opts.scale or 1
    local lod = opts.lod or U.Lod(x, y, z)
    local radius = (opts.radius or 180) * scale
    local from, to = opts.from or -75, opts.to or 75
    local duration = opts.duration or 0.12
    local points = U.ArcPoints(x, y, z, yaw, radius, from, to, 8, opts.upFrom or 110, opts.upTo or 10)

    local spec = element.Trail or {}
    VFX.Trail.Path(element, points, duration, {
        width = (opts.width or spec.SlashWidth or 40) * scale, trailLife = spec.SlashLife or 0.3, lod = lod,
    })

    -- Couches de l'élément au milieu puis à la fin de l'arc
    local mid, last = points[5], points[#points]
    local slash = element.Slash or {}
    Timer.SetTimeout(function()
        VFX.Layers(slash.Body, mid[1], mid[2], mid[3], yaw + (from + to) / 2, { scale = scale, lod = lod })
    end, math.floor(duration * 500))
    Timer.SetTimeout(function()
        local tangent = yaw + to + (to > from and 90 or -90)
        Burst.Flash(element, last[1], last[2], last[3], 0.6 * scale)
        Burst.Spray(element, last[1], last[2], last[3], tangent, { count = (slash.Sparks or 30) * scale, speed = 650 * scale, lod = lod })
        VFX.Layers(slash.Tip, last[1], last[2], last[3], tangent, { scale = scale, lod = lod })
    end, math.floor(duration * 1000))
    VFX.Sound.Set(element.Sounds and element.Sounds.Slash, x, y, z)
end

--- Estoc / trait droit : ruban rapide + rayon lumineux + gerbe à la pointe.
function VFX.Thrust(element, x, y, z, yaw, length, opts)
    opts = opts or {}
    local lod = opts.lod or U.Lod(x, y, z)
    local fx, fy = TMath.Forward(yaw)
    local h = opts.up or 60
    local tip = { x + fx * length, y + fy * length, z + h }
    local base = { x + fx * 60, y + fy * 60, z + h }
    VFX.Trail.Path(element, { base, tip }, opts.duration or 0.08, { width = opts.width or 22, lod = lod })
    Burst.Beam(element, base, tip, { width = (opts.width or 22) * 0.25, life = 0.15, jitter = 0.05 })
    Timer.SetTimeout(function()
        Burst.Spray(element, tip[1], tip[2], tip[3], yaw, { count = 25, speed = 700, lod = lod })
        VFX.Layers(element.Slash and element.Slash.Tip, tip[1], tip[2], tip[3], yaw, { lod = lod })
    end, 80)
    VFX.Sound.Set(element.Sounds and element.Sounds.Slash, x, y, z, { pitch = 1.15 })
end

return Burst
