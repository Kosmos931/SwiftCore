if not SERVER then return end

SC.AdminChat = SC.AdminChat or {}
local chat = SC.AdminChat

local chatCommandRateLimit = {}
local CHAT_COMMAND_RATE_LIMIT = 5
local CHAT_COMMAND_RATE_WINDOW = 1

hook.Add("PlayerDisconnected", "SC.AdminChat.CleanupRateLimit", function(ply)
    if IsValid(ply) and ply:IsPlayer() then
        local steamid = ply:SteamID64()
        if steamid then
            chatCommandRateLimit[steamid] = nil
        end
    end
end)

local function CheckChatRateLimit(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return true end
    
    local steamid = ply:SteamID64()
    if not steamid then return true end
    
    local currentTime = CurTime()
    local rateData = chatCommandRateLimit[steamid]
    
    if not rateData then
        rateData = {times = {}}
        chatCommandRateLimit[steamid] = rateData
    end
    
    local cutoffTime = currentTime - CHAT_COMMAND_RATE_WINDOW
    for i = #rateData.times, 1, -1 do
        if rateData.times[i] < cutoffTime then
            table.remove(rateData.times, i)
        end
    end
    
    if #rateData.times >= CHAT_COMMAND_RATE_LIMIT then
        return false
    end
    
    table.insert(rateData.times, currentTime)
    return true
end

local function OnPlayerChat(ply, text, teamChat, dead)
    if not IsValid(ply) or not ply:IsPlayer() then return "" end
    if not text or text == "" then return "" end
    
    text = string.gsub(string.gsub(text, "^%s+", ""), "%s+$", "")
    local firstChar = string.sub(text, 1, 1)
    
    if firstChar ~= "/" and firstChar ~= "!" then
        return
    end
    
    text = string.sub(text, 2)
    if text == "" then return "" end
    
    local args = {}
    local current = ""
    local inQuotes = false
    
    for i = 1, #text do
        local char = string.sub(text, i, i)
        
        if char == '"' then
            inQuotes = not inQuotes
        elseif char == ' ' and not inQuotes then
            if current ~= "" then
                table.insert(args, current)
                current = ""
            end
        else
            current = current .. char
        end
    end
    
    if current ~= "" then
        table.insert(args, current)
    end
    
    if #args == 0 then return "" end
    
    local commandName = string.lower(args[1])
    if commandName == "" then return "" end
    
    if not CheckChatRateLimit(ply) then
        if SC.Admin and SC.Admin.Notify then
            SC.Admin.Notify.Error(ply, "Пожалуйста, подождите перед использованием следующей команды в чате.")
        else
            ply:ChatPrint("Слишком много команд! Подождите немного.")
        end
        return ""
    end
    
    table.remove(args, 1)
    
    if SC.AdminCommands and SC.AdminCommands.Run then
        SC.AdminCommands.Run(ply, commandName, args)
    end
    
    return ""
end

hook.Add("PlayerSay", "SC.AdminChat.Process", OnPlayerChat)
