AddCSLuaFile()

SWEP.PrintName = "Ключи"
SWEP.Author = "SwiftCore"
SWEP.Category = "SwiftCore"
SWEP.Spawnable = true
SWEP.ViewModel = "models/weapons/v_hands.mdl"
SWEP.UseHands = true
SWEP.HoldType = "normal"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 0.5)
    if CLIENT then return end
    
    local ply = self:GetOwner()
    local tr = ply:GetEyeTrace()
    local ent = tr.Entity

    if IsValid(ent) and (ent:GetClass():find("door")) and ply:GetPos():DistToSqr(ent:GetPos()) < 10000 then
        if SC.Doors.HasAccess(ply, ent) then
            ent:Fire("Lock")
            ply:EmitSound("npc/metropolice/gear" .. math.random(1, 6) .. ".wav")
        else
            ply:EmitSound("physics/wood/wood_crate_impact_hard2.wav", 100, math.random(90, 110))
        end
        ply:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_HL2MP_GESTURE_RANGE_ATTACK_FIST, true)
    end
end

function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 0.5)
    if CLIENT then return end

    local ply = self:GetOwner()
    local tr = ply:GetEyeTrace()
    local ent = tr.Entity

    if IsValid(ent) and (ent:GetClass():find("door")) and ply:GetPos():DistToSqr(ent:GetPos()) < 10000 then
        if SC.Doors.HasAccess(ply, ent) then
            ent:Fire("Unlock")
            ply:EmitSound("npc/metropolice/gear" .. math.random(1, 6) .. ".wav")
        else
            local owner = ent:GetNWEntity("SC_DoorOwner")
            if IsValid(owner) then
                if not ent.NextBell or ent.NextBell <= CurTime() then
                    owner:SendLua([[notification.AddLegacy("В вашу дверь звонят!", 0, 4)]])
                    ply:EmitSound("ambient/alarms/warningbell1.wav", 60, 110)
                    ent.NextBell = CurTime() + 10
                end
            end
        end
        ply:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_HL2MP_GESTURE_RANGE_ATTACK_FIST, true)
    end
end