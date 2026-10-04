--[[
    Demon Slayer RP - Souffle de l'Amour (Koi no Kokyu) - Mitsuri Kanroji
    ------------------------------------------------------------------
    Dérivé de la Flamme. Lame ultra-fine et souple comme un FOUET : portée
    énorme, arcs très larges, mouvements acrobatiques. Identité : rubans
    roses ondulants, éclats scintillants, fouettements rapides.
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
local HEART = "nanos-world::A_Mannequin_Taunt_Heart"

local LASH = { L("P_Ribbon", 1.0, 0.9), L("P_Burst_01", 0.6, 0.8), L("P_FlareShimmer_01", 0.6, 0.9, { Priority = "detail" }) }
local LASH_SOUNDS = { S("A_Whoosh", 0.8, 1.45), S("A_Whoosh", 0.4, 1.9) }
local HIT = { L("P_Burst_02", 0.7, 0.8), L("P_FlareShimmer_01", 0.6, 0.8, { Priority = "detail" }) }
local HIT_SOUNDS = { S("A_Flesh_Impact_MS", 0.8, 1.1), S("A_Punch_Cue", 0.5, 1.3) }

Config.BreathingStyles.amour = {
    Name = "Souffle de l'Amour",
    Description = "Derive de la flamme. Une lame souple comme un fouet, aux arcs immenses et imprevisibles.",
    Color = "purple",
    BlockRegenMs = 2500,
    BladeTrail = { Bone = "hand_r", Layers = { "nanos-world::P_Ribbon", "nanos-world::P_FlareShimmer_01" }, DurationMs = 700 },

    Techniques = {
        -- [Q] Trois bonds rapides en fouettant
        {
            Form = 1, Script = "dashchain",
            Name = "Premiere forme : Frissons du premier amour",
            Description = "Trois bonds fulgurants, la lame-fouet balayant tout autour.",
            Shape = "self", Range = 550, Damage = 10, Cost = 16, CooldownMs = 5000,
            Timeline = { WindupMs = 150 },
            Dash = { Count = 3, IntervalMs = 260, AngleOffsets = { 0, -20, 20 }, Impulse = 1100, Lift = 140,
                     Distance = 550, Width = 420, InvulnerableMs = 150, MaxHits = 3 },
            Hit = { Damage = 10, Knockback = 350, Lift = 150, MaxTargets = 6 },
            Animation = { Windup = SPIN, Slot = "FullBody" },
            Camera = { Fov = 8, DurationMs = 900 },
            Fx = {
                Body = LASH, Attach = { L("P_Ribbon", 0.7, 1, { Bone = "foot_r" }) },
                Trail = { L("P_FlareShimmer_02", 0.5, 0.9) }, TrailEveryMs = 80,
                Strike = LASH_SOUNDS, Hit = HIT, HitSounds = HIT_SOUNDS,
            },
        },
        -- [E] Arcs de fouet immenses devant soi
        {
            Form = 2, Script = "combo",
            Name = "Deuxieme forme : Peines d'amour",
            Description = "Trois fouettements en eventail, d'une portee immense.",
            Shape = "self", Range = 600, Damage = 9, Cost = 15, CooldownMs = 4500,
            Timeline = { WindupMs = 220 },
            Combo = { Count = 3, IntervalMs = 170, Shape = "arc", Range = 600, Angle = 160 },
            Hit = { Damage = 9, Knockback = 300, Lift = 100, MaxTargets = 8 },
            Animation = { Windup = CHOP, Slot = "UpperBody" },
            Camera = { Fov = 5, DurationMs = 600 },
            Fx = { Body = LASH, Strike = LASH_SOUNDS, Hit = HIT, HitSounds = HIT_SOUNDS },
        },
        -- [R] Le fouet s'étend au loin en ondulant puis revient
        {
            Form = 3, Script = "whip",
            Name = "Troisieme forme : Averse feline",
            Description = "La lame s'etire au loin en ondulant puis revient, frappant a l'aller comme au retour.",
            Shape = "self", Range = 1000, Damage = 12, Cost = 18, CooldownMs = 6000,
            Timeline = { WindupMs = 200 },
            Whip = { Path = "sine", Distance = 1000, Amplitude = 160, Waves = 2, Return = true,
                     DurationMs = 800, Radius = 120, MaxHitsPerTarget = 2, HitIntervalMs = 250 },
            Hit = { Damage = 12, Knockback = 300, Lift = 120, MaxTargets = 6 },
            Animation = { Windup = THROW, Slot = "UpperBody" },
            Camera = { Fov = 5, DurationMs = 800 },
            Fx = {
                Body = { L("P_FlareShimmer_01", 0.8, 1), L("P_Burst_01", 0.4, 1, { Priority = "detail" }) },
                Attach = { L("P_Ribbon", 1.0, 1), L("P_Streamer", 0.8, 1) },
                Trail = { L("P_FlareShimmer_02", 0.4, 0.6) }, TrailEveryMs = 80,
                Strike = { S("A_Whoosh", 0.9, 1.3) }, Hit = HIT, HitSounds = HIT_SOUNDS,
            },
        },
        -- [F] Tourbillon de fouet tout autour
        {
            Form = 5, Script = "combo",
            Name = "Cinquieme forme : Griffes sauvages de l'amour",
            Description = "La lame tourbillonne autour de vous en quatre fouettements circulaires.",
            Shape = "self", Range = 480, Damage = 8, Cost = 20, CooldownMs = 7000,
            Timeline = { WindupMs = 180 },
            Combo = { Count = 4, IntervalMs = 180, Shape = "circle", Range = 480 },
            Hit = { Damage = 8, Knockback = 450, Lift = 180, MaxTargets = 8 },
            Animation = { Windup = SPIN, Slot = "FullBody" },
            Camera = { Fov = 6, DurationMs = 800 },
            Fx = {
                Body = { L("P_OmnidirectionalBurst", 0.8, 0.8), L("P_Ribbon", 1.2, 0.9), L("P_FlareShimmer_01", 0.8, 0.9, { Priority = "detail" }) },
                Strike = LASH_SOUNDS, Hit = HIT, HitSounds = HIT_SOUNDS,
            },
        },
        -- [X] Ultime : tempête de fouets qui suit Mitsuri
        {
            Form = 6, Script = "zone",
            Name = "Ultime : Vents de l'amour",
            Description = "Une tempete de fouettements vous entoure et vous suit, broyant tout pendant 4 secondes.",
            Shape = "self", Range = 520, Damage = 7, Cost = 50, CooldownMs = 35000,
            Requirements = { Level = 10 },
            Timeline = { WindupMs = 500 },
            Zone = { Follow = true, Radius = 520, Height = 350, DurationMs = 4000, TickMs = 350,
                     Pull = -350, Lift = 150,
                     FinalBurst = { Damage = 20, Knockback = 1000, Lift = 450 } },
            Hit = { Damage = 7, MaxTargets = 12 },
            Caster = { InvulnerableDuringWindup = true },
            Animation = { Windup = HEART, Release = SPIN, Slot = "FullBody" },
            Camera = { Fov = 10, ArmLength = 200, DurationMs = 4200 },
            Fx = {
                Cast = { L("P_FlareShimmer_01", 1.4, 1.0), L("P_FXVariety_MagicCircle", 1.6, 1.0) },
                CastSounds = { S("A_Male_Breath_Quick_Cue", 0.6, 1.3) },
                Body = { L("P_Ribbon", 1.6, 4, { Bone = "hand_r" }), L("P_Streamer", 1.4, 4, { Bone = "hand_l" }),
                         L("P_FlareShimmer_02", 1.2, 4, { Bone = "pelvis" }) },
                Orbit = { Asset = "nanos-world::P_Ribbon", Count = 6, Scale = 1.0, Speed = 7, RiseSpeed = 0.6 },
                Trail = { L("P_Burst_01", 0.7, 0.8), L("P_FlareShimmer_01", 0.6, 0.8) }, TrailEveryMs = 120,
                Strike = { S("A_WhiteNoise", 0.12, 2.0, 4), S("A_Whoosh", 0.9, 1.2) },
                Burst = { L("P_OmnidirectionalBurst", 1.8, 1.4), L("P_Burst_02", 1.6, 1.2), L("P_ShockWave_07", 1.5, 1.0) },
                BurstSounds = { S("A_Explosion_Small", 0.5, 1.6), S("A_Whoosh", 1.0, 1.0) },
                Hit = HIT, HitSounds = HIT_SOUNDS,
            },
        },
    },
}
