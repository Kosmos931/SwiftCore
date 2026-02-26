if not SERVER then return end

local function OnGhoulSpawn(ply, fraction)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    if fraction.RegenHP then
        local regenData = fraction.RegenHP
        if istable(regenData) and regenData[1] then
            local enabled = regenData[1]
            local amount = regenData[2] or 1
            
            if enabled then
                timer.Create("GhoulHealthRegen." .. ply:SteamID64(), 1, 0, function()
                    if not IsValid(ply) or not ply:Alive() or ply:GetFraction() ~= "ghoul" then
                        timer.Remove("GhoulHealthRegen." .. ply:SteamID64())
                        return
                    end
                    
                    local currentHP = ply:Health()
                    local maxHP = ply:GetMaxHealth()
                    if currentHP < maxHP then
                        ply:SetHealth(math.min(currentHP + amount, maxHP))
                    end
                end)
            end
        end
    end
end

local function OnGhoulDeath(ply, fraction)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    local steamid = ply:SteamID64()
    if not steamid then return end
    
    local timerName = "GhoulHealthRegen." .. steamid
    if timer.Exists(timerName) then
        timer.Remove(timerName)
    end
end

hook.Add("PlayerDisconnected", "SC.Fractions.Ghoul.Cleanup", function(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    local steamid = ply:SteamID64()
    if not steamid then return end
    
    local timerName = "GhoulHealthRegen." .. steamid
    if timer.Exists(timerName) then
        timer.Remove(timerName)
    end
end)

hook.Add("Initialize", "SC.Fractions.Ghoul.Register", function()
    timer.Simple(1, function()
        local fraction = SC.FGet("ghoul")
        if fraction then
            fraction:OnSpawn(OnGhoulSpawn)
            fraction:OnDeath(OnGhoulDeath)
        end
    end)
end)
