--[[
    Black Clover RP — core/sh_permissions.lua
    Realm : PARTAGÉ

    Vérifications de permissions du staff.
    Le client peut appeler ces fonctions pour l'affichage (cacher un bouton…),
    mais SEUL le résultat côté serveur fait foi.

    Les permissions de faction / rang seront ajoutées en Phases 9 et 10.
]]

BlackClover.Permissions = BlackClover.Permissions or {}
local Permissions = BlackClover.Permissions
local Config = BlackClover.Config

--- Le joueur fait-il partie du staff ?
-- superadmin est toujours staff ; les autres groupes sont dans Config.StaffGroups.
function Permissions.IsStaff(ply)
    if not BlackClover.Util.IsValidPlayer(ply) then return false end
    if ply:IsSuperAdmin() then return true end

    return Config.StaffGroups[ply:GetUserGroup()] == true
end

--- Le joueur est-il superadmin ?
function Permissions.IsSuperAdmin(ply)
    return BlackClover.Util.IsValidPlayer(ply) and ply:IsSuperAdmin()
end

-- ─── Noclip ─────────────────────────────────────────────────────────────
-- Hook partagé (prédit) : il doit répondre la même chose des deux côtés.
hook.Add("PlayerNoClip", "BlackClover.Permissions.NoClip", function(ply, desiredState)
    -- Sortir du noclip est toujours autorisé
    if not desiredState then return true end

    if Config.Sandbox.PlayersCanNoclip or Permissions.IsStaff(ply) then
        return true
    end

    return false
end)
