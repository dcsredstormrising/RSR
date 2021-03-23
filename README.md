# RSR
A persistent PvP mission for DCS world.
## Test Client Setup
You can just download this repository as a zip and extract into your DCS.OpenBeta saved games location, 
and you should have everything you need independent of your coding enviroment. Once this is done, you will need to complete step #2 of the DCS Setup. Just doing these two 
things will allow you to run the mission outside of the server. You can run it straight from the mission editor, but only make changes to the mission editor if you have completed
the steps inside the Mission/readme.me
## Clone RSR Repo
If you would like to edit the RSR code, we request that you first clone the repo, then create a branch, and once the changes are ready do the pull request to the development branch of the RSR repo.  This will allow us to review the changes, and deploy them on the Test server.  Please update the serverSettings.lua with changes prior to submitting the pull request.
## Commit changes to Dev Branch
Again please be sure to do the pull request for the Development Branch of the RSR repo.
## DCS Setup
 1. From your install folder (not saved games), open `Scripts/MissionScripting.lua`
 2. Comment out all the lines in the do block below the sanitization function with `-\-`.  This allows the LUA engine access to the file system. It should look similar to:
```lua
  --sanitizeModule('os')
  --sanitizeModule('io')
  --sanitizeModule('lfs')
  --require = nil
  --loadlib = nil
```

## Currently all links point back to the github repository
## <a href="https://github.com/dcsredstormrising/RSR">LUA files</a>
The RSR/RedStormRising repository contains all the lua files required to run the mission. Once tested, submited and approved they are sent to the server and loaded. All the scripts are loaded through the RSR.lua 
### <a href="https://github.com/ModernColdWar/RSR-Syria/blob/main/RSR/AWACS_Tankers.lua">AWACS-Tankers.lua</a>
The <a href="https://github.com/ModernColdWar/RSR-Syria/blob/main/RSR/AWACS_Tankers.lua">AWACS-Tankers.lua</a> Contains moose snippets that generate an F10 menu to allow aircraft to call in AWACS and Tankers into the mission. 
### <a href="https://github.com/ModernColdWar/RSR-Syria/blob/main/RSR/CSAR.lua">CSAR.lua</a>
The <a href="https://github.com/ModernColdWar/RSR-Syria/blob/main/RSR/CSAR.lua">CSAR.lua</a> script allows for downed pilots to be recovered, and thier life returned. We also use the CSAR script to manage pilots lifes on a per restart basis.
### <a href="https://github.com/ModernColdWar/RSR-Syria/blob/main/RSR/EWRS.lua">EWRS.lua</a>
### <a href="https://github.com/ModernColdWar/RSR-Syria/blob/main/RSR/JTAC_Designate.lua">JTAC-Designate.lua</a>
### <a href="https://github.com/ModernColdWar/RSR-Syria/blob/main/RSR/Moose.lua">Moose.lua</a>
### <a href="https://github.com/ModernColdWar/RSR-Syria/blob/main/RSR/SGS_RSR.lua">SGS_RSR.lua</a>
### <a href="https://github.com/ModernColdWar/RSR-Syria/blob/main/RSR/UAV_Recon.lua">UAV-Recon.lua</a>
### <a href="https://github.com/ModernColdWar/RSR-Syria/blob/main/RSR/WeaponManager.lua">WeaponManager.lua</a>
### <a href="https://github.com/ModernColdWar/RSR-Syria/blob/main/RSR/mist_4_4_90.lua">mist_4_4_90.lua</a>
### <a href="https://github.com/ModernColdWar/RSR-Syria/blob/main/RSR/warehouseResupply.lua">warehouseResupply.lua</a>
