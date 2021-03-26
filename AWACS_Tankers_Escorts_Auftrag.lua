-- Name: AWACS-Tankers-Auftrag
-- Author: Wildcat (Chandawg)
-- Date Created: 02 Mar 2021
-- Date Modified: 04 Mar 2021
--Succefully used auftrag to create two AirWings, and have them launch an AWACS with Escorts.

RedSqd = {}
BlueSqd = {}

  -- list of possible loiter zones
  -- 0 = Neutral // 1 = Red // 2 = Blue--

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
RedSqd.SU33:AddMissionCapability({AUFTRAG.Type.ESCORT}, 100)
RedSqd.SU33:SetMissionRange(300)

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

BlueSqd.F14B2=SQUADRON:New("Blue F14B", 12, "F-14B Sqd2") --Ops.Squadron#SQUADRON
BlueSqd.F14B2:SetSkill(AI.Skill.EXCELLENT)
BlueSqd.F14B2:SetMissionRange(300)
BlueSqd.F14B2:AddMissionCapability({AUFTRAG.Type.ESCORT}, 100)

BlueSqd.Wizard=SQUADRON:New("Carrier AWACS Blue", 4, "Wizard Carrier AWACS")
BlueSqd.Wizard:SetCallsign(CALLSIGN.AWACS.Wizard, 5)
BlueSqd.Wizard:AddMissionCapability({AUFTRAG.Type.AWACS}, 100) 
BlueSqd.Wizard:SetMissionRange(500)

BlueSqd.Arco=SQUADRON:New("Recovery Tanker Blue", 2, "126ARS")
BlueSqd.Arco:SetCallsign(CALLSIGN.Tanker.Arco,2)
BlueSqd.Arco:AddMissionCapability({AUFTRAG.Type.TANKER}, 100)
BlueSqd.Arco:SetMissionRange(500)

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
