--[[
    Demon Slayer RP - Souffles de la Flamme, du Tonnerre, de la Brume et du Serpent
    ------------------------------------------------------------------
    Techniques scriptées (comportements génériques, Server/Systems/Techniques/Generic.lua).
    Le rendu visuel vient de l'élément du souffle (Client/Systems/VFX/Elements) :
    seule la logique de jeu et la mise en scène (animation, caméra) sont ici.
]]

local CHOP = "nanos-world::A_Mannequin_Taunt_Chop"
local SPIN = "nanos-world::A_Mannequin_Taunt_Kunfu"
local PUNCH = "nanos-world::A_Mannequin_Taunt_HandPunch"
local THROW = "nanos-world::A_Mannequin_Throw_01"
local THROW2 = "nanos-world::A_Mannequin_Throw_02"
local SHOUT = "nanos-world::A_Mannequin_Shout"
local SUMMON = "nanos-world::A_Mannequin_Taunt_TheHeavins"

local Styles = Config.BreathingStyles

-- ===========================================================================
-- FLAMME (Rengoku) : charges frontales, arcs de feu, explosions
-- ===========================================================================
Styles.flamme = {
    Name = "Souffle de la Flamme",
    Description = "Style offensif et direct de la famille Rengoku : chaque coup est un brasier.",
    Color = "orange", BlockRegenMs = 3000,
    Techniques = {
        { Form = 1, Script = "dash", Name = "Premiere forme : Feu inconnu",
          Description = "Une charge fulgurante qui fend l'ennemi dans une traînee de flammes.",
          Shape = "self", Range = 800, Damage = 26, Cost = 16, CooldownMs = 4500,
          Timeline = { WindupMs = 220 },
          Dash = { Impulse = 1800, Lift = 120, Distance = 800, Width = 260, InvulnerableMs = 250 },
          Hit = { Damage = 26, Knockback = 600, Lift = 250, MaxTargets = 5 },
          Animation = { Windup = PUNCH, Slot = "UpperBody" }, Camera = { Fov = 9, DurationMs = 500 } },
        { Form = 2, Script = "combo", Name = "Deuxieme forme : Ciel ascendant",
          Description = "Deux arcs de feu ascendants qui projettent l'ennemi en l'air.",
          Shape = "self", Range = 380, Damage = 12, Cost = 14, CooldownMs = 3500,
          Timeline = { WindupMs = 200 },
          Combo = { Count = 2, IntervalMs = 200, Shape = "arc", Range = 380, Angle = 110 },
          Hit = { Damage = 12, Knockback = 300, Lift = 550, MaxTargets = 6 },
          Animation = { Windup = CHOP, Slot = "UpperBody" }, Camera = { Fov = 5, DurationMs = 400 } },
        { Form = 3, Script = "bursts", Name = "Troisieme forme : Univers flamboyant",
          Description = "Une coupe circulaire qui fait jaillir un anneau d'explosions.",
          Shape = "self", Range = 420, Damage = 18, Cost = 18, CooldownMs = 6000,
          Timeline = { WindupMs = 300 },
          Bursts = { Type = "rings", Radius = 180, Damage = 18, Knockback = 550, Lift = 300,
                     Rings = { { Radius = 260, Count = 6, DelayMs = 0 } } },
          Hit = { MaxTargets = 8 },
          Animation = { Windup = SPIN, Slot = "FullBody" }, Camera = { Fov = 6, DurationMs = 500 } },
        { Form = 5, Script = "projectiles", Name = "Cinquieme forme : Tigre flamboyant",
          Description = "Un tigre de flammes bondit et explose sur sa proie.",
          Shape = "self", Range = 1200, Damage = 20, Cost = 22, CooldownMs = 8000,
          Timeline = { WindupMs = 320 },
          Projectiles = { Count = 1, SpreadDeg = 0, Speed = 1700, Radius = 160, MaxDistance = 1200,
                          SpawnForward = 120, SpawnHeight = 60,
                          Explosion = { Radius = 320, Damage = 18, Knockback = 800, Lift = 400 } },
          Hit = { Damage = 20, MaxTargets = 8 },
          Animation = { Windup = THROW2, Slot = "UpperBody" }, Camera = { Fov = 6, DurationMs = 400 } },
        { Form = 9, Script = "dash", Name = "Ultime : Purgatoire",
          Description = "Technique ultime de Kyojuro Rengoku : une deflagration qui balaie tout sur sa route.",
          Shape = "self", Range = 1300, Damage = 55, Cost = 55, CooldownMs = 40000,
          Requirements = { Level = 10 },
          Timeline = { WindupMs = 1000 },
          Dash = { Impulse = 2600, Lift = 150, Distance = 1300, Width = 420, InvulnerableMs = 600 },
          Hit = { Damage = 55, Knockback = 1300, Lift = 600, MaxTargets = 10 },
          Caster = { InvulnerableDuringWindup = true, RootDuringWindup = true },
          Animation = { Windup = SHOUT, Release = PUNCH, Slot = "FullBody" },
          Camera = { Fov = 16, ArmLength = 220, DurationMs = 900 } },
    },
}

-- ===========================================================================
-- TONNERRE (Zenitsu) : vitesse extrême, élans éclairs
-- ===========================================================================
Styles.tonnerre = {
    Name = "Souffle du Tonnerre",
    Description = "Toute la puissance dans les jambes : des degainers a la vitesse de l'eclair.",
    Color = "yellow", BlockRegenMs = 2500,
    Techniques = {
        { Form = 1, Script = "dash", Name = "Premiere forme : Eclair foudroyant",
          Description = "Un degainer instantane : vous traversez l'ennemi comme la foudre.",
          Shape = "self", Range = 1000, Damage = 30, Cost = 18, CooldownMs = 4000,
          Timeline = { WindupMs = 260 },
          Dash = { Impulse = 2800, Lift = 60, Distance = 1000, Width = 220, InvulnerableMs = 300 },
          Hit = { Damage = 30, Knockback = 500, Lift = 150, MaxTargets = 4 },
          Animation = { Windup = PUNCH, Slot = "UpperBody" }, Camera = { Fov = 14, DurationMs = 350 } },
        { Form = 2, Script = "combo", Name = "Deuxieme forme : Esprit du riz",
          Description = "Cinq coups en arc autour de vous, en un instant.",
          Shape = "self", Range = 300, Damage = 5, Cost = 15, CooldownMs = 4500,
          Timeline = { WindupMs = 150 },
          Combo = { Count = 5, IntervalMs = 70, Shape = "circle", Range = 300 },
          Hit = { Damage = 5, Knockback = 200, Lift = 100, MaxTargets = 6 },
          Animation = { Windup = SPIN, Slot = "FullBody" }, Camera = { Fov = 6, DurationMs = 400 } },
        { Form = 3, Script = "dashchain", Name = "Troisieme forme : Essaim de tonnerre",
          Description = "Trois eclairs successifs qui frappent de tous cotes.",
          Shape = "self", Range = 600, Damage = 10, Cost = 20, CooldownMs = 6000,
          Timeline = { WindupMs = 180 },
          Dash = { Count = 3, IntervalMs = 180, AngleOffsets = { 0, 50, -50 }, Impulse = 2000, Lift = 60,
                   Distance = 600, Width = 240, InvulnerableMs = 150, MaxHits = 3 },
          Hit = { Damage = 10, Knockback = 300, Lift = 120, MaxTargets = 6 },
          Animation = { Windup = PUNCH, Slot = "UpperBody" }, Camera = { Fov = 12, DurationMs = 700 } },
        { Form = 4, Script = "projectiles", Name = "Quatrieme forme : Tonnerre lointain",
          Description = "Une decharge projetee au loin, qui traverse les ennemis.",
          Shape = "self", Range = 1600, Damage = 18, Cost = 16, CooldownMs = 5000,
          Timeline = { WindupMs = 220 },
          Projectiles = { Count = 1, SpreadDeg = 0, Speed = 4000, Radius = 110, MaxDistance = 1600, Pierce = true,
                          SpawnForward = 100, SpawnHeight = 50 },
          Hit = { Damage = 18, Knockback = 250, Lift = 80, MaxTargets = 6 },
          Animation = { Windup = THROW, Slot = "UpperBody" }, Camera = { Fov = 5, DurationMs = 300 } },
        { Form = 7, Script = "dash", Name = "Ultime : Honoikazuchi no Kami",
          Description = "Septieme forme creee par Zenitsu : un dragon de foudre plus rapide que le regard.",
          Shape = "self", Range = 1600, Damage = 58, Cost = 55, CooldownMs = 40000,
          Requirements = { Level = 10 },
          Timeline = { WindupMs = 900 },
          Dash = { Impulse = 3600, Lift = 80, Distance = 1600, Width = 360, InvulnerableMs = 600 },
          Hit = { Damage = 58, Knockback = 1000, Lift = 500, MaxTargets = 8 },
          Caster = { InvulnerableDuringWindup = true, RootDuringWindup = true },
          Animation = { Windup = SUMMON, Release = PUNCH, Slot = "FullBody" },
          Camera = { Fov = 18, ArmLength = 200, DurationMs = 700 } },
    },
}

-- ===========================================================================
-- BRUME (Muichiro) : apparitions soudaines, brouillard, coups trompeurs
-- ===========================================================================
Styles.brume = {
    Name = "Souffle de la Brume",
    Description = "Derive du vent : on ne voit plus le sabreur, seulement la brume qui frappe.",
    Color = "grey", BlockRegenMs = 2500,
    Techniques = {
        { Form = 1, Script = "dash", Name = "Premiere forme : Nuages bas, brume lointaine",
          Description = "Vous vous dissolvez dans la brume et reapparaissez derriere l'ennemi.",
          Shape = "self", Range = 750, Damage = 22, Cost = 15, CooldownMs = 4000,
          Timeline = { WindupMs = 180 },
          Dash = { Impulse = 1900, Lift = 60, Distance = 750, Width = 200, InvulnerableMs = 450 },
          Hit = { Damage = 22, Knockback = 350, Lift = 100, MaxTargets = 4 },
          Animation = { Windup = PUNCH, Slot = "UpperBody" }, Camera = { Fov = 8, DurationMs = 450 } },
        { Form = 2, Script = "combo", Name = "Deuxieme forme : Brume aux huit couches",
          Description = "Huit coups qui surgissent du brouillard.",
          Shape = "self", Range = 400, Damage = 4, Cost = 18, CooldownMs = 5000,
          Timeline = { WindupMs = 150 },
          Combo = { Count = 8, IntervalMs = 80, Shape = "arc", Range = 400, Angle = 120 },
          Hit = { Damage = 4, Knockback = 120, Lift = 40, MaxTargets = 6 },
          Animation = { Windup = CHOP, Slot = "UpperBody" }, Camera = { Fov = 5, DurationMs = 700 } },
        { Form = 3, Script = "zone", Name = "Troisieme forme : Eclaboussures de brume",
          Description = "Une nappe de brume dense ralentit et entaille ceux qui s'y trouvent.",
          Shape = "self", Range = 450, Damage = 4, Cost = 20, CooldownMs = 9000,
          Timeline = { WindupMs = 300 },
          Zone = { Forward = 300, Radius = 450, Height = 300, DurationMs = 3000, TickMs = 500,
                   Pull = 0, Lift = 0, Slow = { Multiplier = 0.55, DurationMs = 700 } },
          Hit = { Damage = 4, MaxTargets = 8 },
          Animation = { Windup = SPIN, Slot = "UpperBody" }, Camera = { Fov = 4, DurationMs = 400 } },
        { Form = 4, Script = "dashchain", Name = "Quatrieme forme : Tranchant du flux changeant",
          Description = "Deux glissements au ras du sol, invisibles dans la brume.",
          Shape = "self", Range = 500, Damage = 12, Cost = 18, CooldownMs = 6000,
          Timeline = { WindupMs = 150 },
          Dash = { Count = 2, IntervalMs = 300, AngleOffsets = { -25, 25 }, Impulse = 1500, Lift = 40,
                   Distance = 500, Width = 220, InvulnerableMs = 300, MaxHits = 2 },
          Hit = { Damage = 12, Knockback = 250, Lift = 80, MaxTargets = 6 },
          Animation = { Windup = CHOP, Slot = "UpperBody" }, Camera = { Fov = 9, DurationMs = 700 } },
        { Form = 7, Script = "zone", Name = "Ultime : Brume obscurcissante",
          Description = "Forme creee par Muichiro : la brume vous entoure, vous rend insaisissable et dechire tout.",
          Shape = "self", Range = 520, Damage = 8, Cost = 50, CooldownMs = 35000,
          Requirements = { Level = 10 },
          Timeline = { WindupMs = 600 },
          Zone = { Follow = true, Radius = 520, Height = 400, DurationMs = 4000, TickMs = 400,
                   Pull = 0, Lift = 80, Slow = { Multiplier = 0.5, DurationMs = 600 },
                   FinalBurst = { Damage = 22, Knockback = 900, Lift = 350 } },
          Hit = { Damage = 8, MaxTargets = 10 },
          Caster = { InvulnerableDuringWindup = true },
          Animation = { Windup = SHOUT, Release = SPIN, Slot = "FullBody" },
          Camera = { Fov = 10, ArmLength = 200, DurationMs = 4000 } },
    },
}

-- ===========================================================================
-- SERPENT (Obanai) : trajectoires sinueuses, crochets précis
-- ===========================================================================
Styles.serpent = {
    Name = "Souffle du Serpent",
    Description = "Derive de l'eau : la lame ondule comme un serpent et frappe la ou on ne l'attend pas.",
    Color = "purple", BlockRegenMs = 2500,
    Techniques = {
        { Form = 1, Script = "whip", Name = "Premiere forme : Tranchant sinueux",
          Description = "Un coup qui ondule vers l'avant comme un serpent.",
          Shape = "self", Range = 800, Damage = 14, Cost = 14, CooldownMs = 4000,
          Timeline = { WindupMs = 180 },
          Whip = { Path = "sine", Distance = 800, Amplitude = 140, Waves = 2, DurationMs = 450,
                   Radius = 110, MaxHitsPerTarget = 1 },
          Hit = { Damage = 14, Knockback = 300, Lift = 100, MaxTargets = 6 },
          Animation = { Windup = CHOP, Slot = "UpperBody" }, Camera = { Fov = 5, DurationMs = 450 } },
        { Form = 2, Script = "dash", Name = "Deuxieme forme : Crochets venimeux",
          Description = "Un estoc d'une precision absolue qui ralentit la cible.",
          Shape = "self", Range = 900, Damage = 24, Cost = 16, CooldownMs = 5000,
          Timeline = { WindupMs = 200 },
          Dash = { Impulse = 2000, Lift = 60, Distance = 900, Width = 140, InvulnerableMs = 250 },
          Hit = { Damage = 24, Knockback = 250, Lift = 60, Slow = { Multiplier = 0.6, DurationMs = 2500 }, MaxTargets = 2 },
          Animation = { Windup = PUNCH, Slot = "UpperBody" }, Camera = { Fov = 10, DurationMs = 400 } },
        { Form = 3, Script = "whip", Name = "Troisieme forme : Etreinte enroulee",
          Description = "La lame s'enroule en spirale autour de vous et serre ses proies.",
          Shape = "self", Range = 450, Damage = 10, Cost = 18, CooldownMs = 7000,
          Timeline = { WindupMs = 200 },
          Whip = { Path = "spiral", StartRadius = 120, Distance = 450, Turns = 1.5, DurationMs = 700,
                   Radius = 120, MaxHitsPerTarget = 2, HitIntervalMs = 250 },
          Hit = { Damage = 10, Knockback = 150, Lift = 60, Slow = { Multiplier = 0.4, DurationMs = 1500 }, MaxTargets = 8 },
          Animation = { Windup = SPIN, Slot = "FullBody" }, Camera = { Fov = 5, DurationMs = 700 } },
        { Form = 4, Script = "whip", Name = "Quatrieme forme : Reptile a deux tetes",
          Description = "Deux tetes de serpent ondulent en miroir et se croisent sur l'ennemi.",
          Shape = "self", Range = 850, Damage = 13, Cost = 20, CooldownMs = 7000,
          Timeline = { WindupMs = 220 },
          Whip = { Path = "sine", Distance = 850, Amplitude = 200, Waves = 1.5, DurationMs = 550, Heads = 2,
                   Radius = 110, MaxHitsPerTarget = 2, HitIntervalMs = 200 },
          Hit = { Damage = 13, Knockback = 300, Lift = 120, MaxTargets = 8 },
          Animation = { Windup = THROW, Slot = "UpperBody" }, Camera = { Fov = 6, DurationMs = 550 } },
        { Form = 5, Script = "beast", Name = "Ultime : Serpent ondoyant",
          Description = "Technique ultime d'Obanai Iguro : un serpent geant de lame ondule et s'abat sur ses proies.",
          Shape = "self", Range = 2800, Damage = 18, Cost = 55, CooldownMs = 40000,
          Requirements = { Level = 10 },
          Timeline = { WindupMs = 800, TravelMs = 2200, ImpactMs = 800 },
          Beast = { Distance = 2800, StartBack = 100, Height = 120, Amplitude = 320, Waves = 3,
                    Segments = 8, SegmentDelayMs = 90, HitRadius = 260, HitIntervalMs = 400, MaxHitsPerTarget = 3 },
          Hit = { Damage = 18, Knockback = 500, Lift = 250, MaxTargets = 12 },
          Impact = { Radius = 600, Damage = 35, Knockback = 1200, Lift = 500 },
          Caster = { InvulnerableDuringWindup = true, RootDuringWindup = true },
          Animation = { Windup = SPIN, Release = THROW2, Slot = "FullBody" },
          Camera = { Fov = 14, ArmLength = 260, DurationMs = 2400 } },
    },
}
