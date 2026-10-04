# NDR | Demon Slayer — Architecture technique

> Launcher Windows officiel du serveur **NDR | Demon Slayer** (nanos world).
> Ce document décrit l'architecture **complète** visée ; le développement se fait par phases
> (voir [ROADMAP](#10-feuille-de-route)). Seule la **Phase 1** est implémentée à ce stade.

---

## 1. Vue d'ensemble

```
┌──────────────────────────── PC du joueur (Windows) ────────────────────────────┐
│                                                                                │
│   NDR - Demon Slayer.exe  (Tauri 2)                                               │
│   ┌──────────────────────────────┐   invoke()   ┌──────────────────────────┐   │
│   │ Interface  React + TypeScript│ ───────────► │ Cœur Rust                │   │
│   │ (WebView2, aucun accès réseau│ ◄─────────── │ • client HTTPS (reqwest) │   │
│   │  direct, aucun token)        │   JSON       │ • session + refresh auto │   │
│   └──────────────────────────────┘              │ • Credential Manager     │   │
│                                                 │ • (P4) lancement nanos   │   │
│                                                 │ • (P6) mises à jour      │   │
│                                                 └────────────┬─────────────┘   │
└──────────────────────────────────────────────────────────────┼─────────────────┘
                                                               │ HTTPS (TLS)
                                                               ▼
                                     ┌──────────────────────────────────────────┐
                                     │ Reverse proxy (Caddy / nginx) — TLS      │
                                     └───────────────────┬──────────────────────┘
                                                         ▼
┌───────────────────────────────┐    HTTPS + clé    ┌──────────────────────────────┐
│ Serveur nanos world (Lua)     │ ────────────────► │ API backend (Node + Fastify) │
│ package `dsrp-bridge` (P4)    │ ◄──────────────── │ auth · RBAC · validation     │
│ whitelist, personnage, progr. │   JSON            │ rate limiting · logs         │
└───────────────────────────────┘                   └──────────────┬───────────────┘
                                                                   ▼
                                                    ┌──────────────────────────────┐
                                                    │ PostgreSQL 16                │
                                                    └──────────────────────────────┘
```

Principe directeur : **le launcher n'est jamais une source de vérité**. Il affiche et demande ;
le backend décide. Le serveur nanos world interroge lui aussi le backend, jamais le launcher.

---

## 2. Choix technologiques

### Launcher : **Tauri 2** (Rust + WebView2) + React/TypeScript

| Critère | Tauri 2 | Electron | C# WPF / WinUI |
|---|---|---|---|
| Taille de l'installateur | **~4–8 Mo** | 80–120 Mo | 1–5 Mo (+ runtime .NET) |
| RAM au repos | **~40–80 Mo** | 150–300 Mo | ~60–100 Mo |
| Design immersif (animations, brume, particules, typographie) | **CSS/Canvas moderne** | CSS/Canvas | XAML, plus laborieux |
| Sécurité | **Rust mémoire-sûr, permissions par capacité, CSP stricte** | Node exposé si mal configuré | Bon |
| Mises à jour auto + signature | **plugin updater officiel (signature ed25519)** | electron-updater | Squirrel/ClickOnce, vieillissant |
| Installateur `.exe` | **NSIS intégré** | electron-builder | WiX/MSIX à configurer |

**Pourquoi Tauri :** un `.exe` léger et rapide (exigence §31), une interface web qui permet un
rendu réellement « jeu » (exigence §3), et un cœur Rust où vivent toutes les opérations sensibles
(réseau, tokens, lancement du jeu, mises à jour). WebView2 est préinstallé sur Windows 10/11.

**Pourquoi React + TypeScript (sans framework UI) :** composants typés, écosystème mature, et
un design 100 % sur mesure — aucune bibliothèque de « dashboard » générique.

### Backend : **Node.js 22 + Fastify 5 + TypeScript + PostgreSQL 16**

- **Fastify** : très performant, plugins officiels (helmet, CORS, rate-limit), typé.
- **PostgreSQL** : relations fortes (comptes ↔ personnages ↔ whitelist ↔ tickets), JSONB pour
  les logs, transactions et verrous fiables (`SELECT … FOR UPDATE`).
- **SQL paramétré** via `pg` (pas d'ORM) : requêtes explicites, aucune concaténation → pas
  d'injection SQL. Migrations SQL versionnées.
- **zod** : validation stricte de toutes les entrées.
- **argon2id** : hachage des mots de passe (paramètres OWASP).
- **jose** : JWT HS256 courts.

### Intégration nanos world : **package Lua serveur** (Phase 4)

nanos world exécute ses scripts serveur en Lua ; le package appelle l'API via `HTTP.Request`
avec une **clé de serveur** dédiée (jamais distribuée aux joueurs).

---

## 3. Arborescence

```
DemonSlayerLauncher/
├── Launcher/                       Application Windows (Tauri)
│   ├── src/                        Interface React
│   │   ├── api/                    bridge.ts (→ Rust), webBridge.ts (dev navigateur)
│   │   ├── auth/                   AuthContext (état de session côté UI)
│   │   ├── components/             TitleBar, Background, Particles, Form, Toasts…
│   │   ├── models/                 Types partagés
│   │   ├── services/               Appels métier (userService…)
│   │   ├── views/                  Écrans (auth/, Home, Account, Shell…)
│   │   ├── styles/                 Design system (tokens, contrôles, pages)
│   │   └── assets/                 Illustration de fond
│   └── src-tauri/                  Cœur Rust
│       ├── src/config.rs           Configuration (aucune URL codée en dur)
│       ├── src/api.rs              Client HTTPS
│       ├── src/session.rs          Tokens, refresh, Credential Manager
│       ├── src/commands/           Commandes exposées à l'interface
│       ├── (P4) src/game/          Détection + lancement nanos world
│       ├── (P6) src/updates/       Mises à jour, SHA-256, rollback
│       ├── capabilities/           Permissions minimales de la fenêtre
│       └── resources/              launcher.config.json (livré à l'installation)
│
├── Backend/                        API
│   ├── src/config/                 Variables d'environnement validées
│   ├── src/database/               Pool, transactions, migrations
│   ├── src/auth/                   Inscription, connexion, sessions, mot de passe
│   ├── src/players/                Profil, sessions du compte
│   ├── src/security/               RBAC, journal de sécurité
│   ├── src/launcher/               Configuration publique du launcher
│   ├── (P2) src/characters/ src/whitelist/
│   ├── (P3) src/tickets/ src/news/ src/notifications/
│   ├── (P4) src/server/ src/game/  Statut serveur, API serveur nanos
│   ├── (P5) src/admin/             Panel staff
│   ├── migrations/                 SQL versionné
│   └── test/                       Tests d'intégration (PostgreSQL réel)
│
├── NanosIntegration/               (P4) Package Lua serveur nanos world
└── Documentation/
```

---

## 4. Modèle de sécurité

### 4.1 Authentification

| Élément | Choix |
|---|---|
| Mot de passe | argon2id (19 Mio, t=2), jamais stocké ni journalisé en clair |
| Access token | JWT HS256, **15 min**, contient seulement `sub` (ID) et `sid` (session) |
| Refresh token | 384 bits aléatoires, **seul son SHA-256 est stocké** ; 30 j (« Rester connecté ») ou 12 h |
| Rotation | Chaque refresh émet un nouveau token ; l'ancien hash est conservé |
| Vol de token | Présenter un token déjà remplacé **révoque la session** (`token_reuse`) |
| Révocation | Chaque requête relit la session et le compte en base → déconnexion / suspension immédiate |
| Rôle | Toujours relu en base, jamais lu depuis le token |
| Brute-force | Rate limit par IP (10/min sur l'auth) + verrouillage 15 min après 5 échecs par identifiant, 30 par IP |
| Énumération | Même message et même coût (hash factice) pour un compte inconnu ou un mauvais mot de passe ; « mot de passe oublié » répond toujours pareil |
| Réinitialisation | Code `XXXX-XXXX-XXXX` (60 bits), haché, 15 min, usage unique, révoque toutes les sessions |
| Transport | HTTPS obligatoire (le launcher refuse `http://` hors `localhost`) ; HSTS via helmet |

### 4.2 Côté launcher

- **Les tokens ne sont jamais exposés au JavaScript.** L'interface appelle des commandes Rust ;
  seul Rust connaît les tokens. Une faille XSS ne permet donc pas de les voler.
- Le refresh token est stocké dans le **Gestionnaire d'identification Windows** (chiffré par
  Windows pour la session utilisateur), uniquement si « Rester connecté » est coché.
- La passerelle générique `api_request` n'accepte que des chemins `/api/…` validés et **refuse
  `/api/auth/*`** (gérés par des commandes dédiées).
- Les refresh concurrents sont sérialisés par un verrou (sinon la détection de vol se
  déclencherait à tort) — couvert par un test d'intégration.
- CSP stricte (`script-src 'self'`, `connect-src` limité à l'IPC Tauri), prototypes figés,
  capacités Tauri minimales (fenêtre uniquement ; pas de shell, pas de système de fichiers).
- Liens externes : seuls `https://` et `mailto:` sont ouverts.

### 4.3 Côté backend

- Validation **zod** de chaque entrée ; SQL **paramétré** partout.
- Les réponses ne contiennent jamais de hash ni de donnée interne (`toPublicUser`).
- **RBAC** : `player < helper < moderator < admin < superadmin`, permissions fines
  (`whitelist.review`, `tickets.manage`, `sanctions.manage`…) via `requirePermission()`.
- `helmet` (HSTS, nosniff, CSP…), `bodyLimit` 256 Ko, en-têtes d'autorisation masqués dans les logs.
- **Journal de sécurité** (`security_logs`) : inscription, connexion, échecs, blocages,
  déconnexions, vol de token, changements / réinitialisations de mot de passe.
- Secrets uniquement via variables d'environnement (`.env`, jamais commité).

### 4.4 Ce que le launcher ne peut **jamais** faire

Modifier la base, donner une whitelist, un grade, une faction, des stats ou de la monnaie.
Ces opérations n'existent que sous forme de routes staff protégées par RBAC (Phase 5) ou
d'appels du serveur nanos world authentifiés par clé serveur (Phase 4).

---

## 5. Base de données

### Phase 1 (implémentée — `migrations/001_init_auth.sql`)

```
users ──┬── sessions            (refresh tokens hachés, appareil, IP, expiration, révocation)
        ├── password_resets     (codes hachés, usage unique)
        └── security_logs       (événements de sécurité, JSONB)
login_attempts                  (anti brute-force, par identifiant et par IP)
schema_migrations               (suivi des migrations)
```

### Phases suivantes (prévu)

```
users 1─┬─* characters ─────────* character_history     (P2)
        ├─1 whitelists                                    (P2) statut courant
        ├─* whitelist_applications ─* application_reviews (P2)
        ├─* tickets ─* ticket_messages ─* ticket_attachments (P3)
        ├─* notifications                                  (P3)
        ├─* sanctions                                      (P5)
        ├─* game_accounts       (lien compte ↔ ID nanos world / Steam) (P4)
        └─* staff_logs          (acteur, action, cible, avant/après)   (P5)
news, changelog_versions ─* changelog_entries             (P3)
servers ─* server_status_snapshots                         (P4, multi-serveurs prévu)
launcher_releases ─* release_files (sha256, taille)        (P6)
```

Extensions futures prévues sans refonte : boutique, codes, récompenses, classements,
cosmétiques (tables rattachées à `users` / `characters`).

---

## 6. API

Convention : JSON, erreurs `{ "error": { "code", "message", "details?" } }`, messages en français.

| Méthode | Route | Auth | Phase |
|---|---|---|---|
| GET | `/api/health` | — | 1 ✅ |
| GET | `/api/launcher/config` | — | 1 ✅ |
| POST | `/api/auth/register` | — | 1 ✅ |
| POST | `/api/auth/login` | — | 1 ✅ |
| POST | `/api/auth/refresh` | refresh token | 1 ✅ |
| POST | `/api/auth/logout` | refresh token | 1 ✅ |
| POST | `/api/auth/logout-all` | access | 1 ✅ |
| POST | `/api/auth/forgot-password` | — | 1 ✅ |
| POST | `/api/auth/reset-password` | code | 1 ✅ |
| GET | `/api/user/profile` | access | 1 ✅ |
| GET | `/api/user/sessions` | access | 1 ✅ |
| DELETE | `/api/user/sessions/:id` | access | 1 ✅ |
| POST | `/api/user/password` | access | 1 ✅ |
| GET | `/api/user/characters` | access | 2 |
| GET/POST | `/api/user/whitelist` | access | 2 |
| GET/POST | `/api/tickets`, `/api/tickets/:id` | access | 3 |
| GET | `/api/news`, `/api/changelog`, `/api/notifications` | access | 3 |
| GET | `/api/server/status` | — | 4 |
| POST | `/api/game/join-ticket` | access | 4 |
| * | `/api/game/server/*` | clé serveur nanos | 4 |
| * | `/api/admin/*` | access + permission RBAC | 5 |
| GET | `/api/launcher/releases/latest` | — | 6 |

---

## 7. Liaison des identités (Phase 4)

```
Compte launcher (users.id)
        │  liaison unique via code à usage unique affiché en jeu
        ▼
Compte nanos world (account_id) / Steam ID  ── game_accounts
        │
        ▼
Serveur nanos : à la connexion d'un joueur → GET /api/game/server/players/{account_id}
        │        (clé serveur) → whitelist ? sanction ? personnage actif ?
        ▼
Personnage → progression écrite par le serveur via l'API (jamais par le launcher)
```

Le bouton **JOUER** demandera un *join ticket* court (2 min) : le serveur nanos pourra vérifier
qu'un joueur qui se connecte vient bien de passer par le launcher (contrôle additionnel, le
contrôle principal restant la whitelist côté serveur).

---

## 8. Mises à jour (Phase 6)

- Manifeste signé (`latest.json`) : version, URL, **SHA-256**, signature ed25519
  (plugin updater Tauri, clé publique embarquée, clé privée uniquement en CI).
- Téléchargement en fichier temporaire avec reprise (`Range`), vérification SHA-256 + signature,
  installation, **rollback** vers la version précédente si le démarrage échoue.
- Version minimale imposée par l'API (`minLauncherVersion`) pour bloquer les clients obsolètes.

---

## 9. Performance

- Exe Rust optimisé (`lto`, `opt-level = "s"`, `strip`, `panic = "abort"`).
- Interface ≈ 80 Ko gzip ; polices latines uniquement embarquées (les kanji utilisent
  Yu Mincho, installée avec Windows).
- Animations GPU (transform/opacity), particules ~30 i/s mises en pause quand la fenêtre est
  masquée, désactivées si « réduire les animations » est actif.
- Aucune boucle de polling serrée : ping API toutes les 30–60 s, ignoré fenêtre masquée.

---

## 10. Feuille de route

| Phase | Contenu | État |
|---|---|---|
| **1** | Fenêtre, design, connexion / inscription / mot de passe oublié, compte, sessions, API, sécurité | ✅ |
| 2 | Profil immersif, whitelist (candidature), personnages | à venir |
| 3 | Tickets, notifications, actualités, changelog | à venir |
| 4 | Statut serveur temps réel, bouton JOUER, détection / lancement nanos world, liaison d'identité | à venir |
| 5 | Panel staff : joueurs, whitelist, tickets, sanctions, logs, permissions | à venir |
| 6 | Auto-update signé, vérification de fichiers, installateur finalisé | à venir |
| 7 | Optimisation, audit de sécurité, tests end-to-end | à venir |
