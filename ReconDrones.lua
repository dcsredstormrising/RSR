-- =AW=33COM
-- Simple rewrite of our drones who were OK, but their menus were completely wrong and impossible to function.
-- This is no near perfect, but will fix the bugs
local utils = require("utils")
local inspect = require("inspect")

ReconDrones = {}
local droneMaxCount = 4
local droneMaxCountAtOnce = 2
blueDroneCount = 0
redDroneCount = 0
local spawnerName = nil
local BlueRecceDetection = {}
local RedRecceDetection = {}

DroneSpawned = EVENTHANDLER:New()
DroneSpawned:HandleEvent(EVENTS.Birth)

BlueHQ = GROUP:FindByName( "Northern Blue HQ" )
BlueCommandCenter = COMMANDCENTER:New( BlueHQ, "Blue Command" )

RedHQ = GROUP:FindByName( "Northern Red HQ" )
RedCommandCenter = COMMANDCENTER:New( RedHQ, "Red Command" )

---Objects to be spawned with attributes set
local Spawn_Blue_UAV = SPAWN:NewWithAlias("Blue UAV-Recon-FAC","Pontiac 1-1")
    :InitLimit(droneMaxCountAtOnce, droneMaxCount)
	:InitKeepUnitNames(true)
    
local Spawn_Red_UAV = SPAWN:NewWithAlias("Red UAV-Recon-FAC","Pontiac 6-1")
    :InitLimit(droneMaxCountAtOnce, droneMaxCount)
    :InitKeepUnitNames(true)
	
local BlueRecceSetGroup = SET_GROUP:New():FilterCoalitions("blue"):FilterPrefixes( {"Pontiac 1"} ):FilterStart()
local RedRecceSetGroup = SET_GROUP:New():FilterCoalitions("red"):FilterPrefixes( {"Pontiac 6"} ):FilterStart()

	BlueRecceDetection = DETECTION_AREAS:New(BlueRecceSetGroup, 15000)
	BlueRecceDetection:SetAcceptRange(15000)
	BlueRecceDetection:FilterCategories({Unit.Category.GROUND_UNIT})
	BlueRecceDetection:SmokeDetectedUnits()
	BlueRecceDetection:SetRefreshTimeInterval(20) -- seconds
	BlueRecceDetection:Start()

	RedRecceDetection = DETECTION_AREAS:New(RedRecceSetGroup, 15000)
	RedRecceDetection:SetAcceptRange(15000)
	RedRecceDetection:FilterCategories({Unit.Category.GROUND_UNIT})
	RedRecceDetection:SmokeDetectedUnits()
	RedRecceDetection:SetRefreshTimeInterval(20) -- seconds
	RedRecceDetection:Start()
	
local function GetAttackingUnitTypes(DetectedUnits)
	local units = ""
	if DetectedUnits ~= nil then
		for DetectedUnit,Detected in pairs(DetectedUnits)do		
			local unit = Detected:GetDCSObject()
			Detected.SmokeBlue()
			units = units..Detected:GetDCSObject():getTypeName()..", "
		end
		units = units:sub(1,-3)
	end
	return units
end

function BlueRecceDetection:OnAfterDetected(From, Event, To, DetectedUnits)
	trigger.action.outTextForCoalition(coalition.side.BLUE, "Is being attacked by ground forces: "..inspect(GetAttackingUnitTypes(DetectedUnits)), 10)
	
end

function RedRecceDetection:OnAfterDetected(From, Event, To, DetectedUnits)
	trigger.action.outTextForCoalition(coalition.side.RED, "Is being attacked by ground forces: "..inspect(GetAttackingUnitTypes(DetectedUnits)), 10)	
end
	
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
	if coalitionNumber == 1 then		
		return droneMaxCount - redDroneCount
	elseif coalitionNumber == 2 then		
		return droneMaxCount - blueDroneCount
	end
	return 0
end

local function showReconLocations(coalitionNumber)    
  local reconCount = 0
  local recons = nil  
  local uavBases = ""
  
  if coalitionNumber == coalition.side.BLUE then
    recons = SET_GROUP:New():FilterCategoryAirplane():FilterPrefixes( {"Pontiac 1"} ):FilterActive():FilterOnce()
  elseif coalitionNumber == coalition.side.RED then
    recons = SET_GROUP:New():FilterCategoryAirplane():FilterPrefixes( {"Pontiac 6"} ):FilterActive():FilterOnce()
  end
        
  if recons ~= nil then
    recons:ForEachGroup(
      function(grp)
        local vec = grp:GetVec2()
        if vec ~= nil then
          local uavNearBase = utils.getNearestAirbase(vec, coalitionNumber, Airbase.Category.AIRDROME)                
          uavBases = uavBases..string.format("%s ", uavNearBase)
        end
        reconCount = reconCount+1
      end
     )  
  end
       
  if reconCount > 0 then            
    return string.format("Team has %i UAV RECON Drones in the air by: %s", reconCount, uavBases)    
  else
    return string.format("Team does not have any UAV RECON Drones in the air at the moment", reconCount)
  end
  
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
	MENU_GROUP_COMMAND:New(playerGroup, "Show UAV RECON Drone Locations", menuRoot, function()
		trigger.action.outTextForCoalition(coalitionNumber, showReconLocations(coalitionNumber), 15)		
	end)
end

-- notify team
function DroneSpawned:OnEventBirth(EventData)
	if string.find(inspect(EventData.IniDCSGroupName), "Pontiac") then 							
		local coalition = EventData.IniCoalition
		local vec = EventData.IniGroup:GetVec2()        
        local uavNearBase = utils.getNearestAirbase(vec, coalition, Airbase.Category.AIRDROME)
		trigger.action.outTextForCoalition(coalition,"[TEAM] " ..spawnerName.. " called in a UAV RECON Drone close to "..uavNearBase.."\nYour team has "..getDronesRemaining(coalition).." remaining UAVs", 10)		
	end
end



