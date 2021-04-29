local baseOwnershipCheck = require("baseOwnershipCheck")
local M = {}

M.eventHandler = nil  -- constructed in onMissionStart

M.DEAD_EVENTHANDLER = {
    ClassName = "DEAD_EVENTHANDLER"
}

function M.DEAD_EVENTHANDLER:New()
    local _self = BASE:Inherit(self, EVENTHANDLER:New())
    _self:HandleEvent(EVENTS.Dead, _self._OnDead)
    return _self
end

function M.DEAD_EVENTHANDLER:_OnDead( event )
    env.info("deadEventHandler: TYPE: $1, DCS NAME: $2, UNIT: $3", event.IniTypeName, event.IniDCSUnitName, event.IniDCSUnit)

    local _deadUnitCategory = event.IniObjectCategory
    local _deadUnitType = event.IniTypeName
    local _deadUnitName = event.IniDCSUnitName
    local _deadGroupName = event.IniGroupName
    --log:info("eventHander DEAD: TEST1 DEAD LC = nil: $1",_deadUnit == nil)
    
    if string.match(_deadGroupName, "Convoy Transport") then
        env.info("CONVOY: TRANSPORT DESPAWNED")
    end

    if _deadUnitCategory == Object.Category.STATIC then
        --[[
        -- MOOSE
            if Event.IniObjectCategory == Object.Category.STATIC then
            Event.IniDCSUnit = Event.initiator
            Event.IniDCSUnitName = Event.IniDCSUnit:getName()
            Event.IniUnitName = Event.IniDCSUnitName
            Event.IniUnit = STATIC:FindByName( Event.IniDCSUnitName, false )
            Event.IniCoalition = Event.IniDCSUnit:getCoalition()
            Event.IniCategory = Event.IniDCSUnit:getDesc().category
            Event.IniTypeName = Event.IniDCSUnit:getTypeName()
            end
        --]]

        if _deadUnitType == ctld.logisticCentreL3 or _deadUnitType == ctld.logisticCentreL2 then

            local _storedLogisticsCentreBase = "NoLCbase"
            local _storedLogisticsCentreName = "NoLCname"
            local _storedLogisticsCentreSideName
            local _storedLogisticsCentreMarkerID

            for _LCsideName, _baseTable in pairs(ctld.logisticCentreObjects) do

                for _LCbaseName, _storedLogisticsCentre in pairs(_baseTable) do

                    if _storedLogisticsCentre ~= nil then
                        _storedLogisticsCentreName = _storedLogisticsCentre:getName() --getName = DCS function, GetName = MOOSE function
                        _storedLogisticsCentreBase = string.match(_storedLogisticsCentreName, ("^(.+)%sLog")) --"Sochi Logistics Centre #001 red" = "Sochi"
                        _storedLogisticsCentreSideName = string.match(_storedLogisticsCentreName, ("%w+$")) --"Sochi Logistics Centre #001 red" = "red"

                        --log:info("eventHander DEAD: _storedLogisticsCentre: $1, _storedLogisticsCentreName: $2, _storedLogisticsCentreBase: $3, _storedLogisticsCentreSideName: $4", _storedLogisticsCentre, _storedLogisticsCentreName, _storedLogisticsCentreBase, _storedLogisticsCentreSideName)

                    end

                    --log:info("eventHander DEAD: _logisticsCentreName: $1, _deadUnitName: $2", _storedLogisticsCentreName, _deadUnitName)
                    --log:info("eventHander DEAD: _storedLogisticsCentreBase: $1, _LCbaseName: $2", _storedLogisticsCentreBase, _LCbaseName)
                    if _storedLogisticsCentreName == _deadUnitName and _storedLogisticsCentreSideName == _LCsideName and _storedLogisticsCentreBase == _LCbaseName then

                        --log:info("eventHander DEAD (PRE): ctld.logisticCentreObjects[_LCsideName][_LCbaseName]: $1",ctld.logisticCentreObjects[_LCsideName][_LCbaseName])
                        ctld.logisticCentreObjects[_LCsideName][_LCbaseName] = nil
                        --log:info("eventHander DEAD (POST): ctld.logisticCentreObjects[_LCsideName][_LCbaseName]: $1",ctld.logisticCentreObjects[_LCsideName][_LCbaseName])

                        -- remove map marker
                        _storedLogisticsCentreMarkerID = ctld.logisticCentreMarkerID[_LCsideName][_LCbaseName]
                        trigger.action.removeMark(_storedLogisticsCentreMarkerID)
                        ctld.logisticCentreMarkerID[_LCsideName][_LCbaseName] = nil

                        -- (_checkWhichBases,_playerName,_campaignStartSetup)
                        baseOwnershipCheck.baseOwnership = baseOwnershipCheck.getAllBaseOwnership("ALL", "LCdead", false)
                        return
                    end
                end
            end
        end
    end
end

function M.onMissionStart()
    M.eventHandler = M.DEAD_EVENTHANDLER:New()
end

return M
