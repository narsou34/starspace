--[[
    Demon Slayer RP - Network (client)
    ------------------------------------------------------------------
    Envoyer (Client -> Serveur) :
        DS.Net.Send("Ping", Client.GetTime())

    Recevoir (Serveur -> Client) :
        DS.Net.On("Pong", function(clientTime, serverTime) ... end)

    Le client n'est JAMAIS une autorité : il envoie des intentions, le serveur
    décide. Le limiteur local ci-dessous évite seulement qu'un usage normal
    déclenche l'anti-spam du serveur ; la vraie protection est côté serveur.
]]

local Network = DS.Module("Network")
DS.Net = Network

local Log = Network.Log

local buckets = {}
local stats = {
    sent = 0,
    throttled = 0,
    received = 0,
    invalid = 0,
    errors = 0,
}

--- Envoie un évènement déclaré dans DS.NetEvents.C2S. Retourne false si limité localement.
function Network.Send(name, ...)
    local def = DS.NetEvents.Get("C2S", name)
    if def.rate and not DS.Utils.ConsumeToken(buckets, name, def.rate, DS.Utils.NowMs()) then
        stats.throttled = stats.throttled + 1
        Log:Debug("Envoi de '%s' limite localement", name)
        return false
    end
    Events.CallRemote(def.wire, def.reliable and Reliability.Reliable or Reliability.Unreliable, ...)
    stats.sent = stats.sent + 1
    return true
end

--- Écoute un évènement déclaré dans DS.NetEvents.S2C.
function Network.On(name, handler)
    local def = DS.NetEvents.Get("S2C", name)
    assert(type(handler) == "function", "Net.On : fonction attendue pour " .. name)

    Events.SubscribeRemote(def.wire, function(...)
        stats.received = stats.received + 1
        local expected = #def.args
        local args = { ... }
        for i = 1, expected do
            local schema = def.args[i]
            local ok, result = DS.Validator.Check(args[i], schema, schema.name or ("arg" .. i))
            if not ok then
                stats.invalid = stats.invalid + 1
                Log:Warn("Donnees serveur inattendues pour '%s' : %s", name, result)
                return
            end
            args[i] = result
        end
        local ok, err = DS.Utils.Try(handler, table.unpack(args, 1, expected))
        if not ok then
            stats.errors = stats.errors + 1
            Log:Error("Handler '%s' en erreur : %s", name, err)
        end
    end)
end

function Network.GetStats()
    return DS.Utils.DeepCopy(stats)
end

return Network
