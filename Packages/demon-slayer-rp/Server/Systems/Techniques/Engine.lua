--[[
    Demon Slayer RP - Moteur de techniques scriptées (serveur)
    ------------------------------------------------------------------
    Exécute les techniques à chronologie (Souffle de l'Eau...) :
      préparation -> action -> impact -> fin

    Un "comportement" (behavior) est enregistré par script :

        DS.Techniques.Register("water_wave", {
            Start = function(inst) ... end,            -- au lancement
            Tick  = function(inst, elapsedMs, dt) end, -- toutes les 50 ms
            Stop  = function(inst) end,                -- fin (optionnel)
        })

    L'instance (inst) fournit :
      inst.session, inst.caster, inst.tech, inst.origin {x,y,z}, inst.yaw, inst.fx, inst.fy
      inst:Point(forward, side, up)        point du monde dans le repère du lanceur
      inst:At(ms, fn)                      action unique à un instant de la chronologie
      inst:Enemies(list)                   filtre une liste de zones de touche (ennemis vivants)
      inst:Hit(target, opts)               dégâts + projection avec limites par cible
      inst:Event(name, x, y, z, target)    évènement visuel envoyé aux clients proches
      inst:Finish()

    Une seule minuterie (50 ms) tourne, et uniquement tant qu'une technique
    est active. Toute erreur d'une technique est isolée et l'arrête proprement.
]]

local Techniques = DS.Module("Techniques", {
    dependencies = { "PlayerManager", "Network", "Factions", "Abilities" },
})
DS.Techniques = Techniques

local Log = Techniques.Log
local Utils = DS.Utils
local TMath = DS.TechMath

local TICK_MS = 50
local FX_RADIUS = 9000

local behaviors = {}
local instances = {}
local nextInstanceId = 0
local loopTimer = nil

-- ===========================================================================
-- Instance
-- ===========================================================================

local Instance = {}
Instance.__index = Instance

function Instance:Elapsed()
    return Utils.NowMs() - self.startedAt
end

function Instance:Point(forward, side, up)
    local o = self.origin
    return TMath.Point(o.x, o.y, o.z, self.fx, self.fy, forward, side or 0, up or 0)
end

function Instance:At(ms, fn)
    self.schedule[#self.schedule + 1] = { at = ms, fn = fn }
end

--- Ne garde que les ennemis vivants (ni le lanceur, ni les alliés si FriendlyFire = false).
function Instance:Enemies(list)
    local result = {}
    for _, entry in ipairs(list) do
        local target = entry.character
        if target ~= self.caster and DS.Abilities.IsEnemy(self.session, target) then
            result[#result + 1] = entry
        end
    end
    return result
end

--[[
    Applique un coup. opts :
      damage, knockback, lift, dirX, dirY (direction de projection),
      maxHits (par cible, défaut 1), intervalMs (entre deux touches d'une même cible),
      slow = { Multiplier, DurationMs }, poison = { Damage, TickMs, DurationMs }
    Retourne true si le coup a été appliqué.
]]
function Instance:Hit(target, opts)
    if not (target and target:IsValid()) or target:IsDead() then return false end

    local now = Utils.NowMs()
    local record = self.hits[target]
    local maxHits = opts.maxHits or 1
    if record then
        if record.count >= maxHits then return false end
        if now - record.last < (opts.intervalMs or 0) then return false end
    else
        local maxTargets = self.tech.Hit and self.tech.Hit.MaxTargets or 10
        if self.uniqueTargets >= maxTargets then return false end
        self.uniqueTargets = self.uniqueTargets + 1
        record = { count = 0, last = 0 }
        self.hits[target] = record
    end
    record.count = record.count + 1
    record.last = now

    local session = self.session
    local targetSession = DS.Abilities.SessionOf(target)
    local targetIsDemon = targetSession and DS.Factions.Get(targetSession) == "demons"
    local casterIsSlayer = DS.Factions.Get(session) == "slayers"

    local damage = (opts.damage or 0) * DS.Abilities.DamageMultiplier(session, now)
    if targetIsDemon and casterIsSlayer and self.tech.BonusVsDemons then
        damage = damage * self.tech.BonusVsDemons
    end
    damage = math.floor(damage + 0.5)

    local dirX, dirY = opts.dirX or self.fx, opts.dirY or self.fy
    if damage > 0 then
        target:ApplyDamage(damage, "", DamageType.Melee, Vector(dirX, dirY, 0), session.player, self.caster)
    end

    local knockback, lift = opts.knockback or 0, opts.lift or 0
    if (knockback > 0 or lift > 0) and target:IsValid() and not target:IsDead()
        and not DS.Status.IsRooted(target) then
        target:AddImpulse(Vector(dirX * knockback, dirY * knockback, lift), true)
    end

    -- Ralentissement / poison optionnels
    if opts.slow and target:IsValid() and not target:IsDead() then
        DS.Abilities.ApplySlow(target, opts.slow.Multiplier, opts.slow.DurationMs)
    end
    if opts.poison then
        local tick = opts.poison.Damage
        if targetIsDemon and casterIsSlayer and self.tech.BonusVsDemons then tick = tick * self.tech.BonusVsDemons end
        DS.Status.Poison(target, tick, opts.poison.TickMs or 500, opts.poison.DurationMs or 3000,
            session.player, self.caster)
    end

    -- Lame Nichirin : bloque la régénération du démon touché
    if targetIsDemon and casterIsSlayer and self.tech.BlockRegenMs then
        targetSession.data.noRegenUntil = math.max(targetSession.data.noRegenUntil or 0, now + self.tech.BlockRegenMs)
    end

    self.totalHits = self.totalHits + 1
    return true
end

--- Évènement visuel (impact, capture, explosion...) pour les clients proches.
function Instance:Event(name, x, y, z, target)
    DS.Net.BroadcastInRadius(Vector(x, y, z), FX_RADIUS, "TechEvent", self.id, name, x, y, z, target)
end

function Instance:Finish()
    self.finished = true
end

-- ===========================================================================
-- Boucle
-- ===========================================================================

local function stopInstance(inst)
    if inst.stopped then return end
    inst.stopped = true
    local behavior = behaviors[inst.tech.Script]
    if behavior.Stop then
        local ok, err = Utils.Try(behavior.Stop, inst)
        if not ok then Log:Error("Arret de '%s' en erreur : %s", inst.tech.Script, err) end
    end
    Log:Debug("%s terminee (%s touche(s))", inst.tech.Name, inst.totalHits)
end

local function step()
    local now = Utils.NowMs()
    local alive = {}
    for _, inst in ipairs(instances) do
        local behavior = behaviors[inst.tech.Script]
        local elapsed = now - inst.startedAt
        local dt = (now - inst.lastTick) / 1000
        inst.lastTick = now

        local ok, err = Utils.Try(function()
            -- Actions programmées arrivées à échéance
            local pending = {}
            for _, item in ipairs(inst.schedule) do
                if elapsed >= item.at then item.fn(inst) else pending[#pending + 1] = item end
            end
            inst.schedule = pending
            if not inst.finished and behavior.Tick then
                behavior.Tick(inst, elapsed, dt)
            end
        end)
        if not ok then
            Log:Error("Technique '%s' en erreur : %s", inst.tech.Script, err)
            inst.finished = true
        end

        -- Le lanceur a disparu (déconnexion) : la technique s'arrête
        if not inst.caster:IsValid() then inst.finished = true end

        if inst.finished then stopInstance(inst) else alive[#alive + 1] = inst end
    end
    instances = alive
    if #instances == 0 then
        loopTimer = nil
        return false -- arrête la minuterie : aucune technique active
    end
end

-- ===========================================================================
-- API
-- ===========================================================================

function Techniques.Register(script, behavior)
    assert(type(script) == "string" and type(behavior) == "table", "Techniques.Register : parametres invalides")
    if behaviors[script] then error("Techniques.Register : '" .. script .. "' existe deja", 2) end
    behaviors[script] = behavior
end

function Techniques.Has(script)
    return behaviors[script] ~= nil
end

function Techniques.ActiveCount()
    return #instances
end

--- Lance une technique scriptée (appelé par DS.Abilities.Use après toutes les vérifications).
function Techniques.Run(session, caster, tech)
    local behavior = behaviors[tech.Script]
    if not behavior then return false, "script inconnu '" .. tostring(tech.Script) .. "'" end

    local location = caster:GetLocation()
    local fx, fy = DS.Abilities.ForwardOf(caster)
    local yaw = math.deg(math.atan(fy, fx))
    nextInstanceId = nextInstanceId + 1
    local now = Utils.NowMs()

    local inst = setmetatable({
        id = nextInstanceId,
        session = session,
        caster = caster,
        tech = tech,
        set = DS.Catalog.GetSet(tech.Kind, tech.SetId),
        origin = { x = location.X, y = location.Y, z = location.Z },
        yaw = yaw, fx = fx, fy = fy,
        startedAt = now, lastTick = now,
        schedule = {},
        hits = {}, uniqueTargets = 0, totalHits = 0,
        data = {},
        finished = false,
    }, Instance)

    -- Les clients démarrent la chorégraphie visuelle avec la même origine / direction
    DS.Net.BroadcastInRadius(location, FX_RADIUS, "TechStart", caster, tech.Kind, tech.SetId, tech.Slot,
        inst.origin.x, inst.origin.y, inst.origin.z, yaw, inst.id)

    local animation = tech.Animation
    if type(animation) == "table" and animation.Windup then
        caster:PlayAnimation(animation.Windup, AnimationSlotType[animation.Slot] or AnimationSlotType.FullBody)
    end

    if behavior.Start then
        local ok, err = Utils.Try(behavior.Start, inst)
        if not ok then return false, err end
    end

    instances[#instances + 1] = inst
    if not loopTimer then
        loopTimer = Timer.SetInterval(step, TICK_MS)
    end
    Log:Info("%s (#%s) lance %s", session.name, session.id, tech.Name)
    DS.Bus.Emit("Abilities:Used", session, tech, 0)
    return true
end

function Techniques:Init()
    -- Réapparition : on rétablit tous les états de contrôle
    DS.Bus.On("Spawn:CharacterReady", function(_, character) DS.Status.Clear(character) end)
end

function Techniques:Start()
    -- Vérifie que chaque technique scriptée de la configuration a un comportement
    for _, kind in ipairs({ "breathing", "art" }) do
        for _, setId in ipairs(DS.Catalog.ListSets(kind)) do
            for _, tech in ipairs(DS.Catalog.GetSet(kind, setId).Techniques) do
                if tech.Script and not behaviors[tech.Script] then
                    Log:Error("Technique '%s' : script '%s' introuvable", tech.Name, tech.Script)
                end
            end
        end
    end
end

function Techniques:Shutdown()
    if loopTimer then Timer.ClearInterval(loopTimer) end
    loopTimer = nil
    instances = {}
end

return Techniques
