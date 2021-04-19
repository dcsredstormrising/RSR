-- Name: Warehouse Resupply

-- Rewritten by =AW=33COM in order to:
-- 1. Be able to use the same type of ships in the static mission and dynamic warehouses
-- 2. Be able to use the same type of ground units in the static mission and dynamic warehouses
-- 3. Be able to use the same type of units across coalitions.
-- 4. Be able to add warehouses through configuration.
-- 5. Be able to add new warhouses to the map and configure them here and make them work withou programming
-- 6. Be able to configure this without a programmer
-- Notes: The above items were not possible as everything was hardcoded and checked only at type level.  If you added a specific type to RED it was not possible to add it to BLUE.
-- or it was not possible to sling tanks if they were in the warehouse
-- you can now configure your warehouses and add new once without programming
-- add a warhouse and a zone to the map and copy their names into here...then define the unit types for the warehouse plus coalition and type(naval, ground) of warhouse and you're done.
-- warehouse and zone names must be unique
-- count is per unit type for 1 round: 10 MOSCOWs, 10 Type_054A, 40 T90s
-- unit type template name must have: Resupply in the name, that's how we know the unit came from a warehouse
--
-- Limitations: 
-- 1. We need to have a template in the miz file for each unit type.  This is not necessary because we can use DCS, MIST, MOOSE, even CTLD to spawn units dynamically but it needs more work
-- 2. Ground unit types in warehouses must be unique.  Can't use T-72 in 2 different warehouses.  That limitation comes from lack of zones.  Right now half the map has T-72s and the other has T-90s. 
-- each half of the map has it's warehouse.  That's how "zoning" is implemented.  Would require more work to remove that. 

local inspect = require("inspect")
local utils = require("utils")
local warehouseRespawnDelay = 3600
local saveDelay = 10
local warehouses = 
{
    ["BlueNorthernWarehouse"] = {type="ground", side=2, zone="Blue Northern Warehouse Zone", 
      unitTypes = {
        {name="MCV-80", template="Resupply Blue IFV North", spawnCount=2, count=40, spawnDelay=10, respawnDelay=1800}, 
        {name="Leopard-2", template="Resupply Blue MBT North", spawnCount=1, count=40, spawnDelay=10, respawnDelay=1800}
      }},    
    ["BlueSouthernWarehouse"] = {type="ground", side=2, zone="Blue Southern Warehouse Zone", 
      unitTypes = {
        {name="LAV-25", template="Resupply Blue IFV South", spawnCount=2, count=40, spawnDelay=10, respawnDelay=1800},
        {name="Merkava_Mk4", template="Resupply Blue MBT South", spawnCount=1, count=40, spawnDelay=10, respawnDelay=1800}
      }},  
    ["BlueNavalWarehouse"] = {type="naval", side=2, zone="Blue Naval Zone", 
      unitTypes = {
        {name="CVN_73", template="Resupply Blue Carrier", spawnCount=1, count=8, spawnDelay=10, respawnDelay=360},
        {name="LHA_Tarawa", template="Resupply Blue Tarawa", spawnCount=1, count=6, spawnDelay=10, respawnDelay=360},
        {name="Type_052C", template="Resupply Blue Type 052C", spawnCount=1, count=3, spawnDelay=10, respawnDelay=3600},
        {name="Type_052B", template="Resupply Blue Type 052B", spawnCount=1, count=3, spawnDelay=10, respawnDelay=3600},        
        {name="Type_054A", template="Resupply Blue Type 054A", spawnCount=1, count=3, spawnDelay=3600, respawnDelay=3600},
        {name="PERRY", template="Resupply Blue Perry", spawnCount=1, count=3, spawnDelay=10, respawnDelay=3600},
        {name="TICONDEROG", template="Resupply Blue Ticonderoga", spawnCount=1, count=3, spawnDelay=10, respawnDelay=3600},
        {name="", template="Resupply Blue Neustrashimy", spawnCount=1, count=3, spawnDelay=3600, respawnDelay=3600},                
        {name="", template="Resupply Blue Rezky", spawnCount=1, count=3, spawnDelay=10, respawnDelay=3600},
        {name="", template="Resupply Blue Grisha", spawnCount=1, count=3, spawnDelay=10, respawnDelay=3600},
        {name="", template="Resupply Blue Pyotr Velikiy", spawnCount=1, count=3, spawnDelay=3600, respawnDelay=3600},
        {name="MOSCOW", template="Resupply Blue Moskva", spawnCount=1, count=3, spawnDelay=10, respawnDelay=3600},
        {name="MOLNIYA", template="Resupply Blue Molniya", spawnCount=1, count=3, spawnDelay=3600, respawnDelay=3600},
        {name="", template="Resupply Blue Submarine", spawnCount=1, count=2, spawnDelay=10, respawnDelay=3600},        
      }},           
    ["RedNorthernWarehouse"] = {type="ground", side=1, zone="Red Northern Warehouse Zone", 
      unitTypes = {
        {name="BMD-1", template="Resupply Red IFV North", count=40, spawnDelay=1800},
        {name="T-90", template="Resupply Red MBT North", count=40, spawnDelay=1800},
      }},
    ["RedSouthernWarehouse"] = {type="ground", side=1, zone="Red Southern Warehouse Zone",
      unitTypes = {
        {name="BMP-1", template="Resupply Red IFV South", count=40, spawnDelay=1800},
        {name="T-72B", template="Resupply Red MBT South", count=40, spawnDelay=1800},
      }},     
    ["RedNavalWarehouse"] = {type="naval", side=1, zone="Red Naval Zone", 
      unitTypes = {
        {name="CV_1143_5", template="Resupply Red Carrier", spawnCount=1, count=10, spawnDelay=10, respawnDelay=10},
        {name="Type_071", template="Resupply Red Transport Dock", spawnCount=1, count=10, spawnDelay=10, respawnDelay=10},
        {name="Type_052C", template="Resupply Red Type 052C", spawnCount=1, count=3, spawnDelay=10, respawnDelay=3600},
        {name="Type_052B", template="Resupply Red Type 052B", spawnCount=1, count=3, spawnDelay=10, respawnDelay=3600},        
        {name="Type_054A", template="Resupply Red Type 054A", spawnCount=1, count=3, spawnDelay=3600, respawnDelay=3600},
        {name="PERRY", template="Resupply Red Perry", spawnCount=1, count=3, spawnDelay=10, respawnDelay=3600},
        {name="TICONDEROG", template="Resupply Red Ticonderoga", spawnCount=1, count=3, spawnDelay=10, respawnDelay=3600},
        {name="", template="Resupply Red Neustrashimy", spawnCount=1, count=3, spawnDelay=3600, respawnDelay=3600},                
        {name="", template="Resupply Red Rezky", spawnCount=1, count=3, spawnDelay=10, respawnDelay=3600},
        {name="", template="Resupply Red Grisha", spawnCount=1, count=3, spawnDelay=10, respawnDelay=3600},
        {name="", template="Resupply Red Pyotr Velikiy", spawnCount=1, count=3, spawnDelay=3600, respawnDelay=3600},
        {name="MOSCOW", template="Resupply Red Moskva", spawnCount=1, count=3, spawnDelay=10, respawnDelay=3600},
        {name="MOLNIYA", template="Resupply Red Molniya", spawnCount=1, count=3, spawnDelay=3600, respawnDelay=3600},
        {name="", template="Resupply Red Submarine", spawnCount=1, count=2, spawnDelay=10, respawnDelay=3600},
      }},
}

Warehouse_EventHandler = EVENTHANDLER:New()
Warehouse_EventHandler:HandleEvent(EVENTS.Dead)
Warehouse_EventHandler:HandleEvent(EVENTS.Captured)

-- Find them on the map and create
for i, warehouse in pairs(warehouses) do
  table.insert(warehouse, WAREHOUSE:New(STATIC:FindByName(i)))
end

-- we check if the warehouse files exist, if they do, we load saved values from them
if M.file_exists(warehouse.List[1]) then --note this only checks one file, which assumes if 1 file is there, they are all there...limitation
  
  env.info("***=AW=33COM Warehouses loaded from files.")

  -- Load them from files, start, setup zone, and set respawn delay
  for i, warehouse in pairs(warehouses) do    
    if warehouse[1]:GetCoalition()==i.side then 
      warehouse[1]:Load(nil, i)
      warehouse[1]:Start()    
      warehouse[1]:SetRespawnAfterDestroyed(warehouseRespawnDelay)
      warehouse[1]:SetSpawnZone(ZONE_POLYGON:New(i.zone, GROUP:FindByName(i.zone))):SetReportOff()
    end    
  end
  
else  
  -- brand new campaign, we create the warehouse files first  
  env.info("***=AW=33COM Warehouses loaded for the first time.")
  
  --start, setup zone, and set respawn delay
  for i, warehouse in pairs(warehouses) do
    warehouse[1]:Start()    
    warehouse[1]:SetRespawnAfterDestroyed(warehouseRespawnDelay)
    warehouse[1]:SetSpawnZone(ZONE_POLYGON:New(i.zone, GROUP:FindByName(i.zone))):SetReportOff()
    AddAssetsToWarehouse(warehouse[1], i)
  end 
end

-- add assets to warehouses during new campaign start
local function AddAssetsToWarehouse(warehouse, assets)
  env.info("***=AW=33COM AddAssetsToWarehouse.")
  if warehouse ~= nil and assets ~= nil and assets.unitTypes ~= nil then
    for i,asset in pairs (assets) do
      warehouse:AddAsset(asset.template, asset.count)
    end    
  end
end

--When a unit dies we check if it came from the warhouse, if it did, we add a request to respawn it
function Warehouse_EventHandler:OnEventDead(EventData)
  
  if EventData.IniTypeName ~= nil and EventData.IniUnitName ~= nil then
    if M.isUnitFromWarehouse(inspect(EventData.IniUnitName)) then
      env.info("***=AW=33COM Unit is from the warehouse: IniTypeName: ".. inspect(EventData.IniTypeName) .. " IniUnitName:" .. inspect(EventData.IniUnitName) .. " - Add to Warehouse***")
      
      local warehouseName = {}
      local warehouse = {}  -- get the affected warehouse details from the template
      local unit = {} -- get details from the template of the unit that died 
      warehouse[1]:__AddRequest(unit.respawnDelay, warehouseName, WAREHOUSE.Descriptor.GROUPNAME, unit.template, 1, WAREHOUSE.TransportType.SELFPROPELLED)          
      warehouse[1]:__Save(saveDelay,nil,warehouseName)
      
    else
      env.info("***=AW=33COM Unit not part of warehouse: IniTypeName: ".. inspect(EventData.IniTypeName) .. " IniUnitName:" .. inspect(EventData.IniUnitName) .. " - Do not add to Warehouse***")    
    end
  end  
end

--When a warehouse is captured we either stop and start the warehouse depending on the coaltion
-- this runs on session start I believe, hence those full capacity messages
function Warehouse_EventHandler:OnAfterCaptured(From, Event, To, Coalition, Country)
    
  env.info("***=AW=33COM OnAfterCaptured")
  
  -- may need to figure out what actually gets captured here
  local warehouseName = {} 
  local warehouse = {} --figure out which warehouse was captured
  local unitTypes = {} -- get details from the template of the unit types for a given warehouse
  
  if Coalition==warehouse.side then -- if coalition matches warehouse produces
    if (Coalition == coalition.side.BLUE) then
      MESSAGE:New("The " .. warehouseName .. " is running at full capacity.",25,"[TEAM]:"):ToBlue()
    else
      MESSAGE:New("The " .. warehouseName .. " is running at full capacity.",25,"[TEAM]:"):ToRed()
    end
    
    warehouse[1]:Start()
    warehouse[1]:__Save(saveDelay,nil,warehouseName)
    
    if warehouseName.unitTypes ~= nil then    
      for i, unit in pairs(warehouseName.unitTypes) do
        warehouse[1]:AddRequest(warehouseName, WAREHOUSE.Descriptor.GROUPNAME, unit.template, unit.iniSpawnCount, WAREHOUSE.TransportType.SELFPROPELLED)    
      end
    end        
  else  -- if coalition does not matche warehouse produces
    
    if (Coalition == coalition.side.BLUE) then  
      MESSAGE:New("We have captured ".. Coalition .." Team's ".. warehouseName ..", they will no longer receive re-enforcements.",25,"[TEAM]:"):ToBlue()
      MESSAGE:New("We have lost the ".. warehouseName .." and no longer able to re-enforce the front.",25,"[TEAM]:"):ToBlue()  
    else
      MESSAGE:New("We have captured ".. Coalition .." Team's ".. warehouseName ..", they will no longer receive re-enforcements.",25,"[TEAM]:"):ToRed()
      MESSAGE:New("We have lost the ".. warehouseName .." and no longer able to re-enforce the front.",25,"[TEAM]:"):ToRed()      
    end 
    
    warehouse[1]:Stop()
    warehouse[1]:__Save(saveDelay,nil,warehouseName)
            
  end  
end
