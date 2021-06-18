-- =AW=33COM
-- Simple rewrite of our drones who were OK, but their menus were completely wrong and impossible to function.
-- This is no near perfect, but will fix the bugs
local utils = require("utils")
local inspect = require("inspect")

ReconDrones = {}
local droneMaxCount = 4
local droneMaxCountAtOnce = 2
local detectMaxCount = 3
local smokeInterval = 120
local lastSmokedTime = timer.getTime()
local detectInterval = 20  -- this is also lase duration that resets each time detection runs-- super simple way to update laser
blueDroneCount = 0
redDroneCount = 0
local spawnerName = nil
local BlueRecceDetection = {}
local RedRecceDetection = {}
local laserCodeRed = 1686
local laserCodeBlue = 1687

-- setup
DroneSpawned = EVENTHANDLER:New()
DroneSpawned:HandleEvent(EVENTS.Birth)

BlueHQ = GROUP:FindByName( "Northern Blue HQ" )
BlueCommandCenter = COMMANDCENTER:New( BlueHQ, "Blue Command" )

RedHQ = GROUP:FindByName( "Northern Red HQ" )
RedCommandCenter = COMMANDCENTER:New( RedHQ, "Red Command" )

local Spawn_Blue_UAV = SPAWN:NewWithAlias("Blue UAV-Recon-FAC","Pontiac 1-1")
    :InitLimit(droneMaxCountAtOnce, droneMaxCount)
	:InitKeepUnitNames(true)
    
local Spawn_Red_UAV = SPAWN:NewWithAlias("Red UAV-Recon-FAC","Pontiac 6-1")
    :InitLimit(droneMaxCountAtOnce, droneMaxCount)
    :InitKeepUnitNames(true)
	
local BlueRecceSetGroup = SET_GROUP:New():FilterCoalitions("blue"):FilterPrefixes( {"Pontiac 1"} ):FilterStart()
local RedRecceSetGroup = SET_GROUP:New():FilterCoalitions("red"):FilterPrefixes( {"Pontiac 6"} ):FilterStart()

-- detection
blueDetection = DETECTION_AREAS:New(BlueRecceSetGroup, 10000)
blueDetection:SetAcceptRange(10000)
blueDetection:FilterCategories({Unit.Category.GROUND_UNIT})	
blueDetection:SetRefreshTimeInterval(detectInterval) -- seconds
blueDetection.DetectedItemMax = detectMaxCount
blueDetection:SetDistanceProbability(0.3)
blueDetection:SetAlphaAngleProbability(0.3)
blueDetection:Start()

redDetection = DETECTION_AREAS:New(RedRecceSetGroup, 10000)
redDetection:SetAcceptRange(10000)
redDetection:FilterCategories({Unit.Category.GROUND_UNIT})	
redDetection:SetRefreshTimeInterval(detectInterval) -- seconds
redDetection.DetectedItemMax = detectMaxCount
redDetection:SetDistanceProbability(0.3)
redDetection:SetAlphaAngleProbability(0.3)
redDetection:Start()

-- designation
local function isReadyToSmokeAgain()
	local diff = timer.getTime() - lastSmokedTime	
	if diff > smokeInterval then		
		return true
	end
end

function blueDetection:OnAfterDetected(From, Event, To, DetectedUnits)
	--UNIT:LaseOff() -- reset laser because unit position could have changed since last detection
	if isReadyToSmokeAgain() then
		utils.smokeUnits(DetectedUnits, 1)
		lastSmokedTime = timer.getTime()
	end
	--utils.laseUnits(BlueRecceSetGroup, DetectedUnits, detectInterval, laserCodeBlue, 1)
	trigger.action.outTextForCoalition(2, "Detection ran for BLUE", 4)
end

function redDetection:OnAfterDetected(From, Event, To, DetectedUnits)	
	--UNIT:LaseOff() -- reset laser because unit position could have changed since last detection
	local detector = nil
	for _,detectedItem in pairs(redDetection.DetectedItems) do			
		detector = detectedItem.NearestFAC
		break;
	end
		
	if isReadyToSmokeAgain() then
		utils.smokeUnits(DetectedUnits, 1)
		lastSmokedTime = timer.getTime()
	end
	
	if detector then
		utils.laseUnits(detector, DetectedUnits, detectInterval, laserCodeRed, 2)
		trigger.action.outTextForCoalition(1, "Detection ran for RED", 4)
	end
end
	
----Function to actually spawn the RECON from the players nose
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

function DroneSpawned:OnEventBirth(EventData)
	if string.find(inspect(EventData.IniDCSGroupName), "Pontiac") then 							
		local coalition = EventData.IniCoalition
		local vec = EventData.IniGroup:GetVec2()        
        local uavNearBase = utils.getNearestAirbase(vec, coalition, Airbase.Category.AIRDROME)
		trigger.action.outTextForCoalition(coalition,"[TEAM] " ..spawnerName.. " called in a UAV RECON Drone close to "..uavNearBase.."\nYour team has "..getDronesRemaining(coalition).." remaining UAVs", 10)		
	end
end



