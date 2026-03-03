SC.Admin = SC.Admin or {}

local Rank = SC.AdminRanks
local RAdd = Rank and Rank.Add
if not RAdd then return end

RAdd("user", "User")
    :SetRankLevel(1)
    :SetImmunity(0)
    :SetFlags("a")
    :SetMaxProps(5)
    :Register()

RAdd("vip", "VIP")
    :SetRankLevel(2)
    :SetImmunity(10)
    :SetFlags("abcd")
    :SetVIP(true)
    :SetMaxProps(100)
    :Register()

RAdd("root", "Root")
    :SetRankLevel(100)
    :SetImmunity(100)
    :SetFlags("abcdefghijklmnopqrstuvwxyz")
    :SetRoot(true)
    :SetMaxProps(10000)
    :Register()


SC.Admin.DefaultRank = "user"

