if not CLIENT then return end

function PLAYER:GetMoney()
    if not IsValid(self) or not self:IsPlayer() then return 0 end
    if not SC.Money or not SC.Money.NWKey then return 0 end
    return self:GetNWInt(SC.Money.NWKey, 0)
end
