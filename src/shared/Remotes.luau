--!strict
-- The only place that fetches remotes from ReplicatedStorage.Remotes.
-- Declare a new remote in default.project.json, then add it here.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:WaitForChild("Remotes")

return table.freeze({
	RequestReset = folder:WaitForChild("RequestReset") :: RemoteEvent,
	StateChanged = folder:WaitForChild("StateChanged") :: RemoteEvent,
	RequestState = folder:WaitForChild("RequestState") :: RemoteEvent,
	RequestContinue = folder:WaitForChild("RequestContinue") :: RemoteEvent,
	RequestStartOver = folder:WaitForChild("RequestStartOver") :: RemoteEvent,
})
