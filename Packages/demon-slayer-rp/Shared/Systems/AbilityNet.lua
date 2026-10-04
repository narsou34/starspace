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
                level       = { type = "number", integer = true, min = 0 },
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

-- ===========================================================================
-- Techniques scriptées (chronologie partagée, voir Shared/Config/Breathing/)
-- ===========================================================================

-- Serveur -> Clients proches : début d'une technique scriptée.
-- Origine et direction fixées par le serveur : tous les clients dessinent
-- exactement la même trajectoire que celle utilisée pour les zones de touche.
NetEvents.Define("S2C", "TechStart", {
    args = {
        { name = "caster", type = "entity" },
        { name = "kind", type = "string", maxLength = 16 },
        { name = "setId", type = "string", maxLength = 32 },
        { name = "slot", type = "number", integer = true, min = 1, max = DS.Catalog.Slots },
        { name = "x", type = "number" },
        { name = "y", type = "number" },
        { name = "z", type = "number" },
        { name = "yaw", type = "number" },
        { name = "instance", type = "number", integer = true, min = 0 },
    },
})

-- Serveur -> Clients proches : évènement ponctuel d'une technique
-- (impact, emprisonnement, éclatement, explosion finale...).
NetEvents.Define("S2C", "TechEvent", {
    args = {
        { name = "instance", type = "number", integer = true, min = 0 },
        { name = "event", type = "string", maxLength = 32 },
        { name = "x", type = "number" },
        { name = "y", type = "number" },
        { name = "z", type = "number" },
        { name = "target", type = "entity", optional = true },
    },
})
