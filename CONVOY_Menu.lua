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

-- Dont Remove
Convoy = {}

--- CONFIG ---
-- Modify only stuff in this block.

-- Discord URL
local DISCORD = "discord.gg/fVg9gut"

-- Number of spawned in groups at one time.
local ConvoyLimit = 2

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
  _Coalitions[coalitionNumber].TransportGroup = nil
  _Coalitions[coalitionNumber].Queue = nil
end

local function SpawnTransport(heading, location, playerName, coalitionNumber)
  if not _Coalitions[coalitionNumber].Queue then
    env.info("CONVOY: Queue for team: " .. _Coalitions[coalitionNumber].String .. " is empty. Inserting " .. playerName .. "'s location and heading.")
    _Coalitions[coalitionNumber].Queue = {Heading = heading, Location = location, PlayerName = playerName}
    local spawnVec2 = TranslateAndReturnSpawnLocation(heading, location)
    _Coalitions[coalitionNumber].TransportGroup = _Coalitions[coalitionNumber].TransportSpawn:SpawnFromVec2(spawnVec2)
  else
    env.info("CONVOY: Queue for team: " .. _Coalitions[coalitionNumber].String .. " is full!")
    trigger.action.outTextForCoalition(coalitionNumber, "[TEAM] Transport is already in the air!", 10)
  end
end

-- HANDLES BIRTH EVENTS OF TRANSPORT HELOS AND CARGO, TRANSPORTS, AND CONVOY GROUPS
function Convoy.AddMenu( playerGroup, playerName, coalitionNumber )
  env.info("CONVOY: Creating Convoy Menus for " .. playerName .. ".")

  local pos = {heading = playerGroup:GetHeading(), location = playerGroup:GetPointVec2()}
  
  -- PARENT MENU
  local ConvoyMenuRoot = MENU_GROUP:New( playerGroup, "Air Resupply" )
    
  -- SUBMENU COMMANDS CHILD OF ConvoyMenuRoot
  MENU_GROUP_COMMAND:New( playerGroup, "Spawn Air Resupply", ConvoyMenuRoot, SpawnTransport, pos.heading, pos.location, playerName, coalitionNumber)
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
  trigger.action.outTextForCoalition(coalitionNumber,"[TEAM] " .. _Coalitions[coalitionNumber].Queue.PlayerName .. "  Requested an Air Resupply.\nESCORT REQUESTED!", 10)
  trigger.action.outTextForCoalition(coalitionNumber == 1 and 2 or 1,"[TEAM] The Air Operations Center has detected an enemy C130!\nINTERCEPT IMMEDIATELY!", 10)
end

--HANDLES LAND EVENTS OF TRANSPORTS ONLY
function Convoy.OnLand( coalitionNumber )
  env.info(_Coalitions[coalitionNumber].String .. " Transport Landed. Deploying convoy.")
  SpawnConvoy(coalitionNumber)
  trigger.action.outTextForCoalition(coalitionNumber,"[TEAM] " .. _Coalitions[coalitionNumber].String .." Resupply Mission Successful!", 10)
  trigger.action.outTextForCoalition(coalitionNumber == 1 and 2 or 1,"[TEAM] Enemy Transport Faded.\nIntercept Mission Failed!", 10)
end

function Convoy.GetUpTransports(coalitionNum)
  return 0
end

function Convoy.GetUpTransportBaseName(coalitionNum)
  return "Vaziani"
end

---END FUNCTIONS---

