--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Tokens = require(ReplicatedStorage.RVTT.Shared.UI.DesignTokens)
local ViewState = require(ReplicatedStorage.RVTT.Shared.UI.ViewState)

local Panel = {}
Panel.__index = Panel

local function decorate(value: GuiObject, token: string)
	value.BorderSizePixel = 0
	value:SetAttribute("RVTTBackgroundToken", token)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = Tokens.Radius.MD
	corner.Parent = value
end

local function textLabel(parent: Instance, name: string, position: UDim2, size: UDim2): TextLabel
	local value = Instance.new("TextLabel")
	value.Name = name
	value.Position = position
	value.Size = size
	value.BackgroundTransparency = 1
	value.Font = Enum.Font.GothamMedium
	value.TextSize = Tokens.TextSize.Body
	value.TextWrapped = true
	value.TextXAlignment = Enum.TextXAlignment.Left
	value.TextYAlignment = Enum.TextYAlignment.Top
	value:SetAttribute("RVTTTextToken", "textPrimary")
	value.Parent = parent
	return value
end

local function actionButton(parent: Instance, name: string, text: string, x: number): TextButton
	local value = Instance.new("TextButton")
	value.Name = name
	value.Position = UDim2.fromOffset(x, 208)
	value.Size = UDim2.fromOffset(144, 40)
	value.AutoButtonColor = false
	value.Selectable = true
	value.Font = Enum.Font.GothamBold
	value.Text = text
	value.TextSize = Tokens.TextSize.Caption
	value:SetAttribute("RVTTBackgroundToken", "accent")
	value:SetAttribute("RVTTTextToken", "accentOn")
	value.Parent = parent
	decorate(value, "accent")
	return value
end

function Panel.new(onReady: () -> (), onRetry: () -> ()): any
	local entry = Instance.new("Frame")
	entry.Name = "EntryRolePanel"
	entry.AnchorPoint = Vector2.new(0.5, 0.5)
	entry.Position = UDim2.fromScale(0.5, 0.5)
	entry.Size = UDim2.fromOffset(520, 288)
	decorate(entry, "surface")

	local title = textLabel(entry, "Title", UDim2.fromOffset(24, 22), UDim2.new(1, -48, 0, 36))
	title.Font = Enum.Font.GothamBold
	title.TextSize = Tokens.TextSize.Heading
	title.Text = "세션 참가"
	local role = textLabel(entry, "Role", UDim2.fromOffset(24, 72), UDim2.new(1, -48, 0, 30))
	local body = textLabel(entry, "Body", UDim2.fromOffset(24, 112), UDim2.new(1, -48, 0, 76))
	body:SetAttribute("RVTTTextToken", "textSecondary")
	local ready = actionButton(entry, "ReadyButton", "준비", 24)
	ready.Activated:Connect(onReady)

	local recovery = Instance.new("Frame")
	recovery.Name = "RecoveryBoundary"
	recovery.Size = UDim2.fromScale(1, 1)
	recovery.BackgroundTransparency = 0.18
	recovery.Visible = false
	recovery:SetAttribute("RVTTBackgroundToken", "scrim")
	local card = Instance.new("Frame")
	card.Name = "RecoveryCard"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.Size = UDim2.fromOffset(460, 220)
	card.Parent = recovery
	decorate(card, "surfaceRaised")
	local recoveryTitle =
		textLabel(card, "Title", UDim2.fromOffset(24, 22), UDim2.new(1, -48, 0, 36))
	recoveryTitle.Font = Enum.Font.GothamBold
	recoveryTitle.TextSize = Tokens.TextSize.Heading
	local recoveryBody = textLabel(card, "Body", UDim2.fromOffset(24, 72), UDim2.new(1, -48, 0, 64))
	recoveryBody:SetAttribute("RVTTTextToken", "textSecondary")
	local retry = actionButton(card, "RetryButton", "다시 동기화", 24)
	retry.Position = UDim2.fromOffset(24, 156)
	retry.Activated:Connect(onRetry)

	return setmetatable({
		EntryRoot = entry,
		RecoveryRoot = recovery,
		Role = role,
		Body = body,
		Ready = ready,
		RecoveryTitle = recoveryTitle,
		RecoveryBody = recoveryBody,
		Retry = retry,
	}, Panel)
end

function Panel.render(self: any, view: any)
	self.Role.Text = string.format("역할 · %s    세션 · %s", view.role, view.phase)
	if view.role == "observer" then
		self.Body.Text =
			"Observer로 연결되었습니다. DM의 캐릭터 할당을 기다리는 동안 권위 행동은 잠깁니다."
	elseif view.role == "player" and view.ready then
		self.Body.Text =
			"서버가 준비 상태를 확인했습니다. 세션 시작을 기다리고 있습니다."
	elseif view.role == "player" then
		self.Body.Text =
			"캐릭터 할당이 확인되었습니다. 준비를 서버에 제출할 수 있습니다."
	else
		self.Body.Text = "DM 권한이 서버 Projection에서 확인되었습니다."
	end
	self.Ready.Visible = view.role == "player" and view.phase == "lobby"
	self.Ready.Active = view.canReady == true and view.ready ~= true
	self.Ready.Selectable = self.Ready.Active
	self.Ready.Text = if view.ready
		then "준비 완료"
		elseif view.state == ViewState.PENDING then "확인 중"
		else "준비"
	self.Ready:SetAttribute(
		"RVTTBackgroundToken",
		if self.Ready.Active then "accent" else "disabled"
	)

	local blocking = view.state == ViewState.LOADING
		or view.state == ViewState.REBUILDING
		or view.state == ViewState.RECOVERY
		or view.state == ViewState.NETWORK_ERROR
		or view.state == ViewState.STALE
		or view.state == ViewState.PERMISSION_DENIED
		or view.state == ViewState.VALIDATION_ERROR
		or view.state == ViewState.CONFLICT
		or view.state == ViewState.FATAL
	self.RecoveryRoot.Visible = blocking
	if blocking then
		self.RecoveryTitle.Text = if view.state == ViewState.FATAL
			then "복구할 수 없는 오류"
			else "세션 복구"
		self.RecoveryBody.Text = view.message
			or "최신 권위 Projection을 불러오고 있습니다."
		self.Retry.Visible = view.retryable == true
		self.Retry.Active = view.retryable == true
		self.Retry.Selectable = view.retryable == true
	end
end

return Panel
