local logging = require("logging")
local log = logging.Logger:new("utils")
local JSON = require("JSON")
local inspect = require("inspect")
local campaignFileName = "CampaignData.json"

local M = {}
local utilsGpId = 7000
local utilsUnitId = 7000
local utilsDynAddIndex = {[' air '] = 0, [' hel '] = 0, [' gnd '] = 0, [' bld '] = 0, [' static '] = 0, [' shp '] = 0}
M.nextGroupId = 1
M.nextUnitId = 1
local warehouseGroupTag = "Resupply"

-- this does not work like the old Evil Framework
-- in the old framework the ids were across campaign, here they are kind of by session I think
-- this may work for CSAR and CTLD, but it may not work for state/persistance as over there we drop ids and recreated them...  I need to test this
-- the weird part is CTLD uses it's own ID counter, so that CSAR so does state/persistance.  We need to sync this
function M.getNextUnitId()
    M.nextUnitId = M.nextUnitId + 1
    return M.nextUnitId
end

function M.getNextGroupId()
    M.nextGroupId = M.nextGroupId + 1
    return M.nextGroupId
end

--- 3D Vector functions
M.vec = {}
	
--- Vector addition.
-- @tparam Vec3 vec1 first vector
-- @tparam Vec3 vec2 second vector
-- @treturn Vec3 new vector, sum of vec1 and vec2.
function M.vec.add(vec1, vec2)
	return {x = vec1.x + vec2.x, y = vec1.y + vec2.y, z = vec1.z + vec2.z}
end

--- Vector substraction.
-- @tparam Vec3 vec1 first vector
-- @tparam Vec3 vec2 second vector
-- @treturn Vec3 new vector, vec2 substracted from vec1.
function M.vec.sub(vec1, vec2)
	return {x = vec1.x - vec2.x, y = vec1.y - vec2.y, z = vec1.z - vec2.z}
end

--- Vector scalar multiplication.
-- @tparam Vec3 vec vector to multiply
-- @tparam number mult scalar multiplicator
-- @treturn Vec3 new vector multiplied with the given scalar
function M.vec.scalarMult(vec, mult)
	return {x = vec.x*mult, y = vec.y*mult, z = vec.z*mult}
end

M.vec.scalar_mult = M.vec.scalarMult

--- Vector dot product.
-- @tparam Vec3 vec1 first vector
-- @tparam Vec3 vec2 second vector
-- @treturn number dot product of given vectors
function M.vec.dp (vec1, vec2)
	return vec1.x*vec2.x + vec1.y*vec2.y + vec1.z*vec2.z
end

--- Vector cross product.
-- @tparam Vec3 vec1 first vector
-- @tparam Vec3 vec2 second vector
-- @treturn Vec3 new vector, cross product of vec1 and vec2.
function M.vec.cp(vec1, vec2)
	return { x = vec1.y*vec2.z - vec1.z*vec2.y, y = vec1.z*vec2.x - vec1.x*vec2.z, z = vec1.x*vec2.y - vec1.y*vec2.x}
end

--- Vector magnitude
-- @tparam Vec3 vec vector
-- @treturn number magnitude of vector vec
function M.vec.mag(vec)
	return (vec.x^2 + vec.y^2 + vec.z^2)^0.5
end

--- Unit vector
-- @tparam Vec3 vec
-- @treturn Vec3 unit vector of vec
function M.vec.getUnitVec(vec)
	local mag = M.vec.mag(vec)
	return { x = vec.x/mag, y = vec.y/mag, z = vec.z/mag }
end

--- Rotate vector.
-- @tparam Vec2 vec2 to rotoate
-- @tparam number theta
-- @return Vec2 rotated vector.
function M.vec.rotateVec2(vec2, theta)
	return { x = vec2.x*math.cos(theta) - vec2.y*math.sin(theta), y = vec2.x*math.sin(theta) + vec2.y*math.cos(theta)}
end

function M.getFilePath(filename)
    if env ~= nil then
        return lfs.writedir() .. [[Scripts\RSR\]] .. filename
    else
        return filename
    end
end

function M.file_exists(name) --check if the file already exists for writing
    if lfs.attributes(name) then
      return true
    else
      return false 
    end 
end

-- This function is an easy fix for our warehouse/slinging problem. The Warehouse resupply was written in such a way, that once you used a specific unit in the warehouse
-- you were not able to sling that type of unit, becuase the warehouse resupply was checking at unit type.  That eliminated tanks from slinging.
-- Here we determine if the unit is player slung, or if it comes from the miz file, or the initial warehouse spit.
-- AW=33COM
function M.isUnitPlayerSlung(iniUnitName)
  local retVal = false  
  if iniUnitName ~= nil then
    if string.find(iniUnitName, "Unpacked") then
      retVal = true
    end
  end  
  return retVal
end

-- gets opposite coalition name
function M.GetOppositeCoalitionName(side)
  if side == coalition.side.RED then
    return coalition.side.BLUE
  elseif side == coalition.side.BLUE then
    return coalition.side.RED
  else
    return coalition.side.NEUTRAL
  end  
end

-- This is the function that allows us to distinquish between units of the same type, but different location: MIZ ship, Warehouse ship, slung tanks, miz tanks, etc  
-- everything works on the word: Resupply.  Once that word changes nothing will work.  This is similiar to the Player Slung unit check.
-- =AW=33COM  I added this, becuase our entrie warehouse logic had no way of figuring out where the unit came from and limits were introduced.  This fixes it.
function M.isUnitFromWarehouse(iniUnitName)

  local retVal = false
  
  if iniUnitName ~= nil then
    if string.find(iniUnitName, "Resupply") then
      retVal = true
    end
  end
  
  return retVal

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

function M.getFirstKey(Table)  
  if Table ~= nil then    
      for _ in pairs(Table) do
        return _
      end
  end
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

    -- first digit of 5 digit MGRS Easting and Northing more accurate for 10km grid than Evil Framework method of rounding-up MGRS coordinates
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

    --log:info("_RSRbaseCaptureZoneName: $1",_RSRbaseCaptureZoneName)

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
-- this will not work anymore as Evil Framework was pulled out. need to fix this
function M.findUnitsInCircle(center, radius)
    local result = {}
    local units = nil --EF.DBs.unitsByName -- local copy for faster execution
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

function M.getAvgGroupPos(groupName) -- stolen from Evil Framework and corrected
  local group = groupName -- sometimes this parameter is actually a group
  if type(groupName) == 'string' and Group.getByName(groupName) and Group.getByName(groupName):isExist() == true then
    group = Group.getByName(groupName)
  end
  local units = {}
  for i = 1, group:getSize() do
    table.insert(units, group:getUnit(i):getName())
  end
  return M.getAvgPos(units)
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
  M.goRoute(groupName, {newWaypoint})
  return true
end

--- Tasks group to follow a route.
-- This sets the mission task for the given group.
-- Any wrapped actions inside the path (like enroute
-- tasks) will be executed.
-- @tparam Group group group to task.
-- @tparam table path containing
-- points defining a route.
function M.goRoute(group, path)
	local misTask = {
		id = 'Mission',
		params = {
			route = {
				points = M.deepCopy(path),
			},
		},
	}
	if type(group) == 'string' then
		group = Group.getByName(group)
	end
	if group then
		local groupCon = group:getController()
		if groupCon then
			log:warn(misTask)
			groupCon:setTask(misTask)
			return true
		end
	end
	return false
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
        unitPosition = M.getRandPointInCircle(spawnSpot, dispersion)
        local landType = land.getSurfaceType(unitPosition)
        tryCounter = tryCounter - 1
    until ((isShip and landType == land.SurfaceType.WATER) or (not(isShip) and (landType == land.SurfaceType.LAND or landType == land.SurfaceType.ROAD or landType == land.SurfaceType.RUNWAY))) or tryCounter == 0
    if tryCounter == 0 then
        return nil
    else
        return unitPosition
    end
end

	-- need to return a Vec3 or Vec2?
function M.getRandPointInCircle(p, radius, innerRadius, maxA, minA)
		local point = M.makeVec3(p)
        local theta = 2*math.pi*math.random()
		local minR = innerRadius or 0
		if maxA and not minA then
			theta = math.rad(math.random(0, maxA - math.random()))
		elseif maxA and minA and minA < maxA then
			theta = math.rad(math.random(minA, maxA) - math.random())
		end
		local rad = math.random() + math.random()
		if rad > 1 then
			rad = 2 - rad
		end

		local radMult
		if minR and minR <= radius then
			--radMult = (radius - innerRadius)*rad + innerRadius
			radMult = radius * math.sqrt((minR^2 + (radius^2 - minR^2) * math.random()) / radius^2)
		else
			radMult = radius*rad
		end

		local rndCoord
		if radius > 0 then
			rndCoord = {x = math.cos(theta)*radMult + point.x, y = math.sin(theta)*radMult + point.z}
		else
			rndCoord = {x = point.x, y = point.z}
		end
		return rndCoord
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
        totalPosition = M.vec.add(totalPosition,Unit.getPosition(units[count]).p)
      end
    end
    if #units > 0 then
      return M.vec.scalar_mult(totalPosition,1/#units)
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

-- this stores data for the campaign and the file needs to be deleted after restart
-- for now it stores only 1 thing, but i need to rewrite it to be able to add to it
function M.storeCampaignData(key, data)
  if data ~= nil and key ~= nil then  
	local dataTable = nil

	-- get all data first
	local f = io.open(campaignFileName, "r")
	
	if f ~= nil then
		local json = f:read("*all")
		f:close()
		dataTable = JSON:decode(json)
	end
	
	if dataTable == nil then		 
		dataTable = {}
	end
	
    dataTable[key] = data 
    --env.info("dataTable: "..inspect(dataTable))
    local json = JSON:encode_pretty(dataTable)
    File = io.open(campaignFileName, "w")
    File:write(json)
    File:close()
  end
end

function M.getDataFromCampaign(key)  
  if key ~= nil then
    local f = io.open(campaignFileName, "r")
    local json = f:read("*all")
    f:close()
    local data = JSON:decode(json)
    return data[key]
  end
end  
  
function M.fileExists(name) --check if the file already exists for writing
    if lfs.attributes(name) then
      return true 
    end 
end

-- this needs to be improved or maybe not needed, still testing
function M.defaultX()
  return 122428.57142857
end

-- this needs to be improved or maybe not needed, still testing
function M.defaultY()
  return 420857.14285714
end

-- AW33COM this will help us find out if a specific unit type in on a base or in a zone. for example: we can check if Antenna or Mobile ATC is alive on the base
-- this is tight to ground units only as Moose is inconsitent and has 1000000 diff categires unrelated to categories in DCS.  Moose is too big for it's own good
function M.IsUnitTypeAliveInZone(zone, unit_type, coalition)
	local coalName = "red"
	local retVal = false
    if coalition == 2 then coalName = "blue" end
	if coalition == 3 then coalName = "neutral" end	
	local unitsByType = SET_UNIT:New():FilterCoalitions(coalName):FilterCategories("ground"):FilterTypes(unit_type):FilterActive():FilterOnce()
		
	if unitsByType:HasGroundUnits() then
		env.info("AW33COM utils.isAliveUnitTypeInZone Has Ground Units of type: ("..unit_type..") in Zone")		
		 unitsByType:ForEachUnitCompletelyInZone (zone, 
			function(unit)
				retVal = true
				env.info("AW33COM utils.isAliveUnitTypeInZone Unit: ("..unit:Name()..") of Type: ("..unit_type..") is in Zone")
				return
			end			
		)
	else
		env.info("AW33COM utils.isAliveUnitTypeInZone No Units By Type found")
	end
	return retVal
end

-- =AW=33COM Moved all Evil Framework functions below
M.shapeNames = {
	["Landmine"] = "landmine",
	["FARP CP Blindage"] = "kp_ug",
	["Subsidiary structure C"] = "saray-c",
	["Barracks 2"] = "kazarma2",
	["Small house 2C"] = "dom2c",
	["Military staff"] = "aviashtab",
	["Tech hangar A"] = "ceh_ang_a",
	["Oil derrick"] = "neftevyshka",
	["Tech combine"] = "kombinat",
	["Garage B"] = "garage_b",
	["Airshow_Crowd"] = "Crowd1",
	["Hangar A"] = "angar_a",
	["Repair workshop"] = "tech",
	["Subsidiary structure D"] = "saray-d",
	["FARP Ammo Dump Coating"] = "SetkaKP",
	["Small house 1C area"] = "dom2c-all",
	["Tank 2"] = "airbase_tbilisi_tank_01",
	["Boiler-house A"] = "kotelnaya_a",
	["Workshop A"] = "tec_a",
	["Small werehouse 1"] = "s1",
	["Garage small B"] = "garagh-small-b",
	["Small werehouse 4"] = "s4",
	["Shop"] = "magazin",
	["Subsidiary structure B"] = "saray-b",
	["FARP Fuel Depot"] = "GSM Rus",
	["Coach cargo"] = "wagon-gruz",
	["Electric power box"] = "tr_budka",
	["Tank 3"] = "airbase_tbilisi_tank_02",
	["Red_Flag"] = "H-flag_R",
	["Container red 3"] = "konteiner_red3",
	["Garage A"] = "garage_a",
	["Hangar B"] = "angar_b",
	["Black_Tyre"] = "H-tyre_B",
	["Cafe"] = "stolovaya",
	["Restaurant 1"] = "restoran1",
	["Subsidiary structure A"] = "saray-a",
	["Container white"] = "konteiner_white",
	["Warehouse"] = "sklad",
	["Tank"] = "bak",
	["Railway crossing B"] = "pereezd_small",
	["Subsidiary structure F"] = "saray-f",
	["Farm A"] = "ferma_a",
	["Small werehouse 3"] = "s3",
	["Water tower A"] = "wodokachka_a",
	["Railway station"] = "r_vok_sd",
	["Coach a tank blue"] = "wagon-cisterna_blue",
	["Supermarket A"] = "uniwersam_a",
	["Coach a platform"] = "wagon-platforma",
	["Garage small A"] = "garagh-small-a",
	["TV tower"] = "tele_bash",
	["Comms tower M"] = "tele_bash_m",
	["Small house 1A"] = "domik1a",
	["Farm B"] = "ferma_b",
	["GeneratorF"] = "GeneratorF",
	["Cargo1"] = "ab-212_cargo",
	["Container red 2"] = "konteiner_red2",
	["Subsidiary structure E"] = "saray-e",
	["Coach a passenger"] = "wagon-pass",
	["Black_Tyre_WF"] = "H-tyre_B_WF",
	["Electric locomotive"] = "elektrowoz",
	["Shelter"] = "ukrytie",
	["Coach a tank yellow"] = "wagon-cisterna_yellow",
	["Railway crossing A"] = "pereezd_big",
	[".Ammunition depot"] = "SkladC",
	["Small werehouse 2"] = "s2",
	["Windsock"] = "H-Windsock_RW",
	["Shelter B"] = "ukrytie_b",
	["Fuel tank"] = "toplivo-bak",
	["Locomotive"] = "teplowoz",
	[".Command Center"] = "ComCenter",
	["Pump station"] = "nasos",
	["Black_Tyre_RF"] = "H-tyre_B_RF",
	["Coach cargo open"] = "wagon-gruz-otkr",
	["Subsidiary structure 3"] = "hozdomik3",
	["FARP Tent"] = "PalatkaB",
	["White_Tyre"] = "H-tyre_W",
	["Subsidiary structure G"] = "saray-g",
	["Container red 1"] = "konteiner_red1",
	["Small house 1B area"] = "domik1b-all",
	["Subsidiary structure 1"] = "hozdomik1",
	["Container brown"] = "konteiner_brown",
	["Small house 1B"] = "domik1b",
	["Subsidiary structure 2"] = "hozdomik2",
	["Chemical tank A"] = "him_bak_a",
	["WC"] = "WC",
	["Small house 1A area"] = "domik1a-all",
	["White_Flag"] = "H-Flag_W",
	["Airshow_Cone"] = "Comp_cone",
}
		
--- Returns heading of given unit.
-- @tparam Unit unit unit whose heading is returned.
-- @param rawHeading
-- @treturn number heading of the unit, in range
-- of 0 to 2*pi.
function M.getHeading(unit, rawHeading)
	local unitpos = unit:getPosition()
	if unitpos then
		local Heading = math.atan2(unitpos.x.z, unitpos.x.x)
		if not rawHeading then
			Heading = Heading + M.getNorthCorrection(unitpos.p)
		end
		if Heading < 0 then
			Heading = Heading + 2*math.pi	-- put heading in range of 0 to 2*pi
		end
		return Heading
	end
end

--- Converts a Vec2 to a Vec3.
-- @tparam Vec2 vec the 2D vector
-- @param y optional new y axis (altitude) value. If omitted it's 0.
function M.makeVec3(vec, y)
	if not vec.z then
		if vec.alt and not y then
			y = vec.alt
		elseif not y then
			y = 0
		end
		return {x = vec.x, y = y, z = vec.y}
	else
		return {x = vec.x, y = vec.y, z = vec.z}	-- it was already Vec3, actually.
	end
end

function M.getNorthCorrection(gPoint)	--gets the correction needed for true north
	local point = M.deepCopy(gPoint)
	if not point.z then --Vec2; convert to Vec3
		point.z = point.y
		point.y = 0
	end
	local lat, lon = coord.LOtoLL(point)
	local north_posit = coord.LLtoLO(lat + 1, lon)
	return math.atan2(north_posit.z - point.z, north_posit.x - point.x)
end
		
--- Simple rounding function.
-- From http://lua-users.org/wiki/SimpleRound
-- use negative idp for rounding ahead of decimal place, positive for rounding after decimal place
-- @tparam number num number to round
-- @param idp
function M.oldRound(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end		

--- Converts kilometers per hour to meters per second.
-- @param kmph speed in km/h
-- @return speed in m/s
function M.kmphToMps(kmph)
	return kmph/3.6
end

-- No longer accepts path
function M.groundBuildWP(point, overRideForm, overRideSpeed)

	local wp = {}
	wp.x = point.x

	if point.z then
		wp.y = point.z
	else
		wp.y = point.y
	end
	local form, speed

	if point.speed and not overRideSpeed then
		wp.speed = point.speed
	elseif type(overRideSpeed) == 'number' then
		wp.speed = overRideSpeed
	else
		wp.speed = M.kmphToMps(20)
	end

	if point.form and not overRideForm then
		form = point.form
	else
		form = overRideForm
	end

	if not form then
		wp.action = 'Cone'
	else
		form = string.lower(form)
		if form == 'off_road' or form == 'off road' then
			wp.action = 'Off Road'
		elseif form == 'on_road' or form == 'on road' then
			wp.action = 'On Road'
		elseif form == 'rank' or form == 'line_abrest' or form == 'line abrest' or form == 'lineabrest'then
			wp.action = 'Rank'
		elseif form == 'cone' then
			wp.action = 'Cone'
		elseif form == 'diamond' then
			wp.action = 'Diamond'
		elseif form == 'vee' then
			wp.action = 'Vee'
		elseif form == 'echelon_left' or form == 'echelon left' or form == 'echelonl' then
			wp.action = 'EchelonL'
		elseif form == 'echelon_right' or form == 'echelon right' or form == 'echelonr' then
			wp.action = 'EchelonR'
		else
			wp.action = 'Cone' -- if nothing matched
		end
	end

	wp.type = 'Turning Point'

	return wp

end

--- Converts angle in radians to degrees.
-- @param angle angle in radians
-- @return angle in degrees
function M.toDegree(angle)
	return angle*180/math.pi
end

--- Returns heading-error corrected direction.
-- True-north corrected direction from point along vector vec.
-- @tparam Vec3 vec
-- @tparam Vec2 point
-- @return heading-error corrected direction from point.
function M.getDir(vec, point)
	local dir = math.atan2(vec.z, vec.x)
	if point then
		dir = dir + M.getNorthCorrection(point)
	end
	if dir < 0 then
		dir = dir + 2 * math.pi	-- put dir in range of 0 to 2*pi
	end
	return dir
end

--[[acc:
in DM: decimal point of minutes.
In DMS: decimal point of seconds.
position after the decimal of the least significant digit:
So:
42.32 - acc of 2.
]]
function M.tostringLL(lat, lon, acc, DMS)

	local latHemi, lonHemi
	if lat > 0 then
		latHemi = 'N'
	else
		latHemi = 'S'
	end

	if lon > 0 then
		lonHemi = 'E'
	else
		lonHemi = 'W'
	end

	lat = math.abs(lat)
	lon = math.abs(lon)

	local latDeg = math.floor(lat)
	local latMin = (lat - latDeg)*60

	local lonDeg = math.floor(lon)
	local lonMin = (lon - lonDeg)*60

	if DMS then	-- degrees, minutes, and seconds.
		local oldLatMin = latMin
		latMin = math.floor(latMin)
		local latSec = M.oldRound((oldLatMin - latMin)*60, acc)

		local oldLonMin = lonMin
		lonMin = math.floor(lonMin)
		local lonSec = M.oldRound((oldLonMin - lonMin)*60, acc)

		if latSec == 60 then
			latSec = 0
			latMin = latMin + 1
		end

		if lonSec == 60 then
			lonSec = 0
			lonMin = lonMin + 1
		end

		local secFrmtStr -- create the formatting string for the seconds place
		if acc <= 0 then	-- no decimal place.
			secFrmtStr = '%02d'
		else
			local width = 3 + acc	-- 01.310 - that's a width of 6, for example.
			secFrmtStr = '%0' .. width .. '.' .. acc .. 'f'
		end

		return string.format('%02d', latDeg) .. ' ' .. string.format('%02d', latMin) .. '\' ' .. string.format(secFrmtStr, latSec) .. '"' .. latHemi .. '	 '
		.. string.format('%02d', lonDeg) .. ' ' .. string.format('%02d', lonMin) .. '\' ' .. string.format(secFrmtStr, lonSec) .. '"' .. lonHemi

	else	-- degrees, decimal minutes.
		latMin = M.oldRound(latMin, acc)
		lonMin = M.oldRound(lonMin, acc)

		if latMin == 60 then
			latMin = 0
			latDeg = latDeg + 1
		end

		if lonMin == 60 then
			lonMin = 0
			lonDeg = lonDeg + 1
		end

		local minFrmtStr -- create the formatting string for the minutes place
		if acc <= 0 then	-- no decimal place.
			minFrmtStr = '%02d'
		else
			local width = 3 + acc	-- 01.310 - that's a width of 6, for example.
			minFrmtStr = '%0' .. width .. '.' .. acc .. 'f'
		end

		return string.format('%02d', latDeg) .. ' ' .. string.format(minFrmtStr, latMin) .. '\'' .. latHemi .. '	 '
		.. string.format('%02d', lonDeg) .. ' ' .. string.format(minFrmtStr, lonMin) .. '\'' .. lonHemi
	end
end	
	
--- Creates a deep copy of a object.
-- Usually this object is a table.
-- See also: from http://lua-users.org/wiki/CopyTable
-- @param object object to copy
-- @return copy of object
function M.deepCopy(object)
	local lookup_table = {}
	local function _copy(object)
		if type(object) ~= "table" then
			return object
		elseif lookup_table[object] then
			return lookup_table[object]
		end
		local new_table = {}
		lookup_table[object] = new_table
		for index, value in pairs(object) do
			new_table[_copy(index)] = _copy(value)
		end
		return setmetatable(new_table, getmetatable(object))
	end
	return _copy(object)
end

--- Returns the center of a zone as Vec3.
-- @tparam string|table zone trigger zone name or table
-- @treturn Vec3 center of the zone
function M.zoneToVec3(zone)
	local new = {}
	if type(zone) == 'table' then
		if zone.point then
			new.x = zone.point.x
			new.y = zone.point.y
			new.z = zone.point.z
		elseif zone.x and zone.y and zone.z then
			return zone
		end
		return new
	elseif type(zone) == 'string' then
		zone = trigger.misc.getZone(zone)
		if zone then
			new.x = zone.point.x
			new.y = zone.point.y
			new.z = zone.point.z
			return new
		end
	end
end

--- Spawns a static object to the game world.
-- @todo write good docs
-- @tparam table staticObj table containing data needed for the object creation
function M.dynAddStatic(newObj)
	log:info(newObj)
	if newObj.units and newObj.units[1] then -- if its EF format
		for entry, val in pairs(newObj.units[1]) do
			if newObj[entry] and newObj[entry] ~= val or not newObj[entry] then
				newObj[entry] = val
			end
		end
	end
	
	local cntry = newObj.country
	if newObj.countryId then
		cntry = newObj.countryId
	end

	local newCountry = ''

	for countryId, countryName in pairs(country.name) do
		if type(cntry) == 'string' then
			cntry = cntry:gsub("%s+", "_")
			if tostring(countryName) == string.upper(cntry) then
				newCountry = countryName
			end
		elseif type(cntry) == 'number' then
			if countryId == cntry then
				newCountry = countryName
			end
		end
	end
	
	if newCountry == '' then
		log:error("Country not found: $1", cntry)
		return false
	end

	if newObj.clone or not newObj.groupId then
		utilsGpId = utilsGpId + 1
		newObj.groupId = utilsGpId
	end

	if newObj.clone or not newObj.unitId then
		utilsUnitId = utilsUnitId + 1
		newObj.unitId = utilsUnitId
	end

	newObj.name = newObj.name or newObj.unitName
	
	if newObj.clone or not newObj.name then
		utilsDynAddIndex[' static '] = utilsDynAddIndex[' static '] + 1
		newObj.name = (newCountry .. ' static ' .. utilsDynAddIndex[' static '])
	end

	if not newObj.dead then
		newObj.dead = false
	end

	if not newObj.heading then
		newObj.heading = math.random(360)
	end
	
	if newObj.categoryStatic then
		newObj.category = newObj.categoryStatic
	end
	if newObj.mass then
		newObj.category = 'Cargos'
	end
	
	if newObj.shapeName then
		newObj.shape_name = newObj.shapeName
	end
	
	if not newObj.shape_name then
		log:info('shape_name not present')
		if M.shapeNames[newObj.type] then
			newObj.shape_name = M.shapeNames[newObj.type]
		end
	end
	
	if newObj.x and newObj.y and newObj.type and type(newObj.x) == 'number' and type(newObj.y) == 'number' and type(newObj.type) == 'string' then
		log:info(newObj)
		coalition.addStaticObject(country.id[newCountry], newObj)
		return newObj
	end
	log:error("Failed to add static object due to missing or incorrect value. X: $1, Y: $2, Type: $3", newObj.x, newObj.y, newObj.type)
	return false
end

--- Spawns a dynamic group into the game world.
-- Same as coalition.add function in SSE. checks the passed data to see if its valid.
-- Will generate groupId, groupName, unitId, and unitName if needed
-- @tparam table newGroup table containting values needed for spawning a group.
function M.dynAdd(newGroup)
	local cntry = newGroup.country
	if newGroup.countryId then
		cntry = newGroup.countryId
	end

	local groupType = newGroup.category
	local newCountry = ''
	-- validate data
	for countryId, countryName in pairs(country.name) do
		if type(cntry) == 'string' then
			cntry = cntry:gsub("%s+", "_")
			if tostring(countryName) == string.upper(cntry) then
				newCountry = countryName
			end
		elseif type(cntry) == 'number' then
			if countryId == cntry then
				newCountry = countryName
			end
		end
	end

	if newCountry == '' then
		log:error("Country not found: $1", cntry)
		return false
	end

	local newCat = ''
	for catName, catId in pairs(Unit.Category) do
		if type(groupType) == 'string' then
			if tostring(catName) == string.upper(groupType) then
				newCat = catName
			end
		elseif type(groupType) == 'number' then
			if catId == groupType then
				newCat = catName
			end
		end

		if catName == 'GROUND_UNIT' and (string.upper(groupType) == 'VEHICLE' or string.upper(groupType) == 'GROUND') then
			newCat = 'GROUND_UNIT'
		elseif catName == 'AIRPLANE' and string.upper(groupType) == 'PLANE' then
			newCat = 'AIRPLANE'
		end
	end
	local typeName
	if newCat == 'GROUND_UNIT' then
		typeName = ' gnd '
	elseif newCat == 'AIRPLANE' then
		typeName = ' air '
	elseif newCat == 'HELICOPTER' then
		typeName = ' hel '
	elseif newCat == 'SHIP' then
		typeName = ' shp '
	elseif newCat == 'BUILDING' then
		typeName = ' bld '
	end
	if newGroup.clone or not newGroup.groupId then
		utilsDynAddIndex[typeName] = utilsDynAddIndex[typeName] + 1
		utilsGpId = utilsGpId + 1
		newGroup.groupId = utilsGpId
	end
	if newGroup.groupName or newGroup.name then
		if newGroup.groupName then
			newGroup.name = newGroup.groupName
		elseif newGroup.name then
			newGroup.name = newGroup.name
		end
	end

	if newGroup.clone or not newGroup.name then
		newGroup.name = tostring(newCountry .. tostring(typeName) .. utilsDynAddIndex[typeName])
	end

	if not newGroup.hidden then
		newGroup.hidden = false
	end

	if not newGroup.visible then
		newGroup.visible = false
	end

	if (newGroup.start_time and type(newGroup.start_time) ~= 'number') or not newGroup.start_time then
		if newGroup.startTime then
			newGroup.start_time = M.oldRound(newGroup.startTime)
		else
			newGroup.start_time = 0
		end
	end


	for unitIndex, unitData in pairs(newGroup.units) do
		local originalName = newGroup.units[unitIndex].unitName or newGroup.units[unitIndex].name
		if newGroup.clone or not unitData.unitId then
			utilsUnitId = utilsUnitId + 1
			newGroup.units[unitIndex].unitId = utilsUnitId
		end
		if newGroup.units[unitIndex].unitName or newGroup.units[unitIndex].name then
			if newGroup.units[unitIndex].unitName then
				newGroup.units[unitIndex].name = newGroup.units[unitIndex].unitName
			elseif newGroup.units[unitIndex].name then
				newGroup.units[unitIndex].name = newGroup.units[unitIndex].name
			end
		end
		if newGroup.clone or not unitData.name then
			newGroup.units[unitIndex].name = tostring(newGroup.name .. ' unit' .. unitIndex)
		end

		if not unitData.skill then
			newGroup.units[unitIndex].skill = 'Random'
		end

		if newCat == 'AIRPLANE' or newCat == 'HELICOPTER' then
			if newGroup.units[unitIndex].alt_type and newGroup.units[unitIndex].alt_type ~= 'BARO' or not newGroup.units[unitIndex].alt_type then
				newGroup.units[unitIndex].alt_type = 'RADIO'
			end
			if not unitData.speed then
				if newCat == 'AIRPLANE' then
					newGroup.units[unitIndex].speed = 150
				elseif newCat == 'HELICOPTER' then
					newGroup.units[unitIndex].speed = 60
				end
			end
			if not unitData.payload then
				--newGroup.units[unitIndex].payload = EF.getPayload(originalName) I had to remove this
			end
			if not unitData.alt then
				if newCat == 'AIRPLANE' then
					newGroup.units[unitIndex].alt = 2000
					newGroup.units[unitIndex].alt_type = 'RADIO'
					newGroup.units[unitIndex].speed = 150
				elseif newCat == 'HELICOPTER' then
					newGroup.units[unitIndex].alt = 500
					newGroup.units[unitIndex].alt_type = 'RADIO'
					newGroup.units[unitIndex].speed = 60
				end
			end
			
		elseif newCat == 'GROUND_UNIT' then
			if nil == unitData.playerCanDrive then
				unitData.playerCanDrive = true
			end		
		end		
	end
	
	if newGroup.route then
		if newGroup.route and not newGroup.route.points then
			if newGroup.route[1] then
				local copyRoute = M.deepCopy(newGroup.route)
				newGroup.route = {}
				newGroup.route.points = copyRoute
			end
		end
	else -- if aircraft and no route assigned. make a quick and stupid route so AI doesnt RTB immediately
		if newCat == 'AIRPLANE' or newCat == 'HELICOPTER' then
			newGroup.route = {}
			newGroup.route.points = {}
			newGroup.route.points[1] = {}
		end
	end
	newGroup.country = newCountry
	-- sanitize table
	newGroup.groupName = nil
	newGroup.clone = nil
	newGroup.category = nil
	newGroup.country = nil
	newGroup.tasks = {}

	for unitIndex, unitData in pairs(newGroup.units) do
		newGroup.units[unitIndex].unitName = nil
	end
	
	coalition.addGroup(country.id[newCountry], Unit.Category[newCat], newGroup)
	return newGroup
end

--- Returns MGRS coordinates as string.
-- @tparam string MGRS MGRS coordinates
-- @tparam number acc the accuracy of each easting/northing.
-- Can be: 0, 1, 2, 3, 4, or 5.
function M.tostringMGRS(MGRS, acc)
	if acc == 0 then
		return MGRS.UTMZone .. ' ' .. MGRS.MGRSDigraph
	else
		return MGRS.UTMZone .. ' ' .. MGRS.MGRSDigraph .. ' ' .. string.format('%0' .. acc .. 'd', M.oldRound(MGRS.Easting/(10^(5-acc)), 0))
		.. ' ' .. string.format('%0' .. acc .. 'd', M.oldRound(MGRS.Northing/(10^(5-acc)), 0))
	end
end

--- Converts meters to nautical miles.
-- @param meters distance in meters
-- @return distance in nautical miles
function M.metersToNM(meters)
	return meters/1852
end

--- Converts meters to feet.
-- @param meters distance in meters
-- @return distance in feet
function M.metersToFeet(meters)
	return meters/0.3048
end

--- Converts meters per second to knots.
-- @param mps speed in m/s
-- @return speed in knots
function M.mpsToKnots(mps)
	return mps*3600/1852
end

--- Converts meters per second to kilometers per hour.
-- @param mps speed in m/s
-- @return speed in km/h
function M.mpsToKmph(mps)
	return mps*3.6
end

--vars.units - table of unit names (NOT unitNameTable- maybe this should change).
--vars.acc - integer, number of numbers after decimal place
--vars.DMS - if true, output in degrees, minutes, seconds.	Otherwise, output in degrees, minutes.
function M.getLLString(vars)
	local units = vars.units
	local acc = vars.acc or 3
	local DMS = vars.DMS
	local avgPos = M.getAvgPos(units)
	if avgPos then
		local lat, lon = coord.LOtoLL(avgPos)
		return M.tostringLL(lat, lon, acc, DMS)
	end
end

--Gets the average position of a group of units (by name)
function M.getAvgPos(unitNames)
	local avgX, avgY, avgZ, totNum = 0, 0, 0, 0
	for i = 1, #unitNames do
		local unit
		if Unit.getByName(unitNames[i]) then
			unit = Unit.getByName(unitNames[i])
		elseif StaticObject.getByName(unitNames[i]) then
			unit = StaticObject.getByName(unitNames[i])
		end
		if unit then
			local pos = unit:getPosition().p
			if pos then -- you never know O.o
				avgX = avgX + pos.x
				avgY = avgY + pos.y
				avgZ = avgZ + pos.z
				totNum = totNum + 1
			end
		end
	end
	if totNum ~= 0 then
		return {x = avgX/totNum, y = avgY/totNum, z = avgZ/totNum}
	end
end

--- Returns MGRS coordinates as string.
-- @tparam string MGRS MGRS coordinates
-- @tparam number acc the accuracy of each easting/northing.
-- Can be: 0, 1, 2, 3, 4, or 5.
function M.tostringMGRS(MGRS, acc)
	if acc == 0 then
		return MGRS.UTMZone .. ' ' .. MGRS.MGRSDigraph
	else
		return MGRS.UTMZone .. ' ' .. MGRS.MGRSDigraph .. ' ' .. string.format('%0' .. acc .. 'd', M.oldRound(MGRS.Easting/(10^(5-acc)), 0))
		.. ' ' .. string.format('%0' .. acc .. 'd', M.oldRound(MGRS.Northing/(10^(5-acc)), 0))
	end
end

--[[ 
vars.units - table of unit names (NOT unitNameTable- maybe this should change).
vars.acc - integer between 0 and 5, inclusive
]]
function M.getMGRSString(vars)
	local units = vars.units
	local acc = vars.acc or 5
	local avgPos = M.getAvgPos(units)
	if avgPos then
		return M.tostringMGRS(coord.LLtoMGRS(coord.LOtoLL(avgPos)), acc)
	end
end

--[[
vars.units- table of unit names (NOT unitNameTable- maybe this should change).
vars.ref -	vec3 ref point, maybe overload for vec2 as well?
vars.alt - boolean, if used, includes altitude in string
vars.metric - boolean, gives distance in km instead of NM.
]]
function M.getBRString(vars)
	local units = vars.units
	local ref = M.makeVec3(vars.ref, 0)	-- turn it into Vec3 if it is not already.
	local alt = vars.alt
	local metric = vars.metric
	local avgPos = M.getAvgPos(units)
	if avgPos then
		local vec = {x = avgPos.x - ref.x, y = avgPos.y - ref.y, z = avgPos.z - ref.z}
		local dir = M.getDir(vec, ref)
		local dist = M.get2DDist(avgPos, ref)
		if alt then
			alt = avgPos.y
		end
		return M.tostringBR(dir, dist, alt, metric)
	end
end

--- Returns distance in meters between two points.
-- @tparam Vec2|Vec3 point1 first point
-- @tparam Vec2|Vec3 point2 second point
-- @treturn number distance between given points.
function M.get2DDist(point1, point2)
	point1 = M.makeVec3(point1)
	point2 = M.makeVec3(point2)
	return M.vec.mag({x = point1.x - point2.x, y = 0, z = point1.z - point2.z})
end

-- copies these methods from space until files, because we freaken have gazillion method doing the same thing all over
local function getDistSq(x1, y1, x2, y2)
    local dX = x1 - x2
    local dY = y1 - y2
    return dX * dX + dY * dY
end

function M.isPointInZone(point, zonePoint, zoneRadius)
    return getDistSq(point.x, point.y, zonePoint.x, zonePoint.y) < zoneRadius * zoneRadius
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

function M.findNearestBase(point)
    local baseLocations = {}
    for _, base in pairs(AIRBASE.GetAllAirbases()) do
        baseLocations[base:GetName()] = base:GetVec2()
    end
    return M.findNearest(point, baseLocations)
end

function M.closestBaseIsEnemyAndWithinRange(position, friendlySideName, range)
    local state = require("state")
    local nearestBase, distance = M.findNearestBase(position)
    if distance > range then
        -- far from any base
        return false
    end

    local nearestBaseOwner = state.getOwner(nearestBase)
    if nearestBaseOwner == nil or nearestBaseOwner == "neutral" or nearestBaseOwner == friendlySideName then
        -- nearest base is neutral/friendly
        return false
    end
    return true
end

function M.createGroupDataForWarehouseAsset(warehouseName, asset, sideName)
	local groupData = {}
  
	if asset.groupCat == Group.Category.SHIP then
		groupData = {
		["visible"] = false,    
		["route"] = 
		{
			["points"] = 
			{
				[1] = 
				{
					["alt"] = -0,
					["type"] = "Turning Point",
					["ETA"] = 0,
					["alt_type"] = "BARO",
					["formation_template"] = "",
					["y"] = 0.0,
					["x"] = 0.0,
					["ETA_locked"] = true,
					["speed"] = 0,
					["action"] = "Turning Point",
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["enabled"] = true,
									["auto"] = false,
									["id"] = "WrappedAction",
									["number"] = 1,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 25,	-- cut the interception range
												["name"] = 24,
											},
										},
									},
								},
							},
						},
					}, 
					["speed_locked"] = true,
				},
			},
		},		
		["tasks"] =   
		{
		},
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["transportable"] = 
				{
					["randomTransportable"] = false,
				},
				["skill"] = asset.skill,
				["type"] = asset.name,
				["x"] = 0.0,
				["y"] = 0.0,
				["name"] = warehouseName .. '_' .. asset.name,				
				["heading"] = 0,
                ["modulation"] = 0,
			},
		},
		["x"] = 0.0,
		["y"] = 0.0,
		["name"] = warehouseGroupTag..'_'..sideName..'_'..warehouseName..'_'..asset.name,
		["start_time"] = 0,
		["uncontrollable"] = false,
		["category"] = asset.groupCat,
		["country"] = asset.country,
	  }   
	elseif asset.groupCat == Group.Category.GROUND then
		groupData = {
			["visible"] = false,    
			["route"] = {
				["points"] = { { -- unfortunalty this is requried by MOOSE, not by DCS
					["ETA"] = 0,
					["ETA_locked"] = true,
					["action"] = "Off Road",
					["alt"] = 5,
					["alt_type"] = "BARO",
					["formation_template"] = "",
					["speed"] = 5.5555555555556,
					["speed_locked"] = true,
					["task"] = {
					  ["id"] = "ComboTask",
					  ["params"] = {
						["tasks"] = {}
					  }
					},
					["type"] = "Turning Point",
					["x"] = 0.0,
					["y"] = 0.0
				  } },
				routeRelativeTOT = true
			  },
			["taskSelected"] = true,
			["tasks"] =   
			{
			},
			["hidden"] = false,
			["units"] = 
			{
				[1] = 
				{
					["transportable"] = 
					{
						["randomTransportable"] = false,
					},					
					["skill"] = asset.skill,
					["type"] = asset.name,
					["x"] = 0.0,
					["y"] = 0.0,            
					["name"] = warehouseName .. '_' .. asset.name,
					["playerCanDrive"] = true,
					["heading"] = 0,				
				},
			},
			["y"] = 0.0,
			["x"] = 0.0,
			["name"] = warehouseGroupTag..'_'..sideName..'_'..warehouseName..'_'..asset.name,
			["start_time"] = 0,
			["uncontrollable"] = false,
			["category"] = asset.groupCat,
			["country"] = asset.country,
			["task"] = "Ground Nothing",
		}   
	end
  
	return groupData
end

function M.smokeUnits(units, coalition, detectMaxCount)	
	if units ~= nil then
		for _,unit in pairs(units) do
			runner = runner + 1
			if runner <= detectMaxCount then			
				if coalition == 2 then
					unit:Smoke(trigger.smokeColor.Blue, 0, 2)				
				elseif coalition == 1 then
					unit:Smoke(trigger.smokeColor.Red, 0, 2)
				end
			end
		end
	end
end

function M.laseUnits(laser, units, laseDuration, laserCode, coalition, detectMaxCount)
	if units ~= nil then
		local runner = 0
		for _,unit in pairs(units) do
			runner = runner + 1
			if runner <= detectMaxCount then
				env.info("AW33COM utils.laseUnits lasing")
				laser:LaseUnit(unit, laserCode, laseDuration)
			end
		end
	end
end

return M
