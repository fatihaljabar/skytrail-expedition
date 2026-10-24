--!strict
-- Glider, the game's hook (GDD.md section 3, option A). Pressing jump again while airborne opens it;
-- pressing jump once more, or landing, closes it. It is movement only, so it lives on the client
-- (the player's own character is client-owned anyway) and never grants anything:
-- checkpoints and rewards stay on the server.
-- Parts tagged WindZone carry attribute Push (Vector3, studs/s) that is added to the glide velocity
-- while the player is inside them (Technical.md section 4).
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Tags = require(ReplicatedStorage.Shared.Tags)

local zones: { [BasePart]: Vector3 } = {}

local gliding = false
local glideStartedAt = 0
local airborneSince: number? = nil
local stepConnection: RBXScriptConnection? = nil

local Glider = {}

local function windAt(position: Vector3): Vector3
	local total = Vector3.zero
	for zone, push in zones do
		local offset = zone.CFrame:PointToObjectSpace(position)
		local half = zone.Size / 2
		if math.abs(offset.X) <= half.X and math.abs(offset.Y) <= half.Y and math.abs(offset.Z) <= half.Z then
			total += push
		end
	end
	return total
end

local function stop()
	if stepConnection then
		stepConnection:Disconnect()
		stepConnection = nil
	end
	gliding = false
	local character = Players.LocalPlayer.Character
	if character then
		character:SetAttribute("Gliding", false)
	end
end

local function start(character: Model, root: BasePart)
	gliding = true
	glideStartedAt = os.clock()
	character:SetAttribute("Gliding", true)

	stepConnection = RunService.PreSimulation:Connect(function(dt)
		local look = root.CFrame.LookVector
		local heading = Vector3.new(look.X, 0, look.Z)
		if heading.Magnitude < 1e-3 then
			return -- looking straight up or down
		end
		-- Gravity still pulls for one physics step after this runs, so add it back to sink at exactly SinkSpeed.
		local sink = Vector3.new(0, -Config.Glider.SinkSpeed + workspace.Gravity * dt, 0)
		root.AssemblyLinearVelocity = heading.Unit * Config.Glider.ForwardSpeed + sink + windAt(root.Position)
	end)
end

local function registerZone(instance: Instance)
	if not instance:IsA("BasePart") then
		warn(`[Glider] {instance:GetFullName()} is tagged WindZone but is not a BasePart`)
		return
	end
	local push = instance:GetAttribute("Push")
	if typeof(push) ~= "Vector3" then
		warn(`[Glider] {instance:GetFullName()} needs attribute Push (Vector3)`)
		return
	end
	zones[instance] = push
end

local function bind(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	airborneSince = nil

	humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
		if humanoid.FloorMaterial == Enum.Material.Air then
			airborneSince = airborneSince or os.clock()
		else
			airborneSince = nil
			if gliding then
				stop()
			end
		end
	end)
	humanoid.Died:Connect(stop)
end

local function onJumpRequest()
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not character or not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return
	end

	local now = os.clock()
	if gliding then
		if now - glideStartedAt >= Config.Glider.ToggleCooldownSeconds then
			stop()
		end
		return
	end

	local since = airborneSince
	if humanoid.FloorMaterial == Enum.Material.Air and since and now - since >= Config.Glider.MinAirSeconds then
		start(character, root)
	end
end

function Glider.Start()
	local player = Players.LocalPlayer

	-- With StreamingEnabled a zone can appear or disappear at any time.
	CollectionService:GetInstanceAddedSignal(Tags.WindZone):Connect(registerZone)
	CollectionService:GetInstanceRemovedSignal(Tags.WindZone):Connect(function(instance)
		if instance:IsA("BasePart") then
			zones[instance] = nil
		end
	end)
	for _, instance in CollectionService:GetTagged(Tags.WindZone) do
		registerZone(instance)
	end

	player.CharacterAdded:Connect(bind)
	player.CharacterRemoving:Connect(stop)
	if player.Character then
		task.spawn(bind, player.Character)
	end

	UserInputService.JumpRequest:Connect(onJumpRequest)
end

return Glider
