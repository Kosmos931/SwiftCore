SC.Shop = SC.Shop or {}
local shop = SC.Shop

if shop._APIReady then return end
shop._APIReady = true

shop.Items = shop.Items or {}
shop.ByCommand = shop.ByCommand or {}

local Item = {}

function Item.__index(tbl, key)
    local method = rawget(Item, key)
    if method then
        return method
    end

    if isstring(key) and string.find(key, "^Set") then
        local propName = string.sub(key, 4)
        local param = function(self, ...)
            local args = {...}
            if #args == 1 then
                self[propName] = args[1]
            else
                self[propName] = args
            end
            return self
        end

        Item[key] = param
        return param
    end

    return nil
end

local function normalizeFractionMap(...)
    local args = {...}
    local src = args

    if #args == 1 and istable(args[1]) then
        src = args[1]
    end

    local map = {}
    for _, v in ipairs(src) do
        local name = string.lower(tostring(v or ""))
        if name ~= "" then
            map[name] = true
        end
    end

    return next(map) and map or nil
end

function Item:New(name, displayName, entityClass)
    local obj = setmetatable({}, Item)

    obj.Name = string.lower(tostring(name or ""))
    obj.DisplayName = tostring(displayName or name or "Item")
    obj.EntityClass = tostring(entityClass or "")

    obj.Price = 100
    obj.Command = "buy" .. obj.Name
    obj.Model = ""
    obj.VIP = false
    obj.Limit = 0
    obj.Shipment = false
    obj.Icon = ""

    obj.BuyFractions = nil
    obj.NoBuyFractions = nil
    obj.BuyCheck = nil

    return obj
end

function Item:Fractions(rule)
    if isfunction(rule) then
        self.BuyCheck = rule
        return self
    end

    self.BuyCheck = nil
    self.BuyFractions = normalizeFractionMap(rule)
    return self
end

function Item:NoFractions(...)
    self.NoBuyFractions = normalizeFractionMap(...)
    return self
end

function Item:Register()
    if self.Name == "" then return self end

    local cmdName = string.lower(tostring(self.Command or ("buy" .. self.Name)))
    cmdName = string.gsub(cmdName, "^/", "")

    self.Command = cmdName
    shop.Items[self.Name] = self
    shop.ByCommand[cmdName] = self

    return self
end

function shop.Add(name, displayName, entityClass)
    local key = string.lower(tostring(name or ""))
    if shop.Items[key] then
        return shop.Items[key]
    end
    return Item:New(key, displayName, entityClass)
end

function shop.Get(name)
    if not name then return nil end
    return shop.Items[string.lower(tostring(name))]
end

function shop.GetByCommand(command)
    if not command then return nil end
    local cmdName = string.lower(tostring(command))
    cmdName = string.gsub(cmdName, "^/", "")
    return shop.ByCommand[cmdName]
end

function shop.GetAll()
    return shop.Items
end
