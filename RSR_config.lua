-- RSR's configuration object
local utils = require("utils")
local rsrConfig = {}

-- enables "developer mode"; removes crate spawning/unpacking restrictions, more frequent saves
rsrConfig.devMode = false

-- Event reporting for the n0xy bot
rsrConfig.udpEventReporting = false
rsrConfig.udpEventHost = "localhost"
rsrConfig.udpEventPort = 9696

-- state saving
rsrConfig.stateFileName = utils.getFilePath("rsrState.json") -- default name for state file
rsrConfig.writeInterval = rsrConfig.devMode and 60 or 300 -- how often to update and write the state to disk in seconds
rsrConfig.writeDelay = rsrConfig.devMode and 10 or 180  -- initial delay for persistence, to move last one closer to restart

-- base defences
--mr: ensure that associated RSRbaseCaptureZone zone, which is used as a pre-filter, is larger than these values
-- CTLD_config.lua: ctld.RSRbaseCaptureZones = ctldUtils.getRSRbaseCaptureZones(env.mission)
rsrConfig.baseDefenceActivationRadiusAirbase = 5000
rsrConfig.baseDefenceActivationRadiusFARP = 2500

-- laser codes
-- =AW=33COM we need to standardize our laser codes, it's crazy that even developers don't know what the codes are in the game
-- this is a start, from now on we should use same 1 code for BLUE and 1 for RED.  There won't be problems like everyone is saying.
rsrConfig.ReconLaserCodeRed = 1686
rsrConfig.ReconLaserCodeBlue = 1687
rsrConfig.JTACLaserCodeRed = 1686
rsrConfig.JTACLaserCodeBlue = 1687

-- restart schedule
rsrConfig.firstRestartHour = 2 --this is UTC...apperently this is local machine time, setting it to 0100, had the server restart time calling at eastern.
rsrConfig.missionDurationInHours = 6
rsrConfig.restartHours = utils.getRestartHours(rsrConfig.firstRestartHour, rsrConfig.missionDurationInHours)

-- life points configuration
rsrConfig.livesPerHour = 1
-- added on 31st March 2020 as an experiment in "unlimited lives"
-- tuning ratio for adjusting number of lives without giving more weapons per restart
rsrConfig.livesMultiplier = 1
rsrConfig.maxLives = math.floor(rsrConfig.missionDurationInHours * rsrConfig.livesPerHour * rsrConfig.livesMultiplier + 0.5)

-- Ai CAP configuration
if env.mission.theatre == "Syria" then	
	rsrConfig.blueAiCAPAirbase = AIRBASE.Syria.Incirlik
	rsrConfig.redAiCAPAirbase = AIRBASE.Syria.Damascus	
elseif env.mission.theatre == "Caucasus" then	
	rsrConfig.blueAiCAPAirbase = AIRBASE.Caucasus.Kutaisi
	rsrConfig.redAiCAPAirbase = AIRBASE.Caucasus.Maykop_Khanskaya	
end

-- global message configuration
rsrConfig.restartWarningMinutes = { 60, 45, 30, 20, 15, 10, 5, 3, 1 } -- times in minutes before restart to broadcast message
rsrConfig.hitMessageDelay = 30

-- staging bases that never change side, never have logisitics centres and cannot be distinguished from FARP helipads
rsrConfig.stagingBases = {"RedStagingPoint", "BlueStagingPoint", "Carrier Dock", "Carrier Tarawa"}

-- configure DOCK and Tarawa to be like CCs and be able to pickup crates from moving zones
rsrConfig.redCCCarrier = "Carrier Dock"
rsrConfig.blueCCCarrier = "Carrier Tarawa"
rsrConfig.redCCCarrierZone = "Carrier Dock PickUp"
rsrConfig.blueCCCarrierZone = "Carrier Tarawa PickUp"
local carrierUnitRED = UNIT:FindByName(rsrConfig.redCCCarrier)
local carrierUnitBLUE = UNIT:FindByName(rsrConfig.blueCCCarrier)
ZONE_UNIT:New(rsrConfig.blueCCCarrierZone, carrierUnitBLUE, 410)
ZONE_UNIT:New(rsrConfig.redCCCarrierZone, carrierUnitRED, 410)
return rsrConfig
