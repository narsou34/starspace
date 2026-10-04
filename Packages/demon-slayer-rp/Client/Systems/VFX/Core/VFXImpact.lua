--[[
    Demon Slayer RP - VFX_Impact (client)
    ------------------------------------------------------------------
    VFX.Impact(element, size, x, y, z, yaw)
      size : "Small" | "Medium" | "Large" | "Massive"

    Recette commune, puis couches propres à l'élément (element.Impact) :
      Small   flash + cœur de l'élément + gerbe colorée
      Medium  + onde au sol + explosion de particules colorées
      Large   + poussière / brume + couches secondaires + son puissant
      Massive + anneau de cœurs autour du point, ondes multiples, rémanence,
                "coup" de caméra si le joueur local est proche
    La rémanence (Linger) disparaît progressivement : dissipation.

    Lisibilité / performance : quand beaucoup d'impacts tombent en même temps
    (combo sur un groupe, zone qui touche 8 cibles...), les impacts suivants
    sont rétrogradés d'une ou deux tailles. Le premier coup reste spectaculaire,
    les autres restent visibles sans saturer l'écran ni le budget.
]]

local VFX = DS.VFX
local U = DS.VFXUtils

local SIZES = {
    Small   = { scale = 0.6, level = 1, count = 0.6 },
    Medium  = { scale = 1.0, level = 2, count = 1.0 },
    Large   = { scale = 1.6, level = 3, count = 1.5 },
    Massive = { scale = 2.6, level = 4, count = 2.2 },
}

local BY_LEVEL = { "Small", "Medium", "Large", "Massive" }
local WINDOW_MS = 250
local recent = {}

--- Nombre d'impacts créés pendant la dernière fenêtre (WINDOW_MS).
local function pressure(now)
    local kept = {}
    for _, t in ipairs(recent) do
        if now - t < WINDOW_MS then kept[#kept + 1] = t end
    end
    recent = kept
    return #kept
end

function VFX.Impact(element, size, x, y, z, yaw)
    local spec = SIZES[size] or SIZES.Medium
    local now = DS.Utils.NowMs()
    local crowd = pressure(now)
    recent[#recent + 1] = now
    if crowd >= 2 then
        local drop = crowd >= 5 and 2 or 1
        spec = SIZES[BY_LEVEL[math.max(1, spec.level - drop)]]
    end
    local impact = element.Impact or {}
    local scale = spec.scale
    local lod = U.Lod(x, y, z)
    yaw = yaw or 0

    -- 0. Forme anime : étoile d'impact + éclaboussure de l'élément + onde au sol
    local toon = VFX.ToonOf(element)
    VFX.Toon.Sprite(toon.Star, { x = x, y = y, z = z + 20, size = 90 * scale, scale = 0.5, grow = 1.6,
        color = toon.Tint, glow = toon.Glow * 1.4, life = 0.22, fadeIn = 0.01, fadeOut = 0.14, priority = "main", lod = lod })
    VFX.Toon.Sprite(toon.Splash, { x = x, y = y, z = z + 30 * scale, size = 160 * scale, scale = 0.45, grow = 1.25,
        color = toon.White, glow = toon.Glow, life = 0.45 + 0.1 * spec.level, fadeIn = 0.02, priority = "main", lod = lod })
    if spec.level >= 2 then
        VFX.Toon.Ground(toon.Ring, x, y, z - 85, { size = 260 * scale, color = toon.Tint, glow = toon.Glow,
            life = 0.5, scale = 0.25, grow = 1.3, lod = lod })
    end
    if spec.level >= 3 then
        VFX.Toon.Scatter(toon.Scatter, x, y, z, { count = 4 + spec.level * 2, spread = 160 * scale, size = 45 * scale,
            color = toon.White, glow = toon.Glow, lod = lod })
    end

    -- 1. Flash + cœur
    VFX.Burst.Flash(element, x, y, z, scale * 0.8)
    VFX.Layers(impact.Core, x, y, z, yaw, { scale = scale, priority = "main", lod = lod })
    VFX.Burst.Spray(element, x, y, z + 20, yaw, { count = 25 * spec.count, speed = 550 * scale, lod = lod, priority = "detail" })

    -- 2. Onde + explosion colorée
    if spec.level >= 2 then
        VFX.Burst.Ring(element, x, y, z - 70, scale)
        VFX.Burst.Sphere(element, x, y, z, { count = 60 * spec.count, speed = 500 * scale, radius = 20 * scale, lod = lod })
    end

    -- 3. Poussière / brume + secondaires
    if spec.level >= 3 then
        VFX.Layers(impact.Dust, x, y, z - 50, yaw, { scale = scale * 0.8, priority = "secondary", lod = lod })
        VFX.Layers(impact.Secondary, x, y, z, yaw, { scale = scale, priority = "secondary", lod = lod })
    end

    -- 4. Massif : anneau de cœurs, ondes multiples
    if spec.level >= 4 then
        local count = 6
        for i = 1, count do
            local angle = (i / count) * 2 * math.pi
            local r = 220 * scale * 0.6
            VFX.Layers(impact.Core, x + math.cos(angle) * r, y + math.sin(angle) * r, z - 30, yaw,
                { scale = scale * 0.5, priority = "detail", lod = lod })
        end
        Timer.SetTimeout(function() VFX.Burst.Ring(element, x, y, z - 70, scale * 1.4) end, 120)
        Timer.SetTimeout(function() VFX.Burst.Ring(element, x, y, z - 70, scale * 1.9) end, 260)
        local lx, ly, lz = U.LocalPosition()
        if lx and U.Distance(lx, ly, lz, x, y, z) < 2500 then VFX.Camera.Kick(8) end
    end

    -- Dissipation progressive
    if spec.level >= 2 then
        VFX.Layers(impact.Linger, x, y, z - 40, yaw, { scale = scale * 0.8, priority = "detail", lod = lod })
    end

    local sounds = element.Sounds or {}
    VFX.Sound.Set(sounds.Impact, x, y, z, { volume = math.min(1.2, 0.6 + scale * 0.25) })
    if spec.level >= 3 then VFX.Sound.Set(sounds.Big, x, y, z, { falloff = 7000 }) end
end

--- Choix automatique de la taille selon les dégâts.
function VFX.ImpactSizeFor(damage)
    if damage >= 45 then return "Massive" end
    if damage >= 25 then return "Large" end
    if damage >= 12 then return "Medium" end
    return "Small"
end

return SIZES
