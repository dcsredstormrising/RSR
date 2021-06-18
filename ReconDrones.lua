-- =AW=33COM
-- Simple rewrite of our drones who were OK, but their menus were completely wrong and impossible to function.
-- This is no near perfect, but will fix the bugs
local inspect = require("inspect")

ReconDrones = {}
local droneMaxCount = 4
local droneMaxCountAtOnce = 2
local blueDroneCount = 0
local redDroneCount = 0
local spawnerName = nil
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
local function spawnUAV(group, rng, coalition, playerName)
	local range = rng * 1852
	local hdg = group:GetHeading()
	local pos = group:GetPointVec2()	
	local spawnPt = pos:Translate(range, hdg, true)
	local spawnVec2 = spawnPt:GetVec2()
	if coalition == 1 then
		Spawn_Red_UAV:SpawnFromVec2(spawnVec2)
		redDroneCount = redDroneCount + 1
		spawnerName = playerName
	elseif coalition == 2 then
		Spawn_Blue_UAV:SpawnFromVec2(spawnVec2)
		blueDroneCount = blueDroneCount + 1
		spawnerName = playerName
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

-- this is called from the global on birth event handler
function ReconDrones.AddMenu(playerGroup)
	local playerName = playerGroup:GetPlayerName()
	local coalitionNumber = playerGroup:GetCoalition()
	local menuRoot = MENU_GROUP:New(playerGroup, "UAV Reconnaissance")	
	MENU_GROUP_COMMAND:New(playerGroup, "Spawn MQ-1 UAV 1 nm away", menuRoot, spawnUAV, playerGroup, 1, coalitionNumber, playerName)
	MENU_GROUP_COMMAND:New(playerGroup, "Spawn MQ-1 UAV 5 nm away", menuRoot, spawnUAV, playerGroup, 5, coalitionNumber, playerName)
	MENU_GROUP_COMMAND:New(playerGroup, "Spawn MQ-1 UAV 10 nm away", menuRoot, spawnUAV, playerGroup, 10, coalitionNumber, playerName)
	MENU_GROUP_COMMAND:New(playerGroup, "UAV RECON Drones Remaining", menuRoot, function()
		trigger.action.outTextForCoalition(coalitionNumber, "[TEAM] Has " ..getDronesRemaining(coalitionNumber).. " Remaining UAVs", 15)		
	end)
	-- add lase and smoke option for drones in the air
	MENU_GROUP_COMMAND:New(playerGroup, "Lase Units from MQ-1 by Aleppo", menuRoot)
end

-- notify team
function DroneSpawned:OnEventBirth(EventData)	
	env.info("DroneSpawned:OnEventBirth 1")
	if string.find(inspect(EventData.IniDCSGroupName), "Pontiac") then 
		env.info("DroneSpawned:OnEventBirth 2")						
		local coalition = EventData.IniCoalition
		local vec = EventData.IniGroup:GetVec2()        
        local uavNearBase = utils.getNearestAirbase(vec, coalition, Airbase.Category.AIRDROME)
		trigger.action.outTextForCoalition(coalition,"[TEAM] " ..spawnerName.. " called in a UAV RECON Drone close to "..uavNearBase.."\nYour team has "..getDronesRemaining(coalition).." remaining UAVs", 10)
		env.info("DroneSpawned:OnEventBirth 3")
	end
end

