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

SC.IncludeSH('core/systems/money/money_sh.lua')
SC.IncludeSH('core/systems/hunger/hunger_sh.lua'
)
SC.IncludeSH('core/fractions/core/api_sh.lua')

SC.IncludeSH('core/admin/core/api_sh.lua')
SC.IncludeSH('core/admin/core/ranks_sh.lua')
SC.IncludeSV('core/admin/core/commands_sv.lua')
SC.IncludeSV('core/admin/core/notify_sv.lua')
SC.IncludeCL('core/admin/commands_cl.lua')


SC.IncludeSH('cfg/cfg.lua')
SC.IncludeSH('cfg/fractions.lua')
SC.IncludeSH('cfg/admin_ranks.lua')
SC.IncludeSH('cfg/shop.lua')

SC.IncludeSH('core/ui/lib/rndx_cl.lua')
SC.include_dir('darkrp/gamemode/core', true)
// local toolsWhitelist = {
//     ["weld"] = {
//         ["root"] = true,
//         ["admin"] = true,
//         ["vip"] = true
//     },
//     ["axis"] = {
//         ["root"] = true
//     },
//     ["dynamite"] = {
//         ["root"] = true,
//         ["admin"] = true
//     }
// }

// hook.Add("InitPostEntity", "HideWhitelistedTools", function()
//     for toolName, allowedGroups in pairs(toolsWhitelist) do
//         if weapons.GetStored("gmod_tool") and weapons.GetStored("gmod_tool").Tool[toolName] then
//             weapons.GetStored("gmod_tool").Tool[toolName].AddToMenu = false
//         end
//     end
// end)
// local tools = {
//     ["weld"] = {
//         ["root"] = true,
//         ["admin"] = true,
//         ["vip"] = true
//     },
//     ["axis"] = {
//         ["root"] = true
//     },
//     ["dynamite"] = {
//         ["root"] = true,
//         ["admin"] = true
//     }
// }

// hook.Add("CanTool", "AdvancedToolRestrict", function(ply, _, tool)
//     local toolData = tools[tool]
//     if toolData then
//         local userGroup = ply:GetAdminRank() and ply:GetAdminRank():lower() or "unknown"
//         if not toolData[userGroup] then
//             print(string.format("[TOOLS] %s (%s) пытался использовать запрещенный инструмент: %s", ply:Nick(), userGroup, tool))
//             ply:ChatPrint("🚫 Доступ к инструменту '" .. tool .. "' запрещен для группы '" .. userGroup .. "'")
//             return false
//         end
//         print(string.format("[TOOLS] %s (%s) использовал инструмент: %s", ply:Nick(), userGroup, tool))
//     end
    
//     return true
// end)