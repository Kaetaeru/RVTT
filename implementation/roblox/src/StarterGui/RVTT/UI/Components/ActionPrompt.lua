--!strict

local Tokens = require(game:GetService("ReplicatedStorage").RVTT.Shared.UI.DesignTokens)

return function(): Frame
	local frame = Instance.new("Frame")
	frame.Name = "ActionPrompt"
	frame.Size = UDim2.fromOffset(360, 72)
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.new(0.5, 0, 1, -24)
	frame.BorderSizePixel = 0
	frame:SetAttribute("RVTTBackgroundToken", "surfaceRaised")

	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.TextSize = Tokens.TextSize.Body
	text.Text = "Q 취소    E 확인"
	text:SetAttribute("RVTTTextToken", "textPrimary")
	text.Parent = frame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = Tokens.Radius.MD
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Transparency = 0.18
	stroke:SetAttribute("RVTTStrokeToken", "accent")
	stroke.Parent = frame

	local accentBar = Instance.new("Frame")
	accentBar.Name = "AccentBar"
	accentBar.Size = UDim2.new(0, 4, 1, -16)
	accentBar.Position = UDim2.fromOffset(8, 8)
	accentBar.BorderSizePixel = 0
	accentBar:SetAttribute("RVTTBackgroundToken", "accent")
	accentBar.Parent = frame
	local accentCorner = Instance.new("UICorner")
	accentCorner.CornerRadius = UDim.new(1, 0)
	accentCorner.Parent = accentBar

	return frame
end
