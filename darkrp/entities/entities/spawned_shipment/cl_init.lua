include("shared.lua")

function ENT:Draw()
    self:DrawModel()

    local lp = LocalPlayer()
    if not IsValid(lp) then return end

    local min, max = self:OBBMins(), self:OBBMaxs()
    local height = (max.z - min.z)
    local pos = self:GetPos() + Vector(0, 0, math.max(20, height + 8))
    local ang = Angle(0, (lp:EyeAngles().y - 90), 90)

    local name = self:GetShipmentItemName()
    local left = self:GetShipmentRemaining()
    if name == "" then name = "Shipment" end

    cam.Start3D2D(pos, ang, 0.1)
        draw.SimpleTextOutlined(name, "DermaLarge", 0, -16, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
        draw.SimpleTextOutlined("Осталось: " .. tostring(left), "Trebuchet24", 0, 16, Color(255, 220, 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
    cam.End3D2D()
end
