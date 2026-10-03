--[[
    Black Clover RP — systems/grimoire/sv_grimoire.lua
    Realm : SERVEUR

    Grimoire lié DÉFINITIVEMENT à un personnage (1 grimoire max par personnage,
    contrainte UNIQUE en base). Seul un administrateur peut le retirer.

    En mémoire : ply.bcGrimoire
        { ID, CharacterID, Type, Leaves, Magic, Level, XP,
          Unlocked = { [spellID] = true }, Equipped = { "spell", "", ... },
          History = { { t = timestamp, m = "texte" }, ... }, ObtainedAt }

    API :
        Grimoire.Get(ply)
        Grimoire.Give(ply, leaves, magicID, callback)   -- crée + sauvegarde
        Grimoire.Remove(ply)                            -- admin
        Grimoire.SetMagic(ply, magicID)                 -- admin
        Grimoire.Unlock(ply, spellID, force)
        Grimoire.Equip(ply, slot, spellID)
        Grimoire.CheckUnlocks(ply)
        Grimoire.AddXP(ply, amount)
        Grimoire.AddHistory(ply, text)
        Grimoire.Save(ply) / Grimoire.Sync(ply)
        Grimoire.StartCeremony(ply, forcedLeaves, forcedMagic)

    Hooks :
        BlackClover.GrimoireObtained (ply, grimoire)
        BlackClover.SpellUnlocked    (ply, spellID)
]]

local Grimoire = BlackClover.Grimoire
local Config = BlackClover.Config
local Util = BlackClover.Util
local Log = BlackClover.Log
local DB = BlackClover.Database
local Net = BlackClover.Net

DB.RegisterTable("grimoires", [[
    id {ID},
    character_id INT NOT NULL UNIQUE,
    grimoire_type VARCHAR(32) NOT NULL,
    leaves INT NOT NULL,
    magic VARCHAR(32) NOT NULL,
    level INT NOT NULL DEFAULT 1,
    xp INT NOT NULL DEFAULT 0,
    unlocked TEXT,
    equipped TEXT,
    history TEXT,
    obtained_at INT NOT NULL
]])

local T = DB.Table("grimoires")

function Grimoire.Get(ply)
    return IsValid(ply) and ply.bcGrimoire or nil
end

function Grimoire.GetSlotCount(ply)
    local grimoire = ply.bcGrimoire
    local gtype = grimoire and Grimoire.GetType(grimoire.Type)
    return gtype and gtype.Slots or 0
end

-- ─── Réseau ─────────────────────────────────────────────────────────────

function Grimoire.ApplyNetworkVars(ply)
    local grimoire = ply.bcGrimoire
    local char = ply.bcCharacter

    ply:SetNW2Int("BC_GrimoireLeaves", grimoire and grimoire.Leaves or 0)
    ply:SetNW2Int("BC_GrimoireLevel", grimoire and grimoire.Level or 0)
    ply:SetNW2String("BC_Magic", char and char.Magic or "")

    local slots = Grimoire.GetSlotCount(ply)
    if ply:GetSpellSlot() > slots or ply:GetSpellSlot() < 1 then
        ply:SetNW2Int("BC_SpellSlot", 1)
    end
end

--- Envoie le contenu complet du grimoire à son propriétaire.
function Grimoire.Sync(ply)
    local grimoire = ply.bcGrimoire
    Grimoire.ApplyNetworkVars(ply)

    net.Start("BlackClover.Grimoire.Sync")
    if not grimoire then
        net.WriteBool(false)
    else
        net.WriteBool(true)
        net.WriteTable({
            Type = grimoire.Type,
            Leaves = grimoire.Leaves,
            Magic = grimoire.Magic,
            Level = grimoire.Level,
            XP = grimoire.XP,
            Unlocked = table.GetKeys(grimoire.Unlocked),
            Equipped = grimoire.Equipped,
            History = grimoire.History,
            ObtainedAt = grimoire.ObtainedAt,
        })
    end
    net.Send(ply)
end

-- ─── Sauvegarde / chargement ────────────────────────────────────────────

function Grimoire.Save(ply)
    local grimoire = ply.bcGrimoire
    if not grimoire then return end

    DB.Query("UPDATE " .. T .. " SET grimoire_type = ?, leaves = ?, magic = ?, level = ?, xp = ?, unlocked = ?, equipped = ?, history = ? WHERE id = ?",
        { grimoire.Type, grimoire.Leaves, grimoire.Magic, grimoire.Level, grimoire.XP,
          Util.ToJSON(table.GetKeys(grimoire.Unlocked), true), Util.ToJSON(grimoire.Equipped, true),
          Util.ToJSON(grimoire.History, true), grimoire.ID })
end

--- Nettoie les données chargées (sorts supprimés de la config, emplacements…).
local function Sanitize(grimoire)
    local Spells = BlackClover.Spells

    for spellID in pairs(grimoire.Unlocked) do
        if not Spells.Get(spellID) then grimoire.Unlocked[spellID] = nil end
    end

    local gtype = Grimoire.GetType(grimoire.Type)
    local slots = gtype and gtype.Slots or 3
    local equipped = {}

    for i = 1, slots do
        local spellID = grimoire.Equipped[i]
        equipped[i] = (isstring(spellID) and grimoire.Unlocked[spellID]) and spellID or ""
    end

    grimoire.Equipped = equipped
end

local function RowToGrimoire(row)
    local unlocked = {}
    for _, spellID in ipairs(Util.FromJSON(row.unlocked, {})) do
        if isstring(spellID) then unlocked[spellID] = true end
    end

    local grimoire = {
        ID = tonumber(row.id),
        CharacterID = tonumber(row.character_id),
        Type = row.grimoire_type,
        Leaves = tonumber(row.leaves) or 3,
        Magic = row.magic,
        Level = math.max(tonumber(row.level) or 1, 1),
        XP = math.max(tonumber(row.xp) or 0, 0),
        Unlocked = unlocked,
        Equipped = Util.FromJSON(row.equipped, {}),
        History = Util.FromJSON(row.history, {}),
        ObtainedAt = tonumber(row.obtained_at) or 0,
    }

    Sanitize(grimoire)
    return grimoire
end

-- Au chargement d'un personnage : charge son grimoire puis termine le chargement
hook.Add("BlackClover.CharacterLoaded", "BlackClover.Grimoire", function(ply, char)
    ply.bcGrimoire = nil

    DB.Query("SELECT * FROM " .. T .. " WHERE character_id = ?", { char.ID }, function(rows)
        if not IsValid(ply) or ply.bcCharacter ~= char then return end

        if rows[1] then
            ply.bcGrimoire = RowToGrimoire(rows[1])

            -- La magie du grimoire fait foi
            char.Magic = ply.bcGrimoire.Magic
            Grimoire.CheckUnlocks(ply, true)
        end

        Grimoire.Sync(ply)
        BlackClover.Progression.Apply(ply)
        BlackClover.Character.FinishLoad(ply)
    end, function()
        -- En cas d'erreur, le personnage est tout de même chargé (sans grimoire)
        if IsValid(ply) and ply.bcCharacter == char then
            BlackClover.Character.FinishLoad(ply)
        end
    end)
end)

hook.Add("BlackClover.CharacterUnloaded", "BlackClover.Grimoire", function(ply)
    Grimoire.Save(ply)
    ply.bcGrimoire = nil

    timer.Simple(0, function()
        if IsValid(ply) and not ply.bcCharacter then Grimoire.Sync(ply) end
    end)
end)

hook.Add("BlackClover.CharacterSave", "BlackClover.Grimoire", Grimoire.Save)

-- L'arme grimoire est donnée à chaque spawn
hook.Add("BlackClover.PlayerLoadout", "BlackClover.Grimoire", function(ply)
    if ply.bcCharacter and ply.bcGrimoire then
        ply:Give(Grimoire.WeaponClass)
    end
end)

-- ─── Historique / XP ────────────────────────────────────────────────────

function Grimoire.AddHistory(ply, text)
    local grimoire = ply.bcGrimoire
    if not grimoire then return end

    table.insert(grimoire.History, 1, { t = os.time(), m = tostring(text) })

    while #grimoire.History > Config.Grimoire.MaxHistory do
        table.remove(grimoire.History)
    end
end

function Grimoire.AddXP(ply, amount)
    local grimoire = ply.bcGrimoire
    if not grimoire then return end

    amount = Util.ToInteger(amount, 0, 0, 1000000)
    if amount <= 0 or grimoire.Level >= Config.Grimoire.MaxLevel then return end

    local oldLevel = grimoire.Level
    grimoire.XP = grimoire.XP + amount

    while grimoire.Level < Config.Grimoire.MaxLevel do
        local needed = Grimoire.GetXPForLevel(grimoire.Level)
        if grimoire.XP < needed then break end

        grimoire.XP = grimoire.XP - needed
        grimoire.Level = grimoire.Level + 1
    end

    if grimoire.Level >= Config.Grimoire.MaxLevel then grimoire.XP = 0 end

    if grimoire.Level > oldLevel then
        Grimoire.AddHistory(ply, string.format("Maîtrise atteinte : niveau %d", grimoire.Level))
        BlackClover.Notify(ply, string.format("Votre grimoire réagit… Maîtrise niveau %d !", grimoire.Level), BlackClover.NotifyType.Hint, 5)
        Grimoire.CheckUnlocks(ply)
        Grimoire.Save(ply)
    end

    Grimoire.Sync(ply)
end

-- ─── Sorts ──────────────────────────────────────────────────────────────

--- Débloque un sort. force = true ignore les prérequis (admin).
-- @return boolean, string
function Grimoire.Unlock(ply, spellID, force, silent)
    local grimoire = ply.bcGrimoire
    if not grimoire then return false, "Ce personnage n'a pas de grimoire." end

    local Spells = BlackClover.Spells
    local spell = Spells.Get(spellID)
    if not spell then return false, "Sort inconnu." end
    if grimoire.Unlocked[spellID] then return false, "Sort déjà débloqué." end

    if not force then
        if not Spells.MatchesMagic(spell, grimoire.Magic) then return false, "Ce sort n'appartient pas à cette magie." end

        local ok, reason = Spells.MeetsRequirements(ply, spell)
        if not ok then return false, reason end
    end

    grimoire.Unlocked[spellID] = true
    Grimoire.AddHistory(ply, "Nouvelle page : " .. spell.Name)

    -- Équipe automatiquement dans le premier emplacement libre
    for i = 1, #grimoire.Equipped do
        if grimoire.Equipped[i] == "" then
            grimoire.Equipped[i] = spellID
            break
        end
    end

    hook.Run("BlackClover.SpellUnlocked", ply, spellID)

    if not silent then
        BlackClover.Notify(ply, "Une nouvelle page est apparue dans votre grimoire : " .. spell.Name, BlackClover.NotifyType.Hint, 6)
        Grimoire.Save(ply)
        Grimoire.Sync(ply)
    end

    return true
end

--- Débloque tous les sorts de la magie dont les prérequis sont remplis.
function Grimoire.CheckUnlocks(ply, silent)
    local grimoire = ply.bcGrimoire
    if not grimoire then return end

    local Spells = BlackClover.Spells
    local unlockedAny = false

    for _, spell in ipairs(Spells.GetForMagic(grimoire.Magic)) do
        if not grimoire.Unlocked[spell.ID] and Spells.MeetsRequirements(ply, spell) then
            Grimoire.Unlock(ply, spell.ID, false, true)
            unlockedAny = true

            if not silent then
                BlackClover.Notify(ply, "Une nouvelle page est apparue dans votre grimoire : " .. spell.Name, BlackClover.NotifyType.Hint, 6)
            end
        end
    end

    if unlockedAny and not silent then
        Grimoire.Save(ply)
        Grimoire.Sync(ply)
    end
end

hook.Add("BlackClover.LevelUp", "BlackClover.Grimoire", function(ply) Grimoire.CheckUnlocks(ply) end)

--- Équipe (ou retire avec spellID = "") un sort dans un emplacement.
-- @return boolean, string
function Grimoire.Equip(ply, slot, spellID)
    local grimoire = ply.bcGrimoire
    if not grimoire then return false, "Vous n'avez pas de grimoire." end

    slot = Util.ToInteger(slot, 0)
    if slot < 1 or slot > #grimoire.Equipped then return false, "Emplacement invalide." end

    if spellID ~= "" then
        if not grimoire.Unlocked[spellID] then return false, "Ce sort n'est pas débloqué." end

        -- Un sort ne peut être équipé qu'une fois : on le retire de son ancien emplacement
        for i = 1, #grimoire.Equipped do
            if grimoire.Equipped[i] == spellID then grimoire.Equipped[i] = "" end
        end
    end

    grimoire.Equipped[slot] = spellID
    Grimoire.Save(ply)
    Grimoire.Sync(ply)

    return true
end

Net.Receive("BlackClover.Grimoire.Equip", function(ply)
    local slot = net.ReadUInt(4)
    local spellID = net.ReadString()

    if #spellID > 64 then return end

    local ok, err = Grimoire.Equip(ply, slot, spellID)
    if not ok then BlackClover.Notify(ply, err, BlackClover.NotifyType.Error, 3) end
end, { Cooldown = 0.2, MaxBytes = 128 })

-- ─── Attribution ────────────────────────────────────────────────────────

--- Tire un type de grimoire selon les probabilités configurées.
function Grimoire.RollType()
    return Util.WeightedRandom(Config.Grimoires, "Chance") or Config.Grimoires[1]
end

--- Tire une magie compatible avec le nombre de feuilles.
function Grimoire.RollMagic(leaves)
    local candidates = {}

    for _, magic in pairs(BlackClover.Magic.GetAll()) do
        if (magic.RequiredLeaves or 0) <= leaves and magic.Chance > 0 then
            candidates[#candidates + 1] = magic
        end
    end

    local magic = Util.WeightedRandom(candidates, "Chance")
    return magic and magic.ID or "fire"
end

--- Crée le grimoire d'un personnage et le sauvegarde définitivement.
-- @param leaves number|nil Nombre de feuilles imposé (sinon tirage)
-- @param magicID string|nil Magie imposée (sinon celle du personnage, sinon tirage)
-- @param callback function(success, message)|nil
function Grimoire.Give(ply, leaves, magicID, callback)
    callback = callback or function() end

    local char = ply.bcCharacter
    if not char then return callback(false, "Ce joueur n'a pas de personnage chargé.") end
    if ply.bcGrimoire then return callback(false, "Ce personnage possède déjà un grimoire.") end

    local gtype = leaves and Grimoire.GetTypeByLeaves(leaves) or Grimoire.RollType()
    if not gtype then return callback(false, "Type de grimoire invalide.") end

    magicID = magicID or char.Magic
    local magic = magicID and BlackClover.Magic.Get(magicID)
    if not magic or (magic.RequiredLeaves or 0) > gtype.Leaves then
        magicID = Grimoire.RollMagic(gtype.Leaves)
    end

    local equipped = {}
    for i = 1, gtype.Slots do equipped[i] = "" end

    local grimoire = {
        CharacterID = char.ID, Type = gtype.ID, Leaves = gtype.Leaves, Magic = magicID,
        Level = 1, XP = 0, Unlocked = {}, Equipped = equipped, History = {}, ObtainedAt = os.time(),
    }

    DB.Query("INSERT INTO " .. T .. " (character_id, grimoire_type, leaves, magic, level, xp, unlocked, equipped, history, obtained_at) VALUES (?, ?, ?, ?, 1, 0, '[]', ?, '[]', ?)",
        { char.ID, gtype.ID, gtype.Leaves, magicID, Util.ToJSON(equipped, true), grimoire.ObtainedAt },
        function(_, newID)
            if not IsValid(ply) or ply.bcCharacter ~= char then return end

            grimoire.ID = newID
            ply.bcGrimoire = grimoire
            char.Magic = magicID

            Grimoire.AddHistory(ply, string.format("Grimoire obtenu : %s (%d feuilles), %s",
                gtype.Name, gtype.Leaves, BlackClover.Magic.Get(magicID).Name))
            Grimoire.CheckUnlocks(ply, true)
            Grimoire.Save(ply)
            BlackClover.Character.Save(ply)

            BlackClover.Progression.Apply(ply)
            Grimoire.Sync(ply)

            if ply:Alive() then
                ply:Give(Grimoire.WeaponClass)
                ply:SelectWeapon(Grimoire.WeaponClass)
            end

            Log.Admin("Grimoire", "%s (%s) a reçu un grimoire %s — %s",
                Log.FormatPlayer(ply), BlackClover.Character.GetFullName(char), gtype.Name, magicID)

            hook.Run("BlackClover.GrimoireObtained", ply, grimoire)
            callback(true, grimoire)
        end,
        function()
            callback(false, "Erreur de base de données (grimoire déjà existant ?).")
        end)
end

--- Retire le grimoire (administration uniquement).
function Grimoire.Remove(ply)
    local grimoire = ply.bcGrimoire
    if not grimoire then return false end

    DB.Query("DELETE FROM " .. T .. " WHERE id = ?", { grimoire.ID })

    ply.bcGrimoire = nil
    ply:StripWeapon(Grimoire.WeaponClass)
    Grimoire.Sync(ply)
    BlackClover.Progression.Apply(ply)

    return true
end

--- Change la magie (administration). Les sorts incompatibles sont retirés.
function Grimoire.SetMagic(ply, magicID)
    local char = ply.bcCharacter
    if not char or not BlackClover.Magic.Get(magicID) then return false end

    char.Magic = magicID

    local grimoire = ply.bcGrimoire
    if grimoire then
        grimoire.Magic = magicID

        for spellID in pairs(grimoire.Unlocked) do
            local spell = BlackClover.Spells.Get(spellID)
            if not spell or not BlackClover.Spells.MatchesMagic(spell, magicID) then
                grimoire.Unlocked[spellID] = nil
            end
        end

        Sanitize(grimoire)
        Grimoire.AddHistory(ply, "La magie du grimoire a changé : " .. BlackClover.Magic.Get(magicID).Name)
        Grimoire.CheckUnlocks(ply, true)
        Grimoire.Save(ply)
    end

    BlackClover.Character.Save(ply)
    BlackClover.Progression.Apply(ply)
    Grimoire.Sync(ply)

    return true
end

-- ─── Cérémonie ──────────────────────────────────────────────────────────

local CEREMONY_START, CEREMONY_RESULT, CEREMONY_CANCEL = 1, 2, 3

local function SendCeremony(ply, stage, data)
    net.Start("BlackClover.Grimoire.Ceremony")
        net.WriteUInt(stage, 2)
        net.WriteTable(data or {})
    net.Send(ply)
end

--- Vérifie si le joueur peut recevoir son grimoire à la tour.
function Grimoire.CanReceive(ply)
    local char = ply.bcCharacter
    if not char then return false, "Vous devez d'abord incarner un personnage." end
    if ply.bcGrimoire then return false, "Votre grimoire vous a déjà choisi." end
    if ply.bcInCeremony then return false, "La cérémonie est déjà en cours." end
    if char.Level < Config.Grimoire.MinLevel then
        return false, string.format("Vous devez être niveau %d.", Config.Grimoire.MinLevel)
    end
    if char.Age < Config.Grimoire.MinAge then
        return false, string.format("Les grimoires ne choisissent que les mages de %d ans ou plus.", Config.Grimoire.MinAge)
    end
    return true
end

--- Lance la cérémonie : le joueur est figé, les effets se jouent, puis le
-- grimoire apparaît. forcedLeaves / forcedMagic servent aux tests admin.
function Grimoire.StartCeremony(ply, forcedLeaves, forcedMagic, onDone)
    local ok, reason = Grimoire.CanReceive(ply)
    if not ok then
        if onDone then onDone(false, reason) end
        return false, reason
    end

    ply.bcInCeremony = true
    ply:Freeze(true)

    local char = ply.bcCharacter
    local duration = Config.Grimoire.CeremonyDuration

    SendCeremony(ply, CEREMONY_START, { Duration = duration })
    BlackClover.Effects.Play("ceremony", ply:GetPos() + Vector(0, 0, 40), { Color = Color(212, 175, 55), Scale = 1.5 })
    ply:EmitSound("ambient/levels/citadel/strange_talk5.wav", 70, 100)

    timer.Create("BlackClover.Ceremony." .. ply:EntIndex(), duration, 1, function()
        if not IsValid(ply) then return end

        ply.bcInCeremony = false
        ply:Freeze(false)

        if ply.bcCharacter ~= char then
            SendCeremony(ply, CEREMONY_CANCEL)
            return
        end

        Grimoire.Give(ply, forcedLeaves, forcedMagic, function(success, result)
            if not IsValid(ply) then return end

            if not success then
                SendCeremony(ply, CEREMONY_CANCEL)
                BlackClover.Notify(ply, result, BlackClover.NotifyType.Error, 5)
                if onDone then onDone(false, result) end
                return
            end

            local gtype = Grimoire.GetType(result.Type)
            local magic = BlackClover.Magic.Get(result.Magic)

            SendCeremony(ply, CEREMONY_RESULT, { Type = result.Type, Leaves = result.Leaves, Magic = result.Magic })
            BlackClover.Effects.Play("burst", ply:GetPos() + Vector(0, 0, 50), { Color = magic.Color, Scale = 2 })
            ply:EmitSound("ambient/levels/labs/electric_explosion1.wav", 75, 120)

            if gtype.Leaves >= 4 then
                BlackClover.Notify(nil, string.format("Un grimoire à %d feuilles a choisi %s !",
                    gtype.Leaves, BlackClover.Character.GetFullName(char)), BlackClover.NotifyType.Hint, 8)
            end

            if onDone then onDone(true, result) end
        end)
    end)

    return true
end

hook.Add("PlayerDisconnected", "BlackClover.Grimoire.Ceremony", function(ply)
    timer.Remove("BlackClover.Ceremony." .. ply:EntIndex())
end)
