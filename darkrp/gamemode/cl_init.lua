include('sh_init.lua')

local noDraw = {
    CHudHealth = true,
    CHudBattery = true,
    CHudSuitPower = true,
    // CHudAmmo = true,
    // CHudSecondaryAmmo = true,
    CHudCrosshair = true
}

function GM:HUDShouldDraw(name)
    if noDraw[name] or ((name == 'CHudDamageIndicator') and (not LocalPlayer():Alive())) then return false end
    return true
end
function GM:InitPostEntity() local c = LocalPlayer() c:ConCommand('stopsound') end
