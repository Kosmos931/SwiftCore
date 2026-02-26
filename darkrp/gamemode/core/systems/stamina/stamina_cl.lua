if not CLIENT then return end

--[[
    @return number
]]
function PLAYER:GetStamina()
    if not IsValid(self) or not self:IsPlayer() then
        return SC.Config.Stamina.Max or 100
    end
    if not SC.Stamina.NWKey then
        return SC.Config.Stamina.Max or 100
    end
    return math.floor(self:GetNWInt(SC.Stamina.NWKey, SC.Config.Stamina.Max or 100))
end

--[[
    @return number
]]
function PLAYER:GetStaminaPercent()
    if not IsValid(self) then return 100 end
    return (self:GetStamina() / (SC.Config.Stamina.Max or 100)) * 100
end

hook.Add("SetupMove", "SC_Stamina_JumpBlock", function(ply, mv, cmd)
    if mv:KeyPressed(IN_JUMP) and ply:IsOnGround() and (ply:GetStamina() < 15) then
        mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(IN_JUMP)))
        return
    end
end)