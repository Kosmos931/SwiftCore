if not CLIENT then return end

--[[
    @return number
]]
function PLAYER:GetHunger()
    if not IsValid(self) or not self:IsPlayer() then
        return SC.Hunger.Max or 100
    end
    if not SC.Hunger.NWKey then
        return SC.Hunger.Max or 100
    end
    return self:GetNWInt(SC.Hunger.NWKey, SC.Hunger.Max or 100)
end

--[[
    @return number
]]
function PLAYER:GetHungerPercent()
    if not IsValid(self) then return 100 end
    return (self:GetHunger() / (SC.Hunger.Max or 100)) * 100
end

--[[
    @return boolean
]]
function PLAYER:IsHungry()
    if not IsValid(self) then return false end
    local hunger = self:GetHunger()
    local max = SC.Hunger.Max or 100
    return hunger <= 0 or hunger < (max * 0.2)
end
