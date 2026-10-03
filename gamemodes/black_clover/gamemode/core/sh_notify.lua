--[[
    Black Clover RP — core/sh_notify.lua
    Realm : PARTAGÉ

    Notifications à l'écran.

    Côté serveur :
        BlackClover.Notify(ply, "Texte", BlackClover.NotifyType.Info, 5)
        BlackClover.Notify({ ply1, ply2 }, "Texte")   -- plusieurs joueurs
        BlackClover.Notify(nil, "Texte")              -- tout le serveur

    Côté client :
        BlackClover.ShowNotification("Texte", BlackClover.NotifyType.Error, 5)

    Pour l'instant, l'affichage utilise les notifications de Garry's Mod.
    Il sera remplacé par une interface Black Clover en Phase 14 (HUD) sans
    changer cette API.
]]

BlackClover.NotifyType = {
    Info    = 0,
    Error   = 1,
    Undo    = 2,
    Hint    = 3,
    Cleanup = 4,
}

local MAX_LENGTH   = 200
local MAX_DURATION = 15

BlackClover.Net.Register("BlackClover.Notify")

if SERVER then
    --- Envoie une notification.
    -- @param target Player|table|nil Joueur, liste de joueurs, ou nil pour tous
    -- @param text string
    -- @param notifyType number|nil BlackClover.NotifyType (Info par défaut)
    -- @param duration number|nil Durée en secondes (5 par défaut)
    function BlackClover.Notify(target, text, notifyType, duration)
        local Util = BlackClover.Util

        text = Util.SanitizeString(tostring(text), MAX_LENGTH)
        notifyType = Util.ToInteger(notifyType, BlackClover.NotifyType.Info, 0, 4)
        duration = Util.ToInteger(duration, 5, 1, MAX_DURATION)

        net.Start("BlackClover.Notify")
            net.WriteString(text)
            net.WriteUInt(notifyType, 3)
            net.WriteUInt(duration, 4)

        if target == nil then
            net.Broadcast()
        else
            net.Send(target)
        end
    end
else
    local SOUNDS = {
        [BlackClover.NotifyType.Error] = "buttons/button10.wav",
    }

    --- Affiche une notification locale.
    function BlackClover.ShowNotification(text, notifyType, duration)
        notifyType = notifyType or BlackClover.NotifyType.Info
        duration = duration or 5

        notification.AddLegacy(text, notifyType, duration)
        surface.PlaySound(SOUNDS[notifyType] or "buttons/button15.wav")
        MsgC(Color(40, 180, 90), "[Black Clover] ", Color(235, 235, 235), text, "\n")
    end

    BlackClover.Net.Receive("BlackClover.Notify", function()
        local text = net.ReadString()
        local notifyType = net.ReadUInt(3)
        local duration = net.ReadUInt(4)

        BlackClover.ShowNotification(text, notifyType, duration)
    end)
end
