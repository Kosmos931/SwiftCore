if not SERVER then return end

SC.Admin = SC.Admin or {}
SC.Admin.Notify = SC.Admin.Notify or {}
local notify = SC.Admin.Notify

--[[
    @param ply Player|nil
    @param msg string
    @param msgType number|nil
]]
function notify.Send(ply, msg, msgType)
    msgType = msgType or NOTIFY_GENERIC
    if IsValid(ply) and ply:IsPlayer() then
        ply:ChatPrint(msg)
        if ply:IsListenServerHost() then
            ply:PrintMessage(HUD_PRINTCONSOLE, "[SC] " .. msg)
        end
    else
        MsgC(Color(100, 200, 255), "[SC] ", Color(255, 255, 255), msg .. "\n")
    end
end

--[[
    @param ply Player|nil
    @param msg string
]]
function notify.Error(ply, msg)
    notify.Send(ply, "ОШИБКА: " .. msg, NOTIFY_ERROR)
end

--[[
    @param ply Player|nil
    @param msg string
]]
function notify.Success(ply, msg)
    notify.Send(ply, "✓ " .. msg, NOTIFY_GENERIC)
end

--[[
    @param ply Player|nil
    @param msg string
]]
function notify.Info(ply, msg)
    notify.Send(ply, "ℹ " .. msg, NOTIFY_GENERIC)
end

--[[
    @param ply Player|nil
    @param msg string
]]
function notify.Warn(ply, msg)
    notify.Send(ply, "⚠ " .. msg, NOTIFY_GENERIC)
end

--[[
    @param msg string
]]
function notify.All(msg)
    for _, ply in ipairs(player.GetAll()) do
        notify.Send(ply, msg)
    end
    notify.Send(nil, msg)
end

--[[
    @param msg string
    @param excludePly Player|nil
]]
function notify.Staff(msg, excludePly)
    for _, ply in ipairs(player.GetAll()) do
        if ply ~= excludePly then
            if SC.Admin and SC.Admin.GetRankLevel and SC.Admin.GetRankLevel(ply) > 0 then
                notify.Send(ply, "[STAFF] " .. msg)
            end
        end
    end
    MsgC(Color(255, 200, 0), "[STAFF] ", Color(255, 255, 255), msg .. "\n")
end

--[[
    @param msg string
    @param excludePly Player|nil
]]
function notify.AllStaff(msg, excludePly)
    notify.Staff(msg, excludePly)
end

SC.Admin.Notify = notify
