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
-- 2. Add distance config options and adjust functions.
-- 3. Add config for discord invite URL.
---

--- CONFIG ---
-- Modify only stuff in this block.

-- Number of spawned in groups at one time.
ConvoyLimit = 4

-- DO NOT CHANGE FOR NOW. Number of allowed C130s per coalition to be spawned in at one time.
TransportLimit = 1

-- This defines the group names in ME without coalition prefix. This is less code than requesting a set of groups and iterating.
ConvoyGroups = {
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

--- GLOBALS ---

-- Coalition Table to automate menus into one function for both coalitions.
_Coalitions = {
  Red = {Number = 1, String = 'Red', Clients = nil, ConvoysLeft = ConvoyLimit, TransportGroup = nil, TransportSpawn = nil, ConvoySpawns = {}}, 
  Blue = {Number = 2, String = 'Blue', Clients = nil, ConvoysLeft = ConvoyLimit, TransportGroup = nil, TransportSpawn = nil, ConvoySpawns = {}}
}

-- Which bulk clients to include for blue and red coalitions. 
_Coalitions.Blue.Clients = SET_CLIENT:New():FilterCoalitions("blue"):FilterPrefixes({" Blue Cargo", " Blue Helos"}):FilterStart()
_Coalitions.Red.Clients = SET_CLIENT:New():FilterCoalitions("red"):FilterPrefixes({" Red Cargo", " Red Helos"}):FilterStart()

-- Creates a SPAWN object for each group in the convoys per coalition. #array is shorthand for the length of an array. This does not work with tables with key, value pairs.
for i=1, #ConvoyGroups do 
  _Coalitions.Blue.ConvoySpawns[i] = SPAWN:New( "Blue " .. ConvoyGroups[i] ):InitLimit(ConvoyLimit,ConvoyLimit)
  _Coalitions.Red.ConvoySpawns[i] = SPAWN:New( "Red " .. ConvoyGroups[i] ):InitLimit(ConvoyLimit,ConvoyLimit)
end

-- C130 SPAWNs
_Coalitions.Blue.TransportSpawn = SPAWN:New( "Blue Transport" ):InitLimit(TransportLimit,ConvoyLimit)    
_Coalitions.Red.TransportSpawn = SPAWN:New( "Red Transport" ):InitLimit(TransportLimit,ConvoyLimit)

-- Event Handler Initialization
EventHandler = EVENTHANDLER:New():HandleEvent( EVENTS.Birth ):HandleEvent( EVENTS.Land )

--- END GLOBALS ---

--- FUNCTIONS ---

function SpawnTransport(hdg, pos, coalitionWrapper)
  local range = 185
  local spawnPt = pos:Translate(range, hdg, true)
  local spawnVec2 = spawnPt:GetVec2() 
  coalitionWrapper.TransportGroup = coalitionWrapper.TransportSpawn:SpawnFromVec2(spawnVec2)
end

-- Function spawns a convoy 185m (600ft) away in straight line separated by 10m. Accepts coalitionNumber (2=Blue, 1=Red)
function SpawnConvoy(hdg, pos, coalitionWrapper)
  -- Initally spawns group 185m (600ft), increasing by 10 meters per group.
  local range = 185
  
  -- Increment ranges of units by adding 10m to range value, then spawn units via Vec2 ( x and y pos) coordinates.
  for i=1, #coalitionWrapper.ConvoySpawns do
    local spawnPt = pos:Translate(range, hdg, true)
    local spawnVec2 = spawnPt:GetVec2()
    coalitionWrapper.ConvoySpawns[i]:SpawnFromVec2(spawnVec2)
    range = range + 10
  end
end

-- Convoy Menu Function
function CONVOY_MENU(coalitionWrapper)
  coalitionWrapper.Clients:ForEachClient(function(thisClient)
    -- TODO: Find out if checking to see if unit is alive is actually necessary.
      if (thisClient ~= nil) and (thisClient:IsAlive()) then 
        local group = thisClient:GetGroup()
        local pos = group:GetPointVec2()
        local hdg = group:GetHeading()

        -- Main Menu
        local ConvoyMenuRoot = MENU_GROUP:New( group, "Air Resupply" )
        
        -- Commands
        local SpawnTransportCommand = MENU_GROUP_COMMAND:New( group, "Spawn C130 Air Resupply", ConvoyMenuRoot, SpawnTransport, hdg, pos, coalitionWrapper)
        local GetRemainingCommand = MENU_GROUP_COMMAND:New( group, "Air Resupplies Remaining", ConvoyMenuRoot, function() 
          trigger.action.outTextForCoalition(coalitionWrapper.Number, "[TEAM] Has " .. coalitionWrapper.ConvoysLeft .. " Remaining Air Resupplies", 10)
        end)
        
        -- Enters log information
        --env.info("Player name: " ..thisClient:GetPlayerName())
        --env.info("Group Name: " ..group:GetName())       
        
        function EventHandler:OnEventBirth( EventData )
          -- Defines name of unit being spawned in this function bracket for event only.
          local str = EventData.IniDCSGroupName
          
          -- Test to see if it is a red convoy group has been born.
          if string.match(str, coalitionWrapper.String .. " " .. ConvoyGroups[1]) then
            coalitionWrapper.ConvoysLeft = coalitionWrapper.ConvoysLeft - 1
            trigger.action.outTextForCoalition(coalitionWrapper.Number,"[TEAM] " ..thisClient:GetPlayerName().. "  Successfully Deployed a Convoy\nContact a Tactical Commander on Discord (discord.gg/fVg9gut) \n" 
            .. coalitionWrapper.String .. " team has " .. coalitionWrapper.ConvoysLeft .. " remaining Convoy units.", 10)
          -- If not, see if a transport has been born.
          elseif string.match(str, coalitionWrapper.String .. " Transport") then
            trigger.action.outTextForCoalition(coalitionWrapper.Number,"[TEAM] " ..thisClient:GetPlayerName().. "  Requested an Air Resupply\nESCORT REQUESTED", 10)
            trigger.action.outTextForCoalition(coalitionWrapper.Number == 1 and 2 or 1,"[TEAM] " ..thisClient:GetPlayerName().. "  The Air Operations Center has detected an enemy C130\nINTERCEPT IMMEDIATELY", 10)
          end
        end

        function EventHandler:OnEventLand( EventData )
          -- Defines name of unit being spawned in this function bracket for event only.
          local str = EventData.IniDCSGroupName

          --Test to see if a C130 has landed
          if str.match(str, coalitionWrapper.String .. " Transport") then
            SpawnConvoy(hdg, pos, coalitionWrapper)
            coalitionWrapper.TransportGroup:Destroy()
            coalitionWrapper.TransportGroup = nil
            trigger.action.outTextForCoalition(coalitionWrapper.Number,"[TEAM] " .. coalitionWrapper.String .." Resupply Mission Successful", 10)
            trigger.action.outTextForCoalition(coalitionWrapper.Number == 1 and 2 or 1,"[TEAM] C-130 Target Faded Intercept Mission Failure", 10)
          end
        end
        -- TODO: Research this.
        -- Refer to change 6. in changelog, I believe filterStart() will ensure that a despawned Client is removed. Tested with filterOnce()
        --thisClient:Remove(thisClient:GetName(), true)
      end
  end)
  -- This timer will have the function run again as clients become alive and not nil. Runs every 1-2s per coalition number. Prevents same time execution to save resources.
  timer.scheduleFunction(CONVOY_MENU,coalitionWrapper,timer.getTime() + coalitionWrapper.Number)
end
--- END FUNCTIONS---

--- EXECUTION ---

-- Execute menus.

CONVOY_MENU(_Coalitions.Red)
CONVOY_MENU(_Coalitions.Blue)

--- END EXECUTION ---
