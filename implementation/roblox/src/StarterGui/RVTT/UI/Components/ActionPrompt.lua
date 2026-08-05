--!strict
local Tokens = require(game:GetService("ReplicatedStorage").RVTT.Shared.UI.DesignTokens)
return function(): Frame
	local f = Instance.new("Frame")
	f.Name = "ActionPrompt"
	f.Size = UDim2.fromOffset(360, 72)
	f.AnchorPoint = Vector2.new(0.5, 1)
	f.Position = UDim2.new(0.5, 0, 1, -24)
	f.BackgroundColor3 = Tokens.Color.SurfaceRaised
	f.BorderSizePixel = 0
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.TextColor3 = Tokens.Color.TextPrimary
	t.TextSize = Tokens.TextSize.Body
	t.Text = "Q 취소    E 확인"
	t.Parent = f
	local c = Instance.new("UICorner")
	c.CornerRadius = Tokens.Radius.MD
	c.Parent = f
	return f
end
