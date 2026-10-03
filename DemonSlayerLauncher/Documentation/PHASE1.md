# Phase 1 — Launcher de base

## Ce qui est livré

**Launcher (`Launcher/`)**
- Fenêtre Windows sans bordure, barre de titre personnalisée (réduire / agrandir / fermer, déplacement)
- Une seule instance : relancer l'exe remet la fenêtre au premier plan
- Écran de démarrage, fond immersif (illustration, brume animée, braises, motif seigaiha, grain)
- Connexion (pseudo **ou** e-mail), « Rester connecté », inscription avec indicateur de robustesse,
  mot de passe oublié → code par e-mail → nouveau mot de passe
- Boutons Discord / Steam présents mais désactivés (« bientôt »)
- Après connexion : « Bienvenue, *pseudo*. », sidebar, page d'accueil (titre, statut des services
  en direct, parcours joueur, bouton JOUER — activé en Phase 4), page **Mon compte**
  (identité, informations, changement de mot de passe, appareils connectés, déconnexion à distance,
  déconnexion de tous les appareils)
- Les sections des phases suivantes sont visibles et clairement marquées « bientôt »

**API (`Backend/`)** — voir le tableau des routes dans [ARCHITECTURE.md](./ARCHITECTURE.md#6-api).

**Tests**
- Backend : 21 tests d'intégration sur PostgreSQL réel (inscription, connexion, verrouillage,
  rotation + détection de vol de refresh token, révocation, suspension, mot de passe oublié,
  changement de mot de passe, rate limiting, erreurs).
- Rust : 5 tests unitaires (validation d'URL de config, filtrage des chemins d'API) + 2 tests
  d'intégration contre l'API (cycle de session complet, refresh concurrent, restauration depuis le
  coffre Windows, erreurs lisibles).

---

## Prérequis (Windows)

| Outil | Version | Lien |
|---|---|---|
| Node.js | 22 LTS | https://nodejs.org |
| Rust | stable | https://rustup.rs |
| Visual Studio Build Tools | « Développement Desktop en C++ » | https://visualstudio.microsoft.com/visual-cpp-build-tools/ |
| PostgreSQL | 16 | https://www.postgresql.org/download/windows/ (ou Docker) |
| WebView2 | préinstallé sur Windows 10/11 | — |

---

## 1. Lancer l'API

```powershell
cd DemonSlayerLauncher\Backend
copy .env.example .env
```

Éditez `.env` :

```ini
DATABASE_URL=postgres://dsrp:VOTRE_MOT_DE_PASSE@127.0.0.1:5432/dsrp
JWT_SECRET=<64 caractères aléatoires>
```

Pour générer `JWT_SECRET` :

```powershell
node -e "console.log(require('crypto').randomBytes(64).toString('base64url'))"
```

Créez la base (dans `psql` en tant que superutilisateur) :

```sql
CREATE ROLE dsrp LOGIN PASSWORD 'VOTRE_MOT_DE_PASSE';
CREATE DATABASE dsrp OWNER dsrp;
```

Puis :

```powershell
npm install
npm run migrate        # crée les tables
npm run dev            # API sur http://127.0.0.1:8080
```

Vérification : http://127.0.0.1:8080/api/health → `{"status":"ok"}`.

> **Alternative Docker** : depuis `DemonSlayerLauncher/`, définissez `POSTGRES_PASSWORD`, puis
> `docker compose up -d` (PostgreSQL + API, migrations automatiques).

Créer le premier compte administrateur :

```powershell
npm run user:create -- --username Narsou --email narsou@exemple.fr --role superadmin
```

(un mot de passe aléatoire est affiché une fois ; ou définissez `CREATE_USER_PASSWORD`).

**Mot de passe oublié en local :** sans `SMTP_URL`, le code est écrit dans la console de l'API
(en développement uniquement).

## 2. Lancer le launcher en développement

```powershell
cd DemonSlayerLauncher\Launcher
npm install
npm run tauri:dev
```

La fenêtre native s'ouvre et se connecte à `http://127.0.0.1:8080`
(surchargeable avec la variable `DSRP_API_URL` en développement).

*Travailler uniquement le design :* `npm run dev` puis http://localhost:1420 dans un navigateur
(transport de développement, tokens en mémoire, rechargement = déconnexion).

## 3. Produire `Demon Slayer RP.exe` et l'installateur

1. Renseignez l'adresse **HTTPS** de votre API de production dans
   `Launcher/src-tauri/resources/launcher.config.json` :

   ```json
   { "apiBaseUrl": "https://api.votre-domaine.fr", "requestTimeoutSeconds": 15 }
   ```

2. Compilez :

   ```powershell
   npm run tauri:build
   ```

3. Résultats :
   - `src-tauri\target\release\Demon Slayer RP.exe`
   - `src-tauri\target\release\bundle\nsis\Demon Slayer RP_0.1.0_x64-setup.exe` — installateur
     (raccourcis Bureau + menu Démarrer, désinstallation, lancement en fin d'installation)

**Via GitHub Actions** : le workflow `.github/workflows/demon-slayer-launcher.yml` compile
l'installateur sur un runner Windows à chaque push touchant `DemonSlayerLauncher/` et le publie
en artefact `DemonSlayerRP-Windows`. Définissez la variable de dépôt `DSRP_API_URL` (Settings →
Secrets and variables → Actions → *Variables*) pour y injecter l'adresse de l'API.

Un joueur peut surcharger l'adresse sans recompiler en créant
`%APPDATA%\com.demonslayerrp.launcher\launcher.config.json`.

## 4. Lancer les tests

```powershell
# API (base de test dédiée — elle est vidée à chaque test)
cd Backend
$env:TEST_DATABASE_URL="postgres://dsrp:MOT_DE_PASSE@127.0.0.1:5432/dsrp_test"
npm test

# Rust (unitaires)
cd ..\Launcher\src-tauri
cargo test

# Rust (intégration, API locale démarrée)
$env:DSRP_TEST_API="http://127.0.0.1:8080"
cargo test -- --ignored --test-threads=1
```

## 5. Mise en production de l'API (résumé)

- Serveur Linux + PostgreSQL, API derrière **Caddy** ou **nginx** avec certificat TLS
  (Let's Encrypt), `TRUST_PROXY=true`, `NODE_ENV=production`.
- `CORS_ORIGINS` vide (le .exe n'en a pas besoin).
- `SMTP_URL` configuré pour les e-mails de réinitialisation.
- Sauvegardes PostgreSQL quotidiennes.

## Limites connues de la Phase 1

- Discord OAuth / Steam : prévus, boutons désactivés.
- Le bouton JOUER affiche un message : lancement de nanos world en Phase 4.
- Pas encore de signature de code Windows : SmartScreen peut avertir au premier lancement de
  l'installateur (un certificat de signature de code sera nécessaire pour la distribution publique).
- Pas d'e-mail de vérification à l'inscription (prévu avec la mise en production SMTP).
