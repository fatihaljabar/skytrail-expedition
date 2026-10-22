--!strict
-- Shown when the player joins with saved progress: Continue from the last checkpoint or Start over.
-- Start over asks for confirmation. The server decides everything; this only sends the choice.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)
local Create = require(script.Parent.Parent.Create)

local BUTTON_HEIGHT = 52 -- thumb friendly
local CARD_COLOR = Color3.fromRGB(28, 32, 48)
local TEXT_COLOR = Color3.fromRGB(240, 244, 255)
local GREEN = Color3.fromRGB(46, 160, 90)
local RED = Color3.fromRGB(200, 70, 70)
local GREY = Color3.fromRGB(70, 78, 102)

local ChoicePrompt = {}

local function label(text: string, size: number, bold: boolean): TextLabel
	return Create.new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = text,
		TextWrapped = true,
		TextSize = size,
		TextColor3 = TEXT_COLOR,
		Font = if bold then Enum.Font.GothamBold else Enum.Font.Gotham,
	}) :: TextLabel
end

local function button(text: string, color: Color3, height: number): TextButton
	return Create.new("TextButton", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = color,
		Text = text,
		TextSize = 20,
		TextColor3 = TEXT_COLOR,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = true,
	}, { Create.new("UICorner", { CornerRadius = UDim.new(0, 10) }) }) :: TextButton
end

local function page(name: string): Frame
	return Create.new("Frame", {
		Name = name,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, {
		Create.new("UIListLayout", {
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}),
	}) :: Frame
end

function ChoicePrompt.Start()
	local title = label("Welcome back!", 24, true)
	local body = label("", 18, false)
	local continueButton = button("Continue", GREEN, BUTTON_HEIGHT)
	continueButton.Name = "ContinueButton"
	local startOverButton = button("Start over", GREY, 40)
	startOverButton.Name = "StartOverButton"

	local mainPage = page("MainPage")
	local mainChildren: { GuiObject } = { title, body, continueButton, startOverButton }
	for index, child in mainChildren do
		child.LayoutOrder = index
		child.Parent = mainPage
	end

	local confirmText = label("Start over from Stage 1? Your Coins, Relics and cosmetics are kept.", 18, false)
	local confirmButton = button("Yes, start over", RED, BUTTON_HEIGHT)
	confirmButton.Name = "ConfirmButton"
	local cancelButton = button("Cancel", GREY, 40)
	cancelButton.Name = "CancelButton"

	local confirmPage = page("ConfirmPage")
	confirmPage.Visible = false
	local confirmChildren: { GuiObject } = { confirmText, confirmButton, cancelButton }
	for index, child in confirmChildren do
		child.LayoutOrder = index
		child.Parent = confirmPage
	end

	local gui = Create.new("ScreenGui", {
		Name = "ChoicePrompt",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 10,
		Enabled = false,
	}, {
		Create.new("Frame", {
			Name = "Card",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.9, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = CARD_COLOR,
		}, {
			Create.new("UICorner", { CornerRadius = UDim.new(0, 16) }),
			Create.new("UIPadding", {
				PaddingTop = UDim.new(0, 16),
				PaddingBottom = UDim.new(0, 16),
				PaddingLeft = UDim.new(0, 16),
				PaddingRight = UDim.new(0, 16),
			}),
			Create.new("UISizeConstraint", { MaxSize = Vector2.new(380, math.huge) }),
			mainPage,
			confirmPage,
		}),
	}) :: ScreenGui
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	local function showMain()
		mainPage.Visible = true
		confirmPage.Visible = false
	end

	continueButton.Activated:Connect(function()
		gui.Enabled = false -- the server confirms with StateChanged
		Remotes.RequestContinue:FireServer()
	end)
	startOverButton.Activated:Connect(function()
		mainPage.Visible = false
		confirmPage.Visible = true
	end)
	cancelButton.Activated:Connect(showMain)
	confirmButton.Activated:Connect(function()
		gui.Enabled = false
		Remotes.RequestStartOver:FireServer()
	end)

	Remotes.StateChanged.OnClientEvent:Connect(function(state: Types.StateChanged)
		body.Text = `You reached Stage {state.Checkpoint}. Pick up where you left off?`
		if state.NeedsChoice then
			showMain()
		end
		gui.Enabled = state.NeedsChoice
	end)
end

return ChoicePrompt
