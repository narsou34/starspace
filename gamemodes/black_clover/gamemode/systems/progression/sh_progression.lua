--[[
    Black Clover RP — systems/progression/sh_progression.lua
    Realm : PARTAGÉ

    Progression RPG : niveau, expérience et statistiques.
    Formules dans config/sh_progression.lua.

    Accesseurs (serveur et client) :
        ply:GetLevel()        ply:GetXP()           ply:GetXPForNextLevel()
        ply:GetMagicPower()   ply:GetManaControl()  ply:GetMastery()
]]

BlackClover.Progression = BlackClover.Progression or {}
local Progression = BlackClover.Progression
local Config = BlackClover.Config

--- XP nécessaire pour passer du niveau "level" au suivant.
function Progression.GetXPForLevel(level)
    if level >= Config.Progression.MaxLevel then return 0 end

    local ok, value = pcall(Config.Progression.XPForLevel, level)
    return (ok and tonumber(value)) and math.max(math.floor(value), 1) or 100
end

local PLAYER = FindMetaTable("Player")

function PLAYER:GetLevel()
    return self:GetNW2Int("BC_Level", 1)
end

function PLAYER:GetXP()
    return self:GetNW2Int("BC_XP", 0)
end

function PLAYER:GetXPForNextLevel()
    return Progression.GetXPForLevel(self:GetLevel())
end

function PLAYER:GetMagicPower()
    return self:GetNW2Int("BC_MagicPower", 0)
end

function PLAYER:GetManaControl()
    return self:GetNW2Int("BC_ManaControl", 0)
end

--- Maîtrise = niveau du grimoire (0 sans grimoire).
function PLAYER:GetMastery()
    return self:GetNW2Int("BC_GrimoireLevel", 0)
end
