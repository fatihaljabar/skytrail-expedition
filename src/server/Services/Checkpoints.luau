--!strict
-- Checkpoints and respawn (Technical.md sections 4 and 5).
-- Parts tagged Checkpoint carry attributes World (string) and Stage (whole number >= 1).
-- A player only advances by touching the next stage, and respawns at the last one reached.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Tags = require(ReplicatedStorage.Shared.Tags)
local PlayerData = require(script.Parent.PlayerData)

local SPAWN_HEIGHT = 3 -- studs above the checkpoint surface

local checkpoints: { [string]: { [number]: BasePart } } = {}

local Checkpoints = {}

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
		if not data then
			return
		end

		-- Only the next stage counts; touching an earlier or a later one does nothing.
		local progress = PlayerData.GetWorld(data, world)
		if stage == progress.Checkpoint + 1 then
			progress.Checkpoint = stage
		end
	end)
end

-- Every stage from 1 to the highest must exist, otherwise players could get stuck.
local function validateSequences()
	for world, stages in checkpoints do
		local highest = 0
		for stage in stages do
			highest = math.max(highest, stage)
		end
		for stage = 1, highest do
			if not stages[stage] then
				warn(`[Checkpoints] World "{world}" is missing Stage {stage} (highest is {highest})`)
			end
		end
	end
end

local function respawn(player: Player, character: Model)
	local data = PlayerData.WaitFor(player)
	if not data then
		return
	end

	local checkpoint = PlayerData.GetWorld(data, Config.World).Checkpoint
	local part = checkpoints[Config.World] and checkpoints[Config.World][checkpoint]
	if not part then
		return -- checkpoint 0 (not started) or no such part: stay at the default spawn
	end

	character:WaitForChild("HumanoidRootPart")
	character:PivotTo(part.CFrame * CFrame.new(0, part.Size.Y / 2 + SPAWN_HEIGHT, 0))
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
	CollectionService:GetInstanceAddedSignal(Tags.Checkpoint):Connect(register)
	for _, instance in CollectionService:GetTagged(Tags.Checkpoint) do
		register(instance)
	end
	validateSequences()

	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
end

return Checkpoints
