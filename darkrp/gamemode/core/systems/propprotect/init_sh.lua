local function GetOwner(ent)
    return IsValid(ent) and (ent.SC_Owner or ent:GetNW2Entity("SC_Owner")) or nil
end

local function CanInteract(ply, ent)
    if not (IsValid(ent) and IsValid(ply)) then return false end
    if ent:IsWorld() then return true end
    
    local owner = GetOwner(ent)

    if ent:IsPlayer() then
        local pImm = ply:GetRankData().Immunity or 0
        local eImm = ent:GetRankData().Immunity or 0
        return pImm >= eImm
    end

    return owner == ply
end

local listtool = {
    ["material"] = { ["all"] = true },
    ["colour"]   = { ["all"] = true },
    ["weld"]     = { ["all"] = true },
    ["nocollide"] = { ["root"] = true },
    ["button"]   = { ["all"] = true },
    ["remover"]  = { ["all"] = true }
}

hook.Add("PhysgunPickup", "SC.PhysgunPickup", function(ply, ent)
    if not CanInteract(ply, ent) then return false end
    if IsValid(ent) then
        if ent:IsPlayer() then 
            ent:SetMoveType(MOVETYPE_NONE)
        elseif ent:GetClass() == "prop_physics" then 
            ent:SetCollisionGroup(COLLISION_GROUP_WORLD)
        end
    end
    return true
end)

hook.Add("PhysgunDrop", "SC.PhysgunDrop", function(ply, ent)
    if not IsValid(ent) then return end   
    if ent:IsPlayer() then 
        ent:SetMoveType(MOVETYPE_WALK)
    elseif ent:GetClass() == "prop_physics" then
        ent:SetCollisionGroup(COLLISION_GROUP_NONE)
        if IsValid(ent:GetPhysicsObject()) then 
            ent:GetPhysicsObject():EnableMotion(false)
        end
    end
end)

hook.Add("OnPhysgunReload", "SC.OnPhysgunReload", function() return false end)

hook.Add("CanProperty", "SC.CanProperty", function(ply, property, ent)
    return CanInteract(ply, ent)
end)

hook.Add("CanTool", "SC.CanTool", function(ply, tr, tool)
    if not tr then return false end
    if tr.HitWorld then return true end
    
    if IsValid(tr.Entity) then
        return CanInteract(ply, tr.Entity) and (listtool[tool] and (listtool[tool]["all"] or listtool[tool][ply:GetUserGroup():lower()]) or false)
    end
    return false
end)

hook.Add("CanDrive", "SC.CanDrive", function() return false end)
hook.Add("GravGunPunt", "SC.GravGunPunt", function() return false end)
hook.Add("PreDrawHalos", "SC.PP.prophalosnoo", function() return true end)

if SERVER then
    hook.Add("PlayerSpawnProp", "SC.PlayerSpawnProp", function(ply)
        if not IsValid(ply) then return false end
        local limit = ((ply.GetRankData and ply:GetRankData() or {}).MaxProps) or 5
        if ply:GetCount("props") >= limit then 
            ply:ChatPrint("Лимит пропов: " .. limit) 
            return false 
        end
        return true
    end)

    hook.Add("PlayerSpawnedProp", "SC.PlayerSpawnedProp", function(ply, mdl, ent)
        if not (IsValid(ent) and IsValid(ply)) then return end
        ent.SC_Owner = ply
        ent:SetNW2Entity("SC_Owner", ply)
        if IsValid(ent:GetPhysicsObject()) then 
            ent:GetPhysicsObject():EnableMotion(false)
        end
    end)

    hook.Add("PlayerSpawnedSENT", "SC.PlayerSpawnedSENT", function(ply, ent)
        if not (IsValid(ent) and IsValid(ply)) then return end
        ent.SC_Owner = ply
        ent:SetNW2Entity("SC_Owner", ply)
        if IsValid(ent:GetPhysicsObject()) then 
            ent:GetPhysicsObject():EnableMotion(false)
        end
    end)

    hook.Add("PlayerSpawnedNPC", "SC.PlayerSpawnedNPC", function(ply, ent)
        if not (IsValid(ent) and IsValid(ply)) then return end
        ent.SC_Owner = ply
        ent:SetNW2Entity("SC_Owner", ply)
        if IsValid(ent:GetPhysicsObject()) then 
            ent:GetPhysicsObject():EnableMotion(false)
        end
    end)

    hook.Add("PlayerSpawnedVehicle", "SC.PlayerSpawnedVehicle", function(ply, ent)
        if not (IsValid(ent) and IsValid(ply)) then return end
        ent.SC_Owner = ply
        ent:SetNW2Entity("SC_Owner", ply)
        if IsValid(ent:GetPhysicsObject()) then 
            ent:GetPhysicsObject():EnableMotion(false)
        end
    end)

    hook.Add("PlayerSpawnSENT", "SC.PlayerSpawnSENT", function(ply)
        return IsValid(ply) and ((ply.IsRoot and ply:IsRoot()) or ply:IsSuperAdmin())
    end)
    hook.Add("PlayerSpawnNPC", "SC.PlayerSpawnNPC", function(ply)
        return IsValid(ply) and ((ply.IsRoot and ply:IsRoot()) or ply:IsSuperAdmin())
    end)
    hook.Add("PlayerSpawnVehicle", "SC.PlayerSpawnVehicle", function(ply)
        return IsValid(ply) and ((ply.IsRoot and ply:IsRoot()) or ply:IsSuperAdmin())
    end)
    hook.Add("PlayerSpawnRagdoll", "SC.PlayerSpawnRagdoll", function(ply)
        return IsValid(ply) and ((ply.IsRoot and ply:IsRoot()) or ply:IsSuperAdmin())
    end)

    hook.Add("EntityTakeDamage", "SC.EntityTakeDamage", function(ent, dmg)
        if ent:GetClass() == "prop_dynamic" or ent:GetClass() == "prop_physics" then 
            return true 
        end
    end)

    hook.Add("PlayerDisconnected", "SC.Remove", function(ply)
        for _, ent in ipairs(ents.GetAll()) do
            if IsValid(ent) and GetOwner(ent) == ply then
                ent:Remove()
            end
        end
    end)
end