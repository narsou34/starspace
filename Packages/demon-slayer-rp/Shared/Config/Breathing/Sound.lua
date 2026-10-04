--[[
    Demon Slayer RP - Souffle du Son (Oto no Kokyu) - Tengen Uzui
    ------------------------------------------------------------------
    Dérivé du Tonnerre : deux couperets reliés par une chaîne, et des
    billes explosives qui détonent en rythme. Identité : EXPLOSIONS
    rythmées, ondes sonores, étincelles dorées.

    Comportements génériques : voir Server/Systems/Techniques/Generic.lua.
]]

local function L(asset, scale, life, extra)
    local layer = { Asset = "nanos-world::" .. asset, Scale = scale, Life = life }
    for k, v in pairs(extra or {}) do layer[k] = v end
    return layer
end
local function S(asset, volume, pitch, life)
    return { Asset = "nanos-world::" .. asset, Volume = volume, Pitch = pitch, Life = life, FadeOut = life and 0.3 or nil }
end

local CHOP = "nanos-world::A_Mannequin_Taunt_Chop"
local SPIN = "nanos-world::A_Mannequin_Taunt_Kunfu"
local THROW = "nanos-world::A_Mannequin_Throw_01"
local FLEX = "nanos-world::A_Mannequin_Taunt_Flex_02"
local SHOUT = "nanos-world::A_Mannequin_Shout"

local BOOM = { L("P_Explosive_02", 1.0, 1.6), L("P_ShockWave_05", 0.9, 1.0), L("P_SparksFlair", 0.8, 1.2, { Priority = "detail" }) }
local BOOM_SOUNDS = { S("A_Explosion_Small", 0.8, 1.15), S("A_MetalHeavy_Impact_MS", 0.6, 1.3) }
local HIT = { L("P_Sparks", 0.9, 0.8), L("P_FXVariety_Hit_01", 0.8, 0.8, { Priority = "detail" }) }
local HIT_SOUNDS = { S("A_Flesh_Impact_MS", 0.8, 1.0), S("A_MetalHeavy_Impact_MS", 0.5, 1.4) }

Config.BreathingStyles.son = {
    Name = "Souffle du Son",
    Description = "Derive du tonnerre. Couperets jumeaux et billes explosives : chaque coup est une detonation.",
    Color = "yellow",
    BlockRegenMs = 2500,
    BladeTrail = { Bone = "hand_r", Layers = { "nanos-world::P_Streamer", "nanos-world::P_SparksFlair" }, DurationMs = 600 },

    Techniques = {
        -- [Q] Explosions en ligne qui partent du sol devant le lanceur
        {
            Form = 1, Script = "bursts",
            Name = "Premiere forme : Rugissement",
            Description = "Le couperet frappe le sol : une ligne de detonations jaillit droit devant.",
            Shape = "self", Range = 900, Damage = 16, Cost = 16, CooldownMs = 5000,
            Timeline = { WindupMs = 300 },
            Bursts = { Type = "line", Count = 4, Start = 220, Spacing = 220, IntervalMs = 90, Radius = 220, Damage = 16, Knockback = 450, Lift = 250 },
            Hit = { MaxTargets = 8 },
            Animation = { Windup = CHOP, Slot = "FullBody" },
            Camera = { Fov = 5, DurationMs = 400 },
            Fx = {
                Cast = { L("P_SparksFlair", 0.7, 0.6) }, CastSounds = { S("A_Whoosh", 0.8, 0.9) },
                Burst = BOOM, BurstSounds = BOOM_SOUNDS, Hit = HIT, HitSounds = HIT_SOUNDS,
            },
        },
        -- [E] Rotation des deux couperets : 6 coups circulaires, chacun détone
        {
            Form = 4, Script = "combo",
            Name = "Quatrieme forme : Tranchants resonnants",
            Description = "Les couperets tournoient autour de vous : six coups, six explosions.",
            Shape = "self", Range = 340, Damage = 6, Cost = 18, CooldownMs = 7000,
            Timeline = { WindupMs = 200 },
            Combo = { Count = 6, IntervalMs = 160, Shape = "circle", Range = 340 },
            Hit = { Damage = 6, Knockback = 250, Lift = 120, MaxTargets = 8 },
            Animation = { Windup = SPIN, Slot = "FullBody" },
            Camera = { Fov = 4, DurationMs = 900 },
            Fx = {
                Body = { L("P_Explosive_05", 0.7, 0.9), L("P_ShockWave_03", 0.6, 0.7, { Priority = "detail" }) },
                Strike = { S("A_Explosion_Small", 0.5, 1.4), S("A_Whoosh", 0.6, 1.3) },
                Hit = HIT, HitSounds = HIT_SOUNDS,
            },
        },
        -- [R] Trois billes explosives lancées en éventail
        {
            Form = 5, Script = "projectiles",
            Name = "Cinquieme forme : Representation des cordes",
            Description = "Trois billes explosives filent en eventail et detonent a l'impact.",
            Shape = "self", Range = 1500, Damage = 12, Cost = 20, CooldownMs = 8000,
            Timeline = { WindupMs = 280 },
            Projectiles = {
                Count = 3, SpreadDeg = 30, Speed = 1900, Radius = 70, MaxDistance = 1500,
                SpawnForward = 100, SpawnHeight = 50,
                Explosion = { Radius = 260, Damage = 14, Knockback = 600, Lift = 300 },
            },
            Hit = { Damage = 12, MaxTargets = 8 },
            Animation = { Windup = THROW, Slot = "UpperBody" },
            Camera = { Fov = 4, DurationMs = 300 },
            Fx = {
                Body = { L("P_FXVariety_ThunderBall", 0.45, 1) },
                Attach = { L("P_Streamer", 0.6, 1) },
                Trail = { L("P_Sparks", 0.4, 0.5) }, TrailEveryMs = 110,
                Strike = { S("A_Whoosh", 0.8, 1.2) },
                Burst = { L("P_Explosive_07", 1.1, 1.6), L("P_ShockWave_06", 1.0, 1.0), L("P_Smoke_02", 0.8, 2.0, { Priority = "detail" }) },
                BurstSounds = { S("A_Explosion_Small", 0.9, 1.0) },
                Hit = HIT, HitSounds = HIT_SOUNDS,
            },
        },
        -- [F] La Partition : analyse du rythme ennemi -> renforcement + pulsations sonores
        {
            Form = 0, Script = "buff",
            Name = "Partition (Fumen)",
            Description = "Vous decodez le rythme de l'ennemi : vitesse et puissance accrues, ondes sonores autour de vous.",
            Shape = "self", Range = 300, Damage = 5, Cost = 25, CooldownMs = 20000,
            Timeline = { WindupMs = 500 },
            Buff = { SpeedMultiplier = 1.25, DamageMultiplier = 1.3, DurationMs = 8000 },
            Aura = { Radius = 300, TickMs = 1000, DurationMs = 8000, Damage = 5, Knockback = 350, Lift = 100 },
            Hit = { MaxTargets = 8 },
            Animation = { Windup = FLEX, Slot = "UpperBody" },
            Camera = { Fov = 6, DurationMs = 600 },
            Fx = {
                Cast = { L("P_FXVariety_MagicCircle", 1.4, 1.5) }, CastSounds = { S("A_Male_Breath_Quick_Cue", 0.6, 1.0) },
                Body = { L("P_ShockWave_08", 1.2, 1.0) },
                Attach = { L("P_FlareShimmer_01", 0.8, 1, { Bone = "pelvis" }), L("P_SparksFlair", 0.6, 1, { Bone = "hand_r" }) },
                Trail = { L("P_ShockWave_02", 0.8, 0.8) }, TrailEveryMs = 1000,
                Strike = { S("A_Explosion_Small", 0.4, 1.6) },
                Hit = HIT, HitSounds = HIT_SOUNDS,
            },
        },
        -- [X] Ultime : trois anneaux de détonations de plus en plus larges
        {
            Form = 0, Script = "bursts",
            Name = "Ultime : Concert explosif",
            Description = "Vous dechainez toutes les billes : trois anneaux d'explosions balaient la zone.",
            Shape = "self", Range = 750, Damage = 26, Cost = 55, CooldownMs = 40000,
            Requirements = { Level = 10 },
            Timeline = { WindupMs = 900 },
            Bursts = {
                Type = "rings", Radius = 220, Damage = 26, Knockback = 800, Lift = 450,
                Rings = {
                    { Radius = 220, Count = 5, DelayMs = 0 },
                    { Radius = 480, Count = 8, DelayMs = 260, Damage = 22 },
                    { Radius = 740, Count = 11, DelayMs = 520, Damage = 18 },
                },
            },
            Hit = { MaxTargets = 12 },
            Caster = { InvulnerableDuringWindup = true, RootDuringWindup = true },
            Animation = { Windup = SHOUT, Release = CHOP, Slot = "FullBody" },
            Camera = { Fov = 12, ArmLength = 250, DurationMs = 1400 },
            Fx = {
                Cast = { L("P_FXVariety_MagicCircle", 2.4, 1.2), L("P_SparksFlair", 1.2, 1.0) },
                CastSounds = { S("A_Male_Breath_Quick_Cue", 0.8, 0.85), S("A_WhiteNoise", 0.15, 1.6, 0.9) },
                Burst = { L("P_Explosive_09", 1.2, 1.8), L("P_ShockWave_10", 1.0, 1.0), L("P_Smoke_05", 0.9, 2.5, { Priority = "detail" }) },
                BurstSounds = { S("A_Explosion_Small", 0.7, 0.9) },
                Hit = HIT, HitSounds = HIT_SOUNDS,
            },
        },
    },
}
