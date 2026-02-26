if not SERVER then return end

local function OnCCGSpawn(ply, fraction)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
end

local function OnCCGDeath(ply, fraction)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
end

hook.Add("Initialize", "SC.Fractions.CCG.Register", function()
    timer.Simple(1, function()
        local fraction = SC.FGet("ccg")
        if fraction then
            fraction:OnSpawn(OnCCGSpawn)
            fraction:OnDeath(OnCCGDeath)
        end
    end)
end)
