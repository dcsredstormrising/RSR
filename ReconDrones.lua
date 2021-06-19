-- =AW=33COM Simple rewrite of our drones who were OK, but their menus were completely wrong and impossible to function.
-- Their lasing and smoking was complicated to the end user..now everything auto lases and smokes just like our JTAC
-- This is no near perfect, but will fix the bugs
-- due to Moose some of these setting are per instance of the RECON..this is goog but just keep in mind those events below run per instance of drone in the air
local utils = require("utils")
local inspect = require("inspect")
ReconDrones = {}
local laserCodeRed = 1686
local laserCodeBlue = 1687
local droneMaxCount = 4
local droneMaxCountAtOnce = 2
local detectMaxCount = 4
local detectionRange = 12000  --meters
local smokeInterval = 120
local lastSmokedTime = timer.getTime()
local detectInterval = 20  -- this is also lase duration that resets each time detection runs-- super simple way to update laser
local lastNotifyTime = timer.getTime()
local detectMessageInterval = 60
blueDroneCount = 0
redDroneCount = 0
local spawnerName = nil
local BlueRecceDetection = {}
local RedRecceDetection = {}

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
blueDetection = DETECTION_AREAS:New(BlueRecceSetGroup, detectionRange)
blueDetection:SetAcceptRange(detectionRange)
blueDetection:FilterCategories({Unit.Category.GROUND_UNIT})	
blueDetection:SetRefreshTimeInterval(detectInterval) -- seconds
blueDetection.DetectedItemMax = detectMaxCount -- I dont' think this works in Moose correctly
blueDetection:SetDistanceProbability(0.3)
blueDetection:SetAlphaAngleProbability(0.3)
blueDetection:Start()

redDetection = DETECTION_AREAS:New(RedRecceSetGroup, detectionRange)
redDetection:SetAcceptRange(detectionRange)
redDetection:FilterCategories({Unit.Category.GROUND_UNIT})	
redDetection:SetRefreshTimeInterval(detectInterval) -- seconds
redDetection.DetectedItemMax = detectMaxCount -- I dont' think this works in Moose correctly
redDetection:SetDistanceProbability(0.3)
redDetection:SetAlphaAngleProbability(0.3)
redDetection:Start()

local function getAirbaseUnderAttack(detector, coalition)
	local airbase = nil	
	local vec = detector:GetVec2()
    if vec ~= nil then
		return utils.getNearestAirbase(vec, coalition, Airbase.Category.AIRDROME)        
	end
end

local function isReadyToSmokeAgain()
	local diff = timer.getTime() - lastSmokedTime	
	if diff > smokeInterval then		
		return true
	end
end

local function isReadyToNotifyTeamAgain()
	local diff = timer.getTime() - lastNotifyTime	
	if diff > detectMessageInterval then		
		return true
	end
end

local function smokeAndLase(DetectedUnits, coalition)
	trigger.action.outTextForCoalition(1, "Detection ran for coalition: "..inspect(coalition), 4)
	local detector = nil
	for _,detectedItem in pairs(redDetection.DetectedItems) do			
		detector = detectedItem.NearestFAC
		break;
	end		
	if isReadyToSmokeAgain() then
		utils.smokeUnits(DetectedUnits, 2)
		lastSmokedTime = timer.getTime()
	end	
	if isReadyToNotifyTeamAgain() then		
		local airbase = getAirbaseUnderAttack(detector, coalition)		
		trigger.action.outTextForCoalition(1, "Units are on the way to attack "..airbase..": for coalition: "..inspect(coalition), 4)
		lastNotifyTime = timer.getTime()
	end
	if detector then
		if coalition == 2 then
			env.info("RECON:smokeAndLase BLUE")
			utils.laseUnits(detector, DetectedUnits, detectInterval, laserCodeBlue, 1, detectMaxCount)
		elseif coalition == 1 then
			env.info("RECON:smokeAndLase RED")
			utils.laseUnits(detector, DetectedUnits, detectInterval, laserCodeRed, 1, detectMaxCount)			
		end
	end
end

function blueDetection:OnAfterDetected(From, Event, To, DetectedUnits)	
	smokeAndLase(DetectedUnits, coalition.side.BLUE)	
end

function redDetection:OnAfterDetected(From, Event, To, DetectedUnits)
	smokeAndLase(DetectedUnits, coalition.side.RED)	
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