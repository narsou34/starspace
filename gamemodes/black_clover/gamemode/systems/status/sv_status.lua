--[[
    Black Clover RP — systems/status/sv_status.lua
    Realm : SERVEUR

    API :
        Status.Apply(ent, statusTable, source)   -- (ré)applique, rafraîchit la durée
        Status.Remove(ent, id)
        Status.Clear(ent)
        Status.GetMultiplier(ent, "SpeedMult")   -- produit de tous les statuts
        Status.GetSum(ent, "MaxManaAdd")
        Status.HasFlag(ent, "Rooted")

    Fonctionne sur les joueurs et les PNJ (seuls les joueurs ont la vitesse
    et le mana modifiés).
]]

local Status = BlackClover.Status
local Config = BlackClover.Config
local Util = BlackClover.Util

Status.Tracked = Status.Tracked or {} -- entités ayant au moins un statut

local TICK = 0.2
local MAX_DURATION = 3600

--- Envoie au joueur la liste de ses statuts (pour le HUD).
local function Sync(ent)
    if not ent:IsPlayer() then return end

    local list = {}
    for id, data in pairs(ent.bcStatuses or {}) do
        list[#list + 1] = { ID = id, Name = data.Name or id, Expires = data.Expires }
    end

    net.Start("BlackClover.Status.Sync")
        net.WriteTable(list)
    net.Send(ent)
end

--- Applique vitesse / mana après un changement de statut.
function Status.Refresh(ent)
    if not IsValid(ent) or not ent:IsPlayer() then return end

    local cfg = Config.Player
    local speedMult = Status.GetMultiplier(ent, "SpeedMult")
    local rooted = Status.HasFlag(ent, "Rooted")

    if rooted then
        ent:SetWalkSpeed(1)
        ent:SetRunSpeed(1)
        ent:SetJumpPower(0)
    else
        ent:SetWalkSpeed(math.max(cfg.WalkSpeed * speedMult, 1))
        ent:SetRunSpeed(math.max(cfg.RunSpeed * speedMult, 1))
        ent:SetJumpPower(cfg.JumpPower)
    end

    if BlackClover.Mana and BlackClover.Mana.Recalculate then
        BlackClover.Mana.Recalculate(ent)
    end

    Sync(ent)
end

function Status.Apply(ent, status, source)
    if not IsValid(ent) or not istable(status) or not isstring(status.ID) then return end
    if ent:IsPlayer() and not ent:Alive() then return end

    local data = table.Copy(status)
    data.Expires = CurTime() + Util.ToNumber(status.Duration, 1, 0.05, MAX_DURATION)
    data.Source = source
    data.NextDot = CurTime() + 1

    ent.bcStatuses = ent.bcStatuses or {}
    ent.bcStatuses[status.ID] = data
    Status.Tracked[ent] = true

    Status.Refresh(ent)
end

function Status.Remove(ent, id)
    if not IsValid(ent) or not ent.bcStatuses or not ent.bcStatuses[id] then return end

    ent.bcStatuses[id] = nil
    Status.Refresh(ent)
end

function Status.Clear(ent)
    if not IsValid(ent) then return end

    ent.bcStatuses = {}
    Status.Tracked[ent] = nil
    Status.Refresh(ent)
end

function Status.GetMultiplier(ent, field)
    local result = 1
    for _, data in pairs(ent.bcStatuses or {}) do
        if data[field] then result = result * Util.ToNumber(data[field], 1, 0, 100) end
    end
    return result
end

function Status.GetSum(ent, field)
    local result = 0
    for _, data in pairs(ent.bcStatuses or {}) do
        if data[field] then result = result + Util.ToNumber(data[field], 0, -100000, 100000) end
    end
    return result
end

function Status.HasFlag(ent, field)
    for _, data in pairs(ent.bcStatuses or {}) do
        if data[field] then return true end
    end
    return false
end

-- ─── Expiration et dégâts sur la durée ──────────────────────────────────

--- Traite une entité : dégâts sur la durée et expiration.
function Status.Tick(ent, now)
    local changed = false

    for id, data in pairs(ent.bcStatuses or {}) do
        if data.DamagePerSecond and now >= data.NextDot then
            data.NextDot = now + 1

            local source = IsValid(data.Source) and data.Source or game.GetWorld()
            local dmg = DamageInfo()
            dmg:SetDamage(Util.ToNumber(data.DamagePerSecond, 0, 0, 1000))
            dmg:SetDamageType(DMG_POISON)
            dmg:SetAttacker(source)
            dmg:SetInflictor(source)
            ent:TakeDamageInfo(dmg)

            if not IsValid(ent) then return end
        end

        if now >= data.Expires then
            ent.bcStatuses[id] = nil
            changed = true
        end
    end

    if changed then Status.Refresh(ent) end
    if table.IsEmpty(ent.bcStatuses or {}) then Status.Tracked[ent] = nil end
end

timer.Create("BlackClover.Status.Tick", TICK, 0, function()
    local now = CurTime()

    -- Copie des clés : un statut peut être appliqué pendant la boucle
    local entities = table.GetKeys(Status.Tracked)

    for _, ent in ipairs(entities) do
        if IsValid(ent) then
            Status.Tick(ent, now)
        else
            Status.Tracked[ent] = nil
        end
    end
end)

-- ─── Dégâts reçus (boucliers / vulnérabilités) ──────────────────────────

hook.Add("EntityTakeDamage", "BlackClover.Status", function(target, dmg)
    if not target.bcStatuses then return end

    local mult = Status.GetMultiplier(target, "DamageTakenMult")
    if mult ~= 1 then dmg:ScaleDamage(mult) end
end)

-- ─── Nettoyage ──────────────────────────────────────────────────────────

hook.Add("PlayerDeath", "BlackClover.Status", function(ply) Status.Clear(ply) end)
hook.Add("BlackClover.CharacterUnloaded", "BlackClover.Status", function(ply) Status.Clear(ply) end)
hook.Add("BlackClover.PlayerSpawn", "BlackClover.Status", function(ply)
    ply.bcStatuses = {}
    Status.Tracked[ply] = nil
    Sync(ply)
end)
