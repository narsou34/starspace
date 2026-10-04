# Recettes Niagara (archétypes)

Méthode : construire **un système modèle par archétype** dans `Niagara/Core/` (`NS_Template_<Archétype>`),
avec les paramètres utilisateur standard, puis **dupliquer** pour chaque élément et ne changer que les
Material Instances, couleurs et valeurs indiquées dans le catalogue.

## Règles communes (compatibilité nanos world + performance)

1. **Paramètres utilisateur** (onglet *User Parameters*) sur chaque système : `Color` (LinearColor), `SecondaryColor` (LinearColor), `Scale` (Float), `Intensity` (Float), `Duration` (Float), `Speed` (Float), `SpawnScale` (Float), `Width` (Float), `Direction` (Vector), `EndPoint` (Vector).
   Les lier dans les modules (Color x `User.Color`, Size x `User.Scale`, Lifetime x `User.Duration`, Spawn Rate x `User.SpawnScale`...).
2. **Pas de Data Interface liée à la scène** que nanos ne fournit pas : pas de *Skeletal Mesh* DI sur le personnage, pas de *Actor Component* DI,
   pas de *Collision Query* CPU sur la scène, pas de *Export Particle Data* vers Blueprint. Autorisés : Static Mesh DI sur NOS maillages, Curl Noise,
   Vortex/Point Attraction, Event Handlers internes, Beam Emitter Setup, SubUV, Dynamic Material Parameters, GPU Depth Buffer Collision.
3. **Aucune référence à `/Engine/` ou au contenu par défaut de Niagara** (textures, matériaux) : tout vient de `Content/DemonSlayerVFX/`.
   Les modules standards de Niagara (`/Niagara/Modules/...`) sont compilés dans le système : autorisés.
4. **Systèmes à durée finie** : *Loop Behavior = Once* + *Inactive Response = Complete*, pour que nanos détruise le système à la fin
   (sauf Trail / Projectile / Aura : boucle, le script détruit la Particle).
5. **Scalability** : *Effect Type* `EFT_DemonSlayer_Combat` (dans `Niagara/Core/`) : Cull Distance 9000, Max Instances 24, LOD distance
   3000 / 6000 avec *Spawn Count Scale* 0,5 / 0,25. GPU uniquement pour les émetteurs > 150 particules (mousse, gouttes de tsunami).
6. **Fixed Bounds** sur chaque émetteur (pas de calcul dynamique) : ex. Slash 600 x 600 x 300, Tsunami 3000 x 1500 x 800.
7. Orientation : le système suit la rotation de l'acteur (Local Space pour les maillages de coupe, World Space pour rubans et gouttes).

## Chronologie commune (anticipation → dissipation)

| t | Phase | Contenu |
| --- | --- | --- |
| 0,00 | Anticipation | petites particules attirées vers la lame (E_Anticipation / E_Charge) |
| 0,05 | Accumulation | lueur (MI_<E>_Glow) qui grossit |
| 0,08 | Attaque | balayage du maillage (Param1 0→1 en 0,12 s), ruban |
| 0,10 | Forme principale + flash | maillage plein, flash, distorsion |
| 0,15 | Impact | (système _Impact déclenché par le script au point touché) |
| 0,20 | Particules secondaires | gouttes / braises / étincelles avec drag et gravité |
| 0,30 | Dissipation | érosion (Param2) + fumée / brume qui monte |
| 0,45+ | Fin | plus rien de vivant, le système se détruit |

## Archétype Slash

Coupe de lame : arc maillé balayé + ruban + flash + gerbe + distorsion + dissipation.

Durée : 0,45 à 0,8 s · Budget : ≈ 60 particules (CPU), 1 maillage

| Émetteur | Type | Modules et valeurs |
| --- | --- | --- |
| `E_Anticipation` | Sprite CPU, Burst 12 à t=0 | Spawn Burst Instantaneous(12) ; Sphere Location r=40 ; Velocity vers le centre (Point Attraction 600) ; Lifetime 0,12 ; Size 6→0 ; MI_<E>_Spark. Accumulation d'énergie avant le coup. |
| `E_SlashMesh` | Mesh CPU (SM_VFX_Slash_Arc_*), 1 particule à t=0,08 | Spawn Burst(1, Spawn Time 0.08) ; Mesh Renderer : maillage choisi, orientation = acteur (Mesh Orientation : Local Space) ; Scale Mesh Size 0.85→1.15 (courbe ease-out) x User.Scale ; Dynamic Material Parameters : Param1 (balayage) 0→1 en 0,12 s, Param2 (érosion) 0→1 de 0,25 s à la fin ; Lifetime 0,45 x User.Duration ; Material MI_<E>_Slash. |
| `E_SlashCore` | Mesh CPU, copie plus fine | Identique à E_SlashMesh, Scale 0.9, Color = User.SecondaryColor x 2 : fil blanc lumineux au cœur de la coupe. |
| `E_Ribbon` | Ribbon CPU | Spawn Rate 120 pendant 0,15 s ; position = arc paramétrique (Custom : Cylinder Location angle = Normalized Age x 150°, rayon 170) ; Ribbon Width = User.Width ; Lifetime 0,25 ; Ribbon Renderer UV0 Mode = Normalized Age ; MI_<E>_Trail. |
| `E_Particles` | Sprite CPU, Burst 30 à t=0,1 | Location : Shape = Torus/arc (rayon 180) ; Add Velocity tangente (Velocity Cone 25°, 400..900) ; Drag 2 ; Gravity -400 (eau/sang) ; Size 4..10, Scale Size by Speed ; Lifetime 0,4..0,7 ; MI_<E>_Spark (gouttelettes / braises / étincelles). |
| `E_Flash` | Sprite CPU, Burst 1 à t=0,1 | Size 260→40 (0,1 s) ; Color = User.Color x 4 ; MI_VFX_Core_Flash ; Facing Camera. |
| `E_Distortion` | Sprite CPU, Burst 1 | Size 300→420 ; Lifetime 0,3 ; MI_VFX_Core_Distortion ; Opacity courbe 1→0. |
| `E_Dissipation` | Sprite CPU, Burst 8 à t=0,3 | Location sur l'arc ; Velocity +Z 40..120 ; Size 30→60 ; Lifetime 0,6 ; MI_<E>_Smoke (brume / fumée / poussière d'énergie). |

## Archétype Trail

Traînée continue attachée à la lame (socket hand_r) ou à un projectile.

Durée : boucle tant que l'acteur existe (désactiver = fin) · Budget : 1 ruban (≈ 40 segments) + 20 sprites/s

| Émetteur | Type | Modules et valeurs |
| --- | --- | --- |
| `E_Ribbon` | Ribbon CPU, Spawn Rate 60 | Spawn Rate 60 x User.SpawnScale ; Ribbon Width User.Width (défaut 28) avec courbe d'âge 1→0 ; Lifetime 0,3 x User.Duration ; MI_<E>_Trail ; Ribbon Link Order = Normalized Age. |
| `E_RibbonCore` | Ribbon CPU | Comme E_Ribbon, Width x 0,3, Color = SecondaryColor x 3. |
| `E_Bits` | Sprite CPU, Spawn Rate 25 | Inherit Velocity 0,3 ; Curl Noise Force 300 ; Lifetime 0,4 ; Size 3..7 ; MI_<E>_Spark. |

## Archétype Impact

Impact à 4 tailles : flash + onde de choc + particules + élément + poussière + distorsion + éclats.

Durée : 0,5 (Small) → 1,6 s (Massive) · Budget : Small ≈ 25, Medium ≈ 50, Large ≈ 90, Massive ≈ 150 particules

| Émetteur | Type | Modules et valeurs |
| --- | --- | --- |
| `E_Flash` | Sprite, Burst 1 | Size 120 x Scale→0 en 0,08 s ; MI_VFX_Core_Flash ; Color = User.Color x 6. |
| `E_Shockwave` | Sprite (Facing : Custom Facing Vector +Z), Burst 1 | Size 40→420 x Scale (ease-out 0,25 s) ; Opacity 1→0 ; MI_<E>_Ring. Medium et plus : 2e onde à t=0,06. |
| `E_Burst` | Sprite, Burst 20..80 | Sphere Location r=10 ; Add Velocity In Cone (hémisphère haut) 500..1400 ; Drag 3 ; Gravity -900 ; Size by Speed ; MI_<E>_Spark. |
| `E_Element` | Sprite flipbook, Burst 1..3 | SubUV (4x4 ou 8x8) lu en 0,5 s ; Size 220 x Scale ; MI_<E>_Flipbook (éclaboussure, flamme, éclair...). |
| `E_Dust` | Sprite, Burst 6..20 (Large+) | Ring Location au sol r=80 ; Velocity radiale 200 ; Size 80→220 ; Lifetime 1,2 ; MI_VFX_Core_Dust ou MI_<E>_Smoke. |
| `E_Debris` | Mesh ou Sprite, Burst 6..16 (Large+) | Éclats (SM_VFX_Spike_Ice / Rock / Petal) ; Velocity In Cone 600..1200 ; Gravity -980 ; Rotation aléatoire. |
| `E_Distortion` | Sprite, Burst 1 (Medium+) | MI_VFX_Core_DistortionRing, Size 100→500. |

## Archétype Projectile

Projectile = cœur + aura + traînée + gouttes ; l'impact est un système séparé (NS_VFX_<E>_Impact ou _Explosion).

Durée : boucle (le script déplace/détruit le projectile) · Budget : 1 maillage + 1 ruban + ≈ 40 sprites/s

| Émetteur | Type | Modules et valeurs |
| --- | --- | --- |
| `E_Core` | Mesh (SM_VFX_Sphere) | 1 particule persistante ; Scale 0,6 x Scale ; Mesh Rotation Rate aléatoire ; MI_<E>_Mesh. |
| `E_Aura` | Sprite, Spawn Rate 30 | Sphere Location r=30 ; Vortex Velocity 300 autour de l'axe avant ; Size 20..40 ; Lifetime 0,3 ; MI_<E>_Glow. |
| `E_Trail` | Ribbon, Spawn Rate 80 | Local Space OFF (reste dans le monde) ; Width 40 x Scale ; Lifetime 0,35 ; MI_<E>_Trail. |
| `E_Drops` | Sprite, Spawn Rate 40 | Inherit Velocity -0,2 ; Gravity -600 ; Size 4..8 ; Lifetime 0,5 ; MI_<E>_Spark. |

## Archétype Dash

Élan : départ (flash + gerbe), rémanence sur le trajet, lignes de vitesse, arrivée.

Durée : 0,6 s · Budget : ≈ 70 particules + 2 rubans

| Émetteur | Type | Modules et valeurs |
| --- | --- | --- |
| `E_StartFlash` | Sprite, Burst 1 | MI_VFX_Core_Flash, Size 300→0 en 0,1 s. |
| `E_Afterimage` | Ribbon, Spawn Rate 200 pendant 0,15 s | Position interpolée de l'origine à User.EndPoint (Normalized Age) ; Width 90 ; Lifetime 0,35 ; MI_<E>_Trail. |
| `E_SpeedLines` | Sprite (Facing Velocity), Burst 25 | Box Location le long du trajet ; Velocity = Direction x 3000 ; Sprite Size (4, 120) ; Lifetime 0,15 ; MI_<E>_Spark. |
| `E_Element` | Sprite/Beam selon l'élément | Foudre : Beam (Beam Emitter Setup, Start = origine, End = User.EndPoint, Jitter) x 3 ; Brume : MI_Mist_Smoke qui recouvre le personnage ; Eau : flipbook éclaboussures. |
| `E_Arrival` | Sprite, Burst 20 à t=0,15 | Gerbe à User.EndPoint + MI_<E>_Ring au sol. |

## Archétype Wave

Vague / tsunami : mur maillé qui AVANCE + mousse + gouttelettes + éclaboussures + brume + vaguelettes.

Durée : 1,6 s (vague) / 3 s (tsunami) · Budget : 3..6 maillages + ≈ 120 sprites (GPU pour la mousse)

| Émetteur | Type | Modules et valeurs |
| --- | --- | --- |
| `E_WaveMesh` | Mesh (SM_VFX_Wave_Curl), Burst 1..3 | Velocity = Direction x 900 x Speed (Solve Forces and Velocity) ; Scale Mesh Size 0,4→1,2 (montée) ; Dynamic Param1 (érosion) 0→1 sur les 25 % finaux ; MI_Water_Mesh. |
| `E_WaveShell` | Mesh, copie 1,05 | MI_Water_Slash (bord lumineux) ; légère avance (+20 cm). |
| `E_Foam` | Sprite GPU, Spawn Rate 400 x SpawnScale | Spawn sur la crête (Static Mesh Location : SM_VFX_Wave_Curl, filtre V > 0,8) ; Inherit velocity ; Curl Noise 200 ; Size 8..20 ; MI_Water_Spark. |
| `E_Droplets` | Sprite GPU, Spawn Rate 300 | Velocity cône vers l'avant/haut 300..900 ; Gravity -980 ; Collision (GPU Depth Buffer) optionnelle ; MI_Water_Spark. |
| `E_Splash` | Sprite flipbook, Spawn Rate 12 | Sur le pied de la vague ; MI_Water_Flipbook ; Size 250. |
| `E_Mist` | Sprite, Spawn Rate 10 | Derrière la vague ; Size 300→600 ; Lifetime 1,5 ; MI_Mist_Smoke teinté bleu. |
| `E_SmallWaves` | Mesh (SM_VFX_Ring_Flat), Spawn Rate 6 | Au sol ; Scale 0,3→1,5 ; MI_Water_Ring : vaguelettes secondaires. |
| `E_Crash` | Event Handler (Death de E_WaveMesh) | Déclenche une explosion d'eau (gerbe + flipbook + onde) à l'emplacement final. |

## Archétype Vortex

Tornade / tourbillon : cylindres torsadés en rotation + rubans en spirale + gouttes + distorsion.

Durée : 2,5 s (boucle si attaché) · Budget : 2 maillages + 6 rubans + ≈ 120 sprites

| Émetteur | Type | Modules et valeurs |
| --- | --- | --- |
| `E_Funnel` | Mesh (SM_VFX_Vortex_Cone), 1 | Mesh Rotation Rate Z 540°/s x Speed ; Scale 0,3→1 en 0,3 s ; Param1 érosion fin ; MI_<E>_Slash (U = tour). |
| `E_FunnelInner` | Mesh (SM_VFX_Vortex_Cylinder), 1 | Rotation inverse -720°/s ; MI_<E>_Mesh. |
| `E_Spirals` | Ribbon x 6 (Spawn Per Unit) | Vortex Velocity 800 autour de Z + Point Attraction ; montée +Z 300 ; MI_<E>_Trail. |
| `E_Particles` | Sprite GPU, Spawn Rate 250 | Cylinder Location ; Vortex Velocity 600 ; Velocity +Z 200..500 ; MI_<E>_Spark (gouttes, feuilles, poussière). |
| `E_Ground` | Sprite (Facing +Z), Spawn Rate 4 | MI_<E>_Ring au sol, Size 200→700. |
| `E_Distortion` | Sprite, Spawn Rate 3 | MI_VFX_Core_Distortion le long de l'axe. |

## Archétype Beast

Créature (dragon / tigre / serpent) : tête maillée + segments + rubans + brume, trajectoire sinueuse.

Durée : 1,6 à 2,2 s · Budget : 1 tête + 10..14 segments + 3 rubans + ≈ 150 sprites

| Émetteur | Type | Modules et valeurs |
| --- | --- | --- |
| `E_Head` | Mesh (SM_VFX_Dragon_Head), 1 | Velocity = Direction x 1400 x Speed ; ondulation : Sine sur Y/Z (Custom module ou Curl Noise Force faible) ; Orient Mesh To Velocity ; MI_<E>_Mesh. |
| `E_Body` | Mesh (SM_VFX_Dragon_Segment), Spawn Rate 18 | Spawn depuis la position de la tête (Particle Attribute Reader : E_Head.Position) ; Lifetime 0,7 ; Scale 1→0,5 ; Orient To Velocity ; MI_<E>_Slash + MI_<E>_Mesh. |
| `E_Spine` | Ribbon, suit la tête | Width 160→20 (Ribbon Width par âge) ; MI_<E>_Trail. |
| `E_Whiskers` | Ribbon x 2, décalés | Width 12 ; MI_<E>_Trail (SecondaryColor). |
| `E_Mist` | Sprite, Spawn Rate 40 | Le long du corps ; MI_<E>_Smoke. |
| `E_Drops` | Sprite GPU, Spawn Rate 300 | Location = tête ; Gravity -980 ; MI_<E>_Spark. |

## Archétype Burst

Explosion / jaillissement élémentaire (sans projectile).

Durée : 1 à 1,8 s · Budget : ≈ 120 particules + 1..2 maillages

| Émetteur | Type | Modules et valeurs |
| --- | --- | --- |
| `E_Charge` | Sprite, Burst 20 à t=0 | Point Attraction vers le centre en 0,15 s : anticipation. |
| `E_Core` | Sprite flipbook, Burst 2 à t=0,15 | MI_<E>_Flipbook, Size 300→500. |
| `E_Shell` | Mesh (SM_VFX_Sphere), 1 | Scale 0,2→2,5 en 0,3 s ; Param1 érosion ; MI_<E>_Mesh. |
| `E_Ring` | Mesh (SM_VFX_Ring_Flat), 1 | Scale 0,2→4 ; MI_<E>_Slash. |
| `E_Sparks` | Sprite, Burst 60 | Sphere velocity 800..2000 ; Drag 2 ; MI_<E>_Spark. |
| `E_Smoke` | Sprite, Burst 10 | MI_<E>_Smoke ; montée lente ; Lifetime 1,5. |
| `E_Distortion` | Sprite, Burst 1 | MI_VFX_Core_DistortionRing. |

## Archétype Aura

Aura / zone persistante : sceau au sol, particules montantes, rubans d'orbite.

Durée : boucle (détruite par le script) · Budget : ≈ 60 sprites/s + 2 rubans

| Émetteur | Type | Modules et valeurs |
| --- | --- | --- |
| `E_Sigil` | Sprite (Facing +Z), 1 persistante | MI_VFX_Core_Sigil teinté User.Color ; Sprite Rotation Rate 40°/s ; Size 400 x Scale. |
| `E_Rise` | Sprite, Spawn Rate 40 | Cylinder Location r=80 ; Velocity +Z 150..300 ; MI_<E>_Spark. |
| `E_Orbit` | Ribbon x 2 | Vortex Velocity 400 ; MI_<E>_Trail. |
| `E_Glow` | Sprite, 1 persistante | MI_<E>_Glow, Size 250, pulsation (Sine) 0,7..1. |

## Archétype Spikes

Pics qui jaillissent du sol en cercle ou en ligne (glace, sang durci).

Durée : 1,6 s · Budget : 8..14 maillages + ≈ 60 sprites

| Émetteur | Type | Modules et valeurs |
| --- | --- | --- |
| `E_Spikes` | Mesh (SM_VFX_Spike_Ice), Burst 8..14 | Ring Location r=200 (ou Line vers l'avant) ; Scale Z 0→1 en 0,12 s (ease-out) puis 1→0 à la fin ; rotation aléatoire ±15° ; MI_<E>_Mesh. |
| `E_Crack` | Sprite (Facing +Z), Burst 1 | MI_<E>_Ring, Size 600. |
| `E_Shards` | Sprite, Burst 40 | Velocity cône haut 400..900 ; Gravity -980 ; MI_<E>_Spark. |
| `E_Frost` | Sprite, Burst 8 | MI_<E>_Smoke au sol, Lifetime 1,5. |

## Archétype Bolt

Éclair entre deux points (Beam) avec branches, scintillement et impact.

Durée : 0,25 à 0,5 s · Budget : 3 beams + ≈ 30 sprites

| Émetteur | Type | Modules et valeurs |
| --- | --- | --- |
| `E_Beam` | Ribbon (Beam Emitter Setup), 3 beams | Beam Start = position système, Beam End = User.EndPoint ; Jitter Position 40 (régénéré toutes les 0,05 s) ; Width 20 ; MI_Thunder_Trail (sub-UV ligne aléatoire). |
| `E_Branches` | Ribbon (Beam), 4 beams courts | Début aléatoire le long du beam principal ; Width 8. |
| `E_Flicker` | Sprite, Spawn Rate 30 | MI_VFX_Core_Flash, taille aléatoire, Lifetime 0,05. |
| `E_EndSpark` | Sprite, Burst 20 | À User.EndPoint ; MI_Thunder_Spark. |
