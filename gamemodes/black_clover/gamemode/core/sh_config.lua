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
    "character",    -- personnages (création, sélection, sauvegarde)
    "progression",  -- niveau, XP, statistiques
    "status",       -- buffs / debuffs (vitesse, dégâts, mana…)
    "mana",         -- mana
    "magic",        -- types de magie
    "grimoire",     -- grimoires + cérémonie
    "effects",      -- effets visuels et sons
    "spells",       -- sorts (lancement, cooldowns, dégâts)
    "factions",     -- (à venir) factions
    "ranks",        -- (à venir) rangs
    "inventory",    -- (à venir) inventaire
    "quests",       -- (à venir) quêtes
    "economy",      -- (à venir) économie
    "admin",        -- commandes staff
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

-- ─── Personnage ─────────────────────────────────────────────────────────
Config.Character = {
    MaxCharacters  = 3,
    NameMinLength  = 2,
    NameMaxLength  = 24,
    AgeMin         = 15,
    AgeMax         = 90,
    PersonalityMinLength = 3,
    PersonalityMaxLength = 120,
    StoryMinLength = 0,
    StoryMaxLength = 3000,

    -- Recharge automatiquement le dernier personnage joué à la connexion
    AutoLoadLast = true,

    -- Argent de départ (affiché dans le HUD, économie complète à venir)
    StartMoney = 500,
    CurrencyName = "Yul",

    Sexes = { "Homme", "Femme" },

    -- Apparences autorisées par sexe (le serveur refuse tout autre modèle)
    Models = {
        ["Homme"] = {
            "models/player/Group01/male_01.mdl",
            "models/player/Group01/male_02.mdl",
            "models/player/Group01/male_03.mdl",
            "models/player/Group01/male_04.mdl",
            "models/player/Group01/male_05.mdl",
            "models/player/Group01/male_06.mdl",
            "models/player/Group01/male_07.mdl",
            "models/player/Group01/male_08.mdl",
            "models/player/Group01/male_09.mdl",
            "models/player/Group02/male_02.mdl",
            "models/player/Group02/male_04.mdl",
            "models/player/Group02/male_06.mdl",
            "models/player/Group02/male_08.mdl",
        },
        ["Femme"] = {
            "models/player/Group01/female_01.mdl",
            "models/player/Group01/female_02.mdl",
            "models/player/Group01/female_03.mdl",
            "models/player/Group01/female_04.mdl",
            "models/player/Group01/female_05.mdl",
            "models/player/Group01/female_06.mdl",
        },
    },

    Origins = {
        "Famille royale",
        "Noblesse",
        "Roturier",
        "Village frontalier",
        "Étranger",
    },
}
