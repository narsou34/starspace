# NDR | Demon Slayer — Launcher

Launcher Windows officiel du serveur **NDR | Demon Slayer** sur nanos world :
compte joueur, whitelist, personnages, tickets, actualités, statut serveur et bouton **JOUER**.

| Dossier | Contenu |
|---|---|
| [`Launcher/`](./Launcher) | Application Windows — Tauri 2 (Rust) + React/TypeScript |
| [`Backend/`](./Backend) | API — Node.js 22, Fastify, PostgreSQL |
| [`NanosIntegration/`](./NanosIntegration) | Package serveur nanos world (Phase 4) |
| [`Documentation/`](./Documentation) | [Architecture](./Documentation/ARCHITECTURE.md) · [Guide Phase 1](./Documentation/PHASE1.md) |

## Démarrage rapide

```bash
# 1. API
cd Backend && cp .env.example .env   # renseigner DATABASE_URL et JWT_SECRET
npm install && npm run migrate && npm run dev

# 2. Launcher (fenêtre native)
cd ../Launcher && npm install && npm run tauri:dev

# 3. Exe + installateur
npm run tauri:build
```

Détails, prérequis Windows et tests : [Documentation/PHASE1.md](./Documentation/PHASE1.md).

## État

**Phase 1 terminée** — fenêtre, design, connexion / inscription / mot de passe oublié,
compte et sessions, API sécurisée. Phases 2 à 7 : voir la
[feuille de route](./Documentation/ARCHITECTURE.md#10-feuille-de-route).
