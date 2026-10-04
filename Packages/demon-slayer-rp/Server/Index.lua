--[[
    Demon Slayer RP - Point d'entrée SERVEUR
    ------------------------------------------------------------------
    Ordre d'exécution nanos world :
        1. Shared/Index.lua   (namespace, utilitaires, config partagée, contrat réseau)
        2. Server/Index.lua   (ce fichier : config serveur + chargement des modules + Init)
        3. Package "Load"     (Start des modules + bannière de démarrage)

    Pour ajouter un système : créer son fichier (DS.Module(...)) puis l'ajouter
    à MODULE_FILES. L'ordre réel d'exécution est calculé selon les dépendances.
]]

DS.SetSide("Server")

local Log = DS.Logger.Scope("Core")
local bootStartedAt = DS.Utils.NowMs()

-- ---------------------------------------------------------------------------
-- 1. Configuration serveur (jamais envoyée aux clients)
-- ---------------------------------------------------------------------------

Package.Require("Config/Server.lua")
Package.Require("Config/Permissions.lua")
Package.Require("Config/Security.lua")

-- Surcharges sans modifier le code : [custom_settings] du Config.toml ou --custom_settings
local function applyCustomSettings()
    local ok, settings = pcall(Server.GetCustomSettings)
    if not ok or type(settings) ~= "table" then return end
    local debugMode = settings.debug_mode
    if debugMode ~= nil then
        Config.Core.Debug = (debugMode == true or debugMode == "true" or debugMode == 1)
    end
end

applyCustomSettings()
DS.Logger.Configure(Config.Core)

-- ---------------------------------------------------------------------------
-- 2. Modules
-- ---------------------------------------------------------------------------

local MODULE_FILES = {
    -- Core
    "Core/Security.lua",
    "Core/Network.lua",
    "Core/Permissions.lua",
    "Core/PlayerManager.lua",
    "Core/Spawn.lua",
    "Core/Commands.lua",
    "Core/BaseCommands.lua",

    -- Systèmes de jeu
    "Systems/Factions.lua",
    "Systems/Resources.lua",
    "Systems/Abilities.lua",
    "Systems/Techniques/Hitboxes.lua",
    "Systems/Techniques/Status.lua",
    "Systems/Techniques/Engine.lua",
    "Systems/Techniques/Water.lua",
    "Systems/AbilityCommands.lua",
}

local filesFailed = 0
for _, file in ipairs(MODULE_FILES) do
    -- Closure : Package.Require résout le chemin relativement au fichier appelant
    local ok, err = DS.Utils.Try(function() return Package.Require(file) end)
    if not ok then
        filesFailed = filesFailed + 1
        Log:Error("Impossible de charger '%s' : %s", file, err)
    end
end

local initOk, moduleCount = DS.Modules.InitAll()

-- ---------------------------------------------------------------------------
-- 3. Démarrage / arrêt
-- ---------------------------------------------------------------------------

local function printBanner(startedOk, total, bootMs)
    local lines = {
        "==============================================================",
        string.format("  %s v%s - par %s", DS.Name, DS.Version, DS.Author),
        string.format("  nanos world %s | carte : %s | package : %s", Server.GetVersion(), Server.GetMap(), DS.Package),
        string.format("  Modules : %s/%s demarres | fichiers en erreur : %s | demarrage : %s ms",
            startedOk, total, filesFailed, bootMs),
        string.format("  Mode debug : %s | niveau de log : %s",
            Config.Core.Debug and "ACTIF" or "inactif", DS.Logger.GetLevel()),
        "==============================================================",
    }
    for _, line in ipairs(lines) do
        Log:Info("%s", line)
    end

    if startedOk < total or filesFailed > 0 then
        Log:Error("Demarrage INCOMPLET : consultez les erreurs ci-dessus")
    else
        Log:Info("Gamemode pret.")
    end
end

Package.Subscribe("Load", function()
    local startedOk, total = DS.Modules.StartAll()
    DS.StartedAt = DS.Utils.NowMs()
    printBanner(startedOk, total, DS.StartedAt - bootStartedAt)
    DS.Bus.Emit("Server:Started")
end)

Package.Subscribe("Unload", function()
    Log:Info("Arret du gamemode...")
    DS.Bus.Emit("Server:Stopping")
    DS.Modules.ShutdownAll()
    Log:Info("Gamemode arrete.")
end)

Log:Debug("Initialisation : %s/%s modules", initOk, moduleCount)
