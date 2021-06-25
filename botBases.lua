
package.path  = package.path..";.\\LuaSocket\\?.lua;"..'.\\Scripts\\?.lua;'.. '.\\Scripts\\UI\\?.lua;'
package.cpath = package.cpath..";.\\LuaSocket\\?.dll;"

local JSON = require("json")
local inspect = require("inspect")
local socket = require("socket")
local udpEventHost = "127.0.0.1"
local udpEventPort = 9595

local reportable_sams = { '1L13 EWR','55G6 EWR','S-300PS 64H6E sr','Patriot str'}
local reportable_ships = {'CV_1143_5', 'KUZNECOW','Stennis','CVN_75','CVN_73','CVN_72','CVN_71','USS_Arleigh_Burke_IIa','VINSON'}
local reportable_bases = {'FARP', 'Invisible FARP','Gas platform'}

local udp = socket.udp()
udp:settimeout(0.01)
udp:setsockname("*", 0)
udp:setpeername(udpEventHost, udpEventPort)

local function sendBotEvent(dataToSend)
    local jsonEventTableForBot = JSON:encode(dataToSend)
    udp:send(jsonEventTableForBot)
end

local function update()
    --Airbase Table
    local bot_Airbases = {
        ['red_ownership'] = {},
        ['blue_ownership'] = {},
        ['spec_ownership'] = {},
    }

    for i,airbase in pairs(coalition.getAirbases(1)) do
        local aName = airbase:getCallsign()
        bot_Airbases['red_ownership'][#bot_Airbases.red_ownership + 1] = aName
    end


    for i,airbase in pairs(coalition.getAirbases(2)) do
        local aName = airbase:getCallsign()
        bot_Airbases['blue_ownership'][#bot_Airbases.blue_ownership + 1] = aName
    end
    bot_Airbases.id = 51
    sendBotEvent(bot_Airbases)
end

local function in_arr (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

local function getShips()
    --red ships
    for i, gp in pairs(coalition.getGroups(1,Group.Category.SHIP)) do
        data = (Group.getByName(Group.getName(gp)):getUnit(1))
        local name = Unit.getName(data)
        local unit
        if string.find(name,'Resupply') then
        else
            if Unit.getByName(name) then
                unit = Unit.getByName(name)
            end
            local tname = unit:getTypeName()
            if in_arr(reportable_ships,tname)then
                if unit then
                    local pos = unit:getPosition().p
                    if pos then
                        unitpos = pos
                    end
                end
                lat, lon = coord.LOtoLL(unitpos)
                local evtPosUpdate = {}
                evtPosUpdate.id=54
                evtPosUpdate.unit_name = name
                evtPosUpdate.lat = lat
                evtPosUpdate.lon = lon
                evtPosUpdate.unit_type = "carrier"
                evtPosUpdate.unit_ownership = 1
                sendBotEvent(evtPosUpdate)
            end
        end
    end

    --blue ships
    for i, gp in pairs(coalition.getGroups(2,Group.Category.SHIP)) do
        data = (Group.getByName(Group.getName(gp)):getUnit(1))
        local name = Unit.getName(data)
        if string.find(name,'Resupply') then
        else
            local unit
            if Unit.getByName(name) then
                unit = Unit.getByName(name)
            end
            local tname = unit:getTypeName()
            if in_arr(reportable_ships,tname)then
                if unit then
                    local pos = unit:getPosition().p
                    if pos then
                        unitpos = pos
                    end
                end
                lat, lon = coord.LOtoLL(unitpos)
                local evtPosUpdate = {}
                evtPosUpdate.id=54
                evtPosUpdate.unit_name = name
                evtPosUpdate.lat = lat
                evtPosUpdate.lon = lon
                evtPosUpdate.unit_type = "carrier"
                evtPosUpdate.unit_ownership = 2
                sendBotEvent(evtPosUpdate)
            end
        end
    end
end

local function getSams()
    --red sams
    for i, gp in pairs(coalition.getGroups(1,Group.Category.GROUND)) do
        data = (Group.getByName(Group.getName(gp)):getUnit(1))
        local name = Unit.getName(data)
        local unit
		if Unit.getByName(name) then
			unit = Unit.getByName(name)
		end
        local tname = unit:getTypeName()
        if in_arr(reportable_sams,tname)then
            if unit then
                local pos = unit:getPosition().p
                if pos then
                    unitpos = pos
                end
            end
            lat, lon = coord.LOtoLL(unitpos)
            local evtPosUpdate = {}
            evtPosUpdate.id=54
            evtPosUpdate.unit_name = name
            evtPosUpdate.lat = lat
            evtPosUpdate.lon = lon
            evtPosUpdate.unit_type = "sam"
            evtPosUpdate.unit_ownership = 1
            sendBotEvent(evtPosUpdate)
        end
    end

    --blue sams
    for i, gp in pairs(coalition.getGroups(2,Group.Category.GROUND)) do
        data = (Group.getByName(Group.getName(gp)):getUnit(1))
        local name = Unit.getName(data)
        local unit
		if Unit.getByName(name) then
			unit = Unit.getByName(name)
		end
        local tname = unit:getTypeName()
        if in_arr(reportable_sams,tname)then
            if unit then
                local pos = unit:getPosition().p
                if pos then
                    unitpos = pos
                end
            end
            lat, lon = coord.LOtoLL(unitpos)
            local evtPosUpdate = {}
            evtPosUpdate.id=54
            evtPosUpdate.unit_name = name
            evtPosUpdate.lat = lat
            evtPosUpdate.lon = lon
            evtPosUpdate.unit_type = "sam"
            evtPosUpdate.unit_ownership = 2
            sendBotEvent(evtPosUpdate)
        end
    end
end

local function getStartSams()
    -- Red Start AASystem North
    for i, gp in pairs(coalition.getGroups(1,Group.Category.GROUND)) do
        if Group.getByName('Red Start AASystem North'):getUnit(1) then
            data = (Group.getByName('Red Start AASystem North'):getUnit(1))
            local name = Unit.getName(data)
            local unit
            if Unit.getByName(name) then
                unit = Unit.getByName(name)
            end
            if unit then
                local pos = unit:getPosition().p
                if pos then
                    unitpos = pos
                end
            end
            lat, lon = coord.LOtoLL(unitpos)
            local evtPosUpdate = {}
            evtPosUpdate.id=54
            evtPosUpdate.unit_name = name
            evtPosUpdate.lat = lat
            evtPosUpdate.lon = lon
            evtPosUpdate.unit_type = "sam"
            evtPosUpdate.unit_ownership = 1
            sendBotEvent(evtPosUpdate)
        end
    end
    -- Blue Start AASystem North
    for i, gp in pairs(coalition.getGroups(2,Group.Category.GROUND)) do
        if Group.getByName('Blue Start AASystem North'):getUnit(1) then
            data = (Group.getByName('Blue Start AASystem North'):getUnit(1))
            local name = Unit.getName(data)
            local unit
            if Unit.getByName(name) then
                unit = Unit.getByName(name)
            end
            if unit then
                local pos = unit:getPosition().p
                if pos then
                    unitpos = pos
                end
            end
            lat, lon = coord.LOtoLL(unitpos)
            local evtPosUpdate = {}
            evtPosUpdate.id=54
            evtPosUpdate.unit_name = name
            evtPosUpdate.lat = lat
            evtPosUpdate.lon = lon
            evtPosUpdate.unit_type = "sam"
            evtPosUpdate.unit_ownership = 2
            sendBotEvent(evtPosUpdate)
        end
    end
end

local function getFarps()
    --red farps
    for i, gp in pairs(coalition.getAirbases(1)) do
        local base_type = gp:getTypeName()
        if in_arr(reportable_bases, base_type) then
            local pos = gp:getPosition().p
                if pos then
                    unitpos = pos
                end
            lat, lon = coord.LOtoLL(unitpos)
            local evtPosUpdate = {}
            evtPosUpdate.id=54
            evtPosUpdate.unit_name = gp:getName()
            evtPosUpdate.lat = lat
            evtPosUpdate.lon = lon
            evtPosUpdate.unit_type = "farp"
            evtPosUpdate.unit_ownership = 1
            sendBotEvent(evtPosUpdate)
        end
    end

    --blue farps
    for i, gp in pairs(coalition.getAirbases(2)) do
        local base_type = gp:getTypeName()
        if in_arr(reportable_bases, base_type) then
            local pos = gp:getPosition().p
                if pos then
                    unitpos = pos
                end
            lat, lon = coord.LOtoLL(unitpos)
            local evtPosUpdate = {}
            evtPosUpdate.id=54
            evtPosUpdate.unit_name = gp:getName()
            evtPosUpdate.lat = lat
            evtPosUpdate.lon = lon
            evtPosUpdate.unit_type = "farp"
            evtPosUpdate.unit_ownership = 2
            sendBotEvent(evtPosUpdate)
            env.info(inspect(evtPosUpdate))
        end
    end
    --neu farps
    for i, gp in pairs(coalition.getAirbases(0)) do
        local base_type = gp:getTypeName()
        if in_arr(reportable_bases, base_type) then
            local pos = gp:getPosition().p
                if pos then
                    unitpos = pos
                end
            lat, lon = coord.LOtoLL(unitpos)
            local evtPosUpdate = {}
            evtPosUpdate.id=54
            evtPosUpdate.unit_name = gp:getName()
            evtPosUpdate.lat = lat
            evtPosUpdate.lon = lon
            evtPosUpdate.unit_type = "farp"
            evtPosUpdate.unit_ownership = 0
            sendBotEvent(evtPosUpdate)
            env.info(inspect(evtPosUpdate))
        end
    end
end

local function startup_bases()
	for i, gp in pairs(coalition.getAirbases(1)) do
		local base_type = gp:getTypeName()
		if not string.find(base_type,"airbase") then
			local pos = gp:getPosition().p
				if pos then
					unitpos = pos
				end
			lat, lon = coord.LOtoLL(unitpos)
			local evtPosUpdate = {}
			evtPosUpdate.id=54
			evtPosUpdate.unit_name = gp:getName()
			evtPosUpdate.lat = lat
			evtPosUpdate.lon = lon
			evtPosUpdate.unit_type = "airbase"
			evtPosUpdate.unit_ownership = 1
			sendBotEvent(evtPosUpdate)
		end
	end
		for i, gp in pairs(coalition.getAirbases(0)) do
		local base_type = gp:getTypeName()
		if not string.find(base_type,"airbase") then
			local pos = gp:getPosition().p
				if pos then
					unitpos = pos
				end
			lat, lon = coord.LOtoLL(unitpos)
			local evtPosUpdate = {}
			evtPosUpdate.id=54
			evtPosUpdate.unit_name = gp:getName()
			evtPosUpdate.lat = lat
			evtPosUpdate.lon = lon
			evtPosUpdate.unit_type = "airbase"
			evtPosUpdate.unit_ownership = 0
			sendBotEvent(evtPosUpdate)
		end
	end
		for i, gp in pairs(coalition.getAirbases(2)) do
		local base_type = gp:getTypeName()
		if not string.find(base_type,"airbase") then
			local pos = gp:getPosition().p
				if pos then
					unitpos = pos
				end
			lat, lon = coord.LOtoLL(unitpos)
			local evtPosUpdate = {}
			evtPosUpdate.id=54
			evtPosUpdate.unit_name = gp:getName()
			evtPosUpdate.lat = lat
			evtPosUpdate.lon = lon
			evtPosUpdate.unit_type = "airbase"
			evtPosUpdate.unit_ownership = 2
			sendBotEvent(evtPosUpdate)
		end
	end
end

function CheckStatus(arg1,time)
   env.info("botBases - Base status check @ "..time)
   getShips()
   getStartSams()
   getFarps()
   update()
   return time + 300
end

startup_bases()
CheckStatus(1,timer.getTime())
timer.scheduleFunction(CheckStatus, 1, timer.getTime() + 300)