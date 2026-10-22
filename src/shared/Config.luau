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

	RespawnSeconds = 1, -- tunable; Roblox's default of 5 is too slow for an obby
	ResetCooldownSeconds = 2,
	ProcessedPurchasesKept = 50,
})
