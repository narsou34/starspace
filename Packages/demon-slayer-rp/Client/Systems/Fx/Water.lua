--[[
    Demon Slayer RP - Souffle de l'Eau : chorégraphies visuelles et sonores
    ------------------------------------------------------------------
    Chaque technique empile plusieurs COUCHES synchronisées avec la
    chronologie partagée (Shared/Config/Breathing/Water.lua) :

      préparation  souffle, eau qui se rassemble, cercle au sol
      action       traînée du katana, corps principal de l'effet (vague,
                   vortex, sphère, dragon...), écume, embruns, brume
      impact       explosion d'eau, éclaboussures, onde au sol, sons
      fin          brume qui retombe, gouttelettes

    Priorités : "main" (toujours créée), "secondary" (sauf saturation),
    "detail" (réduite en qualité medium / supprimée en low).
]]

local WaterFx = DS.Module("WaterFx", { dependencies = { "FxCore" } })

local Vfx, Sfx, CamFx, Choreo = DS.Vfx, DS.Sfx, DS.CamFx, DS.Choreo
local TMath = DS.TechMath
local FX = Config.WaterFx
local SFX = Config.WaterSfx

local QUALITY_COLUMNS = { high = 1, medium = 0.7, low = 0.5 }

local function columns(base)
    return math.max(2, math.floor(base * (QUALITY_COLUMNS[Config.Vfx.Quality] or 1) + 0.5))
end

local function randomRing(cx, cy, radius)
    local angle = math.random() * math.pi * 2
    local r = radius * (0.4 + math.random() * 0.6)
    return cx + math.cos(angle) * r, cy + math.sin(angle) * r
end

-- Éclaboussure d'impact sur une cible (coup reçu)
local function impactOn(x, y, z, strength)
    strength = strength or 1
    Vfx.Spawn(FX.OrbHit, x, y, z, { scale = 0.9 * strength, life = 1.2, priority = "main" })
    Vfx.Spawn(FX.Impact, x, y, z - 60, { scale = strength, life = 1.0 })
    Vfx.Spawn(FX.Spray, x, y, z, { scale = 0.8 * strength, life = 1.0, priority = "detail" })
    Sfx.Play(SFX.Hit, x, y, z, { volume = 0.8, pitch = 0.9 + math.random() * 0.2 })
    Sfx.Play(SFX.Water, x, y, z, { volume = 0.7, pitch = 1.1 })
end

-- Grosse explosion d'eau (fin de vague, éclatement, impact du dragon)
local function waterExplosion(x, y, z, radius, scale)
    Vfx.Spawn(FX.SplashBig, x, y, z, { scale = scale, life = 2.5, priority = "main" })
    Vfx.Spawn(FX.RingBig, x, y, z - 80, { scale = scale * 0.9, life = 1.8, priority = "main" })
    Vfx.Spawn(FX.Burst, x, y, z + 50, { scale = scale * 0.8, life = 1.5 })
    Vfx.Spawn(FX.Fountain, x, y, z - 80, { scale = scale * 0.7, life = 1.6 })
    local count = math.floor(4 + scale * 2)
    for i = 1, count do
        local angle = (i / count) * math.pi * 2
        local px, py = x + math.cos(angle) * radius * 0.7, y + math.sin(angle) * radius * 0.7
        Vfx.Spawn(FX.Splash, px, py, z - 60, { scale = 0.9 + math.random() * 0.5, life = 1.8, priority = "detail" })
    end
    for _ = 1, 3 do
        local mx, my = randomRing(x, y, radius)
        Vfx.Spawn(FX.MistHeavy, mx, my, z - 40, { scale = scale * 0.6, life = 3.5, priority = "detail" })
    end
end

-- Sons d'une vague en mouvement : grondement d'eau + embruns
local function waveSound(x, y, z, seconds, power)
    Sfx.Play(SFX.Roar, x, y, z, { volume = 0.25 * power, pitch = 0.45, life = seconds, fadeOut = 0.6, falloff = 3000 + 2000 * power })
    Sfx.Play(SFX.Rush, x, y, z, { volume = 0.2 * power, pitch = 0.55, life = seconds, fadeOut = 0.5 })
end

-- ===========================================================================
-- Mur d'eau mobile (utilisé par la Grande vague et le Tsunami)
-- ===========================================================================
local function buildWave(ctx, wave, startMs, travelMs, opts)
    local count = columns(opts.columns)
    local travelSec = travelMs / 1000
    local life = travelSec + (opts.linger or 0.5)

    ctx:At(startMs, function()
        for i = 1, count do
            local lateral = (i - 1) / math.max(1, count - 1) - 0.5 -- -0.5 .. 0.5
            local sx, sy, sz = ctx:Point(wave.StartDistance, lateral * wave.StartWidth, opts.baseZ)
            local ex, ey, ez = ctx:Point(wave.Distance, lateral * wave.EndWidth, opts.baseZ)
            local edge = math.abs(lateral) * 2 -- 0 au centre, 1 sur les bords : bords plus bas
            local height = opts.scale * (1 - edge * 0.35)

            -- Corps de la vague : masse d'eau tourbillonnante
            local body = Vfx.Spawn(FX.Storm, sx, sy, sz, {
                yaw = ctx.yaw, scale = Vector(height * 0.9, height * 1.2, height * opts.heightScale),
                life = life, priority = "main",
            })
            if opts.rise and body then
                Vfx.SetScale(body, Vector(height * 0.5, height * 0.6, height * 0.3))
                ctx:At(startMs + opts.rise * 0.5, function() Vfx.SetScale(body, Vector(height * 0.75, height, height * opts.heightScale * 0.7)) end)
                ctx:At(startMs + opts.rise, function() Vfx.SetScale(body, Vector(height * 0.9, height * 1.2, height * opts.heightScale)) end)
            end
            ctx:At(startMs + (opts.rise or 0), function() Vfx.MoveTo(body, ex, ey, ez, travelSec) end)

            -- Colonne d'eau qui s'élève à l'avant de la vague
            local column = Vfx.Spawn(FX.Fountain, sx, sy, sz - 60, {
                scale = height * 0.8, life = life, priority = i % 2 == 1 and "main" or "secondary",
            })
            ctx:At(startMs + (opts.rise or 0), function() Vfx.MoveTo(column, ex, ey, ez - 60, travelSec) end)
        end

        -- Onde au sol au point de départ
        local rx, ry, rz = ctx:Point(wave.StartDistance, 0, opts.baseZ - 80)
        Vfx.Spawn(FX.Ring, rx, ry, rz, { scale = opts.scale * 0.8, life = 1.2, priority = "main" })
        waveSound(rx, ry, rz, travelSec + (opts.rise or 0) / 1000, opts.power)
    end)

    -- Écume, embruns, brume et sillage le long du trajet (front de la vague)
    local moveStart = startMs + (opts.rise or 0)
    ctx:Every(moveStart, moveStart + travelMs, opts.foamEveryMs, function(_, elapsed)
        local p = TMath.Clamp01((elapsed - moveStart) / travelMs)
        local distance, width = TMath.WaveAt(p, wave)
        for _, lateral in ipairs({ -0.35, 0, 0.35 }) do
            local fx, fy, fz = ctx:Point(distance, lateral * width, opts.baseZ + wave.Height * 0.7)
            Vfx.Spawn(FX.SplashSoft, fx, fy, fz, { scale = opts.scale * 0.5, life = 1.0, priority = "detail" })
        end
        local sx, sy, sz = ctx:Point(distance + 60, 0, opts.baseZ + 40)
        Vfx.Spawn(FX.Spray, sx, sy, sz, { yaw = ctx.yaw, scale = opts.scale * 0.6, life = 1.0 })
        local wx, wy, wz = ctx:Point(distance - wave.Thickness, (math.random() - 0.5) * width, opts.baseZ - 70)
        Vfx.Spawn(FX.Impact, wx, wy, wz, { scale = opts.scale * 0.6, life = 1.0, priority = "detail" })
        local mx, my, mz = ctx:Point(distance - wave.Thickness * 1.5, (math.random() - 0.5) * width, opts.baseZ)
        Vfx.Spawn(FX.Mist, mx, my, mz, { scale = opts.scale * 0.7, life = 2.0, priority = "detail" })
    end)
end

-- ===========================================================================
-- [Q] Grande vague
-- ===========================================================================
Choreo.Register("water_wave", {
    Start = function(ctx)
        local tech, tl, wave = ctx.tech, ctx.tech.Timeline, ctx.tech.Wave
        local o = ctx.origin

        -- Préparation : respiration, eau qui s'enroule autour de la lame
        Sfx.Play(SFX.Breath, o.x, o.y, o.z, { volume = 0.5, pitch = 1.1 })
        Vfx.Attach(FX.Droplets, ctx.caster, "hand_r", { life = 0.6, priority = "detail" })
        Vfx.Spawn(FX.Mist, o.x, o.y, o.z - 80, { scale = 0.6, life = 1.0, priority = "detail" })

        -- Coup de katana
        ctx:At(tl.WindupMs - 80, function()
            ctx:BladeTrail(700)
            Sfx.Play(SFX.Slash, o.x, o.y, o.z, { volume = 0.9, pitch = 1.05 })
            if ctx.isLocal then CamFx.Fov(tech.Camera.Fov, tech.Camera.DurationMs) end
        end)

        buildWave(ctx, wave, tl.WindupMs, tl.TravelMs, {
            columns = 5, scale = 1.25, heightScale = 1.3, baseZ = -40,
            linger = tl.LingerMs / 1000, foamEveryMs = 140, power = 1,
        })

        -- Fin : la vague s'effondre
        ctx:At(tl.WindupMs + tl.TravelMs, function()
            local x, y, z = ctx:Point(wave.Distance, 0, -40)
            waterExplosion(x, y, z, wave.EndWidth / 2, 1.3)
            Sfx.Play(SFX.Crash, x, y, z, { volume = 0.7, pitch = 0.7 })
            Sfx.Play(SFX.Water, x, y, z, { volume = 1, pitch = 0.8 })
        end)
    end,
    Event = function(ctx, event, x, y, z)
        if event == "hit" then impactOn(x, y, z, 1) end
    end,
})

-- ===========================================================================
-- [E] Tourbillon
-- ===========================================================================
Choreo.Register("water_vortex", {
    Start = function(ctx)
        local tech, tl, v = ctx.tech, ctx.tech.Timeline, ctx.tech.Vortex
        local cx, cy, cz = ctx:Point(v.Distance, 0, -90)
        local activeSec = tl.ActiveMs / 1000
        ctx.data.center = { cx, cy, cz }

        -- Préparation : rotation du lanceur, cercle d'eau au sol
        ctx:BladeTrail(tl.WindupMs + 300)
        Sfx.Play(SFX.Slash, ctx.origin.x, ctx.origin.y, ctx.origin.z, { volume = 0.8, pitch = 0.85 })
        Vfx.Spawn(FX.Circle, cx, cy, cz + 5, { scale = 1.6, life = (tl.WindupMs + tl.ActiveMs) / 1000, priority = "main" })
        Vfx.Spawn(FX.Ring, cx, cy, cz, { scale = 1.2, life = 1.0 })

        ctx:At(tl.WindupMs, function()
            if ctx.isLocal then CamFx.Fov(tech.Camera.Fov, tech.Camera.DurationMs) end
            -- Colonne du vortex : plusieurs couches superposées
            Vfx.Spawn(FX.Storm, cx, cy, cz + 60, { scale = Vector(2.2, 2.2, 2.6), life = activeSec, priority = "main" })
            Vfx.Spawn(FX.Wind, cx, cy, cz + 260, { scale = Vector(1.8, 1.8, 2.2), life = activeSec, priority = "main" })
            Vfx.Spawn(FX.Fountain, cx, cy, cz, { scale = 1.6, life = activeSec })
            Vfx.Spawn(FX.MistHeavy, cx, cy, cz + 20, { scale = 1.4, life = activeSec + 1, priority = "detail" })
            Sfx.Play(SFX.Roar, cx, cy, cz, { volume = 0.35, pitch = 0.7, life = activeSec, fadeOut = 0.8 })
            Sfx.Play(SFX.Rush, cx, cy, cz, { volume = 0.3, pitch = 0.5, life = activeSec, fadeOut = 0.8 })
            Sfx.Play(SFX.Water, cx, cy, cz, { volume = 0.9, pitch = 0.75 })

            -- Sphères d'eau en orbite qui montent en spirale
            local orbiters = {}
            local count = columns(6)
            for i = 1, count do
                local orb = Vfx.Spawn(FX.Orb, cx, cy, cz, { scale = 0.55, life = activeSec, priority = i <= 3 and "main" or "secondary" })
                orbiters[i] = { particle = orb, phase = (i / count) * math.pi * 2, rise = (i / count) }
            end
            ctx.data.orbiters = orbiters
        end)

        -- Mouvement spiralé (rotation + montée + rayon qui se resserre)
        ctx:Every(tl.WindupMs, tl.WindupMs + tl.ActiveMs, 60, function(_, elapsed)
            local t = (elapsed - tl.WindupMs) / 1000
            for _, orb in ipairs(ctx.data.orbiters or {}) do
                local p = orb.particle
                if p and p:IsValid() then
                    local h = ((orb.rise + t * 0.45) % 1)
                    local radius = v.Radius * (0.85 - h * 0.45)
                    local angle = orb.phase + t * 5.5
                    pcall(p.SetLocation, p, Vector(cx + math.cos(angle) * radius, cy + math.sin(angle) * radius, cz + 40 + h * v.Height))
                end
            end
        end)

        -- Gouttelettes projetées hors du vortex
        ctx:Every(tl.WindupMs, tl.WindupMs + tl.ActiveMs, 220, function()
            local x, y = randomRing(cx, cy, v.Radius)
            Vfx.Spawn(FX.Impact, x, y, cz, { scale = 0.8, life = 0.9, priority = "detail" })
            local sx, sy = randomRing(cx, cy, v.Radius * 0.6)
            Vfx.Spawn(FX.SplashSoft, sx, sy, cz + 150 + math.random() * 250, { scale = 0.6, life = 0.9, priority = "detail" })
        end)
    end,
    Event = function(ctx, event, x, y, z)
        if event == "burst" then
            waterExplosion(x, y, z + 60, ctx.tech.Vortex.Radius, 1.6)
            Sfx.Play(SFX.Crash, x, y, z, { volume = 0.8, pitch = 0.75 })
            Sfx.Play(SFX.Water, x, y, z, { volume = 1, pitch = 0.7 })
            if ctx.isLocal then CamFx.Kick(6) end
        elseif event == "hit" then
            impactOn(x, y, z, 0.7)
        end
    end,
})

-- ===========================================================================
-- [R] Prison d'eau
-- ===========================================================================
Choreo.Register("water_prison", {
    Start = function(ctx)
        local tech, tl, pr = ctx.tech, ctx.tech.Timeline, ctx.tech.Projectile
        local o = ctx.origin

        -- Préparation : la sphère se forme dans la main
        Vfx.Attach(FX.Orb, ctx.caster, "hand_r", { scale = 0.35, life = tl.WindupMs / 1000, priority = "main" })
        Vfx.Attach(FX.Droplets, ctx.caster, "hand_r", { life = 0.5, priority = "detail" })
        Sfx.Play(SFX.Water, o.x, o.y, o.z, { volume = 0.5, pitch = 1.4 })

        ctx:At(tl.WindupMs, function()
            ctx:BladeTrail(450)
            Sfx.Play(SFX.Slash, o.x, o.y, o.z, { volume = 0.8, pitch = 0.8 })
            if ctx.isLocal then CamFx.Fov(tech.Camera.Fov, tech.Camera.DurationMs) end

            -- Projectile : sphère d'eau + traînée qui la suit
            local flightSec = pr.MaxDistance / pr.Speed
            local sx, sy, sz = ctx:Point(pr.SpawnForward, 0, pr.SpawnHeight)
            local ex, ey, ez = ctx:Point(pr.SpawnForward + pr.MaxDistance, 0, pr.SpawnHeight)
            local orb = Vfx.Spawn(FX.Orb, sx, sy, sz, { scale = 1.0, life = flightSec + 0.1, priority = "main" })
            if orb then
                Vfx.MoveTo(orb, ex, ey, ez, flightSec)
                Vfx.Attach(FX.Streamer, orb, "", { life = flightSec, priority = "secondary" })
                Vfx.Attach(FX.Ribbon, orb, "", { life = flightSec, priority = "detail" })
                Sfx.Play(SFX.Rush, sx, sy, sz, { volume = 0.25, pitch = 1.3, life = flightSec, attach = orb })
            end
            ctx.data.orb = orb
            ctx.data.flightEnd = ctx:Elapsed() + flightSec * 1000

            -- Gouttelettes laissées derrière la sphère
            ctx:Every(tl.WindupMs, tl.WindupMs + flightSec * 1000, 110, function()
                local p = ctx.data.orb
                if p and p:IsValid() then
                    local loc = p:GetLocation()
                    Vfx.Spawn(FX.SplashSoft, loc.X, loc.Y, loc.Z, { scale = 0.35, life = 0.7, priority = "detail" })
                end
            end)
        end)
    end,
    Event = function(ctx, event, x, y, z, target)
        local prison = ctx.tech.Prison
        if event == "capture" then
            Vfx.Destroy(ctx.data.orb)
            ctx.data.orb = nil
            impactOn(x, y, z, 1)
            if target and target:IsValid() then
                local seconds = prison.DurationMs / 1000
                -- Bulle : sphère d'eau géante + courant interne + gouttelettes
                Vfx.Attach(FX.Orb, target, "pelvis", { scale = 2.6, life = seconds, priority = "main" })
                Vfx.Attach(FX.Storm, target, "pelvis", { scale = 1.1, life = seconds, priority = "main" })
                Vfx.Attach(FX.Droplets, target, "pelvis", { life = seconds, priority = "detail" })
                Sfx.Play(SFX.Roar, x, y, z, { volume = 0.2, pitch = 1.6, life = seconds, fadeOut = 0.5, attach = target })
                Sfx.Play(SFX.Water, x, y, z, { volume = 0.9, pitch = 0.9 })
            end
        elseif event == "splash" then
            Vfx.Destroy(ctx.data.orb)
            ctx.data.orb = nil
            Vfx.Spawn(FX.OrbHit, x, y, z, { scale = 1.2, life = 1.2, priority = "main" })
            Vfx.Spawn(FX.Splash, x, y, z - 40, { scale = 0.9, life = 1.5 })
            Sfx.Play(SFX.Water, x, y, z, { volume = 0.8 })
        elseif event == "burst" then
            waterExplosion(x, y, z, 260, 1.0)
            Sfx.Play(SFX.Crash, x, y, z, { volume = 0.6, pitch = 1.2 })
            Sfx.Play(SFX.Water, x, y, z, { volume = 1, pitch = 1 })
        end
    end,
})

-- ===========================================================================
-- [F] Courant fulgurant
-- ===========================================================================
Choreo.Register("water_flow", {
    Start = function(ctx)
        local tech, tl = ctx.tech, ctx.tech.Timeline
        local o = ctx.origin
        local activeSec = tl.ActiveMs / 1000

        Sfx.Play(SFX.Rush, o.x, o.y, o.z, { volume = 0.5, pitch = 1.4, life = 0.7, fadeOut = 0.3 })
        Sfx.Play(SFX.Slash, o.x, o.y, o.z, { volume = 0.9, pitch = 1.25 })

        ctx:At(tl.WindupMs, function()
            -- Élan : jaillissement d'eau vers l'avant
            Vfx.Spawn(FX.Spray, o.x, o.y, o.z, { yaw = ctx.yaw, scale = 1.3, life = 1.0, priority = "main" })
            Vfx.Spawn(FX.Splash, o.x, o.y, o.z - 70, { scale = 0.9, life = 1.2 })
            Vfx.Spawn(FX.Ring, o.x, o.y, o.z - 85, { scale = 0.7, life = 0.9 })
            Sfx.Play(SFX.Water, o.x, o.y, o.z, { volume = 0.9, pitch = 1.2 })

            -- Traînées d'eau sur la lame et les jambes + distorsion de vitesse
            ctx:BladeTrail(tl.ActiveMs)
            Vfx.Attach(FX.Ribbon, ctx.caster, "foot_l", { life = activeSec, priority = "secondary" })
            Vfx.Attach(FX.Ribbon, ctx.caster, "foot_r", { life = activeSec, priority = "secondary" })
            Vfx.Attach(FX.Haze, ctx.caster, "pelvis", { life = activeSec, priority = "detail" })
            if ctx.isLocal then CamFx.Fov(tech.Camera.Fov, tech.Camera.DurationMs) end
        end)

        -- Éclaboussures à chaque foulée + brume dans le sillage
        ctx:Every(tl.WindupMs, tl.WindupMs + tl.ActiveMs, 200, function(_, elapsed)
            if not (ctx.caster and ctx.caster:IsValid()) then return end
            local loc = ctx.caster:GetLocation()
            Vfx.Spawn(FX.Impact, loc.X, loc.Y, loc.Z - 85, { scale = 0.7, life = 0.8 })
            if elapsed % 400 < 200 then
                Vfx.Spawn(FX.Mist, loc.X, loc.Y, loc.Z - 60, { scale = 0.5, life = 1.6, priority = "detail" })
            end
        end)
    end,
    Event = function(ctx, event, x, y, z)
        if event == "hit" then
            impactOn(x, y, z, 0.9)
            Sfx.Play(SFX.Slash, x, y, z, { volume = 0.7, pitch = 1.4 })
        end
    end,
})

-- ===========================================================================
-- [X] Tsunami
-- ===========================================================================
Choreo.Register("water_tsunami", {
    Start = function(ctx)
        local tech, tl, wave = ctx.tech, ctx.tech.Timeline, ctx.tech.Wave
        local o = ctx.origin
        local total = tl.WindupMs + tl.RiseMs + tl.TravelMs + tl.CrashMs

        -- Concentration totale : souffle profond, l'eau se rassemble autour du lanceur
        Sfx.Play(SFX.Breath, o.x, o.y, o.z, { volume = 0.8, pitch = 0.8 })
        Sfx.Play(SFX.Roar, o.x, o.y, o.z, { volume = 0.2, pitch = 0.35, life = total / 1000, fadeOut = 1.2, falloff = 7000 })
        Vfx.Spawn(FX.Circle, o.x, o.y, o.z - 85, { scale = 2.6, life = (tl.WindupMs + tl.RiseMs) / 1000, priority = "main" })
        Vfx.Spawn(FX.Fountain, o.x, o.y, o.z - 80, { scale = 1.3, life = tl.WindupMs / 1000, priority = "main" })
        Vfx.Spawn(FX.MistHeavy, o.x, o.y, o.z - 60, { scale = 1.5, life = (tl.WindupMs + 800) / 1000 })
        if ctx.isLocal then
            CamFx.Pull(tech.Camera.ArmLength, total)
        end

        -- Sphères d'eau qui convergent en spirale vers le lanceur
        local orbs = {}
        for i = 1, columns(6) do
            orbs[i] = { particle = Vfx.Spawn(FX.Orb, o.x, o.y, o.z, { scale = 0.45, life = tl.WindupMs / 1000 }), phase = i }
        end
        ctx:Every(0, tl.WindupMs, 60, function(_, elapsed)
            local p = elapsed / tl.WindupMs
            for _, orb in ipairs(orbs) do
                local particle = orb.particle
                if particle and particle:IsValid() then
                    local angle = orb.phase + elapsed / 1000 * 6
                    local radius = 420 * (1 - p) + 60
                    pcall(particle.SetLocation, particle, Vector(o.x + math.cos(angle) * radius, o.y + math.sin(angle) * radius, o.z - 40 + p * 180))
                end
            end
        end)
        ctx:Every(0, tl.WindupMs, 380, function()
            Vfx.Spawn(FX.Ring, o.x, o.y, o.z - 85, { scale = 1.4, life = 1.0, priority = "secondary" })
        end)

        -- Libération
        ctx:At(tl.WindupMs, function()
            ctx:BladeTrail(900)
            Sfx.Play(SFX.Slash, o.x, o.y, o.z, { volume = 1, pitch = 0.7 })
            Sfx.Play(SFX.CrashBig, o.x, o.y, o.z, { volume = 0.5, pitch = 0.5, falloff = 8000 })
            Vfx.Spawn(FX.Spray, o.x, o.y, o.z, { yaw = ctx.yaw, scale = 1.8, life = 1.2, priority = "main" })
            if ctx.isLocal then CamFx.Fov(tech.Camera.Fov, tl.RiseMs + tl.TravelMs) end
        end)

        -- Le mur d'eau se lève puis avance
        buildWave(ctx, wave, tl.WindupMs, tl.TravelMs, {
            columns = 7, scale = 2.6, heightScale = 2.2, baseZ = -40, rise = tl.RiseMs,
            linger = tl.CrashMs / 1000, foamEveryMs = 120, power = 2,
        })
    end,
    Event = function(ctx, event, x, y, z)
        if event == "crash" then
            local crash = ctx.tech.Crash
            waterExplosion(x, y, z, crash.Radius, 3.0)
            Vfx.Spawn(FX.SplashBig, x + ctx.fx * 200, y + ctx.fy * 200, z, { scale = 2.5, life = 2.5 })
            Sfx.Play(SFX.CrashBig, x, y, z, { volume = 1, pitch = 0.6, falloff = 9000 })
            Sfx.Play(SFX.Thud, x, y, z, { volume = 0.8, pitch = 0.7 })
            Sfx.Play(SFX.Water, x, y, z, { volume = 1, pitch = 0.6 })
            if ctx.isLocal then CamFx.Kick(10) end
        elseif event == "hit" then
            impactOn(x, y, z, 1.4)
        end
    end,
})

-- ===========================================================================
-- [C] Dragon changeant
-- ===========================================================================
Choreo.Register("water_dragon", {
    Start = function(ctx)
        local tech, tl, dragon = ctx.tech, ctx.tech.Timeline, ctx.tech.Dragon
        local o = ctx.origin
        local travelSec = tl.TravelMs / 1000

        -- Préparation : spirale d'eau ascendante autour du lanceur
        Sfx.Play(SFX.Breath, o.x, o.y, o.z, { volume = 0.8, pitch = 0.75 })
        Vfx.Spawn(FX.Circle, o.x, o.y, o.z - 85, { scale = 2.2, life = (tl.WindupMs + 600) / 1000, priority = "main" })
        Vfx.Spawn(FX.Storm, o.x, o.y, o.z, { scale = Vector(1.4, 1.4, 2.2), life = tl.WindupMs / 1000, priority = "main" })
        if ctx.isLocal then CamFx.Pull(tech.Camera.ArmLength, tl.WindupMs + tl.TravelMs + 600) end
        ctx:BladeTrail(tl.WindupMs + 500)

        -- Corps du dragon : tête + segments qui suivent exactement la même trajectoire
        local segments = {}
        local count = columns(dragon.Segments)
        local function pathPoint(p)
            local forward, side, up = TMath.DragonAt(p, dragon)
            return ctx:Point(forward, side, up)
        end
        local sx, sy, sz = pathPoint(0)

        ctx:At(tl.WindupMs, function()
            Sfx.Play(SFX.CrashBig, o.x, o.y, o.z, { volume = 0.6, pitch = 0.8, falloff = 8000 })
            Sfx.Play(SFX.Slash, o.x, o.y, o.z, { volume = 1, pitch = 0.65 })
            Vfx.Spawn(FX.Spray, o.x, o.y, o.z, { yaw = ctx.yaw, scale = 1.6, life = 1.2 })
            if ctx.isLocal then CamFx.Fov(tech.Camera.Fov, tl.TravelMs) end

            -- Tête
            local life = travelSec + 0.3
            local head = Vfx.Spawn(FX.Storm, sx, sy, sz, { scale = Vector(2.4, 2.4, 2.0), life = life, priority = "main" })
            local core = Vfx.Spawn(FX.Orb, sx, sy, sz, { scale = 1.8, life = life, priority = "main" })
            if head then
                Vfx.Attach(FX.Ribbon, head, "", { life = life, priority = "main" })
                Vfx.Attach(FX.Streamer, head, "", { life = life, priority = "secondary" })
                Sfx.Play(SFX.Roar, sx, sy, sz, { volume = 0.35, pitch = 0.5, life = travelSec, fadeOut = 0.5, attach = head, falloff = 7000 })
            end
            segments[0] = { head, core }

            -- Corps : segments de plus en plus fins, décalés dans le temps
            for k = 1, count do
                local scale = 1.6 - (k / count) * 0.9
                local delaySec = k * dragon.SegmentDelayMs / 1000
                local parts = { Vfx.Spawn(FX.Orb, sx, sy, sz, { scale = scale, life = life + delaySec, priority = k <= 3 and "main" or "secondary" }) }
                if k % 2 == 0 then
                    parts[2] = Vfx.Spawn(FX.Storm, sx, sy, sz, { scale = scale * 0.9, life = life + delaySec, priority = "detail" })
                end
                segments[k] = parts
            end
            ctx.data.segments = segments
        end)

        -- Animation : chaque segment vise sa position 100 ms plus tard sur la trajectoire
        local STEP = 100
        ctx:Every(tl.WindupMs, tl.WindupMs + tl.TravelMs + count * dragon.SegmentDelayMs, STEP, function(_, elapsed)
            for k, parts in pairs(ctx.data.segments or {}) do
                local delay = k * dragon.SegmentDelayMs
                local p = (elapsed + STEP - tl.WindupMs - delay) / tl.TravelMs
                if p >= 0 then
                    local x, y, z = pathPoint(math.min(p, 1))
                    for _, particle in ipairs(parts) do Vfx.MoveTo(particle, x, y, z, STEP / 1000) end
                end
            end
        end)

        -- Gouttes et brume arrachées au passage de la tête
        ctx:Every(tl.WindupMs, tl.WindupMs + tl.TravelMs, 150, function(_, elapsed)
            local x, y, z = pathPoint((elapsed - tl.WindupMs) / tl.TravelMs)
            Vfx.Spawn(FX.SplashSoft, x, y, z - 80, { scale = 0.8, life = 1.0, priority = "secondary" })
            Vfx.Spawn(FX.Impact, x, y, ctx.origin.z - 85, { scale = 0.9, life = 1.0, priority = "detail" })
            Vfx.Spawn(FX.Mist, x, y, z - 120, { scale = 0.9, life = 2.2, priority = "detail" })
        end)
    end,
    Event = function(ctx, event, x, y, z)
        if event == "impact" then
            local impact = ctx.tech.Impact
            waterExplosion(x, y, z, impact.Radius, 3.2)
            Vfx.Spawn(FX.Storm, x, y, z + 100, { scale = Vector(3, 3, 2.5), life = 1.6, priority = "main" })
            Sfx.Play(SFX.CrashBig, x, y, z, { volume = 1, pitch = 0.55, falloff = 9000 })
            Sfx.Play(SFX.Thud, x, y, z, { volume = 0.9, pitch = 0.6 })
            Sfx.Play(SFX.Water, x, y, z, { volume = 1, pitch = 0.55 })
            if ctx.isLocal then CamFx.Kick(12) end
        elseif event == "hit" then
            impactOn(x, y, z, 1.2)
        end
    end,
})

return WaterFx
