local maxDist = 400 * 400

local function GetDoorStatusText(door)
    local title = door:GetNWString("SC_DoorTitle", "")
    local faction = door:GetNWString("SC_DoorFaction", "")
    local buyable = door:GetNWBool("SC_DoorBuyable", true)
    local isOwned = door:GetNWBool("SC_DoorOwned", false)
    local owner = door:GetNWEntity("SC_DoorOwner")
    local price = door:GetNWInt("SC_DoorPrice", 0)
    local coowners = door:GetNWInt("SC_DoorCoOwnerCount", 0)

    local lines = {}

    if title ~= "" then
        table.insert(lines, title)
    end

    if faction ~= "" then
        table.insert(lines, "Фракция: " .. faction)
    end

    if isOwned and IsValid(owner) then
        table.insert(lines, "Владелец: " .. owner:Nick())
        table.insert(lines, "Совладельцев: " .. coowners)
    elseif buyable then
        table.insert(lines, "Продается: " .. price .. "$")
    else
        table.insert(lines, "Не продается")
    end

    table.insert(lines, "Купить: sc_door_buy | Продать: sc_door_sell")
    table.insert(lines, "Совладелец: sc_door_addcoowner <ник>")

    return lines
end

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

        local lines = GetDoorStatusText(door)

        local function DrawPanelLines()
            RNDX.Draw(0, -213, -137, 426, 278, sc.Color('030405'))
            for i, line in ipairs(lines) do
                draw.SimpleText(line, sc.Font('Exo 2 SemiBold:16') or "DermaDefault", 0, -95 + (i * 28), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end

        cam.Start3D2D(doorPos + offset, ang, 0.07)
            DrawPanelLines()
        cam.End3D2D()

        cam.Start3D2D(doorPos + offset2, ang2, 0.07)
            DrawPanelLines()
        cam.End3D2D()
    end
end)
