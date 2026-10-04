--[[
    Demon Slayer RP - Souffle de l'Eau : logique serveur
    ------------------------------------------------------------------
    Zones de touche, dégâts, contrôle et timings des techniques de l'eau.
    Les valeurs viennent de Shared/Config/Breathing/Water.lua ; les visuels
    correspondants sont dans Client/Systems/Fx/Water.lua.

      water_wave     Grande vague      boîte qui avance et s'élargit
      water_vortex   Tourbillon        cylindre, ticks + attraction
      water_prison   Prison d'eau      projectile balayé + emprisonnement
      water_flow     Courant fulgurant élan + vitesse + sphère qui suit le lanceur
      water_tsunami  Tsunami           mur d'eau géant + explosion finale
      water_dragon   Dragon changeant  sphère qui suit la trajectoire du dragon
]]

local WaterTechniques = DS.Module("WaterTechniques", { dependencies = { "Techniques" } })

local TMath = DS.TechMath
local Hitboxes = DS.Hitboxes
local Status = DS.Status
local Register = DS.Techniques.Register

-- Direction horizontale normalisée de (x1,y1) vers (x2,y2), ou repli
local function dirTo(x1, y1, x2, y2, fx, fy)
    local dx, dy = x2 - x1, y2 - y1
    local d = math.sqrt(dx * dx + dy * dy)
    if d < 1 then return fx, fy end
    return dx / d, dy / d
end

-- Préparation commune des ultimes : enraciné + invulnérable + bloque les autres techniques
local function channel(inst, windupMs)
    local caster = inst.tech.Caster
    if not caster then return end
    if caster.RootDuringWindup then Status.Root(inst.caster, windupMs) end
    if caster.InvulnerableDuringWindup then Status.Invulnerable(inst.caster, windupMs + 150) end
    inst.session.data.busyUntil = DS.Utils.NowMs() + windupMs
end

local function playRelease(inst)
    local animation = inst.tech.Animation
    if animation.Release and inst.caster:IsValid() then
        inst.caster:PlayAnimation(animation.Release, AnimationSlotType[animation.Slot] or AnimationSlotType.FullBody)
    end
end

-- Coup d'une vague (boîte orientée) à la progression p.
-- La boîte couvre TOUT le trajet depuis le tick précédent : même si le
-- serveur ralentit, la vague ne "saute" jamais par-dessus une cible.
local function waveStrike(inst, p, wave, hit)
    local distance, width = TMath.WaveAt(p, wave)
    local previous = inst.data.lastWaveDistance or distance
    inst.data.lastWaveDistance = distance
    local center = (previous + distance) / 2
    local halfLength = math.abs(distance - previous) / 2 + wave.Thickness / 2
    local cx, cy, cz = inst:Point(center, 0, wave.Height / 2)
    local targets = inst:Enemies(Hitboxes.Box(cx, cy, cz, inst.fx, inst.fy,
        halfLength, width / 2, wave.Height / 2 + 60))
    for _, entry in ipairs(targets) do
        if inst:Hit(entry.character, {
            damage = hit.Damage, knockback = hit.Knockback, lift = hit.Lift, maxHits = 1,
        }) then
            inst:Event("hit", entry.x, entry.y, entry.z, entry.character)
        end
    end
end

-- ===========================================================================
-- [Q] Grande vague
-- ===========================================================================
Register("water_wave", {
    Tick = function(inst, t)
        local tl = inst.tech.Timeline
        if t < tl.WindupMs then return end
        local p = (t - tl.WindupMs) / tl.TravelMs
        if not inst.data.waveDone then
            -- Dernier passage forcé à p = 1 : le bout de la course est toujours balayé
            if p >= 1 then inst.data.waveDone = true end
            waveStrike(inst, TMath.Smooth(math.min(p, 1)), inst.tech.Wave, inst.tech.Hit)
        elseif t >= tl.WindupMs + tl.TravelMs + tl.LingerMs then
            inst:Finish()
        end
    end,
})

-- ===========================================================================
-- [E] Tourbillon
-- ===========================================================================
Register("water_vortex", {
    Start = function(inst)
        local v = inst.tech.Vortex
        inst.data.cx, inst.data.cy, inst.data.cz = inst:Point(v.Distance, 0, -90)
        inst.data.nextTick = inst.tech.Timeline.WindupMs
    end,
    Tick = function(inst, t)
        local tl, v, d = inst.tech.Timeline, inst.tech.Vortex, inst.data
        if t < tl.WindupMs then return end

        if t >= tl.WindupMs + tl.ActiveMs then
            -- Explosion finale : projette tout le monde vers l'extérieur
            for _, entry in ipairs(inst:Enemies(Hitboxes.Cylinder(d.cx, d.cy, d.cz, v.Radius + 80, v.Height))) do
                local dx, dy = dirTo(d.cx, d.cy, entry.x, entry.y, inst.fx, inst.fy)
                inst:Hit(entry.character, {
                    damage = v.FinalBurst.Damage, knockback = v.FinalBurst.Knockback, lift = v.FinalBurst.Lift,
                    dirX = dx, dirY = dy, maxHits = 999,
                })
            end
            inst:Event("burst", d.cx, d.cy, d.cz)
            inst:Finish()
            return
        end

        -- Rattrapage des ticks manqués si le serveur a ralenti (limité à 3)
        local due = 0
        while t >= d.nextTick and due < 3 do
            due = due + 1
            d.nextTick = d.nextTick + v.TickMs
        end
        if due == 0 then return end
        for _, entry in ipairs(inst:Enemies(Hitboxes.Cylinder(d.cx, d.cy, d.cz, v.Radius, v.Height))) do
            -- Attraction vers le centre + soulèvement (mouvement de spirale)
            local dx, dy = dirTo(entry.x, entry.y, d.cx, d.cy, inst.fx, inst.fy)
            local tx, ty = -dy, dx -- composante tangentielle : la cible tourne
            inst:Hit(entry.character, {
                damage = inst.tech.Hit.Damage * due, knockback = v.Pull, lift = v.Lift,
                dirX = dx * 0.8 + tx * 0.6, dirY = dy * 0.8 + ty * 0.6,
                maxHits = 999,
            })
        end
    end,
})

-- ===========================================================================
-- [R] Prison d'eau
-- ===========================================================================
Register("water_prison", {
    Start = function(inst)
        local pr = inst.tech.Projectile
        local x, y, z = inst:Point(pr.SpawnForward, 0, pr.SpawnHeight)
        inst.data.pos = { x = x, y = y, z = z }
        inst.data.traveled = 0
        inst.data.phase = "windup"
    end,
    Tick = function(inst, t, dt)
        local tl, pr, prison, d = inst.tech.Timeline, inst.tech.Projectile, inst.tech.Prison, inst.data

        if d.phase == "windup" then
            if t >= tl.WindupMs then d.phase = "flying" end
            return
        end

        if d.phase == "flying" then
            local step = pr.Speed * dt
            local a = d.pos
            local b = { x = a.x + inst.fx * step, y = a.y + inst.fy * step, z = a.z }
            -- Balayage complet du segment parcouru : pas de "trou" même à grande vitesse
            local targets = inst:Enemies(Hitboxes.Capsule(a.x, a.y, a.z, b.x, b.y, b.z, pr.Radius))
            d.pos = b
            d.traveled = d.traveled + step

            local victim = targets[1]
            if victim then
                local target = victim.character
                inst:Hit(target, { damage = inst.tech.Hit.Damage, maxHits = 1 })
                if target:IsValid() and not target:IsDead() then
                    Status.Root(target, prison.DurationMs, prison.Lift)
                    d.prisoner = target
                    d.phase = "prison"
                    d.prisonUntil = t + prison.DurationMs
                    d.nextTick = t + prison.TickMs
                    inst:Event("capture", victim.x, victim.y, victim.z, target)
                else
                    inst:Event("splash", b.x, b.y, b.z)
                    inst:Finish()
                end
                return
            end

            if d.traveled >= pr.MaxDistance then
                inst:Event("splash", b.x, b.y, b.z)
                inst:Finish()
            end
            return
        end

        if d.phase == "prison" then
            local target = d.prisoner
            if not (target:IsValid()) or target:IsDead() then
                inst:Finish()
                return
            end
            if t >= d.prisonUntil then
                local loc = target:GetLocation()
                inst.hits[target] = nil -- nouvelle touche autorisée pour l'éclatement
                inst.uniqueTargets = 0
                Status.Clear(target)
                inst:Hit(target, {
                    damage = prison.BurstDamage, knockback = prison.BurstKnockback, lift = 300,
                    dirX = inst.fx, dirY = inst.fy,
                })
                inst:Event("burst", loc.X, loc.Y, loc.Z, target)
                inst:Finish()
            elseif t >= d.nextTick then
                local due = 0
                while t >= d.nextTick and due < 3 do
                    due = due + 1
                    d.nextTick = d.nextTick + prison.TickMs
                end
                inst.hits[target] = nil
                inst.uniqueTargets = 0
                inst:Hit(target, { damage = prison.TickDamage * due })
            end
        end
    end,
})

-- ===========================================================================
-- [F] Courant fulgurant
-- ===========================================================================
Register("water_flow", {
    Start = function(inst)
        local f = inst.tech.Flow
        inst:At(inst.tech.Timeline.WindupMs, function()
            if not inst.caster:IsValid() then return end
            Status.Invulnerable(inst.caster, f.InvulnerableMs)
            inst.caster:AddImpulse(Vector(inst.fx * f.Dash, inst.fy * f.Dash, f.DashLift), true)
            DS.Abilities.ApplyBuff(inst.session, {
                SpeedMultiplier = f.SpeedMultiplier, DurationMs = inst.tech.Timeline.ActiveMs,
            })
        end)
        inst.data.nextTick = inst.tech.Timeline.WindupMs
    end,
    Tick = function(inst, t)
        local tl, f, d = inst.tech.Timeline, inst.tech.Flow, inst.data
        if t >= tl.WindupMs + tl.StrikeWindowMs then
            inst:Finish() -- la vitesse et la traînée continuent (buff) jusqu'à ActiveMs
            return
        end
        if t < d.nextTick or not inst.caster:IsValid() then return end
        d.nextTick = d.nextTick + f.TickMs

        local loc = inst.caster:GetLocation()
        local fx, fy = DS.Abilities.ForwardOf(inst.caster)
        for _, entry in ipairs(inst:Enemies(Hitboxes.Sphere(loc.X, loc.Y, loc.Z, f.HitRadius))) do
            local hit = inst.tech.Hit
            if inst:Hit(entry.character, {
                damage = hit.Damage, knockback = hit.Knockback, lift = hit.Lift, dirX = fx, dirY = fy, maxHits = 1,
            }) then
                inst:Event("hit", entry.x, entry.y, entry.z, entry.character)
            end
        end
    end,
})

-- ===========================================================================
-- [X] Tsunami
-- ===========================================================================
Register("water_tsunami", {
    Start = function(inst)
        local tl = inst.tech.Timeline
        channel(inst, tl.WindupMs)
        inst:At(tl.WindupMs, playRelease)
    end,
    Tick = function(inst, t)
        local tl, wave = inst.tech.Timeline, inst.tech.Wave
        local start = tl.WindupMs + tl.RiseMs
        if t < tl.WindupMs then return end

        if t < start then
            -- La vague se lève à son point de départ : elle touche déjà
            waveStrike(inst, 0, wave, inst.tech.Hit)
            return
        end

        local p = (t - start) / tl.TravelMs
        if not inst.data.waveDone then
            if p >= 1 then inst.data.waveDone = true end
            waveStrike(inst, TMath.Smooth(math.min(p, 1)), wave, inst.tech.Hit)
            return
        end

        if not inst.data.crashed then
            inst.data.crashed = true
            local crash = inst.tech.Crash
            local cx, cy, cz = inst:Point(wave.Distance, 0, 0)
            -- L'explosion finale peut toucher à nouveau ceux déjà emportés par la vague
            inst.hits, inst.uniqueTargets = {}, 0
            for _, entry in ipairs(inst:Enemies(Hitboxes.Sphere(cx, cy, cz, crash.Radius))) do
                local dx, dy = dirTo(cx, cy, entry.x, entry.y, inst.fx, inst.fy)
                inst:Hit(entry.character, {
                    damage = crash.Damage, knockback = crash.Knockback, lift = crash.Lift, dirX = dx, dirY = dy,
                })
            end
            inst:Event("crash", cx, cy, cz)
        end
        if t >= start + tl.TravelMs + tl.CrashMs then inst:Finish() end
    end,
})

-- ===========================================================================
-- [C] Dragon changeant
-- ===========================================================================
Register("water_dragon", {
    Start = function(inst)
        local tl = inst.tech.Timeline
        channel(inst, tl.WindupMs)
        inst:At(tl.WindupMs, playRelease)
    end,
    Tick = function(inst, t)
        local tl, dragon, hit = inst.tech.Timeline, inst.tech.Dragon, inst.tech.Hit
        if t < tl.WindupMs then return end

        local p = (t - tl.WindupMs) / tl.TravelMs
        if p <= 1 then
            local forward, side, up = TMath.DragonAt(p, dragon)
            local hx, hy, hz = inst:Point(forward, side, up)
            -- Balayage entre la position précédente de la tête et la position actuelle
            local last = inst.data.lastHead or { hx, hy, hz }
            inst.data.lastHead = { hx, hy, hz }
            local swept = Hitboxes.Capsule(last[1], last[2], last[3], hx, hy, hz, dragon.HitRadius)
            for _, entry in ipairs(inst:Enemies(swept)) do
                local dx, dy = dirTo(hx, hy, entry.x, entry.y, inst.fx, inst.fy)
                if inst:Hit(entry.character, {
                    damage = hit.Damage, knockback = hit.Knockback, lift = hit.Lift,
                    dirX = (dx + inst.fx) / 2, dirY = (dy + inst.fy) / 2,
                    maxHits = dragon.MaxHitsPerTarget, intervalMs = dragon.HitIntervalMs,
                }) then
                    inst:Event("hit", entry.x, entry.y, entry.z, entry.character)
                end
            end
            return
        end

        if not inst.data.impacted then
            inst.data.impacted = true
            local impact = inst.tech.Impact
            local forward, side, up = TMath.DragonAt(1, dragon)
            local ix, iy, iz = inst:Point(forward, side, up - dragon.Height)
            inst.hits, inst.uniqueTargets = {}, 0
            for _, entry in ipairs(inst:Enemies(Hitboxes.Sphere(ix, iy, iz, impact.Radius))) do
                local dx, dy = dirTo(ix, iy, entry.x, entry.y, inst.fx, inst.fy)
                inst:Hit(entry.character, {
                    damage = impact.Damage, knockback = impact.Knockback, lift = impact.Lift, dirX = dx, dirY = dy,
                })
            end
            inst:Event("impact", ix, iy, iz)
        end
        if t >= tl.WindupMs + tl.TravelMs + tl.ImpactMs then inst:Finish() end
    end,
})

return WaterTechniques
