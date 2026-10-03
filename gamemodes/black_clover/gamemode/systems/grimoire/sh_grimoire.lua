--[[
    Black Clover RP — systems/grimoire/sh_grimoire.lua
    Realm : PARTAGÉ

    Grimoires : types (config/sh_grimoires.lua) et accesseurs publics.

        Grimoire.GetType(id)            → type de grimoire ("three_leaf"…)
        Grimoire.GetTypeByLeaves(n)     → type correspondant à n feuilles
        Grimoire.GetXPForLevel(level)   → XP de maîtrise pour passer au niveau suivant

        ply:HasGrimoire()               ply:GetGrimoireLeaves()
        ply:GetGrimoireLevel()          ply:GetSpellSlot()
]]

BlackClover.Grimoire = BlackClover.Grimoire or {}
local Grimoire = BlackClover.Grimoire
local Config = BlackClover.Config

local Net = BlackClover.Net
Net.Register("BlackClover.Grimoire.Sync")       -- serveur → propriétaire : contenu complet
Net.Register("BlackClover.Grimoire.Ceremony")   -- serveur → client : étapes de la cérémonie
Net.Register("BlackClover.Grimoire.Equip")      -- client → serveur : équiper un sort

Grimoire.WeaponClass = "weapon_bc_grimoire"

function Grimoire.GetType(id)
    for _, gtype in ipairs(Config.Grimoires) do
        if gtype.ID == id then return gtype end
    end
end

function Grimoire.GetTypeByLeaves(leaves)
    for _, gtype in ipairs(Config.Grimoires) do
        if gtype.Leaves == leaves then return gtype end
    end
end

function Grimoire.GetXPForLevel(level)
    if level >= Config.Grimoire.MaxLevel then return 0 end

    local ok, value = pcall(Config.Grimoire.XPForLevel, level)
    return (ok and tonumber(value)) and math.max(math.floor(value), 1) or 100
end

local PLAYER = FindMetaTable("Player")

function PLAYER:GetGrimoireLeaves()
    return self:GetNW2Int("BC_GrimoireLeaves", 0)
end

function PLAYER:HasGrimoire()
    if SERVER then return self.bcGrimoire ~= nil end
    return self:GetGrimoireLeaves() > 0
end

function PLAYER:GetGrimoireLevel()
    return self:GetNW2Int("BC_GrimoireLevel", 0)
end

--- Emplacement de sort sélectionné (1 à nombre d'emplacements).
function PLAYER:GetSpellSlot()
    return self:GetNW2Int("BC_SpellSlot", 1)
end
