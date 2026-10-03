--[[
    Black Clover RP — core/sv_player.lua
    Realm : SERVEUR

    Cycle de vie du joueur côté serveur :
        - connexion / déconnexion (logs) ;
        - "joueur prêt" (le client a fini de charger, on peut lui envoyer des données) ;
        - spawn : vitesses, santé, équipement ;
        - restrictions sandbox pour les joueurs non staff.

    Hooks personnalisés déclenchés ici (à utiliser dans les systèmes) :
        hook.Add("BlackClover.PlayerReady", "MonSysteme", function(ply) end)

    Le système de personnage (Phase 2) s'appuiera sur BlackClover.PlayerReady
    pour ouvrir le menu de sélection / charger le personnage.
]]

DEFINE_BASECLASS("gamemode_sandbox")

local Config = BlackClover.Config
local Log = BlackClover.Log
local Permissions = BlackClover.Permissions

-- ─── Connexion / déconnexion ────────────────────────────────────────────

function GM:PlayerInitialSpawn(ply, transition)
    BaseClass.PlayerInitialSpawn(self, ply, transition)

    ply.bcReady = false
    Log.Info("Player", "Connexion : %s", Log.FormatPlayer(ply))
end

hook.Add("PlayerDisconnected", "BlackClover.Player.Disconnect", function(ply)
    Log.Info("Player", "Déconnexion : %s", Log.FormatPlayer(ply))
    -- Phase 2/3 : sauvegarde du personnage ici.
end)

-- ─── Joueur prêt ────────────────────────────────────────────────────────
-- Envoyer des net messages dans PlayerInitialSpawn est risqué : le client
-- n'a pas toujours fini de charger. On attend donc son signal.

BlackClover.Net.Receive("BlackClover.PlayerReady", function(ply)
    if ply.bcReady then return end -- une seule fois par connexion

    ply.bcReady = true
    Log.Debug("Player", "Client prêt : %s", Log.FormatPlayer(ply))

    hook.Run("BlackClover.PlayerReady", ply)
end, { Cooldown = 2, MaxBytes = 16 })

--- Le joueur a-t-il fini de charger côté client ?
function BlackClover.IsPlayerReady(ply)
    return IsValid(ply) and ply.bcReady == true
end

hook.Add("BlackClover.PlayerReady", "BlackClover.Player.Welcome", function(ply)
    BlackClover.Notify(ply, string.format("Bienvenue sur %s (v%s) !", Config.ServerName, BlackClover.Version),
        BlackClover.NotifyType.Hint, 8)
end)

-- ─── Spawn ──────────────────────────────────────────────────────────────

function GM:PlayerSpawn(ply, transition)
    BaseClass.PlayerSpawn(self, ply, transition)

    -- Appliqué APRÈS la classe sandbox, qui définit ses propres valeurs.
    -- Les Phases 4/8 (mana, progression) pourront modifier ces valeurs.
    local cfg = Config.Player
    ply:SetWalkSpeed(cfg.WalkSpeed)
    ply:SetRunSpeed(cfg.RunSpeed)
    ply:SetJumpPower(cfg.JumpPower)
    ply:SetMaxHealth(cfg.MaxHealth)
    ply:SetHealth(cfg.MaxHealth)
end

--- Équipement de départ. Remplace celui de sandbox.
-- @return true pour empêcher l'équipement par défaut
function GM:PlayerLoadout(ply)
    for _, weaponClass in ipairs(Config.Player.Loadout) do
        ply:Give(weaponClass)
    end

    if Permissions.IsStaff(ply) then
        for _, weaponClass in ipairs(Config.Player.StaffLoadout) do
            ply:Give(weaponClass)
        end
    end

    ply:SwitchToDefaultWeapon()
    return true
end

-- ─── Restrictions sandbox ───────────────────────────────────────────────
-- Tous ces hooks reçoivent le joueur en premier argument.
-- Renvoyer false bloque l'action ; nil laisse sandbox décider.

local RESTRICTED_HOOKS = {
    "PlayerSpawnObject",
    "PlayerSpawnProp",
    "PlayerSpawnRagdoll",
    "PlayerSpawnEffect",
    "PlayerSpawnVehicle",
    "PlayerSpawnNPC",
    "PlayerSpawnSENT",
    "PlayerSpawnSWEP",
    "PlayerGiveSWEP",
    "CanProperty",
    "CanDrive",
}

local DENY_MESSAGE_DELAY = 3

local function IsRestricted(ply)
    if not Config.Sandbox.RestrictToStaff then return false end
    return not Permissions.IsStaff(ply)
end

for _, hookName in ipairs(RESTRICTED_HOOKS) do
    hook.Add(hookName, "BlackClover.Sandbox.Restrict", function(ply)
        if not IsRestricted(ply) then return end

        -- Message limité pour éviter le spam
        if (ply.bcNextDenyMessage or 0) < CurTime() then
            ply.bcNextDenyMessage = CurTime() + DENY_MESSAGE_DELAY
            BlackClover.Notify(ply, "Action réservée au staff.", BlackClover.NotifyType.Error, 3)
        end

        return false
    end)
end

-- Outil (toolgun) : réservé au staff même si quelqu'un en obtient un
hook.Add("CanTool", "BlackClover.Sandbox.Restrict", function(ply)
    if IsRestricted(ply) then return false end
end)
