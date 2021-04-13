-- Name: unitManagment
-- Author: Wildcat/=AW=33COM
-- Date Created: 26 Mar 2021
-- This file helps to configure units in the session.  Here we turn units to RED after session start.  This actually has to be correctly tested if it's still needed.
-- EPLRS methoded allowed us to show friendly units on the A10C Scorpion, but due to bad performance we had to turn this off.
local inspect = require("inspect")

--This allows us to set TOR and Rolands to RED state
GroupsSetToRed = SET_GROUP:New():FilterCategoryGround():FilterPrefixes( {"Red Start","Blue Start", "CTLD"} ):FilterActive():FilterOnce()
local _redTypes = {"Roland", "Tor"}

SCHEDULER:New( nil, function()
  env.info("**=AW=33COM GroupsSetToRed Scheduler")
   GroupsSetToRed:ForEachGroup(
   function( grp )    
    if grp ~= nil then    
    
        local _dcsGroup = Group.getByName(grp:GetName())
        
        if _dcsGroup ~= nil then
        
          local _units = _dcsGroup:getUnits()
          
          if _units ~= nil then
          
            local _unitTypeName = _units[1]:getTypeName()
            
            for _, item in pairs(_eplrsTypes) do
              if string.find(_unitTypeName, item) then
                env.info("**=AW=33COM GroupsSetToRed Found: " ..inspect(item) .. " in " .. inspect(_unitTypeName))
                grp:OptionAlarmStateRed()
              end
            end
          end
        end                          
     end
   end) 
end, {}, 30)

-- This sets EPRLS on for Medium and Long range sams only
GroupsForEPLRS = SET_GROUP:New():FilterCategoryGround():FilterPrefixes( {"Red Start","Blue Start", "CTLD"} ):FilterActive():FilterOnce()
local _eplrsTypes = {"Roland", "Tor", "Hawk", "Buk", "rapier", "Kub", "p-19", "SNR_75V", "Patriot", "S-300PS", "snr s-125"}

SCHEDULER:New( nil, function()
env.info("**=AW=33COM GroupsForEPLRS Scheduler")
   GroupsForEPLRS:ForEachGroup(
      function( grp )    
    if grp ~= nil then    
    
        local _dcsGroup = Group.getByName(grp:GetName())
        
        if _dcsGroup ~= nil then
        
          local _units = _dcsGroup:getUnits()
          
          if _units ~= nil then
          
            local _unitTypeName = _units[1]:getTypeName()
            
            for _, eplrsType in pairs(_eplrsTypes) do
              if string.find(_unitTypeName, eplrsType) then
                env.info("**=AW=33COM GroupsForEPLRS Found: " ..inspect(eplrsType) .. " in " .. inspect(_unitTypeName))
                grp:CommandEPLRS(true, 3)
              end
            end
          end
        end                          
     end
   end)
end, {}, 30)


-- this must run after State is reconstructed in order to load correct AASystem.  Otherwise you will load old miz level systems from default position and with different names.
-- when we repair a static AASystem, it's name changes to a player name.  That's why we must get the player name for the unit from the State.  Hence the big delay.
SCHEDULER:New( nil, function()

  -- logic to load saved AASystems into CTLD
  local _aaSystemGroups = SET_GROUP:New():FilterCategoryGround():FilterPrefixes( {"AASystem"} ):FilterActive(true):FilterOnce()  
  
  _aaSystemGroups:ForEachGroup(function (grp)  
    local _spawnedGroup = Group.getByName(grp:GetName())
    ctld.LoadAllExistingSystemsIntoCTLD(_spawnedGroup)    
  end)
   
end, {}, 10)




  
    