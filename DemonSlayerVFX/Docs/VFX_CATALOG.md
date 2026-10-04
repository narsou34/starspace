# Demon Slayer VFX Pack — Catalogue des VFX

Asset Pack nanos world : `demonslayer-vfx` · dossier Unreal : `Content/DemonSlayerVFX/` · Unreal 5.7.0

Chaque système expose les **mêmes paramètres utilisateur** (Niagara `User.*`, réglables depuis nanos world avec `Particle:SetParameter*`) :

| Paramètre | Type | Rôle |
| --- | --- | --- |
| `Color` | LinearColor | Couleur principale (HDR : > 1 = brille) |
| `SecondaryColor` | LinearColor | Couleur secondaire (cœur, écume, braises) |
| `Scale` | Float | Taille globale (1 = normal) |
| `Intensity` | Float | Luminosité / émissif (1 = normal) |
| `Duration` | Float | Multiplicateur de durée (1 = normal) |
| `Speed` | Float | Multiplicateur de vitesse (1 = normal) |
| `SpawnScale` | Float | Multiplicateur du nombre de particules (LOD manuel, 0..1) |
| `Width` | Float | Largeur des traînées / rubans (cm) |
| `Direction` | Vector | Direction de l'attaque (monde), défaut = avant de l'acteur |
| `EndPoint` | Vector | Point d'arrivée (éclairs, élans, projectiles) |

Recettes de construction (émetteurs, modules, valeurs) : [NIAGARA_RECIPES.md](NIAGARA_RECIPES.md).


## Core

### NS_Core_Trail
- **Nom** : `NS_Core_Trail` (`demonslayer-vfx::NS_Core_Trail`)
- **Type** : Niagara System — archétype **Trail** (Traînée continue attachée à la lame (socket hand_r) ou à un projectile.)
- **Utilisation** : Traînée neutre (teinte via User.Color) pour toute arme ou acteur.
- **Particularités** : recette de l’archétype sans changement
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : boucle tant que l'acteur existe (désactiver = fin)
- **Performance** : 1 ruban (≈ 40 segments) + 20 sprites/s · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Niagara/Core/NS_Core_Trail`
- **Dépendances** : MI_VFX_Core_Slash, MI_VFX_Core_Trail, MI_VFX_Core_Spark, MI_VFX_Core_Glow, MI_VFX_Core_Flipbook, MI_VFX_Core_Smoke, MI_VFX_Core_Mesh, MI_VFX_Core_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_Core_RibbonTrail
- **Nom** : `NS_Core_RibbonTrail` (`demonslayer-vfx::NS_Core_RibbonTrail`)
- **Type** : Niagara System — archétype **Trail** (Traînée continue attachée à la lame (socket hand_r) ou à un projectile.)
- **Utilisation** : Ruban large et doux (rémanence de mouvement du corps).
- **Particularités** : recette de l’archétype sans changement
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : boucle tant que l'acteur existe (désactiver = fin)
- **Performance** : 1 ruban (≈ 40 segments) + 20 sprites/s · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Niagara/Core/NS_Core_RibbonTrail`
- **Dépendances** : MI_VFX_Core_Slash, MI_VFX_Core_Trail, MI_VFX_Core_Spark, MI_VFX_Core_Glow, MI_VFX_Core_Flipbook, MI_VFX_Core_Smoke, MI_VFX_Core_Mesh, MI_VFX_Core_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_Core_EnergyTrail
- **Nom** : `NS_Core_EnergyTrail` (`demonslayer-vfx::NS_Core_EnergyTrail`)
- **Type** : Niagara System — archétype **Trail** (Traînée continue attachée à la lame (socket hand_r) ou à un projectile.)
- **Utilisation** : Traînée d'énergie avec cœur blanc très lumineux.
- **Particularités** : recette de l’archétype sans changement
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : boucle tant que l'acteur existe (désactiver = fin)
- **Performance** : 1 ruban (≈ 40 segments) + 20 sprites/s · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Niagara/Core/NS_Core_EnergyTrail`
- **Dépendances** : MI_VFX_Core_Slash, MI_VFX_Core_Trail, MI_VFX_Core_Spark, MI_VFX_Core_Glow, MI_VFX_Core_Flipbook, MI_VFX_Core_Smoke, MI_VFX_Core_Mesh, MI_VFX_Core_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_Core_ElementTrail
- **Nom** : `NS_Core_ElementTrail` (`demonslayer-vfx::NS_Core_ElementTrail`)
- **Type** : Niagara System — archétype **Trail** (Traînée continue attachée à la lame (socket hand_r) ou à un projectile.)
- **Utilisation** : Traînée générique dont la texture de MI est remplacée par élément (base des _Trail).
- **Particularités** : recette de l’archétype sans changement
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : boucle tant que l'acteur existe (désactiver = fin)
- **Performance** : 1 ruban (≈ 40 segments) + 20 sprites/s · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Niagara/Core/NS_Core_ElementTrail`
- **Dépendances** : MI_VFX_Core_Slash, MI_VFX_Core_Trail, MI_VFX_Core_Spark, MI_VFX_Core_Glow, MI_VFX_Core_Flipbook, MI_VFX_Core_Smoke, MI_VFX_Core_Mesh, MI_VFX_Core_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_Core_Flash
- **Nom** : `NS_Core_Flash` (`demonslayer-vfx::NS_Core_Flash`)
- **Type** : Niagara System — archétype **Impact** (Impact à 4 tailles : flash + onde de choc + particules + élément + poussière + distorsion + éclats.)
- **Utilisation** : Flash seul (début d'attaque, contre).
- **Particularités** : Uniquement E_Flash + E_Distortion.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 0,5 (Small) → 1,6 s (Massive)
- **Performance** : Small ≈ 25, Medium ≈ 50, Large ≈ 90, Massive ≈ 150 particules · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Niagara/Core/NS_Core_Flash`
- **Dépendances** : MI_VFX_Core_Slash, MI_VFX_Core_Trail, MI_VFX_Core_Spark, MI_VFX_Core_Glow, MI_VFX_Core_Flipbook, MI_VFX_Core_Smoke, MI_VFX_Core_Mesh, MI_VFX_Core_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_Core_Shockwave
- **Nom** : `NS_Core_Shockwave` (`demonslayer-vfx::NS_Core_Shockwave`)
- **Type** : Niagara System — archétype **Impact** (Impact à 4 tailles : flash + onde de choc + particules + élément + poussière + distorsion + éclats.)
- **Utilisation** : Onde de choc au sol.
- **Particularités** : Uniquement E_Shockwave (2 ondes) + E_Distortion.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 0,5 (Small) → 1,6 s (Massive)
- **Performance** : Small ≈ 25, Medium ≈ 50, Large ≈ 90, Massive ≈ 150 particules · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Niagara/Core/NS_Core_Shockwave`
- **Dépendances** : MI_VFX_Core_Slash, MI_VFX_Core_Trail, MI_VFX_Core_Spark, MI_VFX_Core_Glow, MI_VFX_Core_Flipbook, MI_VFX_Core_Smoke, MI_VFX_Core_Mesh, MI_VFX_Core_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_Core_Distortion
- **Nom** : `NS_Core_Distortion` (`demonslayer-vfx::NS_Core_Distortion`)
- **Type** : Niagara System — archétype **Impact** (Impact à 4 tailles : flash + onde de choc + particules + élément + poussière + distorsion + éclats.)
- **Utilisation** : Distorsion seule (chaleur, onde).
- **Particularités** : Uniquement E_Distortion.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 0,5 (Small) → 1,6 s (Massive)
- **Performance** : Small ≈ 25, Medium ≈ 50, Large ≈ 90, Massive ≈ 150 particules · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Niagara/Core/NS_Core_Distortion`
- **Dépendances** : MI_VFX_Core_Slash, MI_VFX_Core_Trail, MI_VFX_Core_Spark, MI_VFX_Core_Glow, MI_VFX_Core_Flipbook, MI_VFX_Core_Smoke, MI_VFX_Core_Mesh, MI_VFX_Core_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_Core_SpeedLines
- **Nom** : `NS_Core_SpeedLines` (`demonslayer-vfx::NS_Core_SpeedLines`)
- **Type** : Niagara System — archétype **Dash** (Élan : départ (flash + gerbe), rémanence sur le trajet, lignes de vitesse, arrivée.)
- **Utilisation** : Lignes de vitesse seules (élan, sprint).
- **Particularités** : Uniquement E_SpeedLines.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 0,6 s
- **Performance** : ≈ 70 particules + 2 rubans · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Niagara/Core/NS_Core_SpeedLines`
- **Dépendances** : MI_VFX_Core_Slash, MI_VFX_Core_Trail, MI_VFX_Core_Spark, MI_VFX_Core_Glow, MI_VFX_Core_Flipbook, MI_VFX_Core_Smoke, MI_VFX_Core_Mesh, MI_VFX_Core_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_Core_Sparks
- **Nom** : `NS_Core_Sparks` (`demonslayer-vfx::NS_Core_Sparks`)
- **Type** : Niagara System — archétype **Impact** (Impact à 4 tailles : flash + onde de choc + particules + élément + poussière + distorsion + éclats.)
- **Utilisation** : Étincelles de lame (parade, choc de katanas).
- **Particularités** : Uniquement E_Burst (Velocity Cone 45°).
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 0,5 (Small) → 1,6 s (Massive)
- **Performance** : Small ≈ 25, Medium ≈ 50, Large ≈ 90, Massive ≈ 150 particules · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Niagara/Core/NS_Core_Sparks`
- **Dépendances** : MI_VFX_Core_Slash, MI_VFX_Core_Trail, MI_VFX_Core_Spark, MI_VFX_Core_Glow, MI_VFX_Core_Flipbook, MI_VFX_Core_Smoke, MI_VFX_Core_Mesh, MI_VFX_Core_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_Core_Debris
- **Nom** : `NS_Core_Debris` (`demonslayer-vfx::NS_Core_Debris`)
- **Type** : Niagara System — archétype **Impact** (Impact à 4 tailles : flash + onde de choc + particules + élément + poussière + distorsion + éclats.)
- **Utilisation** : Débris et poussière au sol.
- **Particularités** : E_Dust + E_Debris.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 0,5 (Small) → 1,6 s (Massive)
- **Performance** : Small ≈ 25, Medium ≈ 50, Large ≈ 90, Massive ≈ 150 particules · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Niagara/Core/NS_Core_Debris`
- **Dépendances** : MI_VFX_Core_Slash, MI_VFX_Core_Trail, MI_VFX_Core_Spark, MI_VFX_Core_Glow, MI_VFX_Core_Flipbook, MI_VFX_Core_Smoke, MI_VFX_Core_Mesh, MI_VFX_Core_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion


## Impacts

### NS_Impact_Small
- **Nom** : `NS_Impact_Small` (`demonslayer-vfx::NS_Impact_Small`)
- **Type** : Niagara System — archétype **Impact** (Impact à 4 tailles : flash + onde de choc + particules + élément + poussière + distorsion + éclats.)
- **Utilisation** : Petit coup (combo, tick de zone).
- **Particularités** : Flash + E_Burst(20) + E_Element.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 0,5 s
- **Performance** : ≈ 25 particules · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Niagara/Impacts/NS_Impact_Small`
- **Dépendances** : MI_VFX_Core_Slash, MI_VFX_Core_Trail, MI_VFX_Core_Spark, MI_VFX_Core_Glow, MI_VFX_Core_Flipbook, MI_VFX_Core_Smoke, MI_VFX_Core_Mesh, MI_VFX_Core_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_Impact_Medium
- **Nom** : `NS_Impact_Medium` (`demonslayer-vfx::NS_Impact_Medium`)
- **Type** : Niagara System — archétype **Impact** (Impact à 4 tailles : flash + onde de choc + particules + élément + poussière + distorsion + éclats.)
- **Utilisation** : Coup normal.
- **Particularités** : + onde + distorsion.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 0,8 s
- **Performance** : ≈ 50 particules · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Niagara/Impacts/NS_Impact_Medium`
- **Dépendances** : MI_VFX_Core_Slash, MI_VFX_Core_Trail, MI_VFX_Core_Spark, MI_VFX_Core_Glow, MI_VFX_Core_Flipbook, MI_VFX_Core_Smoke, MI_VFX_Core_Mesh, MI_VFX_Core_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_Impact_Large
- **Nom** : `NS_Impact_Large` (`demonslayer-vfx::NS_Impact_Large`)
- **Type** : Niagara System — archétype **Impact** (Impact à 4 tailles : flash + onde de choc + particules + élément + poussière + distorsion + éclats.)
- **Utilisation** : Coup puissant / fin de combo.
- **Particularités** : + poussière + débris + 2e onde.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 1,2 s
- **Performance** : ≈ 90 particules · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Niagara/Impacts/NS_Impact_Large`
- **Dépendances** : MI_VFX_Core_Slash, MI_VFX_Core_Trail, MI_VFX_Core_Spark, MI_VFX_Core_Glow, MI_VFX_Core_Flipbook, MI_VFX_Core_Smoke, MI_VFX_Core_Mesh, MI_VFX_Core_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_Impact_Massive
- **Nom** : `NS_Impact_Massive` (`demonslayer-vfx::NS_Impact_Massive`)
- **Type** : Niagara System — archétype **Impact** (Impact à 4 tailles : flash + onde de choc + particules + élément + poussière + distorsion + éclats.)
- **Utilisation** : Ultime / explosion finale.
- **Particularités** : + anneau de 6 gerbes + onde x3 + caméra.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 1,6 s
- **Performance** : ≈ 150 particules · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Niagara/Impacts/NS_Impact_Massive`
- **Dépendances** : MI_VFX_Core_Slash, MI_VFX_Core_Trail, MI_VFX_Core_Spark, MI_VFX_Core_Glow, MI_VFX_Core_Flipbook, MI_VFX_Core_Smoke, MI_VFX_Core_Mesh, MI_VFX_Core_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion


## Water

### NS_VFX_Water_Slash
- **Nom** : `NS_VFX_Water_Slash` (`demonslayer-vfx::NS_VFX_Water_Slash`)
- **Type** : Niagara System — archétype **Slash** (Coupe de lame : arc maillé balayé + ruban + flash + gerbe + distorsion + dissipation.)
- **Utilisation** : Toute coupe du Souffle de l'Eau (formes 1, 2, 4...).
- **Particularités** : Gouttelettes avec gravité, écume (MI_Water_Spark), brume bleutée en dissipation.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 0,45 à 0,8 s
- **Performance** : ≈ 60 particules (CPU), 1 maillage · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/Water/NS_VFX_Water_Slash`
- **Dépendances** : MI_VFX_Water_Slash, MI_VFX_Water_Trail, MI_VFX_Water_Spark, MI_VFX_Water_Glow, MI_VFX_Water_Flipbook, MI_VFX_Water_Smoke, MI_VFX_Water_Mesh, MI_VFX_Water_Ring ; maillage : SM_VFX_Slash_Arc_180 ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Water_Trail
- **Nom** : `NS_VFX_Water_Trail` (`demonslayer-vfx::NS_VFX_Water_Trail`)
- **Type** : Niagara System — archétype **Trail** (Traînée continue attachée à la lame (socket hand_r) ou à un projectile.)
- **Utilisation** : Traînée d'eau attachée au katana (hand_r) pendant les techniques.
- **Particularités** : E_Bits = gouttes qui tombent (Gravity -600).
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : boucle tant que l'acteur existe (désactiver = fin)
- **Performance** : 1 ruban (≈ 40 segments) + 20 sprites/s · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/Water/NS_VFX_Water_Trail`
- **Dépendances** : MI_VFX_Water_Slash, MI_VFX_Water_Trail, MI_VFX_Water_Spark, MI_VFX_Water_Glow, MI_VFX_Water_Flipbook, MI_VFX_Water_Smoke, MI_VFX_Water_Mesh, MI_VFX_Water_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Water_Wave
- **Nom** : `NS_VFX_Water_Wave` (`demonslayer-vfx::NS_VFX_Water_Wave`)
- **Type** : Niagara System — archétype **Wave** (Vague / tsunami : mur maillé qui AVANCE + mousse + gouttelettes + éclaboussures + brume + vaguelettes.)
- **Utilisation** : [Q] Grande vague.
- **Particularités** : 1 maillage, Speed 900.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 1,6 s
- **Performance** : 3..6 maillages + ≈ 120 sprites (GPU pour la mousse) · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/Water/NS_VFX_Water_Wave`
- **Dépendances** : MI_VFX_Water_Slash, MI_VFX_Water_Trail, MI_VFX_Water_Spark, MI_VFX_Water_Glow, MI_VFX_Water_Flipbook, MI_VFX_Water_Smoke, MI_VFX_Water_Mesh, MI_VFX_Water_Ring ; maillage : SM_VFX_Wave_Curl ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Water_Tsunami
- **Nom** : `NS_VFX_Water_Tsunami` (`demonslayer-vfx::NS_VFX_Water_Tsunami`)
- **Type** : Niagara System — archétype **Wave** (Vague / tsunami : mur maillé qui AVANCE + mousse + gouttelettes + éclaboussures + brume + vaguelettes.)
- **Utilisation** : [X] Tsunami (ultime).
- **Particularités** : 3 maillages côte à côte, Scale 2,5, montée 0,6 s, Speed 600, explosion massive finale.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 3 s
- **Performance** : ≈ 250 particules (GPU) · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/Water/NS_VFX_Water_Tsunami`
- **Dépendances** : MI_VFX_Water_Slash, MI_VFX_Water_Trail, MI_VFX_Water_Spark, MI_VFX_Water_Glow, MI_VFX_Water_Flipbook, MI_VFX_Water_Smoke, MI_VFX_Water_Mesh, MI_VFX_Water_Ring ; maillage : SM_VFX_Wave_Curl ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Water_Tornado
- **Nom** : `NS_VFX_Water_Tornado` (`demonslayer-vfx::NS_VFX_Water_Tornado`)
- **Type** : Niagara System — archétype **Vortex** (Tornade / tourbillon : cylindres torsadés en rotation + rubans en spirale + gouttes + distorsion.)
- **Utilisation** : [E] Tourbillon.
- **Particularités** : Rubans en spirale bleus + gouttes aspirées vers l'axe.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 2,5 s (boucle si attaché)
- **Performance** : 2 maillages + 6 rubans + ≈ 120 sprites · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/Water/NS_VFX_Water_Tornado`
- **Dépendances** : MI_VFX_Water_Slash, MI_VFX_Water_Trail, MI_VFX_Water_Spark, MI_VFX_Water_Glow, MI_VFX_Water_Flipbook, MI_VFX_Water_Smoke, MI_VFX_Water_Mesh, MI_VFX_Water_Ring ; maillage : SM_VFX_Vortex_Cone ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Water_Ball
- **Nom** : `NS_VFX_Water_Ball` (`demonslayer-vfx::NS_VFX_Water_Ball`)
- **Type** : Niagara System — archétype **Projectile** (Projectile = cœur + aura + traînée + gouttes ; l'impact est un système séparé (NS_VFX_<E>_Impact ou _Explosion).)
- **Utilisation** : [R] Prison d'eau (sphère lancée).
- **Particularités** : E_Core = bulle (Fresnel fort) ; impact : NS_VFX_Water_Explosion.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : boucle (le script déplace/détruit le projectile)
- **Performance** : 1 maillage + 1 ruban + ≈ 40 sprites/s · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/Water/NS_VFX_Water_Ball`
- **Dépendances** : MI_VFX_Water_Slash, MI_VFX_Water_Trail, MI_VFX_Water_Spark, MI_VFX_Water_Glow, MI_VFX_Water_Flipbook, MI_VFX_Water_Smoke, MI_VFX_Water_Mesh, MI_VFX_Water_Ring ; maillage : SM_VFX_Sphere ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Water_Dragon
- **Nom** : `NS_VFX_Water_Dragon` (`demonslayer-vfx::NS_VFX_Water_Dragon`)
- **Type** : Niagara System — archétype **Beast** (Créature (dragon / tigre / serpent) : tête maillée + segments + rubans + brume, trajectoire sinueuse.)
- **Utilisation** : [C] Dragon changeant.
- **Particularités** : Écailles = segments + MI_Water_Slash ; moustaches en rubans ; brume.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 2,2 s
- **Performance** : 1 tête + 10..14 segments + 3 rubans + ≈ 150 sprites · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/Water/NS_VFX_Water_Dragon`
- **Dépendances** : MI_VFX_Water_Slash, MI_VFX_Water_Trail, MI_VFX_Water_Spark, MI_VFX_Water_Glow, MI_VFX_Water_Flipbook, MI_VFX_Water_Smoke, MI_VFX_Water_Mesh, MI_VFX_Water_Ring ; maillage : SM_VFX_Dragon_Head ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Water_Explosion
- **Nom** : `NS_VFX_Water_Explosion` (`demonslayer-vfx::NS_VFX_Water_Explosion`)
- **Type** : Niagara System — archétype **Burst** (Explosion / jaillissement élémentaire (sans projectile).)
- **Utilisation** : Éclatement de la prison, fin de tourbillon.
- **Particularités** : Flipbook éclaboussures + sphère d'eau qui s'ouvre.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 1 à 1,8 s
- **Performance** : ≈ 120 particules + 1..2 maillages · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/Water/NS_VFX_Water_Explosion`
- **Dépendances** : MI_VFX_Water_Slash, MI_VFX_Water_Trail, MI_VFX_Water_Spark, MI_VFX_Water_Glow, MI_VFX_Water_Flipbook, MI_VFX_Water_Smoke, MI_VFX_Water_Mesh, MI_VFX_Water_Ring ; maillage : SM_VFX_Sphere ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Water_Impact
- **Nom** : `NS_VFX_Water_Impact` (`demonslayer-vfx::NS_VFX_Water_Impact`)
- **Type** : Niagara System — archétype **Impact** (Impact à 4 tailles : flash + onde de choc + particules + élément + poussière + distorsion + éclats.)
- **Utilisation** : Impact d'eau (variante WaterImpact).
- **Particularités** : E_Element = T_VFX_Flip_Splash_4x4.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 0,5 (Small) → 1,6 s (Massive)
- **Performance** : Small ≈ 25, Medium ≈ 50, Large ≈ 90, Massive ≈ 150 particules · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/Water/NS_VFX_Water_Impact`
- **Dépendances** : MI_VFX_Water_Slash, MI_VFX_Water_Trail, MI_VFX_Water_Spark, MI_VFX_Water_Glow, MI_VFX_Water_Flipbook, MI_VFX_Water_Smoke, MI_VFX_Water_Mesh, MI_VFX_Water_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Water_Dash
- **Nom** : `NS_VFX_Water_Dash` (`demonslayer-vfx::NS_VFX_Water_Dash`)
- **Type** : Niagara System — archétype **Dash** (Élan : départ (flash + gerbe), rémanence sur le trajet, lignes de vitesse, arrivée.)
- **Utilisation** : [F] Courant fulgurant.
- **Particularités** : Rémanence d'eau + éclaboussures au départ et à l'arrivée.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 0,6 s
- **Performance** : ≈ 70 particules + 2 rubans · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/Water/NS_VFX_Water_Dash`
- **Dépendances** : MI_VFX_Water_Slash, MI_VFX_Water_Trail, MI_VFX_Water_Spark, MI_VFX_Water_Glow, MI_VFX_Water_Flipbook, MI_VFX_Water_Smoke, MI_VFX_Water_Mesh, MI_VFX_Water_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion


## Fire

### NS_VFX_Fire_Slash
- **Nom** : `NS_VFX_Fire_Slash` (`demonslayer-vfx::NS_VFX_Fire_Slash`)
- **Type** : Niagara System — archétype **Slash** (Coupe de lame : arc maillé balayé + ruban + flash + gerbe + distorsion + dissipation.)
- **Utilisation** : Coupes du Souffle de la Flamme.
- **Particularités** : Langues de feu (flipbook) le long de l'arc + braises (Gravity +50) + chaleur (distorsion).
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 0,45 à 0,8 s
- **Performance** : ≈ 60 particules (CPU), 1 maillage · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/Fire/NS_VFX_Fire_Slash`
- **Dépendances** : MI_VFX_Fire_Slash, MI_VFX_Fire_Trail, MI_VFX_Fire_Spark, MI_VFX_Fire_Glow, MI_VFX_Fire_Flipbook, MI_VFX_Fire_Smoke, MI_VFX_Fire_Mesh, MI_VFX_Fire_Ring ; maillage : SM_VFX_Slash_Arc_180 ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Fire_Trail
- **Nom** : `NS_VFX_Fire_Trail` (`demonslayer-vfx::NS_VFX_Fire_Trail`)
- **Type** : Niagara System — archétype **Trail** (Traînée continue attachée à la lame (socket hand_r) ou à un projectile.)
- **Utilisation** : Traînée de flammes sur la lame.
- **Particularités** : E_Bits = braises qui montent (Gravity +80).
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : boucle tant que l'acteur existe (désactiver = fin)
- **Performance** : 1 ruban (≈ 40 segments) + 20 sprites/s · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/Fire/NS_VFX_Fire_Trail`
- **Dépendances** : MI_VFX_Fire_Slash, MI_VFX_Fire_Trail, MI_VFX_Fire_Spark, MI_VFX_Fire_Glow, MI_VFX_Fire_Flipbook, MI_VFX_Fire_Smoke, MI_VFX_Fire_Mesh, MI_VFX_Fire_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Fire_Burst
- **Nom** : `NS_VFX_Fire_Burst` (`demonslayer-vfx::NS_VFX_Fire_Burst`)
- **Type** : Niagara System — archétype **Burst** (Explosion / jaillissement élémentaire (sans projectile).)
- **Utilisation** : Univers flamboyant (jaillissement).
- **Particularités** : Colonnes de flammes (flipbook, Velocity +Z).
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 1 à 1,8 s
- **Performance** : ≈ 120 particules + 1..2 maillages · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/Fire/NS_VFX_Fire_Burst`
- **Dépendances** : MI_VFX_Fire_Slash, MI_VFX_Fire_Trail, MI_VFX_Fire_Spark, MI_VFX_Fire_Glow, MI_VFX_Fire_Flipbook, MI_VFX_Fire_Smoke, MI_VFX_Fire_Mesh, MI_VFX_Fire_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Fire_Explosion
- **Nom** : `NS_VFX_Fire_Explosion` (`demonslayer-vfx::NS_VFX_Fire_Explosion`)
- **Type** : Niagara System — archétype **Burst** (Explosion / jaillissement élémentaire (sans projectile).)
- **Utilisation** : Explosion de feu (ultime Purgatoire, fin de projectile).
- **Particularités** : Boule de feu + fumée noire + onde orange.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 1 à 1,8 s
- **Performance** : ≈ 120 particules + 1..2 maillages · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/Fire/NS_VFX_Fire_Explosion`
- **Dépendances** : MI_VFX_Fire_Slash, MI_VFX_Fire_Trail, MI_VFX_Fire_Spark, MI_VFX_Fire_Glow, MI_VFX_Fire_Flipbook, MI_VFX_Fire_Smoke, MI_VFX_Fire_Mesh, MI_VFX_Fire_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Fire_Dragon
- **Nom** : `NS_VFX_Fire_Dragon` (`demonslayer-vfx::NS_VFX_Fire_Dragon`)
- **Type** : Niagara System — archétype **Beast** (Créature (dragon / tigre / serpent) : tête maillée + segments + rubans + brume, trajectoire sinueuse.)
- **Utilisation** : Tigre / dragon de flammes (forme 5, Purgatoire).
- **Particularités** : Corps en flipbooks de flammes, tête maillée MI_Fire_Mesh.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 1,6 à 2,2 s
- **Performance** : 1 tête + 10..14 segments + 3 rubans + ≈ 150 sprites · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/Fire/NS_VFX_Fire_Dragon`
- **Dépendances** : MI_VFX_Fire_Slash, MI_VFX_Fire_Trail, MI_VFX_Fire_Spark, MI_VFX_Fire_Glow, MI_VFX_Fire_Flipbook, MI_VFX_Fire_Smoke, MI_VFX_Fire_Mesh, MI_VFX_Fire_Ring ; maillage : SM_VFX_Dragon_Head ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Fire_Impact
- **Nom** : `NS_VFX_Fire_Impact` (`demonslayer-vfx::NS_VFX_Fire_Impact`)
- **Type** : Niagara System — archétype **Impact** (Impact à 4 tailles : flash + onde de choc + particules + élément + poussière + distorsion + éclats.)
- **Utilisation** : Impact de feu (FireImpact).
- **Particularités** : E_Element = T_VFX_Flip_Fire_8x8, fumée.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 0,5 (Small) → 1,6 s (Massive)
- **Performance** : Small ≈ 25, Medium ≈ 50, Large ≈ 90, Massive ≈ 150 particules · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/Fire/NS_VFX_Fire_Impact`
- **Dépendances** : MI_VFX_Fire_Slash, MI_VFX_Fire_Trail, MI_VFX_Fire_Spark, MI_VFX_Fire_Glow, MI_VFX_Fire_Flipbook, MI_VFX_Fire_Smoke, MI_VFX_Fire_Mesh, MI_VFX_Fire_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion


## Thunder

### NS_VFX_Thunder_Dash
- **Nom** : `NS_VFX_Thunder_Dash` (`demonslayer-vfx::NS_VFX_Thunder_Dash`)
- **Type** : Niagara System — archétype **Dash** (Élan : départ (flash + gerbe), rémanence sur le trajet, lignes de vitesse, arrivée.)
- **Utilisation** : Éclair foudroyant (le joueur disparaît presque).
- **Particularités** : Durée 0,3 s ; 3 beams du départ à EndPoint ; flash énorme au départ ; rémanence 0,12 s seulement.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 0,4 s
- **Performance** : ≈ 70 particules + 2 rubans · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/Thunder/NS_VFX_Thunder_Dash`
- **Dépendances** : MI_VFX_Thunder_Slash, MI_VFX_Thunder_Trail, MI_VFX_Thunder_Spark, MI_VFX_Thunder_Glow, MI_VFX_Thunder_Flipbook, MI_VFX_Thunder_Smoke, MI_VFX_Thunder_Mesh, MI_VFX_Thunder_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Thunder_Slash
- **Nom** : `NS_VFX_Thunder_Slash` (`demonslayer-vfx::NS_VFX_Thunder_Slash`)
- **Type** : Niagara System — archétype **Slash** (Coupe de lame : arc maillé balayé + ruban + flash + gerbe + distorsion + dissipation.)
- **Utilisation** : Coupes de la Foudre.
- **Particularités** : Arc + 4 beams courts le long de l'arc ; étincelles très rapides (Lifetime 0,15).
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 0,45 à 0,8 s
- **Performance** : ≈ 60 particules (CPU), 1 maillage · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/Thunder/NS_VFX_Thunder_Slash`
- **Dépendances** : MI_VFX_Thunder_Slash, MI_VFX_Thunder_Trail, MI_VFX_Thunder_Spark, MI_VFX_Thunder_Glow, MI_VFX_Thunder_Flipbook, MI_VFX_Thunder_Smoke, MI_VFX_Thunder_Mesh, MI_VFX_Thunder_Ring ; maillage : SM_VFX_Slash_Crescent_Tilted ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Thunder_Burst
- **Nom** : `NS_VFX_Thunder_Burst` (`demonslayer-vfx::NS_VFX_Thunder_Burst`)
- **Type** : Niagara System — archétype **Bolt** (Éclair entre deux points (Beam) avec branches, scintillement et impact.)
- **Utilisation** : Pluie d'éclairs autour d'un point.
- **Particularités** : 6 beams verticaux du ciel (EndPoint) au sol, décalés de 0,05 s.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 0,25 à 0,5 s
- **Performance** : 3 beams + ≈ 30 sprites · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/Thunder/NS_VFX_Thunder_Burst`
- **Dépendances** : MI_VFX_Thunder_Slash, MI_VFX_Thunder_Trail, MI_VFX_Thunder_Spark, MI_VFX_Thunder_Glow, MI_VFX_Thunder_Flipbook, MI_VFX_Thunder_Smoke, MI_VFX_Thunder_Mesh, MI_VFX_Thunder_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Thunder_Impact
- **Nom** : `NS_VFX_Thunder_Impact` (`demonslayer-vfx::NS_VFX_Thunder_Impact`)
- **Type** : Niagara System — archétype **Impact** (Impact à 4 tailles : flash + onde de choc + particules + élément + poussière + distorsion + éclats.)
- **Utilisation** : Impact électrique (ThunderImpact).
- **Particularités** : E_Element = T_VFX_Flip_Lightning_4x4 ; arcs au sol.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 0,5 (Small) → 1,6 s (Massive)
- **Performance** : Small ≈ 25, Medium ≈ 50, Large ≈ 90, Massive ≈ 150 particules · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/Thunder/NS_VFX_Thunder_Impact`
- **Dépendances** : MI_VFX_Thunder_Slash, MI_VFX_Thunder_Trail, MI_VFX_Thunder_Spark, MI_VFX_Thunder_Glow, MI_VFX_Thunder_Flipbook, MI_VFX_Thunder_Smoke, MI_VFX_Thunder_Mesh, MI_VFX_Thunder_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Thunder_Explosion
- **Nom** : `NS_VFX_Thunder_Explosion` (`demonslayer-vfx::NS_VFX_Thunder_Explosion`)
- **Type** : Niagara System — archétype **Burst** (Explosion / jaillissement élémentaire (sans projectile).)
- **Utilisation** : Explosion électrique (Honoikazuchi).
- **Particularités** : Sphère + 10 beams radiaux + flash aveuglant.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 1 à 1,8 s
- **Performance** : ≈ 120 particules + 1..2 maillages · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/Thunder/NS_VFX_Thunder_Explosion`
- **Dépendances** : MI_VFX_Thunder_Slash, MI_VFX_Thunder_Trail, MI_VFX_Thunder_Spark, MI_VFX_Thunder_Glow, MI_VFX_Thunder_Flipbook, MI_VFX_Thunder_Smoke, MI_VFX_Thunder_Mesh, MI_VFX_Thunder_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion


## Wind

### NS_VFX_Wind_Slash
- **Nom** : `NS_VFX_Wind_Slash` (`demonslayer-vfx::NS_VFX_Wind_Slash`)
- **Type** : Niagara System — archétype **Slash** (Coupe de lame : arc maillé balayé + ruban + flash + gerbe + distorsion + dissipation.)
- **Utilisation** : Lames d'air.
- **Particularités** : 3 arcs fins décalés (griffes) ; feuilles + poussière.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 0,45 à 0,8 s
- **Performance** : ≈ 60 particules (CPU), 1 maillage · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/Wind/NS_VFX_Wind_Slash`
- **Dépendances** : MI_VFX_Wind_Slash, MI_VFX_Wind_Trail, MI_VFX_Wind_Spark, MI_VFX_Wind_Glow, MI_VFX_Wind_Flipbook, MI_VFX_Wind_Smoke, MI_VFX_Wind_Mesh, MI_VFX_Wind_Ring ; maillage : SM_VFX_Slash_Arc_120 ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Wind_Trail
- **Nom** : `NS_VFX_Wind_Trail` (`demonslayer-vfx::NS_VFX_Wind_Trail`)
- **Type** : Niagara System — archétype **Trail** (Traînée continue attachée à la lame (socket hand_r) ou à un projectile.)
- **Utilisation** : Traînée de vent sur la lame.
- **Particularités** : Feuilles (MI_Wind_Spark) emportées par Curl Noise.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : boucle tant que l'acteur existe (désactiver = fin)
- **Performance** : 1 ruban (≈ 40 segments) + 20 sprites/s · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/Wind/NS_VFX_Wind_Trail`
- **Dépendances** : MI_VFX_Wind_Slash, MI_VFX_Wind_Trail, MI_VFX_Wind_Spark, MI_VFX_Wind_Glow, MI_VFX_Wind_Flipbook, MI_VFX_Wind_Smoke, MI_VFX_Wind_Mesh, MI_VFX_Wind_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Wind_Tornado
- **Nom** : `NS_VFX_Wind_Tornado` (`demonslayer-vfx::NS_VFX_Wind_Tornado`)
- **Type** : Niagara System — archétype **Vortex** (Tornade / tourbillon : cylindres torsadés en rotation + rubans en spirale + gouttes + distorsion.)
- **Utilisation** : Tornades (Arbre de la tempête, Typhon).
- **Particularités** : Débris, feuilles, poussière au sol.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 2,5 s (boucle si attaché)
- **Performance** : 2 maillages + 6 rubans + ≈ 120 sprites · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/Wind/NS_VFX_Wind_Tornado`
- **Dépendances** : MI_VFX_Wind_Slash, MI_VFX_Wind_Trail, MI_VFX_Wind_Spark, MI_VFX_Wind_Glow, MI_VFX_Wind_Flipbook, MI_VFX_Wind_Smoke, MI_VFX_Wind_Mesh, MI_VFX_Wind_Ring ; maillage : SM_VFX_Vortex_Cone ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Wind_Blade
- **Nom** : `NS_VFX_Wind_Blade` (`demonslayer-vfx::NS_VFX_Wind_Blade`)
- **Type** : Niagara System — archétype **Projectile** (Projectile = cœur + aura + traînée + gouttes ; l'impact est un système séparé (NS_VFX_<E>_Impact ou _Explosion).)
- **Utilisation** : Lame d'air lancée (Vent froid de montagne).
- **Particularités** : E_Core = SM_VFX_Slash_Arc_120 au lieu de la sphère.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : boucle (le script déplace/détruit le projectile)
- **Performance** : 1 maillage + 1 ruban + ≈ 40 sprites/s · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/Wind/NS_VFX_Wind_Blade`
- **Dépendances** : MI_VFX_Wind_Slash, MI_VFX_Wind_Trail, MI_VFX_Wind_Spark, MI_VFX_Wind_Glow, MI_VFX_Wind_Flipbook, MI_VFX_Wind_Smoke, MI_VFX_Wind_Mesh, MI_VFX_Wind_Ring ; maillage : SM_VFX_Slash_Arc_120 ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Wind_Impact
- **Nom** : `NS_VFX_Wind_Impact` (`demonslayer-vfx::NS_VFX_Wind_Impact`)
- **Type** : Niagara System — archétype **Impact** (Impact à 4 tailles : flash + onde de choc + particules + élément + poussière + distorsion + éclats.)
- **Utilisation** : Impact de vent (WindImpact).
- **Particularités** : Poussière radiale + feuilles.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 0,5 (Small) → 1,6 s (Massive)
- **Performance** : Small ≈ 25, Medium ≈ 50, Large ≈ 90, Massive ≈ 150 particules · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/Wind/NS_VFX_Wind_Impact`
- **Dépendances** : MI_VFX_Wind_Slash, MI_VFX_Wind_Trail, MI_VFX_Wind_Spark, MI_VFX_Wind_Glow, MI_VFX_Wind_Flipbook, MI_VFX_Wind_Smoke, MI_VFX_Wind_Mesh, MI_VFX_Wind_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Wind_Dash
- **Nom** : `NS_VFX_Wind_Dash` (`demonslayer-vfx::NS_VFX_Wind_Dash`)
- **Type** : Niagara System — archétype **Dash** (Élan : départ (flash + gerbe), rémanence sur le trajet, lignes de vitesse, arrivée.)
- **Utilisation** : Élan du vent.
- **Particularités** : Spirales autour du trajet.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 0,6 s
- **Performance** : ≈ 70 particules + 2 rubans · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/Wind/NS_VFX_Wind_Dash`
- **Dépendances** : MI_VFX_Wind_Slash, MI_VFX_Wind_Trail, MI_VFX_Wind_Spark, MI_VFX_Wind_Glow, MI_VFX_Wind_Flipbook, MI_VFX_Wind_Smoke, MI_VFX_Wind_Mesh, MI_VFX_Wind_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion


## Mist

### NS_VFX_Mist_Slash
- **Nom** : `NS_VFX_Mist_Slash` (`demonslayer-vfx::NS_VFX_Mist_Slash`)
- **Type** : Niagara System — archétype **Slash** (Coupe de lame : arc maillé balayé + ruban + flash + gerbe + distorsion + dissipation.)
- **Utilisation** : Coupes de la Brume.
- **Particularités** : Arc très doux (érosion forte) ; la brume reste 1,5 s.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 0,45 à 0,8 s
- **Performance** : ≈ 60 particules (CPU), 1 maillage · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/Mist/NS_VFX_Mist_Slash`
- **Dépendances** : MI_VFX_Mist_Slash, MI_VFX_Mist_Trail, MI_VFX_Mist_Spark, MI_VFX_Mist_Glow, MI_VFX_Mist_Flipbook, MI_VFX_Mist_Smoke, MI_VFX_Mist_Mesh, MI_VFX_Mist_Ring ; maillage : SM_VFX_Slash_Arc_180 ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Mist_Trail
- **Nom** : `NS_VFX_Mist_Trail` (`demonslayer-vfx::NS_VFX_Mist_Trail`)
- **Type** : Niagara System — archétype **Trail** (Traînée continue attachée à la lame (socket hand_r) ou à un projectile.)
- **Utilisation** : Traînée de brume.
- **Particularités** : recette de l’archétype sans changement
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : boucle tant que l'acteur existe (désactiver = fin)
- **Performance** : 1 ruban (≈ 40 segments) + 20 sprites/s · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/Mist/NS_VFX_Mist_Trail`
- **Dépendances** : MI_VFX_Mist_Slash, MI_VFX_Mist_Trail, MI_VFX_Mist_Spark, MI_VFX_Mist_Glow, MI_VFX_Mist_Flipbook, MI_VFX_Mist_Smoke, MI_VFX_Mist_Mesh, MI_VFX_Mist_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Mist_Fog
- **Nom** : `NS_VFX_Mist_Fog` (`demonslayer-vfx::NS_VFX_Mist_Fog`)
- **Type** : Niagara System — archétype **Aura** (Aura / zone persistante : sceau au sol, particules montantes, rubans d'orbite.)
- **Utilisation** : Nappe de brume (Éclaboussures de brume, Brume obscurcissante).
- **Particularités** : E_Sigil remplacé par 20 sprites de brume au sol (MI_Mist_Smoke), particules flottantes.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : boucle (détruite par le script)
- **Performance** : ≈ 60 sprites/s + 2 rubans · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/Mist/NS_VFX_Mist_Fog`
- **Dépendances** : MI_VFX_Mist_Slash, MI_VFX_Mist_Trail, MI_VFX_Mist_Spark, MI_VFX_Mist_Glow, MI_VFX_Mist_Flipbook, MI_VFX_Mist_Smoke, MI_VFX_Mist_Mesh, MI_VFX_Mist_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Mist_Vanish
- **Nom** : `NS_VFX_Mist_Vanish` (`demonslayer-vfx::NS_VFX_Mist_Vanish`)
- **Type** : Niagara System — archétype **Dash** (Élan : départ (flash + gerbe), rémanence sur le trajet, lignes de vitesse, arrivée.)
- **Utilisation** : Le joueur se fond dans la brume puis réapparaît.
- **Particularités** : Nuage épais qui recouvre le personnage 0,4 s (le script masque le personnage).
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 0,6 s
- **Performance** : ≈ 70 particules + 2 rubans · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/Mist/NS_VFX_Mist_Vanish`
- **Dépendances** : MI_VFX_Mist_Slash, MI_VFX_Mist_Trail, MI_VFX_Mist_Spark, MI_VFX_Mist_Glow, MI_VFX_Mist_Flipbook, MI_VFX_Mist_Smoke, MI_VFX_Mist_Mesh, MI_VFX_Mist_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Mist_Impact
- **Nom** : `NS_VFX_Mist_Impact` (`demonslayer-vfx::NS_VFX_Mist_Impact`)
- **Type** : Niagara System — archétype **Impact** (Impact à 4 tailles : flash + onde de choc + particules + élément + poussière + distorsion + éclats.)
- **Utilisation** : Impact de brume (MistImpact).
- **Particularités** : recette de l’archétype sans changement
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 0,5 (Small) → 1,6 s (Massive)
- **Performance** : Small ≈ 25, Medium ≈ 50, Large ≈ 90, Massive ≈ 150 particules · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/Mist/NS_VFX_Mist_Impact`
- **Dépendances** : MI_VFX_Mist_Slash, MI_VFX_Mist_Trail, MI_VFX_Mist_Spark, MI_VFX_Mist_Glow, MI_VFX_Mist_Flipbook, MI_VFX_Mist_Smoke, MI_VFX_Mist_Mesh, MI_VFX_Mist_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion


## BloodArts

### NS_VFX_Blood_Slash
- **Nom** : `NS_VFX_Blood_Slash` (`demonslayer-vfx::NS_VFX_Blood_Slash`)
- **Type** : Niagara System — archétype **Slash** (Coupe de lame : arc maillé balayé + ruban + flash + gerbe + distorsion + dissipation.)
- **Utilisation** : Griffes / lames de sang.
- **Particularités** : Projections stylisées (MI_Blood_Spark, gravité).
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 0,45 à 0,8 s
- **Performance** : ≈ 60 particules (CPU), 1 maillage · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/BloodArts/NS_VFX_Blood_Slash`
- **Dépendances** : MI_VFX_Blood_Slash, MI_VFX_Blood_Trail, MI_VFX_Blood_Spark, MI_VFX_Blood_Glow, MI_VFX_Blood_Flipbook, MI_VFX_Blood_Smoke, MI_VFX_Blood_Mesh, MI_VFX_Blood_Ring ; maillage : SM_VFX_Slash_Arc_120 ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Blood_Burst
- **Nom** : `NS_VFX_Blood_Burst` (`demonslayer-vfx::NS_VFX_Blood_Burst`)
- **Type** : Niagara System — archétype **Burst** (Explosion / jaillissement élémentaire (sans projectile).)
- **Utilisation** : Explosion de sang + sceau.
- **Particularités** : E_Ring = sceau MI_VFX_Core_Sigil rouge qui tourne.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 1 à 1,8 s
- **Performance** : ≈ 120 particules + 1..2 maillages · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/BloodArts/NS_VFX_Blood_Burst`
- **Dépendances** : MI_VFX_Blood_Slash, MI_VFX_Blood_Trail, MI_VFX_Blood_Spark, MI_VFX_Blood_Glow, MI_VFX_Blood_Flipbook, MI_VFX_Blood_Smoke, MI_VFX_Blood_Mesh, MI_VFX_Blood_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Blood_Projectile
- **Nom** : `NS_VFX_Blood_Projectile` (`demonslayer-vfx::NS_VFX_Blood_Projectile`)
- **Type** : Niagara System — archétype **Projectile** (Projectile = cœur + aura + traînée + gouttes ; l'impact est un système séparé (NS_VFX_<E>_Impact ou _Explosion).)
- **Utilisation** : Lame de sang lancée.
- **Particularités** : E_Core = SM_VFX_Slash_Arc_120.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : boucle (le script déplace/détruit le projectile)
- **Performance** : 1 maillage + 1 ruban + ≈ 40 sprites/s · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/BloodArts/NS_VFX_Blood_Projectile`
- **Dépendances** : MI_VFX_Blood_Slash, MI_VFX_Blood_Trail, MI_VFX_Blood_Spark, MI_VFX_Blood_Glow, MI_VFX_Blood_Flipbook, MI_VFX_Blood_Smoke, MI_VFX_Blood_Mesh, MI_VFX_Blood_Ring ; maillage : SM_VFX_Slash_Arc_120 ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Blood_Aura
- **Nom** : `NS_VFX_Blood_Aura` (`demonslayer-vfx::NS_VFX_Blood_Aura`)
- **Type** : Niagara System — archétype **Aura** (Aura / zone persistante : sceau au sol, particules montantes, rubans d'orbite.)
- **Utilisation** : Éveil du sang (aura).
- **Particularités** : recette de l’archétype sans changement
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : boucle (détruite par le script)
- **Performance** : ≈ 60 sprites/s + 2 rubans · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/BloodArts/NS_VFX_Blood_Aura`
- **Dépendances** : MI_VFX_Blood_Slash, MI_VFX_Blood_Trail, MI_VFX_Blood_Spark, MI_VFX_Blood_Glow, MI_VFX_Blood_Flipbook, MI_VFX_Blood_Smoke, MI_VFX_Blood_Mesh, MI_VFX_Blood_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Blood_Impact
- **Nom** : `NS_VFX_Blood_Impact` (`demonslayer-vfx::NS_VFX_Blood_Impact`)
- **Type** : Niagara System — archétype **Impact** (Impact à 4 tailles : flash + onde de choc + particules + élément + poussière + distorsion + éclats.)
- **Utilisation** : Impact de sang (BloodImpact).
- **Particularités** : recette de l’archétype sans changement
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 0,5 (Small) → 1,6 s (Massive)
- **Performance** : Small ≈ 25, Medium ≈ 50, Large ≈ 90, Massive ≈ 150 particules · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/BloodArts/NS_VFX_Blood_Impact`
- **Dépendances** : MI_VFX_Blood_Slash, MI_VFX_Blood_Trail, MI_VFX_Blood_Spark, MI_VFX_Blood_Glow, MI_VFX_Blood_Flipbook, MI_VFX_Blood_Smoke, MI_VFX_Blood_Mesh, MI_VFX_Blood_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Ice_Slash
- **Nom** : `NS_VFX_Ice_Slash` (`demonslayer-vfx::NS_VFX_Ice_Slash`)
- **Type** : Niagara System — archétype **Slash** (Coupe de lame : arc maillé balayé + ruban + flash + gerbe + distorsion + dissipation.)
- **Utilisation** : Éventails de glace.
- **Particularités** : Cristaux (MI_Ice_Spark = éclats) + neige.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 0,45 à 0,8 s
- **Performance** : ≈ 60 particules (CPU), 1 maillage · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/BloodArts/NS_VFX_Ice_Slash`
- **Dépendances** : MI_VFX_Ice_Slash, MI_VFX_Ice_Trail, MI_VFX_Ice_Spark, MI_VFX_Ice_Glow, MI_VFX_Ice_Flipbook, MI_VFX_Ice_Smoke, MI_VFX_Ice_Mesh, MI_VFX_Ice_Ring ; maillage : SM_VFX_Slash_Arc_180 ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Ice_Spikes
- **Nom** : `NS_VFX_Ice_Spikes` (`demonslayer-vfx::NS_VFX_Ice_Spikes`)
- **Type** : Niagara System — archétype **Spikes** (Pics qui jaillissent du sol en cercle ou en ligne (glace, sang durci).)
- **Utilisation** : Hiver glacé (pics en cercle).
- **Particularités** : recette de l’archétype sans changement
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 1,6 s
- **Performance** : 8..14 maillages + ≈ 60 sprites · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/BloodArts/NS_VFX_Ice_Spikes`
- **Dépendances** : MI_VFX_Ice_Slash, MI_VFX_Ice_Trail, MI_VFX_Ice_Spark, MI_VFX_Ice_Glow, MI_VFX_Ice_Flipbook, MI_VFX_Ice_Smoke, MI_VFX_Ice_Mesh, MI_VFX_Ice_Ring ; maillage : SM_VFX_Spike_Ice ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Ice_Shard
- **Nom** : `NS_VFX_Ice_Shard` (`demonslayer-vfx::NS_VFX_Ice_Shard`)
- **Type** : Niagara System — archétype **Projectile** (Projectile = cœur + aura + traînée + gouttes ; l'impact est un système séparé (NS_VFX_<E>_Impact ou _Explosion).)
- **Utilisation** : Lance de glace.
- **Particularités** : E_Core = SM_VFX_Spike_Ice orienté vers l'avant.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : boucle (le script déplace/détruit le projectile)
- **Performance** : 1 maillage + 1 ruban + ≈ 40 sprites/s · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/BloodArts/NS_VFX_Ice_Shard`
- **Dépendances** : MI_VFX_Ice_Slash, MI_VFX_Ice_Trail, MI_VFX_Ice_Spark, MI_VFX_Ice_Glow, MI_VFX_Ice_Flipbook, MI_VFX_Ice_Smoke, MI_VFX_Ice_Mesh, MI_VFX_Ice_Ring ; maillage : SM_VFX_Spike_Ice ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Ice_Explosion
- **Nom** : `NS_VFX_Ice_Explosion` (`demonslayer-vfx::NS_VFX_Ice_Explosion`)
- **Type** : Niagara System — archétype **Burst** (Explosion / jaillissement élémentaire (sans projectile).)
- **Utilisation** : Explosion de glace (Bodhisattva).
- **Particularités** : Éclats maillés + brume froide.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 1 à 1,8 s
- **Performance** : ≈ 120 particules + 1..2 maillages · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/BloodArts/NS_VFX_Ice_Explosion`
- **Dépendances** : MI_VFX_Ice_Slash, MI_VFX_Ice_Trail, MI_VFX_Ice_Spark, MI_VFX_Ice_Glow, MI_VFX_Ice_Flipbook, MI_VFX_Ice_Smoke, MI_VFX_Ice_Mesh, MI_VFX_Ice_Ring ; maillage : SM_VFX_Spike_Ice ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Ice_Impact
- **Nom** : `NS_VFX_Ice_Impact` (`demonslayer-vfx::NS_VFX_Ice_Impact`)
- **Type** : Niagara System — archétype **Impact** (Impact à 4 tailles : flash + onde de choc + particules + élément + poussière + distorsion + éclats.)
- **Utilisation** : Impact de glace (IceImpact).
- **Particularités** : E_Debris = SM_VFX_Spike_Ice.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 0,5 (Small) → 1,6 s (Massive)
- **Performance** : Small ≈ 25, Medium ≈ 50, Large ≈ 90, Massive ≈ 150 particules · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/BloodArts/NS_VFX_Ice_Impact`
- **Dépendances** : MI_VFX_Ice_Slash, MI_VFX_Ice_Trail, MI_VFX_Ice_Spark, MI_VFX_Ice_Glow, MI_VFX_Ice_Flipbook, MI_VFX_Ice_Smoke, MI_VFX_Ice_Mesh, MI_VFX_Ice_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Shadow_Slash
- **Nom** : `NS_VFX_Shadow_Slash` (`demonslayer-vfx::NS_VFX_Shadow_Slash`)
- **Type** : Niagara System — archétype **Slash** (Coupe de lame : arc maillé balayé + ruban + flash + gerbe + distorsion + dissipation.)
- **Utilisation** : Griffes d'ombre.
- **Particularités** : Fumée noire + particules violettes.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 0,45 à 0,8 s
- **Performance** : ≈ 60 particules (CPU), 1 maillage · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/BloodArts/NS_VFX_Shadow_Slash`
- **Dépendances** : MI_VFX_Shadow_Slash, MI_VFX_Shadow_Trail, MI_VFX_Shadow_Spark, MI_VFX_Shadow_Glow, MI_VFX_Shadow_Flipbook, MI_VFX_Shadow_Smoke, MI_VFX_Shadow_Mesh, MI_VFX_Shadow_Ring ; maillage : SM_VFX_Slash_Arc_120 ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Shadow_Vortex
- **Nom** : `NS_VFX_Shadow_Vortex` (`demonslayer-vfx::NS_VFX_Shadow_Vortex`)
- **Type** : Niagara System — archétype **Vortex** (Tornade / tourbillon : cylindres torsadés en rotation + rubans en spirale + gouttes + distorsion.)
- **Utilisation** : Vortex ténébreux.
- **Particularités** : Distorsion forte au centre.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 2,5 s (boucle si attaché)
- **Performance** : 2 maillages + 6 rubans + ≈ 120 sprites · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/BloodArts/NS_VFX_Shadow_Vortex`
- **Dépendances** : MI_VFX_Shadow_Slash, MI_VFX_Shadow_Trail, MI_VFX_Shadow_Spark, MI_VFX_Shadow_Glow, MI_VFX_Shadow_Flipbook, MI_VFX_Shadow_Smoke, MI_VFX_Shadow_Mesh, MI_VFX_Shadow_Ring ; maillage : SM_VFX_Vortex_Cone ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Shadow_Projectile
- **Nom** : `NS_VFX_Shadow_Projectile` (`demonslayer-vfx::NS_VFX_Shadow_Projectile`)
- **Type** : Niagara System — archétype **Projectile** (Projectile = cœur + aura + traînée + gouttes ; l'impact est un système séparé (NS_VFX_<E>_Impact ou _Explosion).)
- **Utilisation** : Lance du néant.
- **Particularités** : recette de l’archétype sans changement
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : boucle (le script déplace/détruit le projectile)
- **Performance** : 1 maillage + 1 ruban + ≈ 40 sprites/s · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/BloodArts/NS_VFX_Shadow_Projectile`
- **Dépendances** : MI_VFX_Shadow_Slash, MI_VFX_Shadow_Trail, MI_VFX_Shadow_Spark, MI_VFX_Shadow_Glow, MI_VFX_Shadow_Flipbook, MI_VFX_Shadow_Smoke, MI_VFX_Shadow_Mesh, MI_VFX_Shadow_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Shadow_Aura
- **Nom** : `NS_VFX_Shadow_Aura` (`demonslayer-vfx::NS_VFX_Shadow_Aura`)
- **Type** : Niagara System — archétype **Aura** (Aura / zone persistante : sceau au sol, particules montantes, rubans d'orbite.)
- **Utilisation** : Nuit éternelle / aura d'ombre.
- **Particularités** : recette de l’archétype sans changement
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : boucle (détruite par le script)
- **Performance** : ≈ 60 sprites/s + 2 rubans · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/BloodArts/NS_VFX_Shadow_Aura`
- **Dépendances** : MI_VFX_Shadow_Slash, MI_VFX_Shadow_Trail, MI_VFX_Shadow_Spark, MI_VFX_Shadow_Glow, MI_VFX_Shadow_Flipbook, MI_VFX_Shadow_Smoke, MI_VFX_Shadow_Mesh, MI_VFX_Shadow_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Shadow_Impact
- **Nom** : `NS_VFX_Shadow_Impact` (`demonslayer-vfx::NS_VFX_Shadow_Impact`)
- **Type** : Niagara System — archétype **Impact** (Impact à 4 tailles : flash + onde de choc + particules + élément + poussière + distorsion + éclats.)
- **Utilisation** : Impact d'ombre.
- **Particularités** : recette de l’archétype sans changement
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 0,5 (Small) → 1,6 s (Massive)
- **Performance** : Small ≈ 25, Medium ≈ 50, Large ≈ 90, Massive ≈ 150 particules · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/BloodArts/NS_VFX_Shadow_Impact`
- **Dépendances** : MI_VFX_Shadow_Slash, MI_VFX_Shadow_Trail, MI_VFX_Shadow_Spark, MI_VFX_Shadow_Glow, MI_VFX_Shadow_Flipbook, MI_VFX_Shadow_Smoke, MI_VFX_Shadow_Mesh, MI_VFX_Shadow_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Flower_Slash
- **Nom** : `NS_VFX_Flower_Slash` (`demonslayer-vfx::NS_VFX_Flower_Slash`)
- **Type** : Niagara System — archétype **Slash** (Coupe de lame : arc maillé balayé + ruban + flash + gerbe + distorsion + dissipation.)
- **Utilisation** : Pétales tranchants.
- **Particularités** : Pétales maillés (SM_VFX_Petal) au lieu des gouttes.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 0,45 à 0,8 s
- **Performance** : ≈ 60 particules (CPU), 1 maillage · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/BloodArts/NS_VFX_Flower_Slash`
- **Dépendances** : MI_VFX_Flower_Slash, MI_VFX_Flower_Trail, MI_VFX_Flower_Spark, MI_VFX_Flower_Glow, MI_VFX_Flower_Flipbook, MI_VFX_Flower_Smoke, MI_VFX_Flower_Mesh, MI_VFX_Flower_Ring ; maillage : SM_VFX_Slash_Arc_180 ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Flower_PetalStorm
- **Nom** : `NS_VFX_Flower_PetalStorm` (`demonslayer-vfx::NS_VFX_Flower_PetalStorm`)
- **Type** : Niagara System — archétype **Vortex** (Tornade / tourbillon : cylindres torsadés en rotation + rubans en spirale + gouttes + distorsion.)
- **Utilisation** : Tempête de pétales / jardin.
- **Particularités** : E_Funnel masqué (alpha faible), pétales maillés en spirale.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 2,5 s (boucle si attaché)
- **Performance** : 2 maillages + 6 rubans + ≈ 120 sprites · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/BloodArts/NS_VFX_Flower_PetalStorm`
- **Dépendances** : MI_VFX_Flower_Slash, MI_VFX_Flower_Trail, MI_VFX_Flower_Spark, MI_VFX_Flower_Glow, MI_VFX_Flower_Flipbook, MI_VFX_Flower_Smoke, MI_VFX_Flower_Mesh, MI_VFX_Flower_Ring ; maillage : SM_VFX_Petal ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Flower_Bloom
- **Nom** : `NS_VFX_Flower_Bloom` (`demonslayer-vfx::NS_VFX_Flower_Bloom`)
- **Type** : Niagara System — archétype **Burst** (Explosion / jaillissement élémentaire (sans projectile).)
- **Utilisation** : Éclosion (fleur lumineuse au sol).
- **Particularités** : Sceau remplacé par 6 pétales maillés géants qui s'ouvrent.
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 1 à 1,8 s
- **Performance** : ≈ 120 particules + 1..2 maillages · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/BloodArts/NS_VFX_Flower_Bloom`
- **Dépendances** : MI_VFX_Flower_Slash, MI_VFX_Flower_Trail, MI_VFX_Flower_Spark, MI_VFX_Flower_Glow, MI_VFX_Flower_Flipbook, MI_VFX_Flower_Smoke, MI_VFX_Flower_Mesh, MI_VFX_Flower_Ring ; maillage : SM_VFX_Petal ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Flower_Projectile
- **Nom** : `NS_VFX_Flower_Projectile` (`demonslayer-vfx::NS_VFX_Flower_Projectile`)
- **Type** : Niagara System — archétype **Projectile** (Projectile = cœur + aura + traînée + gouttes ; l'impact est un système séparé (NS_VFX_<E>_Impact ou _Explosion).)
- **Utilisation** : Liane / projectile floral.
- **Particularités** : recette de l’archétype sans changement
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : boucle (le script déplace/détruit le projectile)
- **Performance** : 1 maillage + 1 ruban + ≈ 40 sprites/s · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/BloodArts/NS_VFX_Flower_Projectile`
- **Dépendances** : MI_VFX_Flower_Slash, MI_VFX_Flower_Trail, MI_VFX_Flower_Spark, MI_VFX_Flower_Glow, MI_VFX_Flower_Flipbook, MI_VFX_Flower_Smoke, MI_VFX_Flower_Mesh, MI_VFX_Flower_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion

### NS_VFX_Flower_Impact
- **Nom** : `NS_VFX_Flower_Impact` (`demonslayer-vfx::NS_VFX_Flower_Impact`)
- **Type** : Niagara System — archétype **Impact** (Impact à 4 tailles : flash + onde de choc + particules + élément + poussière + distorsion + éclats.)
- **Utilisation** : Impact floral.
- **Particularités** : recette de l’archétype sans changement
- **Paramètres modifiables** : Color, SecondaryColor, Scale, Intensity, Duration, Speed, SpawnScale, Width, Direction, EndPoint
- **Durée** : 0,5 (Small) → 1,6 s (Massive)
- **Performance** : Small ≈ 25, Medium ≈ 50, Large ≈ 90, Massive ≈ 150 particules · LOD : Scalability (distance 3000 / 6000 cm, SpawnScale 0,5 / 0,25), culling au-delà de 9000 cm, Max particules par émetteur fixé
- **Asset principal** : `/Game/DemonSlayerVFX/Systems/BloodArts/NS_VFX_Flower_Impact`
- **Dépendances** : MI_VFX_Flower_Slash, MI_VFX_Flower_Trail, MI_VFX_Flower_Spark, MI_VFX_Flower_Glow, MI_VFX_Flower_Flipbook, MI_VFX_Flower_Smoke, MI_VFX_Flower_Mesh, MI_VFX_Flower_Ring ; maillage : — ; MI_VFX_Core_Flash, MI_VFX_Core_Distortion
