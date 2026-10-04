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

return TMath
