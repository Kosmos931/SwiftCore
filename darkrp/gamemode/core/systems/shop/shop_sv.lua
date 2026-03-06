if not SERVER then return end

SC.Shop = SC.Shop or {}
local shop = SC.Shop

local cmds = {}
local limits = {}

local function Notify(ply, msg, err)
    if not IsValid(ply) then return end
    local str = string.gsub(tostring(msg), '"', '\\"')
    ply:SendLua('notification.AddLegacy("' .. str .. '", ' .. (err and 1 or 0) .. ', 4)')
end

local function CanBuy(ply, item)
    if item.VIP and not (ply.IsVIP and ply:IsVIP()) then
        return false, "Только для VIP"
    end

    local frac = string.lower(tostring((ply.GetFraction and ply:GetFraction()) or ""))

    if istable(item.BuyFractions) and next(item.BuyFractions) then
        if not item.BuyFractions[frac] then
            return false, "Не для вашей фракции"
        end
    end

    if istable(item.NoBuyFractions) and next(item.NoBuyFractions) then
        if item.NoBuyFractions[frac] then
            return false, "Запрещено для вашей фракции"
        end
    end

    local customCheck = rawget(item, "BuyCheck")
    if isfunction(customCheck) then
        local ok, reason = customCheck(ply, item)
        if not ok then 
            return false, reason or "Нельзя купить" 
        end
    end

    return true
end

local function GetCount(ply, name)
    local sid = ply:SteamID64()
    if not sid then return 0 end
    limits[sid] = limits[sid] or {}
    return limits[sid][name] or 0
end

local function AddCount(ply, name, n)
    local sid = ply:SteamID64()
    if not sid then return end
    limits[sid] = limits[sid] or {}
    limits[sid][name] = math.max(0, (limits[sid][name] or 0) + n)
end

local function SpawnItem(ply, item)
    local class = item.EntityClass
    if not class or class == "" then
        return false, "Нет класса"
    end

    local tr = util.TraceLine({
        start = ply:EyePos(),
        endpos = ply:EyePos() + ply:GetAimVector() * 85,
        filter = ply
    })

    local isWeapon = item.Weapon or false
    local isShipment = item.Shipment or false
    
    local ent
    if isShipment then
        ent = ents.Create("spawned_shipment")
    elseif isWeapon then
        ent = ents.Create("spawned_weapon")
    else
        ent = ents.Create(class)
    end

    if not IsValid(ent) then
        return false, "Ошибка создания"
    end

    if isWeapon and not isShipment and ent.SetWeaponData then
        ent:SetWeaponData(class, item.DisplayName or item.Name, ply)
    end

    if isShipment then
        ent:SetModel("models/props_junk/cardboard_box003a.mdl")
        ent.ItemModel = item.Model or ""
    elseif item.Model and item.Model ~= "" then
        ent:SetModel(item.Model)
    end

    ent:SetPos(tr.HitPos)
    ent:SetAngles(Angle(0, ply:EyeAngles().y, 0))
    ent:Spawn()
    ent:Activate()

    if not IsValid(ent) then
        return false, "Ошибка после спавна"
    end

    ent.SC_Owner = ply
    ent:SetNW2Entity("SC_Owner", ply)

    if isShipment and ent.SetShipmentData then
        local _, amount = item.Shipment, 1
        if istable(item.Shipment) then
            amount = math.max(1, math.floor(tonumber(item.Shipment[2]) or 1))
        end
        ent:SetShipmentData(class, item.DisplayName or item.Name, amount)
    end

    return true, ent
end

function shop.Buy(ply, item)
    if not item then
        return false, "Нет такого"
    end

    local ok, reason = CanBuy(ply, item)
    if not ok then
        return false, reason
    end

    local limit = tonumber(item.Limit) or 0
    if limit > 0 and GetCount(ply, item.Name) >= limit then
        return false, "Лимит: " .. limit
    end

    local price = math.max(0, math.floor(tonumber(item.Price) or 0))
    if not ply:HasMoney(price) then
        return false, "Денег нет"
    end

    local ok, ent = SpawnItem(ply, item)
    if not ok then
        return false, ent
    end

    ply:TakeMoney(price)

    if limit > 0 and IsValid(ent) then
        AddCount(ply, item.Name, 1)
        local sid = ply:SteamID64()
        local name = item.Name
        
        ent:CallOnRemove("shop_" .. sid .. "_" .. name, function()
            if limits[sid] then
                limits[sid][name] = math.max(0, (limits[sid][name] or 0) - 1)
            end
        end)
    end

    return true
end

local function AddCmd(item)
    local cmd = tostring(item.Command or ""):lower():gsub("^/", "")
    if cmd == "" then return end
    if cmds[cmd] then return end
    if not (SC.AdminCommands and SC.AdminCommands.Create) then return end

    SC.AdminCommands.Create(cmd, function(ply)
        local ok, msg = shop.Buy(ply, item)
        if not ok then
            Notify(ply, msg, true)
        else
            Notify(ply, "Куплено: " .. (item.DisplayName or item.Name))
        end
    end)

    cmds[cmd] = true
end

local function LoadCmds()
    if not shop.GetAll then return end
    if not (SC.AdminCommands and SC.AdminCommands.Create) then
        timer.Simple(1, LoadCmds)
        return
    end

    for _, item in pairs(shop.GetAll()) do
        AddCmd(item)
    end
end

hook.Add("Initialize", "SC.Shop.Cmds", function()
    timer.Simple(0, LoadCmds)
end)

hook.Add("PlayerDisconnected", "SC.Shop.Clean", function(ply)
    local sid = ply:SteamID64()
    if sid then limits[sid] = nil end
end)
