local itemsinv = {
    { id = "item_1", name = "1ТЕСТ TEST", type = "misc", count = 3, color = "5DA9FF", model = "models/props_c17/FurnitureChair001a.mdl" },
    { id = "item_2", name = '2', type = "weapon", count = 1, color = "8B0000", model = "models/props_c17/FurnitureChair001a.mdl" },
    { id = "item_3", name = "3", type = "food", count = 15, color = "FFB800", model = "models/props_c17/FurnitureChair001a.mdl" },
    { id = "item_4", name = "4", type = "misc", count = 1, color = "9B5CFF", model = "models/props_c17/FurnitureChair001a.mdl" },
    { id = "item_5", name = "5", type = "food", count = 5, color = "00FF88", model = "models/props_c17/FurnitureChair001a.mdl" },
    { id = "item_6", name = "6", type = "shipment", count = 8, color = "FFFFFF", model = "models/props_c17/FurnitureChair001a.mdl" },
    { id = "item_7", name = "7", type = "food", count = 12, color = "8B0000", model = "models/props_c17/FurnitureChair001a.mdl" },
    { id = "item_8", name = "8", type = "misc", count = 1, color = "FFB800", model = "models/props_c17/FurnitureChair001a.mdl" },
    { id = "item_9", name = "9", type = "weapon", count = 2, color = "8B0000", model = "models/props_c17/FurnitureChair001a.mdl" },
    { id = "item_10", name = "10", type = "food", count = 7, color = "00FF88", model = "models/props_c17/FurnitureChair001a.mdl" },
    { id = "item_11", name = "11", type = "shipment", count = 1, color = "FFB800", model = "models/props_c17/FurnitureChair001a.mdl" },
    { id = "item_12", name = "12", type = "food", count = 10, color = "00FF88", model = "models/props_c17/FurnitureChair001a.mdl" },
    { id = "item_13", name = '13"', type = "weapon", count = 1, color = "8B0000", model = "models/props_c17/FurnitureChair001a.mdl" },
    { id = "item_14", name = "14", type = "misc", count = 1, color = "5DA9FF", model = "models/props_c17/FurnitureChair001a.mdl" },
    { id = "item_15", name = "15", type = "misc", count = 1, color = "9B5CFF", model = "models/props_c17/FurnitureChair001a.mdl" },
    { id = "item_16", name = "16", type = "weapon", count = 50, color = "8B0000", model = "models/props_c17/FurnitureChair001a.mdl" },
    { id = "item_17", name = "17", type = "food", count = 3, color = "00FF88", model = "models/props_c17/FurnitureChair001a.mdl" },
    { id = "item_18", name = "18", type = "misc", count = 1, color = "5DA9FF", model = "models/props_junk/PlasticCrate01a.mdl" },
}
local fr
if IsValid(fr) then fr:Remove() end

function GM:OnContextMenuOpen()
    if IsValid(fr) then fr:Remove() end
    
    fr = vgui.Create("EditablePanel")
    fr:SetSize(sc.w(650), sc.h(250))
    fr:SetPos(ScrW() / 2 - fr:GetWide() / 2, ScrH())
    fr:SetAlpha(0)
    fr:MakePopup()
    fr:AlphaTo(255, 0.35, 0)
    fr:MoveTo(fr:GetX(), fr:GetY() / 1.25, .2, 0, 1, function() fr:MoveTo(fr:GetX(), fr:GetY() * .95, 0.1) end)
    
    local top = vgui.Create('Panel', fr)
    top:Dock(TOP)
    top:SetTall(sc.h(36))
    top.Paint = function(self, w, h)
        sc.DrawCutBox(0, 0, w, h, sc.Color('020202', 99), sc.Color('FFFFFF', 10), sc.w(15), 1)
        draw.SimpleText('INVENTORY', sc.Font('Orbitron:8'), sc.w(45), sc.h(6), sc.Color('8B0000', 15))
        draw.SimpleText('ИНВЕНТАРЬ', sc.Font('Exo 2 Bold Italic:14'), sc.w(45), sc.h(16), sc.Color('FFFFFF'))
        
        local mat = GetSVGIcon('https://github.com/lucide-icons/lucide/blob/main/icons/package.svg?raw=true', 24)
        if mat then
            surface.SetDrawColor(sc.Color('8B0000'))
            surface.SetMaterial(mat)
            surface.DrawTexturedRect(sc.w(14), sc.h(5), sc.w(24), sc.h(24))
        end
        rndx.Draw(0,w - sc.w(150), h -sc.h(28) , sc.w(100), sc.h(22), sc.Color('000000', 60))
        rndx.Draw(0,w - sc.w(150), h -sc.h(28) , sc.w(3), sc.h(22), sc.Color('8B0000', 30))
        draw.SimpleText('SLOTS:', sc.Font('Orbitron2:6'),w - sc.w(140), h/2, sc.Color('FFFFFF',30),TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
        draw.SimpleText('18', sc.Font('Exo 2 Bold Italic:14'),w - sc.w(130) + sc.GetTextSize('SLOTS:', sc.Font('Orbitron2:6')), h/2, sc.Color('FFFFFF'),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
        draw.SimpleText(' / 50', sc.Font('Orbitron:8'),w - sc.w(125) + sc.GetTextSize('SLOTS:', sc.Font('Orbitron:6')) + sc.GetTextSize('18', sc.Font('Exo 2 Bold Italic:14')), h/2, sc.Color('FFFFFF',30),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    end
    
    local bottom = vgui.Create('Panel', fr)
    bottom:Dock(BOTTOM)
    bottom:SetTall(sc.h(30))
    bottom.Paint = function(self, w, h)
        sc.DrawCutBox(0, 0, w, h, sc.Color('020202', 99), sc.Color('FFFFFF', 10), sc.w(15))
        draw.SimpleText('ПКМ - МЕНЮ', sc.Font('Orbitron2:8'), sc.w(14), sc.h(9), sc.Color('FFFFFF', 10))
        draw.SimpleText('DRAG - ПЕРЕМЕСТИТЬ', sc.Font('Orbitron2:8'), sc.GetTextSize('ПКМ - МЕНЮ', sc.Font('Orbitron2:8')) + sc.w(14) + sc.w(15), sc.h(9), sc.Color('FFFFFF', 10))
    end

    local center = vgui.Create('Panel', fr)
    center:Dock(FILL)
    center.Paint = function(self, w, h)
        sc.DrawCutBox(0, 0, w, h, sc.Color('020202', 99), sc.Color('FFFFFF', 10), sc.w(15))
    end
    
    local scroll = vgui.Create("DScrollPanel", center)
    scroll:Dock(FILL)
    scroll:GetVBar():SetWide(0)
    scroll:DockMargin(sc.w(14), sc.h(10), sc.w(10), sc.h(10))

    local grid = vgui.Create("DIconLayout", scroll)
    grid:Dock(FILL)
    grid:SetSpaceX(sc.w(10))
    grid:SetSpaceY(sc.h(10))

    for i, item in ipairs(itemsinv) do
        local slot = grid:Add("DButton")
        slot:SetSize(sc.w(80), sc.h(96))
        slot:SetText("")
        slot.Item = item

        local mdl = vgui.Create("ModelImage", slot)
        mdl:SetSize(slot:GetWide() * 0.8, slot:GetTall() * 0.5)
        mdl:SetPos(slot:GetWide() * 0.1, sc.h(5))
        mdl:SetModel(slot.Item.model or "")
        mdl:SetMouseInputEnabled(false)

        slot:Droppable("inv_slot")
        slot:Receiver("inv_slot", function(self, panels, dropped)
            if dropped then
                local drag = panels[1]
                local tempItem = self.Item
                self.Item = drag.Item
                drag.Item = tempItem
            end
        end)

        slot.Paint = function(self, w, h)
            if self.Hovered then
                sc.DrawCutBox(0, 0, w, h, sc.Color('FFFFFF', 5), sc.Color('FFFFFF', 30), sc.w(6), false, false, false, true)
            else
                sc.DrawCutBox(0, 0, w, h, sc.Color('000000', 80), sc.Color('FFFFFF', 10), sc.w(6), false, false, false, true)
            end
            
            if self.Item then
                local itemColor = sc.Color(self.Item.color)
                surface.SetDrawColor(itemColor)
                surface.DrawRect(0, sc.h(10), sc.w(2), h - sc.h(20))
                
                draw.SimpleText(self.Item.name, sc.Font('Exo 2 SemiBold:12'), w / 2, h * 0.65, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                
                surface.SetDrawColor(sc.Color('FFFFFF', 20))
                surface.DrawRect(sc.w(10), h * 0.75, w - sc.w(20), 1)

                draw.SimpleText(self.Item.type:upper(), sc.Font('Orbitron:8'), sc.w(10), h - sc.h(16), itemColor, TEXT_ALIGN_LEFT)
                draw.SimpleText(self.Item.count, sc.Font('Orbitron:10'), w - sc.w(10), h - sc.h(18), color_white, TEXT_ALIGN_RIGHT)
            end
        end
        slot.DoClick = function(self) -- надо бы сделать через дабл клик .... мбмб
            if self.Item then
                // self.Item:Use()
                print('click')
            end
        end
        slot.DoRightClick = function(s)
            if not s.Item then return end
            if IsValid(fr_menu) then fr_menu:Remove() end
            local m = vgui.Create("EditablePanel")
            m:SetSize(sc.w(160), sc.h(120))
            m:SetPos(gui.MouseX(), gui.MouseY())
            m:MakePopup()
            fr_menu = m
            m.Paint = function(self, w, h)
                RNDX.Draw(0, 0, 0, w, h, sc.Color('020202', 98), rndx.BLUR)
                RNDX.Draw(0, 0, 0, w, h, sc.Color('020202', 80))
            end

            local function add_opt(name, col, act)
                local b = m:Add("DButton")
                b:Dock(TOP)
                b:SetTall(sc.h(28))
                b:SetText("")
                b.Paint = function(self, w, h)
                    local hover = self.Hovered
                    local tcol = hover and col or Color(255, 255, 255, 150)
                    
                    if hover then
                        RNDX.Draw(0, 0, 0, w, h, Color(col.r, col.g, col.b, 15))
                        RNDX.Draw(0, 0, 0, sc.w(2), h, col)
                    end

                    draw.SimpleText("▶", sc.Font('Orbitron Bold:10'), sc.w(10), h/2, hover and col or Color(255, 255, 255, 50), 0, 1)
                    draw.SimpleText(name:upper(), sc.Font('Exo 2 Bold:12'), sc.w(25), h/2, tcol, 0, 1)
                end
                b.DoClick = function() act() m:Remove() end
            end

            local function line()
                local p = m:Add("Panel")
                p:Dock(TOP)
                p:SetTall(sc.h(5))
                p.Paint = function(self, w, h)
                    surface.SetDrawColor(sc.Color('FFFFFF', 5))
                    surface.DrawRect(sc.w(10), h/2, w - sc.w(20), 1)
                end
            end

            add_opt("Использовать", sc.Color('00FF88'), function() print("Использовать " .. s.Item.name) end)
            line()
            add_opt("Бросить 1", sc.Color('FFFFFF'), function() print("Выкинуть 1 штучку") end)
                
            // if s.Item.count > 1 then
            //     add_opt("Бросить все ("..s.Item.count..")", sc.Color('FFFFFF'), function() print("Drop All") end) -- не надо оно как будто бы
            // end
            
            line()
            add_opt("Удалить", sc.Color('8B0000'), function() print("Удалить") end)

            local H = 0
            for _, v in ipairs(m:GetChildren()) do H = H + v:GetTall() end
            m:SetTall(H + sc.h(2))
            m.OnFocusChanged = function(self, f)
                if not f then self:Remove() end
            end
        end
    end

end
function GM:OnContextMenuClose()
    if IsValid(fr) then
        fr:Remove()
    end
    if IsValid(fr_menu) then
        fr_menu:Remove()
    end
end