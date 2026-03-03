SC.Config = SC.Config or {}
local cfg = SC.Config
-- чтобы получить эти значения надо SC.Config подставлять
-- не забудь пидр
cfg.Money = cfg.Money or {}
cfg.Money.StartAmount = 1000

cfg.Player = cfg.Player or {}
cfg.Player.WalkSpeed = 180
cfg.Player.RunSpeed = 280
cfg.Player.JumpPower = 200

cfg.Stamina = cfg.Stamina or {}
cfg.Stamina.Enable = true -- restart
cfg.Stamina.Max = 155
cfg.Stamina.DrainRun = 15
cfg.Stamina.DrainJump = 15
cfg.Stamina.RegenWalk = 5
cfg.Stamina.RegenIdle = 10
cfg.Stamina.RegenAir = 2
cfg.Stamina.JumpLimit = 15

// cfg.Level = cfg.Level or {}
// cfg.Level.Enable = true

cfg.Weapons = cfg.Weapons or  {
    "weapon_physgun",
    "weapon_physcannon",
    "gmod_tool",
    "weapon_fists",
    "weapon_medkit"
}

cfg.Spawns = cfg.Spawns or {
    ["rp_downtown_tits_v1"] = {
        Vector(3508, 334, -195),
        Vector(3231, 340, -195),
        Vector(3043, 345, -195),
        Vector(3067, 743, -195),
        Vector(3079, 1133, -195),
        Vector(3289, 1138, -195),
        Vector(3507, 1130, -195),
        Vector(3488, 718, -195),
        Vector(3287, 759, -195),
    },
}
