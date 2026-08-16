--!strict

local AccentPalette = require(script.Parent.AccentPalette)
local PreferenceSchema = require(script.Parent.PreferenceSchema)
local Tokens = require(script.Parent.DesignTokens)

export type Theme = {
	accentId: string,
	uiScale: number,
	textScale: number,
	motion: string,
	motionScale: number,
	colors: { [string]: Color3 },
}

local ThemeContract = {}

function ThemeContract.resolve(preferences: any): Theme
	local values = PreferenceSchema.defaults()
	if type(preferences) == "table" then
		for key, value in preferences do
			local valid, normalized = PreferenceSchema.normalize(key, value)
			if valid then
				values[key] = normalized
			end
		end
	end
	local accent = AccentPalette.resolve(values.accentPaletteId)
	local motionScale = if values.motion == "full"
		then 1
		elseif values.motion == "reduced" then 0.35
		else 0
	return {
		accentId = accent.id,
		uiScale = values.uiScale,
		textScale = values.textScale,
		motion = values.motion,
		motionScale = motionScale,
		colors = {
			accent = accent.primary,
			accentHover = accent.hover,
			accentPressed = accent.pressed,
			accentSoft = accent.soft,
			accentOn = accent.on,
			focus = accent.focus,
			glow = accent.glow,
			success = Tokens.Color.Success,
			warning = Tokens.Color.Warning,
			danger = Tokens.Color.Danger,
			disabled = Tokens.Color.Disabled,
			pending = Tokens.Color.Pending,
		},
	}
end

return table.freeze(ThemeContract)
