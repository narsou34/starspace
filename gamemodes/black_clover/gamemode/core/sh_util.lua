--[[
    Black Clover RP — core/sh_util.lua
    Realm : PARTAGÉ

    Fonctions utilitaires génériques, utilisées par tous les systèmes.
    Accès : BlackClover.Util.NomDeLaFonction(...)

    Les fonctions ToNumber / ToInteger / SanitizeString sont la base de la
    validation serveur : toute donnée venant d'un client doit passer par elles.
]]

BlackClover.Util = BlackClover.Util or {}
local Util = BlackClover.Util

-- ─── Validation ─────────────────────────────────────────────────────────

--- Vérifie qu'une valeur est un joueur valide.
function Util.IsValidPlayer(ply)
    return IsValid(ply) and ply:IsPlayer()
end

--- Convertit une valeur en nombre FINI, avec bornes optionnelles.
-- Rejette nil, NaN, +inf, -inf et les chaînes non numériques.
-- @param value any Valeur à convertir
-- @param default number Valeur renvoyée si la conversion échoue
-- @param min number|nil Borne minimale
-- @param max number|nil Borne maximale
-- @return number
function Util.ToNumber(value, default, min, max)
    local n = tonumber(value)

    -- n ~= n détecte NaN
    if n == nil or n ~= n or n == math.huge or n == -math.huge then
        return default
    end

    if min and n < min then n = min end
    if max and n > max then n = max end

    return n
end

--- Comme ToNumber, mais arrondit à l'entier inférieur.
function Util.ToInteger(value, default, min, max)
    local n = Util.ToNumber(value, nil)
    if n == nil then return default end

    n = math.floor(n)
    if min and n < min then n = min end
    if max and n > max then n = max end

    return n
end

--- Nettoie une chaîne de caractères venant d'un joueur.
-- - force un UTF-8 valide ;
-- - supprime les caractères de contrôle ;
-- - supprime les espaces en trop ;
-- - limite la longueur (en caractères, pas en octets).
-- @param str any Chaîne à nettoyer (toute autre valeur renvoie "")
-- @param maxLength number|nil Nombre maximum de caractères
-- @param allowNewLines boolean|nil Autoriser les retours à la ligne
-- @return string
function Util.SanitizeString(str, maxLength, allowNewLines)
    if not isstring(str) then return "" end

    str = utf8.force(str)

    if allowNewLines then
        str = string.gsub(str, "\r\n", "\n")
        str = string.gsub(str, "\n\n\n+", "\n\n") -- 2 lignes vides max
    else
        str = string.gsub(str, "[\r\n\t]", " ")
    end

    -- Caractères de contrôle ASCII (hors \t et \n), et DEL
    str = string.gsub(str, "[%z\1-\8\11-\31\127]", "")
    str = string.gsub(str, "[ \t]+", " ")
    str = string.Trim(str)

    if maxLength and utf8.len(str) > maxLength then
        str = string.Trim(utf8.sub(str, 1, maxLength))
    end

    return str
end

--- Vérifie qu'une chaîne fait partie d'une liste de valeurs autorisées.
-- @param value any
-- @param allowed table Liste ({ "a", "b" }) ou ensemble ({ a = true })
function Util.IsOneOf(value, allowed)
    if allowed[value] == true then return true end

    for _, v in ipairs(allowed) do
        if v == value then return true end
    end

    return false
end

-- ─── Tables ─────────────────────────────────────────────────────────────

--- Transforme une liste en ensemble : { "a", "b" } → { a = true, b = true }
function Util.ToSet(list)
    local set = {}
    for _, v in ipairs(list) do set[v] = true end
    return set
end

--- Tire un élément au hasard selon un poids.
-- Exemple : Util.WeightedRandom(grimoires, "Chance")
-- Les éléments de poids <= 0 ne peuvent jamais être tirés.
-- @param entries table Liste d'éléments
-- @param weightKey string Nom du champ contenant le poids
-- @return any, number L'élément tiré et son index (nil si aucun)
function Util.WeightedRandom(entries, weightKey)
    local total = 0
    for _, entry in ipairs(entries) do
        total = total + math.max(Util.ToNumber(entry[weightKey], 0), 0)
    end

    if total <= 0 then return nil end

    local roll = math.Rand(0, total)
    local cumulative = 0

    for index, entry in ipairs(entries) do
        local weight = math.max(Util.ToNumber(entry[weightKey], 0), 0)
        if weight > 0 then
            cumulative = cumulative + weight
            if roll <= cumulative then
                return entry, index
            end
        end
    end

    -- Sécurité (erreurs d'arrondi) : dernier élément de poids > 0
    for index = #entries, 1, -1 do
        if Util.ToNumber(entries[index][weightKey], 0) > 0 then
            return entries[index], index
        end
    end
end

-- ─── Formatage ──────────────────────────────────────────────────────────

--- Formate un nombre avec séparateur de milliers : 1234567 → "1 234 567"
function Util.FormatNumber(n)
    n = Util.ToNumber(n, 0)

    local negative = n < 0
    local integer, decimals = string.match(string.format("%.2f", math.abs(n)), "^(%d+)%.(%d+)$")
    local formatted = string.reverse(string.gsub(string.reverse(integer), "(%d%d%d)", "%1 "))
    formatted = string.Trim(formatted)

    if decimals ~= "00" then
        formatted = formatted .. "," .. decimals
    end

    return (negative and "-" or "") .. formatted
end

--- Formate une durée : 3725 → "1h 02m 05s", 65 → "1m 05s", 9 → "9s"
function Util.FormatTime(seconds)
    seconds = math.max(Util.ToInteger(seconds, 0), 0)

    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60

    if h > 0 then return string.format("%dh %02dm %02ds", h, m, s) end
    if m > 0 then return string.format("%dm %02ds", m, s) end
    return string.format("%ds", s)
end

-- ─── Joueurs ────────────────────────────────────────────────────────────

--- Recherche un joueur par SteamID, SteamID64, UserID (#12) ou partie du pseudo.
-- @param query string
-- @return Player|nil, string|nil Le joueur trouvé, ou nil + message d'erreur
function Util.FindPlayer(query)
    query = Util.SanitizeString(query, 64)
    if query == "" then return nil, "Aucun joueur indiqué." end

    -- UserID : "#12"
    local userID = string.match(query, "^#(%d+)$")
    if userID then
        local ply = Player(tonumber(userID))
        if IsValid(ply) then return ply end
        return nil, "Aucun joueur avec l'ID " .. query .. "."
    end

    local lowerQuery = string.lower(query)
    local matches = {}

    for _, ply in ipairs(player.GetAll()) do
        -- Correspondance exacte : SteamID, SteamID64 ou pseudo
        if ply:SteamID() == query or ply:SteamID64() == query or string.lower(ply:Nick()) == lowerQuery then
            return ply
        end

        -- Correspondance partielle sur le pseudo (recherche littérale)
        if string.find(string.lower(ply:Nick()), lowerQuery, 1, true) then
            matches[#matches + 1] = ply
        end
    end

    if #matches == 1 then return matches[1] end
    if #matches > 1 then return nil, "Plusieurs joueurs correspondent à \"" .. query .. "\"." end

    return nil, "Aucun joueur trouvé pour \"" .. query .. "\"."
end
