--!strict
-- Per-player cooldown for remote handlers: the returned function allows one call per interval.
local RateLimit = {}

function RateLimit.new(intervalSeconds: number): (Player) -> boolean
	-- weak keys, so a player who left does not keep an entry alive
	local last: { [Player]: number } = setmetatable({}, { __mode = "k" }) :: any

	return function(player: Player): boolean
		local now = os.clock()
		local previous = last[player]
		if previous and now - previous < intervalSeconds then
			return false
		end
		last[player] = now
		return true
	end
end

return RateLimit
