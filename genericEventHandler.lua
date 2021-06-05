TakeOffEventHandler = EVENTHANDLER:New()
TakeOffEventHandler:HandleEvent(EVENTS.Takeoff)
CrashEventHandler = EVENTHANDLER:New()
CrashEventHandler:HandleEvent(EVENTS.Crash)
EjectionEventHandler = EVENTHANDLER:New()
EjectionEventHandler:HandleEvent(EVENTS.Ejection)
PilotDeadEventHandler = EVENTHANDLER:New()
PilotDeadEventHandler:HandleEvent(EVENTS.PilotDead)
LandEventHandler = EVENTHANDLER:New()
LandEventHandler:HandleEvent(EVENTS.Land)

local function RemovePlayerInAirFlag(EventData)
	if EventData.IniPlayerName then
		local playerGroup = EventData.IniGroup
        if playerGroup then			
			local playerSlotName = playerGroup:GetName()			
			trigger.action.setUserFlag(playerSlotName.."_IN AIR", 0);
        end
    end
end

function TakeOffEventHandler:OnEventTakeoff(EventData)	
	if EventData.IniPlayerName then
		local playerGroup = EventData.IniGroup
        if playerGroup then
			local playerSlotName = playerGroup:GetName()
			trigger.action.setUserFlag(playerSlotName.."_IN AIR", 1);
        end
    end	
end

function CrashEventHandler:OnEventCrash(EventData)
	RemovePlayerInAirFlag(EventData)
	if EventData.IniPlayerName == false then
		local groupName = event.IniGroup:GetName()
		local coalitionNumber = event.IniCoalition
		if string.match(groupName, "Convoy Transport") then
			Convoy.OnTransportCrash(coalitionNumber)
		end
	end
end

function EjectionEventHandler:OnEventEjection(EventData)
	RemovePlayerInAirFlag(EventData)
end

function PilotDeadEventHandler:OnEventPilotDead(EventData)
	RemovePlayerInAirFlag(EventData)
end

function LandEventHandler:OnEventLand(EventData)
	RemovePlayerInAirFlag(EventData)	
	if EventData.IniPlayerName == false then
		local groupName = event.IniGroup:GetName()
		local coalitionNumber = event.IniCoalition
		if string.match(groupName, "Convoy Transport") then
			Convoy.OnLand(coalitionNumber)
		end
	end
end