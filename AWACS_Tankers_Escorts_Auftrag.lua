-- Name: AWACS-Tankers-Auftrag
-- Author: Wildcat (Chandawg)
-- Date Created: 02 Mar 2021
-- Date Modified: 04 Mar 2021
--Succefully used auftrag to create two AirWings, and have them launch an AWACS with Escorts.

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Below is not part of Auftrag, but is something I run to set all units to red on restart

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
