--[[
    Demon Slayer RP - Validator
    ------------------------------------------------------------------
    Validation par schéma des données reçues par le réseau.
    Le serveur l'utilise pour TOUT ce qui vient d'un client.

    Types supportés et options :
      string  : minLength, maxLength, pattern (motif Lua), enum = { ... }
      number  : min, max, integer = true, enum = { ... }   (NaN / infini toujours refusés)
      boolean
      table   : fields = { nom = schéma, ... } (+ strict = false pour tolérer les clés inconnues)
                items = schéma, maxItems         (tableau 1..n homogène)
                sinon : table de données libre, bornée (profondeur, nombre d'entrées)
      entity  : entité nanos world valide, class = Character (optionnel)
    Options communes : optional = true, default = valeur

    Retour : ok, valeur_normalisée | ok = false, message d'erreur.
    Les tables retournées sont des COPIES nettoyées (jamais la table du client).
]]

local Validator = {}
DS.Validator = Validator

local Utils = DS.Utils

-- Limites par défaut (le serveur les remplace par Config.Security au démarrage)
Validator.Defaults = {
    MaxStringLength = 256,
    MaxTableEntries = 64,
    MaxTableDepth = 4,
}

local function fail(path, message)
    return false, path .. " : " .. message
end

local function inEnum(schema, value)
    if not schema._enumSet then
        local set = {}
        for _, v in ipairs(schema.enum) do set[v] = true end
        schema._enumSet = set
    end
    return schema._enumSet[value] == true
end

-- Table de données libre : seules des clés string/nombre et des valeurs simples sont acceptées.
local function checkPlainTable(value, path, depth, counter)
    local defaults = Validator.Defaults
    if depth > defaults.MaxTableDepth then
        return fail(path, "profondeur maximale depassee")
    end
    if getmetatable(value) ~= nil then
        return fail(path, "table de donnees attendue")
    end

    local copy = {}
    for k, v in pairs(value) do
        counter.n = counter.n + 1
        if counter.n > defaults.MaxTableEntries then
            return fail(path, "trop d'entrees (max " .. defaults.MaxTableEntries .. ")")
        end

        local kt = type(k)
        if kt == "string" then
            if #k > defaults.MaxStringLength then return fail(path, "cle trop longue") end
        elseif not (kt == "number" and Utils.IsFiniteNumber(k)) then
            return fail(path, "type de cle interdit : " .. kt)
        end

        local childPath = path .. "." .. tostring(k)
        local vt = type(v)
        if vt == "string" then
            if #v > defaults.MaxStringLength then return fail(childPath, "chaine trop longue") end
            copy[k] = v
        elseif vt == "number" then
            if not Utils.IsFiniteNumber(v) then return fail(childPath, "nombre invalide") end
            copy[k] = v
        elseif vt == "boolean" then
            copy[k] = v
        elseif vt == "table" then
            local ok, result = checkPlainTable(v, childPath, depth + 1, counter)
            if not ok then return false, result end
            copy[k] = result
        else
            return fail(childPath, "type de valeur interdit : " .. vt)
        end
    end
    return true, copy
end

local checkValue

local function checkTable(value, schema, path, depth)
    if depth > Validator.Defaults.MaxTableDepth then
        return fail(path, "profondeur maximale depassee")
    end
    if getmetatable(value) ~= nil then
        return fail(path, "table de donnees attendue")
    end

    -- Objet à champs connus
    if schema.fields then
        local maxEntries = schema.maxEntries or Validator.Defaults.MaxTableEntries
        local count = 0
        for k in pairs(value) do
            count = count + 1
            if count > maxEntries then return fail(path, "trop d'entrees") end
            if schema.strict ~= false and (type(k) ~= "string" or schema.fields[k] == nil) then
                return fail(path, "champ inattendu '" .. tostring(k) .. "'")
            end
        end
        local out = {}
        for name, fieldSchema in pairs(schema.fields) do
            local ok, result = checkValue(value[name], fieldSchema, path .. "." .. name, depth + 1)
            if not ok then return false, result end
            out[name] = result
        end
        return true, out
    end

    -- Tableau homogène 1..n
    if schema.items then
        local n = #value
        local maxItems = schema.maxItems or Validator.Defaults.MaxTableEntries
        if n > maxItems then return fail(path, "trop d'elements (max " .. maxItems .. ")") end
        local count = 0
        for k in pairs(value) do
            count = count + 1
            if math.type(k) ~= "integer" or k < 1 or k > n then
                return fail(path, "tableau attendu (indices 1.." .. n .. ")")
            end
        end
        if count ~= n then return fail(path, "tableau a trous") end
        local out = {}
        for i = 1, n do
            local ok, result = checkValue(value[i], schema.items, path .. "[" .. i .. "]", depth + 1)
            if not ok then return false, result end
            out[i] = result
        end
        return true, out
    end

    -- Table libre bornée
    return checkPlainTable(value, path, depth, { n = 0 })
end

checkValue = function(value, schema, path, depth)
    if value == nil then
        if schema.optional then return true, schema.default end
        return fail(path, "valeur manquante")
    end

    local expected = schema.type
    local actual = type(value)

    if expected == "string" then
        if actual ~= "string" then return fail(path, "chaine attendue (recu " .. actual .. ")") end
        local maxLength = schema.maxLength or Validator.Defaults.MaxStringLength
        if #value > maxLength then return fail(path, "chaine trop longue (" .. #value .. " > " .. maxLength .. ")") end
        if schema.minLength and #value < schema.minLength then return fail(path, "chaine trop courte") end
        if not utf8.len(value) then return fail(path, "UTF-8 invalide") end
        if schema.pattern and not value:match(schema.pattern) then return fail(path, "format invalide") end
        if schema.enum and not inEnum(schema, value) then return fail(path, "valeur non autorisee") end
        return true, value

    elseif expected == "number" then
        if actual ~= "number" then return fail(path, "nombre attendu (recu " .. actual .. ")") end
        if not Utils.IsFiniteNumber(value) then return fail(path, "nombre invalide (NaN/infini)") end
        if schema.integer then
            local int = math.tointeger(value)
            if not int then return fail(path, "entier attendu") end
            value = int
        end
        if schema.min and value < schema.min then return fail(path, "valeur trop petite (min " .. schema.min .. ")") end
        if schema.max and value > schema.max then return fail(path, "valeur trop grande (max " .. schema.max .. ")") end
        if schema.enum and not inEnum(schema, value) then return fail(path, "valeur non autorisee") end
        return true, value

    elseif expected == "boolean" then
        if actual ~= "boolean" then return fail(path, "booleen attendu (recu " .. actual .. ")") end
        return true, value

    elseif expected == "table" then
        if actual ~= "table" then return fail(path, "table attendue (recu " .. actual .. ")") end
        return checkTable(value, schema, path, depth)

    elseif expected == "entity" then
        if actual ~= "table" and actual ~= "userdata" then return fail(path, "entite attendue (recu " .. actual .. ")") end
        local okValid, isValid = pcall(function() return value:IsValid() end)
        if not okValid or not isValid then return fail(path, "entite invalide") end
        if schema.class then
            local okClass, isA = pcall(function() return value:IsA(schema.class) end)
            if not okClass or not isA then return fail(path, "type d'entite inattendu") end
        end
        return true, value
    end

    return fail(path, "type de schema inconnu '" .. tostring(expected) .. "'")
end

--- Valide une valeur selon un schéma.
function Validator.Check(value, schema, path)
    return checkValue(value, schema, path or "valeur", 1)
end

return Validator
