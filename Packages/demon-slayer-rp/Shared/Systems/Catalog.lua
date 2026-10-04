--[[
    Demon Slayer RP - Catalogue des factions, souffles et arts (partagé)
    ------------------------------------------------------------------
    Lit Config.Factions / Config.BreathingStyles / Config.DemonArts, applique
    les valeurs par défaut et vérifie la configuration au chargement.
    Serveur et client construisent le même catalogue : le réseau n'a besoin
    d'échanger que des identifiants ("eau", 3) et jamais les données.

        DS.Catalog.GetSet("breathing", "eau")          -> souffle
        DS.Catalog.GetTechnique("art", "glace", 2)     -> technique
        DS.Catalog.FindFaction("pourfendeur")          -> "slayers"
        DS.Catalog.FindSet("breathing", "flam")        -> "flamme"
]]

local Catalog = {}
DS.Catalog = Catalog

local KINDS = {
    breathing = { config = "BreathingStyles", label = "Souffle" },
    art = { config = "DemonArts", label = "Art demoniaque" },
}
local SHAPES = { cone = true, circle = true, line = true, dash = true, self = true }
local SLOTS = 6

local sets = { breathing = {}, art = {} }
local setOrder = { breathing = {}, art = {} }

local function configError(where, message)
    error("Configuration invalide (" .. where .. ") : " .. message, 0)
end

local function buildTechnique(kind, setId, set, index, raw)
    local where = kind .. "." .. setId .. ".Techniques[" .. index .. "]"
    local tech = {}
    for k, v in pairs(Config.Abilities.TechniqueDefaults) do tech[k] = v end
    -- Valeurs communes définies au niveau du souffle / de l'art
    tech.BlockRegenMs = set.BlockRegenMs
    tech.BonusVsDemons = set.BonusVsDemons
    for k, v in pairs(raw) do tech[k] = v end

    if type(tech.Name) ~= "string" or tech.Name == "" then configError(where, "Name manquant") end
    if not SHAPES[tech.Shape] then configError(where, "Shape inconnue '" .. tostring(tech.Shape) .. "'") end
    for _, field in ipairs({ "Range", "Damage", "Cost", "CooldownMs" }) do
        if type(tech[field]) ~= "number" or tech[field] < 0 then
            configError(where, field .. " doit etre un nombre >= 0")
        end
    end

    if tech.Script ~= nil and type(tech.Script) ~= "string" then configError(where, "Script doit etre un texte") end
    if tech.Requirements ~= nil and type(tech.Requirements) ~= "table" then configError(where, "Requirements doit etre une table") end

    tech.Kind = kind
    tech.SetId = setId
    tech.Slot = index
    tech.Id = kind .. ":" .. setId .. ":" .. index
    tech.IsSpecial = (index >= 5)
    tech.RequiredLevel = tech.Requirements and tech.Requirements.Level or 0
    tech.Description = tech.Description or ""
    return tech
end

local function buildCatalog()
    for kind, info in pairs(KINDS) do
        local source = Config[info.config] or {}
        for _, setId in ipairs(DS.Utils.SortedKeys(source)) do
            local raw = source[setId]
            local where = kind .. "." .. setId
            if type(setId) ~= "string" or not setId:match("^[%w_]+$") then configError(where, "identifiant invalide") end
            if type(raw.Techniques) ~= "table" or #raw.Techniques == 0 then configError(where, "aucune technique") end
            if #raw.Techniques > SLOTS then configError(where, "maximum " .. SLOTS .. " techniques") end

            local set = {
                Id = setId,
                Kind = kind,
                Name = raw.Name or setId,
                Description = raw.Description or "",
                Color = raw.Color,
                Passive = raw.Passive,
                BlockRegenMs = raw.BlockRegenMs,
                BonusVsDemons = raw.BonusVsDemons,
                BladeTrail = raw.BladeTrail,
                Techniques = {},
            }
            for index, techRaw in ipairs(raw.Techniques) do
                set.Techniques[index] = buildTechnique(kind, setId, set, index, techRaw)
            end
            sets[kind][setId] = set
            setOrder[kind][#setOrder[kind] + 1] = setId
        end
    end

    for factionId, faction in pairs(Config.Factions) do
        if not Config.Resources[faction.Resource] then
            configError("faction." .. factionId, "ressource inconnue '" .. tostring(faction.Resource) .. "'")
        end
        if not KINDS[faction.AbilityKind] then
            configError("faction." .. factionId, "AbilityKind inconnu '" .. tostring(faction.AbilityKind) .. "'")
        end
    end
end

buildCatalog()

-- ---------------------------------------------------------------------------
-- API
-- ---------------------------------------------------------------------------

Catalog.Slots = SLOTS

function Catalog.KindLabel(kind)
    return KINDS[kind] and KINDS[kind].label or tostring(kind)
end

function Catalog.GetSet(kind, setId)
    return sets[kind] and sets[kind][setId]
end

function Catalog.GetTechnique(kind, setId, slot)
    local set = Catalog.GetSet(kind, setId)
    return set and set.Techniques[slot]
end

--- Identifiants des souffles / arts, triés.
function Catalog.ListSets(kind)
    return setOrder[kind] or {}
end

--- Retrouve un souffle / art par identifiant exact ou début de nom/identifiant.
function Catalog.FindSet(kind, query)
    query = tostring(query or ""):lower()
    if query == "" or not sets[kind] then return nil end
    if sets[kind][query] then return query end
    for _, id in ipairs(setOrder[kind]) do
        local name = sets[kind][id].Name:lower()
        if id:sub(1, #query) == query or name:find(query, 1, true) then return id end
    end
    return nil
end

function Catalog.GetFaction(factionId)
    return Config.Factions[factionId]
end

--- Retrouve une faction par identifiant ou alias.
function Catalog.FindFaction(query)
    query = tostring(query or ""):lower()
    if Config.Factions[query] then return query end
    for id, faction in pairs(Config.Factions) do
        for _, alias in ipairs(faction.Aliases or {}) do
            if alias == query then return id end
        end
    end
    return nil
end

return Catalog
