--[[
    Demon Slayer RP - VFXManager (client)
    ------------------------------------------------------------------
    Point d'entrée UNIQUE des effets visuels :

        local VFX = DS.VFX
        VFX.Slash("water", caster, { radius = 180, from = -70, to = 80 })
        VFX.Trail.Attach("flame", caster, "hand_r", { duration = 0.6 })
        VFX.Impact("thunder", "Large", x, y, z, yaw)
        local shot = VFX.Projectile("water", { x, y, z }, yaw, { speed = 2000, distance = 1500 })
        shot:Impact(x, y, z, "Medium")

    Responsabilités :
      - création des particules (durée de vie OBLIGATOIRE, paramètres typés)
      - budget global de particules simultanées + niveau de détail par distance
      - registre des identités d'éléments (Client/Systems/VFX/Elements/*.lua)
      - chorégraphies des techniques scriptées (TechStart / TechEvent)

    Priorités des couches : "main" (toujours), "secondary" (sauf budget
    saturé), "detail" (réduite selon la qualité et la distance).
]]

local VFXManager = DS.Module("VFXManager", { dependencies = { "Network" } })

local Log = VFXManager.Log
local Utils = DS.Utils
local U = DS.VFXUtils
local TMath = DS.TechMath

local VFX = {}
DS.VFX = VFX
VFX.Log = Log

-- ===========================================================================
-- Création des particules (budget + durée de vie)
-- ===========================================================================

local active = 0
local tracked = setmetatable({}, { __mode = "k" })
local DETAIL_RATE = { high = 1, medium = 0.5, low = 0 }
-- Part du budget au-delà de laquelle une priorité est refusée : les détails
-- s'effacent d'abord, puis les couches secondaires ; les couches principales
-- passent jusqu'au plafond (MaxActiveParticles n'est jamais dépassé).
local THRESHOLD = { main = 1.0, secondary = 0.8, detail = 0.6 }

-- Technique (contexte de chorégraphie) en train de créer des particules :
-- chaque technique a son propre quota (Config.Vfx.MaxPerTechnique) pour qu'un
-- ultime ne prive pas de VFX les techniques des autres joueurs.
local owner = nil

local function release(particle)
    local by = tracked[particle]
    if by then
        tracked[particle] = nil
        active = math.max(0, active - 1)
        if type(by) == "table" then by.particles = math.max(0, (by.particles or 0) - 1) end
    end
end

local function track(particle, seconds)
    active = active + 1
    tracked[particle] = owner or true
    if owner then owner.particles = (owner.particles or 0) + 1 end
    Timer.SetTimeout(function() release(particle) end, math.floor(seconds * 1000) + 50)
end

--- Exécute fn en attribuant les particules créées à la technique ctx.
function VFX.As(ctx, fn, ...)
    local previous = owner
    owner = ctx
    local result = table.pack(Utils.Try(fn, ...))
    owner = previous
    return table.unpack(result, 1, result.n)
end

function VFX.Count()
    return active
end

--- Peut-on créer une couche de cette priorité, avec ce niveau de détail ?
function VFX.Allow(priority, lod)
    local threshold = THRESHOLD[priority] or THRESHOLD.secondary
    if active >= Config.Vfx.MaxActiveParticles * threshold then return false end
    if owner and (owner.particles or 0) >= (Config.Vfx.MaxPerTechnique or 100) * threshold then return false end
    if priority == "main" then return true end
    if priority == "detail" then
        local rate = (DETAIL_RATE[Config.Vfx.Quality] or 1) * (lod or 1)
        return rate >= 1 or math.random() < rate
    end
    return (lod or 1) > 0.3 or math.random() < 0.6
end

local function toScale(scale)
    if type(scale) == "number" then return Vector(scale, scale, scale) end
    return scale
end

--[[
    Crée une particule. opts :
      yaw, pitch, scale (nombre ou Vector), life (s, défaut 1.5),
      priority ("main" | "secondary" | "detail"), lod (0..1), params (table Niagara)
]]
function VFX.Spawn(asset, x, y, z, opts)
    opts = opts or {}
    if not asset or not VFX.Allow(opts.priority or "secondary", opts.lod) then return nil end
    local ok, particle = pcall(Particle, Vector(x, y, z), Rotator(opts.pitch or 0, opts.yaw or 0, opts.roll or 0), asset, false, true)
    if not ok or not particle then
        Log:Debug("Particule impossible : %s", tostring(asset))
        return nil
    end
    local life = opts.life or 1.5
    if opts.scale then pcall(particle.SetScale, particle, toScale(opts.scale)) end
    if opts.params then U.ApplyParams(particle, opts.params) end
    pcall(particle.SetLifeSpan, particle, life)
    track(particle, life)
    return particle
end

--- Crée une particule attachée à un acteur (os optionnel : "hand_r", "foot_l", "pelvis"...).
function VFX.Attach(asset, actor, bone, opts)
    opts = opts or {}
    if not (actor and actor:IsValid()) then return nil end
    local loc = actor:GetLocation()
    local particle = VFX.Spawn(asset, loc.X, loc.Y, loc.Z, opts)
    if particle then
        pcall(particle.AttachTo, particle, actor, AttachmentRule.SnapToTarget, bone or "", 0)
        if opts.offset then pcall(particle.SetRelativeLocation, particle, opts.offset) end
    end
    return particle
end

function VFX.MoveTo(particle, x, y, z, seconds)
    if particle and particle:IsValid() then
        pcall(particle.TranslateTo, particle, Vector(x, y, z), seconds, 0)
    end
end

function VFX.SetScale(particle, scale)
    if particle and particle:IsValid() then pcall(particle.SetScale, particle, toScale(scale)) end
end

function VFX.Destroy(particle)
    if not particle then return end
    release(particle)
    if particle:IsValid() then pcall(particle.Destroy, particle) end
end

--- Fait suivre à une particule une suite de points (ruban = traînée de cette forme).
function VFX.FollowPath(particle, points, durationSec)
    if not (particle and #points > 1) then return end
    local stepSec = durationSec / (#points - 1)
    for i = 2, #points do
        local p = points[i]
        Timer.SetTimeout(function()
            VFX.MoveTo(particle, p[1], p[2], p[3], stepSec)
        end, math.floor((i - 2) * stepSec * 1000))
    end
end

-- ===========================================================================
-- Éléments
-- ===========================================================================

local elements = {}

--- Enregistre une identité visuelle (voir Client/Systems/VFX/Elements/).
function VFX.RegisterElement(id, preset)
    preset.Id = preset.Id or id   -- un alias (eau -> water) ne remplace pas l identifiant d origine
    elements[id] = preset
end

--- Identité d'un élément (repli sur "neutral").
function VFX.Element(id)
    return elements[id] or elements.neutral
end

--- Élément d'un souffle / art (champ Element de la configuration, sinon son identifiant).
function VFX.ElementOf(set)
    if not set then return VFX.Element("neutral") end
    return VFX.Element(set.Element or set.Id)
end

--- Couleur principale / d'accent d'un élément, prête pour SetParameterColor.
function VFX.Glow(element, which, multiplier)
    local colors = element.Colors
    local rgb = colors[which or "Core"] or colors.Core
    return U.Color(rgb, (colors.Glow or 4) * (multiplier or 1))
end

--- Crée une liste de couches d'élément { Asset, Scale, Life, Forward, Side, Up, Priority, Params }.
function VFX.Layers(layers, x, y, z, yaw, opts)
    if not layers then return {} end
    opts = opts or {}
    local fx, fy = TMath.Forward(yaw or 0)
    local created = {}
    for _, layer in ipairs(layers) do
        local px, py, pz = TMath.Point(x, y, z, fx, fy, layer.Forward or 0, layer.Side or 0, layer.Up or 0)
        local particle = VFX.Spawn(layer.Asset, px, py, pz, {
            yaw = yaw, scale = (layer.Scale or 1) * (opts.scale or 1),
            life = opts.life or layer.Life or 1.2,
            priority = opts.priority or layer.Priority or "secondary",
            params = layer.Params, lod = opts.lod,
        })
        if particle then created[#created + 1] = particle end
    end
    return created
end

-- ===========================================================================
-- Chorégraphies (techniques scriptées)
-- ===========================================================================

local scripts = {}
local running = {}

local Ctx = {}
Ctx.__index = Ctx

function Ctx:Point(forward, side, up)
    local o = self.origin
    return TMath.Point(o.x, o.y, o.z, self.fx, self.fy, forward, side or 0, up or 0)
end

function Ctx:Elapsed()
    return Utils.NowMs() - self.startedAt
end

--- Action unique à `ms` après le début de la technique.
function Ctx:At(ms, fn)
    local delay = math.max(0, math.floor(ms - self:Elapsed()))
    Timer.SetTimeout(function()
        local ok, err = VFX.As(self, fn, self)
        if not ok then Log:Error("VFX '%s' en erreur : %s", tostring(self.tech.Script), err) end
    end, delay)
end

--- Répète fn(ctx, elapsedMs) toutes les `intervalMs` entre fromMs et toMs.
function Ctx:Every(fromMs, toMs, intervalMs, fn)
    self:At(fromMs, function()
        Timer.SetInterval(function()
            local elapsed = self:Elapsed()
            if elapsed > toMs then return false end
            local ok, err = VFX.As(self, fn, self, elapsed)
            if not ok then
                Log:Error("VFX '%s' en erreur : %s", tostring(self.tech.Script), err)
                return false
            end
        end, intervalMs)
    end)
end

--- Position et orientation actuelles du lanceur (repli : origine de la technique).
function Ctx:CasterTransform()
    if self.caster and self.caster:IsValid() then
        local loc = self.caster:GetLocation()
        return loc.X, loc.Y, loc.Z, self.caster:GetRotation().Yaw
    end
    return self.origin.x, self.origin.y, self.origin.z, self.yaw
end

--- Traînée de l'élément sur la lame (main droite) pendant `durationMs`.
function Ctx:BladeTrail(durationMs)
    if self.caster and self.caster:IsValid() then
        VFX.Trail.Blade(self.element, self.caster, (durationMs or 600) / 1000)
    end
end

function VFX.RegisterChoreography(script, choreography)
    scripts[script] = choreography
end

local function startChoreo(caster, tech, x, y, z, yaw, instance)
    local script = scripts[tech.Script]
    if not script then return end
    local lx, ly, lz = U.LocalPosition()
    if lx and U.Distance(lx, ly, lz, x, y, z) > Config.Vfx.MaxDistance then return end

    local fx, fy = TMath.Forward(yaw)
    local player = Client.GetLocalPlayer()
    local set = DS.Catalog.GetSet(tech.Kind, tech.SetId)
    local ctx = setmetatable({
        id = instance, caster = caster, tech = tech, set = set,
        element = VFX.ElementOf(set),
        origin = { x = x, y = y, z = z }, yaw = yaw, fx = fx, fy = fy,
        startedAt = Utils.NowMs(),
        lod = U.Lod(x, y, z),
        isLocal = player ~= nil and caster:IsValid() and caster:GetPlayer() == player,
        data = {},
    }, Ctx)
    running[instance] = ctx
    Timer.SetTimeout(function() running[instance] = nil end, 15000)

    local ok, err = VFX.As(ctx, script.Start, ctx)
    if not ok then Log:Error("VFX '%s' en erreur : %s", tech.Script, err) end
end

local function eventChoreo(instance, event, x, y, z, target)
    local ctx = running[instance]
    if not ctx then return end
    local script = scripts[ctx.tech.Script]
    if not script.Event then return end
    local ok, err = VFX.As(ctx, script.Event, ctx, event, x, y, z, target)
    if not ok then Log:Error("VFX '%s' (%s) en erreur : %s", ctx.tech.Script, event, err) end
end

function VFXManager:Init()
    DS.Net.On("TechStart", function(caster, kind, setId, slot, x, y, z, yaw, instance)
        local tech = DS.Catalog.GetTechnique(kind, setId, slot)
        if tech and tech.Script then startChoreo(caster, tech, x, y, z, yaw, instance) end
    end)
    DS.Net.On("TechEvent", eventChoreo)
end

return VFXManager
