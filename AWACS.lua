-- =AW=33COM Simple rewrite of our AWACS code to fix the crazy menu loops
local utils = require("utils")
local inspect = require("inspect")
AWACS = {}
local awacsMaxCount = 4 -- per session
local awacsMaxCountAtOnce = 2
local blueAWACSCount = 0
local redAWACSCount = 0
local spawnerName = nil
