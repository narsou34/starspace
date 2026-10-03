--[[
    Demon Slayer RP - Logger
    ------------------------------------------------------------------
    Logs centralisés, par niveau et par "scope" (nom du module).

    Format :  [DSRP][Server][Network] message
              [DSRP][Server][Network][WARN] message

    Usage :
        local Log = DS.Logger.Scope("MonModule")
        Log:Info("Joueur %s connecte", name)
        Log:Security("Tentative suspecte de %s", name)

    Extensible : DS.Logger.AddSink(fn) permet d'envoyer chaque entrée ailleurs
    (fichier, base de données, Discord...) sans toucher au reste du code.

    Note : les messages console sont volontairement en ASCII (sans accents)
    pour rester lisibles dans toutes les consoles serveur.
]]

local Logger = {}
DS.Logger = Logger

local LEVELS = {
    DEBUG    = 10,
    INFO     = 20,
    WARN     = 30,
    ERROR    = 40,
    SECURITY = 50, -- toujours affiché, quel que soit le niveau
}
Logger.Levels = LEVELS

local minLevel = LEVELS.INFO
local sinks = {}

-- Historique circulaire des dernières entrées (consultable par les futurs outils staff)
local history = {}
local historyMax = 200
local historyNext = 1

--- Applique la configuration (Config.Core) : niveau et taille d'historique.
function Logger.Configure(coreConfig)
    coreConfig = coreConfig or {}
    local level = coreConfig.Debug and "DEBUG" or (coreConfig.LogLevel or "INFO")
    Logger.SetLevel(level)
    if type(coreConfig.LogHistorySize) == "number" and coreConfig.LogHistorySize > 0 then
        historyMax = math.floor(coreConfig.LogHistorySize)
        history = {}
        historyNext = 1
    end
end

function Logger.SetLevel(name)
    local value = LEVELS[name]
    if value then
        minLevel = value
        return true
    end
    return false
end

function Logger.GetLevel()
    for name, value in pairs(LEVELS) do
        if value == minLevel then return name end
    end
    return "INFO"
end

function Logger.IsEnabled(level)
    return level == "SECURITY" or (LEVELS[level] or LEVELS.INFO) >= minLevel
end

--- Ajoute une sortie supplémentaire : fn(entry) avec entry = { time, level, side, scope, message }.
function Logger.AddSink(fn)
    assert(type(fn) == "function", "Logger.AddSink : fonction attendue")
    sinks[#sinks + 1] = fn
end

--- Retourne les `count` dernières entrées (de la plus ancienne à la plus récente).
function Logger.GetHistory(count)
    local result = {}
    local total = #history
    count = math.min(count or total, total)
    for i = count, 1, -1 do
        local index = ((historyNext - 1 - i) % historyMax) + 1
        if history[index] then result[#result + 1] = history[index] end
    end
    return result
end

local function formatMessage(fmt, ...)
    if select("#", ...) == 0 then
        return tostring(fmt)
    end
    local ok, message = pcall(string.format, tostring(fmt), ...)
    if ok then
        return message
    end
    -- Un format invalide ne doit jamais faire perdre un log
    local parts = { tostring(fmt) }
    for i = 1, select("#", ...) do
        parts[#parts + 1] = tostring((select(i, ...)))
    end
    return table.concat(parts, " | ")
end

function Logger.Write(level, scope, fmt, ...)
    if not Logger.IsEnabled(level) then return end

    local message = formatMessage(fmt, ...)
    local tag = (level == "INFO") and "" or ("[" .. level .. "]")
    local line = "[" .. DS.Short .. "][" .. DS.Side .. "][" .. tostring(scope) .. "]" .. tag .. " " .. message

    -- On passe toujours par "%s" : un '%' dans le message ne doit pas être interprété.
    -- Console.Warn/Error ajoutent une stack trace : réservés à WARN/ERROR, pour que
    -- les logs SECURITY (potentiellement nombreux pendant une attaque) restent lisibles.
    if level == "ERROR" then
        Console.Error("%s", line)
    elseif level == "WARN" then
        Console.Warn("%s", line)
    else
        Console.Log("%s", line)
    end

    local entry = {
        time = DS.Utils.NowMs(),
        level = level,
        side = DS.Side,
        scope = scope,
        message = message,
    }
    history[historyNext] = entry
    historyNext = (historyNext % historyMax) + 1

    for i = 1, #sinks do
        pcall(sinks[i], entry)
    end
end

-- ---------------------------------------------------------------------------
-- Loggers "scopés"
-- ---------------------------------------------------------------------------

local Scoped = {}
Scoped.__index = Scoped

function Scoped:Debug(fmt, ...)    Logger.Write("DEBUG", self.scope, fmt, ...) end
function Scoped:Info(fmt, ...)     Logger.Write("INFO", self.scope, fmt, ...) end
function Scoped:Warn(fmt, ...)     Logger.Write("WARN", self.scope, fmt, ...) end
function Scoped:Error(fmt, ...)    Logger.Write("ERROR", self.scope, fmt, ...) end
function Scoped:Security(fmt, ...) Logger.Write("SECURITY", self.scope, fmt, ...) end

function Logger.Scope(name)
    return setmetatable({ scope = name }, Scoped)
end

return Logger
