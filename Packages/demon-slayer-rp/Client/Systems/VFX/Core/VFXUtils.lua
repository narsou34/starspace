--[[
    Demon Slayer RP - VFXUtils (client)
    ------------------------------------------------------------------
    Outils communs du système VFX :
      - couleurs lumineuses (les particules modèles "multiplient" la couleur :
        une valeur > 1 fait briller, cf. doc nanos world "Default Particles")
      - application typée des paramètres Niagara (Color, Float, Int, Vector)
      - niveau de détail selon la distance au joueur local
      - petites fonctions géométriques (arcs, rotations)

    Paramètres documentés des particules modèles du pack nanos-world :
      P_Ribbon               Color, SpawnRate, Mass, LifeTime, RibbonWidth, Material
      P_Beam                 BeamColor, BeamEnd, BeamWidth, BeamStartTangent, BeamEndTangent, JitterAmount, Material
      P_DirectionalBurst     Color, SpawnCount, VelocityStrengthMax, VelocityStrengthMin, Material
      P_OmnidirectionalBurst Color, SpawnCount, SphereRadius, VelocityStrengthMax, VelocityStrengthMin, Material
      P_Fountain             Color, SpawnRate, SphereRadius, VelocityStrengthMax/Min, SizeMax/Min, VelocityConeAngle, Material
      P_HangingParticulates  Color, BoxSize, SpawnRate, Material
]]

local U = {}
DS.VFXUtils = U

local TMath = DS.TechMath

-- Paramètres entiers (tous les autres nombres sont des Float)
local INT_PARAMS = { SpawnCount = true }

--- Couleur { r, g, b } (0..1) multipliée par `glow` (> 1 = lumineux).
function U.Color(rgb, glow)
    glow = glow or 1
    return Color(rgb[1] * glow, rgb[2] * glow, rgb[3] * glow, 1)
end

--- Applique une table de paramètres à une particule, avec le bon type pour chacun.
function U.ApplyParams(particle, params)
    if not (particle and params) then return end
    for name, value in pairs(params) do
        local kind = type(value)
        if kind == "number" then
            if INT_PARAMS[name] then
                pcall(particle.SetParameterInt, particle, name, math.floor(value + 0.5))
            else
                pcall(particle.SetParameterFloat, particle, name, value)
            end
        elseif kind == "boolean" then
            pcall(particle.SetParameterBool, particle, name, value)
        elseif kind == "string" then
            pcall(particle.SetParameterMaterial, particle, name, value)
        elseif kind == "table" or kind == "userdata" then
            if value.R ~= nil then
                pcall(particle.SetParameterColor, particle, name, value)
            elseif value.X ~= nil then
                pcall(particle.SetParameterVector, particle, name, value)
            end
        end
    end
end

--- Position de la caméra / du personnage local (pour le niveau de détail).
function U.LocalPosition()
    local player = Client.GetLocalPlayer()
    local character = player and player:GetControlledCharacter()
    if character and character:IsValid() then
        local loc = character:GetLocation()
        return loc.X, loc.Y, loc.Z
    end
    return nil
end

--[[
    Niveau de détail selon la distance au joueur local :
      1.0 (proche) -> 0.6 (moyen) -> 0.35 (loin)
    Sert à réduire le nombre de particules secondaires et le SpawnCount des
    gerbes pour les techniques lointaines.
]]
function U.Lod(x, y, z)
    local lx, ly, lz = U.LocalPosition()
    if not lx then return 1 end
    local dx, dy, dz = x - lx, y - ly, z - lz
    local d = math.sqrt(dx * dx + dy * dy + dz * dz)
    if d < 2500 then return 1 end
    if d < 5000 then return 0.6 end
    return 0.35
end

--- Points d'un arc de coupe autour d'un centre (repère : yaw du lanceur).
--- fromDeg / toDeg : angles relatifs à l'avant ; tilt : hauteur au début / à la fin.
function U.ArcPoints(cx, cy, cz, yaw, radius, fromDeg, toDeg, steps, upFrom, upTo)
    local points = {}
    for i = 0, steps do
        local t = i / steps
        local angle = math.rad(yaw + fromDeg + (toDeg - fromDeg) * t)
        points[#points + 1] = {
            cx + math.cos(angle) * radius,
            cy + math.sin(angle) * radius,
            cz + TMath.Lerp(upFrom or 0, upTo or 0, t),
        }
    end
    return points
end

function U.Distance(ax, ay, az, bx, by, bz)
    local dx, dy, dz = bx - ax, by - ay, bz - az
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

--- Raccourci de déclaration d'une couche : U.L("P_Smoke_03", 1.2, 2.0, { Up = 50, Priority = "detail" })
function U.L(asset, scale, life, extra)
    local layer = { Asset = "nanos-world::" .. asset, Scale = scale, Life = life }
    for k, v in pairs(extra or {}) do layer[k] = v end
    return layer
end

--- Raccourci de déclaration d'un son : U.S("A_Whoosh", 0.8, 1.2[, durée])
function U.S(asset, volume, pitch, life)
    return { Asset = "nanos-world::" .. asset, Volume = volume, Pitch = pitch, Life = life, FadeOut = life and 0.4 or nil }
end

return U
