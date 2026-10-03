--[[
    Demon Slayer RP - Contrat réseau
    ------------------------------------------------------------------
    Liste UNIQUE de tous les évènements réseau du gamemode, partagée par le
    serveur et le client. Aucun évènement ne peut être envoyé ou écouté s'il
    n'est pas déclaré ici (ou via DS.NetEvents.Define dans un futur système).

    C2S = Client -> Serveur (toujours validé par le serveur)
      args       : schémas DS.Validator, dans l'ordre des arguments
      rate       : { max, windowMs } limite de débit par joueur (token bucket)
      state      : état minimal de la session : "connecting" < "ready" < "loaded"
      permission : permission requise (optionnel)
      reliable   : false pour un envoi non garanti (défaut : true)

    S2C = Serveur -> Client
      args       : schémas (contrôle de cohérence côté client)

    Nom réseau réel : "DSRP:<direction>:<Nom>"   ex : "DSRP:C2S:Ping"
    (préfixe pour éviter toute collision avec d'autres packages)
]]

local NetEvents = { C2S = {}, S2C = {} }
DS.NetEvents = NetEvents

local PREFIX = "DSRP"
local VALID_STATES = { connecting = true, ready = true, loaded = true }

--- Déclare un évènement réseau. Utilisable par les futurs systèmes depuis leurs fichiers Shared.
function NetEvents.Define(direction, name, def)
    assert(direction == "C2S" or direction == "S2C", "NetEvents.Define : direction invalide")
    assert(type(name) == "string" and name:match("^[%w_]+$"), "NetEvents.Define : nom invalide")
    if NetEvents[direction][name] then
        error(("NetEvents.Define : %s.%s est deja declare"):format(direction, name), 2)
    end
    def = def or {}
    def.name = name
    def.direction = direction
    def.wire = PREFIX .. ":" .. direction .. ":" .. name
    def.args = def.args or {}
    def.reliable = def.reliable ~= false
    if direction == "C2S" then
        def.state = def.state or "loaded"
        assert(VALID_STATES[def.state], "NetEvents.Define : state invalide pour " .. name)
    end
    NetEvents[direction][name] = def
    return def
end

--- Récupère la définition d'un évènement (erreur explicite s'il n'existe pas).
function NetEvents.Get(direction, name)
    local def = NetEvents[direction] and NetEvents[direction][name]
    if not def then
        error(("Evenement reseau inconnu : %s.%s"):format(tostring(direction), tostring(name)), 3)
    end
    return def
end

-- ===========================================================================
-- Client -> Serveur
-- ===========================================================================

-- Le client redemande la poignée de main (ex : après un rechargement du package)
NetEvents.Define("C2S", "HandshakeRequest", {
    args = {},
    rate = { max = 1, windowMs = 3000 },
    state = "connecting",
})

-- Le client confirme la réception de la poignée de main
NetEvents.Define("C2S", "HandshakeAck", {
    args = {
        { name = "version", type = "string", maxLength = 32 },
    },
    rate = { max = 2, windowMs = 5000 },
    state = "ready",
})

-- Mesure de la latence aller-retour applicative
NetEvents.Define("C2S", "Ping", {
    args = {
        { name = "clientTime", type = "number", integer = true, min = 0 },
    },
    rate = { max = 4, windowMs = 1000 },
    state = "loaded",
})

-- ===========================================================================
-- Serveur -> Client
-- ===========================================================================

-- Poignée de main : informations de session envoyées quand le joueur est prêt
NetEvents.Define("S2C", "Handshake", {
    args = {
        {
            name = "payload",
            type = "table",
            fields = {
                gamemode   = { type = "string", maxLength = 64 },
                version    = { type = "string", maxLength = 32 },
                author     = { type = "string", maxLength = 64 },
                sessionId  = { type = "number", integer = true },
                name       = { type = "string", maxLength = 128 },
                group      = { type = "string", maxLength = 32 },
                groupLabel = { type = "string", maxLength = 64 },
                serverTime = { type = "number", integer = true },
                debug      = { type = "boolean" },
            },
        },
    },
})

-- Réponse au Ping
NetEvents.Define("S2C", "Pong", {
    args = {
        { name = "clientTime", type = "number", integer = true },
        { name = "serverTime", type = "number", integer = true },
    },
})

-- Notification à afficher au joueur
NetEvents.Define("S2C", "Notify", {
    args = {
        { name = "message", type = "string", maxLength = 512 },
        { name = "kind", type = "string", enum = { "info", "success", "warning", "error" }, optional = true, default = "info" },
        { name = "durationSec", type = "number", min = 1, max = 60, optional = true, default = 5 },
    },
})

return NetEvents
