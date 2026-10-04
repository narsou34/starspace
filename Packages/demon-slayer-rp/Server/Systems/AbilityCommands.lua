--[[
    Demon Slayer RP - Commandes factions / souffles / arts (serveur)
    ------------------------------------------------------------------
    "moi" peut remplacer le nom du joueur dans le chat : /ds_setfaction moi demon
]]

local AbilityCommands = DS.Module("AbilityCommands", {
    dependencies = { "Commands", "Factions", "Abilities", "Resources" },
})

local Catalog = DS.Catalog

-- Résout la cible d'une commande ("moi" = soi-même dans le chat)
local function findTarget(ctx, query)
    local q = tostring(query or ""):lower()
    if q == "moi" or q == "me" then
        if ctx.isConsole then return nil, "'moi' n'existe pas en console, utilisez l'id du joueur" end
        return ctx.session
    end
    return DS.Players.Find(query)
end

local function byWhom(ctx)
    return ctx.isConsole and "console" or (ctx.session.name .. " #" .. ctx.session.id)
end

local function listSets(ctx, kind)
    ctx.Reply("<yellow>" .. Catalog.KindLabel(kind) .. "s disponibles :</>")
    for _, id in ipairs(Catalog.ListSets(kind)) do
        local set = Catalog.GetSet(kind, id)
        ctx.Reply(id .. " - " .. set.Name)
    end
end

local function giveSet(ctx, args, kind, factionId)
    local target, err = findTarget(ctx, args[1])
    if not target then return ctx.Error(err) end

    local state = DS.Factions.State(target)
    if state.faction ~= factionId then
        return ctx.Error(target.name .. " doit d'abord appartenir a la faction "
            .. Catalog.GetFaction(factionId).Label .. " (/ds_setfaction).")
    end

    local setId = Catalog.FindSet(kind, args[2])
    if not setId then
        return ctx.Error(Catalog.KindLabel(kind) .. " inconnu. Liste : /" .. (kind == "breathing" and "ds_souffles" or "ds_arts"))
    end

    local ok, reason = DS.Factions.SetAbilitySet(target, setId, byWhom(ctx))
    if not ok then return ctx.Error(reason) end

    local set = Catalog.GetSet(kind, setId)
    ctx.Reply(target.name .. " maitrise maintenant : " .. set.Name)
    target:Notify("Vous maitrisez maintenant : " .. set.Name, "success")
end

function AbilityCommands:Init()
    local Commands = DS.Commands

    Commands.Register({
        name = "ds_setfaction",
        description = "Change la faction d'un joueur (pourfendeur, demon, aucune)",
        usage = "[id|nom|moi] [pourfendeur|demon|aucune]",
        permission = "admin.setfaction",
        minArgs = 2,
        params = { "joueur", "faction" },
        handler = function(ctx, args)
            local target, err = findTarget(ctx, args[1])
            if not target then return ctx.Error(err) end

            local query = args[2]:lower()
            local factionId = nil
            if query ~= "aucune" and query ~= "none" then
                factionId = Catalog.FindFaction(query)
                if not factionId then return ctx.Error("Faction inconnue : pourfendeur, demon ou aucune.") end
            end

            DS.Factions.Set(target, factionId, byWhom(ctx))
            local label = factionId and Catalog.GetFaction(factionId).Label or "aucune"
            ctx.Reply(target.name .. " rejoint la faction : " .. label)
            target:Notify("Votre faction : " .. label, "success")
            if factionId then
                local hint = factionId == "slayers" and "/ds_givebreathing" or "/ds_givedemonart"
                ctx.Reply("Etape suivante : " .. hint .. " " .. (ctx.isConsole and target.id or "moi") .. " [nom]")
            end
        end,
    })

    Commands.Register({
        name = "ds_givebreathing",
        description = "Donne un souffle a un pourfendeur",
        usage = "[id|nom|moi] [souffle]",
        permission = "admin.givebreathing",
        minArgs = 2,
        params = { "joueur", "souffle" },
        handler = function(ctx, args) giveSet(ctx, args, "breathing", "slayers") end,
    })

    Commands.Register({
        name = "ds_givedemonart",
        description = "Donne un art demoniaque a un demon",
        usage = "[id|nom|moi] [art]",
        permission = "admin.givedemonart",
        minArgs = 2,
        params = { "joueur", "art" },
        handler = function(ctx, args) giveSet(ctx, args, "art", "demons") end,
    })

    Commands.Register({
        name = "ds_souffles",
        description = "Liste des souffles",
        permission = "core.skills",
        handler = function(ctx) listSets(ctx, "breathing") end,
    })

    Commands.Register({
        name = "ds_arts",
        description = "Liste des arts demoniaques",
        permission = "core.skills",
        handler = function(ctx) listSets(ctx, "art") end,
    })

    Commands.Register({
        name = "ds_skills",
        description = "Vos techniques et leurs touches",
        permission = "core.skills",
        console = false,
        handler = function(ctx)
            local state = DS.Factions.State(ctx.session)
            local set = state.setId and Catalog.GetSet(state.kind, state.setId)
            if not set then
                return ctx.Reply("Vous n'avez pas encore de souffle ni d'art demoniaque.")
            end
            ctx.Reply("<yellow>" .. set.Name .. "</>")
            for slot, tech in ipairs(set.Techniques) do
                local lock = ""
                if tech.RequiredLevel > DS.Factions.GetLevel(ctx.session) then
                    lock = " (niveau " .. tech.RequiredLevel .. " requis)"
                end
                ctx.Reply(string.format("[%s] %s - %s pts, %ss de recharge%s",
                    Config.Abilities.Keys[slot] or slot, tech.Name, tech.Cost, tech.CooldownMs / 1000, lock))
            end
            if set.Passive then
                ctx.Reply("Passif : " .. set.Passive.Name .. " - " .. (set.Passive.Description or ""))
            end
        end,
    })

    Commands.Register({
        name = "ds_heal",
        description = "Soigne un joueur et remplit sa ressource",
        usage = "[id|nom|moi]",
        permission = "admin.heal",
        minArgs = 1,
        params = { "joueur" },
        handler = function(ctx, args)
            local target, err = findTarget(ctx, args[1])
            if not target then return ctx.Error(err) end
            DS.Abilities.Heal(target)
            ctx.Reply(target.name .. " a ete soigne.")
        end,
    })

    Commands.Register({
        name = "ds_npc",
        description = "Fait apparaitre un mannequin d'entrainement devant un joueur",
        usage = "[id|nom|moi]",
        permission = "admin.npc",
        params = { "joueur" },
        handler = function(ctx, args)
            local target, err = ctx.session, nil
            if args[1] or ctx.isConsole then
                target, err = findTarget(ctx, args[1])
                if not target then return ctx.Error(err or "Utilisation : ds_npc [id]") end
            end
            local dummy, spawnErr = DS.Abilities.SpawnDummy(target)
            if not dummy then return ctx.Error(spawnErr) end
            ctx.Reply("Mannequin pret devant " .. target.name .. " (" .. Config.Abilities.TrainingDummyHealth .. " PV).")
        end,
    })

    Commands.Register({
        name = "ds_setlevel",
        description = "Change le niveau d'un joueur (debloque les techniques avancees)",
        usage = "[id|nom|moi] [niveau]",
        permission = "admin.setlevel",
        minArgs = 2,
        params = { "joueur", "niveau" },
        handler = function(ctx, args)
            local target, err = findTarget(ctx, args[1])
            if not target then return ctx.Error(err) end
            local ok, reason = DS.Factions.SetLevel(target, args[2], byWhom(ctx))
            if not ok then return ctx.Error(reason) end
            ctx.Reply(target.name .. " est maintenant niveau " .. DS.Factions.GetLevel(target) .. ".")
            target:Notify("Niveau " .. DS.Factions.GetLevel(target), "success")
        end,
    })

    Commands.Register({
        name = "ds_cast",
        description = "Declenche une technique d'un joueur (test sans clavier)",
        usage = "[id|nom|moi] [1-5]",
        permission = "admin.cast",
        minArgs = 2,
        params = { "joueur", "emplacement" },
        handler = function(ctx, args)
            local target, err = findTarget(ctx, args[1])
            if not target then return ctx.Error(err) end
            local slot = math.tointeger(tonumber(args[2]))
            if not slot or slot < 1 or slot > DS.Catalog.Slots then
                return ctx.Error("Emplacement entre 1 et " .. DS.Catalog.Slots)
            end
            local ok, result = DS.Abilities.Use(target, slot)
            if ok then
                ctx.Reply("Technique " .. slot .. " lancee : " .. result .. " cible(s) touchee(s).")
            else
                ctx.Error("Refusee : " .. tostring(result))
            end
        end,
    })

    Commands.Register({
        name = "ds_clearnpc",
        description = "Supprime tous les mannequins d'entrainement",
        permission = "admin.npc",
        handler = function(ctx)
            ctx.Reply(DS.Abilities.ClearDummies() .. " mannequin(s) supprime(s).")
        end,
    })
end

return AbilityCommands
