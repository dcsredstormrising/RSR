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

function M.getMissionStatus(playerGroup)
  local weather = getWeather(playerGroup)
  return weather
end

function M.addMenu(playerGroup, restartHours)
    local vec3 = playerGroup:GetVec3()
    local enemyCoalitionNum = 1
    local coalitionNum = playerGroup:GetCoalition()
    local coalitionName = "BLUE"        
    if coalitionNum == 1 then
      coalitionName = "RED"
      enemyCoalitionNum = 2
    end 
    
    local infoMenu = MENU_GROUP:New(playerGroup, "Mission info")
    missionCommands.addCommandForGroup(groupId, "JTAC Status", nil, ctld.getJTACStatus, { unitName })
      MENU_GROUP_COMMAND:New(playerGroup, "Time Until Restart", infoMenu, function()
        local secondsUntilRestart = restartInfo.getSecondsUntilRestart(os.date("*t"), restartHours)
    
        --env.info("**=AW=33COM player group: ".. inspect(playerGroup))
            
        MESSAGE:New(string.format("The server will restart in %s", restartInfo.getSecondsAsString(secondsUntilRestart)), 5):ToGroup(playerGroup)
        --MESSAGE:New(string.format("Your coalition can sling %s more groups of units.", ctld.GetPlayerSpawnGroupCount() - ctld.GroupLimitCount), 5):ToGroup(playerGroup)
    end)
        
    MENU_GROUP_COMMAND:New(playerGroup, "Campaign Status", infoMenu, function()
    MESSAGE:New(string.format("Campaign is in progress for: %s", "1 day"), 20):ToGroup(playerGroup)
    MESSAGE:New(string.format("Number of players online: %i", playerGroup:GetPlayerCount()), 20):ToGroup(playerGroup)        
    end)
    
    MENU_GROUP_COMMAND:New(playerGroup, "Personal Status", infoMenu, function()
        local playerName = playerGroup:GetPlayerName()        
        MESSAGE:New(string.format("Your are on the %s TEAM", coalitionName), 20):ToGroup(playerGroup)
        MESSAGE:New(string.format("Your player name is: %s", playerName), 20):ToGroup(playerGroup)
        MESSAGE:New(string.format("Your callsign is: %s", playerGroup:GetCallsign()), 20):ToGroup(playerGroup)
        MESSAGE:New(string.format("You are in : %s", playerGroup.GroupName), 20):ToGroup(playerGroup)
        MESSAGE:New(string.format("Your have %i lives remaining", csar.getLivesLeft(playerName)), 20):ToGroup(playerGroup)
        MESSAGE:New(string.format("You deployed %i Groups of units.", ctld.countGroupsByPlayer(playerName, coalitionName)), 20):ToGroup(playerGroup)
        MESSAGE:New(string.format("You installed %i SAM systems.", ctld.countAASystemsByPlayer(playerName)), 20):ToGroup(playerGroup)
        MESSAGE:New(string.format("You delivered %i JTACs to the field.", ctld.countJTACsByPlayer(playerName, coalitionName)), 20):ToGroup(playerGroup)
        MESSAGE:New(string.format("You were killed by deebix %i in this campaign", 88), 20):ToGroup(playerGroup)
        MESSAGE:New("You shut down nobody in this round", 20):ToGroup(playerGroup)        
        


MESSAGE:New(text, 20):ToGroup(playerGroup)
        
          
    end)
    
    MENU_GROUP_COMMAND:New(playerGroup, "Coalition Status", infoMenu, function()                
        local coalitionAirbaseNames = inspect(AIRBASE.GetAllAirbaseNames(coalition.side.BLUE, Airbase.Category.AIRDROME)):gsub("%{", ""):gsub("%}", ""):gsub("%\"", "")
        local coalitionFARPNames = AIRBASE.GetAllAirbaseNames(coalition.side.BLUE, Airbase.Category.FARP)
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
          for _,farp in pairs (coalitionFARPNames) do
            farpCount = farpCount + 1
          end
        end
        MESSAGE:New(string.format("%s Team controls %s Airbases", coalitionName, coalitionAirbaseNames), 20):ToGroup(playerGroup)
        MESSAGE:New(string.format("%s Team controls %i FARPs", coalitionName, farpCount), 20):ToGroup(playerGroup)        
        MESSAGE:New(string.format("%s Team SAM sling limit is: %i", coalitionName, samSlingLimit), 20):ToGroup(playerGroup)
        MESSAGE:New(string.format("%s Team has %i SAMs installed", coalitionName, ctld.countAASystemsByCoalition(coalitionNum)), 20):ToGroup(playerGroup)                        
        MESSAGE:New(string.format("%s Team GROUP sling limit is: %i", coalitionName, ctld.GroupLimitCount), 20):ToGroup(playerGroup)
       MESSAGE:New(string.format("%s Team has %i Groups deployed", coalitionName, ctld.getLimitedGroupCount(coalitionNum)), 20):ToGroup(playerGroup)
        MESSAGE:New(string.format("%s Team can still deliver %i JTACs to the field", coalitionName, JTACLimit), 20):ToGroup(playerGroup)
        
        -- Air Resupply        
        local convoyCount = Convoy.GetUpTransports(coalitionNum)
        local convoyOverBaseName = Convoy.GetUpTransportBaseName(coalitionNum)

        if convoyCount > 0 then            
          MESSAGE:New(string.format("%s Team has %i Air Resupply cargo plane in the air over %s",coalitionName,convoyCount,convoyOverBaseName), 20):ToGroup(playerGroup)
        else
          MESSAGE:New(string.format("%s Team does not have any Air Resupply cargo plane in the air",coalitionName), 20):ToGroup(playerGroup)
        end
                
        -- UAVs
        local UAVsCount = 0
        local UAVs = nil
        
        if coalitionNum == coalition.side.BLUE then
          UAVs = SET_GROUP:New():FilterCategoryAirplane():FilterPrefixes( {"Pontiac 1"} ):FilterActive():FilterOnce()
        elseif coalitionNum == coalition.side.RED then
          UAVs = SET_GROUP:New():FilterCategoryAirplane():FilterPrefixes( {"Pontiac 6"} ):FilterActive():FilterOnce()
        end
                
        if UAVs ~= nil then
          UAVs:ForEachGroup(
             function(grp)
               UAVsCount = UAVsCount+1             
             end
          )  
        end
       
        if UAVsCount > 0 then            
          MESSAGE:New(string.format("%s Team has %i UAV RECON Drones in the air",coalitionName,UAVsCount), 20):ToGroup(playerGroup)
        else
          MESSAGE:New(string.format("%s Team does not have any UAV RECON Drones in the air at the moment",coalitionName,UAVsCount), 20):ToGroup(playerGroup)
        end
        
        -- AWACS 
        local AWACsCount = 0
        local AWACs = nil
        
        if coalitionNum == coalition.side.BLUE then
          AWACs = SET_GROUP:New():FilterCategoryAirplane():FilterPrefixes({"Magic 1-1"}):FilterActive():FilterOnce()
        elseif coalitionNum == coalition.side.RED then
          AWACs = SET_GROUP:New():FilterCategoryAirplane():FilterPrefixes({"Overlord 1-1"}):FilterActive():FilterOnce()          
        end        
        local bases = ""
        
        if AWACs ~= nil then
          AWACs:ForEachGroup(
             function(grp)
              local vec3 = grp:GetVec3()
              if vec3 ~= nil then
                local nearBase = utils.getNearestAirbase(vec3, coalitionNum, Airbase.Category.AIRDROME)                
                bases = bases..string.format("%s ", nearBase)
              end
               AWACsCount = AWACsCount+1
             end
          )  
        end
       
        if AWACsCount > 0 then            
          MESSAGE:New(string.format("%s Team has %i AWACs in the air by: %s",coalitionName,AWACsCount, bases), 20):ToGroup(playerGroup)
        else
          MESSAGE:New(string.format("%s Team does not have any AWACs in the air at the moment.",coalitionName,UAVsCount), 20):ToGroup(playerGroup)
        end
    end)
    
    MENU_GROUP_COMMAND:New(playerGroup, "Coalition Intel", infoMenu, function()
        local secondsUntilRestart = restartInfo.getSecondsUntilRestart(os.date("*t"), restartHours)
    
      MESSAGE:New(string.format("Enemy TEAM has %s SAMs", ctld.countAASystemsByCoalition(enemyCoalitionNum)), 20):ToGroup(playerGroup)
      MESSAGE:New(string.format("Enemy Team already has %i Groups of units on the ground", ctld.GetPlayerSpawnGroupCount(enemyCoalitionNum)), 20):ToGroup(playerGroup)
    
    end)
end

return M
