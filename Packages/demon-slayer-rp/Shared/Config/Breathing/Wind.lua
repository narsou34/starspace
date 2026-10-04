--[[
    Demon Slayer RP - Souffle du Vent (Kaze no Kokyu) - Sanemi Shinazugawa
    ------------------------------------------------------------------
    Style brutal et agressif : chaque coup porte une bourrasque tranchante.
    Identité : TORNADES, lames de vent projetées, griffes d'air, poussière,
    distorsions, puissantes projections.
]]

local function L(asset, scale, life, extra)
    local layer = { Asset = "nanos-world::" .. asset, Scale = scale, Life = life }
    for k, v in pairs(extra or {}) do layer[k] = v end
    return layer
end
local function S(asset, volume, pitch, life)
    return { Asset = "nanos-world::" .. asset, Volume = volume, Pitch = pitch, Life = life, FadeOut = life and 0.4 or nil }
end

local CHOP = "nanos-world::A_Mannequin_Taunt_Chop"
local SPIN = "nanos-world::A_Mannequin_Taunt_Kunfu"
local THROW = "nanos-world::A_Mannequin_Throw_02"
local SHOUT = "nanos-world::A_Mannequin_Shout"

local GUST = { L("P_FXVariety_Storm", 0.9, 1.0), L("P_ShockWave_03", 0.8, 0.8), L("P_Smoke_02", 0.6, 1.4, { Priority = "detail" }) }
local GUST_SOUNDS = { S("A_Whoosh", 1.0, 0.8), S("A_WhiteNoise", 0.2, 1.2, 0.5) }
local HIT = { L("P_ShockWave_01", 0.6, 0.6), L("P_FXVariety_Hit_01", 0.7, 0.7), L("P_Smoke_01", 0.5, 1.0, { Priority = "detail" }) }
local HIT_SOUNDS = { S("A_Flesh_Impact_MS", 0.8, 0.9), S("A_Body_Impact_Cue", 0.5, 1.0) }

Config.BreathingStyles.vent = {
    Name = "Souffle du Vent",
    Description = "Un style brutal : chaque coup de lame dechaine une bourrasque tranchante.",
    Color = "green",
    BlockRegenMs = 2500,
    BladeTrail = { Bone = "hand_r", Layers = { "nanos-world::P_Streamer", "nanos-world::P_Distortion_01" }, DurationMs = 600 },

    Techniques = {
        -- [Q] Élan en spirale : tourbillon tranchant
        {
            Form = 1, Script = "dash",
            Name = "Premiere forme : Tourbillon tranchant",
            Description = "Vous fondez sur l'ennemi au coeur d'un tourbillon de vent tranchant.",
            Shape = "self", Range = 800, Damage = 22, Cost = 15, CooldownMs = 4500,
            Timeline = { WindupMs = 160 },
            Dash = { Impulse = 1700, Lift = 150, Distance = 800, Width = 300, InvulnerableMs = 250 },
            Hit = { Damage = 22, Knockback = 650, Lift = 300, MaxTargets = 5 },
            Animation = { Windup = SPIN, Slot = "FullBody" },
            Camera = { Fov = 10, DurationMs = 500 },
            Fx = {
                Body = { L("P_FXVariety_Storm", 1.2, 1.2), L("P_ShockWave_05", 1.0, 0.8) },
                Attach = { L("P_Distortion_01", 1.0, 1, { Bone = "pelvis" }), L("P_Streamer", 0.8, 1, { Bone = "hand_r" }) },
                Trail = { L("P_Smoke_02", 0.6, 1.2), L("P_FXVariety_Storm", 0.5, 0.6, { Priority = "detail" }) }, TrailEveryMs = 70,
                Strike = GUST_SOUNDS, Hit = HIT, HitSounds = HIT_SOUNDS,
            },
        },
        -- [E] Quatre griffes de vent projetées
        {
            Form = 2, Script = "combo",
            Name = "Deuxieme forme : Griffes purificatrices",
            Description = "Quatre entailles de vent jaillissent devant vous comme des griffes.",
            Shape = "self", Range = 650, Damage = 7, Cost = 15, CooldownMs = 4000,
            Timeline = { WindupMs = 180 },
            Combo = { Count = 4, IntervalMs = 90, Shape = "line", Range = 650, Width = 260 },
            Hit = { Damage = 7, Knockback = 250, Lift = 80, MaxTargets = 6 },
            Animation = { Windup = CHOP, Slot = "UpperBody" },
            Camera = { Fov = 4, DurationMs = 400 },
            Fx = {
                Body = { L("P_ShockWave_07", 0.7, 0.6), L("P_DirectionalBurst", 0.7, 0.7) },
                Strike = { S("A_Whoosh", 0.8, 1.1) }, Hit = HIT, HitSounds = HIT_SOUNDS,
            },
        },
        -- [R] Lame de vent qui traverse tout
        {
            Form = 5, Script = "projectiles",
            Name = "Cinquieme forme : Vent froid de montagne",
            Description = "Une lame de vent geante file au loin et traverse tous les ennemis.",
            Shape = "self", Range = 1500, Damage = 20, Cost = 18, CooldownMs = 6000,
            Timeline = { WindupMs = 250 },
            Projectiles = { Count = 1, SpreadDeg = 0, Speed = 2600, Radius = 170, MaxDistance = 1500, Pierce = true,
                            SpawnForward = 100, SpawnHeight = 60 },
            Hit = { Damage = 20, Knockback = 500, Lift = 200, MaxTargets = 8 },
            Animation = { Windup = THROW, Slot = "UpperBody" },
            Camera = { Fov = 5, DurationMs = 400 },
            Fx = {
                Body = { L("P_FXVariety_Storm", 1.0, 1), L("P_ShockWave_07", 0.9, 1) },
                Attach = { L("P_Streamer", 1.2, 1), L("P_Distortion_02", 0.9, 1) },
                Trail = { L("P_Smoke_01", 0.6, 1.0) }, TrailEveryMs = 70,
                Strike = { S("A_Whoosh", 1.0, 0.7), S("A_Thruster_03", 0.3, 1.5, 0.6) },
                Burst = { L("P_ShockWave_06", 1.0, 0.8), L("P_Smoke_03", 0.8, 1.5) },
                Hit = HIT, HitSounds = HIT_SOUNDS,
            },
        },
        -- [F] Tornade qui repousse et lacère
        {
            Form = 3, Script = "zone",
            Name = "Troisieme forme : Arbre de la tempete purificatrice",
            Description = "Une tornade se dresse devant vous, lacerant et repoussant les ennemis.",
            Shape = "self", Range = 400, Damage = 6, Cost = 22, CooldownMs = 10000,
            Timeline = { WindupMs = 350 },
            Zone = { Forward = 350, Radius = 400, Height = 700, DurationMs = 2800, TickMs = 350,
                     Pull = -500, Lift = 350,
                     FinalBurst = { Damage = 16, Knockback = 1100, Lift = 600 } },
            Hit = { Damage = 6, MaxTargets = 8 },
            Animation = { Windup = SPIN, Slot = "FullBody" },
            Camera = { Fov = 6, DurationMs = 600 },
            Fx = {
                Body = { L("P_FXVariety_Storm", 2.4, 3, { Priority = "main" }), L("P_FXVariety_DarkStorm", 1.6, 3, { Up = 250 }),
                         L("P_Smoke_06", 1.6, 3.5) },
                Orbit = { Asset = "nanos-world::P_Smoke_02", Count = 6, Scale = 0.7, Speed = 8, RiseSpeed = 0.7 },
                Trail = { L("P_ShockWave_02", 0.6, 0.7), L("P_Smoke_01", 0.6, 1.2) }, TrailEveryMs = 160,
                Strike = { S("A_WhiteNoise", 0.35, 0.8, 2.8), S("A_Thruster_01", 0.3, 0.6, 2.8) },
                Burst = { L("P_ShockWave_12", 1.8, 1.0), L("P_FXVariety_Storm", 2.0, 1.2), L("P_Smoke_07", 1.6, 2.5) },
                BurstSounds = { S("A_Explosion_Small", 0.6, 0.7), S("A_Whoosh", 1.0, 0.6) },
                Hit = HIT, HitSounds = HIT_SOUNDS,
            },
        },
        -- [X] Ultime : typhon autour de Sanemi
        {
            Form = 9, Script = "zone",
            Name = "Ultime : Typhon Idaten",
            Description = "Vous devenez l'oeil d'un typhon : tout ce qui vous entoure est souleve et dechiquete.",
            Shape = "self", Range = 650, Damage = 9, Cost = 55, CooldownMs = 40000,
            Requirements = { Level = 10 },
            Timeline = { WindupMs = 800 },
            Zone = { Follow = true, Radius = 650, Height = 900, DurationMs = 3500, TickMs = 400,
                     Pull = 300, Lift = 450,
                     FinalBurst = { Damage = 28, Knockback = 1600, Lift = 800 } },
            Hit = { Damage = 9, MaxTargets = 12 },
            Caster = { InvulnerableDuringWindup = true, RootDuringWindup = true },
            Animation = { Windup = SHOUT, Release = SPIN, Slot = "FullBody" },
            Camera = { Fov = 14, ArmLength = 300, DurationMs = 3800 },
            Fx = {
                Cast = { L("P_FXVariety_MagicCircle", 2.4, 1.2), L("P_Smoke_06", 1.8, 1.5) },
                CastSounds = { S("A_Male_Breath_Quick_Cue", 0.8, 0.8), S("A_WhiteNoise", 0.2, 0.6, 1.0) },
                Body = { L("P_FXVariety_DarkStorm", 2.8, 3.5, { Bone = "pelvis" }), L("P_FXVariety_Storm", 2.4, 3.5, { Bone = "pelvis" }),
                         L("P_Distortion_3D", 1.6, 3.5, { Bone = "pelvis" }) },
                Orbit = { Asset = "nanos-world::P_FXVariety_Storm", Count = 5, Scale = 0.8, Speed = 9, RiseSpeed = 0.8 },
                Trail = { L("P_Smoke_02", 0.9, 1.5), L("P_ShockWave_04", 0.8, 0.8) }, TrailEveryMs = 140,
                Strike = { S("A_WhiteNoise", 0.4, 0.55, 3.5), S("A_Thruster_04", 0.35, 0.5, 3.5) },
                Burst = { L("P_ShockWave_14", 2.6, 1.2), L("P_FXVariety_DarkStorm", 2.6, 1.4), L("P_Smoke_07", 2.2, 3) },
                BurstSounds = { S("A_Explosion_Large", 0.7, 0.8), S("A_Whoosh", 1.0, 0.5) },
                Hit = HIT, HitSounds = HIT_SOUNDS,
            },
        },
    },
}
