--[[
    Demon Slayer RP - Mathématiques des techniques (partagé)
    ------------------------------------------------------------------
    Trajectoires utilisées À LA FOIS par le serveur (zones de touche) et
    par les clients (effets visuels) : la vague que l'on voit est exactement
    la zone qui touche.

    Repère local d'une technique : origine + direction (yaw) du lanceur.
      forward : vers l'avant, side : vers la droite, up : vers le haut.
]]

local TMath = {}
DS.TechMath = TMath

function TMath.Lerp(a, b, t)
    return a + (b - a) * t
end

function TMath.Clamp01(t)
    if t < 0 then return 0 end
    if t > 1 then return 1 end
    return t
end

--- Lissage (départ et arrivée doux)
function TMath.Smooth(t)
    t = TMath.Clamp01(t)
    return t * t * (3 - 2 * t)
end

--- Direction (fx, fy) à partir d'un yaw en degrés.
function TMath.Forward(yaw)
    local rad = math.rad(yaw)
    return math.cos(rad), math.sin(rad)
end

--- Point du monde à partir du repère local (origine ox,oy,oz ; direction fx,fy).
function TMath.Point(ox, oy, oz, fx, fy, forward, side, up)
    -- Vecteur "droite" dans Unreal (Y vers la droite quand X est l'avant)
    local rx, ry = -fy, fx
    return ox + fx * forward + rx * side, oy + fy * forward + ry * side, oz + up
end

--- Vague : distance parcourue et largeur pour une progression p (0..1).
function TMath.WaveAt(p, wave)
    p = TMath.Clamp01(p)
    local distance = TMath.Lerp(wave.StartDistance, wave.Distance, p)
    local width = TMath.Lerp(wave.StartWidth, wave.EndWidth, p)
    return distance, width
end

--- Dragon : position de la tête (forward, side, up) pour une progression p (0..1).
--- Ondulation latérale de serpent + légère montée au milieu de la course.
function TMath.DragonAt(p, dragon)
    p = TMath.Clamp01(p)
    local forward = -dragon.StartBack + (dragon.Distance + dragon.StartBack) * p
    local side = math.sin(p * dragon.Waves * 2 * math.pi) * dragon.Amplitude * (1 - p * 0.35)
    local up = dragon.Height + math.sin(p * math.pi) * 140
    return forward, side, up
end

--[[
    Fouet / trajectoire sinueuse : position d'une "tête" pour p (0..1).
      whip.Path : "straight" | "sine" | "spiral"
      whip.Return = true : aller-retour (le fouet revient vers le lanceur)
      head = 1 ou 2 : la 2e tête est symétrique (Reptile à deux têtes)
]]
function TMath.WhipAt(p, whip, head)
    p = TMath.Clamp01(p)
    local reach = p
    if whip.Return then reach = p < 0.5 and p * 2 or (1 - p) * 2 end
    local mirror = (head == 2) and -1 or 1
    local up = whip.Height or 80
    if whip.Path == "spiral" then
        -- Spirale autour du lanceur : le rayon grandit, l'angle tourne
        local angle = p * (whip.Turns or 1.5) * 2 * math.pi * mirror
        local radius = TMath.Lerp(whip.StartRadius or 120, whip.Distance, p)
        return math.cos(angle) * radius, math.sin(angle) * radius, up
    end
    local forward = (whip.StartDistance or 80) + (whip.Distance - (whip.StartDistance or 80)) * reach
    local side = 0
    if whip.Path == "sine" then
        side = math.sin(reach * (whip.Waves or 1.5) * 2 * math.pi) * (whip.Amplitude or 150) * mirror
    end
    return forward, side, up
end

--[[
    Explosions programmées : liste { forward, side, delay, radius, damage, knockback, lift }.
      Pattern.Type = "line"  : Count explosions espacées de Spacing à partir de Start
      Pattern.Type = "rings" : Rings = { { Radius, Count, DelayMs, Damage, ... }, ... }
      Pattern.Type = "points": Points = { { Forward, Side, DelayMs }, ... }
]]
function TMath.BurstList(pattern)
    local list = {}
    local function add(forward, side, delay)
        list[#list + 1] = {
            forward = forward, side = side, delay = delay,
            radius = pattern.Radius, damage = pattern.Damage,
            knockback = pattern.Knockback or 0, lift = pattern.Lift or 0,
        }
    end
    if pattern.Type == "line" then
        for i = 1, pattern.Count do
            add(pattern.Start + (i - 1) * pattern.Spacing, 0, (i - 1) * pattern.IntervalMs)
        end
    elseif pattern.Type == "rings" then
        for _, ring in ipairs(pattern.Rings) do
            for i = 1, ring.Count do
                local angle = (i / ring.Count) * 2 * math.pi
                local entry = {
                    forward = math.cos(angle) * ring.Radius, side = math.sin(angle) * ring.Radius,
                    delay = ring.DelayMs, radius = ring.BurstRadius or pattern.Radius,
                    damage = ring.Damage or pattern.Damage,
                    knockback = ring.Knockback or pattern.Knockback or 0, lift = ring.Lift or pattern.Lift or 0,
                }
                list[#list + 1] = entry
            end
        end
    else
        for _, point in ipairs(pattern.Points or {}) do
            add(point.Forward, point.Side or 0, point.DelayMs or 0)
        end
    end
    return list
end

--- Direction (fx, fy) tournée de `degrees` autour de la verticale.
function TMath.Rotate(fx, fy, degrees)
    local r = math.rad(degrees)
    local c, s = math.cos(r), math.sin(r)
    return fx * c - fy * s, fx * s + fy * c
end

return TMath
