--[[
    Demon Slayer RP - Commandes de base (serveur)
    ------------------------------------------------------------------
    Commandes de diagnostic du Core (Phase 1).
    Les commandes d'administration RP (/ds_setfaction, /ds_heal...) seront
    ajoutées avec leurs systèmes respectifs.
]]

local BaseCommands = DS.Module("BaseCommands", {
    dependencies = { "Commands", "PlayerManager", "Permissions", "Network", "Security" },
})

local Utils = DS.Utils

local function uptime()
    if not DS.StartedAt then return "-" end
    return Utils.FormatDuration(Utils.NowMs() - DS.StartedAt)
end

local function describeSession(session)
    local group = DS.Permissions.GetGroup(session.group)
    return string.format("#%s %s | %s | %s | %s ms | %s",
        session.id, session.name, group and group.label or session.group, session.state,
        session:GetPing(), Utils.FormatDuration(session:GetConnectedMs()))
end

function BaseCommands:Init()
    local Commands = DS.Commands

    Commands.Register({
        name = "ds_help",
        description = "Liste des commandes disponibles",
        permission = "core.help",
        handler = function(ctx)
            ctx.Reply("<yellow>Commandes disponibles :</>")
            for _, def in ipairs(Commands.GetAvailable(ctx)) do
                local usage = def.usage ~= "" and (" " .. def.usage) or ""
                ctx.Reply("/" .. def.name .. usage .. " - " .. def.description)
            end
        end,
    })

    Commands.Register({
        name = "ds_info",
        description = "Informations sur le serveur et le gamemode",
        permission = "core.info",
        handler = function(ctx)
            local modules = DS.Modules.List()
            local running = 0
            for _, module in ipairs(modules) do
                if module.state == "started" then running = running + 1 end
            end
            ctx.Reply(string.format("<cyan>%s</> v%s par %s", DS.Name, DS.Version, DS.Author))
            ctx.Reply(string.format("Joueurs : %s | En ligne depuis : %s | Modules : %s/%s",
                DS.Players.Count(), uptime(), running, #modules))
        end,
    })

    Commands.Register({
        name = "ds_whoami",
        description = "Vos informations de session (dont votre Account ID)",
        permission = "core.whoami",
        console = false,
        handler = function(ctx)
            local session = ctx.session
            local group = DS.Permissions.GetGroup(session.group)
            ctx.Reply(string.format("<yellow>%s</> (#%s)", session.name, session.id))
            ctx.Reply("Account ID : " .. session.accountId)
            ctx.Reply(string.format("Groupe : %s | Ping : %s ms | Connecte depuis : %s",
                group and group.label or session.group, session:GetPing(),
                Utils.FormatDuration(session:GetConnectedMs())))
        end,
    })

    Commands.Register({
        name = "ds_players",
        description = "Liste des joueurs connectes",
        permission = "admin.players",
        handler = function(ctx)
            local all = DS.Players.All()
            ctx.Reply(string.format("<yellow>%s joueur(s) connecte(s)</>", #all))
            for _, session in ipairs(all) do
                ctx.Reply(describeSession(session))
            end
        end,
    })

    Commands.Register({
        name = "ds_modules",
        description = "Etat des modules du gamemode",
        permission = "admin.modules",
        handler = function(ctx)
            for _, module in ipairs(DS.Modules.List()) do
                local line = string.format("%s : %s (init %s ms, start %s ms)",
                    module.name, module.state, module.initMs, module.startMs)
                if module.error then line = line .. " - " .. module.error end
                ctx.Reply(line)
            end
        end,
    })

    Commands.Register({
        name = "ds_netstats",
        description = "Statistiques reseau et anti-exploit",
        permission = "admin.netstats",
        handler = function(ctx)
            local net = DS.Net.GetStats()
            local sec = DS.Security.GetStats()
            ctx.Reply(string.format("Recus : %s | acceptes : %s | rejetes : %s | ignores : %s | erreurs : %s | envoyes : %s",
                net.received, net.accepted, net.rejected, net.dropped, net.errors, net.sent))
            local kinds = {}
            for _, kind in ipairs(Utils.SortedKeys(sec.byKind)) do
                kinds[#kinds + 1] = kind .. "=" .. sec.byKind[kind]
            end
            ctx.Reply(string.format("Infractions : %s (%s) | expulsions : %s",
                sec.violations, #kinds > 0 and table.concat(kinds, ", ") or "aucune", sec.kicks))
        end,
    })

    Commands.Register({
        name = "ds_setgroup",
        description = "Change le groupe staff d'un joueur (jusqu'a sa deconnexion)",
        usage = "[id|nom] [groupe]",
        permission = "admin.setgroup",
        minArgs = 2,
        params = { "joueur", "groupe" },
        handler = function(ctx, args)
            local target, err = DS.Players.Find(args[1])
            if not target then return ctx.Error(err) end

            local groupName = args[2]:lower()
            local group = DS.Permissions.GetGroup(groupName)
            if not group then
                local available = {}
                for _, g in ipairs(DS.Permissions.GetGroups()) do available[#available + 1] = g.name end
                return ctx.Error("Groupe inconnu. Disponibles : " .. table.concat(available, ", "))
            end

            -- Hiérarchie : impossible d'agir sur un égal/supérieur ou de donner un rang >= au sien
            if not ctx.isConsole then
                local actorWeight = DS.Permissions.GetWeight(ctx.session)
                if target ~= ctx.session and DS.Permissions.GetWeight(target) >= actorWeight then
                    return ctx.Error("Vous ne pouvez pas modifier un membre de rang egal ou superieur.")
                end
                if group.weight >= actorWeight then
                    return ctx.Error("Vous ne pouvez pas attribuer un groupe de rang egal ou superieur au votre.")
                end
            end

            local by = ctx.isConsole and "console" or (ctx.session.name .. " #" .. ctx.session.id)
            local ok, reason = DS.Permissions.SetGroup(target, groupName, by)
            if not ok then return ctx.Error(reason) end

            ctx.Reply(string.format("%s (#%s) est maintenant %s.", target.name, target.id, group.label))
            target:Notify("Votre groupe est maintenant : " .. group.label, "success")
        end,
    })
end

return BaseCommands
