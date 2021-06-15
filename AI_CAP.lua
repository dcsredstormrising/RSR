-- Author: Wildcat (Chandawg)
-- Date Created: 30 Dec 2020
-- Reintroducing AI-CAP to protect warehouses, add some difficulty when it is PVE.
-- Spawns

local rsrConfig = require("RSR_config")

--COMMON FUNCTIONS to save table to file and reload, in this case we are using it to make the AI-CAP persistent
do
--http://lua-users.org/wiki/SaveTableToFile

   local function exportstring( s )
      return string.format("%q", s)
   end

   --// The Save Function
   function table.save(  tbl,filename )
      local charS,charE = "   ","\n"
      local file,err = io.open( filename, "w+" ) --edited
      if err then return err end

      -- initiate variables for save procedure
      local tables,lookup = { tbl },{ [tbl] = 1 }
      file:write( "return {"..charE )

      for idx,t in ipairs( tables ) do
         file:write( "-- Table: {"..idx.."}"..charE )
         file:write( "{"..charE )
         local thandled = {}

         for i,v in ipairs( t ) do
            thandled[i] = true
            local stype = type( v )
            -- only handle value
            if stype == "table" then
               if not lookup[v] then
                  table.insert( tables, v )
                  lookup[v] = #tables
               end
               file:write( charS.."{"..lookup[v].."},"..charE )
            elseif stype == "string" then
               file:write(  charS..exportstring( v )..","..charE )
            elseif stype == "number" then
               file:write(  charS..tostring( v )..","..charE )
            end
         end

         for i,v in pairs( t ) do
            -- escape handled values
            if (not thandled[i]) then
            
               local str = ""
               local stype = type( i )
               -- handle index
               if stype == "table" then
                  if not lookup[i] then
                     table.insert( tables,i )
                     lookup[i] = #tables
                  end
                  str = charS.."[{"..lookup[i].."}]="
               elseif stype == "string" then
                  str = charS.."["..exportstring( i ).."]="
               elseif stype == "number" then
                  str = charS.."["..tostring( i ).."]="
               end
            
               if str ~= "" then
                  stype = type( v )
                  -- handle value
                  if stype == "table" then
                     if not lookup[v] then
                        table.insert( tables,v )
                        lookup[v] = #tables
                     end
                     file:write( str.."{"..lookup[v].."},"..charE )
                  elseif stype == "string" then
                     file:write( str..exportstring( v )..","..charE )
                  elseif stype == "number" then
                     file:write( str..tostring( v )..","..charE )
                  end
               end
            end
         end
         file:write( "},"..charE )
      end
      file:write( "}" )
      file:close()
   end
   
   --// The Load Function
   function table.load( sfile )
      local ftables,err = loadfile( sfile )
      if err then return _,err end
      local tables = ftables()
      for idx = 1,#tables do
         local tolinki = {}
         for i,v in pairs( tables[idx] ) do
            if type( v ) == "table" then
               tables[idx][i] = tables[v[1]]
            end
            if type( i ) == "table" and tables[i[1]] then
               table.insert( tolinki,{ i,tables[i[1]] } )
            end
         end
         -- link indices
         for _,v in ipairs( tolinki ) do
            tables[idx][v[2]],tables[idx][v[1]] =  tables[idx][v[1]],nil
         end
      end
      return tables[1]
   end
-- close do
end
     
function table.val_to_str ( v )
  if "string" == type( v ) then
    v = string.gsub( v, "\n", "\\n" )
    if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
      return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
  else
    return "table" == type( v ) and table.tostring( v ) or
      tostring( v )
  end
end

function table.key_to_str ( k )
  if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
    return k
  else
    return "[" .. table.val_to_str( k ) .. "]"
  end
end
function table.tostring( tbl )
  local result, done = {}, {}
  for k, v in ipairs( tbl ) do
    table.insert( result, table.val_to_str( v ) )
    done[ k ] = true
  end
  for k, v in pairs( tbl ) do
    if not done[ k ] then
      table.insert( result,
        table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
    end
  end
  return "{" .. table.concat( result, "," ) .. "}"
end

function file_exists(name) --check if the file already exists for writing
    if lfs.attributes(name) then
    return true
    else
    return false end 
end
--end of functions

RedGraveyard ={}
if file_exists("RedGraveyard.lua") then
  env.info("RedGraveyard exists, loading ...")
  RedGraveyard = table.load( "RedGraveyard.lua" )
else RedGraveyard = {
   ["MiG-31"]=40,
}
  env.info("RedGraveyard does not exist, writing ...")
  table.save( RedGraveyard, "RedGraveyard.lua" )
end 

BlueGraveyard ={}
if file_exists("BlueGraveyard.lua") then
  env.info("BlueGraveyard exists, loading ...")
  BlueGraveyard = table.load( "BlueGraveyard.lua" )
else BlueGraveyard = {  
   ["F-14B"]=40,
}
  env.info("BlueGraveyard does not exist, writing ...")
  table.save( BlueGraveyard, "BlueGraveyard.lua" )
end 

AnyRedPilotDeath = EVENTHANDLER:New()
AnyRedPilotDeath:HandleEvent( EVENTS.PilotDead )
function AnyRedPilotDeath:OnEventPilotDead( EventData )
  if RedGraveyard[EventData.IniTypeName] then
    RedGraveyard[EventData.IniTypeName] = RedGraveyard[EventData.IniTypeName] - 1
  else
  --RedGraveyard[EventData.IniTypeName] = -1
  end
--env.info("PILOT DEATH")
 -- EventData.IniUnit:MessageToAll( EventData.place:getName() .. ": " .. EventData.IniTypeName .. " landed.", 15, "Landing" )
end

AnyRedPilotEject = EVENTHANDLER:New()
AnyRedPilotEject:HandleEvent( EVENTS.Ejection )
function AnyRedPilotEject:OnEventEjection( EventData )
  if RedGraveyard[EventData.IniTypeName] then
    RedGraveyard[EventData.IniTypeName] = RedGraveyard[EventData.IniTypeName] - 1
  else
  --RedGraveyard[EventData.IniTypeName] = -1
  end
--env.info("PILOT EJECT")
-- EventData.IniUnit:MessageToAll( EventData.place:getName() .. ": " .. EventData.IniTypeName .. " landed.", 15, "Landing" )
end

AnyBluePilotDeath = EVENTHANDLER:New()
AnyBluePilotDeath:HandleEvent( EVENTS.PilotDead )
function AnyBluePilotDeath:OnEventPilotDead( EventData )
  if BlueGraveyard[EventData.IniTypeName] then
    BlueGraveyard[EventData.IniTypeName] = BlueGraveyard[EventData.IniTypeName] - 1
  else
  --BlueGraveyard[EventData.IniTypeName] = -1
  end
--env.info("PILOT DEATH")
 -- EventData.IniUnit:MessageToAll( EventData.place:getName() .. ": " .. EventData.IniTypeName .. " landed.", 15, "Landing" )
end

AnyBluePilotEject = EVENTHANDLER:New()
AnyBluePilotEject:HandleEvent( EVENTS.Ejection )
function AnyBluePilotEject:OnEventEjection( EventData )
  if BlueGraveyard[EventData.IniTypeName] then
    BlueGraveyard[EventData.IniTypeName] = BlueGraveyard[EventData.IniTypeName] - 1
  else
  --BlueGraveyard[EventData.IniTypeName] = -1
  end
--env.info("PILOT EJECT")
-- EventData.IniUnit:MessageToAll( EventData.place:getName() .. ": " .. EventData.IniTypeName .. " landed.", 15, "Landing" )
end

RedCAPZone = ZONE:New( "Red CAP Zone", GROUP:FindByName( "Red CAP Zone" ) )    

RedDetectionSetGroup = SET_GROUP:New()
RedDetectionSetGroup:FilterCoalitions("red")
RedDetectionSetGroup:FilterPrefixes( { "EWR", "Overlord " } )
RedDetectionSetGroup:FilterStart()
RedDetection = DETECTION_AREAS:New( RedDetectionSetGroup, 5000 )

RedA2ADispatcher = AI_A2A_DISPATCHER:New( RedDetection )
RedA2ADispatcher:SetSquadron( "24th Fighter Aviation Regiment", rsrConfig.redAiCAPAirbase, { "24th Fighter Aviation Regiment" }, RedGraveyard["MiG-31"] ) --MiG-31 Squadron
RedA2ADispatcher:SetSquadronCap( "24th Fighter Aviation Regiment", RedCAPZone, 1000, 12000, 600, 800, 800, 1200, "BARO" )
RedA2ADispatcher:SetSquadronCapInterval( "24th Fighter Aviation Regiment", 2, 180, 600, 1 )
RedA2ADispatcher:SetDefaultTakeoffFromParkingHot()
RedA2ADispatcher:SetDefaultLandingAtEngineShutdown()  

BlueCAPZone = ZONE:New( "Blue CAP Zone", GROUP:FindByName( "Blue CAP Zone" ) )

BlueDetectionSetGroup = SET_GROUP:New()
BlueDetectionSetGroup:FilterCoalitions("blue")
BlueDetectionSetGroup:FilterPrefixes( { "EWR", "Magic " } )
BlueDetectionSetGroup:FilterStart()
BlueDetection = DETECTION_AREAS:New( BlueDetectionSetGroup, 5000 )
BlueA2ADispatcher = AI_A2A_DISPATCHER:New( BlueDetection )

BlueA2ADispatcher:SetSquadron( "313th Tactical Fighter Squadron", rsrConfig.blueAiCAPAirbase, { "313th Tactical Fighter Squadron" }, BlueGraveyard["F-14B"] ) --F14A Squadron
BlueA2ADispatcher:SetSquadronCap( "313th Tactical Fighter Squadron", BlueCAPZone, 1000, 12000, 600, 800, 800, 1200, "BARO" )
BlueA2ADispatcher:SetSquadronCapInterval( "313th Tactical Fighter Squadron", 2, 180, 600, 1 )
BlueA2ADispatcher:SetDefaultTakeoffFromParkingHot()
BlueA2ADispatcher:SetDefaultLandingAtEngineShutdown()

SCHEDULER:New( nil,function()
table.save( RedGraveyard, "RedGraveyard.lua" )
--env.info("Airbases: Updated.")

if RedGraveyard["MiG-31"] < 17 then RedA2ADispatcher:SetSquadronGrouping( "24th Fighter Aviation Regiment", 1) end
if RedGraveyard["MiG-31"]<3 then RedA2ADispatcher:SetSquadronCapInterval( "24th Fighter Aviation Regiment", 1, 180, 600, 1 ) end
end, {}, 10, 300)

SCHEDULER:New( nil,function()
table.save( BlueGraveyard, "BlueGraveyard.lua" )
--env.info("Airbases: Updated.")

if BlueGraveyard["F-14B"] < 17 then BlueA2ADispatcher:SetSquadronGrouping( "313th Tactical Fighter Squadron", 1) end
if BlueGraveyard["F-14B"]<3 then BlueA2ADispatcher:SetSquadronCapInterval( "313th Tactical Fighter Squadron", 1, 180, 600, 1 ) end
end, {}, 10, 300)