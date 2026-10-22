-- Shared types. PlayerData mirrors Technical.md section 6.
export type WorldProgress = {
	Checkpoint: number, -- position of the current run, 0 = in the hub
	Completed: boolean,
	BestTime: number?,
}

export type PlayerData = {
	DataVersion: number,
	Coins: number,
	Worlds: { [string]: WorldProgress },
	Relics: { [string]: boolean }, -- key: RelicId
	Cosmetics: { Owned: { [string]: boolean }, Equipped: string? },
	Stats: { Deaths: number, Completions: number, Skips: number },
	ProcessedPurchases: { string }, -- last PurchaseIds, capped by Config.ProcessedPurchasesKept
}

-- Payload of the StateChanged remote (server to client).
export type StateChanged = {
	Checkpoint: number, -- position of the current run in the world, 0 = in the hub
	NeedsChoice: boolean, -- true while the player must pick Continue or Start over
}

-- Every service (server) and controller (client) follows this shape.
export type Module = {
	Init: (() -> ())?, -- must not yield
	Start: () -> (),
}

return {}
