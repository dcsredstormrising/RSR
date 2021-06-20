-- =AW=33COM Simple rewrite of our drones who were OK, but their menus were completely wrong and impossible to function.
-- Their lasing and smoking was complicated to the end user..now everything auto lases and smokes just like our JTAC
-- This is no near perfect, but will fix the bugs
-- due to Moose some of these setting are per instance of the RECON..this is goog but just keep in mind those events below run per instance of drone in the air
-- This is my last work with Moose, and their lack of software understanding.  Their inheritance is not really inheritance and you will run into trouble
-- pretty fast.  For example:  DETECTION_AREAS inherits from DETECTION_BASE, but public DETECTION_BASE.DetectedItem is never inherited so asking for something simple
-- like this: DetectedItem.NearestFAC will never work.
local utils = require("utils")
local inspect = require("inspect")
ReconDrones = {}
local laserCodeRed = 1686
local laserCodeBlue = 1687
local droneMaxCount = 4 -- per session
local droneMaxCountAtOnce = 2
local detectMaxCount = 5
local detectionRange = 15000  --meters
local maxLaseDistane = 60000 -- I need this becuase of Moose bugs, I need to find the closest RECON airplane that is detecting the units.  More than 60,000 is crazy and shuld not lase from that far
local smokeInterval = 120 -- smoke will update in sec
local lastSmokedTime = timer.getTime()
local detectInterval = 30  -- this is also lase duration that resets each time detection runs-- super simple way to update laser
local lastNotifyTime = timer.getTime()
local detectMessageInterval = 60
blueDroneCount = 0
redDroneCount = 0
local spawnerName = nil
local BlueRecceDetection = {}
local RedRecceDetection = {}
local detectionStatus = {}

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
blueDetection = DETECTION_BASE:New(BlueRecceSetGroup)
blueDetection:SetAcceptRange(detectionRange)
blueDetection:FilterCategories({Unit.Category.GROUND_UNIT})	
blueDetection:SetRefreshTimeInterval(detectInterval) -- seconds
blueDetection.DetectedItemMax = detectMaxCount -- I dont' think this works in Moose correctly
blueDetection:SetDistanceProbability(1)
blueDetection:SetAlphaAngleProbability(1)
blueDetection:Start()

redDetection = DETECTION_BASE:New(RedRecceSetGroup)
redDetection:SetAcceptRange(detectionRange)
redDetection:FilterCategories({Unit.Category.GROUND_UNIT})	
redDetection:SetRefreshTimeInterval(detectInterval) -- seconds
redDetection.DetectedItemMax = detectMaxCount -- I dont' think this works in Moose correctly
redDetection:SetDistanceProbability(1)
redDetection:SetAlphaAngleProbability(1)
redDetection:Start()

local function SendMessage(args)
	trigger.action.outTextForCoalition(args[2], args[1], 20)
end

local function PlaySound(args)
	trigger.action.outSoundForCoalition(args[2], args[1])
end

local function findNearestRecce(detectedUnit, detectionSet)
	local NearestRecce=nil
	local DistanceRecce=maxLaseDistane
	for RecceGroupName,RecceGroup in pairs(detectionSet:GetSet())do		
		if RecceGroup and RecceGroup:IsAlive()then
			for _,RecceUnit in pairs(RecceGroup:GetUnits())do
				if RecceUnit:IsActive()then
					local RecceUnitCoord=RecceUnit:GetCoordinate()					
					local Distance=RecceUnitCoord:Get2DDistance(detectedUnit:GetCoordinate())
					if Distance<DistanceRecce then
						DistanceRecce=Distance	-- pretty clever trick to find the nearest, he simply cuts the distance
						NearestRecce=RecceUnit
					end
				end
			end
		end
	end		
	return NearestRecce
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

-- stupid Moose does not keep detectedItems in their detection object we need to store out ourselfs if we want to have multiple RECONs and be able to 
-- report the status
local function getSimpleDetectionReport(coalition)	
	local simpleStart = "\nEnemy units are on the way to attack "
	local simpleEnd = " and it's surrounding territories. Deploy JTACs to the field and start Close Air Support coalition against the attack."
	local bases = ""
			
	if detectionStatus then
		for reconName, data in pairs(detectionStatus) do
			if coalition == data.coalition then
				bases = bases..data.airbase..","				
			end
		end
		bases = units:sub(1,-1)
		return simpleStart..bases..simpleEnd		
	end	
end

local function getFullDetectionReport(coalition)		
	local text = "\nRECON Airplane Detection Status:\n\n"		
	if detectionStatus then
		for reconName, recon in pairs(detectionStatus) do
			if coalition == recon.coalition then				
				for unitName, unit in pairs(recon.detected) do				
					if coalition == 2 then
						text = text..string.format("RECON: %s - %s - %s - Laser Code: %s\n", reconName, recon.airbase, unit:GetTypeName(), laserCodeBlue)
					elseif coalition == 1 then
						text = text..string.format("RECON: %s - %s - %s - Laser Code: %s\n", reconName, recon.airbase, unit:GetTypeName(), laserCodeRed)
					end
				end
			end
		end
	else
		text = text..string.format("RECON airplanes are not detecting any enemy units near by, or there is no RECON airplane in the air.\n")		
	end	
	return text
end

local function smokeAndLase(DetectedUnits, coalition)
	local unitAirbase = ""
	local reconAirbase = ""
	local nearestRECON = nil
		
	for _,detectedUnit in pairs(DetectedUnits) do		
		local detectionSet = nil -- I need to do all this, due to Moose bugs, their inheritance loses properites and their DetectedItem.NearestFAC is gone since they pass UNIT as oppose to DetectedItem
		if coalition == 1 then
			detectionSet = redDetection:GetDetectionSet()
		elseif coalition == 2 then
			detectionSet = blueDetection:GetDetectionSet()
		end		
		if detectionSet then
			nearestRECON = findNearestRecce(detectedUnit, detectionSet)			
			if nearestRECON then
				reconAirbase = utils.getNearestAirbase(nearestRECON:GetVec2(), coalition, Airbase.Category.AIRDROME)
				detectionStatus[nearestRECON:GetName()] = nil -- reset, this may need to run in OnAfterDetect to be able to remove the last item
				detectionStatus[nearestRECON:GetName()] = {airbase = reconAirbase, detected = DetectedUnits, coalition = coalition}				
			end			
		end
		unitAirbase = utils.getNearestAirbase(detectedUnit:GetVec2(), coalition, Airbase.Category.AIRDROME)			
		break
	end
			
	if isReadyToSmokeAgain() then
		utils.smokeUnits(DetectedUnits, 2, detectMaxCount)
		lastSmokedTime = timer.getTime()
	end	
	
	if isReadyToNotifyTeamAgain() then			
		trigger.action.outSoundForCoalition(coalition, "squelch.ogg")		
		timer.scheduleFunction(SendMessage, {getSimpleDetectionReport(coalition), coalition}, timer.getTime() + 2)
		timer.scheduleFunction(PlaySound, {"siren.ogg", coalition}, timer.getTime() + 4)
		lastNotifyTime = timer.getTime()
	end
	
	if nearestRECON then
		if coalition == 2 then
			utils.laseUnits(nearestRECON, DetectedUnits, detectInterval, laserCodeBlue, 1, detectMaxCount)
		elseif coalition == 1 then
			utils.laseUnits(nearestRECON, DetectedUnits, detectInterval, laserCodeRed, 1, detectMaxCount)			
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
    return string.format("Team has %i RECON airplanes in the air by: %s", reconCount, uavBases)    
  else
    return string.format("Team does not have any RECON Airplane in the air at the moment", reconCount)
  end  
end

-- this is called from the global on birth event handler
function ReconDrones.AddMenu(playerGroup)
	local playerName = playerGroup:GetPlayerName()
	local coalitionNumber = playerGroup:GetCoalition()	
	local menuRoot = MENU_GROUP:New(playerGroup, "RECON Operations")
	MENU_GROUP_COMMAND:New(playerGroup, "Spawn RECON Airplane 1 nm away", menuRoot, spawnUAV, playerGroup, 1, coalitionNumber, playerName)
	MENU_GROUP_COMMAND:New(playerGroup, "Spawn RECON Airplane 5 nm away", menuRoot, spawnUAV, playerGroup, 5, coalitionNumber, playerName)
	MENU_GROUP_COMMAND:New(playerGroup, "Spawn RECON Airplane 10 nm away", menuRoot, spawnUAV, playerGroup, 10, coalitionNumber, playerName)
	MENU_GROUP_COMMAND:New(playerGroup, "RECON Airplanes Remaining", menuRoot, function()
		trigger.action.outTextForCoalition(coalitionNumber, "[TEAM] Has " ..getDronesRemaining(coalitionNumber).. " Remaining RECON Airplanes", 15)
	end)
	MENU_GROUP_COMMAND:New(playerGroup, "Show RECON Airplane Locations", menuRoot, function()
		trigger.action.outTextForCoalition(coalitionNumber, showReconLocations(coalitionNumber), 15)		
	end)
	MENU_GROUP_COMMAND:New(playerGroup, "Show RECON Airplane Lasing Status", menuRoot, function()
		trigger.action.outTextForCoalition(coalitionNumber, getFullDetectionReport(coalitionNumber), 15)
	end)
end

function DroneSpawned:OnEventBirth(EventData)
	if string.find(inspect(EventData.IniDCSGroupName), "Pontiac") then 							
		local coalition = EventData.IniCoalition
		local vec = EventData.IniGroup:GetVec2()        
        local uavNearBase = utils.getNearestAirbase(vec, coalition, Airbase.Category.AIRDROME)
		trigger.action.outTextForCoalition(coalition,"[TEAM] " ..spawnerName.. " called in a RECON Airplane close to "..uavNearBase.."\nYour team has "..getDronesRemaining(coalition).." remaining RECON Airplanes.", 15)
	end
end