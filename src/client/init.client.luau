--!strict
-- Client bootstrap: require every module in Controllers, run all Init, then all Start.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)

local controllersFolder = script:FindFirstChild("Controllers")
local controllers: { Types.Module } = {}

if controllersFolder then
	for _, child in controllersFolder:GetChildren() do
		if child:IsA("ModuleScript") then
			table.insert(controllers, require(child) :: Types.Module)
		end
	end
end

for _, controller in controllers do
	if controller.Init then
		controller.Init()
	end
end

for _, controller in controllers do
	task.spawn(controller.Start)
end

-- Ask the server for the current state once, after every controller is listening for StateChanged.
-- (The server rate limits this, so controllers must not each ask on their own.)
Remotes.RequestState:FireServer()

print(`[Client] started ({#controllers} controllers)`)
