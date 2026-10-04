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

--- Rétablit immédiatement l'état normal (réapparition, changement de faction...).
function Status.Clear(character)
    if rooted[character] then releaseRoot(character) end
    if invulnerable[character] then releaseInvulnerable(character) end
end

return Status
