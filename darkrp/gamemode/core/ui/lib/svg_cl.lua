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
            local mat = Material("data/" .. resp.path, resp.flags)
            resp.cback(true, mat)
            svgBridge.queue[uid] = nil
        end
    end)
    svgBridge.pnl:AddFunction("gmod", "OnFailed", function(uid, err)
        if svgBridge.queue[uid] then svgBridge.queue[uid].cback(false, err) end
        svgBridge.queue[uid] = nil
    end)
    return svgBridge.pnl
end

function SvgStringToMaterial(svgContent, width, height, cback, flags)
    local uid = util.CRC(svgContent .. width .. height)
    local outPath = "svg-material/" .. uid .. ".png"

    if file.Exists(outPath, "DATA") then
        return cback(true, Material("data/" .. outPath, flags))
    end

    local pnl = GetBridgePanel()
    svgBridge.queue[uid] = {cback = cback, flags = flags, path = outPath}
    
    timer.Simple(0.2, function()
        if IsValid(pnl) then
            pnl:QueueJavascript(string.format("window.SvgBridge(%q, %q, %s, %s)", uid, svgContent, width, height))
        end
    end)
end

local iconCache = {}
local downloadQueue = {}

function GetSVGIcon(url, size, callback)
    local id = util.CRC(url .. size)
    local cachePath = "svg-material/" .. id .. ".png"

    if iconCache[id] then return iconCache[id] end
    if file.Exists(cachePath, "DATA") then
        iconCache[id] = Material("data/" .. cachePath, "smooth mips")
        return iconCache[id]
    end

    if downloadQueue[id] then return nil end
    downloadQueue[id] = true

    http.Fetch(url, function(body, len, headers, code)
        if code ~= 200 or len == 0 then
            downloadQueue[id] = nil
            return
        end
        local whiteSvg = string.gsub(body, 'stroke=".-"', 'stroke="#ffffff"')
        SvgStringToMaterial(whiteSvg, size, size, function(success, mat)
            downloadQueue[id] = nil
            if success then
                iconCache[id] = mat
                if callback then callback(mat) end
            end
        end, "smooth mips") --noclamp smooth
    end, function() downloadQueue[id] = nil end)

    return nil
end
