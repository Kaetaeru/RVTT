--!strict

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Tokens = require(ReplicatedStorage.RVTT.Shared.UI.DesignTokens)

local Hud = {}
Hud.__index = Hud

local function panel(name: string): Frame
	local value = Instance.new("Frame")
	value.Name = name
	value.BorderSizePixel = 0
	value:SetAttribute("RVTTBackgroundToken", "surfaceRaised")
	local corner = Instance.new("UICorner")
	corner.CornerRadius = Tokens.Radius.MD
	corner.Parent = value
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Transparency = 0.22
	stroke:SetAttribute("RVTTStrokeToken", "accent")
	stroke.Parent = value
	return value
end

local function textLabel(name: string, size: number, token: string): TextLabel
	local value = Instance.new("TextLabel")
	value.Name = name
	value.BackgroundTransparency = 1
	value.BorderSizePixel = 0
	value.Font = Enum.Font.GothamMedium
	value.TextSize = size
	value.TextXAlignment = Enum.TextXAlignment.Left
	value.TextTruncate = Enum.TextTruncate.AtEnd
	value:SetAttribute("RVTTTextToken", token)
	return value
end

local function clearLabels(parent: Instance)
	for _, child in parent:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
end

local function feedbackText(feedback: any): string
	local state = feedback.state
	if state == "ready" then
		return "권위 상태와 동기화됨"
	elseif state == "pending" then
		return "서버 응답 대기 중"
	elseif state == "partial" then
		return "승인됨 · Projection 반영 대기"
	elseif state == "stale" then
		return "상태가 변경됨 · 미리보기를 갱신하세요"
	elseif state == "expired" then
		return "반응 기회가 만료되었습니다"
	elseif state == "permission_denied" then
		return "이 행동을 요청할 권한이 없습니다"
	elseif state == "network_error" then
		return "서버 응답을 받지 못했습니다"
	elseif state == "validation_error" then
		return "현재 상태에서 유효하지 않은 요청입니다"
	elseif state == "conflict" then
		return "다른 상태 변경과 충돌했습니다"
	elseif state == "recovery" then
		return "권위 상태를 복구하는 중입니다"
	end
	return tostring(state)
end

local function feedbackToken(state: string): string
	if state == "ready" then
		return "success"
	elseif state == "pending" or state == "partial" then
		return "pending"
	elseif state == "stale" or state == "expired" or state == "conflict" then
		return "warning"
	end
	return "danger"
end

local function previewText(preview: any?): string
	if type(preview) ~= "table" then
		return "월드 대상을 가리키면 기본 행동을 미리 볼 수 있습니다"
	end
	local parts = { preview.label .. " → " .. preview.targetLabel }
	if type(preview.distance) == "number" then
		table.insert(parts, string.format("거리 %.1f studs", preview.distance))
	end
	if type(preview.remaining) == "number" then
		table.insert(parts, string.format("남은 이동 %.1f", preview.remaining))
	end
	if type(preview.excess) == "number" and preview.excess > 0 then
		table.insert(parts, string.format("초과 %.1f", preview.excess))
	end
	if type(preview.disabledReason) == "string" then
		table.insert(parts, preview.disabledReason)
	end
	for _, risk in preview.riskLabels do
		table.insert(parts, risk)
	end
	return table.concat(parts, " · ")
end

function Hud.new(parent: Instance, toastParent: Instance, onEndTurn: () -> ()): any
	local root = panel("GameplayHud")
	root.AnchorPoint = Vector2.new(0.5, 1)
	root.Position = UDim2.new(0.5, 0, 1, -20)
	root.Size = UDim2.fromOffset(760, 150)
	root.Parent = parent

	local actorLabel = textLabel("SelectedActor", Tokens.TextSize.Label, "textPrimary")
	actorLabel.Position = UDim2.fromOffset(16, 12)
	actorLabel.Size = UDim2.fromOffset(250, 26)
	actorLabel.Parent = root

	local hpLabel = textLabel("HitPoints", Tokens.TextSize.Body, "success")
	hpLabel.Position = UDim2.fromOffset(16, 40)
	hpLabel.Size = UDim2.fromOffset(250, 24)
	hpLabel.Parent = root

	local modeLabel = textLabel("Mode", Tokens.TextSize.Caption, "textSecondary")
	modeLabel.Position = UDim2.fromOffset(16, 68)
	modeLabel.Size = UDim2.fromOffset(250, 22)
	modeLabel.Parent = root

	local resources = Instance.new("Frame")
	resources.Name = "ResourceRail"
	resources.BackgroundTransparency = 1
	resources.Position = UDim2.fromOffset(276, 12)
	resources.Size = UDim2.fromOffset(468, 30)
	resources.Parent = root
	local resourceLayout = Instance.new("UIListLayout")
	resourceLayout.FillDirection = Enum.FillDirection.Horizontal
	resourceLayout.Padding = UDim.new(0, Tokens.Spacing.SM)
	resourceLayout.Parent = resources

	local preview = textLabel("Preview", Tokens.TextSize.Caption, "textPrimary")
	preview.Position = UDim2.fromOffset(276, 48)
	preview.Size = UDim2.fromOffset(468, 42)
	preview.TextWrapped = true
	preview.Parent = root

	local feedback = textLabel("Feedback", Tokens.TextSize.Caption, "success")
	feedback.Position = UDim2.fromOffset(16, 112)
	feedback.Size = UDim2.fromOffset(560, 24)
	feedback.Parent = root

	local reaction = textLabel("Reaction", Tokens.TextSize.Caption, "warning")
	reaction.Position = UDim2.fromOffset(276, 92)
	reaction.Size = UDim2.fromOffset(280, 22)
	reaction.Parent = root

	local endTurn = Instance.new("TextButton")
	endTurn.Name = "EndTurn"
	endTurn.AnchorPoint = Vector2.new(1, 1)
	endTurn.Position = UDim2.new(1, -16, 1, -14)
	endTurn.Size = UDim2.fromOffset(148, 40)
	endTurn.BorderSizePixel = 0
	endTurn.AutoButtonColor = false
	endTurn.Font = Enum.Font.GothamBold
	endTurn.Text = "턴 종료"
	endTurn.TextSize = Tokens.TextSize.Body
	endTurn.Selectable = true
	endTurn:SetAttribute("RVTTBackgroundToken", "accent")
	endTurn:SetAttribute("RVTTTextToken", "accentOn")
	endTurn.Parent = root
	local endCorner = Instance.new("UICorner")
	endCorner.CornerRadius = Tokens.Radius.SM
	endCorner.Parent = endTurn
	endTurn.Activated:Connect(onEndTurn)

	local initiative = panel("InitiativeRibbon")
	initiative.AnchorPoint = Vector2.new(0.5, 0)
	initiative.Position = UDim2.new(0.5, 0, 0, 62)
	initiative.Size = UDim2.fromOffset(680, 48)
	initiative.Parent = parent
	local initiativeLayout = Instance.new("UIListLayout")
	initiativeLayout.FillDirection = Enum.FillDirection.Horizontal
	initiativeLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	initiativeLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	initiativeLayout.Padding = UDim.new(0, Tokens.Spacing.SM)
	initiativeLayout.Parent = initiative

	local toast = panel("TurnNotification")
	toast.AnchorPoint = Vector2.new(0.5, 0)
	toast.Position = UDim2.new(0.5, 0, 0, 118)
	toast.Size = UDim2.fromOffset(360, 46)
	toast.Visible = false
	toast.Parent = toastParent
	local toastText = textLabel("Text", Tokens.TextSize.Body, "textPrimary")
	toastText.Size = UDim2.fromScale(1, 1)
	toastText.TextXAlignment = Enum.TextXAlignment.Center
	toastText.Parent = toast

	return setmetatable({
		Root = root,
		Initiative = initiative,
		Toast = toast,
		ToastText = toastText,
		ActorLabel = actorLabel,
		HpLabel = hpLabel,
		ModeLabel = modeLabel,
		Resources = resources,
		Preview = preview,
		Feedback = feedback,
		Reaction = reaction,
		EndTurn = endTurn,
		lastActiveActorId = nil,
		toastGeneration = 0,
	}, Hud)
end

function Hud:_renderResources(items: { any })
	clearLabels(self.Resources)
	for index, resource in items do
		local value = textLabel(
			"Resource_" .. resource.id,
			Tokens.TextSize.Caption,
			if resource.available then "textPrimary" else "disabled"
		)
		value.LayoutOrder = index
		value.Size = UDim2.fromOffset(if resource.id == "bonus_action" then 92 else 72, 28)
		value.Text = resource.label
			.. if type(resource.value) == "number"
				then string.format(" %.1f", resource.value)
				else ""
		value.Parent = self.Resources
	end
end

function Hud:_renderTimeline(items: { any }, round: number?)
	clearLabels(self.Initiative)
	if type(round) == "number" then
		local roundLabel = textLabel("Round", Tokens.TextSize.Caption, "textSecondary")
		roundLabel.Size = UDim2.fromOffset(70, 32)
		roundLabel.Text = "R" .. tostring(round)
		roundLabel.Parent = self.Initiative
	end
	for index, entry in items do
		local value = textLabel(
			"Initiative_" .. entry.actorId,
			Tokens.TextSize.Caption,
			if entry.active then "accent" else "textPrimary"
		)
		value.LayoutOrder = index
		value.Size = UDim2.fromOffset(112, 32)
		value.TextXAlignment = Enum.TextXAlignment.Center
		value.Text = entry.label
			.. if type(entry.initiative) == "number"
				then " · " .. tostring(entry.initiative)
				else ""
		value.Parent = self.Initiative
	end
end

function Hud:_notifyTurn(actorId: string?, actorLabel: string)
	if actorId == nil or actorId == self.lastActiveActorId then
		self.lastActiveActorId = actorId
		return
	end
	self.lastActiveActorId = actorId
	self.toastGeneration += 1
	local generation = self.toastGeneration
	self.ToastText.Text = actorLabel .. " 턴"
	self.Toast.Visible = true
	task.delay(2.5, function()
		if self.toastGeneration == generation then
			self.Toast.Visible = false
		end
	end)
end

function Hud:render(state: any)
	self.Root.Visible = state.visible
	self.Initiative.Visible = state.visible and state.mode == "encounter"
	if not state.visible then
		self.Toast.Visible = false
		return
	end
	self.ActorLabel.Text = "조작 Actor · " .. state.selectedActorLabel
	self.HpLabel.Visible = type(state.hitPoints) == "number"
		and type(state.maximumHitPoints) == "number"
	self.HpLabel.Text = if self.HpLabel.Visible
		then string.format("HP %d / %d", state.hitPoints, state.maximumHitPoints)
		else ""
	self.ModeLabel.Text = if state.mode == "encounter"
		then "Encounter · 현재 " .. state.activeActorLabel
		else "Exploration"
	self.Preview.Text = previewText(state.preview)
	self.Preview:SetAttribute(
		"RVTTTextToken",
		if type(state.preview) == "table" and not state.preview.enabled
			then "warning"
			else "textPrimary"
	)
	self.Feedback.Text = feedbackText(state.feedback)
	self.Feedback:SetAttribute("RVTTTextToken", feedbackToken(state.feedback.state))
	self.Reaction.Visible = state.reactionVisible
	self.Reaction.Text = if state.reactionAvailable
		then "반응 사용 가능"
		else "반응 사용됨"
	self.Reaction:SetAttribute(
		"RVTTTextToken",
		if state.reactionAvailable then "warning" else "disabled"
	)
	self.EndTurn.Visible = state.canEndTurn
	self.EndTurn.Active = state.feedback.state ~= "pending"
	self.EndTurn.AutoButtonColor = self.EndTurn.Active
	self.EndTurn:SetAttribute(
		"RVTTBackgroundToken",
		if self.EndTurn.Active then "accent" else "disabled"
	)
	if not self.EndTurn.Visible and GuiService.SelectedObject == self.EndTurn then
		GuiService.SelectedObject = nil
	end
	self:_renderResources(state.resources)
	self:_renderTimeline(state.timeline, state.round)
	if state.mode == "encounter" then
		self:_notifyTurn(state.activeActorId, state.activeActorLabel)
	else
		self.lastActiveActorId = nil
	end
end

function Hud:destroy()
	self.Root:Destroy()
	self.Initiative:Destroy()
	self.Toast:Destroy()
end

return Hud
