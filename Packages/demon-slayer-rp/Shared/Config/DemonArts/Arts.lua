--[[
    Demon Slayer RP - Arts démoniaques scriptés : Glace, Sang, Ombre, Fleurs
    ------------------------------------------------------------------
    Logique de jeu + mise en scène. Rendu : éléments "ice", "blood",
    "shadow", "flower" (Client/Systems/VFX/Elements/Others.lua).
    Les autres arts (temari, fils, biwa, reve) restent dans DemonArts.lua.
]]

local CLAW = "nanos-world::A_Mannequin_Taunt_Chop"
local SPIN = "nanos-world::A_Mannequin_Taunt_Kunfu"
local THROW = "nanos-world::A_Mannequin_Throw_01"
local THROW2 = "nanos-world::A_Mannequin_Throw_02"
local SHOUT = "nanos-world::A_Mannequin_Shout"
local SUMMON = "nanos-world::A_Mannequin_Taunt_TheHeavins"

local Arts = Config.DemonArts

-- ===========================================================================
-- GLACE (Doma) : éventails, brume gelante, pics, statue de glace
-- ===========================================================================
Arts.glace = {
    Name = "Glace",
    Description = "Art de Doma, Lune superieure : glace cristalline et brume gelante.",
    Passive = { Name = "Sang glacial", Description = "Regeneration tres rapide.", RegenMultiplier = 1.6 },
    Techniques = {
        { Script = "combo", Name = "Eventails de glace", Description = "Deux eventails tranchants qui laissent du givre.",
          Shape = "self", Range = 320, Damage = 10, Cost = 10, CooldownMs = 2000,
          Timeline = { WindupMs = 150 }, Combo = { Count = 2, IntervalMs = 160, Shape = "arc", Range = 320, Angle = 110 },
          Hit = { Damage = 10, Knockback = 200, Lift = 60, Slow = { Multiplier = 0.8, DurationMs = 1200 }, MaxTargets = 5 },
          Animation = { Windup = CLAW, Slot = "UpperBody" }, Camera = { Fov = 4, DurationMs = 350 } },
        { Script = "zone", Name = "Nuages gelants", Description = "Une brume glacee qui gele lentement ceux qui la respirent.",
          Shape = "self", Range = 420, Damage = 4, Cost = 18, CooldownMs = 8000,
          Timeline = { WindupMs = 300 },
          Zone = { Forward = 350, Radius = 420, Height = 300, DurationMs = 3000, TickMs = 500,
                   Pull = 0, Lift = 0, Slow = { Multiplier = 0.45, DurationMs = 700 } },
          Hit = { Damage = 4, MaxTargets = 8 },
          Animation = { Windup = THROW, Slot = "UpperBody" }, Camera = { Fov = 4, DurationMs = 400 } },
        { Script = "projectiles", Name = "Lances de glace", Description = "Trois pics de glace en eventail qui eclatent a l'impact.",
          Shape = "self", Range = 1300, Damage = 12, Cost = 16, CooldownMs = 5000,
          Timeline = { WindupMs = 260 },
          Projectiles = { Count = 3, SpreadDeg = 24, Speed = 2400, Radius = 70, MaxDistance = 1300,
                          SpawnForward = 100, SpawnHeight = 60,
                          Explosion = { Radius = 200, Damage = 8, Knockback = 300, Lift = 100, Slow = { Multiplier = 0.6, DurationMs = 1500 } } },
          Hit = { Damage = 12, MaxTargets = 8 },
          Animation = { Windup = THROW2, Slot = "UpperBody" }, Camera = { Fov = 5, DurationMs = 300 } },
        { Script = "bursts", Name = "Hiver glace", Description = "Des pics de glace jaillissent du sol en ligne.",
          Shape = "self", Range = 1000, Damage = 16, Cost = 22, CooldownMs = 7000,
          Timeline = { WindupMs = 300 },
          Bursts = { Type = "line", Count = 5, Start = 200, Spacing = 190, IntervalMs = 80, Radius = 190, Damage = 16,
                     Knockback = 200, Lift = 500, Slow = { Multiplier = 0.6, DurationMs = 1500 } },
          Hit = { MaxTargets = 8 },
          Animation = { Windup = SHOUT, Slot = "UpperBody" }, Camera = { Fov = 6, DurationMs = 500 } },
        { Script = "bursts", Name = "Ultime : Bodhisattva de glace", Description = "Une statue de glace colossale ecrase la zone en trois vagues de gel.",
          Shape = "self", Range = 800, Damage = 30, Cost = 55, CooldownMs = 40000,
          Requirements = { Level = 10 },
          Timeline = { WindupMs = 1000 },
          Bursts = { Type = "rings", Radius = 230, Damage = 30, Knockback = 900, Lift = 500, Slow = { Multiplier = 0.4, DurationMs = 3000 },
                     Rings = { { Radius = 0, Count = 1, DelayMs = 0, BurstRadius = 350, Damage = 35 },
                               { Radius = 450, Count = 7, DelayMs = 250, Damage = 24 },
                               { Radius = 780, Count = 10, DelayMs = 500, Damage = 18 } } },
          Hit = { MaxTargets = 12 },
          Caster = { InvulnerableDuringWindup = true, RootDuringWindup = true },
          Animation = { Windup = SUMMON, Release = SHOUT, Slot = "FullBody" },
          Camera = { Fov = 12, ArmLength = 260, DurationMs = 1400 } },
    },
}

-- ===========================================================================
-- SANG (sang explosif / manipulation) : griffes, lignes d'énergie, cercles
-- ===========================================================================
Arts.sang = {
    Name = "Sang explosif",
    Description = "Le sang du demon devient une arme : griffes, lames et detonations ecarlates.",
    Passive = { Name = "Sang ardent", Description = "Regeneration acceleree.", RegenMultiplier = 1.3 },
    Techniques = {
        { Script = "combo", Name = "Griffes", Description = "Trois coups de griffes enchaines.",
          Shape = "self", Range = 260, Damage = 8, Cost = 8, CooldownMs = 1800,
          Timeline = { WindupMs = 100 }, Combo = { Count = 3, IntervalMs = 120, Shape = "arc", Range = 260, Angle = 100 },
          Hit = { Damage = 8, Knockback = 150, Lift = 40, MaxTargets = 4 },
          Animation = { Windup = CLAW, Slot = "UpperBody" }, Camera = { Fov = 3, DurationMs = 300 } },
        { Script = "projectiles", Name = "Lames de sang", Description = "Cinq lames de sang durci projetees en eventail.",
          Shape = "self", Range = 1200, Damage = 9, Cost = 15, CooldownMs = 4500,
          Timeline = { WindupMs = 220 },
          Projectiles = { Count = 5, SpreadDeg = 40, Speed = 2600, Radius = 60, MaxDistance = 1200, SpawnForward = 100, SpawnHeight = 50 },
          Hit = { Damage = 9, Knockback = 200, Lift = 60, MaxTargets = 8 },
          Animation = { Windup = THROW, Slot = "UpperBody" }, Camera = { Fov = 4, DurationMs = 300 } },
        { Script = "bursts", Name = "Explosion de sang", Description = "Le sang repandu au sol s'embrase en anneau.",
          Shape = "self", Range = 400, Damage = 22, Cost = 20, CooldownMs = 6000,
          Timeline = { WindupMs = 350 },
          Bursts = { Type = "rings", Radius = 200, Damage = 22, Knockback = 700, Lift = 350,
                     Rings = { { Radius = 250, Count = 6, DelayMs = 0 } } },
          Hit = { MaxTargets = 8 },
          Animation = { Windup = SHOUT, Slot = "FullBody" }, Camera = { Fov = 6, DurationMs = 500 } },
        { Script = "dash", Name = "Bond feroce", Description = "Un bond sauvage qui lacere la proie.",
          Shape = "self", Range = 700, Damage = 20, Cost = 14, CooldownMs = 4500,
          Timeline = { WindupMs = 150 },
          Dash = { Impulse = 1700, Lift = 180, Distance = 700, Width = 240, InvulnerableMs = 200 },
          Hit = { Damage = 20, Knockback = 400, Lift = 200, MaxTargets = 4 },
          Animation = { Windup = CLAW, Slot = "UpperBody" }, Camera = { Fov = 9, DurationMs = 450 } },
        { Script = "buff", Name = "Ultime : Eveil du sang", Description = "Transformation : force, vitesse et pulsations de sang autour de vous.",
          Shape = "self", Range = 350, Damage = 8, Cost = 45, CooldownMs = 35000,
          Requirements = { Level = 10 },
          Timeline = { WindupMs = 700 },
          Buff = { SpeedMultiplier = 1.35, DamageMultiplier = 1.5, Heal = 40, DurationMs = 10000 },
          Aura = { Radius = 350, TickMs = 1000, DurationMs = 10000, Damage = 8, Knockback = 400, Lift = 120 },
          Hit = { MaxTargets = 8 },
          Caster = { InvulnerableDuringWindup = true, RootDuringWindup = true },
          Animation = { Windup = SHOUT, Slot = "FullBody" }, Camera = { Fov = 10, ArmLength = 150, DurationMs = 900 } },
    },
}

-- ===========================================================================
-- OMBRE (nouvel art) : fumée noire, énergie violette, vortex, distorsion
-- ===========================================================================
Arts.ombre = {
    Name = "Ombre",
    Description = "Le demon se fond dans les tenebres et frappe depuis l'obscurite.",
    Passive = { Name = "Corps d'ombre", Description = "Deplacements plus rapides.", SpeedMultiplier = 1.15 },
    Techniques = {
        { Script = "combo", Name = "Griffes d'ombre", Description = "Deux griffes de tenebres.",
          Shape = "self", Range = 300, Damage = 10, Cost = 8, CooldownMs = 1800,
          Timeline = { WindupMs = 120 }, Combo = { Count = 2, IntervalMs = 150, Shape = "arc", Range = 300, Angle = 110 },
          Hit = { Damage = 10, Knockback = 200, Lift = 50, MaxTargets = 4 },
          Animation = { Windup = CLAW, Slot = "UpperBody" }, Camera = { Fov = 3, DurationMs = 300 } },
        { Script = "dash", Name = "Pas de l'ombre", Description = "Vous disparaissez et reapparaissez a travers l'ennemi.",
          Shape = "self", Range = 800, Damage = 18, Cost = 14, CooldownMs = 4000,
          Timeline = { WindupMs = 160 },
          Dash = { Impulse = 2200, Lift = 60, Distance = 800, Width = 200, InvulnerableMs = 400 },
          Hit = { Damage = 18, Knockback = 300, Lift = 80, MaxTargets = 4 },
          Animation = { Windup = CLAW, Slot = "UpperBody" }, Camera = { Fov = 10, DurationMs = 400 } },
        { Script = "zone", Name = "Vortex tenebreux", Description = "Un vortex d'ombre aspire les ennemis vers son centre.",
          Shape = "self", Range = 420, Damage = 6, Cost = 20, CooldownMs = 9000,
          Timeline = { WindupMs = 350 },
          Zone = { Forward = 400, Radius = 420, Height = 500, DurationMs = 3000, TickMs = 400, Pull = 450, Lift = 80,
                   FinalBurst = { Damage = 16, Knockback = 900, Lift = 400 } },
          Hit = { Damage = 6, MaxTargets = 8 },
          Animation = { Windup = SPIN, Slot = "FullBody" }, Camera = { Fov = 5, DurationMs = 500 } },
        { Script = "projectiles", Name = "Lance du neant", Description = "Une lance d'ombre perforante.",
          Shape = "self", Range = 1500, Damage = 20, Cost = 16, CooldownMs = 5000,
          Timeline = { WindupMs = 250 },
          Projectiles = { Count = 1, SpreadDeg = 0, Speed = 2800, Radius = 120, MaxDistance = 1500, Pierce = true, SpawnForward = 100, SpawnHeight = 50 },
          Hit = { Damage = 20, Knockback = 300, Lift = 100, MaxTargets = 6 },
          Animation = { Windup = THROW2, Slot = "UpperBody" }, Camera = { Fov = 5, DurationMs = 300 } },
        { Script = "zone", Name = "Ultime : Nuit eternelle", Description = "Les tenebres vous entourent : tout ce qui approche est devore.",
          Shape = "self", Range = 600, Damage = 9, Cost = 55, CooldownMs = 40000,
          Requirements = { Level = 10 },
          Timeline = { WindupMs = 800 },
          Zone = { Follow = true, Radius = 600, Height = 600, DurationMs = 4000, TickMs = 400, Pull = 350, Lift = 150,
                   Slow = { Multiplier = 0.6, DurationMs = 600 },
                   FinalBurst = { Damage = 30, Knockback = 1400, Lift = 600 } },
          Hit = { Damage = 9, MaxTargets = 12 },
          Caster = { InvulnerableDuringWindup = true, RootDuringWindup = true },
          Animation = { Windup = SUMMON, Release = SHOUT, Slot = "FullBody" },
          Camera = { Fov = 12, ArmLength = 280, DurationMs = 4300 } },
    },
}

-- ===========================================================================
-- FLEURS (nouvel art) : pétales, spirales, explosions florales
-- ===========================================================================
Arts.fleurs = {
    Name = "Fleurs de sang",
    Description = "Des fleurs ecarlates eclosent du sang du demon : beaute et poison.",
    Passive = { Name = "Floraison", Description = "Regeneration accrue.", RegenMultiplier = 1.25 },
    Techniques = {
        { Script = "combo", Name = "Petales tranchants", Description = "Trois tourbillons de petales coupants.",
          Shape = "self", Range = 340, Damage = 8, Cost = 10, CooldownMs = 2200,
          Timeline = { WindupMs = 150 }, Combo = { Count = 3, IntervalMs = 140, Shape = "arc", Range = 340, Angle = 120 },
          Hit = { Damage = 8, Knockback = 150, Lift = 60, MaxTargets = 5 },
          Animation = { Windup = CLAW, Slot = "UpperBody" }, Camera = { Fov = 3, DurationMs = 300 } },
        { Script = "whip", Name = "Liane epineuse", Description = "Une liane fleurie s'etend en spirale et revient.",
          Shape = "self", Range = 900, Damage = 12, Cost = 16, CooldownMs = 5000,
          Timeline = { WindupMs = 200 },
          Whip = { Path = "sine", Distance = 900, Amplitude = 120, Waves = 2.5, Return = true, DurationMs = 800,
                   Radius = 110, MaxHitsPerTarget = 2, HitIntervalMs = 250 },
          Hit = { Damage = 12, Knockback = 200, Lift = 80, Slow = { Multiplier = 0.7, DurationMs = 1500 }, MaxTargets = 6 },
          Animation = { Windup = THROW, Slot = "UpperBody" }, Camera = { Fov = 5, DurationMs = 800 } },
        { Script = "bursts", Name = "Eclosion", Description = "Des fleurs de sang eclosent et explosent autour de la cible.",
          Shape = "self", Range = 700, Damage = 16, Cost = 20, CooldownMs = 6000,
          Timeline = { WindupMs = 300 },
          Bursts = { Type = "points", Radius = 200, Damage = 16, Knockback = 450, Lift = 250,
                     Points = { { Forward = 450, Side = 0, DelayMs = 0 }, { Forward = 600, Side = -180, DelayMs = 120 },
                                { Forward = 600, Side = 180, DelayMs = 120 }, { Forward = 750, Side = 0, DelayMs = 240 } } },
          Hit = { MaxTargets = 8 },
          Animation = { Windup = SHOUT, Slot = "UpperBody" }, Camera = { Fov = 5, DurationMs = 500 } },
        { Script = "zone", Name = "Jardin empoisonne", Description = "Un jardin de fleurs toxiques empoisonne la zone.",
          Shape = "self", Range = 450, Damage = 2, Cost = 22, CooldownMs = 10000,
          Timeline = { WindupMs = 350 },
          Zone = { Forward = 350, Radius = 450, Height = 300, DurationMs = 4000, TickMs = 500, Pull = 0, Lift = 0,
                   Poison = { Damage = 4, TickMs = 500, DurationMs = 2500 } },
          Hit = { Damage = 2, MaxTargets = 10 },
          Animation = { Windup = SPIN, Slot = "FullBody" }, Camera = { Fov = 4, DurationMs = 400 } },
        { Script = "bursts", Name = "Ultime : Floraison mortelle", Description = "Une explosion florale geante en spirale.",
          Shape = "self", Range = 800, Damage = 26, Cost = 55, CooldownMs = 40000,
          Requirements = { Level = 10 },
          Timeline = { WindupMs = 900 },
          Bursts = { Type = "rings", Radius = 220, Damage = 26, Knockback = 800, Lift = 450,
                     Rings = { { Radius = 250, Count = 5, DelayMs = 0 }, { Radius = 500, Count = 8, DelayMs = 220, Damage = 22 },
                               { Radius = 760, Count = 12, DelayMs = 440, Damage = 18 } } },
          Hit = { MaxTargets = 12 },
          Caster = { InvulnerableDuringWindup = true, RootDuringWindup = true },
          Animation = { Windup = SUMMON, Release = SHOUT, Slot = "FullBody" },
          Camera = { Fov = 12, ArmLength = 250, DurationMs = 1400 } },
    },
}
