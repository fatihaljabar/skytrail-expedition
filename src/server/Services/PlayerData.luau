--!strict
-- Loads and saves player data with ProfileStore, and is the only way to change Coins.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Shared.Config)
local Types = require(ReplicatedStorage.Shared.Types)
local ProfileStore = require(ServerScriptService.ServerPackages.ProfileStore)

local DATA_VERSION = 1

local TEMPLATE: Types.PlayerData = {
	DataVersion = DATA_VERSION,
	Coins = 0,
	Worlds = {},
	Relics = {},
	Cosmetics = { Owned = {} },
	Stats = { Deaths = 0, Completions = 0, Skips = 0 },
	ProcessedPurchases = {},
}

local realStore = ProfileStore.New("PlayerData_v1", TEMPLATE)
-- ProfileStore only mocks when called through .Mock. Studio never touches real player data.
local store = if RunService:IsStudio() then realStore.Mock else realStore

type Profile = typeof(assert(store:StartSessionAsync("", {})))

local profiles: { [Player]: Profile } = {}

local PlayerData = {}

local function isWholeCoins(amount: number): boolean
	-- amount ~= amount catches NaN
	return amount == amount and amount > 0 and amount % 1 == 0 and amount < math.huge
end

-- Pure rules, so they can be self-checked without a player.
local function addCoins(data: Types.PlayerData, amount: number): boolean
	if not isWholeCoins(amount) then
		return false
	end
	data.Coins += amount
	return true
end

local function spendCoins(data: Types.PlayerData, amount: number): boolean
	if not isWholeCoins(amount) or data.Coins < amount then
		return false
	end
	data.Coins -= amount
	return true
end

-- Analytics hook for every Coins change. Stub until M4-06 wires up AnalyticsService.
local function logCoinsChange(_player: Player, _amount: number, _balance: number) end

function PlayerData.Get(player: Player): Types.PlayerData?
	local profile = profiles[player]
	return profile and profile.Data
end

-- Yields until the player's data is loaded; nil if the player leaves or the load fails first.
function PlayerData.WaitFor(player: Player): Types.PlayerData?
	while player.Parent == Players and not profiles[player] do
		task.wait()
	end
	return PlayerData.Get(player)
end

-- Progress of one world, created with defaults on first access.
function PlayerData.GetWorld(data: Types.PlayerData, world: string): Types.WorldProgress
	local progress = data.Worlds[world]
	if not progress then
		progress = { Checkpoint = 0, Completed = false }
		data.Worlds[world] = progress
	end
	return progress
end

function PlayerData.AddCoins(player: Player, amount: number): boolean
	local data = PlayerData.Get(player)
	if not data or not addCoins(data, amount) then
		return false
	end
	logCoinsChange(player, amount, data.Coins)
	return true
end

function PlayerData.SpendCoins(player: Player, amount: number): boolean
	local data = PlayerData.Get(player)
	if not data or not spendCoins(data, amount) then
		return false
	end
	logCoinsChange(player, -amount, data.Coins)
	return true
end

local function loadPlayer(player: Player)
	local profile = store:StartSessionAsync(`User_{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if not profile then
		player:Kick("Could not load your data. Please rejoin.")
		return
	end

	profile:AddUserId(player.UserId) -- GDPR: lets the profile be found and erased by user id
	profile:Reconcile() -- fill fields added to the template since the profile was saved

	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		player:Kick("Your data session ended. Please rejoin.")
	end)

	if player.Parent == Players then
		profiles[player] = profile
	else
		profile:EndSession()
	end
end

local function selfCheck()
	local function fresh(): Types.PlayerData
		return table.clone(TEMPLATE)
	end

	local data = fresh()
	assert(not addCoins(data, -5), "negative add must be rejected")
	assert(not addCoins(data, 0), "zero add must be rejected")
	assert(not addCoins(data, 1.5), "fractional add must be rejected")
	assert(not addCoins(data, 0 / 0), "NaN add must be rejected")
	assert(not addCoins(data, math.huge), "infinite add must be rejected")
	assert(data.Coins == 0, "rejected adds must not change the balance")

	assert(addCoins(data, Config.Coins.PerRelic), "valid add must succeed")
	assert(data.Coins == Config.Coins.PerRelic, "valid add must change the balance")

	assert(not spendCoins(data, data.Coins + 1), "overspend must be rejected")
	assert(not spendCoins(data, -1), "negative spend must be rejected")
	assert(not spendCoins(data, 2.5), "fractional spend must be rejected")
	assert(data.Coins == Config.Coins.PerRelic, "rejected spends must not change the balance")

	assert(spendCoins(data, Config.Coins.PerRelic), "spending the whole balance must succeed")
	assert(data.Coins == 0, "balance must never go below zero")
end

function PlayerData.Start()
	if RunService:IsStudio() then
		selfCheck()
	end

	Players.PlayerAdded:Connect(function(player)
		task.spawn(loadPlayer, player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		local profile = profiles[player]
		if profile then
			profiles[player] = nil
			profile:EndSession()
		end
	end)

	for _, player in Players:GetPlayers() do
		task.spawn(loadPlayer, player)
	end
end

return PlayerData
