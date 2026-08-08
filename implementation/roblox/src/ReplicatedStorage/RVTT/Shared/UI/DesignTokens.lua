--!strict

local AccentPalette = require(script.Parent.AccentPalette)
local defaultAccent = AccentPalette.resolve(nil)

local Tokens = {
	Color = {
		Canvas = Color3.fromRGB(11, 13, 16),
		Surface = Color3.fromRGB(23, 26, 31),
		SurfaceRaised = Color3.fromRGB(34, 38, 45),
		SurfaceSoft = Color3.fromRGB(48, 54, 64),
		Stroke = Color3.fromRGB(70, 77, 89),
		Scrim = Color3.fromRGB(0, 0, 0),
		TextPrimary = Color3.fromRGB(242, 239, 232),
		TextSecondary = Color3.fromRGB(187, 192, 200),
		TextMuted = Color3.fromRGB(129, 136, 148),
		TextOnAccent = defaultAccent.on,
		Accent = defaultAccent.primary,
		AccentHover = defaultAccent.hover,
		AccentPressed = defaultAccent.pressed,
		AccentSoft = defaultAccent.soft,
		AccentFocus = defaultAccent.focus,
		AccentGlow = defaultAccent.glow,
		Success = Color3.fromRGB(88, 168, 117),
		Warning = Color3.fromRGB(208, 160, 74),
		Danger = Color3.fromRGB(199, 93, 93),
		Disabled = Color3.fromRGB(101, 108, 120),
		Info = Color3.fromRGB(100, 152, 208),
		Pending = Color3.fromRGB(154, 130, 200),
		Focus = Color3.fromRGB(240, 201, 109),
	},
	Spacing = { XS = 4, SM = 8, MD = 12, LG = 16, XL = 24, XXL = 32 },
	Radius = { SM = UDim.new(0, 4), MD = UDim.new(0, 8), LG = UDim.new(0, 12) },
	TextSize = { Caption = 13, Body = 16, Label = 18, Heading = 22, Title = 28 },
	Layer = {
		WorldFeedback = 5,
		Hud = 10,
		Surface = 20,
		Panel = 20,
		System = 30,
		Overlay = 40,
		Prompt = 50,
		Toast = 60,
		Modal = 65,
		Tooltip = 70,
		Critical = 80,
		Recovery = 100,
	},
	Motion = { Fast = 0.12, Normal = 0.2, Slow = 0.35 },
}

return table.freeze(Tokens)

