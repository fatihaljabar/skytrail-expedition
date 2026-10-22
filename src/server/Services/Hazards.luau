--!strict
-- Parts tagged Hazard (lava, kill bricks) kill any character that touches them.
-- Checkpoints respawns the character afterwards.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tags = require(ReplicatedStorage.Shared.Tags)

local Hazards = {}

local function setup(instance: Instance)
	if not instance:IsA("BasePart") then
		warn(`[Hazards] {instance:GetFullName()} is tagged Hazard but is not a BasePart`)
		return
	end

	instance.Touched:Connect(function(hit)
		local model = hit:FindFirstAncestorOfClass("Model")
		local player = model and Players:GetPlayerFromCharacter(model)
		local humanoid = player and player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		-- Touched fires many times per contact; a dead humanoid is the debounce, so a player dies once.
		if humanoid and humanoid.Health > 0 then
			humanoid.Health = 0
		end
	end)
end

function Hazards.Start()
	CollectionService:GetInstanceAddedSignal(Tags.Hazard):Connect(setup)
	for _, instance in CollectionService:GetTagged(Tags.Hazard) do
		setup(instance)
	end
end

return Hazards
