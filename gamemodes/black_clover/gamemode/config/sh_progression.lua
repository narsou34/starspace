--[[
    Black Clover RP — config/sh_progression.lua
    Realm : PARTAGÉ

    Progression RPG et mana.

    Statistiques d'un personnage :
        Niveau / Expérience
        Puissance magique  → augmente les dégâts et les soins
        Contrôle de mana   → augmente le mana max et la régénération
        Maîtrise           → niveau du grimoire (augmente avec l'utilisation des sorts)
]]

local Config = BlackClover.Config

Config.Progression = {
    MaxLevel = 100,

    -- XP nécessaire pour passer du niveau "level" au niveau "level + 1"
    XPForLevel = function(level)
        return math.floor(100 * level ^ 1.5)
    end,

    -- Statistiques gagnées à chaque niveau
    StatsPerLevel = {
        MagicPower  = 1,
        ManaControl = 1,
    },

    -- Effet des statistiques
    DamagePerMagicPower    = 0.02, -- +2 % de dégâts par point
    DamagePerGrimoireLevel = 0.01, -- +1 % de dégâts par niveau de maîtrise

    -- Gains d'XP
    XPPerCast       = 1,    -- par sort lancé avec succès
    XPPerNPCKill    = 15,
    XPPerPlayerKill = 40,
    PlayerKillCooldown = 300, -- pas d'XP pour tuer la même personne avant X secondes

    -- Limite de sécurité pour une seule attribution d'XP
    MaxXPGain = 1000000,
}

Config.Mana = {
    Base          = 100, -- mana max de base
    PerLevel      = 8,   -- + par niveau
    PerManaControl = 2,  -- + par point de contrôle de mana

    RegenBase           = 4,    -- mana / seconde
    RegenPerManaControl = 0.08, -- + mana / seconde par point de contrôle

    RegenDelay = 1.5,  -- secondes sans régénération après une consommation
    TickRate   = 0.25, -- fréquence de mise à jour (secondes)

    RespawnFraction = 1, -- part du mana max rendue à la réapparition (0 à 1)
}
