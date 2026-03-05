local maxDistSqr = 400 * 400

local DOOR_CLASSES = {
    prop_door_rotating = true,
    func_door = true,
    func_door_rotating = true
}

local nearbyDoors = {}
local lastCheckPos = Vector(0,0,0)
local doorData = {}

local IsValid = IsValid
local RealTime = RealTime
local LocalPlayer = LocalPlayer
local ents_FindInSphere = ents.FindInSphere
local cam_Start3D2D = cam.Start3D2D
local cam_End3D2D = cam.End3D2D
local draw_SimpleText = draw.SimpleText
local string_Explode = string.Explode
local math_min = math.min
local math_max = math.max
local table_insert = table.insert
local string_match = string.match
local hook_Add = hook.Add
local hook_Run = hook.Run

local function doortext(pos, ang, lines, lineCount, side)
    local offset = ang:Up() + ang:Forward() * (side * -1.2) + ang:Right() * -23
    local drawAng = Angle(ang.p, ang.y, ang.r)
    
    if side > 0 then
        drawAng:RotateAroundAxis(drawAng:Forward(), 90)
        drawAng:RotateAroundAxis(drawAng:Right(), 90)
    else
        drawAng:RotateAroundAxis(drawAng:Forward(), -90)
        drawAng:RotateAroundAxis(drawAng:Up(), -180)
        drawAng:RotateAroundAxis(drawAng:Right(), 90)
    end

    local font = sc and sc.Font and sc.Font("Exo 2 SemiBold:55") or "Default"
    local yOffset = -60
    
    cam_Start3D2D(pos + offset, drawAng, 0.07)
        for i = 1, lineCount do
            draw_SimpleText(lines[i], font, 0, yOffset + i * 35, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    cam_End3D2D()
end

hook_Add("PostDrawTranslucentRenderables", "SC_DrawDoorInfo", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local plyPos = ply:GetPos()
    local currentTime = RealTime()
    local viewDir = ply:GetAimVector()
    if plyPos:DistToSqr(lastCheckPos) > 10000 or (currentTime % 1 < 0.05 and #nearbyDoors == 0) then
        nearbyDoors = {}
        lastCheckPos = plyPos
        
        local ents = ents_FindInSphere(plyPos, 400)
        for i = 1, #ents do
            local ent = ents[i]
            if IsValid(ent) and DOOR_CLASSES[ent:GetClass()] then
                table_insert(nearbyDoors, ent)
            end
        end
    end

    if #nearbyDoors == 0 then return end
    
    local plyShootPos = ply:GetShootPos()

    for i = 1, #nearbyDoors do
        local ent = nearbyDoors[i]
        if not IsValid(ent) then 
            doorData[ent:EntIndex()] = nil
            continue 
        end
        
        local entPos = ent:GetPos()
        if plyPos:DistToSqr(entPos) > maxDistSqr then continue end
        
        local entIdx = ent:EntIndex()
        local data = doorData[entIdx]

        if not data or data.lastUpdate + 1.0 < currentTime then
            local owner = ent:GetNWEntity("SC_DoorOwner")
            local coStr = ent:GetNWString("SC_DoorCoOwners", "")
            
            data = {
                title = ent:GetNWString("SC_DoorTitle", ""),
                fraction = ent:GetNWString("SC_DoorFraction", ""),
                owner = owner,
                owned = ent:GetNWBool("SC_DoorOwned", false),
                price = ent:GetNWInt("SC_DoorPrice", 250),
                co = ent:GetNWInt("SC_DoorCoOwnerCount", 0),
                coNames = coStr ~= "" and string_Explode(",", coStr) or {},
                lastUpdate = currentTime,
                ownerName = IsValid(owner) and owner:Nick() or "",
                buyable = ent:GetNWBool("SC_DoorBuyable", true)
            }
            
            doorData[entIdx] = data
        end

        local doorDir = ent:GetAngles():Forward()
        local side = viewDir:Dot(doorDir) > 0 and 1 or -1

        local lines = {}
        local lineCount = 0
        
        if data.title ~= "" then
            lineCount = lineCount + 1
            lines[lineCount] = data.title
        end
        
        if data.owned and IsValid(data.owner) then
            lineCount = lineCount + 1
            lines[lineCount] = "Владелец: " .. data.ownerName
            
            if #data.coNames > 0 then
                lineCount = lineCount + 1
                lines[lineCount] = "Совладельцы:"
                
                local maxCo = math_min(#data.coNames, 4)
                for j = 1, maxCo do
                    lineCount = lineCount + 1
                    lines[lineCount] = "• " .. data.coNames[j]
                end
                
                if #data.coNames > 4 then
                    lineCount = lineCount + 1
                    lines[lineCount] = "...и еще " .. (#data.coNames - 4)
                end
            end
        elseif data.buyable then
            lineCount = lineCount + 1
            lines[lineCount] = "Стоимость: $" .. data.price
        end

        if lineCount > 0 then
            doortext(entPos, ent:GetAngles(), lines, lineCount, side)
        end
    end
end)

hook_Add("OnEntityRemoved", "SC_CleanDoorCache", function(ent)
    if ent and DOOR_CLASSES[ent:GetClass()] then
        doorData[ent:EntIndex()] = nil
    end
end)


hook_Add("InitPostEntity", "SC_ClearDoorCache", function()
    doorData = {}
    nearbyDoors = {}
end)

hook_Add("ShutDown", "SC_CleanupDoorCache", function()
    doorData = {}
    nearbyDoors = {}
end)