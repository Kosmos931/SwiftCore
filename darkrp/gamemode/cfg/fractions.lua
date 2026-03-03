local Frac = SC.Frac or SC.Fractions
local FAdd = SC.FAdd or Frac.Add

TEAM_CITIZEN = FAdd("citizen", "Гражданин")
    :SetMaxHealth(100)
    :SetMaxArmor(0)
    :SetDescription("Обычный гражданин города. Не имеет особых способностей, но может свободно перемещаться и взаимодействовать с другими игроками.")
    :SetSpawn(Vector(0, 110, 0))
    :SetWeapons({"weapon_pistol"})
    :Register()

TEAM_CCG = FAdd("ccg", "CCG")
    :SetMaxHealth(150)
    :SetMaxArmor(50)
    :SetDescription("Комиссия по контролю за гулями. Организация, которая борется с гулями и защищает граждан. Имеет повышенное здоровье и броню.")
    :Register()

TEAM_GHOUL = FAdd("ghoul", "Ghoul")
    :SetMaxHealth(360)
    :SetMaxArmor(50)
    :SetWalkSpeed(350)
    :SetRunSpeed(500)
    :SetJumpPower(300)
    :SetRegenHP(true,10)
    :SetColor(Color(255,0,0))
    :Register()

Frac.AddGroup('Лошки', TEAM_CITIZEN, TEAM_CCG)
Frac.AddGroup('Лошки2', TEAM_GHOUL)

Frac.SetBaseFraction(TEAM_CITIZEN)
