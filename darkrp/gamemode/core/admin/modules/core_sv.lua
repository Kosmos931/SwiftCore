if not SERVER then return end

if not SC.AdminCommands or not SC.AdminCommands.Create then
    ErrorNoHalt("[SC.Admin] Система команд не загружена!\n")
    return
end

local cmd = SC.AdminCommands

local function notify(ply, msg)
    if SC.Admin and SC.Admin.Notify then
        SC.Admin.Notify.Send(ply, msg)
    elseif IsValid(ply) and ply:IsPlayer() then
        ply:ChatPrint(msg)
    else
        print("[SC] " .. msg)
    end
end

local function notifyErr(ply, msg)
    if SC.Admin and SC.Admin.Notify then
        SC.Admin.Notify.Error(ply, msg)
    else
        notify(ply, "ОШИБКА: " .. msg)
    end
end

local function GetPlayerName(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return "Неизвестен" end
    local nick = ply:Nick() or "Unknown"
    local steamid = ply:SteamID() or ""
    if steamid == "" and ply:IsBot() then steamid = "BOT" end
    return steamid ~= "" and nick .. "(" .. steamid .. ")" or nick
end

local function FormatPlayerName(nick, steamid)
    if not nick then return "Неизвестен" end
    if steamid and steamid ~= "" and nick ~= steamid then
        return string.format("%s(%s)", nick, steamid)
    end
    return nick
end

local function FormatDuration(seconds, rawTime)
    if not seconds or seconds <= 0 then return " навсегда", "" end
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local durationStr = hours > 0 and minutes > 0 and string.format(" на %dч %dм", hours, minutes)
        or hours > 0 and string.format(" на %dч", hours)
        or minutes > 0 and string.format(" на %dм", minutes)
        or ""
    local expStr = rawTime and string.format(" через %s", rawTime) or ""
    return durationStr, expStr
end

local function GetPlayerFromEntity(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return nil, nil, nil, nil end
    local nick = ply:Nick() or "Unknown"
    local steamid = ply:SteamID() or ""
    if steamid == "" and ply:IsBot() then 
        steamid = "BOT" 
    end
    return ply, nick, steamid, ply:SteamID64()
end

local function GetPlayerFromSteamID(identifier)
    identifier = string.gsub(identifier, ":+", ":")
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:IsPlayer() then
            local plySteamID = ply:SteamID()
            if plySteamID and plySteamID == identifier then
                return ply, ply:Nick() or "Unknown", plySteamID, ply:SteamID64()
            end
        end
    end
    local sid64 = util.SteamIDTo64(identifier)
    return nil, identifier, identifier, sid64
end

local function GetPlayerFromSteamID64(identifier)
    local ply = player.GetBySteamID64(identifier)
    if IsValid(ply) and ply:IsPlayer() then
        return ply, ply:Nick() or "Unknown", ply:SteamID(), ply:SteamID64()
    end
    local sid = util.SteamIDFrom64(identifier)
    return nil, sid or identifier, sid or identifier, identifier
end

local function GetPlayerFromName(identifier)
    identifier = string.lower(identifier)
    local found = {}
    local exactMatch = nil
    
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:IsPlayer() then
            local name = string.lower(ply:Nick() or "")
            if name == identifier then
                exactMatch = ply
            elseif string.find(name, identifier, 1, true) then
                table.insert(found, ply)
            end
        end
    end
    
    local result = exactMatch or (#found == 1 and found[1] or nil)
    if IsValid(result) and result:IsPlayer() then
        return result, result:Nick() or "Unknown", result:SteamID(), result:SteamID64()
    end
    
    return nil, nil, nil, nil
end

local function GetPlayerFromIdentifier(identifier)
    if IsValid(identifier) and identifier:IsPlayer() then
        return GetPlayerFromEntity(identifier)
    end
    
    if type(identifier) ~= "string" then return nil, nil, nil, nil end
    
    if string.find(identifier, "^STEAM_") then
        return GetPlayerFromSteamID(identifier)
    elseif string.find(identifier, "^7656%d+") then
        return GetPlayerFromSteamID64(identifier)
    else
        return GetPlayerFromName(identifier)
    end
end

local function SaveRankToDB(steamid64, rank, flags, prevRank, expireTime)
    if not SC.AdminDB then return false end
    prevRank = prevRank or ""
    expireTime = tonumber(expireTime) or 0
    local query = string.format("INSERT OR REPLACE INTO sc_admin (steamid, rank, flags, prev_rank, rank_expire_time) VALUES (%s, %s, %s, %s, %d)",
        sql.SQLStr(steamid64), sql.SQLStr(rank), sql.SQLStr(flags or ""), sql.SQLStr(prevRank), expireTime)
    local result = sql.Query(query)
    return result ~= false
end

local expireTimers = {}

local function CreateExpireTimer(steamid64, expTime)
    if not expTime or expTime <= 0 or expTime > 31536000 then return end
    
    local timerName = "SC.Admin.ExpireTimer." .. tostring(steamid64)
    if timer.Exists(timerName) then
        timer.Remove(timerName)
    end
    
    timer.Create(timerName, expTime, 1, function()
        expireTimers[steamid64] = nil
        
        if not SC.AdminDB then return end
        local query = "SELECT prev_rank FROM sc_admin WHERE steamid = " .. sql.SQLStr(steamid64)
        local data = sql.QueryRow(query)
        local prevRank = (data and data.prev_rank) or ""
        
        if prevRank == "" then
            prevRank = (SC.Admin and SC.Admin.DefaultRank) or "user"
        end
        
        local targetPly = player.GetBySteamID64(steamid64)
        if IsValid(targetPly) and targetPly:IsPlayer() and SC.Admin and SC.Admin.SetRank then
            local updateQuery = string.format("UPDATE sc_admin SET rank = %s, prev_rank = '', rank_expire_time = 0 WHERE steamid = %s",
                sql.SQLStr(prevRank), sql.SQLStr(steamid64))
            sql.Query(updateQuery)
            
            SC.Admin.SetRank(targetPly, prevRank)
            notify(targetPly, string.format("Ваш ранг истек, установлен: %s", prevRank))
        else
            if prevRank ~= "" then
                local updateQuery = string.format("UPDATE sc_admin SET rank = %s, prev_rank = '', rank_expire_time = 0 WHERE steamid = %s",
                    sql.SQLStr(prevRank), sql.SQLStr(steamid64))
                sql.Query(updateQuery)
            end
        end
    end)
    
    expireTimers[steamid64] = timerName
end

cmd.Create("setrank", function(ply, args)
    if not args.target or not args.rank then
        notify(ply, "Использование: sc setrank <ник|SteamID> <ранг> [длительность] [ранг после истечения]")
        notify(ply, "Примеры: sc setrank Игрок vip | sc setrank Игрок vip 10mi | sc setrank Игрок vip 1h user")
        return
    end
    
    local isConsole = not IsValid(ply) or not ply:IsPlayer()
    local adminName = isConsole and "Консоль" or GetPlayerName(ply)
    local targetPly, targetNick, targetSteamID, steamid64 = GetPlayerFromIdentifier(args.target)
    
    if not targetNick then
        notifyErr(ply, string.format("Игрок '%s' не найден!", tostring(args.target)))
        return
    end
    
    if IsValid(targetPly) and targetPly:IsPlayer() then
        steamid64 = targetPly:SteamID64()
    elseif not steamid64 and type(args.target) == "string" then
        if string.find(args.target, "^STEAM_") then
            steamid64 = util.SteamIDTo64(args.target)
        elseif string.find(args.target, "^7656%d+") then
            steamid64 = args.target
        end
        if not steamid64 then
            notifyErr(ply, string.format("Игрок '%s' должен быть онлайн для установки ранга!", tostring(args.target)))
            return
        end
    end
    
    local rankName = string.lower(args.rank)
    local rankData = SC.AdminRanks and SC.AdminRanks.Get(rankName)
    if not rankData then
        notifyErr(ply, string.format("Ранг '%s' не найден!", rankName))
        return
    end
    
    local currentRank = ""
    if IsValid(targetPly) and targetPly:IsPlayer() then
        currentRank = SC.Admin and SC.Admin.GetRank(targetPly) or ""
    else
        if SC.AdminDB then
            local query = "SELECT rank FROM sc_admin WHERE steamid = " .. sql.SQLStr(steamid64)
            local data = sql.QueryRow(query)
            currentRank = (data and data.rank) or ""
        end
    end
    
    if currentRank == "" then
        currentRank = (SC.Admin and SC.Admin.DefaultRank) or "user"
    end
    
    local expTime = 0
    if args.exp_time then
        if type(args.exp_time) == "number" then
            expTime = args.exp_time
        else
            expTime = tonumber(args.exp_time) or 0
        end
    end
    local durationStr, expStr = FormatDuration(expTime, args.raw and args.raw.exp_time)
    
    local prevRank = ""
    local expireTime = 0
    if expTime > 0 then
        prevRank = currentRank
        expireTime = os.time() + expTime
    end
    
    if IsValid(targetPly) and targetPly:IsPlayer() then
        if SC.Admin and SC.Admin.SetRank then
            local steamid = targetPly:SteamID64()
            if steamid then
                if not SC.Admin.PlayerData[steamid] then
                    SC.Admin.PlayerData[steamid] = {}
                end
                SC.Admin.PlayerData[steamid].prev_rank = prevRank
                SC.Admin.PlayerData[steamid].rank_expire_time = expireTime
            end
            
            SC.Admin.SetRank(targetPly, rankName)
        end
    else
        local flags = (rankData and rankData.Flags) or ""
        if not SaveRankToDB(steamid64, rankName, flags, prevRank, expireTime) then
            notifyErr(ply, string.format("Ошибка сохранения в БД: %s", sql.LastError() or "неизвестно"))
            return
        end
    end
    
    if expTime > 0 then
        CreateExpireTimer(steamid64, expTime)
    end
    
    local targetName = FormatPlayerName(targetNick, targetSteamID)
    local staffMsg = string.format("%s установил %s ранг %s%s%s", adminName, targetName, rankName, durationStr, expStr)
    
    if SC.Admin and SC.Admin.Notify and SC.Admin.Notify.AllStaff then
        SC.Admin.Notify.AllStaff(staffMsg, ply)
    end
    
    if IsValid(targetPly) and targetPly:IsPlayer() then
        notify(targetPly, string.format("Ваш ранг изменен на: %s%s", rankName, durationStr))
        if SC.Admin and SC.Admin.LoadPlayer then
            SC.Admin.LoadPlayer(targetPly)
        end
    end
end)
:AddParam('player_steamid', 'target')
:AddParam('rank', 'rank')
:AddParam('time', 'exp_time', 'optional')
:AddParam('rank', 'exp_rank', 'optional')
:SetFlag('a')
:SetHelp('Установить ранг игроку')
:SetIcon('icon16/group.png')

cmd.Create("ban", function(ply, args)
    if not args.target or not args.time then
        notify(ply, "Использование: sc ban <ник|SteamID> <длительность> <причина>")
        notify(ply, "Примеры: sc ban Игрок 10mi Нарушение правил | sc ban Игрок 1h Читинг")
        return
    end
    
    local isConsole = not IsValid(ply) or not ply:IsPlayer()
    local adminName = isConsole and "Консоль" or GetPlayerName(ply)
    local adminSteamid = isConsole and "CONSOLE" or (ply:SteamID64() or "")
    
    local targetPly, targetNick, targetSteamID, steamid64 = GetPlayerFromIdentifier(args.target)
    if not targetNick then
        notifyErr(ply, string.format("Игрок '%s' не найден!", tostring(args.target)))
        return
    end
    
    if not steamid64 then
        if type(args.target) == "string" then
            if string.find(args.target, "^STEAM_") then
                steamid64 = util.SteamIDTo64(args.target)
            elseif string.find(args.target, "^7656%d+") then
                steamid64 = args.target
            end
        end
        if not steamid64 then
            notifyErr(ply, "Не удалось получить SteamID64 для бана!")
            return
        end
    end
    
    if IsValid(targetPly) and targetPly:IsPlayer() then
        steamid64 = targetPly:SteamID64()
        targetNick = targetPly:Nick() or "Unknown"
        targetSteamID = targetPly:SteamID() or ""
    end
    
    local duration = tonumber(args.time) or 0
    local reason = args.reason or "Не указана"
    
    if SC.AdminDB and SC.AdminDB.Ban then
        if SC.AdminDB.Ban(steamid64, reason, adminSteamid, duration, targetNick, adminName) then
            local hours = math.floor(duration / 3600)
            local minutes = math.floor((duration % 3600) / 60)
            local durationStr = hours > 0 and string.format("%dч %s", hours, minutes > 0 and minutes .. "м" or "") or (minutes .. "м")
            
            local targetName = FormatPlayerName(targetNick, targetSteamID)
            local staffMsg = string.format("%s забанил %s на %s. Причина: %s.", adminName, targetName, durationStr, reason)
            
            if SC.Admin and SC.Admin.Notify and SC.Admin.Notify.AllStaff then
                SC.Admin.Notify.AllStaff(staffMsg, ply)
            end
            
            if IsValid(targetPly) and targetPly:IsPlayer() then
                timer.Simple(0.1, function()
                    if IsValid(targetPly) then
                        local isBanned, banData = SC.AdminDB.IsBanned and SC.AdminDB.IsBanned(steamid64)
                        if isBanned and banData and SC.AdminDB.FormatBanMessage then
                            targetPly:Kick(SC.AdminDB.FormatBanMessage(banData))
                        else
                            targetPly:Kick(string.format("Вы забанены на %s! Причина: %s", durationStr, reason))
                        end
                    end
                end)
            end
        end
    end
end)
:AddParam('player_steamid', 'target')
:AddParam('time', 'time')
:AddParam('string', 'reason')
:SetFlag('c')
:SetHelp('Забанить игрока')
:SetIcon('icon16/delete.png')

cmd.Create("perma", function(ply, args)
    if not args.target then
        notify(ply, "Использование: sc perma <ник|SteamID> <причина>")
        return
    end
    
    local isConsole = not IsValid(ply) or not ply:IsPlayer()
    local adminName = isConsole and "Консоль" or GetPlayerName(ply)
    local adminSteamid = isConsole and "CONSOLE" or (ply:SteamID64() or "")
    
    local targetPly, targetNick, targetSteamID, steamid64 = GetPlayerFromIdentifier(args.target)
    if not targetNick then
        notifyErr(ply, string.format("Игрок '%s' не найден!", tostring(args.target)))
        return
    end
    
    if not steamid64 then
        if type(args.target) == "string" then
            if string.find(args.target, "^STEAM_") then
                steamid64 = util.SteamIDTo64(args.target)
            elseif string.find(args.target, "^7656%d+") then
                steamid64 = args.target
            end
        end
        if not steamid64 then
            notifyErr(ply, "Не удалось получить SteamID64 для бана!")
            return
        end
    end
    
    if IsValid(targetPly) and targetPly:IsPlayer() then
        steamid64 = targetPly:SteamID64()
        targetNick = targetPly:Nick() or "Unknown"
        targetSteamID = targetPly:SteamID() or ""
    end
    
    local reason = args.reason or "Не указана"
    
    if SC.AdminDB and SC.AdminDB.Ban then
        if SC.AdminDB.Ban(steamid64, reason, adminSteamid, 0, targetNick, adminName) then
            local targetName = FormatPlayerName(targetNick, targetSteamID)
            local staffMsg = string.format("%s перманентно забанил %s. Причина: %s.", adminName, targetName, reason)
            
            if SC.Admin and SC.Admin.Notify and SC.Admin.Notify.AllStaff then
                SC.Admin.Notify.AllStaff(staffMsg, ply)
            end
            
            if IsValid(targetPly) and targetPly:IsPlayer() then
                timer.Simple(0.1, function()
                    if IsValid(targetPly) then
                        local isBanned, banData = SC.AdminDB.IsBanned and SC.AdminDB.IsBanned(steamid64)
                        if isBanned and banData and SC.AdminDB.FormatBanMessage then
                            targetPly:Kick(SC.AdminDB.FormatBanMessage(banData))
                        else
                            targetPly:Kick(string.format("Вы забанены навсегда! Причина: %s", reason))
                        end
                    end
                end)
            end
        end
    end
end)
:AddParam('player_steamid', 'target')
:AddParam('string', 'reason')
:SetFlag('c')
:SetHelp('Пермабан игрока')
:SetIcon('icon16/delete.png')

cmd.Create("kick", function(ply, args)
    if not args.target then
        notify(ply, "Использование: sc kick <ник|SteamID> [причина]")
        return
    end
    
    local isConsole = not ply or not IsValid(ply) or not ply:IsPlayer()
    local adminNick = isConsole and "Консоль" or (ply:Nick() or "Unknown")
    local adminSteamID = isConsole and "" or (ply:SteamID() or "")
    local adminName = adminNick .. (adminSteamID ~= "" and "(" .. adminSteamID .. ")" or "")
    
    local target = args.target
    if not IsValid(target) or not target:IsPlayer() then
        local msg = string.format("Игрок %s не найден.", tostring(args.target))
        notifyErr(ply, msg)
        return
    end
    
    local reason = args.reason or "Администратор"
    local targetNick = target:Nick() or "Unknown"
    local targetSteamID = target:SteamID() or ""
    
    if targetSteamID == "" and target:IsBot() then
        targetSteamID = "BOT"
    end
    
    local targetName = FormatPlayerName(targetNick, targetSteamID)
    
    local msg = string.format("%s кикнул %s. Причина: %s.", adminName, targetName, reason)
    
    if SC.Admin and SC.Admin.Notify and SC.Admin.Notify.AllStaff then
        SC.Admin.Notify.AllStaff(msg, ply)
    end
    
    target:Kick("Вас кикнули. Причина: " .. reason)
end)
:AddParam('player_entity', 'target')
:AddParam('string', 'reason', 'optional')
:SetFlag('d')
:SetHelp('Кикнуть игрока')
:SetIcon('icon16/user_delete.png')

cmd.Create("setmoney", function(ply, args)
    if not args.target or not args.amount then
        notify(ply, "Использование: sc setmoney <ник|SteamID> <количество>")
        return
    end
    
    local isConsole = not ply or not IsValid(ply) or not ply:IsPlayer()
    local adminNick = isConsole and "Консоль" or (ply:Nick() or "Unknown")
    local adminSteamID = isConsole and "" or (ply:SteamID() or "")
    local adminName = adminNick .. (adminSteamID ~= "" and "(" .. adminSteamID .. ")" or "")
    
    local target = args.target
    if not IsValid(target) or not target:IsPlayer() then
        local msg = string.format("Игрок %s не найден.", tostring(args.target))
        notifyErr(ply, msg)
        return
    end
    
    local amount = args.amount
    if not amount or amount < 0 then
        notifyErr(ply, "Неверное количество денег!")
        return
    end
    
    if target.SetMoney then
        target:SetMoney(amount)
        
        local targetNick = target:Nick() or "Unknown"
        local targetSteamID = target:SteamID() or ""
        local targetName = FormatPlayerName(targetNick, targetSteamID)
        
        local msg = string.format("%s установил %s деньги на $%s.", adminName, targetName, tostring(amount))
        
        if SC.Admin and SC.Admin.Notify and SC.Admin.Notify.AllStaff then
            SC.Admin.Notify.AllStaff(msg, ply)
        end
        
        local msgYou = string.format("%s установил ваши деньги на $%s.", adminName, tostring(amount))
        notify(target, msgYou)
    end
end)
:AddParam('player_entity', 'target')
:AddParam('number', 'amount')
:SetFlag('e')
:SetHelp('Установить деньги игроку')
:SetIcon('icon16/money.png')

cmd.Create("sethunger", function(ply, args)
    if not args.target or not args.amount then
        notify(ply, "Использование: sc sethunger <ник|SteamID> <количество>")
        return
    end
    
    local isConsole = not ply or not IsValid(ply) or not ply:IsPlayer()
    local adminNick = isConsole and "Консоль" or (ply:Nick() or "Unknown")
    local adminSteamID = isConsole and "" or (ply:SteamID() or "")
    local adminName = adminNick .. (adminSteamID ~= "" and "(" .. adminSteamID .. ")" or "")
    
    local target = args.target
    if not IsValid(target) or not target:IsPlayer() then
        local msg = string.format("Игрок %s не найден.", tostring(args.target))
        notifyErr(ply, msg)
        return
    end
    
    local amount = args.amount
    if not amount or amount < 0 then
        notifyErr(ply, "Неверное количество голода!")
        return
    end
    
    if target.SetHunger then
        target:SetHunger(amount)
        
        local targetNick = target:Nick() or "Unknown"
        local targetSteamID = target:SteamID() or ""
        local targetName = FormatPlayerName(targetNick, targetSteamID)
        
        local msg = string.format("%s установил %s голод на %s.", adminName, targetName, tostring(amount))
        
        if SC.Admin and SC.Admin.Notify and SC.Admin.Notify.AllStaff then
            SC.Admin.Notify.AllStaff(msg, ply)
        end
        
        local msgYou = string.format("%s установил ваш голод на %s.", adminName, tostring(amount))
        notify(target, msgYou)
    end
end)
:AddParam('player_entity', 'target')
:AddParam('number', 'amount')
:SetFlag('e')
:SetHelp('Установить голод игроку')
:SetIcon('icon16/cake.png')

cmd.Create("sethealth", function(ply, args)
    if not args.target or not args.amount then
        notify(ply, "Использование: sc sethealth <ник|SteamID> <количество>")
        return
    end
    
    local isConsole = not ply or not IsValid(ply) or not ply:IsPlayer()
    local adminNick = isConsole and "Консоль" or (ply:Nick() or "Unknown")
    local adminSteamID = isConsole and "" or (ply:SteamID() or "")
    local adminName = adminNick .. (adminSteamID ~= "" and "(" .. adminSteamID .. ")" or "")
    
    local target = args.target
    if not IsValid(target) or not target:IsPlayer() then
        local msg = string.format("Игрок %s не найден.", tostring(args.target))
        notifyErr(ply, msg)
        return
    end
    
    local amount = args.amount
    if not amount or amount < 1 or amount > 1000 then
        notifyErr(ply, "Неверное количество здоровья! (1-1000)")
        return
    end
    
    target:SetHealth(amount)
    
    local targetNick = target:Nick() or "Unknown"
    local targetSteamID = target:SteamID() or ""
    
    if targetSteamID == "" and target:IsBot() then
        targetSteamID = "BOT"
    end
    
    local targetName = FormatPlayerName(targetNick, targetSteamID)
    
    local msg = string.format("%s установил %s здоровье на %s.", adminName, targetName, tostring(amount))
    
    if SC.Admin and SC.Admin.Notify and SC.Admin.Notify.AllStaff then
        SC.Admin.Notify.AllStaff(msg, ply)
    end
    
    local msgYou = string.format("%s установил ваше здоровье на %s.", adminName, tostring(amount))
    notify(target, msgYou)
end)
:AddParam('player_entity', 'target')
:AddParam('number', 'amount')
:SetFlag('e')
:SetHelp('Установить здоровье игроку')
:SetIcon('icon16/heart.png')
:AddAlias('sethp')

cmd.Create("setarmor", function(ply, args)
    if not args.target or not args.amount then
        notify(ply, "Использование: sc setarmor <ник|SteamID> <количество>")
        return
    end
    
    local isConsole = not ply or not IsValid(ply) or not ply:IsPlayer()
    local adminNick = isConsole and "Консоль" or (ply:Nick() or "Unknown")
    local adminSteamID = isConsole and "" or (ply:SteamID() or "")
    local adminName = adminNick .. (adminSteamID ~= "" and "(" .. adminSteamID .. ")" or "")
    
    local target = args.target
    if not IsValid(target) or not target:IsPlayer() then
        local msg = string.format("Игрок %s не найден.", tostring(args.target))
        notifyErr(ply, msg)
        return
    end
    
    local amount = args.amount
    if not amount or amount < 0 or amount > 1000 then
        notifyErr(ply, "Неверное количество брони! (0-1000)")
        return
    end
    
    target:SetArmor(amount)
    
    local targetNick = target:Nick() or "Unknown"
    local targetSteamID = target:SteamID() or ""
    
    if targetSteamID == "" and target:IsBot() then
        targetSteamID = "BOT"
    end
    
    local targetName = FormatPlayerName(targetNick, targetSteamID)
    
    local msg = string.format("%s установил %s броню на %s.", adminName, targetName, tostring(amount))
    
    if SC.Admin and SC.Admin.Notify and SC.Admin.Notify.AllStaff then
        SC.Admin.Notify.AllStaff(msg, ply)
    end
    
    local msgYou = string.format("%s установил вашу броню на %s.", adminName, tostring(amount))
    notify(target, msgYou)
end)
:AddParam('player_entity', 'target')
:AddParam('number', 'amount')
:SetFlag('e')
:SetHelp('Установить броню игроку')
:SetIcon('icon16/shield.png')

cmd.Create("info", function(ply, args)
    if not args.target then
        notify(ply, "Использование: sc info <ник|SteamID>")
        return
    end
    
    local target = args.target
    if not IsValid(target) or not target:IsPlayer() then
        notifyErr(ply, "Игрок не найден!")
        return
    end
    
    notify(ply, "=== Информация о игроке ===")
    notify(ply, "Ник: " .. (target:Nick() or "Unknown"))
    notify(ply, "SteamID: " .. (target:SteamID() or "Unknown"))
    notify(ply, "Здоровье: " .. target:Health() .. " / " .. target:GetMaxHealth())
    notify(ply, "Броня: " .. target:Armor())
    
    if target.GetMoney then
        notify(ply, "Деньги: $" .. target:GetMoney())
    end
    
    if target.GetHunger then
        notify(ply, "Голод: " .. (target:GetHungerPercent() or 100) .. "%")
    end
    
    local fractionName = target.GetFraction and target:GetFraction() or "Не установлена"
    notify(ply, "Фракция: " .. fractionName)
    
    local rank = SC.Admin and SC.Admin.GetRank(target) or "user"
    local flags = SC.Admin and SC.Admin.GetFlags(target) or ""
    notify(ply, "Ранг: " .. rank)
    if flags and flags ~= "" then
        notify(ply, "Флаги: " .. flags)
    end
    if target.GetLevel then
        local lvl = target:GetLevel()
        local exp = target:GetExp()
        local mExp = target:GetMaxExp()
        notify(ply, "Уровень: " .. lvl)
        notify(ply, "Опыт: " .. exp .. " / " .. mExp)
    end
    notify(ply, "Пинг: " .. target:Ping() .. "ms")
    notify(ply, "============================")
end)
:AddParam('player_entity', 'target')
:SetFlag('f')
:SetHelp('Информация о игроке')
:SetIcon('icon16/information.png')

cmd.Create("setfraction", function(ply, args)
    if not args.target or not args.fraction then
        notify(ply, "Использование: sc setfraction <ник|SteamID> <фракция>")
        return
    end
    
    local isConsole = not ply or not IsValid(ply) or not ply:IsPlayer()
    local adminNick = isConsole and "Консоль" or (ply:Nick() or "Unknown")
    local adminSteamID = isConsole and "" or (ply:SteamID() or "")
    local adminName = adminNick .. (adminSteamID ~= "" and "(" .. adminSteamID .. ")" or "")
    
    local target = args.target
    if not IsValid(target) or not target:IsPlayer() then
        local msg = string.format("Игрок %s не найден.", tostring(args.target))
        notifyErr(ply, msg)
        return
    end
    
    local fractionName = args.fraction
    local targetNick = target:Nick() or "Unknown"
    local targetSteamID = target:SteamID() or ""
    
    if targetSteamID == "" and target:IsBot() then
        targetSteamID = "BOT"
    end
    
    local targetName = FormatPlayerName(targetNick, targetSteamID)
    
    if SC.FSetPly then
        SC.FSetPly(target, fractionName)
        
        local msg = string.format("%s заставил работать %s за %s.", adminName, targetName, fractionName)
        
        if SC.Admin and SC.Admin.Notify and SC.Admin.Notify.AllStaff then
            SC.Admin.Notify.AllStaff(msg, ply)
        end
        
        local msgYou = string.format("%s переместил вас за %s.", adminName, fractionName)
        notify(target, msgYou)
        
        if target:Alive() then
            target:KillSilent()
        end
    else
        notifyErr(ply, "Система фракций не загружена!")
    end
end)
:AddParam('player_entity', 'target')
:AddParam('fraction', 'fraction')
:SetFlag('g')
:SetHelp('Установить фракцию игроку')
:SetIcon('icon16/group_edit.png')
:AddAlias('setfrac')

cmd.Create("testflags", function(ply, args)
    local target = args.target or ply
    
    if not IsValid(target) or not target:IsPlayer() then
        notifyErr(ply, "Игрок не найден!")
        return
    end
    
    local rank = SC.Admin and SC.Admin.GetRank(target) or "unknown"
    local flags = SC.Admin and SC.Admin.GetFlags(target) or ""
    local steamid = target:SteamID64()
    local data = SC.Admin and SC.Admin.PlayerData and SC.Admin.PlayerData[steamid]
    
    notify(ply, "=== Debug Info: " .. target:Nick() .. " ===")
    notify(ply, "Rank: " .. rank)
    notify(ply, "Flags: '" .. flags .. "'")
    notify(ply, "SteamID64: " .. (steamid or "none") .. '      |     ' .. "SteamID: " .. (target:SteamID() or "none"))
    if data then
        notify(ply, "Data.rank: " .. (data.rank or "nil"))
        notify(ply, "Data.flags: '" .. (data.flags or "") .. "'")
    else
        notify(ply, "PlayerData not found!")
    end
    
    local rankData = SC.AdminRanks and SC.AdminRanks.Get(rank)
    if rankData then
        notify(ply, "RankData.Flags: '" .. (rankData.Flags or "") .. "'")
    else
        notify(ply, "RankData not found for rank: " .. rank)
    end
    
    local hasFlag = SC.Admin and SC.Admin.HasAnyFlag and SC.Admin.HasAnyFlag(target, "a") or false
    notify(ply, "HasAnyFlag('a'): " .. tostring(hasFlag))
    notify(ply, "==================")
end)
:AddParam('player_entity', 'target', 'optional')
:SetFlag('')
:SetHelp('Тест флагов (для отладки)')

cmd.Create("help", function(ply, args)
    local cmdTable = SC.AdminCommands
    if not cmdTable or not cmdTable.GetTable then
        notifyErr(ply, "Система команд не загружена!")
        return
    end
    
    local allCommands = cmdTable.GetTable()
    local commandList = {}
    
    for cmdName, cmdObj in pairs(allCommands) do
        if cmdObj and cmdObj.GetName and cmdObj.GetHelp then
            local help = cmdObj:GetHelp()
            if help and help ~= "" then
                local cmdNameCheck = cmdObj:GetName()
                if cmdNameCheck == cmdName then
                    table.insert(commandList, {
                        name = cmdName,
                        help = help,
                        flag = cmdObj:GetFlag() or ""
                    })
                end
            end
        end
    end
    
    table.sort(commandList, function(a, b) return a.name < b.name end)
    
    notify(ply, "=== Доступные команды ===")
    for _, cmdData in ipairs(commandList) do
        local flagStr = cmdData.flag ~= "" and (" [флаг: " .. cmdData.flag .. "]") or ""
        notify(ply, "  sc " .. cmdData.name .. flagStr .. " - " .. cmdData.help)
    end
    notify(ply, "========================")
end)
:SetFlag('')
:SetHelp('Показать список всех команд')
:SetIcon('icon16/help.png')

cmd.Create("setlvl", function(ply, args)
    if not args.target or not args.amount then
        notify(ply, "Использование: sc setlvl <ник|SteamID> <уровень>")
        return
    end
    
    local isConsole = not ply or not IsValid(ply) or not ply:IsPlayer()
    local adminName = isConsole and "Консоль" or GetPlayerName(ply)
    
    local target = args.target
    if not IsValid(target) or not target:IsPlayer() then
        notifyErr(ply, string.format("Игрок %s не найден.", tostring(args.target)))
        return
    end
    
    local amount = math.max(1, math.floor(args.amount))
    
    target:SetNW2Int("sc_level", amount)
    target:SetNW2Int("sc_exp", 0)
    
    if target.SaveLvl then target:SaveLvl() end

    local targetName = FormatPlayerName(target:Nick(), target:SteamID())
    local msg = string.format("%s установил уровень %s на %d.", adminName, targetName, amount)
    
    if SC.Admin and SC.Admin.Notify and SC.Admin.Notify.AllStaff then
        SC.Admin.Notify.AllStaff(msg, ply)
    end
    
    notify(target, string.format("%s установил ваш уровень на %d.", adminName, amount))
end)
:AddParam('player_entity', 'target')
:AddParam('number', 'amount')
:SetFlag('e')
:SetHelp('Установить уровень игроку')
:SetIcon('icon16/star.png')
:AddAlias('setlevel')

cmd.Create("addexp", function(ply, args)
    if not args.target or not args.amount then
        notify(ply, "Использование: sc addexp <ник|SteamID> <количество>")
        return
    end
    
    local isConsole = not ply or not IsValid(ply) or not ply:IsPlayer()
    local adminName = isConsole and "Консоль" or GetPlayerName(ply)
    
    local target = args.target
    if not IsValid(target) or not target:IsPlayer() then
        notifyErr(ply, string.format("Игрок %s не найден.", tostring(args.target)))
        return
    end
    
    local amount = math.floor(args.amount)
    if amount == 0 then return end

    if target.AddExp then
        target:AddExp(amount)
        local targetName = FormatPlayerName(target:Nick(), target:SteamID())
        local action = amount > 0 and "добавил" or "забрал"
        local msg = string.format("%s %s %d опыта игроку %s.", adminName, action, math.abs(amount), targetName)
        
        if SC.Admin and SC.Admin.Notify and SC.Admin.Notify.AllStaff then
            SC.Admin.Notify.AllStaff(msg, ply)
        end
        
        notify(target, string.format("%s %s вам %d опыта.", adminName, action, math.abs(amount)))
    else
        notifyErr(ply, "Система уровней (AddExp) не загружена!")
    end
end)
:AddParam('player_entity', 'target')
:AddParam('number', 'amount')
:SetFlag('e')
:SetHelp('Добавить опыт игроку')
:SetIcon('icon16/lightning.png')
cmd.Create("bots", function(ply, args)
	if ply:IsRoot() then
    	for i = 1, tonumber(args.amount) do
			RunConsoleCommand('bot')
		end
    end
end)
:AddParam('number', 'amount')
:SetFlag('e')
:SetHelp('добалвяет ботов')
:SetIcon('icon16/lightning.png')