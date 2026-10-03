--[[
    Black Clover RP — gamemode/shared.lua
    Realm : PARTAGÉ (serveur + client)

    - Déclare les informations du gamemode.
    - Dérive de "sandbox" pour conserver les outils de construction du staff
      (physgun, toolgun, menu de spawn). Les joueurs normaux sont restreints
      par core/sv_player.lua et core/cl_player.lua.
    - Crée la table globale BlackClover, unique point d'accès au gamemode.
    - Démarre le loader qui charge core/, config/, systems/ et ui/.
]]

-- ─── Informations du gamemode ───────────────────────────────────────────
GM.Name    = "Black Clover RP"
GM.Author  = "NARSOU"
GM.Email   = ""
GM.Website = ""
GM.Version = "0.1.0"

DeriveGamemode("sandbox")

-- ─── Table globale ──────────────────────────────────────────────────────
-- "or {}" : permet le rechargement à chaud (lua autorefresh) sans perdre l'état.
BlackClover = BlackClover or {}

BlackClover.Name       = GM.Name
BlackClover.Author     = GM.Author
BlackClover.Version    = GM.Version
BlackClover.FolderName = GM.FolderName -- "black_clover" (nom du dossier dans gamemodes/)

-- ─── Démarrage du loader ────────────────────────────────────────────────
if SERVER then
    AddCSLuaFile("core/sh_loader.lua")
end
include("core/sh_loader.lua")

BlackClover.Loader.Boot()
