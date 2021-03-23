-- Name: Warehouse Resupply
-- Author: Wildcat (Chandawg)
-- Date Created: 28 Apr 2020
-- Trying to integrate the Alpha warehouse system from moose into RSR. Initially this will replace base units
-- Ultimately I couldn't integrate this into RSR-Caucuses because of the capture mechanism, but with the new Syria map we revamped the capture mechanism and went with Moose Zone Capture, so now exploring using these with RSR-Syria


local warehouse={}
----function to check if a save warehouse file exist, stole it from pikey's SGS
function file_exists(name) --check if the file already exists for writing
    if lfs.attributes(name) then
    return true
    else
    return false end 
end

----warehouseBatumi=WAREHOUSE:New(STATIC:FindByName("Warehouse Batumi"), "My optional Warehouse Alias")
----Defines the warehouses
--the string is the name in the mission editor
warehouse.BlueNorthernWarehouse=WAREHOUSE:New(STATIC:FindByName("Blue Northern Warehouse"))
warehouse.BlueNavalWarehouse=WAREHOUSE:New(STATIC:FindByName("Blue Naval Warehouse"))
warehouse.BlueSouthernWarehouse=WAREHOUSE:New(STATIC:FindByName("Blue Southern Warehouse"))
warehouse.RedNorthernWarehouse=WAREHOUSE:New(STATIC:FindByName("Red Northern Warehouse"))
warehouse.RedSouthernWarehouse=WAREHOUSE:New(STATIC:FindByName("Red Southern Warehouse"))
warehouse.RedNavalWarehouse=WAREHOUSE:New(STATIC:FindByName("Red Naval Warehouse"))

----If previous file exists it will load last saved warehouse
if file_exists("BlueNorthernWarehouse") then --Script has been run before, so we need to load the save
  env.info("Existing warehouse, loading from File.")
  warehouse.BlueNorthernWarehouse:Load(nil,"BlueNorthernWarehouse")
  warehouse.BlueSouthernWarehouse:Load(nil,"BlueSouthernWarehouse")
  warehouse.BlueNavalWarehouse:Load(nil,"BlueNavalWarehouse")
  warehouse.RedNorthernWarehouse:Load(nil,"RedNorthernWarehouse")
  warehouse.RedSouthernWarehouse:Load(nil,"RedSouthernWarehouse")
  warehouse.RedNavalWarehouse:Load(nil,"RedNavalWarehouse")
  warehouse.BlueNorthernWarehouse:Start()
  warehouse.BlueNorthernWarehouse:SetRespawnAfterDestroyed(3600)
  warehouse.BlueSouthernWarehouse:Start()
  warehouse.BlueSouthernWarehouse:SetRespawnAfterDestroyed(3600)
  warehouse.BlueNavalWarehouse:Start()
  warehouse.BlueNavalWarehouse:SetRespawnAfterDestroyed(3600)
  warehouse.RedNorthernWarehouse:Start()
  warehouse.RedNorthernWarehouse:SetRespawnAfterDestroyed(3600)
  warehouse.RedSouthernWarehouse:Start()
  warehouse.RedSouthernWarehouse:SetRespawnAfterDestroyed(3600)
  warehouse.RedNavalWarehouse:Start()
  warehouse.RedNavalWarehouse:SetRespawnAfterDestroyed(3600)
  
  if warehouse.BlueNorthernWarehouse:GetCoalition()==2 then
    warehouse.BlueNorthernWarehouse:Start()
    warehouse.BlueNorthernWarehouse:SetRespawnAfterDestroyed(3600)
  elseif warehouse.BlueNorthernWarehouse:GetCoalition()~=2 then
    warehouse.BlueNorthernWarehouse:Stop()
    warehouse.BlueNorthernWarehouse:SetRespawnAfterDestroyed(3600)
  else    
  end
  
  if warehouse.BlueSouthernWarehouse:GetCoalition()==2 then
      warehouse.BlueSouthernWarehouse:Start()
      warehouse.BlueSouthernWarehouse:SetRespawnAfterDestroyed(3600)
    elseif warehouse.BlueSouthernWarehouse:GetCoalition()~=2 then
      warehouse.BlueSouthernWarehouse:Stop()
      warehouse.BlueSouthernWarehouse:SetRespawnAfterDestroyed(3600)    
    else
  end
  
  if warehouse.BlueNavalWarehouse:GetCoalition()==2 then
      warehouse.BlueNavalWarehouse:Start()
      warehouse.BlueNavalWarehouse:SetRespawnAfterDestroyed(3600)
    elseif warehouse.BlueNavalWarehouse:GetCoalition()~=2 then
      warehouse.BlueNavalWarehouse:Stop()
      warehouse.BlueNavalWarehouse:SetRespawnAfterDestroyed(3600)  
    else
  end
    
  if warehouse.RedNorthernWarehouse:GetCoalition()==1 then
      warehouse.RedNorthernWarehouse:Start()
      warehouse.RedNorthernWarehouse:SetRespawnAfterDestroyed(3600)
    elseif warehouse.RedNorthernWarehouse:GetCoalition()~=1 then
      warehouse.RedNorthernWarehouse:Stop()
      warehouse.RedNorthernWarehouse:SetRespawnAfterDestroyed(3600)  
    else
  end
  
  if warehouse.RedSouthernWarehouse:GetCoalition()==1 then
      warehouse.RedSouthernWarehouse:Start()
      warehouse.RedSouthernWarehouse:SetRespawnAfterDestroyed(3600)
    elseif warehouse.RedSouthernWarehouse:GetCoalition()~=1 then
      warehouse.RedSouthernWarehouse:Stop()
      warehouse.RedSouthernWarehouse:SetRespawnAfterDestroyed(3600)    
  end
  
  if warehouse.RedNavalWarehouse:GetCoalition()==1 then
      warehouse.RedNavalWarehouse:Start()
      warehouse.RedNavalWarehouse:SetRespawnAfterDestroyed(3600)
    elseif warehouse.RedNavalWarehouse:GetCoalition()~=1 then
      warehouse.RedNavalWarehouse:Stop()
      warehouse.RedNavalWarehouse:SetRespawnAfterDestroyed(3600)  
    else
  end
  
else  
    --Fresh Campaign starts warehouses, and loads assets
  warehouse.BlueNorthernWarehouse:Start()
  warehouse.BlueNorthernWarehouse:SetRespawnAfterDestroyed(3600)
  
  warehouse.BlueSouthernWarehouse:Start()
  warehouse.BlueSouthernWarehouse:SetRespawnAfterDestroyed(3600)
  
  warehouse.BlueNavalWarehouse:Start()
  warehouse.BlueNavalWarehouse:SetRespawnAfterDestroyed(3600)
  
  warehouse.RedNorthernWarehouse:Start()
  warehouse.RedNorthernWarehouse:SetRespawnAfterDestroyed(3600)
  
  warehouse.RedSouthernWarehouse:Start()
  warehouse.RedSouthernWarehouse:SetRespawnAfterDestroyed(3600)
  
  warehouse.RedNavalWarehouse:Start()
  warehouse.RedNavalWarehouse:SetRespawnAfterDestroyed(3600)
  
  ----Add Assets to the warehouses on new campaign
    --EXAMPLE*** WAREHOUSE:AddAsset(group, ngroups, forceattribute, forcecargobay, forceweight, loadradius, skill, liveries,    assignment) 
  warehouse.BlueNorthernWarehouse:AddAsset("Resupply Blue MBT North", 60) --Counted as tank  in stock
  warehouse.BlueNorthernWarehouse:AddAsset("Resupply Blue IFV North", 90)    --Counted as APC in stock
  
  warehouse.BlueSouthernWarehouse:AddAsset("Resupply Blue MBT South", 60) --Counted as tank  in stock
  warehouse.BlueSouthernWarehouse:AddAsset("Resupply Blue IFV South", 90)    --Counted as APC in stock
  
  warehouse.BlueNavalWarehouse:AddAsset("Resupply Blue Ticonderoga", 10)
  warehouse.BlueNavalWarehouse:AddAsset("Resupply Blue Type 052C", 15)
  warehouse.BlueNavalWarehouse:AddAsset("Resupply Blue Perry", 15) 
  warehouse.BlueNavalWarehouse:AddAsset("Resupply Blue Carrier", 10)
  warehouse.BlueNavalWarehouse:AddAsset("Resupply Blue Tarawa", 10)
  
  warehouse.RedNorthernWarehouse:AddAsset("Resupply Red MBT North", 60)    --counted as tank  in stock
  warehouse.RedNorthernWarehouse:AddAsset("Resupply Red IFV North", 90)   --counted as APC in stock
  
  warehouse.RedSouthernWarehouse:AddAsset("Resupply Red MBT South", 60)    --counted as tank  in stock
  warehouse.RedSouthernWarehouse:AddAsset("Resupply Red IFV South", 90)   --counted as APC in stock
  
  warehouse.RedNavalWarehouse:AddAsset("Resupply Red Moskva", 15)
  warehouse.RedNavalWarehouse:AddAsset("Resupply Red Molniya", 20)
  warehouse.RedNavalWarehouse:AddAsset("Resupply Red Type 054A", 15) 
  warehouse.RedNavalWarehouse:AddAsset("Resupply Red Carrier", 10)
  warehouse.RedNavalWarehouse:AddAsset("Resupply Red Transport Dock", 10)
end

if warehouse.BlueNorthernWarehouse:GetCoalition()==2 or warehouse.BlueNorthernWarehouse:GetCoalition()==0 then
    warehouse.BlueNorthernWarehouse:Start()
    warehouse.BlueNorthernWarehouse:SetRespawnAfterDestroyed(3600)
  elseif warehouse.BlueNorthernWarehouse:GetCoalition()~=2 then
    warehouse.BlueNorthernWarehouse:Stop()
    warehouse.BlueNorthernWarehouse:SetRespawnAfterDestroyed(3600)
  else    
end

if warehouse.BlueSouthernWarehouse:GetCoalition()==2 or warehouse.BlueSouthernWarehouse:GetCoalition()==0 then
    warehouse.BlueSouthernWarehouse:Start()
    warehouse.BlueSouthernWarehouse:SetRespawnAfterDestroyed(3600)
  elseif warehouse.BlueSouthernWarehouse:GetCoalition()~=2 then
    warehouse.BlueSouthernWarehouse:Stop()
    warehouse.BlueSouthernWarehouse:SetRespawnAfterDestroyed(3600)    
  else
end

if warehouse.BlueNavalWarehouse:GetCoalition()==2 or warehouse.BlueNavalWarehouse:GetCoalition()==0 then
    warehouse.BlueNavalWarehouse:Start()
    warehouse.BlueNavalWarehouse:SetRespawnAfterDestroyed(3600)
  elseif warehouse.BlueNavalWarehouse:GetCoalition()~=2 then
    warehouse.BlueNavalWarehouse:Stop()
    warehouse.BlueNavalWarehouse:SetRespawnAfterDestroyed(3600)
  else    
end

if warehouse.RedNorthernWarehouse:GetCoalition()==1 or warehouse.RedNorthernWarehouse:GetCoalition()==0 then
    warehouse.RedNorthernWarehouse:Start()
    warehouse.RedNorthernWarehouse:SetRespawnAfterDestroyed(3600)
  elseif warehouse.RedNorthernWarehouse:GetCoalition()~=1 then
    warehouse.RedNorthernWarehouse:Stop()
    warehouse.RedNorthernWarehouse:SetRespawnAfterDestroyed(3600)  
  else
end

if warehouse.RedSouthernWarehouse:GetCoalition()==1 or warehouse.RedSouthernWarehouse:GetCoalition()==0 then
    warehouse.RedSouthernWarehouse:Start()
    warehouse.RedSouthernWarehouse:SetRespawnAfterDestroyed(3600)
  elseif warehouse.RedSouthernWarehouse:GetCoalition()~=1 then
    warehouse.RedSouthernWarehouse:Stop()
    warehouse.RedSouthernWarehouse:SetRespawnAfterDestroyed(3600)    
end

if warehouse.RedNavalWarehouse:GetCoalition()==1 or warehouse.RedNavalWarehouse:GetCoalition()==0 then
    warehouse.RedNavalWarehouse:Start()
    warehouse.RedNavalWarehouse:SetRespawnAfterDestroyed(3600)
  elseif warehouse.RedNavalWarehouse:GetCoalition()~=1 then
    warehouse.RedNavalWarehouse:Stop()
    warehouse.RedNavalWarehouse:SetRespawnAfterDestroyed(3600)  
  else
end

----Set Spawn Zones for the warehouses
warehouse.BlueNorthernWarehouse:SetSpawnZone(ZONE_POLYGON:New("Blue Northern Warehouse Spawn Zone #001", GROUP:FindByName("Blue Northern Warehouse Spawn Zone #001"))):SetReportOff()
warehouse.BlueSouthernWarehouse:SetSpawnZone(ZONE_POLYGON:New("Blue Southern Warehouse Spawn Zone #001", GROUP:FindByName("Blue Southern Warehouse Spawn Zone #001"))):SetReportOff()

warehouse.BlueNavalWarehouse:SetPortZone(ZONE_POLYGON:NewFromGroupName("Blue Naval Spawn Zone", GROUP:FindByName("Blue Naval Spawn Zone"))):SetReportOff()

warehouse.RedNorthernWarehouse:SetSpawnZone(ZONE_POLYGON:New("Red Northern Warehouse Spawn Zone #001", GROUP:FindByName("Red Northern Warehouse Spawn Zone #001"))):SetReportOff()
warehouse.RedSouthernWarehouse:SetSpawnZone(ZONE_POLYGON:New("Red Southern Warehouse Spawn Zone #001", GROUP:FindByName("Red Southern Warehouse Spawn Zone #001"))):SetReportOff()

warehouse.RedNavalWarehouse:SetPortZone(ZONE_POLYGON:NewFromGroupName("Red Naval Spawn Zone", GROUP:FindByName("Red Naval Spawn Zone"))):SetReportOff()

Warehouse_EventHandler = EVENTHANDLER:New()
Warehouse_EventHandler:HandleEvent( EVENTS.Dead )

----Spawn unit at a warehouse when a unit of it's type dies
function Warehouse_EventHandler:OnEventDead( EventData )
  --BLUE--
  if EventData.IniTypeName == 'MCV-80' then
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
	
  elseif EventData.IniTypeName == 'PERRY' then
    warehouse.BlueNavalWarehouse:__AddRequest(5, warehouse.BlueNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue Perry", 1, WAREHOUSE.TransportType.SELFPROPELLED)
    warehouse.BlueNavalWarehouse:__Save(5,nil,"BlueNavalWarehouse")
  elseif EventData.IniTypeName == 'TICONDEROG' then
    warehouse.BlueNavalWarehouse:__AddRequest(5, warehouse.BlueNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue Ticonderoga", 1, WAREHOUSE.TransportType.SELFPROPELLED)
    warehouse.BlueNavalWarehouse:__Save(5,nil,"BlueNavalWarehouse")
  elseif EventData.IniTypeName == 'Type_052C' then
    warehouse.BlueNavalWarehouse:__AddRequest(5, warehouse.BlueNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue Type 052C", 1, WAREHOUSE.TransportType.SELFPROPELLED)
    warehouse.BlueNavalWarehouse:__Save(5,nil,"BlueNavalWarehouse")
  elseif EventData.IniTypeName == 'CVN_73' then
    warehouse.BlueNavalWarehouse:__AddRequest(5, warehouse.BlueNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue Carrier", 1, WAREHOUSE.TransportType.SELFPROPELLED)
    warehouse.BlueNavalWarehouse:__Save(5,nil,"BlueNavalWarehouse")
  elseif EventData.IniTypeName == 'LHA_Tarawa' then
    warehouse.BlueNavalWarehouse:__AddRequest(5, warehouse.BlueNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue Tarawa", 1, WAREHOUSE.TransportType.SELFPROPELLED)
    warehouse.BlueNavalWarehouse:__Save(5,nil,"BlueNavalWarehouse")
  
  --RED-- 	
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
	 	
  elseif EventData.IniTypeName == 'Type_054A' then
    warehouse.RedNavalWarehouse:__AddRequest(5, warehouse.RedNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red Type 054A", 1, WAREHOUSE.TransportType.SELFPROPELLED)
    warehouse.RedNavalWarehouse:__Save(5,nil,"RedNavalWarehouse")
  elseif EventData.IniTypeName == 'MOSCOW' then
    warehouse.RedNavalWarehouse:__AddRequest(5, warehouse.RedNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red Moskva", 1, WAREHOUSE.TransportType.SELFPROPELLED)
    warehouse.RedNavalWarehouse:__Save(5,nil,"RedNavalWarehouse")
  elseif EventData.IniTypeName == 'MOLNIYA' then
    warehouse.RedNavalWarehouse:__AddRequest(5, warehouse.RedNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red Molniya", 1, WAREHOUSE.TransportType.SELFPROPELLED)
    warehouse.RedNavalWarehouse:__Save(5,nil,"RedNavalWarehouse")
  elseif EventData.IniTypeName == 'CV_1143_5' then
    warehouse.RedNavalWarehouse:__AddRequest(5, warehouse.RedNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red Carrier", 1, WAREHOUSE.TransportType.SELFPROPELLED)
    warehouse.RedNavalWarehouse:__Save(5,nil,"RedNavalWarehouse")
  elseif EventData.IniTypeName == 'Type_071' then
    warehouse.RedNavalWarehouse:__AddRequest(5, warehouse.RedNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red Transport Dock", 1, WAREHOUSE.TransportType.SELFPROPELLED)
    warehouse.RedNavalWarehouse:__Save(5,nil,"RedNavalWarehouse")	
	
  else
    --nothing
  end
end

----Spawn Units after Capture
function warehouse.BlueNorthernWarehouse:OnAfterCaptured(From, Event, To, Coalition, Country)
--function warehouse.BlueNorthernWarehouse:OnAfterAirbaseCaptured(From,Event,To,Coalition)
  if Coalition==coalition.side.BLUE then
    MESSAGE:New("The Northern Warehouse is running at full capacity.",25,"[TEAM]:"):ToBlue()
    warehouse.BlueNorthernWarehouse:Start()
    warehouse.BlueNorthernWarehouse:__Save(15,nil,"BlueNorthernWarehouse")
    warehouse.BlueNorthernWarehouse:AddRequest(warehouse.BlueNorthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue MBT North", 3, WAREHOUSE.TransportType.SELFPROPELLED)
    warehouse.BlueNorthernWarehouse:AddRequest(warehouse.BlueNorthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue IFV North", 6, WAREHOUSE.TransportType.SELFPROPELLED)
  
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
    warehouse.BlueSouthernWarehouse:AddRequest(warehouse.BlueSouthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue MBT South", 3, WAREHOUSE.TransportType.SELFPROPELLED)
    warehouse.BlueSouthernWarehouse:AddRequest(warehouse.BlueSouthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue IFV South", 6, WAREHOUSE.TransportType.SELFPROPELLED)
  
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
    warehouse.RedNorthernWarehouse:AddRequest(warehouse.RedNorthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red MBT North", 3, WAREHOUSE.TransportType.SELFPROPELLED)
    warehouse.RedNorthernWarehouse:AddRequest(warehouse.RedNorthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red IFV North", 6, WAREHOUSE.TransportType.SELFPROPELLED)
  
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
    warehouse.RedSouthernWarehouse:AddRequest(warehouse.RedSouthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red MBT South", 3, WAREHOUSE.TransportType.SELFPROPELLED)
    warehouse.RedSouthernWarehouse:AddRequest(warehouse.RedSouthernWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red IFV South", 6, WAREHOUSE.TransportType.SELFPROPELLED)
  
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
  	warehouse.BlueNavalWarehouse:AddRequest(warehouse.BlueNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue Ticonderoga", 1, WAREHOUSE.TransportType.SELFPROPELLED)
	  warehouse.BlueNavalWarehouse:AddRequest(warehouse.BlueNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Blue Perry", 3, WAREHOUSE.TransportType.SELFPROPELLED)
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
    warehouse.RedNavalWarehouse:AddRequest(warehouse.RedNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red Type 054A", 3, WAREHOUSE.TransportType.SELFPROPELLED)
    warehouse.RedNavalWarehouse:AddRequest(warehouse.RedNavalWarehouse, WAREHOUSE.Descriptor.GROUPNAME, "Resupply Red Molniya", 3, WAREHOUSE.TransportType.SELFPROPELLED)
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