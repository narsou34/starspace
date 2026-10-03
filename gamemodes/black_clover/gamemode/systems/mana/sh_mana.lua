--[[
    Black Clover RP — systems/mana/sh_mana.lua
    Realm : PARTAGÉ

    Système de mana : accesseurs (lecture) disponibles des deux côtés.
    Les modifications (SetMana, ConsumeMana…) n'existent QUE côté serveur.

        ply:GetMana()       mana actuel
        ply:GetMaxMana()    mana maximum
        ply:GetManaRegen()  régénération par seconde
        ply:HasMana(n)      le joueur a-t-il au moins n mana ?
]]

BlackClover.Mana = BlackClover.Mana or {}

local PLAYER = FindMetaTable("Player")

function PLAYER:GetMana()
    return self:GetNW2Float("BC_Mana", 0)
end

function PLAYER:GetMaxMana()
    return self:GetNW2Float("BC_MaxMana", 0)
end

function PLAYER:GetManaRegen()
    return self:GetNW2Float("BC_ManaRegen", 0)
end

function PLAYER:HasMana(amount)
    return self:GetMana() >= (tonumber(amount) or 0)
end
