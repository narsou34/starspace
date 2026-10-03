--[[
    Black Clover RP — core/sv_player.lua
    Realm : SERVEUR

    Cycle de vie du joueur côté serveur :
        - connexion / déconnexion (logs) ;
        - "joueur prêt" (le client a fini de charger, on peut lui envoyer des données) ;
        - spawn : vitesses, santé, modèle, équipement ;
        - touches F1 / F2 / F3 ;
        - restrictions sandbox pour les joueurs non staff.

    Hooks personnalisés déclenchés ici (à utiliser dans les systèmes) :
        BlackClover.PlayerReady (ply)          → le client est prêt
        BlackClover.PlayerSpawn (ply)          → après chaque spawn
        BlackClover.PlayerLoadout (ply)        → ajouter des armes au spawn
        BlackClover.GetPlayerModel (ply)       → renvoyer un modèle à utiliser
]]

DEFINE_BASECLASS("gamemode_sandbox")

local Config = BlackClover.Config
local Log = BlackClover.Log
local Permissions = BlackClover.Permissions

BlackClover.Net.Register("BlackClover.UI.Open")

-- ─── Connexion / déconnexion ────────────────────────────────────────────

function GM:PlayerInitialSpawn(ply, transition)
    BaseClass.PlayerInitialSpawn(self, ply, transition)

    ply.bcReady = false
    Log.Info("Player", "Connexion : %s", Log.FormatPlayer(ply))
end

hook.Add("PlayerDisconnected", "BlackClover.Player.Disconnect", function(ply)
    Log.Info("Player", "Déconnexion : %s", Log.FormatPlayer(ply))
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
    BlackClover.Notify(ply, string.format("Bienvenue sur %s (v%s) ! F1 : fiche  •  F2 : personnages  •  F3 : grimoire",
        Config.ServerName, BlackClover.Version), BlackClover.NotifyType.Hint, 10)
end)

-- ─── Spawn ──────────────────────────────────────────────────────────────

function GM:PlayerSpawn(ply, transition)
    BaseClass.PlayerSpawn(self, ply, transition)

    -- Appliqué APRÈS la classe sandbox, qui définit ses propres valeurs.
    local cfg = Config.Player
    ply:SetWalkSpeed(cfg.WalkSpeed)
    ply:SetRunSpeed(cfg.RunSpeed)
    ply:SetJumpPower(cfg.JumpPower)
    ply:SetMaxHealth(cfg.MaxHealth)
    ply:SetHealth(cfg.MaxHealth)

    hook.Run("BlackClover.PlayerSpawn", ply)
end

function GM:PlayerSetModel(ply)
    local model = hook.Run("BlackClover.GetPlayerModel", ply)

    if isstring(model) then
        ply:SetModel(model)
        return
    end

    BaseClass.PlayerSetModel(self, ply)
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

    hook.Run("BlackClover.PlayerLoadout", ply)

    ply:SwitchToDefaultWeapon()
    return true
end

-- ─── Touches F1 / F2 / F3 ───────────────────────────────────────────────

local function OpenMenu(ply, menu)
    net.Start("BlackClover.UI.Open")
        net.WriteString(menu)
    net.Send(ply)
end

function GM:ShowHelp(ply)   OpenMenu(ply, "sheet") end      -- F1 : fiche personnage
function GM:ShowTeam(ply)   hook.Run("BlackClover.OpenCharacterMenu", ply) end -- F2 : personnages
function GM:ShowSpare1(ply) OpenMenu(ply, "grimoire") end   -- F3 : grimoire
function GM:ShowSpare2(ply) OpenMenu(ply, "sheet") end      -- F4 : fiche personnage

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
