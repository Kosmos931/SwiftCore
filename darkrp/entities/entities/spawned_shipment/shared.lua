ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Spawned Shipment"
ENT.Author = "SC"
ENT.Spawnable = false

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "ShipmentItemClass")
    self:NetworkVar("String", 1, "ShipmentItemName")
    self:NetworkVar("Int", 0, "ShipmentRemaining")
end

