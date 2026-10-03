--[[
    Demon Slayer RP - Configuration générale (PARTAGÉE)
    ------------------------------------------------------------------
    ⚠ Le dossier Shared/ est téléchargé par les joueurs :
      ne JAMAIS mettre d'information sensible ici (Account ID du staff,
      identifiants de base de données...). Utiliser Server/Config/ pour cela.
]]

Config.Core = {
    -- Langue des messages joueurs (préparation de la localisation)
    Language = "fr",

    -- Mode debug : logs DEBUG + commandes de test client.
    -- Côté serveur, il peut être surchargé sans toucher au code via
    -- [custom_settings] debug_mode = false   (Config.toml du serveur)
    Debug = true,

    -- Niveau minimal des logs hors mode debug : "DEBUG", "INFO", "WARN", "ERROR"
    LogLevel = "INFO",

    -- Nombre d'entrées de log gardées en mémoire (outils staff futurs)
    LogHistorySize = 200,

    -- Préfixe des messages du gamemode dans le chat
    ChatPrefix = "<cyan>[DSRP]</>",
}
