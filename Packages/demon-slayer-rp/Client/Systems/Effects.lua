--[[
    Demon Slayer RP - Effets visuels et sonores des techniques (client)
    ------------------------------------------------------------------
    Séparé de la logique de jeu : le serveur envoie seulement
    "SkillFx(lanceur, type, souffle/art, emplacement, nb de cibles touchées)".
    Particule, son et durée viennent de la configuration de la technique
    (Effect, Sound, EffectDuration, EffectOffset) : changer un effet ne
    demande aucune modification du code.

    Les entités créées ici (Particle, Sound) n'existent que pour ce joueur.
]]

local Effects = DS.Module("Effects", { dependencies = { "Network" } })
DS.Effects = Effects

local Log = Effects.Log

local function spawnParticle(asset, location, rotation, duration)
    if not asset or asset == "" then return end
    local ok, particle = pcall(Particle, location, rotation, asset, true, true)
    if ok and particle then
        pcall(particle.SetLifeSpan, particle, duration)
    else
        Log:Debug("Particule impossible : %s", tostring(asset))
    end
end

local function playSound(asset, location)
    if not asset or asset == "" then return end
    local ok = pcall(Sound, location, asset, false, true, SoundType.SFX, 1.0, 1.0)
    if not ok then
        Log:Debug("Son impossible : %s", tostring(asset))
    end
end

--- Joue l'effet d'une technique à partir de la position du lanceur.
function Effects.PlayTechnique(caster, tech, hits)
    if not (caster and caster:IsValid()) then return end
    local origin = caster:GetLocation()
    local yaw = caster:GetRotation().Yaw
    local rad = math.rad(yaw)
    local offset = tech.EffectOffset or 0
    local location = Vector(origin.X + math.cos(rad) * offset, origin.Y + math.sin(rad) * offset, origin.Z)

    spawnParticle(tech.Effect, location, Rotator(0, yaw, 0), tech.EffectDuration or 1.5)
    playSound(tech.Sound, location)
    if hits > 0 then
        playSound("nanos-world::A_Flesh_Impact_MS", location)
    end
end

function Effects:Init()
    DS.Net.On("SkillFx", function(caster, kind, setId, slot, hits)
        local tech = DS.Catalog.GetTechnique(kind, setId, slot)
        if tech then
            Effects.PlayTechnique(caster, tech, hits)
        end
    end)
end

return Effects
