--[[
    Combat Troop and Logistics Drop
    Allows Huey, Mi-8 and C130 to transport troops internally and Helicopters to transport Logistic / Vehicle units to the field via sling-loads
    without requiring external mods.
    Supports all of the original CTTS functionality such as AI auto troop load and unload as well as group spawning and preloading of troops into units.
    Supports deployment of Auto Lasing JTAC to the field
    See https://github.com/ciribob/DCS-CTLD for a user manual and the latest version
  Contributors:
      - Steggles - https://github.com/Bob7heBuilder
      - mvee - https://github.com/mvee
      - jmontleon - https://github.com/jmontleon
      - emilianomolina - https://github.com/emilianomolina
    Version: 1.73 - 15/04/2018
      - Allow minimum distance from friendly logistics to be set
	  
	  =AW=33COM Fixed JTAC for cargo planes.  Weight of crates does matter.
 ]]
-- luacheck: no max comment line length
local ctldUtils = require("ctldUtils")

ctld = {} -- DONT REMOVE!

-- ************************************************************************
-- *********************  USER CONFIGURATION ******************************
-- ************************************************************************
ctld.debug = false -- Set true to turn off logistics distances, to test crates
ctld.disableAllSmoke = true -- if true, all smoke is diabled at pickup and drop off zones regardless of settings below. Leave false to respect settings below

ctld.hoverPickup = false --  if set to false you can load internal crates with the F10 menu instead of hovering... Only if not using real crates!

ctld.enableCrates = true -- if false, Helis will not be able to spawn or unpack crates so will be normal CTTS
ctld.internalCargo = true -- if true, allow the internal carriage of some cargo
ctld.slingLoad = true -- if false, crates can be used WITHOUT slingloading, by hovering above the crate, simulating slingloading but not the weight...
-- There are some bug with Sling-loading that can cause crashes, if these occur set slingLoad to false
-- to use the other method.
-- Set staticBugFix  to FALSE if use set ctld.slingLoad to TRUE

ctld.enableSmokeDrop = true -- if false, helis and c-130 will not be able to drop smoke

ctld.maxExtractDistance = 200 -- max distance from vehicle to troops to allow a group extraction
ctld.maximumDistanceLogistic = 200 -- max distance from vehicle to logistics to allow a loading or spawning operation
ctld.maximumSearchDistance = 0 -- max distance for troops to search for enemy
ctld.maximumMoveDistance = 0 -- max distance for troops to move from drop point if no enemy is nearby

ctld.minimumDeployDistance = 600 -- minimum distance from a friendly pickup zone where you can deploy a crate
ctld.maximumCrateDistanceForLoading = 150 -- maximum distance from a crate to allow internal loading

ctld.numberOfTroops = 10 -- default number of troops to load on a transport heli or C-130
-- also works as maximum size of group that'll fit into a helicopter unless overridden
ctld.enableFastRopeInsertion = true -- allows you to drop troops by fast rope
ctld.fastRopeMaximumHeight = 18.28 -- in meters which is 60 ft max fast rope (not rappell) safe height

ctld.vehiclesForTransportRED = { "BRDM-2", "BTR_D" } -- vehicles to load onto Il-76 - Alternatives {"Strela-1 9P31","BMP-1"}
ctld.vehiclesForTransportBLUE = { "M1045 HMMWV TOW", "M1043 HMMWV Armament" } -- vehicles to load onto c130 - Alternatives {"M1128 Stryker MGS","M1097 Avenger"}

ctld.spawnRPGWithCoalition = true --spawns a friendly RPG unit with Coalition forces
ctld.spawnStinger = true -- spawns a stinger / igla soldier with a group of 6 or more soldiers!

ctld.enabledFOBBuilding = true -- if true, you can load a crate INTO a C-130 than when unpacked creates a Logistics Centre which is a new place to spawn (crates) and carry crates from
-- In future i'd like it to be a FARP but so far that seems impossible...
-- You can also enable troop Pickup at S

ctld.cratesRequiredForLogisticsCentre = 1 -- The amount of crates required to build a Logistics Centre. Once built, helis can spawn crates at this outpost to be carried and deployed in another area.
-- The large crates can only be loaded and dropped by large aircraft, like the C-130 and listed in ctld.vehicleTransportEnabled
-- Small Logistics Centre crates can be moved by helicopter. The Logistics Centre will require ctld.cratesRequiredForLogisticsCentre larges crates and small crates are 1/3 of a large Logistics Centre crate
-- To build the Logistics Centre entirely out of small crates you will need ctld.cratesRequiredForLogisticsCentre * 3

ctld.troopPickupAtFOB = true -- if true, troops can also be picked up at a created FOB

ctld.buildTimeFOB = 60 --time in seconds for the FOB to be built

ctld.crateWaitTime = 1 -- time in seconds to wait before you can spawn another crate

ctld.forceCrateToBeMoved = false -- a crate must be picked up at least once and moved before it can be unpacked. Helps to reduce crate spam. Only works if ctld.slingLoad = false -Swallow you might want to change this to True

ctld.radioSound = "beacon.ogg" -- the name of the sound file to use for the FOB radio beacons. If this isnt added to the mission BEACONS WONT WORK!
ctld.radioSoundFC3 = "beaconsilent.ogg" -- name of the second silent radio file, used so FC3 aircraft dont hear ALL the beacon noises... :)

ctld.deployedBeaconBattery = 30 -- the battery on deployed beacons will last for this number minutes before needing to be re-deployed

ctld.enabledRadioBeaconDrop = false -- if its set to false then beacons cannot be dropped by units

ctld.allowRandomAiTeamPickups = false -- Allows the AI to randomize the loading of infantry teams (specified below) at pickup zones

ctld.heavyCrateWeightMultiplier = 3 -- weight multiplier applied to the weight of light crates to create heavy ones

ctld.ewrFrequencyRed = 124
ctld.ewrFrequencyBlue = 124

-- Simulated Sling load configuration

ctld.minimumHoverHeight = 7.5 -- Lowest allowable height for crate hover
ctld.maximumHoverHeight = 18.0 -- Highest allowable height for crate hover
ctld.maxDistanceFromCrate = 8.0 -- Maximum distance from from crate for hover
ctld.hoverTime = 4 -- Time to hold hover above a crate for loading in seconds

-- end of Simulated Sling load configuration
-- AA SYSTEM CONFIG --
-- Sets a limit on the number of active AA systems that can be built for RED.
-- A system is counted as Active if its fully functional and has all parts
-- If a system is partially destroyed, it no longer counts towards the total
-- When this limit is hit, a player will still be able to get crates for an AA system, just unable
-- to unpack them

ctld.completeAASystemsTag = "AASystem" -- This is the tag in ME and in code that defines AA system and allows us to repair them
ctld.AASystemLimitRED = 35 -- Red side limit  -- this has to be 30 (20 player, 10 static) now or a rewrite to CTLD is required since we now count static sams in order to repair them
ctld.AASystemLimitBLUE = 35 -- Blue side limit -- this has to be 30 now or a rewrite to CTLD is required since we now count static sams in order to repair them
ctld.aaSR2Launchers = 2 -- controls how many launchers to add to Short Range Missile systems: Roland, HQ when spawned.
ctld.aaSRLaunchers = 3 -- controls how many launchers to add to Short Range Missile systems when spawned.
ctld.aaMRLaunchers = 4 -- controls how many launchers to add to Medium Range Missile systems when spawned.
ctld.aaLRLaunchers = 5 -- controls how many launchers to add to Long Range Missile systems when spawned.
ctld.aaSLRLaunchers = 8 -- controls how many launchers to add to Super Long Range Missile systems when spawned. (Patriot)
ctld.launcherRadius = 100 -- distance from crate for spawned launchers
ctld.patriotSTRRadius = 100
ctld.hawkSTRRadius = 100
ctld.s300STRRadius = 100
--END AA SYSTEM CONFIG --


-- ****************** SLING GROUP LIMIT ****************** 
-- In order to create upper limit for how many units we have on the server, we decided to impose a 200 unit limit per side.
-- And here is the code for limiting how many units can be slung by players during a round.
-- We assume 1 sam is 1 unit.  2 tanks in a group (T55s) is 1 unit.  2 HQs is 1 unit.  Anything that we spawn as a set is 1 unit.
-- Basically the limit is by number of groups
-- If a player repairs a sam system that was part of the mission, that sam system becomes a player slung system and it counts towards the limit. I am not rewritting CTLD to fix that. 
ctld.GroupLimitCount = 230  -- RED/BLUE side total group limit

-- units in the table below are not counted towards the ctld.GroupLimitCount.  True next to the unit is required for speed
ctld.UnitTypesOutsideOfGroupLimit = {['Kub Repair']=true,['HQ-7 Repair']=true,['Buk Repair']=true,['SA-2 Repair']=true,['SA-3 Repair']=true,['SA-10 Repair']=true,['Hawk Repair']=true,['Patriot Repair']=true,['Rapier Repair']=true,['Roland Repair']=true,['Silkworm Repair']=true,['Tigr_233036']=true,['Hummer']=true,['M 818']=true,['M978 HEMTT Tanker']=true,['KAMAZ Truck']=true,['ATZ-10']=true,['1L13 EWR']=true,['55G6 EWR']=true,['LogisticsCentre']=true}


-- ***************** JTAC CONFIGURATION *****************

ctld.JTAC_LIMIT_RED = 20 -- max number of JTAC Crates for the RED Side
ctld.JTAC_LIMIT_BLUE = 20 -- max number of JTAC Crates for the BLUE Side

-- we need to update our code to use this as oppose to hardcoding them
ctld.JTAC_TYPE_RED = "Tigr_233036"
ctld.JTAC_TYPE_BLUE = "Hummer"

ctld.JTAC_LIMIT_perPLAYER_perSIDE = 2 -- max number of JTACs per player
ctld.JTACsPerUCIDPerSide = {} -- list of players and their JTACs per side

ctld.JTAC_dropEnabled = true -- allow JTAC Crate spawn from F10 menu

ctld.JTAC_maxDistance = 10000 -- How far a JTAC can "see" in meters (with Line of Sight)

ctld.JTAC_smokeOn_RED = true -- enables marking of target with smoke for RED forces
ctld.JTAC_smokeOn_BLUE = true -- enables marking of target with smoke for BLUE forces

ctld.JTAC_smokeColour_RED = 4 -- RED side smoke colour -- Green = 0 , Red = 1, White = 2, Orange = 3, Blue = 4
ctld.JTAC_smokeColour_BLUE = 1 -- BLUE side smoke colour -- Green = 0 , Red = 1, White = 2, Orange = 3, Blue = 4

ctld.JTAC_jtacStatusF10 = true -- enables F10 JTAC Status menu

ctld.JTAC_location = true -- shows location of target in JTAC message
ctld.location_DMS = false -- shows coordinates as Degrees Minutes Seconds instead of Degrees Decimal minutes

ctld.JTAC_lock = "all" -- "vehicle" OR "troop" OR "all" forces JTAC to only lock vehicles or troops or all ground units

-- ***************** Pickup, dropoff and waypoint zones *****************

-- Available colors (anything else like "none" disables smoke): "green", "red", "white", "orange", "blue", "none",

-- Use any of the predefined names or set your own ones

-- You can add number as a third option to limit the number of soldier or vehicle groups that can be loaded from a zone.
-- Dropping back a group at a limited zone will add one more to the limit

-- If a zone isn't ACTIVE then you can't pickup from that zone until the zone is activated by ctld.activatePickupZone
-- using the Mission editor

-- You can pickup from a SHIP by adding the SHIP UNIT NAME instead of a zone name

-- Side - Controls which side can load/unload troops at the zone

-- Flag Number - Optional last field. If set the current number of groups remaining can be obtained from the flag value


ctld.RSRbaseCaptureZones = ctldUtils.getRSRbaseCaptureZones(env.mission)
ctld.RSRcarrierActivateZones = ctldUtils.getRSRcarrierActivateZones(env.mission)

--pickupZones = { "Zone name or Ship Unit Name", "smoke color", "limit (-1 unlimited)", "ACTIVE (yes/no)", "side (0 = Both sides / 1 = Red / 2 = Blue )", flag number (optional) }
ctld.pickupZones = ctldUtils.getPickupZones(env.mission)


-- dropOffZones = {"name","smoke colour",0,side 1 = Red or 2 = Blue or 0 = Both sides}
ctld.dropOffZones = {
    { "dropzone1", "green", 2 },
    { "dropzone2", "blue", 2 },
    { "dropzone3", "orange", 2 },
    { "dropzone4", "none", 2 },
    { "dropzone5", "none", 1 },
    { "dropzone6", "none", 1 },
    { "dropzone7", "none", 1 },
    { "dropzone8", "none", 1 },
    { "dropzone9", "none", 1 },
    { "dropzone10", "none", 1 },
}


--wpZones = { "Zone name", "smoke color",  "ACTIVE (yes/no)", "side (0 = Both sides / 1 = Red / 2 = Blue )", }
ctld.wpZones = {
    { "wpzone1", "green", "yes", 2 },
    { "wpzone2", "blue", "yes", 2 },
    { "wpzone3", "orange", "yes", 2 },
    { "wpzone4", "none", "yes", 2 },
    { "wpzone5", "none", "yes", 2 },
    { "wpzone6", "none", "yes", 1 },
    { "wpzone7", "none", "yes", 1 },
    { "wpzone8", "none", "yes", 1 },
    { "wpzone9", "none", "yes", 1 },
    { "wpzone10", "none", "no", 0 }, -- Both sides as its set to 0
}


-- ******************** Transports names **********************

-- Use any of the predefined names or set your own ones
ctld.transportPilotNames = ctldUtils.getTransportPilotNames(env.mission)

-- *************** Optional Extractable GROUPS *****************

-- Use any of the predefined names or set your own ones

ctld.extractableGroups = {
    "extract1",
    "extract2",
    "extract3",
    "extract4",
    "extract5",
    "extract6",
    "extract7",
    "extract8",
    "extract9",
    "extract10",


}

-- ************** Logistics UNITS FOR CRATE SPAWNING ******************

-- Use any of the predefined names or set your own ones
-- When a logistic unit is destroyed, you will no longer be able to spawn crates

ctld.logisticCentreZones = ctldUtils.getLogisticCentreZones(env.mission)

-- ************** UNITS ABLE TO TRANSPORT VEHICLES ******************
-- Add the model name of the unit that you want to be able to transport and deploy vehicles
-- units db has all the names or you can extract a mission.miz file by making it a zip and looking
-- in the contained mission file
ctld.vehicleTransportEnabled = {
    "76MD", -- the il-76 mod doesnt use a normal - sign so il-76md wont match... !!!! GRR
    "C-130",
}

-- cargo planes only where crates = false below in ctld.unitActions
-- add to this list only if aircraft cannot transport vehicles, otherwise menu options duplicated
--ctld.internalCargoEnabled = {
ctld.cargoPlanes = {
    "C-101CC",
    "L-39ZA",
    "MiG-15bis",
    "F-86F Sabre",
    "TF-51D",
    "Bf-109K-4",
    "FW-190D9",
    "FW-190A8",
    "I-16",
    "SpitfireLFMkIX",
    "SpitfireLFMkIXCW",
    "P-51D",
    "P-51D-30-NA",
    "Christen Eagle II",
    "Yak-52"
}


-- ************** Maximum Units SETUP for UNITS ******************

-- Put the name of the Unit you want to limit group sizes too
-- i.e
-- ["UH-1H"] = 10,
--
-- Will limit UH1 to only transport groups with a size 10 or less
-- Make sure the unit name is exactly right or it wont work

ctld.unitLoadLimits = {

    ["CH-47D"] = 33,
    ---
    ["UH-1H"] = 10,
    ["Mi-8MT"] = 20,
	["Mi-24P"] = 10,
    ["SA342Minigun"] = 1,
    ["SA342M"] = 1,
    ["SA342L"] = 1,
    --["Ka-50"] = 1,
    ---
    ["C-101CC"] = 1,
    ["L-39ZA"] = 1,
    ---
    ["MiG-15bis"] = 1,
    ["F-86F Sabre"] = 1,
    ---
    ["TF-51D"] = 1,
    ["Bf-109K-4"] = 1,
    ["FW-190D9"] = 1,
    ["FW-190A8"] = 1,
    ["I-16"] = 1,
    ["SpitfireLFMkIX"] = 1,
    ["SpitfireLFMkIXCW"] = 1,
    ["P-51D"] = 1,
    ["P-51D-30-NA"] = 1,
    ["Christen Eagle II"] = 1,
    ["Yak-52"] = 1
}


-- ************** Allowable actions for UNIT TYPES ******************

-- Put the name of the Unit you want to limit actions for
-- NOTE - the unit must've been listed in the transportPilotNames list above
-- This can be used in conjunction with the options above for group sizes
-- By default you can load both crates and troops unless overriden below
-- i.e
-- ["UH-1H"] = {crates=true, troops=false},
--
-- Will limit UH1 to only transport CRATES but NOT TROOPS
--
-- ["SA342Mistral"] = {crates=fales, troops=true},
-- Will allow Mistral Gazelle to only transport crates, not troops

ctld.unitActions = {

    -- Remove the -- below to turn on options
    --["SA342Mistral"] = { crates = false, troops = false, internal = false },
    ["SA342Minigun"] = { crates = false, troops = true, internal = false },
    ["SA342L"] = { crates = false, troops = true, internal = false },
    ["SA342M"] = { crates = false, troops = true, internal = false },
    ["Ka-50"] = { crates = true, troops = false, internal = false },
    ["UH-1H"] = { crates = true, troops = true, internal = true },
    ["Mi-8MT"] = { crates = true, troops = true, internal = true },
	["Mi-24P"] = { crates = true, troops = true, internal = true },

    --allowing 'troops' necessary to allow cargo plane actions for internal cargo load/unload in absence of 'crates' allowance
    ["C-101CC"] = { crates = false, troops = true, internal = true },
    ["L-39ZA"] = { crates = false, troops = true, internal = true },
    ----
    ["MiG-15bis"] = { crates = false, troops = true, internal = true },
    ["F-86F Sabre"] = { crates = false, troops = true, internal = true },
    ----
    ["TF-51D"] = { crates = false, troops = true, internal = true },
    ["Bf-109K-4"] = { crates = false, troops = true, internal = true },
    ["FW-190D9"] = { crates = false, troops = true, internal = true },
    ["FW-190A8"] = { crates = false, troops = true, internal = true },
    ["I-16"] = { crates = false, troops = true, internal = true },
    ["SpitfireLFMkIX"] = { crates = false, troops = true, internal = true },
    ["SpitfireLFMkIXCW"] = { crates = false, troops = true, internal = true },
    ["P-51D"] = { crates = false, troops = true, internal = true },
    ["P-51D-30-NA"] = { crates = false, troops = true, internal = true },
    ["Christen Eagle II"] = { crates = false, troops = true, internal = true },
    ["Yak-52"] = { crates = false, troops = true, internal = true }
}

-- allow cargo planes and helos to carry troops and internal crates simultaneously
ctld.simultaneousTroopInternalCrateLoad = true

--transportTypes in missionUtils.lua
--ctld.transportTypes unused and not able to be included in missionUtils.lua due to loop creation
ctld.transportTypes = {

    --"SA342Mistral",
    "SA342L",
    "SA342M",
    "SA342Minigun",
    "Ka-50",
    "UH-1H",
    "Mi-8MT",
	"Mi-24P",
    ----
    "C-101CC",
    "L-39ZA",
    ----
    "MiG-15bis",
    "F-86F Sabre",
    ----
    "TF-51D",
    "Bf-109K-4",
    "FW-190D9",
    "FW-190A8",
    "I-16",
    "SpitfireLFMkIX",
    "SpitfireLFMkIXCW",
    "P-51D",
    "P-51D-30-NA",
    "Christen Eagle II",
    "Yak-52"
}

-- ************** INFANTRY GROUPS FOR PICKUP ******************
-- Unit Types
-- inf is normal infantry
-- mg is M249
-- at is RPG-16
-- aa is Stinger or Igla
-- mortar is a 2B11 mortar unit
-- You must add a name to the group for it to work
-- You can also add an optional coalition side to limit the group to one side
-- for the side - 2 is BLUE and 1 is RED
-- {name = "Mortar Squad Red", inf = 2, mortar = 5, side =1 }, --would make a group loadable by RED only
ctld.loadableGroupsHelis = {
    { name = "Infantry Squad: \n    5 x AK/M4, 2 x MGs", inf = 5, mg = 2 }, 
    --{ name = "Infantry Platoon [Mi-8]: \n    10 x AK/M4, 4 x MGs, 2 x AT", inf = 10, mg = 4, at = 2 },
    { name = "Anti-Air Squad: \n    2 x MANPAD", aa = 2 },
    { name = "Anti-Tank Squad: \n    2 x AK/M4, 4 x AT", inf = 2, at = 4 },
    { name = "Artillery Squad: \n    6 x Mortar", mortar = 6 },
  ----
    { name = "Rifle Infantry: 1 x AK/M4", inf = 1 },
    { name = "MG Infantry: 1 x MG", mg = 1 },
    { name = "Anti-Air Infantry: 1 x MANPAD", aa = 1 },
    { name = "Anti-Tank Infantry: 1 x AT", at = 1 },
    { name = "Artillery Infantry: 1 x Mortar", mortar = 1 },
}

--duplicated list for cargo planes
ctld.loadableGroupsCargoPlanes = {
    { name = "Rifle Infantry: \n    1 x AK/M4", inf = 1 },
    --{ name = "MG Infantry: \n    1 x MG", mg = 1 },
    --{ name = "Anti-Air Infantry: 1 x MANPAD", aa = 1 },
    --{ name = "Anti-Tank Infantry: 1 x AT", at = 1 },
    --{ name = "Artillery Infantry: 1 x Mortar", mortar = 1 },
}

-- ************** CC / Logistic Centre Building Types ******************

ctld.logisticCentreL1 = "FARP Tent"
ctld.logisticCentreL2 = "outpost"
--ctld.logisticCentreL2 = ".Command Center"
--ctld.logisticCentreL3 = ".Command Center"
ctld.logisticCentreL3 = "Shelter"

ctld.maximumDistFromFARPToRepair = 3000
ctld.maximumDistFromAirbaseToRepair = 5000

--[[
  FOBs need to be excluded > 10km from airbases, FARPs and other FOBs 
  - for balancing given that logistics centre crates are available from FOBs and logistics centre destruction required for all captures
  - prevent multiple FOBs within an airbase/FARP
  - for ctld.spawnLogisticsCentre referencing as each FOB named after it's airbase or MGRS grid which is a 10km square
  - detection of player within airbase of FARP to initiate repair c.f. FOB deployment
  - FOB building being an outpost is somewhat camouflaged in towns c.f. bunker building in airbases/FARPs
  - FOB building being an outpost being a neutral coalition object won't be detected by red/blue ground units
--]]
ctld.exclusionZoneFromBasesForFOBs = 10000 --10km
ctld.friendlyLogisiticsCentreSpacing = 10000 --10km
ctld.allowLogisticsCentreCratesFromFOBs = false

--need to ensure country is part of neutral coalition e.g. Greece, as neutral static objects will not block DCS controlled rearm/refuel
ctld.neutralCountry = "Greece"

--[[
  ctld.logisticCentreObjects populated upon spawning logistics centre static object with:
    - airbase, FARP or FOB grid + "FOB (e.g. "CK61 FOB") name as index
  seperate lists for red and blue teams to allow for rare occurence of FOBs from both team in same grid
  due to spacing ctld.friendlyLogisiticsCentreSpacing restrictions, friendly FOBs should never be in the same 10km grid, important for referencing
  important that only 1 logisitics centre per base due to baseOwnershipCheck.lua referencing elsewhere
    i.e.  _LCobj = ctld.logisticCentreObjects[_sideName][_baseORfobName][1]
--]]
ctld.logisticCentreObjects = { red = {}, blue = {} }

--table of marker IDs for coalition associated markers of each logisitics centre
ctld.logisticCentreMarkerID = { red = {}, blue = {} }

-- airbases/FARPs that if within, do not require a logisitics centre to be present e.g. Gas Platforms
ctld.logisticCentreNotReqInBase = {"RedStagingPoint", "BlueStagingPoint", "Carrier Dock", "Carrier Tarawa"}

-- ************** SPAWNABLE CRATES ******************
-- Weights must be unique as we use the weight to change the cargo to the correct unit
-- when we unpack

-- =AW=33COM, This was added to control the order of menu for slinging. Names in here must match the names in ctld.spawnableCrates, this is case sensitive
-- This is requried now in order for the CTLD to run, as CTLD uses this
ctld.spawnableCratesOrdered = 
{
	"Artillery","AAA","IFVs & Light Vehicles","Tanks","Short Range SAMs","Medium Range SAMs","Long Range SAMs","SAM Repairs","Missiles","Support"
}

ctld.spawnableCrates = {
    -- name of the sub menu on F10 for spawning crates
    --crates you can spawn
    -- weight in KG
    -- Desc is the description on the F10 MENU
    -- unit is the model name of the unit to spawn
    -- cratesRequired - if set requires that many crates of the same type within 100m of each other in order build the unit
    -- side is optional but 2 is BLUE and 1 is RED
    -- internal is cargo can be carried in internal bays, set 0 for external.
	
	  ["Artillery"] = {
	  
		-- RED
        { weight = 871, desc = "2S9 Nona", unit = "2S9 Nona", side = 1, cratesRequired = 1, unitQuantity = 2, internal = 1 },
        { weight = 768, desc = "PLZ-05", unit = "PLZ05", side = 1, cratesRequired = 1, unitQuantity = 2, internal = 1 },        		
		    { weight = 720, desc = "SAU Akatsia", unit = "SAU Akatsia", cratesRequired = 1, unitQuantity = 2, internal = 1 },
        { weight = 872, desc = "SAU Gvozdika", unit = "SAU Gvozdika", side = 1, cratesRequired = 1, unitQuantity = 2, internal = 1 },
        { weight = 873, desc = "SPH 2S19 Msta", unit = "SAU Msta", side = 1, cratesRequired = 1, unitQuantity = 2, internal = 1 },
        { weight = 903, desc = "MLRS Grad", unit = "Grad-URAL", side = 1, cratesRequired = 2, unitQuantity = 2, internal = 1 },
        { weight = 905, desc = "MLRS Uragan", unit = "Uragan_BM-27", side = 1, cratesRequired = 3, unitQuantity = 2, internal = 1 },
        { weight = 874, desc = "MLRS Smerch HE", unit = "Smerch_HE", side = 1, cratesRequired = 4, unitQuantity = 2, internal = 1 },
        { weight = 875, desc = "MLRS Smerch", unit = "Smerch", side = 1, cratesRequired = 4, unitQuantity = 2, internal = 1 }, 

		-- BLUE
		    { weight = 889, desc = "T-155 Firtina", unit = "T155_Firtina", side = 2, cratesRequired = 1, unitQuantity = 1, internal = 1 },
        { weight = 877, desc = "SpGH DANA", unit = "SpGH_Dana", side = 2, cratesRequired = 1, unitQuantity = 2, internal = 1 },
        { weight = 878, desc = "M-109", unit = "M-109", side = 2, cratesRequired = 1, unitQuantity = 2, internal = 1 },
        { weight = 900, desc = "MLRS Grad", unit = "Grad-URAL", side = 2, cratesRequired = 2, unitQuantity = 2, internal = 1 },
        { weight = 879, desc = "MLRS", unit = "MLRS", side = 2, cratesRequired = 3, unitQuantity = 2, internal = 1 },
        { weight = 902, desc = "MLRS Uragan", unit = "Uragan_BM-27", side = 2, cratesRequired = 3, unitQuantity = 2, internal = 1 },			
    },
		["AAA"] = {
		
		{ weight = 836, desc = "Bofors 40mm AAA Gun", unit = "bofors40", cratesRequired = 1, unitQuantity = 2, internal = 1 },
        { weight = 837, desc = "Flak 18 AAA Gun", unit = "flak18", cratesRequired = 1, unitQuantity = 2, internal = 1 },		
	
		--RED        	
    		{ weight = 778, desc = "AZP S-60", unit = "S-60_Type59_Artillery", side = 1, cratesRequired = 1, unitQuantity = 1, internal = 1 },			
    		{ weight = 736, desc = "ZU-23 Emplacement", unit = "ZU-23 Emplacement", side = 1, cratesRequired = 1, unitQuantity = 1, internal = 1 },		
    		{ weight = 706, desc = "ZU-23 Emplacement Closed", unit = "ZU-23 Emplacement Closed", side = 1, cratesRequired = 1, unitQuantity = 1, internal = 1 },		
    		{ weight = 705, desc = "Ural-375 ZU-23", unit = "Ural-375 ZU-23", side = 1, cratesRequired = 1, unitQuantity = 2, internal = 1 },
        { weight = 825, desc = "ZSU-23-4 Shilka", unit = "ZSU-23-4 Shilka", side = 1, cratesRequired = 1, unitQuantity = 2, internal = 1 },
        { weight = 826, desc = "ZSU-57-2", unit = "ZSU_57_2", side = 1, cratesRequired = 1, unitQuantity = 2, internal = 1 },
        
		--BLUE
        { weight = 835, desc = "M163 Vulcan", unit = "Vulcan", side = 2, cratesRequired = 1, unitQuantity = 2, internal = 1 },                
        { weight = 838, desc = "Gepard", unit = "Gepard", side = 2, cratesRequired = 1, unitQuantity = 2, internal = 1 },
    },

    ["IFVs & Light Vehicles"] = {
	
		-- RED
        { weight = 800, desc = "BTR-80", unit = "BTR-80", side = 1, cratesRequired = 1, unitQuantity = 2, internal = 1 },
    		{ weight = 700, desc = "BTR-82A", unit = "BTR-82A", side = 1, cratesRequired = 1, unitQuantity = 2, internal = 1 },
    		{ weight = 701, desc = "BTR-RD", unit = "BTR-RD", side = 1, cratesRequired = 1, unitQuantity = 2, internal = 1 },				
    		{ weight = 702, desc = "IFV BMD-1", unit = "BMD-1", side = 1, cratesRequired = 1, unitQuantity = 2, internal = 1 },
        { weight = 801, desc = "IFV BMP-1", unit = "BMP-1", side = 1, cratesRequired = 1, unitQuantity = 2, internal = 1 },		
        { weight = 802, desc = "IFV BMP-2", unit = "BMP-2", side = 1, cratesRequired = 1, unitQuantity = 2, internal = 1 },
        { weight = 803, desc = "IFV BMP-3", unit = "BMP-3", side = 1, cratesRequired = 1, unitQuantity = 1, internal = 1 },
        { weight = 804, desc = "IFV ZBD04A", unit = "ZBD04A", side = 1, cratesRequired = 1, unitQuantity = 1, internal = 1 },
        		
		-- BLUE
  		  { weight = 726, desc = "AAV7", unit = "AAV7", side = 2, cratesRequired = 1, unitQuantity = 2, internal = 1 },		
  		  { weight = 703, desc = "ATGM VAB Mephisto", unit = "VAB_Mephisto", side = 2, cratesRequired = 1, unitQuantity = 1, internal = 1 },
        { weight = 807, desc = "HMMWV TOW", unit = "M1045 HMMWV TOW", side = 2, cratesRequired = 1, unitQuantity = 2, internal = 1 },
        { weight = 808, desc = "IFV Marder", unit = "Marder", side = 2, cratesRequired = 1, unitQuantity = 2, internal = 1 },				
    		{ weight = 740, desc = "LAV-25", unit = "LAV-25", side = 2, cratesRequired = 1, unitQuantity = 2, internal = 1 },
    		{ weight = 741, desc = "MCV-80 Warrior", unit = "MCV-80", side = 2, cratesRequired = 1, unitQuantity = 1, internal = 1 },		
    		{ weight = 704, desc = "Stryker ICV", unit = "M1126 Stryker ICV", side = 2, cratesRequired = 1, unitQuantity = 2, internal = 1 },
        { weight = 809, desc = "Stryker ATGM", unit = "M1134 Stryker ATGM", side = 2, cratesRequired = 1, unitQuantity = 1, internal = 1 },
        { weight = 810, desc = "Stryker MGS", unit = "M1128 Stryker MGS", side = 2, cratesRequired = 1, unitQuantity = 1, internal = 1 },
        { weight = 811, desc = "IFV BRADLEY", unit = "M-2 Bradley", side = 2, cratesRequired = 1, unitQuantity = 1, internal = 1 },        
    },

    ["Tanks"] = {
	
		-- RED
		    { weight = 666, desc = "PT-76", unit = "PT_76", side = 1, cratesRequired = 1, unitQuantity = 1, internal = 1 },		    
        { weight = 814, desc = "T-55", unit = "T-55", side = 1, cratesRequired = 1, unitQuantity = 1, internal = 1 },
        { weight = 815, desc = "T-72", unit = "T-72B", side = 1, cratesRequired = 2, unitQuantity = 1, internal = 1 },
		    { weight = 739, desc = "T-72B3", unit = "T-72B3", side = 1, cratesRequired = 3, unitQuantity = 1, internal = 1 },
        { weight = 816, desc = "T-80UD", unit = "T-80UD", side = 1, cratesRequired = 3, unitQuantity = 1, internal = 1 },
        { weight = 817, desc = "T-90", unit = "T-90", side = 1, cratesRequired = 3, unitQuantity = 1, internal = 1 },
        { weight = 818, desc = "ZTZ-96B", unit = "ZTZ96B", side = 1, cratesRequired = 3, unitQuantity = 1, internal = 1 },
        { weight = 819, desc = "LeClerc", unit = "Leclerc", side = 1, cratesRequired = 4, unitQuantity = 1, internal = 1 },

		-- BLUE
        { weight = 820, desc = "Leopard 1A3", unit = "Leopard1A3", side = 2, cratesRequired = 1, unitQuantity = 1, internal = 1 },
        { weight = 713, desc = "Chieftain", unit = "Chieftain_mk3", side = 2, cratesRequired = 1, unitQuantity = 1, internal = 1 },
        { weight = 821, desc = "Merkava", unit = "Merkava_Mk4", side = 2, cratesRequired = 2, unitQuantity = 1, internal = 1 },
        { weight = 822, desc = "Leopard 2A4", unit = "leopard-2A4", side = 2, cratesRequired = 3, unitQuantity = 1, internal = 1 },
        { weight = 823, desc = "Leopard 2A5", unit = "Leopard-2A5", side = 2, cratesRequired = 3, unitQuantity = 1, internal = 1 },
        { weight = 824, desc = "Leopard 2A6M", unit = "Leopard-2", side = 2, cratesRequired = 3, unitQuantity = 1, internal = 1 },
        { weight = 885, desc = "Challenger II", unit = "Challenger2", side = 2, cratesRequired = 3, unitQuantity = 1, internal = 1 },
        { weight = 712, desc = "M1A2 Abrams", unit = "M-1 Abrams", side = 2, cratesRequired = 4, unitQuantity = 1, internal = 1 },        
    },

    ["Short Range SAMs"] = {
	
		--RED        		
        { weight = 830, desc = "SA-9 Strela-1", unit = "Strela-1 9P31", side = 1, cratesRequired = 1, unitQuantity = 2, internal = 1 },
        { weight = 831, desc = "SA-13 Strela-10", unit = "Strela-10M3", side = 1, cratesRequired = 1, unitQuantity = 1, internal = 1 },
		    { weight = 829, desc = "SA-8 Osa 9A33", unit = "Osa 9A33 ln", side = 1, cratesRequired = 1, internal = 1 },
        { weight = 832, desc = "SA-15 Tor", unit = "Tor 9A331", side = 1, cratesRequired = 2, unitQuantity = 1, internal = 1 },
        { weight = 833, desc = "SA-19 Tunguska", unit = "2S6 Tunguska", side = 1, cratesRequired = 2, unitQuantity = 1, internal = 1 },
        { weight = 834, desc = "HQ-7 Launcher - Single", unit = "HQ-7_LN_SP", side = 1, cratesRequired = 1, unitQuantity = 1, internal = 1, isStandalone = true },
        { weight = 755, desc = "HQ-7 Launcher", unit = "HQ-7_LN_SP", side = 1, internal = 1, isStandalone = false },
        { weight = 756, desc = "HQ-7 Search Radar", unit = "HQ-7_STR_SP", side = 1, internal = 1, isStandalone = false },
		
		--BLUE
        { weight = 707, desc = "M48 Chaparral", unit = "M48 Chaparral", side = 2, cratesRequired = 1, unitQuantity = 1, internal = 1 },		
        { weight = 840, desc = "M1097 Avenger", unit = "M1097 Avenger", side = 2, cratesRequired = 1, unitQuantity = 1, internal = 1 },
        { weight = 841, desc = "M6 Linebacker", unit = "M6 Linebacker", side = 2, cratesRequired = 2, unitQuantity = 1, internal = 1 },        
        { weight = 839, desc = "SA-15 Tor", unit = "Tor 9A331", side = 2, cratesRequired = 2, unitQuantity = 1, internal = 1 },
        { weight = 842, desc = "Crotale Launcher - Single", unit = "HQ-7_LN_SP", side = 2, cratesRequired = 1, unitQuantity = 1, internal = 1, isStandalone = true },        
        { weight = 752, desc = "Crotale Launcher", unit = "HQ-7_LN_SP", side = 2, internal = 1, isStandalone = false },
        { weight = 753, desc = "Crotale Search Radar", unit = "HQ-7_STR_SP", side = 2, internal = 1, isStandalone = false },
        { weight = 855, desc = "Roland Launcher - Single", unit = "Roland ADS", side = 2, cratesRequired = 1, unitQuantity = 1, internal = 1, isStandalone = true },                
        { weight = 757, desc = "Roland Launcher", unit = "Roland ADS", side = 2, internal = 1, isStandalone = false },
        { weight = 758, desc = "Roland Radar", unit = "Roland Radar", side = 2, internal = 1, isStandalone = false },        
    },

    ["Medium Range SAMs"] = {   
    -- Buk system
        { weight = 848, desc = "Buk Launcher", unit = "SA-11 Buk LN 9A310M1", side = 1, internal = 1, isStandalone = false },
        { weight = 849, desc = "Buk Search Radar", unit = "SA-11 Buk SR 9S18M1", side = 1, internal = 1, isStandalone = false },
        { weight = 850, desc = "Buk CC Radar", unit = "SA-11 Buk CC 9S470M1", side = 1, internal = 1, isStandalone = false },
    -- Kub system
        { weight = 846, desc = "Kub Launcher", unit = "Kub 2P25 ln", side = 1, internal = 1, isStandalone = false },
        { weight = 847, desc = "Kub Radar", unit = "Kub 1S91 str", side = 1, internal = 1, isStandalone = false },    
    -- SA-3 system
        { weight = 843, desc = "SA-3 Launcher", unit = "5p73 s-125 ln", side = 1, internal = 1, isStandalone = false },
        { weight = 844, desc = "SA-3 Search Radar", unit = "p-19 s-125 sr", side = 1, internal = 1, isStandalone = false },
        { weight = 845, desc = "SA-3 Track Radar", unit = "snr s-125 tr", side = 1, internal = 1, isStandalone = false },
    -- Raipier System
		    { weight = 708, desc = "Rapier Blindfire Radar", unit = "rapier_fsa_blindfire_radar", side = 2, internal = 1, isStandalone = false },
		    { weight = 709, desc = "Rapier Optical Tracker", unit = "rapier_fsa_optical_tracker_unit", side = 2, internal = 1, isStandalone = false },
		    { weight = 710, desc = "Rapier Launcher", unit = "rapier_fsa_launcher", side = 2, internal = 1, isStandalone = false },				
	 -- Hawk System
        { weight = 851, desc = "Hawk Launcher", unit = "Hawk ln", side = 2, internal = 1, isStandalone = false },
        { weight = 852, desc = "Hawk Search Radar", unit = "Hawk sr", side = 2, internal = 1, isStandalone = false },
        { weight = 853, desc = "Hawk Track Radar", unit = "Hawk tr", side = 2, internal = 1, isStandalone = false },
        { weight = 854, desc = "Hawk PCP", unit = "Hawk pcp", side = 2, internal = 1, isStandalone = false },     
    },
  
  ["Long Range SAMs"] = {
    -- SA-2 system
        { weight = 857, desc = "SA-2 Launcher", unit = "S_75M_Volhov", side = 1, internal = 1, isStandalone = false },
        { weight = 858, desc = "SA-2 Search Radar", unit = "p-19 s-125 sr", side = 1, internal = 1, isStandalone = false },
        { weight = 859, desc = "SA-2 Track Radar", unit = "SNR_75V", side = 1, internal = 1, isStandalone = false },    
    -- Patriot
        { weight = 860, desc = "Patriot EPP", unit = "Patriot EPP", side = 2, internal = 1, isStandalone = false },
        { weight = 861, desc = "Patriot STR", unit = "Patriot str", side = 2, internal = 1, isStandalone = false },
        { weight = 862, desc = "Patriot CP", unit = "Patriot cp", side = 2, internal = 1, isStandalone = false },
        { weight = 863, desc = "Patriot AMG", unit = "Patriot AMG", side = 2, internal = 1, isStandalone = false },
        { weight = 864, desc = "Patriot ECS", unit = "Patriot ECS", side = 2, internal = 1, isStandalone = false },
        { weight = 865, desc = "Patriot LN", unit = "Patriot ln", side = 2, internal = 1, isStandalone = false },    
    -- S-300
        { weight = 866, desc = "S-300PS 64H6E SR", unit = "S-300PS 64H6E sr", side = 1, internal = 1, isStandalone = false },
        { weight = 867, desc = "S-300PS 40B6M TR", unit = "S-300PS 40B6M tr", side = 1, internal = 1, isStandalone = false },
        { weight = 868, desc = "S-300PS 54K6 CP", unit = "S-300PS 54K6 cp", side = 1, internal = 1, isStandalone = false },
        { weight = 869, desc = "S-300PS 5P85D LN", unit = "S-300PS 5P85D ln", side = 1, internal = 1, isStandalone = false },
        { weight = 870, desc = "S-300PS 5P85C LN", unit = "S-300PS 5P85C ln", side = 1, internal = 1, isStandalone = false },    
    
    },
	["SAM Repairs"] = {	
		{ weight = 884, desc = "Buk Repair", unit = "Buk Repair", side = 1, internal = 1, isStandalone = false },
		{ weight = 754, desc = "HQ-7 Repair", unit = "HQ-7 Repair", side = 1, internal = 1, isStandalone = false },
		{ weight = 883, desc = "Kub Repair", unit = "Kub Repair", side = 1, internal = 1, isStandalone = false },
		{ weight = 880, desc = "SA-2 Repair", unit = "SA-2 Repair", side = 1, internal = 1, isStandalone = false },
    { weight = 881, desc = "SA-3 Repair", unit = "SA-3 Repair", side = 1, internal = 1, isStandalone = false },
    { weight = 882, desc = "SA-10 Repair", unit = "SA-10 Repair", side = 1, internal = 1, isStandalone = false },
    		
    { weight = 759, desc = "Crotale Repair", unit = "HQ-7 Repair", side = 2, internal = 1, isStandalone = false },
    { weight = 886, desc = "Hawk Repair", unit = "Hawk Repair", side = 2, internal = 1, isStandalone = false },
    { weight = 888, desc = "Patriot Repair", unit = "Patriot Repair", side = 2, internal = 1, isStandalone = false },
    { weight = 728, desc = "Rapier Repair", unit = "Rapier Repair", side = 2, internal = 1, isStandalone = false },
    { weight = 887, desc = "Roland Repair", unit = "Roland Repair", side = 2, internal = 1, isStandalone = false },
	{ weight = 729, desc = "Silkworm Repair", unit = "Silkworm Repair", internal = 1, isStandalone = false },
	},
		
    ["Missiles"] = {	  
		{ weight = 876, desc = "Scud-B", unit = "Scud_B", side = 1, cratesRequired = 4, unitQuantity = 3, internal = 1 },
		-- Silkworm
		{ weight = 721, desc = "Silkworm Radar", unit = "Silkworm_SR", internal = 1, isStandalone = false},
		{ weight = 722, desc = "Silkworm Missile HY-2A", unit = "hy_launcher", internal = 1, isStandalone = false},		
    },
			
   ["Support"] = {
        { weight = 891, desc = "FOB/CC/Logistics Repair", unit = "LogisticsCentre", internal = 1 },
        { weight = 502, desc = "GAZ Tigr - JTAC", unit = "Tigr_233036", side = 1, cratesRequired = 1, internal = 1 },
		{ weight = 501, desc = "HMMWV - JTAC", unit = "Hummer", side = 2, cratesRequired = 1, internal = 1 },
		{ weight = 805, desc = "ATZ-10 Fuel Truck", unit = "ATZ-10", side = 1, cratesRequired = 1, internal = 1 },
        { weight = 806, desc = "KAMAZ-43101 Ammo Truck", unit = "KAMAZ Truck", side = 1, cratesRequired = 1, internal = 1 },		
		{ weight = 812, desc = "M978 HEMTT Tanker", unit = "M978 HEMTT Tanker", side = 2, cratesRequired = 1, unitQuantity = 1, internal = 1 },
        { weight = 813, desc = "M-818 Ammo Truck", unit = "M 818", side = 2, cratesRequired = 1, unitQuantity = 1, internal = 1 },
        { weight = 723, desc = "EWR 1L13 - Short Range", unit = "1L13 EWR", internal = 1 },
		{ weight = 724, desc = "EWR 55G6 - Long Range", unit = "55G6 EWR", internal = 1 },		
		--{ weight = 667, desc = "Mobile ATC SKP 11", unit = "SKP-11", side = 1, internal = 1},  -- future
		--{ weight = 668, desc = "Mobile ATC Trojan Spirit", unit = "Predator TrojanSpirit", side = 2, internal = 1}, -- future
    },	
}

ctld.internalCratesOnly = ctld.spawnableCrates["Internal Cargo"]

-- if the unit is on this list, it will be made into a JTAC when deployed
ctld.jtacUnitTypes = {
    "Tigr_233036", "Hummer" -- there are some wierd encoding issues so if you write SKP-11 it wont match as the - sign is encoded differently...
}

--- Tells CTLD What multipart AA Systems there are and what parts they need
-- A New system added here also needs the launcher added
ctld.AASystemTemplate = {    
    {
        name = "HQ-7 Full System",
        count = 2,
        parts = {
            { name = "HQ-7_LN_SP", desc = "HQ-7 Launchers", launcher = true },  
            { name = "HQ-7_STR_SP", desc = "HQ-7 Search Track Radar" },                        
        },
        repair = "HQ-7 Repair",
        systemType = "SR2",
    }, 
    {
        name = "Roland SAM System",
        count = 2,
        parts = {
            { name = "Roland ADS", desc = "Roland Launcher", launcher = true },
            { name = "Roland Radar", desc = "Roland Radar" },
        },
        repair = "Roland Repair",
        systemType = "SR2",
    },    
    {
        name = "Hawk SAM System",
        count = 4,
        parts = {
            { name = "Hawk ln", desc = "Hawk Launcher", launcher = true },
            { name = "Hawk tr", desc = "Hawk Track" },
            { name = "Hawk sr", desc = "Hawk Search Radar" },
            { name = "Hawk pcp", desc = "Hawk PCP" },
        },
        repair = "Hawk Repair",
        systemType = "LR",
    },
    {
        name = "Buk SAM System",
        count = 3,
        parts = {
            { name = "SA-11 Buk LN 9A310M1", desc = "Buk Launcher", launcher = true },
            { name = "SA-11 Buk CC 9S470M1", desc = "Buk CC Radar" },
            { name = "SA-11 Buk SR 9S18M1", desc = "Buk Search Radar" },
        },
        repair = "Buk Repair",
        systemType = "MR"
    },	
	{
        name = "Rapier SAM System",
        count = 3,
        parts = {
			{ name = "rapier_fsa_launcher", desc = "Rapier Launcher", launcher = true},
            { name = "rapier_fsa_blindfire_radar", desc = "Rapier Blindfire Radar"},
            { name = "rapier_fsa_optical_tracker_unit", desc = "Rapier Optical Tracker" },            
        },
        repair = "Rapier Repair",
        systemType = "SR"
    },	
	{
        name = "Silkworm System",
        count = 2,
        parts = {
            { name = "hy_launcher", desc = "Silkworm Missile HY-2A", launcher = true },
            { name = "Silkworm_SR", desc = "Silkworm Radar" },
        },
        repair = "Silkworm Repair",
        systemType = "LR",
    },	
    {
        name = "Kub SAM System",
        count = 2,
        parts = {
            { name = "Kub 2P25 ln", desc = "Kub Launcher", launcher = true },
            { name = "Kub 1S91 str", desc = "Kub Radar" },
        },
        repair = "Kub Repair",
        systemType = "MR",
    },
    {
        name = "SA-2 SAM System",
        count = 3,
        parts = {
            { name = "S_75M_Volhov", desc = "SA-2 Launcher", launcher = true },
            { name = "SNR_75V", desc = "SA-2 Track Radar" },
            { name = "p-19 s-125 sr", desc = "SA-2 Search Radar" },
        },
        repair = "SA-2 Repair",
        systemType = "LR",
    },
  {
    name = "Patriot SAM System",
    count = 6,
    parts = {
      { name = "Patriot ln", desc = "Patriot ln", launcher = true },
      { name = "Patriot AMG", desc = "Patriot AMG" },
      { name = "Patriot ECS", desc = "Patriot ECS" },
      { name = "Patriot cp", desc = "Patriot cp" },
      { name = "Patriot str", desc = "Patriot str" },
      { name = "Patriot EPP", desc = "Patriot EPP (internal)" },
    },
    repair = "Patriot Repair",
    systemType = "SLR",
  },
  {
    name = "S-300 SAM System",
    count = 5,
    parts = {
      { name = "S-300PS 64H6E sr", desc = "S-300PS 64H6E sr" },
      { name = "S-300PS 5P85D ln", desc = "S-300PS 5P85D ln", launcher = true },
      { name = "S-300PS 54K6 cp", desc = "S-300PS 54K6 cp" },
      { name = "S-300PS 40B6M tr", desc = "S-300PS 40B6M tr" },
      { name = "S-300PS 5P85C ln", desc = "S-300PS 5P85C ln" },
    },
    repair = "SA-10 Repair",
    systemType = "LR",
  },
  -- omit SA3-3 for now given 82K ft ceiling
  -- re introducing it, they cant turn that well, and they are supposed to have an 82k ceiling  
  {
        name = "SA-3 SAM System",
        count = 3,
        parts = {
    
            { name = "5p73 s-125 ln", desc = "SA-3 Launcher", launcher = true },
            { name = "snr s-125 tr", desc = "SA-3 Track Radar" },
            { name = "p-19 s-125 sr", desc = "SA-3 Search Radar" },
        },
        repair = "SA-3 Repair",
        systemType = "MR",
    },
}
