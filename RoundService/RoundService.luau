--=========================================================================================================================================================

--======================================> ROUND SERVICE MADE BY notHazel on 23/8/2026 <==============================================================

--======================================>       <Lincensed under the MIT license>            <=================================================

--=========================================================================================================================================================



--//Module - Server side \\--



--[[ IF THERES SOMEONE ACTUALLY READING THE CODE PLEASE DONT MIND THE COMMENT HELL, IM TRYING TO EXPLAIN WHAT THE (possibly)

CONFUSING VARIABLES DO CAUSE IDK HOW TO MAKE THEM MORE CLEAR]]



--Also im using ; after defining constants cause im trying to get used to C# stuff.



--// SERVICES \\--

const ServerStorage = game:GetService("ServerStorage");

const ReplicatedStorage = game:GetService("ReplicatedStorage");

const players = game:GetService("Players");

const dependencies = script.Dependencies;

const types = require(dependencies.Types);



const Service = {}



--//-



--// FOLDERS \\--



local Maps = ServerStorage.Assets.maps --folder containing maps

local Weapons = nil  -- folder containing weapon/items



--[[Run this inside of the command line if you dont have the maps and items folder already: 

require(game.ServerStorage.RoundService).MakeFolders()



Otherwise change the folder locations in the code]]

function Service.MakeFolders()

	local assets = ServerStorage:FindFirstChild("Assets")



	if not assets then

		assets = Instance.new("Folder")

		assets.Name = "Assets"

		assets.Parent = ServerStorage

		warn(`Round service: {assets.Name} folder has been sucessfully made inside {assets.Parent}`)

	end



	local mapsFolder = Maps or assets:FindFirstChild("roundService_maps")

	if not mapsFolder then

		mapsFolder = Instance.new("Folder")

		mapsFolder.Name = "roundService_maps"

		mapsFolder.Parent = assets

		warn(`Round service: {mapsFolder.Name} folder has been sucessfully made inside {mapsFolder.Parent}`)

	end



	local weaponsFolder

	if typeof(Weapons) ~= "Folder" then 

		weaponsFolder = assets:FindFirstChild("roundService_Items")

	else

		weaponsFolder = Weapons

	end



	if not weaponsFolder then

		weaponsFolder = Instance.new("Folder")

		weaponsFolder.Name = "roundService_Items"

		weaponsFolder.Parent = assets

		warn(`Round service: {weaponsFolder.Name} folder has been sucessfully made inside {weaponsFolder.Parent}`)

	end



	return mapsFolder, weaponsFolder

end







if not Maps or not Weapons then

	Maps, Weapons = Service.MakeFolders()

end





local currentMapFolder

if not workspace:FindFirstChild("RoundService_CurrentMap") then

	currentMapFolder = Instance.new("Folder")

	currentMapFolder.Name = "RoundService_CurrentMap"

	currentMapFolder.Parent = workspace

end



--//-



--//VARIABLES AND CONSTANTS\\--

const DefaultRoundTime = 180;

const DefaultIntermissionTime = 20;

const DefaultWeaponsAmount = 3;

const DefaultCountDownWaitTime = 1; --[[the amount of seconds the coundown function has to wait before doing the

StartNumber - 1 (read lines 122, 136 and 137 to understand better). ]]





const customSettings: types.CustomRoundSettings = {

	["CustomRoundTime"] = nil,

	["CustomIntermissionTime"] = nil,

	["CustomWeaponsAmount"] = nil,

	["CustomCountDownWaitTime"] = nil, -- do not change this if you dont know what u doin.

	["CustomMap"] = nil,

	["AutoEndRound"] = false,

	["SortWeapons"] = false,



	["BlacklistedMaps"] = {},

	["BlacklistedItems"] = {},

	["HumanoidStates"] = {}

}



local currentMap = nil

local roundType = "_default" -- do NOT change this to anything else if you dont know what u doin (please).



Service.currentlyInGame = false

local SortWeapons = true --[[used to set if the GiveItems function should reroll an item if the player already

has it in their inventory untill its an different item that isnt found in the player's inventory

(true = should reroll / no same items allowed | false = true random/same items allowed). ]]



local FetchingWeapons = false



--// both of these work togheter. Dont change them manually. Instead use the pauseRound function.

Service.isGamePaused = false

Service.canChangeWait = true

local AutoRound = false

local cancelCountDown = false

--//



local CurrentGameState = "" -- can either be Round or Intermission, nothing else.



--[[//Can be changed during match if you have an admin pannel or something. _default IS FOR DEFAULT/NORMAL ROUND

AND _custom IS FOR CUSTOM ROUNDS THAT USES THE custom round presets ADDON.]]

const BlacklistedMaps = {

	["_default"] = {},

	["_custom"] = {},

}



const BlacklistedWeapons = {

	["_default"] = {},

	["_custom"] = {},

}

--//



const playersInRound = {}



--//-

--//EVENTS\\--







--//service events

const goodSignal = require(dependencies.GoodSignal)



Service.OnRoundStart = goodSignal.new()

Service.OnRoundEnd = goodSignal.new()



--/



--//-



--//CALLBACKS\\--



--//-



--//FUNCTIONS\\--





--[[starts counting from the specified start number and subtracts untill the start number is equal to 0.

Example: startNumber = 20 will repeap 20 - 1 untill 20 is equal to 0]]

function countdown(startNumber:number)

	if not startNumber then return end

	if startNumber < 2 then return end



	local endCounter = 0

	local decrement = 1

	local num = startNumber

	local CountDownWaitTime = customSettings["CustomCountDownWaitTime"] or DefaultCountDownWaitTime



	while num ~= endCounter do

		if cancelCountDown then break end



		if Service.isGamePaused and Service.canChangeWait then

			CountDownWaitTime = math.huge

			Service.canChangeWait = false



		elseif not Service.isGamePaused and Service.canChangeWait then

			CountDownWaitTime = customSettings["CustomCountDownWaitTime"] or DefaultCountDownWaitTime

			Service.canChangeWait = false

		end



		num -= decrement

		task.wait(CountDownWaitTime)

	end



end



--[[Takes "map" or "weapon" as an argument and if clone is set to true, returns the clone of a random child from the 

weapons/maps folder, otherwise returns the random child itself.]]

function getRandom(Type:string, clone:boolean)

	if not Type then return warn("missing type") end



	local lowerType = string.lower(Type)



	if lowerType == "weapon" then



		local itemsTab = {}

		for _, tool in Weapons:QueryDescendants("Tool") do



			table.insert(itemsTab, tool)

		end

		if #itemsTab < 1 then return warn("f") end



		local item:Tool



		repeat

			item = itemsTab[math.random(1, #itemsTab)]

		until item and not BlacklistedWeapons[roundType][item.Name]



		if clone then

			return item:Clone()

		else

			return item

		end



	elseif lowerType == "map" then



		local map



		repeat

			map = Maps:GetChildren()[math.random(1, #Maps:GetChildren())]

		until map and not BlacklistedMaps[roundType][map.Name]



		if clone then

			return map:Clone()

		else

			return map

		end



	else

		return

	end



end





function sortItems()

	local loadout = {}

	local weaponsName = {}



	local maxWeaponsAmount = customSettings["CustomWeaponsAmount"] or DefaultWeaponsAmount

	FetchingWeapons = true



	repeat



		local weapon:Tool = getRandom("weapon", true)

		if weapon then



			if not table.find(weaponsName, weapon.Name) then

				table.insert(weaponsName, weapon.Name)

				table.insert(loadout, weapon)			

			else

				weapon:Destroy()

			end



		end



		task.wait()

	until #loadout == maxWeaponsAmount



	FetchingWeapons = false

	return loadout

end





function spawnMap(riggedMap:string)

	if riggedMap and typeof(riggedMap) ~= "string" then 

		warn("riggedMap must be a string and not a <| ", typeof(riggedMap), " |>. A random map will be spawned") 

		riggedMap = false

	end





	local newMap:Model



	if riggedMap and not table.find(BlacklistedMaps, riggedMap) then

		newMap = Maps:FindFirstChild(riggedMap)

	end



	if riggedMap and newMap then

		newMap:Clone().Parent = workspace



	elseif riggedMap and not newMap then

		warn(riggedMap, "is not a valid map name or does not exist. A random map will be spawned")

		newMap = getRandom("map", true)

	end



	if not riggedMap then

		newMap = getRandom("map", true)

	end



	currentMap = newMap

	newMap.Parent = workspace	

end





function despawnMap()

	local map = currentMapFolder:FindFirstChild(currentMap.Name) or workspace:FindFirstChild(currentMap.Name)

	if not map then return warn("missing map:", currentMap) end



	map:Destroy()

	currentMap = nil



end 





--[[Gives a tool to the specified player untill the amount of weapons inside the player's loadout (NOT backpack)

	is equal to the maxweapons amount]]

function giveItems(player:Player)

	if not player then return end



	local loadout = {}



	local maxWeaponsAmount



	if roundType == "_custom" and customSettings.CustomWeaponsAmount and customSettings.CustomWeaponsAmount > 0 then

		maxWeaponsAmount = customSettings.CustomWeaponsAmount

	else

		maxWeaponsAmount = DefaultWeaponsAmount

	end





	if SortWeapons or customSettings["SortWeapons"] then



		loadout = sortItems()



	else



		repeat



			local weapon = getRandom("weapon", true)

			if weapon then

				table.insert(loadout, weapon)

			end



		until #loadout == maxWeaponsAmount



	end



	for _, item in loadout do

		item.Parent = player.Backpack

	end



end





--//-



--//MODULE FUNCTIONS\\--



--returns default and custom configs. (default, custom)

function Service.getConfigs()

	local configs = customSettings

	local defaultConfigs = {DefaultRoundTime, DefaultCountDownWaitTime, DefaultWeaponsAmount}

	return defaultConfigs, configs

end





--[[Changes the custom configurations like Round time, intermission time, the amount of items a player can have, blacklisted

    maps and etc. Use this to change the Service configs, otherwise defaults will be used AND if you pass an array of blacklisted maps 

    or items and they have already been blacklisted, it will remove them from the blacklist. 

    CONFIG NAMES: CustomRoundTime, CustomIntermissionTime, CustomWeaponsAmount, CustomCountDownWaitTime, AutoEndRound: boolean, 

    BlacklistedMaps: string array, BlacklistedItems: string array, CustomMap: string, HumanoidStates: Dictionary ]]

function Service.changeConfigs(config: types.CustomRoundSettings)

	if not config then return end



	for configName, value in customSettings do

		if customSettings[configName] then

			customSettings[configName] = value

		end

	end



	if config["BlacklistedMaps"] then

		for _, map in config["BlacklistedMaps"] do

			if not table.find(BlacklistedMaps["_default"]) then

				table.insert(BlacklistedMaps["_default"], map)

			else

				BlacklistedMaps["_default"][map] = nil

			end

		end	

	end



	if config["BlacklistedItems"] then

		for _, item in config["BlacklistedWeapons"] do

			if not table.find(BlacklistedWeapons["_default"], item) then

				table.insert(BlacklistedWeapons["_default"])

			else

				BlacklistedWeapons["_default"][item] = nil

			end

		end	

	end



end





--[[Automatically begins and end rounds. Use StopAutoGame to stop it.]]

function Service.AutoGame(customRound: boolean)

	AutoRound = true



	while AutoRound do

		if customRound then

			Service.beginCustomRound()

		else

			Service.beginRound()

		end

	end



end





--Stops the AutoGame function from running if its active.

function Service.StopAutoGame(CustomRound:boolean)

	if not AutoRound then return end



	AutoRound = false



	if CustomRound and Service.currentlyInGame ~= true then

		Service.beginCustomRound()

	elseif not CustomRound and Service.currentlyInGame ~= true then

		Service.beginRound()

	end



end





--[[Begins a round using the default configs]]

function Service.beginRound()

	if CurrentGameState == "Round" or Service.currentlyInGame == true then return end

	CurrentGameState = "Round"

	roundType = "_default"

	Service.currentlyInGame = true

	Service.OnRoundStart:Fire(roundType)



	spawnMap()



	for _, player:Player in players:GetPlayers() do



		player:SetAttribute("IsOnRound", true)

		table.insert(playersInRound, player)



		player.CharacterAdded:Connect(function(char)

			if table.find(playersInRound, player) then

				giveItems(player)

			end

		end)



		player:LoadCharacterAsync()

	end





	countdown(DefaultRoundTime)

	if customSettings["AutoEndRound"] or AutoRound == true then Service.endRound() end



end





--[[ends the current round]]

function Service.endRound()

	if CurrentGameState == "Intermission" then return end

	CurrentGameState = "Intermission"



	if Service.currentlyInGame then

		cancelCountDown = true

	end



	Service.currentlyInGame = false

	Service.OnRoundEnd:Fire()



	despawnMap()



	for _, player:Player in players:GetPlayers() do

		player:SetAttribute("IsOnRound", false)

		table.clear(playersInRound)

		player:LoadCharacterAsync()

	end



	cancelCountDown = false



	if roundType == "_custom" then

		countdown(customSettings.CustomIntermissionTime or DefaultRoundTime)

	else

		countdown(DefaultIntermissionTime)

	end



	if AutoRound then

		Service.endRound()

	end

end





function Service.pauseRound()

	if not Service.canChangeWait then Service.canChangeWait = true end

	local waitTime

	if roundType == "_default" then

		waitTime = DefaultCountDownWaitTime

	else

		waitTime = customSettings.CustomCountDownWaitTime

	end



	if Service.isGamePaused then

		Service.isGamePaused = false

	else

		Service.isGamePaused = true

	end



end





--[[Begins a round using the custom settings. You can change this if you know how to do it, but AutoEndRound is on by default for custom rounds]]

function Service.beginCustomRound()

	if CurrentGameState == "Round" or Service.currentlyInGame == true then return warn(`Failed to start custom round. There is already a round going on: {Service.currentlyInGame} | {CurrentGameState}`) end



	Service.currentlyInGame = true

	CurrentGameState = "Round"

	roundType = "_custom"

	Service.OnRoundStart:Fire(roundType)



	spawnMap(customSettings.CustomMap)



	for _, player in players:GetPlayers() do



		player:SetAttribute("IsOnRound", true)

		table.insert(playersInRound, player)



		player.CharacterAdded:Connect(function(char)



			if table.find(playersInRound, player) then

				giveItems(player)



				local humanoid:Humanoid = char:FindFirstChild("Humanoid")

				if humanoid then

					for Property, Value in customSettings.HumanoidStates do

						if humanoid[Property] then

							humanoid[Property] = Value

						end

					end

				end



			end

		end)



		player:LoadCharacterAsync()

	end



	countdown(customSettings.CustomRoundTime or DefaultRoundTime)

	Service.endRound()

end





--//-



return Service
