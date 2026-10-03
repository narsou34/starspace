--[[
    Black Clover RP — systems/status/sh_status.lua
    Realm : PARTAGÉ

    Effets de statut (buffs / debuffs) temporaires.

    Un statut est une table :
        {
            ID = "slow", Name = "Ralenti", Duration = 3,
            SpeedMult = 0.5,          -- vitesse de déplacement
            DamageTakenMult = 0.7,    -- dégâts reçus (bouclier < 1, vulnérabilité > 1)
            DamageDealtMult = 1.2,    -- dégâts des sorts infligés
            ManaRegenMult = 1.5,      -- régénération de mana
            MaxManaMult = 1.1,        -- mana maximum
            MaxManaAdd = 50,          -- mana maximum (+ fixe)
            Rooted = true,            -- immobilisé
            Silenced = true,          -- ne peut pas lancer de sort
            DamagePerSecond = 3,      -- dégâts sur la durée
        }

    Les équipements (inventaire) pourront utiliser le même système avec une
    durée très longue.
]]

BlackClover.Status = BlackClover.Status or {}
local Status = BlackClover.Status

Status.MultiplierFields = { "SpeedMult", "DamageTakenMult", "DamageDealtMult", "ManaRegenMult", "MaxManaMult" }
Status.FlagFields = { "Rooted", "Silenced" }

BlackClover.Net.Register("BlackClover.Status.Sync")

-- Côté client : liste des statuts du joueur local, pour le HUD
if CLIENT then
    Status.Local = Status.Local or {}

    BlackClover.Net.Receive("BlackClover.Status.Sync", function()
        Status.Local = net.ReadTable()
    end)
end
