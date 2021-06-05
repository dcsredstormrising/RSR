GenericTakeOffEventHandler = EVENTHANDLER:New()
GenericTakeOffEventHandler:HandleEvent(EVENTS.Takeoff)

function GenericTakeOffEventHandler:OnEventTakeoff(EventData)
	env.info("AW33COM Big Cock Took Off 1")
	if EventData.IniPlayerName then
		local playerGroup = EventData.IniGroup
        if playerGroup then			
			local playerSlotName = playerGroup:GetName()
			env.info("AW33COM Big Cock Took Off IN: "..playerGroup:GetName())
			trigger.action.setUserFlag(playerSlotName.."_IN AIR", 1);
			env.info("AW33COM Big Cock Took Off IN New Name: "..playerGroup:GetName())
        end
    end	
end