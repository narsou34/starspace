--[[
    Demon Slayer RP - Sons et caméra des VFX (client)
    ------------------------------------------------------------------
    VFX.Sound.Play(asset, x, y, z, opts)    son positionné (volume, hauteur, fondu, attache)
    VFX.Sound.Set(list, x, y, z, opts)      joue une liste de sons d'élément
    VFX.Camera.Fov(delta, ms)               élargit le champ de vision (vitesse / puissance)
    VFX.Camera.Pull(delta, ms)              recule la caméra (techniques géantes)
    VFX.Camera.Kick(delta)                  "coup" bref à l'impact

    La caméra n'est modifiée que pour le joueur local, avec des limites
    (Config.Vfx.MaxFovDelta / MaxArmLengthDelta) et toujours restaurée.
]]

local VFX = DS.VFX

-- ===========================================================================
-- Sons
-- ===========================================================================

local Sound_ = {}
VFX.Sound = Sound_

function Sound_.Play(asset, x, y, z, opts)
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

--- Joue une liste { { Asset, Volume, Pitch, Life, FadeOut, Falloff }, ... } avec une légère variation.
function Sound_.Set(list, x, y, z, opts)
    if not list then return end
    opts = opts or {}
    for _, s in ipairs(list) do
        Sound_.Play(s.Asset, x, y, z, {
            volume = (s.Volume or 1) * (opts.volume or 1),
            pitch = (s.Pitch or 1) * (opts.pitch or 1) * (0.95 + math.random() * 0.1),
            life = s.Life, fadeOut = s.FadeOut, falloff = s.Falloff or opts.falloff,
            attach = opts.attach,
        })
    end
end

-- ===========================================================================
-- Caméra (joueur local)
-- ===========================================================================

local Camera = {}
VFX.Camera = Camera

local BASE_FOV = 90
local fovStack, armStack = {}, {}
local nextId = 0

local function apply()
    local player = Client.GetLocalPlayer()
    if not player then return end
    local fov, arm = 0, 0
    for _, v in pairs(fovStack) do fov = math.max(fov, v) end
    for _, v in pairs(armStack) do arm = math.max(arm, v) end
    pcall(player.SetCameraFOV, player, BASE_FOV + math.min(fov, Config.Vfx.MaxFovDelta))
    local ok, base = pcall(player.GetCameraArmLength, player, true)
    if ok and base then
        pcall(player.SetCameraArmLength, player, base + math.min(arm, Config.Vfx.MaxArmLengthDelta), false)
    end
end

local function push(stack, delta, durationMs)
    if not Config.Vfx.CameraEffects or not delta or delta <= 0 then return end
    nextId = nextId + 1
    local id = nextId
    stack[id] = delta
    apply()
    Timer.SetTimeout(function() stack[id] = nil; apply() end, math.floor(durationMs))
end

function Camera.Fov(delta, durationMs) push(fovStack, delta, durationMs or 300) end
function Camera.Pull(delta, durationMs) push(armStack, delta, durationMs or 600) end
function Camera.Kick(delta) push(fovStack, delta, 160) end

return Sound_
