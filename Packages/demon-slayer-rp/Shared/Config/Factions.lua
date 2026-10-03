--[[
    Demon Slayer RP - Factions (configuration de base)
    ------------------------------------------------------------------
    Version minimale pour les techniques. Les grades, permissions RP et
    la création de personnage viendront avec les Phases 4, 6 et 7.

    Aliases : mots acceptés dans les commandes (/ds_setfaction moi demon).
]]

Config.Factions = {
    slayers = {
        Label = "Pourfendeurs de demons",
        Aliases = { "pourfendeur", "pourfendeurs", "slayer", "slayers", "p" },
        ChatColor = "cyan",
        MaxHealth = 100,
        Resource = "breath",      -- voir Config.Resources
        AbilityKind = "breathing", -- les pourfendeurs utilisent les Souffles
    },
    demons = {
        Label = "Demons",
        Aliases = { "demon", "demons", "oni", "d" },
        ChatColor = "red",
        MaxHealth = 150,
        Resource = "blood",
        AbilityKind = "art",       -- les démons utilisent les Arts démoniaques
        -- Régénération passive des démons
        Regeneration = {
            HealthPerSecond = 4,
            DelayAfterDamageMs = 3000,  -- pas de régénération juste après un coup
        },
    },
}
