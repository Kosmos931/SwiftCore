if not SERVER then return end

SC.Database = SC.Database or {}
local db = SC.Database
db.PlayerData = db.PlayerData or {}

local function GetBaseFraction()
    return (SC.FBase and SC.FBase()) or "citizen"
end

--[[
    @return boolean
]]
function db.Initialize()
    local query = string.format("CREATE TABLE IF NOT EXISTS sc_players (steamid TEXT PRIMARY KEY, money INTEGER DEFAULT 0, hunger INTEGER DEFAULT 100, name TEXT, fraction TEXT DEFAULT 'citizen')")
    local result = sql.Query(query)
    if result == false then
        ErrorNoHalt("[SC.Database] Ошибка создания таблицы: " .. (sql.LastError() or "неизвестно") .. "\n")
        return false
    end
    return true
end

--[[
    @param ply Player
]]
function db.LoadPlayer(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    local steamid = ply:SteamID64()
    if not steamid then 
        ErrorNoHalt("[SC.Database] Не удалось получить SteamID64 для игрока\n")
        return 
    end
    
    local query = "SELECT * FROM sc_players WHERE steamid = " .. sql.SQLStr(steamid)
    local data = sql.QueryRow(query)
    
    if data == false then
        ErrorNoHalt("[SC.Database] Ошибка SQL: " .. (sql.LastError() or "неизвестно") .. "\n")
        data = nil
    end
    
    local baseFraction = GetBaseFraction()
    
    if data then
        db.PlayerData[steamid] = {
            money = tonumber(data.money) or 0,
            hunger = tonumber(data.hunger) or 100,
            name = tostring(data.name or ply:Nick() or "Unknown"),
            fraction = tostring(data.fraction or baseFraction)
        }
    else
        local startAmount = (SC.Config and SC.Config.Money and SC.Config.Money.StartAmount) or 1000
        db.PlayerData[steamid] = {
            money = startAmount,
            hunger = 100,
            name = ply:Nick() or "Unknown",
            fraction = baseFraction
        }
        SC.DBSave(ply)
    end
    timer.Simple(0.1, function()
        db.ApplyPlayerData(ply)
        local playerData = SC.DBGet and SC.DBGet(ply)
        if SC.FSetPly and playerData and playerData.fraction then
            SC.FSetPly(ply, playerData.fraction)
        elseif SC.FSetPly and not ply:GetFraction() then
            SC.FSetPly(ply, GetBaseFraction())
        end
    end)
end

--[[
    @param ply Player
]]
function db.SavePlayer(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    local steamid = ply:SteamID64()
    if not steamid then return end
    
    local data = db.PlayerData[steamid]
    if not data then return end
    
    local money = tonumber(data.money) or 0
    local hunger = tonumber(data.hunger) or 100
    local name = string.sub(tostring(data.name or ply:Nick() or "Unknown"), 1, 64)
    local fraction = string.sub(tostring(data.fraction or GetBaseFraction()), 1, 32)
    
    if not string.match(fraction, "^[%w_]+$") then
        fraction = "citizen"
    end
    
    local query = string.format("INSERT OR REPLACE INTO sc_players (steamid, money, hunger, name, fraction) VALUES (%s, %d, %d, %s, %s)",
        sql.SQLStr(steamid), money, hunger, sql.SQLStr(name), sql.SQLStr(fraction))
    
    local result = sql.Query(query)
    if result == false then
        ErrorNoHalt("[SC.Database] Ошибка сохранения данных " .. steamid .. ": " .. (sql.LastError() or "неизвестно") .. "\n")
    end
end

--[[
    @param ply Player
]]
function db.ApplyPlayerData(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    local steamid = ply:SteamID64()
    if not steamid then return end
    
    local data = SC.DBGet and SC.DBGet(ply)
    if not data then return end
    
    if ply.SetMoney and data.money then
        ply:SetMoney(data.money)
    end
    
    if ply.SetHunger and data.hunger then
        ply:SetHunger(data.hunger)
    end
end

--[[
    @param ply Player
    @return table|nil
]]
function db.GetPlayerData(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return nil end
    local steamid = ply:SteamID64()
    if not steamid then return nil end
    return db.PlayerData[steamid]
end

hook.Add("Initialize", "db.Initialize", db.Initialize)

hook.Add("PlayerInitialSpawn", "db.LoadPlayer", function(ply)
    SC.DBLoad(ply)
end)

hook.Add("PlayerDisconnected", "db.SavePlayer", function(ply)
    SC.DBSave(ply)
    local steamid = ply:SteamID64()
    if steamid then
        db.PlayerData[steamid] = nil
    end
end)

local saveQueue = {}
local isSaving = false

--[[
    Обрабатывает очередь сохранений (сохраняет по одному игроку за тик)
]]
local function ProcessSaveQueue()
    if isSaving then return end
    if #saveQueue == 0 then return end
    
    isSaving = true
    local ply = table.remove(saveQueue, 1)
    
    if IsValid(ply) and ply:IsPlayer() then
        SC.DBSave(ply)
    end
    
    isSaving = false
end

hook.Add("Think", "SC.Database.ProcessSaveQueue", ProcessSaveQueue)

timer.Create("db.AutoSave", 60, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:IsPlayer() then
            table.insert(saveQueue, ply)
        end
    end
end)

SC.DB = SC.Database
SC.DBLoad = db.LoadPlayer
SC.DBSave = db.SavePlayer
SC.DBGet = db.GetPlayerData