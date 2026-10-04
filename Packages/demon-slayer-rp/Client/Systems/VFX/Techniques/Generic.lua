--[[
    Demon Slayer RP - VFX des comportements génériques (client)
    ------------------------------------------------------------------
    Chorégraphies des scripts serveur "combo", "bursts", "projectiles",
    "buff", "dash", "dashchain", "zone", "whip", "beast"
    (Server/Systems/Techniques/Generic.lua).

    Le rendu vient de l'ÉLÉMENT du souffle / de l'art (Client/Systems/VFX/Elements)
    via le VFXManager : coupes en arc, estocs, projectiles, élans, zones,
    impacts Small -> Massive. La table Fx d'une technique (optionnelle) ajoute
    des couches propres à la technique :
      Fx = { Cast, CastSounds, Body, Attach, Trail, TrailEveryMs, Strike,
             Burst, BurstSounds, Hit, HitSounds, Orbit, Segment }
]]

local GenericVfx = DS.Module("GenericVfx", { dependencies = { "VFXManager" } })

local VFX = DS.VFX
local TMath = DS.TechMath

-- ---------------------------------------------------------------------------
-- Outils
-- ---------------------------------------------------------------------------

local function fxOf(ctx) return ctx.tech.Fx or {} end
local function lookOf(ctx) return VFX.LookOf(ctx.tech) end

-- Signatures d'élan jouées au DÉPART (traits le long du trajet) ; les autres à l'arrivée
local DASH_AT_START = { fire_line = true, bolt_line = true, thunder_god = true, mist_veil = true, ink_veil = true, butterflies = true }

--[[
    Coupe selon le look de la technique : orientation du croissant (Planes),
    taille (Scale), croissants parallèles (Multi, griffes), ultime (Big).
]]
local function lookSlash(ctx, index, opts)
    local look = lookOf(ctx)
    opts = opts or {}
    opts.plane = opts.plane or VFX.PlaneOf(look, index)
    opts.scale = (opts.scale or 1) * (look.Scale or 1) * (look.Big and 1.35 or 1)
    opts.big = opts.big or look.Big
    opts.lod = opts.lod or ctx.lod
    local multi = look.Multi or 1
    if multi <= 1 then
        VFX.Slash(ctx.element, ctx.caster, opts)
        return
    end
    local x, y, z, yaw = ctx:CasterTransform()
    local fx, fy = TMath.Forward(yaw)
    for m = 1, multi do
        local side = (m - (multi + 1) / 2) * 55
        local px, py, pz = TMath.Point(x, y, z, fx, fy, 0, side, (m - 1) * 8)
        local copy = {}
        for k, v in pairs(opts) do copy[k] = v end
        copy.x, copy.y, copy.z, copy.yaw = px, py, pz, yaw
        Timer.SetTimeout(function() VFX.Slash(ctx.element, ctx.caster, copy) end, (m - 1) * 35)
    end
end

local function attachLayers(layers, actor, seconds)
    for _, layer in ipairs(layers or {}) do
        VFX.Attach(layer.Asset, actor, layer.Bone or "", {
            scale = layer.Scale, life = seconds or layer.Life or 1.2, priority = layer.Priority or "secondary", params = layer.Params,
        })
    end
end

-- Préparation : couches de lancement, cercle d'élément, sons, caméra du lanceur
local function cast(ctx)
    local fx, o = fxOf(ctx), ctx.origin
    local look = lookOf(ctx)
    if look.OnRelease then
        ctx:At(ctx.tech.Timeline.WindupMs, function()
            local x, y, z = ctx:CasterTransform()
            VFX.PlaySignature(look.OnRelease, ctx, x, y, z)
        end)
    end
    VFX.Layers(fx.Cast, o.x, o.y, o.z - 60, ctx.yaw, { priority = "main", lod = ctx.lod })
    VFX.Sound.Set(fx.CastSounds, o.x, o.y, o.z)
    if ctx.tech.Caster then
        -- Ultime : l'élément se concentre autour du lanceur pendant la préparation
        VFX.Aura(ctx.element, ctx.caster, ctx.tech.Timeline.WindupMs / 1000)
        VFX.Burst.Ring(ctx.element, o.x, o.y, o.z - 85, 1.4)
    end
    local camera = ctx.tech.Camera
    if ctx.isLocal and camera then
        local total = ctx.tech.Timeline.WindupMs + (camera.DurationMs or 400)
        if camera.ArmLength then VFX.Camera.Pull(camera.ArmLength, total) end
        ctx:At(ctx.tech.Timeline.WindupMs, function() VFX.Camera.Fov(camera.Fov, camera.DurationMs or 400) end)
    end
end

local function hitSize(ctx, damage)
    return VFX.ImpactSizeFor(damage or (ctx.tech.Hit and ctx.tech.Hit.Damage) or ctx.tech.Damage or 10)
end

local function onHit(ctx, x, y, z)
    local fx = fxOf(ctx)
    VFX.Impact(ctx.element, hitSize(ctx), x, y, z, ctx.yaw)
    VFX.Layers(fx.Hit, x, y, z, ctx.yaw, { priority = "secondary", lod = ctx.lod })
    VFX.Sound.Set(fx.HitSounds, x, y, z)
end

local function onBurst(ctx, x, y, z, size)
    local fx = fxOf(ctx)
    VFX.PlaySignature(lookOf(ctx).OnBurst, ctx, x, y, z)
    VFX.Impact(ctx.element, size or "Large", x, y, z, ctx.yaw)
    VFX.Layers(fx.Burst, x, y, z, ctx.yaw, { priority = "main", lod = ctx.lod })
    VFX.Sound.Set(fx.BurstSounds, x, y, z)
end

local function defaultEvent(ctx, event, x, y, z)
    if event == "hit" then onHit(ctx, x, y, z)
    elseif event == "burst" then onBurst(ctx, x, y, z, "Large") end
end

-- ---------------------------------------------------------------------------
-- combo : chaque coup = une coupe qui suit la lame
-- ---------------------------------------------------------------------------
VFX.RegisterChoreography("combo", {
    Start = function(ctx)
        cast(ctx)
        local combo, fx = ctx.tech.Combo, fxOf(ctx)
        for i = 1, combo.Count do
            ctx:At(ctx.tech.Timeline.WindupMs + (i - 1) * combo.IntervalMs, function()
                local x, y, z, yaw = ctx:CasterTransform()
                local swing = (i % 2 == 0) and -1 or 1
                ctx:BladeTrail(combo.IntervalMs + 200)
                if combo.Shape == "circle" then
                    lookSlash(ctx, i, { radius = math.max(160, combo.Range * 0.55), from = i * 40,
                        to = i * 40 + 330 * swing, upFrom = 80, upTo = 40, duration = math.min(0.2, combo.IntervalMs / 1000) })
                elseif combo.Shape == "line" then
                    VFX.Thrust(ctx.element, x, y, z, yaw + swing * 4, combo.Range, { width = combo.Width and combo.Width / 8 or 20, lod = ctx.lod })
                else
                    local half = math.min((combo.Angle or 90) / 2 + 10, 100)
                    lookSlash(ctx, i, { radius = math.max(150, combo.Range * 0.45), from = -half * swing,
                        to = half * swing, upFrom = 60 + 50 * swing, upTo = 60 - 50 * swing })
                end
                local fwdX, fwdY = TMath.Forward(yaw)
                local reach = combo.Shape == "circle" and 0 or combo.Range * 0.5
                VFX.Layers(fx.Body, x + fwdX * reach, y + fwdY * reach, z, yaw, { priority = "secondary", lod = ctx.lod })
                VFX.Sound.Set(fx.Strike, x, y, z)
            end)
        end
    end,
    Event = defaultEvent,
})

-- ---------------------------------------------------------------------------
-- bursts : explosions programmées (mêmes positions / délais que le serveur)
-- ---------------------------------------------------------------------------
VFX.RegisterChoreography("bursts", {
    Start = function(ctx)
        cast(ctx)
        ctx:At(ctx.tech.Timeline.WindupMs - 80, function()
            ctx:BladeTrail(500)
            lookSlash(ctx, 1, { radius = 210, from = -50, to = 50, upFrom = 220, upTo = -40, width = 60 })
        end)
        for _, burst in ipairs(TMath.BurstList(ctx.tech.Bursts)) do
            ctx:At(ctx.tech.Timeline.WindupMs + burst.delay, function()
                local x, y, z = ctx:Point(burst.forward, burst.side, 0)
                onBurst(ctx, x, y, z, VFX.ImpactSizeFor(burst.damage))
            end)
        end
    end,
    Event = function(ctx, event, x, y, z)
        if event == "hit" then onHit(ctx, x, y, z) end
    end,
})

-- ---------------------------------------------------------------------------
-- projectiles : VFX_Projectile qui suit réellement la trajectoire serveur
-- ---------------------------------------------------------------------------
VFX.RegisterChoreography("projectiles", {
    Start = function(ctx)
        cast(ctx)
        local pr, fx = ctx.tech.Projectiles, fxOf(ctx)
        ctx.data.shots = {}
        ctx:At(ctx.tech.Timeline.WindupMs - 60, function()
            ctx:BladeTrail(450)
            lookSlash(ctx, 1, { radius = 160, from = 70, to = -40, upFrom = 140, upTo = 60 })
        end)
        ctx:At(ctx.tech.Timeline.WindupMs, function()
            for i = 1, pr.Count do
                local offset = (pr.Count > 1) and ((i - 1) / (pr.Count - 1) - 0.5) * pr.SpreadDeg or 0
                local dx, dy = TMath.Rotate(ctx.fx, ctx.fy, offset)
                local sx, sy, sz = ctx:Point(pr.SpawnForward or 100, 0, pr.SpawnHeight or 40)
                local shot = VFX.Projectile(ctx.element, { sx, sy, sz }, math.deg(math.atan(dy, dx)), {
                    speed = pr.Speed, distance = pr.MaxDistance, core = fx.Body, scale = pr.Radius >= 150 and 1.4 or 1,
                    orb = lookOf(ctx).Orb, orbSize = lookOf(ctx).OrbSize,
                })
                if shot:Head() then attachLayers(fx.Attach, shot:Head(), pr.MaxDistance / pr.Speed) end
                ctx.data.shots[i] = shot
            end
            VFX.Sound.Set(fx.Strike, ctx.origin.x, ctx.origin.y, ctx.origin.z)
        end)
    end,
    Event = function(ctx, event, x, y, z)
        local index = tonumber(event:match("^impact:(%d+)$"))
        if index then
            local shot = ctx.data.shots and ctx.data.shots[index]
            local pr = ctx.tech.Projectiles
            local size = pr.Explosion and VFX.ImpactSizeFor(pr.Explosion.Damage * 2) or "Small"
            if shot then shot:Destroy() end
            onBurst(ctx, x, y, z, size)
        elseif event == "hit" then
            onHit(ctx, x, y, z)
        end
    end,
})

-- ---------------------------------------------------------------------------
-- buff : aura de l'élément + pulsations
-- ---------------------------------------------------------------------------
VFX.RegisterChoreography("buff", {
    Start = function(ctx)
        cast(ctx)
        local fx = fxOf(ctx)
        local seconds = (ctx.tech.Buff.DurationMs or 3000) / 1000
        ctx:At(ctx.tech.Timeline.WindupMs, function()
            local x, y, z = ctx:CasterTransform()
            VFX.Burst.Flash(ctx.element, x, y, z, 1.2)
            VFX.Burst.Sphere(ctx.element, x, y, z, { count = 80, speed = 500, radius = 60 })
            VFX.Burst.Ring(ctx.element, x, y, z - 80, 1.2)
            VFX.Aura(ctx.element, ctx.caster, seconds)
            attachLayers(fx.Attach, ctx.caster, seconds)
            VFX.Layers(fx.Body, x, y, z, ctx.yaw, { priority = "main", lod = ctx.lod })
            VFX.Sound.Set(fx.Strike, x, y, z)
        end)
        local aura = ctx.tech.Aura
        if aura then
            ctx:Every(ctx.tech.Timeline.WindupMs, ctx.tech.Timeline.WindupMs + aura.DurationMs, aura.TickMs, function()
                local x, y, z = ctx:CasterTransform()
                VFX.Burst.Ring(ctx.element, x, y, z - 80, aura.Radius / 300)
                VFX.Layers(fx.Trail, x, y, z - 60, ctx.yaw, { priority = "detail", lod = ctx.lod })
            end)
        end
    end,
    Event = defaultEvent,
})

-- ---------------------------------------------------------------------------
-- dash / dashchain : VFX.Dash à chaque élan + coupe à l'arrivée
-- ---------------------------------------------------------------------------
local function dashes(ctx, count, interval, offsets, distance)
    cast(ctx)
    local fx = fxOf(ctx)
    for i = 1, count do
        ctx:At(ctx.tech.Timeline.WindupMs + (i - 1) * interval, function()
            local x, y, z, yaw = ctx:CasterTransform()
            yaw = yaw + (offsets and offsets[i] or 0)
            VFX.Dash(ctx.element, ctx.caster, { yaw = yaw, distance = distance, duration = (interval + 250) / 1000 })
            local look = lookOf(ctx)
            if look.OnDash and DASH_AT_START[look.OnDash] then VFX.PlaySignature(look.OnDash, ctx, x, y, z) end
            attachLayers(fx.Attach, ctx.caster, (interval + 300) / 1000)
            VFX.Layers(fx.Body, x, y, z, yaw, { priority = "secondary", lod = ctx.lod })
            VFX.Sound.Set(fx.Strike, x, y, z)
        end)
        ctx:At(ctx.tech.Timeline.WindupMs + (i - 1) * interval + math.min(200, interval * 0.7), function()
            local swing = (i % 2 == 0) and -1 or 1
            lookSlash(ctx, i, { radius = 170, from = -80 * swing, to = 80 * swing })
            local look = lookOf(ctx)
            if look.OnDash and not DASH_AT_START[look.OnDash] then
                local x, y, z = ctx:CasterTransform()
                VFX.PlaySignature(look.OnDash, ctx, x, y, z)
            end
        end)
    end
end

VFX.RegisterChoreography("dash", {
    Start = function(ctx) dashes(ctx, 1, 450, nil, ctx.tech.Dash.Distance) end,
    Event = defaultEvent,
})

VFX.RegisterChoreography("dashchain", {
    Start = function(ctx)
        local dash = ctx.tech.Dash
        dashes(ctx, dash.Count, dash.IntervalMs, dash.AngleOffsets, dash.Distance)
    end,
    Event = defaultEvent,
})

-- ---------------------------------------------------------------------------
-- zone : VFX.Zone (corps, orbites spiralées, pulsations) + explosion finale
-- ---------------------------------------------------------------------------
VFX.RegisterChoreography("zone", {
    Start = function(ctx)
        cast(ctx)
        local zone, fx, tl = ctx.tech.Zone, fxOf(ctx), ctx.tech.Timeline
        local function center()
            if zone.Follow then
                local x, y, z = ctx:CasterTransform()
                return x, y, z - 90
            end
            return ctx:Point(zone.Forward or 0, 0, -90)
        end
        ctx:At(tl.WindupMs, function()
            ctx:BladeTrail(600)
            local x, y, z = ctx:CasterTransform()
            if zone.Follow then
                lookSlash(ctx, 1, { radius = 200, from = 0, to = 350, upFrom = 60, upTo = 60, duration = 0.25 })
            else
                lookSlash(ctx, 1, { radius = 190, from = -70, to = 70 })
            end
            VFX.Zone(ctx.element, center, {
                flat = lookOf(ctx).FlatZone,
                radius = zone.Radius, height = zone.Height, seconds = zone.DurationMs / 1000,
                follow = zone.Follow and ctx.caster or nil, orbit = (fx.Orbit and fx.Orbit.Count) or 6,
            })
            local cx, cy, cz = center()
            if zone.Follow and ctx.caster and ctx.caster:IsValid() then
                attachLayers(fx.Body, ctx.caster, zone.DurationMs / 1000)
            else
                VFX.Layers(fx.Body, cx, cy, cz, ctx.yaw, { life = zone.DurationMs / 1000, priority = "main", lod = ctx.lod })
            end
            VFX.Sound.Set(fx.Strike, cx, cy, cz)
        end)
        if fx.Trail then
            ctx:Every(tl.WindupMs, tl.WindupMs + zone.DurationMs, fx.TrailEveryMs or 200, function()
                local cx, cy, cz = center()
                local a, r = math.random() * 2 * math.pi, zone.Radius * (0.3 + math.random() * 0.7)
                VFX.Layers(fx.Trail, cx + math.cos(a) * r, cy + math.sin(a) * r, cz + math.random() * zone.Height * 0.5,
                    ctx.yaw, { priority = "detail", lod = ctx.lod })
            end)
        end
    end,
    Event = function(ctx, event, x, y, z)
        if event == "burst" then onBurst(ctx, x, y, z, "Massive")
        elseif event == "hit" then
            -- Ticks fréquents : petit impact seulement (lisibilité + performance)
            VFX.Impact(ctx.element, "Small", x, y, z, ctx.yaw)
        end
    end,
})

-- ---------------------------------------------------------------------------
-- whip : rubans colorés qui suivent exactement la trajectoire du serveur
-- ---------------------------------------------------------------------------
local STEP = 70

VFX.RegisterChoreography("whip", {
    Start = function(ctx)
        cast(ctx)
        local whip, fx, tl = ctx.tech.Whip, fxOf(ctx), ctx.tech.Timeline
        local heads = {}
        local seconds = whip.DurationMs / 1000
        ctx:At(tl.WindupMs, function()
            ctx:BladeTrail(whip.DurationMs + 200)
            VFX.Sound.Set(fx.Strike, ctx.origin.x, ctx.origin.y, ctx.origin.z)
            for head = 1, (whip.Heads or 1) do
                local x, y, z = ctx:Point(TMath.WhipAt(0, whip, head))
                local parts = VFX.Layers(fx.Body or (ctx.element.Projectile and ctx.element.Projectile.Core), x, y, z, ctx.yaw,
                    { life = seconds + 0.2, priority = "main", lod = ctx.lod })
                parts[#parts + 1] = VFX.Trail.Ribbon(ctx.element, x, y, z, { duration = seconds + 0.6, width = whip.Radius * 0.35, trailLife = 0.45 })
                parts[#parts + 1] = VFX.Trail.Ribbon(ctx.element, x, y, z, { duration = seconds + 0.6, width = whip.Radius * 0.1, trailLife = 0.3, color = "Highlight", glow = 1.5, priority = "secondary" })
                if parts[1] then attachLayers(fx.Attach, parts[1], seconds) end
                -- tête peinte qui suit le fouet
                local toon = VFX.ToonOf(ctx.element)
                parts.toon = VFX.Toon.Sprite("Orb_Soft", { x = x, y = y, z = z, size = whip.Radius * 1.6, color = toon.Tint,
                    glow = toon.Glow * 1.3, life = seconds + 0.1, fadeOut = 0.15, priority = "main", lod = ctx.lod })
                heads[head] = parts
            end
        end)
        ctx:Every(tl.WindupMs, tl.WindupMs + whip.DurationMs, STEP, function(_, elapsed)
            local p = (elapsed + STEP - tl.WindupMs) / whip.DurationMs
            for head, parts in pairs(heads) do
                local x, y, z = ctx:Point(TMath.WhipAt(math.min(p, 1), whip, head))
                for _, particle in ipairs(parts) do VFX.MoveTo(particle, x, y, z, STEP / 1000) end
                VFX.Toon.Place(parts.toon, x, y, z, STEP / 1000)
                -- rémanence : croissants de l'élément laissés le long du fouet
                if math.floor(elapsed / STEP) % 2 == 0 then
                    local toon = VFX.ToonOf(ctx.element)
                    local p2 = math.min(p + 0.05, 1)
                    local nx, ny = ctx:Point(TMath.WhipAt(p2, whip, head))
                    local dx, dy = nx - x, ny - y
                    if dx * dx + dy * dy > 1 then
                        VFX.Toon.Card(toon.Slash, { x = x, y = y, z = z, right = { dx, dy, 0 }, up = { -dy / math.sqrt(dx * dx + dy * dy), dx / math.sqrt(dx * dx + dy * dy), 0.8 },
                            size = whip.Radius * 2.4, life = 0.45, fadeIn = 0.02, fadeOut = 0.3, scale = 0.8, grow = 1.0,
                            glow = toon.Glow, priority = "secondary", lod = ctx.lod })
                    end
                end
                if parts[1] and parts[1]:IsValid() then
                    local loc = parts[1]:GetLocation()
                    VFX.Burst.Spray(ctx.element, loc.X, loc.Y, loc.Z, ctx.yaw + 180, { count = 8, speed = 250, life = 0.5, priority = "detail", lod = ctx.lod })
                    VFX.Layers(fx.Trail, loc.X, loc.Y, loc.Z, ctx.yaw, { priority = "detail", lod = ctx.lod })
                end
            end
        end)
    end,
    Event = defaultEvent,
})

-- ---------------------------------------------------------------------------
-- beast : créature segmentée (serpent, dragon) + impact massif
-- ---------------------------------------------------------------------------
VFX.RegisterChoreography("beast", {
    Start = function(ctx)
        cast(ctx)
        local beast, fx, tl = ctx.tech.Beast, fxOf(ctx), ctx.tech.Timeline
        local segments = {}
        local count = math.max(3, math.floor(beast.Segments * (ctx.lod >= 1 and 1 or 0.6)))
        local travel = tl.TravelMs / 1000
        local function pathPoint(p) return ctx:Point(TMath.DragonAt(p, beast)) end
        ctx:At(tl.WindupMs, function()
            ctx:BladeTrail(900)
            lookSlash(ctx, 1, { radius = 240, from = 90, to = -90, upFrom = 40, upTo = 200, width = 70, duration = 0.18 })
            VFX.Sound.Set(fx.Strike, ctx.origin.x, ctx.origin.y, ctx.origin.z)
            local sx, sy, sz = pathPoint(0)
            local head = VFX.Layers(fx.Body or ctx.element.Projectile.Core, sx, sy, sz, ctx.yaw,
                { scale = 2.0, life = travel + 0.3, priority = "main" })
            head[#head + 1] = VFX.Trail.Ribbon(ctx.element, sx, sy, sz, { duration = travel + 0.8, width = 110, trailLife = 0.9 })
            head[#head + 1] = VFX.Trail.Ribbon(ctx.element, sx, sy, sz, { duration = travel + 0.8, width = 30, trailLife = 0.6, color = "Highlight", glow = 1.5 })
            segments[0] = head
            for k = 1, count do
                local scale = 1.5 - (k / count) * 0.9
                local life = travel + k * beast.SegmentDelayMs / 1000
                local asset = fx.Segment or (ctx.element.Projectile.Core[1] and ctx.element.Projectile.Core[1].Asset)
                segments[k] = { VFX.Spawn(asset, sx, sy, sz, { scale = scale, life = life, priority = k <= 3 and "main" or "secondary" }) }
            end
        end)
        ctx:Every(tl.WindupMs, tl.WindupMs + tl.TravelMs + count * beast.SegmentDelayMs, 100, function(_, elapsed)
            for k, parts in pairs(segments) do
                local p = (elapsed + 100 - tl.WindupMs - k * beast.SegmentDelayMs) / tl.TravelMs
                if p >= 0 then
                    local x, y, z = pathPoint(math.min(p, 1))
                    for _, particle in ipairs(parts) do VFX.MoveTo(particle, x, y, z, 0.1) end
                end
            end
        end)
        ctx:Every(tl.WindupMs, tl.WindupMs + tl.TravelMs, 140, function(_, elapsed)
            local p = (elapsed - tl.WindupMs) / tl.TravelMs
            local x, y, z = pathPoint(p)
            -- corps de la créature : croissants peints orientés le long du trajet
            local nx, ny, nz = pathPoint(math.min(1, p + 0.04))
            local toon = VFX.ToonOf(ctx.element)
            local len = math.max(1, math.sqrt((nx - x) ^ 2 + (ny - y) ^ 2))
            VFX.Toon.Card(toon.Slash, { x = x, y = y, z = z, right = { nx - x, ny - y, nz - z }, up = { -(ny - y) / len, (nx - x) / len, 1.0 },
                size = 260, life = 0.7, fadeIn = 0.03, fadeOut = 0.45, scale = 0.7, grow = 1.0, glow = toon.Glow,
                priority = "main", lod = ctx.lod })
            VFX.Burst.Spray(ctx.element, x, y, z - 60, ctx.yaw + 180, { count = 10, speed = 400, priority = "detail", lod = ctx.lod })
            VFX.Layers(fx.Trail or (ctx.element.Impact and ctx.element.Impact.Linger), x, y, z - 80, ctx.yaw, { priority = "detail", lod = ctx.lod })
        end)
    end,
    Event = function(ctx, event, x, y, z)
        if event == "impact" then onBurst(ctx, x, y, z, "Massive") elseif event == "hit" then onHit(ctx, x, y, z) end
    end,
})

-- ---------------------------------------------------------------------------
-- Démarrage : préchargement des textures + commandes de la console du jeu
-- ---------------------------------------------------------------------------

local function localTransform()
    local player = Client.GetLocalPlayer()
    local character = player and player:GetControlledCharacter()
    if not (character and character:IsValid()) then return nil end
    local loc = character:GetLocation()
    return character, loc.X, loc.Y, loc.Z, character:GetRotation().Yaw
end

function GenericVfx:Start()
    VFX.Toon.Preload()

    -- Carte de calibration : flèche ROUGE = avant (doit pointer devant vous),
    -- barre VERTE = haut (doit être en haut / vers le ciel).
    Console.RegisterCommand("ds_vfxcalib", function()
        local character, x, y, z, yaw = localTransform()
        if not character then return end
        local fx, fy = TMath.Forward(yaw)
        VFX.Toon.Card("Calibration", { x = x + fx * 250, y = y + fy * 250, z = z + 60,
            right = { fx, fy, 0 }, up = { 0, 0, 1 }, size = 200, life = 8, glow = 1, priority = "main" })
        VFX.Toon.Card("Calibration", { x = x + fx * 250, y = y + fy * 250, z = z - 85,
            right = { fx, fy, 0 }, up = { -fy, fx, 0 }, size = 200, life = 8, glow = 1, priority = "main" })
        Chat.AddMessage("<cyan>[DSRP]</> Calibration : fleche rouge = devant, barre verte = haut (mur) / gauche (sol).")
    end, "Affiche la carte de calibration des VFX anime")

    -- Démonstration sans combat : croissant + impact de chaque élément devant soi
    Console.RegisterCommand("ds_vfxdemo", function(id)
        local character, x, y, z, yaw = localTransform()
        if not character then return end
        local ids = id and id ~= "" and { id } or { "water", "flame", "sun", "thunder", "wind", "mist", "stone", "beast",
            "ice", "shadow", "blood", "flower", "sound", "insect", "love", "serpent" }
        local planes = { "flat", "rising", "falling", "diagonal", "diagonal2", "tilted" }
        for i, elementId in ipairs(ids) do
            Timer.SetTimeout(function()
                local element = VFX.Element(elementId)
                VFX.Slash(element, character, { radius = 200, plane = planes[(i - 1) % #planes + 1] })
                local fx, fy = TMath.Forward(yaw)
                Timer.SetTimeout(function() VFX.Impact(element, "Large", x + fx * 400, y + fy * 400, z) end, 250)
                Chat.AddMessage("<cyan>[DSRP]</> VFX : " .. elementId)
            end, (i - 1) * 1300)
        end
    end, "Joue le croissant et l'impact de chaque element (ou d'un seul : ds_vfxdemo water)")
end

return GenericVfx
