--[[
    Black Clover RP — gamemode/cl_init.lua
    Realm : CLIENT

    Point d'entrée côté client.
    Le client charge shared.lua, qui démarre le loader : celui-ci inclut
    automatiquement tous les fichiers sh_ et cl_ envoyés par le serveur.
]]

include("shared.lua")
