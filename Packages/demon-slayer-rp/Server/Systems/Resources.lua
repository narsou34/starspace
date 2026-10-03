--[[
    Demon Slayer RP - Ressources et régénération (serveur)
    ------------------------------------------------------------------
    - Souffle (pourfendeurs) / Énergie démoniaque (démons), selon la faction
    - Régénération passive de la ressource (après un court délai sans technique)
    - Régénération de la VIE des démons, bloquée :
        * quelques secondes après avoir reçu un coup
        * plus longtemps après une technique de souffle (lame Nichirin) :
          session.data.noRegenUntil, fixé par le système de techniques

    Une seule tâche périodique pour tous les joueurs (Config.Abilities.TickMs).
    Évènement interne émis à chaque tick : "RP:Tick" (now, dtSeconds)
]]

local Resources = DS.Module("Resources", { dependencies = { "Factions" } })
DS.Resources = Resources

local Log = Resources.Log
local Utils = DS.Utils

local timer = nil
local lastTick = 0

local function resetPool(session)
    local faction = DS.Catalog.GetFaction(DS.Factions.Get(session))
    local def = faction and Config.Resources[faction.Resource]
    if not def then
        session.data.resource = nil
        return
    end
    session.data.resource = { id = faction.Resource, current = def.Max, max = def.Max, lastUseAt = 0, lastSent = -1 }
end

local function sync(session, force)
    local pool = session.data.resource
    if not pool then return end
    local rounded = math.floor(pool.current)
    if force or rounded ~= pool.lastSent then
        pool.lastSent = rounded
        session:Send("ResourceSync", rounded, pool.max)
    end
end

--- Valeur actuelle et max de la ressource (nil si aucune faction).
function Resources.Get(session)
    local pool = session.data.resource
    if not pool then return nil end
    return pool.current, pool.max, pool.id
end

--- Dépense `amount` si possible. Retourne true si la ressource était suffisante.
function Resources.TrySpend(session, amount)
    local pool = session.data.resource
    if not pool or pool.current < amount then return false end
    pool.current = pool.current - amount
    pool.lastUseAt = Utils.NowMs()
    sync(session)
    return true
end

function Resources.Refill(session)
    local pool = session.data.resource
    if not pool then return end
    pool.current = pool.max
    sync(session, true)
end

local function regenHealth(session, faction, now, dt)
    local regen = faction.Regeneration
    local character = session:GetCharacter()
    if not (character and character:IsValid()) or character:IsDead() then return end

    local health, maxHealth = character:GetHealth(), character:GetMaxHealth()
    if health >= maxHealth then session.data.regenAcc = 0 return end
    if now - (session.data.lastDamagedAt or 0) < regen.DelayAfterDamageMs then return end
    if now < (session.data.noRegenUntil or 0) then return end

    local multiplier = 1
    local art = DS.Catalog.GetSet("art", DS.Factions.State(session).setId or "")
    if art and art.Passive and art.Passive.RegenMultiplier then
        multiplier = art.Passive.RegenMultiplier
    end

    local acc = (session.data.regenAcc or 0) + regen.HealthPerSecond * multiplier * dt
    local whole = math.floor(acc)
    session.data.regenAcc = acc - whole
    if whole > 0 then
        character:SetHealth(math.min(maxHealth, health + whole))
    end
end

local function tick()
    local now = Utils.NowMs()
    local dt = (lastTick > 0) and (now - lastTick) / 1000 or Config.Abilities.TickMs / 1000
    lastTick = now

    for _, session in ipairs(DS.Players.GetLoaded()) do
        local pool = session.data.resource
        if pool and pool.current < pool.max then
            local def = Config.Resources[pool.id]
            if now - pool.lastUseAt >= def.RegenDelayMs then
                pool.current = math.min(pool.max, pool.current + def.RegenPerSecond * dt)
                sync(session)
            end
        end

        local faction = DS.Catalog.GetFaction(DS.Factions.Get(session))
        if faction and faction.Regeneration then
            regenHealth(session, faction, now, dt)
        end
    end

    DS.Bus.Emit("RP:Tick", now, dt)
end

function Resources:Init()
    DS.Bus.On("RP:FactionChanged", function(session)
        resetPool(session)
        sync(session, true)
    end)
    DS.Bus.On("Player:Loaded", function(session) sync(session, true) end)

    -- Mémorise le dernier coup reçu par un joueur (délai de régénération des démons)
    Character.Subscribe("TakeDamage", function(character)
        local player = character:GetPlayer()
        local session = player and DS.Players.Get(player)
        if session then
            session.data.lastDamagedAt = Utils.NowMs()
        end
    end)
end

function Resources:Start()
    timer = Timer.SetInterval(tick, Config.Abilities.TickMs)
    Log:Info("Ressources actives : %s", table.concat(Utils.SortedKeys(Config.Resources), ", "))
end

function Resources:Shutdown()
    if timer then
        Timer.ClearInterval(timer)
        timer = nil
    end
end

return Resources
