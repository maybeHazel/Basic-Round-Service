local RoundManager = {}

--// SERVICES \\--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local workspace = game.Workspace

--// VARIABLES \\--
local GameValues = ReplicatedStorage.Values.GameValues
local Lobby = workspace.Lobby.LobbyMap
local Swords = ServerStorage.SwordsFolder:GetChildren()
local SwordsFolder = ServerStorage.SwordsFolder
local MapsFolder = ServerStorage.MapsFolder
local Maps = ServerStorage.MapsFolder:GetChildren()

local MatchTime = GameValues.Time
local IsOnGame = GameValues.OnGame
local ROUND_TIME = 30 -- Round time / Duraçao da partida
local IsOnIntermission = GameValues.OnIntermission
local INTERMISSION_TIME = 20 -- Intermission time / tempo de espera ate o proximo round
local FilterSwords = false
local Map

--// FUNCTIONS \\--
function Cooldown(Duration)
	for i = Duration, 1, -1 do
		MatchTime.Value = i
		task.wait(1)
	end
end

function GetRandSword(Amount)
	local RandomSword = Swords[math.random(1, #Swords)]
	return RandomSword
end

function GetRandMap() --Pega um mapa aleatorio dentro da pasta de mapas e guarda na funçao
	local RandomMap = Maps[math.random(1, #Maps)]
	return RandomMap
end

Map = GetRandMap()

function SpawnMap()
	Map.Parent = workspace.CurrentMap
end

function DespawnMap()
	Map.Parent = MapsFolder
end

--// MAIN MODULE FUNCTIONS \\--

function RoundManager.BeginRound(ROUND_DURATION:number)
	IsOnIntermission.Value = false
	IsOnGame.Value = true
	Lobby.SpawnLocation.Enabled = false

	GetRandMap()
	Map = GetRandMap()
	SpawnMap()
	Cooldown(ROUND_DURATION)
end

function RoundManager.BeginIntermission(INTERMISSION_DURATION:number)
	IsOnGame.Value = false
	IsOnIntermission.Value = true
	Lobby.SpawnLocation.Enabled = true

	DespawnMap()
	Cooldown(INTERMISSION_DURATION)
end

--//Gives random swords for every player depending on the amount set (If the amount is lesser than or equal to ZERO, it sets the amount to 3). Set UsePlayer to true and give the specified player the sword you want\\
function RoundManager.GiveSwords(Amount:number, UsePlayer:boolean, PlayerName:string, SwordName:string)

	if UsePlayer and Players:FindFirstChild(PlayerName) and SwordsFolder:FindFirstChild(SwordName) then -->
		local givenSword = SwordsFolder:FindFirstChild(SwordName)
		local Player = Players:FindFirstChild(PlayerName)

		for i = 1, Amount do
			local NewSword = givenSword:Clone()
			NewSword.Parent = Player.Backpack
		end
	end --> UsePlayer stuff

	for _, player in Players:GetPlayers() do
		player.CharacterAdded:Connect(function(Char)
			if IsOnGame.Value == true then
				for i = 1, Amount do
					if #player.Backpack:GetChildren() >=Amount then
						break
					end

					repeat --> THIS BLOCK OF CODE PREVENTS THE PLAYER FROM GETTING MULTIPLE OF THE SAME SWORD IN THE

						GetRandSword()
						local Sword = GetRandSword():Clone()
						if not player.Backpack:FindFirstChild(Sword.Name) then
							Sword.Parent = player.Backpack
						else Sword:Destroy()
						end

					until #player.Backpack:GetChildren() == Amount --> LOADOUT/IVENTORY

				end
			end
		end)
	end
end

--//Removes every sword from all the player's inventory if the value of UsePlayer is FALSE OR NIL or the specified player does not exist\\
function RoundManager.RemoveSwords(UsePlayer:boolean, PlayerName:string)
	if UsePlayer and Players:FindFirstChild(PlayerName) then
		local Player = Players:FindFirstChild(PlayerName)
		Player.Backpack:ClearAllChildren()
		print(PlayerName ,"'s Inventory cleared")
	end

	for _, player in Players:GetPlayers() do
		print("cleared the inventory of every player")
		player.Backpack:ClearAllChildren()
	end
end

return RoundManager
