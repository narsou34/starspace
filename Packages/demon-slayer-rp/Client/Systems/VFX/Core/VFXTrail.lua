--[[
    Demon Slayer RP - VFX_Trail (client)
    ------------------------------------------------------------------
    Traînées colorées basées sur P_Ribbon (particule modèle paramétrable :
    Color, RibbonWidth, LifeTime, SpawnRate). Un ruban laisse une trace
    PARTOUT où il passe : attaché à la main, il dessine le mouvement réel
    de la lame ; déplacé le long d'un arc, il dessine la coupe.

      VFX.Trail.Attach(element, actor, bone, opts)  traînée sur une lame / un membre / un projectile
      VFX.Trail.Blade(element, actor, seconds)      traînée de katana standard de l'élément
      VFX.Trail.Path(element, points, seconds, opts) traînée qui parcourt une suite de points
      VFX.Trail.Ribbon(element, x, y, z, opts)      ruban "porteur" à déplacer soi-même

    opts : width, trailLife (durée de vie de la traînée laissée), duration
           (durée de vie de l'entité), color ("Core" | "Accent" | "Highlight"),
           glow (multiplicateur), spawnRate, material, core (bool : ajoute un
           fil blanc lumineux au centre), priority
]]

local VFX = DS.VFX

local Trail = {}
VFX.Trail = Trail

local RIBBON = "nanos-world::P_Ribbon"

local function ribbonParams(element, opts)
    local spec = element.Trail or {}
    local params = {
        Color = VFX.Glow(element, opts.color or "Core", opts.glow),
        RibbonWidth = opts.width or spec.Width or 20,
        LifeTime = opts.trailLife or spec.Life or 0.35,
        SpawnRate = opts.spawnRate or 240,
    }
    if opts.material or spec.Material then params.Material = opts.material or spec.Material end
    return params
end

--- Ruban "porteur" à une position (à déplacer avec VFX.MoveTo / FollowPath).
function Trail.Ribbon(element, x, y, z, opts)
    opts = opts or {}
    return VFX.Spawn(RIBBON, x, y, z, {
        life = opts.duration or 1, priority = opts.priority or "main",
        params = ribbonParams(element, opts), lod = opts.lod,
    })
end

--- Traînée attachée à un acteur (os optionnel). Ajoute le fil central et les couches de l'élément.
function Trail.Attach(element, actor, bone, opts)
    opts = opts or {}
    local duration = opts.duration or 0.6
    local main = VFX.Attach(RIBBON, actor, bone or "", {
        life = duration, priority = opts.priority or "main", params = ribbonParams(element, opts),
    })
    if opts.core ~= false then
        local spec = element.Trail or {}
        VFX.Attach(RIBBON, actor, bone or "", {
            life = duration, priority = "secondary",
            params = ribbonParams(element, {
                color = "Highlight", glow = 1.5, width = spec.CoreWidth or ((opts.width or spec.Width or 20) * 0.3),
                trailLife = (opts.trailLife or spec.Life or 0.35) * 0.6, spawnRate = opts.spawnRate,
            }),
        })
    end
    for _, layer in ipairs((element.Trail and element.Trail.Layers) or {}) do
        VFX.Attach(layer.Asset, actor, bone or "", {
            life = duration, scale = layer.Scale, priority = layer.Priority or "detail", params = layer.Params,
        })
    end
    return main
end

--- Traînée standard du katana (main droite) pour un élément.
function Trail.Blade(element, actor, seconds)
    -- Pack Niagara : traînée élémentaire attachée au katana
    local packed = VFX.Pack and VFX.Pack.Attach("Trail", element, actor, "hand_r", (seconds or 0.6) + 0.3)
    if packed then return packed end
    return Trail.Attach(element, actor, "hand_r", { duration = seconds or 0.6 })
end

--- Traînée qui parcourt `points` ({ {x,y,z}, ... }) en `seconds`, avec fil central lumineux.
function Trail.Path(element, points, seconds, opts)
    opts = opts or {}
    if #points < 2 then return nil end
    local first = points[1]
    local life = seconds + (opts.trailLife or (element.Trail and element.Trail.Life) or 0.35) + 0.2
    local carrier = Trail.Ribbon(element, first[1], first[2], first[3], {
        duration = life, width = opts.width, trailLife = opts.trailLife, color = opts.color,
        glow = opts.glow, priority = opts.priority, lod = opts.lod,
    })
    VFX.FollowPath(carrier, points, seconds)
    if opts.core ~= false then
        local spec = element.Trail or {}
        local core = Trail.Ribbon(element, first[1], first[2], first[3], {
            duration = life, color = "Highlight", glow = 1.5, priority = "secondary", lod = opts.lod,
            width = (opts.width or spec.Width or 20) * 0.3, trailLife = (opts.trailLife or spec.Life or 0.35) * 0.6,
        })
        VFX.FollowPath(core, points, seconds)
    end
    return carrier
end

return Trail
