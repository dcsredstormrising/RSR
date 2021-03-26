-- Name: unitManagment
-- Author: Wildcat/=AW=33COM
-- Date Created: 26 Mar 2021
-- This file helps to configure units in the session.  Here we turn units to RED after session start.  This actually has to be correctly tested if it's still needed.
-- EPLRS methoded allowed us to show friendly units on the A10C Scorpion, but due to bad performance we had to turn this off.

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
WakeUpSet = SET_GROUP:New():FilterPrefixes( {"Red Start","Blue Start", "Resupply ", " Convoy", "Dropped Group ","CTLD"} ):FilterStart()

SCHEDULER:New( nil, function()
   WakeUpSet:ForEachGroup(
   function( MooseGroup )
    local chance = math.random(1,99)
     if chance > 1 then
        MooseGroup:OptionAlarmStateRed()
--        MooseGroup:CommandEPLRS(true, 3)
     else
        MooseGroup: OptionAlarmStateGreen()
     end
    end)

end, {}, 40)
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
