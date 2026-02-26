local ply
local lerphp, lerpar, lerpst, lerphr = 0, 0, 0, 0

local resources = {}

local function InitResources()
    if not sc or not sc.Font or resources.initialized then return end

    resources.fonts = {
        exo10 = sc.Font('Exo 2 Black:10'),
        orb12 = sc.Font('Orbitron Bold:12'),
        exo12 = sc.Font('Exo 2 Black:12'),
        orb10 = sc.Font('Orbitron Bold:10'),
        orb2_10 = sc.Font('Orbitron2:10'),
        exo16 = sc.Font('Exo 2 Bold:16'),
        exo_b12 = sc.Font('Exo 2 Bold:12')
    }

    resources.colors = {
        black25 = sc.Color('000000', 25),
        main_bg = sc.Color('050605', 80),
        red_line = sc.Color('8C0303'),
        label = sc.Color('353737'),
        armor = sc.Color('5FA9FD'),
        hunger = sc.Color('FEB803'),
        separator = sc.Color('131313'),
        white_text = sc.Color('F6EEBE'),
        seg_bg = sc.Color('0C0C0C', 90),
        hp_bar = sc.Color('8B0203'),
        st_bar = sc.Color('454545'),
        lvl_bg = sc.Color('8B0202'),
        lvl_sh = sc.Color('8B0202', 25),
        frac = sc.Color('3D3D44'),
        mon_lbl = sc.Color('6D6E74'),
        mon_val = sc.Color('99979D'),
        mon_sep = sc.Color('3B3D44')
    }
    
    resources.initialized = true
end

local function segment(x,y,w,h,space,count,cur,max,col,bg)
    local per = max/count
    for i=0,count-1 do
        local sw = math.Clamp(cur-i*per,0,per)/per*w
        if bg then draw.RoundedBox(4,x+i*(w+space),y,w,h,bg) end
        RNDX.Draw(0,x+i*(w+space),y,sw,h,col)
    end
end

function GM:HUDPaint()
    InitResources()
    if not resources.initialized then return end
    
    local f = resources.fonts
    local c = resources.colors

    ply = ply or LocalPlayer()
    if not IsValid(ply) then return end
    --[[        LEFT DOWN        ]]--
    local hp, mhp = ply:Health(), ply:GetMaxHealth()
    local ar, mar = ply:Armor(), ply:GetMaxArmor()
    local st = ply:GetStamina()
    local hr = ply:GetHunger()

    lerphp = sc.lerpvalue(lerphp, hp, mhp)
    lerpar = sc.lerpvalue(lerpar, ar, mar)
    lerpst = sc.lerpvalue(lerpst, st, SC.Config.Stamina.Max)
    lerphr = sc.lerpvalue(lerphr, hr, 100)

    RNDX.DrawShadows(0, sc.w(38), sc.h(904), sc.w(327), sc.h(110), c.black25, 15,15*1.2,1,rndx.BLUR)

    RNDX.Draw(0, sc.w(38), sc.h(904), sc.w(327), sc.h(110), c.main_bg)
    RNDX.Draw(0, sc.w(38), sc.h(904), sc.w(3), sc.h(110), c.red_line)

    draw.SimpleText('ARMOR', f.exo10, sc.w(241), sc.h(964), c.label, TEXT_ALIGN_CENTER)
    draw.SimpleText(math.Round(lerpar) .. '%', f.orb12, sc.w(241), sc.h(977), c.armor, TEXT_ALIGN_CENTER)
    RNDX.Draw(0, sc.w(211), sc.h(964), sc.w(2), sc.h(29), c.separator)

    draw.SimpleText('HUNGER', f.exo10, sc.w(304), sc.h(964), c.label, TEXT_ALIGN_CENTER)
    draw.SimpleText(math.Round(lerphr) .. '%', f.orb12, sc.w(304), sc.h(977), c.hunger, TEXT_ALIGN_CENTER)
    RNDX.Draw(0, sc.w(274), sc.h(964), sc.w(2), sc.h(29), c.separator)

    draw.SimpleText('HP', f.exo12, sc.w(62), sc.h(925), c.label)
    draw.SimpleText(math.Round(lerphp) .. '/' .. mhp, f.orb12, sc.w(345), sc.h(925), c.white_text, TEXT_ALIGN_RIGHT)

    segment(sc.w(62), sc.h(943), sc.w(55), sc.h(4), 2, 5, 1, 1, c.seg_bg)
    segment(sc.w(62), sc.h(943), sc.w(55), sc.h(4), 2, 5, lerphp, mhp, c.hp_bar)

    draw.SimpleText('STAMINA', f.exo12, sc.w(62), sc.h(965), c.label)
    draw.SimpleText(math.Round(lerpst), f.orb12, sc.w(195), sc.h(965), c.white_text, TEXT_ALIGN_RIGHT)

    segment(sc.w(62), sc.h(983), sc.w(26), sc.h(3), 1, 5, 1, 1, c.seg_bg)
    segment(sc.w(62), sc.h(983), sc.w(26), sc.h(3), 1, 5, lerpst, SC.Config.Stamina.Max, c.st_bar)
    --[[        LEFT UP        ]]--
    RNDX.DrawShadows(0, sc.w(41), sc.h(34), sc.w(58), sc.h(25), c.lvl_sh, 12,12*1.2,1,rndx.BLUR)

    RNDX.Draw(0, sc.w(41), sc.h(34), sc.w(58), sc.h(25), c.lvl_bg)
    draw.SimpleText('LVL 18', f.exo_b12, sc.w(70), sc.h(40), color_white, TEXT_ALIGN_CENTER)
    draw.SimpleText(ply:GetFractionName(), f.orb2_10, sc.w(110), sc.h(34), c.frac)
    draw.SimpleText(ply:Nick(), f.exo16, sc.w(110), sc.h(41), color_white)

    RNDX.Draw(0, sc.w(45), sc.h(70), sc.w(2), sc.h(13), c.mon_sep)
    draw.SimpleText('Money: ', f.orb2_10, sc.w(55), sc.h(71), c.mon_lbl)
    
    surface.SetFont(f.orb2_10)
    local tw, _ = surface.GetTextSize('Money: ')
    draw.SimpleText(string.Comma(ply:GetMoney()) .. ' $', f.orb10, sc.w(55) + tw, sc.h(71), c.mon_val)
end
// local maxDist = 400 * 400

// hook.Add("PostDrawTranslucentRenderables", "Door_Load", function()
//     local ply = LocalPlayer()
//     if not IsValid(ply) then return end
//     local plyPos = ply:GetPos()
//     for _, door in ipairs(ents.FindByClass("prop_door_rotating")) do
//         if not IsValid(door) then continue end
//         local doorPos = door:GetPos()
//         if plyPos:DistToSqr(doorPos) > maxDist then continue end
//         local ang = door:GetAngles()
//         local ang2 = Angle(ang.p, ang.y, ang.r)
//         local offset = ang:Up() + ang:Forward() * -1.2 + ang:Right() * -23
//         ang:RotateAroundAxis(ang:Forward(), 90)
//         ang:RotateAroundAxis(ang:Right(), 90)
//         local offset2 = ang2:Up() + ang2:Forward() * 1.2 + ang2:Right() * -23
//         ang2:RotateAroundAxis(ang2:Forward(), -90)
//         ang2:RotateAroundAxis(ang2:Up(), -180)
//         ang2:RotateAroundAxis(ang2:Right(), 90)

//         cam.Start3D2D(doorPos + offset, ang, 0.07)
//             draw.SimpleText("f7ogf087e0h7hvsd8b790", "DermaDefault", 0, 0, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
//         cam.End3D2D()

//         cam.Start3D2D(doorPos + offset2, ang2, 0.07)
//             RNDX.Draw(0, -215, -143, 430, 286, sc.Color('5AA0F1'))
//             RNDX.Draw(0, -213, -137, 426, 278, sc.Color('030405'))
//         cam.End3D2D()
//     end
// end)