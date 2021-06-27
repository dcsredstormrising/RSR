---
-- Name: Convoy Menu
-- Author: Babushka (West#9009)
-- Date Created: 3/23/2020
-- Date Modified: 4/28/2021 by Babushka (West#9009)
-- Will spawn a convoy based on template in Crimea. The command is wrapped it into the F10 menu option to be called by clients in Helos And Cargo.
-- Babushka Changelog.
-- 1. Added config options.
-- 2. Fixed convoy limits.
-- 3. Transport now desctructed after delay.
-- 4. Removed message spam. 
-- 5. Removed unnescessary event handler. Event Handling now down through global event handlers.
-- 6. Removed SET_CLIENT
-- 7. Position data now saved at menu runtime.
-- TODO:
-- 1. Complete any FIXME:s.
---
local utils = require("utils")
local inspect = require("inspect")

-- Dont Remove
Convoy = {}

--- CONFIG ---
-- Modify only stuff in this block.

-- Discord URL
local DISCORD = "discord.gg/fVg9gut"

-- Number of spawned in groups at one time.
local ConvoyLimit = 4

-- This defines the group names in ME without coalition prefix. This is less code than requesting a set of groups and iterating.
local ConvoyLength = 6

-- Range from player of spawned groups.
local RANGE = 185

-- DO NOT CHANGE FOR NOW. Number of allowed C130s per coalition to be spawned in at one time.
local TransportLimit = 1

-- Delay in seconds before destroying a group.
local DELAY = 30

--- END CONFIG ---

--- LOCAL VARIABLES ---

local landHandler = {}
world.addEventHandler(landHandler)

local crashHandler = {}
world.addEventHandler(crashHandler)

-- COALITION TABLE [1] Red [2] Blue
local _Coalitions = {
  {Number = 1, String = 'Red', ConvoysLeft = ConvoyLimit, TransportGroup = nil, TransportSpawn = nil, ConvoySpawns = {}, Queue = nil}, 
  {Number = 2, String = 'Blue', ConvoysLeft = ConvoyLimit, TransportGroup = nil, TransportSpawn = nil, ConvoySpawns = {}, Queue = nil}
}

-- CONVOY GROUP SPAWNS
for i=1, ConvoyLength do 
  _Coalitions[1].ConvoySpawns[i] = SPAWN:New( "Red Convoy Group " .. i ):InitLimit(ConvoyLimit,ConvoyLimit)
  _Coalitions[2].ConvoySpawns[i] = SPAWN:New( "Blue Convoy Group " .. i ):InitLimit(ConvoyLimit,ConvoyLimit)
end

-- TRANSPORT SPAWNs
_Coalitions[1].TransportSpawn = SPAWN:New( "Red Convoy Transport" ):InitLimit(TransportLimit,ConvoyLimit)
_Coalitions[2].TransportSpawn = SPAWN:New( "Blue Convoy Transport" ):InitLimit(TransportLimit,ConvoyLimit)

--- END LOCAL VARIABLES ---

--- FUNCTIONS ---

local function TranslateAndReturnSpawnLocation(heading, location, range)
  range = range or RANGE
  return location:Translate(range, heading, true):GetVec2()
end

local function SpawnConvoy(coalitionNumber)
  local range = RANGE
  local queue = _Coalitions[coalitionNumber].Queue

  for i=1, #_Coalitions[coalitionNumber].ConvoySpawns do
    local spawnVec2 = TranslateAndReturnSpawnLocation(queue.Heading, queue.Location, range)
    _Coalitions[coalitionNumber].ConvoySpawns[i]:SpawnFromVec2(spawnVec2)
    range = range + 10
  end

  -- DELETE TRANSPORT and DELETE Queued Information
  _Coalitions[coalitionNumber].TransportGroup:Destroy(true, DELAY) 
end

local function SpawnTransport(playerGroup, coalitionNumber)
  local heading = playerGroup:GetHeading()
  local location = playerGroup:GetPointVec2()
  local playerName = playerGroup:GetPlayerName()
  local playerAirbase = utils.getNearestAirbase(playerGroup:GetVec2(), coalitionNumber, Airbase.Category.AIRDROME)

  if not _Coalitions[coalitionNumber].Queue and playerAirbase then
    env.info("CONVOY: Queue for team: " .. _Coalitions[coalitionNumber].String .. " is empty. Inserting " .. playerName .. "'s location and heading.")
    _Coalitions[coalitionNumber].Queue = {Heading = heading, Location = location, PlayerName = playerName, PlayerAirbase = playerAirbase}
    local spawnVec2 = TranslateAndReturnSpawnLocation(heading, location)
    _Coalitions[coalitionNumber].TransportGroup = _Coalitions[coalitionNumber].TransportSpawn:SpawnFromVec2(spawnVec2)
  elseif not playerAirbase then
    env.info("CONVOY: " .. playerName .. " is not at airbase, will not spawn convoy transport.")
    trigger.action.outTextForCoalition(coalitionNumber, "[TEAM] " .. playerName .. " Must be at airbase to spawn convoy.", 10)
  elseif _Coalitions[coalitionNumber].Queue then
    env.info("CONVOY: Queue for team: " .. _Coalitions[coalitionNumber].String .. " is full!")
    trigger.action.outTextForCoalition(coalitionNumber, "[TEAM] Transport is already in the air from " .. playerAirbase .. "!", 10)
  else
    env.info("CONVOY: Unhandled case in function SpawnTransport()")
  end
end

-- HANDLES BIRTH EVENTS OF TRANSPORT HELOS AND CARGO, TRANSPORTS, AND CONVOY GROUPS
function Convoy.AddMenu( playerGroup )
  local groupName = playerGroup:GetName()
  local coalitionNumber = playerGroup:GetCoalition()

  env.info("CONVOY: Creating Convoy Menus for " .. groupName .. ".")
  
  -- PARENT MENU
  local ConvoyMenuRoot = MENU_GROUP:New( playerGroup, "Air Resupply" )
    
  -- SUBMENU COMMANDS CHILD OF ConvoyMenuRoot
  MENU_GROUP_COMMAND:New( playerGroup, "Spawn Air Resupply", ConvoyMenuRoot, SpawnTransport, playerGroup, coalitionNumber)
  MENU_GROUP_COMMAND:New( playerGroup, "Air Resupplies Remaining", ConvoyMenuRoot, function()
    trigger.action.outTextForCoalition(coalitionNumber, "[TEAM] Has " .. _Coalitions[coalitionNumber].ConvoysLeft .. " Remaining Air Resupplies.", 10)
  end)
end

function Convoy.ConvoyGroupBorn( coalitionNumber )
  _Coalitions[coalitionNumber].ConvoysLeft = _Coalitions[coalitionNumber].ConvoysLeft - 1
  trigger.action.outTextForCoalition(coalitionNumber,"[TEAM] " .. _Coalitions[coalitionNumber].Queue.PlayerName .. "  Successfully Deployed a Convoy!\nContact a Tactical Commander on Discord (" .. DISCORD ..").\n" 
  .. _Coalitions[coalitionNumber].String .. " team has " .. _Coalitions[coalitionNumber].ConvoysLeft .. " remaining convoys.", 10)
end

function Convoy.ConvoyTransportGroupBorn( coalitionNumber )
  env.info("CONVOY: Convoy Transport Spawned.")
  trigger.action.outTextForCoalition(coalitionNumber,"[TEAM] " .. _Coalitions[coalitionNumber].Queue.PlayerName .. "  Requested an Air Resupply in " .. _Coalitions[coalitionNumber].Queue.PlayerAirbase .. ".\nESCORT REQUESTED!", 10)
  trigger.action.outTextForCoalition(coalitionNumber == 1 and 2 or 1,"[TEAM] The Air Operations Center has detected an enemy cargo transport in " .. _Coalitions[coalitionNumber].Queue.PlayerAirbase .. ".\nINTERCEPT IMMEDIATELY!", 10)
end

--HANDLES LAND EVENTS OF TRANSPORTS ONLY
function landHandler:onEvent(event)
	if event.id == world.event.S_EVENT_LAND then
		local initiator = event.initiator
		if initiator then
			local groupName = initiator:getName()			
			if string.match(groupName, "Convoy Transport") then
				local coalitionNumber = initiator:getCoalition()
				env.info(_Coalitions[coalitionNumber].String .. " Transport Landed. Deploying convoy.")		
				SpawnConvoy(coalitionNumber)
				trigger.action.outTextForCoalition(coalitionNumber,"[TEAM] " .. _Coalitions[coalitionNumber].String .." Resupply Mission Successful!", 10)
				trigger.action.outTextForCoalition(coalitionNumber == 1 and 2 or 1,"[TEAM] Enemy Transport Faded.\nIntercept Mission Failed!", 10)
			end
		end
	end
end

function crashHandler:onEvent(event)
	if event.id == world.event.S_EVENT_CRASH then
		local initiator = event.initiator
		if initiator then
			local groupName = initiator:getName()			
			if string.match(groupName, "Convoy Transport") then
				local coalitionNumber = event.IniCoalition		
				env.info("CONVOY: Convoy Transport Deleting. Clearing queue.")
				_Coalitions[coalitionNumber].TransportGroup = nil
				_Coalitions[coalitionNumber].Queue = nil
			end
		end
	end
end

function Convoy.GetUpTransports( coalitionNumber )
  return not _Coalitions[coalitionNumber].TransportGroup and 0 or 1
end

function Convoy.GetUpTransportBaseName( coalitionNumber )
  return not _Coalitions[coalitionNumber].TransportGroup and '' or _Coalitions[coalitionNumber].Queue.PlayerAirbase 
end
---END FUNCTIONS---
