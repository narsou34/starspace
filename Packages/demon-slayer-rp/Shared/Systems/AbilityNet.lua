--[[
    Demon Slayer RP - Évènements réseau des techniques (souffles / arts)
    ------------------------------------------------------------------
    Le client n'envoie QUE l'emplacement de la technique voulue (1 à 5).
    Le serveur décide de tout le reste : technique, coût, cooldown, cibles, dégâts.
]]

local NetEvents = DS.NetEvents

-- Client -> Serveur : "je veux utiliser la technique de l'emplacement N"
NetEvents.Define("C2S", "UseSkill", {
    args = {
        { name = "slot", type = "number", integer = true, min = 1, max = DS.Catalog.Slots },
    },
    rate = { max = 5, windowMs = 1000 },
    state = "loaded",
})

-- Serveur -> Client : faction / souffle / art du joueur (envoyé à chaque changement)
NetEvents.Define("S2C", "AbilitiesSync", {
    args = {
        {
            name = "payload",
            type = "table",
            fields = {
                faction     = { type = "string", maxLength = 32 },  -- "" = aucune
                kind        = { type = "string", maxLength = 16 },  -- "breathing" | "art" | ""
                setId       = { type = "string", maxLength = 32 },  -- "" = aucun
                resource    = { type = "string", maxLength = 32 },
                resourceMax = { type = "number", min = 0 },
            },
        },
    },
})

-- Serveur -> Client : valeur de la ressource (souffle / énergie démoniaque)
NetEvents.Define("S2C", "ResourceSync", {
    args = {
        { name = "current", type = "number", min = 0 },
        { name = "max", type = "number", min = 0 },
    },
    reliable = false,
})

-- Serveur -> Client : une technique vient d'être utilisée (cooldown à afficher)
NetEvents.Define("S2C", "SkillCooldown", {
    args = {
        { name = "slot", type = "number", integer = true, min = 1, max = DS.Catalog.Slots },
        { name = "durationMs", type = "number", min = 0 },
    },
})

-- Serveur -> Clients proches : effet visuel / sonore d'une technique
NetEvents.Define("S2C", "SkillFx", {
    args = {
        { name = "caster", type = "entity" },
        { name = "kind", type = "string", maxLength = 16 },
        { name = "setId", type = "string", maxLength = 32 },
        { name = "slot", type = "number", integer = true, min = 1, max = DS.Catalog.Slots },
        { name = "hits", type = "number", integer = true, min = 0 },
    },
    reliable = false,
})
