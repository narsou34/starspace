--[[
    Demon Slayer RP - Pont vers le pack Niagara "demonslayer-vfx" (client)
    ------------------------------------------------------------------
    Quand l'Asset Pack Niagara (DemonSlayerVFX/, construit dans Unreal) est
    installé et que Config.Vfx.Pack.Enabled = true, chaque rôle d'effet
    (coupe, traînée de lame, impact, projectile, élan, zone, vague, tsunami,
    tornade, dragon, explosion, pics) joue le Niagara System du pack à la
    place des formes peintes, avec les paramètres utilisateur standard :

      Color, SecondaryColor (couleurs de l'élément), Scale, Intensity,
      Duration, Speed, SpawnScale (LOD), Width, Direction, EndPoint

    Table rôle -> système : Shared/Config/VfxPackCatalog.lua (générée par
    DemonSlayerVFX/Tools/vfx_catalog.py).

    API :
      VFX.Pack.Enabled()                       pack actif ?
      VFX.Pack.System(role, element)           nom du NS ou nil
      VFX.Pack.Play(role, element, x, y, z, opts)      -> Particle | nil
          opts : yaw, pitch, scale, duration (s), speed, width, direction {x,y,z},
                 endPoint {x,y,z}, life (durée de vie de l'entité), size ("Small".."Massive")
      VFX.Pack.Attach(role, element, actor, bone, seconds, opts) -> Particle | nil
]]

local VFX = DS.VFX
local U = DS.VFXUtils

local Pack = {}
VFX.Pack = Pack

local function cfg() return Config.Vfx.Pack or {} end

function Pack.Enabled()
    return cfg().Enabled == true and Config.VfxPackCatalog ~= nil
end

--- Nom du système du pack pour un rôle et un élément (repli : élément neutre).
function Pack.System(role, element)
    if not Pack.Enabled() then return nil end
    local roles = Config.VfxPackCatalog.Roles
    local id = element and element.Id or "neutral"
    local entry = roles[id] or roles.neutral
    return entry and entry[role] or nil
end

local function asset(system)
    return Config.VfxPackCatalog.PackId .. "::" .. system
end

-- Paramètres utilisateur communs à tous les systèmes du pack
local function userParams(element, opts)
    local c = cfg()
    local colors = element and element.Colors or {}
    local core = colors.Core or { 1, 1, 1 }
    local high = colors.Highlight or { 1, 1, 1 }
    local glow = (colors.Glow or 4) * 0.35 * (c.Intensity or 1)
    local lod = opts.lod or 1
    local params = {
        Color = Color(core[1] * glow, core[2] * glow, core[3] * glow, 1),
        SecondaryColor = Color(high[1] * glow * 1.5, high[2] * glow * 1.5, high[3] * glow * 1.5, 1),
        Scale = (opts.scale or 1) * (c.Scale or 1),
        Intensity = c.Intensity or 1,
        Duration = opts.duration or 1,
        Speed = opts.speed or 1,
        SpawnScale = math.max(0.2, lod),
        Width = opts.width or 30,
    }
    if opts.direction then params.Direction = Vector(opts.direction[1], opts.direction[2], opts.direction[3] or 0) end
    if opts.endPoint then params.EndPoint = Vector(opts.endPoint[1], opts.endPoint[2], opts.endPoint[3]) end
    return params
end

--- Joue le système du rôle à une position. Retourne la Particle (ou nil si pas de pack / pas de système).
function Pack.Play(role, element, x, y, z, opts)
    local system = Pack.System(role, element)
    if not system then return nil end
    opts = opts or {}
    local lod = opts.lod or U.Lod(x, y, z)
    opts.lod = lod
    return VFX.Spawn(asset(system), x, y, z, {
        yaw = opts.yaw, pitch = opts.pitch, roll = opts.roll, life = opts.life or 2.5, priority = opts.priority or "main",
        lod = lod, params = userParams(element, opts),
    })
end

--- Attache le système du rôle à un acteur (traînée de lame sur "hand_r", aura sur "pelvis"...).
function Pack.Attach(role, element, actor, bone, seconds, opts)
    local system = Pack.System(role, element)
    if not (system and actor and actor:IsValid()) then return nil end
    opts = opts or {}
    local loc = actor:GetLocation()
    opts.lod = opts.lod or U.Lod(loc.X, loc.Y, loc.Z)
    return VFX.Attach(asset(system), actor, bone or "", {
        life = seconds or 1, priority = opts.priority or "main", lod = opts.lod, params = userParams(element, opts),
    })
end

--- Impact du pack : système d'élément (Medium/Large) ou impacts génériques Small..Massive.
function Pack.Impact(element, size, x, y, z, yaw)
    if not Pack.Enabled() then return nil end
    local scale = ({ Small = 0.6, Medium = 1, Large = 1.5, Massive = 2.4 })[size] or 1
    local particle = Pack.Play("Impact", element, x, y, z, { yaw = yaw, scale = scale, life = 2 })
    if size == "Massive" or size == "Large" then
        local generic = Config.VfxPackCatalog.Impacts[size]
        if generic then
            VFX.Spawn(asset(generic), x, y, z, { yaw = yaw, life = 2.5, priority = "secondary",
                params = userParams(element, { scale = 1 }) })
        end
    end
    return particle
end

return Pack
