if not SERVER then return end

function PLAYER:GetHunger()
    if not IsValid(self) or not self:IsPlayer() then
        return SC.Hunger.Max or 100
    end
    if not SC.Hunger.NWKey then
        return SC.Hunger.Max or 100
    end
    return self:GetNWInt(SC.Hunger.NWKey, SC.Hunger.Max or 100)
end

function PLAYER:SetHunger(amount)
    if not IsValid(self) or not self:IsPlayer() then return end
    if amount == nil or not SC.Hunger.Max or not SC.Hunger.NWKey then return end

    amount = math.Clamp(math.floor(tonumber(amount) or 0), 0, SC.Hunger.Max)
    self:SetNWInt(SC.Hunger.NWKey, amount)

    local data = SC.DBGet and SC.DBGet(self)
    if data then
        data.hunger = amount
        if SC.DBSave then
            SC.DBSave(self)
        end
    end
end

function PLAYER:AddHunger(amount)
    if not IsValid(self) then return end
    self:SetHunger(self:GetHunger() + (tonumber(amount) or 0))
end

function PLAYER:TakeHunger(amount)
    if not IsValid(self) then return end
    self:SetHunger(self:GetHunger() - (tonumber(amount) or 0))
end

function PLAYER:IsHungry()
    if not IsValid(self) then return false end
    local hunger = self:GetHunger()
    local max = SC.Hunger.Max or 100
    return hunger <= 0 or hunger < (max * 0.2)
end

function PLAYER:GetHungerPercent()
    if not IsValid(self) then return 100 end
    return (self:GetHunger() / (SC.Hunger.Max or 100)) * 100
end

hook.Add("PlayerSpawn", "SC.Hunger.InitTimer", function(ply)
    if not IsValid(ply) then return end
    
    local timerName = "SC.Hunger.Decay." .. ply:SteamID64()
    if timer.Exists(timerName) then
        timer.Remove(timerName)
    end
    
    timer.Create(timerName, 160, 0, function()
        if not IsValid(ply) or not ply:Alive() then
            timer.Remove(timerName)
            return
        end

        local hunger = ply:GetHunger()
        if hunger <= 0 then
            local dmg = DamageInfo()
            dmg:SetDamage(1)
            dmg:SetDamageType(DMG_GENERIC)
            dmg:SetAttacker(game.GetWorld())
            ply:TakeDamageInfo(dmg)
        else
            ply:TakeHunger(SC.Hunger.DecayRate or 0.1)
        end
    end)
end)

hook.Add("PlayerDeath", "SC.Hunger.RemoveTimer", function(ply)
    if not IsValid(ply) then return end
    local timerName = "SC.Hunger.Decay." .. ply:SteamID64()
    if timer.Exists(timerName) then
        timer.Remove(timerName)
    end
end)

hook.Add("PlayerDisconnected", "SC.Hunger.Cleanup", function(ply)
    if not IsValid(ply) then return end
    local timerName = "SC.Hunger.Decay." .. ply:SteamID64()
    if timer.Exists(timerName) then
        timer.Remove(timerName)
    end
end)
