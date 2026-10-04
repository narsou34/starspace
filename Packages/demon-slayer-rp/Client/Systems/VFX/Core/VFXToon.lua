--[[
    Demon Slayer RP - VFX "anime" : textures peintes sur des formes (client)
    ------------------------------------------------------------------
    Les particules du pack par défaut sont génériques (étincelles, fumée).
    Pour obtenir le style des souffles de l'anime, la FORME PRINCIPALE de
    chaque technique est une texture peinte (Client/Textures/*.png, générée
    par tools/gen_textures.py) affichée sur :
      - une carte plane 3D (SM_Plane)  : croissants de coupe, vagues, spirales
        au sol, anneaux, bandes de tornade (orientées dans l'espace)
      - un panneau face caméra (Billboard) : impacts, éclaboussures, boules de
        feu, éclairs, pétales, nuages

    Matériau : nanos-world::M_Default_Translucent_Unlit (documenté) :
      Texture (image), Tint (couleur, > 1 = lumineux / bloom), Opacity (0..1,
      vaut 0 par défaut : toujours la régler).

    API :
      Toon.Card(texture, opts)    carte plane orientée
        opts : x, y, z ; axes forward = {x,y,z} (droite de l'image) et up = {x,y,z}
               (haut de l'image) ; size (cm), aspect (hauteur/largeur),
               color {r,g,b}, glow, alpha, life (s), fadeIn, fadeOut,
               grow (échelle finale), spin (degrés/s autour de la normale),
               sweep (degrés : la carte tourne de -sweep à 0 au début),
               sweepTime, moveTo {x,y,z}, follow (acteur), priority, lod
      Toon.Sprite(texture, opts)  panneau face caméra : x, y, z, size, color,
               glow, alpha, life, fadeIn, fadeOut, grow, moveTo, follow,
               rise (cm/s), priority, lod
      Toon.Count()                éléments affichés
      Toon.Preload()              charge toutes les textures une fois (évite
                                  les saccades au premier lancement)

    Performance : réserve d'entités réutilisées (pool), plafond
    Config.Vfx.MaxToon, une seule boucle d'animation (33 ms) active seulement
    quand des éléments sont affichés, rien n'est créé au-delà de MaxDistance.
]]

local VFX = DS.VFX
local U = DS.VFXUtils

local Toon = {}
VFX.Toon = Toon

local PACKAGE = "demon-slayer-rp"
local MATERIAL = "nanos-world::M_Default_Translucent_Unlit"
local PLANE = "nanos-world::SM_Plane"
local PLANE_SIZE = 100       -- SM_Plane mesure 100 x 100 cm
local TICK_MS = 33
local HIDDEN = Vector(0, 0, -100000)

-- Toutes les textures livrées (Client/Textures/<nom>.png)
Toon.TEXTURES = {
    "Slash_Water", "Slash_Flame", "Slash_Sun", "Slash_Thunder", "Slash_Wind", "Slash_Mist",
    "Slash_Ice", "Slash_Blood", "Slash_Shadow", "Slash_Flower", "Slash_Sound", "Slash_Love",
    "Slash_Insect", "Slash_Serpent", "Slash_Stone", "Slash_Beast", "Slash_Neutral",
    "Wave_Curl", "Water_Splash", "Fire_Ball", "Fire_Tongue", "Bolt", "Cloud", "Ink_Splash",
    "Petal", "Flower_Bloom", "Ice_Crystal", "Ice_Shard", "Butterfly", "Speed_Lines",
    "Swirl_Band", "Sigil", "Leaf", "Rock", "Blood_Splat", "Sound_Wave", "Ring_Shock",
    "Ring_Broken", "Spiral", "Spiral_Dense", "Impact_Star", "Impact_Star_Sharp", "Orb_Soft",
    "Calibration",
}

local function texturePath(name)
    return "package://" .. PACKAGE .. "/Client/Textures/" .. name .. ".png"
end
Toon.Path = texturePath

-- ===========================================================================
-- Mathématiques d'orientation (repère Unreal : X avant, Y droite, Z haut)
-- ===========================================================================

local function norm(v)
    local l = math.sqrt(v[1] * v[1] + v[2] * v[2] + v[3] * v[3])
    if l < 1e-6 then return { 1, 0, 0 } end
    return { v[1] / l, v[2] / l, v[3] / l }
end
local function cross(a, b)
    return { a[2] * b[3] - a[3] * b[2], a[3] * b[1] - a[1] * b[3], a[1] * b[2] - a[2] * b[1] }
end
local function dot(a, b) return a[1] * b[1] + a[2] * b[2] + a[3] * b[3] end
Toon.Norm, Toon.Cross = norm, cross

--- Rotation d'un vecteur v autour de l'axe k (unitaire) de `deg` degrés (Rodrigues).
local function rotateAround(v, k, deg)
    local a = math.rad(deg)
    local c, s = math.cos(a), math.sin(a)
    local kv = cross(k, v)
    local kd = dot(k, v) * (1 - c)
    return { v[1] * c + kv[1] * s + k[1] * kd, v[2] * c + kv[2] * s + k[2] * kd, v[3] * c + kv[3] * s + k[3] * kd }
end
Toon.RotateAround = rotateAround

--[[
    Rotator d'une carte dont :
      axe local X (droite de l'image)  = `right`
      axe local -Y (haut de l'image)   = `up`
    Formule de FRotationMatrix::Rotator() d'Unreal (axes X, Y, Z de la matrice).
    Config.Vfx.Toon.UVYaw corrige l'orientation de la texture si besoin
    (voir la commande console ds_vfxcalib).
]]
local function orient(right, up)
    local cfg = Config.Vfx.Toon or {}
    if cfg.UVYaw and cfg.UVYaw ~= 0 then
        local n = cross(right, { -up[1], -up[2], -up[3] })
        right = rotateAround(right, norm(n), cfg.UVYaw)
        up = rotateAround(up, norm(n), cfg.UVYaw)
    end
    if cfg.FlipV then up = { -up[1], -up[2], -up[3] } end
    local X = norm(right)
    local Y = norm({ -up[1], -up[2], -up[3] })
    local Z = norm(cross(X, Y))
    Y = cross(Z, X)
    local pitch = math.deg(math.atan(X[3], math.sqrt(X[1] * X[1] + X[2] * X[2])))
    local yaw = math.deg(math.atan(X[2], X[1]))
    local sy = { -math.sin(math.rad(yaw)), math.cos(math.rad(yaw)), 0 }
    local roll = math.deg(math.atan(dot(Z, sy), dot(Y, sy)))
    return Rotator(pitch, yaw, roll)
end
Toon.Orient = orient

-- ===========================================================================
-- Réserve d'entités (pool) + budget
-- ===========================================================================

local pools = { card = {}, sprite = {} }
local active = {}
local activeCount = 0
local loopRunning = false
local POOL_MAX = 48

local function limit()
    return (Config.Vfx.Toon and Config.Vfx.Toon.MaxElements) or 70
end

function Toon.Count() return activeCount end

local THRESHOLD = { main = 1.0, secondary = 0.8, detail = 0.6 }
local function allow(priority, lod)
    local cap = limit() * (THRESHOLD[priority] or THRESHOLD.secondary)
    if activeCount >= cap then return false end
    if priority == "detail" and (lod or 1) < 1 then return math.random() < (lod or 1) end
    return true
end
Toon.Allow = allow

-- Textures neutres (blanches) : teintées avec la couleur demandée. Les autres
-- sont déjà peintes en couleur : teinte blanche (seul l'éclat s'applique).
local NEUTRAL = {
    Swirl_Band = true, Ring_Shock = true, Ring_Broken = true, Spiral = true, Spiral_Dense = true,
    Impact_Star = true, Impact_Star_Sharp = true, Orb_Soft = true, Speed_Lines = true, Sigil = true,
    Slash_Neutral = true,
}
Toon.NEUTRAL = NEUTRAL

local function paint(entity, texture, color, glow)
    if not NEUTRAL[texture] then color = nil end
    color = color or { 1, 1, 1 }
    glow = glow or 1
    pcall(entity.SetMaterialTextureParameter, entity, "Texture", texturePath(texture))
    pcall(entity.SetMaterialColorParameter, entity, "Tint", Color(color[1] * glow, color[2] * glow, color[3] * glow, 1))
end

local function setAlpha(entity, a)
    pcall(entity.SetMaterialScalarParameter, entity, "Opacity", math.max(0, math.min(1, a)))
end

local function newCard()
    local ok, mesh = pcall(StaticMesh, HIDDEN, Rotator(0, 0, 0), PLANE, CollisionType.NoCollision)
    if not ok or not mesh then return nil end
    pcall(mesh.SetMaterial, mesh, MATERIAL)
    pcall(mesh.SetCastShadow, mesh, false)
    return mesh
end

local function newSprite(size)
    local ok, board = pcall(Billboard, HIDDEN, MATERIAL, Vector2D(size, size), false)
    if not ok or not board then return nil end
    return board
end

local function acquire(kind)
    local pool = pools[kind]
    local entity = table.remove(pool)
    while entity and not entity:IsValid() do entity = table.remove(pool) end
    if entity then
        pcall(entity.SetVisibility, entity, true)
        return entity
    end
    if kind == "card" then return newCard() end
    return newSprite(100)
end

local function release(entity, kind)
    if not (entity and entity:IsValid()) then return end
    if kind == "mesh" then pcall(entity.Destroy, entity) return end
    setAlpha(entity, 0)
    pcall(entity.SetVisibility, entity, false)
    pcall(entity.SetLocation, entity, HIDDEN)
    local pool = pools[kind]
    if #pool < POOL_MAX then pool[#pool + 1] = entity else pcall(entity.Destroy, entity) end
end

-- ===========================================================================
-- Animation (une seule boucle)
-- ===========================================================================

local function ease(t) return 1 - (1 - t) * (1 - t) end

local function envelope(e, t)
    local a = 1
    if e.fadeIn > 0 and t < e.fadeIn then a = t / e.fadeIn end
    local outStart = e.life - e.fadeOut
    if t > outStart and e.fadeOut > 0 then a = math.min(a, (e.life - t) / e.fadeOut) end
    return math.max(0, a) * e.alpha
end

local function update(e, t)
    local k = math.min(1, t / e.life)
    -- position : suit un acteur, ou se déplace vers moveTo
    local x, y, z = e.x, e.y, e.z
    if e.follow then
        if e.follow:IsValid() then
            local loc = e.follow:GetLocation()
            x, y, z = loc.X + e.ox, loc.Y + e.oy, loc.Z + e.oz
        end
    elseif e.moveTo then
        local k2 = math.max(0, math.min(1, (t - (e.moveStart or 0)) / (e.moveTime or e.life)))
        local m = e.linear and k2 or ease(k2)
        x = e.x + (e.moveTo[1] - e.x) * m
        y = e.y + (e.moveTo[2] - e.y) * m
        z = e.z + (e.moveTo[3] - e.z) * m
    end
    if e.rise then z = z + e.rise * t end
    pcall(e.entity.SetLocation, e.entity, Vector(x, y, z))

    local scale = e.scale0 + (e.scale1 - e.scale0) * ease(k)
    if e.kind == "card" then
        local angle = 0
        if e.sweep ~= 0 and t < e.sweepTime then angle = -e.sweep * (1 - ease(t / e.sweepTime)) end
        if e.spin ~= 0 then angle = angle + e.spin * t end
        local right, up = e.right, e.up
        if angle ~= 0 then
            right = rotateAround(right, e.normal, angle)
            up = rotateAround(up, e.normal, angle)
        end
        pcall(e.entity.SetRotation, e.entity, orient(right, up))
        pcall(e.entity.SetScale, e.entity, Vector(scale * e.sx, scale * e.sy, 1))
    else
        pcall(e.entity.SetScale, e.entity, Vector(scale, scale, scale))
    end
    setAlpha(e.entity, envelope(e, t))
    if e.kind == "mesh" and e.wobble ~= false then
        -- bulle vivante : légère ondulation
        local w = 1 + math.sin(t * 9) * 0.04
        pcall(e.entity.SetScale, e.entity, Vector(scale * w, scale / w, scale * w))
    end
end

local function loop()
    if loopRunning then return end
    loopRunning = true
    Timer.SetInterval(function()
        local now = DS.Utils.NowMs()
        for e in pairs(active) do
            local t = (now - e.start) / 1000
            if t >= e.life or (e.follow and not e.follow:IsValid()) then
                active[e] = nil
                activeCount = activeCount - 1
                release(e.entity, e.kind)
            elseif t >= 0 then
                update(e, t)
            end
        end
        if activeCount <= 0 then
            activeCount = 0
            loopRunning = false
            return false
        end
    end, TICK_MS)
end

local function start(e)
    active[e] = true
    activeCount = activeCount + 1
    update(e, 0)
    loop()
    return e
end

local function common(e, opts)
    e.x, e.y, e.z = opts.x, opts.y, opts.z
    e.start = DS.Utils.NowMs() + (opts.delay or 0) * 1000
    e.life = math.max(0.05, opts.life or 0.5)
    e.fadeIn = opts.fadeIn or 0.04
    e.fadeOut = opts.fadeOut or e.life * 0.6
    e.alpha = opts.alpha or 1
    e.scale0 = opts.scale or 1
    e.scale1 = opts.grow or e.scale0
    e.moveTo, e.moveTime = opts.moveTo, opts.moveTime
    e.rise = opts.rise
    if opts.follow and opts.follow:IsValid() then
        local loc = opts.follow:GetLocation()
        e.follow = opts.follow
        e.ox, e.oy, e.oz = (opts.x or loc.X) - loc.X, (opts.y or loc.Y) - loc.Y, (opts.z or loc.Z) - loc.Z
        e.x, e.y, e.z = opts.x or loc.X, opts.y or loc.Y, opts.z or loc.Z
    end
end

local function visible(opts)
    if not opts.x then return false end
    local lx, ly, lz = U.LocalPosition()
    if lx and U.Distance(lx, ly, lz, opts.x, opts.y, opts.z) > Config.Vfx.MaxDistance then return false end
    return true
end

--- Carte plane orientée (voir l'en-tête).
function Toon.Card(texture, opts)
    if not (Config.Vfx.Toon and Config.Vfx.Toon.Enabled ~= false) then return nil end
    if not visible(opts) or not allow(opts.priority or "main", opts.lod) then return nil end
    local entity = acquire("card")
    if not entity then return nil end
    paint(entity, texture, opts.color, opts.glow or (Config.Vfx.Toon.Glow or 1.6))
    local right = norm(opts.right or { 1, 0, 0 })
    local up = norm(opts.up or { 0, 0, 1 })
    -- `up` rendu orthogonal à `right`
    local d = dot(up, right)
    up = norm({ up[1] - right[1] * d, up[2] - right[2] * d, up[3] - right[3] * d })
    local size = opts.size or 200
    local e = {
        kind = "card", entity = entity, right = right, up = up,
        normal = norm(cross(right, { -up[1], -up[2], -up[3] })),
        sx = size / PLANE_SIZE, sy = size * (opts.aspect or 1) / PLANE_SIZE,
        sweep = opts.sweep or 0, sweepTime = opts.sweepTime or 0.1, spin = opts.spin or 0,
    }
    common(e, opts)
    return start(e)
end

--- Panneau face caméra (voir l'en-tête).
function Toon.Sprite(texture, opts)
    if not (Config.Vfx.Toon and Config.Vfx.Toon.Enabled ~= false) then return nil end
    if not visible(opts) or not allow(opts.priority or "secondary", opts.lod) then return nil end
    local entity = acquire("sprite")
    if not entity then return nil end
    paint(entity, texture, opts.color, opts.glow or (Config.Vfx.Toon.Glow or 1.6))
    local e = { kind = "sprite", entity = entity }
    common(e, opts)
    -- le Billboard est créé à 100 cm : la taille passe par l'échelle
    local k = (opts.size or 100) / 100
    e.scale0, e.scale1 = e.scale0 * k, e.scale1 * k
    return start(e)
end

--- Arrête un élément avant la fin (ex. projectile qui touche).
function Toon.Stop(e, fadeSeconds)
    if not (e and active[e]) then return end
    local t = (DS.Utils.NowMs() - e.start) / 1000
    e.fadeOut = fadeSeconds or 0.1
    e.life = math.min(e.life, t + e.fadeOut)
end

--- Déplace un élément vers (x, y, z) en `seconds` (glissement continu, défaut 0,1 s).
function Toon.Place(e, x, y, z, seconds)
    if not (e and active[e] and e.entity:IsValid()) then return end
    local loc = e.entity:GetLocation()
    if e.rise then loc = Vector(loc.X, loc.Y, loc.Z - e.rise * ((DS.Utils.NowMs() - e.start) / 1000)) end
    e.x, e.y, e.z, e.follow = loc.X, loc.Y, loc.Z, nil
    e.moveTo, e.moveTime, e.linear = { x, y, z }, seconds or 0.1, true
    e.moveStart = (DS.Utils.NowMs() - e.start) / 1000
end

-- ===========================================================================
-- Préchargement des textures (les images brutes ne sont pas préchargées par
-- nanos world : sans cela, le premier lancement d'une technique saccade)
-- ===========================================================================

local holders = {}
function Toon.Preload()
    if not (Config.Vfx.Toon and Config.Vfx.Toon.Enabled ~= false) then return end
    for i, name in ipairs(Toon.TEXTURES) do
        Timer.SetTimeout(function()
            local board = newSprite(1)
            if board then
                paint(board, name, { 1, 1, 1 }, 1)
                setAlpha(board, 0)
                holders[#holders + 1] = board
            end
        end, i * 60)
    end
end

-- ===========================================================================
-- Formes de haut niveau
-- ===========================================================================

--[[
    Croissant de coupe orienté dans l'espace.
      center {x,y,z}, forward {x,y,z} (direction du coup)
      plane : "flat" (horizontal), "rising" (bas -> haut), "falling" (haut -> bas,
              coup vertical), "diagonal", "diagonal2", "tilted" (horizontal penché)
      swing : 1 / -1 (sens), radius, life, texture, color, glow, sweep, grow, delay
]]
function Toon.Crescent(texture, center, forward, opts)
    opts = opts or {}
    local f = norm({ forward[1], forward[2], 0 })
    local right = { -f[2], f[1], 0 }     -- droite du lanceur (cf. TechMath.Point)
    local swing = opts.swing or 1
    local zUp = { 0, 0, 1 }
    local s                                -- direction "fin du coup" (haut de l'image)
    local plane = opts.plane or "flat"
    if plane == "rising" then
        s = zUp
    elseif plane == "falling" then
        s = { 0, 0, -1 }
    elseif plane == "diagonal" then
        s = norm({ right[1] * swing + 0, right[2] * swing, 0.9 })
    elseif plane == "diagonal2" then
        s = norm({ right[1] * swing, right[2] * swing, -0.9 })
    elseif plane == "tilted" then
        s = norm({ right[1] * swing, right[2] * swing, 0.35 })
    else
        s = { right[1] * swing, right[2] * swing, 0 }
    end
    local radius = opts.radius or 200
    return Toon.Card(texture, {
        x = center[1], y = center[2], z = center[3],
        right = f, up = s, size = radius * 2,
        color = opts.color, glow = opts.glow, alpha = opts.alpha or 1,
        life = opts.life or 0.42, fadeIn = 0.02, fadeOut = opts.fadeOut or 0.26,
        sweep = opts.sweep or 55, sweepTime = opts.sweepTime or 0.1,
        scale = opts.scale or 0.9, grow = opts.grow or 1.12,
        priority = opts.priority or "main", lod = opts.lod, delay = opts.delay,
        follow = opts.follow,
    })
end

--- Carte posée au sol (anneau, spirale, sceau) qui grandit / tourne.
function Toon.Ground(texture, x, y, z, opts)
    opts = opts or {}
    return Toon.Card(texture, {
        x = x, y = y, z = z + (opts.lift or 6),
        right = { 1, 0, 0 }, up = { 0, 1, 0 }, size = opts.size or 300,
        color = opts.color, glow = opts.glow, alpha = opts.alpha or 0.9,
        life = opts.life or 0.6, fadeIn = opts.fadeIn or 0.05, fadeOut = opts.fadeOut,
        scale = opts.scale or 0.4, grow = opts.grow or 1.2, spin = opts.spin or 0,
        priority = opts.priority or "secondary", lod = opts.lod, delay = opts.delay,
        follow = opts.follow,
    })
end

--- Carte verticale face à une direction (vague, mur d'eau, flamme géante).
function Toon.Wall(texture, x, y, z, yaw, opts)
    opts = opts or {}
    local f = { math.cos(math.rad(yaw)), math.sin(math.rad(yaw)), 0 }
    local right = { -f[2], f[1], 0 }
    if opts.mirror then right = { f[2], -f[1], 0 } end
    if opts.sideways then right = f end
    return Toon.Card(texture, {
        x = x, y = y, z = z, right = right, up = { 0, 0, 1 },
        size = opts.size or 400, aspect = opts.aspect or 1,
        color = opts.color, glow = opts.glow, alpha = opts.alpha or 1,
        life = opts.life or 1, fadeIn = opts.fadeIn or 0.08, fadeOut = opts.fadeOut,
        scale = opts.scale or 0.6, grow = opts.grow or 1.1, moveTo = opts.moveTo, moveTime = opts.moveTime,
        priority = opts.priority or "main", lod = opts.lod, delay = opts.delay, follow = opts.follow,
    })
end

--[[
    Tornade / pilier : plusieurs bandes verticales disposées en étoile qui
    tournent autour de l'axe (lecture "spirale" sous tous les angles).
]]
function Toon.Pillar(texture, x, y, z, opts)
    opts = opts or {}
    local count = opts.count or 3
    local created = {}
    for i = 1, count do
        local yaw = (i - 1) * 180 / count
        local f = { math.cos(math.rad(yaw)), math.sin(math.rad(yaw)), 0 }
        created[#created + 1] = Toon.Card(texture, {
            x = x, y = y, z = z + (opts.height or 400) / 2,
            right = f, up = { 0, 0, 1 }, size = opts.radius and opts.radius * 2 or 300,
            aspect = (opts.height or 400) / ((opts.radius or 150) * 2),
            color = opts.color, glow = opts.glow, alpha = opts.alpha or 0.8,
            life = opts.life or 1.2, fadeIn = 0.12, fadeOut = opts.fadeOut,
            scale = opts.scale or 0.5, grow = opts.grow or 1.05,
            spin = (opts.spin or 360) * ((i % 2 == 0) and -1 or 1),
            priority = i == 1 and "main" or "secondary", lod = opts.lod, delay = opts.delay,
            follow = opts.follow,
        })
    end
    return created
end

--[[
    Maillage translucide qui suit un acteur (bulle d'eau : SM_Sphere).
    Non mis en réserve (rare) : détruit à la fin.
]]
function Toon.Bubble(actor, opts)
    opts = opts or {}
    if not (actor and actor:IsValid()) then return nil end
    if not (Config.Vfx.Toon and Config.Vfx.Toon.Enabled ~= false) then return nil end
    local loc = actor:GetLocation()
    local ok, mesh = pcall(StaticMesh, loc, Rotator(0, 0, 0), opts.mesh or "nanos-world::SM_Sphere", CollisionType.NoCollision)
    if not ok or not mesh then return nil end
    pcall(mesh.SetMaterial, mesh, MATERIAL)
    pcall(mesh.SetCastShadow, mesh, false)
    local c, glow = opts.color or { 0.4, 0.8, 1.0 }, opts.glow or 1.2
    pcall(mesh.SetMaterialColorParameter, mesh, "Tint", Color(c[1] * glow, c[2] * glow, c[3] * glow, 1))
    local radius = opts.radius or 120
    local e = { kind = "mesh", entity = mesh, sx = 1, sy = 1 }
    common(e, { follow = actor, x = loc.X, y = loc.Y, z = loc.Z + (opts.up or 0), life = opts.life or 3,
        alpha = opts.alpha or 0.35, fadeIn = 0.25, fadeOut = 0.3, scale = radius / 50 * 0.3, grow = radius / 50 })
    return start(e)
end

--- Gerbe de petits panneaux (pétales, éclats, gouttes) projetés autour d'un point.
function Toon.Scatter(textures, x, y, z, opts)
    opts = opts or {}
    local count = math.max(1, math.floor((opts.count or 6) * (opts.lod or 1)))
    for i = 1, count do
        local a = math.random() * 2 * math.pi
        local dist = (opts.spread or 220) * (0.4 + math.random() * 0.6)
        local tex = textures[(i - 1) % #textures + 1]
        Toon.Sprite(tex, {
            x = x, y = y, z = z + (opts.up or 0),
            moveTo = { x + math.cos(a) * dist, y + math.sin(a) * dist, z + (opts.up or 0) + (math.random() - 0.3) * (opts.height or 160) },
            size = (opts.size or 40) * (0.7 + math.random() * 0.6),
            color = opts.color, glow = opts.glow,
            life = (opts.life or 0.8) * (0.7 + math.random() * 0.5), fadeOut = 0.35,
            grow = opts.grow, rise = opts.rise, priority = "detail", lod = opts.lod, delay = opts.delay,
        })
    end
end

return Toon
