--!strict

local Tokens = require(game:GetService("ReplicatedStorage").RVTT.Shared.UI.DesignTokens)

return function(): TextLabel
	local value = Instance.new("TextLabel")
	value.Name = "StateBanner"
	value.Size = UDim2.new(1, -164, 0, 40)
	value.Position = UDim2.fromOffset(16, 16)
	value.BorderSizePixel = 0
	value.TextSize = Tokens.TextSize.Body
	value.Text = "연결 상태 확인 중"
	value.TextXAlignment = Enum.TextXAlignment.Left
	value:SetAttribute("RVTTBackgroundToken", "surfaceRaised")
	value:SetAttribute("RVTTTextToken", "textPrimary")

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, Tokens.Spacing.MD)
	padding.PaddingRight = UDim.new(0, Tokens.Spacing.MD)
	padding.Parent = value

	local corner = Instance.new("UICorner")
	corner.CornerRadius = Tokens.Radius.SM
	corner.Parent = value

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Transparency = 0.25
	stroke:SetAttribute("RVTTStrokeToken", "accent")
	stroke.Parent = value

	return value
end
