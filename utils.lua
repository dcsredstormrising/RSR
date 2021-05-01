local logging = require("logging")
local log = logging.Logger:new("utils")
local JSON = require("JSON")
local inspect = require("inspect")
local campaignFileName = "CampaignData.json"

local M = {}


function M.getFilePath(filename)
    if env ~= nil then
        return lfs.writedir() .. [[Scripts\RSR\]] .. filename
    else
        return filename
    end
end

local sideLookupTable

local function populateSideLookupTable()
    if sideLookupTable ~= nil then
        return
    end
    sideLookupTable = {
        bySide = {
            [coalition.side.RED] = "red",
            [coalition.side.BLUE] = "blue",
            [coalition.side.NEUTRAL] = "neutral",
        },
        byName = {
            red = coalition.side.RED,
            blue = coalition.side.BLUE,
            neutral = coalition.side.NEUTRAL,
        }
    }
end

function M.getSideName(side)
    populateSideLookupTable()
    return sideLookupTable.bySide[side]
end

function M.getSide(sideName)
    populateSideLookupTable()
    return sideLookupTable.byName[sideName]
end

function M.startswith(string, prefix)
    if string:sub(1, #prefix) == prefix then
        return true
    end
    return false
end

local function split(string, sep)
    local fields = {}
    local pattern = string.format("([^%s]+)", sep)
    string:gsub(pattern, function(c)
        fields[#fields + 1] = c
    end)
    return fields
end

-- Matches a base name against a prefix
-- is fairly generous in that you only need the distinguishing prefix on the group
-- with each word being treated independently
function M.matchesBaseName(baseName, prefix)
    if prefix == nil then
        return false
    end
    if M.startswith(baseName, prefix) then
        return true
    end

    -- special case for typos!
    if prefix == "Sukumi" and baseName == "Sukhumi-Babushara" then
        return true
    end

    local baseNameParts = split(baseName, "-")
    local prefixParts = split(prefix, "-")

    if #baseNameParts < #prefixParts then
        return false
    end
    for i = 1, #prefixParts do
        local baseNamePart = baseNameParts[i]
        local groupPrefixPart = prefixParts[i]
        if M.startswith(baseNamePart, groupPrefixPart) == false then
            return false
        end
    end
    return true
end

function M.getPlayerNameFromGroupName(groupName)
    -- match the inside of the part in parentheses at the end of the group name if present
    -- this is the other half of the _groupName construction in ctld.spawnCrateGroup
    return string.match(groupName, "%((.+)%)$")
end

function M.getBaseAndSideNamesFromGroupName(groupName)
    local blueIndex = string.find(groupName:lower(), " blue ")
    local redIndex = string.find(groupName:lower(), " red ")
    if blueIndex ~= nil then
        return groupName:sub(1, blueIndex - 1), "blue"
    end
    if redIndex ~= nil then
        return groupName:sub(1, redIndex - 1), "red"
    end
end

--extract base name from first character of zone name to first character of suffix - 1 (idx - 1, most likely white space)
function M.getBaseNameFromZoneName(zoneName, suffix)
    --mr: will LUA wildcard * work with when passed with suffix?
    -- e.g. logisticsManager.lua: utils.getBaseNameFromZoneName(logisticsZoneName, "RSRlogisticsZone*") = "MM75 RSRlogisticsZone 01" ?
    local idx = zoneName:lower():find(" " .. suffix:lower())
    if idx == nil then
        return nil
    end
    return zoneName:sub(1, idx - 1)
end

function M.getRestartHours(firstRestart, missionDuration)
    local restartHours = {}
    local nextRestart = firstRestart
    while nextRestart < 24 do
        table.insert(restartHours, nextRestart)
        nextRestart = nextRestart + missionDuration
    end
    return restartHours
end

function M.round(number, roundTo)
    return math.floor((number + 0.5 * roundTo) / roundTo) * roundTo
end

-- MGRS coordinate with no UTM and only 10km square e.g. LP49
function M.posToMapGrid(position)

    -- .p as coord.LOtoLL requires x,y,z format
    local _MGRStable = coord.LLtoMGRS(coord.LOtoLL(position.p))
    --log:info("_MGRStable: $1",_MGRStable)

    -- DCS drops leading 0 for 10km map grids
    -- e.g. Vazani @ NM00: MGRStable = { Easting = 2566, MGRSDigraph = "NM", Northing = 9426, UTMZone = "38T" }
    local _easting10kmGrid
    if string.len(_MGRStable.Easting) < 5 then
        _easting10kmGrid = 0
    else
        _easting10kmGrid = string.match(_MGRStable.Easting, "(%d)%d%d%d%d$")
    end

    local _northing10kmGrid
    if string.len(_MGRStable.Northing) < 5 then
        _northing10kmGrid = 0
    else
        _northing10kmGrid = string.match(_MGRStable.Northing, "(%d)%d%d%d%d$")
    end

    -- first digit of 5 digit MGRS Easting and Northing more accurate for 10km grid than MIST method of rounding-up MGRS coordinates
    local _MapGrid = _MGRStable.MGRSDigraph .. _easting10kmGrid .. _northing10kmGrid
    --log:info("_MapGrid: $1",_MapGrid)

    return _MapGrid
end

-- based on ctld.isInfantry
local function isInfantry(unit)
    local typeName = string.lower(unit:getTypeName() .. "")
    local soldierType = { "infantry", "paratrooper", "stinger", "manpad", "mortar" }

    for _, value in pairs(soldierType) do
        if string.match(typeName, value) then
            return true
        end
    end

    return false

end

function M.setGroupControllerOptions(group)
    -- delayed 2 second to work around bug (as per ctld.addEWRTask and ctld.orderGroupToMoveToPoint)
    timer.scheduleFunction(function(_group)
        -- make sure nothing "bad" happened in time since spawn
        if not _group:isExist() or #_group:getUnits() < 1 then
            return
        end
        local controller = _group:getController()
        controller:setOption(AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.AUTO)
        controller:setOption(AI.Option.Ground.id.ROE, AI.Option.Ground.val.ROE.OPEN_FIRE)
        controller:setOption(AI.Option.Ground.id.DISPERSE_ON_ATTACK, 0)
        local leader = group:getUnit(1)
        local position = leader:getPoint()
        local formation = isInfantry(leader) and AI.Task.VehicleFormation.CONE or AI.Task.VehicleFormation.OFF_ROAD
        local mission = {
            id = 'Mission',
            params = {
                route = {
                    points = {
                        [1] = {
                            action = formation,
                            x = position.x,
                            y = position.z,
                            type = 'Turning Point'
                        }
                    }
                },
            },
        }
        controller:setTask(mission)
        --env.info("Set controller options for " .. _group:getName())
    end, group, timer.getTime() + 2)
end


--searches for FARP name in baseOwnership nested table to determine currently assigned side
--mr: find more efficient way to transvere nested table
function M.getCurrFARPside (_FARPname)
    local _bOFARPside = "FARPnotFound"
    for _, _b in pairs(baseOwnership.FARPs.red) do
        if _b == _FARPname then
            _bOFARPside = "red"
            break
        end
    end

    if _bOFARPside == "FARPnotFound" then
        for _, _b in pairs(baseOwnership.FARPs.blue) do
            if _b == _FARPname then
                _bOFARPside = "blue"
                break
            end
        end
    end

    if _bOFARPside == "FARPnotFound" then
        --log:error("$1 FARP not found in 'baseOwnership.FARPs' sides.",_FARPname)
        for _, _b in pairs(baseOwnership.FARPs.neutral) do
            if _b == _FARPname then
                _bOFARPside = "neutral"
                break
            end
        end
    end

    return _bOFARPside
end

function M.getCurrABside (_ABname)
    local _bOABside = "ABnotFound"
    for _, _b in pairs(baseOwnership.Airbases.red) do
        if _b == _ABname then
            _bOABside = "red"
            break
        end
    end

    if _bOABside == "ABnotFound" then
        for _, _b in pairs(baseOwnership.Airbases.blue) do
            if _b == _ABname then
                _bOABside = "blue"
                break
            end
        end
    end

    if _bOABside == "ABnotFound" then
        --log:error("$1 Airbase not found in 'baseOwnership.Airbases' sides.",_ABname)
        for _, _b in pairs(baseOwnership.Airbases.neutral) do
            if _b == _ABname then
                _bOABside = "neutral"
                break
            end
        end
    end

    return _bOABside
end

function M.removeFARPownership (_FARPname)
    local _FARPremoved = false
    for _k, _b in pairs(baseOwnership.FARPs.red) do
        if _b == _FARPname then
            table.remove(baseOwnership.FARPs.red, _k)
            _FARPremoved = true
            break
        end
    end

    if not _FARPremoved then
        for _k, _b in pairs(baseOwnership.FARPs.blue) do
            if _b == _FARPname then
                table.remove(baseOwnership.FARPs.blue, _k)
                _FARPremoved = true
                break
            end
        end
    end

    if not _FARPremoved then
        for _k, _b in pairs(baseOwnership.FARPs.neutral) do
            if _b == _FARPname then
                table.remove(baseOwnership.FARPs.neutral, _k)
                _FARPremoved = true
                break
            end
        end
    end

    if not _FARPremoved then
        log:error("$1 FARP not found in 'baseOwnership.FARPs' sides. No ownership record to remove.", _FARPname)
    end
end

function M.removeABownership (_ABname)
    local _ABremoved = false
    for _k, _b in pairs(baseOwnership.Airbases.red) do
        if _b == _ABname then
            table.remove(baseOwnership.Airbases.red, _k)
            _ABremoved = true
            break
        end
    end

    if not _ABremoved then
        for _k, _b in pairs(baseOwnership.Airbases.blue) do
            if _b == _ABname then
                table.remove(baseOwnership.Airbases.blue, _k)
                _ABremoved = true
                break
            end
        end
    end

    if not _ABremoved then
        for _k, _b in pairs(baseOwnership.Airbases.neutral) do
            if _b == _ABname then
                table.remove(baseOwnership.Airbases.neutral, _k)
                _ABremoved = true
                break
            end
        end
    end

    if not _ABremoved then
        log:error("$1 Airbase not found in 'baseOwnership.Airbases' sides. No ownership record to remove.", _ABname)
    end
end

function M.baseCaptureZoneToNameSideType(_zone)
    local _zoneName = _zone.name
    --"MM75 RSRbaseCaptureZone FARP" = "MM75" i.e. from whitepace and RSR up
    local _RSRbaseCaptureZoneName = string.match(_zoneName, ("^(.+)%sRSR"))

    log:info("_RSRbaseCaptureZoneName: $1",_RSRbaseCaptureZoneName)

    --"MM75 RSRbaseCaptureZone FARP" = "FARP"
    local _baseType = string.match(_zoneName, ("%w+$"))
    local _baseTypes = ""

    if _baseType == nil then
        log:error("RSR MIZ SETUP: $1 RSRbaseCaptureZone Trigger Zone name does not contain 'Airbase' or 'FARP' e.g. 'MM75 RSRbaseCaptureZone FARP'", _RSRbaseCaptureZoneName)
    else
        _baseTypes = _baseTypes .. _baseType .. "s"
    end

    local _zoneColor = _zone.color
    local _baseSide = "ERROR"

    local _whiteInitZoneCheck = 0
    if _zoneColor[1] == 1 then
        _baseSide = "red"
        _whiteInitZoneCheck = _whiteInitZoneCheck + 1
    elseif _zoneColor[3] == 1 then
        _baseSide = "blue"
        _whiteInitZoneCheck = _whiteInitZoneCheck + 1
    elseif _zoneColor[2] == 1 then
        --green
        _baseSide = "neutral"
        _whiteInitZoneCheck = _whiteInitZoneCheck + 1
    end

    if _baseSide == "ERROR" then
        if _whiteInitZoneCheck == 3 then
            log:error("RSR MIZ SETUP: $1 $2 Trigger Zone color not changed from white. Setting as neutral", _RSRbaseCaptureZoneName, _zoneColor)
        elseif _whiteInitZoneCheck > 1 then
            log:error("RSR MIZ SETUP: $1 $2 Trigger Zone color not correctly set to only red, blue or green. Setting as neutral", _RSRbaseCaptureZoneName, _zoneColor)
        end
        _baseSide = "neutral"
    end
    return { _RSRbaseCaptureZoneName, _baseSide, _baseTypes }
end

function M.carrierActivateForBaseWhenOwnedBySide(_zone)
    local _zoneName = _zone.name
    --"Novorossiysk RSRcarrierActivate Group1" = "Novorossiysk" i.e. from whitepace and RSR up
    local _RSRcarrierActivateForBase = string.match(_zoneName, ("^(.+)%sRSR"))

    --log:info("_RSRcarrierActivateForBase: $1",_RSRcarrierActivateForBase)

    --"Novorossiysk RSRcarrierActivate Group1" = "Group1"
    local _carrierGroup = string.match(_zoneName, ("%w+$"))

    local _zoneColor = _zone.color
    local _whenBaseOwnedBySide = "ERROR"

    local _whiteInitZoneCheck = 0
    if _zoneColor[1] == 1 then
        _whenBaseOwnedBySide = "red"
        _whiteInitZoneCheck = _whiteInitZoneCheck + 1
    elseif _zoneColor[3] == 1 then
        _whenBaseOwnedBySide = "blue"
        _whiteInitZoneCheck = _whiteInitZoneCheck + 1
    elseif _zoneColor[2] == 1 then
        --green
        _whenBaseOwnedBySide = "neutral"
        _whiteInitZoneCheck = _whiteInitZoneCheck + 1
    end

    if _whenBaseOwnedBySide == "ERROR" then
        if _whiteInitZoneCheck == 3 then
            log:error("RSR MIZ SETUP: $1 Trigger Zone color $2 not chnaged from white to only red or blue. Setting 'when owned by requirement' to neutral.  Carriers will NEVER activate.", _zoneName, _zoneColor)
        elseif _whiteInitZoneCheck > 1 then
            log:error("RSR MIZ SETUP: $1 Trigger Zone color $2 not correctly set to only red or blue. Setting 'when owned by requirement' to neutral.  Carriers will NEVER activate.", _zoneName, _zoneColor)
        end
        _whenBaseOwnedBySide = "neutral"
    end
    return { _carrierGroup, _RSRcarrierActivateForBase, _whenBaseOwnedBySide }
end

-- will check if LC alive not just nil i.e. StaticObject.getLife() and clean-up list if not alive
function M.getAliveLogisticsCentreforBase(_airbaseORfarpORfob)

    local _aliveLCobj
    local _LCfound = false
    local _foundLCbaseRef = "NoBase" --debug
    local _foundLCsideRef = "NoSide" --debug
    for _refLCsideName, _baseTable in pairs(ctld.logisticCentreObjects) do
        for _refLCbaseName, _LCobj in pairs(_baseTable) do
            if _refLCbaseName == _airbaseORfarpORfob then

                --log:info("_refLCbaseName: $1, _LCobj: $2",_refLCbaseName, _LCobj)

                if _LCobj ~= nil then

                    if StaticObject.getLife(_LCobj) == 0 then
                        --10000 = starting command centre static object life
                        ctld.logisticCentreObjects[_refLCsideName][_refLCbaseName] = nil
                        local _LCmarkerID = ctld.logisticCentreMarkerID[_refLCsideName][_refLCbaseName]
                        trigger.action.removeMark(_LCmarkerID)

                    else
                        if _LCfound then
                            -- should not occur
                            log:error("DUPLICATE LC record: _foundLCbaseRef: $1, _foundLCsideRef: $2, _refLCbaseName: $3, _refLCsideName: 4", _foundLCbaseRef, _foundLCsideRef, _refLCbaseName, _refLCsideName)
                        end

                        _aliveLCobj = _LCobj

                        --debug
                        _LCfound = true
                        _foundLCbaseRef = _refLCbaseName
                        _foundLCsideRef = _refLCsideName

                        local _LCname = _LCobj:getName()
                        --log:info("_LCname: $1",_LCname)

                        --"Krymsk Logistics Centre #001 red" = "red"
                        local _derivedLCsideName = string.match(_LCname, ("%w+$"))

                        --"Sochi Logistics Centre #001 red" = "Sochi" i.e. from whitepace and 'Log' up
                        local _derivedLCbaseNameOrGrid = string.match(_LCname, ("^(.+)%sLog"))

                        -- run checks
                        if _refLCsideName ~= _derivedLCsideName then
                            log:error("Reference LC side in ctld.logisticCentreObjects (_refLCsideName: $1) and derived LC side by name (_derivedLCsideName: $2) mistmatch", _refLCsideName, _derivedLCsideName)
                        end

                        if _airbaseORfarpORfob ~= _derivedLCbaseNameOrGrid then
                            log:error("Passed LC base (_airbaseORfarpORfob: $1) and derived base from LC name (_derivedLCbaseNameOrGrid: $2) mistmatch", _refLCsideName, _derivedLCsideName)
                        end
                    end
                end
            end
        end
    end
    return _aliveLCobj
end

-- functions below added by =AW=33COM
function M.findUnitsInCircle(center, radius)
    local result = {}
    local units = mist.DBs.unitsByName -- local copy for faster execution
    for name, _ in pairs(units) do
        local unit = Unit.getByName(name)
        if not unit then 
            unit = StaticObject.getByName(name)
        end
        if unit then 
            local pos = unit:getPosition().p
            if pos then -- you never know O.o
                distanceFromCenter = ((pos.x - center.x)^2 + (pos.z - center.z)^2)^0.5
                if distanceFromCenter <= radius then
                    result[name] = unit
                end
            end
        end
    end
    return result
end

function M.getAvgGroupPos(groupName) -- stolen from Mist and corrected
  local group = groupName -- sometimes this parameter is actually a group
  if type(groupName) == 'string' and Group.getByName(groupName) and Group.getByName(groupName):isExist() == true then
    group = Group.getByName(groupName)
  end
  local units = {}
  for i = 1, group:getSize() do
    table.insert(units, group:getUnit(i):getName())
  end
  return mist.getAvgPos(units)
end

-- Makes a group move to a specific waypoint at a specific speed
function M.moveGroupTo(groupName, pos, speed)
    env.info("veaf.moveGroupTo(groupName=" .. groupName .. ", speed=".. speed)
    env.info("pos="..veaf.vecToString(pos))

  local unitGroup = Group.getByName(groupName)
    if unitGroup == nil then
        env.info("veaf.moveGroupTo: " .. groupName .. ' not found')
    return false
  end
    
  -- new route point
  local newWaypoint = {
    ["action"] = "Turning Point",
    ["alt"] = 0,
    ["alt_type"] = "BARO",
    ["form"] = "Turning Point",
    ["speed"] = speed,
    ["type"] = "Turning Point",
    ["x"] = pos.x,
    ["y"] = pos.z,
  }
  -- order group to new waypoint
  mist.goRoute(groupName, {newWaypoint})
  return true
end

-- Add a unit to the <group> on a suitable point in a <dispersion>-sized circle around a spot
function M.addUnit(group, spawnSpot, dispersion, unitType, unitName, skill)
    local unitPosition = M.findPointInZone(spawnSpot, dispersion, false)
    if unitPosition ~= nil then
        table.insert(
            group,
            {
                ["x"] = unitPosition.x,
                ["y"] = unitPosition.y,
                ["type"] = unitType,
                ["name"] = unitName,
                ["heading"] = 0,
                ["skill"] = skill
            }
        )
    else
        env.info("cannot find a suitable position for unit "..unitType)
    end
end

-- Find a suitable point for spawning a unit in a <dispersion>-sized circle around a spot
function M.findPointInZone(spawnSpot, dispersion, isShip)
    local unitPosition
    local tryCounter = 1000
    
    repeat -- Place the unit in a "dispersion" ft radius circle from the spawn spot
        unitPosition = mist.getRandPointInCircle(spawnSpot, dispersion)
        local landType = land.getSurfaceType(unitPosition)
        tryCounter = tryCounter - 1
    until ((isShip and landType == land.SurfaceType.WATER) or (not(isShip) and (landType == land.SurfaceType.LAND or landType == land.SurfaceType.ROAD or landType == land.SurfaceType.RUNWAY))) or tryCounter == 0
    if tryCounter == 0 then
        return nil
    else
        return unitPosition
    end
end

-- Returns the wind direction (from) and strength.
function M.getWind(point)

    -- Get wind velocity vector.
    local windvec3  = atmosphere.getWind(point)
    local direction = math.floor(math.deg(math.atan2(windvec3.z, windvec3.x)))
    
    if direction < 0 then
      direction = direction + 360
    end
    
    -- Convert TO direction to FROM direction. 
    if direction > 180 then
      direction = direction-180
    else
      direction = direction+180
    end
    
    -- Calc 2D strength.
    local strength=math.floor(math.sqrt((windvec3.x)^2+(windvec3.z)^2))
    
    -- Debug output.
    --env.info(string.format("Wind data: point x=%.1f y=%.1f, z=%.1f", point.x, point.y,point.z))
    --env.info(string.format("Wind data: wind  x=%.1f y=%.1f, z=%.1f", windvec3.x, windvec3.y,windvec3.z))
    --env.info(string.format("Wind data: |v| = %.1f", strength))
    --env.info(string.format("Wind data: ang = %.1f", direction))
    
    -- Return wind direction and strength km/h.
    return direction, strength, windvec3
end

-- Get the average center of a group position (average point of all units position)
function M.getAveragePosition(group)
    if type(group) == "string" then 
        group = Group.getByName(group)
    end

    local count

  local totalPosition = {x = 0,y = 0,z = 0}
  if group then
    local units = Group.getUnits(group)
    for count = 1,#units do
      if units[count] then 
        totalPosition = mist.vec.add(totalPosition,Unit.getPosition(units[count]).p)
      end
    end
    if #units > 0 then
      return mist.vec.scalar_mult(totalPosition,1/#units)
    else
      return nil
    end
  else
    return nil
  end
end

-- Return a point at the same coordinates, but on the surface
function M.placePointOnLand(vec3)
    if not vec3.y then
        vec3.y = 0
    end
    
  --  env.info(string.format("getLandHeight: vec3  x=%.1f y=%.1f, z=%.1f", vec3.x, vec3.y, vec3.z))
    local height = M.getLandHeight(vec3)
--    env.info(string.format("getLandHeight: result  height=%.1f",height))
    local result={x=vec3.x, y=height, z=vec3.z}
    --env.info(string.format("placePointOnLand: result  x=%.1f y=%.1f, z=%.1f", result.x, result.y, result.z))
    return result
end

-- Return the height of the land at the coordinate.
function M.getLandHeight(vec3)
    --env.info(string.format("getLandHeight: vec3  x=%.1f y=%.1f, z=%.1f", vec3.x, vec3.y, vec3.z))
    local vec2 = {x = vec3.x, y = vec3.z}
    --env.info(string.format("getLandHeight: vec2  x=%.1f z=%.1f", vec3.x, vec3.z))
    -- We add 1 m "safety margin" because data from getlandheight gives the surface and wind at or below the surface is zero!
    local height = math.floor(land.getHeight(vec2) + 1)
    --env.info(string.format("getLandHeight: result  height=%.1f",height))
    return height
end

function M.vecToString(vec)
    local result = ""
    if vec.x then
        result = result .. string.format(" x=%.1f", vec.x)
    end
    if vec.y then
        result = result .. string.format(" y=%.1f", vec.y)
    end
    if vec.z then
        result = result .. string.format(" z=%.1f", vec.z)
    end
    return result
end

function M.discover(o)
    local text = ""
    for key,value in pairs(getmetatable(o)) do
       text = text .. " - ".. key.."\n";
    end
  return text
end

function M.discoverTable(o)
    local text = ""
    for key,value in pairs(o) do
       text = text .. " - ".. key.."\n";
    end
  return text
end

-- Trim a string
function M.trim(s)
    local a = s:match('^%s*()')
    local b = s:match('()%s*$', a)
    return s:sub(a,b-1)
end

-- Split string. C.f. http://stackoverflow.com/questions/1426954/split-string-in-lua
function M.split(str, sep)
    local result = {}
    local regex = ("([^%s]+)"):format(sep)
    for each in str:gmatch(regex) do
        table.insert(result, each)
    end
    return result
end

-- Break string around a separator
function M.breakString(str, sep)
    local regex = ("^([^%s]+)%s(.*)$"):format(sep, sep)
    local a, b = str:match(regex)
    if not a then a = str end
    local result = {a, b}
    return result
end

local function getDistSq(x1, y1, x2, y2)
    local dX = x1 - x2
    local dY = y1 - y2
    return dX * dX + dY * dY
end

function M.findNearest(point, points)
    local pX = point.x
    local pY = point.y
    local minIdx, minDist
    for idx, p in pairs(points) do
        local dist = getDistSq(pX, pY, p.x, p.y)
        if minDist == nil or dist < minDist then
            minIdx = idx
            minDist = dist
        end
    end
    return minIdx, minDist and math.sqrt(minDist) or nil
end

-- Returns nearest airbase or FARP based on location (vec2), coalition and category (Airbase (Moose))
function M.getNearestAirbase(location, coalition, category)
    local point = {x = location.x, y = location.y}
    local baseLocations = {}
    for _, base in pairs(AIRBASE.GetAllAirbases(coalition, category)) do
        baseLocations[base:GetName()] = base:GetVec2()
    end
    return M.findNearest(point, baseLocations)
end

-- this is mega temporary, a hack if you will to help me test something
-- this stores data for the campaign and the file needs to be deleted after restart
-- for now it stores only 1 thing, but i need to rewrite it to be able to add to it
function M.storeCampaignData(key, data)
  if data ~= nil and key ~= nil then    
    local dataTable = {}
    dataTable[key] = data 
    env.info("dataTable: "..inspect(dataTable))
    local json = JSON:encode_pretty(dataTable)
    File = io.open(campaignFileName, "w")
    File:write(json)
    File:close()
  end
end

-- we probably need to read this data on mission start and keep it in memory
function M.getDataFromCampaign(key)
  local retVal = ""
  if key ~= nil then
    local f = io.open(campaignFileName, "r")
    local json = f:read("*all")
    f:close()
    local data = JSON:decode(json)
    retVal = data[key]     
  end
  return retVal
end  
  
function M.fileExists(name) --check if the file already exists for writing
    if lfs.attributes(name) then
      return true 
    end 
end

return M
