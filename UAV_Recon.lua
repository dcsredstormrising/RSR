-- Name: UAV Recon
-- Author: Wildcat (Chandawg)
-- Date Created: 03 Nov 2020
-- Trying to spawn a UAV, then spawn it based on Client Helo position, then wrap it into a F10 menu option to be called by clients in 
-- Helos

---Count UAVs
local _BlueUAVsLeft = 4
local _RedUAVsLeft = 4

function RemainingBlueUAVs()
  trigger.action.outTextForCoalition(2, "[TEAM] Has " .. _BlueUAVsLeft .. " Remaining UAVs", 10)
end

function RemainingRedUAVs()
  trigger.action.outTextForCoalition(1, "[TEAM] Has " .. _RedUAVsLeft .. " Remaining UAVs", 10)
end

DroneSpawned = EVENTHANDLER:New()
DroneSpawned:HandleEvent(EVENTS.Birth)


---Objects to be spawned with attributes set
Spawn_Blue_UAV = SPAWN:NewWithAlias("Blue UAV-Recon-FAC","Pontiac 1-1")
    :InitLimit(2,4)
	:InitKeepUnitNames(true)
    
Spawn_Red_UAV = SPAWN:NewWithAlias("Red UAV-Recon-FAC","Pontiac 6-1")
    :InitLimit(2,4)
    :InitKeepUnitNames(true)

                    
----Function to actually spawn the UAV from the players nose      
function BlueUAV(group,rng)
  local range = rng * 1852
  local hdg = group:GetHeading()
  local pos = group:GetPointVec2()
  local spawnPt = pos:Translate(range, hdg, true)
  local spawnVec2 = spawnPt:GetVec2() 
  local spawnUnit = Spawn_Blue_UAV:SpawnFromVec2(spawnVec2)
end

function RedUAV(group,rng)
  local range = rng * 1852
  local hdg = group:GetHeading()
  local pos = group:GetPointVec2()
  local spawnPt = pos:Translate(range, hdg, true)
  local spawnVec2 = spawnPt:GetVec2() 
  local spawnUnit = Spawn_Red_UAV:SpawnFromVec2(spawnVec2)
end

----Define the client to have the menu
local SetClient = SET_CLIENT:New():FilterCoalitions("blue"):FilterPrefixes({" Blue Cargo", " Blue Helos"}):FilterOnce()
local SetClient2 = SET_CLIENT:New():FilterCoalitions("red"):FilterPrefixes({" Red Cargo", " Red Helos"}):FilterOnce()
----Menus for the client
local function UAV_MENU()
  SetClient:ForEachClient(function(client1)
      if (client1 ~= nil) and (client1:IsAlive()) then 
      local group1 = client1:GetGroup()
      local groupName = group1:GetName()
            BlueMenuGroup = group1
            BlueMenuGroupName = BlueMenuGroup:GetName()
            ----Main Menu
            BlueSpawnRECON = MENU_GROUP:New( BlueMenuGroup, "RECON" )
            ---- Sub Menu
            BlueSpawnRECONmenu = MENU_GROUP:New( BlueMenuGroup, "MQ-1 Recon UAV Menu", BlueSpawnRECON)
            ---- Command for the sub Menu the number on the end is the argument for the command (the rng) for the function
            BlueSpawnRECONrng1 = MENU_GROUP_COMMAND:New( BlueMenuGroup, "Spawn UAV 1 nmi away", BlueSpawnRECON, BlueUAV, BlueMenuGroup, 1)
            BlueSpawnRECONrng5 = MENU_GROUP_COMMAND:New( BlueMenuGroup, "Spawn UAV 5 nmi away", BlueSpawnRECON, BlueUAV, BlueMenuGroup, 5)
            BlueSpawnRECONrng10 = MENU_GROUP_COMMAND:New( BlueMenuGroup, "Spawn UAV 10 nmi away", BlueSpawnRECON, BlueUAV, BlueMenuGroup, 10)
            BlueRemainingUAVs = MENU_GROUP_COMMAND:New( BlueMenuGroup, "Remaining UAVs", BlueSpawnRECON, RemainingBlueUAVs, BlueMenuGroup)
            ---- Enters log information
            env.info("Player name: " ..client1:GetPlayerName())
            env.info("Group Name: " ..group1:GetName())

            function BlueUAV_EventHandler:OnEventBirth( EventData )
              if EventData.IniDCSGroupName == 'Pontiac 1-1#001' then 
              _BlueUAVsLeft = _BlueUAVsLeft - 1
              trigger.action.outTextForCoalition(2,"[TEAM] " ..client1:GetPlayerName().. " called in a UAV\nContact via F10/F8 Designation for UAV \nBlue team has ".._BlueUAVsLeft.." remaining UAVs", 10)
              elseif EventData.IniDCSGroupName == 'Pontiac 1-1#002' then
              _BlueUAVsLeft = _BlueUAVsLeft - 1
              trigger.action.outTextForCoalition(2,"[TEAM] " ..client1:GetPlayerName().. " called in a UAV\nContact via F10/F8 Designation for UAV \nBlue team has ".._BlueUAVsLeft.." remaining UAVs", 10)
              elseif EventData.IniDCSGroupName == 'Pontiac 1-1#003' then
              _BlueUAVsLeft = _BlueUAVsLeft - 1
              trigger.action.outTextForCoalition(2,"[TEAM] " ..client1:GetPlayerName().. " called in a UAV\nContact via F10/F8 Designation for UAV \nBlue team has ".._BlueUAVsLeft.." remaining UAVs", 10)
              elseif EventData.IniDCSGroupName == 'Pontiac 1-1#004' then
              _BlueUAVsLeft = _BlueUAVsLeft - 1
              trigger.action.outTextForCoalition(2,"[TEAM] " ..client1:GetPlayerName().. " called in a UAV\nContact via F10/F8 Designation for UAV \nBlue team has ".._BlueUAVsLeft.." remaining UAVs", 10)
              elseif EventData.IniDCSGroupName == 'Pontiac 1-1#005' then
              _BlueUAVsLeft = _BlueUAVsLeft - 1
              trigger.action.outTextForCoalition(2,"[TEAM] " ..client1:GetPlayerName().. " called in a UAV\nContact via F10/F8 Designation for UAV \nBlue team has ".._BlueUAVsLeft.." remaining UAVs", 10)
              elseif EventData.IniDCSGroupName == 'Pontiac 1-1#006' then
              _BlueUAVsLeft = _BlueUAVsLeft - 1
              trigger.action.outTextForCoalition(2,"[TEAM] " ..client1:GetPlayerName().. " called in a UAV\nContact via F10/F8 Designation for UAV \nBlue team has ".._BlueUAVsLeft.." remaining UAVs", 10)
              else
              --nothing
              end
            end

            SetClient:Remove(client1:GetName(), true)
    end
  end)
--timer.scheduleFunction(UAV_MENU,nil,timer.getTime() + 1)
end
local function UAV_MENU2()
  SetClient2:ForEachClient(function(client2)
      if (client2 ~= nil) and (client2:IsAlive()) then 
      local group2 = client2:GetGroup()
      local groupName = group2:GetName()
            RedMenuGroup = group2
            RedMenuGroupName = RedMenuGroup:GetName()
            ----Main Menu
            RedSpawnRECON2 = MENU_GROUP:New( RedMenuGroup, "RECON" )
            ---- Sub Menu
            SpawnRECONmenu = MENU_GROUP:New( RedMenuGroup, "MQ-1 Recon UAV Menu", RedSpawnRECON2)
            ---- Command for the sub Menu the number on the end is the argument for the command (the rng) for the function
            RedSpawnRECONrng1 = MENU_GROUP_COMMAND:New( RedMenuGroup, "Spawn 1 nmi away", RedSpawnRECON2, RedUAV, RedMenuGroup, 1)
            RedSpawnRECONrng5 = MENU_GROUP_COMMAND:New( RedMenuGroup, "Spawn 5 nmi away", RedSpawnRECON2, RedUAV, RedMenuGroup, 5)
            RedSpawnRECONrng10 = MENU_GROUP_COMMAND:New( RedMenuGroup, "Spawn 10 nmi away", RedSpawnRECON2, RedUAV, RedMenuGroup, 10)
            RedRemainingUAVs = MENU_GROUP_COMMAND:New( RedMenuGroup, "Remaining UAVs", RedSpawnRECON2, RemainingRedUAVs, RedMenuGroup)
            ---- Enters log information
            env.info("Player name: " ..client2:GetPlayerName())
            env.info("Group Name: " ..group2:GetName())

            function RedUAV_EventHandler:OnEventBirth( EventData )
              if EventData.IniDCSGroupName == 'Pontiac 6-1#001' then 
              _RedUAVsLeft = _RedUAVsLeft - 1
              trigger.action.outTextForCoalition(1,"[TEAM] " ..client2:GetPlayerName().. " called in a UAV\nContact via F10/F8 Designation for UAV \nRed team has ".._RedUAVsLeft.." remaining UAVs", 10)
              elseif EventData.IniDCSGroupName == 'Pontiac 6-1#002' then
              _RedUAVsLeft = _RedUAVsLeft - 1
              trigger.action.outTextForCoalition(1,"[TEAM] " ..client2:GetPlayerName().. " called in a UAV\nContact via F10/F8 Designation for UAV \nRed team has ".._RedUAVsLeft.." remaining UAVs", 10)
              elseif EventData.IniDCSGroupName == 'Pontiac 6-1#003' then
              _RedUAVsLeft = _RedUAVsLeft - 1
              trigger.action.outTextForCoalition(1,"[TEAM] " ..client2:GetPlayerName().. " called in a UAV\nContact via F10/F8 Designation for UAV \nRed team has ".._RedUAVsLeft.." remaining UAVs", 10)
              elseif EventData.IniDCSGroupName == 'Pontiac 6-1#004' then
              _RedUAVsLeft = _RedUAVsLeft - 1
              trigger.action.outTextForCoalition(1,"[TEAM] " ..client2:GetPlayerName().. " called in a UAV\nContact via F10/F8 Designation for UAV \nRed team has ".._RedUAVsLeft.." remaining UAVs", 10)
              elseif EventData.IniDCSGroupName == 'Pontiac 6-1#005' then
              _RedUAVsLeft = _RedUAVsLeft - 1
              trigger.action.outTextForCoalition(1,"[TEAM] " ..client2:GetPlayerName().. " called in a UAV\nContact via F10/F8 Designation for UAV \nRed team has ".._RedUAVsLeft.." remaining UAVs", 10)
              elseif EventData.IniDCSGroupName == 'Pontiac 6-1#006' then
              _RedUAVsLeft = _RedUAVsLeft - 1
              trigger.action.outTextForCoalition(1,"[TEAM] " ..client2:GetPlayerName().. " called in a UAV\nContact via F10/F8 Designation for UAV \nRed team has ".._RedUAVsLeft.." remaining UAVs", 10)
              else
              --nothing
              end
            end

            SetClient2:Remove(client2:GetName(), true)
    end
  end)
--timer.scheduleFunction(UAV_MENU2,nil,timer.getTime() + 1)
end


--UAV_MENU()
--UAV_MENU2()