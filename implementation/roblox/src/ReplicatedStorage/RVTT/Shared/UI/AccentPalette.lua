--!strict

local AccentPreference = require(script.Parent.AccentPreference)

export type Palette = {
	id: string,
	displayName: string,
	primary: Color3,
	hover: Color3,
	pressed: Color3,
	soft: Color3,
	on: Color3,
	focus: Color3,
	glow: Color3,
}

local palettes: { [string]: Palette } = {
	gold = {
		id = "gold",
		displayName = "황금색",
		primary = Color3.fromRGB(217, 184, 95),
		hover = Color3.fromRGB(235, 206, 126),
		pressed = Color3.fromRGB(181, 143, 62),
		soft = Color3.fromRGB(65, 54, 32),
		on = Color3.fromRGB(24, 20, 11),
		focus = Color3.fromRGB(240, 201, 109),
		glow = Color3.fromRGB(244, 202, 105),
	},
	azure = {
		id = "azure",
		displayName = "푸른색",
		primary = Color3.fromRGB(98, 169, 230),
		hover = Color3.fromRGB(132, 195, 245),
		pressed = Color3.fromRGB(65, 130, 190),
		soft = Color3.fromRGB(25, 50, 73),
		on = Color3.fromRGB(9, 20, 30),
		focus = Color3.fromRGB(133, 205, 255),
		glow = Color3.fromRGB(93, 183, 255),
	},
	emerald = {
		id = "emerald",
		displayName = "에메랄드",
		primary = Color3.fromRGB(88, 184, 138),
		hover = Color3.fromRGB(120, 207, 164),
		pressed = Color3.fromRGB(56, 143, 101),
		soft = Color3.fromRGB(24, 57, 43),
		on = Color3.fromRGB(8, 24, 17),
		focus = Color3.fromRGB(126, 226, 174),
		glow = Color3.fromRGB(78, 215, 145),
	},
	amethyst = {
		id = "amethyst",
		displayName = "자수정",
		primary = Color3.fromRGB(155, 124, 224),
		hover = Color3.fromRGB(183, 155, 240),
		pressed = Color3.fromRGB(116, 87, 184),
		soft = Color3.fromRGB(49, 38, 70),
		on = Color3.fromRGB(19, 13, 28),
		focus = Color3.fromRGB(196, 169, 255),
		glow = Color3.fromRGB(170, 126, 255),
	},
	teal = {
		id = "teal",
		displayName = "청록색",
		primary = Color3.fromRGB(79, 182, 178),
		hover = Color3.fromRGB(112, 207, 202),
		pressed = Color3.fromRGB(50, 139, 136),
		soft = Color3.fromRGB(23, 55, 55),
		on = Color3.fromRGB(7, 23, 23),
		focus = Color3.fromRGB(119, 225, 219),
		glow = Color3.fromRGB(71, 214, 207),
	},
	silver = {
		id = "silver",
		displayName = "은색",
		primary = Color3.fromRGB(170, 178, 192),
		hover = Color3.fromRGB(201, 207, 217),
		pressed = Color3.fromRGB(128, 138, 156),
		soft = Color3.fromRGB(48, 52, 61),
		on = Color3.fromRGB(17, 19, 23),
		focus = Color3.fromRGB(220, 225, 234),
		glow = Color3.fromRGB(190, 201, 220),
	},
}

for _, palette in palettes do
	table.freeze(palette)
end

table.freeze(palettes)

local AccentPalette = {}

function AccentPalette.resolve(value: any): Palette
	return palettes[AccentPreference.normalize(value)]
end

function AccentPalette.list(): { Palette }
	local result: { Palette } = {}
	for _, id in AccentPreference.list() do
		table.insert(result, palettes[id])
	end
	return result
end

return table.freeze(AccentPalette)
