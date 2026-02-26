if not SERVER then return end

SC.Fractions = SC.Fractions or {}
local frac = SC.Fractions

hook.Add("Initialize", "SC.Fractions.SetupTeams", function()
    timer.Simple(0.5, function()
        local Frac = SC.Frac or SC.Fractions
        if Frac and Frac.List then
            for _, fraction in ipairs(Frac.List) do
                if fraction and fraction.TeamID and fraction.DisplayName then
                    team.SetUp(fraction.TeamID, fraction.DisplayName, Color(255, 255, 255))
                end
            end
        end
    end)
end)

--[[
    @param ply Player
    @param fractionName string
]]
function frac.SetPlayerFraction(ply, fractionName)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not SC.FGet or not frac.NWKey then return end

    local fraction = SC.FGet(fractionName)
    if not fraction or not fraction.TeamID then return end
    
    ply:SetNWString(frac.NWKey, fractionName)
    ply:SetTeam(fraction.TeamID)

    local model = fraction:GetRandomModel()
    if model then
        ply:SetModel(model)
    end
    ply:SetupHands()

    ply:SetMaxHealth(fraction.MaxHealth or 100)
    ply:SetHealth(fraction.MaxHealth or 100)
    ply:SetArmor(fraction.MaxArmor or 0)
    
    local cfg = SC.Config and SC.Config.Player or {}
    ply:SetWalkSpeed(fraction.WalkSpeed or cfg.WalkSpeed or 180)
    ply:SetRunSpeed(fraction.RunSpeed or cfg.RunSpeed or 280)
    ply:SetJumpPower(fraction.JumpPower or cfg.JumpPower or 200)

    SC.FGive(ply, fraction)
    local data = SC.DBGet and SC.DBGet(ply)
    if data then
        data.fraction = fractionName
        if SC.DBSave then
            SC.DBSave(ply)
        end
    end
end

--[[
    @param fraction Fraction
    @return Vector|nil, Angle|nil
]]
function frac.GetSpawnPoint(fraction)
    if not fraction then return nil end
    
    if istable(fraction.SpawnPoints) and #fraction.SpawnPoints > 0 then
        local validSpawns = {}
        for i = 1, #fraction.SpawnPoints do
            local spawn = fraction.SpawnPoints[i]
            if isvector(spawn) then
                table.insert(validSpawns, spawn)
            end
        end
        
        if #validSpawns > 0 then
            local idx = math.random(1, #validSpawns)
            local spawn = validSpawns[idx]
            if isvector(spawn) then
                return spawn, Angle(0, 0, 0)
            end
        end
    end
    
    local map = game.GetMap()
    local mapSpawns = SC.Config and SC.Config.Spawns and SC.Config.Spawns[map]
    
    if istable(mapSpawns) and #mapSpawns > 0 then
        local validSpawns = {}
        for i = 1, #mapSpawns do
            local spawn = mapSpawns[i]
            if isvector(spawn) then
                table.insert(validSpawns, spawn)
            end
        end
        
        if #validSpawns > 0 then
            local idx = math.random(1, #validSpawns)
            local spawn = validSpawns[idx]
            if isvector(spawn) then
                return spawn, Angle(0, 0, 0)
            end
        end
    end
    
    return nil
end

--[[
    @param ply Player
    @param fraction Fraction
]]
function frac.GiveLoadout(ply, fraction)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    if not fraction and SC.FGetPly and SC.FGet then
        local fractionName = SC.FGetPly(ply)
        if fractionName then
            fraction = SC.FGet(fractionName)
        end
    end
    
    if not fraction then return end

    ply:StripWeapons()

    if SC.Config and SC.Config.Weapons then
        for _, wep in ipairs(SC.Config.Weapons) do
            if isstring(wep) then
                ply:Give(wep)
            end
        end
    end

    if fraction.Weapons then
        for _, wep in ipairs(fraction.Weapons) do
            if isstring(wep) then
                ply:Give(wep)
            end
        end
    end
end

--[[
    @param fractionName string
]]
function PLAYER:SetFraction(fractionName)
    if not IsValid(self) or not self:IsPlayer() then return end
    if not SC.FSetPly then return end
    SC.FSetPly(self, fractionName)
end

SC.FSetPly = frac.SetPlayerFraction
SC.FSpawn = frac.GetSpawnPoint
SC.FGive = frac.GiveLoadout
