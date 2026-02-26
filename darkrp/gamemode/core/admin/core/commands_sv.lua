if not SERVER then return end

SC.AdminCommands = SC.AdminCommands or {}
local cmd = SC.AdminCommands

cmd.Stored = cmd.Stored or {}
cmd.Params = cmd.Params or {}

local cmd_mt = {}
cmd_mt.__index = cmd_mt

function cmd.Create(name, callback)
    local c = {
        Name = name:lower():gsub(' ', ''),
        NiceName = name,
        Args = {},
        Flag = 'a',
        Icon = 'icon16/group.png',
        Help = '',
        Callback = callback or function() end
    }
    setmetatable(c, cmd_mt)
    cmd.Stored[c.Name] = c
    return c
end

function cmd.Get(name)
    return cmd.Stored[name:lower()]
end

function cmd.Exists(name)
    return (cmd.Stored[name:lower()] ~= nil)
end

function cmd.GetTable()
    return cmd.Stored
end

function cmd_mt:AddArg(param, key, flag)
    self.Args[#self.Args + 1] = {
        Param = param,
        Key = key,
        Flag = flag or 'required'
    }
    return self
end

cmd_mt.AddParam = cmd_mt.AddArg

function cmd_mt:SetFlag(flag)
    self.Flag = flag or 'a'
    return self
end

function cmd_mt:SetHelp(help)
    self.Help = help or ''
    return self
end

function cmd_mt:SetIcon(icon)
    self.Icon = icon or 'icon16/group.png'
    return self
end

function cmd_mt:AddAlias(alias)
    cmd.Stored[alias:lower()] = self
    return self
end

function cmd_mt:GetName()
    return self.Name
end

function cmd_mt:GetNiceName()
    return self.NiceName
end

function cmd_mt:GetArgs()
    return self.Args
end

function cmd_mt:GetFlag()
    return self.Flag
end

function cmd_mt:GetHelp()
    return self.Help
end

function cmd_mt:GetIcon()
    return self.Icon
end

function cmd_mt:Init(ply, args)
    if SERVER then
        return self.Callback(ply, args)
    end
end

local parser_mt = {}
parser_mt.__index = parser_mt

function cmd.Param(name)
    name = name:lower()
    if cmd.Params[name] then
        return cmd.Params[name]
    else
        local p = {
            Name = name
        }
        setmetatable(p, parser_mt)
        cmd.Params[p.Name] = p
        return p
    end
end

function parser_mt:Parse(callback)
    if SERVER then
        self.ParseFunc = callback
    end
    return self
end

local function TrimString(str)
    if not str then return "" end
    str = tostring(str)
    return string.gsub(string.gsub(str, "^%s+", ""), "%s+$", "")
end

function cmd.FindPlayer(identifier)
    if not identifier then return nil end
    
    identifier = tostring(identifier)
    identifier = TrimString(identifier)
    
    if string.find(identifier, "^STEAM_[%d:]+") or string.find(identifier, "^7656%d+") then
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and ply:IsPlayer() then
                if ply:SteamID() == identifier or tostring(ply:SteamID64()) == identifier then
                    return ply
                end
            end
        end
        return identifier
    else
        identifier = string.lower(identifier)
        local found = {}
        local exactMatch = nil
        
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and ply:IsPlayer() then
                local name = string.lower(TrimString(ply:Nick() or ""))
                if name == identifier then
                    exactMatch = ply
                elseif string.find(name, identifier, 1, true) then
                    table.insert(found, ply)
                end
            end
        end
        
        if exactMatch then
            return exactMatch
        elseif #found == 1 then
            return found[1]
        elseif #found > 1 then
            return nil
        end
        
        return nil
    end
end

function cmd.Parse(ply, cmdName, args)
    args = args or {}
    local cmdObj = cmd.Get(cmdName)
    if not cmdObj then return false, "Команда не найдена" end
    
    local parsed = {}
    parsed.raw = {}
    
    local argIndex = 1
    for k, v in ipairs(cmdObj:GetArgs()) do
        if (not args[argIndex] or args[argIndex] == "") and v.Flag ~= 'optional' then
            return false, "Недостаточно аргументов! Требуется: " .. v.Key
        elseif (not args[argIndex] or args[argIndex] == "") and v.Flag == 'optional' then
            parsed[v.Key] = nil
            parsed.raw[v.Key] = nil
        else
            local param = cmd.Param(v.Param)
            if param.ParseFunc then
                local success, result = param.ParseFunc(param, ply, cmdName, args[argIndex] or "", {Key = v.Key, Pos = argIndex, Args = args})
                if not success then
                    return false, result or "Ошибка парсинга аргумента: " .. v.Key
                end
                parsed[v.Key] = result
                parsed.raw[v.Key] = args[argIndex]
                argIndex = argIndex + 1
            else
                parsed[v.Key] = args[argIndex]
                parsed.raw[v.Key] = args[argIndex]
                argIndex = argIndex + 1
            end
        end
    end
    
    return true, parsed
end

function cmd.Run(ply, cmdName, args)
    args = args or {}
    
    if not cmd.Exists(cmdName) then
        local msg = "# такой команды не существует!"
        msg = string.gsub(msg, "#", cmdName)
        if SC.Admin and SC.Admin.Notify then
            SC.Admin.Notify.Error(ply, msg)
        elseif IsValid(ply) and ply:IsPlayer() then
            ply:ChatPrint(msg)
        else
            print("[SC] " .. msg)
        end
        return
    end
    
    local cmdObj = cmd.Get(cmdName)
    local flag = cmdObj:GetFlag()
    
    local isConsole = not ply or not IsValid(ply) or not ply:IsPlayer()
    
    if not isConsole then
        if not SC.Admin then
            ply:ChatPrint("Система администрирования не загружена!")
            return
        end
        
        if flag and flag ~= "" then
            if not SC.Admin.HasAnyFlag or not SC.Admin.HasAnyFlag(ply, flag) then
                local playerFlags = SC.Admin.GetFlags and SC.Admin.GetFlags(ply) or ""
                local msg = 'Вам нужен флаг "#" чтобы использовать #'
                msg = string.gsub(msg, "#", flag, 1)
                msg = string.gsub(msg, "#", cmdName)
                if SC.Admin.Notify then
                    SC.Admin.Notify.Error(ply, msg)
                else
                    ply:ChatPrint(msg)
                end
                return
            end
        end
    end
    
    local success, parsed = cmd.Parse(ply, cmdName, args)
    if not success then
        if SC.Admin and SC.Admin.Notify then
            SC.Admin.Notify.Error(ply, parsed or "Ошибка парсинга команды")
        elseif IsValid(ply) and ply:IsPlayer() then
            ply:ChatPrint(parsed or "Ошибка парсинга команды")
        else
            print("[SC] " .. (parsed or "Ошибка парсинга команды"))
        end
        return
    end
    
    cmdObj:Init(ply, parsed)
end

cmd.Param('player_entity')
    :Parse(function(self, ply, cmdName, arg, opts)
        local cmdTable = SC.AdminCommands
        local result = cmdTable and cmdTable.FindPlayer and cmdTable.FindPlayer(arg) or nil
        if not result then
            return false, "Игрок '" .. (arg or "не указан") .. "' не найден!"
        end
        
        if IsValid(result) and result:IsPlayer() then
            local isConsole = not ply or not IsValid(ply) or not ply:IsPlayer()
            if not isConsole then
                local adminRanks = SC.AdminRanks
                if adminRanks and adminRanks.CanTarget then
                    if not adminRanks.CanTarget(ply, result) then
                        return false, "Вы не можете использовать команду на этого игрока (недостаточно иммунитета)!"
                    end
                end
            end
        end
        
        return true, result
    end)

cmd.Param('player_steamid')
    :Parse(function(self, ply, cmdName, arg, opts)
        if not arg or arg == "" then
            return false, "Игрок не указан!"
        end
        
        local TrimString = function(str)
            if not str then return "" end
            str = tostring(str)
            return string.gsub(string.gsub(str, "^%s+", ""), "%s+$", "")
        end
        
        arg = TrimString(tostring(arg))
        local cmdTable = SC.AdminCommands
        local result = cmdTable and cmdTable.FindPlayer and cmdTable.FindPlayer(arg) or nil
        
        if IsValid(result) and result:IsPlayer() then
            local isConsole = not ply or not IsValid(ply) or not ply:IsPlayer()
            if not isConsole then
                local adminRanks = SC.AdminRanks
                if adminRanks and adminRanks.CanTarget then
                    if not adminRanks.CanTarget(ply, result) then
                        return false, "Вы не можете использовать команду на этого игрока (недостаточно иммунитета)!"
                    end
                end
            end
            return true, result
        end
        
        if string.find(arg, "^STEAM_[%d:]+") or string.find(arg, "^7656%d+") then
            return true, arg
        end
        
        if result and not IsValid(result) then
            return false, "Игрок '" .. arg .. "' не найден (должен быть онлайн)!"
        end
        
        return false, "Игрок '" .. (arg or "не указан") .. "' не найден!"
    end)

cmd.Param('time')
    :Parse(function(self, ply, cmdName, arg, opts)
        if not arg or arg == "" then
            return true, 0
        end
        
        arg = string.lower(arg)
        local units = {
            mi = 60,
            m = 60,
            h = 3600,
            d = 86400,
            w = 604800,
            mo = 2592000
        }
        
        local total = 0
        local found = false
        for amount, unit in string.gmatch(arg, "(%d+)(%a+)") do
            found = true
            amount = tonumber(amount)
            unit = string.sub(unit, 1, 2)
            if units[unit] then
                total = total + (amount * units[unit])
            else
                return false, "Неверная единица времени: " .. unit .. " (доступно: mi, h, d, w, mo)"
            end
        end
        
        if not found or total == 0 then
            return false, "Неверный формат времени! Примеры: 10mi, 1h, 2d, 1mo"
        end
        
        return true, total
    end)

cmd.Param('string')
    :Parse(function(self, ply, cmdName, arg, opts)
        local cmdTable = SC.AdminCommands
        if opts and opts.Args and cmdTable then
            local cmdObj = cmdTable.Get(cmdName)
            if cmdObj and opts.Args then
                local cmdArgsCount = #cmdObj:GetArgs()
                if #opts.Args > cmdArgsCount then
                    local extraArgs = {}
                    for i = opts.Pos + 1, #opts.Args do
                        table.insert(extraArgs, opts.Args[i] or "")
                    end
                    if #extraArgs > 0 then
                        arg = (arg or "") .. " " .. table.concat(extraArgs, " ")
                    end
                end
            end
        end
        arg = arg or ""
        if string.len(arg) > 512 then
            arg = string.sub(arg, 1, 512)
        end
        return true, arg
    end)

cmd.Param('number')
    :Parse(function(self, ply, cmdName, arg, opts)
        local num = tonumber(arg)
        if not num then
            return false, "Ожидается число, получено: " .. (arg or "nil")
        end
        return true, num
    end)

cmd.Param('rank')
    :Parse(function(self, ply, cmdName, arg, opts)
        arg = string.lower(arg or "")
        local ranks = SC.AdminRanks
        if not ranks or not ranks.Get(arg) then
            return false, "Ранг '" .. (arg or "не указан") .. "' не найден!"
        end
        return true, arg
    end)

cmd.Param('fraction')
    :Parse(function(self, ply, cmdName, arg, opts)
        arg = string.lower(arg or "")
        if not SC.FGet or not SC.FGet(arg) then
            return false, "Фракция '" .. (arg or "не указан") .. "' не найдена!"
        end
        return true, arg
    end)

SC.Admin.Commands = cmd

