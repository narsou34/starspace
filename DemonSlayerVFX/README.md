# Demon Slayer VFX Pack — kit de production Unreal / Niagara pour nanos world

Kit **original** (aucun fichier extrait d'un autre serveur) pour produire l'Asset Pack Niagara
`demonslayer-vfx` utilisé par le gamemode **Demon Slayer RP**.

> **Ce qui est déjà fait** : sources (textures, maillages), matériaux VFX, Material Instances,
> arborescence, scène de test, vérification d'export, `Assets.toml`, documentation de chaque VFX
> et branchement complet dans le gamemode.
> **Ce qu'il reste à faire dans l'éditeur** : l'intérieur des Niagara Systems (émetteurs et modules),
> en suivant `Docs/NIAGARA_RECIPES.md`. Un `.uasset` Niagara ne peut être créé que dans l'éditeur
> Unreal : aucun outil externe ne peut l'écrire.

---

## Contenu

```
DemonSlayerVFX/
├── README.md                   ce guide
├── Tools/
│   ├── generate_sources.py     génère Source/ (textures + maillages), sans Unreal
│   └── vfx_catalog.py          catalogue unique -> docs, Assets.toml, catalog.json, table Lua du gamemode
├── Source/
│   ├── Textures/               33 textures : Noise/ Masks/ Trails/ Particles/ (flipbooks) Distortion/
│   └── Meshes/                 16 maillages OBJ : coupes 120/180/270/360°, croissant penché,
│                               anneaux, vortex (cylindre/cône torsadés), vague déferlante,
│                               sphère, cône, pic de glace, tête + segment de dragon, pétale
├── Unreal/
│   ├── ue_setup_pack.py        script Python de l'éditeur : construit tout le projet
│   └── catalog.json            données lues par le script
├── AssetPack/
│   └── Assets.toml             configuration de l'Asset Pack nanos world (66 systèmes, 16 maillages, 85 MI)
└── Docs/
    ├── VFX_CATALOG.md          fiche de CHAQUE VFX (nom, type, utilisation, paramètres, durée,
    │                           performance, asset principal, dépendances)
    └── NIAGARA_RECIPES.md      recettes Niagara : 12 archétypes, émetteur par émetteur
```

Arborescence créée dans Unreal (`Content/DemonSlayerVFX/`) :

```
Niagara/   Core Water Fire Thunder Wind Mist BloodArts Impacts Trails Projectiles Environment
Materials/ Core Water Fire Energy Thunder Blood Mist
Meshes/    Slashes Waves Rings Energy Water Fire
Textures/  Noise Masks Distortion Trails Particles
Systems/   Water Fire Thunder Wind Mist BloodArts
```
La scène de test est dans `Content/DemonSlayerVFX_Test/` (en dehors du pack : elle n'est pas cuite).

---

## Étape 1 — Installer l'environnement (une fois)

1. Unreal Engine **5.7** (Epic Games Launcher).
2. L'**ADK nanos world** : <https://github.com/nanos-world/assets-development-kit> (releases), qui contient
   le plugin **Forge**. Ouvrir le projet ADK.
3. *Edit > Plugins* : activer **Python Editor Script Plugin** et **Editor Scripting Utilities**, redémarrer.

## Étape 2 — Construire le projet automatiquement

1. Copier tout le dossier `DemonSlayerVFX/` (ce kit) n'importe où sur le PC.
2. Dans Unreal : *Tools > Execute Python Script...* > `DemonSlayerVFX/Unreal/ue_setup_pack.py`.
3. Lire le résumé dans *Output Log* (filtre `DSVFX`) :
   - dossiers, 33 textures (réglages *Masks*, sans sRGB, groupe *Effects*, 1024 max, sans streaming),
   - 16 maillages (collisions supprimées, Nanite désactivé),
   - 7 matériaux maîtres construits nœud par nœud,
   - 85 Material Instances (couleurs, émissif, textures de chaque élément),
   - 12 modèles vides `NS_Template_<Archétype>` + Effect Type `EFT_DemonSlayer_Combat`,
   - scène `DemonSlayer_VFX_Test` avec les zones WATER, FIRE, THUNDER, WIND, MIST, BLOOD ARTS,
     IMPACTS, TRAILS, PROJECTILES,
   - vérification : toute dépendance hors du pack est signalée en rouge.

Le script peut être relancé à tout moment : il met à jour et replace les systèmes construits dans la scène.

| Matériau maître | Usage |
| --- | --- |
| `M_VFX_Sprite_Additive` | flash, étincelles, gouttes, braises (érosion Dynamic Parameter, Depth Fade) |
| `M_VFX_Sprite_Translucent` | fumée, brume, poussière (flipbook + bruit panné) |
| `M_VFX_Sprite_Flipbook` | flammes, éclaboussures, éclairs, explosions (sub-UV avec fondu) |
| `M_VFX_Mesh_Slash` | coupes, anneaux, ondes (balayage le long de l'arc, cœur chaud, érosion) |
| `M_VFX_Ribbon` | traînées de lame et spirales (texture pannée, bruit) |
| `M_VFX_Mesh_Energy` | vague, dragon, boule, vortex (fresnel, caustiques, Depth Fade) |
| `M_VFX_Distortion` | chaleur, onde de choc (réfraction) |

Chaque Material Instance expose : `Color`, `SecondaryColor`, `Emissive`, `PanSpeed`, `Opacity`,
`Tiling`, `FresnelPower`, `Strength` et ses textures.

## Étape 3 — Construire les Niagara Systems

Suivre `Docs/NIAGARA_RECIPES.md` :
1. Remplir les **12 modèles** `Niagara/Core/NS_Template_<Archétype>` (un par famille : coupe,
   traînée, impact, projectile, élan, vague, vortex, créature, explosion, aura, pics, éclair),
   avec les **paramètres utilisateur standard** (`Color`, `SecondaryColor`, `Scale`, `Intensity`,
   `Duration`, `Speed`, `SpawnScale`, `Width`, `Direction`, `EndPoint`).
2. **Dupliquer** chaque modèle pour chaque système de `Docs/VFX_CATALOG.md`, le ranger dans
   `Systems/<Élément>/` et ne changer que les Material Instances, maillages et valeurs indiqués.
   Ordre conseillé : `NS_VFX_Water_Slash` → `NS_VFX_Water_Trail` → `NS_Impact_*` → le reste de l'Eau → les autres éléments.
3. Tester dans `DemonSlayer_VFX_Test` (relancer le script pour placer les nouveaux systèmes) : apparition,
   mouvement, timing, impact, disparition, taille, lisibilité, *Stat Niagara* pour les performances.

Règles qui garantissent que le pack fonctionne dans nanos world (détail dans les recettes) :
- pas de Data Interface sur le personnage ou la scène (squelette, acteurs, collisions CPU) ;
- aucune texture ni matériau de `/Engine/` (sauf `/Engine/Functions`, `/Engine/BasicShapes`,
  `/Engine/ArtTools`, `/Engine/EngineMaterials`) ou du contenu par défaut de Niagara ;
- systèmes finis en *Loop Once* + *Inactive Response = Complete* ; *Fixed Bounds* ; Effect Type
  avec Cull Distance 9000 et LOD de distance.

## Étape 4 — Cuire et installer l'Asset Pack

1. *Project Settings > Packaging* : *Additional Asset Directories to Cook* = `DemonSlayerVFX`
   (ne pas cuire `DemonSlayerVFX_Test`). Cuire avec Forge (*Window > Nanos World Forge > Cook*)
   ou *Platforms > Windows > Cook Content*.
2. Créer `Server/Assets/demonslayer-vfx/`, y copier le dossier cuit `DemonSlayerVFX/`
   (`.uasset`, `.uexp`, `.ubulk`) et `AssetPack/Assets.toml`. Ne rien renommer après la cuisson.
   Si vous ajoutez ou renommez des systèmes : modifier `Tools/vfx_catalog.py` puis `python vfx_catalog.py`.
3. Dans `Packages/demon-slayer-rp/Package.toml` : `assets_requirements = [ "demonslayer-vfx" ]`.
4. Dans `Packages/demon-slayer-rp/Shared/Config/Vfx.lua` : `Pack = { Enabled = true, ... }`.
5. En jeu, console du jeu : `ds_vfxpack on|off` pour comparer avec les effets intégrés.

## Comment le gamemode utilise le pack

`Client/Systems/VFX/Core/VFXPack.lua` remplace chaque rôle d'effet par le système de l'élément
(table générée `Shared/Config/VfxPackCatalog.lua`) et envoie les paramètres utilisateur :

| Événement du gamemode | Système joué (ex. Eau) |
| --- | --- |
| coupe (combo, coupe d'arrivée d'élan...) | `NS_VFX_Water_Slash`, orienté dans le plan du coup (horizontal, montant, descendant, diagonal) |
| traînée de lame (attachée à `hand_r`) | `NS_VFX_Water_Trail` |
| impact sur une cible | `NS_VFX_Water_Impact` (+ `NS_Impact_Large` / `NS_Impact_Massive` selon les dégâts) |
| projectile (déplacé jusqu'à son point d'arrivée) | `NS_VFX_Water_Ball` |
| élan | `NS_VFX_Water_Dash` (`EndPoint` = arrivée) |
| vague / tsunami / tourbillon / dragon | `NS_VFX_Water_Wave` / `_Tsunami` / `_Tornado` / `_Dragon` |
| explosions et signatures | `_Burst`, `_Explosion`, `_Spikes`, `_Aura`... |

Sans le pack (ou `Enabled = false`), les effets intégrés (textures peintes + particules nanos)
restent utilisés : rien ne casse.

## Régénérer les sources

```
pip install numpy pillow scipy
python Tools/generate_sources.py     # textures + maillages
python Tools/vfx_catalog.py          # docs, Assets.toml, catalog.json, table Lua
```
