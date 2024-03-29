local restartInfo = require("restartInfo")
local inspect = require("inspect")
local utils = require("utils")
local M = {}

local function getWeather(playerGroup)         
  local vec3 = playerGroup:GetVec3()
  local T
  local Pqfe
  if not alt then
     alt = utils.getLandHeight(vec3)
  end
  
  -- At user specified altitude.
  T,Pqfe=atmosphere.getTemperatureAndPressure({x=vec3.x, y=alt, z=vec3.z})
  
  -- Get pressure at sea level.
  local _,Pqnh=atmosphere.getTemperatureAndPressure({x=vec3.x, y=0, z=vec3.z})
  
  -- Convert pressure from Pascal to hecto Pascal.
  Pqfe=Pqfe/100
  Pqnh=Pqnh/100
  
  -- Pressure unit conversion hPa --> mmHg or inHg
  local _Pqnh=string.format("%.1f mmHg (%.1f inHg)", Pqnh * weathermark.hPa2mmHg, Pqnh * weathermark.hPa2inHg)
  local _Pqfe=string.format("%.1f mmHg (%.1f inHg)", Pqfe * weathermark.hPa2mmHg, Pqfe * weathermark.hPa2inHg)
  
  -- Temperature unit conversion: Kelvin to Celsius or Fahrenheit.
  T=T-273.15
  local _T=string.format('%d C (%d F)', T, weathermark._CelsiusToFahrenheit(T))
  
  -- Get wind direction and speed.
  local Dir,Vel=weathermark._GetWind(vec3, alt)
  
  -- Get Beaufort wind scale.
  local Bn,Bd=weathermark._BeaufortScale(Vel)
  
  -- Formatted wind direction.
  local Ds = string.format('%03d', Dir)
  
  -- Velocity in player units.
  local Vs=string.format('%.1f m/s (%.1f kn)', Vel, Vel * weathermark.mps2knots)
  
  -- Altitude.
  local _Alt=string.format("%d m (%d ft)", alt, alt * weathermark.meter2feet)
  
  local text=""
  text=text..string.format("Altitude %s ASL\n",_Alt)
  text=text..string.format("QFE %.1f hPa = %s\n", Pqfe,_Pqfe)
  text=text..string.format("QNH %.1f hPa = %s\n", Pqnh,_Pqnh)
  text=text..string.format("Temperature %s\n",_T)
  if Vel > 0 then
     text=text..string.format("Wind from %s at %s (%s)", Ds, Vs, Bd)
  else
     text=text.."No wind"
  end
  return text
end

local function getCampaignStatus(playerGroup, restartHours)
  local secondsUntilRestart = restartInfo.getSecondsUntilRestart(os.date("*t"), restartHours)
  local playerCount = 0  
  local bluePlayers = coalition.getPlayers(2)
  local redPlayers = coalition.getPlayers(1)
  playerCount = #bluePlayers +  #redPlayers
  
  return  "Campaign Status:\n"..         
          "The server will restart in "..restartInfo.getSecondsAsString(secondsUntilRestart).."\n"..
          "Campaign started on: " ..utils.getDataFromCampaign("CampaignStartDateTime").."\n"..
          "There is "..playerCount.." players online\n\n"
end

local function getPlayerStatus(playerGroup,playerName,coalitionName)
  return  "Personal Status:\n"..         
          "You are on the "..coalitionName.." TEAM\n"..
          "Your player name is: "..playerName.."\n"..
          "Your callsign is: "..playerGroup:GetCallsign().."\n"..
          "You are in: "..playerGroup.GroupName.."\n"..
          "You have "..csar.getLivesLeft(playerName).." lives remaining\n"..
          "You deployed "..ctld.countGroupsByPlayer(playerName, coalitionName).." Groups of units\n"..
          "You installed "..ctld.countAASystemsByPlayer(playerName).." SAM systems\n"..
          "You delivered "..ctld.countJTACsByPlayer(playerName, coalitionName).." JTACs to the field\n\n"..
          "Weather at your location:\n"..
          getWeather(playerGroup).."\n\n"
end

local function getCoalitionStatus(playerGroup,coalitionNum,coalitionName)
  -- Moose has a bug in catogories documentation.  No such thing as Airbase.Category.FARP  
  --[Airbase.Category.AIRDROME]="Airdrome",
  --[Airbase.Category.HELIPAD]="Helipad",
  --[Airbase.Category.SHIP]="Ship",  -- this will never work
  local coalitionAirbaseNames = inspect(AIRBASE.GetAllAirbaseNames(coalitionNum, Airbase.Category.AIRDROME)):gsub("%{", ""):gsub("%}", ""):gsub("%\"", "")
  local coalitionFARPNames = AIRBASE.GetAllAirbaseNames(coalitionNum, Airbase.Category.HELIPAD)
    
  -- get ships
  local ships = SET_GROUP:New():FilterCategoryShip():FilterCoalitions(coalitionName:lower()):FilterActive(true):FilterOnce()  
  local shipCount = ships:Count()  
  local farpCount = 0  
  local samSlingLimit = 0
  local JTACLimit = 0
        
  if coalitionNum == coalition.side.BLUE then
    samSlingLimit = ctld.AASystemLimitBLUE
  elseif coalitionNum == coalition.side.RED then
    samSlingLimit = ctld.AASystemLimitRED
  end
        
  if coalitionNum == coalition.side.BLUE then
    JTACLimit = ctld.JTAC_LIMIT_BLUE
  elseif coalitionNum == coalition.side.RED then
    JTACLimit = ctld.JTAC_LIMIT_RED
  end
                
  if coalitionFARPNames ~= nil then   
    for _,item in pairs (coalitionFARPNames) do
      farpCount = farpCount + 1
    end
  end
    
  -- Air Resupply
  local convoyCount = Convoy.GetUpTransports(coalitionNum)
  local convoyOverBaseName = Convoy.GetUpTransportBaseName(coalitionNum)
  local airResupplyText = ""

  if convoyCount > 0 then            
    airResupplyText = string.format("%s Team has %i Air Resupply cargo plane in the air over %s",coalitionName,convoyCount,convoyOverBaseName)
  else
    airResupplyText = string.format("%s Team does not have any Air Resupply cargo plane in the air",coalitionName)
  end
  
  -- UAVs
  local UAVsCount = 0
  local UAVs = nil
  local uavText = ""
        
  if coalitionNum == coalition.side.BLUE then
    UAVs = SET_GROUP:New():FilterCategoryAirplane():FilterPrefixes( {"Pontiac 1"} ):FilterActive():FilterOnce()
  elseif coalitionNum == coalition.side.RED then
    UAVs = SET_GROUP:New():FilterCategoryAirplane():FilterPrefixes( {"Pontiac 6"} ):FilterActive():FilterOnce()
  end
  
  local uavBases = ""
        
  if UAVs ~= nil then
    UAVs:ForEachGroup(
      function(grp)
        local vec = grp:GetVec2()
        if vec ~= nil then
          local uavNearBase = utils.getNearestAirbase(vec, coalitionNum, Airbase.Category.AIRDROME)                
          uavBases = uavBases..string.format("%s ", uavNearBase)
        end
        UAVsCount = UAVsCount+1
      end
     )  
  end
       
  if UAVsCount > 0 then            
    uavText = string.format("%s Team has %i UAV RECON Drones in the air by: %s",coalitionName,UAVsCount, uavBases)    
  else
    uavText = string.format("%s Team does not have any UAV RECON Drones in the air at the moment",coalitionName,UAVsCount)
  end
  
  -- AWACS 
  local AWACsCount = 0
  local AWACs = nil
  local AWACsText = ""
        
  if coalitionNum == coalition.side.BLUE then
    AWACs = SET_GROUP:New():FilterCategoryAirplane():FilterPrefixes({"Magic 1-1"}):FilterActive():FilterOnce()
  elseif coalitionNum == coalition.side.RED then
    AWACs = SET_GROUP:New():FilterCategoryAirplane():FilterPrefixes({"Overlord 1-1"}):FilterActive():FilterOnce()          
  end        
  
  local AWACsBases = ""
        
  if AWACs ~= nil then
    AWACs:ForEachGroup(
      function(grp)
        local vec = grp:GetVec2()
        if vec ~= nil then
          local AWACsNearBase = utils.getNearestAirbase(vec, coalitionNum, Airbase.Category.AIRDROME)                
          AWACsBases = AWACsBases..string.format("%s ", AWACsNearBase)
        end
        AWACsCount = AWACsCount+1
      end
     )  
  end
       
  if AWACsCount > 0 then            
    AWACsText = string.format("%s Team has %i AWACs in the air by: %s",coalitionName,AWACsCount, AWACsBases)
  else
    AWACsText = string.format("%s Team does not have any AWACs in the air at the moment.",coalitionName,UAVsCount)
  end
        
  return  "Coalition Status:\n"..                   
          coalitionName.." Team\'s SAM sling limit is: "..samSlingLimit.."\n"..
          coalitionName.." Team has "..ctld.countAASystemsByCoalition(coalitionNum).." SAMs installed\n".. 
          coalitionName.." Team GROUP sling limit is "..ctld.GroupLimitCount.."\n".. 
          coalitionName.." Team has "..ctld.getLimitedGroupCount(coalitionName).." Groups deployed\n"..          
          coalitionName.." Team can still deliver "..JTACLimit.." JTACs to the field\n"..
          airResupplyText.."\n"..
          uavText.."\n"..
          AWACsText.."\n"..
          coalitionName.." Team Navy has: "..shipCount.." Ships sailing\n".. 
          coalitionName.." Team owns: "..farpCount.." FARPs\n".. 
          coalitionName.." Team controls: "..coalitionAirbaseNames.."\n\n"
end

local function getIntelStatus(enemyCoalitionNum, enemyCoalitionName)  
  local ships = SET_GROUP:New():FilterCategoryShip():FilterCoalitions(enemyCoalitionName:lower()):FilterActive(true):FilterOnce()  
  local shipCount = ships:Count()
  
  return  "Coalition Intel:\n"..
          "Enemy Navy has: "..shipCount.." Ships sailing\n"..         
          "Enemy TEAM has "..ctld.countAASystemsByCoalition(enemyCoalitionNum).." SAMs\n"..
          --"Enemy TEAM was able to sling "..ctld.getLimitedGroupCount(enemyCoalitionName).." group of units\n"..          
          " \n\n"    
end

function M.getMissionStatus(playerGroup, restartHours)  
  local enemyCoalitionNum = 1
  local enemyCoalitionName = "RED"
  local coalitionNum = playerGroup:GetCoalition()
  local coalitionName = "BLUE"        
  if coalitionNum == 1 then
    coalitionName = "RED"
    enemyCoalitionNum = 2
    enemyCoalitionName = "BLUE"
  end
  local playerName = playerGroup:GetPlayerName()  
  local campaignStatus = getCampaignStatus(playerGroup, restartHours)
  local playerStatus = getPlayerStatus(playerGroup, playerName, coalitionName)
  local coalitionStatus = getCoalitionStatus(playerGroup,coalitionNum,coalitionName)
  local intelStatus = getIntelStatus(enemyCoalitionNum,enemyCoalitionName)
  return " \n"..campaignStatus..playerStatus..coalitionStatus..intelStatus
end

return M