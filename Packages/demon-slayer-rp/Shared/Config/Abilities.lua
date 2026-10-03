--[[
    Demon Slayer RP - Techniques : réglages généraux et ressources
    ------------------------------------------------------------------
    Les Souffles sont dans BreathingStyles.lua, les Arts dans DemonArts.lua.
]]

Config.Abilities = {
    -- Touches par défaut (modifiables par chaque joueur dans Paramètres > Touches)
    -- Emplacement 1..4 = techniques, 5 = technique spéciale
    Keys = { "Q", "E", "R", "F", "X" },

    -- Délai minimal entre deux techniques quelles qu'elles soient (anti-macro)
    GlobalCooldownMs = 400,

    -- Les membres d'une même faction peuvent-ils se blesser ?
    FriendlyFire = false,

    -- Fréquence de la tâche unique ressources / régénération / effets (ms)
    TickMs = 500,

    -- Mannequins d'entraînement (/ds_npc)
    MaxTrainingDummies = 10,
    TrainingDummyHealth = 300,

    -- Valeurs par défaut de chaque technique (surchargées technique par technique)
    TechniqueDefaults = {
        Shape = "cone",          -- "cone" | "circle" | "line" | "dash" | "self"
        Range = 400,             -- portée (cm, 100 = 1 m)
        Angle = 90,              -- ouverture du cône (degrés)
        Width = 200,             -- largeur d'une ligne / d'un dash
        Height = 250,            -- tolérance de hauteur
        MaxTargets = 5,
        Damage = 20,
        Cost = 15,
        CooldownMs = 3000,
        Knockback = 0,           -- projection des cibles
        Dash = 0,                -- élan donné au lanceur
        Animation = "nanos-world::A_Mannequin_Taunt_Chop",
        AnimationSlot = "UpperBody", -- "FullBody" | "UpperBody"
        Effect = "nanos-world::P_FXVariety_Hit_01",
        EffectDuration = 1.5,    -- secondes
        EffectOffset = 150,      -- distance devant le lanceur
        Sound = "nanos-world::A_Whoosh",
    },
}

-- Ressources consommées par les techniques
Config.Resources = {
    breath = {
        Label = "Souffle",
        Max = 100,
        RegenPerSecond = 8,
        RegenDelayMs = 1500,     -- délai après une technique avant de récupérer
    },
    blood = {
        Label = "Energie demoniaque",
        Max = 120,
        RegenPerSecond = 6,
        RegenDelayMs = 2000,
    },
}
