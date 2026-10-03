--[[
    Black Clover RP — core/sv_database.lua
    Realm : SERVEUR

    Abstraction de base de données.
    Tous les systèmes passent par BlackClover.Database et ne savent pas
    s'ils parlent à SQLite ou à MySQL. Pour changer de moteur, il suffit
    de modifier Config.Database.Driver dans core/sv_config.lua.

    - "sqlite" : intégré à Garry's Mod (fichier garrysmod/sv.db)
    - "mysql"  : nécessite le module MySQLOO (garrysmod/lua/bin/)
                 En cas d'échec de chargement, retour automatique à SQLite.

    API :
        DB.Table("characters")                         → "bc_characters"
        DB.RegisterTable("characters", "colonnes…")    → déclare une table
        DB.Query(sql, params, onSuccess, onError)      → requête paramétrée
        DB.OnReady(callback)                           → exécute quand la BDD est prête

    Les paramètres remplacent les "?" dans l'ordre, et sont TOUJOURS échappés :
        DB.Query("SELECT * FROM " .. DB.Table("characters") .. " WHERE steamid64 = ?",
            { ply:SteamID64() },
            function(rows, lastInsertID) ... end)

    Dans un schéma, {ID} est remplacé par la clé primaire auto-incrémentée
    adaptée au moteur.

    Note : SQLite renvoie toutes les valeurs sous forme de chaînes.
    Utilisez toujours tonumber / Util.ToNumber sur les résultats.
]]

BlackClover.Database = BlackClover.Database or {}
local DB = BlackClover.Database
local Config = BlackClover.Config
local Log = BlackClover.Log

DB.Connected = DB.Connected or false
DB.Tables = DB.Tables or {}
DB.ReadyQueue = DB.ReadyQueue or {}

-- Valeur spéciale pour écrire NULL dans une requête
DB.NULL = DB.NULL or setmetatable({}, { __tostring = function() return "NULL" end })

-- ─── Drivers ────────────────────────────────────────────────────────────

local Drivers = {}

Drivers.sqlite = {
    PrimaryKey = "INTEGER PRIMARY KEY AUTOINCREMENT",

    Connect = function(onConnected)
        onConnected()
    end,

    Escape = function(value)
        return sql.SQLStr(value)
    end,

    Query = function(query, onSuccess, onError)
        local result = sql.Query(query)

        if result == false then
            onError(sql.LastError() or "erreur inconnue")
            return
        end

        local lastID = tonumber(sql.QueryValue("SELECT last_insert_rowid()"))
        onSuccess(result or {}, lastID)
    end,
}

Drivers.mysql = {
    PrimaryKey = "INT NOT NULL AUTO_INCREMENT PRIMARY KEY",

    Connect = function(onConnected, onFailed)
        local ok = pcall(require, "mysqloo")
        if not ok or not mysqloo then
            onFailed("module MySQLOO introuvable")
            return
        end

        local c = Config.Database.MySQL
        local connection = mysqloo.connect(c.Host, c.Username, c.Password, c.Database, c.Port)

        connection.onConnected = function()
            Drivers.mysql.Connection = connection
            onConnected()
        end

        connection.onConnectionFailed = function(_, err)
            onFailed(err)
        end

        connection:connect()
    end,

    Escape = function(value)
        return "'" .. Drivers.mysql.Connection:escape(value) .. "'"
    end,

    Query = function(query, onSuccess, onError)
        local q = Drivers.mysql.Connection:query(query)

        q.onSuccess = function(self, data)
            onSuccess(data or {}, self:lastInsert())
        end

        q.onError = function(_, err)
            onError(err)
        end

        q:start()
    end,
}

local function GetDriver()
    return Drivers[DB.DriverName or "sqlite"]
end

-- ─── Fonctions publiques ────────────────────────────────────────────────

function DB.Table(name)
    return Config.Database.TablePrefix .. name
end

--- Convertit une valeur Lua en valeur SQL sûre.
function DB.Format(value)
    if value == nil or value == DB.NULL then return "NULL" end

    local valueType = type(value)

    if valueType == "number" then
        if value ~= value or value == math.huge or value == -math.huge then return "0" end
        return tostring(value)
    elseif valueType == "boolean" then
        return value and "1" or "0"
    end

    return GetDriver().Escape(tostring(value))
end

--- Exécute une requête paramétrée.
-- @param query string Requête avec des "?"
-- @param params table|nil Valeurs (utiliser DB.NULL pour NULL)
-- @param onSuccess function(rows, lastInsertID)|nil
-- @param onError function(err)|nil
function DB.Query(query, params, onSuccess, onError)
    if params then
        local index = 0
        query = string.gsub(query, "%?", function()
            index = index + 1
            return DB.Format(params[index])
        end)
    end

    if not DB.Connected then
        Log.Error("Database", "Requête ignorée, base non connectée : %s", query)
        if onError then onError("base non connectée") end
        return
    end

    GetDriver().Query(query, function(rows, lastID)
        if onSuccess then
            local ok, err = xpcall(onSuccess, debug.traceback, rows, lastID)
            if not ok then Log.Error("Database", "Erreur dans le callback :\n%s", err) end
        end
    end, function(err)
        Log.Error("Database", "Requête échouée : %s\n→ %s", tostring(err), query)
        if onError then onError(err) end
    end)
end

--- Déclare une table. À appeler au chargement d'un système (fichier sv_).
-- @param name string Nom sans préfixe
-- @param columns string Définition des colonnes ({ID} = clé primaire)
function DB.RegisterTable(name, columns)
    DB.Tables[name] = columns
end

--- Exécute callback dès que la base est prête (immédiatement si déjà prête).
function DB.OnReady(callback)
    if DB.Connected then
        callback()
    else
        DB.ReadyQueue[#DB.ReadyQueue + 1] = callback
    end
end

local function CreateTables()
    local driver = GetDriver()

    for name, columns in pairs(DB.Tables) do
        local schema = string.Replace(columns, "{ID}", driver.PrimaryKey)
        DB.Query("CREATE TABLE IF NOT EXISTS " .. DB.Table(name) .. " (" .. schema .. ")")
    end
end

local function OnConnected()
    DB.Connected = true
    Log.Info("Database", "Connecté (%s)", DB.DriverName)

    CreateTables()

    local queue = DB.ReadyQueue
    DB.ReadyQueue = {}
    for _, callback in ipairs(queue) do
        local ok, err = xpcall(callback, debug.traceback)
        if not ok then Log.Error("Database", "Erreur OnReady :\n%s", err) end
    end

    hook.Run("BlackClover.DatabaseReady")
end

function DB.Initialize()
    if DB.Connected then return end

    local driverName = string.lower(tostring(Config.Database.Driver))
    if not Drivers[driverName] then
        Log.Error("Database", "Driver inconnu \"%s\", utilisation de SQLite", driverName)
        driverName = "sqlite"
    end

    DB.DriverName = driverName

    Drivers[driverName].Connect(OnConnected, function(err)
        Log.Error("Database", "Connexion %s impossible (%s) → retour à SQLite", driverName, tostring(err))
        DB.DriverName = "sqlite"
        Drivers.sqlite.Connect(OnConnected)
    end)
end

hook.Add("BlackClover.Initialized", "BlackClover.Database.Initialize", DB.Initialize)
