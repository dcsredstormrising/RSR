local missionUtils = require("missionUtils")
local missionInfoMenu = require("missionInfoMenu")
local M = {}
M.eventHandler = nil  -- constructed in onMissionStart

M.BIRTH_EVENTHANDLER = {
    ClassName = "BIRTH_EVENTHANDLER"
}

function M.BIRTH_EVENTHANDLER:New(restartHours)
    local _self = BASE:Inherit(self, EVENTHANDLER:New())
    _self.restartHours = restartHours
    _self:HandleEvent(EVENTS.Birth, _self._OnBirth)
    _self.groupsMenusAdded = {}
    return _self
end

function M.BIRTH_EVENTHANDLER:_OnBirth(event)
    self:_AddMenus(event)	
end

function M.BIRTH_EVENTHANDLER:_AddMenus(event)
    if event.IniPlayerName then
        local playerGroup = event.IniGroup
        if playerGroup then
            local groupId = playerGroup:GetDCSObject():getID()
            local groupName = playerGroup:GetName()
            if self.groupsMenusAdded[groupName] then
                self:I("Not adding menus again for " .. groupName)
                return
            end
            self:I("Adding menus for " .. playerGroup:GetName())
            self.groupsMenusAdded[groupName] = true
            local unitName = event.IniUnitName
            self:AddMissionStatusMenu(playerGroup)
            self:_AddJTACStatusMenu(groupId, unitName)
            
            if missionUtils.isTransportType(playerGroup:GetTypeName()) then
                self:_AddTransportMenus(groupId, unitName, playerGroup)
            else
                self:_AddRadioListMenu(groupId, unitName)
                self:_AddLivesLeftMenu(playerGroup, unitName)
            end

            self:_AddEWRS(groupId, event.IniDCSUnit)
        end
    else
        self:_NonPlayerRouter(event)
    end
end

--luacheck: push no unused
function M.BIRTH_EVENTHANDLER:_AddJTACStatusMenu(groupId, unitName)
    if ctld.JTAC_jtacStatusF10 then
        missionCommands.addCommandForGroup(groupId, "JTAC Status", nil, ctld.getJTACStatus, { unitName })
    end
end

function M.BIRTH_EVENTHANDLER:_AddWeaponsManagerMenus(groupId)
    --missionCommands.addCommandForGroup(groupId, "Show weapons left", nil, weaponManager.printHowManyLeft, groupId)
    --missionCommands.addCommandForGroup(groupId, "Validate Loadout", nil, weaponManager.validateLoadout, groupId)
end

function M.BIRTH_EVENTHANDLER:_AddTransportMenus(groupId, unitName, playerGroup)
    local _unit = ctld.getTransportUnit(unitName)
    local _unitActions = ctld.getUnitActions(_unit:getTypeName())

    csar.addMedevacMenuItem(unitName)
    ctld.addF10MenuOptions(unitName)
    Convoy.AddMenu(playerGroup)
    -- mr: shortcuts disabled for now as intermittently not working for unknown reasons e.g. unitName not passed or = nil
    --[[
        if ctld.enableCrates and _unitActions.crates then
            if ctld.unitCanCarryVehicles(_unit) == false then
                if _unit:getTypeName() == "Mi-8MT" or _unit:getTypeName() == "Ka-50" then
                    ctld.addCrateMenu(nil, "Heavy crates", _unit, groupId, ctld.spawnableCrates, ctld.heavyCrateWeightMultiplier)
                else
                    ctld.addCrateMenu(nil, "Light crates", _unit, groupId, ctld.spawnableCrates, 1)
                end
            end
        end
        if (ctld.enabledFOBBuilding or ctld.enableCrates) and _unitActions.crates then
            if ctld.hoverPickup == false then
                if ((ctld.slingLoad == false) or ((ctld.internalCargo == true) and (_unitActions.internal == true))) then
                    missionCommands.addCommandForGroup(groupId, "Load Nearby Crate", nil, ctld.loadNearbyCrate, unitName)
                end
            end
            missionCommands.addCommandForGroup(groupId, "Unpack Nearby Crate", nil, ctld.unpackCrates, { unitName })
            if (ctld.slingLoad == false) or (ctld.internalCargo == true) then
                missionCommands.addCommandForGroup(groupId, "Load Nearby Crate", nil, ctld.loadNearbyCrate, { unitName })
                missionCommands.addCommandForGroup(groupId, "Drop Crate", nil, ctld.unloadInternalCrate, { unitName })
            end
        end
        if _unitActions.troops then
            missionCommands.addCommandForGroup(groupId, "Unload / Extract Troops", nil, ctld.unloadExtractTroops, { unitName })
        end
        --]]
end

function M.BIRTH_EVENTHANDLER:_AddRadioListMenu(groupId, unitName)
    if ctld.enabledRadioBeaconDrop then
        missionCommands.addCommandForGroup(groupId, "List Radio Beacons", nil, ctld.listRadioBeacons, { unitName })
    end
end

function M.BIRTH_EVENTHANDLER:_AddLivesLeftMenu(playerGroup, unitName)
    MENU_GROUP_COMMAND:New(playerGroup, "Show remaining lives", nil, function()
        local unit = Unit.getByName(unitName)
        if unit ~= nil then
            local playerName = unit:getPlayerName()
            if playerName ~= nil then
                local lives = csar.getLivesLeft(playerName)
                if lives ~= nil then
                    local message = string.format("You have %d %s remaining", lives, lives == 1 and "life" or "lives")
                    MESSAGE:New(message, 5):ToGroup(playerGroup)
                end
            end
        end
    end)
end

function M.BIRTH_EVENTHANDLER:AddMissionStatusMenu(playerGroup)
    MENU_GROUP_COMMAND:New(playerGroup, "Mission Status", nil, function()
      MESSAGE:New(missionInfoMenu.getMissionStatus(playerGroup, self.restartHours), 25):ToGroup(playerGroup)
    end)
end

function M.BIRTH_EVENTHANDLER:_AddEWRS(groupId, unit)
    local playerName = unit:getPlayerName()
    if playerName ~= nil and ewrs.enabledAircraftTypes[unit:getTypeName()] then
        ewrs.buildF10Menu(groupId)
        ewrs.addPlayer(playerName, groupId, unit)
    end
end

function M.BIRTH_EVENTHANDLER:_NonPlayerRouter(event)
    --Make sure not static
    if event.IniGroup then
        local groupName = event.IniGroup:GetName()
        local coalitionNumber = event.IniCoalition
        if string.match(groupName, "Convoy Transport") then
            Convoy.ConvoyTransportGroupBorn(coalitionNumber)
        elseif string.match(groupName, "Convoy Group 1") then
            Convoy.ConvoyGroupBorn(coalitionNumber)
        end  
    end
end
-- luacheck: pop

function M.onMissionStart(restartHours)
    M.eventHandler = M.BIRTH_EVENTHANDLER:New(restartHours)
end

return M
