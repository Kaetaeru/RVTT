--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ThemeContract = require(ReplicatedStorage.RVTT.Shared.UI.ThemeContract)
local Tokens = require(ReplicatedStorage.RVTT.Shared.UI.DesignTokens)

type ColorMap = { [string]: Color3 }

local ThemeApplicator = {}

local function buildColors(theme: any): ColorMap
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
		accent = theme.colors.accent,
		accentHover = theme.colors.accentHover,
		accentPressed = theme.colors.accentPressed,
		accentSoft = theme.colors.accentSoft,
		accentOn = theme.colors.accentOn,
		focus = theme.colors.focus,
		glow = theme.colors.glow,
		success = Tokens.Color.Success,
		warning = Tokens.Color.Warning,
		danger = Tokens.Color.Danger,
		info = Tokens.Color.Info,
		pending = Tokens.Color.Pending,
		disabled = Tokens.Color.Disabled,
	}
end

local function lookup(colors: ColorMap, value: any): Color3?
	if type(value) ~= "string" then
		return nil
	end
	return colors[value]
end

local function applyText(instance: Instance, color: Color3)
	if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
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

local function applyTextScale(instance: Instance, scale: number)
	if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
		local textObject = instance :: any
		local storedSize = instance:GetAttribute("RVTTBaseTextSize")
		local baseSize: number
		if type(storedSize) == "number" then
			baseSize = storedSize
		else
			baseSize = textObject.TextSize
			instance:SetAttribute("RVTTBaseTextSize", baseSize)
		end
		textObject.TextSize = math.floor(baseSize * scale + 0.5)
	end
end

function ThemeApplicator.apply(root: Instance, preferences: any): string
	local input = if type(preferences) == "string"
		then { accentPaletteId = preferences }
		else preferences
	local theme = ThemeContract.resolve(input)
	local colors = buildColors(theme)
	applyInstance(root, colors)
	applyTextScale(root, theme.textScale)
	for _, descendant in root:GetDescendants() do
		applyInstance(descendant, colors)
		applyTextScale(descendant, theme.textScale)
		if descendant:IsA("UIScale") and descendant.Name == "RVTT_UI_SCALE" then
			descendant.Scale = theme.uiScale
		end
	end
	root:SetAttribute("RVTTMotion", theme.motion)
	root:SetAttribute("RVTTMotionScale", theme.motionScale)
	return theme.accentId
end

return table.freeze(ThemeApplicator)

