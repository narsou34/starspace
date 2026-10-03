--[[
    ╔══════════════════════════════════════════════════════════╗
    ║                    BLACK CLOVER RP                       ║
    ║                 Auteur  : NARSOU                         ║
    ║                 Version : 0.1.0                          ║
    ╚══════════════════════════════════════════════════════════╝

    Fichier : gamemode/init.lua
    Realm   : SERVEUR

    Point d'entrée côté serveur.
    - Envoie au client les fichiers dont il a besoin (cl_init.lua, shared.lua).
    - Charge shared.lua, qui démarre le loader du gamemode.

    Tous les autres fichiers (core, config, systems, ui) sont envoyés
    et inclus automatiquement par le loader (core/sh_loader.lua)
    selon leur préfixe : sv_ / cl_ / sh_.
]]

-- Fichiers envoyés au client
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

-- Chargement du code partagé (et donc de tout le gamemode)
include("shared.lua")

--[[
    Contenu (matériaux, sons, modèles)
    Le dossier "content/" du gamemode est monté automatiquement par
    Garry's Mod. Pour un serveur public, il faudra plus tard publier ce
    contenu sur le Workshop et l'ajouter ici :

    resource.AddWorkshop("ID_WORKSHOP")
]]
