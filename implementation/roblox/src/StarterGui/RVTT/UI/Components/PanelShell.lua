--!strict

local Tokens = require(game:GetService("ReplicatedStorage").RVTT.Shared.UI.DesignTokens)

return function(name: string, size: UDim2, position: UDim2): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.Position = position
	frame.BorderSizePixel = 0
	frame:SetAttribute("RVTTBackgroundToken", "surface")

	local corner = Instance.new("UICorner")
	corner.CornerRadius = Tokens.Radius.MD
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Transparency = 0.25
	stroke:SetAttribute("RVTTStrokeToken", "stroke")
	stroke.Parent = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, Tokens.Spacing.MD)
	padding.PaddingRight = padding.PaddingLeft
	padding.PaddingTop = padding.PaddingLeft
	padding.PaddingBottom = padding.PaddingLeft
	padding.Parent = frame

	return frame
end
