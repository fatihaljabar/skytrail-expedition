--!strict
-- Collapsing platforms, local to each player (Technical.md section 5).
-- Parts tagged FallingPlatform carry attributes Delay (seconds of shaking before it collapses)
-- and RespawnTime (seconds until it is back). Everything here changes only this client's view,
-- so other players still see and stand on the platform. There are no rewards involved,
-- which is why this does not need the server.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Tags = require(ReplicatedStorage.Shared.Tags)

local FADE_SECONDS = 0.25
local SHAKE_STUDS = 0.15
local SHAKE_STEP = 1 / 30

-- weak keys, so a platform that streams out does not keep an entry alive
local collapsing: { [BasePart]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local FallingPlatforms = {}

local function collapse(part: BasePart, shakeSeconds: number, respawnSeconds: number)
	collapsing[part] = true
	local home = part.CFrame
	local solid = part.CanCollide
	local transparency = part.Transparency

	local startedAt = os.clock()
	while part.Parent and os.clock() - startedAt < shakeSeconds do
		local dx = (math.random() - 0.5) * 2 * SHAKE_STUDS
		local dz = (math.random() - 0.5) * 2 * SHAKE_STUDS
		part.CFrame = home * CFrame.new(dx, 0, dz)
		task.wait(SHAKE_STEP)
	end

	if part.Parent then
		part.CFrame = home
		part.CanCollide = false
		TweenService:Create(part, TweenInfo.new(FADE_SECONDS), { Transparency = 1 }):Play()
		task.wait(respawnSeconds)
	end

	if part.Parent then
		part.CanCollide = solid
		TweenService:Create(part, TweenInfo.new(FADE_SECONDS), { Transparency = transparency }):Play()
	end
	collapsing[part] = nil
end

local function setup(instance: Instance)
	if not instance:IsA("BasePart") then
		warn(`[FallingPlatforms] {instance:GetFullName()} is tagged FallingPlatform but is not a BasePart`)
		return
	end

	local shakeSeconds = instance:GetAttribute("Delay")
	local respawnSeconds = instance:GetAttribute("RespawnTime")
	if
		type(shakeSeconds) ~= "number"
		or shakeSeconds < 0
		or type(respawnSeconds) ~= "number"
		or respawnSeconds <= 0
	then
		warn(
			`[FallingPlatforms] {instance:GetFullName()} needs attributes Delay (number >= 0) and RespawnTime (number > 0)`
		)
		return
	end

	instance.Touched:Connect(function(hit)
		local character = Players.LocalPlayer.Character
		if collapsing[instance] or not character or not hit:IsDescendantOf(character) then
			return
		end

		-- Only standing on top counts, not brushing against the side.
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root or not root:IsA("BasePart") or root.Position.Y < instance.Position.Y + instance.Size.Y / 2 then
			return
		end

		task.spawn(collapse, instance, shakeSeconds, respawnSeconds)
	end)
end

function FallingPlatforms.Start()
	-- With StreamingEnabled a platform can appear at any time, so listen for new ones as well.
	CollectionService:GetInstanceAddedSignal(Tags.FallingPlatform):Connect(setup)
	for _, instance in CollectionService:GetTagged(Tags.FallingPlatform) do
		setup(instance)
	end
end

return FallingPlatforms
