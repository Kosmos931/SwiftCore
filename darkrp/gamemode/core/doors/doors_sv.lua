if not SERVER then return end

SC = SC or {}
SC.Doors = SC.Doors or {}

local map = game.GetMap()
local path = "sc_doors/" .. map .. ".json"

if not file.Exists("sc_doors", "DATA") then
    file.CreateDir("sc_doors")
end

local doorGroups = {}
if file.Exists(path, "DATA") then
    doorGroups = util.JSONToTable(file.Read(path, "DATA")) or {}
end

local doorClasses = {
    prop_door_rotating = true,
    func_door = true,
    func_door_rotating = true
}

local function isDoor(ent)
    if not IsValid(ent) then return false end
    return doorClasses[ent:GetClass()] == true
end

local function getData(ent)
    if not ent.SC_Data then
        ent.SC_Data = {
            owner = nil,
            coowners = {},
            title = "",
            fraction = nil,
            buyable = true,
            price = SC.Config.Doors.DefaultPrice or 250,
            group = doorGroups[ent:MapCreationID()]
        }
    end

    return ent.SC_Data
end

function SC.Doors.HasAccess(ply, ent)
    if not IsValid(ply) or not IsValid(ent) then return false end
    if not isDoor(ent) then return false end

    local data = getData(ent)
    if data.owner == ply then return true end
    if data.coowners and data.coowners[ply:SteamID64()] then
        return true
    end
    if data.fraction and ply.GetFraction and ply:GetFraction() == data.fraction then
        return true
    end

    if not IsValid(data.owner) and (not data.fraction or data.fraction == "") then
        return false
    end

    return false
end

local function sync(ent)
    local d = getData(ent)

    ent:SetNWBool("SC_DoorOwned", IsValid(d.owner))
    ent:SetNWEntity("SC_DoorOwner", d.owner or NULL)
    ent:SetNWString("SC_DoorTitle", d.title or "")
    ent:SetNWString("SC_DoorFraction", d.fraction or "")
    ent:SetNWBool("SC_DoorBuyable", d.buyable)
    ent:SetNWInt("SC_DoorPrice", d.price or 250)
    local coNames = {}
    for sid64, _ in pairs(d.coowners or {}) do
        local p = player.GetBySteamID64(sid64)
        if IsValid(p) then
            table.insert(coNames, p:Nick())
        end
    end
    
    ent:SetNWString("SC_DoorCoOwners", table.concat(coNames, ","))
    ent:SetNWInt("SC_DoorCoOwnerCount", #coNames)
end

function SC.Doors.GetGroupDoors(ent)
    local id = ent:MapCreationID()
    local group = doorGroups[id]

    if not group then
        return { ent }
    end

    local result = {}

    for _, e in ipairs(ents.GetAll()) do
        if isDoor(e) then
            if doorGroups[e:MapCreationID()] == group then
                table.insert(result, e)
            end
        end
    end

    return result
end

local function getLookDoor(ply)
    local tr = ply:GetEyeTrace()
    if not IsValid(tr.Entity) then return end
    if not isDoor(tr.Entity) then return end

    if ply:GetPos():DistToSqr(tr.Entity:GetPos()) > (SC.Config.Doors.UseDistanceSqr or 40000) then
        return
    end

    return tr.Entity
end

local function initDoors()
    for _, ent in ipairs(ents.GetAll()) do
        if not isDoor(ent) then continue end

        local data = getData(ent)

        local static = SC.Config.Doors.StaticDoors and SC.Config.Doors.StaticDoors[map]
        if static and static[ent:MapCreationID()] then
            local row = static[ent:MapCreationID()]

            data.title = row.title or data.title
            data.fraction = row.fraction or data.fraction
            if row.buyable ~= nil then
                data.buyable = row.buyable
            end
            data.price = row.price or data.price
        end

        sync(ent)
    end
end

hook.Add("InitPostEntity", "SC_Doors_Init", function()
    timer.Simple(3, initDoors)
end)

hook.Add("PostCleanupMap", "SC_Doors_Reset", initDoors)

hook.Add("PlayerDisconnected", "SC_Doors_Cleanup", function(ply)
    local sid64 = ply:SteamID64()
    for _, ent in ipairs(ents.GetAll()) do
        if not isDoor(ent) then continue end
        local data = getData(ent)
        
        if data.owner == ply then
            data.owner = nil
            data.coowners = {}
            data.title = ""
            sync(ent)
        elseif data.coowners[sid64] then
            data.coowners[sid64] = nil
            sync(ent)
        end
    end
end)

local cmd = SC.AdminCommands

local function notify(ply, msg)
    if SC.Admin and SC.Admin.Notify then
        SC.Admin.Notify.Send(ply, msg)
    elseif IsValid(ply) and ply:IsPlayer() then
        ply:ChatPrint(msg)
    else
        print("[SC] " .. msg)
    end
end

local function notifyErr(ply, msg)
    if SC.Admin and SC.Admin.Notify then
        SC.Admin.Notify.Error(ply, msg)
    else
        notify(ply, "ОШИБКА: " .. msg)
    end
end

cmd.Create("door_buy", function(ply)
    local door = getLookDoor(ply)
    local data = getData(door)
    
    if IsValid(data.owner) then 
        notifyErr(ply, "Дверь куплена.")
        return 
    end

    if data.buyable == false then
        return
    end

    if data.fraction and data.fraction ~= "" then 
        return 
    end
    
    if not ply:HasMoney(data.price) then 
        notifyErr(ply, "Недостаточно денег! Нужно: " .. data.price)
        return 
    end

    local groupDoors = SC.Doors.GetGroupDoors(door)
    ply:TakeMoney(data.price)

    for _, d in ipairs(groupDoors) do
        local doorData = getData(d)
        doorData.owner = ply
        doorData.coowners = {}
        sync(d)
    end

    notify(ply, "Вы купили дверь за " .. data.price)
end)

cmd.Create("door_sell", function(ply)
    local door = getLookDoor(ply)
    if not door then return end

    local data = getData(door)
    if data.owner ~= ply then 
        notifyErr(ply, "Вы не владелец этой двери!")
        return 
    end

    local groupDoors = SC.Doors.GetGroupDoors(door)
    local refund = math.floor(data.price * 0.7)
    ply:AddMoney(refund)

    for _, d in ipairs(groupDoors) do
        local doorData = getData(d)
        doorData.owner = nil
        doorData.coowners = {}
        doorData.title = ""
        sync(d)
    end

    notify(ply, "Дверь продана. Возврат: " .. refund)
end)

cmd.Create("door_setgroup", function(ply, args)
    local door = getLookDoor(ply)
    if not door then return end

    local name = args.group_name
    local id = door:MapCreationID()

    doorGroups[id] = name
    file.Write(path, util.TableToJSON(doorGroups, true))

    getData(door).group = name
    
    for _, d in ipairs(ents.GetAll()) do
        if isDoor(d) and d:MapCreationID() == id then sync(d) end
    end

    notify(ply, string.format("Группа '%s' установлена для двери ID: %d", name, id))
end)
:AddParam('string', 'group_name')
:SetFlag('a')
:SetHelp('Привязать дверь к категории')
:SetIcon('icon16/key.png')

cmd.Create("door_removegroup", function(ply)
    local door = getLookDoor(ply)
    if not door then return end

    local id = door:MapCreationID()
    doorGroups[id] = nil
    file.Write(path, util.TableToJSON(doorGroups, true))

    getData(door).group = nil
    sync(door)

    notify(ply, "Категория двери удалена.")
end)
:SetFlag('a')
:SetHelp('Удалить категорию у двери')
:SetIcon('icon16/key_delete.png')

cmd.Create("door_addco", function(ply, args)
    local door = getLookDoor(ply)
    if not door then return end

    local data = getData(door)
    if data.owner ~= ply then 
        notifyErr(ply, "Вы не владелец!")
        return 
    end

    local target = args.target
    if target == ply then 
        notifyErr(ply, "Вы уже владелец.")
        return 
    end

    local groupDoors = SC.Doors.GetGroupDoors(door)
    for _, d in ipairs(groupDoors) do
        local doorData = getData(d)
        doorData.coowners[target:SteamID64()] = true
        sync(d)
    end

    notify(ply, "Игрок " .. target:Nick() .. " добавлен в совладельцы.")
    notify(target, "Вы стали совладельцем двери игрока " .. ply:Nick())
end)
:AddParam('player_entity', 'target')

cmd.Create("door_removeco", function(ply, args)
    local door = getLookDoor(ply)
    if not door then return end

    local data = getData(door)
    if data.owner ~= ply then return end

    local target = args.target
    local sid64 = target:SteamID64()

    if not data.coowners[sid64] then 
        notifyErr(ply, "Этот игрок не является совладельцем.")
        return 
    end

    local groupDoors = SC.Doors.GetGroupDoors(door)
    for _, d in ipairs(groupDoors) do
        local doorData = getData(d)
        doorData.coowners[sid64] = nil
        sync(d)
    end

    notify(ply, "Игрок " .. target:Nick() .. " удален из совладельцев.")
end)
:AddParam('player_entity', 'target')

cmd.Create("door_title", function(ply, args)
    local door = getLookDoor(ply)
    if not door then return end

    local data = getData(door)
    if data.owner ~= ply and not ply:IsAdmin() then 
        notifyErr(ply, "Вы не владелец!")
        return 
    end

    local newTitle = string.sub(args.text, 1, 64)
    local groupDoors = SC.Doors.GetGroupDoors(door)

    for _, d in ipairs(groupDoors) do
        local doorData = getData(d)
        doorData.title = newTitle
        sync(d)
    end

    notify(ply, "Название двери обновлено.")
end)
:AddParam('string', 'text')