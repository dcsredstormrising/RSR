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
-- add a warhouse and a zoneName to the map and copy their names into here...then define the unit types for the warehouse plus coalition and type(naval, ground) of warhouse and you're done.
-- warehouse and zone names must be unique
-- count is per unit type for 1 round: 10 MOSCOWs, 10 Type_054A, 40 T90s
-- unit type template name must have: Resupply in the name, that's how we know the unit came from a warehouse
-- this uses MOOSE warehousing
-- warehouse:AddAsset from Mooose can take group name, or actual group object

-- Limitations: 
-- 1. We need to have a template in the miz file for each unit type.  This is not necessary because we can use DCS, EF, MOOSE, even CTLD to spawn units dynamically but it needs more work
-- 2. Ground unit types in warehouses must be unique.  Can't use T-72 in 2 different warehouses.  That limitation comes from lack of zones.  Right now half the map has T-72s and the other has T-90s. 
-- each half of the map has it's warehouse.  That's how "zoning" is implemented.  Would require more work to remove that.
-- everything works on Resupply as the name of the unit
-- spawnBy="DYNAMIC" uses DCS to create units, spawnBy="LA" uses Late Activation (template="Resupply Blue Tarawa") to create units
-- Late Activation template is built like this: warehouseGroupTag..'_'..warehouseName..'_'..asset.name  example: Resupply_BNW_Leopard-2   You will need to add it like that to ME
   
local inspect = require("inspect")
local utils = require("utils")
local warehousesExistOnMap = false
local saveDelay = 5
local ArmedForce = {ARMY=1, NAVY=2, AIRFORCE=3}
local SpawnType = {DYNAMIC=1, LATE_ACTIVATION=2}
local warehouseGroupTag = "Resupply"

-- unitCategory requried by Moose for dynamic spawning, DCS has this but without the ENUM like Moose.  If using late activation templates, unitCategory is not required
local CategoryNames={[Unit.Category.AIRPLANE]="Airplane",[Unit.Category.HELICOPTER]="Helicopter",[Unit.Category.GROUND_UNIT]="Ground Unit",[Unit.Category.SHIP]="Ship",[Unit.Category.STRUCTURE]="Structure",}-- requried by Moose for dynamic spawning
 
local warehouses = 
{
    ["BNW"] = {displayName="Blue Northern Warehouse", isActive=true, type=ArmedForce.ARMY, spawnBy=SpawnType.DYNAMIC, country=country.id.USA, side=coalition.side.BLUE, sideName="BLUE", respawnDelay=10, zoneSize=300, coverageZone="BlueNorthZone", spawnZone="BlueNorthWarehouseSpawn", 
      assets = {
        {name="M1045 HMMWV TOW", groupCat=Group.Category.GROUND, catName=Unit.Category.GROUND_UNIT, iniSpawnCount=3, spawnCount=1, count=10, spawnDelay=10, respawnDelay=10, country=country.id.UK, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=false},
        {name="M1134 Stryker ATGM", groupCat=Group.Category.GROUND, catName=Unit.Category.GROUND_UNIT, iniSpawnCount=3, spawnCount=1, count=10, spawnDelay=10, respawnDelay=10, country=country.id.UK, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=false},
        {name="Leopard-2A5", groupCat=Group.Category.GROUND, catName=Unit.Category.GROUND_UNIT, iniSpawnCount=3, spawnCount=1, count=10, spawnDelay=10, respawnDelay=10, country=country.id.GERMANY, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=false},
      }},
    ["BSW"] = {displayName="Blue Southern Warehouse", isActive=true, type=ArmedForce.ARMY, spawnBy=SpawnType.DYNAMIC, country=country.id.USA, side=coalition.side.BLUE, sideName="BLUE", respawnDelay=10, zoneSize=300, coverageZone="BlueSouthZone", spawnZone="BlueSouthWarehouseSpawn",
      assets = {
        {name="VAB_Mephisto", groupCat=Group.Category.GROUND, catName=Unit.Category.GROUND_UNIT, iniSpawnCount=3, spawnCount=1, count=10, spawnDelay=10, respawnDelay=10, country=country.id.UK, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=false}, 
        {name="M-2 Bradley", groupCat=Group.Category.GROUND, catName=Unit.Category.GROUND_UNIT, iniSpawnCount=3, spawnCount=1, count=10, spawnDelay=10, respawnDelay=10, country=country.id.UK, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=false},
        {name="Challenger2", groupCat=Group.Category.GROUND, catName=Unit.Category.GROUND_UNIT, iniSpawnCount=3, spawnCount=1, count=10, spawnDelay=10, respawnDelay=10, country=country.id.GERMANY, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=false},        
      }},            
    ["BEW"] = {displayName="Blue Eastern Warehouse", isActive=true, type=ArmedForce.ARMY, spawnBy=SpawnType.DYNAMIC, country=country.id.USA, side=coalition.side.BLUE, sideName="BLUE", respawnDelay=10, zoneSize=300, coverageZone="BlueEastZone", spawnZone="BlueEastWarehouseSpawn", 
      assets = {
        {name="M1097 Avenger", groupCat=Group.Category.GROUND, catName=Unit.Category.GROUND_UNIT, iniSpawnCount=2, spawnCount=1, count=8, spawnDelay=10, respawnDelay=10, country=country.id.USA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=false}, 
        {name="HQ-7_LN_SP", groupCat=Group.Category.GROUND, catName=Unit.Category.GROUND_UNIT, iniSpawnCount=2, spawnCount=1, count=8, spawnDelay=10, respawnDelay=10, country=country.id.USA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=false},
        {name="M6 Linebacker", groupCat=Group.Category.GROUND, catName=Unit.Category.GROUND_UNIT, iniSpawnCount=2, spawnCount=1, count=8, spawnDelay=10, respawnDelay=10, country=country.id.USA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=false},
        {name="Roland ADS", groupCat=Group.Category.GROUND, catName=Unit.Category.GROUND_UNIT, iniSpawnCount=2, spawnCount=1, count=6, spawnDelay=10, respawnDelay=10, country=country.id.USA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=true},
      }},
    ["BNavalW"] = {displayName="Blue Naval Warehouse", isActive=true, type=ArmedForce.NAVY, spawnBy=SpawnType.DYNAMIC, country=country.id.USA, side=coalition.side.BLUE, sideName="BLUE", respawnDelay=7200, zoneSize=300, spawnZone="BlueNavalSpawn",
      assets = {
        {name="CVN_73", groupCat=Group.Category.SHIP, catName=Unit.Category.SHIP, iniSpawnCount=1, spawnCount=1, count=6, spawnDelay=10, respawnDelay=10, country=country.id.USA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=true},
        {name="Type_052C", groupCat=Group.Category.SHIP, catName=Unit.Category.SHIP, iniSpawnCount=1, spawnCount=1, count=1, spawnDelay=1800, respawnDelay=10, country=country.id.USA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=true},
        {name="Type_052B", groupCat=Group.Category.SHIP, catName=Unit.Category.SHIP, iniSpawnCount=1, spawnCount=1, count=1, spawnDelay=10, respawnDelay=10, country=country.id.USA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=true},        
        {name="Type_054A", groupCat=Group.Category.SHIP, catName=Unit.Category.SHIP, iniSpawnCount=1, spawnCount=1, count=1, spawnDelay=3600, respawnDelay=10, country=country.id.USA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=true},
        {name="PERRY", groupCat=Group.Category.SHIP, catName=Unit.Category.SHIP, iniSpawnCount=1, spawnCount=1, count=2, spawnDelay=10, respawnDelay=10, country=country.id.USA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=true},
        {name="TICONDEROG", groupCat=Group.Category.SHIP, catName=Unit.Category.SHIP, iniSpawnCount=1, spawnCount=1, count=2, spawnDelay=10, respawnDelay=10, country=country.id.USA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=true},
        {name="NEUSTRASH", groupCat=Group.Category.SHIP, catName=Unit.Category.SHIP, iniSpawnCount=1, spawnCount=1, count=2, spawnDelay=3600, respawnDelay=10, country=country.id.USA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=true},
        {name="REZKY", groupCat=Group.Category.SHIP, catName=Unit.Category.SHIP, iniSpawnCount=1, spawnCount=1, count=3, spawnDelay=10, respawnDelay=10, country=country.id.USA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=true},
        {name="ALBATROS", groupCat=Group.Category.SHIP, catName=Unit.Category.SHIP, iniSpawnCount=1, spawnCount=1, count=3, spawnDelay=10, respawnDelay=10, country=country.id.USA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=true},
        {name="MOSCOW", groupCat=Group.Category.SHIP, catName=Unit.Category.SHIP, iniSpawnCount=1, spawnCount=1, count=2, spawnDelay=10, respawnDelay=10, country=country.id.USA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=true},
        {name="MOLNIYA", groupCat=Group.Category.SHIP, catName=Unit.Category.SHIP, iniSpawnCount=1, spawnCount=1, count=3, spawnDelay=1800, respawnDelay=10, country=country.id.USA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=true},
        {name="Type_093", groupCat=Group.Category.SHIP, catName=Unit.Category.SHIP, iniSpawnCount=1, spawnCount=1, count=2, spawnDelay=10, respawnDelay=10, country=country.id.USA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=true},
        {name="La_Combattante_II", groupCat=Group.Category.SHIP, catName=Unit.Category.SHIP, iniSpawnCount=1, spawnCount=1, count=2, spawnDelay=10, respawnDelay=10, country=country.id.USA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=true},
        {name="USS_Arleigh_Burke_IIa", groupCat=Group.Category.SHIP, catName=Unit.Category.SHIP, iniSpawnCount=1, spawnCount=1, count=2, spawnDelay=10, respawnDelay=10, country=country.id.USA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=true},
      }},     
    ["BAW"] = {displayName="Blue AirForce Warehouse", isActive=false, type=ArmedForce.AIRFORCE, spawnBy=SpawnType.DYNAMIC, country=country.id.USA, side=coalition.side.BLUE, sideName="BLUE", respawnDelay=10, zoneSize=300, coverageZone="BlueAirForceZone", spawnZone="BlueAirForceWarehouseSpawn", 
      assets = {
        {name="Ka-50", groupCat=Group.Category.HELICOPTER, catName=Unit.Category.HELICOPTER, iniSpawnCount=1, spawnCount=1, count=10, spawnDelay=10, respawnDelay=60, country=country.id.USA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=false},       
      }},
            
    ["RNW"] = {displayName="Red Northern Warehouse", isActive=true, type=ArmedForce.ARMY, spawnBy=SpawnType.DYNAMIC, country=country.id.RUSSIA, side=coalition.side.RED, sideName="RED", respawnDelay=10, zoneSize=300, coverageZone="RedNorthZone", spawnZone="RedNorthWarehouseSpawn", 
      assets = {
        {name="BMP-2", groupCat=Group.Category.GROUND, catName=Unit.Category.GROUND_UNIT, iniSpawnCount=3, spawnCount=1, count=10, spawnDelay=10, respawnDelay=10, country=country.id.RUSSIA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=false},
        {name="BMP-3", groupCat=Group.Category.GROUND, catName=Unit.Category.GROUND_UNIT, iniSpawnCount=3, spawnCount=1, count=10, spawnDelay=10, respawnDelay=10, country=country.id.RUSSIA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=false},
        {name="ZTZ96B", groupCat=Group.Category.GROUND, catName=Unit.Category.GROUND_UNIT, iniSpawnCount=3, spawnCount=1, count=10, spawnDelay=10, respawnDelay=10, country=country.id.RUSSIA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=false},
      }},
    ["RSW"] = {displayName="Red Southern Warehouse", isActive=true, type=ArmedForce.ARMY, spawnBy=SpawnType.DYNAMIC, country=country.id.RUSSIA, side=coalition.side.RED, sideName="RED", respawnDelay=10, zoneSize=300, coverageZone="RedSouthZone", spawnZone="RedSouthWarehouseSpawn", 
      assets = {
        {name="ZBD04A", groupCat=Group.Category.GROUND, catName=Unit.Category.GROUND_UNIT, iniSpawnCount=3, spawnCount=1, count=10, spawnDelay=10, respawnDelay=10, country=country.id.RUSSIA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=false},
        {name="BMD-1", groupCat=Group.Category.GROUND, catName=Unit.Category.GROUND_UNIT, iniSpawnCount=3, spawnCount=1, count=10, spawnDelay=10, respawnDelay=10, country=country.id.RUSSIA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=false},
        {name="Leclerc", groupCat=Group.Category.GROUND, catName=Unit.Category.GROUND_UNIT, iniSpawnCount=3, spawnCount=1, count=10, spawnDelay=10, respawnDelay=10, country=country.id.RUSSIA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=false},
      }},
    ["REW"] = {displayName="Red Eastern Warehouse", isActive=true, type=ArmedForce.ARMY, spawnBy=SpawnType.DYNAMIC, country=country.id.RUSSIA, side=coalition.side.RED, sideName="RED", respawnDelay=10, zoneSize=300, coverageZone="RedEastZone", spawnZone="RedEastWarehouseSpawn", 
      assets = {
        {name="Strela-10M3", groupCat=Group.Category.GROUND, catName=Unit.Category.GROUND_UNIT, iniSpawnCount=2, spawnCount=1, count=8, spawnDelay=10, respawnDelay=10, country=country.id.RUSSIA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=false},
        {name="2S6 Tunguska", groupCat=Group.Category.GROUND, catName=Unit.Category.GROUND_UNIT, iniSpawnCount=2, spawnCount=1, count=8, spawnDelay=10, respawnDelay=10, country=country.id.RUSSIA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=false},
        {name="HQ-7_LN_SP", groupCat=Group.Category.GROUND, catName=Unit.Category.GROUND_UNIT, iniSpawnCount=2, spawnCount=1, count=8, spawnDelay=10, respawnDelay=10, country=country.id.RUSSIA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=false},
        {name="Tor 9A331", groupCat=Group.Category.GROUND, catName=Unit.Category.GROUND_UNIT, iniSpawnCount=2, spawnCount=1, count=6, spawnDelay=10, respawnDelay=10, country=country.id.RUSSIA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=true},
      }},     
    ["RNavalW"] = {displayName="Red Naval Warehouse", isActive=true, type=ArmedForce.NAVY, spawnBy=SpawnType.DYNAMIC, country=country.id.RUSSIA, side=coalition.side.RED, sideName="RED", respawnDelay=7200, zoneSize=300, spawnZone="RedNavalSpawn", 
      assets = {
        {name="CV_1143_5", groupCat=Group.Category.SHIP, catName=Unit.Category.SHIP, iniSpawnCount=1, spawnCount=1, count=6, spawnDelay=10, respawnDelay=10, country=country.id.RUSSIA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=true},
        {name="Type_052C", groupCat=Group.Category.SHIP, catName=Unit.Category.SHIP, iniSpawnCount=1, spawnCount=1, count=1, spawnDelay=1800, respawnDelay=10, country=country.id.RUSSIA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=true},
        {name="Type_052B", groupCat=Group.Category.SHIP, catName=Unit.Category.SHIP, iniSpawnCount=1, spawnCount=1, count=1, spawnDelay=10, respawnDelay=10, country=country.id.RUSSIA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=true},        
        {name="Type_054A", groupCat=Group.Category.SHIP, catName=Unit.Category.SHIP, iniSpawnCount=1, spawnCount=1, count=1, spawnDelay=3600, respawnDelay=10, country=country.id.RUSSIA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=true},
        {name="PERRY", groupCat=Group.Category.SHIP, catName=Unit.Category.SHIP, iniSpawnCount=1, spawnCount=1, count=2, spawnDelay=10, respawnDelay=10, country=country.id.RUSSIA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=true},
        {name="TICONDEROG", groupCat=Group.Category.SHIP, catName=Unit.Category.SHIP, iniSpawnCount=1, spawnCount=1, count=2, spawnDelay=10, respawnDelay=10, country=country.id.RUSSIA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=true},
        {name="NEUSTRASH", groupCat=Group.Category.SHIP, catName=Unit.Category.SHIP, iniSpawnCount=1, spawnCount=1, count=2, spawnDelay=3600, respawnDelay=10, country=country.id.RUSSIA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=true},
        {name="REZKY", groupCat=Group.Category.SHIP, catName=Unit.Category.SHIP, iniSpawnCount=1, spawnCount=1, count=3, spawnDelay=10, respawnDelay=10, country=country.id.RUSSIA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=true},
        {name="ALBATROS", groupCat=Group.Category.SHIP, catName=Unit.Category.SHIP, iniSpawnCount=1, spawnCount=1, count=3, spawnDelay=10, respawnDelay=10, country=country.id.RUSSIA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=true},
        {name="MOSCOW", groupCat=Group.Category.SHIP, catName=Unit.Category.SHIP, iniSpawnCount=1, spawnCount=1, count=2, spawnDelay=10, respawnDelay=10, country=country.id.RUSSIA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=true},
        {name="MOLNIYA", groupCat=Group.Category.SHIP, catName=Unit.Category.SHIP, iniSpawnCount=1, spawnCount=1, count=3, spawnDelay=1800, respawnDelay=10, country=country.id.RUSSIA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=true},
        {name="Type_093", groupCat=Group.Category.SHIP, catName=Unit.Category.SHIP, iniSpawnCount=1, spawnCount=1, count=2, spawnDelay=10, respawnDelay=10, country=country.id.RUSSIA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=true},
        {name="La_Combattante_II", groupCat=Group.Category.SHIP, catName=Unit.Category.SHIP, iniSpawnCount=1, spawnCount=1, count=2, spawnDelay=10, respawnDelay=10, country=country.id.RUSSIA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=true},
        {name="USS_Arleigh_Burke_IIa", groupCat=Group.Category.SHIP, catName=Unit.Category.SHIP, iniSpawnCount=1, spawnCount=1, count=2, spawnDelay=10, respawnDelay=10, country=country.id.RUSSIA, skill=AI.Skill.EXCELLENT, EPLRS=false, hiddenOnMFD=false, enableEmission=true},
      }},
}
Warehouse_Dead = EVENTHANDLER:New()
Warehouse_Dead:HandleEvent(EVENTS.Dead)

local function getGroupName(warehouseName, asset)
  if asset ~= nil then	
	local sideName = warehouses[warehouseName].sideName	
    return warehouseGroupTag..'_'..sideName..'_'..warehouseName..'_'..asset.name -- Resupply_BNorthW_Leopard-2
  end  
end

-- this takes care of adding groups of units from the configuration into DCS.  You need this step if you do not have late activation.  Late activation templates are
-- loaded by DCS automatically, and dynamic units are not, so we sipmly load them here.  Required by DCS and MOOSE.
local function addDynamicGroupsToDCSandMoose()
  if warehouses ~= nil then
    for i, warehouse in pairs(warehouses) do
      if warehouse.isActive then
        if warehouse ~= nil and warehouse.assets ~= nil and warehouse.spawnBy == SpawnType.DYNAMIC then -- run this only for dynamic spawning and not late activation           
          for j,asset in pairs (warehouse.assets) do
            local groupData = utils.createGroupDataForWarehouseAsset(i, asset, warehouse.sideName)
            coalition.addGroup(asset.country, asset.groupCat, groupData) -- add to DCS memory          
            _DATABASE:_RegisterGroupTemplate(groupData,warehouse.side,asset.catName,groupData.country,groupData.name) -- add to MOOSE memory, this is the entire MOOSE trick
            --utils.setGroupControllerOptions(_myGroup) ? -- I may need this          
          end
        end
      end
    end
  end
end
   
-- add assets to warehouses during new campaign start
local function AddAssetsToWarehouse(warehouse, assets, warehouseName)
  if warehouse ~= nil and assets ~= nil then           
    for i,asset in pairs (assets) do      
      if warehouse.spawnBy == SpawnType.DYNAMIC then
        local groupForWarehouse=GROUP:FindByName(getGroupName(warehouseName, asset))
        warehouse[1]:AddAsset(groupForWarehouse, asset.count)      
      elseif warehouse.spawnBy == SpawnType.LATE_ACTIVATION then        
        warehouse[1]:AddAsset(getGroupName(warehouseName, asset), asset.count)
      else
        env.info("***=AW=33COM AddAssetsToWarehouse You fucked up somewhere the way you configured warehouses.")
      end
    end
  end
end

-- load warehouses
do
  -- Find warehouses on the map and create them. This is what allows everything to make it dynamic, warehouse instances go into our warehouses config table at position [1]
  -- Warehouses must exist in the configuration above in order to find them on the map
  if (warehouses ~= nil) then -- make sure at least 1 warehouse is configured before you start searching for warehouses on the map
    for warehouseName, warehouse in pairs(warehouses) do
      if warehouse.isActive then
        local warehouseFromMap = WAREHOUSE:New(STATIC:FindByName(warehouseName))  
        if warehouseFromMap ~= nil then
          warehousesExistOnMap = true
          table.insert(warehouse, warehouseFromMap)
        else
          env.info("***=AW=33COM Warehouse: " .. warehouse.displayName .. " is missing on the map.  You might have problems.")   
        end
      end
    end
    
    if warehousesExistOnMap then      
      addDynamicGroupsToDCSandMoose() -- the heart of everything      
      -- we check if the warehouse file exist, if they do, we load saved values from them
      if utils.file_exists(utils.getFirstKey(warehouses)) then --note this only checks one file, which assumes if 1 file is there, they are all there...limitation  
        env.info("***=AW=33COM Warehouses loaded from files.")
        -- Load warehouses from the saved files.
        for i, warehouse in pairs(warehouses) do 
          if warehouse.isActive then         
            env.info("***=AW=33COM Warehouses loading from files, warehouse: " .. i .. " and side: ".. inspect(warehouse.side))      
            warehouse[1]:Load(nil, i)            
            if warehouse[1]:GetCoalition()==warehouse.side then
              --warehouse[1]:SetWarehouseZone(warehouse.zoneSize)
              warehouse[1]:Start()            
              warehouse[1]:SetRespawnAfterDestroyed(warehouse.respawnDelay)            
              if warehouse.type == ArmedForce.NAVY then
                warehouse[1]:SetPortZone(ZONE_POLYGON:NewFromGroupName(warehouse.spawnZone, GROUP:FindByName(warehouse.spawnZone))):SetReportOff()
              else
                warehouse[1]:SetSpawnZone(ZONE_POLYGON:New(warehouse.spawnZone, GROUP:FindByName(warehouse.spawnZone))):SetReportOff()          
              end
            else
              warehouse[1]:SetRespawnAfterDestroyed(warehouse.respawnDelay)
            end    
          end
        end  
      else  
        -- brand new campaign, we create the warehouse files first  
        env.info("***=AW=33COM Warehouses loaded for the first time.")
		utils.storeCampaignData("CampaignStartDateTime", os.date('%A, %B %d %Y at %I:%M:%S %p')) -- it does not belong here, but I dont' have a place for it yet
				
        for i, warehouse in pairs(warehouses) do
          if warehouse.isActive then          
            env.info("***=AW=33COM New Campaign warehouse.spawnZone: " .. inspect(warehouse.spawnZone))
            --warehouse[1]:SetWarehouseZone(warehouse.zoneSize)
            warehouse[1]:Start()    
            warehouse[1]:SetRespawnAfterDestroyed(warehouse.respawnDelay)    
            AddAssetsToWarehouse(warehouse, warehouse.assets, i)      
            if warehouse.type == ArmedForce.NAVY then
              warehouse[1]:SetPortZone(ZONE_POLYGON:NewFromGroupName(warehouse.spawnZone, GROUP:FindByName(warehouse.spawnZone))):SetReportOff()
            else
              warehouse[1]:SetSpawnZone(ZONE_POLYGON:New(warehouse.spawnZone, GROUP:FindByName(warehouse.spawnZone))):SetReportOff()          
            end
          end
        end
      end
    end
  end
end

local function getWarehouseForAsset(name)
  if name ~= nil then
    local warehouseName = utils.split(name, "_")[2]
    return warehouses[warehouseName][1],warehouseName 
  end
end

local function getAssetTemplate(warehouseName, typeName)
  if warehouseName ~= nil and typeName ~= nil then
    env.info("warehouseName: "..warehouseName.." typeName: "..typeName)
    for _,asset in pairs (warehouses[warehouseName].assets) do      
      if asset.name == typeName then        
        return asset        
      end
    end
  end
end

--When a unit dies we check if it came from the warhouse, if it did, we add a request to respawn it
function Warehouse_Dead:OnEventDead(EventData)  
  if warehousesExistOnMap then
    if EventData.IniTypeName ~= nil and EventData.IniUnitName ~= nil then      
      if utils.isUnitFromWarehouse(inspect(EventData.IniUnitName)) then      
        env.info("***=AW=33COM Unit is from the warehouse: IniTypeName: ".. inspect(EventData.IniTypeName) .. " IniUnitName:" .. inspect(EventData.IniUnitName) .. " - Add Request to Warehouse***")
        local warehouse, warehouseName = getWarehouseForAsset(EventData.IniUnitName)
        if warehouse ~= nil then
          local asset = getAssetTemplate(warehouseName, EventData.IniTypeName)                
          if asset ~= nil then                        
            warehouse:__AddRequest(asset.respawnDelay, warehouse, WAREHOUSE.Descriptor.GROUPNAME, getGroupName(warehouseName, asset), asset.spawnCount, WAREHOUSE.TransportType.SELFPROPELLED)
            warehouse:__Save(saveDelay,nil,warehouseName)
          end
        end
      else
        --env.info("***=AW=33COM Unit not part of warehouse: IniTypeName: ".. inspect(EventData.IniTypeName) .. " IniUnitName:" .. inspect(EventData.IniUnitName) .. " - Do not add request to Warehouse***")    
      end
    end
  end  
end

if warehousesExistOnMap then
  -- This is how we handle the dynamic/generic way of handing OnAfterCaptured for warehouses
  -- DCS needs a generic event called Captured for anything capturable in order to avoid this "abstract" function loop. 
  -- When a warehouse is captured we either stop or start the warehouse depending on the coaltion.
  -- This runs on session start as warehouses start NEUTRAL and are captured right away by the unit standing there 
  for warehouseName, warehouseTable in pairs(warehouses) do
    if warehouseTable.isActive then
      local warehouse = warehouseTable[1] -- yup this is it, I never knew you could do this in LUA, function name is a variable and we need that to compile, 
      --this: warehouses["BlueNorthernWarehouse"][1] as a function name would not compile, but it does now lol 
      function warehouse:OnAfterCaptured(From, Event, To, Coalition, Country)
        if Coalition==warehouses[warehouseName].side then -- captured or recaptured by the same team      
          if (Coalition == coalition.side.BLUE) then
            MESSAGE:New("The " .. warehouses[warehouseName].displayName .. " is running at full capacity.",25,"[TEAM]:"):ToBlue()
          elseif (Coalition == coalition.side.RED) then
            MESSAGE:New("The " .. warehouses[warehouseName].displayName .. " is running at full capacity.",25,"[TEAM]:"):ToRed()
          end
          warehouse:Start()
          warehouse:SetReportOff()
          warehouse:__Save(saveDelay,nil,warehouseName)
          env.info("***=AW=33COM warehouse:OnAfterCaptured warehouse saved: " .. warehouseName)      
          if warehouses[warehouseName].assets ~= nil then  -- initial spawning when captured, I wonder if this works after recaptured, probably not as the file get overwritten              
            for i, asset in pairs(warehouses[warehouseName].assets) do
              --env.info("***=AW=33COM warehouse:OnAfterCaptured adding asset: " .. getGroupName(warehouseName, asset)) 
              warehouse:__AddRequest(asset.spawnDelay, warehouse, WAREHOUSE.Descriptor.GROUPNAME, getGroupName(warehouseName, asset), asset.iniSpawnCount, WAREHOUSE.TransportType.SELFPROPELLED)    
            end
          else
            env.info("***=AW=33COM warehouse:OnAfterCaptured warehouseName.assets are NOT THERE for warehouseName: " .. warehouseName)
          end      
        elseif Coalition==utils.GetOppositeCoalitionName(warehouses[warehouseName].side) then -- captured by the opposite team      
          if (Coalition == coalition.side.BLUE) then  
            MESSAGE:New("We have captured ".. warehouses[warehouseName].sideName .." Team's "..warehouses[warehouseName].displayName..", they will no longer receive re-enforcements.",25,"[TEAM]:"):ToBlue()
            MESSAGE:New("We have lost the ".. warehouses[warehouseName].displayName .." and no longer able to re-enforce the front.",25,"[TEAM]:"):ToRed()  
          elseif (Coalition == coalition.side.RED) then
            MESSAGE:New("We have captured ".. warehouses[warehouseName].sideName .." Team's "..warehouses[warehouseName].displayName..", they will no longer receive re-enforcements.",25,"[TEAM]:"):ToRed()
            MESSAGE:New("We have lost the ".. warehouses[warehouseName].displayName .." and no longer able to re-enforce the front.",25,"[TEAM]:"):ToBlue()      
          end
		  warehouse:_Fireworks()
          warehouse:Stop()
          warehouse:SetReportOff()
          warehouse:__Save(saveDelay,nil,warehouseName)
        else
          env.info("***=AW=33COM warehouse:OnAfterCaptured Coalition problem for warehouse: " .. warehouseName)  
        end
      end
    end
  end  
end