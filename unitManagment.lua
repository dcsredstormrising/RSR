-- Name: unitManagment
-- Author: Wildcat/=AW=33COM
-- Date Created: 26 Mar 2021
-- This file helps to configure units in the session.  Here we turn units to RED after session start.  This actually has to be correctly tested if it's still needed.
-- EPLRS methoded allowed us to show friendly units on the A10C Scorpion, but due to bad performance we had to turn this off.
local inspect = require("inspect")

--This allows us to set TOR and Rolands to RED state
GroupsSetToRed = SET_GROUP:New():FilterCategoryGround():FilterPrefixes( {"Red Start","Blue Start", "Resupply ", " Convoy", "CTLD"} ):FilterActive():FilterOnce()

SCHEDULER:New( nil, function()
   GroupsSetToRed:ForEachGroup(
   function( grp )    
    if grp ~= nil and grp:getUnits() ~= nil and grp:getUnits()[1] ~= nil then        
    
        local _unitTypeName = grp:getUnits()[1]:getTypeName()  
        
        if string.find(_unitTypeName, "Roland ADS") then
          grp:OptionAlarmStateRed()
        end
        
        if string.find(_unitTypeName, "Tor") then
          grp:OptionAlarmStateRed()
        end
                                  
    end
   end) 
end, {}, 40)

-- This sets EPRLS on for Medium and Long range sams only
GroupsSetToRed = SET_GROUP:New():FilterCategoryGround():FilterPrefixes( {"Red Start","Blue Start", "CTLD"} ):FilterActive():FilterOnce()

SCHEDULER:New( nil, function()
   GroupsSetToRed:ForEachGroup(
   function( grp )
      grp:CommandEPLRS(true, 3)    
      
    --if grp ~= nil and grp:getUnits() ~= nil and grp:getUnits()[1] ~= nil then        
    
      --  local _unitTypeName = grp:getUnits()[1]:getTypeName()  
        
        --if string.find(_unitTypeName, "Hawk pcp") then
          --grp:CommandEPLRS(true, 3)
        --end
        
        --if string.find(_unitTypeName, "Patriot ECS") then
          --grp:CommandEPLRS(true, 3)
        --end
                                  
    --end
   end) 
end, {}, 40)


  -- logic to load saved AASystems into CTLD
  local _aaSystemGroups = SET_GROUP:New():FilterCategoryGround():FilterPrefixes( {"AASystem"} ):FilterActive(true):FilterOnce()  
  
  _aaSystemGroups:ForEachGroup(function (grp)  
    local _spawnedGroup = Group.getByName(grp:GetName())
    LoadAllExistingSystemsIntoCTLD(_spawnedGroup)    
  end)
  
  
 -- Here we update the AA System in CTLD upon each session start.
 local function LoadAllExistingSystemsIntoCTLD(_spawnedGroup)
    
    env.info("***=AW=33COM LoadAllExistingSystemsIntoCTLD")
        
    if _spawnedGroup ~= nil and _spawnedGroup:getUnits() ~= nil and _spawnedGroup:getUnits()[1] ~= nil then
    
      local _units = _spawnedGroup:getUnits()  
      local _firstUnitType = _units[1]:getTypeName()      
    
      env.info("***=AW=33COM _spawnedGroup Name: " .. inspect(_spawnedGroup:getName()))            
      local _aaSystemDetails = ctld.getAASystemDetails(_spawnedGroup, ctld.getAATemplate(_firstUnitType))      
      ctld.completeAASystems[_spawnedGroup:getName()] = _aaSystemDetails
      
      --env.info("******=AW=33COM sgs_rsr.LoadAllExistingSystemsIntoCTLD: ctld.completeAASystems ******")
      --env.info(inspect(ctld.completeAASystems))      
      --env.info("***=AW=33COM End:")

    else
      env.info("***=AW=33COM _spawnedGroup is empty")
    end
 end 


