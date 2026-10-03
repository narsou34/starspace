--[[
    Black Clover RP — systems/magic/sh_magic.lua
    Realm : PARTAGÉ

    Registre des magies, construit à partir de config/sh_magic.lua.
    Chaque magie est vérifiée au chargement : une magie mal configurée est
    ignorée avec un message d'erreur clair dans la console.

        Magic.Get(id)          → table de la magie (ou nil)
        Magic.GetAll()         → { id = magie, ... }
        Magic.GetSorted()      → liste triée par rareté puis par nom
        Magic.GetRarity(id)    → table de rareté
        ply:GetMagic()         → identifiant de la magie du personnage ("" si aucune)
]]

BlackClover.Magic = BlackClover.Magic or {}
local Magic = BlackClover.Magic
local Config = BlackClover.Config
local Log = BlackClover.Log

Magic.Registry = {}

local DEFAULT_STATS = { Power = 1, Mana = 1, Regen = 1 }

local function Validate(id, data)
    if not isstring(data.Name) then return "Name manquant" end
    if not IsColor(data.Color) and not istable(data.Color) then return "Color manquante" end
    if not Config.Rarities[data.Rarity] then return "Rarity inconnue (" .. tostring(data.Rarity) .. ")" end
    return nil
end

for id, data in pairs(Config.Magic or {}) do
    local err = Validate(id, data)

    if err then
        Log.Error("Magic", "Magie \"%s\" ignorée : %s", id, err)
    else
        data.ID = id
        data.Description = data.Description or ""
        data.Icon = data.Icon or "icon16/star.png"
        data.Chance = tonumber(data.Chance) or 0
        data.Stats = data.Stats or {}

        for stat, default in pairs(DEFAULT_STATS) do
            if data.Stats[stat] == nil then data.Stats[stat] = default end
        end

        Magic.Registry[id] = data
    end
end

function Magic.Get(id)
    return Magic.Registry[id]
end

function Magic.GetAll()
    return Magic.Registry
end

function Magic.GetRarity(id)
    local magic = Magic.Registry[id]
    return magic and Config.Rarities[magic.Rarity] or nil
end

function Magic.GetSorted()
    local list = table.ClearKeys(table.Copy(Magic.Registry))

    table.sort(list, function(a, b)
        local ra, rb = Config.Rarities[a.Rarity].Order, Config.Rarities[b.Rarity].Order
        if ra ~= rb then return ra < rb end
        return a.Name < b.Name
    end)

    return list
end

local PLAYER = FindMetaTable("Player")

function PLAYER:GetMagic()
    return self:GetNW2String("BC_Magic", "")
end
