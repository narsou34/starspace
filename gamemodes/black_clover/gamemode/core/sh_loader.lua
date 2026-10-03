--[[
    Black Clover RP — core/sh_loader.lua
    Realm : PARTAGÉ

    Loader du gamemode. Il inclut les fichiers selon leur PRÉFIXE :

        sv_xxx.lua  → serveur uniquement (jamais envoyé au client)
        cl_xxx.lua  → client uniquement (AddCSLuaFile côté serveur)
        sh_xxx.lua  → partagé (AddCSLuaFile + include des deux côtés)

    Ordre de chargement :
        1. core/      (liste explicite, l'ordre compte)
        2. config/    (tous les fichiers du dossier)
        3. systems/   (dans l'ordre de BlackClover.Config.Systems)
        4. ui/        (récursif, fichiers cl_ uniquement en pratique)

    Dans un même dossier : sh_ → sv_ → cl_, puis ordre alphabétique.
    Un fichier sans préfixe reconnu est ignoré avec un avertissement.
]]

BlackClover.Loader = BlackClover.Loader or {}
local Loader = BlackClover.Loader

-- Chemin racine utilisé par include/AddCSLuaFile/file.Find ("LUA")
Loader.Root = BlackClover.FolderName .. "/gamemode/"

-- Ordre de chargement des fichiers du core
Loader.CoreFiles = {
    "core/sh_config.lua",       -- configuration partagée
    "core/sv_config.lua",       -- configuration serveur (secrets, BDD)
    "core/sh_util.lua",         -- fonctions utilitaires
    "core/sh_log.lua",          -- logs console + fichiers
    "core/sh_permissions.lua",  -- staff / permissions
    "core/sh_network.lua",      -- net sécurisé + anti-flood
    "core/sh_notify.lua",       -- notifications serveur → client
    "core/sv_database.lua",     -- abstraction base de données (Phase 3)
    "core/sv_player.lua",       -- cycle de vie du joueur côté serveur
    "core/cl_player.lua",       -- cycle de vie du joueur côté client
}

local REALM_ORDER = { shared = 1, server = 2, client = 3 }

--- Détermine le realm d'un fichier à partir de son préfixe.
-- @param path string Chemin ou nom de fichier
-- @return string|nil "shared", "server", "client" ou nil
function Loader.GetRealm(path)
    local prefix = string.lower(string.sub(string.GetFileFromFilename(path), 1, 3))

    if prefix == "sh_" then return "shared" end
    if prefix == "sv_" then return "server" end
    if prefix == "cl_" then return "client" end

    return nil
end

--- Inclut un fichier dans le bon realm.
-- @param relativePath string Chemin relatif à gamemode/ (ex: "core/sh_util.lua")
-- @param realm string|nil Realm forcé (sinon déduit du préfixe)
-- @return boolean true si le fichier a été traité
function Loader.IncludeFile(relativePath, realm)
    realm = realm or Loader.GetRealm(relativePath)
    local fullPath = Loader.Root .. relativePath

    if realm == "server" then
        if CLIENT then return false end
        include(fullPath)
    elseif realm == "client" then
        if SERVER then
            AddCSLuaFile(fullPath)
            return true -- envoyé au client, mais pas exécuté sur le serveur
        end
        include(fullPath)
    elseif realm == "shared" then
        if SERVER then AddCSLuaFile(fullPath) end
        include(fullPath)
    else
        MsgC(Color(255, 170, 0), "[Black Clover] [Loader] Préfixe inconnu, fichier ignoré : " .. relativePath .. "\n")
        return false
    end

    Loader.LoadedFiles[#Loader.LoadedFiles + 1] = relativePath
    return true
end

--- Inclut tous les fichiers .lua d'un dossier.
-- @param relativeDir string Dossier relatif à gamemode/ (ex: "systems/mana")
-- @param recursive boolean Inclure aussi les sous-dossiers
function Loader.IncludeDir(relativeDir, recursive)
    local files, folders = file.Find(Loader.Root .. relativeDir .. "/*", "LUA")
    files = files or {}
    folders = folders or {}

    -- Uniquement les .lua, triés par realm puis par nom
    local luaFiles = {}
    for _, fileName in ipairs(files) do
        if string.GetExtensionFromFilename(fileName) == "lua" then
            luaFiles[#luaFiles + 1] = fileName
        end
    end

    table.sort(luaFiles, function(a, b)
        local ra = REALM_ORDER[Loader.GetRealm(a)] or 99
        local rb = REALM_ORDER[Loader.GetRealm(b)] or 99
        if ra ~= rb then return ra < rb end
        return a < b
    end)

    for _, fileName in ipairs(luaFiles) do
        Loader.IncludeFile(relativeDir .. "/" .. fileName)
    end

    if recursive then
        table.sort(folders)
        for _, folder in ipairs(folders) do
            Loader.IncludeDir(relativeDir .. "/" .. folder, true)
        end
    end
end

--- Démarre le chargement complet du gamemode.
-- Appelé par shared.lua, des deux côtés, à chaque (re)chargement.
function Loader.Boot()
    local startTime = SysTime()
    Loader.LoadedFiles = {}
    Loader.LoadedSystems = {}

    -- 1. Core (ordre explicite)
    for _, path in ipairs(Loader.CoreFiles) do
        Loader.IncludeFile(path)
    end

    local Log = BlackClover.Log

    -- 2. Configuration de contenu (magies, sorts, factions, rangs…)
    Loader.IncludeDir("config", false)

    -- 3. Systèmes, dans l'ordre défini par la configuration
    for _, systemName in ipairs(BlackClover.Config.Systems or {}) do
        Loader.IncludeDir("systems/" .. systemName, true)
        Loader.LoadedSystems[#Loader.LoadedSystems + 1] = systemName
        Log.Debug("Loader", "Système chargé : %s", systemName)
    end

    -- 4. Interfaces (client)
    Loader.IncludeDir("ui", true)

    Log.Info("Loader", "%s v%s chargé (%d fichiers, %d systèmes) en %.3f s",
        BlackClover.Name, BlackClover.Version,
        #Loader.LoadedFiles, #Loader.LoadedSystems, SysTime() - startTime)

    hook.Run("BlackClover.Loaded")
end

-- Hook unique de fin d'initialisation : les systèmes peuvent s'y abonner
-- avec hook.Add("BlackClover.Initialized", ...) pour démarrer leur logique.
hook.Add("Initialize", "BlackClover.Initialize", function()
    hook.Run("BlackClover.Initialized")
end)

-- Commande d'information : "bc_info" dans la console (serveur ou client).
if SERVER then
    concommand.Add("bc_info", function(ply)
        local lines = {
            string.format("%s v%s — par %s", BlackClover.Name, BlackClover.Version, BlackClover.Author),
            string.format("Fichiers chargés (serveur) : %d", #Loader.LoadedFiles),
            "Systèmes : " .. table.concat(Loader.LoadedSystems, ", "),
        }

        for _, line in ipairs(lines) do
            if IsValid(ply) then
                ply:PrintMessage(HUD_PRINTCONSOLE, line)
            else
                print(line)
            end
        end
    end)
end
