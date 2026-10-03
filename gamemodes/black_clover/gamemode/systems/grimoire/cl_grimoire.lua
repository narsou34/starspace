--[[
    Black Clover RP — systems/grimoire/cl_grimoire.lua
    Realm : CLIENT

    Données du grimoire du joueur local (reçues du serveur) :
        BlackClover.Grimoire.Local = { Type, Leaves, Magic, Level, XP,
                                       Unlocked = { [id] = true }, Equipped, History }
    L'interface est dans ui/grimoire/.
]]

local Grimoire = BlackClover.Grimoire
local Net = BlackClover.Net

Grimoire.Local = Grimoire.Local or nil

Net.Receive("BlackClover.Grimoire.Sync", function()
    if not net.ReadBool() then
        Grimoire.Local = nil
    else
        local data = net.ReadTable()

        local unlocked = {}
        for _, spellID in ipairs(data.Unlocked or {}) do unlocked[spellID] = true end
        data.Unlocked = unlocked

        Grimoire.Local = data
    end

    hook.Run("BlackClover.GrimoireUpdated", Grimoire.Local)
end)

Net.Receive("BlackClover.Grimoire.Ceremony", function()
    local stage = net.ReadUInt(2)
    local data = net.ReadTable()

    local ui = BlackClover.CeremonyUI
    if not ui then return end

    if stage == 1 then ui.Start(data)
    elseif stage == 2 then ui.Result(data)
    else ui.Cancel() end
end)

--- Demande au serveur d'équiper un sort ("" pour vider l'emplacement).
function Grimoire.RequestEquip(slot, spellID)
    net.Start("BlackClover.Grimoire.Equip")
        net.WriteUInt(slot, 4)
        net.WriteString(spellID or "")
    net.SendToServer()
end
