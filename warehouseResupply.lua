-- Name: Warehouse Resupply

-- Mostly rewritten by =AW=33COM in order to:
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
local warRespawnDelay = 3600
local shipRespawnDelay = 1800
local vehicleRespawnDelay = 1800
local warUnitPrefix = "Resupply" -- do not change this
local warehouses = 
{
    ["BlueNorthernWarehouse"] = {type = "ground", side = 2, count = 40, zone = "Blue Northern Warehouse Zone", unitTypes = {"MCV-80","Leopard-2"}},    -- North units must be different than South, otherwise you will get double units I think
    ["BlueSouthernWarehouse"] = {type = "ground", side = 2, count = 40, zone = "Blue Southern Warehouse Zone", unitTypes = {"LAV-25", "Merkava_Mk4"}},  -- South units must be different than North  
    ["BlueNavalWarehouse"] = {type = "naval", side = 2, count = 10, zone = "Blue Naval Zone", unitTypes = {"CVN_73", "Type_052C", "Type_054A", "MOSCOW", "TICONDEROG", "PERRY", "MOLNIYA", "LHA_Tarawa"}}, -- ships can use same units   
    ["RedNorthernWarehouse"] = {type = "ground", side = 1, count = 40, zone="Red Northern Warehouse Zone", unitTypes = {"BMD-1","T-90"}},    -- North units must be different than South, otherwise you will get double units I think
    ["RedSouthernWarehouse"] = {type = "ground", side = 1, count = 40, zone="Red Southern Warehouse Zone", unitTypes = {"BMP-1", "T-72B"}},  -- South units must be different than North
    ["RedNavalWarehouse"] = {type = "naval", side = 1, count = 10, zone = "Red Naval Zone", unitTypes = {"CV_1143_5", "Type_052C", "Type_054A", "MOSCOW", "TICONDEROG", "PERRY", "MOLNIYA", "Type_071"}}, -- ships can use same units
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
      warehouse[1]:SetRespawnAfterDestroyed(warRespawnDelay)
      warehouse[1]:SetSpawnZone(ZONE_POLYGON:New(i.zone, GROUP:FindByName(i.zone))):SetReportOff()
    end    
  end
  
else  
  -- brand new campaign, we create the warehouse files first  
  env.info("***=AW=33COM Warehouses loaded for the first time.")
  
  --start, setup zone, and set respawn delay
  for i, warehouse in pairs(warehouses) do
    warehouse[1]:Start()    
    warehouse[1]:SetRespawnAfterDestroyed(warRespawnDelay)
    warehouse[1]:SetSpawnZone(ZONE_POLYGON:New(i.zone, GROUP:FindByName(i.zone))):SetReportOff()
  end 
  
  -- add assets to warehouses since this is new campaign
      --Fresh Campaign, we starts warehouses, and loads assets
  ----Add Assets to the warehouses on new campaign
    --EXAMPLE*** WAREHOUSE:AddAsset(group, ngroups, forceattribute, forcecargobay, forceweight, loadradius, skill, liveries,    assignment) 
  warehouse.BlueNorthernWarehouse:AddAsset("Resupply Blue MBT North", 40) --Counted as tank  in stock
  warehouse.BlueNorthernWarehouse:AddAsset("Resupply Blue IFV North", 40)    --Counted as APC in stock
  
  warehouse.BlueSouthernWarehouse:AddAsset("Resupply Blue MBT South", 40) --Counted as tank  in stock
  warehouse.BlueSouthernWarehouse:AddAsset("Resupply Blue IFV South", 40)    --Counted as APC in stock
  
  warehouse.BlueNavalWarehouse:AddAsset("Resupply Blue Ticonderoga", 10)
  warehouse.BlueNavalWarehouse:AddAsset("Resupply Blue Type 052C", 15)
  warehouse.BlueNavalWarehouse:AddAsset("Resupply Blue Perry", 15) 
  warehouse.BlueNavalWarehouse:AddAsset("Resupply Blue Carrier", 10)
  warehouse.BlueNavalWarehouse:AddAsset("Resupply Blue Tarawa", 10)
  
  warehouse.RedNorthernWarehouse:AddAsset("Resupply Red MBT North", 40)    --counted as tank  in stock
  warehouse.RedNorthernWarehouse:AddAsset("Resupply Red IFV North", 40)   --counted as APC in stock
  
  warehouse.RedSouthernWarehouse:AddAsset("Resupply Red MBT South", 40)    --counted as tank  in stock
  warehouse.RedSouthernWarehouse:AddAsset("Resupply Red IFV South", 40)   --counted as APC in stock
  
  warehouse.RedNavalWarehouse:AddAsset("Resupply Red Moskva", 10)
  warehouse.RedNavalWarehouse:AddAsset("Resupply Red Molniya", 15)
  warehouse.RedNavalWarehouse:AddAsset("Resupply Red Type 054A", 15) 
  warehouse.RedNavalWarehouse:AddAsset("Resupply Red Carrier", 10)
  warehouse.RedNavalWarehouse:AddAsset("Resupply Red Transport Dock", 10)
end


Warehouse_EventHandler = EVENTHANDLER:New()
Warehouse_EventHandler:HandleEvent( EVENTS.Dead )

----Spawn unit at a warehouse when a unit dies
function Warehouse_EventHandler:OnEventDead( EventData )

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