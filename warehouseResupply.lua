-- Name: Warehouse Resupply

-- Mostly rewritten by =AW=33COM in order to:
-- 1. Be able to use the same type of ships in the static mission and dynamic warehouses
-- 2. Be able to use the same type of ground units in the static mission and dynamic warehouses
-- 3. Be able to use the same type of units across coalitions.
-- 4. Be able to add warehouses through configuration.
-- 5. Be able to configure this without a programmer
-- Notes: The above items were not possible as everything was hardcoded and checked only at type level.  If you added a specific type to RED it was not possible to add it to BLUE.
-- or it was not possible to sling tanks if they were in the warehouse

local inspect = require("inspect")
local utils = require("utils")

local war= {}
local warRespawnDelay = 3600
local shipRespawnDelay = 1800
local vehicleRespawnDelay = 1800
local warUnitPrefix = "Resupply" -- do not change this

-- you can now configure your warehouses and add new once without programming
-- add a warhouse and a zone to the map and copy their names into here...then define the unit types for the warehouse plus coalition and type(naval, ground) of warhouse and you're done.
-- warehouse and zone names must be unique
war.warehouses = 
{
    -- BLUE warehouses
    ["Blue Northern Warehouse"] = {type = "ground", side = 2, count = 40, zone = "Blue Northern Warehouse Zone", unitTypes = {"MCV-80","Leopard-2"}},    -- North units must be different than South, otherwise you will get double units I think
    ["Blue Southern Warehouse"] = {type = "ground", side = 2, count = 40, zone = "Blue Southern Warehouse Zone", unitTypes = {"LAV-25", "Merkava_Mk4"}},  -- South units must be different than North  
    ["Blue Naval Warehouse"] = {type = "naval", side = 2, count = 10, zone = "Blue Naval Zone", unitTypes = {"CVN_73", "Type_052C", "Type_054A", "MOSCOW", "TICONDEROG", "PERRY", "MOLNIYA", "LHA_Tarawa"}}, -- ships can use same units
    
    -- RED warehouses 
    ["Red Northern Warehouse"] = {type = "ground", side = 1, count = 40, zone="Red Northern Warehouse Zone", unitTypes = {"BMD-1","T-90"}},    -- North units must be different than South, otherwise you will get double units I think
    ["Red Southern Warehouse"] = {type = "ground", side = 1, count = 40, zone="Red Southern Warehouse Zone", unitTypes = {"BMP-1", "T-72B"}},  -- South units must be different than North
    ["Red Naval Warehouse"] = {type = "naval", side = 1, count = 10, zone = "Red Naval Zone", unitTypes = {"CV_1143_5", "Type_052C", "Type_054A", "MOSCOW", "TICONDEROG", "PERRY", "MOLNIYA", "Type_071"}}, -- ships can use same units
}

----Defines the warehouses
--the string is the name in the mission editor
war.BlueNorthernWarehouse=WAREHOUSE:New(STATIC:FindByName("Blue Northern Warehouse"))
war.BlueNavalWarehouse=WAREHOUSE:New(STATIC:FindByName("Blue Naval Warehouse"))
war.BlueSouthernWarehouse=WAREHOUSE:New(STATIC:FindByName("Blue Southern Warehouse"))
war.RedNorthernWarehouse=WAREHOUSE:New(STATIC:FindByName("Red Northern Warehouse"))
war.RedSouthernWarehouse=WAREHOUSE:New(STATIC:FindByName("Red Southern Warehouse"))
war.RedNavalWarehouse=WAREHOUSE:New(STATIC:FindByName("Red Naval Warehouse"))

----If previous file exists it will load last saved warehouse
if M.file_exists("BlueNorthernWarehouse") then --Script has been run before, so we need to load the saved values
  env.info("Existing warehouses, loading from File.")
  war.BlueNorthernWarehouse:Load(nil,"BlueNorthernWarehouse")
  war.BlueSouthernWarehouse:Load(nil,"BlueSouthernWarehouse")
  war.BlueNavalWarehouse:Load(nil,"BlueNavalWarehouse")
  war.RedNorthernWarehouse:Load(nil,"RedNorthernWarehouse")
  war.RedSouthernWarehouse:Load(nil,"RedSouthernWarehouse")
  war.RedNavalWarehouse:Load(nil,"RedNavalWarehouse")
  war.BlueNorthernWarehouse:Start()
  war.BlueNorthernWarehouse:SetRespawnAfterDestroyed(3600)
  war.BlueSouthernWarehouse:Start()
  war.BlueSouthernWarehouse:SetRespawnAfterDestroyed(3600)
  war.BlueNavalWarehouse:Start()
  war.BlueNavalWarehouse:SetRespawnAfterDestroyed(3600)
  war.RedNorthernWarehouse:Start()
  war.RedNorthernWarehouse:SetRespawnAfterDestroyed(3600)
  war.RedSouthernWarehouse:Start()
  war.RedSouthernWarehouse:SetRespawnAfterDestroyed(3600)
  war.RedNavalWarehouse:Start()
  war.RedNavalWarehouse:SetRespawnAfterDestroyed(3600)
  
  if war.BlueNorthernWarehouse:GetCoalition()==2 then
    war.BlueNorthernWarehouse:Start()
    war.BlueNorthernWarehouse:SetRespawnAfterDestroyed(3600)
  elseif war.BlueNorthernWarehouse:GetCoalition()~=2 then
    war.BlueNorthernWarehouse:Stop()
    war.BlueNorthernWarehouse:SetRespawnAfterDestroyed(3600)
  else    
  end
  
  if war.BlueSouthernWarehouse:GetCoalition()==2 then
      war.BlueSouthernWarehouse:Start()
      war.BlueSouthernWarehouse:SetRespawnAfterDestroyed(3600)
    elseif war.BlueSouthernWarehouse:GetCoalition()~=2 then
      war.BlueSouthernWarehouse:Stop()
      war.BlueSouthernWarehouse:SetRespawnAfterDestroyed(3600)    
    else
  end
  
  if war.BlueNavalWarehouse:GetCoalition()==2 then
      war.BlueNavalWarehouse:Start()
      war.BlueNavalWarehouse:SetRespawnAfterDestroyed(3600)
    elseif war.BlueNavalWarehouse:GetCoalition()~=2 then
      war.BlueNavalWarehouse:Stop()
      war.BlueNavalWarehouse:SetRespawnAfterDestroyed(3600)  
    else
  end
    
  if war.RedNorthernWarehouse:GetCoalition()==1 then
      war.RedNorthernWarehouse:Start()
      war.RedNorthernWarehouse:SetRespawnAfterDestroyed(3600)
    elseif war.RedNorthernWarehouse:GetCoalition()~=1 then
      war.RedNorthernWarehouse:Stop()
      war.RedNorthernWarehouse:SetRespawnAfterDestroyed(3600)  
    else
  end
  
  if war.RedSouthernWarehouse:GetCoalition()==1 then
      war.RedSouthernWarehouse:Start()
      war.RedSouthernWarehouse:SetRespawnAfterDestroyed(3600)
    elseif war.RedSouthernWarehouse:GetCoalition()~=1 then
      war.RedSouthernWarehouse:Stop()
      war.RedSouthernWarehouse:SetRespawnAfterDestroyed(3600)    
  end
  
  if war.RedNavalWarehouse:GetCoalition()==1 then
      war.RedNavalWarehouse:Start()
      war.RedNavalWarehouse:SetRespawnAfterDestroyed(3600)
    elseif war.RedNavalWarehouse:GetCoalition()~=1 then
      war.RedNavalWarehouse:Stop()
      war.RedNavalWarehouse:SetRespawnAfterDestroyed(3600)  
    else
  end
  
else  
    --Fresh Campaign, we starts warehouses, and loads assets
  war.BlueNorthernWarehouse:Start()
  war.BlueNorthernWarehouse:SetRespawnAfterDestroyed(3600)
  
  war.BlueSouthernWarehouse:Start()
  war.BlueSouthernWarehouse:SetRespawnAfterDestroyed(3600)
  
  war.BlueNavalWarehouse:Start()
  war.BlueNavalWarehouse:SetRespawnAfterDestroyed(3600)
  
  war.RedNorthernWarehouse:Start()
  war.RedNorthernWarehouse:SetRespawnAfterDestroyed(3600)
  
  war.RedSouthernWarehouse:Start()
  war.RedSouthernWarehouse:SetRespawnAfterDestroyed(3600)
  
  war.RedNavalWarehouse:Start()
  war.RedNavalWarehouse:SetRespawnAfterDestroyed(3600)
  
  ----Add Assets to the warehouses on new campaign
    --EXAMPLE*** WAREHOUSE:AddAsset(group, ngroups, forceattribute, forcecargobay, forceweight, loadradius, skill, liveries,    assignment) 
  war.BlueNorthernWarehouse:AddAsset("Resupply Blue MBT North", 40) --Counted as tank  in stock
  war.BlueNorthernWarehouse:AddAsset("Resupply Blue IFV North", 40)    --Counted as APC in stock
  
  war.BlueSouthernWarehouse:AddAsset("Resupply Blue MBT South", 40) --Counted as tank  in stock
  war.BlueSouthernWarehouse:AddAsset("Resupply Blue IFV South", 40)    --Counted as APC in stock
  
  war.BlueNavalWarehouse:AddAsset("Resupply Blue Ticonderoga", 10)
  war.BlueNavalWarehouse:AddAsset("Resupply Blue Type 052C", 15)
  war.BlueNavalWarehouse:AddAsset("Resupply Blue Perry", 15) 
  war.BlueNavalWarehouse:AddAsset("Resupply Blue Carrier", 10)
  war.BlueNavalWarehouse:AddAsset("Resupply Blue Tarawa", 10)
  
  war.RedNorthernWarehouse:AddAsset("Resupply Red MBT North", 40)    --counted as tank  in stock
  war.RedNorthernWarehouse:AddAsset("Resupply Red IFV North", 40)   --counted as APC in stock
  
  war.RedSouthernWarehouse:AddAsset("Resupply Red MBT South", 40)    --counted as tank  in stock
  war.RedSouthernWarehouse:AddAsset("Resupply Red IFV South", 40)   --counted as APC in stock
  
  war.RedNavalWarehouse:AddAsset("Resupply Red Moskva", 10)
  war.RedNavalWarehouse:AddAsset("Resupply Red Molniya", 15)
  war.RedNavalWarehouse:AddAsset("Resupply Red Type 054A", 15) 
  war.RedNavalWarehouse:AddAsset("Resupply Red Carrier", 10)
  war.RedNavalWarehouse:AddAsset("Resupply Red Transport Dock", 10)
end

if war.BlueNorthernWarehouse:GetCoalition()==2 or war.BlueNorthernWarehouse:GetCoalition()==0 then
    war.BlueNorthernWarehouse:Start()
    war.BlueNorthernWarehouse:SetRespawnAfterDestroyed(3600)
  elseif war.BlueNorthernWarehouse:GetCoalition()~=2 then
    war.BlueNorthernWarehouse:Stop()
    war.BlueNorthernWarehouse:SetRespawnAfterDestroyed(3600)
  else    
end

if war.BlueSouthernWarehouse:GetCoalition()==2 or war.BlueSouthernWarehouse:GetCoalition()==0 then
    war.BlueSouthernWarehouse:Start()
    war.BlueSouthernWarehouse:SetRespawnAfterDestroyed(3600)
  elseif war.BlueSouthernWarehouse:GetCoalition()~=2 then
    war.BlueSouthernWarehouse:Stop()
    war.BlueSouthernWarehouse:SetRespawnAfterDestroyed(3600)    
  else
end

if war.BlueNavalWarehouse:GetCoalition()==2 or war.BlueNavalWarehouse:GetCoalition()==0 then
    war.BlueNavalWarehouse:Start()
    war.BlueNavalWarehouse:SetRespawnAfterDestroyed(3600)
  elseif war.BlueNavalWarehouse:GetCoalition()~=2 then
    war.BlueNavalWarehouse:Stop()
    war.BlueNavalWarehouse:SetRespawnAfterDestroyed(3600)
  else    
end

if war.RedNorthernWarehouse:GetCoalition()==1 or war.RedNorthernWarehouse:GetCoalition()==0 then
    war.RedNorthernWarehouse:Start()
    war.RedNorthernWarehouse:SetRespawnAfterDestroyed(3600)
  elseif war.RedNorthernWarehouse:GetCoalition()~=1 then
    war.RedNorthernWarehouse:Stop()
    war.RedNorthernWarehouse:SetRespawnAfterDestroyed(3600)  
  else
end

if war.RedSouthernWarehouse:GetCoalition()==1 or war.RedSouthernWarehouse:GetCoalition()==0 then
    war.RedSouthernWarehouse:Start()
    war.RedSouthernWarehouse:SetRespawnAfterDestroyed(3600)
  elseif war.RedSouthernWarehouse:GetCoalition()~=1 then
    war.RedSouthernWarehouse:Stop()
    war.RedSouthernWarehouse:SetRespawnAfterDestroyed(3600)    
end

if war.RedNavalWarehouse:GetCoalition()==1 or war.RedNavalWarehouse:GetCoalition()==0 then
    war.RedNavalWarehouse:Start()
    war.RedNavalWarehouse:SetRespawnAfterDestroyed(3600)
  elseif war.RedNavalWarehouse:GetCoalition()~=1 then
    war.RedNavalWarehouse:Stop()
    war.RedNavalWarehouse:SetRespawnAfterDestroyed(3600)  
  else
end

----Set Spawn Zones for the warehouses
war.BlueNorthernWarehouse:SetSpawnZone(ZONE_POLYGON:New("Blue Northern Warehouse Spawn Zone #001", GROUP:FindByName("Blue Northern Warehouse Spawn Zone #001"))):SetReportOff()
war.BlueSouthernWarehouse:SetSpawnZone(ZONE_POLYGON:New("Blue Southern Warehouse Spawn Zone #001", GROUP:FindByName("Blue Southern Warehouse Spawn Zone #001"))):SetReportOff()

war.BlueNavalWarehouse:SetPortZone(ZONE_POLYGON:NewFromGroupName("Blue Naval Spawn Zone", GROUP:FindByName("Blue Naval Spawn Zone"))):SetReportOff()

war.RedNorthernWarehouse:SetSpawnZone(ZONE_POLYGON:New("Red Northern Warehouse Spawn Zone #001", GROUP:FindByName("Red Northern Warehouse Spawn Zone #001"))):SetReportOff()
war.RedSouthernWarehouse:SetSpawnZone(ZONE_POLYGON:New("Red Southern Warehouse Spawn Zone #001", GROUP:FindByName("Red Southern Warehouse Spawn Zone #001"))):SetReportOff()

war.RedNavalWarehouse:SetPortZone(ZONE_POLYGON:NewFromGroupName("Red Naval Spawn Zone", GROUP:FindByName("Red Naval Spawn Zone"))):SetReportOff()

Warehouse_EventHandler = EVENTHANDLER:New()
Warehouse_EventHandler:HandleEvent( EVENTS.Dead )

----Spawn unit at a warehouse when a unit dies
function Warehouse_EventHandler:OnEventDead( EventData )

	-- here we check if the unit is player slung, if it's not we check if it's part of the war...this allows us not to add player slung units to the warehouses	
	if EventData.IniUnitName ~= nil then	
		
		local isPlayerSlung = M.isUnitPlayerSlung(inspect(EventData.IniUnitName))	
			
		if isPlayerSlung == false then
		
			-- unit comes from miz or warehouse, we need to add it	
			if EventData.IniTypeName ~= nil and EventData.IniUnitName ~= nil then
				env.info("***=AW=33COM Warehouse Unit: IniTypeName: ".. inspect(EventData.IniTypeName) .. " IniUnitName:" .. inspect(EventData.IniUnitName) .. " - Add to Warehouse if type matches***")			
			end
				-- ships
			if EventData.IniTypeName == 'PERRY' then
				war.BlueNavalWarehouse:__AddRequest(1800, war.BlueNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue Perry", 1, WAREHOUSE.TransportType.SELFPROPELLED)
				war.BlueNavalWarehouse:__Save(5,nil,"BlueNavalWarehouse")
			  elseif EventData.IniTypeName == 'TICONDEROG' then
				war.BlueNavalWarehouse:__AddRequest(1800, war.BlueNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue Ticonderoga", 1, WAREHOUSE.TransportType.SELFPROPELLED)
				war.BlueNavalWarehouse:__Save(5,nil,"BlueNavalWarehouse")
			  elseif EventData.IniTypeName == 'Type_052C' then
				war.BlueNavalWarehouse:__AddRequest(1800, war.BlueNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue Type 052C", 1, WAREHOUSE.TransportType.SELFPROPELLED)
				war.BlueNavalWarehouse:__Save(5,nil,"BlueNavalWarehouse")
			  elseif EventData.IniTypeName == 'CVN_73' then
			  
				local isFromNavalWarehouse = M.isUnitFromWarehouse(inspect(EventData.IniUnitName))	
				
				if isFromNavalWarehouse == true then
					env.info("***=AW=33COM Naval Warehouse BLUE Unit: IniTypeName: ".. inspect(EventData.IniTypeName) .. " IniUnitName:" .. inspect(EventData.IniUnitName) .. " - Add to BLUE Naval Warehouse***")			  
					war.BlueNavalWarehouse:__AddRequest(1800, war.BlueNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue Carrier", 1, WAREHOUSE.TransportType.SELFPROPELLED)
					war.BlueNavalWarehouse:__Save(5,nil,"BlueNavalWarehouse")
				else
					env.info("***=AW=33COM Ship BLUE Unit: IniTypeName: ".. inspect(EventData.IniTypeName) .. " IniUnitName:" .. inspect(EventData.IniUnitName) .. " - DO NOT ADD to BLUE Naval Warehouse.  Ship comes from MIZ***")			
				end
				
			  elseif EventData.IniTypeName == 'LHA_Tarawa' then
				war.BlueNavalWarehouse:__AddRequest(1800, war.BlueNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue Tarawa", 1, WAREHOUSE.TransportType.SELFPROPELLED)
				war.BlueNavalWarehouse:__Save(5,nil,"BlueNavalWarehouse")
				
			  elseif EventData.IniTypeName == 'Type_054A' then
				war.RedNavalWarehouse:__AddRequest(1800, war.RedNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red Type 054A", 1, WAREHOUSE.TransportType.SELFPROPELLED)
				war.RedNavalWarehouse:__Save(5,nil,"RedNavalWarehouse")
			  elseif EventData.IniTypeName == 'MOSCOW' then
				war.RedNavalWarehouse:__AddRequest(1800, war.RedNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red Moskva", 1, WAREHOUSE.TransportType.SELFPROPELLED)
				war.RedNavalWarehouse:__Save(5,nil,"RedNavalWarehouse")
			  elseif EventData.IniTypeName == 'MOLNIYA' then
				war.RedNavalWarehouse:__AddRequest(1800, war.RedNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red Molniya", 1, WAREHOUSE.TransportType.SELFPROPELLED)
				war.RedNavalWarehouse:__Save(5,nil,"RedNavalWarehouse")
			  elseif EventData.IniTypeName == 'CV_1143_5' then
			  
				local isFromNavalWarehouse = M.isUnitFromWarehouse(inspect(EventData.IniUnitName))	
				
				if isFromNavalWarehouse == true then
					env.info("***=AW=33COM Naval Warehouse RED Unit: IniTypeName: ".. inspect(EventData.IniTypeName) .. " IniUnitName:" .. inspect(EventData.IniUnitName) .. " - Add to RED Naval Warehouse***")			
					war.RedNavalWarehouse:__AddRequest(1800, war.RedNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red Carrier", 1, WAREHOUSE.TransportType.SELFPROPELLED)
					war.RedNavalWarehouse:__Save(5,nil,"RedNavalWarehouse")
				else
					env.info("***=AW=33COM Ship RED Unit: IniTypeName: ".. inspect(EventData.IniTypeName) .. " IniUnitName:" .. inspect(EventData.IniUnitName) .. " - DO NOT ADD to RED Naval Warehouse.  Ship comes from MIZ***")			
				end
				
			  elseif EventData.IniTypeName == 'Type_071' then
				war.RedNavalWarehouse:__AddRequest(1800, war.RedNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red Transport Dock", 1, WAREHOUSE.TransportType.SELFPROPELLED)
				war.RedNavalWarehouse:__Save(5,nil,"RedNavalWarehouse")	
			  
			  --ground units  	
			  elseif EventData.IniTypeName == 'MCV-80' then
				war.BlueNorthernWarehouse:__AddRequest(1800, war.BlueNorthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue IFV North", 1, WAREHOUSE.TransportType.SELFPROPELLED)
				war.BlueNorthernWarehouse:__Save(5,nil,"BlueNorthernWarehouse")
			  elseif EventData.IniTypeName == 'LAV-25' then
				war.BlueSouthernWarehouse:__AddRequest(1800, war.BlueSouthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue IFV South", 1, WAREHOUSE.TransportType.SELFPROPELLED)
				war.BlueSouthernWarehouse:__Save(10,nil,"BlueSouthernWarehouse")
			  elseif EventData.IniTypeName == 'Leopard-2' then 
				war.BlueNorthernWarehouse:__AddRequest(1800, war.BlueNorthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue MBT North", 1, WAREHOUSE.TransportType.SELFPROPELLED)
				war.BlueNorthernWarehouse:__Save(5,nil,"BlueNorthernWarehouse")
			  elseif EventData.IniTypeName == 'Merkava_Mk4' then
				war.BlueSouthernWarehouse:__AddRequest(1800, war.BlueSouthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue MBT South", 1, WAREHOUSE.TransportType.SELFPROPELLED)
				war.BlueSouthernWarehouse:__Save(10,nil,"BlueSouthernWarehouse")	
				
			  elseif EventData.IniTypeName == 'BMD-1' then
				war.RedNorthernWarehouse:__AddRequest(1800, war.RedNorthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red IFV North", 1, WAREHOUSE.TransportType.SELFPROPELLED)
				war.RedNorthernWarehouse:__Save(5,nil,"RedNorthernWarehouse")
			  elseif EventData.IniTypeName == 'BMP-1' then
				war.RedSouthernWarehouse:__AddRequest(1800, war.RedSouthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red IFV South", 1, WAREHOUSE.TransportType.SELFPROPELLED)
				war.RedSouthernWarehouse:__Save(10,nil,"RedSouthernWarehouse")
			  elseif EventData.IniTypeName == 'T-90' then
				war.RedNorthernWarehouse:__AddRequest(1800, war.RedNorthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red MBT North", 1, WAREHOUSE.TransportType.SELFPROPELLED)
				war.RedNorthernWarehouse:__Save(5,nil,"RedNorthernWarehouse")
			  elseif EventData.IniTypeName == 'T-72B' then
				war.RedSouthernWarehouse:__AddRequest(1800, war.RedSouthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red MBT South", 1, WAREHOUSE.TransportType.SELFPROPELLED)
				war.RedSouthernWarehouse:__Save(10,nil,"RedSouthernWarehouse")
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
function war.BlueNorthernWarehouse:OnAfterCaptured(From, Event, To, Coalition, Country)
--function war.BlueNorthernWarehouse:OnAfterAirbaseCaptured(From,Event,To,Coalition)
  if Coalition==coalition.side.BLUE then
    MESSAGE:New("The Northern Warehouse is running at full capacity.",25,"[TEAM]:"):ToBlue()
    war.BlueNorthernWarehouse:Start()
    war.BlueNorthernWarehouse:__Save(15,nil,"BlueNorthernWarehouse")
    war.BlueNorthernWarehouse:AddRequest(war.BlueNorthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue MBT North", 1, WAREHOUSE.TransportType.SELFPROPELLED)
    war.BlueNorthernWarehouse:AddRequest(war.BlueNorthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue IFV North", 2, WAREHOUSE.TransportType.SELFPROPELLED)
  
  elseif Coalition==coalition.side.RED then
    MESSAGE:New("We have captured Blue Team's Northern Warehouse, they will no longer receive re-enforcements.",25,"[TEAM]:"):ToRed()
    MESSAGE:New("We have lost the Northern Warehouse and no longer able to re-enforce the front.",25,"[TEAM]:"):ToBlue()
    war.BlueNorthernWarehouse:Stop()
    war.BlueNorthernWarehouse:__Save(15,nil,"BlueNorthernWarehouse")
    end
end

---- An asset has died request self resupply for it from the war. Would be awesome if I could somehow get the warehouse to recognize the units after a restart. 
-- Until then going to send a request to ALL warehouses dependent on when the type of vehicle that dies, Probably not going to only make the fixed SAM sites at least not based on warehouses. 
--function war.BlueNorthernWarehouse:OnAfterAssetDead(From, Event, To, asset, request)
--  local asset=asset       --Functional.Warehouse#WAREHOUSE.Assetitem
--  local request=request   --Functional.Warehouse#WAREHOUSE.Pendingitem
--
--  -- Get assignment.
--  local assignment=war.BlueNorthernWarehouse:GetAssignment(request)
--    war.BlueNorthernWarehouse:AddRequest(war.BlueNorthernWarehouse, WAREHOUSE.Descriptor.ATTRIBUTE, asset.attribute, nil, nil, nil, nil, "Resupply from Blue Northern Warehouse")
--    war.BlueNorthernWarehouse:__Save(15,nil,"BlueNorthernWarehouse")
--end


function war.BlueSouthernWarehouse:OnAfterCaptured(From, Event, To, Coalition, Country)
--function  war.BlueSouthernWarehouse:OnAfterAirbaseCaptured(From,Event,To,Coalition)
  if Coalition==coalition.side.BLUE then
    MESSAGE:New("The Southern Warehouse is running at full capacity.",25,"[TEAM]:"):ToBlue()
    war.BlueSouthernWarehouse:Start()
    war.BlueSouthernWarehouse:__Save(4,nil,"BlueSouthernWarehouse")
    war.BlueSouthernWarehouse:AddRequest(war.BlueSouthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue MBT South", 1, WAREHOUSE.TransportType.SELFPROPELLED)
    war.BlueSouthernWarehouse:AddRequest(war.BlueSouthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue IFV South", 2, WAREHOUSE.TransportType.SELFPROPELLED)
  
  elseif Coalition==coalition.side.RED then
    MESSAGE:New("We have captured Blue Team's Southern Warehouse, they will no longer receive re-enforcements.",25,"[TEAM]:"):ToRed()
    MESSAGE:New("We have lost the Southern Warehouse and no longer able to re-enforce the front.",25,"[TEAM]:"):ToBlue()
    war.BlueSouthernWarehouse:Stop()
    war.BlueSouthernWarehouse:__Save(15,nil,"BlueSouthernWarehouse")
    end
end

function war.RedNorthernWarehouse:OnAfterCaptured(From, Event, To, Coalition, Country)
--function war.RedNorthernWarehouse:OnAfterAirbaseCaptured(From,Event,To,Coalition)
  if Coalition==coalition.side.RED then
    MESSAGE:New("The Northern Warehouse is running at full capacity.",25,"[TEAM]:"):ToRed()
    war.RedNorthernWarehouse:Start()
    war.RedNorthernWarehouse:__Save(7,nil,"RedNorthernWarehouse")
    war.RedNorthernWarehouse:AddRequest(war.RedNorthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red MBT North", 1, WAREHOUSE.TransportType.SELFPROPELLED)
    war.RedNorthernWarehouse:AddRequest(war.RedNorthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red IFV North", 2, WAREHOUSE.TransportType.SELFPROPELLED)
  
  elseif Coalition==coalition.side.BLUE then
    MESSAGE:New("We have captured Red Team's Northern Warehouse, they will no longer receive re-enforcements.",25,"[TEAM]:"):ToBlue()
    MESSAGE:New("We have lost the Northern Warehouse and no longer able to re-enforce the front.",25,"[TEAM]:"):ToRed()
    war.RedNorthernWarehouse:Stop()
    war.RedNorthernWarehouse:__Save(10,nil,"RedNorthernWarehouse")
    end
end

function war.RedSouthernWarehouse:OnAfterCaptured(From, Event, To, Coalition, Country)
--function war.RedSouthernWarehouse:OnAfterAirbaseCaptured(From,Event,To,Coalition)
  if Coalition==coalition.side.RED then
    MESSAGE:New("The Southern Warehouse is running at full capacity.",25,"[TEAM]:"):ToRed()
    war.RedSouthernWarehouse:Start()
    war.RedSouthernWarehouse:__Save(9,nil,"RedSouthernWarehouse")
    war.RedSouthernWarehouse:AddRequest(war.RedSouthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red MBT South", 1, WAREHOUSE.TransportType.SELFPROPELLED)
    war.RedSouthernWarehouse:AddRequest(war.RedSouthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red IFV South", 2, WAREHOUSE.TransportType.SELFPROPELLED)
  
  elseif Coalition==coalition.side.BLUE then
    MESSAGE:New("We have captured Red Team's Southern Warehouse, they will no longer receive re-enforcements.",25,"[TEAM]:"):ToBlue()
    MESSAGE:New("We have lost the Southern Warehouse and no longer able to re-enforce the front.",25,"[TEAM]:"):ToRed()
    war.RedSouthernWarehouse:Stop()
    war.RedSouthernWarehouse:__Save(15,nil,"RedSouthernWarehouse")
    end
end

--Spawn naval units after capture
function war.BlueNavalWarehouse:OnAfterCaptured(From, Event, To, Coalition, Country)
--function war.BlueNavalWarehouse:OnAfterAirbaseCaptured(From,Event,To,Coalition)
  if Coalition==coalition.side.BLUE then
    MESSAGE:New("Our Drydock is running at full capacity.",25,"[TEAM]:"):ToBlue()
    war.BlueNavalWarehouse:Start()
    war.BlueNavalWarehouse:__Save(15,nil,"BlueNavalWarehouse")
--initial spawn of ships as well as when captured by blue team
    war.BlueNavalWarehouse:AddRequest(war.BlueNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue Type 052C", 2, WAREHOUSE.TransportType.SELFPROPELLED)
  	war.BlueNavalWarehouse:AddRequest(war.BlueNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue Ticonderoga", 2, WAREHOUSE.TransportType.SELFPROPELLED)
	  war.BlueNavalWarehouse:AddRequest(war.BlueNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue Perry", 2, WAREHOUSE.TransportType.SELFPROPELLED)
	  war.BlueNavalWarehouse:AddRequest(war.BlueNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue Carrier", 1, WAREHOUSE.TransportType.SELFPROPELLED)
    war.BlueNavalWarehouse:AddRequest(war.BlueNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue Tarawa", 1, WAREHOUSE.TransportType.SELFPROPELLED)
  
  elseif Coalition==coalition.side.RED then
    MESSAGE:New("We have captured Blue Team's Drydock! They will no longer be able to reinforce their fleet!",25,"[TEAM]:"):ToRed()
    MESSAGE:New("We have lost our Drydock and will no longer able to re-enforce the fleet.",25,"[TEAM]:"):ToBlue()
    war.BlueNavalWarehouse:Stop()
    war.BlueNavalWarehouse:__Save(15,nil,"BlueNavalWarehouse")
    end
end

function war.RedNavalWarehouse:OnAfterCaptured(From, Event, To, Coalition, Country)
--function war.RedSouthernWarehouse:OnAfterAirbaseCaptured(From,Event,To,Coalition)
  if Coalition==coalition.side.RED then
    MESSAGE:New("Our Drydock is running at full capacity.",25,"[TEAM]:"):ToRed()
    war.RedNavalWarehouse:Start()
    war.RedNavalWarehouse:__Save(9,nil,"RedNavalWarehouse")	
--initial spawn of ships as well as when captured by red team
    war.RedNavalWarehouse:AddRequest(war.RedNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red Type 054A", 2, WAREHOUSE.TransportType.SELFPROPELLED)
    war.RedNavalWarehouse:AddRequest(war.RedNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red Molniya", 2, WAREHOUSE.TransportType.SELFPROPELLED)
	  war.RedNavalWarehouse:AddRequest(war.RedNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red Moskva", 2, WAREHOUSE.TransportType.SELFPROPELLED)
    war.RedNavalWarehouse:AddRequest(war.RedNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red Carrier", 1, WAREHOUSE.TransportType.SELFPROPELLED)
	  war.RedNavalWarehouse:AddRequest(war.RedNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red Transport Dock", 1, WAREHOUSE.TransportType.SELFPROPELLED)
  elseif Coalition==coalition.side.BLUE then
    MESSAGE:New("We have captured Red Team's Drydock! They will no longer be able to reinforce their fleet!",25,"[TEAM]:"):ToBlue()
    MESSAGE:New("We have lost our Drydock and will no longer able to re-enforce the fleet.",25,"[TEAM]:"):ToRed()
    war.RedNavalWarehouse:Stop()
    war.RedNavalWarehouse:__Save(15,nil,"RedNavalWarehouse")
    end
end