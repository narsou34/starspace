--[[
    Demon Slayer RP - Zones de touche (serveur)
    ------------------------------------------------------------------
    Formes géométriques testées contre tous les personnages vivants.
    Chaque fonction retourne une liste { character = c, x, y, z } triée par
    distance au centre. Le filtrage ami / ennemi est fait par le moteur.

      Sphere(cx, cy, cz, radius)
      Cylinder(cx, cy, baseZ, radius, height)          -- tornade
      Box(cx, cy, cz, fx, fy, halfLength, halfWidth, halfHeight)  -- vague (orientée)
      Capsule(ax, ay, az, bx, by, bz, radius)          -- balayage d'un projectile
      Arc(ox, oy, oz, fx, fy, range, angleDeg, height) -- coup de katana
]]

local Hitboxes = {}
DS.Hitboxes = Hitboxes

-- Les personnages sont des capsules : on ajoute leur "épaisseur"
local BODY_RADIUS = 45
local BODY_HALF_HEIGHT = 90

local function collect(test)
    local found = {}
    for _, character in pairs(Character.GetPairs()) do
        if character:IsValid() and not character:IsDead() then
            local loc = character:GetLocation()
            local score = test(loc.X, loc.Y, loc.Z)
            if score then
                found[#found + 1] = { character = character, x = loc.X, y = loc.Y, z = loc.Z, score = score }
            end
        end
    end
    table.sort(found, function(a, b) return a.score < b.score end)
    return found
end

function Hitboxes.Sphere(cx, cy, cz, radius)
    local r = radius + BODY_RADIUS
    return collect(function(x, y, z)
        local dx, dy = x - cx, y - cy
        local dz = math.max(0, math.abs(z - cz) - BODY_HALF_HEIGHT)
        local d2 = dx * dx + dy * dy + dz * dz
        if d2 <= r * r then return d2 end
    end)
end

function Hitboxes.Cylinder(cx, cy, baseZ, radius, height)
    local r = radius + BODY_RADIUS
    return collect(function(x, y, z)
        if z + BODY_HALF_HEIGHT < baseZ - 50 or z - BODY_HALF_HEIGHT > baseZ + height then return nil end
        local dx, dy = x - cx, y - cy
        local d2 = dx * dx + dy * dy
        if d2 <= r * r then return d2 end
    end)
end

function Hitboxes.Box(cx, cy, cz, fx, fy, halfLength, halfWidth, halfHeight)
    local rx, ry = -fy, fx
    return collect(function(x, y, z)
        local dx, dy = x - cx, y - cy
        local along = dx * fx + dy * fy
        local lateral = dx * rx + dy * ry
        if math.abs(along) > halfLength + BODY_RADIUS then return nil end
        if math.abs(lateral) > halfWidth + BODY_RADIUS then return nil end
        if math.abs(z - cz) > halfHeight + BODY_HALF_HEIGHT then return nil end
        return math.abs(along)
    end)
end

function Hitboxes.Capsule(ax, ay, az, bx, by, bz, radius)
    local sx, sy, sz = bx - ax, by - ay, bz - az
    local len2 = sx * sx + sy * sy + sz * sz
    local r = radius + BODY_RADIUS
    return collect(function(x, y, z)
        local t = 0
        if len2 > 0 then
            t = ((x - ax) * sx + (y - ay) * sy + (z - az) * sz) / len2
            if t < 0 then t = 0 elseif t > 1 then t = 1 end
        end
        local px, py, pz = ax + sx * t, ay + sy * t, az + sz * t
        local dx, dy = x - px, y - py
        local dz = math.max(0, math.abs(z - pz) - BODY_HALF_HEIGHT)
        local d2 = dx * dx + dy * dy + dz * dz
        if d2 <= r * r then return t end   -- tri : premier touché le long du trajet
    end)
end

function Hitboxes.Arc(ox, oy, oz, fx, fy, range, angleDeg, height)
    local cosHalf = math.cos(math.rad(angleDeg / 2))
    local r = range + BODY_RADIUS
    return collect(function(x, y, z)
        if math.abs(z - oz) > (height or 250) then return nil end
        local dx, dy = x - ox, y - oy
        local d = math.sqrt(dx * dx + dy * dy)
        if d > r then return nil end
        if d > 60 and (dx * fx + dy * fy) / d < cosHalf then return nil end
        return d
    end)
end

return Hitboxes
