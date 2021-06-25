--LOAD REQUIRED LIBS
local socket = require("socket")
local JSON = require("json")
--local inspect = require("inspect")
local playerList = {}
local dataToSend = {}

-----------------------------------
--options!
-----------------------------------
local udpEventHost = "127.0.0.1"
local udpEventPort = 9595
--set this to false if you want BOT Voice Channel checking AND UCID Table lookup!
JustBotCheckingOnly = true


function queryBotAPI(endpoint)
    -- the host value here is always 127.0.0.1, the bot has to run locally to the server.
    local host = "127.0.0.1"
    local port = 8000
    local c = socket.tcp()
    c:settimeout(1)
    c:connect(host, port)
    --the connect function above has ZERO connection-state awareness. The only way to check if its open, is to attempt to send data.
    --in this case, sending will return the number of bytes sent, the error (if there is one), and index of the last byte sent (if its interrupted mid-send.)
    local bytesSent, sendError, lastByteSent = c:send("GET "..endpoint.." HTTP/1.1\r\nHost: "..host..":"..port.."\r\nConnection: close\r\n\r\n")

    --if bytessent isnt nil, then it sent the request.
    if bytesSent then
        --now we loop through and receive the response from the api, and concatenate it all into a string.
        local result = ""
        while true do
            local s, status, partial = c:receive()
            result = result .. "\n" .. (s or partial)
            if status == "closed" then
                break
            end
        end
        --close the connection!
        c:close()
        --split the result into a useable table.
        local response = {}
		--net.log(inspect(response))
        for str in string.gmatch(result, "([^\n]+)") do
                table.insert(response, str)
				net.log(str)
        end
		
        status = string.sub(response[1],10)
        body = response[7]
        --check the response status. if its anything other than 200, theres an error so fail. if its 200, send the response body back to whatever called this function.
        if status ~= "200 OK" then
            return "FAIL"
        else
            return body
        end
    else
        -- The connection to the botAPI didnt work, for whatever reason, so log this and return a FAIL response to the caller.
        net.log("BotAPI Error: "..sendError)
		c:close()
        return "FAIL"
    end
end


char_to_hex = function(c)
  return string.format("%%%02X", string.byte(c))
end

function urlencode(url)
  if url == nil then
    return
  end
  url = url:gsub("\n", "\r\n")
  url = url:gsub("([^%w ])", char_to_hex)
  url = url:gsub(" ", "+")
  return url
end

local function sendBotEvent(dataToSend)
    local udp = assert(socket.udp())
    udp:settimeout(0.01)
    assert(udp:setsockname("*", 0))
    assert(udp:setpeername(udpEventHost, udpEventPort))
    local jsonEventTableForBot = JSON:encode(dataToSend) --Encode the event table
    assert(udp:send(jsonEventTableForBot))
    --net.log(jsonEventTableForBot)
end

--gets all the players, sorts em by side and sends it to the bot (json encoded). The bot stores the players per side :: e.g {"BoardBlue":"player1,player2","BoardRed":"player3,player4","BoardSpec":"someweasel,someweasel2"}
local function getPlayerList()
	local plist = net.get_player_list()
	local redCount = ""
	local blueCount = ""
	local specCount = ""
	for k,v in pairs(plist) do
		local pdata = net.get_player_info(v)
		local pid = pdata.id
		local pname = pdata.name
		local pside = pdata.side
		if(pside == 1)
		then
			redCount = redCount .. pname .. ","
		end
		if(pside == 2)
		then 
			blueCount = blueCount .. pname .. ","
		end
		if(pside == 0)
		then 
			specCount = specCount .. pname .. ","
		end
	end
	dataToSend.id = 50
	dataToSend.board_blue = blueCount
	dataToSend.board_red = redCount
	dataToSend.board_spec = specCount
	sendBotEvent(dataToSend)
end


--update the board when a player swaps slots. itll update the WHOLE board.
playerList.onPlayerChangeSlot = function(playerID)
    if  DCS.isServer() and DCS.isMultiplayer() then
		getPlayerList()
    end
end

playerList.onChatMessage = function(message, whofrom)
	net.log("CHAT: "..whofrom .." : "..message)
	local eventData = {}
	eventData.id = 52
	eventData.initiator = whofrom
	if net.get_player_info(whofrom) ~= nil then
            local playerDetails = net.get_player_info(whofrom)
            eventData.initiator = playerDetails.name
            eventData.initiator_coalition = playerDetails.side
			if message == "-taccomcheck" then
				--net.log("tac checker")
				for k, v in pairs(net.get_player_list()) do
					local side,slot = net.get_slot(v)
					if string.find(slot,"artillery_commander") or string.find(slot,"forward_observer") or string.find(slot, "observer") then
						local playerName = net.get_player_info(v,'name')
						local playerUcid = net.get_player_info(v,'ucid')
						--net.log("player " .. playerName .. playerUcid .. " is in slot " .. slot)
						local res = {}
						local decode = {}
						local found = false
						--net.log("taccheck 1")
						--get the gci members from discord
						local res = queryBotAPI("/api/voice/".. playerUcid)
						--check for fail reponse from the queryBotAPI func.
						--if its FAIL, it means the connection to the API failed (bots not running), so pretend the player was found in the response.
						--net.log("taccheck 2")
						if res == "FAIL" then
							found = true
							--net.log("taccheck fail")
						else
							--if the api request didnt fail, decode the JSON response, and check the value of "success". 1 = theyre in voice, 0 = not in voice
							--net.log("taccheck success")
							local decode = JSON:decode(res)
							--net.log(inspect(decode))
							if decode["response"] == "1" then
								--do nothing, its a success.
								--net.log("taccheck status 1")
							else
								--kickem.
								--net.log("taccheck status 0")
								net.send_chat_to("Commander slots require you to be in voice.",v)
								net.force_player_slot(v,0,'')
							end
						end
					end
				end
			end
    end 	
	eventData.chat_message = message
	sendBotEvent(eventData)
end

playerList.onTriggerMessage = function(message, duration, clearview)
	local eventData = {}
	eventData.id = 52
	eventData.initiator_coalition = 4
	eventData.initiator = "MSG"
	eventData.chat_message = message
	sendBotEvent(eventData)
end

playerList.onPlayerConnect = function(id)
	local eventData = {}
	if net.get_player_info(id) ~= nil then
            local initiatorDetails = net.get_player_info(id)
            eventData.initiator = initiatorDetails.name
            eventData.initiator_ucid = initiatorDetails.ucid
    end
	eventData.id = 55
	sendBotEvent(eventData)
end


playerList.onGameEvent = function(eventName,arg1,arg2,arg3,arg4,arg5,arg6,arg7) 
    if eventName == "unit_lost" then
        net.log("unit lost: ".. arg1 .. arg2 .. arg3)
    end
    if eventName == "kill" then
        local eventData = {}
        
        --initiator - if you cant get the player_info of the id, it means they are AI. probably ground target or awacs (ill count em as the same)
        if net.get_player_info(arg1) ~= nil then
            local initiatorDetails = net.get_player_info(arg1)
            eventData.initiator = initiatorDetails.name
            eventData.initiator_ucid = initiatorDetails.ucid
        else    
            eventData.initiator = "AI"
        end
        eventData.initiator_coalition = arg3

        --target - if you cant get the player_info of the id, it means they are AI.
        if net.get_player_info(arg4) ~= nil then
            local targetDetails = net.get_player_info(arg4)
            eventData.target = targetDetails.name
        else    
            eventData.target = "AI"
        end
		if arg6 ~=nil then
			eventData.target_coalition = arg6
		end
        --weapon/misc
        eventData.id = 28
        eventData.weapon = arg7
        eventData.time = 1.1
        sendBotEvent(eventData)
    end

    if eventName == "pilot_death" then
        local eventData = {}
        --initiator
        if net.get_player_info(arg1) ~= nil then
            local initiatorDetails = net.get_player_info(arg1)
            eventData.initiator = initiatorDetails.name
			eventData.initiator_ucid = initiatorDetails.ucid
            eventData.initiator_coalition = initiatorDetails.side
        else    
            eventData.initiator = "AI"
        end
        
        --weapon/misc
        eventData.id = 9
        eventData.time = 1.1
        sendBotEvent(eventData)
    end

    if eventName == "crash" then
        local eventData = {}

        --initiator
        if net.get_player_info(arg1) ~= nil then
            local playerDetails = net.get_player_info(arg1)
            eventData.initiator = playerDetails.name
			eventData.initiator_ucid = initiatorDetails.ucid
            eventData.initiator_coalition = playerDetails.side
        else    
            eventData.initiator = "AI"
        end
        eventData.home_base = arg3

        --weapons/misc
        eventData.id = 5
        eventData.time = 1.1
        sendBotEvent(eventData)
    end

    if eventName == "eject" then
        local eventData = {}

        --initiator
        if net.get_player_info(arg1) ~= nil then
            local playerDetails = net.get_player_info(arg1)
            eventData.initiator = playerDetails.name
			eventData.initiator_ucid = initiatorDetails.ucid
            eventData.initiator_coalition = playerDetails.side
        else    
            eventData.initiator = "AI"
        end
        eventData.home_base = arg3
        
        --weapon/misc
        eventData.id = 6
        eventData.time = 1.1
        sendBotEvent(eventData)
    end

    if eventName == "takeoff" then
        local eventData = {}

        --initiator
        if net.get_player_info(arg1) ~= nil then
            local playerDetails = net.get_player_info(arg1)
            eventData.initiator = playerDetails.name
			eventData.initiator_ucid = initiatorDetails.ucid
            eventData.initiator_coalition = playerDetails.side
        else    
            eventData.initiator = "AI"
        end
        eventData.home_base = arg3

        --weapon/misc
        eventData.id = 3
        eventData.time = 1.1
        sendBotEvent(eventData)
    end

    if eventName == "landing" then
        local eventData = {}

        --initiator
        if net.get_player_info(arg1) ~= nil then
            local playerDetails = net.get_player_info(arg1)
            eventData.initiator = playerDetails.name
			eventData.initiator_ucid = initiatorDetails.ucid
            eventData.initiator_coalition = playerDetails.side
        else    
            eventData.initiator = "AI"
        end
        eventData.home_base = arg3
        --weapon/misc
        eventData.id = 4
        eventData.time = 1.1
        sendBotEvent(eventData)
    end
	
	if eventName == "base captured" then
		local eventData = {}
		eventData.id = 10
		eventData.place = arg2
		eventData.initiator = arg1
		net.log("BASE CAP EVENT")
		sendBotEvent(eventData)
	end

end
-- ABOVE ARE THE BOT FUNCTIONS
-------------------------------------------------------------------------------
-- 
-------------------------------------------------------------------------------
-- BELOW ARE THE SLOTBLOCKING HOOKS


net.log("Loading RSRSlotBlocker...")
local M = {}
--simple per-session side lock init
M.sidelock = {}
M.sidelock.blue = {}
M.sidelock.red = {}


-- RSR developers and admins
M.gameMasterUcids = {
    "46f14d9df21bcca261da5d54ff77b6a8", -- Winston
    "117bc9e9faafa19d71f099d650cf1b0c", -- deebix
    "64cb0b85fffe51c3e79ecd8f13766ded", -- Wildcat/Chandawg
    "cbb43fc99e978ee535b86653d14e5dbc", -- Mobius
    "99bc992d15a8b9366c1af3873f53a895", -- Capt.Fdez
    "231aa8ac940aa8a712c1f17c2a3f0122", -- Flashheart
    "6e14d6e4deb4bf3b08d99713754cd1dc", -- n0xy Steam
    "87dd983a6c5b678de30c9adb55b18cf4", -- n0xy Standalone
    "263d36e3b60782a6c16e2b3c5cebf3f9", -- mad rabbit

}

M.tacCmdrUcids = {
    "9afc4637083feaf599e78b25b37adf25",
    "053ec863e71f9b83f1dc3155a3563ee6",
    "f47be7b9564d03e6d8a75313efeba92a",
    "117bc9e9faafa19d71f099d650cf1b0c", -- Deebix
    "cbb43fc99e978ee535b86653d14e5dbc", -- Mobius
    "64cb0b85fffe51c3e79ecd8f13766ded", -- Wildcat/Chandawg
    "0f8240487915af76a6f44a41c01cde47",
    "182fb65bdbbdf9566d7cefeaab8c3c25",
    "7d5c7a1b8bf4e5bee87cf9fd20d3a90c", -- Lord Felix
    "e2b6cc3261d5513faaaffe8a7c157a32",
    "a0d2bd3f8eea70563d49cae543f4ed8f",
    "ebb1471000e15b3ca240910d82342503", --Savage
    "e711c21cecbfb91534afa41275027291", -- Hbomb
    "57c75549549a256464978b7a7deba4c8",
    "9d70024558a2a3949c2ae9b8b9f79669",
    "e5d0f5316232e5802ced7cc4c86d2c95",
    "5d619981c0a192bda60c927bd6fbccf9",
    "24b0e1cfc1b27e375d38a98a43db9779",
    "d7f6161e6401a1c9c1f31ba7315e647c",
    "60eaa32a48cdf3b1162739acf7cfec28", --DakiBajoMoj
    "6e1c8117ab788fa693feec6326320a5e",
    "842514dc165092ba9631f8c7d2052d0a",
    "837f1acd1132ed0a60f2a6a1f57bcc1c", -- Smitty
    "b12d9af45f2b08a353f1e706e034eaec",
    "0a312f0e5531d0fb0e1b1d90bb559fa3",
    "e011e49e75560dbe802d50cd0f1ce68d",
    "80981e82a3f8b8178c232ddc96d7fe40",
    "3beb7082568d91bdeb29282d840c4e76",
    "3b1623a591687015f620aaba1598b3ca",
    "6151a2842ea86fd5bf7274fdf0cce579",
    "67d27f9376433f555b1ae71c2872c584",
    "f3120f75fa5d66e5a1adaeea4f303c3d", -- Drif
    "a9a6ba83cc166d960fcf7ef3d8a20eb9",
    "c0fda776e215e597c37c92fb9dde70fb",
    "9d76164a91c872953a4f1ab378f0e008",
    "a78d9cc5ad679f472dc36f66c71d99db", -- Canuck
    "dc91af6f5f48dd94c89ace508c17cc69",
    "eae6f83ee3693287e92229d7eeab25b3",
    "5df2d8f9d4675adf07a1d0f7eed7f9e0",
    "b0d7c14dd6fe1ac1ef203643512f4387", -- Two Lives
    "22f8d3edba38b8052c3b82242262a867", -- Shatten55
    "630959d9628dce969646b5ce279a5996", -- crazzymrbc
    "18228f3b7ecb8b5af9cb7965870d3f1b", -- EARL 4-2 | H4nS0L0
    "822f0042190141165d100ccffe8d2cbf", -- EARL 1-4 | alxz
    "fff7b6fabadc7339a246fa5330ceb3b2", -- SaabFAN
    "a1f7bf58006730415c9cdda22b2f89b2", -- EARL 6-4 | CYPHER
    "5d194005968acd3db845fdae1f1575e9", -- Checklist
    "07aa971b0e583a05c69dc06075bedabf", -- HansPeter
    "703a4d348871ec2fe9cac9cd2168f609", -- NightStalker
    "5cb74e04677581b97c65d7ac67872b99", -- Woodstock
    "e1277ddbc6cc620bfbc9ceb0f57dc19c", -- Airplaneman321
    "2e9713fc055304fe1bd6c6c778c0f620", -- LeoNerd
    "91ec71924c23f4f15d785f5d7105e6b3", -- Salad
    "9b1a9d6714bfc414eb0c2e5158f75c89", -- -=*26th*=- | Pakster
    "4f306d55e7ca9d3c683ebd983ad6c859", -- Firefly
    "afce946e4b300ebc03bbbfdee7b07f31", -- <64>Kazansky
    "10fb130391f045766bb836e7c9f66c2c", -- Viper 77|Gandalf
    "964158664f15dd3d7fbb0ea80c6b296f", -- The State|LTJG SNOT
    "20dd4b54a9fc51df4d38cd8955103361", -- Disco
    "f10c00accc6b3f694490dbb307988e1d", -- ROGUE | Archangel
    "6cb230729c620cd22eea9a1900279dcb", -- GasMachine
    "a72632f9d4aef4bc3fc12fb0a6bcdc87", -- =R|D= johnnytrump
    "d125549aa96ca9c8c021e7bfb1028d7c", -- Tester
    "d26bb6e1f0b5268626d41a0feef17727", -- Shabi
    "b67841fbaf484d62fd93c159f00a5a78", -- ALA15-Snake
    "19db9ec1f7b12df8c89360e17a31d7ef", -- VS33 Stroke
    "53ecb670a7fa0147ccf6ab8af0eb7f9d", -- wolfy
    "0905260d71275b3f8051e42d73b96a19", -- {WD} bert, added by Capt.Fdez
    "7e8563b5c0ae6d9657de5758395c2406", -- ZZ added by deebix
    "8f3e2a5beadbd739a973027607f4a5cc", -- Rigez added by mad rabbit
    "7c6028ee85d15cb5008a07403f486522", -- outcast 1-1 by deebix
    "37922d84eaf6bb71e775a54af9b1c75d", -- Drip added by deebix
    "88e28730b17a4cacae63e61fafbded1e", -- Airogue added by mad rabbit
    "a83dd704a242de5450deec9887e7c9d3", -- Sephryn added by mad rabbit
    "079236f5f48b0350bdaf364d042dccfe", -- rocket_knight added by deebix
    "c70c2a7bb2d855e80bcf4964ee1daaeb", -- moupe added by deebix
    "9de0e2e317a56c09aecff8eeeecdd47a", -- =AW=33COM added by mad rabbit
    "7695c98ec481ce38dc1728d469dbd5ba", -- Kestrel added by mad rabbit
    "062792cea85dc2159a74a82e0ceeeff3", -- REAPER 54 | Sturdyguns added by mad rabbit
    "c3bb707bca08093fdb732fcf3f99fa5a", -- Sauce added by mad rabbit
    "89e2077ea937fbed24efe004e16e9739", -- NIGHTFOX 2 [GER] added by mad rabbit
    "5c9b2c4bd446d3b64a7c60efd35b3cfa", -- Ayey added by mad rabbit
    "1d31532cc4a452bb55dafa22e034e40d", -- [VMO-2] ApacheRed [BiH] added by mad rabbit
    -----------------------------------
    -- Penis clan
    "4c38b2e3c3647473512e5400017df50e", -- 8==D Ritt
    "92fd1d66e41dfa65c7dd73b4f309db87", -- 8==D Texas
    "2afada4c6dcd47147a1140cea34bc43a", -- 8==D Redback
    "d64300a70517b5878f2aae5cc4e96968", -- 8==D Shively
    "a73cc77ec3926ac636a4fd419f1c0fb5", -- 8==D Jarhead
    "c7dade15a8a58dca9d91e12402b77e65", -- 8==D Jarhead
    "b7477d13cfac623b3ca55e1e2dd0df1f", -- 8==D Guns
    "e64dcbab81dcdb157439018fc6e76488", -- 8==D Zooker
    -----------------------------------
    -- Russian Players
    -----------------------------------
    "53c1017106f484956c9e56d8c4b85acb", -- GenaPilot
    "3dd6e3bcd9f99a8826e8f9791dc15199", -- Sakhalin66
    -- ROSS Clan
    "09bc71361a591195159e2b84dfc67482", -- ROSS_Pups added by deebix
    "20ef9ad2392e236cf72cd3f3a853da42", -- ROSS_BoomSbk added by mad rabbit
    "253bbe973927a779286cdbef17928f30", -- ROSS_Checkist added by mad rabbit
    "566dadeeeede5c4c21322bf5c2e6b30f", -- ROSS_Kuzia added by mad rabbit
    "90d0af5d35b62cc5012de966b5bd1dcf", -- ROSS_Harkonnen added by mad rabbit
    "e61489151c2de788e78e8c92b97a2cca", -- ROSS berrymore by deebix
    "7fa9836632054f227b042f6a185b957c", -- ROSS grishik by deebix
    "2ae207adbe9eb102edaaee21e20211c1", -- ROSS_Gorillaz added by mad rabbit
    -- TOPHATTERS Clan
    --"6582f8c67aae73d83134e21cfbe73e35", -- TOPHATTERS 200 | Adler added by mad rabbit (not yet requested)
    --"e9f2b5115c161b629fd4a18e99446e4e", -- TOPHATTERS 211 | Bes added by mad rabbit (not yet requested)
    "7a88f3ed4ba0e1fd52e2d751befa6ce8", -- TOPHATTERS 203 | Adwar added by mad rabbit
    "df80fd4f0f8683328658631998b1c8cc", -- TOPHATTERS 222 | Pitkun added by mad rabbit
    -----------------------------------
    "00e5296e187ccfb8ee5edb55a7968d39", -- â˜…Ð’Ð�Ð Ð¯Ð“â˜…
    "b148135d459915551e3d2b5489821c16", -- Santa
    "e5f8848b3ef84a88c635e5bc2a8e2a41", -- Djim
    "25bd8aec82ad88e26c5534abddb3cc22", -- HanSolo
    "aea4fb0972eb001320d390b7a955356b", -- Ð�Ð¾Ð²Ð¾Ð‘Ñ€Ð°Ð½ÐµÑ†
    "a1aef3ef90d4e611eb8bd40a21ab26cd", -- Coldays
    "1d62619fb7ccd513e9f7cd639ad595bb", -- Lam, added by Mobius
    "4052f4b970efd04829623d087898a66f", -- =KAG=Zakha
    "1d086e78fb0870ad682ff5ee90aa94fd", -- -=WildCat=-
    -----------------------------------
    "6b042842639036e651eb1efc3da3233f", -- ~SCAR~ Vulture 27 added by Chandawg
    "0a603dfc6c7a71f0541ffac4bb353c9a", -- ~SCAR~ Blackhawk added by Chandawg
    "34f87245200b1a32d10da41c6c8b6dbf", -- Goblin 6-9 added by Chandawg
    "58d656379adf57b36ce5c23300b1de3b", -- Enigma added by Chandawg
    "44bbf11dd53fd0dd1441645280bedb92", -- Kaider added by Chandawg
    "24ea50e9bb162021d2e79f9ded1f9033", -- =BK=Krypto added by Chandawg
    "231aa8ac940aa8a712c1f17c2a3f0122", -- Flashheart added by Chandawg
    "e784ff1723dc9d810482184006a018cd", -- Aurora 4-1 | DanielNL added by Chandawg
    "f71dcbb5df5800ffd6289cb228fb8417", -- Figjam added by Chandawg
    "0e4ad640360ede636b97db75d5797039", -- RogueBat added by Chandawg
    "18044c89bfd4b4bcda1e538da3a442ff", -- SwooperDuper added by Chandawg
    "2534dbad9f36ddab28e2979a4fd98cf2", -- GreyCat_SPb added by Chandawg
    "7529aeda41cccf0e1a8ee78a025f431a", -- TMAC added by Chandawg
    "da407b5d0d97584e8ca5a50f770f79e6", -- Wanganui Wildcat added by Chandawg
    "dfbdef0a5fda039a98c7efb4f2bc15c1",	-- NikHeli by deebix
    "8b1ddd64b3b4f2694231d9fb8c006c02", -- fela by Mobius
    "ead96425cf877ec7d99ac4944436e423", -- Whiskey by Enigma
    "a4749f4bea30ec98b98d764667b767b8", -- ROGUE | Cdt. Dean by Enigma
    "2cf6ca78f6de38250eef5c3552edbee4", -- Huggies by Enigma
    "d180c58d290ba406a889c03ea1ad9f1b", -- Athena | Flint by Enigma
    "87dd983a6c5b678de30c9adb55b18cf4", -- N0xy by Enigma
    "cfe80f48a9c92f612b49ad11ee978081", -- Asurada by Enigma
    "bd1b1e6eba359a354a25dc3aec5e2b6d", -- MadCows by Enigma
    "1af05b6ae7f34f5838814220ab136e3c", -- ROGUE | Leumi by Enigma
    "142a1398c0258cf5de1844fd58192b9a", -- Mongoose by Enigma
    "2a7e3690f63586b4c03c8ba081324736", -- Huggies by Enigma
    "bfac4912fc76ce35ea9b23fca847469f", -- Laki by Enigma
    "e6e3d94fc0b140bf7fc07307c1ffd7df", -- tuli by deebix
    "77e555b45dbfc96d88d11afb49485070", -- Aim9Sidewinder add by Wildcat
    "4b8ec83e7345c8e68e6a205cca1a720b", -- XPC by Mobius
    "4f49f8306274a0a36e5f7f42478b650f", -- Hokum by Wildcat/Chandawg
    "9305c9100e3203d96f629514be79e2fc", -- Deady by Wildcat/Chandawg
    "af80ab416679d9aa305fe38d5bfad688", -- Viper by Enigma
    "c5c69727a7b8ed25e093f5667215cf11", -- threeps by deebix
    "680c380738b532d1df171ed15a763ccf", -- marsh by deebix
    "43009af9ad72caf2a3ff31396bed074f", -- eagle eye added by Enigma
    "227452caa05504df807333d5dd09bc0b", -- Yuri 1-1 LC added by Enigma
    "b16eeca6d0d79081bc423e9f5f0fac66", -- =DDCS=AnarchyZG by Enigma
    "19a63038083a850f99b41e013344f0ad", -- Samsung added by Wildcat
    "2d9f2aa9b7e929181131bf19a834d888", -- Eisen added by Mobius
    "0a7dc6b8b11b9a80cf356c8245dd46ef", -- =R|D= Sh4rk added by Wildcat
    "77babf7f049c1125e21b2d6eec5f183d", -- LongTree added by Wildcat
    "6796a3f8e176cc9d1aaf3be94f63e790", -- Woody added by Wildcat
    "780f45ae1af96718173ce53a0bb80982", -- Shaffy added by Wildcat
    "a9754129be8af66ef5ddeeb9eb23d8b8", -- Perronator added by Wildcat
    "4b09c235f18e0d5b9951bd1dc72b2421", -- Tim Neumann added by Mobius
    "dfc9ee83c48be5006a51691c03a49c55", -- [279-й] Буран added by Mobius
    "0da12769f4e46ee2af4ffcbf06b7b88b", -- FredTheKing added by Mobius
    "1663b351d7e1bfa54ccd48f60b77c024", -- Babushka added by Mobius
    "ec3ecb7075ed4e55153c7208b2ac555d", -- Caddis added
    "5cfe1554cb498f371c268e9c388e580b", -- WebWeaver added
}

M.fwdObsUcids = {}
M.obsUcids = {}
-- These values must match what's in RSR\slotBlocker.lua
M.slotEnabled = 1
M.slotDisabled = 99 -- flags default to 0 if not set, so don't use 0 for disabled!

local function log(message)
    net.log("RSRSlotBlocker: " .. message)
end

--checkSideLock: takes the playerUcid string, and returns the coalition int that they are sidelocked to.
local function checkSideLock(playerUcid)
    for _,v in pairs(M.sidelock.blue) do
        if playerUcid == v then
            return 2
        end
    end
    for _,v in pairs(M.sidelock.red) do
        if playerUcid == v then
            return 1
        end
    end
    return 0
end

local function getFlagValue(groupName)
    local status, error = net.dostring_in('server', " return trigger.misc.getUserFlag(\"" .. groupName .. "\"); ")

    if not status and error then
        log("Error getting flag '" .. groupName .. "': " .. error)
        return M.slotEnabled
    else
        return tonumber(status)
    end
end

local function isUcidAllowed(playerUcid, allowedUcids)
    for _, allowedUcid in pairs(allowedUcids) do
        if allowedUcid == playerUcid then
            return true
        end
    end
    return false
end

local function isGameMasterSlot(unitRole)
    return unitRole == "instructor"
end

local function isTacCmdrSlot(unitRole)
    --    return unitRole == "artillery_commander" or unitRole == "forward_observer" or unitRole == "observer"
    return unitRole == "artillery_commander"
end

local function isFwdObs(unitRole)
    return unitRole == "forward_observer"
end

local function isObs(unitRole)
    return unitRole == "observer"
end


local function isNonAircraftSlot(unitRole)
    --    return unitRole ~= nil and isGameMasterSlot(unitRole) or isTacCmdrSlot(unitRole)
    return unitRole ~= nil and isGameMasterSlot(unitRole) or isTacCmdrSlot(unitRole) or isFwdObs(unitRole) or isObs(unitRole)
end

local function logNonAircraftSlot(playerId, playerName, playerUcid, unitRole, allowed)
    if allowed then
        log("Allowing " .. playerName .. " into " .. unitRole .. " slot (UCID " .. playerUcid .. ")")
    else
        log("Rejecting " .. playerName .. " from " .. unitRole .. " slot (UCID " .. playerUcid .. ")")
        net.send_chat_to("*** Sorry, you are not allowed into the " .. unitRole .. " slots.  Access to Tactical Commander slots must be requested on Discord (https://discord.gg/NRvtGax)\\\nAccess to JTAC\Operator slot is available to all***", playerId)
    end
end





function M.onPlayerTryChangeSlot(playerId, side, slotId)
	
    --Make sure its running as a multiplayer server, and the slot isnt spectator.
    if not DCS.isServer() or not DCS.isMultiplayer() then
        return
    end

    local playerName = net.get_player_info(playerId, 'name')
    local playerUcid = net.get_player_info(playerId, 'ucid')

    if playerName == nil then
        playerName = ""
    end

    local unitRole = DCS.getUnitType(slotId)

----------------------
--CHECK FOR IN-AIR SLOT SWAPPING
------------------------

    local player_UCID = net.get_player_info(playerId, 'ucid')
    if player_UCID == nil or player_UCID == "" then
        net.log("AIR_CHECK: Unable to get ucid " .. playerId)
    else
		net.log('AIR_CHECK: checking if player in air: '..player_UCID)
		
		local str = ' return trigger.misc.getUserFlag("'..player_UCID..'_IN AIR");'
		local status = net.dostring_in('server', str)
		net.log('AIR_CHECK: '..status)
		if (status == "1") then
			net.log('AIR_CHECK: denying slot switch, unit in air')
			net.send_chat_to("***You need to land in order to change slots***", playerId)
			return false 
			--this denys the slot switch.
		else
			net.log('AIR_CHECK: allowing slot switch, player on ground')
		end
    end   

    -------------------------------------------------------------------------------
    -- NON Aircraft slots check. (TACCOM / Game Master / JTAC)
    -------------------------------------------------------------------------------
    if isNonAircraftSlot(unitRole) then
				----------------------------------------------------------
        --Bot API check. 
        -----------------------------------------------------------
		local res = {}
		local decode = {}
        local found = false

		--get the playername from playerID
		local playerDetails = net.get_player_info(playerId)
		
        --get the gci members from discord
		local res = queryBotAPI("/api/voice/"..playerUcid)
		--check for fail reponse from the queryBotAPI func.
        --if its FAIL, it means the connection to the API failed (bots not running), so pretend the player was found in the response.
        if res == "FAIL" then
            found = true
        else
            --if the api request didnt fail, decode the JSON response, and check the value of "success". 1 = theyre in voice, 0 = not in voice
            local decode = JSON:decode(res)
			--net.log(inspect(decode))
            if decode["response"] == "1" then
				--do nothing, its a success.
			else
            --Because we want the rest of the slotblocker to work correctly, we need to only return false when the slot should be blocked. DONT RETURN TRUE or it will skip the rest of the slot block logic.
                net.send_chat_to("Join the discord and register your name with the bot. Then join a voice channel to get access to TACCOM.", playerId)
                return false
			end
		end
        -------------------------------------------------------------------------------
        --END API CHECK
        -------------------------------------------------------------------------------


        -------------------------------------------------------------------------------
        --Coalition Sidelock checks
        -------------------------------------------------------------------------------
        local unitCoalition = DCS.getUnitProperty(slotId,DCS.UNIT_COALITION)
        if unitCoalition == "red" then
            if checkSideLock(playerUcid) == 1 then
                --do nothing, already locked
            elseif checkSideLock(playerUcid) == 2 then
                    --theyre trying to swap.
                    net.log("!! sidelocker - player trying to swap from blue to red. TACCOM")
                    net.send_chat_to("*** Sorry, you have already selected BLUE Commander role and are side locked to BLUE until restart ***", playerId)
                    return false
            elseif checkSideLock(playerUcid) == 0 then
                    net.log("!! sidelocker - player not on any side. adding entry")
                    table.insert(M.sidelock.red, playerUcid)
                    table.insert(M.fwdObsUcids, playerUcid)
            end
        end
        if unitCoalition == "blue" then
            if checkSideLock(playerUcid) == 2 then
                --do nothing, already locked
            elseif checkSideLock(playerUcid) == 1 then
                --theyre trying to swap.
                net.log("!! sidelocker - player trying to swap from blue to red. TACCOM")
                net.send_chat_to("*** Sorry, you have already selected RED Commander role and are side locked to RED until restart ***", playerId)
                return false
            elseif checkSideLock(playerUcid) == 0 then
                net.log("!! sidelocker - player not on any side. adding entry")
                table.insert(M.sidelock.blue, playerUcid)
                table.insert(M.fwdObsUcids, playerUcid)
            end
        end
        -------------------------------------------------------------------------------
        --End Coalition Sidelock checks
        -------------------------------------------------------------------------------


        
		if JustBotCheckingOnly == true then
            if isGameMasterSlot(unitRole) then
                local allowedIntoGameMaster = isUcidAllowed(playerUcid, M.gameMasterUcids)
                logNonAircraftSlot(playerId, playerName, playerUcid, unitRole, allowedIntoGameMaster)
                return allowedIntoGameMaster
            else
			    return true
            end
		end
		-------------------------------------------------------------------------------
        --Some random-ass functions returning functions, i have no idea who coded this
        --or what it specifically does. I think its checking the UCIDs for each of
        --the game master, taccom and jtac slots.
        --Im not too much of a stickler for comments, but god damn, please comment it.
        -------------------------------------------------------------------------------
        if isGameMasterSlot(unitRole) then
            local allowedIntoGameMaster = isUcidAllowed(playerUcid, M.gameMasterUcids)
            logNonAircraftSlot(playerId, playerName, playerUcid, unitRole, allowedIntoGameMaster)
            return allowedIntoGameMaster
        elseif isTacCmdrSlot(unitRole) then
            local allowedIntoTacCmdr = isUcidAllowed(playerUcid, M.gameMasterUcids) or isUcidAllowed(playerUcid, M.tacCmdrUcids)
            logNonAircraftSlot(playerId, playerName, playerUcid, unitRole, allowedIntoTacCmdr)
            return allowedIntoTacCmdr
        elseif isFwdObs(unitRole) then
            local allowedIntoFwdObs = isUcidAllowed(playerUcid, M.gameMasterUcids) or isUcidAllowed(playerUcid, M.tacCmdrUcids) or isUcidAllowed(playerUcid, M.fwdObsUcids)
            logNonAircraftSlot(playerId, playerName, playerUcid, unitRole, allowedIntoFwdObs)
            return allowedIntoFwdObs
        elseif isObs(unitRole) then
            local allowedIntoObs = isUcidAllowed(playerUcid, M.gameMasterUcids) or isUcidAllowed(playerUcid, M.tacCmdrUcids) or isUcidAllowed(playerUcid, M.fwdObsUcids) or isUcidAllowed(playerUcid, M.obsUcids)
            logNonAircraftSlot(playerId, playerName, playerUcid, unitRole, allowedIntoObs)
            return allowedIntoObs
        end
		
		
    end
    -------------------------------------------------------------------------------
    --END Non-Aircraft slots check. (TACCOM / Game Master / JTAC)
    -------------------------------------------------------------------------------
    

    -------------------------------------------------------------------------------
    -- Aircraft Slots check. 
    -- First checks if theyre on the sidelock list (only commander slots will get added to these lists.)
    -- Then checks the flags set in the MIZ to see if the slot should be allowed pending base ownership.
    -------------------------------------------------------------------------------
    local groupName = DCS.getUnitProperty(slotId, DCS.UNIT_GROUPNAME)

    if groupName == nil or groupName == "" then
        log("Unable to get group name for slot " .. slotId .. "; allowing access")
        return true
    end

    --Check the Aircraft slots for people going from Commander roles to Aircraft roles
    net.log("!! sidelocker check")
    -- ITS A RED SLOT!
    if string.find(groupName, "Red") ~= nil  or string.find(groupName, "red")~=nil then
        if checkSideLock(playerUcid) == 1 then
            --do nothing, already locked to red side
        elseif checkSideLock(playerUcid) == 2 then
            --theyre trying to swap.
            net.log("!! sidelocker - player trying to swap from blue to red. TACCOM")
            net.send_chat_to("*** Sorry, you have already selected BLUE Commander Role and are side locked to BLUE until restart ***", playerId)
           return false
        elseif checkSideLock(playerUcid) == 0 then
            --do nothing, they havent been a commander.
        end
    end
    --BLUE SLOT CHECKS
    if string.find(groupName, "Blue") ~= nil or string.find(groupName, "blue")~=nil then
       if checkSideLock(playerUcid) == 2 then
            --do nothing, already locked to blue side
        elseif checkSideLock(playerUcid) == 1 then
            --theyre trying to swap.
            net.log("!! sidelocker - player trying to swap from blue to red. TACCOM")
            net.send_chat_to("*** Sorry, you have already selected RED Commander Role and are side locked to RED until restart ***", playerId)
            return false
        elseif checkSideLock(playerUcid) == 0 then
            --do nothing, they havent been a commander
        end
    end

    local flagValue = getFlagValue(groupName)
    net.log(string.format("Flag value for group '%s' is %d", groupName, flagValue))
    -- only reject a slot if the disabled value is set (ie fail-safe and allow the slot)
    local slotAllowed = flagValue ~= M.slotDisabled

    if slotAllowed then
        log("Allowing player " .. playerName .. " on side " .. side .. " into slot '" .. groupName .. "'")
        return true
    else
        net.send_chat_to("*** Sorry, this slot is only active if your side controls this base ***", playerId)
        log("Rejecting player " .. playerName .. " on side " .. side .. " from slot '" .. groupName .. "'")
        return false
    end
    -------------------------------------------------------------------------------
    -- End Aircraft slots check.
    -------------------------------------------------------------------------------
end

--TRACK TAKEOFFS AND LANDING-LIKE EVENTS FOR THE SLOTBLOCK.
function M.onGameEvent(event_name,playerId,slotId,...)
	if(event_name == "takeoff") then
		local player_UCID = net.get_player_info(playerId, 'ucid')
		if player_UCID ~= nil then
			local set_str = [[trigger.action.setUserFlag(']]..player_UCID.."_IN AIR"..[[',1)]];
			local set_status = net.dostring_in('server',set_str);
			net.log('AIR_CHECK: Setuserflag1 '..'Player_UCID: '..player_UCID..' slot: '..slotId..set_status)
		end
	end
	if (event_name == "eject" or event_name == "crash" or event_name == "landing" or event_name == "pilot_death"  or event_name == "change_slot" or event_name == "connect") then
		local player_UCID = net.get_player_info(playerId, 'ucid')
		if player_UCID ~= nil then
			local set_str = [[trigger.action.setUserFlag(']]..player_UCID.."_IN AIR"..[[',0)]];
			local set_status = net.dostring_in('server',set_str);
			net.log('AIR_CHECK: Setuserflag0 '..player_UCID..' : '..set_status)
		end
	end
end

DCS.setUserCallbacks(M)
net.log("Loaded PlayerList Bot Functions")
DCS.setUserCallbacks(playerList)
net.log("Loaded RSRSlotBlocker")