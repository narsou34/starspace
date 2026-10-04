--[[
    Demon Slayer RP - VFX_Projectile et mouvements (client)
    ------------------------------------------------------------------
    VFX.Projectile(element, start, yaw, opts) -> handle
        start = { x, y, z } ; opts : speed, distance, scale, core (couches), width
        Le cœur (couches element.Projectile.Core) se déplace réellement
        (TranslateTo), un ruban coloré est attaché comme traînée, et des
        gerbes sont laissées derrière la tête.
        handle:Impact(x, y, z, size)  explosion + disparition
        handle:Destroy()

    VFX.Dash(element, caster, opts)       élan : flash, rémanence le long du trajet,
                                           traînées sur le corps, particules de vitesse
    VFX.Aura(element, actor, seconds)     enveloppe de l'élément autour d'un personnage
    VFX.Zone(element, center, opts)       zone persistante (corps, orbites, pulsations)
    VFX.Vanish(actor, seconds)            le personnage disparaît (brume) puis réapparaît
]]

local VFX = DS.VFX
local U = DS.VFXUtils
local TMath = DS.TechMath

-- ===========================================================================
-- Projectile
-- ===========================================================================

local Handle = {}
Handle.__index = Handle

function Handle:Head()
    return self.parts[1]
end

function Handle:Destroy()
    self.alive = false
    for _, particle in ipairs(self.parts) do VFX.Destroy(particle) end
    for _, card in ipairs(self.toon or {}) do VFX.Toon.Stop(card, 0.08) end
end

function Handle:Impact(x, y, z, size)
    if not self.alive then return end
    self:Destroy()
    VFX.Impact(self.element, size or "Medium", x, y, z, self.yaw)
end

function VFX.Projectile(element, start, yaw, opts)
    opts = opts or {}
    local spec = element.Projectile or {}
    local speed, distance = opts.speed or 2000, opts.distance or 1500
    local flight = distance / speed
    local scale = opts.scale or 1
    local fx, fy = TMath.Forward(yaw)
    local lod = U.Lod(start[1], start[2], start[3])
    local endX, endY, endZ = start[1] + fx * distance, start[2] + fy * distance, start[3]

    local handle = setmetatable({ element = element, yaw = yaw, alive = true, parts = {} }, Handle)
    handle.parts = VFX.Layers(opts.core or spec.Core, start[1], start[2], start[3], yaw,
        { scale = scale, life = flight + 0.1, priority = "main", lod = lod })
    for _, particle in ipairs(handle.parts) do VFX.MoveTo(particle, endX, endY, endZ, flight) end

    -- Forme anime : tête peinte qui vole jusqu'au bout de la trajectoire
    -- (croissant volant pour les lames d'air / de sang..., sinon boule face caméra)
    local toon = VFX.ToonOf(element)
    local orb = opts.orb or toon.Orb
    local size = (opts.orbSize or 130) * scale
    handle.toon = {}
    if orb:sub(1, 6) == "Slash_" then
        handle.toon[1] = VFX.Toon.Card(orb, {
            x = start[1], y = start[2], z = start[3], right = { fx, fy, 0 }, up = { -fy, fx, 0.25 },
            size = size * 1.6, moveTo = { endX, endY, endZ }, moveTime = flight, life = flight + 0.05,
            fadeIn = 0.03, fadeOut = 0.08, scale = 0.8, grow = 1.15, glow = toon.Glow, lod = lod,
        })
    else
        handle.toon[1] = VFX.Toon.Sprite(orb, {
            x = start[1], y = start[2], z = start[3], size = size, moveTo = { endX, endY, endZ }, moveTime = flight,
            life = flight + 0.05, fadeIn = 0.03, fadeOut = 0.08, scale = 0.7, grow = 1.1,
            color = toon.OrbTint or toon.White, glow = toon.Glow * 1.2, lod = lod,
        })
        handle.toon[2] = VFX.Toon.Sprite("Orb_Soft", {
            x = start[1], y = start[2], z = start[3], size = size * 1.8, moveTo = { endX, endY, endZ }, moveTime = flight,
            life = flight + 0.05, alpha = 0.45, fadeOut = 0.08, color = toon.Tint, glow = toon.Glow, priority = "secondary", lod = lod,
        })
    end

    local head = handle:Head()
    if head then
        VFX.Trail.Attach(element, head, "", { duration = flight, width = (opts.width or spec.TrailWidth or 24) * scale })
    end
    VFX.Burst.Flash(element, start[1], start[2], start[3], 0.5 * scale)
    VFX.Sound.Set(element.Sounds and element.Sounds.Projectile, start[1], start[2], start[3], { attach = head })

    -- Particules secondaires derrière la tête
    local steps = math.floor(flight * 1000 / 90)
    local step = 0
    Timer.SetInterval(function()
        step = step + 1
        if not handle.alive or step > steps then return false end
        local h = handle:Head()
        if h and h:IsValid() then
            local loc = h:GetLocation()
            VFX.Burst.Spray(element, loc.X, loc.Y, loc.Z, yaw + 180, { count = 10, speed = 250, life = 0.5, priority = "detail", lod = lod })
            VFX.Layers(spec.Trail, loc.X, loc.Y, loc.Z, yaw, { priority = "detail", lod = lod })
        end
    end, 90)

    Timer.SetTimeout(function() handle.alive = false end, math.floor(flight * 1000) + 100)
    return handle
end

-- ===========================================================================
-- Élan
-- ===========================================================================

--[[
    opts : yaw (direction), distance (longueur estimée du trajet), duration (s)
]]
function VFX.Dash(element, caster, opts)
    opts = opts or {}
    if not (caster and caster:IsValid()) then return end
    local loc = caster:GetLocation()
    local yaw = opts.yaw or caster:GetRotation().Yaw
    local duration = opts.duration or 0.6
    local distance = opts.distance or 600
    local fx, fy = TMath.Forward(yaw)
    local lod = U.Lod(loc.X, loc.Y, loc.Z)
    local dash = element.Dash or {}

    -- 1. Flash de départ + gerbe vers l'arrière
    VFX.Burst.Flash(element, loc.X, loc.Y, loc.Z, 0.8)
    VFX.Burst.Spray(element, loc.X, loc.Y, loc.Z - 40, yaw + 180, { count = 40, speed = 700, lod = lod })
    VFX.Layers(dash.Start, loc.X, loc.Y, loc.Z, yaw, { priority = "main", lod = lod })
    -- Brume / ombre : le personnage se dissout puis réapparaît plus loin
    if dash.Vanish then VFX.Vanish(caster, dash.Vanish) end

    -- 2. Rémanence : traînée le long du trajet (plus rapide que le personnage)
    local endPoint = { loc.X + fx * distance, loc.Y + fy * distance, loc.Z }
    VFX.Trail.Path(element, { { loc.X, loc.Y, loc.Z }, endPoint }, 0.12, { width = (element.Trail and element.Trail.DashWidth) or 60, lod = lod })
    if dash.Lightning then
        VFX.Burst.Lightning(element, { loc.X, loc.Y, loc.Z + 40 }, { endPoint[1], endPoint[2], endPoint[3] + 40 }, { bolts = 2, spread = 160 })
    end

    -- 2b. Forme anime : lignes de vitesse au départ + traits de l'élément le long du trajet
    local toon = VFX.ToonOf(element)
    VFX.Toon.Sprite("Speed_Lines", { x = loc.X, y = loc.Y, z = loc.Z, size = 320, scale = 0.6, grow = 1.4,
        color = toon.Tint, glow = toon.Glow, life = 0.25, fadeOut = 0.18, lod = lod })
    local strokes = math.max(2, math.floor(distance / 220))
    for i = 1, strokes do
        local k = i / (strokes + 1)
        local px, py = loc.X + fx * distance * k, loc.Y + fy * distance * k
        if toon.Dash == "Bolt" or toon.Dash:sub(1, 6) == "Slash_" then
            -- trait couché le long du trajet (éclair, eau qui file)
            VFX.Toon.Card(toon.Dash, {
                x = px, y = py, z = loc.Z - 30, right = { -fy, fx, 0 }, up = { fx, fy, 0.15 },
                size = 160, aspect = 1.6, glow = toon.Glow * 1.2, life = 0.35, fadeIn = 0.02, fadeOut = 0.22,
                delay = duration * k * 0.6, priority = i == 1 and "main" or "secondary", lod = lod,
            })
        else
            VFX.Toon.Sprite(toon.Dash, {
                x = px, y = py, z = loc.Z + (math.random() - 0.5) * 60, size = 110, scale = 0.8, grow = 1.3,
                glow = toon.Glow, life = 0.45, fadeOut = 0.3, delay = duration * k * 0.6,
                priority = i == 1 and "main" or "secondary", lod = lod,
            })
        end
    end

    -- 3. Traînées sur le corps + lame
    VFX.Trail.Attach(element, caster, "foot_l", { duration = duration, width = 14, core = false, priority = "secondary" })
    VFX.Trail.Attach(element, caster, "foot_r", { duration = duration, width = 14, core = false, priority = "secondary" })
    VFX.Trail.Attach(element, caster, "pelvis", { duration = duration, width = 30, core = false, priority = "detail" })
    VFX.Trail.Blade(element, caster, duration)

    -- 4. Particules de vitesse pendant l'élan
    local stop = math.floor(duration * 1000)
    local elapsed = 0
    Timer.SetInterval(function()
        elapsed = elapsed + 70
        if elapsed > stop or not caster:IsValid() then return false end
        local p = caster:GetLocation()
        VFX.Layers(dash.Path, p.X, p.Y, p.Z - 40, yaw, { priority = "detail", lod = lod })
        if dash.Lightning and elapsed % 140 == 0 then
            local a = math.random() * 2 * math.pi
            VFX.Burst.Beam(element, { p.X, p.Y, p.Z }, { p.X + math.cos(a) * 120, p.Y + math.sin(a) * 120, p.Z + (math.random() - 0.5) * 120 },
                { width = 3, jitter = 0.7, life = 0.08, priority = "detail" })
        end
    end, 70)

    VFX.Sound.Set(element.Sounds and element.Sounds.Dash, loc.X, loc.Y, loc.Z)
end

-- ===========================================================================
-- Aura / zone / disparition
-- ===========================================================================

function VFX.Aura(element, actor, seconds)
    if not (actor and actor:IsValid()) then return end
    local aura = element.Aura or {}
    for _, layer in ipairs(aura.Layers or {}) do
        VFX.Attach(layer.Asset, actor, layer.Bone or "pelvis", {
            life = seconds, scale = layer.Scale, priority = layer.Priority or "secondary", params = layer.Params,
        })
    end
    VFX.Trail.Attach(element, actor, "hand_r", { duration = seconds, width = 10, core = false, priority = "detail" })
    VFX.Trail.Attach(element, actor, "hand_l", { duration = seconds, width = 10, core = false, priority = "detail" })
    -- anneau peint sous les pieds qui suit le personnage + halo
    local toon = VFX.ToonOf(element)
    local loc = actor:GetLocation()
    VFX.Toon.Ground(toon.Ground, loc.X, loc.Y, loc.Z - 88, { size = 240, scale = 0.6, grow = 1.0, spin = 90,
        color = toon.Tint, glow = toon.Glow, alpha = 0.7, life = seconds, fadeOut = 0.4, follow = actor })
    VFX.Toon.Sprite("Orb_Soft", { x = loc.X, y = loc.Y, z = loc.Z, size = 220, alpha = 0.35, color = toon.Tint,
        glow = toon.Glow, life = seconds, fadeOut = 0.4, follow = actor, priority = "secondary" })
    local elapsed = 0
    Timer.SetInterval(function()
        elapsed = elapsed + 450
        if elapsed > seconds * 1000 or not actor:IsValid() then return false end
        local loc = actor:GetLocation()
        VFX.Burst.Sphere(element, loc.X, loc.Y, loc.Z, { count = 18, speed = 180, radius = 60, life = 0.8, priority = "detail" })
    end, 450)
end

--[[
    VFX.Zone(element, getCenter, opts)
      getCenter() -> x, y, z (permet une zone qui suit un personnage)
      opts : radius, height, seconds, follow (acteur), orbit (nombre d'orbites)
]]
function VFX.Zone(element, getCenter, opts)
    local zone = element.Zone or {}
    local seconds = opts.seconds or 3
    local radius, height = opts.radius or 400, opts.height or 500
    local cx, cy, cz = getCenter()
    local lod = U.Lod(cx, cy, cz)
    local scale = radius / 400

    if opts.follow and opts.follow:IsValid() then
        for _, layer in ipairs(zone.Core or {}) do
            VFX.Attach(layer.Asset, opts.follow, "pelvis", { life = seconds, scale = (layer.Scale or 1) * scale, priority = layer.Priority or "main", params = layer.Params })
        end
    else
        VFX.Layers(zone.Core, cx, cy, cz, 0, { scale = scale, life = seconds, priority = "main", lod = lod })
    end
    VFX.Burst.Ring(element, cx, cy, cz, scale)

    -- Forme anime : motif au sol qui tourne + colonne / tornade peinte
    local toon = VFX.ToonOf(element)
    VFX.Toon.Ground(toon.Ground, cx, cy, cz - 85, { size = radius * 2.2, scale = 0.3, grow = 1.0,
        spin = (zone.Spin or 5) * 40, color = toon.Tint, glow = toon.Glow, alpha = 0.85,
        life = seconds, fadeIn = 0.25, fadeOut = 0.5, priority = "main", follow = opts.follow })
    if not opts.flat then
        VFX.Toon.Pillar(toon.Pillar, cx, cy, cz - 85, { radius = radius * 0.8, height = height, count = 3,
            spin = (zone.Spin or 5) * 60, color = toon.Tint, glow = toon.Glow, alpha = 0.65,
            life = seconds, fadeOut = 0.5, follow = opts.follow })
    end

    -- Orbites : particules qui tournent en spirale montante
    local orbs = {}
    local count = math.max(2, math.floor((opts.orbit or 6) * lod))
    for i = 1, count do
        orbs[i] = {
            particle = VFX.Spawn(zone.Orbit or "nanos-world::P_OmnidirectionalBurst", cx, cy, cz, {
                life = seconds, scale = zone.OrbitScale or 0.6, priority = i <= 2 and "main" or "detail", lod = lod,
            }),
            ribbon = (i <= 3) and VFX.Trail.Ribbon(element, cx, cy, cz, { duration = seconds, width = 18, trailLife = 0.5, lod = lod }) or nil,
            phase = (i / count) * 2 * math.pi, rise = i / count,
        }
    end
    local start = DS.Utils.NowMs()
    Timer.SetInterval(function()
        local t = (DS.Utils.NowMs() - start) / 1000
        if t > seconds then return false end
        local x, y, z = getCenter()
        for _, orb in ipairs(orbs) do
            local h = (orb.rise + t * (zone.RiseSpeed or 0.45)) % 1
            local r = radius * (0.9 - h * 0.45)
            local angle = orb.phase + t * (zone.Spin or 5)
            local pos = Vector(x + math.cos(angle) * r, y + math.sin(angle) * r, z + 40 + h * height)
            if orb.particle and orb.particle:IsValid() then pcall(orb.particle.SetLocation, orb.particle, pos) end
            if orb.ribbon and orb.ribbon:IsValid() then pcall(orb.ribbon.SetLocation, orb.ribbon, pos) end
        end
    end, 50)

    -- Pulsations au sol et particules ambiantes
    Timer.SetInterval(function()
        if (DS.Utils.NowMs() - start) / 1000 > seconds then return false end
        local x, y, z = getCenter()
        local a, r = math.random() * 2 * math.pi, radius * (0.3 + math.random() * 0.7)
        VFX.Layers(zone.Ambient, x + math.cos(a) * r, y + math.sin(a) * r, z + math.random() * height * 0.4, 0,
            { priority = "detail", lod = lod })
        VFX.Burst.Spray(element, x + math.cos(a) * r, y + math.sin(a) * r, z, math.deg(a), { count = 12, speed = 300, pitch = 40, priority = "detail", lod = lod })
    end, 180)

    VFX.Sound.Set(element.Sounds and element.Sounds.Loop, cx, cy, cz, { attach = opts.follow })
end

--- Disparition dans la brume : le personnage devient invisible (localement) puis réapparaît.
function VFX.Vanish(actor, seconds)
    if not (actor and actor:IsValid()) then return end
    pcall(actor.SetVisibility, actor, false)
    Timer.SetTimeout(function()
        if actor:IsValid() then pcall(actor.SetVisibility, actor, true) end
    end, math.floor(seconds * 1000))
end

return Handle
