--[[
    Demon Slayer RP - Boîte à outils des effets (client)
    ------------------------------------------------------------------
    DS.Vfx    particules : création, attache à un os, déplacement, échelle
    DS.Sfx    sons positionnés avec volume / hauteur / fondu
    DS.CamFx  effets de caméra du joueur local (FOV, recul), toujours limités
    DS.Choreo chorégraphies : un script visuel par technique scriptée

    Garde-fous de performance (Config.Vfx) :
      - durée de vie systématique (aucune particule "oubliée")
      - nombre maximal de particules simultanées : au-delà, seules les
        couches principales ("main") sont créées
      - qualité "medium"/"low" : couches "detail" réduites ou supprimées
      - distance max : une technique trop lointaine n'est pas dessinée
]]

local FxCore = DS.Module("FxCore", { dependencies = { "Network" } })

local Log = FxCore.Log
local Utils = DS.Utils
local TMath = DS.TechMath

-- ===========================================================================
-- Particules
-- ===========================================================================

local Vfx = {}
DS.Vfx = Vfx

local active = 0
local DETAIL_RATE = { high = 1, medium = 0.5, low = 0 }

local function track(seconds)
    active = active + 1
    Timer.SetTimeout(function() active = math.max(0, active - 1) end, math.floor(seconds * 1000) + 50)
end

--- Peut-on créer une particule de cette priorité ? ("main" | "secondary" | "detail")
function Vfx.Allow(priority)
    if priority == "main" then return true end
    if active >= Config.Vfx.MaxActiveParticles then return false end
    if priority == "detail" then
        local rate = DETAIL_RATE[Config.Vfx.Quality] or 1
        return rate >= 1 or math.random() < rate
    end
    return true
end

function Vfx.Count()
    return active
end

local function toScale(scale)
    if type(scale) == "number" then return Vector(scale, scale, scale) end
    return scale
end

--[[
    Crée une particule. opts :
      yaw, pitch   orientation (degrés)
      scale        nombre ou Vector
      life         durée de vie en secondes (défaut 2)
      priority     "main" | "secondary" | "detail" (défaut "secondary")
]]
function Vfx.Spawn(asset, x, y, z, opts)
    opts = opts or {}
    if not asset or not Vfx.Allow(opts.priority or "secondary") then return nil end
    local ok, particle = pcall(Particle, Vector(x, y, z), Rotator(opts.pitch or 0, opts.yaw or 0, 0), asset, false, true)
    if not ok or not particle then
        Log:Debug("Particule impossible : %s", tostring(asset))
        return nil
    end
    local life = opts.life or 2
    if opts.scale then pcall(particle.SetScale, particle, toScale(opts.scale)) end
    pcall(particle.SetLifeSpan, particle, life)
    track(life)
    return particle
end

--- Crée une particule attachée à un acteur (os optionnel : "hand_r", "foot_l", "pelvis"...).
function Vfx.Attach(asset, actor, bone, opts)
    opts = opts or {}
    if not (actor and actor:IsValid()) then return nil end
    local loc = actor:GetLocation()
    local particle = Vfx.Spawn(asset, loc.X, loc.Y, loc.Z, opts)
    if particle then
        pcall(particle.AttachTo, particle, actor, AttachmentRule.SnapToTarget, bone or "", 0)
        if opts.offset then pcall(particle.SetRelativeLocation, particle, opts.offset) end
    end
    return particle
end

--- Déplace une particule en douceur vers un point (en `seconds`).
function Vfx.MoveTo(particle, x, y, z, seconds)
    if particle and particle:IsValid() then
        pcall(particle.TranslateTo, particle, Vector(x, y, z), seconds, 0)
    end
end

function Vfx.SetScale(particle, scale)
    if particle and particle:IsValid() then pcall(particle.SetScale, particle, toScale(scale)) end
end

function Vfx.Destroy(particle)
    if particle and particle:IsValid() then pcall(particle.Destroy, particle) end
end

-- ===========================================================================
-- Sons
-- ===========================================================================

local Sfx = {}
DS.Sfx = Sfx

--[[
    opts : volume, pitch, life (secondes, coupe les sons longs), fadeOut (secondes),
           falloff (portée en cm), attach (acteur à suivre)
]]
function Sfx.Play(asset, x, y, z, opts)
    opts = opts or {}
    if not asset then return nil end
    local ok, sound = pcall(Sound, Vector(x, y, z), asset, false, true, SoundType.SFX,
        opts.volume or 1, opts.pitch or 1, 400, opts.falloff or 4000)
    if not ok or not sound then return nil end
    if opts.attach and opts.attach:IsValid() then
        pcall(sound.AttachTo, sound, opts.attach, AttachmentRule.SnapToTarget, "", 0)
    end
    if opts.life then
        local fade = opts.fadeOut or 0
        if fade > 0 then
            Timer.SetTimeout(function()
                if sound:IsValid() then pcall(sound.FadeOut, sound, fade, 0, true) end
            end, math.max(0, math.floor((opts.life - fade) * 1000)))
        end
        pcall(sound.SetLifeSpan, sound, opts.life + 0.1)
    end
    return sound
end

-- ===========================================================================
-- Caméra (joueur local uniquement)
-- ===========================================================================

local CamFx = {}
DS.CamFx = CamFx

local BASE_FOV = 90
local fovStack, armStack = {}, {}
local nextCamId = 0

local function localPlayer()
    return Client.GetLocalPlayer()
end

local function applyFov()
    local player = localPlayer()
    if not player then return end
    local delta = 0
    for _, value in pairs(fovStack) do delta = math.max(delta, value) end
    pcall(player.SetCameraFOV, player, BASE_FOV + math.min(delta, Config.Vfx.MaxFovDelta))
end

local function applyArm()
    local player = localPlayer()
    if not player then return end
    local delta = 0
    for _, value in pairs(armStack) do delta = math.max(delta, value) end
    local ok, base = pcall(player.GetCameraArmLength, player, true)
    if ok and base then
        pcall(player.SetCameraArmLength, player, base + math.min(delta, Config.Vfx.MaxArmLengthDelta), false)
    end
end

--- Élargit le champ de vision pendant `durationMs` (effet de vitesse / puissance).
function CamFx.Fov(delta, durationMs)
    if not Config.Vfx.CameraEffects or not delta or delta <= 0 then return end
    nextCamId = nextCamId + 1
    local id = nextCamId
    fovStack[id] = delta
    applyFov()
    Timer.SetTimeout(function() fovStack[id] = nil; applyFov() end, durationMs)
end

--- Recule la caméra pendant `durationMs` (pour voir une technique géante).
function CamFx.Pull(delta, durationMs)
    if not Config.Vfx.CameraEffects or not delta or delta <= 0 then return end
    nextCamId = nextCamId + 1
    local id = nextCamId
    armStack[id] = delta
    applyArm()
    Timer.SetTimeout(function() armStack[id] = nil; applyArm() end, durationMs)
end

--- "Coup" de caméra bref à l'impact (FOV qui pulse).
function CamFx.Kick(delta)
    CamFx.Fov(delta, 180)
end

-- ===========================================================================
-- Chorégraphies
-- ===========================================================================

local Choreo = {}
DS.Choreo = Choreo

local scripts = {}
local running = {} -- [instance] = ctx

local Ctx = {}
Ctx.__index = Ctx

function Ctx:Point(forward, side, up)
    local o = self.origin
    return TMath.Point(o.x, o.y, o.z, self.fx, self.fy, forward, side or 0, up or 0)
end

--- Action unique à `ms` après le début de la technique (horloge locale).
function Ctx:At(ms, fn)
    local delay = math.max(0, math.floor(ms - (Utils.NowMs() - self.startedAt)))
    Timer.SetTimeout(function()
        local ok, err = Utils.Try(fn, self)
        if not ok then Log:Error("Effet '%s' en erreur : %s", self.tech.Script, err) end
    end, delay)
end

--- Répète `fn(ctx, elapsedMs)` toutes les `intervalMs` entre `fromMs` et `toMs`.
function Ctx:Every(fromMs, toMs, intervalMs, fn)
    self:At(fromMs, function()
        local timer
        timer = Timer.SetInterval(function()
            local elapsed = Utils.NowMs() - self.startedAt
            if elapsed > toMs then return false end
            local ok, err = Utils.Try(fn, self, elapsed)
            if not ok then
                Log:Error("Effet '%s' en erreur : %s", self.tech.Script, err)
                return false
            end
        end, intervalMs)
    end)
end

function Ctx:Elapsed()
    return Utils.NowMs() - self.startedAt
end

--- Traînée d'eau sur le katana (main droite) pendant `durationMs`.
function Ctx:BladeTrail(durationMs)
    local trail = self.set and self.set.BladeTrail
    if not trail or not (self.caster and self.caster:IsValid()) then return end
    for index, asset in ipairs(trail.Layers) do
        Vfx.Attach(asset, self.caster, trail.Bone, {
            life = (durationMs or trail.DurationMs) / 1000,
            priority = index == 1 and "main" or "secondary",
        })
    end
end

function Choreo.Register(script, choreography)
    scripts[script] = choreography
end

local function localDistance(x, y, z)
    local player = Client.GetLocalPlayer()
    local character = player and player:GetControlledCharacter()
    if not (character and character:IsValid()) then return 0 end
    local loc = character:GetLocation()
    local dx, dy, dz = loc.X - x, loc.Y - y, loc.Z - z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function Choreo.Start(caster, tech, x, y, z, yaw, instance)
    local script = scripts[tech.Script]
    if not script then return end
    if localDistance(x, y, z) > Config.Vfx.MaxDistance then return end

    local fx, fy = TMath.Forward(yaw)
    local player = Client.GetLocalPlayer()
    local ctx = setmetatable({
        id = instance,
        caster = caster,
        tech = tech,
        set = DS.Catalog.GetSet(tech.Kind, tech.SetId),
        origin = { x = x, y = y, z = z },
        yaw = yaw, fx = fx, fy = fy,
        startedAt = Utils.NowMs(),
        isLocal = player ~= nil and caster:IsValid() and caster:GetPlayer() == player,
        data = {},
    }, Ctx)
    running[instance] = ctx
    -- Nettoyage de la table de suivi (les particules ont leur propre durée de vie)
    Timer.SetTimeout(function() running[instance] = nil end, 15000)

    local ok, err = Utils.Try(script.Start, ctx)
    if not ok then Log:Error("Effet '%s' en erreur : %s", tech.Script, err) end
end

function Choreo.Event(instance, event, x, y, z, target)
    local ctx = running[instance]
    if not ctx then return end
    local script = scripts[ctx.tech.Script]
    if not script.Event then return end
    local ok, err = Utils.Try(script.Event, ctx, event, x, y, z, target)
    if not ok then Log:Error("Effet '%s' (%s) en erreur : %s", ctx.tech.Script, event, err) end
end

function FxCore:Init()
    DS.Net.On("TechStart", function(caster, kind, setId, slot, x, y, z, yaw, instance)
        local tech = DS.Catalog.GetTechnique(kind, setId, slot)
        if tech and tech.Script then
            Choreo.Start(caster, tech, x, y, z, yaw, instance)
        end
    end)
    DS.Net.On("TechEvent", function(instance, event, x, y, z, target)
        Choreo.Event(instance, event, x, y, z, target)
    end)
end

return FxCore
