--!strict
-- Checkpoints, respawn and the Continue / Start over choice (Technical.md sections 4 and 5).
-- Parts tagged Checkpoint carry attributes World (string) and Stage (whole number >= 1).
-- A player only advances by touching the next stage, and respawns at the last one reached.
-- A player who joins with saved progress starts in the hub and must pick Continue or Start over
-- first; until then checkpoints are ignored and respawns stay in the hub.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Tags = require(ReplicatedStorage.Shared.Tags)
local Types = require(ReplicatedStorage.Shared.Types)
local PlayerData = require(script.Parent.PlayerData)
local RateLimit = require(script.Parent.Parent.RateLimit)

local SPAWN_HEIGHT = 3 -- studs above the checkpoint surface

local checkpoints: { [string]: { [number]: BasePart } } = {}

-- nil: not evaluated yet. false: must pick Continue or Start over. true: free to play.
local chosen: { [Player]: boolean } = {}

local allowStateRequest = RateLimit.new(1)

local Checkpoints = {}

-- Decided once per session, the first time the player's data is available.
local function hasChosen(player: Player, data: Types.PlayerData): boolean
	local decision = chosen[player]
	if decision == nil then
		decision = PlayerData.GetWorld(data, Config.World).Checkpoint == 0
		chosen[player] = decision
	end
	return decision
end

-- The client cannot count checkpoints itself: with StreamingEnabled it may not have them all loaded.
local function totalStages(world: string): number
	local highest = 0
	local stages = checkpoints[world]
	if stages then
		for stage in stages do
			highest = math.max(highest, stage)
		end
	end
	return highest
end

local function pushState(player: Player, data: Types.PlayerData)
	local state: Types.StateChanged = {
		Checkpoint = PlayerData.GetWorld(data, Config.World).Checkpoint,
		TotalStages = totalStages(Config.World),
		NeedsChoice = chosen[player] == false,
	}
	Remotes.StateChanged:FireClient(player, state)
end

local function register(instance: Instance)
	if not instance:IsA("BasePart") then
		warn(`[Checkpoints] {instance:GetFullName()} is tagged Checkpoint but is not a BasePart`)
		return
	end

	local world = instance:GetAttribute("World")
	local stage = instance:GetAttribute("Stage")
	if type(world) ~= "string" or world == "" or type(stage) ~= "number" or stage < 1 or stage % 1 ~= 0 then
		warn(`[Checkpoints] {instance:GetFullName()} needs attributes World (string) and Stage (whole number >= 1)`)
		return
	end
	if world ~= Config.World then
		warn(`[Checkpoints] {instance:GetFullName()} has unknown World "{world}" (expected "{Config.World}")`)
	end

	local stages = checkpoints[world] or {}
	checkpoints[world] = stages
	if stages[stage] then
		warn(`[Checkpoints] duplicate World "{world}" Stage {stage}: {instance:GetFullName()} ignored`)
		return
	end
	stages[stage] = instance

	instance.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit:FindFirstAncestorOfClass("Model"))
		local humanoid = player and player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if not player or not humanoid or humanoid.Health <= 0 then
			return
		end

		local data = PlayerData.Get(player)
		if not data or not hasChosen(player, data) then
			return
		end

		-- Only the next stage counts; touching an earlier or a later one does nothing.
		local progress = PlayerData.GetWorld(data, world)
		if stage == progress.Checkpoint + 1 then
			progress.Checkpoint = stage
			pushState(player, data)
		end
	end)
end

-- Every stage from 1 to the highest must exist, otherwise players could get stuck.
local function validateSequences()
	for world, stages in checkpoints do
		local highest = totalStages(world)
		for stage = 1, highest do
			if not stages[stage] then
				warn(`[Checkpoints] World "{world}" is missing Stage {stage} (highest is {highest})`)
			end
		end
	end
end

local function moveToCheckpoint(character: Model, data: Types.PlayerData)
	local checkpoint = PlayerData.GetWorld(data, Config.World).Checkpoint
	local part = checkpoints[Config.World] and checkpoints[Config.World][checkpoint]
	if not part then
		return -- checkpoint 0 (in the hub) or no such part: stay at the default spawn
	end

	character:WaitForChild("HumanoidRootPart")
	character:PivotTo(part.CFrame * CFrame.new(0, part.Size.Y / 2 + SPAWN_HEIGHT, 0))
end

local function respawn(player: Player, character: Model)
	local data = PlayerData.WaitFor(player)
	if not data or not hasChosen(player, data) then
		return -- no data, or still has to choose: stay in the hub
	end
	moveToCheckpoint(character, data)
end

local function watch(player: Player)
	player.CharacterAdded:Connect(function(character)
		respawn(player, character)
	end)
	if player.Character then
		task.spawn(respawn, player, player.Character)
	end
end

function Checkpoints.Start()
	Players.RespawnTime = Config.RespawnSeconds

	CollectionService:GetInstanceAddedSignal(Tags.Checkpoint):Connect(register)
	for _, instance in CollectionService:GetTagged(Tags.Checkpoint) do
		register(instance)
	end
	validateSequences()

	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		chosen[player] = nil
	end)

	-- The client asks for its state once its UI is ready, so a message sent at join is never missed.
	Remotes.RequestState.OnServerEvent:Connect(function(player)
		if not allowStateRequest(player) then
			return
		end
		task.spawn(function()
			local data = PlayerData.WaitFor(player)
			if data then
				hasChosen(player, data)
				pushState(player, data)
			end
		end)
	end)

	-- Only the first of Continue / Start over counts; any further call is ignored.
	Remotes.RequestContinue.OnServerEvent:Connect(function(player)
		local data = PlayerData.Get(player)
		if not data or chosen[player] ~= false then
			return
		end
		chosen[player] = true
		if player.Character then
			moveToCheckpoint(player.Character, data)
		end
		pushState(player, data)
	end)

	Remotes.RequestStartOver.OnServerEvent:Connect(function(player)
		local data = PlayerData.Get(player)
		if not data or chosen[player] ~= false then
			return
		end
		chosen[player] = true
		PlayerData.GetWorld(data, Config.World).Checkpoint = 0 -- Coins, Relics and cosmetics are kept
		pushState(player, data)
	end)
end

return Checkpoints
