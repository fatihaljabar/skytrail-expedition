--!strict
-- Developer chat commands. They only exist inside Studio and are never created in a published game,
-- so players (and exploiters) never see them. They change only this client's own character and grant nothing.
-- /fly  toggles free flight: move with the usual stick or WASD, E goes up, Q goes down.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)

local flyConnection: RBXScriptConnection? = nil

local DevTools = {}

local function stopFly()
	if flyConnection then
		flyConnection:Disconnect()
		flyConnection = nil
	end
end

local function toggleFly()
	if flyConnection then
		stopFly()
		return
	end

	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or not root:IsA("BasePart") then
		return
	end

	flyConnection = RunService.PreSimulation:Connect(function(dt)
		local vertical = 0
		if UserInputService:IsKeyDown(Enum.KeyCode.E) then
			vertical += 1
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
			vertical -= 1
		end
		local move = humanoid.MoveDirection * Config.Dev.FlySpeed
		-- Gravity still pulls for one physics step after this runs, so add it back to hover.
		root.AssemblyLinearVelocity =
			Vector3.new(move.X, vertical * Config.Dev.FlySpeed + workspace.Gravity * dt, move.Z)
	end)
end

function DevTools.Start()
	if not RunService:IsStudio() then
		return
	end

	local command = Instance.new("TextChatCommand")
	command.Name = "FlyCommand"
	command.PrimaryAlias = "/fly"
	command.Triggered:Connect(toggleFly)
	command.Parent = TextChatService

	Players.LocalPlayer.CharacterRemoving:Connect(stopFly)
	print("[DevTools] /fly is available (E up, Q down)")
end

return DevTools
