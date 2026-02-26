if not SERVER then return end

local function OnCitizenSpawn(ply, fraction)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
end

local function OnCitizenDeath(ply, fraction)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
end

hook.Add("Initialize", "SC.Fractions.Citizen.Register", function()
    timer.Simple(1, function()
        local fraction = SC.FGet("citizen")
        if fraction then
            fraction:OnSpawn(OnCitizenSpawn)
            fraction:OnDeath(OnCitizenDeath)
        end
    end)
end)
