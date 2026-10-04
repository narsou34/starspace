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
Package.Require("Config/Factions.lua")
Package.Require("Config/Abilities.lua")
Package.Require("Config/BreathingStyles.lua")
Package.Require("Config/Breathing/Water.lua")
Package.Require("Config/Breathing/Sound.lua")
Package.Require("Config/Breathing/Insect.lua")
Package.Require("Config/Breathing/Love.lua")
Package.Require("Config/Breathing/Wind.lua")
Package.Require("Config/Breathing/FlameThunderMist.lua")
Package.Require("Config/DemonArts.lua")
Package.Require("Config/DemonArts/Arts.lua")
Package.Require("Config/Vfx.lua")
Package.Require("Config/VfxPackCatalog.lua")

-- Systèmes partagés (catalogue construit et vérifié au chargement)
Package.Require("Systems/Catalog.lua")
Package.Require("Systems/AbilityNet.lua")
Package.Require("Systems/TechniqueMath.lua")
