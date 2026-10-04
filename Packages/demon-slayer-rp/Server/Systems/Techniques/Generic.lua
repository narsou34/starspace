--[[
    Demon Slayer RP - Comportements génériques de techniques (serveur)
    ------------------------------------------------------------------
    Briques réutilisables, paramétrées par la configuration de chaque
    technique (Shared/Config/Breathing/*.lua). Les effets visuels associés
    sont dans Client/Systems/Fx/Generic.lua.

      combo        N coups successifs (arc, cercle ou ligne) avec intervalle
      bursts       explosions programmées (ligne, anneaux, points)
      projectiles  un ou plusieurs projectiles (éventail), perçants ou non,
                   avec explosion à l'impact
      buff         renforcement sur soi + aura de dégâts optionnelle
      dash         élan + entaille sur toute la trajectoire
      dashchain    plusieurs élans enchaînés (zigzag)
      zone         zone persistante (devant soi ou qui suit le lanceur) :
                   ticks, attraction / répulsion, ralentissement, poison
      whip         fouet / tête qui suit une trajectoire (droite, sinusoïde,
                   spirale, aller-retour, 1 ou 2 têtes)
      beast        créature géante qui ondule (serpent, dragon) + impact

    Options d'effet communes à chaque coup (table Hit de la technique ou
    des sous-tables) : Damage, Knockback, Lift, Slow, Poison.
]]

local GenericTechniques = DS.Module("GenericTechniques", { dependencies = { "Techniques" } })

local TMath = DS.TechMath
local Hitboxes = DS.Hitboxes
local Status = DS.Status
local Register = DS.Techniques.Register

local function dirTo(x1, y1, x2, y2, fx, fy)
    local dx, dy = x2 - x1, y2 - y1
    local d = math.sqrt(dx * dx + dy * dy)
    if d < 1 then return fx, fy end
    return dx / d, dy / d
end

-- Coup standard à partir d'une table de paramètres (Damage, Knockback, Lift, Slow, Poison)
local function strike(inst, entry, params, dirX, dirY, extra)
    local opts = {
        damage = params.Damage, knockback = params.Knockback, lift = params.Lift,
        slow = params.Slow, poison = params.Poison,
        dirX = dirX, dirY = dirY,
    }
    for k, v in pairs(extra or {}) do opts[k] = v end
    if inst:Hit(entry.character, opts) then
        inst:Event("hit", entry.x, entry.y, entry.z, entry.character)
        return true
    end
    return false
end

local function release(inst)
    local animation = inst.tech.Animation
    if animation and animation.Release and inst.caster:IsValid() then
        inst.caster:PlayAnimation(animation.Release, AnimationSlotType[animation.Slot] or AnimationSlotType.FullBody)
    end
end

-- Préparation des ultimes : immobile + invulnérable + aucune autre technique
local function channel(inst)
    local caster = inst.tech.Caster
    local windup = inst.tech.Timeline.WindupMs
    if not caster then return end
    if caster.RootDuringWindup then Status.Root(inst.caster, windup) end
    if caster.InvulnerableDuringWindup then Status.Invulnerable(inst.caster, windup + 150) end
    inst.session.data.busyUntil = DS.Utils.NowMs() + windup
end

local function startCommon(inst)
    channel(inst)
    if inst.tech.Animation and inst.tech.Animation.Release then
        inst:At(inst.tech.Timeline.WindupMs, release)
    end
end

-- ===========================================================================
-- combo : N coups successifs
-- ===========================================================================
Register("combo", {
    Start = function(inst)
        startCommon(inst)
        local combo = inst.tech.Combo
        for i = 1, combo.Count do
            inst:At(inst.tech.Timeline.WindupMs + (i - 1) * combo.IntervalMs, function()
                if not inst.caster:IsValid() then return end
                local loc = inst.caster:GetLocation()
                local fx, fy = DS.Abilities.ForwardOf(inst.caster)
                local list
                if combo.Shape == "circle" then
                    list = Hitboxes.Sphere(loc.X, loc.Y, loc.Z, combo.Range)
                elseif combo.Shape == "line" then
                    local half = combo.Range / 2
                    list = Hitboxes.Box(loc.X + fx * half, loc.Y + fy * half, loc.Z, fx, fy, half, combo.Width / 2, 150)
                else
                    list = Hitboxes.Arc(loc.X, loc.Y, loc.Z, fx, fy, combo.Range, combo.Angle, 250)
                end
                for _, entry in ipairs(inst:Enemies(list)) do
                    local dx, dy = dirTo(loc.X, loc.Y, entry.x, entry.y, fx, fy)
                    strike(inst, entry, inst.tech.Hit, dx, dy, { maxHits = combo.Count })
                end
            end)
        end
        inst:At(inst.tech.Timeline.WindupMs + combo.Count * combo.IntervalMs + 200, function() inst:Finish() end)
    end,
})

-- ===========================================================================
-- bursts : explosions programmées
-- ===========================================================================
Register("bursts", {
    Start = function(inst)
        startCommon(inst)
        local list = TMath.BurstList(inst.tech.Bursts)
        local last = 0
        for index, burst in ipairs(list) do
            local at = inst.tech.Timeline.WindupMs + burst.delay
            last = math.max(last, at)
            inst:At(at, function()
                local x, y, z = inst:Point(burst.forward, burst.side, 0)
                local hit = {
                    Damage = burst.damage, Knockback = burst.knockback, Lift = burst.lift,
                    Slow = inst.tech.Bursts.Slow, Poison = inst.tech.Bursts.Poison,
                }
                for _, entry in ipairs(inst:Enemies(Hitboxes.Sphere(x, y, z, burst.radius))) do
                    local dx, dy = dirTo(x, y, entry.x, entry.y, inst.fx, inst.fy)
                    strike(inst, entry, hit, dx, dy, { maxHits = #list, intervalMs = 0 })
                end
                inst:Event("burst", x, y, z)
            end)
        end
        inst:At(last + 300, function() inst:Finish() end)
    end,
})

-- ===========================================================================
-- projectiles : éventail de projectiles
-- ===========================================================================
Register("projectiles", {
    Start = function(inst)
        startCommon(inst)
        local pr = inst.tech.Projectiles
        inst.data.shots = {}
        for i = 1, pr.Count do
            local offset = (pr.Count > 1) and ((i - 1) / (pr.Count - 1) - 0.5) * pr.SpreadDeg or 0
            local fx, fy = TMath.Rotate(inst.fx, inst.fy, offset)
            local x, y, z = inst:Point(pr.SpawnForward or 100, 0, pr.SpawnHeight or 40)
            inst.data.shots[i] = { x = x, y = y, z = z, fx = fx, fy = fy, traveled = 0, alive = true, hits = {} }
        end
    end,
    Tick = function(inst, t, dt)
        local tl, pr = inst.tech.Timeline, inst.tech.Projectiles
        if t < tl.WindupMs then return end
        local anyAlive = false
        for index, shot in ipairs(inst.data.shots) do
            if shot.alive then
                anyAlive = true
                local step = pr.Speed * dt
                local bx, by = shot.x + shot.fx * step, shot.y + shot.fy * step
                local targets = inst:Enemies(Hitboxes.Capsule(shot.x, shot.y, shot.z, bx, by, shot.z, pr.Radius))
                shot.x, shot.y = bx, by
                shot.traveled = shot.traveled + step

                local stopped = false
                for _, entry in ipairs(targets) do
                    if not shot.hits[entry.character] then
                        shot.hits[entry.character] = true
                        strike(inst, entry, inst.tech.Hit, shot.fx, shot.fy, { maxHits = pr.Count, intervalMs = 0 })
                        if not pr.Pierce then stopped = true break end
                    end
                end
                if stopped or shot.traveled >= pr.MaxDistance then
                    shot.alive = false
                    if pr.Explosion then
                        local ex = pr.Explosion
                        for _, entry in ipairs(inst:Enemies(Hitboxes.Sphere(shot.x, shot.y, shot.z, ex.Radius))) do
                            local dx, dy = dirTo(shot.x, shot.y, entry.x, entry.y, shot.fx, shot.fy)
                            strike(inst, entry, ex, dx, dy, { maxHits = pr.Count * 2, intervalMs = 0 })
                        end
                    end
                    inst:Event("impact:" .. index, shot.x, shot.y, shot.z)
                end
            end
        end
        if not anyAlive then inst:Finish() end
    end,
})

-- ===========================================================================
-- buff : renforcement sur soi + aura
-- ===========================================================================
Register("buff", {
    Start = function(inst)
        startCommon(inst)
        inst:At(inst.tech.Timeline.WindupMs, function()
            DS.Abilities.ApplyBuff(inst.session, inst.tech.Buff)
        end)
        local aura = inst.tech.Aura
        if not aura then
            inst:At(inst.tech.Timeline.WindupMs + 100, function() inst:Finish() end)
            return
        end
        inst.data.nextTick = inst.tech.Timeline.WindupMs
    end,
    Tick = function(inst, t)
        local aura = inst.tech.Aura
        if not aura or t < inst.data.nextTick then return end
        if t > inst.tech.Timeline.WindupMs + aura.DurationMs or not inst.caster:IsValid() then
            inst:Finish()
            return
        end
        inst.data.nextTick = inst.data.nextTick + aura.TickMs
        local loc = inst.caster:GetLocation()
        for _, entry in ipairs(inst:Enemies(Hitboxes.Sphere(loc.X, loc.Y, loc.Z, aura.Radius))) do
            local dx, dy = dirTo(loc.X, loc.Y, entry.x, entry.y, inst.fx, inst.fy)
            strike(inst, entry, aura, dx, dy, { maxHits = 999 })
        end
    end,
})

-- ===========================================================================
-- dash / dashchain : élans avec entaille sur la trajectoire
-- ===========================================================================
local function dashStep(inst, dash, yawOffset, index)
    if not inst.caster:IsValid() then return end
    local loc = inst.caster:GetLocation()
    local baseX, baseY = DS.Abilities.ForwardOf(inst.caster)
    local fx, fy = TMath.Rotate(baseX, baseY, yawOffset or 0)
    if dash.InvulnerableMs then Status.Invulnerable(inst.caster, dash.InvulnerableMs) end
    inst.caster:AddImpulse(Vector(fx * dash.Impulse, fy * dash.Impulse, dash.Lift or 100), true)

    local half = dash.Distance / 2
    local list = Hitboxes.Box(loc.X + fx * half, loc.Y + fy * half, loc.Z, fx, fy, half, dash.Width / 2, 150)
    for _, entry in ipairs(inst:Enemies(list)) do
        strike(inst, entry, inst.tech.Hit, fx, fy, { maxHits = dash.MaxHits or 1, intervalMs = 0 })
    end
    inst:Event("dash:" .. index, loc.X, loc.Y, loc.Z)
end

Register("dash", {
    Start = function(inst)
        startCommon(inst)
        inst:At(inst.tech.Timeline.WindupMs, function() dashStep(inst, inst.tech.Dash, 0, 1) end)
        inst:At(inst.tech.Timeline.WindupMs + 400, function() inst:Finish() end)
    end,
})

Register("dashchain", {
    Start = function(inst)
        startCommon(inst)
        local chain = inst.tech.Dash
        for i = 1, chain.Count do
            local offset = chain.AngleOffsets and chain.AngleOffsets[i] or 0
            inst:At(inst.tech.Timeline.WindupMs + (i - 1) * chain.IntervalMs, function()
                dashStep(inst, chain, offset, i)
            end)
        end
        inst:At(inst.tech.Timeline.WindupMs + chain.Count * chain.IntervalMs + 300, function() inst:Finish() end)
    end,
})

-- ===========================================================================
-- zone : zone persistante
-- ===========================================================================
Register("zone", {
    Start = function(inst)
        startCommon(inst)
        local zone = inst.tech.Zone
        inst.data.cx, inst.data.cy, inst.data.cz = inst:Point(zone.Forward or 0, 0, -90)
        inst.data.nextTick = inst.tech.Timeline.WindupMs
    end,
    Tick = function(inst, t)
        local tl, zone, d = inst.tech.Timeline, inst.tech.Zone, inst.data
        if t < tl.WindupMs then return end
        if zone.Follow and inst.caster:IsValid() then
            local loc = inst.caster:GetLocation()
            d.cx, d.cy, d.cz = loc.X, loc.Y, loc.Z - 90
        end

        if t >= tl.WindupMs + zone.DurationMs then
            if zone.FinalBurst then
                for _, entry in ipairs(inst:Enemies(Hitboxes.Cylinder(d.cx, d.cy, d.cz, zone.Radius + 80, zone.Height))) do
                    local dx, dy = dirTo(d.cx, d.cy, entry.x, entry.y, inst.fx, inst.fy)
                    strike(inst, entry, zone.FinalBurst, dx, dy, { maxHits = 999 })
                end
                inst:Event("burst", d.cx, d.cy, d.cz)
            end
            inst:Finish()
            return
        end

        local due = 0
        while t >= d.nextTick and due < 3 do
            due = due + 1
            d.nextTick = d.nextTick + zone.TickMs
        end
        if due == 0 then return end
        for _, entry in ipairs(inst:Enemies(Hitboxes.Cylinder(d.cx, d.cy, d.cz, zone.Radius, zone.Height))) do
            local inX, inY = dirTo(entry.x, entry.y, d.cx, d.cy, inst.fx, inst.fy)
            local pull = zone.Pull or 0 -- > 0 attire, < 0 repousse
            local sign = pull >= 0 and 1 or -1
            strike(inst, entry, {
                Damage = (inst.tech.Hit.Damage or 0) * due, Knockback = math.abs(pull), Lift = zone.Lift,
                Slow = zone.Slow, Poison = zone.Poison,
            }, inX * sign, inY * sign, { maxHits = 999 })
        end
    end,
})

-- ===========================================================================
-- whip : tête(s) suivant une trajectoire
-- ===========================================================================
Register("whip", {
    Start = function(inst)
        startCommon(inst)
    end,
    Tick = function(inst, t)
        local tl, whip = inst.tech.Timeline, inst.tech.Whip
        if t < tl.WindupMs then return end
        local p = (t - tl.WindupMs) / whip.DurationMs
        local done = p >= 1
        p = math.min(p, 1)
        inst.data.last = inst.data.last or {}
        for head = 1, (whip.Heads or 1) do
            local forward, side, up = TMath.WhipAt(p, whip, head)
            local x, y, z = inst:Point(forward, side, up)
            local last = inst.data.last[head] or { x, y, z }
            inst.data.last[head] = { x, y, z }
            for _, entry in ipairs(inst:Enemies(Hitboxes.Capsule(last[1], last[2], last[3], x, y, z, whip.Radius))) do
                local dx, dy = dirTo(inst.origin.x, inst.origin.y, entry.x, entry.y, inst.fx, inst.fy)
                strike(inst, entry, inst.tech.Hit, dx, dy, {
                    maxHits = whip.MaxHitsPerTarget or 1, intervalMs = whip.HitIntervalMs or 300,
                })
            end
        end
        if done then inst:Finish() end
    end,
})

-- ===========================================================================
-- beast : créature géante ondulante (serpent, dragon...)
-- ===========================================================================
Register("beast", {
    Start = function(inst)
        startCommon(inst)
    end,
    Tick = function(inst, t)
        local tl, beast, hit = inst.tech.Timeline, inst.tech.Beast, inst.tech.Hit
        if t < tl.WindupMs then return end
        local p = (t - tl.WindupMs) / tl.TravelMs
        if p <= 1 or not inst.data.swept then
            if p >= 1 then inst.data.swept = true end
            local forward, side, up = TMath.DragonAt(math.min(p, 1), beast)
            local hx, hy, hz = inst:Point(forward, side, up)
            local last = inst.data.lastHead or { hx, hy, hz }
            inst.data.lastHead = { hx, hy, hz }
            for _, entry in ipairs(inst:Enemies(Hitboxes.Capsule(last[1], last[2], last[3], hx, hy, hz, beast.HitRadius))) do
                local dx, dy = dirTo(hx, hy, entry.x, entry.y, inst.fx, inst.fy)
                strike(inst, entry, hit, (dx + inst.fx) / 2, (dy + inst.fy) / 2, {
                    maxHits = beast.MaxHitsPerTarget, intervalMs = beast.HitIntervalMs,
                })
            end
            return
        end
        if not inst.data.impacted then
            inst.data.impacted = true
            local impact = inst.tech.Impact
            local forward, side, up = TMath.DragonAt(1, beast)
            local ix, iy, iz = inst:Point(forward, side, up - beast.Height)
            inst.hits, inst.uniqueTargets = {}, 0
            for _, entry in ipairs(inst:Enemies(Hitboxes.Sphere(ix, iy, iz, impact.Radius))) do
                local dx, dy = dirTo(ix, iy, entry.x, entry.y, inst.fx, inst.fy)
                strike(inst, entry, impact, dx, dy)
            end
            inst:Event("impact", ix, iy, iz)
        end
        if t >= tl.WindupMs + tl.TravelMs + (tl.ImpactMs or 800) then inst:Finish() end
    end,
})

return GenericTechniques
