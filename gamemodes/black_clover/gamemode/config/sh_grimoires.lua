--[[
    Black Clover RP — config/sh_grimoires.lua
    Realm : PARTAGÉ

    Types de grimoires et réglages de la cérémonie.

    ► Les probabilités (Chance) sont des POIDS : 85 / 14 / 1 donne bien
      85 %, 14 % et 1 % car le total fait 100, mais un total différent
      fonctionne aussi (les chances sont relatives).

    Champs d'un type :
        ID                identifiant unique (sauvegardé en base)
        Name              nom affiché
        Leaves            nombre de feuilles (dessinées sur la couverture)
        Rarity            clé de Config.Rarities
        Chance            poids du tirage
        Slots             nombre de sorts équipables en même temps
        PowerMultiplier   multiplicateur de dégâts / soins
        ManaMultiplier    multiplicateur de mana maximum
]]

local Config = BlackClover.Config

Config.Grimoires = {
    {
        ID = "three_leaf",
        Name = "Three Leaf",
        Leaves = 3,
        Rarity = "Common",
        Chance = 85,
        Slots = 4,
        PowerMultiplier = 1.0,
        ManaMultiplier = 1.0,
    },

    {
        ID = "four_leaf",
        Name = "Four Leaf",
        Leaves = 4,
        Rarity = "Rare",
        Chance = 14,
        Slots = 5,
        PowerMultiplier = 1.15,
        ManaMultiplier = 1.15,
    },

    {
        ID = "five_leaf",
        Name = "Five Leaf",
        Leaves = 5,
        Rarity = "Legendary",
        Chance = 1,
        Slots = 6,
        PowerMultiplier = 1.3,
        ManaMultiplier = 1.25,
    },
}

Config.Grimoire = {
    -- Conditions pour recevoir son grimoire à la Tour des Grimoires
    MinLevel = 1,
    MinAge   = 15,

    -- Durée de la cérémonie (secondes)
    CeremonyDuration = 6,

    -- Maîtrise du grimoire (niveau du grimoire)
    MaxLevel = 50,
    XPPerCast = 4,
    XPForLevel = function(level)
        return math.floor(60 * level ^ 1.4)
    end,

    -- Nombre d'entrées conservées dans l'historique
    MaxHistory = 40,
}
