--[[
    Black Clover RP — core/sh_config.lua
    Realm : PARTAGÉ

    Configuration GÉNÉRALE partagée entre serveur et client.

    ⚠ Ce fichier est envoyé à tous les clients : n'y mettez JAMAIS
      de mot de passe, d'identifiant de base de données ou de clé d'API.
      Ces données vont dans core/sv_config.lua.

    Le contenu du jeu (magies, sorts, grimoires, factions, rangs…)
    est configuré dans le dossier config/.
]]

BlackClover.Config = BlackClover.Config or {}
local Config = BlackClover.Config

-- ─── Général ────────────────────────────────────────────────────────────
-- Affiche les messages de debug dans la console. Mettre false en production.
Config.Debug = true

-- Nom affiché du serveur (HUD, menus…)
Config.ServerName = "Black Clover RP"

-- ─── Systèmes ───────────────────────────────────────────────────────────
-- Ordre de chargement des dossiers de systems/.
-- Un système dépendant d'un autre doit être placé APRÈS lui.
-- Commentez une ligne pour désactiver un système.
Config.Systems = {
    "character",    -- Phase 2  : personnages
    "progression",  -- Phase 8  : niveau, XP, statistiques
    "mana",         -- Phase 4  : mana
    "magic",        -- Phase 5  : types de magie
    "grimoire",     -- Phase 6  : grimoires
    "spells",       -- Phase 7  : sorts
    "factions",     -- Phase 9  : factions
    "ranks",        -- Phase 10 : rangs
    "inventory",    -- Phase 11 : inventaire
    "quests",       -- Phase 12 : quêtes
    "economy",      -- Phase 13 : économie
    "effects",      -- Phase 16 : effets et animations
    "admin",        -- Phase 17 : administration
}

-- ─── Staff ──────────────────────────────────────────────────────────────
-- Groupes considérés comme staff (en plus de superadmin, toujours staff).
-- Compatible avec ULX / SAM / sAdmin… tant qu'ils utilisent les usergroups.
Config.StaffGroups = {
    ["superadmin"] = true,
    ["admin"]      = true,
}

-- ─── Joueur ─────────────────────────────────────────────────────────────
Config.Player = {
    WalkSpeed  = 180,
    RunSpeed   = 300,
    JumpPower  = 200,
    MaxHealth  = 100,

    -- Armes données à tous les joueurs au spawn
    Loadout = {
        -- "weapon_fists",
    },

    -- Armes données en plus au staff (outils de construction / test)
    StaffLoadout = {
        "weapon_physgun",
        "gmod_tool",
        "gmod_camera",
    },
}

-- ─── Sandbox ────────────────────────────────────────────────────────────
Config.Sandbox = {
    -- true : seuls les membres du staff peuvent spawn props, NPC, véhicules,
    -- armes, utiliser le menu Q / le menu contextuel C…
    RestrictToStaff = true,

    -- true : tout le monde peut utiliser le noclip (sinon staff uniquement)
    PlayersCanNoclip = false,
}

-- ─── Réseau ─────────────────────────────────────────────────────────────
-- Valeurs par défaut de BlackClover.Net.Receive (voir core/sh_network.lua).
Config.Net = {
    DefaultCooldown       = 0.25, -- secondes entre 2 messages identiques d'un joueur
    DefaultMaxBytes       = 2048, -- taille max d'un message client → serveur
    MaxMessagesPerSecond  = 40,   -- tous messages BlackClover confondus, par joueur
    KickOnFlood           = false,-- expulser un joueur qui dépasse 2x la limite
}

-- ─── Personnage (utilisé en Phase 2) ────────────────────────────────────
Config.Character = {
    MaxCharacters  = 3,
    NameMinLength  = 2,
    NameMaxLength  = 24,
    AgeMin         = 15,
    AgeMax         = 90,
    StoryMaxLength = 3000,
}
