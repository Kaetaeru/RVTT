--!strict

local Tokens = {
	Color = {
		Canvas = Color3.fromRGB(18, 20, 24),
		Surface = Color3.fromRGB(31, 34, 41),
		SurfaceRaised = Color3.fromRGB(43, 47, 56),
		TextPrimary = Color3.fromRGB(238, 239, 242),
		TextSecondary = Color3.fromRGB(176, 181, 191),
		Accent = Color3.fromRGB(82, 139, 199),
		Success = Color3.fromRGB(87, 166, 112),
		Warning = Color3.fromRGB(219, 168, 75),
		Danger = Color3.fromRGB(204, 82, 82),
		Focus = Color3.fromRGB(123, 184, 255),
	},
	Spacing = { XS = 4, SM = 8, MD = 12, LG = 16, XL = 24 },
	Radius = { SM = UDim.new(0, 4), MD = UDim.new(0, 8), LG = UDim.new(0, 12) },
	TextSize = { Caption = 13, Body = 16, Heading = 20, Title = 28 },
	Layer = { Hud = 10, Panel = 20, Prompt = 40, Critical = 60, Recovery = 80 },
}

return table.freeze(Tokens)
