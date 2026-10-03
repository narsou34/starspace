--[[
    Demon Slayer RP - Session (client)
    ------------------------------------------------------------------
    Reçoit la poignée de main du serveur et conserve les informations de
    session du joueur local (lecture seule : le serveur reste l'autorité).

    Évènements internes émis (DS.Bus) :
        "Session:Ready"   (payload)  première poignée de main reçue
        "Session:Updated" (payload)  poignée de main renvoyée (ex : rechargement)
]]

local Session = DS.Module("Session", { dependencies = { "Network" } })
DS.Session = Session

local Log = Session.Log

local state = {
    ready = false,
    data = nil,
    receivedAt = 0,
    clockOffset = 0,
}

local NOTIFICATION_TYPES = {
    info = NotificationType.Info,
    success = NotificationType.Success,
    warning = NotificationType.Warning,
    error = NotificationType.Error,
}

function Session.IsReady()
    return state.ready
end

--- Données de session reçues du serveur (table en lecture seule par convention).
function Session.Get()
    return state.data
end

--- Le serveur est-il en mode debug ? (active les commandes de test client)
function Session.IsDebug()
    return state.data ~= nil and state.data.debug == true
end

--- Heure serveur estimée (ms), utile plus tard pour les cooldowns affichés.
function Session.GetServerTime()
    return DS.Utils.NowMs() + state.clockOffset
end

local function onHandshake(payload)
    local first = not state.ready
    state.ready = true
    state.data = payload
    state.receivedAt = DS.Utils.NowMs()
    state.clockOffset = payload.serverTime - state.receivedAt

    DS.Net.Send("HandshakeAck", DS.Version)

    -- Le mode debug est décidé par le serveur (custom_settings) : le client s'aligne
    DS.Logger.SetLevel(payload.debug and "DEBUG" or (Config.Core.LogLevel or "INFO"))

    if payload.version ~= DS.Version then
        Log:Warn("Version differente : client %s / serveur %s", DS.Version, payload.version)
    end

    Log:Info("Connecte a %s v%s en tant que %s (#%s, groupe %s)",
        payload.gamemode, payload.version, payload.name, payload.sessionId, payload.group)

    if first then
        Client.ShowNotification(payload.gamemode .. " v" .. payload.version .. " - connexion etablie",
            NotificationType.Success, false, 5)
        DS.Bus.Emit("Session:Ready", payload)
    else
        DS.Bus.Emit("Session:Updated", payload)
    end
end

local function onNotify(message, kind, durationSec)
    Client.ShowNotification(message, NOTIFICATION_TYPES[kind] or NotificationType.Info, true, durationSec)
end

function Session:Init()
    DS.Net.On("Handshake", onHandshake)
    DS.Net.On("Notify", onNotify)
end

function Session:Start()
    -- Package rechargé alors que le joueur est déjà en jeu : on redemande la
    -- poignée de main (lors d'une première connexion, le serveur l'envoie seul
    -- à l'évènement "Ready", le joueur local n'existe pas encore ici).
    if Client.GetLocalPlayer() then
        DS.Net.Send("HandshakeRequest")
    end
end

return Session
