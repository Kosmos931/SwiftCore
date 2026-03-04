if not SERVER then return end

SC.Doors = SC.Doors or {}
local doors = SC.Doors

util.AddNetworkString("SC.Doors.Notify")

local DOOR_CLASSES = {
    ["prop_door_rotating"] = true,
    ["func_door"] = true,
    ["func_door_rotating"] = true
}

local function IsDoor(ent)
    return IsValid(ent) and DOOR_CLASSES[ent:GetClass()] == true
end

local function Notify(ply, msg)
    if SC.Admin and SC.Admin.Notify and SC.Admin.Notify.Info then
        SC.Admin.Notify.Info(ply, msg)
    elseif IsValid(ply) then
        ply:ChatPrint(msg)
    end
end

local function Error(ply, msg)
    if SC.Admin and SC.Admin.Notify and SC.Admin.Notify.Error then
        SC.Admin.Notify.Error(ply, msg)
    elseif IsValid(ply) then
        ply:ChatPrint("ОШИБКА: " .. msg)
    end
end

local function Success(ply, msg)
    if SC.Admin and SC.Admin.Notify and SC.Admin.Notify.Success then
        SC.Admin.Notify.Success(ply, msg)
    elseif IsValid(ply) then
        ply:ChatPrint("✓ " .. msg)
    end
end

local function GetDoorData(door)
    if not IsDoor(door) then return nil end
    door.SC_DoorData = door.SC_DoorData or {
        owner = nil,
        ownerSteamID64 = nil,
        coowners = {},
        title = "",
        faction = nil,
        buyable = true,
        price = (SC.Config and SC.Config.Doors and SC.Config.Doors.DefaultPrice) or 250
    }
    return door.SC_DoorData
end

local function SyncDoorNW(door)
    local data = GetDoorData(door)
    if not data then return end

    door:SetNWBool("SC_DoorOwned", IsValid(data.owner))
    door:SetNWEntity("SC_DoorOwner", IsValid(data.owner) and data.owner or NULL)
    door:SetNWString("SC_DoorTitle", data.title or "")
    door:SetNWString("SC_DoorFaction", data.faction or "")
    door:SetNWBool("SC_DoorBuyable", data.buyable ~= false)
    door:SetNWInt("SC_DoorPrice", tonumber(data.price) or 0)

    local coCount = 0
    for _ in pairs(data.coowners) do
        coCount = coCount + 1
    end
    door:SetNWInt("SC_DoorCoOwnerCount", coCount)
end

local function GetPlayerFraction(ply)
    if not IsValid(ply) then return nil end
    if SC.FGetPly then return SC.FGetPly(ply) end
    if ply.GetFraction then return ply:GetFraction() end
    return nil
end

local function HasAccess(ply, door)
    local data = GetDoorData(door)
    if not data then return false end

    if IsValid(data.owner) and data.owner == ply then
        return true
    end

    local sid = ply:SteamID64()
    if sid and data.coowners[sid] then
        return true
    end

    if data.faction and data.faction ~= "" then
        return GetPlayerFraction(ply) == data.faction
    end

    return not IsValid(data.owner)
end

local function IsOwnedBySomeone(data)
    return data and IsValid(data.owner)
end

local function GetLookDoor(ply)
    if not IsValid(ply) then return nil end
    local tr = ply:GetEyeTrace()
    if not tr or not IsDoor(tr.Entity) then return nil end

    local maxDist = (SC.Config and SC.Config.Doors and SC.Config.Doors.UseDistance) or 180
    if ply:GetPos():DistToSqr(tr.Entity:GetPos()) > (maxDist * maxDist) then
        return nil
    end

    return tr.Entity
end

local function ApplySpecialDoors()
    local map = game.GetMap()
    local special = SC.Config and SC.Config.Doors and SC.Config.Doors.SpecialByMap and SC.Config.Doors.SpecialByMap[map]
    if not special then return end

    for _, ent in ipairs(ents.GetAll()) do
        if not IsDoor(ent) then continue end

        local id = ent:MapCreationID()
        local row = id and special[id]
        if not row then continue end

        local data = GetDoorData(ent)
        data.title = row.title or data.title
        data.faction = row.faction or data.faction
        if row.buyable ~= nil then
            data.buyable = row.buyable
        end
        if row.price ~= nil then
            data.price = math.max(0, math.floor(tonumber(row.price) or data.price))
        end

        SyncDoorNW(ent)
    end
end

hook.Add("InitPostEntity", "SC.Doors.SetupSpecial", function()
    timer.Simple(0.2, ApplySpecialDoors)
end)

hook.Add("PlayerInitialSpawn", "SC.Doors.SetupForSpawn", function()
    timer.Simple(1, ApplySpecialDoors)
end)

hook.Add("PlayerDisconnected", "SC.Doors.CleanOwner", function(ply)
    for _, ent in ipairs(ents.GetAll()) do
        if not IsDoor(ent) then continue end
        local data = ent.SC_DoorData
        if data and data.owner == ply then
            data.owner = nil
            data.ownerSteamID64 = nil
            data.coowners = {}
            SyncDoorNW(ent)
        end
    end
end)

hook.Add("PlayerUse", "SC.Doors.AccessControl", function(ply, ent)
    if not IsDoor(ent) then return end

    local data = GetDoorData(ent)
    if not data then return end

    if data.faction and data.faction ~= "" and GetPlayerFraction(ply) ~= data.faction and not HasAccess(ply, ent) then
        Error(ply, "Эта дверь доступна только для фракции: " .. data.faction)
        return false
    end

    if IsOwnedBySomeone(data) and not HasAccess(ply, ent) then
        Error(ply, "У вас нет доступа к этой двери.")
        return false
    end

    if ent:IsDoorLocked() and HasAccess(ply, ent) then
        ent:Fire("Unlock")
        ent:Fire("Toggle")
        timer.Simple(0.2, function()
            if IsValid(ent) then
                ent:Fire("Lock")
            end
        end)
        return false
    end
end)

local function FindPlayerByName(part)
    if not part or part == "" then return nil end
    part = string.lower(part)

    for _, ply in ipairs(player.GetAll()) do
        if string.find(string.lower(ply:Nick()), part, 1, true) then
            return ply
        end
    end

    return nil
end

concommand.Add("sc_door_buy", function(ply)
    if not IsValid(ply) then return end

    local door = GetLookDoor(ply)
    if not door then
        return Error(ply, "Наведитесь на дверь рядом с вами.")
    end

    local data = GetDoorData(door)
    if not data then return end

    if data.buyable == false then
        return Error(ply, "Эта дверь не продается.")
    end

    if data.faction and data.faction ~= "" and GetPlayerFraction(ply) ~= data.faction then
        return Error(ply, "Эта дверь доступна только фракции " .. data.faction)
    end

    if IsValid(data.owner) then
        return Error(ply, "У двери уже есть владелец.")
    end

    local price = math.max(0, math.floor(tonumber(data.price) or 0))
    if ply.HasMoney and not ply:HasMoney(price) then
        return Error(ply, "Недостаточно денег. Цена двери: " .. price)
    end

    if ply.TakeMoney and price > 0 then
        ply:TakeMoney(price)
    end

    data.owner = ply
    data.ownerSteamID64 = ply:SteamID64()
    data.coowners = {}

    SyncDoorNW(door)
    Success(ply, "Вы купили дверь за " .. price)
end)

concommand.Add("sc_door_sell", function(ply)
    if not IsValid(ply) then return end

    local door = GetLookDoor(ply)
    if not door then
        return Error(ply, "Наведитесь на дверь рядом с вами.")
    end

    local data = GetDoorData(door)
    if not data then return end

    if data.owner ~= ply then
        return Error(ply, "Вы не владелец этой двери.")
    end

    local mul = (SC.Config and SC.Config.Doors and SC.Config.Doors.SellMultiplier) or 0.7
    local refund = math.max(0, math.floor((tonumber(data.price) or 0) * mul))

    if ply.AddMoney and refund > 0 then
        ply:AddMoney(refund)
    end

    data.owner = nil
    data.ownerSteamID64 = nil
    data.coowners = {}

    SyncDoorNW(door)
    Success(ply, "Вы продали дверь и получили " .. refund)
end)

concommand.Add("sc_door_addcoowner", function(ply, _, args)
    if not IsValid(ply) then return end

    local door = GetLookDoor(ply)
    if not door then
        return Error(ply, "Наведитесь на дверь рядом с вами.")
    end

    local data = GetDoorData(door)
    if not data or data.owner ~= ply then
        return Error(ply, "Только владелец может добавлять совладельцев.")
    end

    local target = FindPlayerByName(args[1] or "")
    if not IsValid(target) then
        return Error(ply, "Игрок не найден.")
    end

    local sid = target:SteamID64()
    if not sid then
        return Error(ply, "Не удалось получить SteamID игрока.")
    end

    data.coowners[sid] = true
    SyncDoorNW(door)

    Success(ply, "Вы добавили совладельца: " .. target:Nick())
    Notify(target, "Вы стали совладельцем двери игрока " .. ply:Nick())
end)

concommand.Add("sc_door_removecoowner", function(ply, _, args)
    if not IsValid(ply) then return end

    local door = GetLookDoor(ply)
    if not door then
        return Error(ply, "Наведитесь на дверь рядом с вами.")
    end

    local data = GetDoorData(door)
    if not data or data.owner ~= ply then
        return Error(ply, "Только владелец может удалять совладельцев.")
    end

    local target = FindPlayerByName(args[1] or "")
    if not IsValid(target) then
        return Error(ply, "Игрок не найден.")
    end

    local sid = target:SteamID64()
    if not sid or not data.coowners[sid] then
        return Error(ply, "Этот игрок не является совладельцем.")
    end

    data.coowners[sid] = nil
    SyncDoorNW(door)

    Success(ply, "Вы удалили совладельца: " .. target:Nick())
    Notify(target, "Вы больше не совладелец двери игрока " .. ply:Nick())
end)

concommand.Add("sc_door_title", function(ply, _, args, argStr)
    if not IsValid(ply) then return end

    local door = GetLookDoor(ply)
    if not door then
        return Error(ply, "Наведитесь на дверь рядом с вами.")
    end

    local data = GetDoorData(door)
    if not data or data.owner ~= ply then
        return Error(ply, "Только владелец может менять надпись двери.")
    end

    local text = string.Trim(argStr or "")
    if #text > 64 then
        text = string.sub(text, 1, 64)
    end

    data.title = text
    SyncDoorNW(door)

    Success(ply, "Надпись двери обновлена.")
end)
