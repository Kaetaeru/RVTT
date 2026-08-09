--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Tokens = require(ReplicatedStorage.RVTT.Shared.UI.DesignTokens)

local Popover = {}
Popover.__index = Popover

local function clearButtons(parent: Instance)
	for _, child in parent:GetChildren() do
		if child:IsA("TextButton") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end
end

local function actionButton(parent: Instance, action: any, callback: (string) -> ()): TextButton
	local button = Instance.new("TextButton")
	button.Name = "SheetItemAction_" .. tostring(action.id)
	button.Size = UDim2.new(1, 0, 0, 28)
	button.AutoButtonColor = false
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamMedium
	button.TextSize = Tokens.TextSize.Caption
	button.Text = tostring(action.label or action.id)
	button.Selectable = action.enabled ~= false
	button.Active = action.enabled ~= false
	button:SetAttribute("RVTTBackgroundToken", if button.Active then "surfaceSoft" else "disabled")
	button:SetAttribute("RVTTTextToken", if button.Active then "textPrimary" else "disabled")
	button:SetAttribute("RVTTDisabledReason", action.disabledReason)
	button.Parent = parent
	if button.Active and action.localOnly ~= true then
		button.Activated:Connect(function()
			callback(action.id)
		end)
	end
	return button
end

function Popover.new(parent: Instance, callback: (string) -> ()): any
	local root = Instance.new("Frame")
	root.Name = "SheetItemActionPopover"
	root.Size = UDim2.new(1, -12, 0, 232)
	root.Position = UDim2.fromOffset(6, 44)
	root.BorderSizePixel = 0
	root:SetAttribute("RVTTBackgroundToken", "surfaceRaised")
	root.Parent = parent
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.Parent = root
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingBottom = UDim.new(0, 6)
	padding.PaddingLeft = UDim.new(0, 6)
	padding.PaddingRight = UDim.new(0, 6)
	padding.Parent = root
	return setmetatable({ Root = root, callback = callback }, Popover)
end

function Popover.render(self: any, item: any?)
	clearButtons(self.Root)
	if type(item) ~= "table" then
		local empty = Instance.new("TextLabel")
		empty.Name = "NoEquipmentActions"
		empty.Size = UDim2.new(1, 0, 0, 32)
		empty.BackgroundTransparency = 1
		empty.Text = "조작 가능한 장비가 없습니다"
		empty.TextSize = Tokens.TextSize.Caption
		empty:SetAttribute("RVTTTextToken", "textSecondary")
		empty.Parent = self.Root
		return
	end
	for _, action in item.actions do
		actionButton(self.Root, action, self.callback)
	end
end

return table.freeze(Popover)
