--[[
    Demon Slayer RP - Configuration serveur
    ------------------------------------------------------------------
    Fichiers de Server/ : jamais envoyés aux joueurs.
]]

Config.Server = {
    -- Message envoyé dans le chat quand le joueur a entièrement chargé le gamemode
    WelcomeMessage = "Bienvenue sur <cyan>Demon Slayer RP</> ! Tapez <yellow>/ds_help</> pour la liste des commandes.",

    -- Délai maximal (ms) entre le "Ready" du joueur et la confirmation (HandshakeAck) de son client
    HandshakeTimeoutMs = 60000,
    -- Expulser le joueur si ce délai est dépassé (sinon simple avertissement dans les logs)
    KickOnHandshakeTimeout = false,

    -- Intervalle (ms) de la tâche de maintenance unique (contrôles périodiques).
    -- Une seule tâche pour tous les joueurs plutôt qu'un timer par joueur.
    MaintenanceIntervalMs = 5000,
}

-- Spawn TEMPORAIRE : permet de jouer et tester dès la Phase 1.
-- Il sera remplacé par le flux de création/sélection de personnage (Phase 4).
Config.Spawn = {
    Enabled = true,

    -- Modèle du personnage (asset pack "nanos-world" fourni avec le jeu)
    CharacterMesh = "nanos-world::SK_Mannequin",

    -- Délai avant réapparition après une mort (ms)
    RespawnDelayMs = 5000,

    -- Utilisés uniquement si la carte ne définit aucun point de spawn
    FallbackPoints = {
        { location = Vector(0, 0, 100), rotation = Rotator(0, 0, 0) },
    },
}
