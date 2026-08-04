--!strict
local Tokens=require(game:GetService("ReplicatedStorage").RVTT.Shared.UI.DesignTokens)
return function(name:string,size:UDim2,position:UDim2):Frame local f=Instance.new("Frame");f.Name=name;f.Size=size;f.Position=position;f.BackgroundColor3=Tokens.Color.Surface;f.BorderSizePixel=0;local c=Instance.new("UICorner");c.CornerRadius=Tokens.Radius.MD;c.Parent=f;local p=Instance.new("UIPadding");p.PaddingLeft=UDim.new(0,Tokens.Spacing.MD);p.PaddingRight=p.PaddingLeft;p.PaddingTop=p.PaddingLeft;p.PaddingBottom=p.PaddingLeft;p.Parent=f;return f end
