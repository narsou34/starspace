--[[
    Black Clover RP — core/sv_config.lua
    Realm : SERVEUR UNIQUEMENT

    Configuration sensible ou purement serveur.
    Grâce au préfixe "sv_", ce fichier n'est JAMAIS envoyé aux clients :
    c'est ici que vont les identifiants de base de données.
]]

local Config = BlackClover.Config

-- ─── Base de données (implémentée en Phase 3) ───────────────────────────
Config.Database = {
    -- "sqlite" : base locale intégrée à Garry's Mod (garrysmod/sv.db)
    -- "mysql"  : nécessite le module binaire MySQLOO sur le serveur
    Driver = "sqlite",

    -- Préfixe ajouté à toutes les tables (bc_characters, bc_grimoires…)
    TablePrefix = "bc_",

    MySQL = {
        Host     = "127.0.0.1",
        Port     = 3306,
        Database = "blackclover",
        Username = "root",
        Password = "",
    },
}

-- ─── Sauvegarde (utilisée à partir de la Phase 2/3) ─────────────────────
Config.Save = {
    AutoSaveInterval = 300, -- secondes entre deux sauvegardes automatiques
}

-- ─── Logs ───────────────────────────────────────────────────────────────
Config.Logging = {
    -- Écrit les logs dans garrysmod/data/<Directory>/AAAA-MM-JJ.txt
    WriteToFile = true,
    Directory   = "blackclover/logs",
}
