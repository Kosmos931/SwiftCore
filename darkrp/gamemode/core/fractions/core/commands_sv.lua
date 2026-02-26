concommand.Add("sc_listfractions", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    local Frac = SC.Frac or SC.Fractions
    if not Frac or not Frac.Teams then
        ply:ChatPrint("Ошибка: система фракций не загружена!")
        return
    end
    
    ply:ChatPrint("=== Доступные фракции ===")
    local count = 0
    for name, fraction in pairs(Frac.Teams) do
        if fraction and fraction.DisplayName then
            ply:ChatPrint(name .. " - " .. fraction.DisplayName)
            count = count + 1
        end
    end
    
    if count == 0 then
        ply:ChatPrint("Фракции не найдены!")
    end
end)
