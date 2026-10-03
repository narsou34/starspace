--[[
    Black Clover RP — systems/progression/sv_progression.lua
    Realm : SERVEUR

    API :
        Progression.AddXP(ply, amount, reason)
        Progression.SetLevel(ply, level)
        Progression.GetStat(ply, "MagicPower" | "ManaControl")
        Progression.AddStatBonus(ply, stat, amount)   -- entraînement, objets…
        Progression.Apply(ply)                        -- recalcule et synchronise

    Hook déclenché :
        BlackClover.LevelUp (ply, newLevel, oldLevel)
]]

local Progression = BlackClover.Progression
local Config = BlackClover.Config
local Util = BlackClover.Util
local Log = BlackClover.Log

local VALID_STATS = { MagicPower = true, ManaControl = true }

--- Valeur totale d'une statistique : gain par niveau + bonus (entraînement…).
function Progression.GetStat(ply, stat)
    local char = ply.bcCharacter
    if not char or not VALID_STATS[stat] then return 0 end

    local perLevel = Config.Progression.StatsPerLevel[stat] or 0
    local bonus = Util.ToNumber(char.Data.Stats[stat], 0, 0)

    return math.floor((char.Level - 1) * perLevel + bonus)
end

--- Ajoute un bonus permanent à une statistique.
function Progression.AddStatBonus(ply, stat, amount)
    local char = ply.bcCharacter
    if not char or not VALID_STATS[stat] then return end

    amount = Util.ToNumber(amount, 0, -10000, 10000)
    char.Data.Stats[stat] = math.max(Util.ToNumber(char.Data.Stats[stat], 0) + amount, 0)

    Progression.Apply(ply)
end

--- Synchronise niveau / XP / stats et recalcule le mana.
function Progression.Apply(ply)
    local char = ply.bcCharacter

    ply:SetNW2Int("BC_Level", char and char.Level or 1)
    ply:SetNW2Int("BC_XP", char and char.XP or 0)
    ply:SetNW2Int("BC_MagicPower", char and Progression.GetStat(ply, "MagicPower") or 0)
    ply:SetNW2Int("BC_ManaControl", char and Progression.GetStat(ply, "ManaControl") or 0)

    if BlackClover.Mana and BlackClover.Mana.Recalculate then
        BlackClover.Mana.Recalculate(ply)
    end
end

local function OnLevelsGained(ply, oldLevel, newLevel)
    hook.Run("BlackClover.LevelUp", ply, newLevel, oldLevel)

    BlackClover.Notify(ply, string.format("Niveau supérieur ! Vous êtes maintenant niveau %d.", newLevel), BlackClover.NotifyType.Hint, 6)

    if BlackClover.Effects then
        BlackClover.Effects.Play("levelup", ply:GetPos() + Vector(0, 0, 40), { Color = Color(255, 215, 80), Scale = 1.5 })
    end
end

--- Ajoute de l'expérience et gère les passages de niveau.
function Progression.AddXP(ply, amount, reason)
    local char = ply.bcCharacter
    if not char then return end

    amount = Util.ToInteger(amount, 0, 0, Config.Progression.MaxXPGain)
    if amount <= 0 then return end

    local maxLevel = Config.Progression.MaxLevel
    if char.Level >= maxLevel then return end

    local oldLevel = char.Level
    char.XP = char.XP + amount

    while char.Level < maxLevel do
        local needed = Progression.GetXPForLevel(char.Level)
        if char.XP < needed then break end

        char.XP = char.XP - needed
        char.Level = char.Level + 1
    end

    if char.Level >= maxLevel then char.XP = 0 end

    Progression.Apply(ply)

    if char.Level > oldLevel then
        OnLevelsGained(ply, oldLevel, char.Level)
    end

    Log.Debug("Progression", "%s +%d XP (%s)", Log.FormatPlayer(ply), amount, reason or "?")
end

--- Définit directement le niveau (XP remise à 0).
function Progression.SetLevel(ply, level)
    local char = ply.bcCharacter
    if not char then return false end

    local oldLevel = char.Level
    char.Level = Util.ToInteger(level, 1, 1, Config.Progression.MaxLevel)
    char.XP = 0

    Progression.Apply(ply)

    if char.Level > oldLevel then
        OnLevelsGained(ply, oldLevel, char.Level)
    end

    return true
end

-- ─── Chargement / déchargement ──────────────────────────────────────────

hook.Add("BlackClover.CharacterLoaded", "BlackClover.Progression", Progression.Apply)
hook.Add("BlackClover.CharacterUnloaded", "BlackClover.Progression", function(ply)
    -- ply.bcCharacter est encore défini pendant ce hook : on attend la frame suivante
    timer.Simple(0, function()
        if IsValid(ply) and not ply.bcCharacter then Progression.Apply(ply) end
    end)
end)

-- ─── Gains d'XP au combat ───────────────────────────────────────────────

hook.Add("OnNPCKilled", "BlackClover.Progression", function(npc, attacker)
    if IsValid(attacker) and attacker:IsPlayer() then
        Progression.AddXP(attacker, Config.Progression.XPPerNPCKill, "PNJ tué")
    end
end)

hook.Add("PlayerDeath", "BlackClover.Progression", function(victim, _, attacker)
    if not (IsValid(attacker) and attacker:IsPlayer()) or attacker == victim then return end
    if not victim.bcCharacter then return end

    -- Anti-farm : pas d'XP pour tuer la même personne trop souvent
    attacker.bcKillCooldowns = attacker.bcKillCooldowns or {}
    local key = victim:SteamID64()
    if (attacker.bcKillCooldowns[key] or 0) > CurTime() then return end
    attacker.bcKillCooldowns[key] = CurTime() + Config.Progression.PlayerKillCooldown

    Progression.AddXP(attacker, Config.Progression.XPPerPlayerKill, "joueur vaincu")
end)
