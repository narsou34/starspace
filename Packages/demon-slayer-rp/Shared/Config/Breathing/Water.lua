--[[
    Demon Slayer RP - Souffle de l'Eau (Mizu no Kokyu) - REWORK
    ------------------------------------------------------------------
    Techniques SCRIPTÉES : chaque technique a une chronologie complète
        préparation -> action -> impact -> fin
    exécutée par le serveur (Server/Systems/Techniques/) pour la logique
    (zones de touche mobiles, dégâts, contrôle) et par chaque client
    (Client/Systems/Fx/Water.lua) pour les effets (couches de particules,
    traînée du katana, sons, caméra).

    Serveur et client lisent CE fichier : les timings sont identiques des
    deux côtés, la synchronisation visuel / dégâts en dépend.
    Toutes les distances sont en cm (100 = 1 m), les durées en ms.

    Assets : uniquement le pack "nanos-world" fourni avec le jeu. Pour
    utiliser un pack d'effets externe, il suffit de remplacer les chemins
    de la table WATER_FX ci-dessous (voir README).
]]

-- Bibliothèque d'effets de l'eau (un seul endroit à modifier pour changer de pack)
local WATER_FX = {
    Orb        = "nanos-world::P_FXVariety_WaterBall",
    OrbHit     = "nanos-world::P_FXVariety_WaterBallHit",
    Storm      = "nanos-world::P_FXVariety_AquaStorm",
    Splash     = "nanos-world::P_Explosion_Water",
    SplashBig  = "nanos-world::P_GrenadeEXP_Water",
    SplashSoft = "nanos-world::P_LTGrenadeEXP_Water",
    Impact     = "nanos-world::P_Water_Impact",
    Fountain   = "nanos-world::P_Fountain",
    Ribbon     = "nanos-world::P_Ribbon",
    Streamer   = "nanos-world::P_Streamer",
    Wind       = "nanos-world::P_FXVariety_Storm",
    Mist       = "nanos-world::P_Smoke_03",
    MistHeavy  = "nanos-world::P_Smoke_06",
    Droplets   = "nanos-world::P_HangingParticulates",
    Ring       = "nanos-world::P_ShockWave_02",
    RingBig    = "nanos-world::P_ShockWave_06",
    Burst      = "nanos-world::P_OmnidirectionalBurst",
    Spray      = "nanos-world::P_DirectionalBurst",
    Haze       = "nanos-world::P_Distortion_01",
    Circle     = "nanos-world::P_FXVariety_MagicCircle",
}

-- Sons (le pack de base n'a pas de son de vague : on les compose avec
-- volume / hauteur différents pour chaque couche)
local WATER_SFX = {
    Breath   = "nanos-world::A_Male_Breath_Quick_Cue",
    Slash    = "nanos-world::A_Whoosh",
    Water    = "nanos-world::A_Water_Impact_MS",
    Roar     = "nanos-world::A_WhiteNoise",
    Crash    = "nanos-world::A_Explosion_Small",
    CrashBig = "nanos-world::A_Explosion_Large",
    Thud     = "nanos-world::A_BigHammer_Land",
    Rush     = "nanos-world::A_Thruster_02",
    Hit      = "nanos-world::A_Flesh_Impact_MS",
}

Config.WaterFx = WATER_FX
Config.WaterSfx = WATER_SFX

local CHOP = "nanos-world::A_Mannequin_Taunt_Chop"
local SPIN = "nanos-world::A_Mannequin_Taunt_Kunfu"
local THROW = "nanos-world::A_Mannequin_Throw_01"
local THROW_HEAVY = "nanos-world::A_Mannequin_Throw_02"
local THRUST = "nanos-world::A_Mannequin_Taunt_HandPunch"
local SUMMON = "nanos-world::A_Mannequin_Taunt_TheHeavins"

Config.BreathingStyles = Config.BreathingStyles or {}

Config.BreathingStyles.eau = {
    Name = "Souffle de l'Eau",
    Description = "Style fluide et adaptable, enseigne par Sakonji Urokodaki. La lame suit le courant.",
    Color = "cyan",
    BlockRegenMs = 2500,

    -- Traînée d'eau du katana (main droite) pendant les phases d'attaque
    BladeTrail = {
        Bone = "hand_r",
        Layers = { WATER_FX.Ribbon, WATER_FX.Streamer },
        DurationMs = 700,
    },

    Techniques = {
        -- =================================================================
        -- [Q] Première forme : Grande vague
        -- Une vague se lève devant le lanceur et déferle vers l'avant.
        -- Zone : boîte qui AVANCE avec la vague et s'élargit.
        -- =================================================================
        {
            Form = 1, Script = "water_wave",
            Name = "Premiere forme : Grande vague",
            Description = "Une vague se leve et deferle devant vous, emportant les ennemis.",
            Shape = "self", Range = 1200, Damage = 26, Cost = 18, CooldownMs = 6000,
            Timeline = { WindupMs = 280, TravelMs = 900, LingerMs = 600 },
            Wave = {
                StartDistance = 120, Distance = 1200,
                StartWidth = 360, EndWidth = 700,
                Height = 260, Thickness = 220,
            },
            Hit = { Damage = 26, Knockback = 750, Lift = 260, MaxTargets = 8 },
            Animation = { Windup = CHOP, Slot = "FullBody" },
            Camera = { Fov = 6, DurationMs = 350 },
        },

        -- =================================================================
        -- [E] Deuxième forme : Tourbillon
        -- Un vortex se forme devant le lanceur, aspire et soulève les ennemis.
        -- Zone : cylindre, dégâts par tick + attraction vers le centre.
        -- =================================================================
        {
            Form = 2, Script = "water_vortex",
            Name = "Deuxieme forme : Tourbillon",
            Description = "Un vortex d'eau aspire, souleve et broie les ennemis proches.",
            Shape = "self", Range = 420, Damage = 7, Cost = 24, CooldownMs = 11000,
            Timeline = { WindupMs = 450, ActiveMs = 3200 },
            Vortex = {
                Distance = 380,          -- centre du vortex devant le lanceur
                Radius = 420, Height = 650,
                TickMs = 400,            -- dégâts toutes les 0,4 s
                Pull = 420,              -- attraction vers le centre
                Lift = 160,
                FinalBurst = { Damage = 18, Knockback = 900, Lift = 500 },
            },
            Hit = { Damage = 7, MaxTargets = 8 },
            Animation = { Windup = SPIN, Slot = "FullBody" },
            Camera = { Fov = 5, DurationMs = 500 },
        },

        -- =================================================================
        -- [R] Troisième forme : Prison d'eau
        -- Une sphère d'eau est lancée ; la cible touchée est emprisonnée
        -- (immobilisée, soulevée), noyée par ticks puis la bulle éclate.
        -- Zone : projectile (balayage sphérique entre deux ticks, sans "trou").
        -- =================================================================
        {
            Form = 3, Script = "water_prison",
            Name = "Troisieme forme : Prison d'eau",
            Description = "Une sphere d'eau emprisonne la premiere cible touchee puis eclate.",
            Shape = "self", Range = 2200, Damage = 14, Cost = 22, CooldownMs = 12000,
            Timeline = { WindupMs = 320 },
            Projectile = { Speed = 2200, Radius = 110, MaxDistance = 2200, SpawnForward = 120, SpawnHeight = 40 },
            Prison = {
                DurationMs = 3000, TickMs = 500, TickDamage = 4,
                Lift = 120,              -- la cible flotte dans la bulle
                BurstDamage = 14, BurstKnockback = 650,
            },
            Hit = { Damage = 6, MaxTargets = 1 },
            Animation = { Windup = THROW, Slot = "UpperBody" },
            Camera = { Fov = 4, DurationMs = 250 },
        },

        -- =================================================================
        -- [F] Quatrième forme : Courant fulgurant
        -- Le lanceur file comme l'eau : élan, vitesse x1.8, traînée d'eau,
        -- invulnérable pendant l'élan, entaille les ennemis traversés.
        -- Zone : sphère qui suit le lanceur (1 touche max par cible).
        -- =================================================================
        {
            Form = 4, Script = "water_flow",
            Name = "Quatrieme forme : Courant fulgurant",
            Description = "Vous filez comme un torrent, tranchant tout sur votre passage.",
            Shape = "self", Range = 180, Damage = 16, Cost = 20, CooldownMs = 14000,
            Timeline = { WindupMs = 120, ActiveMs = 5000, StrikeWindowMs = 1600 },
            Flow = {
                Dash = 1600, DashLift = 120,
                SpeedMultiplier = 1.8,
                InvulnerableMs = 450,
                HitRadius = 180, TickMs = 150,
            },
            Hit = { Damage = 16, Knockback = 450, Lift = 150, MaxTargets = 6 },
            Animation = { Windup = THRUST, Slot = "UpperBody" },
            Camera = { Fov = 12, DurationMs = 5000 },
        },

        -- =================================================================
        -- [X] Technique ultime : Tsunami
        -- Concentration totale (invulnérable), l'eau se rassemble, puis une
        -- vague gigantesque grandit et avance avant de s'écraser.
        -- Zone : mur d'eau mobile (s'élargit) + explosion finale.
        -- =================================================================
        {
            Form = 0, Script = "water_tsunami",
            Name = "Ultime : Tsunami",
            Description = "Vous invoquez un mur d'eau colossal qui balaie tout avant de s'ecraser.",
            Shape = "self", Range = 2600, Damage = 55, Cost = 60, CooldownMs = 45000,
            Requirements = { Level = 10 },
            Timeline = { WindupMs = 1300, RiseMs = 500, TravelMs = 2200, CrashMs = 900 },
            Wave = {
                StartDistance = 250, Distance = 2600,
                StartWidth = 600, EndWidth = 1500,
                Height = 700, Thickness = 320,
            },
            Hit = { Damage = 55, Knockback = 1500, Lift = 650, MaxTargets = 12 },
            Crash = { Radius = 700, Damage = 20, Knockback = 900, Lift = 400 },
            Caster = { InvulnerableDuringWindup = true, RootDuringWindup = true },
            Animation = { Windup = SUMMON, Release = CHOP, Slot = "FullBody" },
            Camera = { Fov = 14, ArmLength = 250, DurationMs = 1800 },
        },

        -- =================================================================
        -- [C] Dixième forme : Dragon changeant (Dragon d'eau)
        -- Un dragon d'eau surgit derrière le lanceur, ondule vers l'avant en
        -- frappant tout sur sa trajectoire puis explose au bout de sa course.
        -- Zone : sphère qui suit EXACTEMENT la trajectoire du dragon.
        -- =================================================================
        {
            Form = 10, Script = "water_dragon",
            Name = "Dixieme forme : Dragon changeant",
            Description = "Un immense dragon d'eau ondule vers l'avant et s'ecrase dans une explosion.",
            Shape = "self", Range = 3400, Damage = 22, Cost = 70, CooldownMs = 60000,
            Requirements = { Level = 20 },
            Timeline = { WindupMs = 900, TravelMs = 2800, ImpactMs = 1000 },
            Dragon = {
                Distance = 3400, StartBack = 150, Height = 160,
                Amplitude = 260, Waves = 2.5,      -- ondulation latérale (serpent)
                Segments = 7, SegmentDelayMs = 110, -- corps : segments qui suivent la tête
                HitRadius = 320, HitIntervalMs = 450, MaxHitsPerTarget = 3,
            },
            Hit = { Damage = 22, Knockback = 650, Lift = 350, MaxTargets = 12 },
            Impact = { Radius = 800, Damage = 45, Knockback = 1600, Lift = 700 },
            Caster = { InvulnerableDuringWindup = true, RootDuringWindup = true },
            Animation = { Windup = SPIN, Release = THROW_HEAVY, Slot = "FullBody" },
            Camera = { Fov = 16, ArmLength = 300, DurationMs = 2600 },
        },
    },
}
