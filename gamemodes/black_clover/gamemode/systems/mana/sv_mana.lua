--[[
    Black Clover RP — systems/mana/sv_mana.lua
    Realm : SERVEUR

    Méthodes joueur (serveur uniquement) :
        ply:SetMana(amount)       → borné entre 0 et le maximum
        ply:RestoreMana(amount)   → ajoute du mana (amount > 0)
        ply:ConsumeMana(amount)   → retire du mana, renvoie false si insuffisant

    Mana maximum =
        (Base + PerLevel × (niveau - 1) + PerManaControl × contrôle)
        × multiplicateur de la magie × multiplicateur du grimoire
        × statuts (MaxManaMult) + statuts (MaxManaAdd)
        → puis le hook "BlackClover.ModifyMaxMana" (équipements…)

    Régénération / s =
        (RegenBase + RegenPerManaControl × contrôle)
        × multiplicateur de la magie × statuts (ManaRegenMult)
        → puis le hook "BlackClover.ModifyManaRegen"

    Toutes les valeurs sont protégées contre NaN, l'infini et les négatifs.
]]

local Mana = BlackClover.Mana
local Config = BlackClover.Config
local Util = BlackClover.Util

local MAX_MANA_LIMIT = 1000000

local function GetMagicStats(ply)
    local magic = ply.bcCharacter and ply.bcCharacter.Magic and Config.Magic[ply.bcCharacter.Magic]
    return magic and magic.Stats or {}
end

local function GetGrimoireType(ply)
    local grimoire = ply.bcGrimoire
    return grimoire and BlackClover.Grimoire and BlackClover.Grimoire.GetType(grimoire.Type) or nil
end

function Mana.CalculateMax(ply)
    local char = ply.bcCharacter
    if not char then return 0 end

    local cfg = Config.Mana
    local control = BlackClover.Progression.GetStat(ply, "ManaControl")

    local value = cfg.Base + cfg.PerLevel * (char.Level - 1) + cfg.PerManaControl * control
    value = value * Util.ToNumber(GetMagicStats(ply).Mana, 1, 0, 100)

    local grimoireType = GetGrimoireType(ply)
    if grimoireType then
        value = value * Util.ToNumber(grimoireType.ManaMultiplier, 1, 0, 100)
    end

    local Status = BlackClover.Status
    value = value * Status.GetMultiplier(ply, "MaxManaMult") + Status.GetSum(ply, "MaxManaAdd")

    value = hook.Run("BlackClover.ModifyMaxMana", ply, value) or value

    return Util.ToNumber(value, 0, 0, MAX_MANA_LIMIT)
end

function Mana.CalculateRegen(ply)
    if not ply.bcCharacter then return 0 end

    local cfg = Config.Mana
    local control = BlackClover.Progression.GetStat(ply, "ManaControl")

    local value = cfg.RegenBase + cfg.RegenPerManaControl * control
    value = value * Util.ToNumber(GetMagicStats(ply).Regen, 1, 0, 100)
    value = value * BlackClover.Status.GetMultiplier(ply, "ManaRegenMult")

    value = hook.Run("BlackClover.ModifyManaRegen", ply, value) or value

    return Util.ToNumber(value, 0, 0, MAX_MANA_LIMIT)
end

--- Recalcule maximum et régénération (après un changement de niveau, de magie, de statut…).
function Mana.Recalculate(ply)
    if not IsValid(ply) then return end

    ply:SetNW2Float("BC_MaxMana", Mana.CalculateMax(ply))
    ply:SetNW2Float("BC_ManaRegen", Mana.CalculateRegen(ply))

    -- Le mana actuel ne peut pas dépasser le nouveau maximum
    if ply:GetMana() > ply:GetMaxMana() then
        ply:SetMana(ply:GetMaxMana())
    end
end

-- ─── Méthodes joueur ────────────────────────────────────────────────────

local PLAYER = FindMetaTable("Player")

function PLAYER:SetMana(amount)
    amount = Util.ToNumber(amount, 0, 0, self:GetMaxMana())

    self:SetNW2Float("BC_Mana", amount)
    if self.bcCharacter then self.bcCharacter.Mana = amount end
end

function PLAYER:RestoreMana(amount)
    amount = Util.ToNumber(amount, 0)
    if amount <= 0 then return end

    self:SetMana(self:GetMana() + amount)
end

--- @return boolean true si le mana a été consommé
function PLAYER:ConsumeMana(amount)
    amount = Util.ToNumber(amount, nil)
    if amount == nil or amount < 0 then return false end
    if amount == 0 then return true end

    local current = self:GetMana()
    if current < amount then return false end

    self:SetMana(current - amount)
    self.bcManaRegenBlockedUntil = CurTime() + Config.Mana.RegenDelay

    return true
end

-- ─── Régénération ───────────────────────────────────────────────────────

timer.Create("BlackClover.Mana.Regen", Config.Mana.TickRate, 0, function()
    local now = CurTime()
    local tick = Config.Mana.TickRate

    for _, ply in ipairs(player.GetAll()) do
        if ply.bcCharacter and ply:Alive() and now >= (ply.bcManaRegenBlockedUntil or 0) then
            local current, max = ply:GetMana(), ply:GetMaxMana()

            if current < max then
                ply:SetMana(current + ply:GetManaRegen() * tick)
            end
        end
    end
end)

-- ─── Spawn / chargement ─────────────────────────────────────────────────

hook.Add("BlackClover.PlayerSpawn", "BlackClover.Mana", function(ply)
    ply.bcManaRegenBlockedUntil = 0
    Mana.Recalculate(ply)
    ply:SetMana(ply:GetMaxMana() * Util.ToNumber(Config.Mana.RespawnFraction, 1, 0, 1))
end)

hook.Add("BlackClover.CharacterUnloaded", "BlackClover.Mana", function(ply)
    timer.Simple(0, function()
        if IsValid(ply) and not ply.bcCharacter then
            Mana.Recalculate(ply)
            ply:SetMana(0)
        end
    end)
end)
