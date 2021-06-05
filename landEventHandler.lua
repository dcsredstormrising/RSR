local inspect = require("inspect")

local M = {}

M.eventHandler = nil  -- constructed in onMissionStart

M.LAND_EVENTHANDLER = {
    ClassName = "LAND_EVENTHANDLER"
}

function M.LAND_EVENTHANDLER:New()
    local _self = BASE:Inherit(self, EVENTHANDLER:New())
    _self:HandleEvent(EVENTS.Land, _self._OnLand)
    return _self
end

function M.LAND_EVENTHANDLER:_OnLand( event )
    if event.IniPlayerName then
        local playerGroup = event.IniGroup
        if playerGroup then
			local playerSlotName = playerGroup:GetName()
			env.info("AW33COM Landing with a big cock in: "..playerSlotName)
			trigger.action.setUserFlag(playerSlotName.."_IN AIR", 0);
			env.info("AW33COM Landing with a big cock in: "..playerGroup:GetName())
        end
    else
        self:_NonPlayerRouter( event )
    end
end

function M.LAND_EVENTHANDLER:_NonPlayerRouter( event )
    local groupName = event.IniGroup:GetName()
    local coalitionNumber = event.IniCoalition
    if string.match(groupName, "Convoy Transport") then
        Convoy.OnLand(coalitionNumber)
    end
end
    
function M.onMissionStart()
    M.eventHandler = M.LAND_EVENTHANDLER:New()
end

return M
