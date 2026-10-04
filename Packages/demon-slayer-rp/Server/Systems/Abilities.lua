--[[
    Demon Slayer RP - Techniques : Souffles & Arts démoniaques (serveur)
    ------------------------------------------------------------------
    Le client envoie seulement "UseSkill(emplacement)". Le serveur vérifie :
      faction + souffle/art attribués, personnage vivant, cooldown global et
      cooldown de la technique, ressource suffisante
    puis calcule LUI-MÊME les cibles (forme, portée, angle), les dégâts,
    la projection, les ralentissements et les bonus.

    Formes de zone :
      cone   : devant le lanceur, dans un angle (Angle) et une portée (Range)
      circle : tout autour du lanceur (Range = rayon)
      line   : rectangle devant le lanceur (Range x Width)
      dash   : le lanceur s'élance (Dash) + zone "line" sur sa trajectoire
      self   : aucun ennemi, uniquement Buff / soin sur soi

    Les effets visuels / sons sont joués côté client (Client/Systems/Effects.lua) :
    le serveur n'envoie que "SkillFx" aux joueurs proches.
]]

local Abilities = DS.Module("Abilities", {
    dependencies = { "PlayerManager", "Network", "Factions", "Resources" },
})
DS.Abilities = Abilities

local Log = Abilities.Log
local Utils = DS.Utils

local FX_RADIUS = 6000          -- distance max à laquelle les joueurs voient l'effet
local DUMMY_MESH = "nanos-world::SK_Mannequin"

local slowed = {}               -- [Character] = { multiplier, untilMs }
local dummies = {}              -- [Character] = true

-- ===========================================================================
-- Vitesse : passif d'art x buff actif x ralentissement subi
-- ===========================================================================

local function sessionOf(character)
    local player = character:GetPlayer()
    return player and DS.Players.Get(player) or nil
end

local function passiveOf(session)
    local state = DS.Factions.State(session)
    if state.kind ~= "art" or not state.setId then return nil end
    local set = DS.Catalog.GetSet("art", state.setId)
    return set and set.Passive
end

local function activeBuff(session, now)
    local buff = session.data.buff
    if buff and buff.untilMs > now then return buff end
    return nil
end

local function refreshSpeed(character, now)
    if not (character and character:IsValid()) then return end
    -- Immobilisé (prison d'eau...) : la vitesse reste nulle jusqu'à la libération
    if DS.Status and DS.Status.IsRooted(character) then
        character:SetSpeedMultiplier(0)
        return
    end
    local multiplier = 1
    local session = sessionOf(character)
    if session then
        local passive = passiveOf(session)
        if passive and passive.SpeedMultiplier then multiplier = multiplier * passive.SpeedMultiplier end
        local buff = activeBuff(session, now)
        if buff and buff.speed then multiplier = multiplier * buff.speed end
    end
    local slow = slowed[character]
    if slow and slow.untilMs > now then multiplier = multiplier * slow.multiplier end
    character:SetSpeedMultiplier(multiplier)
end

-- ===========================================================================
-- Ciblage
-- ===========================================================================

--- Direction horizontale visée par le personnage (x, y normalisés).
local function forwardOf(character)
    local ok, rotation = pcall(character.GetControlRotation, character)
    if not ok or not rotation then rotation = character:GetRotation() end
    local yaw = math.rad(rotation.Yaw)
    return math.cos(yaw), math.sin(yaw)
end

local function isEnemy(casterSession, target)
    if dummies[target] then return true end
    local targetSession = sessionOf(target)
    if not targetSession then return true end -- PNJ
    if Config.Abilities.FriendlyFire then return true end
    local a, b = DS.Factions.Get(casterSession), DS.Factions.Get(targetSession)
    return a == nil or b == nil or a ~= b
end

local function findTargets(session, caster, origin, fx, fy, tech)
    local shape = tech.Shape
    local range = tech.Range
    local halfWidth = tech.Width / 2
    local cosHalfAngle = math.cos(math.rad(tech.Angle / 2))
    local found = {}

    for _, target in pairs(Character.GetPairs()) do
        if target ~= caster and target:IsValid() and not target:IsDead() and isEnemy(session, target) then
            local location = target:GetLocation()
            local dx, dy, dz = location.X - origin.X, location.Y - origin.Y, location.Z - origin.Z
            if math.abs(dz) <= tech.Height then
                local dist = math.sqrt(dx * dx + dy * dy)
                local hit = false
                if shape == "circle" then
                    hit = dist <= range
                elseif shape == "cone" then
                    hit = dist <= range and (dist < 60 or (dx * fx + dy * fy) / dist >= cosHalfAngle)
                elseif shape == "line" or shape == "dash" then
                    local along = dx * fx + dy * fy
                    local lateral = math.abs(dx * fy - dy * fx)
                    hit = along >= -50 and along <= range and lateral <= halfWidth
                end
                if hit then
                    found[#found + 1] = { character = target, dist = dist, dx = dx, dy = dy }
                end
            end
        end
    end

    table.sort(found, function(a, b) return a.dist < b.dist end)
    while #found > tech.MaxTargets do table.remove(found) end
    return found
end

-- ===========================================================================
-- Application des effets
-- ===========================================================================

local function damageMultiplier(session, now)
    local multiplier = 1
    local passive = passiveOf(session)
    if passive and passive.DamageMultiplier then multiplier = multiplier * passive.DamageMultiplier end
    local buff = activeBuff(session, now)
    if buff and buff.damage then multiplier = multiplier * buff.damage end
    return multiplier
end

local function applyHit(session, caster, tech, hit, fx, fy, now)
    local target = hit.character
    local targetSession = sessionOf(target)
    local targetIsDemon = targetSession and DS.Factions.Get(targetSession) == "demons"
    local casterIsSlayer = DS.Factions.Get(session) == "slayers"

    -- Direction de projection : du lanceur vers la cible (ou devant si collé)
    local dirX, dirY = fx, fy
    if hit.dist > 1 then dirX, dirY = hit.dx / hit.dist, hit.dy / hit.dist end

    local damage = tech.Damage * damageMultiplier(session, now)
    if targetIsDemon and casterIsSlayer and tech.BonusVsDemons then
        damage = damage * tech.BonusVsDemons
    end
    damage = math.floor(damage + 0.5)
    if damage > 0 then
        target:ApplyDamage(damage, "", DamageType.Melee, Vector(dirX, dirY, 0), session.player, caster)
    end

    if tech.Knockback > 0 and target:IsValid() and not target:IsDead() then
        target:AddImpulse(Vector(dirX * tech.Knockback, dirY * tech.Knockback, tech.Knockback * 0.35), true)
    end

    if tech.Slow and target:IsValid() then
        slowed[target] = { multiplier = tech.Slow.Multiplier, untilMs = now + tech.Slow.DurationMs }
        refreshSpeed(target, now)
    end

    -- Lame Nichirin / poison : bloque la régénération du démon touché
    if targetIsDemon and casterIsSlayer and tech.BlockRegenMs then
        targetSession.data.noRegenUntil = math.max(targetSession.data.noRegenUntil or 0, now + tech.BlockRegenMs)
    end
end

local function applyBuff(session, caster, buff, now)
    if buff.Heal and buff.Heal > 0 then
        caster:SetHealth(math.min(caster:GetMaxHealth(), caster:GetHealth() + buff.Heal))
    end
    if buff.DurationMs and buff.DurationMs > 0 then
        session.data.buff = {
            speed = buff.SpeedMultiplier,
            damage = buff.DamageMultiplier,
            untilMs = now + buff.DurationMs,
        }
        refreshSpeed(caster, now)
    end
end

local function execute(session, caster, tech, now)
    local origin = caster:GetLocation()
    local fx, fy = forwardOf(caster)

    local slot = AnimationSlotType[tech.AnimationSlot] or AnimationSlotType.UpperBody
    caster:PlayAnimation(tech.Animation, slot)

    -- Cibles calculées AVANT l'élan, depuis la position de départ
    local hits = {}
    local needsTargets = tech.Shape ~= "self" and tech.Range > 0
        and (tech.Damage > 0 or tech.Knockback > 0 or tech.Slow ~= nil)
    if needsTargets then
        hits = findTargets(session, caster, origin, fx, fy, tech)
    end

    if tech.Dash > 0 then
        caster:AddImpulse(Vector(fx * tech.Dash, fy * tech.Dash, 200), true)
    end

    for _, hit in ipairs(hits) do
        applyHit(session, caster, tech, hit, fx, fy, now)
    end

    if tech.Buff then
        applyBuff(session, caster, tech.Buff, now)
    end

    DS.Net.BroadcastInRadius(origin, FX_RADIUS, "SkillFx", caster, tech.Kind, tech.SetId, tech.Slot, #hits)
    Log:Info("%s (#%s) utilise %s - %s cible(s) touchee(s)", session.name, session.id, tech.Name, #hits)
    DS.Bus.Emit("Abilities:Used", session, tech, #hits)
    return #hits
end

-- ===========================================================================
-- Requête du client
-- ===========================================================================

-- Refus expliqué au joueur et dans la console (diagnostic)
local function refuse(session, slot, reason, notify)
    Log:Info("Technique %s refusee pour %s (#%s) : %s", slot, session.name, session.id, reason)
    if notify then session:Notify(reason, "warning", 3) end
    return false, reason
end

--- Tente d'utiliser la technique de l'emplacement `slot`. Retourne true ou false, raison.
function Abilities.Use(session, slot)
    local state = DS.Factions.State(session)
    if not state.faction then
        return refuse(session, slot, "Vous n'avez pas encore de faction.", true)
    end
    if not state.setId then
        return refuse(session, slot, "Aucun " .. DS.Catalog.KindLabel(state.kind):lower() .. " attribue.", true)
    end

    local tech = DS.Catalog.GetTechnique(state.kind, state.setId, slot)
    if not tech then return refuse(session, slot, "aucune technique a cet emplacement", false) end

    -- Prérequis (vérifiés uniquement côté serveur)
    local requirements = tech.Requirements
    if requirements then
        if requirements.Level and DS.Factions.GetLevel(session) < requirements.Level then
            return refuse(session, slot, tech.Name .. " : niveau " .. requirements.Level .. " requis.", true)
        end
        if requirements.Permission and not session:HasPermission(requirements.Permission) then
            return refuse(session, slot, tech.Name .. " : technique non debloquee.", true)
        end
    end
    if Abilities.IsBusy(session) then
        return refuse(session, slot, "technique deja en cours", false)
    end

    local caster = session:GetCharacter()
    if not (caster and caster:IsValid()) then
        return refuse(session, slot, "Vous n'avez pas de personnage.", true)
    end
    if caster:IsDead() then return refuse(session, slot, "personnage mort", false) end

    local now = Utils.NowMs()
    local cooldowns = session.data.cooldowns or {}
    session.data.cooldowns = cooldowns
    -- Cooldown actif : refus sans sanction (peut arriver avec du lag)
    if (cooldowns.global or 0) > now or (cooldowns[slot] or 0) > now then
        return refuse(session, slot, "recharge en cours", false)
    end

    if not DS.Resources.TrySpend(session, tech.Cost) then
        local faction = DS.Catalog.GetFaction(state.faction)
        return refuse(session, slot, "Pas assez de " .. Config.Resources[faction.Resource].Label:lower() .. ".", true)
    end

    cooldowns.global = now + Config.Abilities.GlobalCooldownMs
    cooldowns[slot] = now + tech.CooldownMs
    session:Send("SkillCooldown", slot, tech.CooldownMs)

    if tech.Script then
        -- Technique scriptée : chronologie complète gérée par le moteur
        local ok, err = DS.Techniques.Run(session, caster, tech)
        if not ok then
            Log:Error("Technique scriptee '%s' en erreur : %s", tech.Script, tostring(err))
            return false, "erreur interne"
        end
        return true, 0
    end
    local hits = execute(session, caster, tech, now)
    return true, hits
end

local function onUseSkill(session, slot)
    Abilities.Use(session, slot)
end

-- ===========================================================================
-- Tick : expiration des buffs et ralentissements
-- ===========================================================================

local function onTick(now)
    for character, slow in pairs(slowed) do
        if not character:IsValid() then
            slowed[character] = nil
        elseif slow.untilMs <= now then
            slowed[character] = nil
            refreshSpeed(character, now)
        end
    end
    for _, session in ipairs(DS.Players.GetLoaded()) do
        local buff = session.data.buff
        if buff and buff.untilMs <= now then
            session.data.buff = nil
            refreshSpeed(session:GetCharacter(), now)
        end
    end
    for character in pairs(dummies) do
        if not character:IsValid() then dummies[character] = nil end
    end
end

-- ===========================================================================
-- API utilisée par le moteur de techniques scriptées
-- ===========================================================================

Abilities.SessionOf = sessionOf
Abilities.ForwardOf = forwardOf
Abilities.IsEnemy = isEnemy
Abilities.DamageMultiplier = damageMultiplier

--- Une technique scriptée bloquante (préparation d'un ultime...) est-elle en cours ?
function Abilities.IsBusy(session)
    return (session.data.busyUntil or 0) > Utils.NowMs()
end

function Abilities.ApplySlow(target, multiplier, durationMs)
    local now = Utils.NowMs()
    slowed[target] = { multiplier = multiplier, untilMs = now + durationMs }
    refreshSpeed(target, now)
end

function Abilities.ApplyBuff(session, buff)
    local caster = session:GetCharacter()
    if caster and caster:IsValid() then
        applyBuff(session, caster, buff, Utils.NowMs())
    end
end

function Abilities.RefreshSpeed(character)
    refreshSpeed(character, Utils.NowMs())
end

-- ===========================================================================
-- Mannequins d'entraînement
-- ===========================================================================

function Abilities.CountDummies()
    local n = 0
    for character in pairs(dummies) do
        if character:IsValid() then n = n + 1 end
    end
    return n
end

--- Fait apparaître un mannequin devant le joueur. Retourne le personnage ou nil, erreur.
function Abilities.SpawnDummy(session)
    if Abilities.CountDummies() >= Config.Abilities.MaxTrainingDummies then
        return nil, "nombre maximal de mannequins atteint (" .. Config.Abilities.MaxTrainingDummies .. ")"
    end
    local caster = session:GetCharacter()
    if not (caster and caster:IsValid()) then return nil, "vous n'avez pas de personnage" end

    local origin = caster:GetLocation()
    local fx, fy = forwardOf(caster)
    local location = Vector(origin.X + fx * 350, origin.Y + fy * 350, origin.Z)
    local rotation = Rotator(0, math.deg(math.atan(-fy, -fx)), 0)

    local dummy = Character(location, rotation, DUMMY_MESH)
    dummy:SetMaxHealth(Config.Abilities.TrainingDummyHealth)
    dummy:SetHealth(Config.Abilities.TrainingDummyHealth)
    dummies[dummy] = true
    return dummy
end

function Abilities.ClearDummies()
    local n = 0
    for character in pairs(dummies) do
        if character:IsValid() then
            character:Destroy()
            n = n + 1
        end
    end
    dummies = {}
    return n
end

function Abilities.Heal(session)
    local character = session:GetCharacter()
    if character and character:IsValid() and not character:IsDead() then
        character:SetHealth(character:GetMaxHealth())
    end
    session.data.noRegenUntil = 0
    DS.Resources.Refill(session)
end

-- ===========================================================================
-- Cycle de vie
-- ===========================================================================

function Abilities:Init()
    DS.Net.Handle("UseSkill", onUseSkill)
    DS.Bus.On("RP:Tick", onTick)

    -- Changement de faction / de souffle : on remet les compteurs à zéro
    local function reset(session)
        session.data.cooldowns = {}
        session.data.buff = nil
        session.data.busyUntil = 0
        refreshSpeed(session:GetCharacter(), Utils.NowMs())
    end
    DS.Bus.On("RP:FactionChanged", reset)
    DS.Bus.On("RP:SetChanged", reset)
    DS.Bus.On("Spawn:CharacterReady", function(session, character)
        session.data.buff = nil
        refreshSpeed(character, Utils.NowMs())
    end)

    -- Mannequin mort : disparaît après 3 s
    Character.Subscribe("Death", function(character)
        if not dummies[character] then return end
        local timer = Timer.SetTimeout(function()
            if character:IsValid() then character:Destroy() end
        end, 3000)
        Timer.Bind(timer, character)
    end)

    local breathing, arts = #DS.Catalog.ListSets("breathing"), #DS.Catalog.ListSets("art")
    Log:Info("%s souffles et %s arts demoniaques charges", breathing, arts)
end

return Abilities
