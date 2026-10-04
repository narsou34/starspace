--[[
    Demon Slayer RP - HUD provisoire (client)
    ------------------------------------------------------------------
    Affichage simple en bas à gauche : faction, souffle / art, ressource,
    techniques avec leur touche et leur recharge.
    Le HUD définitif (HTML, Phase 21) le remplacera.

    Le Canvas n'est redessiné que lorsque c'est utile (changement d'état,
    ou 4 fois par seconde tant qu'une recharge est en cours).
]]

local Hud = DS.Module("Hud", { dependencies = { "Abilities" } })
DS.Hud = Hud

local canvas = nil
local refreshTimer = nil

local FONT = FontType.OpenSans
local COLORS = {
    title = Color.WHITE,
    ready = Color(0.6, 1, 0.6, 1),
    cooldown = Color(1, 0.55, 0.45, 1),
    resource = Color(0.5, 0.85, 1, 1),
    demon = Color(1, 0.35, 0.35, 1),
}

local function bar(current, max, width)
    if max <= 0 then return "" end
    local filled = math.floor(width * current / max + 0.5)
    return "[" .. string.rep("|", filled) .. string.rep(".", width - filled) .. "]"
end

local function text(value, x, y, size, color)
    canvas:DrawText(value, Vector2D(x, y), FONT, size, color, 0, false, false,
        Color.TRANSPARENT, Vector2D(1, 1), true, Color.BLACK)
end

local function draw(_, width, height)
    local state = DS.Abilities.GetState()
    if state.faction == "" then return end

    local faction = DS.Catalog.GetFaction(state.faction)
    local set = DS.Abilities.GetSet()
    local x = 30
    local lines = 2 + (set and #set.Techniques or 1)
    local y = height - 60 - lines * 24

    text((faction and faction.Label or state.faction) .. "  -  niveau " .. (state.level or 1), x, y, 18,
        state.faction == "demons" and COLORS.demon or COLORS.title)
    y = y + 24

    local resource = Config.Resources[state.resource]
    if resource then
        text(string.format("%s %s %d/%d", resource.Label, bar(state.resourceCurrent, state.resourceMax, 20),
            math.floor(state.resourceCurrent), state.resourceMax), x, y, 14, COLORS.resource)
    end
    y = y + 24

    if not set then
        text("Aucune technique (demandez a un admin)", x, y, 14, COLORS.title)
        return
    end

    text(set.Name, x, y - 2, 15, COLORS.title)
    for slot, tech in ipairs(set.Techniques) do
        y = y + 22
        local remaining = DS.Abilities.GetRemaining(slot)
        local key = Config.Abilities.Keys[slot] or tostring(slot)
        local locked = tech.RequiredLevel > (state.level or 1)
        local status = locked and ("niveau " .. tech.RequiredLevel)
            or (remaining > 0 and string.format("%.1fs", remaining / 1000) or "pret")
        text(string.format("[%s] %s - %s", key, tech.Name, status), x + 10, y, 13,
            (locked or remaining > 0) and COLORS.cooldown or COLORS.ready)
    end
end

local function anyCooldown()
    local set = DS.Abilities.GetSet()
    if not set then return false end
    for slot in ipairs(set.Techniques) do
        if DS.Abilities.GetRemaining(slot) > 0 then return true end
    end
    return false
end

function Hud:Init()
    canvas = Canvas(true, Color.TRANSPARENT, -1, true)
    canvas:Subscribe("Update", draw)
    DS.Bus.On("Abilities:Changed", function() canvas:Repaint() end)
end

function Hud:Start()
    refreshTimer = Timer.SetInterval(function()
        if anyCooldown() then canvas:Repaint() end
    end, 250)
end

function Hud:Shutdown()
    if refreshTimer then Timer.ClearInterval(refreshTimer) end
end

return Hud
