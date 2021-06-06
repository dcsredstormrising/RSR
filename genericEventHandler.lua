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

function TakeOffEventHandler:OnEventTakeoff(EventData)	
end

function CrashEventHandler:OnEventCrash(EventData)	
	if EventData.IniPlayerName then
		--
	else
		local groupName = EventData.IniGroup:GetName()
		local coalitionNumber = EventData.IniCoalition
		if string.match(groupName, "Convoy Transport") then
			Convoy.OnTransportCrash(coalitionNumber)
		end
	end
end

function EjectionEventHandler:OnEventEjection(EventData)
end

function PilotDeadEventHandler:OnEventPilotDead(EventData)
end

function LandEventHandler:OnEventLand(EventData)	
	if EventData.IniPlayerName then
		--
	else
		local groupName = EventData.IniGroup:GetName()
		local coalitionNumber = EventData.IniCoalition
		if string.match(groupName, "Convoy Transport") then
			Convoy.OnLand(coalitionNumber)
		end
	end
end