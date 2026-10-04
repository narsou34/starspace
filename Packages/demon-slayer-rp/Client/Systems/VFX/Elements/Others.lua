--[[
    Demon Slayer RP - Identités visuelles : ARTS DÉMONIAQUES + autres souffles (client)
    ------------------------------------------------------------------
    Arts démoniaques : style sombre et agressif, chacun reconnaissable.
      ice      cristaux, fragments, gel, brume froide, pics, scintillements
      shadow   fumée noire, énergie violette, vortex, distorsion
      blood    énergie rouge stylisée, cercles, lignes d'énergie
      flower   pétales, spirales, éclats lumineux, explosions florales
    Autres souffles : sound, insect, love, serpent. Puis "neutral" (repli)
    et la table d'association souffle / art -> élément.
]]

local VFX = DS.VFX
local L, S = DS.VFXUtils.L, DS.VFXUtils.S

-- ===========================================================================
-- GLACE
-- ===========================================================================
VFX.RegisterElement("ice", {
    Colors = { Core = { 0.55, 0.85, 1.0 }, Accent = { 0.8, 0.95, 1.0 }, Highlight = { 1.0, 1.0, 1.0 }, Glow = 4 },
    Trail = { Width = 24, Life = 0.5, CoreWidth = 8, SlashWidth = 44, SlashLife = 0.5, DashWidth = 60,
              Layers = { L("P_FlareShimmer_02", 0.3, 1, { Priority = "detail" }) } },
    Slash = { Body = { L("P_LTGrenadeEXP_Ice", 0.6, 1.2) }, Tip = { L("P_FlareShimmer_01", 0.6, 1.0), L("P_LTGrenadeEXP_Snow", 0.4, 1.2) }, Sparks = 40 },
    Impact = { Core = { L("P_GrenadeEXP_Ice", 0.9, 1.6), L("P_FlareShimmer_01", 0.8, 1.2) },
               Ring = "nanos-world::P_ShockWave_02",
               Dust = { L("P_GrenadeEXP_Snow", 0.9, 2.2) },
               Secondary = { L("P_HangingParticulates", 0.9, 2.5, { Params = { Color = Color(2, 3, 4, 1), BoxSize = Vector(250, 250, 200), SpawnRate = 70 } }) },
               Linger = { L("P_Smoke_03", 0.8, 3.0) } },
    Projectile = { Core = { L("P_LTGrenadeEXP_Ice", 0.5, 1), L("P_FlareShimmer_02", 0.5, 1) }, TrailWidth = 22,
                   Trail = { L("P_FlareShimmer_01", 0.3, 0.8) } },
    Dash = { Start = { L("P_GrenadeEXP_Ice", 0.6, 1.2) }, Path = { L("P_LTGrenadeEXP_Snow", 0.3, 1.0) } },
    Aura = { Layers = { L("P_HangingParticulates", 0.5, 1, { Bone = "pelvis", Params = { Color = Color(2, 3, 4, 1), BoxSize = Vector(120, 120, 180), SpawnRate = 50 } }) } },
    Zone = { Core = { L("P_GrenadeEXP_Snow", 1.6, 3), L("P_Smoke_06", 1.6, 3),
                      L("P_HangingParticulates", 1.6, 3, { Params = { Color = Color(2, 3, 4, 1), BoxSize = Vector(600, 600, 300), SpawnRate = 120 } }) },
             Orbit = "nanos-world::P_FlareShimmer_02", OrbitScale = 0.6, Ambient = { L("P_LTGrenadeEXP_Ice", 0.5, 1.2) }, Spin = 3, RiseSpeed = 0.3 },
    Sounds = {
        Slash = { S("A_Whoosh", 0.8, 1.2), S("A_MetalHeavy_Impact_MS", 0.25, 1.8) },
        Impact = { S("A_MetalHeavy_Impact_MS", 0.6, 1.6), S("A_Explosion_Small", 0.3, 1.8) },
        Big = { S("A_Explosion_Small", 0.6, 1.3) },
        Projectile = { S("A_Whoosh", 0.6, 1.6) },
        Loop = { S("A_WhiteNoise", 0.2, 1.4, 3) },
    },
})

-- ===========================================================================
-- OMBRE
-- ===========================================================================
VFX.RegisterElement("shadow", {
    Colors = { Core = { 0.45, 0.05, 0.75 }, Accent = { 0.75, 0.2, 1.0 }, Highlight = { 0.95, 0.75, 1.0 }, Glow = 4 },
    Trail = { Width = 34, Life = 0.55, CoreWidth = 6, SlashWidth = 52, SlashLife = 0.55, DashWidth = 80,
              Layers = { L("P_Smoke_05", 0.3, 1, { Priority = "detail" }) } },
    Slash = { Body = { L("P_FXVariety_DarkStorm", 0.5, 1.0), L("P_Distortion_02", 0.6, 0.8, { Priority = "detail" }) },
              Tip = { L("P_Smoke_07", 0.5, 1.5) }, Sparks = 35 },
    Impact = { Core = { L("P_FXVariety_DarkStorm", 0.9, 1.4), L("P_Distortion_3D", 0.8, 1.0) },
               Ring = "nanos-world::P_ShockWave_11",
               Dust = { L("P_Smoke_07", 1.0, 2.5) },
               Secondary = { L("P_Distortion_SQ", 0.9, 1.2) },
               Linger = { L("P_Smoke_05", 1.0, 3.0) } },
    Projectile = { Core = { L("P_FXVariety_DarkStorm", 0.6, 1), L("P_Distortion_02", 0.6, 1) }, TrailWidth = 30,
                   Trail = { L("P_Smoke_05", 0.4, 1.0) } },
    Dash = { Start = { L("P_Smoke_07", 0.9, 1.8), L("P_Distortion_3D", 0.7, 0.8) }, Path = { L("P_Smoke_05", 0.4, 1.2) }, Vanish = 0.3 },
    Aura = { Layers = { L("P_FXVariety_DarkStorm", 0.5, 1, { Bone = "pelvis" }), L("P_Distortion_02", 0.6, 1, { Bone = "pelvis", Priority = "detail" }) } },
    Zone = { Core = { L("P_FXVariety_DarkStorm", 2.4, 3), L("P_Smoke_07", 1.8, 3), L("P_Distortion_3D", 1.5, 3) },
             Orbit = "nanos-world::P_Smoke_05", OrbitScale = 0.6, Ambient = { L("P_Distortion_02", 0.6, 1.0) }, Spin = 6, RiseSpeed = 0.5 },
    Sounds = {
        Slash = { S("A_Whoosh", 0.8, 0.6), S("A_WhiteNoise", 0.12, 0.5, 0.5) },
        Impact = { S("A_Body_Impact_Cue", 0.8, 0.7), S("A_Explosion_Small", 0.3, 0.6) },
        Big = { S("A_Explosion_Large", 0.6, 0.6) },
        Projectile = { S("A_Thruster_04", 0.3, 0.6, 1.0) },
        Dash = { S("A_Whoosh", 1.0, 0.5) },
        Loop = { S("A_WhiteNoise", 0.3, 0.4, 3), S("A_Thruster_04", 0.25, 0.4, 3) },
    },
})

-- ===========================================================================
-- SANG
-- ===========================================================================
VFX.RegisterElement("blood", {
    Colors = { Core = { 0.85, 0.02, 0.05 }, Accent = { 1.0, 0.2, 0.15 }, Highlight = { 1.0, 0.75, 0.7 }, Glow = 5 },
    Trail = { Width = 28, Life = 0.45, CoreWidth = 7, SlashWidth = 50, SlashLife = 0.45, DashWidth = 70 },
    Slash = { Body = { L("P_Blood_Impact", 0.9, 1.0) }, Tip = { L("P_Blood_Impact", 0.7, 1.0) }, Sparks = 45 },
    Impact = { Core = { L("P_Blood_Impact", 1.4, 1.2), L("P_FXVariety_MagicCircle", 0.6, 1.0) },
               Ring = "nanos-world::P_ShockWave_05",
               Dust = { L("P_Blood_Impact", 1.6, 1.4) },
               Secondary = { L("P_FXVariety_MagicCircle", 1.0, 1.5) },
               Linger = { L("P_Smoke_05", 0.6, 2.0) } },
    Projectile = { Core = { L("P_Blood_Impact", 0.8, 1) }, TrailWidth = 26, Trail = { L("P_Blood_Impact", 0.4, 0.6) } },
    Dash = { Start = { L("P_Blood_Impact", 1.0, 1.0) }, Path = { L("P_Blood_Impact", 0.5, 0.6) } },
    Aura = { Layers = { L("P_FXVariety_MagicCircle", 0.6, 1, { Bone = "pelvis" }) } },
    Zone = { Core = { L("P_FXVariety_MagicCircle", 2.2, 3) }, Orbit = "nanos-world::P_Blood_Impact", OrbitScale = 0.6,
             Ambient = { L("P_Blood_Impact", 0.6, 0.8) }, Spin = 5, RiseSpeed = 0.4 },
    Sounds = {
        Slash = { S("A_Whoosh", 0.9, 0.8), S("A_Flesh_Impact_MS", 0.25, 1.5) },
        Impact = { S("A_Flesh_Impact_MS", 1.0, 0.8), S("A_Body_Impact_Cue", 0.5, 0.8) },
        Big = { S("A_Explosion_Small", 0.7, 0.7) },
        Projectile = { S("A_Whoosh", 0.7, 0.9) },
        Dash = { S("A_Whoosh", 1.0, 0.7) },
        Loop = { S("A_WhiteNoise", 0.2, 0.5, 3) },
    },
})

-- ===========================================================================
-- FLEURS (art démoniaque) / FLEUR (souffle)
-- ===========================================================================
VFX.RegisterElement("flower", {
    Colors = { Core = { 1.0, 0.35, 0.65 }, Accent = { 1.0, 0.65, 0.85 }, Highlight = { 1.0, 0.95, 0.98 }, Glow = 4 },
    Trail = { Width = 24, Life = 0.55, CoreWidth = 6, SlashWidth = 44, SlashLife = 0.55, DashWidth = 60,
              Layers = { L("P_HangingParticulates", 0.3, 1, { Priority = "detail", Params = { Color = Color(4, 1.4, 2.6, 1), BoxSize = Vector(60, 60, 60), SpawnRate = 40 } }) } },
    Slash = { Body = { L("P_Burst_01", 0.6, 1.0) }, Tip = { L("P_FlareShimmer_01", 0.6, 1.0) }, Sparks = 40 },
    Impact = { Core = { L("P_Burst_02", 1.0, 1.2), L("P_FlareShimmer_01", 0.8, 1.2) },
               Ring = "nanos-world::P_ShockWave_03",
               Dust = { L("P_FXVariety_HealAura", 0.8, 1.6) },
               Secondary = { L("P_HangingParticulates", 1.0, 2.5, { Params = { Color = Color(4, 1.4, 2.6, 1), BoxSize = Vector(280, 280, 220), SpawnRate = 90 } }) },
               Linger = { L("P_FlareShimmer_02", 0.8, 2.0) } },
    Projectile = { Core = { L("P_Burst_01", 0.5, 1), L("P_FlareShimmer_02", 0.5, 1) }, TrailWidth = 22, Trail = { L("P_FlareShimmer_01", 0.3, 0.8) } },
    Dash = { Start = { L("P_Burst_02", 0.7, 1.0) }, Path = { L("P_FlareShimmer_02", 0.3, 0.8) } },
    Aura = { Layers = { L("P_FXVariety_HealAura", 0.6, 1, { Bone = "pelvis" }) } },
    Zone = { Core = { L("P_FXVariety_HealAura", 2.0, 3), L("P_HangingParticulates", 1.8, 3, { Params = { Color = Color(4, 1.4, 2.6, 1), BoxSize = Vector(600, 600, 300), SpawnRate = 140 } }) },
             Orbit = "nanos-world::P_FlareShimmer_01", OrbitScale = 0.6, Ambient = { L("P_Burst_01", 0.4, 0.9) }, Spin = 3.5, RiseSpeed = 0.35 },
    Sounds = {
        Slash = { S("A_Whoosh", 0.8, 1.3) },
        Impact = { S("A_Flesh_Impact_MS", 0.7, 1.2), S("A_Balloon_Pop", 0.2, 0.6) },
        Big = { S("A_Explosion_Small", 0.5, 1.4) },
        Projectile = { S("A_Whoosh", 0.6, 1.5) },
        Loop = { S("A_WhiteNoise", 0.15, 1.6, 3) },
    },
})

-- ===========================================================================
-- SON / INSECTE / AMOUR / SERPENT (souffles)
-- ===========================================================================
VFX.RegisterElement("sound", {
    Colors = { Core = { 1.0, 0.75, 0.15 }, Accent = { 1.0, 0.9, 0.4 }, Highlight = { 1.0, 1.0, 0.85 }, Glow = 6 },
    Trail = { Width = 26, Life = 0.3, SlashWidth = 46, DashWidth = 70, Layers = { L("P_SparksFlair", 0.4, 1, { Priority = "detail" }) } },
    Slash = { Body = { L("P_Explosive_05", 0.5, 0.9) }, Tip = { L("P_SparksFlair", 0.6, 1.0) }, Sparks = 45 },
    Impact = { Core = { L("P_Explosive_02", 0.9, 1.4) }, Ring = "nanos-world::P_ShockWave_05",
               Dust = { L("P_Smoke_02", 0.8, 2.0) }, Secondary = { L("P_SparksFlair", 1.0, 1.2) }, Linger = { L("P_Smoke_01", 0.7, 2.0) } },
    Projectile = { Core = { L("P_FXVariety_ThunderBall", 0.45, 1) }, TrailWidth = 18, Trail = { L("P_Sparks", 0.3, 0.5) } },
    Dash = { Start = { L("P_Explosive_03", 0.6, 1.0) }, Path = { L("P_Sparks", 0.3, 0.5) } },
    Aura = { Layers = { L("P_FlareShimmer_01", 0.6, 1, { Bone = "pelvis" }) } },
    Zone = { Core = { L("P_ShockWave_08", 1.6, 1.0) }, Orbit = "nanos-world::P_SparksFlair", Ambient = { L("P_Explosive_01", 0.4, 0.8) } },
    Sounds = { Slash = { S("A_Whoosh", 0.8, 1.0), S("A_MetalHeavy_Impact_MS", 0.3, 1.4) },
               Impact = { S("A_Explosion_Small", 0.8, 1.15) }, Big = { S("A_Explosion_Large", 0.6, 1.0) } },
})

VFX.RegisterElement("insect", {
    Colors = { Core = { 0.7, 0.3, 1.0 }, Accent = { 0.95, 0.6, 1.0 }, Highlight = { 1.0, 0.95, 1.0 }, Glow = 4 },
    Trail = { Width = 14, Life = 0.4, CoreWidth = 4, SlashWidth = 26, DashWidth = 50, Layers = { L("P_FlareShimmer_01", 0.3, 1, { Priority = "detail" }) } },
    Slash = { Body = { L("P_FlareShimmer_02", 0.5, 0.8) }, Tip = { L("P_FlareShimmer_01", 0.5, 0.9) }, Sparks = 25 },
    Impact = { Core = { L("P_FlareShimmer_01", 0.8, 1.0), L("P_FXVariety_Hit_02", 0.6, 0.6) }, Ring = "nanos-world::P_ShockWave_01",
               Dust = { L("P_Smoke_03", 0.6, 1.6) }, Secondary = { L("P_FXVariety_HealAura", 0.6, 1.2) }, Linger = { L("P_FlareShimmer_02", 0.6, 1.6) } },
    Projectile = { Core = { L("P_FlareShimmer_02", 0.5, 1) }, TrailWidth = 14 },
    Dash = { Start = { L("P_FlareShimmer_02", 0.8, 1.0) }, Path = { L("P_FlareShimmer_01", 0.4, 0.8) } },
    Aura = { Layers = { L("P_FlareShimmer_01", 0.6, 1, { Bone = "pelvis" }) } },
    Zone = { Core = { L("P_Smoke_06", 2.0, 3), L("P_FXVariety_HealAura", 1.8, 3) }, Orbit = "nanos-world::P_FlareShimmer_01",
             Ambient = { L("P_FlareShimmer_02", 0.6, 1.0) }, Spin = 2.5, RiseSpeed = 0.25 },
    Sounds = { Slash = { S("A_Whoosh", 0.6, 1.8) }, Impact = { S("A_Flesh_Impact_MS", 0.7, 1.3) }, Loop = { S("A_WhiteNoise", 0.15, 1.8, 3) } },
})

VFX.RegisterElement("love", {
    Colors = { Core = { 1.0, 0.3, 0.6 }, Accent = { 1.0, 0.6, 0.8 }, Highlight = { 1.0, 0.92, 0.96 }, Glow = 5 },
    Trail = { Width = 22, Life = 0.6, CoreWidth = 6, SlashWidth = 40, SlashLife = 0.6, DashWidth = 60 },
    Slash = { Body = { L("P_Burst_01", 0.6, 0.9) }, Tip = { L("P_FlareShimmer_01", 0.6, 0.9) }, Sparks = 35 },
    Impact = { Core = { L("P_Burst_02", 0.9, 1.0), L("P_FlareShimmer_01", 0.7, 1.0) }, Ring = "nanos-world::P_ShockWave_07",
               Dust = { L("P_FlareShimmer_02", 0.8, 1.4) }, Linger = { L("P_FlareShimmer_02", 0.7, 1.6) } },
    Projectile = { Core = { L("P_FlareShimmer_01", 0.7, 1) }, TrailWidth = 22 },
    Dash = { Start = { L("P_Burst_01", 0.7, 0.9) }, Path = { L("P_FlareShimmer_02", 0.4, 0.8) } },
    Aura = { Layers = { L("P_FlareShimmer_02", 0.8, 1, { Bone = "pelvis" }) } },
    Zone = { Core = { L("P_OmnidirectionalBurst", 1.2, 1.0) }, Orbit = "nanos-world::P_FlareShimmer_01", Ambient = { L("P_Burst_01", 0.4, 0.8) }, Spin = 7 },
    Sounds = { Slash = { S("A_Whoosh", 0.8, 1.45), S("A_Whoosh", 0.4, 1.9) }, Impact = { S("A_Flesh_Impact_MS", 0.8, 1.1), S("A_Punch_Cue", 0.5, 1.3) } },
})

VFX.RegisterElement("serpent", {
    Colors = { Core = { 0.55, 0.25, 0.85 }, Accent = { 0.85, 0.85, 1.0 }, Highlight = { 1.0, 1.0, 1.0 }, Glow = 3.5 },
    Trail = { Width = 20, Life = 0.6, CoreWidth = 5, SlashWidth = 38, SlashLife = 0.6, DashWidth = 60 },
    Slash = { Body = { L("P_Streamer", 0.8, 0.9) }, Tip = { L("P_DirectionalBurst", 0.5, 0.7) }, Sparks = 30 },
    Impact = { Core = { L("P_FXVariety_Hit_01", 0.9, 0.8), L("P_Smoke_06", 0.6, 1.4) }, Ring = "nanos-world::P_ShockWave_03",
               Dust = { L("P_Smoke_06", 0.8, 2.0) }, Linger = { L("P_Smoke_05", 0.7, 2.0) } },
    Projectile = { Core = { L("P_Streamer", 0.8, 1) }, TrailWidth = 20 },
    Dash = { Start = { L("P_Smoke_06", 0.7, 1.4) }, Path = { L("P_Smoke_03", 0.4, 1.0) } },
    Aura = { Layers = { L("P_Streamer", 0.6, 1, { Bone = "pelvis" }) } },
    Zone = { Core = { L("P_FXVariety_DarkStorm", 1.6, 3) }, Orbit = "nanos-world::P_Streamer", Ambient = { L("P_Smoke_03", 0.5, 1.2) }, Spin = 5 },
    Sounds = { Slash = { S("A_Whoosh", 0.8, 1.1), S("A_WhiteNoise", 0.1, 2.2, 0.4) }, Impact = { S("A_Flesh_Impact_MS", 0.8, 1.0) },
               Big = { S("A_Explosion_Small", 0.5, 0.8) }, Loop = { S("A_WhiteNoise", 0.2, 2.0, 3) } },
})

-- ===========================================================================
-- Repli + association souffle / art -> élément
-- ===========================================================================
VFX.RegisterElement("neutral", {
    Colors = { Core = { 0.85, 0.85, 0.9 }, Accent = { 1, 1, 1 }, Highlight = { 1, 1, 1 }, Glow = 2 },
    Trail = { Width = 20, Life = 0.3 },
    Impact = { Core = { L("P_FXVariety_Hit_01", 0.8, 0.8) }, Ring = "nanos-world::P_ShockWave_01" },
    Sounds = { Slash = { S("A_Whoosh", 0.8, 1.0) }, Impact = { S("A_Flesh_Impact_MS", 0.8, 1.0) } },
})

local ALIASES = {
    -- Souffles
    eau = "water", flamme = "flame", soleil = "sun", tonnerre = "thunder", vent = "wind", brume = "mist",
    pierre = "stone", bete = "beast", son = "sound", insecte = "insect", amour = "love", serpent = "serpent",
    fleur = "flower",
    -- Arts démoniaques
    sang = "blood", glace = "ice", ombre = "shadow", fleurs = "flower",
    temari = "blood", fils = "blood", biwa = "shadow", reve = "shadow",
}
for setId, elementId in pairs(ALIASES) do
    VFX.RegisterElement(setId, VFX.Element(elementId))
end
