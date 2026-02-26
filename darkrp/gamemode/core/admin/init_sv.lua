if not SERVER then return end

hook.Add("Initialize", "SC.Admin.Initialize", function()
    if SC.AdminDB and SC.AdminDB.Initialize then
        timer.Simple(0.1, function()
            SC.AdminDB.Initialize()
        end)
    end
end)

local banMessage = [[

Вы забанены!

-------------------------------------

Дата бана: %s

Дата разбана: %s

Осталось: %s

Админ: %s

Причина: %s

-------------------------------------

Написать амнистию/купить разбан: 

https://discord.gg/CGH6ax4n

]]

--[[
    @param seconds number
    @return string
]]
local function FormatTimeLeft(seconds)
    if seconds <= 0 then return "Разбанен" end
    
    local months = math.floor(seconds / 2592000)
    local weeks = math.floor((seconds % 2592000) / 604800)
    local days = math.floor((seconds % 604800) / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)

    local parts = {}
    if months > 0 then table.insert(parts, months .. "месяц" .. (months > 1 and "а" or "")) end
    if weeks > 0 then table.insert(parts, weeks .. "недел" .. (weeks > 1 and "и" or "я")) end
    if days > 0 then table.insert(parts, days .. "дн" .. (days > 1 and "ей" or "ь")) end
    if hours > 0 then table.insert(parts, hours .. "час" .. (hours > 1 and "ов" or "")) end
    if minutes > 0 then table.insert(parts, minutes .. "минут" .. (minutes > 1 and "" or "а")) end
    
    return #parts > 0 and table.concat(parts, " ") or seconds .. " секунд"
end

--[[
    @param data table
    @return string
]]
function SC.AdminDB.GetAdminNameFromData(data)
    if not data then return "Неизвестен" end
    
    if data.admin_name and data.admin_name ~= "" then
        return data.admin_name
    end
    
    local adminSteamid = data.admin or ""
    if adminSteamid == "" or adminSteamid == "CONSOLE" then return "Консоль" end
    
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:IsPlayer() and (ply:SteamID() == adminSteamid or tostring(ply:SteamID64()) == adminSteamid) then
            return string.format("%s(%s)", ply:Nick() or "Unknown", ply:SteamID() or adminSteamid)
        end
    end
    
    if string.find(adminSteamid, "^7656%d+") then
        local sid = util.SteamIDFrom64(adminSteamid)
        return sid and string.format("Неизвестен(%s)", sid) or adminSteamid
    end
    
    return adminSteamid ~= "" and string.format("Неизвестен(%s)", adminSteamid) or "Неизвестен"
end

--[[
    @param data table
    @return string
]]
function SC.AdminDB.FormatBanMessage(data)
    if not data then return "" end
    
    local banDate = os.date('%d.%m.%Y - %H:%M', data.ban_time)
    local unbanDate = (data.unban_time == 0) and "Навсегда" or os.date('%d.%m.%Y - %H:%M', data.unban_time)
    local timeLeft = data.unban_time > 0 and FormatTimeLeft(data.unban_time - os.time()) or "Навсегда"
    local admin = SC.AdminDB.GetAdminNameFromData(data)
    local reason = data.reason or "Не указана"
    
    return string.format(banMessage, banDate, unbanDate, timeLeft, admin, reason)
end

--[[
    @param steamid64 string
    @param ip string
    @param pass string
    @param cl_pass string
    @param name string
    @return boolean, string|nil
]]
function SC.AdminDB.CheckPassword(steamid64, ip, pass, cl_pass, name)
    if not SC.AdminDB or not SC.AdminDB.IsBanned then return true end
    
    local banned, data = SC.AdminDB.IsBanned(steamid64)
    if not banned then return true end
    
    return false, SC.AdminDB.FormatBanMessage(data)
end

hook.Add("CheckPassword", "SC.AdminDB.CheckPassword", SC.AdminDB.CheckPassword)

hook.Add("PlayerInitialSpawn", "SC.Admin.LoadPlayer", function(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    timer.Simple(0.1, function()
        if not IsValid(ply) then return end
        
        if SC.Admin and SC.Admin.LoadPlayer then
            SC.Admin.LoadPlayer(ply)
        end
    end)
end)

hook.Add("PlayerDisconnected", "SC.Admin.SavePlayer", function(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    if SC.AdminDB and SC.AdminDB.Save then
        SC.AdminDB.Save(ply)
    end
end)
