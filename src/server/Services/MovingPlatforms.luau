--!strict
-- Moves parts tagged MovingPlatform back and forth with physics, so players standing on them are carried.
-- Contract (Technical.md section 4): attributes Offset (Vector3) and Period (number, seconds).
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Tags = require(ReplicatedStorage.Shared.Tags)

type Platform = {
	start: Vector3,
	offset: Vector3,
	period: number,
	align: AlignPosition,
}

local platforms: { [BasePart]: Platform } = {}

local MovingPlatforms = {}

local function setup(instance: Instance)
	if not instance:IsA("BasePart") then
		warn(`[MovingPlatforms] {instance:GetFullName()} is tagged MovingPlatform but is not a BasePart`)
		return
	end

	local offset = instance:GetAttribute("Offset")
	local period = instance:GetAttribute("Period")
	if typeof(offset) ~= "Vector3" or type(period) ~= "number" or period <= 0 then
		warn(`[MovingPlatforms] {instance:GetFullName()} needs attributes Offset (Vector3) and Period (number > 0)`)
		return
	end

	-- An unanchored part moved by constraints carries the character standing on it.
	-- Moving an anchored part with CFrame or tweens does not.
	instance.Anchored = false

	local attachment = Instance.new("Attachment")
	attachment.Name = "PlatformAttachment"
	attachment.Parent = instance

	local align = Instance.new("AlignPosition")
	align.Mode = Enum.PositionAlignmentMode.OneAttachment
	align.Attachment0 = attachment
	align.MaxForce = math.huge
	align.MaxVelocity = math.huge
	align.Responsiveness = 200
	align.Position = instance.Position
	align.Parent = instance

	local orientation = Instance.new("AlignOrientation")
	orientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	orientation.Attachment0 = attachment
	orientation.MaxTorque = math.huge
	orientation.Responsiveness = 200
	orientation.CFrame = instance.CFrame.Rotation
	orientation.Parent = instance

	instance:SetNetworkOwner(nil) -- the server drives it, so every player sees the same motion

	platforms[instance] = {
		start = instance.Position,
		offset = offset,
		period = period,
		align = align,
	}
end

function MovingPlatforms.Start()
	CollectionService:GetInstanceAddedSignal(Tags.MovingPlatform):Connect(setup)
	CollectionService:GetInstanceRemovedSignal(Tags.MovingPlatform):Connect(function(instance)
		if instance:IsA("BasePart") then
			platforms[instance] = nil
		end
	end)
	for _, instance in CollectionService:GetTagged(Tags.MovingPlatform) do
		setup(instance)
	end

	RunService.Heartbeat:Connect(function()
		local now = workspace:GetServerTimeNow()
		for part, platform in platforms do
			if part.Parent == nil then
				platforms[part] = nil
				continue
			end
			-- Smooth back and forth: 0 -> 1 -> 0 over one period.
			local alpha = (1 - math.cos(2 * math.pi * now / platform.period)) / 2
			platform.align.Position = platform.start + platform.offset * alpha
		end
	end)
end

return MovingPlatforms
