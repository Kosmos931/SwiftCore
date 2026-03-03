local ply = FindMetaTable("Player")

hook.Add("Initialize", "SC.Lvl.TableInit", function()
    sql.Query("CREATE TABLE IF NOT EXISTS sc_levels(steamid TEXT PRIMARY KEY, lvl INTEGER, exp INTEGER)")
end)

hook.Add("PlayerInitialSpawn", "SC.Lvl.Load", function(p)
    local data = sql.QueryRow("SELECT * FROM sc_levels WHERE steamid = " .. sql.SQLStr(p:SteamID()))
    
    if data then
        p:SetNW2Int("sc_level", tonumber(data.lvl) or 1)
        p:SetNW2Int("sc_exp", tonumber(data.exp) or 0)
    else
        p:SetNW2Int("sc_level", 1)
        p:SetNW2Int("sc_exp", 0)
    end
end)

function ply:SaveLvl()
    sql.Query("INSERT OR REPLACE INTO sc_levels(steamid, lvl, exp) VALUES(" .. sql.SQLStr(self:SteamID()) .. ", " .. self:GetLevel() .. ", " .. self:GetExp() .. ")")
end

util.AddNetworkString("SC.LevelUp")

function ply:AddExp(amount)
    // if not SC.Config.Level.Enable then return end
    
    local curExp = self:GetExp() + amount
    local curLvl = self:GetLevel()
    local maxExp = self:GetMaxExp()

    local leveledUp = false
    while curExp >= maxExp do
        curExp = curExp - maxExp
        curLvl = curLvl + 1
        self:SetNW2Int("sc_level", curLvl)
        maxExp = self:GetMaxExp()
        leveledUp = true
    end

    self:SetNW2Int("sc_exp", curExp)

    if leveledUp then
        net.Start("SC.LevelUp")
            net.WriteInt(self:GetLevel(), 32)
        net.Send(self)
        
        hook.Run("SC.OnLevelUp", self, self:GetLevel())
    end
    
    self:SaveLvl()
end

hook.Add("PlayerDisconnected", "SC.Lvl.SaveOnExit", function(p) p:SaveLvl() end)
