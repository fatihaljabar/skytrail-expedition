--!strict
-- The Reset button: kills the character, and Checkpoints respawns it at the last checkpoint
-- (or in the hub). Rate limited, so spamming the remote cannot loop the player through deaths.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local RateLimit = require(script.Parent.Parent.RateLimit)

local Reset = {}

function Reset.Start()
	local allow = RateLimit.new(Config.ResetCooldownSeconds)

	Remotes.RequestReset.OnServerEvent:Connect(function(player)
		if not allow(player) then
			return
		end

		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid.Health = 0
		end
	end)
end

return Reset
