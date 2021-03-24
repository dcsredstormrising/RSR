-- Name: AWACS-Tankers-Auftrag
-- Author: Wildcat (Chandawg)
-- Date Created: 02 Mar 2021
-- Date Modified: 04 Mar 2021
--Succefully used auftrag to create two AirWings, and have them launch an AWACS with Escorts.

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Below is not part of Auftrag, but is something I run to set all units to red on restart
--[[
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
--]]
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
RedSqd = {}
BlueSqd = {}

  -- list of possible loiter zones
  -- 0 = Neutral // 1 = Red // 2 = Blue--

function PickAWACsZone()
  local CoalitionSenaki = AIRBASE:FindByName("Senaki-Kolkhi"):GetCoalition()
  local CoalitionMaykop = AIRBASE:FindByName("Maykop-Khanskaya"):GetCoalition()

  if  CoalitionSenaki == 2 or 0 then
    Blue_AWACS_Zone = ZONE:New("Blue AWACs Zone-1"):GetCoordinate()
  else
    Blue_AWACS_Zone = ZONE:New("Blue AWACs Zone-2"):GetCoordinate()
  end
  if CoalitionMaykop == 1 or 0 then
    Red_AWACS_Zone = ZONE:New("Red AWACs Zone-1"):GetCoordinate()
  else
    Red_AWACS_Zone = ZONE:New("Red AWACs Zone-2"):GetCoordinate()
  end
end

PickAWACsZone()

RedSqd.MiG31=SQUADRON:New("Red MiG31", 12, "MiG-31 Sqd.") --Ops.Squadron#SQUADRON
RedSqd.MiG31:SetSkill(AI.Skill.EXCELLENT)
RedSqd.MiG31:SetMissionRange(300)
RedSqd.MiG31:AddMissionCapability({AUFTRAG.Type.ESCORT}, 100)

RedSqd.Darkstar=SQUADRON:New("AWACS Red", 4, "Darkstar AWACS")
RedSqd.Darkstar:SetCallsign(CALLSIGN.AWACS.Darkstar, 5)
RedSqd.Darkstar:AddMissionCapability({AUFTRAG.Type.AWACS}, 100) 
RedSqd.Darkstar:SetMissionRange(500)

RedSqd.Shell=SQUADRON:New("Tanker Basket Red", 2, "566ARR")
RedSqd.Shell:SetCallsign(CALLSIGN.Tanker.Shell,2)
RedSqd.Shell:AddMissionCapability({AUFTRAG.Type.TANKER}, 100)
RedSqd.Shell:SetMissionRange(500)

RedSqd.Texaco=SQUADRON:New("Tanker Boom Red", 2, "546ARR")
RedSqd.Texaco:SetCallsign(CALLSIGN.Tanker.Texaco,2)
RedSqd.Texaco:AddMissionCapability({AUFTRAG.Type.TANKER}, 100)
RedSqd.Texaco:SetMissionRange(500)

RedSqd.Wizard=SQUADRON:New("Carrier AWACS Red", 4, "Wizard Carrier AWACS")
RedSqd.Wizard:SetCallsign(CALLSIGN.AWACS.Wizard, 5)
RedSqd.Wizard:AddMissionCapability({AUFTRAG.Type.AWACS}, 100) 
RedSqd.Wizard:SetMissionRange(500)

RedSqd.Arco=SQUADRON:New("Recovery Tanker Red", 2, "547ARR")
RedSqd.Arco:SetCallsign(CALLSIGN.Tanker.Arco,2)
RedSqd.Arco:AddMissionCapability({AUFTRAG.Type.TANKER}, 100)
RedSqd.Arco:SetMissionRange(500)

RedSqd.SU33=SQUADRON:New("Red SU33", 12, "Su-33 Sqd.") --Ops.Squadron#SQUADRON
RedSqd.SU33:SetSkill(AI.Skill.EXCELLENT)
RedSqd.SU33:SetMissionRange(300)
RedSqd.SU33:AddMissionCapability({AUFTRAG.Type.ESCORT}, 100)

Krasnodar_Pashkovsky=AIRWING:New("Krasnodar_Pashkovsky Warehouse", "Krasnodar_Pashkovsky Airwing") --Ops.AirWing#AIRWING
Krasnodar_Pashkovsky:SetNumberTankerProbe(1)
Krasnodar_Pashkovsky:SetNumberTankerBoom(1)
Krasnodar_Pashkovsky:SetNumberAWACS(1)
Krasnodar_Pashkovsky:AddPatrolPointTANKER(ZONE:New("Red Basket Tanker Zone"):GetCoordinate(), 16000, 235, 15, 25)
Krasnodar_Pashkovsky:AddPatrolPointTANKER(ZONE:New("Red Boom Tanker Zone"):GetCoordinate(), 16000, 235, 15, 25)
Krasnodar_Pashkovsky:AddPatrolPointAWACS(Red_AWACS_Zone, 25000, 280, 90, 35)
--Krasnodar_Pashkovsky:AddPatrolPointAWACS(ZONE:New("Red AWACs Zone-2"):GetCoordinate(), 25000, 250, 15, 25)
Krasnodar_Pashkovsky:SetAirbase(AIRBASE:FindByName("Krasnodar_Pashkovsky"))
Krasnodar_Pashkovsky:Start(30)
Krasnodar_Pashkovsky:AddSquadron(RedSqd.Darkstar)
Krasnodar_Pashkovsky:NewPayload("AWACS Red",-1,{AUFTRAG.Type.AWACS},100)
Krasnodar_Pashkovsky:AddSquadron(RedSqd.MiG31)
Krasnodar_Pashkovsky:NewPayload("Red MiG31",-1,{AUFTRAG.Type.ESCORT},100)
Krasnodar_Pashkovsky:AddSquadron(RedSqd.Shell)
Krasnodar_Pashkovsky:NewPayload("Tanker Basket Red",-1,{AUFTRAG.Type.TANKER},100)
Krasnodar_Pashkovsky:AddSquadron(RedSqd.Texaco)
Krasnodar_Pashkovsky:NewPayload("Tanker Boom Red",-1,{AUFTRAG.Type.TANKER},100)
Krasnodar_Pashkovsky:SetVerbosity(20)

function Krasnodar_Pashkovsky:OnAfterFlightOnMission(From, Event, To, FlightGroup, Mission)
    if Mission:GetType()==AUFTRAG.Type.AWACS then -- If the mission type is an AWACS then the aircraft must be one. Request an escort group
      local flightgroup = FlightGroup --Ops.FlightGroup#FLIGHTGROUP
	  
	  flightgroup:GetGroup():CommandEPLRS(true)  -- enables datalink apparently, added as a test by =AW=33COM
	  
      BASE:E("+++++++++++++ MISSION TYPE IS AWACS, REQUESTING ESCORTS... +++++++++++++")
      local escortMission = AUFTRAG:NewESCORT(flightgroup:GetGroup(), nil, 50)
      local escortMission2 = AUFTRAG:NewESCORT(flightgroup:GetGroup(), nil, 50)
      Krasnodar_Pashkovsky:AddMission(escortMission)    
      Krasnodar_Pashkovsky:AddMission(escortMission2)    
    end
    if Mission:GetType()==AUFTRAG.Type.TANKER then
      local flightGroup = FlightGroup
      BASE:E("+++++++++++++ MISSION TYPE IS TANKER, REQUESTING ESCORTS... +++++++++++++")
      local escortMission3 = AUFTRAG:NewESCORT(flightGroup:GetGroup(), nil, 50)
      Krasnodar_Pashkovsky:AddMission(escortMission3)    
    end
end

RedCarrier=AIRWING:New("Red Carrier Group2", "Red Carrier Airwing") --Ops.AirWing#AIRWING
RedCarrier:SetNumberTankerProbe(1)
RedCarrier:SetNumberTankerBoom(1)
RedCarrier:SetNumberAWACS(1)
RedCarrier:AddPatrolPointTANKER(ZONE:New("Red Recovery Tanker Zone"):GetCoordinate(), 16000, 235, 15, 25)
RedCarrier:AddPatrolPointAWACS(ZONE:New("Red Carrier AWACs Zone"):GetCoordinate(), 25000, 280, 270, 35)
RedCarrier:Start(30)
RedCarrier:AddSquadron(RedSqd.Wizard)
RedCarrier:NewPayload("Carrier AWACS Red",-1,{AUFTRAG.Type.AWACS},100)
RedCarrier:AddSquadron(RedSqd.SU33)
RedCarrier:NewPayload("Red SU33",-1,{AUFTRAG.Type.ESCORT},100)
RedCarrier:AddSquadron(RedSqd.Arco)
RedCarrier:NewPayload("Carrier Recovery Tanker Red",-1,{AUFTRAG.Type.TANKER},100)
RedCarrier:SetVerbosity(20)

function RedCarrier:OnAfterFlightOnMission(From, Event, To, FlightGroup, Mission)
    if Mission:GetType()==AUFTRAG.Type.AWACS then -- If the mission type is an AWACS then the aircraft must be one. Request an escort group
      local flightgroup = FlightGroup --Ops.FlightGroup#FLIGHTGROUP
	  
	  flightgroup:GetGroup():CommandEPLRS(true)  -- enables datalink apparently, added as a test by =AW=33COM
	  
      BASE:E("+++++++++++++ MISSION TYPE IS AWACS, REQUESTING ESCORTS... +++++++++++++")
      local escortMission = AUFTRAG:NewESCORT(flightgroup:GetGroup(), nil, 50)
      local escortMission2 = AUFTRAG:NewESCORT(flightgroup:GetGroup(), nil, 50)
      --local escortMission = AUFTRAG:NewESCORT(EscortGroup, OffsetVector, EngageMaxDistance, TargetTypes)
      RedCarrier:AddMission(escortMission)    
      RedCarrier:AddMission(escortMission2)
    end  
    if Mission:GetType()==AUFTRAG.Type.TANKER then
      local flightGroup = FlightGroup
      BASE:E("+++++++++++++ MISSION TYPE IS TANKER, REQUESTING ESCORTS... +++++++++++++")
      local escortMission3 = AUFTRAG:NewESCORT(flightGroup:GetGroup(), nil, 50)
      RedCarrier:AddMission(escortMission3)    
    end
end

BlueSqd.F14B=SQUADRON:New("Blue F14B", 12, "F-14B Sqd.") --Ops.Squadron#SQUADRON
BlueSqd.F14B:SetSkill(AI.Skill.EXCELLENT)
BlueSqd.F14B:SetMissionRange(300)
BlueSqd.F14B:AddMissionCapability({AUFTRAG.Type.ESCORT}, 100)

BlueSqd.F14B2=SQUADRON:New("Blue F14B", 12, "F-14B Sqd2") --Ops.Squadron#SQUADRON
BlueSqd.F14B2:SetSkill(AI.Skill.EXCELLENT)
BlueSqd.F14B2:SetMissionRange(300)
BlueSqd.F14B2:AddMissionCapability({AUFTRAG.Type.ESCORT}, 100)

BlueSqd.Magic=SQUADRON:New("AWACS Blue", 4, "Magic AWACS")
BlueSqd.Magic:SetCallsign(CALLSIGN.AWACS.Magic, 5)
BlueSqd.Magic:AddMissionCapability({AUFTRAG.Type.AWACS}, 100) 
BlueSqd.Magic:SetMissionRange(500)

BlueSqd.Wizard=SQUADRON:New("Carrier AWACS Blue", 4, "Wizard Carrier AWACS")
BlueSqd.Wizard:SetCallsign(CALLSIGN.AWACS.Wizard, 5)
BlueSqd.Wizard:AddMissionCapability({AUFTRAG.Type.AWACS}, 100) 
BlueSqd.Wizard:SetMissionRange(500)


BlueSqd.Shell=SQUADRON:New("Tanker Basket Blue", 2, "121ARS")
BlueSqd.Shell:SetCallsign(CALLSIGN.Tanker.Shell,2)
BlueSqd.Shell:AddMissionCapability({AUFTRAG.Type.TANKER}, 100)
BlueSqd.Shell:SetMissionRange(500)

BlueSqd.Texaco=SQUADRON:New("Tanker Boom Blue", 2, "123ARS")
BlueSqd.Texaco:SetCallsign(CALLSIGN.Tanker.Texaco,2)
BlueSqd.Texaco:AddMissionCapability({AUFTRAG.Type.TANKER}, 100)
BlueSqd.Texaco:SetMissionRange(500)

BlueSqd.Arco=SQUADRON:New("Recovery Tanker Blue", 2, "126ARS")
BlueSqd.Arco:SetCallsign(CALLSIGN.Tanker.Arco,2)
BlueSqd.Arco:AddMissionCapability({AUFTRAG.Type.TANKER}, 100)
BlueSqd.Arco:SetMissionRange(500)

Vaziani=AIRWING:New("Vaziani Warehouse", "Vaziani Airwing") --Ops.AirWing#AIRWING
Vaziani:SetNumberTankerProbe(1)
Vaziani:SetNumberTankerBoom(1)
Vaziani:SetNumberAWACS(1)
Vaziani:AddPatrolPointTANKER(ZONE:New("Blue Basket Tanker Zone"):GetCoordinate(), 16000, 235, 15, 25)
Vaziani:AddPatrolPointTANKER(ZONE:New("Blue Boom Tanker Zone"):GetCoordinate(), 16000, 235, 15, 25)
Vaziani:AddPatrolPointAWACS(Blue_AWACS_Zone, 25000, 280, 270, 35)
--Tbilisi_Lochini:AddPatrolPointAWACS(ZONE:New("Blue AWACs Zone-2"):GetCoordinate(), 25000, 250, 15, 25)
Vaziani:SetAirbase(AIRBASE:FindByName("Vaziani"))
Vaziani:Start(30)
Vaziani:AddSquadron(BlueSqd.Magic)
Vaziani:NewPayload("AWACS Blue",-1,{AUFTRAG.Type.AWACS},100)
Vaziani:AddSquadron(BlueSqd.F14B)
Vaziani:NewPayload("Blue F14B",-1,{AUFTRAG.Type.ESCORT},100)
Vaziani:AddSquadron(BlueSqd.Shell)
Vaziani:NewPayload("Tanker Basket Blue",-1,{AUFTRAG.Type.TANKER},100)
Vaziani:AddSquadron(BlueSqd.Texaco)
Vaziani:NewPayload("Tanker Boom Blue",-1,{AUFTRAG.Type.TANKER},100)
Vaziani:SetVerbosity(20)

function Vaziani:OnAfterFlightOnMission(From, Event, To, FlightGroup, Mission)
    if Mission:GetType()==AUFTRAG.Type.AWACS then -- If the mission type is an AWACS then the aircraft must be one. Request an escort group
      local flightgroup = FlightGroup --Ops.FlightGroup#FLIGHTGROUP
	  
	  flightgroup:GetGroup():CommandEPLRS(true)  -- enables datalink apparently, added as a test by =AW=33COM
	  
      BASE:E("+++++++++++++ MISSION TYPE IS AWACS, REQUESTING ESCORTS... +++++++++++++")
      local escortMission = AUFTRAG:NewESCORT(flightgroup:GetGroup(), nil, 50)
      local escortMission2 = AUFTRAG:NewESCORT(flightgroup:GetGroup(), nil, 50)
      --local escortMission = AUFTRAG:NewESCORT(EscortGroup, OffsetVector, EngageMaxDistance, TargetTypes)
      Vaziani:AddMission(escortMission)    
      Vaziani:AddMission(escortMission2)
    end  
    if Mission:GetType()==AUFTRAG.Type.TANKER then
      local flightGroup = FlightGroup
      BASE:E("+++++++++++++ MISSION TYPE IS TANKER, REQUESTING ESCORTS... +++++++++++++")
      local escortMission3 = AUFTRAG:NewESCORT(flightGroup:GetGroup(), nil, 50)
      Vaziani:AddMission(escortMission3)    
    end
end

BlueCarrier=AIRWING:New("Blue Carrier Group", "Blue Carrier Airwing") --Ops.AirWing#AIRWING
BlueCarrier:SetNumberTankerProbe(1)
BlueCarrier:SetNumberTankerBoom(1)
BlueCarrier:SetNumberAWACS(1)
BlueCarrier:AddPatrolPointTANKER(ZONE:New("Blue Recovery Tanker Zone"):GetCoordinate(), 16000, 235, 15, 25)
BlueCarrier:AddPatrolPointAWACS(ZONE:New("Blue Carrier AWACs Zone"):GetCoordinate(), 25000, 280, 270, 35)
BlueCarrier:Start(30)
BlueCarrier:AddSquadron(BlueSqd.Wizard)
BlueCarrier:NewPayload("Carrier AWACS Blue",-1,{AUFTRAG.Type.AWACS},100)
BlueCarrier:AddSquadron(BlueSqd.F14B2)
BlueCarrier:NewPayload("Blue F14B",-1,{AUFTRAG.Type.ESCORT},100)
BlueCarrier:AddSquadron(BlueSqd.Arco)
BlueCarrier:NewPayload("Carrier Recovery Tanker Blue",-1,{AUFTRAG.Type.TANKER},100)
BlueCarrier:SetVerbosity(20)

function BlueCarrier:OnAfterFlightOnMission(From, Event, To, FlightGroup, Mission)
    if Mission:GetType()==AUFTRAG.Type.AWACS then -- If the mission type is an AWACS then the aircraft must be one. Request an escort group
      local flightgroup = FlightGroup --Ops.FlightGroup#FLIGHTGROUP
	  
	  flightgroup:GetGroup():CommandEPLRS(true)  -- enables datalink apparently, added as a test by =AW=33COM
	  
      BASE:E("+++++++++++++ MISSION TYPE IS AWACS, REQUESTING ESCORTS... +++++++++++++")
      local escortMission = AUFTRAG:NewESCORT(flightgroup:GetGroup(), nil, 50)
      local escortMission2 = AUFTRAG:NewESCORT(flightgroup:GetGroup(), nil, 50)
      --local escortMission = AUFTRAG:NewESCORT(EscortGroup, OffsetVector, EngageMaxDistance, TargetTypes)
      BlueCarrier:AddMission(escortMission)    
      BlueCarrier:AddMission(escortMission2)
    end  
    if Mission:GetType()==AUFTRAG.Type.TANKER then
      local flightGroup = FlightGroup
      BASE:E("+++++++++++++ MISSION TYPE IS TANKER, REQUESTING ESCORTS... +++++++++++++")
      local escortMission3 = AUFTRAG:NewESCORT(flightGroup:GetGroup(), nil, 50)
      BlueCarrier:AddMission(escortMission3)    
    end
end

--[[Awacs and Tankers is working with Escorts, really good. Next on the list is a fixed sam site, resupplied with Helos, and when the units are dead in the zone, a resupply will be requested and deliverd with a Helo.]]--

