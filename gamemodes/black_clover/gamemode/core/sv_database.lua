--[[
    Black Clover RP — core/sv_database.lua
    Realm : SERVEUR

    Abstraction de base de données.
    ► Implémentation complète en PHASE 3.

    Objectif : tous les systèmes passent par BlackClover.Database et ne
    savent pas s'ils parlent à SQLite ou à MySQL. Changer de moteur se fera
    uniquement dans core/sv_config.lua (Config.Database.Driver).

    API prévue :
        DB.Initialize()                                  -- connexion + création des tables
        DB.Query(sql, params, onSuccess, onError)        -- requête paramétrée (anti-injection)
        DB.Escape(value)                                 -- échappement d'une valeur
        DB.Table(name)                                   -- "characters" → "bc_characters"
        DB.RegisterTable(name, schema)                   -- déclaration de table par un système
]]

BlackClover.Database = BlackClover.Database or {}
local DB = BlackClover.Database
local Config = BlackClover.Config
local Log = BlackClover.Log

DB.Connected = DB.Connected or false

--- Renvoie le nom réel d'une table avec le préfixe configuré.
function DB.Table(name)
    return Config.Database.TablePrefix .. name
end

--- Initialise la base de données (version Phase 1 : vérification uniquement).
function DB.Initialize()
    local driver = Config.Database.Driver

    if driver ~= "sqlite" and driver ~= "mysql" then
        Log.Error("Database", "Driver inconnu \"%s\" (attendu : sqlite ou mysql)", tostring(driver))
        return
    end

    Log.Info("Database", "Driver configuré : %s — implémentation complète en Phase 3", driver)
end

hook.Add("BlackClover.Initialized", "BlackClover.Database.Initialize", DB.Initialize)
