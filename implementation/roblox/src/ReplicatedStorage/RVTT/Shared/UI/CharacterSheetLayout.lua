--!strict

local Layout = {
	REFERENCE_PAGE_WIDTH = 8.5,
	REFERENCE_PAGE_HEIGHT = 11,
	RATIO_TOLERANCE = 0.02,
	COMPACT_BREAKPOINT = 1200,
	PAGE_1 = {
		TOP_HEADER = 0.13,
		MAIN = 0.87,
		MAIN_LEFT = 0.35,
		MAIN_RIGHT = 0.65,
		RIGHT_WEAPONS = 0.24,
		RIGHT_CLASS_FEATURES = 0.43,
		RIGHT_SPECIES_FEATS = 0.33,
	},
	PAGE_2 = {
		LEFT = 0.68,
		RIGHT = 0.32,
		SPELLCASTING_ABILITY = 0.24,
		SPELL_SLOTS = 0.76,
		RIGHT_APPEARANCE = 0.14,
		RIGHT_BACKSTORY = 0.30,
		RIGHT_LANGUAGES = 0.10,
		RIGHT_EQUIPMENT = 0.34,
		RIGHT_COINS = 0.12,
	},
}

function Layout.modeForWidth(width: number): string
	return if width < Layout.COMPACT_BREAKPOINT then "Compact" else "WideReference"
end

return table.freeze(Layout)
