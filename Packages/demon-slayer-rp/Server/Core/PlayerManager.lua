--[[
    Demon Slayer RP - PlayerManager (serveur)
    ------------------------------------------------------------------
    Système de joueur minimal : une SESSION par joueur connecté.

    Cycle de vie d'une session :
        connecting  Player "Spawn"   : le client télécharge / charge la carte
        ready       Player "Ready"   : client chargé -> envoi du Handshake
        loaded      HandshakeAck     : le client a chargé le gamemode et répondu
        leaving     Player "Destroy" : déconnexion

    Évènements internes émis (DS.Bus) :
        "Player:Connecting" (session)
        "Player:Ready"      (session)
        "Player:Loaded"     (session)
        "Player:Leaving"    (session, reason)  reason = "disconnect" | "shutdown"
        "Player:Left"       (session)

    session.data est réservé aux futurs systèmes (personnage, inventaire...).
]]

local Players = DS.Module("PlayerManager", { dependencies = { "Network", "Permissions", "Security" } })
DS.Players = Players

local Log = Players.Log
local Utils = DS.Utils

local sessions = {} -- [Player] = session
local byId = {}     -- [id] = session
local count = 0
local maintenanceTimer = nil

-- ===========================================================================
-- Objet Session
-- ===========================================================================

local Session = {}
Session.__index = Session

function Session:IsValid()
    return not self.removed and self.player ~= nil and self.player:IsValid()
end

function Session:IsLoaded()
    return self.state == "loaded"
end

function Session:HasPermission(perm)
    return DS.Permissions.Has(self, perm)
end

function Session:Send(eventName, ...)
    return DS.Net.Send(self, eventName, ...)
end

--- Notification à l'écran du joueur. kind : "info" | "success" | "warning" | "error".
function Session:Notify(message, kind, durationSec)
    return DS.Net.Send(self, "Notify", tostring(message), kind or "info", durationSec or 5)
end

--- Message dans le chat du joueur (avec le préfixe du gamemode).
function Session:Chat(message)
    if self:IsValid() then
        Chat.SendMessage(self.player, Config.Core.ChatPrefix .. " " .. tostring(message))
    end
end

function Session:Kick(reason)
    if self.kicked then return end
    self.kicked = true
    Log:Info("Expulsion de %s (#%s) : %s", self.name, self.id, tostring(reason))
    if self.player and self.player:IsValid() then
        self.player:Kick(tostring(reason))
    end
end

function Session:GetPing()
    return self:IsValid() and self.player:GetPing() or -1
end

function Session:GetConnectedMs()
    return Utils.NowMs() - self.connectedAt
end

function Session:GetCharacter()
    if not self:IsValid() then return nil end
    return self.player:GetControlledCharacter()
end

-- ===========================================================================
-- Gestion des sessions
-- ===========================================================================

local function createSession(player)
    local existing = sessions[player]
    if existing then return existing end

    local accountId = player:GetAccountID()
    local session = setmetatable({
        id = player:GetID(),
        player = player,
        accountId = accountId,
        steamId = player:GetSteamID(),
        accountName = player:GetAccountName(),
        name = Utils.SanitizeChat(player:GetName()),
        state = "connecting",
        group = DS.Permissions.ResolveInitialGroup(accountId),
        connectedAt = Utils.NowMs(),
        readyAt = nil,
        loadedAt = nil,
        handshakeSentAt = nil,
        kicked = false,
        removed = false,
        rate = {},
        security = DS.Security.CreateState(),
        data = {},
    }, Session)

    sessions[player] = session
    byId[session.id] = session
    count = count + 1

    Log:Info("Connexion : %s (#%s, compte %s) - groupe '%s'", session.name, session.id, accountId, session.group)
    DS.Bus.Emit("Player:Connecting", session)
    return session
end

local function buildHandshake(session)
    local group = DS.Permissions.GetGroup(session.group)
    return {
        gamemode = DS.Name,
        version = DS.Version,
        author = DS.Author,
        sessionId = session.id,
        name = session.name,
        group = session.group,
        groupLabel = group and group.label or session.group,
        serverTime = Utils.NowMs(),
        debug = Config.Core.Debug == true,
    }
end

local function sendHandshake(session)
    session.handshakeSentAt = Utils.NowMs()
    session:Send("Handshake", buildHandshake(session))
end

local function onReady(player)
    local session = sessions[player] or createSession(player)
    if session.state == "connecting" then
        session.state = "ready"
        session.readyAt = Utils.NowMs()
        Log:Info("%s (#%s) pret apres %s de chargement", session.name, session.id,
            Utils.FormatDuration(session.readyAt - session.connectedAt))
        DS.Bus.Emit("Player:Ready", session)
    end
    sendHandshake(session)
end

local function removeSession(player, reason)
    local session = sessions[player]
    if not session then return end

    session.state = "leaving"
    DS.Bus.Emit("Player:Leaving", session, reason)

    sessions[player] = nil
    byId[session.id] = nil
    count = count - 1
    session.removed = true

    Log:Info("Deconnexion : %s (#%s) apres %s", session.name, session.id, Utils.FormatDuration(session:GetConnectedMs()))
    DS.Bus.Emit("Player:Left", session)
end

-- ===========================================================================
-- Handlers réseau
-- ===========================================================================

local function onHandshakeAck(session, clientVersion)
    if session.state == "loaded" then return end -- doublon (ex : handshake renvoyé)

    if clientVersion ~= DS.Version then
        Log:Warn("Version client differente pour %s (#%s) : client %s / serveur %s",
            session.name, session.id, clientVersion, DS.Version)
    end

    session.state = "loaded"
    session.loadedAt = Utils.NowMs()
    local roundTrip = session.handshakeSentAt and (session.loadedAt - session.handshakeSentAt) or -1
    Log:Info("Handshake OK : %s (#%s) - aller-retour %s ms", session.name, session.id, roundTrip)

    session:Chat(Config.Server.WelcomeMessage)
    DS.Bus.Emit("Player:Loaded", session)
end

local function onHandshakeRequest(session)
    -- En "connecting", le Handshake partira automatiquement à l'évènement Ready
    if session.state == "connecting" then return end
    sendHandshake(session)
end

-- Tâche périodique unique (pas de timer par joueur)
local function maintenance()
    local now = Utils.NowMs()
    local timeout = Config.Server.HandshakeTimeoutMs
    for _, session in pairs(sessions) do
        if session.state == "ready" and not session.handshakeTimeoutReported
            and session.readyAt and now - session.readyAt > timeout then
            session.handshakeTimeoutReported = true
            Log:Warn("%s (#%s) n'a pas confirme le handshake apres %s : le gamemode client ne semble pas charge",
                session.name, session.id, Utils.FormatDuration(now - session.readyAt))
            if Config.Server.KickOnHandshakeTimeout then
                session:Kick("Le gamemode n'a pas pu etre charge sur votre client.")
            end
        end
    end
end

-- ===========================================================================
-- Cycle de vie du module
-- ===========================================================================

function Players:Init()
    Player.Subscribe("Spawn", createSession)
    Player.Subscribe("Ready", onReady)
    Player.Subscribe("Destroy", function(player)
        removeSession(player, "disconnect")
    end)

    DS.Net.Handle("HandshakeAck", onHandshakeAck)
    DS.Net.Handle("HandshakeRequest", onHandshakeRequest)
end

function Players:Start()
    -- Rechargement à chaud (package reload) : reprend les joueurs déjà connectés
    local adopted = 0
    for _, player in pairs(Player.GetPairs()) do
        if not sessions[player] then
            createSession(player)
            onReady(player)
            adopted = adopted + 1
        end
    end
    if adopted > 0 then
        Log:Info("%s joueur(s) deja connecte(s) repris apres rechargement", adopted)
    end

    maintenanceTimer = Timer.SetInterval(maintenance, Config.Server.MaintenanceIntervalMs)
end

function Players:Shutdown()
    if maintenanceTimer then
        Timer.ClearInterval(maintenanceTimer)
        maintenanceTimer = nil
    end
    -- Laisse aux systèmes l'occasion de sauvegarder (Phase 5)
    for _, session in pairs(sessions) do
        DS.Bus.Emit("Player:Leaving", session, "shutdown")
    end
end

-- ===========================================================================
-- API publique
-- ===========================================================================

function Players.Get(player)
    return sessions[player]
end

function Players.GetById(id)
    return byId[id]
end

function Players.GetByAccountId(accountId)
    for _, session in pairs(sessions) do
        if session.accountId == accountId then return session end
    end
    return nil
end

function Players.IsSession(value)
    return getmetatable(value) == Session
end

function Players.Count()
    return count
end

--- Toutes les sessions, triées par id.
function Players.All()
    local list = {}
    for _, session in pairs(sessions) do list[#list + 1] = session end
    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end

--- Sessions ayant entièrement chargé le gamemode.
function Players.GetLoaded()
    local list = {}
    for _, session in pairs(sessions) do
        if session.state == "loaded" then list[#list + 1] = session end
    end
    return list
end

--- Recherche par id (#12 ou 12) ou par partie du nom (insensible à la casse).
--- Retourne session | nil, message d'erreur.
function Players.Find(query)
    query = tostring(query or "")
    local id = tonumber((query:gsub("^#", "")))
    if id then
        local session = byId[id]
        if session then return session end
        return nil, "aucun joueur avec l'id #" .. id
    end

    local needle = query:lower()
    if needle == "" then return nil, "joueur non precise" end
    local found = nil
    for _, session in pairs(sessions) do
        if session.name:lower():find(needle, 1, true) then
            if found then return nil, "plusieurs joueurs correspondent a '" .. query .. "', utilisez l'id" end
            found = session
        end
    end
    if not found then return nil, "aucun joueur ne correspond a '" .. query .. "'" end
    return found
end

return Players
