--[[
    Demon Slayer RP - Identités visuelles des SOUFFLES (client)
    ------------------------------------------------------------------
    Chaque élément définit :
      Colors     Core / Accent / Highlight ({r,g,b} 0..1) + Glow (luminosité)
      Trail      Width / Life (traînée de lame), SlashWidth, DashWidth, Layers attachées
      Slash      Body (milieu de l'arc), Tip (fin de l'arc), Sparks (nombre)
      Impact     Core, Ring, Dust, Secondary, Linger (dissipation)
      Projectile Core (couches qui se déplacent), Trail, TrailWidth
      Dash       Start, Path, Lightning (éclairs autour du joueur)
      Aura       Layers attachées au personnage
      Zone       Core, Orbit, Ambient, Spin, RiseSpeed
      Sounds     Slash, Impact, Big, Projectile, Dash, Loop

    Toutes les particules / sons cités existent dans le pack "nanos-world".
    Les particules modèles (P_Ribbon, P_Beam, P_*Burst, P_Fountain,
    P_HangingParticulates) sont recolorées ; les autres gardent leurs couleurs.
]]

local VFX = DS.VFX
local L, S = DS.VFXUtils.L, DS.VFXUtils.S

-- ===========================================================================
-- EAU : bleu / cyan / blanc lumineux, fluide et rapide
-- ===========================================================================
VFX.RegisterElement("water", {
    Colors = { Core = { 0.05, 0.45, 1.0 }, Accent = { 0.25, 0.85, 1.0 }, Highlight = { 0.8, 0.95, 1.0 }, Glow = 5 },
    Trail = { Width = 26, Life = 0.4, CoreWidth = 7, SlashWidth = 46, SlashLife = 0.38, DashWidth = 70,
              Layers = { L("P_HangingParticulates", 0.3, 1, { Priority = "detail", Params = { Color = Color(0.6, 2.2, 4, 1), BoxSize = Vector(40, 40, 40), SpawnRate = 40 } }) } },
    Slash = { Body = { L("P_FXVariety_WaterBallHit", 0.6, 1.0), L("P_LTGrenadeEXP_Water", 0.5, 1.0, { Priority = "detail" }) },
              Tip = { L("P_Water_Impact", 0.6, 0.9) }, Sparks = 35 },
    Impact = { Core = { L("P_FXVariety_WaterBallHit", 1.0, 1.2), L("P_Explosion_Water", 0.7, 1.6) },
               Ring = "nanos-world::P_ShockWave_02",
               Dust = { L("P_GrenadeEXP_Water", 0.9, 2.0) },
               Secondary = { L("P_Fountain", 0.9, 1.2, { Params = { Color = Color(0.4, 1.6, 4, 1), VelocityStrengthMax = 700, SpawnRate = 160 } }) },
               Linger = { L("P_Smoke_03", 0.9, 2.5) } },
    Projectile = { Core = { L("P_FXVariety_WaterBall", 0.9, 1) }, TrailWidth = 28,
                   Trail = { L("P_LTGrenadeEXP_Water", 0.3, 0.6) } },
    Dash = { Start = { L("P_Explosion_Water", 0.6, 1.2) }, Path = { L("P_Water_Impact", 0.6, 0.8) } },
    Aura = { Layers = { L("P_FXVariety_AquaStorm", 0.6, 1, { Bone = "pelvis" }) } },
    Zone = { Core = { L("P_FXVariety_AquaStorm", 2.0, 3), L("P_Fountain", 1.4, 3, { Params = { Color = Color(0.3, 1.4, 4, 1), SpawnRate = 200 } }) },
             Orbit = "nanos-world::P_FXVariety_WaterBall", OrbitScale = 0.5,
             Ambient = { L("P_LTGrenadeEXP_Water", 0.5, 0.9) }, Spin = 5.5, RiseSpeed = 0.45 },
    Sounds = {
        Slash = { S("A_Whoosh", 0.8, 1.05), S("A_Water_Impact_MS", 0.35, 1.5) },
        Impact = { S("A_Water_Impact_MS", 0.9, 1.0), S("A_Flesh_Impact_MS", 0.6, 1.0) },
        Big = { S("A_Explosion_Small", 0.6, 0.7) },
        Projectile = { S("A_Thruster_02", 0.25, 1.3, 1.0) },
        Dash = { S("A_Thruster_02", 0.4, 1.4, 0.6), S("A_Water_Impact_MS", 0.6, 1.2) },
        Loop = { S("A_WhiteNoise", 0.3, 0.7, 3), S("A_Thruster_02", 0.25, 0.5, 3) },
    },
})

-- ===========================================================================
-- FLAMME : orange / rouge / jaune, cœur blanc ; braises, chaleur, explosions
-- ===========================================================================
VFX.RegisterElement("flame", {
    Colors = { Core = { 1.0, 0.35, 0.05 }, Accent = { 1.0, 0.7, 0.15 }, Highlight = { 1.0, 0.95, 0.75 }, Glow = 7 },
    Trail = { Width = 30, Life = 0.35, CoreWidth = 9, SlashWidth = 52, SlashLife = 0.32, DashWidth = 80,
              Layers = { L("P_Fire_02", 0.25, 1, { Priority = "secondary" }) } },
    Slash = { Body = { L("P_Fire_Exp_01", 0.6, 1.0), L("P_Distortion_01", 0.6, 0.6, { Priority = "detail" }) },
              Tip = { L("P_SparksFlair", 0.7, 1.0) }, Sparks = 45 },
    Impact = { Core = { L("P_Fire_Exp_02", 1.0, 1.4), L("P_FXVariety_FireBall", 0.6, 1.0) },
               Ring = "nanos-world::P_ShockWave_05",
               Dust = { L("P_Explosion_Fire_02", 0.8, 1.8) },
               Secondary = { L("P_Fire_Grd_01", 0.8, 2.0), L("P_SparksFlair", 1.0, 1.4) },
               Linger = { L("P_Smoke_02", 0.8, 2.5), L("P_Distortion_01", 0.8, 1.5) } },
    Projectile = { Core = { L("P_FXVariety_FireBall", 0.8, 1) }, TrailWidth = 32,
                   Trail = { L("P_Fire_05", 0.25, 0.6) } },
    Dash = { Start = { L("P_Fire_Exp_01", 0.7, 1.0) }, Path = { L("P_Fire_03", 0.35, 0.8) } },
    Aura = { Layers = { L("P_Fire_04", 0.6, 1, { Bone = "pelvis" }), L("P_Distortion_01", 0.8, 1, { Bone = "pelvis", Priority = "detail" }) } },
    Zone = { Core = { L("P_FXVariety_FireStorm", 2.0, 3), L("P_Fire_Grd_02", 1.6, 3) },
             Orbit = "nanos-world::P_FXVariety_FireBall", OrbitScale = 0.4,
             Ambient = { L("P_SparksFlair", 0.6, 1.0), L("P_Fire_06", 0.4, 1.0) }, Spin = 4, RiseSpeed = 0.6 },
    Sounds = {
        Slash = { S("A_Whoosh", 0.9, 0.9), S("A_Explosion_Small", 0.25, 1.6) },
        Impact = { S("A_Explosion_Small", 0.7, 1.2), S("A_Flesh_Impact_MS", 0.6, 0.9) },
        Big = { S("A_Explosion_Large", 0.7, 0.9) },
        Projectile = { S("A_Thruster_01", 0.3, 1.2, 1.0) },
        Dash = { S("A_Thruster_01", 0.45, 1.1, 0.6), S("A_Explosion_Small", 0.4, 1.4) },
        Loop = { S("A_Thruster_04", 0.3, 0.6, 3) },
    },
})

-- Soleil (Hinokami Kagura) : flamme plus claire, presque dorée
VFX.RegisterElement("sun", {
    Colors = { Core = { 1.0, 0.55, 0.1 }, Accent = { 1.0, 0.85, 0.3 }, Highlight = { 1.0, 1.0, 0.9 }, Glow = 9 },
    Trail = { Width = 34, Life = 0.4, CoreWidth = 12, SlashWidth = 60, SlashLife = 0.4, DashWidth = 90,
              Layers = { L("P_Fire_01", 0.3, 1) } },
    Slash = { Body = { L("P_FXVariety_ShootingStar", 0.6, 1.0), L("P_Fire_Exp_03", 0.6, 1.0) },
              Tip = { L("P_SparksFlair", 0.9, 1.0) }, Sparks = 55 },
    Impact = { Core = { L("P_Explosion_Fire_03", 0.9, 1.6), L("P_FXVariety_ShootingStar", 0.6, 1.0) },
               Ring = "nanos-world::P_ShockWave_06",
               Dust = { L("P_Fire_Grd_03", 0.9, 2.0) },
               Secondary = { L("P_SparksFlair", 1.2, 1.4) },
               Linger = { L("P_Distortion_01", 1.0, 1.6), L("P_Smoke_02", 0.7, 2.2) } },
    Projectile = { Core = { L("P_FXVariety_FireBall", 0.9, 1) }, TrailWidth = 36 },
    Dash = { Start = { L("P_Fire_Exp_03", 0.8, 1.0) }, Path = { L("P_Fire_02", 0.4, 0.8) } },
    Aura = { Layers = { L("P_Fire_04", 0.7, 1, { Bone = "pelvis" }) } },
    Zone = { Core = { L("P_FXVariety_FireStorm", 2.2, 3) }, Orbit = "nanos-world::P_FXVariety_FireBall", OrbitScale = 0.45,
             Ambient = { L("P_SparksFlair", 0.7, 1.0) } },
    Sounds = {
        Slash = { S("A_Whoosh", 1.0, 0.85), S("A_Explosion_Small", 0.3, 1.4) },
        Impact = { S("A_Explosion_Small", 0.8, 1.0) }, Big = { S("A_Explosion_Large", 0.8, 0.85) },
        Dash = { S("A_Thruster_01", 0.5, 1.0, 0.6) }, Loop = { S("A_Thruster_04", 0.3, 0.6, 3) },
    },
})

-- ===========================================================================
-- TONNERRE : jaune / blanc électrique, extrêmement rapide
-- ===========================================================================
VFX.RegisterElement("thunder", {
    Colors = { Core = { 1.0, 0.85, 0.15 }, Accent = { 1.0, 1.0, 0.45 }, Highlight = { 1.0, 1.0, 1.0 }, Glow = 9 },
    Trail = { Width = 18, Life = 0.22, CoreWidth = 7, SlashWidth = 34, SlashLife = 0.2, DashWidth = 90,
              Layers = { L("P_Sparks", 0.4, 1, { Priority = "secondary" }) } },
    Slash = { Body = { L("P_FXVariety_Lightning_02", 0.5, 0.5) }, Tip = { L("P_FXVariety_ThunderBallHit", 0.5, 0.6) }, Sparks = 50 },
    Impact = { Core = { L("P_FXVariety_ThunderBallHit", 0.9, 0.9), L("P_FXVariety_Lightning_03", 0.7, 0.6) },
               Ring = "nanos-world::P_ShockWave_08",
               Dust = { L("P_Sparks", 1.2, 1.0) },
               Secondary = { L("P_FXVariety_Lightning_01", 0.9, 0.7), L("P_SparksFlair", 1.0, 1.0) },
               Linger = { L("P_Smoke_01", 0.6, 1.5) } },
    Projectile = { Core = { L("P_FXVariety_ThunderBall", 0.7, 1) }, TrailWidth = 20, Trail = { L("P_Sparks", 0.3, 0.4) } },
    Dash = { Start = { L("P_FXVariety_ThunderBallHit", 0.8, 0.7) }, Path = { L("P_Sparks", 0.5, 0.5) }, Lightning = true },
    Aura = { Layers = { L("P_FXVariety_Lightning_01", 0.4, 1, { Bone = "pelvis" }), L("P_Sparks", 0.5, 1, { Bone = "hand_r" }) } },
    Zone = { Core = { L("P_FXVariety_ThunderStorm", 1.8, 3) }, Orbit = "nanos-world::P_FXVariety_ThunderBall", OrbitScale = 0.35,
             Ambient = { L("P_FXVariety_Lightning_02", 0.5, 0.4) }, Spin = 8, RiseSpeed = 0.9 },
    Sounds = {
        Slash = { S("A_Whoosh", 0.9, 1.5), S("A_Laser_Push", 0.4, 1.2) },
        Impact = { S("A_Explosion_Small", 0.6, 1.6), S("A_Laser_Pull", 0.4, 1.4) },
        Big = { S("A_Explosion_Large", 0.6, 1.3) },
        Projectile = { S("A_Laser_Push", 0.4, 1.0) },
        Dash = { S("A_Laser_Push", 0.6, 0.8), S("A_Whoosh", 1.0, 1.8) },
        Loop = { S("A_WhiteNoise", 0.2, 2.0, 3) },
    },
})

-- ===========================================================================
-- VENT : tornades, spirales, lames d'air, débris
-- ===========================================================================
VFX.RegisterElement("wind", {
    Colors = { Core = { 0.55, 0.95, 0.65 }, Accent = { 0.85, 1.0, 0.85 }, Highlight = { 1.0, 1.0, 1.0 }, Glow = 3 },
    Trail = { Width = 34, Life = 0.45, CoreWidth = 6, SlashWidth = 56, SlashLife = 0.45, DashWidth = 80,
              Layers = { L("P_Distortion_01", 0.4, 1, { Priority = "detail" }) } },
    Slash = { Body = { L("P_ShockWave_07", 0.6, 0.6), L("P_FXVariety_Storm", 0.4, 0.8, { Priority = "detail" }) },
              Tip = { L("P_Smoke_01", 0.5, 1.2), L("P_GrenadeEXP_Grass", 0.4, 1.2, { Priority = "detail" }) }, Sparks = 25 },
    Impact = { Core = { L("P_ShockWave_03", 1.0, 0.9), L("P_FXVariety_Storm", 0.7, 1.0) },
               Ring = "nanos-world::P_ShockWave_12",
               Dust = { L("P_GrenadeEXP_Dirt", 0.8, 1.8), L("P_GrenadeEXP_Grass", 0.7, 1.8) },
               Secondary = { L("P_Distortion_02", 0.9, 1.0) },
               Linger = { L("P_Smoke_02", 0.9, 2.2) } },
    Projectile = { Core = { L("P_FXVariety_Storm", 0.8, 1), L("P_ShockWave_07", 0.7, 1) }, TrailWidth = 40,
                   Trail = { L("P_Smoke_01", 0.4, 0.8) } },
    Dash = { Start = { L("P_ShockWave_05", 0.8, 0.7) }, Path = { L("P_Smoke_01", 0.4, 0.9) } },
    Aura = { Layers = { L("P_FXVariety_Storm", 0.5, 1, { Bone = "pelvis" }) } },
    Zone = { Core = { L("P_FXVariety_Storm", 2.2, 3), L("P_FXVariety_DarkStorm", 1.4, 3, { Up = 250 }) },
             Orbit = "nanos-world::P_Smoke_01", OrbitScale = 0.6,
             Ambient = { L("P_GrenadeEXP_Grass", 0.5, 1.0), L("P_Smoke_02", 0.5, 1.4) }, Spin = 8, RiseSpeed = 0.8 },
    Sounds = {
        Slash = { S("A_Whoosh", 1.0, 0.75), S("A_WhiteNoise", 0.15, 1.3, 0.4) },
        Impact = { S("A_Body_Impact_Cue", 0.7, 1.0), S("A_Whoosh", 0.6, 0.6) },
        Big = { S("A_Explosion_Small", 0.5, 0.7) },
        Projectile = { S("A_Thruster_03", 0.3, 1.5, 1.0) },
        Dash = { S("A_Whoosh", 1.0, 0.6), S("A_Thruster_03", 0.3, 1.2, 0.5) },
        Loop = { S("A_WhiteNoise", 0.35, 0.8, 3), S("A_Thruster_01", 0.3, 0.6, 3) },
    },
})

-- ===========================================================================
-- BRUME : brouillard, silhouettes, apparitions soudaines
-- ===========================================================================
VFX.RegisterElement("mist", {
    Colors = { Core = { 0.75, 0.85, 1.0 }, Accent = { 0.9, 0.95, 1.0 }, Highlight = { 1.0, 1.0, 1.0 }, Glow = 2 },
    Trail = { Width = 40, Life = 0.7, CoreWidth = 5, SlashWidth = 60, SlashLife = 0.7, DashWidth = 90,
              Layers = { L("P_Smoke_03", 0.3, 1, { Priority = "detail" }) } },
    Slash = { Body = { L("P_Smoke_04", 0.7, 1.6) }, Tip = { L("P_Smoke_02", 0.6, 1.8), L("P_Distortion_02", 0.5, 0.8, { Priority = "detail" }) }, Sparks = 15 },
    Impact = { Core = { L("P_Smoke_05", 0.9, 2.0), L("P_Distortion_02", 0.7, 0.8) },
               Ring = "nanos-world::P_ShockWave_01",
               Dust = { L("P_Smoke_06", 1.0, 2.6) },
               Secondary = { L("P_HangingParticulates", 1.0, 2.0, { Params = { Color = Color(1.5, 1.6, 2, 1), BoxSize = Vector(300, 300, 150), SpawnRate = 60 } }) },
               Linger = { L("P_Smoke_07", 1.0, 3.5) } },
    Projectile = { Core = { L("P_Smoke_04", 0.6, 1), L("P_Distortion_02", 0.5, 1) }, TrailWidth = 36, Trail = { L("P_Smoke_01", 0.4, 1.2) } },
    Dash = { Start = { L("P_Smoke_06", 1.0, 2.2) }, Path = { L("P_Smoke_03", 0.5, 1.6) }, Vanish = 0.45 },
    Aura = { Layers = { L("P_Smoke_03", 0.6, 1, { Bone = "pelvis" }), L("P_Distortion_02", 0.6, 1, { Bone = "pelvis", Priority = "detail" }) } },
    Zone = { Core = { L("P_Smoke_07", 2.0, 3), L("P_HangingParticulates", 1.5, 3, { Params = { Color = Color(1.4, 1.5, 1.8, 1), BoxSize = Vector(500, 500, 250), SpawnRate = 90 } }) },
             Orbit = "nanos-world::P_Smoke_02", OrbitScale = 0.6, Ambient = { L("P_Smoke_01", 0.5, 1.8) }, Spin = 2.5, RiseSpeed = 0.2 },
    Sounds = {
        Slash = { S("A_Whoosh", 0.7, 0.95), S("A_WhiteNoise", 0.12, 1.1, 0.5) },
        Impact = { S("A_Body_Impact_Cue", 0.6, 1.0), S("A_Whoosh", 0.4, 0.7) },
        Big = { S("A_WhiteNoise", 0.3, 0.6, 1.2) },
        Dash = { S("A_Whoosh", 0.9, 0.7), S("A_WhiteNoise", 0.2, 0.9, 0.6) },
        Loop = { S("A_WhiteNoise", 0.25, 0.6, 3) },
    },
})

-- ===========================================================================
-- PIERRE / BÊTE
-- ===========================================================================
VFX.RegisterElement("stone", {
    Colors = { Core = { 0.65, 0.55, 0.45 }, Accent = { 0.85, 0.75, 0.6 }, Highlight = { 1.0, 0.95, 0.85 }, Glow = 2 },
    Trail = { Width = 36, Life = 0.3, CoreWidth = 6, SlashWidth = 60, DashWidth = 70 },
    Slash = { Body = { L("P_ImpactExplosion_01", 0.5, 1.0) }, Tip = { L("P_GrenadeEXP_Concrete", 0.5, 1.4) }, Sparks = 20 },
    Impact = { Core = { L("P_HighImpact", 1.0, 1.4), L("P_ImpactExplosion_03", 0.8, 1.4) }, Ring = "nanos-world::P_ShockWave_09",
               Dust = { L("P_GrenadeEXP_Concrete", 1.0, 2.2), L("P_GrenadeEXP_Dirt", 0.9, 2.2) },
               Secondary = { L("P_Destruction", 0.8, 2.0) }, Linger = { L("P_Smoke_05", 0.9, 2.8) } },
    Projectile = { Core = { L("P_HighImpact", 0.4, 1) }, TrailWidth = 26 },
    Dash = { Start = { L("P_GrenadeEXP_Dirt", 0.7, 1.4) }, Path = { L("P_Smoke_01", 0.4, 1.0) } },
    Zone = { Core = { L("P_Destruction", 1.6, 3) }, Orbit = "nanos-world::P_GrenadeEXP_Concrete", Ambient = { L("P_GrenadeEXP_Dirt", 0.5, 1.2) } },
    Sounds = { Slash = { S("A_Whoosh", 1.0, 0.6) }, Impact = { S("A_BigHammer_Impact", 0.9, 1.0) }, Big = { S("A_BigHammer_Land", 0.9, 0.8) } },
})

VFX.RegisterElement("beast", {
    Colors = { Core = { 0.6, 0.65, 0.75 }, Accent = { 0.85, 0.85, 0.9 }, Highlight = { 1, 1, 1 }, Glow = 2.5 },
    Trail = { Width = 22, Life = 0.25, SlashWidth = 40, DashWidth = 60 },
    Slash = { Body = { L("P_FXVariety_Hit_02", 0.6, 0.6) }, Tip = { L("P_GrenadeEXP_Dirt", 0.4, 1.0) }, Sparks = 30 },
    Impact = { Core = { L("P_FXVariety_Hit_02", 1.0, 0.9), L("P_HighImpact", 0.6, 1.0) }, Ring = "nanos-world::P_ShockWave_04",
               Dust = { L("P_GrenadeEXP_Dirt", 0.8, 1.6) }, Linger = { L("P_Smoke_01", 0.7, 1.8) } },
    Dash = { Start = { L("P_GrenadeEXP_Dirt", 0.6, 1.0) }, Path = { L("P_Smoke_01", 0.3, 0.8) } },
    Sounds = { Slash = { S("A_Whoosh", 1.0, 1.0), S("A_Punch_Cue", 0.4, 1.2) }, Impact = { S("A_Flesh_Impact_MS", 0.9, 0.9) } },
})
