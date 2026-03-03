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
// local toolsToHide = {
//     axis = true,
//     balloon = true,
//     ballsocket = true,
//     button = false,
//     camera = true,
//     colour = false,
//     creator = true,
//     duplicator = true,
//     dynamite = true,
//     editentity = true,
//     elastic = true,
//     emitter = true,
//     example = true,
//     eyeposer = true,
//     faceposer = true,
//     finger = true,
//     hoverball = true,
//     hydraulic = true,
//     inflator = true,
//     lamp = true,
//     leafblower = true,
//     light = true,
//     material = false,
//     motor = true,
//     muscle = true,
//     nocollide = false,
//     paint = true,
//     physprop = true,
//     pulley = true,
//     remover = false,
//     rope = true,
//     slider = true,
//     thruster = true,
//     trails = true,
//     weld = false,
//     wheel = true,
//     winch = true
// }

// hook.Add( "PreReloadToolsMenu", "HideTools", function()
//     for name, data in pairs( weapons.GetStored( "gmod_tool" ).Tool ) do
//         if toolsToHide[ name ] then
//             data.AddToMenu = false
//         end
//     end
// end )
// function GM:PreRegisterTOOL( a, b)
//     for name, data in pairs( weapons.GetStored( "gmod_tool" ).Tool ) do
//         if toolsToHide[ name ] then
//             data.AddToMenu = false
//         end
//     end
// end
// hook.Add( "PreRegisterTOOL", "HideT1ools", function( a, b)
//     print(a,b)
// end )