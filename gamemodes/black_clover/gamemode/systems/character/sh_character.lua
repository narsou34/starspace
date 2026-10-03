--[[
    Black Clover RP — systems/character/sh_character.lua
    Realm : PARTAGÉ

    Système de personnages : déclarations communes.

    Données publiques (visibles par tous, via NW2) :
        ply:HasCharacter()      ply:GetCharacterID()
        ply:GetCharacterName()  ply:GetKingdom()       ply:GetMoney()

    Les données privées (âge, origine, histoire…) ne sont envoyées qu'au
    propriétaire (net "BlackClover.Character.Sync").
]]

BlackClover.Character = BlackClover.Character or {}
local Character = BlackClover.Character
local Config = BlackClover.Config
local Util = BlackClover.Util

local Net = BlackClover.Net
Net.Register("BlackClover.Character.List")          -- serveur → client : liste des personnages
Net.Register("BlackClover.Character.Sync")          -- serveur → client : données privées du personnage chargé
Net.Register("BlackClover.Character.Error")         -- serveur → client : erreur de création…
Net.Register("BlackClover.Character.Create")        -- client → serveur
Net.Register("BlackClover.Character.Select")        -- client → serveur
Net.Register("BlackClover.Character.Delete")        -- client → serveur
Net.Register("BlackClover.Character.RequestMenu")   -- client → serveur

-- ─── Accesseurs joueur ──────────────────────────────────────────────────

local PLAYER = FindMetaTable("Player")

function PLAYER:HasCharacter()
    if SERVER then return self.bcCharacter ~= nil end
    return self:GetNW2Int("BC_CharID", 0) > 0
end

function PLAYER:GetCharacterID()
    return self:GetNW2Int("BC_CharID", 0)
end

function PLAYER:GetCharacterName()
    local name = self:GetNW2String("BC_Name", "")
    return name ~= "" and name or self:Nick()
end

function PLAYER:GetKingdom()
    return self:GetNW2String("BC_Kingdom", "")
end

function PLAYER:GetMoney()
    return self:GetNW2Int("BC_Money", 0)
end

-- ─── Validation (partagée : le client l'utilise pour l'affichage, ───────
-- ─── le serveur la refait TOUJOURS avant d'enregistrer)          ───────

--- Un nom ne contient que des lettres (accents compris), espaces, - et '.
function Character.IsValidName(name)
    local cfg = Config.Character
    local length = utf8.len(name)

    if not length or length < cfg.NameMinLength or length > cfg.NameMaxLength then
        return false, string.format("doit contenir entre %d et %d caractères", cfg.NameMinLength, cfg.NameMaxLength)
    end

    for _, code in utf8.codes(name) do
        local isLetter = (code >= 65 and code <= 90) or (code >= 97 and code <= 122)
            or (code >= 0xC0 and code <= 0x24F and code ~= 0xD7 and code ~= 0xF7)
        local isAllowed = code == 32 or code == 45 or code == 39

        if not isLetter and not isAllowed then
            return false, "ne peut contenir que des lettres, espaces, tirets et apostrophes"
        end
    end

    return true
end

--- Valide toutes les données de création.
-- @param data table Données brutes
-- @return boolean, string|table false + message d'erreur, ou true + données nettoyées
function Character.Validate(data)
    local cfg = Config.Character
    local clean = {}

    clean.FirstName = Util.SanitizeString(data.FirstName, cfg.NameMaxLength)
    clean.LastName  = Util.SanitizeString(data.LastName, cfg.NameMaxLength)

    local ok, err = Character.IsValidName(clean.FirstName)
    if not ok then return false, "Le prénom " .. err .. "." end

    ok, err = Character.IsValidName(clean.LastName)
    if not ok then return false, "Le nom " .. err .. "." end

    clean.Age = Util.ToInteger(data.Age, nil)
    if not clean.Age or clean.Age < cfg.AgeMin or clean.Age > cfg.AgeMax then
        return false, string.format("L'âge doit être compris entre %d et %d ans.", cfg.AgeMin, cfg.AgeMax)
    end

    if not Util.IsOneOf(data.Sex, cfg.Sexes) then
        return false, "Sexe invalide."
    end
    clean.Sex = data.Sex

    if not Util.IsOneOf(data.Model, cfg.Models[clean.Sex] or {}) then
        return false, "Apparence invalide."
    end
    clean.Model = data.Model

    if not (isstring(data.Kingdom) and Config.Kingdoms[data.Kingdom]) then
        return false, "Royaume invalide."
    end
    clean.Kingdom = data.Kingdom

    if not Util.IsOneOf(data.Origin, cfg.Origins) then
        return false, "Origine invalide."
    end
    clean.Origin = data.Origin

    clean.Personality = Util.SanitizeString(data.Personality, cfg.PersonalityMaxLength)
    if utf8.len(clean.Personality) < cfg.PersonalityMinLength then
        return false, string.format("La personnalité doit contenir au moins %d caractères.", cfg.PersonalityMinLength)
    end

    clean.Story = Util.SanitizeString(data.Story, cfg.StoryMaxLength, true)
    if utf8.len(clean.Story) < cfg.StoryMinLength then
        return false, string.format("L'histoire doit contenir au moins %d caractères.", cfg.StoryMinLength)
    end

    return true, clean
end
