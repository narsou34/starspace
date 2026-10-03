--[[
    Demon Slayer RP - Utils
    ------------------------------------------------------------------
    Fonctions utilitaires pures, sans état, utilisables des deux côtés.
]]

local Utils = {}
DS.Utils = Utils

local traceback = (debug and debug.traceback) or function(err) return tostring(err) end

-- ---------------------------------------------------------------------------
-- Temps
-- ---------------------------------------------------------------------------

--- Heure actuelle en millisecondes (timestamp Unix, fourni par le moteur).
function Utils.NowMs()
    if DS.Side == "Server" then
        return Server.GetTime()
    elseif DS.Side == "Client" then
        return Client.GetTime()
    end
    return math.floor(os.clock() * 1000)
end

--- Formate une durée en millisecondes : "1h02m03s", "4m05s", "12s".
function Utils.FormatDuration(ms)
    local total = math.max(0, math.floor((tonumber(ms) or 0) / 1000))
    local h = total // 3600
    local m = (total % 3600) // 60
    local s = total % 60
    if h > 0 then
        return string.format("%dh%02dm%02ds", h, m, s)
    elseif m > 0 then
        return string.format("%dm%02ds", m, s)
    end
    return string.format("%ds", s)
end

-- ---------------------------------------------------------------------------
-- Exécution protégée
-- ---------------------------------------------------------------------------

--- Appelle `fn(...)` en mode protégé. Retourne `true, résultats...` ou `false, erreur+traceback`.
function Utils.Try(fn, ...)
    return xpcall(fn, traceback, ...)
end

-- ---------------------------------------------------------------------------
-- Nombres
-- ---------------------------------------------------------------------------

--- Vrai si `v` est un nombre fini (ni NaN, ni infini).
function Utils.IsFiniteNumber(v)
    return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

function Utils.Clamp(v, min, max)
    if v < min then return min end
    if v > max then return max end
    return v
end

function Utils.Round(v, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(v * mult + 0.5) / mult
end

-- ---------------------------------------------------------------------------
-- Limiteur de débit (token bucket)
-- ---------------------------------------------------------------------------

--- Consomme un jeton dans `buckets[key]`.
--- `rate` = { max = jetons max (rafale), windowMs = durée pour regagner `max` jetons }.
--- Retourne true si l'action est autorisée.
function Utils.ConsumeToken(buckets, key, rate, now)
    local bucket = buckets[key]
    if not bucket then
        bucket = { tokens = rate.max, last = now }
        buckets[key] = bucket
    else
        local refill = (now - bucket.last) * (rate.max / rate.windowMs)
        if refill > 0 then
            bucket.tokens = math.min(rate.max, bucket.tokens + refill)
            bucket.last = now
        end
    end
    if bucket.tokens < 1 then
        return false
    end
    bucket.tokens = bucket.tokens - 1
    return true
end

-- ---------------------------------------------------------------------------
-- Chaînes
-- ---------------------------------------------------------------------------

function Utils.Trim(s)
    return (s:match("^%s*(.-)%s*$"))
end

function Utils.StartsWith(s, prefix)
    return s:sub(1, #prefix) == prefix
end

--- Retire les balises de style du chat nanos world (<cyan>, </>, ...) qu'un joueur pourrait injecter.
function Utils.SanitizeChat(s)
    return (tostring(s):gsub("[<>]", ""))
end

--- Supprime les balises de style (<cyan>texte</>) pour un affichage console.
function Utils.StripChatTags(s)
    return (tostring(s):gsub("</>", ""):gsub("<%a+>", ""))
end

--- Découpe une ligne de commande en arguments en respectant les "guillemets".
--- ex : 'ds_setgroup "Tanjiro K" admin' -> { "ds_setgroup", "Tanjiro K", "admin" }
function Utils.ParseArgs(input)
    local args = {}
    local i, n = 1, #input
    while i <= n do
        local c = input:sub(i, i)
        if c:match("%s") then
            i = i + 1
        elseif c == '"' then
            local close = input:find('"', i + 1, true)
            if not close then
                args[#args + 1] = input:sub(i + 1)
                break
            end
            args[#args + 1] = input:sub(i + 1, close - 1)
            i = close + 1
        else
            local stop = input:find("%s", i) or (n + 1)
            args[#args + 1] = input:sub(i, stop - 1)
            i = stop
        end
    end
    return args
end

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

function Utils.Count(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

function Utils.Contains(list, value)
    for i = 1, #list do
        if list[i] == value then return true end
    end
    return false
end

--- Clés d'une table, triées (utile pour des affichages stables).
function Utils.SortedKeys(t)
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    return keys
end

--- Copie profonde (gère les références cycliques).
function Utils.DeepCopy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local copy = {}
    seen[value] = copy
    for k, v in pairs(value) do
        copy[Utils.DeepCopy(k, seen)] = Utils.DeepCopy(v, seen)
    end
    return setmetatable(copy, getmetatable(value))
end

--- Fusion profonde : retourne une nouvelle table = `base` surchargée par `override`.
function Utils.Merge(base, override)
    local result = Utils.DeepCopy(base)
    for k, v in pairs(override or {}) do
        if type(v) == "table" and type(result[k]) == "table" then
            result[k] = Utils.Merge(result[k], v)
        else
            result[k] = Utils.DeepCopy(v)
        end
    end
    return result
end

return Utils
