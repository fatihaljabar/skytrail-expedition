-- All gameplay numbers live here (CLAUDE.md section 4). Values marked "tunable" are first guesses (GDD.md).
return table.freeze({
	World = "SkyRuins",

	-- Stages 1-3 are tutorial stages and cannot be skipped (GDD section 9).
	TutorialStages = 3,

	Coins = table.freeze({
		PerRelic = 10, -- tunable
		FirstCompletion = 100, -- tunable
		RepeatCompletion = 25, -- tunable
	}),

	Skip = table.freeze({
		CoinCost = 40, -- tunable
		DeathsBeforeOffer = 5, -- tunable
	}),

	-- Glider prototype (GDD section 3, hook A). All first guesses until the M2-03 playtest.
	Glider = table.freeze({
		ForwardSpeed = 28, -- studs/s, tunable
		SinkSpeed = 12, -- studs/s, tunable
		MinAirSeconds = 0.2, -- airborne this long before a jump press opens the glider, tunable
		ToggleCooldownSeconds = 0.25, -- ignore a second jump press right after opening, tunable
	}),

	-- Studio-only developer tools (client/Controllers/DevTools.luau)
	Dev = table.freeze({
		FlySpeed = 60, -- studs/s
	}),

	RespawnSeconds = 1, -- tunable; Roblox's default of 5 is too slow for an obby
	ResetCooldownSeconds = 2,
	ProcessedPurchasesKept = 50,
})
