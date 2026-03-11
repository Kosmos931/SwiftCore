if not SERVER then return end

SC.AdminDB = SC.AdminDB or {}
local db = SC.AdminDB

function db.Initialize()
    local adminTable = [[
        CREATE TABLE IF NOT EXISTS sc_admin (
            steamid TEXT PRIMARY KEY,
            rank TEXT DEFAULT 'user',
            flags TEXT DEFAULT '',
            prev_rank TEXT DEFAULT '',
            rank_expire_time INTEGER DEFAULT 0
        )
    ]]
    
    local bansTable = [[
        CREATE TABLE IF NOT EXISTS sc_bans (
            steamid TEXT PRIMARY KEY,
            name TEXT DEFAULT '',
            reason TEXT DEFAULT '',
            admin TEXT DEFAULT '',
            admin_name TEXT DEFAULT '',
            ban_time INTEGER DEFAULT 0,
            unban_time INTEGER DEFAULT 0
        )
    ]]
    
    local adminResult = sql.Query(adminTable)
    if adminResult == false then
        ErrorNoHalt("[SC.AdminDB] Ошибка создания таблицы sc_admin: " .. (sql.LastError() or "неизвестно") .. "\n")
        return false
    end
    
    local bansResult = sql.Query(bansTable)
    if bansResult == false then
        ErrorNoHalt("[SC.AdminDB] Ошибка создания таблицы sc_bans: " .. (sql.LastError() or "неизвестно") .. "\n")
        return false
    end
    
    local adminColumns = sql.Query("PRAGMA table_info(sc_admin)")
    if adminColumns then
        local hasPrevRank = false
        local hasRankExpireTime = false
        
        for _, col in ipairs(adminColumns) do
            if col.name == "prev_rank" then hasPrevRank = true end
            if col.name == "rank_expire_time" then hasRankExpireTime = true end
        end
        
        if not hasPrevRank then
            sql.Query("ALTER TABLE sc_admin ADD COLUMN prev_rank TEXT DEFAULT ''")
        end
        if not hasRankExpireTime then
            sql.Query("ALTER TABLE sc_admin ADD COLUMN rank_expire_time INTEGER DEFAULT 0")
        end
    end
    
    local columns = sql.Query("PRAGMA table_info(sc_bans)")
    if columns then
        local hasName = false
        local hasAdminName = false
        
        for _, col in ipairs(columns) do
            if col.name == "name" then hasName = true end
            if col.name == "admin_name" then hasAdminName = true end
        end
        
        if not hasName then
            sql.Query("ALTER TABLE sc_bans ADD COLUMN name TEXT DEFAULT ''")
        end
        if not hasAdminName then
            sql.Query("ALTER TABLE sc_bans ADD COLUMN admin_name TEXT DEFAULT ''")
        end
    end
    
    return true
end

function db.Load(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    local steamid = ply:SteamID64()
    if not steamid then return end
    
    local query = "SELECT * FROM sc_admin WHERE steamid = " .. sql.SQLStr(steamid)
    local data = sql.QueryRow(query)
    
    if data == false then
        ErrorNoHalt("[SC.AdminDB] Ошибка SQL: " .. (sql.LastError() or "неизвестно") .. "\n")
        data = nil
    end
    
    local admin = SC.Admin
    local rank = tostring(data and data.rank or admin.DefaultRank or "user")
    
    local expireTime = tonumber(data and data.rank_expire_time or 0) or 0
    local prevRank = tostring(data and data.prev_rank or "") or ""
    
    if expireTime > 0 and os.time() >= expireTime then
        if prevRank ~= "" then
            rank = prevRank
            prevRank = ""
            expireTime = 0
            
            local updateQuery = string.format("UPDATE sc_admin SET rank = %s, prev_rank = '', rank_expire_time = 0 WHERE steamid = %s",
                sql.SQLStr(rank), sql.SQLStr(steamid))
            sql.Query(updateQuery)
        else
            rank = admin.DefaultRank or "user"
            expireTime = 0
            
            local updateQuery = string.format("UPDATE sc_admin SET rank = %s, prev_rank = '', rank_expire_time = 0 WHERE steamid = %s",
                sql.SQLStr(rank), sql.SQLStr(steamid))
            sql.Query(updateQuery)
        end
    end
    
    local rankData = SC.AdminRanks and SC.AdminRanks.Get(rank)
    local rankFlags = rankData and rankData.Flags or ""
    
    local flags = tostring(data and data.flags or "")
    
    if flags == "" then
        flags = rankFlags
    end
    
    admin.PlayerData[steamid] = {
        rank = rank,
        flags = flags,
        prev_rank = prevRank,
        rank_expire_time = expireTime
    }
    
    ply:SetNWString(admin.NWKey, rank)
    ply:SetNWString(admin.NWKeyFlags, flags)
    
    if expireTime > 0 and os.time() < expireTime then
        timer.Simple(0.2, function()
            if not IsValid(ply) or not ply:IsPlayer() then return end
            local remainingTime = expireTime - os.time()
            if remainingTime > 0 and remainingTime <= 31536000 then
                local timerName = "SC.Admin.ExpireTimer." .. tostring(steamid)
                if timer.Exists(timerName) then
                    timer.Remove(timerName)
                end
                
                timer.Create(timerName, remainingTime, 1, function()
                    local targetPly = player.GetBySteamID64(steamid)
                    if IsValid(targetPly) and targetPly:IsPlayer() and SC.Admin and SC.Admin.SetRank then
                        local query = "SELECT prev_rank FROM sc_admin WHERE steamid = " .. sql.SQLStr(steamid)
                        local timerData = sql.QueryRow(query)
                        local prevRankFromDB = (timerData and timerData.prev_rank) or ""
                        
                        if prevRankFromDB == "" then
                            prevRankFromDB = (SC.Admin and SC.Admin.DefaultRank) or "user"
                        end
                        
                        local updateQuery = string.format("UPDATE sc_admin SET rank = %s, prev_rank = '', rank_expire_time = 0 WHERE steamid = %s",
                            sql.SQLStr(prevRankFromDB), sql.SQLStr(steamid))
                        sql.Query(updateQuery)
                        
                        SC.Admin.SetRank(targetPly, prevRankFromDB)
                        
                        if SC.Admin and SC.Admin.Notify then
                            SC.Admin.Notify.Send(targetPly, string.format("Ваш ранг истек, установлен: %s", prevRankFromDB))
                        end
                    else
                        local query = "SELECT prev_rank FROM sc_admin WHERE steamid = " .. sql.SQLStr(steamid)
                        local timerData = sql.QueryRow(query)
                        local prevRankFromDB = (timerData and timerData.prev_rank) or ""
                        
                        if prevRankFromDB ~= "" then
                            local updateQuery = string.format("UPDATE sc_admin SET rank = %s, prev_rank = '', rank_expire_time = 0 WHERE steamid = %s",
                                sql.SQLStr(prevRankFromDB), sql.SQLStr(steamid))
                            sql.Query(updateQuery)
                        end
                    end
                end)
            end
        end)
    end
    
    if not data then
        db.Save(ply)
    elseif data and data.flags == "" and flags ~= "" then
        db.Save(ply)
    end
end

function db.Save(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    local steamid = ply:SteamID64()
    if not steamid then return end
    
    local admin = SC.Admin
    local data = admin.PlayerData[steamid]
    if not data then return end
    
    local rank = string.sub(tostring(data.rank or admin.DefaultRank or "user"), 1, 32)
    local flags = tostring(data.flags or "")
    
    if flags == "" then
        local rankData = SC.AdminRanks and SC.AdminRanks.Get(rank)
        if rankData and rankData.Flags then
            flags = rankData.Flags
            data.flags = flags
        end
    end
    
    flags = string.sub(flags, 1, 64)
    
    if not string.match(flags, "^[a-z]*$") then
        flags = ""
    end
    
    local prevRank = data.prev_rank
    local expireTime = data.rank_expire_time
    
    if prevRank == nil or expireTime == nil then
        local currentQuery = "SELECT prev_rank, rank_expire_time FROM sc_admin WHERE steamid = " .. sql.SQLStr(steamid)
        local currentData = sql.QueryRow(currentQuery)
        if currentData then
            prevRank = prevRank or (currentData.prev_rank or "")
            expireTime = expireTime or (tonumber(currentData.rank_expire_time or 0) or 0)
        else
            prevRank = prevRank or ""
            expireTime = expireTime or 0
        end
    end
    
    prevRank = prevRank or ""
    expireTime = tonumber(expireTime) or 0
    
    local query = string.format("INSERT OR REPLACE INTO sc_admin (steamid, rank, flags, prev_rank, rank_expire_time) VALUES (%s, %s, %s, %s, %d)",
        sql.SQLStr(steamid), sql.SQLStr(rank), sql.SQLStr(flags), sql.SQLStr(prevRank), expireTime)
    
    local result = sql.Query(query)
    if result == false then
        ErrorNoHalt("[SC.AdminDB] Ошибка сохранения " .. steamid .. ": " .. (sql.LastError() or "неизвестно") .. "\n")
    end
end

function db.IsBanned(steamid)
    if not steamid then return false, nil end
    
    local query = "SELECT * FROM sc_bans WHERE steamid = " .. sql.SQLStr(steamid)
    local data = sql.QueryRow(query)
    
    if data == false then
        ErrorNoHalt("[SC.AdminDB] Ошибка SQL: " .. (sql.LastError() or "неизвестно") .. "\n")
        return false, nil
    end
    
    if not data then return false, nil end
    
    local unbanTime = tonumber(data.unban_time) or 0
    local banTime = tonumber(data.ban_time) or 0
    
    if unbanTime > 0 and os.time() >= unbanTime then
        local deleteQuery = "DELETE FROM sc_bans WHERE steamid = " .. sql.SQLStr(steamid)
        sql.Query(deleteQuery)
        return false, nil
    end
    
    if unbanTime == 0 or os.time() < unbanTime then
        return true, {
            name = tostring(data.name or ""),
            reason = tostring(data.reason or ""),
            admin = tostring(data.admin or ""),
            admin_name = tostring(data.admin_name or ""),
            ban_time = banTime,
            unban_time = unbanTime
        }
    end
    
    return false, nil
end

function db.Ban(steamid, reason, adminSteamid, duration, targetName, adminName)
    if not steamid then return false end
    
    reason = tostring(reason or "")
    adminSteamid = tostring(adminSteamid or "")
    targetName = tostring(targetName or "")
    adminName = tostring(adminName or "")
    duration = tonumber(duration) or 0
    
    local banTime = os.time()
    local unbanTime = 0
    
    if duration > 0 then
        unbanTime = banTime + duration
    end
    
    local query = string.format("INSERT OR REPLACE INTO sc_bans (steamid, name, reason, admin, admin_name, ban_time, unban_time) VALUES (%s, %s, %s, %s, %s, %d, %d)",
        sql.SQLStr(steamid), sql.SQLStr(targetName), sql.SQLStr(reason), sql.SQLStr(adminSteamid), sql.SQLStr(adminName), banTime, unbanTime)
    
    local result = sql.Query(query)
    if result == false then
        ErrorNoHalt("[SC.AdminDB] Ошибка бана " .. steamid .. ": " .. (sql.LastError() or "неизвестно") .. "\n")
        return false
    end
    
    return true
end

function db.Unban(steamid)
    if not steamid then return false end
    
    local query = "DELETE FROM sc_bans WHERE steamid = " .. sql.SQLStr(steamid)
    local result = sql.Query(query)
    
    if result == false then
        ErrorNoHalt("[SC.AdminDB] Ошибка разбана " .. steamid .. ": " .. (sql.LastError() or "неизвестно") .. "\n")
        return false
    end
    
    return true
end
