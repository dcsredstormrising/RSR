local M = {}

M.eventHandler = nil  -- constructed in onMissionStart

M.CRASH_EVENTHANDLER = {
    ClassName = "CRASH_EVENTHANDLER"
}

function M.CRASH_EVENTHANDLER:New()
    local _self = BASE:Inherit(self, EVENTHANDLER:New())
    _self:HandleEvent(EVENTS.Crash, _self._OnCrash)
    return _self
end

function M.CRASH_EVENTHANDLER:_OnCrash( event )
    if event.IniPlayerName then
        local playerGroup = event.IniGroup
        if playerGroup then
            -- Does Nothing right now
        end
    else
        self:_NonPlayerRouter( event )
    end
end

function M.CRASH_EVENTHANDLER:_NonPlayerRouter( event )
    local groupName = event.IniGroup:GetName()
    local coalitionNumber = event.IniCoalition
    if string.match(groupName, "Convoy Transport") then
        -- Do Nothing
    end
end
    
function M.onMissionStart()
    M.eventHandler = M.CRASH_EVENTHANDLER:New()
end

return M
