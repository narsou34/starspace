--[[
    Demon Slayer RP - VFX des techniques INSTANTANÉES (client)
    ------------------------------------------------------------------
    Techniques non scriptées (forme cone / circle / line / dash / self).
    Le visuel suit la forme réelle de la zone de touche et l'identité de
    l'élément du souffle / de l'art :

      cone   coupe en arc qui suit la lame + couche propre à la technique
      circle coupe à 360° + onde au sol + explosion colorée
      line   estoc lumineux + projectile éclair jusqu'au bout de la portée
      dash   élan (flash, rémanence, traînées) + coupe à l'arrivée
      self   aura de l'élément + flash + explosion colorée

    Chronologie : préparation (lame) -> coupe (+80 ms, synchronisée avec le
    geste de l'animation jouée par le serveur) -> impacts (SkillHit) ->
    dissipation.
]]

local InstantVfx = DS.Module("InstantVfx", { dependencies = { "VFXManager" } })

local VFX = DS.VFX
local TMath = DS.TechMath

local SWING_DELAY_MS = 80

local function playTechnique(caster, tech, hits)
    if not (caster and caster:IsValid()) then return end
    local set = DS.Catalog.GetSet(tech.Kind, tech.SetId)
    local element = VFX.ElementOf(set)
    local loc = caster:GetLocation()
    local yaw = caster:GetRotation().Yaw
    local x, y, z = loc.X, loc.Y, loc.Z
    local fx, fy = TMath.Forward(yaw)
    local swing = (tech.Slot % 2 == 0) and -1 or 1
    local reach = math.min(tech.Range, 450)
    local look = VFX.LookOf(tech)

    -- Coupe selon le look (orientation, taille, griffes multiples, ultime)
    local function slash(opts)
        opts.plane = opts.plane or VFX.PlaneOf(look, 1)
        opts.scale = (opts.scale or 1) * (look.Scale or 1) * (look.Big and 1.35 or 1)
        opts.big = look.Big
        local multi = look.Multi or 1
        for m = 1, multi do
            local side = (m - (multi + 1) / 2) * 55
            local copy = {}
            for k, v in pairs(opts) do copy[k] = v end
            if multi > 1 then
                local px, py, pz = TMath.Point(x, y, z, fx, fy, 0, side, (m - 1) * 8)
                copy.x, copy.y, copy.z, copy.yaw = px, py, pz, yaw
            end
            Timer.SetTimeout(function() VFX.Slash(element, caster, copy) end, (m - 1) * 35)
        end
    end

    VFX.Trail.Blade(element, caster, 0.6)

    Timer.SetTimeout(function()
        if tech.Shape == "cone" then
            local half = math.min(tech.Angle / 2 + 15, 100)
            slash({ radius = math.max(150, reach * 0.5), from = -half * swing, to = half * swing })
        elseif tech.Shape == "circle" then
            slash({ radius = math.max(160, tech.Range * 0.6), from = 0, to = 350 * swing, plane = "flat",
                upFrom = 70, upTo = 50, duration = 0.2 })
            VFX.Burst.Ring(element, x, y, z - 80, tech.Range / 350)
            VFX.Burst.Sphere(element, x, y, z, { count = 60, speed = 600, radius = 40 })
        elseif tech.Shape == "line" then
            VFX.Thrust(element, x, y, z, yaw, math.min(tech.Range, 300))
            VFX.Projectile(element, { x + fx * 120, y + fy * 120, z + 40 }, yaw,
                { speed = 3500, distance = tech.Range, scale = 0.6 })
        elseif tech.Shape == "dash" then
            VFX.Dash(element, caster, { yaw = yaw, distance = math.max(tech.Range, 500), duration = 0.6 })
            Timer.SetTimeout(function()
                slash({ radius = 170, from = -80 * swing, to = 80 * swing })
            end, 250)
        else -- self
            VFX.Aura(element, caster, (tech.Buff and tech.Buff.DurationMs or 2000) / 1000)
            VFX.Burst.Flash(element, x, y, z, 1.2)
            VFX.Burst.Sphere(element, x, y, z, { count = 70, speed = 400, radius = 60 })
            VFX.Burst.Ring(element, x, y, z - 80, 1.0)
        end

        -- Signature propre à la technique (Looks.lua)
        if look.OnRelease then
            VFX.PlaySignature(look.OnRelease, { element = element, caster = caster, lod = DS.VFXUtils.Lod(x, y, z),
                yaw = yaw, fx = fx, fy = fy,
                Point = function(_, f, sd, up) return TMath.Point(x, y, z, fx, fy, f, sd or 0, up or 0) end,
            }, x, y, z)
        end

        -- Couche propre à la technique (configurée dans BreathingStyles / DemonArts)
        if tech.Effect and tech.Effect ~= "" then
            local offset = tech.EffectOffset or 0
            VFX.Spawn(tech.Effect, x + fx * offset, y + fy * offset, z, {
                yaw = yaw, life = tech.EffectDuration or 1.5, priority = "secondary",
            })
        end
        if tech.Sound and tech.Sound ~= "" then
            VFX.Sound.Play(tech.Sound, x, y, z, { volume = 0.6 })
        end
    end, SWING_DELAY_MS)
end

function InstantVfx:Init()
    DS.Net.On("SkillFx", function(caster, kind, setId, slot, hits)
        local tech = DS.Catalog.GetTechnique(kind, setId, slot)
        if tech and not tech.Script then playTechnique(caster, tech, hits) end
    end)
    DS.Net.On("SkillHit", function(kind, setId, slot, x, y, z)
        local tech = DS.Catalog.GetTechnique(kind, setId, slot)
        if not tech then return end
        local element = VFX.ElementOf(DS.Catalog.GetSet(kind, setId))
        Timer.SetTimeout(function()
            VFX.Impact(element, VFX.ImpactSizeFor(tech.Damage), x, y, z)
        end, SWING_DELAY_MS + 40)
    end)
end

return InstantVfx
