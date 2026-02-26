SC.Fractions = SC.Fractions or {}

SC.Fractions.List   = SC.Fractions.List   or {}
SC.Fractions.Teams  = SC.Fractions.Teams  or {}
SC.Fractions.Groups = SC.Fractions.Groups or {}

SC.Fractions.NWKey = "SC_Fraction"

local citizens = {'models/player/Group01/Female_01.mdl', 'models/player/Group01/Female_02.mdl', 'models/player/Group01/Female_03.mdl', 'models/player/Group01/Female_04.mdl', 'models/player/Group01/Female_06.mdl', 'models/player/group01/male_01.mdl', 'models/player/Group01/Male_02.mdl', 'models/player/Group01/male_03.mdl', 'models/player/Group01/Male_04.mdl', 'models/player/Group01/Male_05.mdl', 'models/player/Group01/Male_06.mdl', 'models/player/Group01/Male_07.mdl', 'models/player/Group01/Male_08.mdl', 'models/player/Group01/Male_09.mdl', 'models/player/Group02/male_02.mdl', 'models/player/Group02/male_04.mdl', 'models/player/Group02/male_06.mdl', 'models/player/Group02/male_08.mdl',}

local Fraction = {}

--[[
    Автоматически создает параметры при первом обращении
    При вызове :SetPropertyName(value) создается метод автоматически
    @example fraction:SetWalkSpeed(180)  создаст метод автоматически и установит self.WalkSpeed = 180
    @example fraction:SetChototam(1000)  создаст метод автоматически и установит self.Chototam = 1000
    @example local value = fraction.WalkSpeed or 180  получение значения (прямой доступ)
    Если несколько параметров:
    @example regenData = fraction.RegenHP   {true, 100}
    @example enabled = regenData[1]         true
    @example amount = regenData[2]          100
]]
function Fraction.__index(tbl, key)
    local method = rawget(Fraction, key)
    if method then
        return method
    end
    
    if string.find(key, "^Set") then
        local propName = string.sub(key, 4)
        local param = function(self, ...)
            local args = {...}
            if #args == 1 then
                self[propName] = args[1]
            else
                self[propName] = args
            end
            return self
        end
        Fraction[key] = param
        return param
    end
    
    return nil
end

--[[
    @param name string
    @param displayName string
    @return Fraction
]]
function Fraction:New(name, displayName)
    local obj = setmetatable({}, Fraction)
    obj.Name = name
    obj.DisplayName = displayName
    obj.TeamID = nil
    obj.Models = citizens
    obj.SpawnPoints = {}
    obj.Weapons = {}
    obj.Callbacks = {}
    obj.SpawnHooks = {}
    obj.DeathHooks = {}
    return obj
end

--[[
    @return string|nil
]]
function Fraction:GetRandomModel()
    if not self.Models or #self.Models == 0 then return nil end
    return self.Models[math.random(1, #self.Models)]
end

--[[
    @param tbl string|table
    @return self
]]
function Fraction:SetModels(tbl)
    if isstring(tbl) then
        self.Models = {tbl}
    elseif istable(tbl) then
        self.Models = tbl
    end
    return self
end

--[[
    @param tbl string|table
    @return self
]]
function Fraction:SetWeapons(tbl)
    if isstring(tbl) then
        self.Weapons = {tbl}
    elseif istable(tbl) then
        self.Weapons = tbl
    else
        self.Weapons = {tbl}
    end
    return self
end

--[[
    @param pos Vector|table
    @return self
]]
function Fraction:SetSpawn(pos)
    if not pos then return self end
    if isvector(pos) then
        table.insert(self.SpawnPoints, pos)
    elseif istable(pos) then
        for _, v in ipairs(pos) do
            if isvector(v) then
                table.insert(self.SpawnPoints, v)
            end
        end
    end
    return self
end

--[[
    @param pos Vector|table
    @return self
]]
function Fraction:AddSpawn(pos)
    return self:SetSpawn(pos)
end

--[[
    @param fn function
    @return self
]]
function Fraction:OnSpawn(fn)
    if isfunction(fn) then
        table.insert(self.SpawnHooks, fn)
    end
    return self
end

--[[
    @param fn function
    @return self
]]
function Fraction:OnDeath(fn)
    if isfunction(fn) then
        table.insert(self.DeathHooks, fn)
    end
    return self
end

--[[
    @param fn function
    @return self
]]
function Fraction:Other(fn)
    if isfunction(fn) then
        table.insert(self.Callbacks, fn)
    end
    return self
end

--[[
    @return self
]]
function Fraction:Register()
    if self.TeamID then return self end
    if SC.Fractions.Teams[self.Name] then return self end

    table.insert(SC.Fractions.List, self)
    self.TeamID = #SC.Fractions.List
    SC.Fractions.Teams[self.Name] = self

    for _, cb in ipairs(self.Callbacks) do
        if isfunction(cb) then
            cb(self)
        end
    end

    self.Callbacks = {}
    return self
end

--[[
    @param name string
    @param displayName string
    @return Fraction
]]
function SC.Fractions.Add(name, displayName)
    if SC.Fractions.Teams[name] then
        return SC.Fractions.Teams[name]
    end
    return Fraction:New(name, displayName)
end

--[[
    @param name string
    @return Fraction|nil
]]
function SC.Fractions.Get(name)
    return SC.Fractions.Teams[name]
end

--[[
    @param ply Player
    @return string|nil
]]
function SC.Fractions.GetPlayerFraction(ply)
    if not IsValid(ply) then return nil end
    return ply:GetNWString(SC.Fractions.NWKey, nil)
end

--[[
    @param groupName string
    @param ... string
]]
function SC.Fractions.AddGroup(groupName, ...)
    SC.Fractions.Groups[groupName] = {...}
end

--[[
    @param groupName string
    @return table|nil
]]
function SC.Fractions.GetGroup(groupName)
    return SC.Fractions.Groups[groupName]
end

SC.Fractions.BaseFraction = SC.Fractions.BaseFraction or nil

--[[
    @param fractionName string
]]
function SC.Fractions.SetBaseFraction(fractionName)
    if SC.Fractions.Teams[fractionName] then
        SC.Fractions.BaseFraction = fractionName
    end
end

--[[
    @return string|nil
]]
function SC.Fractions.GetBaseFraction()
    return SC.Fractions.BaseFraction
end

--[[
    @return string|nil
]]
function PLAYER:GetFraction()
    if not IsValid(self) then return nil end
    return self:GetNWString(SC.Fractions.NWKey, nil)
end
--[[
    @return string|nil
]]
function PLAYER:GetFractionName()
    if not IsValid(self) then return nil end
    return SC.Fractions.Get(self:GetFraction()).DisplayName
end
--[[
    @return Fraction|nil
]]
function PLAYER:GetFractionData()
    local fractionName = self:GetFraction()
    if not fractionName then return nil end
    return SC.FGet and SC.FGet(fractionName) or nil
end

--[[
    @param fractionName string|table
    @return boolean
]]
function PLAYER:IsInFraction(fractionName)
    local currentFraction = self:GetFraction()
    if not currentFraction then return false end
    
    if istable(fractionName) then
        for _, name in ipairs(fractionName) do
            if currentFraction == name then return true end
        end
        return false
    end
    
    return currentFraction == fractionName
end

SC.Frac = SC.Fractions
SC.FGet = SC.Fractions.Get
SC.FAdd = SC.Fractions.Add
SC.FGetPly = SC.Fractions.GetPlayerFraction
SC.FBase = SC.Fractions.GetBaseFraction
