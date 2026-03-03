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

local showStamina = SC.Config.Stamina.Enable

function GM:HUDPaint()
    InitResources()
    if not resources.initialized then return end
    
    local f, c = resources.fonts, resources.colors
    ply = ply or LocalPlayer()
    if not IsValid(ply) then return end
    --[[         LOCALS         ]]--
    local hp, mhp = ply:Health(), ply:GetMaxHealth()
    local ar, mar = ply:Armor(), ply:GetMaxArmor()
    local st = (showStamina and ply.GetStamina) and ply:GetStamina() or 0
    local hr = ply:GetHunger() or 0

    lerphp = sc.lerpvalue(lerphp, hp, mhp)
    lerpar = sc.lerpvalue(lerpar, ar, mar)
    lerpst = showStamina and sc.lerpvalue(lerpst, st, (SC.Config.Stamina and SC.Config.Stamina.Max or 100)) or 0
    lerphr = sc.lerpvalue(lerphr, hr, 100)
    --[[         BG         ]]--
    RNDX.DrawShadows(0, sc.w(38), sc.h(904), sc.w(327), sc.h(110), c.black25, 15, 15*1.2)
    RNDX.Draw(0, sc.w(38), sc.h(904), sc.w(327), sc.h(110), c.main_bg,rndx.BLUR)
    RNDX.Draw(0, sc.w(38), sc.h(904), sc.w(327), sc.h(110), c.main_bg)
    RNDX.Draw(0, sc.w(38), sc.h(904), sc.w(3), sc.h(110), c.red_line)
    --[[         HP         ]]--
    draw.SimpleText('HP', f.exo12, sc.w(62), sc.h(925), c.label)
    draw.SimpleText(math.Round(lerphp) .. '/' .. mhp, f.orb12, sc.w(345), sc.h(925), c.white_text, TEXT_ALIGN_RIGHT)
    segment(sc.w(62), sc.h(943), sc.w(55), sc.h(4), 2, 5, 1, 1, c.seg_bg)
    segment(sc.w(62), sc.h(943), sc.w(55), sc.h(4), 2, 5, lerphp, mhp, c.hp_bar)
    --[[         STAMINA OR ARMOR         ]]--
    draw.SimpleText(showStamina and 'STAMINA' or 'ARMOR', f.exo12, sc.w(62), sc.h(965), c.label)
    draw.SimpleText(math.Round(showStamina and lerpst or lerpar) .. (showStamina and '' or '%'), f.orb12, sc.w(195), sc.h(965), showStamina and c.white_text or c.armor, TEXT_ALIGN_RIGHT)
    segment(sc.w(62), sc.h(983), sc.w(26), sc.h(3), 1, 5, 1, 1, c.seg_bg)
    segment(sc.w(62), sc.h(983), sc.w(26), sc.h(3), 1, 5, showStamina and lerpst or lerpar, showStamina and SC.Config.Stamina.Max or mar, showStamina and c.st_bar or c.armor)
    --[[         ARMOR OR HUNGER         ]]--
    draw.SimpleText(showStamina and 'ARMOR' or 'HUNGER', f.exo10, sc.w(241), sc.h(964), c.label, TEXT_ALIGN_CENTER)
    draw.SimpleText(math.Round(showStamina and lerpar or lerphr) .. '%', f.orb12, sc.w(241), sc.h(977), showStamina and c.armor or c.hunger, TEXT_ALIGN_CENTER)
    RNDX.Draw(0, sc.w(211), sc.h(964), sc.w(2), sc.h(29), c.separator)
    --[[         HUNGER         ]]--
    local _ = showStamina and (function()
        draw.SimpleText('HUNGER', f.exo10, sc.w(304), sc.h(964), c.label, TEXT_ALIGN_CENTER)
        draw.SimpleText(math.Round(lerphr) .. '%', f.orb12, sc.w(304), sc.h(977), c.hunger, TEXT_ALIGN_CENTER)
        RNDX.Draw(0, sc.w(274), sc.h(964), sc.w(2), sc.h(29), c.separator)
    end)()
    --[[         BG         ]]--
    RNDX.DrawShadows(0, sc.w(41), sc.h(34), sc.w(58), sc.h(25), c.lvl_sh, 12, 12*1.2, 1, rndx.BLUR)
    RNDX.Draw(0, sc.w(41), sc.h(34), sc.w(58), sc.h(25), c.lvl_bg)
    --[[         INFO         ]]--
    draw.SimpleText('LVL ' .. ply:GetLevel(), f.exo_b12, sc.w(70), sc.h(40), color_white, TEXT_ALIGN_CENTER)
    draw.SimpleText(ply:GetFractionName(), f.orb2_10, sc.w(110), sc.h(34), ply:GetFractionData().Color or c.frac)
    draw.SimpleText(ply:Nick(), f.exo16, sc.w(110), sc.h(41), color_white)
    --[[         MONEY         ]]--
    RNDX.Draw(0, sc.w(45), sc.h(70), sc.w(2), sc.h(13), c.mon_sep)
    draw.SimpleText('Money: ', f.orb2_10, sc.w(55), sc.h(71), c.mon_lbl)
    draw.SimpleText(string.Comma(ply:GetMoney()) .. ' $', f.orb10, sc.w(55) + sc.GetTextSize('Money: ',f.orb2_10), sc.h(71), c.mon_val)
end
