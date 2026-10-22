--!strict
-- Server bootstrap: require every module in Services, run all Init, then all Start.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)

local servicesFolder = script:FindFirstChild("Services")
local services: { Types.Module } = {}

if servicesFolder then
	for _, child in servicesFolder:GetChildren() do
		if child:IsA("ModuleScript") then
			table.insert(services, require(child) :: Types.Module)
		end
	end
end

for _, service in services do
	if service.Init then
		service.Init()
	end
end

for _, service in services do
	task.spawn(service.Start)
end

print(`[Server] started ({#services} services)`)
