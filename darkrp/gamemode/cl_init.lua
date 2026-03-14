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
local GUIToggled = false
local mouseX, mouseY = ScrW() / 2, ScrH() / 2
function GM:ShowSpare1()
	GUIToggled = not GUIToggled

	if GUIToggled then
		gui.SetMousePos(mouseX, mouseY)
	else
		mouseX, mouseY = gui.MousePos()
	end
	gui.EnableScreenClicker(GUIToggled)
end

local FKeyBinds = {
	["gm_showhelp"] = "ShowHelp",
	["gm_showteam"] = "ShowTeam",
	["gm_showspare1"] = "ShowSpare1",
	["gm_showspare2"] = "ShowSpare2"
}

function GM:PlayerBindPress(ply, bind, pressed)
	local bnd = string.match(string.lower(bind), "gm_[a-z]+[12]?")
	if bnd and FKeyBinds[bnd] and GAMEMODE[FKeyBinds[bnd]] then
		GAMEMODE[FKeyBinds[bnd]](GAMEMODE)
	end
	return
end