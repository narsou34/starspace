# NDR | Demon Slayer — Système visuel

## Principes
- **Illustration + panneaux + espace vide** : le décor illustré occupe l'écran, l'interface flotte dessus
  en panneaux translucides teintés (jamais du noir uni).
- **Une Respiration par page** : chaque page a son ambiance (couleurs + décor). Les couleurs
  se transforment en douceur d'une page à l'autre (`@property`).
- **JOUER** est toujours l'élément le plus fort : dégradé « flamme » qui contraste avec toutes les ambiances.

## Thèmes (`src/theme/themes.ts`)
| Thème | Couleurs | Pages |
|---|---|---|
| Eau | bleu / cyan | Accueil, Personnage, connexion |
| Vent | turquoise / bleu | Serveur |
| Brume | violet / bleu clair | Profil |
| Flamme | rouge / orange | Actualités |
| Tonnerre | jaune / violet | Whitelist |
| Lune | indigo / or | Tickets |
| Soleil | doré / rouge | Boutique, événements |
| Démon | rouge / violet | Paramètres |

Le joueur peut imposer un thème dans **Paramètres → Thème des Respirations**.
Ajouter un thème = ajouter une entrée dans `THEMES`.

## Fonds illustrés (`src/scenery/Backdrop.tsx`)
| Illustration | Pages | Ambiance |
|---|---|---|
| Akaza (œil) | Accueil, Serveur, Tickets | Eau, Vent, Lune |
| Gyomei | Profil, Whitelist, Actualités, Boutique | Soleil, Tonnerre, Flamme |
| Kokushibo | Connexion, Personnage, Paramètres | Brume, Démon |

Image nette d'un côté, copie floutée sur toute la fenêtre, teinte de la Respiration,
brume, particules et parallaxe ; fondu enchaîné entre deux illustrations.
Ajouter un fond : déposer l'image dans `src/assets/`, la déclarer dans `ART`, puis l'associer
à une page dans `views/navigation.ts`.

## Mode aperçu
Bouton « Découvrir en mode aperçu » sur l'écran de connexion, uniquement si le launcher est compilé
avec `VITE_DEMO_MODE=true` (activé dans le workflow GitHub pour les builds de test). Il permet de
visiter toute l'interface sans serveur ; rien n'est envoyé. **À désactiver pour la version publique.**

## Illustrations des cartes (`src/scenery/`)
SVG procéduraux et déterministes (aucune image externe) : ciel, étoiles, lune + lumière volumétrique,
montagnes en couches (parallaxe), brume, et une scène par page : `mountains` (Fuji), `village`
(maisons + lanternes + pagode), `forest` (bambous), `shrine` (torii), `lake` (reflets).
Particules par thème : lucioles, braises, pétales, étincelles, feuilles.

## Performance
Animations GPU (transform/opacity), particules ~30 i/s en pause fenêtre masquée.
Réglages : qualité des animations (élevée / réduite / aucune), parallaxe, particules ;
la préférence système « réduire les animations » est respectée.

## Résolutions
L'échelle typographique suit la fenêtre (`html { font-size: clamp(...) }`) :
vérifié en 1280×720, 1920×1080 et 2560×1440.

## Données d'aperçu
Les écrans des phases 2 à 4 (personnage, whitelist, tickets, actualités, statut serveur, boutique)
affichent des données d'exemple (`src/models/preview.ts`) marquées « Aperçu ». Elles seront
remplacées par l'API au fil des phases.
