--!strict
-- Small helper to build UI instances from code: Create.new("Frame", { Size = ... }, { child, ... }).
local Create = {}

function Create.new(className: string, properties: { [string]: any }, children: { Instance }?): Instance
	local instance = Instance.new(className)
	for name, value in properties do
		(instance :: any)[name] = value
	end
	if children then
		for _, child in children do
			child.Parent = instance
		end
	end
	return instance
end

return Create
