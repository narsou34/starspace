--[[
    Demon Slayer RP - Network (serveur)
    ------------------------------------------------------------------
    Couche réseau sécurisée. Toute communication client <-> serveur passe ici.

    Recevoir (Client -> Serveur) :
        DS.Net.Handle("Ping", function(session, clientTime) ... end)

        Avant d'appeler le handler, chaque message reçu est contrôlé :
          1. le joueur possède une session active
          2. débit global puis débit propre à l'évènement
          3. état de la session (connecting / ready / loaded)
          4. permission (si l'évènement en exige une)
          5. nombre, types et bornes des arguments (DS.Validator)
        Le handler reçoit la SESSION (jamais le Player brut) et des arguments
        validés. Il s'exécute en mode protégé : une erreur est loggée sans
        casser le serveur.

    Envoyer (Serveur -> Client) :
        DS.Net.Send(session_ou_player, "Notify", "Bonjour", "info")
        DS.Net.SendMany({ s1, s2 }, "Notify", ...)
        DS.Net.Broadcast("Notify", ...)          -- tous les joueurs connectés
        DS.Net.BroadcastInRadius(location, 5000, "SkillFx", ...)  -- joueurs proches
        DS.Net.BroadcastLoaded("Notify", ...)    -- uniquement les joueurs chargés
]]

local Network = DS.Module("Network", { dependencies = { "Security" } })
DS.Net = Network

local Log = Network.Log

local handlers = {}

local stats = {
    received = 0,
    accepted = 0,
    rejected = 0,
    dropped = 0,
    errors = 0,
    sent = 0,
}

local STATE_RANK = { connecting = 1, ready = 2, loaded = 3 }

local function reliabilityOf(def)
    return def.reliable and Reliability.Reliable or Reliability.Unreliable
end

local function reject(session, kind, detail)
    stats.rejected = stats.rejected + 1
    DS.Security.Flag(session, kind, detail)
end

local function dispatch(def, handler, player, ...)
    stats.received = stats.received + 1

    -- 1. Session active
    local session = DS.Players and DS.Players.Get(player)
    if not session or session.kicked or session.state == "leaving" then
        stats.dropped = stats.dropped + 1
        return
    end

    -- 2. Débit (global puis par évènement)
    if not DS.Security.ConsumeRate(session, "net:*", Config.Security.GlobalRate) then
        return reject(session, "rate", "debit global depasse (" .. def.name .. ")")
    end
    if not DS.Security.ConsumeRate(session, "net:" .. def.name, def.rate) then
        return reject(session, "rate", "debit depasse pour " .. def.name)
    end

    -- 3. État de la session
    if (STATE_RANK[session.state] or 0) < STATE_RANK[def.state] then
        return reject(session, "state", def.name .. " recu en etat '" .. tostring(session.state) .. "'")
    end

    -- 4. Permission
    if def.permission and not DS.Permissions.Has(session, def.permission) then
        return reject(session, "unauthorized", def.name .. " sans la permission " .. def.permission)
    end

    -- 5. Arguments
    local expected = #def.args
    local argc = select("#", ...)
    if argc > expected then
        return reject(session, "invalid", def.name .. " : " .. argc .. " arguments recus, " .. expected .. " attendus")
    end
    local args = { ... }
    for i = 1, expected do
        local schema = def.args[i]
        local ok, result = DS.Validator.Check(args[i], schema, schema.name or ("arg" .. i))
        if not ok then
            return reject(session, "invalid", def.name .. " -> " .. result)
        end
        args[i] = result
    end

    -- Exécution protégée
    stats.accepted = stats.accepted + 1
    local ok, err = DS.Utils.Try(handler, session, table.unpack(args, 1, expected))
    if not ok then
        stats.errors = stats.errors + 1
        Log:Error("Handler '%s' en erreur (joueur #%s) : %s", def.name, session.id, err)
    end
end

--- Enregistre le handler d'un évènement Client -> Serveur déclaré dans DS.NetEvents.
function Network.Handle(name, handler)
    local def = DS.NetEvents.Get("C2S", name)
    assert(type(handler) == "function", "Net.Handle : fonction attendue pour " .. name)
    if handlers[name] then
        error("Net.Handle : un handler existe deja pour " .. name, 2)
    end
    handlers[name] = handler

    Events.SubscribeRemote(def.wire, function(player, ...)
        dispatch(def, handler, player, ...)
    end)
    Log:Debug("Handler enregistre : %s", def.wire)
end

-- Accepte une session ou un Player ; retourne le Player valide ou nil.
local function resolvePlayer(target)
    if target == nil then return nil end
    if DS.Players and DS.Players.IsSession(target) then
        target = target.player
    end
    if target and target:IsValid() then
        return target
    end
    return nil
end

--- Envoie un évènement Serveur -> Client à un joueur.
function Network.Send(target, name, ...)
    local def = DS.NetEvents.Get("S2C", name)
    local player = resolvePlayer(target)
    if not player then return false end
    Events.CallRemote(def.wire, player, reliabilityOf(def), ...)
    stats.sent = stats.sent + 1
    return true
end

--- Envoie un évènement à une liste de sessions/joueurs. Retourne le nombre de destinataires.
function Network.SendMany(targets, name, ...)
    local def = DS.NetEvents.Get("S2C", name)
    local players = {}
    for _, target in ipairs(targets) do
        local player = resolvePlayer(target)
        if player then players[#players + 1] = player end
    end
    if #players == 0 then return 0 end
    Events.CallRemotePlayers(def.wire, players, reliabilityOf(def), ...)
    stats.sent = stats.sent + #players
    return #players
end

--- Envoie un évènement à tous les joueurs connectés (y compris ceux en chargement).
function Network.Broadcast(name, ...)
    local def = DS.NetEvents.Get("S2C", name)
    Events.BroadcastRemote(def.wire, reliabilityOf(def), ...)
    stats.sent = stats.sent + DS.Players.Count()
end

--- Envoie un évènement aux joueurs proches d'une position (filtrage fait par le moteur).
function Network.BroadcastInRadius(location, radius, name, ...)
    local def = DS.NetEvents.Get("S2C", name)
    Events.BroadcastRemoteInRadius(def.wire, location, radius, reliabilityOf(def), ...)
    stats.sent = stats.sent + 1
end

--- Envoie un évènement uniquement aux joueurs ayant entièrement chargé le gamemode.
function Network.BroadcastLoaded(name, ...)
    return Network.SendMany(DS.Players.GetLoaded(), name, ...)
end

function Network.GetStats()
    return DS.Utils.DeepCopy(stats)
end

function Network:Init()
    -- Évènement de diagnostic intégré : mesure de la latence applicative
    Network.Handle("Ping", function(session, clientTime)
        session:Send("Pong", clientTime, DS.Utils.NowMs())
    end)
end

return Network
