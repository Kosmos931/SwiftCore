if not SERVER then return end

if not SC.AdminCommands or not SC.AdminCommands.Run then
    ErrorNoHalt("[SC.AdminCommands] Система команд не загружена!\n")
    return
end

local cmd = SC.AdminCommands

local commandRateLimit = {}
local COMMAND_RATE_LIMIT = 10
local COMMAND_RATE_WINDOW = 1

local function CleanupRateLimit(steamid)
    if not steamid then return end
    commandRateLimit[steamid] = nil
end

hook.Add("PlayerDisconnected", "SC.AdminCommands.CleanupRateLimit", function(ply)
    if IsValid(ply) and ply:IsPlayer() then
        local steamid = ply:SteamID64()
        if steamid then
            CleanupRateLimit(steamid)
        end
    end
end)

local function CheckRateLimit(ply)
    local isConsole = not ply or not IsValid(ply) or not ply:IsPlayer()
    if isConsole then return true end
    
    local steamid = ply:SteamID64()
    if not steamid then return true end
    
    local currentTime = CurTime()
    local rateData = commandRateLimit[steamid]
    
    if not rateData then
        rateData = {times = {}}
        commandRateLimit[steamid] = rateData
    end
    
    local cutoffTime = currentTime - COMMAND_RATE_WINDOW
    for i = #rateData.times, 1, -1 do
        if rateData.times[i] < cutoffTime then
            table.remove(rateData.times, i)
        end
    end
    
    if #rateData.times >= COMMAND_RATE_LIMIT then
        return false
    end
    
    table.insert(rateData.times, currentTime)
    return true
end

local function RunAdminCommand(ply, cmdName, args, cmdPrefix)
    local isConsole = not ply or not IsValid(ply) or not ply:IsPlayer()
    if not isConsole then
        if not CheckRateLimit(ply) then
            if SC.Admin and SC.Admin.Notify then
                SC.Admin.Notify.Error(ply, "Пожалуйста, подождите перед использованием следующей команды.")
            elseif IsValid(ply) and ply:IsPlayer() then
                ply:ChatPrint("Слишком много команд! Подождите немного.")
            end
            return
        end
    end
    cmdPrefix = cmdPrefix or "sc"
    if not args or #args == 0 then
        if SC.Admin and SC.Admin.Notify then
            SC.Admin.Notify.Send(ply, "Использование: " .. cmdPrefix .. " <команда> [аргументы]")
        elseif IsValid(ply) and ply:IsPlayer() then
            ply:ChatPrint("Использование: " .. cmdPrefix .. " <команда> [аргументы]")
        else
            print("[SC] Использование: " .. cmdPrefix .. " <команда> [аргументы]")
        end
        return
    end
    
    local commandName = string.lower(args[1] or "")
    if commandName == "" then return end
    
    table.remove(args, 1)
    
    if args and #args > 0 then
        local newArgs = {}
        local i = 1
        while i <= #args do
            local arg = tostring(args[i] or "")
            if string.upper(string.sub(arg, 1, 6)) == "STEAM_" then
                local steamid = arg
                i = i + 1
                while i <= #args do
                    local nextArg = tostring(args[i] or "")
                    if string.match(nextArg, "^%d+$") then
                        steamid = steamid .. ":" .. nextArg
                        i = i + 1
                    elseif string.match(nextArg, "^%d+:%d+$") then
                        steamid = steamid .. ":" .. nextArg
                        i = i + 1
                    else
                        break
                    end
                end
                steamid = string.gsub(steamid, ":+", ":")
                table.insert(newArgs, steamid)
            elseif string.find(arg, "^7656%d+") then
                table.insert(newArgs, arg)
                i = i + 1
            else
                table.insert(newArgs, arg)
                i = i + 1
            end
        end
        args = newArgs
    end
    
    cmd.Run(ply, commandName, args or {})
end

local function AutoCompleteSc(cmdName, arguments)
    cmdName = cmdName or "sc"
    arguments = arguments or ""
    
    if not SC.AdminCommands or not SC.AdminCommands.GetTable then
        return {}
    end
    
    local commandList = {}
    local allCommands = SC.AdminCommands.GetTable()
    
    local parts = string.Explode(" ", arguments)
    local len = #parts
    
    local cleanParts = {}
    for _, part in ipairs(parts) do
        part = string.gsub(string.gsub(part, "^%s+", ""), "%s+$", "")
        if part ~= "" then
            table.insert(cleanParts, part)
        end
    end
    len = #cleanParts
    
    for cmdNameKey, cmdObj in pairs(allCommands) do
        if cmdObj and cmdObj.GetName then
            local cmdNameLower = string.lower(cmdNameKey)
            if len == 0 then
                table.insert(commandList, cmdName .. " " .. cmdNameKey)
            elseif len >= 1 and cleanParts[1] then
                local commandPart = string.lower(cleanParts[1] or "")
                if string.find(cmdNameLower, "^" .. commandPart) then
                    table.insert(commandList, cmdName .. " " .. cmdNameKey)
                end
            end
        end
    end
    
    table.sort(commandList)
    return (#commandList > 0) and commandList or {}
end

concommand.Add("_sc", function(ply, cmdName, args)
    RunAdminCommand(ply, cmdName, args, "sc")
end)

concommand.Add("sc", function(ply, cmdName, args)
    RunAdminCommand(ply, cmdName, args, "sc")
end, AutoCompleteSc)



util.AddNetworkString("SC.AdminCommands.Sync")

local function SyncCommandNamesToClient(ply)
    if not SC.AdminCommands or not SC.AdminCommands.GetTable then
        return
    end
    
    local allCommands = SC.AdminCommands.GetTable()
    local commandData = {}
    
    for cmdNameKey, cmdObj in pairs(allCommands) do
        if cmdObj and cmdObj.GetName and cmdObj.GetArgs then
            local args = cmdObj:GetArgs()
            local firstArgType = nil
            if args and #args > 0 and args[1] then
                firstArgType = args[1].Param or nil
            end
            commandData[cmdNameKey] = {
                name = cmdNameKey,
                firstArgType = firstArgType
            }
        end
    end
    
    if IsValid(ply) and ply:IsPlayer() then
        local cmdCount = 0
        for _ in pairs(commandData) do
            cmdCount = cmdCount + 1
        end
        
        if cmdCount > 256 then
            ErrorNoHalt("[SC.AdminCommands] Слишком много команд для синхронизации: " .. cmdCount .. "\n")
            return
        end
        
        net.Start("SC.AdminCommands.Sync")
        net.WriteTable(commandData)
        if net.BytesWritten() > 32768 then
            ErrorNoHalt("[SC.AdminCommands] Отправка слишком большого пакета: " .. net.BytesWritten() .. "\n")
            net.Abort()
            return
        end
        net.Send(ply)
    end
end

hook.Add("PlayerInitialSpawn", "SC.AdminCommands.Sync", function(ply)
    timer.Simple(1, function()
        if IsValid(ply) and ply:IsPlayer() then
            SyncCommandNamesToClient(ply)
        end
    end)
end)

hook.Add("InitPostEntity", "SC.AdminCommands.SyncAll", function()
    timer.Simple(2, function()
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and ply:IsPlayer() then
                SyncCommandNamesToClient(ply)
            end
        end
    end)
end)
