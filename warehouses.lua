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
        {name="MCV-80", template="Resupply Blue IFV North", iniSpawnCount=2, count=40, spawnDelay=1800}, 
        {name="Leopard-2", template="Resupply Blue MBT North", iniSpawnCount=1, count=40, spawnDelay=1800}
      }},    
    ["BlueSouthernWarehouse"] = {type="ground", side=2, zone="Blue Southern Warehouse Zone", 
      unitTypes = {
        {name="LAV-25", template="Resupply Blue IFV South", iniSpawnCount=2, count=40, spawnDelay=1800},
        {name="Merkava_Mk4", template="Resupply Blue MBT South", iniSpawnCount=1, count=40, spawnDelay=1800}
      }},  
    ["BlueNavalWarehouse"] = {type="naval", side=2, zone="Blue Naval Zone", 
      unitTypes = {
        {name="CVN_73", template="Resupply Blue Carrier", count=10, spawnDelay=1800},
        {name="LHA_Tarawa", template="Resupply Blue Tarawa", count=10, spawnDelay=1800},
        {name="Type_052C", template="Resupply Blue Type 052C", count=8, spawnDelay=3600},
        {name="Type_054A", template="Resupply Blue Type 054A", count=6, spawnDelay=3600},        
        {name="TICONDEROG", template="Resupply Blue Ticonderoga", count=8, spawnDelay=1800},
        {name="PERRY", template="Resupply Blue Perry", count=8, spawnDelay=1800},
        {name="MOSCOW", template="Resupply Blue Moskva", count=6, spawnDelay=3600},
        {name="MOLNIYA", template="Resupply Blue Molniya", count=8, spawnDelay=1800},        
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
        {name="CV_1143_5", template="Resupply Red Carrier", count=10, spawnDelay=1800},
        {name="Type_071", template="Resupply Red Transport Dock", count=10, spawnDelay=1800},
        {name="Type_052C", template="Resupply Red Type 052C", count=8, spawnDelay=3600},
        {name="Type_054A", template="Resupply Red Type 054A", count=6, spawnDelay=3600},        
        {name="TICONDEROG", template="Resupply Red Ticonderoga", count=8, spawnDelay=1800},
        {name="PERRY", template="Resupply Red Perry", count=8, spawnDelay=1800},
        {name="MOSCOW", template="Resupply Red Moskva", count=6, spawnDelay=3600},
        {name="MOLNIYA", template="Resupply Red Molniya", count=8, spawnDelay=1800},
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
      warehouse[1]:__AddRequest(unit.spawnDelay, warehouseName, WAREHOUSE.Descriptor.GROUPNAME, unit.template, 1, WAREHOUSE.TransportType.SELFPROPELLED)          
      warehouse[1]:__Save(saveDelay,nil,warehouseName)
      
    else
      env.info("***=AW=33COM Unit not part of warehouse: IniTypeName: ".. inspect(EventData.IniTypeName) .. " IniUnitName:" .. inspect(EventData.IniUnitName) .. " - Do not add to Warehouse***")    
    end
  end  
end

--When a warehouse is captured we either stop and start the warehouse depending on the coaltion
function Warehouse_EventHandler:OnAfterCaptured(From, Event, To, Coalition, Country)
    
  -- may need to figure out what actually gets captured here
  local warehouseName = {} 
  local warehouse = {} --figure out which warehouse was captured
  local unitTypes = {} -- get details from the template of the unit types for a given warehouse
  
  if Coalition==warehouse.side then
    MESSAGE:New("The " .. warehouseName .. " is running at full capacity.",25,"[TEAM]:"):ToBlue()
    warehouse[1]:Start()
    warehouse[1]:__Save(saveDelay,nil,warehouseName)
    
    if warehouseName.unitTypes ~= nil then    
      for i, unit in pairs(warehouseName.unitTypes) do
        warehouse[1]:__AddRequest(warehouseName, WAREHOUSE.Descriptor.GROUPNAME, unit.template, unit.iniSpawnCount, WAREHOUSE.TransportType.SELFPROPELLED)    
      end
    end        
  else
    MESSAGE:New("We have captured Blue Team's Northern Warehouse, they will no longer receive re-enforcements.",25,"[TEAM]:"):ToRed()
    MESSAGE:New("We have lost the Northern Warehouse and no longer able to re-enforce the front.",25,"[TEAM]:"):ToBlue()
    warehouse.BlueNorthernWarehouse:Stop()
    warehouse.BlueNorthernWarehouse:__Save(15,nil,"BlueNorthernWarehouse")
  end  
end

----Spawn Units after Capture
function warehouse.BlueNorthernWarehouse:OnAfterCaptured(From, Event, To, Coalition, Country)
--function warehouse.BlueNorthernWarehouse:OnAfterAirbaseCaptured(From,Event,To,Coalition)
  if Coalition==coalition.side.BLUE then
    MESSAGE:New("The Northern Warehouse is running at full capacity.",25,"[TEAM]:"):ToBlue()
    warehouse.BlueNorthernWarehouse:Start()
    warehouse.BlueNorthernWarehouse:__Save(15,nil,"BlueNorthernWarehouse")
    warehouse.BlueNorthernWarehouse:AddRequest(warehouse.BlueNorthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue MBT North", 1, WAREHOUSE.TransportType.SELFPROPELLED)
    warehouse.BlueNorthernWarehouse:AddRequest(warehouse.BlueNorthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue IFV North", 2, WAREHOUSE.TransportType.SELFPROPELLED)
  
  elseif Coalition==coalition.side.RED then
    MESSAGE:New("We have captured Blue Team's Northern Warehouse, they will no longer receive re-enforcements.",25,"[TEAM]:"):ToRed()
    MESSAGE:New("We have lost the Northern Warehouse and no longer able to re-enforce the front.",25,"[TEAM]:"):ToBlue()
    warehouse.BlueNorthernWarehouse:Stop()
    warehouse.BlueNorthernWarehouse:__Save(15,nil,"BlueNorthernWarehouse")
    end
end

function warehouse.BlueSouthernWarehouse:OnAfterCaptured(From, Event, To, Coalition, Country)
--function  warehouse.BlueSouthernWarehouse:OnAfterAirbaseCaptured(From,Event,To,Coalition)
  if Coalition==coalition.side.BLUE then
    MESSAGE:New("The Southern Warehouse is running at full capacity.",25,"[TEAM]:"):ToBlue()
    warehouse.BlueSouthernWarehouse:Start()
    warehouse.BlueSouthernWarehouse:__Save(4,nil,"BlueSouthernWarehouse")
    warehouse.BlueSouthernWarehouse:AddRequest(warehouse.BlueSouthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue MBT South", 1, WAREHOUSE.TransportType.SELFPROPELLED)
    warehouse.BlueSouthernWarehouse:AddRequest(warehouse.BlueSouthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue IFV South", 2, WAREHOUSE.TransportType.SELFPROPELLED)
  
  elseif Coalition==coalition.side.RED then
    MESSAGE:New("We have captured Blue Team's Southern Warehouse, they will no longer receive re-enforcements.",25,"[TEAM]:"):ToRed()
    MESSAGE:New("We have lost the Southern Warehouse and no longer able to re-enforce the front.",25,"[TEAM]:"):ToBlue()
    warehouse.BlueSouthernWarehouse:Stop()
    warehouse.BlueSouthernWarehouse:__Save(15,nil,"BlueSouthernWarehouse")
    end
end

function warehouse.RedNorthernWarehouse:OnAfterCaptured(From, Event, To, Coalition, Country)
--function warehouse.RedNorthernWarehouse:OnAfterAirbaseCaptured(From,Event,To,Coalition)
  if Coalition==coalition.side.RED then
    MESSAGE:New("The Northern Warehouse is running at full capacity.",25,"[TEAM]:"):ToRed()
    warehouse.RedNorthernWarehouse:Start()
    warehouse.RedNorthernWarehouse:__Save(7,nil,"RedNorthernWarehouse")
    warehouse.RedNorthernWarehouse:AddRequest(warehouse.RedNorthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red MBT North", 1, WAREHOUSE.TransportType.SELFPROPELLED)
    warehouse.RedNorthernWarehouse:AddRequest(warehouse.RedNorthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red IFV North", 2, WAREHOUSE.TransportType.SELFPROPELLED)
  
  elseif Coalition==coalition.side.BLUE then
    MESSAGE:New("We have captured Red Team's Northern Warehouse, they will no longer receive re-enforcements.",25,"[TEAM]:"):ToBlue()
    MESSAGE:New("We have lost the Northern Warehouse and no longer able to re-enforce the front.",25,"[TEAM]:"):ToRed()
    warehouse.RedNorthernWarehouse:Stop()
    warehouse.RedNorthernWarehouse:__Save(10,nil,"RedNorthernWarehouse")
    end
end

function warehouse.RedSouthernWarehouse:OnAfterCaptured(From, Event, To, Coalition, Country)
--function warehouse.RedSouthernWarehouse:OnAfterAirbaseCaptured(From,Event,To,Coalition)
  if Coalition==coalition.side.RED then
    MESSAGE:New("The Southern Warehouse is running at full capacity.",25,"[TEAM]:"):ToRed()
    warehouse.RedSouthernWarehouse:Start()
    warehouse.RedSouthernWarehouse:__Save(9,nil,"RedSouthernWarehouse")
    warehouse.RedSouthernWarehouse:AddRequest(warehouse.RedSouthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red MBT South", 1, WAREHOUSE.TransportType.SELFPROPELLED)
    warehouse.RedSouthernWarehouse:AddRequest(warehouse.RedSouthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red IFV South", 2, WAREHOUSE.TransportType.SELFPROPELLED)
  
  elseif Coalition==coalition.side.BLUE then
    MESSAGE:New("We have captured Red Team's Southern Warehouse, they will no longer receive re-enforcements.",25,"[TEAM]:"):ToBlue()
    MESSAGE:New("We have lost the Southern Warehouse and no longer able to re-enforce the front.",25,"[TEAM]:"):ToRed()
    warehouse.RedSouthernWarehouse:Stop()
    warehouse.RedSouthernWarehouse:__Save(15,nil,"RedSouthernWarehouse")
    end
end

--Spawn naval units after capture
function warehouse.BlueNavalWarehouse:OnAfterCaptured(From, Event, To, Coalition, Country)
--function warehouse.BlueNavalWarehouse:OnAfterAirbaseCaptured(From,Event,To,Coalition)
  if Coalition==coalition.side.BLUE then
    MESSAGE:New("Our Drydock is running at full capacity.",25,"[TEAM]:"):ToBlue()
    warehouse.BlueNavalWarehouse:Start()
    warehouse.BlueNavalWarehouse:__Save(15,nil,"BlueNavalWarehouse")
--initial spawn of ships as well as when captured by blue team
    warehouse.BlueNavalWarehouse:AddRequest(warehouse.BlueNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue Type 052C", 2, WAREHOUSE.TransportType.SELFPROPELLED)
  	warehouse.BlueNavalWarehouse:AddRequest(warehouse.BlueNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue Ticonderoga", 2, WAREHOUSE.TransportType.SELFPROPELLED)
	  warehouse.BlueNavalWarehouse:AddRequest(warehouse.BlueNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue Perry", 2, WAREHOUSE.TransportType.SELFPROPELLED)
	  warehouse.BlueNavalWarehouse:AddRequest(warehouse.BlueNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue Carrier", 1, WAREHOUSE.TransportType.SELFPROPELLED)
    warehouse.BlueNavalWarehouse:AddRequest(warehouse.BlueNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue Tarawa", 1, WAREHOUSE.TransportType.SELFPROPELLED)
  
  elseif Coalition==coalition.side.RED then
    MESSAGE:New("We have captured Blue Team's Drydock! They will no longer be able to reinforce their fleet!",25,"[TEAM]:"):ToRed()
    MESSAGE:New("We have lost our Drydock and will no longer able to re-enforce the fleet.",25,"[TEAM]:"):ToBlue()
    warehouse.BlueNavalWarehouse:Stop()
    warehouse.BlueNavalWarehouse:__Save(15,nil,"BlueNavalWarehouse")
    end
end

function warehouse.RedNavalWarehouse:OnAfterCaptured(From, Event, To, Coalition, Country)
--function warehouse.RedSouthernWarehouse:OnAfterAirbaseCaptured(From,Event,To,Coalition)
  if Coalition==coalition.side.RED then
    MESSAGE:New("Our Drydock is running at full capacity.",25,"[TEAM]:"):ToRed()
    warehouse.RedNavalWarehouse:Start()
    warehouse.RedNavalWarehouse:__Save(9,nil,"RedNavalWarehouse")	
--initial spawn of ships as well as when captured by red team
    warehouse.RedNavalWarehouse:AddRequest(warehouse.RedNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red Type 054A", 2, WAREHOUSE.TransportType.SELFPROPELLED)
    warehouse.RedNavalWarehouse:AddRequest(warehouse.RedNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red Molniya", 2, WAREHOUSE.TransportType.SELFPROPELLED)
	  warehouse.RedNavalWarehouse:AddRequest(warehouse.RedNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red Moskva", 2, WAREHOUSE.TransportType.SELFPROPELLED)
    warehouse.RedNavalWarehouse:AddRequest(warehouse.RedNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red Carrier", 1, WAREHOUSE.TransportType.SELFPROPELLED)
	  warehouse.RedNavalWarehouse:AddRequest(warehouse.RedNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red Transport Dock", 1, WAREHOUSE.TransportType.SELFPROPELLED)
  elseif Coalition==coalition.side.BLUE then
    MESSAGE:New("We have captured Red Team's Drydock! They will no longer be able to reinforce their fleet!",25,"[TEAM]:"):ToBlue()
    MESSAGE:New("We have lost our Drydock and will no longer able to re-enforce the fleet.",25,"[TEAM]:"):ToRed()
    warehouse.RedNavalWarehouse:Stop()
    warehouse.RedNavalWarehouse:__Save(15,nil,"RedNavalWarehouse")
    end
end