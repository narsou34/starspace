--[[
    Black Clover RP — config/sh_factions.lua
    Realm : PARTAGÉ

    Royaumes (choisis à la création du personnage).
    Les factions complètes (ordres des Chevaliers-Mages, chefs, salaires,
    permissions…) seront ajoutées dans ce fichier lors de l'étape Factions.
]]

local Config = BlackClover.Config

Config.Kingdoms = {
    clover  = { Name = "Royaume de Clover",  Color = Color(46, 160, 87),  Order = 1 },
    diamond = { Name = "Royaume de Diamond", Color = Color(90, 170, 255), Order = 2 },
    heart   = { Name = "Royaume de Heart",   Color = Color(230, 90, 130), Order = 3 },
    spade   = { Name = "Royaume de Spade",   Color = Color(120, 80, 160), Order = 4 },
}

Config.Factions = Config.Factions or {}
