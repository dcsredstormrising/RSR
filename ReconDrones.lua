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
local droneMaxCount = 4 -- per session
local droneMaxCountAtOnce = 2
local detectMaxCount = 5
local detectionRange = 20000  --meters
local maxLaseDistane = 60000 -- I need this becuase of Moose bugs, I need to find the closest RECON airplane that is detecting the units.  More than 60,000 is crazy and shuld not lase from that far
local detectInterval = 20  -- this is also lase duration that resets each time detection runs-- super simple way to update laser
local smokeIntervalRed = 40 -- smoke will update in sec
local smokeIntervalBlue = 40 -- smoke will update in sec
local lastSmokedTimeRed = timer.getTime()
local lastSmokedTimeBlue = timer.getTime()
local lastNotifyTimeRed = timer.getTime()
local lastNotifyTimeBlue = timer.getTime()
local detectMessageIntervalRed = 60
local detectMessageIntervalBlue = 60
local blueDroneCount = 0
local redDroneCount = 0
local spawnerName = nil
local BlueRecceDetection = {}
local RedRecceDetection = {}
local detectionStatus = {}

-- setup
DroneSpawned = EVENTHANDLER:New()
DroneSpawned:HandleEvent(EVENTS.Birth)

DroneCrashed = EVENTHANDLER:New()
DroneCrashed:HandleEvent(EVENTS.Crash)

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
	if coalition == 2 then
		local diff = timer.getTime() - lastSmokedTimeRed	
		if diff > smokeIntervalRed then		
			return true
		end
	elseif coalition == 1 then
		local diff = timer.getTime() - lastSmokedTimeBlue	
		if diff > smokeIntervalBlue then		
			return true
		end
	end
end

local function isReadyToNotifyTeamAgain(coalition)
	if coalition == 2 then
		local diff = timer.getTime() - lastNotifyTimeRed	
		if diff > detectMessageIntervalRed then		
			return true
		end
	elseif coalition == 1 then
		local diff = timer.getTime() - lastNotifyTimeBlue	
		if diff > detectMessageIntervalBlue then		
			return true
		end
	end
end

local function resetSmokeTimer(coalition)
	if coalition == 2 then
		lastSmokedTimeRed = timer.getTime()
	elseif coalition == 1 then
		lastSmokedTimeBlue = timer.getTime()
	end
end

-- stupid Moose does not keep detectedItems in their detection object we need to store it ourselfs if we want to have multiple RECONs and be able to 
-- report the status
local function getSimpleDetectionReport(coalition)	
	local text = "\n\nEnemy units are on the way to attack"
	local bases = ""
					
	if detectionStatus then
		for reconName, data in pairs(detectionStatus) do
			if coalition == data.coalition then
				bases = bases.." "..data.airbase..","				
			end
		end
		bases = bases:sub(1,-1)
		text = text..bases		
		text = text.." and it's surrounding territories. Deploy JTACs to the field and start Close Air Support coalition against the attack.\n\n"
		text = text.."You may use the RECON menu to view the status of the RECON Operation.  The status will show you what units are being lased, where they are, and what laser codes to use.  "
		text = text.."Enemy units are also smoked by default.\n\n"
		
		return text
	end	
end

local function getFullDetectionReport(coalition)		
	local text = ""
	local startText = "\nOur RECON Operation Status:\n\n"
	local areReconsUpAndDetecting = false
	if detectionStatus then		
		for reconName, recon in pairs(detectionStatus) do			
			if coalition == recon.coalition then				
				for unitName, unit in pairs(recon.detected) do
					if unit and unit:IsAlive() then -- can't show those we are killing, our detection will eventually remove the item from the list
						areReconsUpAndDetecting = true
						if coalition == 2 then
							text = text..string.format("RECON: %s - %s - %s - Laser Code: %s\n", reconName, recon.airbase, unit:GetTypeName(), rsrConfig.ReconLaserCodeBlue)
						elseif coalition == 1 then
							text = text..string.format("RECON: %s - %s - %s - Laser Code: %s\n", reconName, recon.airbase, unit:GetTypeName(), rsrConfig.ReconLaserCodeRed)
						end
					end
				end
			end
		end
	end
	
	if areReconsUpAndDetecting then
		return startText..text
	else
		return startText..string.format("RECON airplanes are not detecting any enemy units near by, or there is no RECON airplane in the air.\n")		
	end
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
		local attackingCoalition = 0
		if coalition == 2 then
			attackingCoalition = 1
		elseif coalition == 1 then
			attackingCoalition = 2
		end
		utils.smokeUnits(DetectedUnits, attackingCoalition)
		timer.scheduleFunction(resetSmokeTimer, coalition, timer.getTime() + 5)	-- required for all instances of drones to run not just the first one	
	end	
	
	if isReadyToNotifyTeamAgain(coalition) then		
		trigger.action.outSoundForCoalition(coalition, "squelch.ogg")		
		timer.scheduleFunction(SendMessage, {getSimpleDetectionReport(coalition), coalition}, timer.getTime() + 2)
		timer.scheduleFunction(PlaySound, {"siren.ogg", coalition}, timer.getTime() + 4)
		
		if coalition == 2 then
			lastNotifyTimeBlue = timer.getTime()
		elseif coalition == 1 then
			lastNotifyTimeRed = timer.getTime()
		end
	end
	
	if nearestRECON then
		if coalition == 2 then
			utils.laseUnits(nearestRECON, DetectedUnits, detectInterval, rsrConfig.ReconLaserCodeBlue, 1)
		elseif coalition == 1 then
			utils.laseUnits(nearestRECON, DetectedUnits, detectInterval, rsrConfig.ReconLaserCodeRed, 1)			
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
		
		if redDroneCount < droneMaxCountAtOnce then -- that's right, Moose runs this thing and does not spawn it
			redDroneCount = redDroneCount + 1
		else
			trigger.action.outTextForCoalition(coalition,"[TEAM] already has maximum allowed RECON Airplanes in the air.", 15)
		end
		
		spawnerName = playerName
	elseif coalition == 2 then
		Spawn_Blue_UAV:SpawnFromVec2(spawnVec2)
		
		if redDroneCount < droneMaxCountAtOnce then -- that's right, Moose runs this thing and does not spawn it
			blueDroneCount = blueDroneCount + 1
		else
			trigger.action.outTextForCoalition(coalition,"[TEAM] already has maximum allowed RECON Airplanes in the air.", 15)
		end
		
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
		local text = "[TEAM] " ..spawnerName.. " called in a RECON Airplane close to "..uavNearBase.."\nYour team has "..getDronesRemaining(coalition).." remaining RECON Airplanes."
		if coalition == 2 then
			text = text.."\nYour RECON Airplane will be lasing with laser code: "..rsrConfig.ReconLaserCodeBlue
		elseif coalition == 1 then
			text = text.."\nYour RECON Airplane will be lasing with laser code: "..rsrConfig.ReconLaserCodeRed
		end
		trigger.action.outTextForCoalition(coalition, text, 15)
	end
end

function DroneCrashed:OnEventCrash(EventData)
	if string.find(inspect(EventData.IniUnitName), "Pontiac") then		
		local coalition = EventData.IniCoalition
		local unitName = EventData.IniDCSUnitName
		local unit = EventData.IniUnit		
		local vec = unit:GetVec2()
        local uavNearBase = utils.getNearestAirbase(vec, coalition, Airbase.Category.AIRDROME)		
		if unit then
			unit:LaseOff()	-- we turn off lasing for the RECON Airplane
			detectionStatus[unitName] = nil	 -- we set the detection to nil for that RECON airplane			
			trigger.action.outSoundForCoalition(coalition, "squelch.ogg")		
			timer.scheduleFunction(SendMessage, {"Our RECON Airplane "..unitName.." close to "..uavNearBase.." has been shut down.\nYour team has "..getDronesRemaining(coalition).." RECONS remaining.", coalition}, timer.getTime() + 2)			
		end
	end
end