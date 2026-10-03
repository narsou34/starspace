--[[
    Demon Slayer RP - Point d'entrée PARTAGÉ
    ------------------------------------------------------------------
    Exécuté en premier, sur le serveur ET sur chaque client
    (ordre nanos world : Shared/Index.lua -> Server|Client/Index.lua -> évènement "Load").

    Contient uniquement du code sans effet de bord : définitions, utilitaires,
    configuration et contrat réseau. Aucune entité n'est créée ici.
]]

Package.Require("Core/Namespace.lua")
Package.Require("Core/Utils.lua")
Package.Require("Core/Logger.lua")
Package.Require("Core/EventBus.lua")
Package.Require("Core/ModuleManager.lua")
Package.Require("Core/Validator.lua")
Package.Require("Core/NetEvents.lua")

Package.Require("Config/Core.lua")
