ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Spawned Weapon"
ENT.Author = "SC"
ENT.Spawnable = false

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "WeaponClass")
    self:NetworkVar("String", 1, "WeaponName")
end

