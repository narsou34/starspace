--[[
    Demon Slayer RP - Factions (serveur) - version de base
    ------------------------------------------------------------------
    État RP du joueur (session.data.rp) :
        faction = "slayers" | "demons" | nil
        kind    = "breathing" | "art" | nil   (déduit de la faction)
        setId   = identifiant du souffle / de l'art | nil

    Sans base de données (Phase 5), cet état est perdu à la déconnexion.

    Évènement interne émis : "RP:FactionChanged" (session, oldFaction, newFaction)
]]

local Factions = DS.Module("Factions", { dependencies = { "PlayerManager", "Network" } })
DS.Factions = Factions

local Log = Factions.Log

local function rp(session)
    local state = session.data.rp
    if not state then
        state = { faction = nil, kind = nil, setId = nil, level = Config.Abilities.StartLevel or 1 }
        session.data.rp = state
    end
    return state
end
Factions.State = rp

--- Applique les statistiques de la faction au personnage (vie max).
function Factions.ApplyStats(session, character, refill)
    character = character or session:GetCharacter()
    if not (character and character:IsValid()) then return end
    local faction = DS.Catalog.GetFaction(rp(session).faction)
    local maxHealth = faction and faction.MaxHealth or 100
    character:SetMaxHealth(maxHealth)
    if refill or character:GetHealth() > maxHealth then
        character:SetHealth(maxHealth)
    end
end

--- Envoie au client son état RP (faction, souffle/art, ressource).
function Factions.Sync(session)
    local state = rp(session)
    local faction = DS.Catalog.GetFaction(state.faction)
    local resourceId = faction and faction.Resource or ""
    local resource = Config.Resources[resourceId]
    session:Send("AbilitiesSync", {
        faction = state.faction or "",
        kind = state.kind or "",
        setId = state.setId or "",
        resource = resourceId,
        resourceMax = resource and resource.Max or 0,
        level = state.level or 1,
    })
end

function Factions.Get(session)
    return rp(session).faction
end

--- Change la faction (nil = aucune). Réinitialise le souffle / l'art.
function Factions.Set(session, factionId, by)
    if factionId ~= nil and not DS.Catalog.GetFaction(factionId) then
        return false, "faction inconnue"
    end
    local state = rp(session)
    local old = state.faction
    state.faction = factionId
    state.kind = factionId and DS.Catalog.GetFaction(factionId).AbilityKind or nil
    state.setId = nil

    Factions.ApplyStats(session, nil, true)
    Log:Info("Faction de %s (#%s) : %s -> %s (par %s)", session.name, session.id,
        tostring(old), tostring(factionId), tostring(by))
    DS.Bus.Emit("RP:FactionChanged", session, old, factionId)
    Factions.Sync(session)
    return true
end

--- Définit le souffle / l'art (doit correspondre à la faction).
function Factions.SetAbilitySet(session, setId, by)
    local state = rp(session)
    if not state.kind then return false, "le joueur n'a pas de faction" end
    if setId ~= nil and not DS.Catalog.GetSet(state.kind, setId) then
        return false, DS.Catalog.KindLabel(state.kind) .. " inconnu pour cette faction"
    end
    state.setId = setId
    Log:Info("%s de %s (#%s) : %s (par %s)", DS.Catalog.KindLabel(state.kind), session.name, session.id,
        tostring(setId), tostring(by))
    DS.Bus.Emit("RP:SetChanged", session, setId)
    Factions.Sync(session)
    return true
end

--- Niveau du personnage (progression complète : Phase 8).
function Factions.SetLevel(session, level, by)
    level = math.floor(tonumber(level) or 1)
    if level < 1 or level > (Config.Abilities.MaxLevel or 100) then
        return false, "niveau entre 1 et " .. (Config.Abilities.MaxLevel or 100)
    end
    rp(session).level = level
    Log:Info("Niveau de %s (#%s) : %s (par %s)", session.name, session.id, level, tostring(by))
    Factions.Sync(session)
    return true
end

function Factions.GetLevel(session)
    return rp(session).level or 1
end

function Factions:Init()
    DS.Bus.On("Player:Connecting", function(session) rp(session) end)
    DS.Bus.On("Player:Loaded", Factions.Sync)
    DS.Bus.On("Spawn:CharacterReady", function(session, character)
        Factions.ApplyStats(session, character, true)
    end)
end

return Factions
