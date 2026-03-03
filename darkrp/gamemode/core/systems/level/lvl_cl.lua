--
net.Receive("SC.LevelUp", function()
    local lvl = net.ReadInt(32)
    
    notification.AddLegacy({
        sc.Color('FFFFFF'), "Уровень повышен! Теперь вы ", 
        sc.Color('00FF00'), tostring(lvl), 
        sc.Color('FFFFFF'), " уровня!"
    }, 0, 5)
end)