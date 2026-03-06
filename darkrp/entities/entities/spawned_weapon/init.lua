AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

local function getWeaponWorldModel(class)
    local wep = weapons.GetStored(class or "")
    if wep and isstring(wep.WorldModel) and wep.WorldModel ~= "" then
        return wep.WorldModel
    end
    if class == "weapon_shotgun" then
        return "models/weapons/w_shotgun.mdl"
    end
    return "models/weapons/w_pistol.mdl"
end

function ENT:Initialize()
    local class = self:GetWeaponClass()
    local worldModel = getWeaponWorldModel(class)
    self:SetModel(self:GetModel() ~= "" and self:GetModel() or worldModel)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)

    self:PhysWake()
end

function ENT:PhysWake()
    local phys = self:GetPhysicsObject()
    if not IsValid(phys) then return end
    phys:EnableMotion(true)
    phys:Wake()
end

function ENT:SetWeaponData(weaponClass, weaponName, owner)
    weaponClass = tostring(weaponClass or "")
    self:SetWeaponClass(weaponClass)
    self:SetWeaponName(tostring(weaponName or weaponClass))
    self:SetModel(getWeaponWorldModel(weaponClass))
    self.SC_Owner = owner
    if IsValid(owner) then
        self:SetNW2Entity("SC_Owner", owner)
    end
end

function ENT:Use(activator)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if self._nextUse and self._nextUse > CurTime() then return end
    self._nextUse = CurTime() + 0.2

    local weaponClass = self:GetWeaponClass()
    if weaponClass == "" then return end

    local weapon = ents.Create(weaponClass)
    if not IsValid(weapon) then return end

    if not weapon:IsWeapon() then
        weapon:SetPos(self:GetPos())
        weapon:SetAngles(self:GetAngles())
        weapon:Spawn()
        weapon:Activate()
        self:Remove()
        return
    end

    local canPickup = hook.Call("PlayerCanPickupWeapon", GAMEMODE, activator, weapon)
    if canPickup == false then
        weapon:Remove()
        return
    end
    weapon:Remove()

    activator:Give(weaponClass)
    local givenWeapon = activator:GetWeapon(weaponClass)
    if IsValid(givenWeapon) then
        local ammoType = givenWeapon:GetPrimaryAmmoType()
        if ammoType and ammoType >= 0 then
            local clipSize = tonumber(givenWeapon:GetMaxClip1()) or -1
            if clipSize <= 0 then
                local stored = weapons.GetStored(weaponClass)
                clipSize = tonumber(stored and stored.Primary and (stored.Primary.ClipSize or stored.Primary.DefaultClip) or 0) or 0
            end
            if clipSize > 0 then
                activator:GiveAmmo(clipSize, ammoType, true)
            end
        end
    end
    self:Remove()
end
