local restartInfo = require("restartInfo")
local inspect = require("inspect")
local ctld = require("ctld")

local M = {}

function M.addMenu(playerGroup, restartHours)
    local enemyCoalitionNum = 1
    local coalitionNum = playerGroup:GetCoalition()
    local coalitionName = "BLUE"        
    if coalitionNum == 1 then
      coalitionName = "RED"
      enemyCoalitionNum = 2
    end 
    
    local infoMenu = MENU_GROUP:New(playerGroup, "Mission info")
    MENU_GROUP_COMMAND:New(playerGroup, "Time Until Restart", infoMenu, function()
        local secondsUntilRestart = restartInfo.getSecondsUntilRestart(os.date("*t"), restartHours)
    
        --env.info("**=AW=33COM player group: ".. inspect(playerGroup))
            
        MESSAGE:New(string.format("The server will restart in %s", restartInfo.getSecondsAsString(secondsUntilRestart)), 5):ToGroup(playerGroup)
        --MESSAGE:New(string.format("Your coalition can sling %s more groups of units.", ctld.GetPlayerSpawnGroupCount() - ctld.GroupLimitCount), 5):ToGroup(playerGroup)
    end)
        
    MENU_GROUP_COMMAND:New(playerGroup, "Campaign Settings", infoMenu, function()
        local secondsUntilRestart = restartInfo.getSecondsUntilRestart(os.date("*t"), restartHours)
            
    MESSAGE:New(string.format("Campaign started on: %s", restartInfo.getSecondsAsString(secondsUntilRestart)), 5):ToGroup(playerGroup)
    MESSAGE:New(string.format("Campaign is in progress for: %s", restartInfo.getSecondsAsString(secondsUntilRestart)), 5):ToGroup(playerGroup)
    MESSAGE:New(string.format("Campaign temperature and pressure: %s", restartInfo.getSecondsAsString(secondsUntilRestart)), 5):ToGroup(playerGroup)
    MESSAGE:New(string.format("Campaign weather: %s", restartInfo.getSecondsAsString(secondsUntilRestart)), 5):ToGroup(playerGroup)
    MESSAGE:New(string.format("Number of players online: %i", playerGroup:GetPlayerCount()), 5):ToGroup(playerGroup)        
    end)
    
    MENU_GROUP_COMMAND:New(playerGroup, "Personal Status", infoMenu, function()
        local playerName = playerGroup:GetPlayerName()
        MESSAGE:New(string.format("Your are on the %s TEAM", coalitionName), 5):ToGroup(playerGroup)
        MESSAGE:New(string.format("Your player name is: %s", playerName), 5):ToGroup(playerGroup)
        MESSAGE:New(string.format("Your callsign is: %s", playerGroup:GetCallsign()), 5):ToGroup(playerGroup)
        MESSAGE:New(string.format("You are in : %s", playerGroup.GroupName), 5):ToGroup(playerGroup)
        MESSAGE:New(string.format("Your have %i lives remaining", csar.getLivesLeft(playerName)), 5):ToGroup(playerGroup)        
        MESSAGE:New(string.format("You slung %i groups of units.", ctld.countGroupsByPlayer(playerName)), 5):ToGroup(playerGroup)
        MESSAGE:New(string.format("You slung %i SAM systems.", ctld.countAASystemsByPlayer(playerName)), 5):ToGroup(playerGroup)        
        MESSAGE:New(string.format("You delivered %i JTACs to the field.", ctld.countJTACsByPlayer(playerName)), 5):ToGroup(playerGroup)
        MESSAGE:New(string.format("You were killed by deebix %i times.", 88), 5):ToGroup(playerGroup)
        local windDirection, windStrength = utils.getWind(point)
        MESSAGE:New(string.format("Your wind direction: %s, and strength: %s", windDirection, windStrength), 5):ToGroup(playerGroup)    
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
        
        MESSAGE:New(string.format("%s Team is winning.", coalitionName), 5):ToGroup(playerGroup)
        MESSAGE:New(string.format("%s Team controls %s Airbases", coalitionName, coalitionAirbaseNames), 5):ToGroup(playerGroup)
        MESSAGE:New(string.format("%s Team controls %i FARPs", coalitionName, farpCount), 5):ToGroup(playerGroup)        
        MESSAGE:New(string.format("%s Team SAM sling limit is: %i", coalitionName, samSlingLimit), 5):ToGroup(playerGroup)
        MESSAGE:New(string.format("%s Team already has %i SAMs", coalitionName, ctld.countAASystemsByCoalition(coalitionNum)), 5):ToGroup(playerGroup)                        
        MESSAGE:New(string.format("%s Team GROUP sling limit is: %i", coalitionName, ctld.GroupLimitCount), 5):ToGroup(playerGroup)
        MESSAGE:New(string.format("%s Team has already %i Groups", coalitionName, ctld.GetPlayerSpawnGroupCount(coalitionNum)), 5):ToGroup(playerGroup)
        MESSAGE:New(string.format("%s Team can still deploy %1 JTACs to the field: %i", coalitionName, JTACLimit), 5):ToGroup(playerGroup)
        
        -- Air Resupply
        local convoyCount = Convoy.GetUpTransports(coalitionNum)
        local convoyOverBaseName = Convoy.GetUpTransportBaseName(coalitionNum)

        if convoyCount > 0 then            
          MESSAGE:New(string.format("%s Team has %i Air Resupply cargo plane in the air over %s.",coalitionName,convoyCount,convoyOverBaseName), 5):ToGroup(playerGroup)
        else
          MESSAGE:New(string.format("%s Team does not have any Air Resupply cargo plane in the air.",coalitionName), 5):ToGroup(playerGroup)
        end
        
        -- UAVs
        local UAVsCount = 0
        local UAVs = {}
        
        if coalition == coalition.side.BLUE then
          UAVs = SET_GROUP:New():FilterCategoryAirplane():FilterPrefixes( {"Pontiac 1"} ):FilterActive():FilterOnce()
        elseif coalition == coalition.side.RED then
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
          MESSAGE:New(string.format("%s Team has %i UAV RECON Drones in the air.",coalitionName,UAVsCount), 5):ToGroup(playerGroup)
        else
          MESSAGE:New(string.format("%s Team does not have any UAV RECON Drones in the air at the moment.",coalitionName,UAVsCount), 5):ToGroup(playerGroup)
        end
        
        -- AWACS 
        local AWACsCount = 0
        local AWACs = {}
        
        if coalition == coalition.side.BLUE then
          AWACs = SET_GROUP:New():FilterCategoryAirplane():FilterPrefixes( {"AWACS Blue"} ):FilterActive():FilterOnce()
        elseif coalition == coalition.side.RED then
          AWACs = SET_GROUP:New():FilterCategoryAirplane():FilterPrefixes( {"AWACS Red"} ):FilterActive():FilterOnce()
        end
        
        if AWACs ~= nil then
          AWACs:ForEachGroup(
             function(grp)
               AWACsCount = AWACsCount+1             
             end
          )  
        end
       
        if AWACsCount > 0 then            
          MESSAGE:New(string.format("%s Team has %i AWACs in the air.",coalitionName,UAVsCount), 5):ToGroup(playerGroup)
        else
          MESSAGE:New(string.format("%s Team does not have any AWACs in the air at the moment.",coalitionName,UAVsCount), 5):ToGroup(playerGroup)
        end
    end)
    
    MENU_GROUP_COMMAND:New(playerGroup, "Coalition Intel", infoMenu, function()
        local secondsUntilRestart = restartInfo.getSecondsUntilRestart(os.date("*t"), restartHours)
    
      MESSAGE:New(string.format("Enemy TEAM has %s SAMs", ctld.countAASystemsByCoalition(enemyCoalitionNum)), 5):ToGroup(playerGroup)
      MESSAGE:New(string.format("Enemy Team already has %i Groups of units on the ground", ctld.GetPlayerSpawnGroupCount(enemyCoalitionNum)), 5):ToGroup(playerGroup)
    
    end)
end

return M
