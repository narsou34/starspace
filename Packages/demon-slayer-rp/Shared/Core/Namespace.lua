--[[
    Demon Slayer RP - Namespace
    ------------------------------------------------------------------
    Définit la table racine `DS` utilisée par tous les fichiers du package.

    Chaque package nanos world s'exécute dans son propre environnement Lua :
    les globales définies ici (DS, Config) ne sont visibles que par ce package,
    côté serveur comme côté client.
]]

DS = DS or {}

DS.Name    = "Demon Slayer RP"
DS.Short   = "DSRP"
DS.Author  = "NARSOU"
-- La version provient du Package.toml (source unique de vérité)
DS.Version = Package.GetVersion() or "0.0.0"
DS.Package = Package.GetName()

-- "Shared" tant que Server/Index.lua ou Client/Index.lua n'a pas indiqué le côté.
DS.Side = DS.Side or "Shared"

function DS.SetSide(side)
    assert(side == "Server" or side == "Client", "DS.SetSide : cote invalide '" .. tostring(side) .. "'")
    DS.Side = side
end

function DS.IsServer()
    return DS.Side == "Server"
end

function DS.IsClient()
    return DS.Side == "Client"
end

-- Table globale de configuration, remplie par les fichiers Config/ (partagés puis serveur).
Config = Config or {}
DS.Config = Config

return DS
