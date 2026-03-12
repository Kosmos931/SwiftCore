local svgBridge = {
    pnl = nil,
    queue = {},
    code = [[<html><body style="margin:0;padding:0;overflow:hidden;"><canvas></canvas><script>
        window.SvgBridge = (uid, svgRaw, width, height) => {
            try {
                const svgBlob = new Blob([svgRaw], {type: "image/svg+xml"});
                const svgUrl = URL.createObjectURL(svgBlob);
                const img = new Image();
                const canvas = document.querySelector("canvas");
                const ctx = canvas.getContext("2d");
                img.onload = () => {
                    canvas.width = width; canvas.height = height;
                    ctx.clearRect(0, 0, width, height);
                    ctx.drawImage(img, 0, 0, width, height);
                    const base64 = canvas.toDataURL("image/png").split(",")[1];
                    URL.revokeObjectURL(svgUrl);
                    gmod.OnSuccess(uid, base64);
                };
                img.onerror = () => gmod.OnFailed(uid, "IMG_ERR");
                img.src = svgUrl;
            } catch (err) { gmod.OnFailed(uid, err.toString()); }
        }
    </script></body></html>]]
}

file.CreateDir("svg-material")

local iconCache = {}
local downloadQueue = {}

local function GetBridgePanel()
    if IsValid(svgBridge.pnl) then return svgBridge.pnl end
    svgBridge.pnl = vgui.Create("DHTML")
    svgBridge.pnl:SetSize(200, 200)
    svgBridge.pnl:SetAlpha(0)
    svgBridge.pnl:SetHTML(svgBridge.code)
    
    svgBridge.pnl:AddFunction("gmod", "OnSuccess", function(uid, b64)
        local resp = svgBridge.queue[uid]
        if resp then
            file.Write(resp.path, util.Base64Decode(b64))
            timer.Simple(0.05, function()
                local mat = Material("data/" .. resp.path, resp.flags)
                if resp.cback then resp.cback(true, mat) end
            end)
            svgBridge.queue[uid] = nil
        end
    end)
    
    svgBridge.pnl:AddFunction("gmod", "OnFailed", function(uid, err)
        if svgBridge.queue[uid] then svgBridge.queue[uid].cback(false, err) end
        svgBridge.queue[uid] = nil
    end)
    
    return svgBridge.pnl
end

function GetSVGIcon(url, size, callback)
    if not url or url == "" then return end
    
    local id = util.CRC(url .. size)
    local urlLower = url:lower()
    local isSvg = string.find(urlLower, "%.svg") or string.find(urlLower, "svg")
    local cachePath = "svg-material/" .. id .. ".png"

    if iconCache[id] then return iconCache[id] end
    if file.Exists(cachePath, "DATA") then
        iconCache[id] = Material("data/" .. cachePath, "smooth mips")
        return iconCache[id]
    end
    if downloadQueue[id] then return nil end
    downloadQueue[id] = true

    -- Discord
    local targetURL = string.gsub(url, "format=webp", "format=png")

    http.Fetch(targetURL, function(body, len, headers, code)
        if code ~= 200 or len == 0 then 
            downloadQueue[id] = nil 
            return 
        end

        if isSvg then
            local whiteSvg = string.gsub(body, 'stroke=".-"', 'stroke="#ffffff"')
            local pnl = GetBridgePanel()
            
            svgBridge.queue[id] = {
                path = cachePath, 
                flags = "smooth mips", 
                cback = function(success, mat)
                    if success then
                        iconCache[id] = mat
                        if callback then callback(mat) end
                    end
                end
            }
            
            pnl:QueueJavascript(string.format("window.SvgBridge(%q, %q, %s, %s)", id, whiteSvg, size, size))
        else
            file.Write(cachePath, body)
            timer.Simple(0.1, function()
                local mat = Material("data/" .. cachePath, "smooth mips")
                iconCache[id] = mat
                if callback then callback(mat) end
            end)
        end
        downloadQueue[id] = nil
    end, function() 
        downloadQueue[id] = nil 
    end)

    return nil
end