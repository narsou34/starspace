--[[
    Demon Slayer RP - Arts demoniaques du sang (Kekkijutsu)
    ------------------------------------------------------------------
    Même format de techniques que les Souffles (voir BreathingStyles.lua),
    plus un Passive par art :
      Passive = { Name, Description, RegenMultiplier, DamageMultiplier, SpeedMultiplier }

    Les 4 premières compétences vont sur les touches 1 à 4, la 5e (spéciale)
    est en général une transformation (Buff sur soi).
]]

local CHOP = "nanos-world::A_Mannequin_Taunt_Chop"
local KUNFU = "nanos-world::A_Mannequin_Taunt_Kunfu"
local PUNCH = "nanos-world::A_Mannequin_Taunt_HandPunch"
local THROW = "nanos-world::A_Mannequin_Throw_01"
local THROW2 = "nanos-world::A_Mannequin_Throw_02"
local SHOUT = "nanos-world::A_Mannequin_Shout"

Config.DemonArts = {

    sang = {
        Name = "Sang explosif",
        Description = "Le sang du demon s'enflamme au contact de l'air.",
        Passive = { Name = "Sang ardent", Description = "Regeneration acceleree.", RegenMultiplier = 1.3 },
        Techniques = {
            { Name = "Griffes", Description = "Attaque naturelle aux griffes.",
              Range = 250, Angle = 80, Damage = 18, Cost = 8, CooldownMs = 1500,
              Animation = CHOP, Effect = "nanos-world::P_Blood_Impact" },
            { Name = "Gerbe de sang", Description = "Projette du sang qui s'embrase.",
              Range = 450, Angle = 70, Damage = 24, Cost = 15, CooldownMs = 4000,
              Animation = THROW, Effect = "nanos-world::P_Fire_Exp_01", Sound = "nanos-world::A_Explosion_Small" },
            { Name = "Explosion de sang", Description = "Detonation autour de soi.",
              Shape = "circle", Range = 350, Damage = 28, Cost = 22, CooldownMs = 6000, Knockback = 600,
              Animation = SHOUT, AnimationSlot = "FullBody", Effect = "nanos-world::P_Explosion_Fire_01", EffectOffset = 0,
              Sound = "nanos-world::A_Explosion_Small" },
            { Name = "Bond feroce", Description = "Saute sur sa proie.",
              Shape = "dash", Range = 650, Dash = 1500, Damage = 22, Cost = 14, CooldownMs = 4500,
              Effect = "nanos-world::P_Blood_Impact" },
            { Name = "Eveil du sang", Description = "Transformation : force et vitesse accrues.",
              Shape = "self", Damage = 0, Cost = 40, CooldownMs = 30000,
              Buff = { SpeedMultiplier = 1.3, DamageMultiplier = 1.5, Heal = 30, DurationMs = 10000 },
              Animation = SHOUT, AnimationSlot = "FullBody", Effect = "nanos-world::P_FXVariety_FireStorm", EffectOffset = 0, EffectDuration = 2.5 },
        },
    },

    temari = {
        Name = "Temari",
        Description = "Art de Susamaru : balles lancees avec une force inouie.",
        Passive = { Name = "Bras multiples", Description = "Degats accrus.", DamageMultiplier = 1.1 },
        Techniques = {
            { Name = "Griffes", Description = "Attaque naturelle aux griffes.",
              Range = 250, Angle = 80, Damage = 18, Cost = 8, CooldownMs = 1500, Effect = "nanos-world::P_Blood_Impact" },
            { Name = "Lancer de temari", Description = "Balle lancee en ligne droite.",
              Shape = "line", Range = 1200, Width = 150, Damage = 26, Cost = 14, CooldownMs = 3000, Knockback = 500,
              Animation = THROW, Effect = "nanos-world::P_FXVariety_ShotShockWave", Sound = "nanos-world::A_BigHammer_Impact" },
            { Name = "Double temari", Description = "Deux balles en eventail.",
              Range = 900, Angle = 50, Damage = 24, Cost = 18, CooldownMs = 5000, Knockback = 400,
              Animation = THROW2, Effect = "nanos-world::P_ShockWave_02" },
            { Name = "Rebond", Description = "Les balles rebondissent tout autour.",
              Shape = "circle", Range = 450, Damage = 22, Cost = 20, CooldownMs = 6000, Knockback = 700,
              Animation = KUNFU, AnimationSlot = "FullBody", Effect = "nanos-world::P_ShockWave_09", EffectOffset = 0 },
            { Name = "Jeu de balles sans fin", Description = "Pluie de temari devastatrice.",
              Shape = "line", Range = 1400, Width = 350, Damage = 48, Cost = 45, CooldownMs = 22000, Knockback = 900,
              Animation = THROW2, AnimationSlot = "FullBody", Effect = "nanos-world::P_FXVariety_Explosion", EffectDuration = 2.5,
              Sound = "nanos-world::A_Explosion_Large" },
        },
    },

    fils = {
        Name = "Fils d'araignee",
        Description = "Art de Rui : des fils plus tranchants que l'acier.",
        Passive = { Name = "Toile", Description = "Regeneration legerement accrue.", RegenMultiplier = 1.15 },
        Techniques = {
            { Name = "Fil tranchant", Description = "Fil fin projete devant soi.",
              Shape = "line", Range = 900, Width = 120, Damage = 22, Cost = 12, CooldownMs = 2500,
              Animation = THROW, Effect = "nanos-world::P_Beam" },
            { Name = "Filet", Description = "Toile qui immobilise presque la cible.",
              Range = 600, Angle = 60, Damage = 14, Cost = 16, CooldownMs = 6000,
              Slow = { Multiplier = 0.35, DurationMs = 3000 }, Effect = "nanos-world::P_Ribbon" },
            { Name = "Cage tranchante", Description = "Cage de fils autour de soi.",
              Shape = "circle", Range = 400, Damage = 26, Cost = 22, CooldownMs = 7000,
              Animation = KUNFU, AnimationSlot = "FullBody", Effect = "nanos-world::P_Streamer", EffectOffset = 0 },
            { Name = "Fil de sang rouge", Description = "Fil durci au sang, longue portee.",
              Shape = "line", Range = 1200, Width = 160, Damage = 30, Cost = 22, CooldownMs = 7000,
              Animation = THROW2, Effect = "nanos-world::P_FXVariety_Laser_01" },
            { Name = "Fils qui decoupent tout", Description = "Toile geante de fils de sang.",
              Shape = "circle", Range = 650, Damage = 50, Cost = 50, CooldownMs = 24000,
              Slow = { Multiplier = 0.5, DurationMs = 3000 },
              Animation = SHOUT, AnimationSlot = "FullBody", Effect = "nanos-world::P_FXVariety_DarkStorm", EffectOffset = 0, EffectDuration = 3 },
        },
    },

    glace = {
        Name = "Glace",
        Description = "Art de Doma, Lune superieure : glace et brume gelante.",
        Passive = { Name = "Sang glacial", Description = "Regeneration tres rapide.", RegenMultiplier = 1.6 },
        Techniques = {
            { Name = "Eventails de glace", Description = "Coups d'eventails tranchants.",
              Range = 300, Angle = 90, Damage = 20, Cost = 10, CooldownMs = 1800, Effect = "nanos-world::P_GrenadeEXP_Ice" },
            { Name = "Nuages gelants", Description = "Brume glacee qui ralentit.",
              Range = 550, Angle = 80, Damage = 16, Cost = 16, CooldownMs = 5000,
              Slow = { Multiplier = 0.5, DurationMs = 3000 }, Effect = "nanos-world::P_LTGrenadeEXP_Snow", EffectDuration = 2 },
            { Name = "Vignes de lotus", Description = "Lianes de glace a distance.",
              Shape = "line", Range = 1000, Width = 200, Damage = 26, Cost = 18, CooldownMs = 5000,
              Animation = THROW, Effect = "nanos-world::P_LTGrenadeEXP_Ice" },
            { Name = "Hiver glace", Description = "Pics de glace tout autour.",
              Shape = "circle", Range = 450, Damage = 30, Cost = 24, CooldownMs = 7000, Knockback = 500,
              Animation = SHOUT, AnimationSlot = "FullBody", Effect = "nanos-world::P_GrenadeEXP_Snow", EffectOffset = 0 },
            { Name = "Bodhisattva de glace", Description = "Statue geante de glace devastatrice.",
              Shape = "circle", Range = 750, Damage = 52, Cost = 55, CooldownMs = 26000, Knockback = 900,
              Slow = { Multiplier = 0.5, DurationMs = 4000 },
              Animation = SHOUT, AnimationSlot = "FullBody", Effect = "nanos-world::P_FXVariety_AquaStorm", EffectOffset = 0, EffectDuration = 3.5 },
        },
    },

    biwa = {
        Name = "Biwa",
        Description = "Art de Nakime : deplace l'espace d'un coup de biwa.",
        Passive = { Name = "Chateau infini", Description = "Deplacements plus rapides.", SpeedMultiplier = 1.15 },
        Techniques = {
            { Name = "Griffes", Description = "Attaque naturelle aux griffes.",
              Range = 250, Angle = 80, Damage = 18, Cost = 8, CooldownMs = 1500, Effect = "nanos-world::P_Blood_Impact" },
            { Name = "Deplacement", Description = "Se deplace instantanement vers l'avant.",
              Shape = "dash", Range = 0, Dash = 2500, Damage = 0, Cost = 14, CooldownMs = 4000,
              Effect = "nanos-world::P_Distortion_02", EffectOffset = 0 },
            { Name = "Accord repoussant", Description = "Onde de choc qui repousse.",
              Shape = "circle", Range = 450, Damage = 16, Cost = 16, CooldownMs = 5000, Knockback = 1100,
              Effect = "nanos-world::P_ShockWave_11", EffectOffset = 0 },
            { Name = "Portes du chateau", Description = "Onde lointaine en ligne.",
              Shape = "line", Range = 1100, Width = 250, Damage = 24, Cost = 18, CooldownMs = 6000, Knockback = 600,
              Effect = "nanos-world::P_Distortion_SQ" },
            { Name = "Remaniement du chateau", Description = "Distord l'espace autour de soi.",
              Shape = "circle", Range = 700, Damage = 40, Cost = 45, CooldownMs = 22000, Knockback = 1300,
              Buff = { SpeedMultiplier = 1.3, DurationMs = 6000 },
              Animation = SHOUT, AnimationSlot = "FullBody", Effect = "nanos-world::P_Distortion_3D", EffectOffset = 0, EffectDuration = 3 },
        },
    },

    reve = {
        Name = "Reve",
        Description = "Art d'Enmu : plonge ses victimes dans un sommeil fatal.",
        Passive = { Name = "Corps du train", Description = "Regeneration accrue.", RegenMultiplier = 1.25 },
        Techniques = {
            { Name = "Griffes", Description = "Attaque naturelle aux griffes.",
              Range = 250, Angle = 80, Damage = 18, Cost = 8, CooldownMs = 1500, Effect = "nanos-world::P_Blood_Impact" },
            { Name = "Murmure du sommeil", Description = "Endort a moitie : fort ralentissement.",
              Range = 650, Angle = 50, Damage = 8, Cost = 18, CooldownMs = 7000,
              Slow = { Multiplier = 0.3, DurationMs = 3500 }, Animation = "nanos-world::A_Mannequin_Taunt_Shoosh",
              Effect = "nanos-world::P_FXVariety_MagicCircle" },
            { Name = "Cauchemar", Description = "Vision terrifiante a distance.",
              Shape = "line", Range = 1000, Width = 180, Damage = 24, Cost = 16, CooldownMs = 5000,
              Effect = "nanos-world::P_FXVariety_DarkStorm" },
            { Name = "Bras de chair", Description = "Tentacules surgissant autour de soi.",
              Shape = "circle", Range = 420, Damage = 26, Cost = 22, CooldownMs = 7000, Knockback = 500,
              Animation = SHOUT, AnimationSlot = "FullBody", Effect = "nanos-world::P_Blood_Impact", EffectOffset = 0 },
            { Name = "Sommeil eternel", Description = "Endort tous les ennemis proches.",
              Shape = "circle", Range = 700, Damage = 20, Cost = 50, CooldownMs = 25000,
              Slow = { Multiplier = 0.2, DurationMs = 5000 },
              Animation = "nanos-world::A_Mannequin_Taunt_Shoosh", AnimationSlot = "FullBody",
              Effect = "nanos-world::P_FXVariety_MagicCircle", EffectOffset = 0, EffectDuration = 3 },
        },
    },
}
