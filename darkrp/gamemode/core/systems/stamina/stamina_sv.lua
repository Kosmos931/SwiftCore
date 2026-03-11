if not SERVER then return end
if SC.Config.Stamina.Enable == false then return end
function PLAYER:GetStamina()
    if not IsValid(self) or not self:IsPlayer() then
        return SC.Config.Stamina.Max or 100
    end
    if not SC.Stamina.NWKey then
        return SC.Config.Stamina.Max or 100
    end
    return self:GetNWFloat(SC.Stamina.NWKey, SC.Config.Stamina.Max or 100)
end

function PLAYER:SetStamina(amount)
    if not IsValid(self) or not self:IsPlayer() then return end
    if amount == nil or not SC.Config.Stamina.Max or not SC.Stamina.NWKey then return end

    amount = math.Clamp(tonumber(amount) or 0, 0, SC.Config.Stamina.Max)
    self:SetNWFloat(SC.Stamina.NWKey, amount)
end

function PLAYER:AddStamina(amount)
    if not IsValid(self) then return end
    self:SetStamina(self:GetStamina() + (tonumber(amount) or 0))
end

function PLAYER:TakeStamina(amount)
    if not IsValid(self) then return end
    self:SetStamina(self:GetStamina() - (tonumber(amount) or 0))
end

function PLAYER:GetStaminaPercent()
    if not IsValid(self) then return 100 end
    return (self:GetStamina() / (SC.Config.Stamina.Max or 100)) * 100
end

hook.Add("PlayerSpawn", "SC.Stamina.InitTimer", function(ply)
    if not IsValid(ply) then return end
    
    local timerName = "SC.Stamina." .. ply:SteamID64()
    
    if timer.Exists(timerName) then
        timer.Remove(timerName)
    end
    
    local cfg = SC.Config.Stamina

    ply:SetStamina(cfg.Max or 100)
    ply:SprintEnable()
    timer.Create(timerName, 0.1, 0, function()
        if not IsValid(ply) or not ply:Alive() or ply:InVehicle() then
            timer.Remove(timerName)
            return
        end

        local vel = ply:GetVelocity():Length()
        local ground = ply:IsOnGround()
        
        local isRun = ground and ply:IsSprinting() and vel > (ply:GetWalkSpeed() + 10)

        local change = isRun and -cfg.DrainRun or (not ground and cfg.RegenAir or (vel > 10 and cfg.RegenWalk or cfg.RegenIdle))

        ply:AddStamina(change * 0.1)
    end)
end)

hook.Add("PlayerDeath", "SC.Stamina.RemoveTimer", function(ply)
    if not IsValid(ply) then return end
    local timerName = "SC.Stamina." .. ply:SteamID64()
    if timer.Exists(timerName) then
        timer.Remove(timerName)
    end
end)

hook.Add("PlayerDisconnected", "SC.Stamina.Cleanup", function(ply)
    if not IsValid(ply) then return end
    local timerName = "SC.Stamina." .. ply:SteamID64()
    if timer.Exists(timerName) then
        timer.Remove(timerName)
    end
end)

hook.Add("SetupMove", "SC.Stamina.JumpBlock", function(ply, mv, cmd)
    if IsValid(ply) and mv:KeyPressed(IN_JUMP) and ply:IsOnGround() then
        if ply:GetStamina() < (SC.Config.Stamina.JumpLimit or 10) then
            mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(IN_JUMP)))
            return
        end
        ply:TakeStamina(SC.Config.Stamina.DrainJump or 5)
    end
    if IsValid(ply) and ply:GetStamina() <= 1 then
        ply:SprintDisable()
    elseif IsValid(ply) and ply:GetStamina() >= 50 then
        ply:SprintEnable()
    end
end)