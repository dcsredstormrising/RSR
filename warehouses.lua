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

local inspect = require("inspect")
local utils = require("utils")
local warehouseRespawnDelay = 3600
local warehouses = 
{
    ["BlueNorthernWarehouse"] = {type="ground", side=2, zone="Blue Northern Warehouse Zone", 
      unitTypes = {
        {name="MCV-80", template="Resupply Blue IFV North", count=40, spawnDelay=1800}, 
        {name="Leopard-2", template="Resupply Blue MBT North", count=40, spawnDelay=1800}
      }},    
    ["BlueSouthernWarehouse"] = {type="ground", side=2, zone="Blue Southern Warehouse Zone", 
      unitTypes = {
        {name="LAV-25", template="Resupply Blue IFV South", count=40, spawnDelay=1800},
        {name="Merkava_Mk4", template="Resupply Blue MBT South", count=40, spawnDelay=1800}
      }},  
    ["BlueNavalWarehouse"] = {type="naval", side=2, zone="Blue Naval Zone", 
      unitTypes = {
        {name="CVN_73", template="Resupply Blue Carrier", count=10, spawnDelay=1800},
        {name="LHA_Tarawa", template="Resupply Blue Tarawa", count=10, spawnDelay=1800},
        {name="Type_052C", template="Resupply Blue Type 052C", count=8, spawnDelay=3600},
        {name="Type_054A", template="Resupply Blue Type 054A", count=6, spawnDelay=3600},        
        {name="TICONDEROG", template="Resupply Blue Ticonderoga", count=8, spawnDelay=1800},
        {name="PERRY", template="Resupply Blue Perry", count=8, spawnDelay=1800},
        {name="MOSCOW", template="Resupply Blue Moskva", count=8, spawnDelay=3600},
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
        {name="MOSCOW", template="Resupply Red Moskva", count=8, spawnDelay=3600},
        {name="MOLNIYA", template="Resupply Red Molniya", count=8, spawnDelay=1800},
      }},
}

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


Warehouse_EventHandler = EVENTHANDLER:New()
Warehouse_EventHandler:HandleEvent(EVENTS.Dead)

----Spawn unit at a warehouse when a unit dies
function Warehouse_EventHandler:OnEventDead(EventData)

	-- here we check if the unit is player slung, if it's not we check if it's part of the warehouse...this allows us not to add player slung units to the warehouses	
	if EventData.IniUnitName ~= nil then	
		
		local isPlayerSlung = M.isUnitPlayerSlung(inspect(EventData.IniUnitName))	
			
		if isPlayerSlung == false then
		
			-- unit comes from miz or warehouse, we need to add it	
			if EventData.IniTypeName ~= nil and EventData.IniUnitName ~= nil then
				env.info("***=AW=33COM Warehouse Unit: IniTypeName: ".. inspect(EventData.IniTypeName) .. " IniUnitName:" .. inspect(EventData.IniUnitName) .. " - Add to Warehouse if type matches***")			
			end
				-- ships
			if EventData.IniTypeName == 'PERRY' then
				warehouse.BlueNavalWarehouse:__AddRequest(1800, warehouse.BlueNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue Perry", 1, WAREHOUSE.TransportType.SELFPROPELLED)
				warehouse.BlueNavalWarehouse:__Save(5,nil,"BlueNavalWarehouse")
			  elseif EventData.IniTypeName == 'TICONDEROG' then
				warehouse.BlueNavalWarehouse:__AddRequest(1800, warehouse.BlueNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue Ticonderoga", 1, WAREHOUSE.TransportType.SELFPROPELLED)
				warehouse.BlueNavalWarehouse:__Save(5,nil,"BlueNavalWarehouse")
			  elseif EventData.IniTypeName == 'Type_052C' then
				warehouse.BlueNavalWarehouse:__AddRequest(1800, warehouse.BlueNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue Type 052C", 1, WAREHOUSE.TransportType.SELFPROPELLED)
				warehouse.BlueNavalWarehouse:__Save(5,nil,"BlueNavalWarehouse")
			  elseif EventData.IniTypeName == 'CVN_73' then
			  
				local isFromNavalWarehouse = M.isUnitFromWarehouse(inspect(EventData.IniUnitName))	
				
				if isFromNavalWarehouse == true then
					env.info("***=AW=33COM Naval Warehouse BLUE Unit: IniTypeName: ".. inspect(EventData.IniTypeName) .. " IniUnitName:" .. inspect(EventData.IniUnitName) .. " - Add to BLUE Naval Warehouse***")			  
					warehouse.BlueNavalWarehouse:__AddRequest(1800, warehouse.BlueNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue Carrier", 1, WAREHOUSE.TransportType.SELFPROPELLED)
					warehouse.BlueNavalWarehouse:__Save(5,nil,"BlueNavalWarehouse")
				else
					env.info("***=AW=33COM Ship BLUE Unit: IniTypeName: ".. inspect(EventData.IniTypeName) .. " IniUnitName:" .. inspect(EventData.IniUnitName) .. " - DO NOT ADD to BLUE Naval Warehouse.  Ship comes from MIZ***")			
				end
				
			  elseif EventData.IniTypeName == 'LHA_Tarawa' then
				warehouse.BlueNavalWarehouse:__AddRequest(1800, warehouse.BlueNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue Tarawa", 1, WAREHOUSE.TransportType.SELFPROPELLED)
				warehouse.BlueNavalWarehouse:__Save(5,nil,"BlueNavalWarehouse")
				
			  elseif EventData.IniTypeName == 'Type_054A' then
				warehouse.RedNavalWarehouse:__AddRequest(1800, warehouse.RedNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red Type 054A", 1, WAREHOUSE.TransportType.SELFPROPELLED)
				warehouse.RedNavalWarehouse:__Save(5,nil,"RedNavalWarehouse")
			  elseif EventData.IniTypeName == 'MOSCOW' then
				warehouse.RedNavalWarehouse:__AddRequest(1800, warehouse.RedNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red Moskva", 1, WAREHOUSE.TransportType.SELFPROPELLED)
				warehouse.RedNavalWarehouse:__Save(5,nil,"RedNavalWarehouse")
			  elseif EventData.IniTypeName == 'MOLNIYA' then
				warehouse.RedNavalWarehouse:__AddRequest(1800, warehouse.RedNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red Molniya", 1, WAREHOUSE.TransportType.SELFPROPELLED)
				warehouse.RedNavalWarehouse:__Save(5,nil,"RedNavalWarehouse")
			  elseif EventData.IniTypeName == 'CV_1143_5' then
			  
				local isFromNavalWarehouse = M.isUnitFromWarehouse(inspect(EventData.IniUnitName))	
				
				if isFromNavalWarehouse == true then
					env.info("***=AW=33COM Naval Warehouse RED Unit: IniTypeName: ".. inspect(EventData.IniTypeName) .. " IniUnitName:" .. inspect(EventData.IniUnitName) .. " - Add to RED Naval Warehouse***")			
					warehouse.RedNavalWarehouse:__AddRequest(1800, warehouse.RedNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red Carrier", 1, WAREHOUSE.TransportType.SELFPROPELLED)
					warehouse.RedNavalWarehouse:__Save(5,nil,"RedNavalWarehouse")
				else
					env.info("***=AW=33COM Ship RED Unit: IniTypeName: ".. inspect(EventData.IniTypeName) .. " IniUnitName:" .. inspect(EventData.IniUnitName) .. " - DO NOT ADD to RED Naval Warehouse.  Ship comes from MIZ***")			
				end
				
			  elseif EventData.IniTypeName == 'Type_071' then
				warehouse.RedNavalWarehouse:__AddRequest(1800, warehouse.RedNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red Transport Dock", 1, WAREHOUSE.TransportType.SELFPROPELLED)
				warehouse.RedNavalWarehouse:__Save(5,nil,"RedNavalWarehouse")	
			  
			  --ground units  	
			  elseif EventData.IniTypeName == 'MCV-80' then
				warehouse.BlueNorthernWarehouse:__AddRequest(1800, warehouse.BlueNorthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue IFV North", 1, WAREHOUSE.TransportType.SELFPROPELLED)
				warehouse.BlueNorthernWarehouse:__Save(5,nil,"BlueNorthernWarehouse")
			  elseif EventData.IniTypeName == 'LAV-25' then
				warehouse.BlueSouthernWarehouse:__AddRequest(1800, warehouse.BlueSouthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue IFV South", 1, WAREHOUSE.TransportType.SELFPROPELLED)
				warehouse.BlueSouthernWarehouse:__Save(10,nil,"BlueSouthernWarehouse")
			  elseif EventData.IniTypeName == 'Leopard-2' then 
				warehouse.BlueNorthernWarehouse:__AddRequest(1800, warehouse.BlueNorthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue MBT North", 1, WAREHOUSE.TransportType.SELFPROPELLED)
				warehouse.BlueNorthernWarehouse:__Save(5,nil,"BlueNorthernWarehouse")
			  elseif EventData.IniTypeName == 'Merkava_Mk4' then
				warehouse.BlueSouthernWarehouse:__AddRequest(1800, warehouse.BlueSouthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue MBT South", 1, WAREHOUSE.TransportType.SELFPROPELLED)
				warehouse.BlueSouthernWarehouse:__Save(10,nil,"BlueSouthernWarehouse")	
				
			  elseif EventData.IniTypeName == 'BMD-1' then
				warehouse.RedNorthernWarehouse:__AddRequest(1800, warehouse.RedNorthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red IFV North", 1, WAREHOUSE.TransportType.SELFPROPELLED)
				warehouse.RedNorthernWarehouse:__Save(5,nil,"RedNorthernWarehouse")
			  elseif EventData.IniTypeName == 'BMP-1' then
				warehouse.RedSouthernWarehouse:__AddRequest(1800, warehouse.RedSouthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red IFV South", 1, WAREHOUSE.TransportType.SELFPROPELLED)
				warehouse.RedSouthernWarehouse:__Save(10,nil,"RedSouthernWarehouse")
			  elseif EventData.IniTypeName == 'T-90' then
				warehouse.RedNorthernWarehouse:__AddRequest(1800, warehouse.RedNorthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red MBT North", 1, WAREHOUSE.TransportType.SELFPROPELLED)
				warehouse.RedNorthernWarehouse:__Save(5,nil,"RedNorthernWarehouse")
			  elseif EventData.IniTypeName == 'T-72B' then
				warehouse.RedSouthernWarehouse:__AddRequest(1800, warehouse.RedSouthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red MBT South", 1, WAREHOUSE.TransportType.SELFPROPELLED)
				warehouse.RedSouthernWarehouse:__Save(10,nil,"RedSouthernWarehouse")
			  else
				--nothing
			end
		else
			-- unit is player spawn, no need to do anything
			if EventData.IniTypeName ~= nil and EventData.IniUnitName ~= nil then
				env.info("***=AW=33COM Slung Unit: IniTypeName: ".. inspect(EventData.IniTypeName) .. " IniUnitName:" .. inspect(EventData.IniUnitName) .. " - Do not add to Warehouse***")			
			end
		end
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

---- An asset has died request self resupply for it from the warehouse. Would be awesome if I could somehow get the warehouse to recognize the units after a restart. 
-- Until then going to send a request to ALL warehouses dependent on when the type of vehicle that dies, Probably not going to only make the fixed SAM sites at least not based on warehouses. 
--function warehouse.BlueNorthernWarehouse:OnAfterAssetDead(From, Event, To, asset, request)
--  local asset=asset       --Functional.Warehouse#WAREHOUSE.Assetitem
--  local request=request   --Functional.Warehouse#WAREHOUSE.Pendingitem
--
--  -- Get assignment.
--  local assignment=warehouse.BlueNorthernWarehouse:GetAssignment(request)
--    warehouse.BlueNorthernWarehouse:AddRequest(warehouse.BlueNorthernWarehouse, WAREHOUSE.Descriptor.ATTRIBUTE, asset.attribute, nil, nil, nil, nil, "Resupply from Blue Northern Warehouse")
--    warehouse.BlueNorthernWarehouse:__Save(15,nil,"BlueNorthernWarehouse")
--end


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