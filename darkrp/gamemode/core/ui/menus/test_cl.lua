--

local PANEL = {}

function PANEL:Init()
    self:SetSize(sc.w(1337), sc.h(774))
    self:Center()
    self:MakePopup()

end

function PANEL:Paint(w, h)
    rndx.Draw(sc.h(15), 0, 0, w, h, nil, rndx.BLUR)
    rndx.Draw(sc.h(15), 0, 0, w, h, sc.Color('161616', 86))
    rndx.Draw(sc.h(3), sc.w(116), sc.h(34), sc.w(47), sc.h(19), sc.Color('238D64'))
    draw.SimpleText('Menu', sc.Font('Default:12'), sc.w(124), sc.h(37), color_white)
    draw.SimpleText('Arena', sc.Font('Default:27'), sc.w(34), sc.h(27), color_white)
end

vgui.Register('SC.Frame', PANEL, 'EditablePanel')

for k, v in pairs(vgui.GetAll()) do
    if v:GetName() == 'SC.Frame' then
        v:Remove()
    end
end
// local DEBUG = vgui.Create('SC.Frame')