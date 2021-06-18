--- Red Storm Rising DCS mission LUA code
-- Add this dir and external paths (socket for calling n0xy's bot, luarocks systree for other dependencies)
-- note default path does not end with ; but the cpath does
package.path = package.path .. ";" .. lfs.writedir() .. [[Scripts\RSR\?.lua;.\LuaSocket\?.lua]]
package.cpath = package.cpath .. [[C:\dev\luarocks\lib\lua\5.1\?.dll]]

env.info("RSR STARTUP: RSR.LUA INIT")
require("Moose")
require("CTLD")
require("CSAR")
require("CONVOY_Menu")
require("ReconDrones")
local logging = require("logging")
local log = logging.Logger:new("RSR")

local rsrConfig = require("RSR_config")
if rsrConfig.devMode then
    log:warn("Running in developer mode - should not be used for 'real' servers")
    ctld.debug = true
    ctld.buildTimeFARP = 5
    ctld.crateWaitTime = 1
end

local persistence = require("persistence")
local slotBlocker = require("slotBlocker")
local baseCapturedHandler = require("baseCapturedHandler")
local hitEventHandler = require("hitEventHandler")
local birthEventHandler = require("birthEventHandler")
local genericEventHandler = require("genericEventHandler")
local deadEventHandler = require("deadEventHandler")
local restartInfo = require("restartInfo")
local SGS_RSR = require("SGS_RSR")
local SCUD_EventHandler = require("SCUD_EventHandler")
local warehouses = require("warehouses")
--local UAV_Designate = require("UAV_Designate")
local botBases = require("botBases")
require("EWRS_OPM")
local AWACS_Tankers = require("AWACS_Tankers")
local AI_CAP = require("AI_CAP")
local weathermark = require("WeatherMark")
local unitManagement = require("unitManagement")

slotBlocker.onMissionStart()
baseCapturedHandler.register()
persistence.onMissionStart(rsrConfig)
hitEventHandler.onMissionStart(rsrConfig.hitMessageDelay)
birthEventHandler.onMissionStart(rsrConfig.restartHours)
deadEventHandler.onMissionStart()
restartInfo.onMissionStart(rsrConfig.restartHours, rsrConfig.restartWarningMinutes)
_SETTINGS:SetPlayerMenuOff()
trigger.action.outText("RSR.LUA LOADED", 10)
env.info("RSR STARTUP: RSR.LUA LOADED")