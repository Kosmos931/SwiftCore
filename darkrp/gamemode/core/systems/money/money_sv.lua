if not SERVER then return end

function PLAYER:GetMoney()
    if not IsValid(self) or not self:IsPlayer() then return 0 end
    if not SC.Money or not SC.Money.NWKey then return 0 end
    return self:GetNWInt(SC.Money.NWKey, 0)
end

function PLAYER:SetMoney(amount)
    if not IsValid(self) or not self:IsPlayer() then return end
    if not SC.Money or not SC.Money.NWKey then return end

    amount = math.max(0, math.floor(tonumber(amount) or 0))
    self:SetNWInt(SC.Money.NWKey, amount)
    
    local data = SC.DBGet and SC.DBGet(self)
    if data then
        data.money = amount
        if SC.DBSave then
            SC.DBSave(self)
        end
    end
end

function PLAYER:AddMoney(amount)
    if not IsValid(self) then return end
    self:SetMoney(self:GetMoney() + (tonumber(amount) or 0))
end

function PLAYER:TakeMoney(amount)
    if not IsValid(self) then return end
    self:SetMoney(self:GetMoney() - (tonumber(amount) or 0))
end

function PLAYER:HasMoney(amount)
    if not IsValid(self) then return false end
    return self:GetMoney() >= (tonumber(amount) or 0)
end
