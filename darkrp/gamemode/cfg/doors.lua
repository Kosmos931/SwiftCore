SC.Config.Doors = SC.Config.Doors or {}

local cfg = SC.Config.Doors

cfg.DefaultPrice = 250
cfg.SellMultiplier = 0.7
cfg.UseDistanceSqr = 150 * 150

cfg.StaticDoors = {
    ["rp_downtown_tits_v1"] = {
       [1354] = { title = "Тест дверька", fraction = "citizen", buyable = false }
    }
}