GM.Name = "DarkRP"
GM.Author = "Swifter"
GM.Team = "SwiftRP"
GM.ServerName = "SwiftCore"
GM.Version = "1.0.0"

AddCSLuaFile('cl_init.lua')
AddCSLuaFile('sh_init.lua')
include('sh_init.lua')
function SC.AddFastDLDir(dir)
	local Dir = (GM or GAMEMODE).Folder .. "/content/" .. dir .. "/*"
	local Files, Folders = file.Find(Dir, "GAME")
	// Msg("Adding recursive FastDL for directory -> ", Dir)
	for k, v in next, Folders do
		SC.AddFastDLDir(dir .. "/" .. v)
	end
	for k, v in next, Files do
		if not v:find(".", 1, true) then continue end
		resource.AddFile(dir .. "/" .. v)
	end

end

SC.AddFastDLDir("resource")

function GM:ShowHelp() end
function GM:GetFallDamage( ply, speed )
	return ( speed / 8 )
end

function GM:PlayerSpawn( ply )
    if not IsValid(ply) then return end
    
    player_manager.SetPlayerClass(ply, "player_default")
    if not SC.FGet then return end
    
    local function GetBaseFractionName()
        return (SC.FBase and SC.FBase()) or "citizen"
    end
    
    local data = SC.DBGet and SC.DBGet(ply)
    local fractionName = nil
    
    if data and data.fraction then
        fractionName = data.fraction
    elseif ply:GetFraction() then
        fractionName = ply:GetFraction()
    else
        fractionName = GetBaseFractionName()
    end
    
    local fraction = SC.FGet(fractionName)
    if not fraction then 
        fractionName = GetBaseFractionName()
        fraction = SC.FGet(fractionName)
        if not fraction then return end
    end
    
    if SC.FSpawn then
        local spawnPos, spawnAng = SC.FSpawn(fraction)
        if spawnPos then
            ply:SetPos(spawnPos)
            ply:SetEyeAngles(spawnAng or Angle(0, 0, 0))
        end
    end
    
    if SC.FSetPly then
        SC.FSetPly(ply, fractionName)
    end

    if fraction.SpawnHooks then
        for _, fn in ipairs(fraction.SpawnHooks) do
            if isfunction(fn) then
                fn(ply, fraction)
            end
        end
    end
end

function GM:PlayerDeath( ply, inflictor, attacker )
	if not IsValid(ply) then return end
	
	ply.NextSpawnTime = CurTime() + 2
	ply.DeathTime = CurTime()

    if not SC.FGetPly then return end
    
    local fractionName = SC.FGetPly(ply)
    if not fractionName then return end
    
    local fraction = SC.FGet(fractionName)
    if not fraction then return end

    if fraction.DeathHooks then
        for _, fn in ipairs(fraction.DeathHooks) do
            if isfunction(fn) then
                fn(ply, fraction)
            end
        end
    end
end
local remove = {
	['prop_physics'] = true,
	['prop_physics_multiplayer'] = true,
	['prop_ragdoll'] = true,
	['ambient_generic'] = true,
	['func_tracktrain'] = true,
	['func_reflective_glass'] = true,
	['info_player_terrorist'] = true,
	['info_player_counterterrorist'] = true,
	['env_soundscape'] 	= true,
	['point_spotlight'] = true,
	['ai_network'] 		= true,

	['lua_run'] 			= true,
	['logic_timer'] 		= true,
	['trigger_multiple']	= true
}

function GM:InitPostEntity()
	local physData 								= physenv.GetPerformanceSettings()
	physData.MaxVelocity 						= 1000
	physData.MaxCollisionChecksPerTimestep		= 10000
	physData.MaxCollisionsPerObjectPerTimestep 	= 2
	physData.MaxAngularVelocity					= 3636

	physenv.SetPerformanceSettings(physData)

	game.ConsoleCommand("sv_allowcslua 0\n")
	game.ConsoleCommand("physgun_DampingFactor 0.9\n")
	game.ConsoleCommand("sv_sticktoground 0\n")
	game.ConsoleCommand("sv_airaccelerate 100\n")

	for _, ent in ipairs(ents.GetAll()) do
		if remove[ent:GetClass()] then
			ent:Remove()
		end
    end

    for k, v in ipairs(ents.FindByClass('info_player_start')) do
		if util.IsInWorld(v:GetPos()) and (not self.SpawnPoint) then
			self.SpawnPoint = v
		else
			v:Remove()
		end
	end
end