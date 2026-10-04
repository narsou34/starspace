# Demon Slayer RP — gamemode nanos world

| | |
| --- | --- |
| **Auteur** | NARSOU |
| **Version** | 0.1.0 (Core + souffles / arts démoniaques) |
| **Type de package** | `game-mode` |
| **Compatibilité** | nanos world `1.144` et plus (`compatibility_version` du Package.toml) |
| **Dépendances** | aucune : tout est développé de zéro |

## Installation

1. Copier le dossier `demon-slayer-rp/` dans le dossier `Packages/` du serveur :

   ```
   NanosWorldServer.exe
   Config.toml
   Packages/
   └── demon-slayer-rp/      <- ce dossier (le nom = identifiant du package)
   ```

2. Dans le `Config.toml` du serveur (généré au premier lancement), section `[game]` :

   ```toml
   [game]
       map =           "default-testing-map"
       game_mode =     "demon-slayer-rp"
       packages = [
       ]
   ```

   Ou bien sans modifier le fichier : `NanosWorldServer.exe --game_mode demon-slayer-rp --map default-testing-map`

3. Optionnel : désactiver le mode debug sans toucher au code :

   ```toml
   [custom_settings]
       debug_mode = false
   ```

## Arborescence

```
demon-slayer-rp/
├── Package.toml                 Métadonnées + réglages game-mode
├── Shared/                      Exécuté sur le serveur ET les clients (téléchargé par les joueurs)
│   ├── Index.lua                Point d'entrée partagé (chargé en premier)
│   ├── Core/
│   │   ├── Namespace.lua        Table globale DS + version (lue depuis Package.toml)
│   │   ├── Utils.lua            Utilitaires (temps, token bucket, chaînes, tables)
│   │   ├── Logger.lua           Logs par niveau / module + historique + sinks
│   │   ├── EventBus.lua         Bus d'évènements interne entre modules
│   │   ├── ModuleManager.lua    Chargement des modules : dépendances, Init/Start/Shutdown
│   │   ├── Validator.lua        Validation des données réseau par schéma
│   │   └── NetEvents.lua        Contrat réseau : liste de TOUS les évènements client/serveur
│   └── Config/
│       └── Core.lua             Configuration générale (debug, logs, langue)
├── Server/                      Jamais envoyé aux joueurs
│   ├── Index.lua                Point d'entrée serveur (config, modules, bannière)
│   ├── Config/
│   │   ├── Server.lua           Bienvenue, handshake, spawn temporaire
│   │   ├── Permissions.lua      Groupes staff + Account ID du staff
│   │   └── Security.lua         Limites réseau, score d'infractions, expulsion
│   └── Core/
│       ├── Security.lua         Limiteur de débit + score d'infractions
│       ├── Network.lua          Couche réseau sécurisée (Handle / Send / Broadcast)
│       ├── Permissions.lua      Groupes, héritage, jokers ("admin.*")
│       ├── PlayerManager.lua    Sessions joueurs + handshake + rechargement à chaud
│       ├── Spawn.lua            Spawn TEMPORAIRE (remplacé en Phase 4)
│       ├── Commands.lua         Registre des commandes chat + console
│       └── BaseCommands.lua     Commandes de diagnostic (/ds_help, /ds_info...)
└── Client/
    ├── Index.lua                Point d'entrée client
    └── Core/
        ├── Network.lua          Envoi / réception côté client
        ├── Session.lua          Session du joueur local (reçue du serveur)
        └── Diagnostics.lua      Commandes de la console du jeu (ds_ping, tests)
```

Les systèmes des phases suivantes iront dans `Server/Systems/<Système>/`,
`Client/UI/`, `Client/Effects/`, etc., et seront déclarés dans `MODULE_FILES`
de `Server/Index.lua` / `Client/Index.lua`.

## Principes d'architecture

- **Ordre de chargement nanos world** : `Shared/Index.lua` → `Server|Client/Index.lua` → évènement `Load`.
- **Modules** : chaque système est un module `DS.Module(nom, { dependencies = {...} })`
  avec `Init` / `Start` / `Shutdown`. L'ordre est calculé selon les dépendances.
  Un module en erreur n'arrête que les modules qui dépendent de lui.
- **Communication interne** : `DS.Bus.On / Emit` (ex. `"Player:Loaded"`), pas d'appels directs entre systèmes.
- **Communication réseau** : uniquement via `DS.Net`, sur des évènements déclarés dans `Shared/Core/NetEvents.lua`.
- **Serveur autoritaire** : chaque message client passe par débit global → débit de l'évènement →
  état de session → permission → validation des arguments, avant d'atteindre le code de jeu.
  Les handlers reçoivent une **session**, jamais un `Player` brut.
- **Configuration** séparée du code : `Shared/Config/` (visible des joueurs) et `Server/Config/` (privée).

### Cycle de vie d'un joueur

```
Player "Spawn"  -> session "connecting"            Bus : Player:Connecting
Player "Ready"  -> session "ready" + Handshake     Bus : Player:Ready   (spawn du personnage)
HandshakeAck    -> session "loaded" + bienvenue    Bus : Player:Loaded
Player "Destroy"-> session supprimée               Bus : Player:Leaving / Player:Left
```

## Commandes

### Chat (en jeu)

| Commande | Permission | Description |
| --- | --- | --- |
| `/ds_help` | `core.help` | Commandes disponibles pour vous |
| `/ds_info` | `core.info` | Version, joueurs, uptime, modules |
| `/ds_whoami` | `core.whoami` | Votre session, dont votre **Account ID** |
| `/ds_players` | `admin.players` | Liste des joueurs |
| `/ds_modules` | `admin.modules` | État de chaque module |
| `/ds_netstats` | `admin.netstats` | Statistiques réseau et anti-exploit |
| `/ds_setgroup [id\|nom] [groupe]` | `admin.setgroup` | Change le groupe staff (jusqu'à la déconnexion) |

### Console du serveur

Les mêmes commandes, sans `/` et avec tous les droits : `ds_info`, `ds_players`,
`ds_modules`, `ds_netstats`, `ds_setgroup 1 superadmin`, `ds_help`.

### Console du jeu (client)

| Commande | Description |
| --- | --- |
| `ds_ping` | Latence aller-retour avec le serveur |
| `ds_session` | Session reçue du serveur |
| `ds_netstats` | Statistiques réseau du client |
| `ds_test_spam [n]` | *(debug)* Envoie n Ping sans limitation → teste l'anti-spam |
| `ds_test_invalid` | *(debug)* Envoie 3 messages invalides → teste la validation |

## Devenir super-admin de façon permanente

1. En jeu : `/ds_whoami` → noter l'Account ID.
2. Dans `Server/Config/Permissions.lua` :

   ```lua
   Staff = {
       ["VOTRE-ACCOUNT-ID"] = "superadmin",
   },
   ```

3. Console serveur : `package reload demon-slayer-rp`.

## Souffles et arts démoniaques

- **13 souffles** (`Shared/Config/BreathingStyles.lua`) : eau, flamme, tonnerre, vent, pierre,
  brume, amour, serpent, insecte, fleur, son, bête, soleil — 5 techniques chacun.
- **6 arts démoniaques** (`Shared/Config/DemonArts.lua`) : sang, temari, fils, glace, biwa, rêve —
  5 compétences + un passif chacun.
- Touches par défaut **Q E R F X C** (5 et 6 = techniques spéciales), modifiables dans
  *Paramètres > Touches* ; liste dans `Shared/Config/Abilities.lua`.
- Ressources : Souffle (pourfendeurs) / Énergie démoniaque (démons), `Config.Resources`.
- Régénération des démons (`Config.Factions.demons.Regeneration`), bloquée après un coup
  et plus longtemps après une technique de souffle (`BlockRegenMs`, très long pour Soleil / Insecte).
- Serveur autoritaire : le client n'envoie que l'emplacement (1-5) ; cibles, dégâts, coûts
  et recharges sont calculés par le serveur. Effets visuels/sons séparés (`Client/Systems/Effects.lua`).

| Commande | Permission | Description |
| --- | --- | --- |
| `/ds_setfaction [joueur\|moi] [pourfendeur\|demon\|aucune]` | `admin.setfaction` | Change la faction |
| `/ds_givebreathing [joueur\|moi] [souffle]` | `admin.givebreathing` | Donne un souffle |
| `/ds_givedemonart [joueur\|moi] [art]` | `admin.givedemonart` | Donne un art démoniaque |
| `/ds_souffles`, `/ds_arts`, `/ds_skills` | `core.skills` | Listes et vos techniques |
| `/ds_heal [joueur\|moi]` | `admin.heal` | Soin + ressource pleine |
| `/ds_npc`, `/ds_clearnpc` | `admin.npc` | Mannequins d'entraînement |

Faction et souffle/art ne sont pas encore sauvegardés (base de données : Phase 5).

## Souffle de l'Eau (rework : techniques scriptées)

| Touche | Technique | Comportement | Zone de touche |
| --- | --- | --- | --- |
| Q | Grande vague | une vague se lève et déferle | boîte qui avance et s'élargit (balayage continu) |
| E | Tourbillon | vortex qui aspire, soulève, puis explose | cylindre, dégâts par tick + attraction |
| R | Prison d'eau | sphère lancée ; la cible flotte, emprisonnée, puis la bulle éclate | projectile balayé, immobilisation 3 s |
| F | Courant fulgurant | élan, vitesse x1.8, traînée d'eau, invulnérable pendant l'élan | sphère qui suit le lanceur |
| X | Tsunami (niv. 10) | canalisation invulnérable, mur d'eau géant, explosion | mur mobile + explosion finale |
| C | Dragon changeant (niv. 20) | dragon d'eau ondulant, segmenté, impact massif | sphère balayée le long de la trajectoire |

- **Données** : `Shared/Config/Breathing/Water.lua` (timings, dégâts, zones, effets, sons, caméra).
  Serveur et clients lisent les mêmes valeurs ; la trajectoire visible est la zone qui touche
  (`Shared/Systems/TechniqueMath.lua`).
- **Serveur** : `Server/Systems/Techniques/` — `Engine.lua` (chronologie, limites de touches),
  `Hitboxes.lua` (sphère, cylindre, boîte orientée, capsule, arc), `Status.lua` (immobilisation,
  invulnérabilité, toujours rétablies), `Water.lua` (les 6 comportements).
- **Client** : `Client/Systems/Fx/` — `FxCore.lua` (particules, sons, caméra, chorégraphies,
  budget de particules) et `Water.lua` (effets multicouches, traînée du katana sur `hand_r`).
- **Prérequis** vérifiés côté serveur : `Requirements = { Level = 10 }` (et `Permission` possible).
  `/ds_setlevel [joueur|moi] [niveau]` en attendant la progression (Phase 8).
- **Performance** : une seule boucle serveur (50 ms) active uniquement pendant une technique ;
  durée de vie sur chaque particule, plafond `Config.Vfx.MaxActiveParticles`, qualité et
  distance d'affichage dans `Shared/Config/Vfx.lua`.
- **Pack d'effets externe** : remplacer les chemins de `WATER_FX` / `WATER_SFX` en haut de
  `Water.lua` par ceux d'un Asset Pack nanos world (et l'ajouter à `assets_requirements`).
- **Limites actuelles** : pas de modèle de katana (la traînée suit la main droite), pas de
  ralenti ni de tremblement de caméra dans l'API (remplacés par FOV / recul de caméra),
  le projectile ne collisionne pas avec les murs (le serveur n'a pas de Trace).

## Ajouter un module (exemple)

```lua
-- Server/Systems/Exemple/Index.lua
local Exemple = DS.Module("Exemple", { dependencies = { "PlayerManager" } })

function Exemple:Init()
    DS.Bus.On("Player:Loaded", function(session)
        session:Notify("Bienvenue " .. session.name, "success")
    end)
end

return Exemple
```

Puis ajouter `"Systems/Exemple/Index.lua"` à `MODULE_FILES` dans `Server/Index.lua`.

## Ajouter un évènement réseau (exemple)

```lua
-- Déclaration (Shared) : le serveur validera automatiquement les arguments
DS.NetEvents.Define("C2S", "ChoisirFaction", {
    args = { { name = "faction", type = "string", enum = { "slayers", "demons" } } },
    rate = { max = 1, windowMs = 2000 },
    state = "loaded",
})

-- Serveur
DS.Net.Handle("ChoisirFaction", function(session, faction) ... end)

-- Client
DS.Net.Send("ChoisirFaction", "slayers")
```
