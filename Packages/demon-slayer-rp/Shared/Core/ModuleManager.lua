--[[
    Demon Slayer RP - ModuleManager
    ------------------------------------------------------------------
    Système de chargement des modules (identique serveur / client).

    Déclarer un module :

        local MonSysteme = DS.Module("MonSysteme", { dependencies = { "PlayerManager" } })

        function MonSysteme:Init()      -- enregistrement des handlers, lecture de la config
        end
        function MonSysteme:Start()     -- appelé quand tout le package est chargé
        end
        function MonSysteme:Shutdown()  -- arrêt / rechargement du package
        end

        return MonSysteme

    Cycle de vie :  registered -> initialized -> started -> stopped
                    (ou failed / skipped en cas d'erreur)

    - L'ordre d'exécution est calculé à partir des dépendances (tri topologique).
    - Un module en erreur n'arrête pas le serveur : seuls les modules qui
      dépendent de lui sont ignorés (skipped), avec un log explicite.
]]

local Modules = {}
DS.Modules = Modules

local Log = DS.Logger.Scope("Modules")

local registry = {}  -- [name] = module
local declared = {}  -- noms dans l'ordre de déclaration
local order = {}     -- noms dans l'ordre résolu
local booted = false

--- Déclare un module et retourne sa table.
function DS.Module(name, opts)
    assert(type(name) == "string" and name ~= "", "DS.Module : nom de module invalide")
    if registry[name] then
        error(("DS.Module : le module '%s' est deja declare"):format(name), 2)
    end
    if booted then
        Log:Warn("Module '%s' declare apres le demarrage : il ne sera pas initialise", name)
    end
    opts = opts or {}

    local module = {
        Name = name,
        Dependencies = opts.dependencies or {},
        Log = DS.Logger.Scope(name),
        _state = "registered",
        _initMs = 0,
        _startMs = 0,
        _error = nil,
    }
    registry[name] = module
    declared[#declared + 1] = name
    return module
end

-- Tri topologique : chaque module apparaît après ses dépendances.
local function resolveOrder()
    local result, visiting, visited = {}, {}, {}

    local function visit(name, chain)
        if visited[name] then return true end
        if visiting[name] then
            return false, "dependance circulaire : " .. table.concat(chain, " -> ") .. " -> " .. name
        end
        visiting[name] = true
        chain[#chain + 1] = name
        for _, dep in ipairs(registry[name].Dependencies) do
            if registry[dep] then
                local ok, err = visit(dep, chain)
                if not ok then return false, err end
            end
        end
        chain[#chain] = nil
        visiting[name] = nil
        visited[name] = true
        result[#result + 1] = name
        return true
    end

    for _, name in ipairs(declared) do
        local ok, err = visit(name, {})
        if not ok then return nil, err end
    end
    return result
end

-- Retourne le nom de la première dépendance qui empêche ce module de passer à `requiredState`.
local function blockingDependency(module, requiredState)
    for _, dep in ipairs(module.Dependencies) do
        local depModule = registry[dep]
        if not depModule then
            return dep .. " (introuvable)"
        end
        if depModule._state ~= requiredState then
            return dep .. " (" .. depModule._state .. ")"
        end
    end
    return nil
end

local function runPhase(module, method)
    local fn = module[method]
    if type(fn) ~= "function" then return true, 0 end
    local started = DS.Utils.NowMs()
    local ok, err = DS.Utils.Try(fn, module)
    return ok, DS.Utils.NowMs() - started, err
end

--- Initialise tous les modules déclarés. Retourne (nombre OK, total).
function Modules.InitAll()
    local resolved, err = resolveOrder()
    if not resolved then
        Log:Error("Impossible de determiner l'ordre des modules : %s", err)
        booted = true
        return 0, #declared
    end
    order = resolved
    booted = true

    local okCount = 0
    for _, name in ipairs(order) do
        local module = registry[name]
        local blocker = blockingDependency(module, "initialized")
        if blocker then
            module._state = "skipped"
            module._error = "dependance indisponible : " .. blocker
            Log:Error("Module '%s' ignore - %s", name, module._error)
        else
            local ok, elapsed, initErr = runPhase(module, "Init")
            module._initMs = elapsed
            if ok then
                module._state = "initialized"
                okCount = okCount + 1
                Log:Debug("Module '%s' initialise (%s ms)", name, elapsed)
            else
                module._state = "failed"
                module._error = tostring(initErr)
                Log:Error("Echec de l'initialisation du module '%s' : %s", name, module._error)
            end
        end
    end
    return okCount, #order
end

--- Démarre les modules initialisés. Retourne (nombre démarrés, total).
function Modules.StartAll()
    local okCount = 0
    for _, name in ipairs(order) do
        local module = registry[name]
        if module._state == "initialized" then
            local blocker = blockingDependency(module, "started")
            if blocker then
                module._state = "skipped"
                module._error = "dependance non demarree : " .. blocker
                Log:Error("Module '%s' non demarre - %s", name, module._error)
            else
                local ok, elapsed, startErr = runPhase(module, "Start")
                module._startMs = elapsed
                if ok then
                    module._state = "started"
                    okCount = okCount + 1
                    Log:Debug("Module '%s' demarre (%s ms)", name, elapsed)
                else
                    module._state = "failed"
                    module._error = tostring(startErr)
                    Log:Error("Echec du demarrage du module '%s' : %s", name, module._error)
                end
            end
        end
    end
    return okCount, #order
end

--- Arrête les modules dans l'ordre inverse du démarrage.
function Modules.ShutdownAll()
    for i = #order, 1, -1 do
        local module = registry[order[i]]
        if module._state == "started" or module._state == "initialized" then
            local ok, _, err = runPhase(module, "Shutdown")
            if not ok then
                Log:Error("Erreur a l'arret du module '%s' : %s", module.Name, tostring(err))
            end
            module._state = "stopped"
        end
    end
end

function Modules.Get(name)
    return registry[name]
end

function Modules.IsRunning(name)
    local module = registry[name]
    return module ~= nil and module._state == "started"
end

--- Liste des modules (ordre d'exécution) : { name, state, initMs, startMs, error }.
function Modules.List()
    local list = {}
    local source = (#order > 0) and order or declared
    for _, name in ipairs(source) do
        local module = registry[name]
        list[#list + 1] = {
            name = name,
            state = module._state,
            initMs = module._initMs,
            startMs = module._startMs,
            error = module._error,
        }
    end
    return list
end

return Modules
