if not CLIENT then return end

if not SC.AdminCommands then
    SC.AdminCommands = {}
end

local cmd = SC.AdminCommands

cmd.CommandData = cmd.CommandData or {}

local function GetPlayerAutocomplete(arg)
    arg = arg or ""
    arg = string.lower(arg)
    local ret = {}
    
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:IsPlayer() then
            local name = ply:Nick() or ""
            local nameLower = string.lower(name)
            
            if arg == "" or string.find(nameLower, "^" .. arg) then
                table.insert(ret, name)
            end
        end
    end
    
    return ret
end

local function IsSteamID(str)
    if not str then return false end
    str = tostring(str)
    return string.find(str, "^STEAM_[%d:]+") ~= nil or string.find(str, "^7656%d+") ~= nil
end

local function ConcatArgs(args, endPos)
    local str = ""
    for i = 1, endPos do
        if i > 1 then str = str .. " " end
        str = str .. (args[i] or "")
    end
    return str
end

local function AutoCompleteSc(cmdName, arguments)
    cmdName = cmdName or "sc"
    arguments = arguments or ""
    
    local commandList = {}
    local allCommands = cmd.CommandData or {}
    
    local parts = string.Explode(" ", arguments)
    local cleanParts = {}
    for _, part in ipairs(parts) do
        if part ~= "" then
            table.insert(cleanParts, part)
        end
    end
    local len = #cleanParts
    
    local endsWithSpace = (#arguments > 0 and string.sub(arguments, #arguments, #arguments) == " ")
    
    if len == 0 then
        for cmdKey, cmdData in pairs(allCommands) do
            if cmdData and cmdData.name then
                table.insert(commandList, cmdName .. " " .. cmdData.name)
            end
        end
    elseif len == 1 and not endsWithSpace then
        local commandPart = string.lower(cleanParts[1] or "")
        for cmdKey, cmdData in pairs(allCommands) do
            if cmdData and cmdData.name then
                local cmdNameLower = string.lower(cmdData.name)
                if commandPart == "" or string.find(cmdNameLower, "^" .. commandPart) then
                    table.insert(commandList, cmdName .. " " .. cmdData.name)
                end
            end
        end
    else
        local commandName = string.lower(cleanParts[1] or "")
        local cmdData = nil
        
        for cmdKey, data in pairs(allCommands) do
            if data and data.name and string.lower(data.name) == commandName then
                cmdData = data
                break
            end
        end
        
        if cmdData and cmdData.firstArgType then
            if endsWithSpace or len >= 2 then
                if cmdData.firstArgType == "player_entity" or cmdData.firstArgType == "player_steamid" then
                    local argPart = (len >= 2 and cleanParts[2]) or ""
                    if not IsSteamID(argPart) then
                        local players = GetPlayerAutocomplete(argPart)
                        local prefix = cmdName .. " " .. cmdData.name .. " "
                        for _, playerName in ipairs(players) do
                            table.insert(commandList, prefix .. playerName)
                        end
                    else
                        table.insert(commandList, cmdName .. " " .. cmdData.name .. " " .. argPart)
                    end
                end
            end
        end
    end
    
    table.sort(commandList)
    return (#commandList > 0) and commandList or {}
end

local function RunAdminCommandClient(ply, cmdName, args)
    if args and #args > 0 then
        local fullCommand = "_sc " .. table.concat(args, " ")
        LocalPlayer():ConCommand(fullCommand)
    else
        LocalPlayer():ConCommand("_sc")
    end
end

concommand.Add("sc", RunAdminCommandClient, AutoCompleteSc)


net.Receive("SC.AdminCommands.Sync", function(len)
    if len > 32768 then
        ErrorNoHalt("[SC.AdminCommands] Пакет слишком большой: " .. len .. " байт\n")
        return
    end
    
    local commandData = net.ReadTable()
    if type(commandData) == "table" then
        cmd.CommandData = commandData
    end
end)
