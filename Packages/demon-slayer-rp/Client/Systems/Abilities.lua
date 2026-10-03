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

local function tryUse(slot)
    if not DS.Session.IsReady() then return end
    local set = Abilities.GetSet()
    if not set or not set.Techniques[slot] then return end
    -- Le serveur vérifie aussi : ceci évite seulement d'envoyer des requêtes inutiles
    if Abilities.GetRemaining(slot) > 0 then return end
    DS.Net.Send("UseSkill", slot)
end

function Abilities:Init()
    DS.Net.On("AbilitiesSync", function(payload)
        state.faction = payload.faction
        state.kind = payload.kind
        state.setId = payload.setId
        state.resource = payload.resource
        state.resourceMax = payload.resourceMax
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
        local label = slot == #Config.Abilities.Keys and "Demon Slayer RP - Technique speciale"
            or ("Demon Slayer RP - Technique " .. slot)
        Input.Register(binding, key, label)
        Input.Bind(binding, InputEvent.Pressed, function()
            tryUse(slot)
        end)
    end
    Log:Debug("Touches des techniques : %s", table.concat(Config.Abilities.Keys, " "))
end

return Abilities
