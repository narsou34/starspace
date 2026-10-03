# Black Clover RP

Gamemode RP Garry's Mod inspiré de l'univers de Black Clover, écrit de zéro.

- **Auteur :** NARSOU
- **Version :** 0.1.0 (Phase 1 : architecture)

## Installation

Copier le dossier `black_clover` (celui qui contient `black_clover.txt`) dans :

```
garrysmod/gamemodes/black_clover/
```

Le nom du dossier doit être exactement `black_clover` (minuscules, sans espace),
identique au nom du fichier `black_clover.txt`.

## Arborescence

```
black_clover/
├── black_clover.txt           Déclaration du gamemode (nom, base, catégorie)
├── content/                   Matériaux, sons, modèles (monté automatiquement)
└── gamemode/
    ├── init.lua               Entrée serveur
    ├── cl_init.lua            Entrée client
    ├── shared.lua             Infos du gamemode + démarrage du loader
    ├── core/                  Noyau (chargé dans un ordre fixe)
    │   ├── sh_loader.lua      Chargement automatique selon le préfixe
    │   ├── sh_config.lua      Configuration partagée
    │   ├── sv_config.lua      Configuration serveur (BDD, logs) — jamais envoyée au client
    │   ├── sh_util.lua        Utilitaires (validation, formatage, recherche de joueur…)
    │   ├── sh_log.lua         Logs console + fichiers
    │   ├── sh_permissions.lua Staff / noclip
    │   ├── sh_network.lua     net.Receive sécurisé + anti-flood
    │   ├── sh_notify.lua      Notifications serveur → client
    │   ├── sv_database.lua    Abstraction SQLite/MySQL (Phase 3)
    │   ├── sv_player.lua      Spawn, équipement, restrictions sandbox
    │   └── cl_player.lua      Signal "client prêt", menus Q/C
    ├── config/                Données de contenu (magies, sorts, grimoires, factions, rangs)
    ├── systems/               Un dossier par système, chargés dans l'ordre de Config.Systems
    └── ui/                    Interfaces client (thème, HUD, grimoire…)
```

## Conventions

| Préfixe | Realm   | Envoyé au client |
|---------|---------|------------------|
| `sh_`   | partagé | oui              |
| `sv_`   | serveur | **non**          |
| `cl_`   | client  | oui              |

Un nouveau fichier placé dans `config/`, `systems/<système>/` ou `ui/` est chargé
automatiquement : aucun `include` à écrire.

## Commandes de test

- `bc_info` (console) : version, nombre de fichiers chargés, systèmes actifs.
