--[[
    Black Clover RP — core/cl_player.lua
    Realm : CLIENT

    Cycle de vie du joueur côté client :
        - signale au serveur que le client est prêt ;
        - cache les menus sandbox (Q / C) aux joueurs non staff.

    Note : cacher les menus côté client n'est que du confort.
    La vraie restriction est faite côté serveur (core/sv_player.lua).
]]

local Config = BlackClover.Config
local Permissions = BlackClover.Permissions

-- ─── Joueur prêt ────────────────────────────────────────────────────────
-- InitPostEntity est appelé quand le client a fini de charger le monde :
-- à partir de là, il peut recevoir des net messages sans risque.
hook.Add("InitPostEntity", "BlackClover.Player.Ready", function()
    net.Start("BlackClover.PlayerReady")
    net.SendToServer()

    hook.Run("BlackClover.LocalPlayerReady", LocalPlayer())
end)

-- ─── Menus sandbox ──────────────────────────────────────────────────────

local function CanUseSandboxMenus()
    if not Config.Sandbox.RestrictToStaff then return true end
    return Permissions.IsStaff(LocalPlayer())
end

hook.Add("SpawnMenuOpen", "BlackClover.Sandbox.Restrict", function()
    if not CanUseSandboxMenus() then return false end
end)

hook.Add("ContextMenuOpen", "BlackClover.Sandbox.Restrict", function()
    if not CanUseSandboxMenus() then return false end
end)
