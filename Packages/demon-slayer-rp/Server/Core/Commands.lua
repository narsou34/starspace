--[[
    Demon Slayer RP - Commandes (serveur)
    ------------------------------------------------------------------
    Registre unique pour les commandes chat (/ds_...) et console serveur.

        DS.Commands.Register({
            name = "ds_exemple",
            description = "Ce que fait la commande",
            usage = "[joueur] [valeur]",  -- pas de < > : réservés aux styles du chat
            permission = "admin.exemple",  -- nil = tout le monde
            minArgs = 1,
            chat = true,                   -- utilisable dans le chat (défaut true)
            console = true,                -- utilisable dans la console serveur (défaut true)
            handler = function(ctx, args)
                ctx.Reply("OK")            -- ctx.session = nil si console
            end,
        })

    Sécurité :
      - permission vérifiée côté serveur avant toute exécution
      - limite de débit par joueur (Config.Security.CommandRate)
      - longueur maximale de la ligne de commande
      - exécution protégée + journal d'audit de chaque commande chat
      - la console serveur a tous les droits (accès machine = propriétaire)
]]

local Commands = DS.Module("Commands", { dependencies = { "PlayerManager", "Permissions", "Security" } })
DS.Commands = Commands

local Log = Commands.Log
local Utils = DS.Utils

local registry = {}
local names = {}

-- ===========================================================================
-- Contextes d'exécution
-- ===========================================================================

local function chatContext(session)
    return {
        session = session,
        isConsole = false,
        Reply = function(message) session:Chat(message) end,
        Error = function(message) session:Chat("<red>Erreur :</> " .. tostring(message)) end,
    }
end

local consoleContext = {
    session = nil,
    isConsole = true,
    Reply = function(message) Log:Info("%s", Utils.StripChatTags(message)) end,
    Error = function(message) Log:Warn("%s", Utils.StripChatTags(message)) end,
}

-- ===========================================================================
-- Exécution
-- ===========================================================================

--- Vrai si le contexte peut utiliser la commande.
function Commands.CanUse(ctx, def)
    if ctx.isConsole then return def.console end
    if not def.chat then return false end
    return def.permission == nil or ctx.session:HasPermission(def.permission)
end

local function execute(def, ctx, args)
    if not Commands.CanUse(ctx, def) then
        if ctx.isConsole then
            ctx.Error("La commande " .. def.name .. " n'est pas disponible en console.")
        else
            ctx.Error("Vous n'avez pas la permission d'utiliser cette commande.")
            Log:Info("Refus : %s (#%s) a tente /%s", ctx.session.name, ctx.session.id, def.name)
        end
        return
    end

    if #args < def.minArgs then
        ctx.Error("Utilisation : /" .. def.name .. " " .. def.usage)
        return
    end

    local ok, err = Utils.Try(def.handler, ctx, args)
    if not ok then
        Log:Error("Commande '%s' en erreur : %s", def.name, err)
        ctx.Error("Erreur interne pendant l'execution de la commande.")
    end
end

local function onChatSubmit(message, player)
    if type(message) ~= "string" or message:sub(1, 1) ~= "/" then return end

    local args = Utils.ParseArgs(message:sub(2))
    local name = args[1] and args[1]:lower()
    if not name then return end

    local def = registry[name]
    if not def then
        -- Les commandes d'autres packages ne sont pas interceptées
        if name:sub(1, 3) ~= "ds_" then return end
        local session = DS.Players.Get(player)
        if session then session:Chat("<red>Commande inconnue.</> Tapez /ds_help.") end
        return false
    end

    local session = DS.Players.Get(player)
    if not session or session.state ~= "loaded" then
        return false
    end

    if #message > Config.Security.MaxCommandLength then
        session:Chat("<red>Commande trop longue.</>")
        return false
    end

    if not DS.Security.ConsumeRate(session, "cmd", Config.Security.CommandRate) then
        session:Chat("<red>Trop de commandes.</> Patientez quelques secondes.")
        return false
    end

    table.remove(args, 1)
    Log:Info("%s (#%s) : %s", session.name, session.id, message)
    execute(def, chatContext(session), args)

    -- false = la commande n'est pas affichée dans le chat public
    return false
end

-- ===========================================================================
-- API publique
-- ===========================================================================

function Commands.Register(def)
    assert(type(def) == "table", "Commands.Register : table attendue")
    assert(type(def.name) == "string" and def.name:match("^[%w_]+$"), "Commands.Register : nom invalide")
    assert(type(def.handler) == "function", "Commands.Register : handler manquant pour " .. tostring(def.name))
    def.name = def.name:lower()
    if registry[def.name] then
        error("Commands.Register : la commande '" .. def.name .. "' existe deja", 2)
    end

    def.description = def.description or ""
    def.usage = def.usage or ""
    def.minArgs = def.minArgs or 0
    def.chat = def.chat ~= false
    def.console = def.console ~= false

    registry[def.name] = def
    names[#names + 1] = def.name
    table.sort(names)

    if def.console then
        Console.RegisterCommand(def.name, function(...)
            execute(def, consoleContext, { ... })
        end, def.description, def.params or {})
    end
    return def
end

function Commands.Get(name)
    return registry[name]
end

--- Commandes utilisables dans ce contexte, triées par nom.
function Commands.GetAvailable(ctx)
    local list = {}
    for _, name in ipairs(names) do
        local def = registry[name]
        if Commands.CanUse(ctx, def) then list[#list + 1] = def end
    end
    return list
end

function Commands:Init()
    Chat.Subscribe("PlayerSubmit", onChatSubmit)
end

return Commands
