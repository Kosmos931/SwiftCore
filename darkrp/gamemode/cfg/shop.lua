local SAdd = SC.Shop and SC.Shop.Add
if not SAdd then return end

SAdd("hil", "Хилка", "item_healthvial")
    :SetPrice(150)
    :SetCommand("buyhil")
    :SetVIP(true)
    :SetLimit(1)
    :SetModel("models/Items/HealthKit.mdl")
    :Register()

SAdd("ar", "Броня", "item_battery")
    :SetPrice(200)
    :SetCommand("buyarmor")
    :SetVIP(true)
    :SetLimit(1)
    :SetModel("models/items/battery.mdl")
    :Register()

SAdd("crowbar", "Лом", "weapon_crowbar")
    :SetWeapon(true)
    :SetPrice(300)
    :SetCommand("buycrowbar")
    :SetModel("models/weapons/w_crowbar.mdl")
    :Register()


SAdd("shotgun_box", "Коробка дробовиков", "weapon_shotgun")
    :SetShipment(true, 5)
    :SetPrice(1200)
    :SetCommand("buyshotgunbox")
    :SetLimit(1)
    :Fractions({"ccg", "ghoul"})
    :SetModel("models/weapons/shotgun.mdl")
    :Register()

SAdd("stul", "Стул", "prop_physics")
    :SetPrice(120)
    :SetCommand("buystul")
    :SetLimit(1)
    :NoFractions({"ghoul"})
    :SetModel("models/props_c17/FurnitureChair001a.mdl")
    :Register()