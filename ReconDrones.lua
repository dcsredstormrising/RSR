-- =AW=33COM
-- Simple rewrite of our drones who were OK, but their menus were completely wrong and impossible to function.
-- This is no near perfect, but will fix the bugs

ReconDrones = {}
local droneMaxCount = 4
local droneMaxCountAtOnce = 2
local blueDroneCount = 0
local redDroneCount = 0
DroneSpawned = EVENTHANDLER:New()
DroneSpawned:HandleEvent(EVENTS.Birth)

---Objects to be spawned with attributes set
Spawn_Blue_UAV = SPAWN:NewWithAlias("Blue UAV-Recon-FAC","Pontiac 1-1")
    :InitLimit(droneMaxCountAtOnce, droneMaxCount)
	:InitKeepUnitNames(true)
    
Spawn_Red_UAV = SPAWN:NewWithAlias("Red UAV-Recon-FAC","Pontiac 6-1")
    :InitLimit(droneMaxCountAtOnce, droneMaxCount)
    :InitKeepUnitNames(true)
	
----Function to actually spawn the UAV from the players nose      
local function spawnUAV(group, rng, coalition)
	local range = rng * 1852
	local hdg = group:GetHeading()
	local pos = group:GetPointVec2()	
	local spawnPt = pos:Translate(range, hdg, true)
	local spawnVec2 = spawnPt:GetVec2()
	if coalition == 1 then
		Spawn_Red_UAV:SpawnFromVec2(spawnVec2)
		redDroneCount = redDroneCount + 1
	elseif coalition == 2 then
		Spawn_Blue_UAV:SpawnFromVec2(spawnVec2)
		blueDroneCount = blueDroneCount + 1
	end
end

local function getDronesRemaining(coalitionNumber)
	if coalition == 1 then
		return droneMaxCount - redDroneCount
	elseif coalition == 2 then
		return droneMaxCount - blueDroneCount
	end
	return 0
end

-- this is called in the global on birth event handler
function ReconDrones.AddMenu(playerGroup)
	local groupName = playerGroup:GetName()
	local coalitionNumber = playerGroup:GetCoalition()
	local menuRoot = MENU_GROUP:New(playerGroup, "UAV Reconnaissance")	
	MENU_GROUP_COMMAND:New(playerGroup, "Spawn MQ-1 UAV 1 nm away", menuRoot, spawnBlueUAV, playerGroup, 1, coalitionNumber)
	MENU_GROUP_COMMAND:New(playerGroup, "Spawn MQ-1 UAV 5 nm away", menuRoot, spawnBlueUAV, playerGroup, 5, coalitionNumber)
	MENU_GROUP_COMMAND:New(playerGroup, "Spawn MQ-1 UAV 10 nm away", menuRoot, spawnBlueUAV, playerGroup, 10, coalitionNumber)
	MENU_GROUP_COMMAND:New(playerGroup, "UAV RECON Drones Remaining", menuRoot, function()
		trigger.action.outTextForCoalition(coalitionNumber, "[TEAM] Has " ..getDronesRemaining(coalitionNumber).. " Remaining UAVs", 15)		
  end)
end

function DroneSpawned:OnEventBirth(EventData)
	local coalition = EventData.IniCoalition
	local playerName = playerGroup:GetName()
	trigger.action.outTextForCoalition(2,"[TEAM] " ..client1:GetPlayerName().. " called in a UAV\nContact via F10/F8 Designation for UAV \nBlue team has ".._BlueUAVsLeft.." remaining UAVs", 10)
end

