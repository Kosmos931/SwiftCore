if not SERVER then return end

SC.Admin = SC.Admin or {}
local admin = SC.Admin

admin.PlayerData = admin.PlayerData or {}

admin.NWKey = admin.NWKey or "SC.Admin.Rank"
admin.NWKeyFlags = admin.NWKeyFlags or "SC.Admin.Flags"

util.AddNetworkString(admin.NWKey)
util.AddNetworkString(admin.NWKeyFlags)

--[[
    @param ply Player
    @return string
]]
function admin.GetRank(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return admin.DefaultRank or "user" end
    
    local steamid = ply:SteamID64()
    if not steamid then return admin.DefaultRank or "user" end
    
    local data = admin.PlayerData[steamid]
    if not data then
        local nwRank = ply:GetNWString(admin.NWKey, "")
        if nwRank ~= "" then
            if not admin.PlayerData[steamid] then
                admin.PlayerData[steamid] = {}
            end
            admin.PlayerData[steamid].rank = nwRank
            return nwRank
        end
        return admin.DefaultRank or "user"
    end
    
    return data.rank or admin.DefaultRank or "user"
end

--[[
    @param ply Player
    @return string
]]
function admin.GetFlags(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return "" end
    
    local steamid = ply:SteamID64()
    if not steamid then return "" end
    
    local data = admin.PlayerData[steamid]
    
    if not data then
        local nwRank = ply:GetNWString(admin.NWKey, admin.DefaultRank or "user")
        local nwFlags = ply:GetNWString(admin.NWKeyFlags, "")
        
        if nwFlags == "" then
            local rankData = SC.AdminRanks and SC.AdminRanks.Get(nwRank)
            nwFlags = rankData and rankData.Flags or ""
        end
        
        if not admin.PlayerData[steamid] then
            admin.PlayerData[steamid] = {
                rank = nwRank,
                flags = nwFlags
            }
        end
        
        return nwFlags
    end
    
    local flags = data.flags or ""
    
    if flags == "" and data.rank then
        local rankData = SC.AdminRanks and SC.AdminRanks.Get(data.rank)
        if rankData and rankData.Flags then
            flags = rankData.Flags
            data.flags = flags
            ply:SetNWString(admin.NWKeyFlags, flags)
            if SC.AdminDB then
                SC.AdminDB.Save(ply)
            end
        end
    end
    
    return flags
end

--[[
    @param ply Player
    @param rank string
    @return boolean
]]
function admin.SetRank(ply, rank)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    local rankData = SC.AdminRanks.Get(rank)
    if not rankData then return false end
    
    local steamid = ply:SteamID64()
    if not steamid then return false end
    
    admin.PlayerData[steamid] = admin.PlayerData[steamid] or {}
    admin.PlayerData[steamid].rank = rank:lower()
    admin.PlayerData[steamid].flags = rankData.Flags or ""
    
    ply:SetNWString(admin.NWKey, rank:lower())
    ply:SetNWString(admin.NWKeyFlags, rankData.Flags or "")
    
    if SC.AdminDB then SC.AdminDB.Save(ply) end
    return true
end

--[[
    @param ply Player
    @param flags string
    @return boolean
]]
function admin.SetFlags(ply, flags)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    
    local steamid = ply:SteamID64()
    if not steamid then return false end
    
    if not string.match(flags or "", "^[a-z]*$") then
        return false
    end
    
    if not admin.PlayerData[steamid] then
        admin.PlayerData[steamid] = {}
    end
    
    admin.PlayerData[steamid].flags = flags or ""
    ply:SetNWString(admin.NWKeyFlags, flags or "")
    
    if SC.AdminDB then
        SC.AdminDB.Save(ply)
    end
    
    return true
end

--[[
    @param ply Player
    @param flag string
    @return boolean
]]
function admin.HasFlag(ply, flag)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    if not flag or #flag ~= 1 then return false end
    
    local flags = admin.GetFlags(ply)
    if flags == "" then return false end
    
    return string.find(flags, flag, 1, true) ~= nil
end

--[[
    @param ply Player
    @param flags string
    @return boolean
]]
function admin.HasAnyFlag(ply, flags)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    if not flags or flags == "" then return true end
    
    local playerFlags = admin.GetFlags(ply)
    if not playerFlags or playerFlags == "" then return false end
    
    for i = 1, #flags do
        local flag = string.sub(flags, i, i)
        if string.find(playerFlags, flag, 1, true) then
            return true
        end
    end
    
    return false
end

--[[
    @param ply Player
    @param flags string
    @return boolean
]]
function admin.HasAllFlags(ply, flags)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    if not flags or flags == "" then return false end
    
    local playerFlags = admin.GetFlags(ply)
    if playerFlags == "" then return false end
    
    for i = 1, #flags do
        local flag = string.sub(flags, i, i)
        if not string.find(playerFlags, flag, 1, true) then
            return false
        end
    end
    
    return true
end

--[[
    @param ply Player
    @return number
]]
function admin.GetRankLevel(ply)
    local rank = admin.GetRank(ply)
    if not rank then return 0 end
    
    local ranks = SC.AdminRanks
    if not ranks then return 0 end
    
    local rankData = ranks.Get(rank)
    if not rankData then return 0 end
    
    return rankData.RankLevel or 0
end

--[[
    @param ply Player
    @param minRank string
    @return boolean
]]
function admin.HasRankOrHigher(ply, minRank)
    local ranks = SC.AdminRanks
    if not ranks then return false end
    
    local minRankData = ranks.Get(minRank)
    if not minRankData then return false end
    
    return admin.GetRankLevel(ply) >= (minRankData.RankLevel or 0)
end

--[[
    @param ply Player
    @return number
]]
function admin.GetImmunity(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return 0 end
    
    local ranks = SC.AdminRanks
    if not ranks then return 0 end
    
    local rankData = ranks.GetPlayerRankData(ply)
    if not rankData then return 0 end
    
    return rankData.Immunity or 0
end

--[[
    @param ply Player
]]
function admin.LoadPlayer(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    local steamid = ply:SteamID64()
    if not steamid then return end
    
    if SC.AdminDB then
        SC.AdminDB.Load(ply)
    else
        local rank = admin.DefaultRank or "user"
        local rankData = SC.AdminRanks and SC.AdminRanks.Get(rank)
        local flags = rankData and rankData.Flags or ""
        
        admin.PlayerData[steamid] = {
            rank = rank,
            flags = flags
        }
        
        ply:SetNWString(admin.NWKey, rank)
        ply:SetNWString(admin.NWKeyFlags, flags)
    end
end
