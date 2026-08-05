--!strict
local Tokens = require(game:GetService("ReplicatedStorage").RVTT.Shared.UI.DesignTokens)
return function(): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = "StateBanner"
	l.Size = UDim2.new(1, -32, 0, 40)
	l.Position = UDim2.fromOffset(16, 16)
	l.BackgroundColor3 = Tokens.Color.SurfaceRaised
	l.TextColor3 = Tokens.Color.TextPrimary
	l.TextSize = Tokens.TextSize.Body
	l.Text = "연결 상태 확인 중"
	l.BorderSizePixel = 0
	local c = Instance.new("UICorner")
	c.CornerRadius = Tokens.Radius.SM
	c.Parent = l
	return l
end
