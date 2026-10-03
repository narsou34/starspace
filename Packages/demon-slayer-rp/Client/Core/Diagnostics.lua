--[[
    Demon Slayer RP - Diagnostics (client)
    ------------------------------------------------------------------
    Commandes de la console du JEU (touche "Console" dans les paramètres) :

        ds_ping                 latence aller-retour applicative
        ds_session              informations de session reçues du serveur
        ds_netstats             statistiques réseau du client

    Uniquement si le serveur est en mode debug :
        ds_test_spam [n]        envoie n Ping d'un coup (contourne le limiteur local)
                                -> vérifie l'anti-spam du serveur
        ds_test_invalid         envoie des données invalides
                                -> vérifie la validation du serveur

    Les commandes de test reproduisent ce que pourrait faire un client
    malveillant : elles ne donnent aucun pouvoir, le serveur les rejette.
]]

local Diagnostics = DS.Module("Diagnostics", { dependencies = { "Network", "Session" } })

local Log = Diagnostics.Log

local function requireSession()
    if not DS.Session.IsReady() then
        Log:Warn("Session non etablie : le serveur n'a pas encore envoye la poignee de main")
        return false
    end
    return true
end

local function requireDebug()
    if not requireSession() then return false end
    if not DS.Session.IsDebug() then
        Log:Warn("Commande de test disponible uniquement quand le serveur est en mode debug")
        return false
    end
    return true
end

local function onPong(clientTime, serverTime)
    local now = DS.Utils.NowMs()
    local rtt = now - clientTime
    Log:Info("Pong : aller-retour %s ms (ecart horloge serveur %s ms)", rtt, serverTime - now)
    Chat.AddMessage("<cyan>[DSRP]</> Ping : " .. rtt .. " ms")
end

function Diagnostics:Init()
    DS.Net.On("Pong", onPong)

    Console.RegisterCommand("ds_ping", function()
        if not requireSession() then return end
        if not DS.Net.Send("Ping", DS.Utils.NowMs()) then
            Log:Warn("Trop de ping : patientez une seconde")
        end
    end, "Mesure la latence avec le serveur Demon Slayer RP")

    Console.RegisterCommand("ds_session", function()
        local data = DS.Session.Get()
        if not data then
            Log:Info("Aucune session (poignee de main non recue)")
            return
        end
        Log:Info("Session #%s : %s | groupe %s (%s) | %s v%s | debug %s",
            data.sessionId, data.name, data.groupLabel, data.group, data.gamemode, data.version, tostring(data.debug))
    end, "Affiche la session Demon Slayer RP")

    Console.RegisterCommand("ds_netstats", function()
        local stats = DS.Net.GetStats()
        Log:Info("Envoyes %s | limites localement %s | recus %s | invalides %s | erreurs %s",
            stats.sent, stats.throttled, stats.received, stats.invalid, stats.errors)
    end, "Statistiques reseau du client Demon Slayer RP")

    Console.RegisterCommand("ds_test_spam", function(amount)
        if not requireDebug() then return end
        local n = math.floor(math.max(1, math.min(tonumber(amount) or 10, 100)))
        local wire = DS.NetEvents.Get("C2S", "Ping").wire
        for _ = 1, n do
            Events.CallRemote(wire, Reliability.Reliable, DS.Utils.NowMs())
        end
        Log:Warn("%s Ping envoyes sans limitation : consultez la console du serveur", n)
    end, "[DEBUG] Teste l'anti-spam du serveur", { "nombre" })

    Console.RegisterCommand("ds_test_invalid", function()
        if not requireDebug() then return end
        local wire = DS.NetEvents.Get("C2S", "Ping").wire
        Events.CallRemote(wire, Reliability.Reliable, "pas_un_nombre")   -- mauvais type
        Events.CallRemote(wire, Reliability.Reliable, -50)               -- hors bornes
        Events.CallRemote(wire, Reliability.Reliable, 1, 2, 3)           -- trop d'arguments
        Log:Warn("3 messages invalides envoyes : consultez la console du serveur")
    end, "[DEBUG] Teste la validation des donnees du serveur")
end

return Diagnostics
