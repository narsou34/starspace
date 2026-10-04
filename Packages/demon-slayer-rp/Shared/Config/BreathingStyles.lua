--[[
    Demon Slayer RP - Souffles (Respirations) des Pourfendeurs
    ------------------------------------------------------------------
    Ajouter un souffle = ajouter une entrée ici, sans toucher au code.

    Chaque technique hérite de Config.Abilities.TechniqueDefaults et peut surcharger :
      Name, Form, Description, Shape ("cone"|"circle"|"line"|"dash"|"self"),
      Range, Angle, Width, Damage, Cost, CooldownMs, Knockback, Dash, MaxTargets,
      BonusVsDemons (multiplicateur contre les démons), BlockRegenMs (bloque la
      régénération du démon touché), Slow = { Multiplier, DurationMs },
      Buff = { SpeedMultiplier, DamageMultiplier, Heal, DurationMs } (sur soi),
      Animation, AnimationSlot, Effect, EffectDuration, EffectOffset, Sound.

    Techniques : les 4 premières vont sur les touches 1 à 4, la 5e est la
    technique spéciale (touche X par défaut).
]]

local CHOP = "nanos-world::A_Mannequin_Taunt_Chop"
local KUNFU = "nanos-world::A_Mannequin_Taunt_Kunfu"
local PUNCH = "nanos-world::A_Mannequin_Taunt_HandPunch"
local THROW = "nanos-world::A_Mannequin_Throw_01"
local THROW2 = "nanos-world::A_Mannequin_Throw_02"

Config.BreathingStyles = {

    -- Souffles scriptés (timeline + VFX chorégraphiés), chacun dans son fichier :
    --   eau                         Shared/Config/Breathing/Water.lua
    --   son / insecte / amour / vent Shared/Config/Breathing/{Sound,Insect,Love,Wind}.lua
    --   flamme / tonnerre / brume / serpent  Shared/Config/Breathing/FlameThunderMist.lua

    pierre = {
        Name = "Souffle de la Pierre",
        Description = "Le plus puissant des souffles, lent mais ecrasant.",
        Color = "grey",
        BlockRegenMs = 3000,
        Techniques = {
            { Form = 1, Name = "Serpentinite bipolaire", Description = "Lancer de la hache et du fleau.",
              Shape = "line", Range = 900, Width = 200, Damage = 30, Cost = 18, CooldownMs = 5000, Knockback = 500,
              Animation = THROW2, Effect = "nanos-world::P_HighImpact", Sound = "nanos-world::A_BigHammer_Impact" },
            { Form = 2, Name = "Frappe ascendante", Description = "Coup ecrasant vers le haut.",
              Range = 300, Angle = 70, Damage = 34, Cost = 20, CooldownMs = 5000, Knockback = 700,
              Animation = PUNCH, Effect = "nanos-world::P_ImpactExplosion_02", Sound = "nanos-world::A_BigHammer_Impact" },
            { Form = 3, Name = "Peau de pierre", Description = "Endurcit le corps.",
              Shape = "self", Cost = 20, CooldownMs = 15000, Damage = 0,
              Buff = { DamageMultiplier = 1.3, Heal = 15, DurationMs = 8000 },
              Animation = "nanos-world::A_Mannequin_Taunt_Flex_01", Effect = "nanos-world::P_FXVariety_MagicCircle", EffectOffset = 0, EffectDuration = 2 },
            { Form = 4, Name = "Conquete du roc volcanique", Description = "Pluie de coups autour de soi.",
              Shape = "circle", Range = 400, Damage = 32, Cost = 26, CooldownMs = 8000, Knockback = 600,
              AnimationSlot = "FullBody", Animation = KUNFU, Effect = "nanos-world::P_Destruction", EffectOffset = 0, EffectDuration = 2 },
            { Form = 5, Name = "Arcs de justice", Description = "Technique ultime de Gyomei Himejima.",
              Shape = "circle", Range = 600, Damage = 60, Cost = 55, CooldownMs = 25000, Knockback = 1100,
              AnimationSlot = "FullBody", Animation = PUNCH, Effect = "nanos-world::P_ImpactExplosion_06", EffectOffset = 0,
              EffectDuration = 3, Sound = "nanos-world::A_Explosion_Large" },
        },
    },

    fleur = {
        Name = "Souffle de la Fleur",
        Description = "Derive de l'eau, elegant et precis.",
        Color = "rose",
        BlockRegenMs = 2000,
        Techniques = {
            { Form = 2, Name = "Prunier honorable", Description = "Quatre coups en croix.",
              Range = 360, Angle = 80, Damage = 22, Cost = 13, CooldownMs = 2800,
              Effect = "nanos-world::P_Burst_02" },
            { Form = 4, Name = "Hanagoromo cramoisi", Description = "Coup en arc ample.",
              Range = 420, Angle = 130, Damage = 22, Cost = 15, CooldownMs = 3500,
              Effect = "nanos-world::P_Burst_01" },
            { Form = 5, Name = "Pivoines de la futilite", Description = "Neuf coups autour de soi.",
              Shape = "circle", Range = 340, Damage = 24, Cost = 18, CooldownMs = 5000,
              Animation = KUNFU, AnimationSlot = "FullBody", Effect = "nanos-world::P_OmnidirectionalBurst", EffectOffset = 0 },
            { Form = 6, Name = "Pecher tourbillonnant", Description = "Tourbillon defensif.",
              Shape = "circle", Range = 300, Damage = 16, Cost = 15, CooldownMs = 5000, Knockback = 600,
              Effect = "nanos-world::P_Burst_02", EffectOffset = 0 },
            { Form = 7, Name = "Oeil vermillon de l'equinoxe", Description = "Vision acceleree au prix d'un grand effort.",
              Shape = "self", Damage = 0, Cost = 40, CooldownMs = 25000,
              Buff = { SpeedMultiplier = 1.5, DamageMultiplier = 1.4, DurationMs = 8000 },
              Animation = "nanos-world::A_Mannequin_Taunt_EyesOnYou", Effect = "nanos-world::P_FXVariety_HealAura", EffectOffset = 0, EffectDuration = 2 },
        },
    },

    bete = {
        Name = "Souffle de la Bete",
        Description = "Style sauvage invente par Inosuke Hashibira, deux lames dentelees.",
        Color = "grey",
        BlockRegenMs = 2000,
        Techniques = {
            { Form = 1, Name = "Percer", Description = "Double estoc en avancant.",
              Shape = "dash", Range = 650, Dash = 1500, Damage = 24, Cost = 14, CooldownMs = 3500,
              Effect = "nanos-world::P_FXVariety_Hit_02" },
            { Form = 2, Name = "Dechirer", Description = "Deux coups en ciseaux.",
              Range = 340, Angle = 90, Damage = 24, Cost = 14, CooldownMs = 3000,
              Effect = "nanos-world::P_FXVariety_Hit_01" },
            { Form = 3, Name = "Devorer", Description = "Coup en machoire sur une cible.",
              Range = 280, Angle = 50, Damage = 32, Cost = 18, CooldownMs = 5000,
              Animation = PUNCH, Effect = "nanos-world::P_HighImpact" },
            { Form = 5, Name = "Decoupe insensee", Description = "Coups desordonnes tout autour.",
              Shape = "circle", Range = 330, Damage = 24, Cost = 18, CooldownMs = 5000,
              Animation = KUNFU, AnimationSlot = "FullBody", Effect = "nanos-world::P_FXVariety_Hit_02", EffectOffset = 0 },
            { Form = 7, Name = "Lancer brutal", Description = "Lance une lame a toute force.",
              Shape = "line", Range = 1100, Width = 160, Damage = 45, Cost = 40, CooldownMs = 18000, Knockback = 500,
              Animation = THROW2, Effect = "nanos-world::P_FXVariety_ShotShockWave", EffectDuration = 2 },
        },
    },

    soleil = {
        Name = "Souffle du Soleil (Hinokami Kagura)",
        Description = "Le premier des souffles. Redoutable contre les demons.",
        Color = "red",
        BlockRegenMs = 8000,
        BonusVsDemons = 1.5,
        Techniques = {
            { Form = 1, Name = "Danse", Description = "Coup descendant en cercle de feu.",
              Range = 380, Angle = 90, Damage = 28, Cost = 18, CooldownMs = 3500,
              Effect = "nanos-world::P_Fire_Exp_02", Sound = "nanos-world::A_Explosion_Small" },
            { Form = 2, Name = "Ciel bleu clair", Description = "Rotation complete enflammee.",
              Shape = "circle", Range = 340, Damage = 26, Cost = 20, CooldownMs = 5000,
              Animation = KUNFU, AnimationSlot = "FullBody", Effect = "nanos-world::P_FXVariety_FireStorm", EffectOffset = 0 },
            { Form = 3, Name = "Soleil ardent", Description = "Saut et coup vertical.",
              Shape = "dash", Range = 700, Dash = 1500, Damage = 30, Cost = 22, CooldownMs = 5500,
              Effect = "nanos-world::P_Explosion_Fire_02" },
            { Form = 4, Name = "Tournesol perforant", Description = "Estoc fulgurant.",
              Shape = "line", Range = 800, Width = 150, Damage = 32, Cost = 24, CooldownMs = 6000,
              Effect = "nanos-world::P_FXVariety_ShootingStar" },
            { Form = 13, Name = "Treizieme forme", Description = "Enchainement des douze formes, sans fin.",
              Shape = "circle", Range = 650, Damage = 62, Cost = 60, CooldownMs = 28000, Knockback = 900,
              AnimationSlot = "FullBody", Animation = KUNFU, Effect = "nanos-world::P_Explosion_Fire_06", EffectOffset = 0,
              EffectDuration = 3, Sound = "nanos-world::A_Explosion_Large" },
        },
    },
}
