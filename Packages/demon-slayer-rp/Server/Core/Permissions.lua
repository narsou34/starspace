--[[
    Demon Slayer RP - Permissions (serveur)
    ------------------------------------------------------------------
    Groupes staff définis dans Server/Config/Permissions.lua.
    La configuration est compilée au démarrage (héritage résolu, cycles et
    groupes inconnus détectés) : une erreur de config est signalée
    immédiatement au lieu de provoquer un bug plus tard.

        DS.Permissions.Has(session, "admin.players")
        session:HasPermission("admin.players")
        DS.Permissions.SetGroup(session, "admin", "console")
]]

local Permissions = DS.Module("Permissions")
DS.Permissions = Permissions

local Log = Permissions.Log

local groups = {} -- [name] = { name, label, weight, inherits, set = { [perm] = true } }

local function compile(config)
    local raw = config.Groups or {}
    local resolved = {}

    local function resolve(name, chain)
        if resolved[name] then return resolved[name] end
        local def = raw[name]
        if not def then
            error(("groupe inconnu '%s'"):format(tostring(name)), 0)
        end
        if chain[name] then
            error(("heritage circulaire sur le groupe '%s'"):format(name), 0)
        end
        chain[name] = true

        local set = {}
        if def.Inherits then
            local parent = resolve(def.Inherits, chain)
            for perm in pairs(parent.set) do set[perm] = true end
        end
        for _, perm in ipairs(def.Permissions or {}) do
            set[perm] = true
        end
        chain[name] = nil

        local group = {
            name = name,
            label = def.Label or name,
            weight = def.Weight or 0,
            inherits = def.Inherits,
            set = set,
        }
        resolved[name] = group
        return group
    end

    for name in pairs(raw) do
        resolve(name, {})
    end

    if not resolved[config.DefaultGroup] then
        error(("DefaultGroup '%s' n'existe pas"):format(tostring(config.DefaultGroup)), 0)
    end
    return resolved
end

function Permissions:Init()
    groups = compile(Config.Permissions)

    local staffCount = 0
    for accountId, groupName in pairs(Config.Permissions.Staff or {}) do
        if groups[groupName] then
            staffCount = staffCount + 1
        else
            Log:Warn("Staff '%s' : groupe '%s' inconnu, entree ignoree", accountId, tostring(groupName))
        end
    end
    Log:Info("%s groupes charges, %s membre(s) du staff configure(s)", DS.Utils.Count(groups), staffCount)
end

-- "admin.players.kick" est accordé par : "*", "admin.players.kick", "admin.players.*", "admin.*"
local function groupHas(group, perm)
    local set = group.set
    if set["*"] or set[perm] then return true end
    local prefix = perm
    while true do
        prefix = prefix:match("^(.*)%.[^%.]+$")
        if not prefix then return false end
        if set[prefix .. ".*"] then return true end
    end
end

function Permissions.Has(session, perm)
    if not session then return false end
    local group = groups[session.group]
    return group ~= nil and groupHas(group, perm)
end

function Permissions.GroupExists(name)
    return groups[name] ~= nil
end

function Permissions.GetGroup(name)
    return groups[name]
end

function Permissions.GetWeight(session)
    local group = session and groups[session.group]
    return group and group.weight or 0
end

--- Liste des groupes triés par poids croissant.
function Permissions.GetGroups()
    local list = {}
    for _, group in pairs(groups) do list[#list + 1] = group end
    table.sort(list, function(a, b) return a.weight < b.weight end)
    return list
end

--- Groupe initial d'un compte (liste Staff de la config, sinon DefaultGroup).
function Permissions.ResolveInitialGroup(accountId)
    local groupName = (Config.Permissions.Staff or {})[accountId]
    if groupName and groups[groupName] then
        return groupName
    end
    return Config.Permissions.DefaultGroup
end

--- Change le groupe d'une session (non persistant avant la Phase 5).
--- `by` : description de l'auteur pour les logs.
function Permissions.SetGroup(session, groupName, by)
    if not groups[groupName] then
        return false, "groupe inconnu"
    end
    local old = session.group
    if old == groupName then
        return false, "le joueur est deja dans ce groupe"
    end
    session.group = groupName
    Log:Info("Groupe de %s (#%s) : %s -> %s (par %s)", session.name, session.id, old, groupName, tostring(by))
    DS.Bus.Emit("Permissions:GroupChanged", session, old, groupName, by)
    return true
end

return Permissions
