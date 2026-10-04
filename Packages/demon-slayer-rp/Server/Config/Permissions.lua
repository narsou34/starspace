--[[
    Demon Slayer RP - Groupes et permissions staff
    ------------------------------------------------------------------
    Permissions sous la forme "domaine.action" :
      - "*"          : toutes les permissions
      - "admin.*"    : toutes les permissions commençant par "admin."

    Weight : hiérarchie. Un membre du staff ne peut agir que sur un joueur
    de poids strictement inférieur, et ne peut pas attribuer un groupe
    de poids supérieur ou égal au sien.

    Ces groupes concernent l'ADMINISTRATION du serveur. Les grades RP
    (Pourfendeurs / Démons) seront un système séparé (Phase 7).
]]

Config.Permissions = {
    -- Groupe attribué à tout joueur absent de la liste Staff
    DefaultGroup = "user",

    Groups = {
        user = {
            Label = "Joueur",
            Weight = 0,
            Permissions = {
                "core.help",
                "core.info",
                "core.whoami",
                "core.skills",
            },
        },
        moderator = {
            Label = "Moderateur",
            Weight = 50,
            Inherits = "user",
            Permissions = {
                "admin.players",
            },
        },
        admin = {
            Label = "Administrateur",
            Weight = 80,
            Inherits = "moderator",
            Permissions = {
                "admin.modules",
                "admin.netstats",
                "admin.setgroup",
                "admin.setfaction",
                "admin.givebreathing",
                "admin.givedemonart",
                "admin.heal",
                "admin.npc",
                "admin.cast",
                "admin.setlevel",
            },
        },
        superadmin = {
            Label = "Super-admin",
            Weight = 100,
            Inherits = "admin",
            Permissions = {
                "*",
            },
        },
    },

    -- Staff permanent : ["Account ID nanos world"] = "groupe"
    -- Votre Account ID s'affiche avec la commande /ds_whoami.
    -- (En attendant la base de données - Phase 5 - les changements faits avec
    --  /ds_setgroup ne durent que jusqu'à la déconnexion.)
    Staff = {
        -- ["00000000-0000-0000-0000-000000000000"] = "superadmin",
    },
}
