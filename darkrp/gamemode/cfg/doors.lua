SC.Config = SC.Config or {}
SC.Config.Doors = SC.Config.Doors or {}

local cfg = SC.Config.Doors

cfg.DefaultPrice = cfg.DefaultPrice or 250
cfg.SellMultiplier = cfg.SellMultiplier or 0.7
cfg.UseDistance = cfg.UseDistance or 180

cfg.SpecialByMap = cfg.SpecialByMap or {
    ["rp_downtown_tits_v1"] = {
        -- [MapCreationID] = { title = "Полицейский участок", faction = "ccg", buyable = false }
    }
}
