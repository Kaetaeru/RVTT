--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AccentPalette = require(ReplicatedStorage.RVTT.Shared.UI.AccentPalette)
local AccentPreference = require(ReplicatedStorage.RVTT.Shared.UI.AccentPreference)
local Tokens = require(ReplicatedStorage.RVTT.Shared.UI.DesignTokens)

type ColorMap = { [string]: Color3 }

local ThemeApplicator = {}

local function buildColors(accentId: any): ColorMap
	local accent = AccentPalette.resolve(accentId)
	return {
		canvas = Tokens.Color.Canvas,
		surface = Tokens.Color.Surface,
		surfaceRaised = Tokens.Color.SurfaceRaised,
		surfaceSoft = Tokens.Color.SurfaceSoft,
		stroke = Tokens.Color.Stroke,
		scrim = Tokens.Color.Scrim,
		textPrimary = Tokens.Color.TextPrimary,
		textSecondary = Tokens.Color.TextSecondary,
		textMuted = Tokens.Color.TextMuted,
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
		info = Tokens.Color.Info,
		pending = Tokens.Color.Pending,
	}
end

local function lookup(colors: ColorMap, value: any): Color3?
	if type(value) ~= "string" then
		return nil
	end
	return colors[value]
end

local function applyText(instance: Instance, color: Color3)
	if
		instance:IsA("TextLabel")
		or instance:IsA("TextButton")
		or instance:IsA("TextBox")
	then
		(instance :: any).TextColor3 = color
	end
end

local function applyImage(instance: Instance, color: Color3)
	if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
		(instance :: any).ImageColor3 = color
	end
end

local function applyInstance(instance: Instance, colors: ColorMap)
	local background = lookup(colors, instance:GetAttribute("RVTTBackgroundToken"))
	if background ~= nil and instance:IsA("GuiObject") then
		instance.BackgroundColor3 = background
	end

	local text = lookup(colors, instance:GetAttribute("RVTTTextToken"))
	if text ~= nil then
		applyText(instance, text)
	end

	local image = lookup(colors, instance:GetAttribute("RVTTImageToken"))
	if image ~= nil then
		applyImage(instance, image)
	end

	local stroke = lookup(colors, instance:GetAttribute("RVTTStrokeToken"))
	if stroke ~= nil and instance:IsA("UIStroke") then
		instance.Color = stroke
	end
end

function ThemeApplicator.apply(root: Instance, accentId: any): string
	local normalized = AccentPreference.normalize(accentId)
	local colors = buildColors(normalized)
	applyInstance(root, colors)
	for _, descendant in root:GetDescendants() do
		applyInstance(descendant, colors)
	end
	return normalized
end

return table.freeze(ThemeApplicator)
