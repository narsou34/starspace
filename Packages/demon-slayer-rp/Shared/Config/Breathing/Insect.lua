--[[
    Demon Slayer RP - Souffle de l'Insecte (Mushi no Kokyu) - Shinobu Kocho
    ------------------------------------------------------------------
    Trop peu de force pour décapiter un démon : la lame fine injecte du
    poison de glycine. Identité : ESTOCS fulgurants, POISON (dégâts dans le
    temps, régénération bloquée longtemps), papillons scintillants violets.
]]

local function L(asset, scale, life, extra)
    local layer = { Asset = "nanos-world::" .. asset, Scale = scale, Life = life }
    for k, v in pairs(extra or {}) do layer[k] = v end
    return layer
end
local function S(asset, volume, pitch, life)
    return { Asset = "nanos-world::" .. asset, Volume = volume, Pitch = pitch, Life = life, FadeOut = life and 0.3 or nil }
end

local THRUST = "nanos-world::A_Mannequin_Taunt_HandPunch"
local CHOP = "nanos-world::A_Mannequin_Taunt_Chop"
local SPIN = "nanos-world::A_Mannequin_Taunt_Kunfu"
local GRACE = "nanos-world::A_Mannequin_Taunt_Salute_01"

-- Poison de glycine : dégâts toutes les 0,5 s + régénération bloquée (BlockRegenMs du souffle)
local POISON = { Damage = 3, TickMs = 500, DurationMs = 4000 }
local POISON_STRONG = { Damage = 5, TickMs = 500, DurationMs = 7000 }

local BUTTERFLY = { L("P_FlareShimmer_02", 0.8, 1.2), L("P_SparksFlair", 0.5, 0.8, { Priority = "detail" }) }
local HIT = { L("P_FlareShimmer_01", 0.7, 1.0), L("P_FXVariety_Hit_02", 0.6, 0.6) }
local HIT_SOUNDS = { S("A_Flesh_Impact_MS", 0.7, 1.3), S("A_Whoosh", 0.4, 1.8) }

Config.BreathingStyles.insecte = {
    Name = "Souffle de l'Insecte",
    Description = "Estocs d'une vitesse extreme charges de poison de glycine. Redoutable contre les demons.",
    Color = "purple",
    BlockRegenMs = 7000,
    BonusVsDemons = 1.5,
    BladeTrail = { Bone = "hand_r", Layers = { "nanos-world::P_FlareShimmer_01", "nanos-world::P_Streamer" }, DurationMs = 500 },

    Techniques = {
        -- [Q] Élan-estoc : traverse la cible en lui injectant du poison
        {
            Form = 1, Script = "dash",
            Name = "Danse du papillon : Caprice",
            Description = "Un bond leger comme un papillon et un estoc empoisonne.",
            Shape = "self", Range = 700, Damage = 10, Cost = 12, CooldownMs = 3500,
            Timeline = { WindupMs = 120 },
            Dash = { Impulse = 1500, Lift = 120, Distance = 700, Width = 160, InvulnerableMs = 250 },
            Hit = { Damage = 10, Poison = POISON, MaxTargets = 3 },
            Animation = { Windup = THRUST, Slot = "UpperBody" },
            Camera = { Fov = 8, DurationMs = 400 },
            Fx = {
                Body = BUTTERFLY, Attach = { L("P_FlareShimmer_01", 0.7, 1, { Bone = "hand_r" }) },
                Trail = { L("P_FlareShimmer_02", 0.5, 0.9) }, TrailEveryMs = 70,
                Strike = { S("A_Whoosh", 0.8, 1.6) },
                Hit = HIT, HitSounds = HIT_SOUNDS,
            },
        },
        -- [E] Trois piqûres en ligne d'une rapidité extrême
        {
            Form = 2, Script = "combo",
            Name = "Danse de l'abeille : Dard",
            Description = "Trois piqures fulgurantes en ligne droite, chacune empoisonnee.",
            Shape = "self", Range = 480, Damage = 6, Cost = 14, CooldownMs = 4500,
            Timeline = { WindupMs = 150 },
            Combo = { Count = 3, IntervalMs = 110, Shape = "line", Range = 480, Width = 130 },
            Hit = { Damage = 6, Poison = POISON, MaxTargets = 3 },
            Animation = { Windup = THRUST, Slot = "UpperBody" },
            Camera = { Fov = 4, DurationMs = 400 },
            Fx = {
                Body = { L("P_DirectionalBurst", 0.5, 0.7), L("P_FlareShimmer_02", 0.5, 0.8, { Priority = "detail" }) },
                Strike = { S("A_Whoosh", 0.6, 1.9) },
                Hit = HIT, HitSounds = HIT_SOUNDS,
            },
        },
        -- [R] Six piqûres en un instant sur une cible proche
        {
            Form = 3, Script = "combo",
            Name = "Danse de la libellule : Hexagone",
            Description = "Six piqures en un instant, dessinant un hexagone dans la chair.",
            Shape = "self", Range = 320, Damage = 4, Cost = 18, CooldownMs = 7000,
            Timeline = { WindupMs = 180 },
            Combo = { Count = 6, IntervalMs = 70, Shape = "arc", Range = 320, Angle = 50 },
            Hit = { Damage = 4, Poison = POISON_STRONG, Slow = { Multiplier = 0.7, DurationMs = 2000 }, MaxTargets = 2 },
            Animation = { Windup = THRUST, Slot = "UpperBody" },
            Camera = { Fov = 5, DurationMs = 500 },
            Fx = {
                Body = { L("P_FlareShimmer_01", 0.6, 0.6), L("P_Sparks", 0.4, 0.5, { Priority = "detail" }) },
                Strike = { S("A_Whoosh", 0.5, 2.0) },
                Hit = HIT, HitSounds = HIT_SOUNDS,
            },
        },
        -- [F] Zigzag du mille-pattes : quatre élans alternés
        {
            Form = 5, Script = "dashchain",
            Name = "Danse du mille-pattes : Zigzag",
            Description = "Quatre bonds en zigzag, insaisissables, qui piquent tout sur leur passage.",
            Shape = "self", Range = 500, Damage = 7, Cost = 22, CooldownMs = 9000,
            Timeline = { WindupMs = 120 },
            Dash = { Count = 4, IntervalMs = 220, AngleOffsets = { -35, 35, -35, 35 }, Impulse = 1200, Lift = 80,
                     Distance = 500, Width = 180, InvulnerableMs = 200, MaxHits = 2 },
            Hit = { Damage = 7, Poison = POISON, MaxTargets = 6 },
            Animation = { Windup = SPIN, Slot = "UpperBody" },
            Camera = { Fov = 10, DurationMs = 1000 },
            Fx = {
                Body = BUTTERFLY, Attach = { L("P_Ribbon", 0.6, 1, { Bone = "foot_l" }), L("P_Ribbon", 0.6, 1, { Bone = "foot_r" }) },
                Trail = { L("P_FlareShimmer_02", 0.4, 0.8) }, TrailEveryMs = 60,
                Strike = { S("A_Whoosh", 0.7, 1.7) },
                Hit = HIT, HitSounds = HIT_SOUNDS,
            },
        },
        -- [X] Ultime : nuage de poison de glycine
        {
            Form = 0, Script = "zone",
            Name = "Ultime : Brume de glycine",
            Description = "Un nuage de poison concentre envahit la zone : ralentit, empoisonne et empeche toute regeneration.",
            Shape = "self", Range = 480, Damage = 2, Cost = 50, CooldownMs = 35000,
            Requirements = { Level = 10 },
            Timeline = { WindupMs = 700 },
            Zone = { Forward = 500, Radius = 480, Height = 400, DurationMs = 5000, TickMs = 500,
                     Pull = 0, Lift = 0, Slow = { Multiplier = 0.5, DurationMs = 800 },
                     Poison = { Damage = 6, TickMs = 500, DurationMs = 3000 },
                     FinalBurst = { Damage = 12, Knockback = 400, Lift = 200, Poison = POISON_STRONG } },
            Hit = { Damage = 2, MaxTargets = 12 },
            Caster = { InvulnerableDuringWindup = true },
            Animation = { Windup = GRACE, Release = CHOP, Slot = "UpperBody" },
            Camera = { Fov = 8, ArmLength = 180, DurationMs = 1200 },
            Fx = {
                Cast = { L("P_FXVariety_MagicCircle", 1.6, 1.0), L("P_FlareShimmer_01", 1.0, 1.0) },
                CastSounds = { S("A_Male_Breath_Quick_Cue", 0.6, 1.2) },
                Body = { L("P_Smoke_06", 2.2, 5, { Priority = "main" }), L("P_FXVariety_HealAura", 2.0, 5), L("P_HangingParticulates", 1.8, 5) },
                Trail = { L("P_FlareShimmer_02", 0.7, 1.2), L("P_Smoke_03", 0.7, 2.0) }, TrailEveryMs = 180,
                Orbit = { Asset = "nanos-world::P_FlareShimmer_01", Count = 6, Scale = 0.6, Speed = 2.5, RiseSpeed = 0.25 },
                Strike = { S("A_WhiteNoise", 0.15, 1.8, 5) },
                Burst = { L("P_Smoke_07", 2.0, 2.5), L("P_FlareShimmer_02", 1.6, 1.5), L("P_ShockWave_04", 1.4, 1.0) },
                BurstSounds = { S("A_Explosion_Small", 0.5, 1.5) },
                Hit = { L("P_FlareShimmer_01", 0.5, 0.8, { Priority = "detail" }) },
            },
        },
    },
}
