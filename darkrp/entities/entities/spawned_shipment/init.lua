AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

local DEFAULT_MODEL = "models/props_junk/cardboard_box003a.mdl"

function ENT:Initialize()
    self:SetModel(self:GetModel() ~= "" and self:GetModel() or DEFAULT_MODEL)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)

    self:PhysWake()

    if self:GetShipmentRemaining() <= 0 then
        self:SetShipmentRemaining(1)
    end
end

function ENT:PhysWake()
    local phys = self:GetPhysicsObject()
    if not IsValid(phys) then return end
    phys:EnableMotion(true)
    phys:Wake()
end

function ENT:SetShipmentData(itemClass, itemName, count)
    self:SetShipmentItemClass(tostring(itemClass or ""))
    self:SetShipmentItemName(tostring(itemName or "Unknown"))
    self:SetShipmentRemaining(math.max(1, math.floor(tonumber(count) or 1)))
end

function ENT:Use(activator)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if self._nextUse and self._nextUse > CurTime() then return end
    self._nextUse = CurTime() + 0.2

    local itemClass = self:GetShipmentItemClass()
    local left = self:GetShipmentRemaining()
    if itemClass == "" or left <= 0 then
        self:Remove()
        return
    end

    local weaponEnt = ents.Create("spawned_weapon")
    if not IsValid(weaponEnt) then return end

    weaponEnt:SetPos(self:GetPos() + self:GetUp() * 5)
    weaponEnt:SetAngles(self:GetAngles())
    if weaponEnt.SetWeaponData then
        weaponEnt:SetWeaponData(itemClass, self:GetShipmentItemName(), self.SC_Owner)
    end
    weaponEnt:Spawn()
    weaponEnt:Activate()

    left = left - 1
    self:SetShipmentRemaining(left)

    if left <= 0 then
        self:Remove()
    end
end
