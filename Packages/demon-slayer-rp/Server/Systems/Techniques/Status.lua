--[[
    Demon Slayer RP - États de contrôle (serveur)
    ------------------------------------------------------------------
    Effets temporaires appliqués aux personnages, toujours rétablis :
      Root(character, ms, floatLift)  immobilise (et fait flotter si floatLift)
      Invulnerable(character, ms)     ignore tous les dégâts

    Un nouvel effet prolonge l'effet en cours au lieu de l'écraser.
    Les minuteries sont liées au personnage : s'il est détruit, rien ne reste.
    Clear(character) rétablit tout immédiatement (réapparition).
]]

local Status = {}
DS.Status = Status

local Utils = DS.Utils

local rooted = {}       -- [Character] = untilMs
local invulnerable = {} -- [Character] = untilMs

local function releaseRoot(character)
    rooted[character] = nil
    if not character:IsValid() then return end
    character:SetInputEnabled(true)
    character:SetGravityScale(1)
    DS.Abilities.RefreshSpeed(character)
end

local function releaseInvulnerable(character)
    invulnerable[character] = nil
    if character:IsValid() then
        character:SetInvulnerable(false)
    end
end

local function schedule(store, character, ms, release)
    local now = Utils.NowMs()
    local untilMs = math.max(store[character] or 0, now + ms)
    store[character] = untilMs
    local timer = Timer.SetTimeout(function()
        if store[character] and Utils.NowMs() >= store[character] - 5 then
            release(character)
        end
    end, untilMs - now)
    Timer.Bind(timer, character)
end

function Status.Root(character, ms, floatLift)
    if not (character and character:IsValid()) then return end
    character:SetInputEnabled(false)
    character:StopMovement(true)
    character:SetSpeedMultiplier(0)
    if floatLift and floatLift > 0 then
        character:SetGravityScale(0)
        character:AddImpulse(Vector(0, 0, floatLift), true)
    end
    schedule(rooted, character, ms, releaseRoot)
end

function Status.IsRooted(character)
    return (rooted[character] or 0) > Utils.NowMs()
end

function Status.Invulnerable(character, ms)
    if not (character and character:IsValid()) then return end
    character:SetInvulnerable(true)
    schedule(invulnerable, character, ms, releaseInvulnerable)
end

-- ---------------------------------------------------------------------------
-- Poison (Souffle de l'Insecte...) : dégâts périodiques, un seul poison par
-- cible (le plus fort est gardé, la durée est prolongée).
-- ---------------------------------------------------------------------------
local poisoned = {} -- [Character] = { damage, untilMs, player, causer, timer }

function Status.Poison(character, damage, tickMs, durationMs, player, causer)
    if not (character and character:IsValid()) or character:IsDead() then return end
    local now = Utils.NowMs()
    local current = poisoned[character]
    if current then
        current.damage = math.max(current.damage, damage)
        current.untilMs = math.max(current.untilMs, now + durationMs)
        return
    end
    local state = { damage = damage, untilMs = now + durationMs, player = player, causer = causer }
    poisoned[character] = state
    state.timer = Timer.SetInterval(function()
        if not character:IsValid() or character:IsDead() or Utils.NowMs() > state.untilMs then
            poisoned[character] = nil
            return false
        end
        local instigator = (state.player and state.player:IsValid()) and state.player or nil
        local source = (state.causer and state.causer:IsValid()) and state.causer or nil
        character:ApplyDamage(math.floor(state.damage + 0.5), "", DamageType.Unknown, Vector(0, 0, 0), instigator, source)
    end, tickMs)
    Timer.Bind(state.timer, character)
end

function Status.IsPoisoned(character)
    return poisoned[character] ~= nil
end

--- Rétablit immédiatement l'état normal (réapparition, changement de faction...).
function Status.Clear(character)
    if rooted[character] then releaseRoot(character) end
    if invulnerable[character] then releaseInvulnerable(character) end
    local poison = poisoned[character]
    if poison then
        poisoned[character] = nil
        if poison.timer then Timer.ClearInterval(poison.timer) end
    end
end

return Status
