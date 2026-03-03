local ply = FindMetaTable("Player")

function ply:GetLevel()
    return self:GetNW2Int("sc_level", 1)
end

function ply:GetExp()
    return self:GetNW2Int("sc_exp", 0)
end

function ply:GetMaxExp()
    local i = self:GetLevel()
    return math.floor(10 * (i ^ 1.2))
end