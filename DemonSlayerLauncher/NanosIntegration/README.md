# Intégration nanos world (Phase 4)

Ce dossier accueillera le package **serveur** nanos world `dsrp-bridge` (Lua) qui relie le
serveur de jeu au backend. Rien n'est implémenté en Phase 1 ; ce document fixe le contrat.

## Principes

- Le serveur nanos world parle **uniquement au backend**, jamais au launcher.
- Il s'authentifie avec une **clé serveur** (`DSRP_SERVER_API_KEY`) stockée dans sa
  configuration, jamais distribuée aux joueurs. Côté API : routes `/api/game/server/*`,
  clé comparée en temps constant, IP du serveur en liste blanche.
- Toute progression (personnage, grade, monnaie…) est écrite **par le serveur** via l'API,
  qui valide chaque changement et le journalise.

## Flux prévu

1. **Liaison du compte (une fois)** — à la première connexion en jeu, le serveur demande à
   l'API un code court lié à l'`account_id` nanos world du joueur et l'affiche à l'écran ;
   le joueur le saisit dans le launcher → table `game_accounts`.
2. **JOUER** — le launcher vérifie statut serveur, whitelist, fichiers et version, demande un
   *join ticket* (2 min), puis lance nanos world vers `IP:port` (via Steam ou l'exécutable
   détecté ; paramètres lus depuis la configuration, jamais codés en dur).
3. **Connexion en jeu** — `Player.Subscribe("Spawn")` → l'API répond : whitelisté ?
   sanctionné ? personnage actif ? ticket de lancement récent ? Sinon, expulsion avec message.
4. **Sauvegarde** — le serveur pousse la progression à intervalles et à la déconnexion.

## À vérifier au démarrage de la Phase 4

- Paramètres de ligne de commande exacts du client nanos world pour se connecter
  directement à un serveur (et via `steam://run/<appid>//…`).
- API `HTTP.Request` disponible côté serveur dans la version de nanos world utilisée.
