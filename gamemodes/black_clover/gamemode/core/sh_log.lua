--[[
    Black Clover RP — core/sh_log.lua
    Realm : PARTAGÉ

    Système de logs.
    - Console colorée (serveur et client).
    - Côté serveur : écriture dans garrysmod/data/blackclover/logs/AAAA-MM-JJ.txt
      (configurable dans core/sv_config.lua).

    Utilisation :
        BlackClover.Log.Info("Mana", "Mana restauré pour %s", ply:Nick())
        BlackClover.Log.Warn("Network", "Message invalide de %s", ply:SteamID())
        BlackClover.Log.Error("Database", "Requête échouée : %s", err)
        BlackClover.Log.Debug("Spells", "Cooldown de %s : %.2f", spellID, cd)  -- si Config.Debug
        BlackClover.Log.Admin("Commands", "%s a donné un grimoire à %s", a, b)   -- toujours écrit

    ⚠ Le premier argument après la catégorie est un format string.format :
      ne passez JAMAIS une donnée joueur directement comme format,
      utilisez "%s" et passez-la en paramètre.
]]

BlackClover.Log = BlackClover.Log or {}
local Log = BlackClover.Log

Log.Levels = {
    DEBUG = { Name = "DEBUG", Color = Color(150, 150, 150) },
    INFO  = { Name = "INFO",  Color = Color(120, 200, 120) },
    WARN  = { Name = "WARN",  Color = Color(255, 190, 60)  },
    ERROR = { Name = "ERROR", Color = Color(255, 80, 80)   },
    ADMIN = { Name = "ADMIN", Color = Color(200, 120, 255) },
}

local COLOR_PREFIX   = Color(40, 180, 90)   -- vert trèfle
local COLOR_CATEGORY = Color(200, 200, 200)
local COLOR_TEXT     = Color(235, 235, 235)

-- Création du dossier de logs (serveur)
if SERVER then
    local logging = BlackClover.Config.Logging
    if logging and logging.WriteToFile then
        file.CreateDir(logging.Directory)
    end
end

--- Formate le message en toute sécurité (un format invalide ne casse rien).
local function FormatMessage(message, ...)
    message = tostring(message)
    if select("#", ...) == 0 then return message end

    local ok, result = pcall(string.format, message, ...)
    return ok and result or (message .. " [format invalide]")
end

--- Écrit une ligne dans le fichier de log du jour (serveur uniquement).
local function WriteToFile(line)
    local logging = BlackClover.Config.Logging
    if not (logging and logging.WriteToFile) then return end

    file.Append(logging.Directory .. "/" .. os.date("%Y-%m-%d") .. ".txt", line .. "\n")
end

--- Fonction centrale d'écriture.
-- @param level table Entrée de Log.Levels
-- @param category string Catégorie (Loader, Mana, Database…)
-- @param message string Format string.format
function Log.Write(level, category, message, ...)
    if level == Log.Levels.DEBUG and not BlackClover.Config.Debug then return end

    local text = FormatMessage(message, ...)
    category = tostring(category or "General")

    MsgC(
        COLOR_PREFIX, "[Black Clover] ",
        level.Color, "[" .. level.Name .. "] ",
        COLOR_CATEGORY, "[" .. category .. "] ",
        COLOR_TEXT, text, "\n"
    )

    -- Les DEBUG ne sont pas écrits dans les fichiers (trop verbeux)
    if SERVER and level ~= Log.Levels.DEBUG then
        WriteToFile(string.format("[%s] [%s] [%s] %s", os.date("%H:%M:%S"), level.Name, category, text))
    end
end

function Log.Debug(category, message, ...) Log.Write(Log.Levels.DEBUG, category, message, ...) end
function Log.Info(category, message, ...)  Log.Write(Log.Levels.INFO,  category, message, ...) end
function Log.Warn(category, message, ...)  Log.Write(Log.Levels.WARN,  category, message, ...) end
function Log.Error(category, message, ...) Log.Write(Log.Levels.ERROR, category, message, ...) end
function Log.Admin(category, message, ...) Log.Write(Log.Levels.ADMIN, category, message, ...) end

--- Représentation lisible d'un joueur pour les logs : "Pseudo (STEAM_0:1:123)"
function Log.FormatPlayer(ply)
    if not IsValid(ply) then return "Console" end
    return string.format("%s (%s)", ply:Nick(), ply:SteamID())
end
