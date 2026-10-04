"""
Demon Slayer VFX Pack - script Unreal Editor (Python)
=====================================================
À exécuter DANS le projet ADK nanos world (Unreal 5.7) :
  Edit > Plugins : activer "Python Editor Script Plugin" (et "Editor Scripting Utilities")
  Tools > Execute Python Script... > ue_setup_pack.py
  (ou dans la console Output Log en mode "Python" : exec(open(r"C:/.../ue_setup_pack.py").read()))

Étapes (chacune peut être relancée sans risque, les assets existants sont mis à jour) :
  1. Arborescence Content/DemonSlayerVFX/...
  2. Import des textures (Source/Textures) avec les bons réglages (Masks, sans sRGB, Effects)
  3. Import des maillages (Source/Meshes/*.obj), collisions supprimées
  4. Matériaux maîtres VFX (graphes construits automatiquement)
  5. Material Instances par élément (couleurs, émissif, textures)
  6. Modèles Niagara vides par archétype (NS_Template_*) + Effect Type
  7. Scène de test Content/DemonSlayerVFX_Test/DemonSlayer_VFX_Test (zones + systèmes existants)
  8. Vérification d'export : systèmes manquants, dépendances interdites (/Engine hors liste, autres packs)

Le contenu des Niagara Systems (émetteurs, modules) se construit dans l'éditeur Niagara
en suivant Docs/NIAGARA_RECIPES.md ; relancer ce script place ensuite les systèmes dans la
scène de test et vérifie leurs dépendances.
"""
import json
import os

import unreal

HERE = os.path.dirname(os.path.abspath(__file__)) if "__file__" in globals() else os.getcwd()
SOURCE = os.path.normpath(os.path.join(HERE, "..", "Source"))
CATALOG = json.load(open(os.path.join(HERE, "catalog.json"), encoding="utf-8"))
ROOT = "/Game/" + CATALOG["root"]
TEST_ROOT = "/Game/DemonSlayerVFX_Test"           # hors de l'Asset Pack (non cuit)

ASSET_TOOLS = unreal.AssetToolsHelpers.get_asset_tools()
EAL = unreal.EditorAssetLibrary
MEL = unreal.MaterialEditingLibrary
REPORT = {"ok": [], "warn": [], "error": []}


def log(kind, msg):
    REPORT[kind].append(msg)
    (unreal.log_error if kind == "error" else unreal.log_warning if kind == "warn" else unreal.log)("[DSVFX] " + msg)


# ===========================================================================
# 1. Dossiers
# ===========================================================================
FOLDERS = [
    "Niagara/Core", "Niagara/Water", "Niagara/Fire", "Niagara/Thunder", "Niagara/Wind", "Niagara/Mist",
    "Niagara/BloodArts", "Niagara/Impacts", "Niagara/Trails", "Niagara/Projectiles", "Niagara/Environment",
    "Materials/Core", "Materials/Water", "Materials/Fire", "Materials/Energy", "Materials/Thunder",
    "Materials/Blood", "Materials/Mist",
    "Meshes/Slashes", "Meshes/Waves", "Meshes/Rings", "Meshes/Energy", "Meshes/Water", "Meshes/Fire",
    "Textures/Noise", "Textures/Masks", "Textures/Distortion", "Textures/Trails", "Textures/Particles",
    "Systems/Water", "Systems/Fire", "Systems/Thunder", "Systems/Wind", "Systems/Mist", "Systems/BloodArts",
]


def make_folders():
    for f in FOLDERS:
        EAL.make_directory(f"{ROOT}/{f}")
    EAL.make_directory(TEST_ROOT)
    log("ok", f"{len(FOLDERS)} dossiers prêts sous {ROOT}")


# ===========================================================================
# 2-3. Imports
# ===========================================================================
def import_file(path, dest, name):
    task = unreal.AssetImportTask()
    task.set_editor_property("filename", path)
    task.set_editor_property("destination_path", dest)
    task.set_editor_property("destination_name", name)
    task.set_editor_property("automated", True)
    task.set_editor_property("replace_existing", True)
    task.set_editor_property("save", False)
    ASSET_TOOLS.import_asset_tasks([task])
    asset_path = f"{dest}/{name}"
    return EAL.load_asset(asset_path) if EAL.does_asset_exist(asset_path) else None


def import_textures():
    count = 0
    for folder in sorted(os.listdir(os.path.join(SOURCE, "Textures"))):
        for file in sorted(os.listdir(os.path.join(SOURCE, "Textures", folder))):
            if not file.endswith(".png"):
                continue
            name = file[:-4]
            tex = import_file(os.path.join(SOURCE, "Textures", folder, file), f"{ROOT}/Textures/{folder}", name)
            if not tex:
                log("error", f"import texture impossible : {file}")
                continue
            normal = folder == "Distortion"
            tex.set_editor_property("compression_settings",
                                    unreal.TextureCompressionSettings.TC_NORMALMAP if normal else unreal.TextureCompressionSettings.TC_MASKS)
            tex.set_editor_property("srgb", False)
            tex.set_editor_property("lod_group", unreal.TextureGroup.TEXTUREGROUP_EFFECTS)
            tex.set_editor_property("max_texture_size", 1024)
            tex.set_editor_property("never_stream", True)    # VFX courts : pas de flou au premier affichage
            if folder in ("Noise", "Trails", "Distortion"):
                tex.set_editor_property("address_x", unreal.TextureAddress.TA_WRAP)
                tex.set_editor_property("address_y", unreal.TextureAddress.TA_WRAP)
            else:
                tex.set_editor_property("address_x", unreal.TextureAddress.TA_CLAMP)
                tex.set_editor_property("address_y", unreal.TextureAddress.TA_CLAMP)
            EAL.save_loaded_asset(tex)
            count += 1
    log("ok", f"{count} textures importées")


MESH_FOLDER = {"Slash": "Slashes", "Ring": "Rings", "Wave": "Waves", "Dragon": "Water", "Vortex": "Energy",
               "Sphere": "Energy", "Cone": "Energy", "Spike": "Energy", "Petal": "Energy"}


def import_meshes():
    count = 0
    subsystem = unreal.get_editor_subsystem(unreal.StaticMeshEditorSubsystem)
    for file in sorted(os.listdir(os.path.join(SOURCE, "Meshes"))):
        if not file.endswith(".obj"):
            continue
        name = file[:-4]
        key = name.split("_")[2]
        folder = MESH_FOLDER.get(key, "Energy")
        mesh = import_file(os.path.join(SOURCE, "Meshes", file), f"{ROOT}/Meshes/{folder}", name)
        if not mesh:
            log("error", f"import maillage impossible : {file}")
            continue
        try:
            subsystem.remove_collisions(mesh)
        except Exception as exc:  # noqa: BLE001
            log("warn", f"{name} : collisions non supprimées ({exc})")
        try:
            settings = mesh.get_editor_property("nanite_settings")
            settings.set_editor_property("enabled", False)
            mesh.set_editor_property("nanite_settings", settings)
        except Exception:  # noqa: BLE001
            pass
        EAL.save_loaded_asset(mesh)
        count += 1
    log("ok", f"{count} maillages importés")


# ===========================================================================
# 4. Matériaux maîtres
# ===========================================================================
class Graph:
    """Petit utilitaire de construction de graphe de matériau."""

    def __init__(self, material):
        self.m = material
        self.x = -1600
        self.y = 0

    def node(self, cls, x, y, **props):
        expr = MEL.create_material_expression(self.m, cls, x, y)
        for k, v in props.items():
            expr.set_editor_property(k, v)
        return expr

    def link(self, a, out, b, inp):
        if not MEL.connect_material_expressions(a, out, b, inp):
            log("warn", f"{self.m.get_name()} : liaison {a.get_name()}.{out or 'out'} -> {b.get_name()}.{inp or 'in'} refusée")

    def out(self, a, out, prop):
        if not MEL.connect_material_property(a, out, prop):
            log("warn", f"{self.m.get_name()} : sortie {prop} non reliée")

    # -- raccourcis
    def scalar(self, name, value, x, y):
        return self.node(unreal.MaterialExpressionScalarParameter, x, y, parameter_name=name, default_value=value)

    def vector(self, name, value, x, y):
        return self.node(unreal.MaterialExpressionVectorParameter, x, y, parameter_name=name,
                         default_value=unreal.LinearColor(value[0], value[1], value[2], 1))

    def texture(self, name, default_path, x, y, subuv=False):
        cls = unreal.MaterialExpressionTextureSampleParameterSubUV if subuv else unreal.MaterialExpressionTextureSampleParameter2D
        expr = self.node(cls, x, y, parameter_name=name)
        tex = EAL.load_asset(default_path) if EAL.does_asset_exist(default_path) else None
        if tex:
            expr.set_editor_property("texture", tex)
            expr.set_editor_property("sampler_type", unreal.MaterialSamplerType.SAMPLERTYPE_MASKS
                                     if "Distortion" not in default_path else unreal.MaterialSamplerType.SAMPLERTYPE_NORMAL)
        else:
            log("warn", f"{self.m.get_name()} : texture par défaut absente {default_path}")
        return expr

    def op(self, cls, x, y, a=None, b=None, a_out="", b_out=""):
        expr = self.node(cls, x, y)
        if a is not None:
            self.link(a, a_out, expr, "A")
        if b is not None:
            self.link(b, b_out, expr, "B")
        return expr

    def mul(self, x, y, a, b, a_out="", b_out=""):
        return self.op(unreal.MaterialExpressionMultiply, x, y, a, b, a_out, b_out)

    def single(self, cls, x, y, a, a_out=""):
        expr = self.node(cls, x, y)
        self.link(a, a_out, expr, "")
        return expr

    def panner(self, x, y, coord, speed_param, tiling=None):
        tc = self.node(unreal.MaterialExpressionTextureCoordinate, x - 400, y)
        coordinate = tc
        if tiling is not None:
            coordinate = self.mul(x - 250, y, tc, tiling)
        zero = self.node(unreal.MaterialExpressionConstant, x - 400, y + 120, r=0.0)
        speed = self.op(unreal.MaterialExpressionAppendVector, x - 250, y + 120, speed_param, zero)
        pan = self.node(unreal.MaterialExpressionPanner, x, y)
        self.link(coordinate, "", pan, "Coordinate")
        self.link(speed, "", pan, "Speed")
        return pan


def new_material(name, folder, blend, two_sided=False, mesh=False, ribbon=False, sprites=True):
    path = f"{ROOT}/Materials/{folder}"
    full = f"{path}/{name}"
    if EAL.does_asset_exist(full):
        EAL.delete_asset(full)       # reconstruit à neuf (les MI enfants seront ré-associées)
    mat = ASSET_TOOLS.create_asset(name, path, unreal.Material, unreal.MaterialFactoryNew())
    mat.set_editor_property("blend_mode", blend)
    mat.set_editor_property("shading_model", unreal.MaterialShadingModel.MSM_UNLIT)
    mat.set_editor_property("two_sided", two_sided)
    mat.set_editor_property("used_with_niagara_sprites", sprites)
    mat.set_editor_property("used_with_niagara_ribbons", ribbon or sprites)
    mat.set_editor_property("used_with_niagara_mesh_particles", mesh)
    mat.set_editor_property("used_with_static_lighting", False)
    return mat, Graph(mat)


def dyn_param(g, names, default, x, y):
    expr = g.node(unreal.MaterialExpressionDynamicParameter, x, y)
    expr.set_editor_property("param_names", names)
    expr.set_editor_property("default_value", unreal.LinearColor(*default))
    return expr


def depth_fade(g, value, distance, x, y):
    df = g.node(unreal.MaterialExpressionDepthFade, x, y, fade_distance_default=distance)
    g.link(value, "", df, "Opacity")
    return df


TEX = lambda folder, name: f"{ROOT}/Textures/{folder}/{name}"  # noqa: E731


def build_sprite_additive():
    mat, g = new_material("M_VFX_Sprite_Additive", "Core", unreal.BlendMode.BLEND_ADDITIVE)
    mask = g.texture("Mask", TEX("Masks", "T_VFX_Mask_SoftCircle"), -1400, 0)
    pc = g.node(unreal.MaterialExpressionParticleColor, -1400, 300)
    dyn = dyn_param(g, ["Erosion", "Unused1", "Unused2", "Unused3"], (0, 0, 0, 0), -1400, 500)
    eroded = g.single(unreal.MaterialExpressionSaturate, -900, 100, g.op(unreal.MaterialExpressionSubtract, -1100, 100, mask, dyn, "R", "Erosion"))
    alpha = g.mul(-700, 150, eroded, pc, "", "A")
    faded = depth_fade(g, alpha, 40.0, -500, 150)
    color = g.mul(-900, -150, g.vector("Color", (1, 1, 1), -1200, -250), g.scalar("Emissive", 5.0, -1200, -150))
    tinted = g.mul(-700, -100, color, pc, "", "")
    final = g.mul(-300, 0, tinted, faded)
    g.out(final, "", unreal.MaterialProperty.MP_EMISSIVE_COLOR)
    return mat


def build_sprite_translucent():
    mat, g = new_material("M_VFX_Sprite_Translucent", "Core", unreal.BlendMode.BLEND_TRANSLUCENT)
    mask = g.texture("Mask", TEX("Particles", "T_VFX_Flip_Smoke_8x8"), -1500, 0, subuv=True)
    pan_speed = g.scalar("PanSpeed", 0.05, -2100, 400)
    noise = g.texture("Noise", TEX("Noise", "T_VFX_Noise_Cloud"), -1300, 350)
    g.link(g.panner(-1500, 350, None, pan_speed), "", noise, "UVs")
    pc = g.node(unreal.MaterialExpressionParticleColor, -1300, 650)
    dyn = dyn_param(g, ["Erosion", "Unused1", "Unused2", "Unused3"], (0, 0, 0, 0), -1300, 850)
    shaped = g.mul(-1000, 100, mask, noise, "R", "R")
    eroded = g.single(unreal.MaterialExpressionSaturate, -800, 150, g.op(unreal.MaterialExpressionSubtract, -900, 150, shaped, dyn, "", "Erosion"))
    alpha = g.mul(-600, 200, g.mul(-700, 250, eroded, pc, "", "A"), g.scalar("Opacity", 0.6, -800, 400))
    g.out(depth_fade(g, alpha, 120.0, -400, 200), "", unreal.MaterialProperty.MP_OPACITY)
    g.out(g.mul(-500, -100, g.vector("Color", (0.8, 0.8, 0.85), -800, -150), pc), "", unreal.MaterialProperty.MP_EMISSIVE_COLOR)
    return mat


def build_sprite_flipbook():
    mat, g = new_material("M_VFX_Sprite_Flipbook", "Core", unreal.BlendMode.BLEND_ADDITIVE)
    flip = g.texture("Flipbook", TEX("Particles", "T_VFX_Flip_Fire_8x8"), -1500, 0, subuv=True)
    flip.set_editor_property("blend", True)
    pc = g.node(unreal.MaterialExpressionParticleColor, -1500, 350)
    hot = g.node(unreal.MaterialExpressionPower, -1200, -100)
    g.link(flip, "R", hot, "Base")
    g.link(g.node(unreal.MaterialExpressionConstant, -1400, -50, r=2.5), "", hot, "Exponent")
    lerp = g.node(unreal.MaterialExpressionLinearInterpolate, -1000, -200)
    g.link(g.vector("Color", (1, 0.4, 0.05), -1300, -350), "", lerp, "A")
    g.link(g.vector("SecondaryColor", (1, 0.9, 0.5), -1300, -250), "", lerp, "B")
    g.link(hot, "", lerp, "Alpha")
    shaped = g.mul(-800, 0, flip, pc, "R", "A")
    glow = g.mul(-700, -150, g.mul(-850, -200, lerp, g.scalar("Emissive", 8.0, -1000, -50)), pc, "", "")
    g.out(g.mul(-400, 0, glow, depth_fade(g, shaped, 40.0, -600, 50)), "", unreal.MaterialProperty.MP_EMISSIVE_COLOR)
    return mat


def build_mesh_slash():
    mat, g = new_material("M_VFX_Mesh_Slash", "Core", unreal.BlendMode.BLEND_ADDITIVE, two_sided=True, mesh=True, sprites=True)
    tc = g.node(unreal.MaterialExpressionTextureCoordinate, -2000, 0)
    mask = g.texture("Mask", TEX("Masks", "T_VFX_Mask_SlashTrail"), -1600, 0)
    g.link(tc, "", mask, "UVs")
    pan_speed = g.scalar("PanSpeed", 1.5, -2200, 450)
    noise = g.texture("Noise", TEX("Trails", "T_VFX_Trail_Water"), -1600, 350)
    g.link(g.panner(-1800, 350, None, pan_speed), "", noise, "UVs")
    dyn = dyn_param(g, ["Sweep", "Erosion", "Unused2", "Unused3"], (1, 0, 0, 0), -1600, 700)
    pc = g.node(unreal.MaterialExpressionParticleColor, -1600, 950)
    # révélation le long de l'arc : saturate((Sweep * 1.2 - U) * 6)
    u = g.node(unreal.MaterialExpressionComponentMask, -1700, -250, r=True, g=False, b=False, a=False)
    g.link(tc, "", u, "")
    sweep = g.mul(-1400, -300, dyn, g.node(unreal.MaterialExpressionConstant, -1600, -350, r=1.2), "Sweep", "")
    reveal = g.single(unreal.MaterialExpressionSaturate, -1000, -300,
                      g.mul(-1150, -300, g.op(unreal.MaterialExpressionSubtract, -1300, -300, sweep, u), g.node(unreal.MaterialExpressionConstant, -1300, -200, r=6.0)))
    body = g.mul(-1200, 100, mask, noise, "R", "R")
    body = g.op(unreal.MaterialExpressionAdd, -1050, 100, body, g.mul(-1200, 0, mask, mask, "R", "R"))   # cœur plein + texture d'eau/feu
    eroded = g.single(unreal.MaterialExpressionSaturate, -850, 150, g.op(unreal.MaterialExpressionSubtract, -950, 150, body, dyn, "", "Erosion"))
    alpha = g.mul(-650, 100, g.mul(-750, 50, eroded, reveal), pc, "", "A")
    hot = g.node(unreal.MaterialExpressionPower, -1000, -550)
    g.link(mask, "R", hot, "Base")
    g.link(g.node(unreal.MaterialExpressionConstant, -1200, -500, r=3.0), "", hot, "Exponent")
    lerp = g.node(unreal.MaterialExpressionLinearInterpolate, -800, -600)
    g.link(g.vector("Color", (0.1, 0.55, 1), -1100, -750), "", lerp, "A")
    g.link(g.vector("SecondaryColor", (0.85, 0.97, 1), -1100, -650), "", lerp, "B")
    g.link(hot, "", lerp, "Alpha")
    glow = g.mul(-550, -450, g.mul(-650, -550, lerp, g.scalar("Emissive", 6.0, -800, -400)), pc, "", "")
    g.out(g.mul(-300, -100, glow, alpha), "", unreal.MaterialProperty.MP_EMISSIVE_COLOR)
    return mat


def build_ribbon():
    mat, g = new_material("M_VFX_Ribbon", "Core", unreal.BlendMode.BLEND_ADDITIVE, two_sided=True, ribbon=True)
    tiling = g.node(unreal.MaterialExpressionAppendVector, -2000, 0)
    g.link(g.scalar("Tiling", 2.0, -2200, -50), "", tiling, "A")
    g.link(g.node(unreal.MaterialExpressionConstant, -2200, 50, r=1.0), "", tiling, "B")
    pan_speed = g.scalar("PanSpeed", 2.0, -2200, 200)
    trail = g.texture("Trail", TEX("Trails", "T_VFX_Trail_Energy"), -1500, 0)
    g.link(g.panner(-1700, 0, None, pan_speed, tiling), "", trail, "UVs")
    noise = g.texture("Noise", TEX("Noise", "T_VFX_Noise_Streaks"), -1500, 350)
    g.link(g.panner(-1700, 350, None, g.scalar("NoiseSpeed", 3.0, -2200, 450)), "", noise, "UVs")
    pc = g.node(unreal.MaterialExpressionParticleColor, -1500, 650)
    shaped = g.mul(-1200, 100, trail, g.op(unreal.MaterialExpressionAdd, -1300, 300, noise, g.node(unreal.MaterialExpressionConstant, -1500, 550, r=0.5), "R", ""), "R", "")
    alpha = g.mul(-1000, 150, shaped, pc, "", "A")
    hot = g.node(unreal.MaterialExpressionPower, -1100, -300)
    g.link(trail, "R", hot, "Base")
    g.link(g.node(unreal.MaterialExpressionConstant, -1300, -250, r=3.0), "", hot, "Exponent")
    lerp = g.node(unreal.MaterialExpressionLinearInterpolate, -900, -350)
    g.link(g.vector("Color", (0.1, 0.55, 1), -1200, -500), "", lerp, "A")
    g.link(g.vector("SecondaryColor", (0.85, 0.97, 1), -1200, -400), "", lerp, "B")
    g.link(hot, "", lerp, "Alpha")
    glow = g.mul(-600, -250, g.mul(-700, -300, lerp, g.scalar("Emissive", 6.0, -900, -200)), pc, "", "")
    g.out(g.mul(-350, -50, glow, alpha), "", unreal.MaterialProperty.MP_EMISSIVE_COLOR)
    return mat


def build_mesh_energy():
    mat, g = new_material("M_VFX_Mesh_Energy", "Core", unreal.BlendMode.BLEND_TRANSLUCENT, two_sided=True, mesh=True, sprites=False)
    fres = g.node(unreal.MaterialExpressionFresnel, -1300, -400)
    g.link(g.scalar("FresnelPower", 2.5, -1600, -400), "", fres, "ExponentIn")
    tiling = g.node(unreal.MaterialExpressionConstant, -2000, 100, r=2.0)
    noise = g.texture("Noise", TEX("Noise", "T_VFX_Noise_Caustics"), -1400, 0)
    g.link(g.panner(-1600, 0, None, g.scalar("PanSpeed", 0.15, -2100, 200), tiling), "", noise, "UVs")
    dyn = dyn_param(g, ["Erosion", "Unused1", "Unused2", "Unused3"], (0, 0, 0, 0), -1400, 400)
    pc = g.node(unreal.MaterialExpressionParticleColor, -1400, 650)
    c2 = g.vector("SecondaryColor", (0.85, 0.97, 1), -1300, -650)
    rim = g.mul(-1000, -500, c2, g.mul(-1100, -450, fres, g.node(unreal.MaterialExpressionConstant, -1300, -300, r=2.0)))
    caust = g.mul(-1000, -150, c2, noise, "", "R")
    col = g.op(unreal.MaterialExpressionAdd, -800, -300, g.op(unreal.MaterialExpressionAdd, -900, -400, g.vector("Color", (0.1, 0.55, 1), -1100, -750), rim), caust)
    emissive = g.mul(-550, -250, g.mul(-650, -300, col, g.scalar("Emissive", 3.0, -800, -150)), pc, "", "")
    g.out(emissive, "", unreal.MaterialProperty.MP_EMISSIVE_COLOR)
    base = g.op(unreal.MaterialExpressionAdd, -1000, 100, g.mul(-1100, 50, fres, g.node(unreal.MaterialExpressionConstant, -1300, 100, r=0.7)), g.mul(-1100, 200, noise, g.node(unreal.MaterialExpressionConstant, -1300, 250, r=0.35), "R", ""))
    base = g.op(unreal.MaterialExpressionAdd, -900, 150, base, g.node(unreal.MaterialExpressionConstant, -1100, 300, r=0.25))
    shaped = g.mul(-750, 150, g.mul(-850, 200, base, g.scalar("Opacity", 0.85, -1000, 350)), pc, "", "A")
    eroded = g.single(unreal.MaterialExpressionSaturate, -550, 200, g.op(unreal.MaterialExpressionSubtract, -650, 200, shaped, dyn, "", "Erosion"))
    g.out(depth_fade(g, eroded, 60.0, -350, 200), "", unreal.MaterialProperty.MP_OPACITY)
    return mat


def build_distortion():
    mat, g = new_material("M_VFX_Distortion", "Core", unreal.BlendMode.BLEND_TRANSLUCENT, two_sided=True, mesh=True)
    try:
        mat.set_editor_property("refraction_method", unreal.RefractionMode.RM_PIXEL_NORMAL_OFFSET)
    except Exception:  # noqa: BLE001
        log("warn", "M_VFX_Distortion : mode de réfraction à régler à la main (Pixel Normal Offset)")
    normal = g.texture("Normal", TEX("Distortion", "T_VFX_Distortion_Noise_N"), -1300, 0)
    g.link(g.panner(-1500, 0, None, g.scalar("PanSpeed", 0.3, -2000, 150)), "", normal, "UVs")
    pc = g.node(unreal.MaterialExpressionParticleColor, -1300, 400)
    strength = g.mul(-900, 300, g.scalar("Strength", 0.08, -1100, 300), pc, "", "A")
    g.out(normal, "RGB", unreal.MaterialProperty.MP_NORMAL)
    refr = g.op(unreal.MaterialExpressionAdd, -700, 300, strength, g.node(unreal.MaterialExpressionConstant, -900, 450, r=1.0))
    g.out(refr, "", unreal.MaterialProperty.MP_REFRACTION)
    g.out(g.node(unreal.MaterialExpressionConstant, -700, 550, r=0.0), "", unreal.MaterialProperty.MP_OPACITY)
    return mat


BUILDERS = [build_sprite_additive, build_sprite_translucent, build_sprite_flipbook, build_mesh_slash,
            build_ribbon, build_mesh_energy, build_distortion]


def build_masters():
    for fn in BUILDERS:
        try:
            mat = fn()
            MEL.layout_material_expressions(mat)
            MEL.recompile_material(mat)
            EAL.save_loaded_asset(mat)
            log("ok", f"matériau {mat.get_name()} construit")
        except Exception as exc:  # noqa: BLE001
            log("error", f"{fn.__name__} : {exc}")


# ===========================================================================
# 5. Material Instances
# ===========================================================================
def build_instances():
    count = 0
    for spec in CATALOG["instances"]:
        path = f"{ROOT}/Materials/{spec['folder']}"
        full = f"{path}/{spec['name']}"
        parent = EAL.load_asset(f"{ROOT}/Materials/Core/{spec['parent']}")
        if not parent:
            log("error", f"{spec['name']} : parent {spec['parent']} absent")
            continue
        mi = EAL.load_asset(full) if EAL.does_asset_exist(full) else ASSET_TOOLS.create_asset(
            spec["name"], path, unreal.MaterialInstanceConstant, unreal.MaterialInstanceConstantFactoryNew())
        MEL.set_material_instance_parent(mi, parent)
        for name, rgb in spec["vectors"].items():
            MEL.set_material_instance_vector_parameter_value(mi, name, unreal.LinearColor(rgb[0], rgb[1], rgb[2], 1))
        for name, value in spec["scalars"].items():
            MEL.set_material_instance_scalar_parameter_value(mi, name, float(value))
        for name, tex_name in spec["textures"].items():
            found = None
            for folder in ("Masks", "Noise", "Trails", "Particles", "Distortion"):
                p = TEX(folder, tex_name)
                if EAL.does_asset_exist(p):
                    found = EAL.load_asset(p)
                    break
            if found:
                MEL.set_material_instance_texture_parameter_value(mi, name, found)
            else:
                log("warn", f"{spec['name']} : texture {tex_name} introuvable")
        MEL.update_material_instance(mi)
        EAL.save_loaded_asset(mi)
        count += 1
    log("ok", f"{count} Material Instances")


# ===========================================================================
# 6. Modèles Niagara + Effect Type
# ===========================================================================
ARCHETYPES = ["Slash", "Trail", "Impact", "Projectile", "Dash", "Wave", "Vortex", "Beast", "Burst", "Aura", "Spikes", "Bolt"]


def build_niagara_templates():
    path = f"{ROOT}/Niagara/Core"
    try:
        factory = unreal.NiagaraSystemFactoryNew()
    except Exception:  # noqa: BLE001
        log("warn", "NiagaraSystemFactoryNew indisponible : créez les modèles à la main (Docs/NIAGARA_RECIPES.md)")
        return
    for arch in ARCHETYPES:
        name = f"NS_Template_{arch}"
        if not EAL.does_asset_exist(f"{path}/{name}"):
            ASSET_TOOLS.create_asset(name, path, unreal.NiagaraSystem, factory)
    try:
        if not EAL.does_asset_exist(f"{path}/EFT_DemonSlayer_Combat"):
            ASSET_TOOLS.create_asset("EFT_DemonSlayer_Combat", path, unreal.NiagaraEffectType, unreal.NiagaraEffectTypeFactoryNew())
    except Exception:  # noqa: BLE001
        log("warn", "Effect Type à créer à la main : Niagara/Core/EFT_DemonSlayer_Combat")
    log("ok", f"modèles NS_Template_* prêts dans {path} (à remplir selon NIAGARA_RECIPES.md)")


# ===========================================================================
# 7. Scène de test
# ===========================================================================
ZONE_OF = {"Water": "WATER", "Fire": "FIRE", "Thunder": "THUNDER", "Wind": "WIND", "Mist": "MIST",
           "Blood": "BLOOD ARTS", "Ice": "BLOOD ARTS", "Shadow": "BLOOD ARTS", "Flower": "BLOOD ARTS"}


def zone_of(system):
    if system["name"].startswith("NS_Impact_"):
        return "IMPACTS"
    if system["archetype"] == "Trail":
        return "TRAILS"
    if system["archetype"] == "Projectile":
        return "PROJECTILES"
    return ZONE_OF.get(system["element"], "IMPACTS")


def build_test_map():
    level_path = f"{TEST_ROOT}/DemonSlayer_VFX_Test"
    les = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    eas = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    if EAL.does_asset_exist(level_path):
        les.load_level(level_path)
        for actor in eas.get_all_level_actors():
            if actor.get_actor_label().startswith("DSVFX_"):
                eas.destroy_actor(actor)
    else:
        les.new_level(level_path)

    def spawn(cls, label, loc, rot=unreal.Rotator(0, 0, 0)):
        actor = eas.spawn_actor_from_class(cls, loc, rot)
        actor.set_actor_label("DSVFX_" + label)
        return actor

    floor = spawn(unreal.StaticMeshActor, "Floor", unreal.Vector(0, 0, 0))
    floor.static_mesh_component.set_static_mesh(EAL.load_asset("/Engine/BasicShapes/Plane"))
    floor.set_actor_scale3d(unreal.Vector(200, 200, 1))
    spawn(unreal.DirectionalLight, "Sun", unreal.Vector(0, 0, 1000), unreal.Rotator(0, -50, 30))
    spawn(unreal.SkyLight, "Sky", unreal.Vector(0, 0, 800))

    zones = CATALOG["zones"]
    per_zone = {z: [] for z in zones}
    for s in CATALOG["systems"]:
        per_zone[zone_of(s)].append(s)
    placed, missing = 0, []
    for zi, zone in enumerate(zones):
        y = zi * 1500 - len(zones) * 750
        label = spawn(unreal.TextRenderActor, "Zone_" + zone.replace(" ", ""), unreal.Vector(-400, y, 300), unreal.Rotator(0, 0, 0))
        comp = label.get_editor_property("text_render")
        comp.set_editor_property("text", zone)
        comp.set_editor_property("world_size", 120)
        for si, s in enumerate(per_zone[zone]):
            loc = unreal.Vector(si * 700, y, 100)
            asset_path = f"/Game/{s['folder']}/{s['name']}"
            tag = spawn(unreal.TextRenderActor, "Label_" + s["name"], unreal.Vector(si * 700, y - 300, 20), unreal.Rotator(0, 90, 0))
            tc = tag.get_editor_property("text_render")
            tc.set_editor_property("world_size", 30)
            if EAL.does_asset_exist(asset_path):
                actor = eas.spawn_actor_from_object(EAL.load_asset(asset_path), loc, unreal.Rotator(0, 0, 0))
                actor.set_actor_label("DSVFX_" + s["name"])
                tc.set_editor_property("text", s["name"])
                placed += 1
            else:
                tc.set_editor_property("text", s["name"] + " (a construire)")
                missing.append(s["name"])
    les.save_current_level()
    log("ok", f"scène de test : {placed} systèmes placés, {len(missing)} à construire")
    return missing


# ===========================================================================
# 8. Vérification d'export
# ===========================================================================
ALLOWED_ENGINE = ("/Engine/Functions", "/Engine/BasicShapes", "/Engine/ArtTools", "/Engine/EngineMaterials")
ALLOWED_PREFIX = (ROOT, "/Niagara/", "/Script/") + ALLOWED_ENGINE


def verify_export():
    registry = unreal.AssetRegistryHelpers.get_asset_registry()
    options = unreal.AssetRegistryDependencyOptions(include_soft_package_references=True, include_hard_package_references=True)
    bad = 0
    for asset_path in EAL.list_assets(ROOT, recursive=True, include_folder=False):
        package = asset_path.split(".")[0]
        deps = registry.get_dependencies(package, options) or []
        for dep in deps:
            dep = str(dep)
            if not dep.startswith(ALLOWED_PREFIX):
                bad += 1
                log("error", f"dépendance non exportable : {package} -> {dep}")
    for s in CATALOG["systems"]:
        if not EAL.does_asset_exist(f"/Game/{s['folder']}/{s['name']}"):
            log("warn", f"système manquant (Assets.toml le référence) : {s['name']}")
    if bad == 0:
        log("ok", "aucune dépendance hors du pack (prêt pour la cuisson)")


# ===========================================================================
def main():
    make_folders()
    import_textures()
    import_meshes()
    build_masters()
    build_instances()
    build_niagara_templates()
    build_test_map()
    verify_export()
    unreal.EditorAssetLibrary.save_directory(ROOT, only_if_is_dirty=True, recursive=True)
    unreal.log("[DSVFX] ===== RÉSUMÉ =====")
    unreal.log(f"[DSVFX] OK : {len(REPORT['ok'])} | avertissements : {len(REPORT['warn'])} | erreurs : {len(REPORT['error'])}")
    for msg in REPORT["error"]:
        unreal.log_error("[DSVFX] " + msg)


main()
