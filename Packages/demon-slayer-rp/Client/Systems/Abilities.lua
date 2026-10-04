--[[
    Demon Slayer RP - Techniques (client)
    ------------------------------------------------------------------
    - Enregistre les touches (Q E R F X par défaut). Chaque joueur peut les
      changer dans Paramètres > Touches (catégorie "Demon Slayer RP").
    - Envoie au serveur uniquement l'emplacement choisi ; le serveur décide.
    - Garde une copie de l'état reçu du serveur pour l'affichage (HUD).

    Évènement interne émis : "Abilities:Changed" à chaque mise à jour de l'état.
]]

local Abilities = DS.Module("Abilities", { dependencies = { "Network", "Session" } })
DS.Abilities = Abilities

local Log = Abilities.Log

local state = {
    faction = "",
    kind = "",
    setId = "",
    resource = "",
    resourceCurrent = 0,
    resourceMax = 0,
    cooldownUntil = {}, -- [slot] = heure locale (ms) de fin de recharge
}

function Abilities.GetState()
    return state
end

--- Souffle / art actuel (table du catalogue) ou nil.
function Abilities.GetSet()
    if state.kind == "" or state.setId == "" then return nil end
    return DS.Catalog.GetSet(state.kind, state.setId)
end

--- Temps de recharge restant (ms) pour un emplacement.
function Abilities.GetRemaining(slot)
    local untilMs = state.cooldownUntil[slot]
    if not untilMs then return 0 end
    return math.max(0, untilMs - DS.Utils.NowMs())
end

local function changed()
    DS.Bus.Emit("Abilities:Changed", state)
end

-- Message dans le chat local, au plus une fois par seconde
local lastFeedback = 0
local function feedback(message)
    local now = DS.Utils.NowMs()
    if now - lastFeedback < 1000 then return end
    lastFeedback = now
    Chat.AddMessage(Config.Core.ChatPrefix .. " " .. message)
    Log:Info("%s", message)
end

local function tryUse(slot)
    Log:Debug("Touche de la technique %s pressee", slot)
    if not DS.Session.IsReady() then
        return feedback("Connexion au gamemode pas encore etablie (handshake).")
    end
    local set = Abilities.GetSet()
    if not set then
        if state.faction == "" then
            return feedback("Pas de faction : /ds_setfaction moi pourfendeur")
        end
        return feedback("Pas encore de souffle / d'art demoniaque attribue.")
    end
    if not set.Techniques[slot] then return end
    -- Le serveur vérifie aussi : ceci évite seulement d'envoyer des requêtes inutiles
    if Abilities.GetRemaining(slot) > 0 then return end
    local tech = set.Techniques[slot]
    if tech.RequiredLevel > (state.level or 1) then
        return feedback(tech.Name .. " : niveau " .. tech.RequiredLevel .. " requis.")
    end
    if DS.Net.Send("UseSkill", slot) then
        Log:Info("Technique %s demandee au serveur", slot)
    end
end

function Abilities:Init()
    DS.Net.On("AbilitiesSync", function(payload)
        state.faction = payload.faction
        state.kind = payload.kind
        state.setId = payload.setId
        state.resource = payload.resource
        state.resourceMax = payload.resourceMax
        state.level = payload.level
        state.cooldownUntil = {}
        changed()
    end)

    DS.Net.On("ResourceSync", function(current, max)
        state.resourceCurrent = current
        state.resourceMax = max
        changed()
    end)

    DS.Net.On("SkillCooldown", function(slot, durationMs)
        state.cooldownUntil[slot] = DS.Utils.NowMs() + durationMs
        changed()
    end)

    for slot, key in ipairs(Config.Abilities.Keys) do
        local binding = "DSRP_Technique_" .. slot
        local label = slot >= 5 and ("Demon Slayer RP - Technique speciale " .. (slot - 4))
            or ("Demon Slayer RP - Technique " .. slot)
        Input.Register(binding, key, label)
        Input.Bind(binding, InputEvent.Pressed, function()
            tryUse(slot)
        end)
    end
    Log:Debug("Touches des techniques : %s", table.concat(Config.Abilities.Keys, " "))
end

return Abilities
