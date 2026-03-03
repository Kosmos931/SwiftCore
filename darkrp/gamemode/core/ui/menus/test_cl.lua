local PANEL = {}

function PANEL:Init()
    self:SetSize(ScrW(), ScrH())
    self:Center()
    self:MakePopup()
    self:Add('SC.Header')
end

function PANEL:Paint(w, h)
    rndx.Draw(0, 0, 0, w, h, sc.Color('070709'))
end

vgui.Register('SC.Frame', PANEL, 'EditablePanel')

local PANEL = {}

function PANEL:Init()
    self:Dock(TOP)
    self:SetTall(sc.h(60))
    self:DockMargin(0,0,0,0)
    self:Add('SC.HeaderBlock')
    self:Add('SC.HeaderBlockButton'):SETText('1213'):SETimg('123'):ISActive(true)
    self:Add('SC.HeaderBlockButton'):SETText('12113'):ISActive(false)

end

function PANEL:Paint(w, h)
    rndx.Draw(0, 0, 0, w, h, sc.Color('050606'))
end

vgui.Register('SC.Header', PANEL, 'Panel')

local PANEL = {}

function PANEL:Init()
    self:Dock(LEFT)
    self:SetWidth(sc.w(200))
    self:DockMargin(0,0,0,0)
end

function PANEL:Paint(w, h)
    draw.SimpleText('ЛИЧНЫЙ ТЕРМИНАЛ', sc.Font('Exo 2 Black Italic:20'), w/2,h/2,color_white,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
end

vgui.Register('SC.HeaderBlock', PANEL, 'Panel')

local function boxwithcut(x, y, w, h, bg,line,cutz)
    local vertices = {
        { x = x, y = y },
        { x = x + w - cutz, y = y },
        { x = x + w, y = y + cutz },
        { x = x + w, y = y + h },
        { x = x + cutz, y = y + h },
        { x = x, y = y + h - cutz },
    }

    surface.SetDrawColor(bg)
    draw.NoTexture()
    surface.DrawPoly(vertices)
    surface.SetDrawColor(line)
    surface.DrawRect(x + w - 2, y + cutz, 2, h - cutz)
end

local PANEL = {}

function PANEL:Init()
    self:Dock(LEFT)
    self:SetWidth(sc.w(200))
    self:DockMargin(0,0,sc.w(15),0)
    self:SetText('')
    self.TEXT = '1'
    self.IMG = '1'
    self.ISActve = false
    self.alpha = 25
end

function PANEL:SETText(text)
    self.TEXT = text
    return self
end

function PANEL:SETimg(img)
    self.IMG = img
    return self
end
function PANEL:ISActive(s)
    self.ISActive = s
    return self
end
function PANEL:PerformLayout()
    self:SetWidth(sc.GetTextSize(self.TEXT, sc.Font('Exo 2 Black Italic:20'))+sc.w(40))
end

function PANEL:Paint(w, h)

    if self:IsHovered() and not self.ISActive then self.alpha = sc.lerpvalue(self.alpha, 25, 100) else self.alpha = sc.lerpvalue(self.alpha, 100, 25) end
    boxwithcut(0,0+h/3,w,sc.h(20), self.ISActive and sc.Color('8B0000',13) or sc.Color('212121',25), self.ISActive and sc.Color('8B0000') or sc.Color('FFFFFF',0), 8)
    draw.SimpleText(self.TEXT, sc.Font('Exo 2 Bold Italic:14'), w/2 + sc.w(10),h/2,self.ISActive and sc.Color('FFFFFF',self.alpha) or sc.Color('FFFFFF',self.alpha),TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end
function PANEL:DoClick()
    if self.ISActive then
        self.ISActive = false
    else
        self.ISActive = true
    end
end
vgui.Register('SC.HeaderBlockButton', PANEL, 'Button')


for k, v in pairs(vgui.GetAll()) do
    if v:GetName() == 'SC.Frame' then
        v:Remove()
    end
end
// local DEBUG = vgui.Create('SC.Frame')
