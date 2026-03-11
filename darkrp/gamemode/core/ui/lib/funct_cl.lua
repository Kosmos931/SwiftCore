sc = sc or {}
do
    local scrw, scrh = ScrW() / 1920, ScrH() / 1080
    local cacheW = {}
    local cacheH = {}
    local cacheSize = {}

    local function h(px)
        local cached = cacheH[px]
        if cached then return cached end
        
        local value = math.Round(scrh * px)
        cacheH[px] = value
        return value
    end
    
    local function s(px)
        local cached = cacheW[px]
        if cached then return cached end
        
        local value = math.Round(scrw * px)
        cacheW[px] = value
        return value
    end

    function sc.w(value, ref)
        return s(value)
    end

    function sc.h(value, ref)
        return h(value)
    end

    function sc.getSize(w, h)
        local key = w .. ':' .. (h or w)
        local cached = cacheSize[key]
        if cached then return cached[1], cached[2] end
        
        local sw = s(w)
        local sh = h(h or w)
        cacheSize[key] = {sw, sh}
        return sw, sh
    end

    hook.Add('OnScreenSizeChanged', 'sc.ratio', function()
        scrw, scrh = ScrW() / 1920, ScrH() / 1080
        cacheW = {}
        cacheH = {}
        cacheSize = {}
    end)
end
do
    local FIGMA_RATE = 2

    local fontsCache = {}

    local string_Explode = string.Explode
    local surface_CreateFont = surface.CreateFont

    function sc.Font(name)
        local fontData = string_Explode(':', name)
        local size = math.floor(sc.h((fontData[2]) + FIGMA_RATE))

        if fontsCache[name] then 
            return name
        end

        fontsCache[name] = {
            font = fontData[1],
            extended = true,
            antialias = true,
            size = size,
        }

        surface_CreateFont(name, fontsCache[name])

        return name
    end

    hook.Add('OnScreenSizeChanged', 'sc.fonts.refresh', function()
        fontsCache = {}
    end)
end
do
    function sc.GetTextSize(text, font)
        surface.SetFont(font)
        return surface.GetTextSize(text)
    end
end
do
    local colorCache = {}

    local function hexToColor(hex, alpha)
        if #hex ~= 6 then
            error('invalid hex' .. tostring(hex))
        end

        if not alpha then
            alpha = 255
        else
            alpha = (alpha * 255) / 100
        end
        
        local cacheKey = hex .. alpha

        if colorCache[cacheKey] then
            return colorCache[cacheKey]
        end

        local color = Color(
            tonumber('0x' .. hex:sub(1,2)),
            tonumber('0x' .. hex:sub(3,4)),
            tonumber('0x' .. hex:sub(5,6)),
            alpha
        )

        colorCache[cacheKey] = color

        return color
    end

    sc.Color = hexToColor
end
do
    function sc.lerpto(l, c, s) 
        local delta = (s or 100) * FrameTime()
        return (math.Approach(l or 0, c, delta))
    end

    function sc.lerpvalue(val, current, max)
        return sc.lerpto(val, current, max) 
    end
end
do
    function sc.DrawCutBox(x, y, w, h, bg, line, cut, tl, tr, br, bl)
        local c = cut or sc.w(10)
        local poly = {}
        
        local r, b = x + w - 1, y + h - 1

        if tl then
            poly[#poly + 1] = { x = x, y = y + c }
            poly[#poly + 1] = { x = x + c, y = y }
        else
            poly[#poly + 1] = { x = x, y = y }
        end

        if tr then
            poly[#poly + 1] = { x = r - c, y = y }
            poly[#poly + 1] = { x = r, y = y + c }
        else
            poly[#poly + 1] = { x = r, y = y }
        end

        if br then
            poly[#poly + 1] = { x = r, y = b - c }
            poly[#poly + 1] = { x = r - c, y = b }
        else
            poly[#poly + 1] = { x = r, y = b }
        end

        if bl then
            poly[#poly + 1] = { x = x + c, y = b }
            poly[#poly + 1] = { x = x, y = b - c }
        else
            poly[#poly + 1] = { x = x, y = b }
        end

        surface.SetDrawColor(bg)
        draw.NoTexture()
        surface.DrawPoly(poly)

        if not line then return end
        surface.SetDrawColor(line)
        for i = 1, #poly do
            local p1 = poly[i]
            local p2 = poly[i % #poly + 1]
            surface.DrawLine(p1.x, p1.y, p2.x, p2.y)
        end
    end
    function sc.DrawDiamond(cx, cy, size, fill, line)
        surface.SetDrawColor(fill)
        draw.NoTexture()
        surface.DrawPoly({
            { x = cx, y = cy - size },
            { x = cx + size, y = cy },
            { x = cx, y = cy + size },
            { x = cx - size, y = cy }
        })

        if not line then return end
        surface.SetDrawColor(line)
        surface.DrawLine(cx, cy - size, cx + size, cy)
        surface.DrawLine(cx + size, cy, cx, cy + size)
        surface.DrawLine(cx, cy + size, cx - size, cy)
        surface.DrawLine(cx - size, cy, cx, cy - size)
    end
end