--[[ local maxDist = 400 * 400

hook.Add("PostDrawTranslucentRenderables", "Door_Load", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local plyPos = ply:GetPos()
    for _, door in ipairs(ents.FindByClass("prop_door_rotating")) do
        if not IsValid(door) then continue end
        local doorPos = door:GetPos()
        if plyPos:DistToSqr(doorPos) > maxDist then continue end
        local ang = door:GetAngles()
        local ang2 = Angle(ang.p, ang.y, ang.r)
        local offset = ang:Up() + ang:Forward() * -1.2 + ang:Right() * -23
        ang:RotateAroundAxis(ang:Forward(), 90)
        ang:RotateAroundAxis(ang:Right(), 90)
        local offset2 = ang2:Up() + ang2:Forward() * 1.2 + ang2:Right() * -23
        ang2:RotateAroundAxis(ang2:Forward(), -90)
        ang2:RotateAroundAxis(ang2:Up(), -180)
        ang2:RotateAroundAxis(ang2:Right(), 90)

        cam.Start3D2D(doorPos + offset, ang, 0.07)
            draw.SimpleText("f7ogf087e0h7hvsd8b790", "DermaDefault", 0, 0, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        cam.End3D2D()

        cam.Start3D2D(doorPos + offset2, ang2, 0.07)
            RNDX.Draw(0, -215, -143, 430, 286, sc.Color('5AA0F1'))
            RNDX.Draw(0, -213, -137, 426, 278, sc.Color('030405'))
        cam.End3D2D()
    end
end)--]]