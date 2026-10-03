# Demon Slayer RP — gamemode nanos world

| | |
| --- | --- |
| **Auteur** | NARSOU |
| **Version** | 0.1.0 (Phase 1 : architecture + Core) |
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
