--[[
    Black Clover RP — systems/grimoire/sv_tower.lua
    Realm : SERVEUR

    Sauvegarde des "Tours des Grimoires" (PNJ de cérémonie) placées par le staff.
    - Le staff fait apparaître le PNJ via le menu Q > Entités > Black Clover.
    - /bc_savetowers enregistre leurs positions pour la carte actuelle.
    - Elles réapparaissent automatiquement au démarrage et après un nettoyage.

    Fichier : garrysmod/data/blackclover/towers/<carte>.txt
]]

local Grimoire = BlackClover.Grimoire
local Log = BlackClover.Log

local TOWER_CLASS = "bc_grimoire_tower"
local DIRECTORY = "blackclover/towers"

local function GetFilePath()
    return DIRECTORY .. "/" .. string.lower(game.GetMap()) .. ".txt"
end

function Grimoire.SaveTowers()
    local list = {}

    for _, ent in ipairs(ents.FindByClass(TOWER_CLASS)) do
        list[#list + 1] = { Pos = ent:GetPos(), Ang = ent:GetAngles() }
    end

    file.CreateDir(DIRECTORY)
    file.Write(GetFilePath(), util.TableToJSON(list))

    return #list
end

function Grimoire.SpawnTowers()
    local list = BlackClover.Util.FromJSON(file.Read(GetFilePath(), "DATA"), {})

    for _, data in ipairs(list) do
        if isvector(data.Pos) and isangle(data.Ang) then
            local ent = ents.Create(TOWER_CLASS)
            if IsValid(ent) then
                ent:SetPos(data.Pos)
                ent:SetAngles(data.Ang)
                ent:Spawn()
            end
        end
    end

    if #list > 0 then
        Log.Info("Grimoire", "%d Tour(s) des Grimoires chargée(s)", #list)
    end
end

hook.Add("InitPostEntity", "BlackClover.Grimoire.Towers", Grimoire.SpawnTowers)
hook.Add("PostCleanupMap", "BlackClover.Grimoire.Towers", Grimoire.SpawnTowers)
