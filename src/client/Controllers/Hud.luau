--!strict
-- Always-on HUD: the current stage out of the total, and the Reset button.
-- It sits at the top centre, away from Roblox's own controls (menu top left, leaderboard top right,
-- thumbstick bottom left, jump button bottom right).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)
local Create = require(script.Parent.Parent.Create)

local HEIGHT = 44 -- minimum comfortable touch target
local PANEL_COLOR = Color3.fromRGB(28, 32, 48)
local TEXT_COLOR = Color3.fromRGB(240, 244, 255)
local RESET_COLOR = Color3.fromRGB(200, 70, 70)
local COOLDOWN_COLOR = Color3.fromRGB(90, 96, 120)

local Hud = {}

local function stageText(state: Types.StateChanged): string
	if state.Checkpoint == 0 then
		return "Hub"
	elseif state.TotalStages > 0 then
		return `Stage {state.Checkpoint} / {state.TotalStages}`
	end
	return `Stage {state.Checkpoint}`
end

function Hud.Start()
	local stageLabel = Create.new("TextLabel", {
		Name = "StageLabel",
		Size = UDim2.fromOffset(130, HEIGHT), -- fixed width, so it does not jump as the text changes
		BackgroundColor3 = PANEL_COLOR,
		BackgroundTransparency = 0.2,
		Text = "Hub",
		TextSize = 18,
		TextColor3 = TEXT_COLOR,
		Font = Enum.Font.GothamBold,
		LayoutOrder = 1,
	}, { Create.new("UICorner", { CornerRadius = UDim.new(0, 12) }) }) :: TextLabel

	local resetButton = Create.new("TextButton", {
		Name = "ResetButton",
		Size = UDim2.fromOffset(88, HEIGHT),
		BackgroundColor3 = RESET_COLOR,
		Text = "Reset",
		TextSize = 18,
		TextColor3 = TEXT_COLOR,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = true,
		LayoutOrder = 2,
	}, { Create.new("UICorner", { CornerRadius = UDim.new(0, 12) }) }) :: TextButton

	local gui = Create.new("ScreenGui", {
		Name = "Hud",
		ResetOnSpawn = false,
		DisplayOrder = 5, -- below the Continue / Start over prompt
	}, {
		Create.new("Frame", {
			Name = "Row",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 8),
			Size = UDim2.fromOffset(0, HEIGHT),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
		}, {
			Create.new("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			stageLabel,
			resetButton,
		}),
	}) :: ScreenGui
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	-- Local feedback only: the server rate limits RequestReset on its own.
	local cooling = false
	resetButton.Activated:Connect(function()
		if cooling then
			return
		end
		cooling = true
		resetButton.BackgroundColor3 = COOLDOWN_COLOR
		Remotes.RequestReset:FireServer()
		task.delay(Config.ResetCooldownSeconds, function()
			cooling = false
			resetButton.BackgroundColor3 = RESET_COLOR
		end)
	end)

	Remotes.StateChanged.OnClientEvent:Connect(function(state: Types.StateChanged)
		stageLabel.Text = stageText(state)
	end)
end

return Hud
