--[[
    Demon Slayer RP - Point d'entrée CLIENT
    ------------------------------------------------------------------
    Ordre d'exécution nanos world (sur chaque joueur) :
        1. Shared/Index.lua
        2. Client/Index.lua   (ce fichier : chargement des modules + Init)
        3. Package "Load"     (Start des modules)

    Seuls Client/ et Shared/ sont téléchargés par les joueurs.
]]

DS.SetSide("Client")
DS.Logger.Configure(Config.Core)

local Log = DS.Logger.Scope("Core")

local MODULE_FILES = {
    -- Core
    "Core/Network.lua",
    "Core/Session.lua",
    "Core/Diagnostics.lua",

    -- Systèmes de jeu
    "Systems/Abilities.lua",

    -- Effets visuels (VFX) : cœur, identités d'éléments, chorégraphies
    "Systems/VFX/Core/VFXUtils.lua",
    "Systems/VFX/Core/VFXManager.lua",
    "Systems/VFX/Core/VFXToon.lua",
    "Systems/VFX/Core/VFXSoundCamera.lua",
    "Systems/VFX/Core/VFXTrail.lua",
    "Systems/VFX/Core/VFXBurst.lua",
    "Systems/VFX/Core/VFXImpact.lua",
    "Systems/VFX/Core/VFXProjectile.lua",
    "Systems/VFX/Elements/Breathing.lua",
    "Systems/VFX/Elements/Others.lua",
    "Systems/VFX/Elements/Toon.lua",
    "Systems/VFX/Techniques/Signatures.lua",
    "Systems/VFX/Techniques/Looks.lua",
    "Systems/VFX/Techniques/Instant.lua",
    "Systems/VFX/Techniques/Water.lua",
    "Systems/VFX/Techniques/Generic.lua",

    -- Interfaces
    "UI/Hud.lua",
}

local filesFailed = 0
for _, file in ipairs(MODULE_FILES) do
    local ok, err = DS.Utils.Try(function() return Package.Require(file) end)
    if not ok then
        filesFailed = filesFailed + 1
        Log:Error("Impossible de charger '%s' : %s", file, err)
    end
end

DS.Modules.InitAll()

Package.Subscribe("Load", function()
    local startedOk, total = DS.Modules.StartAll()
    if startedOk < total or filesFailed > 0 then
        Log:Error("Client %s v%s charge avec des erreurs : %s/%s modules, %s fichier(s) en erreur",
            DS.Name, DS.Version, startedOk, total, filesFailed)
    else
        Log:Info("Client %s v%s charge (%s/%s modules)", DS.Name, DS.Version, startedOk, total)
    end
end)

Package.Subscribe("Unload", function()
    DS.Modules.ShutdownAll()
end)
