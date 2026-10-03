--[[
    Demon Slayer RP - Spawn par défaut (serveur) - TEMPORAIRE
    ------------------------------------------------------------------
    Donne un personnage aux joueurs pour pouvoir tester le gamemode dès la
    Phase 1. Sera remplacé par la création / sélection de personnage
    (Phase 4) : il suffira alors de passer Config.Spawn.Enabled à false.

    Évènement interne émis : "Spawn:CharacterReady" (session, character, "spawn" | "respawn")
]]

local Spawn = DS.Module("Spawn", { dependencies = { "PlayerManager" } })
DS.Spawn = Spawn

local Log = Spawn.Log
local cfg

local function pickSpawnPoint()
    local points = Server.GetMapSpawnPoints()
    if points and #points > 0 then
        local point = points[math.random(#points)]
        return point.location, point.rotation
    end
    local fallback = cfg.FallbackPoints[math.random(#cfg.FallbackPoints)]
    return fallback.location, fallback.rotation
end

--- Crée et possède un personnage pour la session (sauf si elle en contrôle déjà un).
function Spawn.SpawnFor(session)
    if not session:IsValid() then return nil end

    local current = session.player:GetControlledCharacter()
    if current and current:IsValid() then
        return current
    end

    local location, rotation = pickSpawnPoint()
    local character = Character(location, rotation, cfg.CharacterMesh)
    session.player:Possess(character)
    session.data.spawnCharacter = character

    Log:Debug("Personnage cree pour %s (#%s)", session.name, session.id)
    DS.Bus.Emit("Spawn:CharacterReady", session, character, "spawn")
    return character
end

local function onLeaving(session, reason)
    -- À l'arrêt du package, auto_cleanup détruit déjà les entités
    if reason == "shutdown" then return end

    local character = session.data.spawnCharacter
    if not (character and character:IsValid()) and session.player:IsValid() then
        character = session.player:GetControlledCharacter()
    end
    if character and character:IsValid() then
        character:Destroy()
    end
    session.data.spawnCharacter = nil
end

local function onCharacterDeath(character)
    local player = character:GetPlayer()
    if not player then return end -- PNJ
    local session = DS.Players.Get(player)
    if not session then return end

    local timer = Timer.SetTimeout(function()
        if not character:IsValid() then return end
        local location, rotation = pickSpawnPoint()
        character:Respawn(location, rotation)
        if session:IsValid() then
            DS.Bus.Emit("Spawn:CharacterReady", session, character, "respawn")
        end
    end, cfg.RespawnDelayMs)
    -- Le timer est annulé automatiquement si le personnage est détruit (déconnexion)
    Timer.Bind(timer, character)
end

function Spawn:Init()
    cfg = Config.Spawn
    assert(type(cfg.CharacterMesh) == "string", "Config.Spawn.CharacterMesh manquant")
    assert(type(cfg.FallbackPoints) == "table" and #cfg.FallbackPoints > 0,
        "Config.Spawn.FallbackPoints doit contenir au moins un point")
    if not cfg.Enabled then
        Log:Info("Spawn par defaut desactive (Config.Spawn.Enabled = false)")
        return
    end

    DS.Bus.On("Player:Ready", Spawn.SpawnFor)
    DS.Bus.On("Player:Leaving", onLeaving)
    Character.Subscribe("Death", onCharacterDeath)
end

return Spawn
