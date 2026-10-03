--[[
    Black Clover RP — core/sv_commands.lua
    Realm : SERVEUR

    Registre de commandes. Chaque commande est utilisable :
        - dans le chat : /bc_setmana Yuno 200   (ou !bc_setmana)
        - dans la console : bc_setmana Yuno 200

    Déclaration :
        BlackClover.Commands.Register("bc_setmana", {
            Description = "Définit le mana d'un joueur",
            Usage       = "<joueur> <montant>",
            Staff       = true,                       -- réservé au staff
            Callback    = function(ply, args)
                -- ply est nil si la commande vient de la console serveur
                return true, "Message de succès"      -- ou false, "Message d'erreur"
            end,
        })

    Toutes les commandes staff sont loguées (Log.Admin).
]]

BlackClover.Commands = BlackClover.Commands or {}
local Commands = BlackClover.Commands
local Log = BlackClover.Log

Commands.List = Commands.List or {}

local COMMAND_COOLDOWN = 0.5

--- Répond à l'auteur d'une commande (chat/notification ou console serveur).
function Commands.Reply(ply, message, isError)
    if IsValid(ply) then
        BlackClover.Notify(ply, message, isError and BlackClover.NotifyType.Error or BlackClover.NotifyType.Info, 5)
        ply:PrintMessage(HUD_PRINTCONSOLE, "[Black Clover] " .. message)
    else
        print("[Black Clover] " .. message)
    end
end

--- Exécute une commande avec vérification des permissions.
function Commands.Run(ply, name, args)
    local command = Commands.List[name]
    if not command then return false end

    if IsValid(ply) then
        if (ply.bcNextCommand or 0) > SysTime() then return true end
        ply.bcNextCommand = SysTime() + COMMAND_COOLDOWN

        if command.Staff and not BlackClover.Permissions.IsStaff(ply) then
            Commands.Reply(ply, "Vous n'avez pas la permission d'utiliser cette commande.", true)
            Log.Admin("Commands", "%s a tenté /%s sans permission", Log.FormatPlayer(ply), name)
            return true
        end
    end

    local ok, success, message = xpcall(command.Callback, debug.traceback, IsValid(ply) and ply or nil, args)

    if not ok then
        Log.Error("Commands", "Erreur dans /%s :\n%s", name, success)
        Commands.Reply(ply, "Erreur interne lors de l'exécution de la commande.", true)
        return true
    end

    if success == false then
        Commands.Reply(ply, (message or "Commande invalide.") .. (command.Usage and ("  Usage : /" .. name .. " " .. command.Usage) or ""), true)
        return true
    end

    if message then Commands.Reply(ply, message, false) end

    if command.Staff then
        Log.Admin("Commands", "%s : /%s %s", Log.FormatPlayer(ply), name, table.concat(args, " "))
    end

    return true
end

function Commands.Register(name, data)
    name = string.lower(name)
    data.Name = name
    Commands.List[name] = data

    concommand.Add(name, function(ply, _, args)
        Commands.Run(ply, name, args)
    end)
end

-- Chat : "/commande" ou "!commande"
hook.Add("PlayerSay", "BlackClover.Commands", function(ply, text)
    local prefix = string.sub(text, 1, 1)
    if prefix ~= "/" and prefix ~= "!" then return end

    local args = BlackClover.Util.ParseArgs(string.sub(text, 2))
    local name = string.lower(table.remove(args, 1) or "")

    if Commands.List[name] then
        Commands.Run(ply, name, args)
        return ""
    end
end)

-- Liste des commandes : /bc_help
Commands.Register("bc_help", {
    Description = "Liste les commandes disponibles",
    Callback = function(ply)
        local isStaff = not IsValid(ply) or BlackClover.Permissions.IsStaff(ply)
        local names = table.GetKeys(Commands.List)
        table.sort(names)

        for _, name in ipairs(names) do
            local cmd = Commands.List[name]
            if isStaff or not cmd.Staff then
                local line = string.format("/%s %s — %s", name, cmd.Usage or "", cmd.Description or "")
                if IsValid(ply) then ply:PrintMessage(HUD_PRINTCONSOLE, line) else print(line) end
            end
        end

        return true, "Liste des commandes affichée dans la console."
    end,
})
