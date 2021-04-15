---
-- Name: Convoy Menu
-- Author: Babushka (West#9009) with credit to Wildcat (Chandawg)
-- Date Created: 3/23/2020
-- Date Modified: 3/27/2021 by Babushka (West#9009)
-- Will spawn a convoy based on template in Crimea. The command is wrapped it into the F10 menu option to be called by clients in Helos And Cargo.
-- Babushka Changelog.
-- 1. Fixed counters. The convoy limit can be set manually with the global ConvoyLimit.
-- 2. Related to the counters, the init limit has been set up so that units spawn in individual groups with there unit count and group limit being equal to the convoy limit, but
-- separetely counted per coalition.
-- 3. Setup globals for tracking the groups of the spawned C130s. This allows for proper destruction of unit because initCleanup does NOT remove a C130, but would rather respawn it
-- upon landing because it is not considered destroyed. GROUP:Destroy() will destroy the unit regardless, hence the need for a global.
-- 4. Fixed message spam. Inside the birth event handler, it was incorrectly configured to send a message every birth event, which includes every unit, not just per group. 
-- Solution was to rename the initial group unit with an "Init" suffix with the string.match function.
-- 5. Removed unnescessary event handler.
-- 6. Removed unnescessary client remove as SET_CLIENT:filterStart() dynamically adds and removes clients. This appears to do nothing, but commented out just in case we need it later.
-- 7. Changed convoy spawning mechanic to have the clients hdg and pos stored at runtime of indexed alive clients. FilterStart as I understand it removes dynamically which will make
-- despawned clients nil. This is likely related to any timer.scheduleFunction() errors with this function.
-- TODO:
-- 1. Complete any FIXME:s.
-- 2. Make Pos dynamic at SpawnTransport runtime. i.e. lookup group provided to function then re-grab vec2 data. 
-- 3. Add config for discord invite URL.
---

--- CONFIG ---
-- Modify only stuff in this block.

-- Discord URL
local DISCORD = "discord.gg/fVg9gut"

-- Number of spawned in groups at one time.
local ConvoyLimit = 4

-- Range from player of spawned groups.
local RANGE = 185

-- DO NOT CHANGE FOR NOW. Number of allowed C130s per coalition to be spawned in at one time.
local TransportLimit = 1

-- Delay in seconds before destroying a group.
local DELAY = 10

-- This defines the group names in ME without coalition prefix. This is less code than requesting a set of groups and iterating.
local ConvoyGroups = {
  "Convoy Group 1",
  "Convoy Group 2",  
  "Convoy Group 3",  
  "Convoy Group 4",  
  "Convoy Group 5",    
  "Convoy Group 6",  
  "Convoy Group 7",  
  "Convoy Group 8",  
  "Convoy Group 9",  
}
--- END CONFIG ---

--- LOCAL VARIABLES ---

-- COALITION TABLE [1] Red [2] Blue
local _Coalitions = {
  {Number = 1, String = 'Red', ConvoysLeft = ConvoyLimit, TransportGroup = nil, TransportSpawn = nil, ConvoySpawns = {}, Queue = nil}, 
  {Number = 2, String = 'Blue', ConvoysLeft = ConvoyLimit, TransportGroup = nil, TransportSpawn = nil, ConvoySpawns = {}, Queue = nil}
}

-- CONVOY GROUP SPAWNS
for i=1, #ConvoyGroups do 
  _Coalitions[1].ConvoySpawns[i] = SPAWN:New( "Red " .. ConvoyGroups[i] ):InitLimit(ConvoyLimit,ConvoyLimit)
  _Coalitions[2].ConvoySpawns[i] = SPAWN:New( "Blue " .. ConvoyGroups[i] ):InitLimit(ConvoyLimit,ConvoyLimit)
end

-- TRANSPORT SPAWNs
_Coalitions[1].TransportSpawn = SPAWN:New( "Red Convoy Transport" ):InitLimit(TransportLimit,ConvoyLimit)
_Coalitions[2].TransportSpawn = SPAWN:New( "Blue Convoy Transport" ):InitLimit(TransportLimit,ConvoyLimit)

-- Event Handler Initialization
--local EventHandler = EVENTHANDLER:New():HandleEvent( EVENTS.Birth ):HandleEvent( EVENTS.Land)

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

local function SpawnTransport(heading, location, playerName, CoalitionNumber)
  if not _Coalitions[CoalitionNumber].Queue then
    env.info("CONVOY: Queue for team: " .. _Coalitions[CoalitionNumber].String .. " is empty. Inserting " .. playerName .. " location and heading.")
    _Coalitions[CoalitionNumber].Queue = {Heading = heading, Location = location, PlayerName = playerName}
    local spawnVec2 = TranslateAndReturnSpawnLocation(heading, location)
    _Coalitions[CoalitionNumber].TransportGroup = _Coalitions[CoalitionNumber].TransportSpawn:SpawnFromVec2(spawnVec2)
  end
end

local landEventHandler = nil

LAND_EVENTHANDLER = {
  ClassName = "LAND_EVENTHANDLER"
}

function LAND_EVENTHANDLER:New()
  local self = BASE:Inherit(self, EVENTHANDLER:New())

  self:HandleEvent(EVENTS.Land, self.OnLand)
  self:HandleEvent(EVENTS.Birth, self.OnBirth)

  return self
end

function LAND_EVENTHANDLER:OnLand( EventData )
  env.info("CONVOY: Landed")
  trigger.action.outTextForCoalition(1,"You Landed!", 10)
end


-- HANDLES BIRTH EVENTS OF TRANSPORT HELOS AND CARGO, TRANSPORTS, AND CONVOY GROUPS
function LAND_EVENTHANDLER:OnBirth( EventData )
  local group = EventData.IniGroup
  local groupName = EventData.IniGroupName
  local coalitionNumber = EventData.IniCoalition
  local playerName = nil
  local pos = nil

  -- NOT NIL
  if groupName then
    -- PLAYER IN HELO OR CARGO BORN.
    if string.match(groupName, "Helos") or string.match(groupName, "Cargo") then
      env.info("CONVOY: " .. groupName .. " detected.")
      
      -- PLAYER OCCUPANT OF GROUP
      if EventData.IniPlayerName then
        playerName = EventData.IniPlayerName
        env.info("CONVOY: Creating Convoy Menus for " .. playerName .. ".")

        pos = {heading = group:GetHeading(), location = group:GetPointVec2()}
        
        -- PARENT MENU
        local ConvoyMenuRoot = MENU_GROUP:New( group, "Air Resupply" )
          
        -- SUBMENU COMMANDS CHILD OF ConvoyMenuRoot
        MENU_GROUP_COMMAND:New( group, "Spawn Air Resupply", ConvoyMenuRoot, SpawnTransport, pos.heading, pos.location, playerName, coalitionNumber)
        MENU_GROUP_COMMAND:New( group, "Air Resupplies Remaining", ConvoyMenuRoot, function() 
          trigger.action.outTextForCoalition(coalitionNumber, "[TEAM] Has " .. _Coalitions[coalitionNumber].ConvoysLeft .. " Remaining Air Resupplies.", 10)
        end)
      end
    
    -- CONVOY GROUP BORN.
    elseif string.match(groupName, ConvoyGroups[1]) then

      _Coalitions[EventData.IniCoalition].ConvoysLeft = _Coalitions[EventData.IniCoalition].ConvoysLeft - 1
      trigger.action.outTextForCoalition(coalitionNumber,"[TEAM] " .. _Coalitions[coalitionNumber].Queue.PlayerName .. "  Successfully Deployed a Convoy!\nContact a Tactical Commander on Discord (" .. DISCORD ..").\n" 
              .. _Coalitions[coalitionNumber].String .. " team has " .. _Coalitions[coalitionNumber].ConvoysLeft .. " remaining convoys.", 10)
    
    -- TRANSPORT BORN.
    elseif string.match(groupName, "Convoy Transport") then
      env.info("CONVOY: Convoy Transport incoming.")
      --trigger.action.outTextForCoalition(coalitionNumber,"[TEAM] " .. _Coalitions[coalitionNumber].Queue.PlayerName .. "  Requested an Air Resupply.\nESCORT REQUESTED!", 10)
      --trigger.action.outTextForCoalition(coalitionNumber == 1 and 2 or 1,"[TEAM] The Air Operations Center has detected an enemy C130!\nINTERCEPT IMMEDIATELY!", 10)
    end
  end   
end

landEventHandler = LAND_EVENTHANDLER:New()


-- HANDLES LAND EVENTS OF TRANSPORTS ONLY
--function EventHandler:OnEventLand( EventData )
  --env.info("CONVOY: LANDING EVENT")
  --local groupName = EventData.IniGroupName
  --local coalitionNumber = EventData.IniCoalition

  -- TRANSPORT LANDED
  --if string.match(groupName, "Red Transport") then
    --env.info(_Coalitions[coalitionNumber].String .. " Transport Landed. Deploying convoy.")
    --SpawnConvoy(coalitionNumber)
    
    --trigger.action.outTextForCoalition(coalitionNumber,"[TEAM] " .. _Coalitions[coalitionNumber].String .." Resupply Mission Successful!", 10)
    --trigger.action.outTextForCoalition(coalitionNumber == 1 and 2 or 1,"[TEAM] Enemy Transport Faded.\nIntercept Mission Failed!", 10)
  --end
--end
--- END FUNCTIONS---
