#!/usr/bin/env python3
"""
Demon Slayer VFX Pack - CATALOGUE (source unique de vérité)
===========================================================
Décrit TOUT le pack : éléments, matériaux maîtres, Material Instances,
textures, maillages, archétypes Niagara et chaque Niagara System.

`python vfx_catalog.py` génère :
  ../Docs/VFX_CATALOG.md            fiche de chaque VFX (nom, type, utilisation,
                                    paramètres, durée, performance, asset, dépendances)
  ../Docs/NIAGARA_RECIPES.md        recettes Niagara (émetteurs + modules) par archétype
  ../Unreal/catalog.json            données lues par ue_setup_pack.py (MI, scène de test)
  ../AssetPack/Assets.toml          configuration de l'Asset Pack nanos world
  ../../Packages/demon-slayer-rp/Shared/Config/VfxPackCatalog.lua
                                    table utilisée par le gamemode (rôle -> NS_)
"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
PACK_ID = "demonslayer-vfx"          # nom du dossier de l'Asset Pack dans Server/Assets/
UE_ROOT = "DemonSlayerVFX"           # dossier racine dans Content/ du projet ADK
UNREAL_VERSION = "5.7.0"

# ===========================================================================
# Paramètres utilisateur standard (identiques sur TOUS les systèmes)
# Niagara : "User.<Nom>" ; nanos world : Particle:SetParameterXxx("<Nom>", valeur)
# ===========================================================================
USER_PARAMS = [
    ("Color", "LinearColor", "Couleur principale (HDR : > 1 = brille)"),
    ("SecondaryColor", "LinearColor", "Couleur secondaire (cœur, écume, braises)"),
    ("Scale", "Float", "Taille globale (1 = normal)"),
    ("Intensity", "Float", "Luminosité / émissif (1 = normal)"),
    ("Duration", "Float", "Multiplicateur de durée (1 = normal)"),
    ("Speed", "Float", "Multiplicateur de vitesse (1 = normal)"),
    ("SpawnScale", "Float", "Multiplicateur du nombre de particules (LOD manuel, 0..1)"),
    ("Width", "Float", "Largeur des traînées / rubans (cm)"),
    ("Direction", "Vector", "Direction de l'attaque (monde), défaut = avant de l'acteur"),
    ("EndPoint", "Vector", "Point d'arrivée (éclairs, élans, projectiles)"),
]

# ===========================================================================
# Éléments
# ===========================================================================
ELEMENTS = {
    "Water":   {"fr": "Eau",      "color": (0.10, 0.55, 1.00), "color2": (0.80, 0.97, 1.00), "trail": "T_VFX_Trail_Water",     "spark": "T_VFX_Mask_Droplet", "flip": "T_VFX_Flip_Splash_4x4", "flipGrid": 4},
    "Fire":    {"fr": "Flamme",   "color": (1.00, 0.32, 0.04), "color2": (1.00, 0.85, 0.35), "trail": "T_VFX_Trail_Fire",      "spark": "T_VFX_Mask_Spark",   "flip": "T_VFX_Flip_Fire_8x8",   "flipGrid": 8},
    "Thunder": {"fr": "Foudre",   "color": (1.00, 0.82, 0.12), "color2": (1.00, 1.00, 0.85), "trail": "T_VFX_Trail_Lightning_1x4", "spark": "T_VFX_Mask_Spark", "flip": "T_VFX_Flip_Lightning_4x4", "flipGrid": 4},
    "Wind":    {"fr": "Vent",     "color": (0.45, 1.00, 0.65), "color2": (0.92, 1.00, 0.95), "trail": "T_VFX_Trail_Wind",      "spark": "T_VFX_Mask_Leaf",    "flip": "T_VFX_Flip_Smoke_8x8",  "flipGrid": 8},
    "Mist":    {"fr": "Brume",    "color": (0.75, 0.82, 0.95), "color2": (1.00, 1.00, 1.00), "trail": "T_VFX_Trail_Mist",      "spark": "T_VFX_Mask_SoftCircle", "flip": "T_VFX_Flip_Mist_4x4", "flipGrid": 4},
    "Blood":   {"fr": "Sang",     "color": (1.00, 0.04, 0.10), "color2": (1.00, 0.55, 0.55), "trail": "T_VFX_Trail_Energy",    "spark": "T_VFX_Mask_Droplet", "flip": "T_VFX_Flip_Explosion_8x8", "flipGrid": 8},
    "Ice":     {"fr": "Glace",    "color": (0.45, 0.85, 1.00), "color2": (0.92, 1.00, 1.00), "trail": "T_VFX_Trail_Energy",    "spark": "T_VFX_Mask_Shard",   "flip": "T_VFX_Flip_Mist_4x4",   "flipGrid": 4},
    "Shadow":  {"fr": "Ombre",    "color": (0.45, 0.10, 0.90), "color2": (0.90, 0.60, 1.00), "trail": "T_VFX_Trail_Mist",      "spark": "T_VFX_Mask_SoftCircle", "flip": "T_VFX_Flip_Smoke_8x8", "flipGrid": 8},
    "Flower":  {"fr": "Fleurs",   "color": (1.00, 0.40, 0.70), "color2": (1.00, 0.92, 0.96), "trail": "T_VFX_Trail_Energy",    "spark": "T_VFX_Mask_Petal",   "flip": "T_VFX_Flip_Mist_4x4",   "flipGrid": 4},
    "Core":    {"fr": "Générique", "color": (1.00, 1.00, 1.00), "color2": (1.00, 1.00, 1.00), "trail": "T_VFX_Trail_Energy",   "spark": "T_VFX_Mask_Spark",   "flip": "T_VFX_Flip_Explosion_8x8", "flipGrid": 8},
}
EMISSIVE = {"Water": 6, "Fire": 10, "Thunder": 16, "Wind": 4, "Mist": 2, "Blood": 8, "Ice": 6, "Shadow": 5, "Flower": 5, "Core": 8}

# Dossiers Unreal par élément
FOLDER = {"Water": "Water", "Fire": "Fire", "Thunder": "Thunder", "Wind": "Wind", "Mist": "Mist",
          "Blood": "BloodArts", "Ice": "BloodArts", "Shadow": "BloodArts", "Flower": "BloodArts", "Core": "Core"}
MAT_FOLDER = {"Water": "Water", "Fire": "Fire", "Thunder": "Thunder", "Wind": "Energy", "Mist": "Mist",
              "Blood": "Blood", "Ice": "Energy", "Shadow": "Energy", "Flower": "Energy", "Core": "Core"}

# ===========================================================================
# Matériaux maîtres (construits par ue_setup_pack.py)
# ===========================================================================
MASTER_MATERIALS = {
    "M_VFX_Sprite_Additive": "Sprites lumineux (flash, étincelles, gouttes, braises). Additif, unlit. Texture x Color x Emissive x couleur de particule ; érosion par Dynamic Parameter (Param1) ; Depth Fade.",
    "M_VFX_Sprite_Translucent": "Fumée, brume, poussière. Translucide, unlit. Alpha = masque x bruit panné ; érosion (Param1) ; Depth Fade large.",
    "M_VFX_Sprite_Flipbook": "Flipbooks sub-UV (flammes, éclaboussures, éclairs, explosion). Additif, ParticleSubUV avec fondu entre images.",
    "M_VFX_Mesh_Slash": "Coupes / anneaux / ondes sur maillage. Additif, deux faces. Masque de traînée parcouru en U (Param1 = balayage), bruit panné, fresnel de bord, érosion (Param2).",
    "M_VFX_Ribbon": "Rubans (traînées de lame, spirales). Additif. Texture tuilable pannée en U, fondu de queue (U), érosion selon l'alpha de particule.",
    "M_VFX_Mesh_Energy": "Volumes d'énergie / d'eau (vague, dragon, boule, vortex). Translucide unlit, fresnel, caustiques pannées, Depth Fade, érosion (Param1).",
    "M_VFX_Distortion": "Distorsion de chaleur / onde de choc. Translucide, Refraction depuis une normale pannée, intensité x alpha de particule.",
}

# Material Instances : (nom, parent, paramètres)
def material_instances():
    out = []
    for e, d in ELEMENTS.items():
        c, c2, em = d["color"], d["color2"], EMISSIVE[e]
        mf = MAT_FOLDER[e]
        out += [
            {"name": f"MI_VFX_{e}_Slash", "parent": "M_VFX_Mesh_Slash", "folder": mf,
             "vectors": {"Color": c, "SecondaryColor": c2}, "scalars": {"Emissive": em, "PanSpeed": 1.5, "FresnelPower": 3},
             "textures": {"Mask": "T_VFX_Mask_SlashTrail", "Noise": d["trail"] if e != "Thunder" else "T_VFX_Noise_Streaks"}},
            {"name": f"MI_VFX_{e}_Trail", "parent": "M_VFX_Ribbon", "folder": mf,
             "vectors": {"Color": c, "SecondaryColor": c2}, "scalars": {"Emissive": em, "PanSpeed": 2.0, "Tiling": 2},
             "textures": {"Trail": d["trail"], "Noise": "T_VFX_Noise_Streaks"}},
            {"name": f"MI_VFX_{e}_Glow", "parent": "M_VFX_Sprite_Additive", "folder": mf,
             "vectors": {"Color": c}, "scalars": {"Emissive": em}, "textures": {"Mask": "T_VFX_Mask_SoftCircle"}},
            {"name": f"MI_VFX_{e}_Spark", "parent": "M_VFX_Sprite_Additive", "folder": mf,
             "vectors": {"Color": c2}, "scalars": {"Emissive": em * 1.5}, "textures": {"Mask": d["spark"]}},
            {"name": f"MI_VFX_{e}_Flipbook", "parent": "M_VFX_Sprite_Flipbook", "folder": mf,
             "vectors": {"Color": c, "SecondaryColor": c2}, "scalars": {"Emissive": em}, "textures": {"Flipbook": d["flip"]}},
            {"name": f"MI_VFX_{e}_Smoke", "parent": "M_VFX_Sprite_Translucent", "folder": mf,
             "vectors": {"Color": tuple(min(1, x * 0.5 + 0.35) for x in c)}, "scalars": {"Opacity": 0.6}, "textures": {"Mask": "T_VFX_Flip_Smoke_8x8" if e != "Mist" else "T_VFX_Flip_Mist_4x4", "Noise": "T_VFX_Noise_Cloud"}},
            {"name": f"MI_VFX_{e}_Mesh", "parent": "M_VFX_Mesh_Energy", "folder": mf,
             "vectors": {"Color": c, "SecondaryColor": c2}, "scalars": {"Emissive": em * 0.6, "Opacity": 0.85, "FresnelPower": 2.5},
             "textures": {"Noise": "T_VFX_Noise_Caustics" if e in ("Water", "Ice") else "T_VFX_Noise_Perlin"}},
            {"name": f"MI_VFX_{e}_Ring", "parent": "M_VFX_Sprite_Additive", "folder": mf,
             "vectors": {"Color": c}, "scalars": {"Emissive": em}, "textures": {"Mask": "T_VFX_Mask_Shockwave"}},
        ]
    out += [
        {"name": "MI_VFX_Core_Distortion", "parent": "M_VFX_Distortion", "folder": "Core", "vectors": {}, "scalars": {"Strength": 0.08, "PanSpeed": 0.3}, "textures": {"Normal": "T_VFX_Distortion_Noise_N"}},
        {"name": "MI_VFX_Core_DistortionRing", "parent": "M_VFX_Distortion", "folder": "Core", "vectors": {}, "scalars": {"Strength": 0.15, "PanSpeed": 0.0}, "textures": {"Normal": "T_VFX_Distortion_Ring_N"}},
        {"name": "MI_VFX_Core_Flash", "parent": "M_VFX_Sprite_Additive", "folder": "Core", "vectors": {"Color": (1, 1, 1)}, "scalars": {"Emissive": 20}, "textures": {"Mask": "T_VFX_Mask_Star"}},
        {"name": "MI_VFX_Core_Sigil", "parent": "M_VFX_Sprite_Additive", "folder": "Core", "vectors": {"Color": (1, 1, 1)}, "scalars": {"Emissive": 8}, "textures": {"Mask": "T_VFX_Mask_Sigil"}},
        {"name": "MI_VFX_Core_Dust", "parent": "M_VFX_Sprite_Translucent", "folder": "Core", "vectors": {"Color": (0.45, 0.4, 0.35)}, "scalars": {"Opacity": 0.5}, "textures": {"Mask": "T_VFX_Flip_Smoke_8x8", "Noise": "T_VFX_Noise_Cloud"}},
    ]
    return out


# ===========================================================================
# Archétypes Niagara (recettes complètes, voir NIAGARA_RECIPES.md)
# ===========================================================================
ARCHETYPES = {
    "Slash": {
        "desc": "Coupe de lame : arc maillé balayé + ruban + flash + gerbe + distorsion + dissipation.",
        "duration": "0,45 à 0,8 s", "budget": "≈ 60 particules (CPU), 1 maillage",
        "emitters": [
            ("E_Anticipation", "Sprite CPU, Burst 12 à t=0", "Spawn Burst Instantaneous(12) ; Sphere Location r=40 ; Velocity vers le centre (Point Attraction 600) ; Lifetime 0,12 ; Size 6→0 ; MI_<E>_Spark. Accumulation d'énergie avant le coup."),
            ("E_SlashMesh", "Mesh CPU (SM_VFX_Slash_Arc_*), 1 particule à t=0,08", "Spawn Burst(1, Spawn Time 0.08) ; Mesh Renderer : maillage choisi, orientation = acteur (Mesh Orientation : Local Space) ; Scale Mesh Size 0.85→1.15 (courbe ease-out) x User.Scale ; Dynamic Material Parameters : Param1 (balayage) 0→1 en 0,12 s, Param2 (érosion) 0→1 de 0,25 s à la fin ; Lifetime 0,45 x User.Duration ; Material MI_<E>_Slash."),
            ("E_SlashCore", "Mesh CPU, copie plus fine", "Identique à E_SlashMesh, Scale 0.9, Color = User.SecondaryColor x 2 : fil blanc lumineux au cœur de la coupe."),
            ("E_Ribbon", "Ribbon CPU", "Spawn Rate 120 pendant 0,15 s ; position = arc paramétrique (Custom : Cylinder Location angle = Normalized Age x 150°, rayon 170) ; Ribbon Width = User.Width ; Lifetime 0,25 ; Ribbon Renderer UV0 Mode = Normalized Age ; MI_<E>_Trail."),
            ("E_Particles", "Sprite CPU, Burst 30 à t=0,1", "Location : Shape = Torus/arc (rayon 180) ; Add Velocity tangente (Velocity Cone 25°, 400..900) ; Drag 2 ; Gravity -400 (eau/sang) ; Size 4..10, Scale Size by Speed ; Lifetime 0,4..0,7 ; MI_<E>_Spark (gouttelettes / braises / étincelles)."),
            ("E_Flash", "Sprite CPU, Burst 1 à t=0,1", "Size 260→40 (0,1 s) ; Color = User.Color x 4 ; MI_VFX_Core_Flash ; Facing Camera."),
            ("E_Distortion", "Sprite CPU, Burst 1", "Size 300→420 ; Lifetime 0,3 ; MI_VFX_Core_Distortion ; Opacity courbe 1→0."),
            ("E_Dissipation", "Sprite CPU, Burst 8 à t=0,3", "Location sur l'arc ; Velocity +Z 40..120 ; Size 30→60 ; Lifetime 0,6 ; MI_<E>_Smoke (brume / fumée / poussière d'énergie)."),
        ],
    },
    "Trail": {
        "desc": "Traînée continue attachée à la lame (socket hand_r) ou à un projectile.",
        "duration": "boucle tant que l'acteur existe (désactiver = fin)", "budget": "1 ruban (≈ 40 segments) + 20 sprites/s",
        "emitters": [
            ("E_Ribbon", "Ribbon CPU, Spawn Rate 60", "Spawn Rate 60 x User.SpawnScale ; Ribbon Width User.Width (défaut 28) avec courbe d'âge 1→0 ; Lifetime 0,3 x User.Duration ; MI_<E>_Trail ; Ribbon Link Order = Normalized Age."),
            ("E_RibbonCore", "Ribbon CPU", "Comme E_Ribbon, Width x 0,3, Color = SecondaryColor x 3."),
            ("E_Bits", "Sprite CPU, Spawn Rate 25", "Inherit Velocity 0,3 ; Curl Noise Force 300 ; Lifetime 0,4 ; Size 3..7 ; MI_<E>_Spark."),
        ],
    },
    "Impact": {
        "desc": "Impact à 4 tailles : flash + onde de choc + particules + élément + poussière + distorsion + éclats.",
        "duration": "0,5 (Small) → 1,6 s (Massive)", "budget": "Small ≈ 25, Medium ≈ 50, Large ≈ 90, Massive ≈ 150 particules",
        "emitters": [
            ("E_Flash", "Sprite, Burst 1", "Size 120 x Scale→0 en 0,08 s ; MI_VFX_Core_Flash ; Color = User.Color x 6."),
            ("E_Shockwave", "Sprite (Facing : Custom Facing Vector +Z), Burst 1", "Size 40→420 x Scale (ease-out 0,25 s) ; Opacity 1→0 ; MI_<E>_Ring. Medium et plus : 2e onde à t=0,06."),
            ("E_Burst", "Sprite, Burst 20..80", "Sphere Location r=10 ; Add Velocity In Cone (hémisphère haut) 500..1400 ; Drag 3 ; Gravity -900 ; Size by Speed ; MI_<E>_Spark."),
            ("E_Element", "Sprite flipbook, Burst 1..3", "SubUV (4x4 ou 8x8) lu en 0,5 s ; Size 220 x Scale ; MI_<E>_Flipbook (éclaboussure, flamme, éclair...)."),
            ("E_Dust", "Sprite, Burst 6..20 (Large+)", "Ring Location au sol r=80 ; Velocity radiale 200 ; Size 80→220 ; Lifetime 1,2 ; MI_VFX_Core_Dust ou MI_<E>_Smoke."),
            ("E_Debris", "Mesh ou Sprite, Burst 6..16 (Large+)", "Éclats (SM_VFX_Spike_Ice / Rock / Petal) ; Velocity In Cone 600..1200 ; Gravity -980 ; Rotation aléatoire."),
            ("E_Distortion", "Sprite, Burst 1 (Medium+)", "MI_VFX_Core_DistortionRing, Size 100→500."),
        ],
    },
    "Projectile": {
        "desc": "Projectile = cœur + aura + traînée + gouttes ; l'impact est un système séparé (NS_VFX_<E>_Impact ou _Explosion).",
        "duration": "boucle (le script déplace/détruit le projectile)", "budget": "1 maillage + 1 ruban + ≈ 40 sprites/s",
        "emitters": [
            ("E_Core", "Mesh (SM_VFX_Sphere)", "1 particule persistante ; Scale 0,6 x Scale ; Mesh Rotation Rate aléatoire ; MI_<E>_Mesh."),
            ("E_Aura", "Sprite, Spawn Rate 30", "Sphere Location r=30 ; Vortex Velocity 300 autour de l'axe avant ; Size 20..40 ; Lifetime 0,3 ; MI_<E>_Glow."),
            ("E_Trail", "Ribbon, Spawn Rate 80", "Local Space OFF (reste dans le monde) ; Width 40 x Scale ; Lifetime 0,35 ; MI_<E>_Trail."),
            ("E_Drops", "Sprite, Spawn Rate 40", "Inherit Velocity -0,2 ; Gravity -600 ; Size 4..8 ; Lifetime 0,5 ; MI_<E>_Spark."),
        ],
    },
    "Dash": {
        "desc": "Élan : départ (flash + gerbe), rémanence sur le trajet, lignes de vitesse, arrivée.",
        "duration": "0,6 s", "budget": "≈ 70 particules + 2 rubans",
        "emitters": [
            ("E_StartFlash", "Sprite, Burst 1", "MI_VFX_Core_Flash, Size 300→0 en 0,1 s."),
            ("E_Afterimage", "Ribbon, Spawn Rate 200 pendant 0,15 s", "Position interpolée de l'origine à User.EndPoint (Normalized Age) ; Width 90 ; Lifetime 0,35 ; MI_<E>_Trail."),
            ("E_SpeedLines", "Sprite (Facing Velocity), Burst 25", "Box Location le long du trajet ; Velocity = Direction x 3000 ; Sprite Size (4, 120) ; Lifetime 0,15 ; MI_<E>_Spark."),
            ("E_Element", "Sprite/Beam selon l'élément", "Foudre : Beam (Beam Emitter Setup, Start = origine, End = User.EndPoint, Jitter) x 3 ; Brume : MI_Mist_Smoke qui recouvre le personnage ; Eau : flipbook éclaboussures."),
            ("E_Arrival", "Sprite, Burst 20 à t=0,15", "Gerbe à User.EndPoint + MI_<E>_Ring au sol."),
        ],
    },
    "Wave": {
        "desc": "Vague / tsunami : mur maillé qui AVANCE + mousse + gouttelettes + éclaboussures + brume + vaguelettes.",
        "duration": "1,6 s (vague) / 3 s (tsunami)", "budget": "3..6 maillages + ≈ 120 sprites (GPU pour la mousse)",
        "emitters": [
            ("E_WaveMesh", "Mesh (SM_VFX_Wave_Curl), Burst 1..3", "Velocity = Direction x 900 x Speed (Solve Forces and Velocity) ; Scale Mesh Size 0,4→1,2 (montée) ; Dynamic Param1 (érosion) 0→1 sur les 25 % finaux ; MI_Water_Mesh."),
            ("E_WaveShell", "Mesh, copie 1,05", "MI_Water_Slash (bord lumineux) ; légère avance (+20 cm)."),
            ("E_Foam", "Sprite GPU, Spawn Rate 400 x SpawnScale", "Spawn sur la crête (Static Mesh Location : SM_VFX_Wave_Curl, filtre V > 0,8) ; Inherit velocity ; Curl Noise 200 ; Size 8..20 ; MI_Water_Spark."),
            ("E_Droplets", "Sprite GPU, Spawn Rate 300", "Velocity cône vers l'avant/haut 300..900 ; Gravity -980 ; Collision (GPU Depth Buffer) optionnelle ; MI_Water_Spark."),
            ("E_Splash", "Sprite flipbook, Spawn Rate 12", "Sur le pied de la vague ; MI_Water_Flipbook ; Size 250."),
            ("E_Mist", "Sprite, Spawn Rate 10", "Derrière la vague ; Size 300→600 ; Lifetime 1,5 ; MI_Mist_Smoke teinté bleu."),
            ("E_SmallWaves", "Mesh (SM_VFX_Ring_Flat), Spawn Rate 6", "Au sol ; Scale 0,3→1,5 ; MI_Water_Ring : vaguelettes secondaires."),
            ("E_Crash", "Event Handler (Death de E_WaveMesh)", "Déclenche une explosion d'eau (gerbe + flipbook + onde) à l'emplacement final."),
        ],
    },
    "Vortex": {
        "desc": "Tornade / tourbillon : cylindres torsadés en rotation + rubans en spirale + gouttes + distorsion.",
        "duration": "2,5 s (boucle si attaché)", "budget": "2 maillages + 6 rubans + ≈ 120 sprites",
        "emitters": [
            ("E_Funnel", "Mesh (SM_VFX_Vortex_Cone), 1", "Mesh Rotation Rate Z 540°/s x Speed ; Scale 0,3→1 en 0,3 s ; Param1 érosion fin ; MI_<E>_Slash (U = tour)."),
            ("E_FunnelInner", "Mesh (SM_VFX_Vortex_Cylinder), 1", "Rotation inverse -720°/s ; MI_<E>_Mesh."),
            ("E_Spirals", "Ribbon x 6 (Spawn Per Unit)", "Vortex Velocity 800 autour de Z + Point Attraction ; montée +Z 300 ; MI_<E>_Trail."),
            ("E_Particles", "Sprite GPU, Spawn Rate 250", "Cylinder Location ; Vortex Velocity 600 ; Velocity +Z 200..500 ; MI_<E>_Spark (gouttes, feuilles, poussière)."),
            ("E_Ground", "Sprite (Facing +Z), Spawn Rate 4", "MI_<E>_Ring au sol, Size 200→700."),
            ("E_Distortion", "Sprite, Spawn Rate 3", "MI_VFX_Core_Distortion le long de l'axe."),
        ],
    },
    "Beast": {
        "desc": "Créature (dragon / tigre / serpent) : tête maillée + segments + rubans + brume, trajectoire sinueuse.",
        "duration": "1,6 à 2,2 s", "budget": "1 tête + 10..14 segments + 3 rubans + ≈ 150 sprites",
        "emitters": [
            ("E_Head", "Mesh (SM_VFX_Dragon_Head), 1", "Velocity = Direction x 1400 x Speed ; ondulation : Sine sur Y/Z (Custom module ou Curl Noise Force faible) ; Orient Mesh To Velocity ; MI_<E>_Mesh."),
            ("E_Body", "Mesh (SM_VFX_Dragon_Segment), Spawn Rate 18", "Spawn depuis la position de la tête (Particle Attribute Reader : E_Head.Position) ; Lifetime 0,7 ; Scale 1→0,5 ; Orient To Velocity ; MI_<E>_Slash + MI_<E>_Mesh."),
            ("E_Spine", "Ribbon, suit la tête", "Width 160→20 (Ribbon Width par âge) ; MI_<E>_Trail."),
            ("E_Whiskers", "Ribbon x 2, décalés", "Width 12 ; MI_<E>_Trail (SecondaryColor)."),
            ("E_Mist", "Sprite, Spawn Rate 40", "Le long du corps ; MI_<E>_Smoke."),
            ("E_Drops", "Sprite GPU, Spawn Rate 300", "Location = tête ; Gravity -980 ; MI_<E>_Spark."),
        ],
    },
    "Burst": {
        "desc": "Explosion / jaillissement élémentaire (sans projectile).",
        "duration": "1 à 1,8 s", "budget": "≈ 120 particules + 1..2 maillages",
        "emitters": [
            ("E_Charge", "Sprite, Burst 20 à t=0", "Point Attraction vers le centre en 0,15 s : anticipation."),
            ("E_Core", "Sprite flipbook, Burst 2 à t=0,15", "MI_<E>_Flipbook, Size 300→500."),
            ("E_Shell", "Mesh (SM_VFX_Sphere), 1", "Scale 0,2→2,5 en 0,3 s ; Param1 érosion ; MI_<E>_Mesh."),
            ("E_Ring", "Mesh (SM_VFX_Ring_Flat), 1", "Scale 0,2→4 ; MI_<E>_Slash."),
            ("E_Sparks", "Sprite, Burst 60", "Sphere velocity 800..2000 ; Drag 2 ; MI_<E>_Spark."),
            ("E_Smoke", "Sprite, Burst 10", "MI_<E>_Smoke ; montée lente ; Lifetime 1,5."),
            ("E_Distortion", "Sprite, Burst 1", "MI_VFX_Core_DistortionRing."),
        ],
    },
    "Aura": {
        "desc": "Aura / zone persistante : sceau au sol, particules montantes, rubans d'orbite.",
        "duration": "boucle (détruite par le script)", "budget": "≈ 60 sprites/s + 2 rubans",
        "emitters": [
            ("E_Sigil", "Sprite (Facing +Z), 1 persistante", "MI_VFX_Core_Sigil teinté User.Color ; Sprite Rotation Rate 40°/s ; Size 400 x Scale."),
            ("E_Rise", "Sprite, Spawn Rate 40", "Cylinder Location r=80 ; Velocity +Z 150..300 ; MI_<E>_Spark."),
            ("E_Orbit", "Ribbon x 2", "Vortex Velocity 400 ; MI_<E>_Trail."),
            ("E_Glow", "Sprite, 1 persistante", "MI_<E>_Glow, Size 250, pulsation (Sine) 0,7..1."),
        ],
    },
    "Spikes": {
        "desc": "Pics qui jaillissent du sol en cercle ou en ligne (glace, sang durci).",
        "duration": "1,6 s", "budget": "8..14 maillages + ≈ 60 sprites",
        "emitters": [
            ("E_Spikes", "Mesh (SM_VFX_Spike_Ice), Burst 8..14", "Ring Location r=200 (ou Line vers l'avant) ; Scale Z 0→1 en 0,12 s (ease-out) puis 1→0 à la fin ; rotation aléatoire ±15° ; MI_<E>_Mesh."),
            ("E_Crack", "Sprite (Facing +Z), Burst 1", "MI_<E>_Ring, Size 600."),
            ("E_Shards", "Sprite, Burst 40", "Velocity cône haut 400..900 ; Gravity -980 ; MI_<E>_Spark."),
            ("E_Frost", "Sprite, Burst 8", "MI_<E>_Smoke au sol, Lifetime 1,5."),
        ],
    },
    "Bolt": {
        "desc": "Éclair entre deux points (Beam) avec branches, scintillement et impact.",
        "duration": "0,25 à 0,5 s", "budget": "3 beams + ≈ 30 sprites",
        "emitters": [
            ("E_Beam", "Ribbon (Beam Emitter Setup), 3 beams", "Beam Start = position système, Beam End = User.EndPoint ; Jitter Position 40 (régénéré toutes les 0,05 s) ; Width 20 ; MI_Thunder_Trail (sub-UV ligne aléatoire)."),
            ("E_Branches", "Ribbon (Beam), 4 beams courts", "Début aléatoire le long du beam principal ; Width 8."),
            ("E_Flicker", "Sprite, Spawn Rate 30", "MI_VFX_Core_Flash, taille aléatoire, Lifetime 0,05."),
            ("E_EndSpark", "Sprite, Burst 20", "À User.EndPoint ; MI_Thunder_Spark."),
        ],
    },
}

# ===========================================================================
# Systèmes (nom -> élément, archétype, utilisation, particularités)
# ===========================================================================
def S(name, element, archetype, usage, special="", mesh=None, duration=None, perf=None, params_extra=""):
    return {"name": name, "element": element, "archetype": archetype, "usage": usage, "special": special,
            "mesh": mesh, "duration": duration, "perf": perf, "params_extra": params_extra}


SYSTEMS = [
    # ------------------------------------------------------------------ Core
    S("NS_Core_Trail", "Core", "Trail", "Traînée neutre (teinte via User.Color) pour toute arme ou acteur."),
    S("NS_Core_RibbonTrail", "Core", "Trail", "Ruban large et doux (rémanence de mouvement du corps)."),
    S("NS_Core_EnergyTrail", "Core", "Trail", "Traînée d'énergie avec cœur blanc très lumineux."),
    S("NS_Core_ElementTrail", "Core", "Trail", "Traînée générique dont la texture de MI est remplacée par élément (base des _Trail)."),
    S("NS_Core_Flash", "Core", "Impact", "Flash seul (début d'attaque, contre).", "Uniquement E_Flash + E_Distortion."),
    S("NS_Core_Shockwave", "Core", "Impact", "Onde de choc au sol.", "Uniquement E_Shockwave (2 ondes) + E_Distortion."),
    S("NS_Core_Distortion", "Core", "Impact", "Distorsion seule (chaleur, onde).", "Uniquement E_Distortion."),
    S("NS_Core_SpeedLines", "Core", "Dash", "Lignes de vitesse seules (élan, sprint).", "Uniquement E_SpeedLines."),
    S("NS_Core_Sparks", "Core", "Impact", "Étincelles de lame (parade, choc de katanas).", "Uniquement E_Burst (Velocity Cone 45°)."),
    S("NS_Core_Debris", "Core", "Impact", "Débris et poussière au sol.", "E_Dust + E_Debris."),
    # ------------------------------------------------------------------ Impacts génériques
    S("NS_Impact_Small", "Core", "Impact", "Petit coup (combo, tick de zone).", "Flash + E_Burst(20) + E_Element.", duration="0,5 s", perf="≈ 25 particules"),
    S("NS_Impact_Medium", "Core", "Impact", "Coup normal.", "+ onde + distorsion.", duration="0,8 s", perf="≈ 50 particules"),
    S("NS_Impact_Large", "Core", "Impact", "Coup puissant / fin de combo.", "+ poussière + débris + 2e onde.", duration="1,2 s", perf="≈ 90 particules"),
    S("NS_Impact_Massive", "Core", "Impact", "Ultime / explosion finale.", "+ anneau de 6 gerbes + onde x3 + caméra.", duration="1,6 s", perf="≈ 150 particules"),
    # ------------------------------------------------------------------ Eau
    S("NS_VFX_Water_Slash", "Water", "Slash", "Toute coupe du Souffle de l'Eau (formes 1, 2, 4...).", "Gouttelettes avec gravité, écume (MI_Water_Spark), brume bleutée en dissipation.", mesh="SM_VFX_Slash_Arc_180"),
    S("NS_VFX_Water_Trail", "Water", "Trail", "Traînée d'eau attachée au katana (hand_r) pendant les techniques.", "E_Bits = gouttes qui tombent (Gravity -600)."),
    S("NS_VFX_Water_Wave", "Water", "Wave", "[Q] Grande vague.", "1 maillage, Speed 900.", mesh="SM_VFX_Wave_Curl", duration="1,6 s"),
    S("NS_VFX_Water_Tsunami", "Water", "Wave", "[X] Tsunami (ultime).", "3 maillages côte à côte, Scale 2,5, montée 0,6 s, Speed 600, explosion massive finale.", mesh="SM_VFX_Wave_Curl", duration="3 s", perf="≈ 250 particules (GPU)"),
    S("NS_VFX_Water_Tornado", "Water", "Vortex", "[E] Tourbillon.", "Rubans en spirale bleus + gouttes aspirées vers l'axe.", mesh="SM_VFX_Vortex_Cone"),
    S("NS_VFX_Water_Ball", "Water", "Projectile", "[R] Prison d'eau (sphère lancée).", "E_Core = bulle (Fresnel fort) ; impact : NS_VFX_Water_Explosion.", mesh="SM_VFX_Sphere"),
    S("NS_VFX_Water_Dragon", "Water", "Beast", "[C] Dragon changeant.", "Écailles = segments + MI_Water_Slash ; moustaches en rubans ; brume.", mesh="SM_VFX_Dragon_Head", duration="2,2 s"),
    S("NS_VFX_Water_Explosion", "Water", "Burst", "Éclatement de la prison, fin de tourbillon.", "Flipbook éclaboussures + sphère d'eau qui s'ouvre.", mesh="SM_VFX_Sphere"),
    S("NS_VFX_Water_Impact", "Water", "Impact", "Impact d'eau (variante WaterImpact).", "E_Element = T_VFX_Flip_Splash_4x4."),
    S("NS_VFX_Water_Dash", "Water", "Dash", "[F] Courant fulgurant.", "Rémanence d'eau + éclaboussures au départ et à l'arrivée."),
    # ------------------------------------------------------------------ Feu
    S("NS_VFX_Fire_Slash", "Fire", "Slash", "Coupes du Souffle de la Flamme.", "Langues de feu (flipbook) le long de l'arc + braises (Gravity +50) + chaleur (distorsion).", mesh="SM_VFX_Slash_Arc_180"),
    S("NS_VFX_Fire_Trail", "Fire", "Trail", "Traînée de flammes sur la lame.", "E_Bits = braises qui montent (Gravity +80)."),
    S("NS_VFX_Fire_Burst", "Fire", "Burst", "Univers flamboyant (jaillissement).", "Colonnes de flammes (flipbook, Velocity +Z)."),
    S("NS_VFX_Fire_Explosion", "Fire", "Burst", "Explosion de feu (ultime Purgatoire, fin de projectile).", "Boule de feu + fumée noire + onde orange."),
    S("NS_VFX_Fire_Dragon", "Fire", "Beast", "Tigre / dragon de flammes (forme 5, Purgatoire).", "Corps en flipbooks de flammes, tête maillée MI_Fire_Mesh.", mesh="SM_VFX_Dragon_Head"),
    S("NS_VFX_Fire_Impact", "Fire", "Impact", "Impact de feu (FireImpact).", "E_Element = T_VFX_Flip_Fire_8x8, fumée."),
    # ------------------------------------------------------------------ Foudre
    S("NS_VFX_Thunder_Dash", "Thunder", "Dash", "Éclair foudroyant (le joueur disparaît presque).", "Durée 0,3 s ; 3 beams du départ à EndPoint ; flash énorme au départ ; rémanence 0,12 s seulement.", duration="0,4 s"),
    S("NS_VFX_Thunder_Slash", "Thunder", "Slash", "Coupes de la Foudre.", "Arc + 4 beams courts le long de l'arc ; étincelles très rapides (Lifetime 0,15).", mesh="SM_VFX_Slash_Crescent_Tilted"),
    S("NS_VFX_Thunder_Burst", "Thunder", "Bolt", "Pluie d'éclairs autour d'un point.", "6 beams verticaux du ciel (EndPoint) au sol, décalés de 0,05 s."),
    S("NS_VFX_Thunder_Impact", "Thunder", "Impact", "Impact électrique (ThunderImpact).", "E_Element = T_VFX_Flip_Lightning_4x4 ; arcs au sol."),
    S("NS_VFX_Thunder_Explosion", "Thunder", "Burst", "Explosion électrique (Honoikazuchi).", "Sphère + 10 beams radiaux + flash aveuglant."),
    # ------------------------------------------------------------------ Vent
    S("NS_VFX_Wind_Slash", "Wind", "Slash", "Lames d'air.", "3 arcs fins décalés (griffes) ; feuilles + poussière.", mesh="SM_VFX_Slash_Arc_120"),
    S("NS_VFX_Wind_Trail", "Wind", "Trail", "Traînée de vent sur la lame.", "Feuilles (MI_Wind_Spark) emportées par Curl Noise."),
    S("NS_VFX_Wind_Tornado", "Wind", "Vortex", "Tornades (Arbre de la tempête, Typhon).", "Débris, feuilles, poussière au sol.", mesh="SM_VFX_Vortex_Cone"),
    S("NS_VFX_Wind_Blade", "Wind", "Projectile", "Lame d'air lancée (Vent froid de montagne).", "E_Core = SM_VFX_Slash_Arc_120 au lieu de la sphère.", mesh="SM_VFX_Slash_Arc_120"),
    S("NS_VFX_Wind_Impact", "Wind", "Impact", "Impact de vent (WindImpact).", "Poussière radiale + feuilles."),
    S("NS_VFX_Wind_Dash", "Wind", "Dash", "Élan du vent.", "Spirales autour du trajet."),
    # ------------------------------------------------------------------ Brume
    S("NS_VFX_Mist_Slash", "Mist", "Slash", "Coupes de la Brume.", "Arc très doux (érosion forte) ; la brume reste 1,5 s.", mesh="SM_VFX_Slash_Arc_180"),
    S("NS_VFX_Mist_Trail", "Mist", "Trail", "Traînée de brume."),
    S("NS_VFX_Mist_Fog", "Mist", "Aura", "Nappe de brume (Éclaboussures de brume, Brume obscurcissante).", "E_Sigil remplacé par 20 sprites de brume au sol (MI_Mist_Smoke), particules flottantes."),
    S("NS_VFX_Mist_Vanish", "Mist", "Dash", "Le joueur se fond dans la brume puis réapparaît.", "Nuage épais qui recouvre le personnage 0,4 s (le script masque le personnage)."),
    S("NS_VFX_Mist_Impact", "Mist", "Impact", "Impact de brume (MistImpact)."),
    # ------------------------------------------------------------------ Arts sanguinaires
    S("NS_VFX_Blood_Slash", "Blood", "Slash", "Griffes / lames de sang.", "Projections stylisées (MI_Blood_Spark, gravité).", mesh="SM_VFX_Slash_Arc_120"),
    S("NS_VFX_Blood_Burst", "Blood", "Burst", "Explosion de sang + sceau.", "E_Ring = sceau MI_VFX_Core_Sigil rouge qui tourne."),
    S("NS_VFX_Blood_Projectile", "Blood", "Projectile", "Lame de sang lancée.", "E_Core = SM_VFX_Slash_Arc_120.", mesh="SM_VFX_Slash_Arc_120"),
    S("NS_VFX_Blood_Aura", "Blood", "Aura", "Éveil du sang (aura)."),
    S("NS_VFX_Blood_Impact", "Blood", "Impact", "Impact de sang (BloodImpact)."),
    S("NS_VFX_Ice_Slash", "Ice", "Slash", "Éventails de glace.", "Cristaux (MI_Ice_Spark = éclats) + neige.", mesh="SM_VFX_Slash_Arc_180"),
    S("NS_VFX_Ice_Spikes", "Ice", "Spikes", "Hiver glacé (pics en cercle).", mesh="SM_VFX_Spike_Ice"),
    S("NS_VFX_Ice_Shard", "Ice", "Projectile", "Lance de glace.", "E_Core = SM_VFX_Spike_Ice orienté vers l'avant.", mesh="SM_VFX_Spike_Ice"),
    S("NS_VFX_Ice_Explosion", "Ice", "Burst", "Explosion de glace (Bodhisattva).", "Éclats maillés + brume froide.", mesh="SM_VFX_Spike_Ice"),
    S("NS_VFX_Ice_Impact", "Ice", "Impact", "Impact de glace (IceImpact).", "E_Debris = SM_VFX_Spike_Ice."),
    S("NS_VFX_Shadow_Slash", "Shadow", "Slash", "Griffes d'ombre.", "Fumée noire + particules violettes.", mesh="SM_VFX_Slash_Arc_120"),
    S("NS_VFX_Shadow_Vortex", "Shadow", "Vortex", "Vortex ténébreux.", "Distorsion forte au centre.", mesh="SM_VFX_Vortex_Cone"),
    S("NS_VFX_Shadow_Projectile", "Shadow", "Projectile", "Lance du néant."),
    S("NS_VFX_Shadow_Aura", "Shadow", "Aura", "Nuit éternelle / aura d'ombre."),
    S("NS_VFX_Shadow_Impact", "Shadow", "Impact", "Impact d'ombre."),
    S("NS_VFX_Flower_Slash", "Flower", "Slash", "Pétales tranchants.", "Pétales maillés (SM_VFX_Petal) au lieu des gouttes.", mesh="SM_VFX_Slash_Arc_180"),
    S("NS_VFX_Flower_PetalStorm", "Flower", "Vortex", "Tempête de pétales / jardin.", "E_Funnel masqué (alpha faible), pétales maillés en spirale.", mesh="SM_VFX_Petal"),
    S("NS_VFX_Flower_Bloom", "Flower", "Burst", "Éclosion (fleur lumineuse au sol).", "Sceau remplacé par 6 pétales maillés géants qui s'ouvrent.", mesh="SM_VFX_Petal"),
    S("NS_VFX_Flower_Projectile", "Flower", "Projectile", "Liane / projectile floral."),
    S("NS_VFX_Flower_Impact", "Flower", "Impact", "Impact floral."),
]


# ===========================================================================
# Rôles utilisés par le gamemode (Client/Systems/VFX) -> système
# ===========================================================================
ROLES = ["Slash", "Trail", "Impact", "Projectile", "Dash", "Burst", "Zone", "Wave", "Tsunami", "Tornado", "Dragon", "Explosion", "Spikes"]


def role_map():
    """Pour chaque élément du gamemode, le système à jouer par rôle (repli Core)."""
    # éléments du gamemode -> éléments du pack
    game = {"water": "Water", "flame": "Fire", "sun": "Fire", "thunder": "Thunder", "wind": "Wind", "mist": "Mist",
            "blood": "Blood", "ice": "Ice", "shadow": "Shadow", "flower": "Flower", "love": "Flower",
            "insect": "Flower", "sound": "Thunder", "serpent": "Shadow", "stone": "Core", "beast": "Wind", "neutral": "Core"}
    names = {s["name"] for s in SYSTEMS}
    out = {}
    for gid, e in game.items():
        def pick(*cands):
            for c in cands:
                if c in names:
                    return c
            return None
        out[gid] = {
            "Slash": pick(f"NS_VFX_{e}_Slash", "NS_Core_EnergyTrail"),
            "Trail": pick(f"NS_VFX_{e}_Trail", "NS_Core_ElementTrail"),
            "Impact": pick(f"NS_VFX_{e}_Impact", "NS_Impact_Medium"),
            "Projectile": pick(f"NS_VFX_{e}_Ball", f"NS_VFX_{e}_Projectile", f"NS_VFX_{e}_Blade", f"NS_VFX_{e}_Shard"),
            "Dash": pick(f"NS_VFX_{e}_Dash", f"NS_VFX_{e}_Vanish", "NS_Core_SpeedLines"),
            "Burst": pick(f"NS_VFX_{e}_Burst", f"NS_VFX_{e}_Explosion", f"NS_VFX_{e}_Bloom", "NS_Impact_Large"),
            "Zone": pick(f"NS_VFX_{e}_Tornado", f"NS_VFX_{e}_Vortex", f"NS_VFX_{e}_Fog", f"NS_VFX_{e}_Aura", f"NS_VFX_{e}_PetalStorm"),
            "Explosion": pick(f"NS_VFX_{e}_Explosion", f"NS_VFX_{e}_Burst", "NS_Impact_Massive"),
            "Wave": pick(f"NS_VFX_{e}_Wave"),
            "Tsunami": pick(f"NS_VFX_{e}_Tsunami"),
            "Tornado": pick(f"NS_VFX_{e}_Tornado", f"NS_VFX_{e}_Vortex"),
            "Dragon": pick(f"NS_VFX_{e}_Dragon"),
            "Spikes": pick(f"NS_VFX_{e}_Spikes"),
        }
        out[gid] = {k: v for k, v in out[gid].items() if v}
    return out


# ===========================================================================
# Générateurs
# ===========================================================================

def system_folder(s):
    return f"{UE_ROOT}/Systems/{FOLDER[s['element']]}" if s["name"].startswith("NS_VFX_") else (
        f"{UE_ROOT}/Niagara/Impacts" if s["name"].startswith("NS_Impact_") else f"{UE_ROOT}/Niagara/Core")


def write_catalog_md(path):
    lines = ["# Demon Slayer VFX Pack — Catalogue des VFX", "",
             f"Asset Pack nanos world : `{PACK_ID}` · dossier Unreal : `Content/{UE_ROOT}/` · Unreal {UNREAL_VERSION}", "",
             "Chaque système expose les **mêmes paramètres utilisateur** (Niagara `User.*`, réglables depuis nanos world avec `Particle:SetParameter*`) :", "",
             "| Paramètre | Type | Rôle |", "| --- | --- | --- |"]
    lines += [f"| `{n}` | {t} | {d} |" for n, t, d in USER_PARAMS]
    lines += ["", "Recettes de construction (émetteurs, modules, valeurs) : [NIAGARA_RECIPES.md](NIAGARA_RECIPES.md).", ""]
    current = None
    for s in SYSTEMS:
        group = FOLDER[s["element"]] if s["name"].startswith("NS_VFX_") else ("Impacts" if s["name"].startswith("NS_Impact_") else "Core")
        if group != current:
            lines += ["", f"## {group}", ""]
            current = group
        arch = ARCHETYPES[s["archetype"]]
        e = s["element"]
        mats = ", ".join(f"MI_VFX_{e}_{k}" for k in ("Slash", "Trail", "Spark", "Glow", "Flipbook", "Smoke", "Mesh", "Ring"))
        meshes = s["mesh"] or "—"
        lines += [
            f"### {s['name']}",
            f"- **Nom** : `{s['name']}` (`{PACK_ID}::{s['name']}`)",
            f"- **Type** : Niagara System — archétype **{s['archetype']}** ({arch['desc']})",
            f"- **Utilisation** : {s['usage']}",
            f"- **Particularités** : {s['special'] or 'recette de l’archétype sans changement'}",
            f"- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint{(', ' + s['params_extra']) if s['params_extra'] else ''}",
            f"- **Durée** : {s['duration'] or arch['duration']}",
            f"- **Performance** : {s['perf'] or arch['budget']} · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé",
            f"- **Asset principal** : `/Game/{system_folder(s)}/{s['name']}`",
            f"- **Dépendances** : {mats} ; maillage : {meshes} ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion",
            "",
        ]
    with open(path, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines))


def write_recipes_md(path):
    lines = ["# Recettes Niagara (archétypes)", "",
             "Méthode : construire **un système modèle par archétype** dans `Niagara/Core/` (`NS_Template_<Archétype>`),",
             "avec les paramètres utilisateur standard, puis **dupliquer** pour chaque élément et ne changer que les",
             "Material Instances, couleurs et valeurs indiquées dans le catalogue.", "",
             "## Règles communes (compatibilité nanos world + performance)", "",
             "1. **Paramètres utilisateur** (onglet *User Parameters*) sur chaque système : " + ", ".join(f"`{n}` ({t})" for n, t, _ in USER_PARAMS) + ".",
             "   Les lier dans les modules (Color x `User.Color`, Size x `User.Scale`, Lifetime x `User.Duration`, Spawn Rate x `User.SpawnScale`...).",
             "2. **Pas de Data Interface liée à la scène** que nanos ne fournit pas : pas de *Skeletal Mesh* DI sur le personnage, pas de *Actor Component* DI,",
             "   pas de *Collision Query* CPU sur la scène, pas de *Export Particle Data* vers Blueprint. Autorisés : Static Mesh DI sur NOS maillages, Curl Noise,",
             "   Vortex/Point Attraction, Event Handlers internes, Beam Emitter Setup, SubUV, Dynamic Material Parameters, GPU Depth Buffer Collision.",
             "3. **Aucune référence à `/Engine/` ou au contenu par défaut de Niagara** (textures, matériaux) : tout vient de `Content/DemonSlayerVFX/`.",
             "   Les modules standards de Niagara (`/Niagara/Modules/...`) sont compilés dans le système : autorisés.",
             "4. **Systèmes à durée finie** : *Loop Behavior = Once* + *Inactive Response = Complete*, pour que nanos détruise le système à la fin",
             "   (sauf Trail / Projectile / Aura : boucle, le script détruit la Particle).",
             "5. **Scalability** : *Effect Type* `EFT_DemonSlayer_Combat` (dans `Niagara/Core/`) : Cull Distance 9000, Max Instances 24, LOD distance",
             "   3000 / 6000 avec *Spawn Count Scale* 0,5 / 0,25. GPU uniquement pour les émetteurs > 150 particules (mousse, gouttes de tsunami).",
             "6. **Fixed Bounds** sur chaque émetteur (pas de calcul dynamique) : ex. Slash 600 x 600 x 300, Tsunami 3000 x 1500 x 800.",
             "7. Orientation : le système suit la rotation de l'acteur (Local Space pour les maillages de coupe, World Space pour rubans et gouttes).",
             "",
             "## Chronologie commune (anticipation → dissipation)", "",
             "| t | Phase | Contenu |", "| --- | --- | --- |",
             "| 0,00 | Anticipation | petites particules attirées vers la lame (E_Anticipation / E_Charge) |",
             "| 0,05 | Accumulation | lueur (MI_<E>_Glow) qui grossit |",
             "| 0,08 | Attaque | balayage du maillage (Param1 0→1 en 0,12 s), ruban |",
             "| 0,10 | Forme principale + flash | maillage plein, flash, distorsion |",
             "| 0,15 | Impact | (système _Impact déclenché par le script au point touché) |",
             "| 0,20 | Particules secondaires | gouttes / braises / étincelles avec drag et gravité |",
             "| 0,30 | Dissipation | érosion (Param2) + fumée / brume qui monte |",
             "| 0,45+ | Fin | plus rien de vivant, le système se détruit |",
             ""]
    for name, a in ARCHETYPES.items():
        lines += [f"## Archétype {name}", "", a["desc"], "", f"Durée : {a['duration']} · Budget : {a['budget']}", "",
                  "| Émetteur | Type | Modules et valeurs |", "| --- | --- | --- |"]
        lines += [f"| `{n}` | {t} | {m} |" for n, t, m in a["emitters"]]
        lines.append("")
    with open(path, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines))


def write_assets_toml(path):
    lines = ["# Demon Slayer VFX Pack - Assets.toml (généré par Tools/vfx_catalog.py)",
             "# À placer à la racine de l'Asset Pack : Server/Assets/" + PACK_ID + "/Assets.toml", "",
             "[meta]", '    title = "Demon Slayer VFX Pack"', '    author = "NARSOU"', '    version = "0.1.0"', "",
             "[unreal]", f'    unreal_folders = [ "{UE_ROOT}" ]', f'    unreal_version = "{UNREAL_VERSION}"', "    is_plugin_content = false", "",
             "[assets]", "", "    [assets.particles]"]
    for s in SYSTEMS:
        lines.append(f'        {s["name"]} = "{system_folder(s)}/{s["name"]}"')
    lines += ["", "    [assets.static_meshes]"]
    for m in ["SM_VFX_Slash_Arc_120", "SM_VFX_Slash_Arc_180", "SM_VFX_Slash_Arc_270", "SM_VFX_Slash_Arc_360",
              "SM_VFX_Slash_Crescent_Tilted", "SM_VFX_Ring_Flat", "SM_VFX_Ring_Thick", "SM_VFX_Vortex_Cylinder",
              "SM_VFX_Vortex_Cone", "SM_VFX_Wave_Curl", "SM_VFX_Sphere", "SM_VFX_Cone_Open", "SM_VFX_Spike_Ice",
              "SM_VFX_Dragon_Head", "SM_VFX_Dragon_Segment", "SM_VFX_Petal"]:
        sub = "Slashes" if "Slash" in m else "Rings" if "Ring" in m else "Waves" if "Wave" in m else "Water" if "Dragon" in m else "Energy"
        lines.append(f'        {m} = "{UE_ROOT}/Meshes/{sub}/{m}"')
    lines += ["", "    [assets.materials]"]
    for mi in material_instances():
        lines.append(f'        {mi["name"]} = "{UE_ROOT}/Materials/{mi["folder"]}/{mi["name"]}"')
    with open(path, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines) + "\n")


def write_catalog_json(path):
    data = {
        "pack_id": PACK_ID, "root": UE_ROOT, "user_params": USER_PARAMS,
        "masters": MASTER_MATERIALS, "instances": material_instances(),
        "systems": [dict(s, folder=system_folder(s)) for s in SYSTEMS],
        "zones": ["WATER", "FIRE", "THUNDER", "WIND", "MIST", "BLOOD ARTS", "IMPACTS", "TRAILS", "PROJECTILES"],
    }
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(data, fh, indent=1, ensure_ascii=False)


def write_lua(path):
    rm = role_map()
    lines = ["--[[",
             "    Demon Slayer RP - Catalogue du pack Niagara \"" + PACK_ID + "\" (GÉNÉRÉ, ne pas modifier à la main)",
             "    ------------------------------------------------------------------",
             "    Source : DemonSlayerVFX/Tools/vfx_catalog.py",
             "    Rôle d'effet du gamemode -> Niagara System du pack, par élément.",
             "    Utilisé par Client/Systems/VFX/Core/VFXPack.lua quand Config.Vfx.Pack.Enabled = true.",
             "]]", "",
             "Config.VfxPackCatalog = {",
             f'    PackId = "{PACK_ID}",',
             "    Systems = {"]
    for s in SYSTEMS:
        lines.append(f'        "{s["name"]}",')
    lines += ["    },", "    Roles = {"]
    for gid in sorted(rm):
        roles = rm[gid]
        body = ", ".join(f'{k} = "{v}"' for k, v in sorted(roles.items()))
        lines.append(f"        {gid} = {{ {body} }},")
    lines += ["    },", "    Impacts = { Small = \"NS_Impact_Small\", Medium = \"NS_Impact_Medium\", Large = \"NS_Impact_Large\", Massive = \"NS_Impact_Massive\" },", "}", ""]
    with open(path, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines))


if __name__ == "__main__":
    base = os.path.join(HERE, "..")
    os.makedirs(os.path.join(base, "Docs"), exist_ok=True)
    os.makedirs(os.path.join(base, "Unreal"), exist_ok=True)
    os.makedirs(os.path.join(base, "AssetPack"), exist_ok=True)
    write_catalog_md(os.path.join(base, "Docs", "VFX_CATALOG.md"))
    write_recipes_md(os.path.join(base, "Docs", "NIAGARA_RECIPES.md"))
    write_assets_toml(os.path.join(base, "AssetPack", "Assets.toml"))
    write_catalog_json(os.path.join(base, "Unreal", "catalog.json"))
    lua = os.path.join(base, "..", "Packages", "demon-slayer-rp", "Shared", "Config", "VfxPackCatalog.lua")
    write_lua(lua)
    print(f"{len(SYSTEMS)} systèmes, {len(material_instances())} Material Instances, {len(MASTER_MATERIALS)} matériaux maîtres, {len(ARCHETYPES)} archétypes")
