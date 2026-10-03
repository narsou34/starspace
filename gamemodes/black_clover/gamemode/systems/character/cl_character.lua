--[[
    Black Clover RP — systems/character/cl_character.lua
    Realm : CLIENT

    Réception des données de personnage et envoi des demandes au serveur.
    L'interface est dans ui/character/.

    BlackClover.Character.Local → données privées du personnage chargé
    BlackClover.Character.List  → liste reçue pour le menu de sélection
]]

local Character = BlackClover.Character
local Net = BlackClover.Net

Character.Local = Character.Local or nil
Character.List = Character.List or {}

Net.Receive("BlackClover.Character.List", function()
    Character.List = net.ReadTable()
    local canClose = net.ReadBool()
    local currentID = net.ReadUInt(32)

    if BlackClover.CharacterMenu then
        BlackClover.CharacterMenu.Open(Character.List, canClose, currentID)
    end
end)

Net.Receive("BlackClover.Character.Sync", function()
    Character.Local = net.ReadTable()

    if BlackClover.CharacterMenu then
        BlackClover.CharacterMenu.Close()
    end
end)

Net.Receive("BlackClover.Character.Error", function()
    local message = net.ReadString()
    BlackClover.ShowNotification(message, BlackClover.NotifyType.Error, 5)

    if BlackClover.CharacterMenu and BlackClover.CharacterMenu.OnError then
        BlackClover.CharacterMenu.OnError(message)
    end
end)

-- ─── Demandes ───────────────────────────────────────────────────────────

function Character.RequestCreate(data)
    net.Start("BlackClover.Character.Create")
        net.WriteString(data.FirstName or "")
        net.WriteString(data.LastName or "")
        net.WriteUInt(math.Clamp(math.floor(tonumber(data.Age) or 0), 0, 255), 8)
        net.WriteString(data.Sex or "")
        net.WriteString(data.Model or "")
        net.WriteString(data.Kingdom or "")
        net.WriteString(data.Origin or "")
        net.WriteString(data.Personality or "")
        net.WriteString(data.Story or "")
    net.SendToServer()
end

function Character.RequestSelect(charID)
    net.Start("BlackClover.Character.Select")
        net.WriteUInt(charID, 32)
    net.SendToServer()
end

function Character.RequestDelete(charID)
    net.Start("BlackClover.Character.Delete")
        net.WriteUInt(charID, 32)
    net.SendToServer()
end

function Character.RequestMenu()
    net.Start("BlackClover.Character.RequestMenu")
    net.SendToServer()
end
