SC = SC or {}
SC.util = SC.util or {}
SC.cfg = SC.cfg or {}

PLAYER	= FindMetaTable 'Player'
ENTITY	= FindMetaTable 'Entity'
VECTOR	= FindMetaTable 'Vector'

DeriveGamemode("sandbox")

SC.IncludeSV = (SERVER) and include or function() end
SC.IncludeCL = (SERVER) and AddCSLuaFile or include
SC.IncludeSH = function(f) AddCSLuaFile(f) return include(f) end

SC.include = function(f)
	if string.find(f, '_sv.lua') then
		return SC.IncludeSV(f)
	elseif string.find(f, '_cl.lua') then
		return SC.IncludeCL(f)
	else
		return SC.IncludeSH(f)
	end
end
SC.include_dir = function(dir, recursive)
	local fol = dir .. '/'
	local files, folders = file.Find(fol .. '*', 'LUA')
	for _, f in ipairs(files) do
		SC.include(fol .. f)
	end
	if (recursive ~= false) then
		for _, f in ipairs(folders) do
			SC.include_dir(dir .. '/' .. f)
		end
	end
end
SC.IncludeCL('core/ui/lib/funct_cl.lua')
SC.IncludeSH('core/systems/money/money_sh.lua')
SC.IncludeSH('core/systems/hunger/hunger_sh.lua')
SC.IncludeSH('core/fractions/core/api_sh.lua')

SC.IncludeSH('core/admin/core/api_sh.lua')
SC.IncludeSH('core/admin/core/ranks_sh.lua')
SC.IncludeSV('core/admin/core/commands_sv.lua')
SC.IncludeSV('core/admin/core/notify_sv.lua')
SC.IncludeCL('core/admin/commands_cl.lua')


SC.IncludeSH('cfg/cfg.lua')
SC.IncludeSH('cfg/fractions.lua')
SC.IncludeSH('cfg/admin_ranks.lua')
SC.IncludeSH('core/systems/shop/shop_sh.lua')
SC.IncludeSH('cfg/shop.lua')
SC.IncludeSH('cfg/doors.lua')

SC.IncludeSH('core/ui/lib/rndx_cl.lua')
SC.include_dir('darkrp/gamemode/core', true)
local toolsToHide = {
    axis = true,
    balloon = true,
    ballsocket = true,
    camera = true,
    creator = true,
    duplicator = true,
    dynamite = true,
    editentity = true,
    elastic = true,
    emitter = true,
    example = true,
    eyeposer = true,
    faceposer = true,
    finger = true,
    hoverball = true,
    hydraulic = true,
    inflator = true,
    lamp = true,
    leafblower = true,
    light = true,
    motor = true,
    muscle = true,
    paint = true,
    physprop = true,
    pulley = true,
    rope = true,
    slider = true,
    thruster = true,
    trails = true,
    wheel = true,
    winch = true
}
hook.Add("PopulateToolMenu", "HideToolsFromMenu", function()
    local toolgun = weapons.GetStored("gmod_tool")
    if not toolgun or not toolgun.Tool then return end

    for name, data in pairs(toolgun.Tool) do
        if toolsToHide[name] then
            data.AddToMenu = false
        end
    end
end)
function GM:AddGamemodeToolMenuCategories()
end
