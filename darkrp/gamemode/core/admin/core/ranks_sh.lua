SC.Admin = SC.Admin or {}
SC.Admin.Ranks = SC.Admin.Ranks or {}
local ranks = SC.Admin.Ranks

ranks.List = ranks.List or {}
ranks.Teams = ranks.Teams or {}

local Rank = {}


function Rank.__index(tbl, key)
    local method = rawget(Rank, key)
    if method then
        return method
    end
    if type(key) == "string" and string.find(key, "^Set") then
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
        Rank[key] = param
        return param
    end
    
    return nil
end

function Rank:New(name, displayName)
    local obj = setmetatable({}, Rank)
    obj.Name = name:lower()
    obj.DisplayName = displayName
    obj.Immunity = 0
    obj.Flags = ""
    obj.RankLevel = 0

    obj.IsVip = false
    obj.IsAdminS = false
    obj.IsSuperAdminS = false
    obj.IsRootS = false
    return obj
end

function Rank:SetVIP(bool) self.IsVip = bool return self end
function Rank:SetAdmin(bool) 
    if bool then self:SetVIP(true) end
    self.IsAdminS = bool 
    return self 
end
function Rank:SetSuperAdmin(bool) 
    if bool then self:SetAdmin(true) end
    self.IsSuperAdminS = bool 
    return self 
end
function Rank:SetRoot(bool)
    if bool then self:SetSuperAdmin(true) end
    self.IsRootS = bool
    return self
end

function Rank:SetImmunity(immunity) self.Immunity = tonumber(immunity) or 0 return self end
function Rank:SetFlags(flags)
    if string.match(flags or "", "^[a-z]*$") then self.Flags = flags or "" end
    return self
end
function Rank:SetRankLevel(level) self.RankLevel = tonumber(level) or 0 return self end

function Rank:Register()
    if ranks.Teams[self.Name] then return self end
    table.insert(ranks.List, self)
    ranks.Teams[self.Name] = self
    return self
end

function ranks.Add(name, displayName)
    return ranks.Teams[name:lower()] or Rank:New(name, displayName)
end

function ranks.Get(name) return ranks.Teams[tostring(name):lower()] end

function ranks.GetPlayerRank(ply)
    if not IsValid(ply) then return SC.Admin.DefaultRank or "user" end
    if SERVER then
        return SC.Admin.GetRank(ply)
    else
        local r = ply:GetNWString("SC.Admin.Rank", "")
        return (r ~= "") and r or (SC.Admin.DefaultRank or "user")
    end
end

function ranks.GetPlayerRankData(ply)
    return ranks.Get(ranks.GetPlayerRank(ply))
end

local PLAYER = debug.getregistry().Player

function PLAYER:GetUserGroup() return ranks.GetPlayerRank(self) end
function PLAYER:IsUserGroup(name) return self:GetUserGroup() == tostring(name):lower() end

function PLAYER:IsAdmin()
    local data = ranks.GetPlayerRankData(self)
    return data and data.IsAdminS or false
end

function PLAYER:IsSuperAdmin()
    local data = ranks.GetPlayerRankData(self)
    return data and data.IsSuperAdminS or false
end

function PLAYER:IsRoot()
    local data = ranks.GetPlayerRankData(self)
    return data and data.IsRootS or false
end

function PLAYER:IsVIP()
    local data = ranks.GetPlayerRankData(self)
    return data and data.IsVip or false
end
function PLAYER:GetRankData()
    if not IsValid(self) then return nil end
    return SC.Admin.Ranks.GetPlayerRankData(self)
end
function Rank:HasFlag(flag)
    if self.IsRootS then return true end
    return string.find(self.Flags or "", string.lower(flag or ""), 1, true) ~= nil
end

function ranks.CanTarget(ply, target)
    if not IsValid(ply) or not IsValid(target) then return false end
    if ply == target then return true end
    local pD, tD = ranks.GetPlayerRankData(ply), ranks.GetPlayerRankData(target)
    if not pD then return false end
    if pD.IsRootS then return true end
    if not tD then return true end
    return pD.Immunity > tD.Immunity
end

SC.AdminRanks = ranks