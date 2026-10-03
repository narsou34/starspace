--[[
    Demon Slayer RP - Sécurité réseau
    ------------------------------------------------------------------
    Le serveur est autoritaire : chaque évènement client est contrôlé
    (débit, état de la session, permission, types et bornes des arguments)
    AVANT d'atteindre la logique de jeu.

    Score d'infraction : chaque infraction ajoute un poids au score du joueur,
    qui diminue avec le temps. Au-delà du seuil, le joueur est expulsé.
    Un joueur honnête avec un peu de lag ne doit jamais atteindre le seuil.
]]

Config.Security = {
    -- Débit global max d'évènements réseau par joueur, tous évènements confondus
    GlobalRate = { max = 30, windowMs = 1000 },

    -- Débit par défaut d'un évènement qui n'en déclare pas
    DefaultRate = { max = 5, windowMs = 1000 },

    -- Bornes appliquées à toutes les données reçues
    MaxStringLength = 256,
    MaxTableEntries = 64,
    MaxTableDepth = 4,

    -- Poids de chaque type d'infraction
    ViolationWeights = {
        rate = 1,          -- trop d'envois
        state = 1,         -- évènement reçu au mauvais moment (ex : avant le chargement)
        invalid = 3,       -- arguments invalides (type, bornes, champs inconnus...)
        unauthorized = 3,  -- permission manquante
    },
    -- Points retirés du score par seconde sans infraction
    ViolationDecayPerSecond = 0.5,
    -- Score déclenchant l'expulsion
    KickThreshold = 20,
    KickEnabled = true,
    KickReason = "Activite reseau anormale detectee (anti-exploit).",

    -- Anti-flood des logs : une ligne max par joueur et par type d'infraction sur cet intervalle
    LogThrottleMs = 2000,

    -- Limite des commandes chat (/ds_...) par joueur
    CommandRate = { max = 5, windowMs = 3000 },
    MaxCommandLength = 256,
}
