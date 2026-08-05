--!strict

export type BuiltinPack = {
	packId: string,
	version: string,
	ruleset: string?,
	rightsStatus: string,
	blockedReason: string?,
	contentKinds: { string },
}

local packs: { BuiltinPack } = {
	{
		packId = "rvtt.core.runtime",
		version = "1.0.0",
		ruleset = "dnd5e-2024",
		rightsStatus = "original",
		contentKinds = { "runtime", "ui", "localization_keys" },
	},
	{
		packId = "rvtt.official.placeholder",
		version = "0.0.0",
		rightsStatus = "blocked",
		blockedReason = "Official data and distribution rights require explicit review.",
		contentKinds = { "character_options", "spells", "equipment", "monsters" },
	},
}

return table.freeze(packs)
