local notify = notify or {}

function notification.AddLegacy(text, type, time)
    time = time or 5
    
    local w = 0
    if istable(text) then
        for _, v in ipairs(text) do
            if isstring(v) then w = w + sc.GetTextSize(v, sc.Font('Exo 2 SemiBold:14')) end
        end
    else
        w = sc.GetTextSize(text, sc.Font('Exo 2 SemiBold:14'))
    end

    local pnl = vgui.Create("DPanel")
    pnl:SetSize(w + sc.w(55), sc.h(32)) 

    table.insert(notify, pnl)
    pnl:SetPos(0, sc.h(200) + ((table.KeyFromValue(notify, pnl) - 1) * (pnl:GetTall() + 8)))
    pnl:SetAlpha(0)
    pnl:AlphaTo(255, 0.3)
    pnl:MoveTo(20, pnl:GetY(), 0.3) 

    local ttext = CreateTypingText(text, {
        x = 25,
        y = pnl:GetTall() / 2,
        font = sc.Font('Exo 2 SemiBold:14'),
        delay = 0.01,
        autoStart = true
    })
    
    pnl.Paint = function(self, w, h)
        RNDX.Draw(0, 0, 0, w, h, sc.Color('050605', 80))
        RNDX.Draw(0, 0, 0, 2, h, sc.Color('8B0000'))
        draw.SimpleText("!", sc.Font('Orbitron Bold:12'), 10, h/2, sc.Color('8B0000'), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        ttext.config.y = h / 2
        ttext:Draw()
    end

    timer.Simple(time, function()
        if IsValid(pnl) then
            pnl:MoveTo(0, pnl:GetY() + 10, 0.3) 
            pnl:AlphaTo(0, 0.3, 0, function()
                table.RemoveByValue(notify, pnl)
                if IsValid(pnl) then pnl:Remove() end
                for k, v in ipairs(notify) do
                    if IsValid(v) then 
                        v:MoveTo(20, sc.h(200) + ((k - 1) * (v:GetTall() + 8)), 0.2) 
                    end
                end
            end)
        end
    end)
end
// timer.Simple(0.1, function()
//     for i = 1, 15 do
//         timer.Simple(i * 0.2, function()
//             notification.AddLegacy("Вы купили за много денег #" .. i, i, 1)
//         end)
//     end

//     notification.AddLegacy({
//         Color(255,255,255), "До. передал вам ", 
//         Color(0,255,0), "10000$ ", 
//         Color(255,255,255), "!"
//     }, 0, 5)
// end)