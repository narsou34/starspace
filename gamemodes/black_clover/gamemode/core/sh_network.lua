--[[
    Black Clover RP — core/sh_network.lua
    Realm : PARTAGÉ

    Couche réseau sécurisée, à utiliser À LA PLACE de net.Receive.

    Déclaration d'un message (dans un fichier sh_, pour que les deux côtés
    connaissent le nom) :
        BlackClover.Net.Register("BlackClover.Mana.Sync")

    Réception côté SERVEUR (message envoyé par un client) :
        BlackClover.Net.Receive("BlackClover.Spells.Cast", function(ply, len)
            local spellID = net.ReadString()
            -- valider spellID, le mana, le cooldown… ici
        end, {
            Cooldown     = 0.2,   -- secondes entre deux messages de ce type
            MaxBytes     = 256,   -- taille max du message
            RequireAlive = true,  -- refusé si le joueur est mort
            RequireStaff = false, -- réservé au staff
        })

    Réception côté CLIENT (message envoyé par le serveur) :
        BlackClover.Net.Receive("BlackClover.Mana.Sync", function(len)
            local mana = net.ReadFloat()
        end)

    Protections automatiques côté serveur :
        - joueur valide ;
        - taille maximale du message ;
        - cooldown par message et par joueur ;
        - limite globale de messages par seconde (anti-flood) ;
        - erreurs Lua du callback capturées et loguées (le serveur ne casse pas).

    ⚠ Ces protections ne remplacent pas la validation des DONNÉES :
      chaque callback doit vérifier ce qu'il lit (Util.ToNumber, SanitizeString…).
]]

BlackClover.Net = BlackClover.Net or {}
local Net = BlackClover.Net

Net.Messages = Net.Messages or {}

--- Déclare un message réseau. À appeler dans un fichier sh_ (ou sv_).
-- Côté serveur, enregistre la chaîne (util.AddNetworkString).
function Net.Register(name)
    if SERVER then
        util.AddNetworkString(name)
    end

    Net.Messages[name] = true
end

if SERVER then
    local Config = BlackClover.Config
    local Log = BlackClover.Log
    local Permissions = BlackClover.Permissions

    --- Anti-flood global : limite le nombre de messages par seconde et par joueur.
    -- @return boolean true si le message peut être traité
    local function CheckFlood(ply)
        local now = SysTime()
        local data = ply.bcNetFlood

        if not data or now - data.Start >= 1 then
            data = { Start = now, Count = 0, Warned = false }
            ply.bcNetFlood = data
        end

        data.Count = data.Count + 1

        local limit = Config.Net.MaxMessagesPerSecond
        if data.Count <= limit then return true end

        if not data.Warned then
            data.Warned = true
            Log.Warn("Network", "Flood réseau détecté : %s (%d+ messages/s)", Log.FormatPlayer(ply), limit)
        end

        if Config.Net.KickOnFlood and data.Count > limit * 2 then
            Log.Admin("Network", "%s expulsé pour flood réseau", Log.FormatPlayer(ply))
            ply:Kick("Flood réseau détecté")
        end

        return false
    end

    --- Cooldown par message et par joueur.
    -- @return boolean true si le cooldown est écoulé
    local function CheckCooldown(ply, name, cooldown)
        if cooldown <= 0 then return true end

        local now = SysTime()
        ply.bcNetCooldowns = ply.bcNetCooldowns or {}

        if (ply.bcNetCooldowns[name] or 0) > now then
            return false
        end

        ply.bcNetCooldowns[name] = now + cooldown
        return true
    end

    --- Reçoit un message client de façon sécurisée.
    -- @param name string Nom du message (doit avoir été Register)
    -- @param callback function(ply, len)
    -- @param options table|nil Cooldown, MaxBytes, RequireAlive, RequireStaff
    function Net.Receive(name, callback, options)
        options = options or {}

        if not Net.Messages[name] then
            Net.Register(name)
            Log.Warn("Network", "Message \"%s\" reçu sans Register préalable, enregistré automatiquement", name)
        end

        local cooldown = options.Cooldown or Config.Net.DefaultCooldown
        local maxBytes = options.MaxBytes or Config.Net.DefaultMaxBytes

        net.Receive(name, function(len, ply)
            if not BlackClover.Util.IsValidPlayer(ply) then return end
            if not CheckFlood(ply) then return end

            -- len est en bits
            if len / 8 > maxBytes then
                Log.Warn("Network", "Message \"%s\" trop gros (%d octets) de %s", name, math.ceil(len / 8), Log.FormatPlayer(ply))
                return
            end

            if not CheckCooldown(ply, name, cooldown) then return end

            if options.RequireAlive and not ply:Alive() then return end

            if options.RequireStaff and not Permissions.IsStaff(ply) then
                Log.Admin("Network", "Accès refusé à \"%s\" pour %s (non staff)", name, Log.FormatPlayer(ply))
                return
            end

            local ok, err = xpcall(callback, debug.traceback, ply, len)
            if not ok then
                Log.Error("Network", "Erreur dans \"%s\" (joueur %s) :\n%s", name, Log.FormatPlayer(ply), err)
            end
        end)
    end
else
    --- Reçoit un message serveur côté client (erreurs capturées).
    function Net.Receive(name, callback)
        Net.Messages[name] = true

        net.Receive(name, function(len)
            local ok, err = xpcall(callback, debug.traceback, len)
            if not ok then
                BlackClover.Log.Error("Network", "Erreur dans \"%s\" :\n%s", name, err)
            end
        end)
    end
end

-- ─── Messages du core ───────────────────────────────────────────────────
-- Le client signale qu'il est prêt à recevoir des données (voir cl_player.lua).
Net.Register("BlackClover.PlayerReady")
