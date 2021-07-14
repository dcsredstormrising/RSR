-- Name: unitManagment
-- Author: =AW=33COM
-- Date Created: 26 Mar 2021
-- This file helps to configure units in the session.  Here we turn units to RED after session start.  This actually has to be correctly tested if it's still needed.
-- EPLRS methoded allowed us to show friendly units on the A10C Scorpion, but due to bad performance (our fault somewhere else) we had to turn this off.
local inspect = require("inspect")
local rsrConfig = require("RSR_config")
 
SCHEDULER:New( nil, function()

	--This allows us to set TOR and Rolands to RED state
	local GroupsSetToRed = SET_GROUP:New():FilterCategoryGround():FilterPrefixes( {"Red Start","Blue Start", "CTLD"} ):FilterActive():FilterOnce()
	local _redTypes = {"Roland", "Tor"}

	-- can not run this due to performance until we figure out what is Moose/DCS doing with this: grp:CommandEPLRS(true, 3)
	-- might be that Moose is the problem here not DCS and that's why the big performance hit every 15 sec
	-- This sets EPRLS ON
	--GroupsForEPLRS = SET_GROUP:New():FilterCategoryGround():FilterPrefixes( {"Red Start","Blue Start", "CTLD"} ):FilterActive():FilterOnce()
	--local _eplrsTypes = {"Hawk", "Buk", "Kub", "p-19", "SNR_75V", "Patriot", "S-300PS", "snr s-125", "Tor", "Roland"}
	--local useFullEPLRS = true

	-- logic to load saved AASystems into CTLD. This fixes the problem of static sams not being part of CTLD.  Now they are. This fixes half the problem, 
	  -- the other problem is CTLD Repair was written for 1 session.  It has to be rewritten in order to repair systems through out the entire round.  
	  -- this must run after State is reconstructed in order to load correct AASystem.  Otherwise you will load old miz level systems from default position and with different names.
	  -- when we repair a static AASystem, it's name changes to a player name.     
	 local _aaSystemGroups = SET_GROUP:New():FilterCategoryGround():FilterPrefixes({"AASystem"}):FilterActive(true):FilterOnce()
	 
	 -- we find all jtacs by type and rebuild the count for CTLD on session start
	 local JTACsRED = SET_GROUP:New():FilterCategoryGround():FilterPrefixes({ctld.JTAC_TYPE_RED}):FilterActive(true):FilterOnce()
	 local JTACsBLUE = SET_GROUP:New():FilterCategoryGround():FilterPrefixes({ctld.JTAC_TYPE_BLUE}):FilterActive(true):FilterOnce()

	env.info("**=AW=33COM GroupsSetToRed Scheduler")
	
	GroupsSetToRed:ForEachGroup(
	function( grp )    
    if grp ~= nil then        
        if _redTypes ~= nil and #_redTypes > 0 then -- for groups with specific type     
          local _dcsGroup = Group.getByName(grp:GetName())          
          if _dcsGroup ~= nil then
            local _units = _dcsGroup:getUnits()
            if _units ~= nil then
              local _unitTypeName = _units[1]:getTypeName()
              for _, redType in ipairs (_redTypes) do
                if string.find(_unitTypeName, redType) then                  
                  grp:OptionAlarmStateRed()
                end
              end
            end
          end
        else
          env.info("**=AW=33COM OptionAlarmStateRed For all units")
          grp:OptionAlarmStateRed()
        end                          
     end
   end) 
         
   --env.info("**=AW=33COM GroupsForEPLRS Scheduler")   
   --[[
   GroupsForEPLRS:ForEachGroup(
      function( grp )                  
		if useFullEPLRS then
			grp:CommandEPLRS(true, 10) -- for all groups
		else
			if _eplrsTypes ~= nil and #_eplrsTypes > 0 then -- for groups with specific type      
				local _dcsGroup = Group.getByName(grp:GetName())          
				if _dcsGroup ~= nil then          
					local _units = _dcsGroup:getUnits()
            
					if _units ~= nil then            
						local _unitTypeName = _units[1]:getTypeName()
				  
						for _, eplrsType in ipairs (_eplrsTypes) do
							if string.find(_unitTypeName, eplrsType) then						
								grp:CommandEPLRS(true, 10)	-- for specific unit types
							end
						end
					end
				end
			end
		end
	end)
	]]--
     
  -- rebuild all AA system in CTLD on session start
	env.info("**=AW=33COM Loaded Existing AASystems into CTLD Scheduler")
	_aaSystemGroups:ForEachGroup(function (grp)  
    local _spawnedGroup = Group.getByName(grp:GetName())	
    ctld.LoadAllExistingSystemsIntoCTLD(_spawnedGroup)
  end)   
  
  local redJTACCount = 0
  JTACsRED:ForEachGroup(
    function(grp)
      redJTACCount=redJTACCount+1  
    end)
 
  local blueJTACCount = 0
  JTACsBLUE:ForEachGroup(
    function(grp)
      blueJTACCount=blueJTACCount+1
    end)

  -- rebuild JTAC count in CTLD on session start
  env.info("**=AW=33COM Loaded JTAC count into CTLD Scheduler")
  ctld.RebuildJTACCountsOnSessionStart(redJTACCount, blueJTACCount)  
  
end, {}, 30)
  