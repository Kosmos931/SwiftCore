SC.Admin = SC.Admin or {}
local admin = SC.Admin

admin.DefaultRank = admin.DefaultRank or "user"
admin.DefaultFlags = admin.DefaultFlags or ""

admin.Ranks = admin.Ranks or {}

hook.Add( "PlayerNoClip", "NCLP.Disable", function(ply)
    return (SERVER and ply:IsRoot() and true) or false
end)