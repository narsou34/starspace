--[[
    Demon Slayer RP - EventBus
    ------------------------------------------------------------------
    Bus d'évènements INTERNE (même côté, même package) permettant aux modules
    de communiquer sans dépendre directement les uns des autres.

        DS.Bus.On("Player:Loaded", function(session) ... end)
        DS.Bus.On("Player:Loaded", handler, { priority = 10 })   -- appelé avant
        DS.Bus.Once("Server:Started", handler)
        DS.Bus.Emit("Player:Loaded", session)

    - Chaque listener est isolé (une erreur est loggée, les autres continuent).
    - Emit retourne false si au moins un listener a renvoyé false (veto),
      ce qui permet des évènements du type "Attempt..." annulables.

    Pour la communication réseau serveur <-> client, voir DS.Net.
]]

local Bus = {}
DS.Bus = Bus

local Log = DS.Logger.Scope("EventBus")

local listeners = {} -- [event] = tableau trié par priorité décroissante
local nextId = 0

--- Abonne `fn` à `event`. opts = { priority = number, once = boolean }.
--- Retourne un handle à passer à Bus.Off.
function Bus.On(event, fn, opts)
    assert(type(event) == "string", "Bus.On : nom d'evenement attendu")
    assert(type(fn) == "function", "Bus.On : fonction attendue")
    opts = opts or {}

    nextId = nextId + 1
    local entry = {
        id = nextId,
        fn = fn,
        priority = opts.priority or 0,
        once = opts.once == true,
    }

    -- Copie à l'écriture : un Emit en cours n'est jamais perturbé par un On/Off
    local current = listeners[event]
    local updated = {}
    local inserted = false
    if current then
        for i = 1, #current do
            if not inserted and entry.priority > current[i].priority then
                updated[#updated + 1] = entry
                inserted = true
            end
            updated[#updated + 1] = current[i]
        end
    end
    if not inserted then
        updated[#updated + 1] = entry
    end
    listeners[event] = updated

    return { event = event, id = entry.id }
end

function Bus.Once(event, fn, opts)
    opts = opts or {}
    opts.once = true
    return Bus.On(event, fn, opts)
end

function Bus.Off(handle)
    if type(handle) ~= "table" then return false end
    local current = listeners[handle.event]
    if not current then return false end

    local updated = {}
    local removed = false
    for i = 1, #current do
        if current[i].id == handle.id then
            removed = true
        else
            updated[#updated + 1] = current[i]
        end
    end
    listeners[handle.event] = (#updated > 0) and updated or nil
    return removed
end

--- Déclenche `event`. Retourne false si un listener a opposé un veto (return false).
function Bus.Emit(event, ...)
    local current = listeners[event]
    if not current then return true end

    local allowed = true
    for i = 1, #current do
        local entry = current[i]
        if entry.once then
            Bus.Off({ event = event, id = entry.id })
        end
        local ok, result = DS.Utils.Try(entry.fn, ...)
        if not ok then
            Log:Error("Listener de '%s' en erreur : %s", event, result)
        elseif result == false then
            allowed = false
        end
    end
    return allowed
end

function Bus.Count(event)
    local current = listeners[event]
    return current and #current or 0
end

return Bus
