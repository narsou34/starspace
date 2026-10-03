--[[
    Black Clover RP — systems/character/sv_character.lua
    Realm : SERVEUR

    Création, chargement, sélection, suppression et sauvegarde des personnages.

    En mémoire, le personnage chargé est dans ply.bcCharacter :
        { ID, SteamID64, FirstName, LastName, Age, Sex, Model, Kingdom, Origin,
          Personality, Story, Magic, Level, XP, Mana, Money, Data, CreatedAt }
    Data est une table libre sauvegardée en JSON (stats d'entraînement, etc.),
    pratique pour ajouter des informations sans modifier la base.

    Hooks déclenchés :
        BlackClover.CharacterLoaded   (ply, character)
        BlackClover.CharacterUnloaded (ply, character)
        BlackClover.CharacterSave     (ply, character)   → avant chaque sauvegarde
]]

local Character = BlackClover.Character
local Config = BlackClover.Config
local Util = BlackClover.Util
local Log = BlackClover.Log
local DB = BlackClover.Database
local Net = BlackClover.Net

DB.RegisterTable("characters", [[
    id {ID},
    steamid64 VARCHAR(32) NOT NULL,
    first_name VARCHAR(64) NOT NULL,
    last_name VARCHAR(64) NOT NULL,
    age INT NOT NULL,
    sex VARCHAR(16) NOT NULL,
    model VARCHAR(128) NOT NULL,
    kingdom VARCHAR(32) NOT NULL,
    origin VARCHAR(64) NOT NULL,
    personality VARCHAR(255) NOT NULL,
    story TEXT,
    magic VARCHAR(32),
    level INT NOT NULL DEFAULT 1,
    xp INT NOT NULL DEFAULT 0,
    mana FLOAT NOT NULL DEFAULT 0,
    money INT NOT NULL DEFAULT 0,
    data TEXT,
    created_at INT NOT NULL,
    last_played INT NOT NULL DEFAULT 0,
    deleted INT NOT NULL DEFAULT 0
]])

local T = DB.Table("characters")

-- ─── Utilitaires ────────────────────────────────────────────────────────

local function SendError(ply, message)
    net.Start("BlackClover.Character.Error")
        net.WriteString(message)
    net.Send(ply)
end

--- Transforme une ligne SQL en table personnage.
local function RowToCharacter(row)
    local data = Util.FromJSON(row.data, {})
    data.Stats = istable(data.Stats) and data.Stats or {}

    local magic = row.magic
    if magic == "" or magic == "NULL" or not (magic and Config.Magic[magic]) then magic = nil end

    return {
        ID          = tonumber(row.id),
        SteamID64   = row.steamid64,
        FirstName   = row.first_name,
        LastName    = row.last_name,
        Age         = tonumber(row.age) or 0,
        Sex         = row.sex,
        Model       = row.model,
        Kingdom     = row.kingdom,
        Origin      = row.origin,
        Personality = row.personality,
        Story       = row.story or "",
        Magic       = magic,
        Level       = math.max(tonumber(row.level) or 1, 1),
        XP          = math.max(tonumber(row.xp) or 0, 0),
        Mana        = tonumber(row.mana) or -1, -- -1 = jamais joué (mana plein)
        Money       = math.max(tonumber(row.money) or 0, 0),
        Data        = data,
        CreatedAt   = tonumber(row.created_at) or 0,
    }
end

function Character.Get(ply)
    return IsValid(ply) and ply.bcCharacter or nil
end

function Character.GetFullName(char)
    return char.FirstName .. " " .. char.LastName
end

--- Met à jour les variables réseau publiques.
function Character.ApplyNetworkVars(ply)
    local char = ply.bcCharacter

    ply:SetNW2Int("BC_CharID", char and char.ID or 0)
    ply:SetNW2String("BC_Name", char and Character.GetFullName(char) or "")
    ply:SetNW2String("BC_Kingdom", char and char.Kingdom or "")
    ply:SetNW2Int("BC_Money", char and char.Money or 0)
end

--- Envoie les données privées au propriétaire.
function Character.SyncPrivate(ply)
    local char = ply.bcCharacter
    if not char then return end

    net.Start("BlackClover.Character.Sync")
        net.WriteTable({
            ID = char.ID, FirstName = char.FirstName, LastName = char.LastName,
            Age = char.Age, Sex = char.Sex, Kingdom = char.Kingdom, Origin = char.Origin,
            Personality = char.Personality, Story = char.Story, CreatedAt = char.CreatedAt,
        })
    net.Send(ply)
end

-- ─── Liste ──────────────────────────────────────────────────────────────

--- Envoie la liste des personnages et ouvre le menu côté client.
function Character.SendList(ply)
    if not IsValid(ply) then return end

    DB.OnReady(function()
        DB.Query("SELECT c.id, c.first_name, c.last_name, c.age, c.sex, c.model, c.kingdom, c.level, c.magic, g.leaves " ..
            "FROM " .. T .. " c LEFT JOIN " .. DB.Table("grimoires") .. " g ON g.character_id = c.id " ..
            "WHERE c.steamid64 = ? AND c.deleted = 0 ORDER BY c.id ASC",
            { ply:SteamID64() },
            function(rows)
                if not IsValid(ply) then return end

                local list = {}
                for _, row in ipairs(rows) do
                    list[#list + 1] = {
                        ID = tonumber(row.id),
                        Name = row.first_name .. " " .. row.last_name,
                        Age = tonumber(row.age),
                        Sex = row.sex,
                        Model = row.model,
                        Kingdom = row.kingdom,
                        Level = tonumber(row.level) or 1,
                        Magic = (row.magic ~= "NULL") and row.magic or nil,
                        Leaves = tonumber(row.leaves) or 0,
                    }
                end

                net.Start("BlackClover.Character.List")
                    net.WriteTable(list)
                    net.WriteBool(ply.bcCharacter ~= nil) -- le menu peut-il être fermé ?
                    net.WriteUInt(ply.bcCharacter and ply.bcCharacter.ID or 0, 32)
                net.Send(ply)
            end)
    end)
end

-- ─── Sauvegarde ─────────────────────────────────────────────────────────

function Character.Save(ply)
    local char = Character.Get(ply)
    if not char then return end

    hook.Run("BlackClover.CharacterSave", ply, char)

    DB.Query("UPDATE " .. T .. " SET magic = ?, level = ?, xp = ?, mana = ?, money = ?, model = ?, data = ?, last_played = ? WHERE id = ?",
        { char.Magic or DB.NULL, char.Level, char.XP, math.Round(char.Mana, 2), char.Money, char.Model,
          Util.ToJSON(char.Data), os.time(), char.ID })
end

function Character.SaveAll()
    for _, ply in ipairs(player.GetAll()) do
        Character.Save(ply)
    end
end

-- ─── Chargement ─────────────────────────────────────────────────────────

--- Décharge le personnage actuel (sans le supprimer).
function Character.Unload(ply, save)
    local char = ply.bcCharacter
    if not char then return end

    if save ~= false then Character.Save(ply) end

    hook.Run("BlackClover.CharacterUnloaded", ply, char)

    ply.bcCharacter = nil
    Character.ApplyNetworkVars(ply)
end

--- Charge un personnage appartenant au joueur.
function Character.Load(ply, charID)
    if not IsValid(ply) or ply.bcCharacterLoading then return end
    ply.bcCharacterLoading = true

    DB.OnReady(function()
        DB.Query("SELECT * FROM " .. T .. " WHERE id = ? AND steamid64 = ? AND deleted = 0",
            { charID, ply:SteamID64() },
            function(rows)
                if not IsValid(ply) then return end
                ply.bcCharacterLoading = false

                local row = rows[1]
                if not row then
                    SendError(ply, "Personnage introuvable.")
                    Character.SendList(ply)
                    return
                end

                Character.Unload(ply, true)

                local char = RowToCharacter(row)
                ply.bcCharacter = char
                Character.ApplyNetworkVars(ply)

                DB.Query("UPDATE " .. T .. " SET last_played = ? WHERE id = ?", { os.time(), char.ID })

                Log.Info("Character", "%s joue maintenant %s (#%d)", Log.FormatPlayer(ply), Character.GetFullName(char), char.ID)

                -- Les autres systèmes (grimoire, progression, mana) chargent leurs
                -- données ici. Le grimoire est asynchrone : il fait le spawn lui-même
                -- via Character.FinishLoad une fois prêt.
                hook.Run("BlackClover.CharacterLoaded", ply, char)
            end,
            function()
                if IsValid(ply) then ply.bcCharacterLoading = false end
            end)
    end)
end

--- Dernière étape du chargement : réapparition et restauration du mana.
-- Appelée par le système de grimoire une fois ses données chargées.
function Character.FinishLoad(ply)
    local char = Character.Get(ply)
    if not char then return end

    local savedMana = char.Mana
    ply:Spawn()

    -- Le spawn remet le mana au maximum : on restaure la valeur sauvegardée
    if savedMana >= 0 and ply.SetMana then ply:SetMana(savedMana) end

    Character.SyncPrivate(ply)
    hook.Run("BlackClover.CharacterReady", ply, char)

    BlackClover.Notify(ply, "Vous incarnez maintenant " .. Character.GetFullName(char) .. ".", BlackClover.NotifyType.Hint, 5)
end

-- ─── Création ───────────────────────────────────────────────────────────

function Character.Create(ply, rawData)
    local ok, result = Character.Validate(rawData)
    if not ok then
        SendError(ply, result)
        return
    end

    local data = result
    local steamID64 = ply:SteamID64()

    DB.OnReady(function()
        -- Limite de personnages + nom unique
        DB.Query("SELECT id, first_name, last_name, steamid64 FROM " .. T .. " WHERE deleted = 0 AND (steamid64 = ? OR (LOWER(first_name) = LOWER(?) AND LOWER(last_name) = LOWER(?)))",
            { steamID64, data.FirstName, data.LastName },
            function(rows)
                if not IsValid(ply) then return end

                local owned = 0
                for _, row in ipairs(rows) do
                    if row.steamid64 == steamID64 then owned = owned + 1 end

                    if string.lower(row.first_name) == string.lower(data.FirstName)
                        and string.lower(row.last_name) == string.lower(data.LastName) then
                        SendError(ply, "Un personnage porte déjà ce nom.")
                        return
                    end
                end

                if owned >= Config.Character.MaxCharacters then
                    SendError(ply, string.format("Vous avez déjà %d personnages (maximum).", Config.Character.MaxCharacters))
                    return
                end

                DB.Query("INSERT INTO " .. T .. " (steamid64, first_name, last_name, age, sex, model, kingdom, origin, personality, story, magic, level, xp, mana, money, data, created_at, last_played, deleted) " ..
                    "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL, 1, 0, -1, ?, ?, ?, ?, 0)",
                    { steamID64, data.FirstName, data.LastName, data.Age, data.Sex, data.Model, data.Kingdom,
                      data.Origin, data.Personality, data.Story, Config.Character.StartMoney,
                      Util.ToJSON({ Stats = {} }), os.time(), os.time() },
                    function(_, newID)
                        if not IsValid(ply) then return end

                        Log.Info("Character", "%s a créé %s %s (#%s)", Log.FormatPlayer(ply), data.FirstName, data.LastName, tostring(newID))

                        if newID then
                            Character.Load(ply, newID)
                        else
                            Character.SendList(ply)
                        end
                    end,
                    function()
                        if IsValid(ply) then SendError(ply, "Erreur lors de la création du personnage.") end
                    end)
            end)
    end)
end

-- ─── Suppression ────────────────────────────────────────────────────────
-- Suppression "douce" : le personnage est marqué supprimé mais reste en base
-- (récupérable par un administrateur, et l'historique reste intact).

function Character.Delete(ply, charID)
    DB.OnReady(function()
        DB.Query("UPDATE " .. T .. " SET deleted = 1 WHERE id = ? AND steamid64 = ?",
            { charID, ply:SteamID64() },
            function()
                if not IsValid(ply) then return end

                Log.Info("Character", "%s a supprimé son personnage #%d", Log.FormatPlayer(ply), charID)

                if ply.bcCharacter and ply.bcCharacter.ID == charID then
                    Character.Unload(ply, false)
                    ply:Spawn()
                end

                Character.SendList(ply)
            end)
    end)
end

-- ─── Réseau (client → serveur) ──────────────────────────────────────────

Net.Receive("BlackClover.Character.Create", function(ply)
    local data = {
        FirstName   = net.ReadString(),
        LastName    = net.ReadString(),
        Age         = net.ReadUInt(8),
        Sex         = net.ReadString(),
        Model       = net.ReadString(),
        Kingdom     = net.ReadString(),
        Origin      = net.ReadString(),
        Personality = net.ReadString(),
        Story       = net.ReadString(),
    }

    Character.Create(ply, data)
end, { Cooldown = 3, MaxBytes = 16384 })

Net.Receive("BlackClover.Character.Select", function(ply)
    local charID = net.ReadUInt(32)
    if charID <= 0 then return end

    if ply.bcCharacter and ply.bcCharacter.ID == charID then return end
    if ply.bcInCeremony then
        SendError(ply, "Impossible de changer de personnage pendant la cérémonie.")
        return
    end

    Character.Load(ply, charID)
end, { Cooldown = 2, MaxBytes = 16 })

Net.Receive("BlackClover.Character.Delete", function(ply)
    local charID = net.ReadUInt(32)
    if charID <= 0 then return end
    if ply.bcInCeremony then return end

    Character.Delete(ply, charID)
end, { Cooldown = 2, MaxBytes = 16 })

Net.Receive("BlackClover.Character.RequestMenu", function(ply)
    Character.SendList(ply)
end, { Cooldown = 1, MaxBytes = 8 })

hook.Add("BlackClover.OpenCharacterMenu", "BlackClover.Character", Character.SendList)

-- ─── Cycle de vie ───────────────────────────────────────────────────────

-- Connexion : rechargement automatique du dernier personnage, sinon menu
hook.Add("BlackClover.PlayerReady", "BlackClover.Character", function(ply)
    if not Config.Character.AutoLoadLast then
        Character.SendList(ply)
        return
    end

    DB.OnReady(function()
        DB.Query("SELECT id FROM " .. T .. " WHERE steamid64 = ? AND deleted = 0 ORDER BY last_played DESC LIMIT 1",
            { ply:SteamID64() },
            function(rows)
                if not IsValid(ply) then return end

                if rows[1] then
                    Character.Load(ply, tonumber(rows[1].id))
                else
                    Character.SendList(ply)
                end
            end)
    end)
end)

-- Spawn sans personnage : le joueur est figé, invisible et invincible
hook.Add("BlackClover.PlayerSpawn", "BlackClover.Character", function(ply)
    local hasCharacter = ply.bcCharacter ~= nil

    ply:Freeze(not hasCharacter)
    ply:SetNoDraw(not hasCharacter)
    ply:SetNotSolid(not hasCharacter)

    if hasCharacter then
        ply:GodDisable()
    else
        ply:GodEnable()
        ply:StripWeapons()
    end
end)

-- Modèle du personnage
hook.Add("BlackClover.GetPlayerModel", "BlackClover.Character", function(ply)
    local char = ply.bcCharacter
    if char and Util.IsOneOf(char.Model, Config.Character.Models[char.Sex] or {}) then
        return char.Model
    end
end)

-- Pas d'arme sans personnage
hook.Add("PlayerCanPickupWeapon", "BlackClover.Character", function(ply)
    if not ply.bcCharacter then return false end
end)

-- Déconnexion et arrêt du serveur
hook.Add("PlayerDisconnected", "BlackClover.Character", function(ply)
    Character.Unload(ply, true)
end)

hook.Add("ShutDown", "BlackClover.Character", Character.SaveAll)

-- Sauvegarde automatique
timer.Create("BlackClover.Character.AutoSave", Config.Save.AutoSaveInterval, 0, function()
    Character.SaveAll()
    Log.Debug("Character", "Sauvegarde automatique effectuée")
end)
