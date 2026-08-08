--!strict

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local SharedUI = ReplicatedStorage.RVTT.Shared.UI
local Tokens = require(SharedUI.DesignTokens)
local ViewModel = require(SharedUI.DmWorkspaceViewModel)

local DmWorkspacePanel = {}
DmWorkspacePanel.__index = DmWorkspacePanel

local function label(parent: Instance, text: string, size: UDim2, position: UDim2?): TextLabel
	local value = Instance.new("TextLabel")
	value.Size = size
	value.Position = position or UDim2.fromOffset(0, 0)
	value.BackgroundTransparency = 1
	value.Text = text
	value.TextXAlignment = Enum.TextXAlignment.Left
	value.TextYAlignment = Enum.TextYAlignment.Top
	value.TextWrapped = true
	value.TextSize = Tokens.TextSize.Caption
	value:SetAttribute("RVTTTextToken", "textPrimary")
	value.Parent = parent
	return value
end

local function button(parent: Instance, text: string, size: UDim2): TextButton
	local value = Instance.new("TextButton")
	value.Size = size
	value.AutoButtonColor = false
	value.Text = text
	value.TextSize = Tokens.TextSize.Caption
	value.BorderSizePixel = 0
	value:SetAttribute("RVTTBackgroundToken", "surfaceRaised")
	value:SetAttribute("RVTTTextToken", "textPrimary")
	value.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = Tokens.Radius.SM
	corner.Parent = value
	return value
end

local function textBox(parent: Instance, placeholder: string, value: string): TextBox
	local input = Instance.new("TextBox")
	input.Size = UDim2.new(1, -16, 0, 30)
	input.BackgroundTransparency = 0
	input.BorderSizePixel = 0
	input.ClearTextOnFocus = false
	input.PlaceholderText = placeholder
	input.Text = value
	input.TextSize = Tokens.TextSize.Caption
	input.TextXAlignment = Enum.TextXAlignment.Left
	input:SetAttribute("RVTTBackgroundToken", "surfaceSoft")
	input:SetAttribute("RVTTTextToken", "textPrimary")
	input.Parent = parent
	return input
end

function DmWorkspacePanel.registerDefaults(registry: any)
	registry:register({
		moduleId = "inspector",
		title = "Inspector",
		instancePolicy = "multiple",
		commandBindings = {},
		defaultWindowPlacement = {
			position = { x = 16, y = 72 },
			size = { x = 280, y = 360 },
			dock = "left",
		},
		minimumSize = { x = 240, y = 180 },
		maximumSize = { x = 620, y = 760 },
	})
	registry:register({
		moduleId = "player_view",
		title = "Player View Preview",
		instancePolicy = "singleton",
		commandBindings = {},
		defaultWindowPlacement = { position = { x = 320, y = 72 }, size = { x = 360, y = 300 } },
		minimumSize = { x = 300, y = 220 },
		maximumSize = { x = 760, y = 720 },
	})
	registry:register({
		moduleId = "override",
		title = "Override & Control",
		instancePolicy = "singleton",
		commandBindings = {
			ViewModel.Commands.ASSIGN_CONTROL,
			ViewModel.Commands.RUNTIME_PATCH,
			ViewModel.Commands.REQUEST_RECOVERY,
		},
		defaultWindowPlacement = { position = { x = 704, y = 72 }, size = { x = 340, y = 390 } },
		minimumSize = { x = 300, y = 300 },
		maximumSize = { x = 720, y = 760 },
	})
	registry:register({
		moduleId = "queue",
		title = "DM Queue",
		instancePolicy = "singleton",
		commandBindings = {},
		defaultWindowPlacement = {
			position = { x = 320, y = 396 },
			size = { x = 360, y = 260 },
			dock = "bottom",
		},
		minimumSize = { x = 300, y = 180 },
		maximumSize = { x = 900, y = 600 },
	})
	registry:register({
		moduleId = "quick_action",
		title = "Quick Action",
		instancePolicy = "context_popover",
		commandBindings = { ViewModel.Commands.QUICK_ACTION },
	})
end

function DmWorkspacePanel.new(
	parent: Instance,
	registry: any,
	host: any,
	previewClient: any,
	preferences: any,
	submit: any
): any
	local self: any = setmetatable({
		registry = registry,
		host = host,
		previewClient = previewClient,
		preferences = preferences,
		submitCommand = submit,
		state = { visible = false, queue = {}, viewers = {} },
		pending = {},
		previewState = nil,
		quickActionVisible = false,
		quickActionId = "",
		windowConnections = {},
		defaultOpened = false,
	}, DmWorkspacePanel)

	local root = Instance.new("Frame")
	root.Name = "DmWorkspace"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.Visible = false
	root.Parent = parent
	self.Root = root

	local strip = Instance.new("Frame")
	strip.Name = "TopAuthoringStrip"
	strip.Size = UDim2.new(1, -32, 0, 48)
	strip.Position = UDim2.fromOffset(16, 12)
	strip.BorderSizePixel = 0
	strip:SetAttribute("RVTTBackgroundToken", "surfaceRaised")
	strip.Parent = root
	self.Strip = strip
	local stripLayout = Instance.new("UIListLayout")
	stripLayout.FillDirection = Enum.FillDirection.Horizontal
	stripLayout.Padding = UDim.new(0, 6)
	stripLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	stripLayout.Parent = strip
	local stripPadding = Instance.new("UIPadding")
	stripPadding.PaddingLeft = UDim.new(0, 8)
	stripPadding.PaddingRight = UDim.new(0, 8)
	stripPadding.Parent = strip

	for _, definition in registry:list() do
		local launcher = button(strip, definition.title, UDim2.fromOffset(132, 32))
		launcher.Name = "Launch_" .. definition.moduleId
		launcher.Activated:Connect(function()
			if definition.instancePolicy == "context_popover" then
				self.quickActionVisible = not self.quickActionVisible
				self:_renderQuickAction()
			else
				host:open(
					definition.moduleId,
					if definition.instancePolicy == "multiple" then "selection" else nil
				)
			end
		end)
	end

	local canvas = Instance.new("Frame")
	canvas.Name = "WindowCanvas"
	canvas.Size = UDim2.new(1, 0, 1, -64)
	canvas.Position = UDim2.fromOffset(0, 64)
	canvas.BackgroundTransparency = 1
	canvas.ClipsDescendants = true
	canvas.Parent = root
	self.Canvas = canvas

	local popover = Instance.new("Frame")
	popover.Name = "QuickActionPopover"
	popover.Size = UDim2.fromOffset(280, 112)
	popover.Position = UDim2.new(1, -304, 0, 62)
	popover.BorderSizePixel = 0
	popover.Visible = false
	popover:SetAttribute("RVTTBackgroundToken", "surfaceRaised")
	popover.Parent = root
	self.QuickActionPopover = popover
	label(
		popover,
		"Quick Action · 문맥 명령",
		UDim2.new(1, -16, 0, 24),
		UDim2.fromOffset(8, 8)
	)
	local quickInput = textBox(popover, "stable actionId", "")
	quickInput.Position = UDim2.fromOffset(8, 36)
	quickInput:GetPropertyChangedSignal("Text"):Connect(function()
		self.quickActionId = quickInput.Text
	end)
	local execute = button(popover, "실행", UDim2.fromOffset(72, 28))
	execute.Position = UDim2.new(1, -80, 1, -34)
	execute.Activated:Connect(function()
		self:_submit(
			ViewModel.Commands.QUICK_ACTION,
			{ actionId = self.quickActionId, payload = {} },
			self.quickActionId
		)
		self.quickActionVisible = false
		self:_renderQuickAction()
	end)

	host.Changed:Connect(function()
		if not self.suppressLayoutSave then
			self.preferences:set("dmWorkspaceLayout", self.host:serializeLayout())
		end
		self:_renderWindows()
	end)
	return self
end

function DmWorkspacePanel:_renderQuickAction()
	self.QuickActionPopover.Visible = self.Root.Visible and self.quickActionVisible
end

function DmWorkspacePanel:_submit(commandType: string, payload: any, target: any)
	local intent, errorCode = ViewModel.intent(commandType, payload)
	if intent == nil then
		self.previewState = { error = errorCode }
		self:_renderWindows()
		return
	end
	local commandId = self.submitCommand(intent.commandType, intent.payload)
	self.pending[commandId] = {
		commandType = commandType,
		kind = commandType,
		target = target,
		createdAt = os.time(),
		baseRevision = self.state.revision or -1,
		accepted = false,
	}
	self:_renderWindows()
end

function DmWorkspacePanel:onReceipt(message: any)
	if type(message) ~= "table" or message.phase ~= "terminal" then
		return
	end
	local record = self.pending[message.commandId]
	if record == nil then
		return
	end
	if type(message.result) == "table" and message.result.ok == true then
		record.accepted = true
	else
		self.pending[message.commandId] = nil
	end
	self:_renderWindows()
end

function DmWorkspacePanel:_disconnectWindowConnections()
	for _, connection in self.windowConnections do
		connection:Disconnect()
	end
	self.windowConnections = {}
end

function DmWorkspacePanel:_windowPosition(window: any): UDim2
	if window.dock == "right" then
		return UDim2.new(1, -window.size.x - 16, 0, window.position.y)
	elseif window.dock == "bottom" then
		return UDim2.new(0, window.position.x, 1, -window.size.y - 16)
	elseif window.dock == "left" then
		return UDim2.fromOffset(16, window.position.y)
	end
	return UDim2.fromOffset(window.position.x, window.position.y)
end

function DmWorkspacePanel:_bindDrag(frame: Frame, title: GuiObject, window: any)
	local dragging = false
	local startMouse = Vector2.zero
	local startPosition = Vector2.zero
	table.insert(
		self.windowConnections,
		title.InputBegan:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 and window.dock == nil then
				dragging = true
				startMouse = Vector2.new(input.Position.X, input.Position.Y)
				startPosition = Vector2.new(frame.Position.X.Offset, frame.Position.Y.Offset)
			end
		end)
	)
	table.insert(
		self.windowConnections,
		UserInputService.InputChanged:Connect(function(input: InputObject)
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				local current = Vector2.new(input.Position.X, input.Position.Y)
				local delta = current - startMouse
				frame.Position =
					UDim2.fromOffset(startPosition.X + delta.X, startPosition.Y + delta.Y)
			end
		end)
	)
	table.insert(
		self.windowConnections,
		UserInputService.InputEnded:Connect(function(input: InputObject)
			if dragging and input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
				self.host:move(window.instanceId, frame.Position.X.Offset, frame.Position.Y.Offset)
				self.host:focus(window.instanceId)
			end
		end)
	)
end

function DmWorkspacePanel:_bindResize(frame: Frame, handle: GuiObject, window: any)
	local resizing = false
	local startMouse = Vector2.zero
	local startSize = Vector2.zero
	table.insert(
		self.windowConnections,
		handle.InputBegan:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				resizing = true
				startMouse = Vector2.new(input.Position.X, input.Position.Y)
				startSize = Vector2.new(frame.Size.X.Offset, frame.Size.Y.Offset)
			end
		end)
	)
	table.insert(
		self.windowConnections,
		UserInputService.InputChanged:Connect(function(input: InputObject)
			if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
				local current = Vector2.new(input.Position.X, input.Position.Y)
				local delta = current - startMouse
				frame.Size = UDim2.fromOffset(
					math.clamp(startSize.X + delta.X, window.minimumSize.x, window.maximumSize.x),
					math.clamp(startSize.Y + delta.Y, window.minimumSize.y, window.maximumSize.y)
				)
			end
		end)
	)
	table.insert(
		self.windowConnections,
		UserInputService.InputEnded:Connect(function(input: InputObject)
			if resizing and input.UserInputType == Enum.UserInputType.MouseButton1 then
				resizing = false
				self.host:resize(window.instanceId, frame.Size.X.Offset, frame.Size.Y.Offset)
				self.host:focus(window.instanceId)
			end
		end)
	)
end

function DmWorkspacePanel:_renderInspector(body: Frame, window: any)
	label(
		body,
		"선택 문맥: " .. tostring(window.contextKey or "없음"),
		UDim2.new(1, -16, 0, 28),
		UDim2.fromOffset(8, 8)
	)
	label(
		body,
		"이 창의 배치와 크기는 로컬 레이아웃이며 Domain 상태를 변경하지 않습니다.",
		UDim2.new(1, -16, 0, 60),
		UDim2.fromOffset(8, 40)
	)
end

function DmWorkspacePanel:_renderPreview(body: Frame)
	label(
		body,
		"서버 Viewer Policy로 현재 시점을 생성합니다.",
		UDim2.new(1, -16, 0, 36),
		UDim2.fromOffset(8, 8)
	)
	local y = 44
	for _, viewer in self.state.viewers or {} do
		local selectViewer = button(
			body,
			string.format("%d · %s", viewer.userId, viewer.role),
			UDim2.new(1, -16, 0, 28)
		)
		selectViewer.Position = UDim2.fromOffset(8, y)
		selectViewer.Activated:Connect(function()
			self.previewState = { loading = true, targetUserId = viewer.userId }
			self.previewClient:request(viewer.userId, function(result)
				self.previewState = result
				self:_renderWindows()
			end)
			self:_renderWindows()
		end)
		y += 32
	end
	local summary = "대상을 선택하세요"
	if type(self.previewState) == "table" then
		if self.previewState.loading then
			summary = "서버 Projection 요청 중"
		elseif self.previewState.ok == true and self.previewState.stale ~= true then
			local value = self.previewState.value
			local target = if type(value) == "table" then value.target else nil
			local domains = if type(value) == "table" and type(value.payload) == "table"
				then value.payload.domains
				else nil
			local hidden = type(domains) == "table"
				and type(domains.dm_workspace) == "table"
				and next(domains.dm_workspace) == nil
			summary = string.format(
				"preview revision %s · %s · DM data hidden=%s",
				tostring(value.revision),
				tostring(if type(target) == "table" then target.role else nil),
				tostring(hidden)
			)
		elseif self.previewState.ok == true then
			summary =
				"대상 또는 권위 Revision이 바뀌어 미리보기가 오래되었습니다"
		else
			local errorValue = self.previewState.error
			summary = "미리보기 실패 · "
				.. tostring(if type(errorValue) == "table" then errorValue.code else errorValue)
		end
	end
	label(body, summary, UDim2.new(1, -16, 0, 64), UDim2.fromOffset(8, y + 4))
	if
		type(self.previewState) == "table"
		and self.previewState.ok == true
		and self.previewState.stale ~= true
	then
		local value = self.previewState.value
		local domains = if type(value) == "table" and type(value.payload) == "table"
			then value.payload.domains
			else nil
		local scene = if type(domains) == "table" then domains.scene else nil
		local actorIds = {}
		for actorId in
			if type(scene) == "table" and type(scene.actors) == "table" then scene.actors else {}
		do
			table.insert(actorIds, actorId)
		end
		table.sort(actorIds)
		label(
			body,
			"노출 Actor: " .. (if #actorIds > 0 then table.concat(actorIds, ", ") else "없음"),
			UDim2.new(1, -16, 0, 64),
			UDim2.fromOffset(8, y + 68)
		)
	end
end

function DmWorkspacePanel:_renderOverride(body: Frame, window: any)
	window.localViewState.actorId = window.localViewState.actorId or ""
	window.localViewState.controllerUserId = window.localViewState.controllerUserId or ""
	window.localViewState.patchTargetId = window.localViewState.patchTargetId or ""
	window.localViewState.patchJson = window.localViewState.patchJson or "{}"
	window.localViewState.recoveryTarget = window.localViewState.recoveryTarget or ""
	local y = 8
	local actor = textBox(body, "actorId", window.localViewState.actorId)
	actor.Position = UDim2.fromOffset(8, y)
	actor.FocusLost:Connect(function()
		window.localViewState.actorId = actor.Text
	end)
	y += 34
	local controller = textBox(body, "controller userId", window.localViewState.controllerUserId)
	controller.Position = UDim2.fromOffset(8, y)
	controller.FocusLost:Connect(function()
		window.localViewState.controllerUserId = controller.Text
	end)
	y += 34
	local assign = button(body, "Control 배정", UDim2.fromOffset(112, 28))
	assign.Position = UDim2.fromOffset(8, y)
	assign.Activated:Connect(function()
		self:_submit(
			ViewModel.Commands.ASSIGN_CONTROL,
			{ actorId = actor.Text, controllerUserId = tonumber(controller.Text) },
			actor.Text
		)
	end)
	y += 40
	local patchTarget = textBox(body, "runtime patch targetId", window.localViewState.patchTargetId)
	patchTarget.Position = UDim2.fromOffset(8, y)
	patchTarget.FocusLost:Connect(function()
		window.localViewState.patchTargetId = patchTarget.Text
	end)
	y += 34
	local patchJson = textBox(body, "patch JSON", window.localViewState.patchJson)
	patchJson.Position = UDim2.fromOffset(8, y)
	patchJson.FocusLost:Connect(function()
		window.localViewState.patchJson = patchJson.Text
	end)
	y += 34
	local patch = button(body, "Runtime Patch", UDim2.fromOffset(112, 28))
	patch.Position = UDim2.fromOffset(8, y)
	patch.Activated:Connect(function()
		local ok, decoded = pcall(function()
			return HttpService:JSONDecode(patchJson.Text)
		end)
		self:_submit(ViewModel.Commands.RUNTIME_PATCH, {
			targetId = patchTarget.Text,
			patch = if ok and type(decoded) == "table" then decoded else nil,
		}, patchTarget.Text)
	end)
	y += 40
	local recovery = textBox(body, "recovery target", window.localViewState.recoveryTarget)
	recovery.Position = UDim2.fromOffset(8, y)
	recovery.FocusLost:Connect(function()
		window.localViewState.recoveryTarget = recovery.Text
	end)
	y += 34
	local request = button(body, "Recovery 요청", UDim2.fromOffset(112, 28))
	request.Position = UDim2.fromOffset(8, y)
	request.Activated:Connect(function()
		self:_submit(ViewModel.Commands.REQUEST_RECOVERY, { target = recovery.Text }, recovery.Text)
	end)
end

function DmWorkspacePanel:_renderQueue(body: Frame)
	local state = ViewModel.build(
		self._lastPayload or {},
		self._userId or 0,
		self.state.revision or -1,
		self.pending
	)
	local y = 8
	for index, row in state.queue or {} do
		if index > 8 then
			break
		end
		label(
			body,
			string.format("%s · %s · r%s", row.status, row.kind, tostring(row.revision)),
			UDim2.new(1, -16, 0, 24),
			UDim2.fromOffset(8, y)
		)
		y += 26
	end
	if y == 8 then
		label(
			body,
			"대기 중인 DM 명령이 없습니다.",
			UDim2.new(1, -16, 0, 28),
			UDim2.fromOffset(8, y)
		)
	end
end

function DmWorkspacePanel:_renderWindows()
	self:_disconnectWindowConnections()
	for _, child in self.Canvas:GetChildren() do
		child:Destroy()
	end
	for zIndex, instanceId in self.host.zOrder do
		local window = self.host.windowsByInstanceId[instanceId]
		if window == nil then
			continue
		end
		local frame = Instance.new("Frame")
		frame.Name = "Window_" .. instanceId
		frame.Size = UDim2.fromOffset(window.size.x, if window.minimized then 36 else window.size.y)
		frame.Position = self:_windowPosition(window)
		frame.BorderSizePixel = 0
		frame.ZIndex = 100 + zIndex * 5
		frame:SetAttribute("RVTTBackgroundToken", "surface")
		frame.Parent = self.Canvas
		local title =
			button(frame, self.registry:get(window.moduleId).title, UDim2.new(1, -104, 0, 32))
		title.Position = UDim2.fromOffset(4, 2)
		title.ZIndex = frame.ZIndex + 1
		local minimize =
			button(frame, if window.minimized then "+" else "–", UDim2.fromOffset(28, 28))
		minimize.Position = UDim2.new(1, -96, 0, 4)
		minimize.ZIndex = frame.ZIndex + 1
		minimize.Activated:Connect(function()
			if window.minimized then
				self.host:restore(instanceId)
			else
				self.host:minimize(instanceId)
			end
		end)
		local dock =
			button(frame, if window.dock == nil then "D" else "U", UDim2.fromOffset(28, 28))
		dock.Position = UDim2.new(1, -64, 0, 4)
		dock.ZIndex = frame.ZIndex + 1
		dock.Activated:Connect(function()
			if window.dock == nil then
				self.host:dock(instanceId, "left")
			else
				self.host:undock(instanceId)
			end
		end)
		local close = button(frame, "×", UDim2.fromOffset(28, 28))
		close.Position = UDim2.new(1, -32, 0, 4)
		close.ZIndex = frame.ZIndex + 1
		close.Activated:Connect(function()
			self.host:close(instanceId)
		end)
		self:_bindDrag(frame, title, window)
		if not window.minimized then
			local resizeHandle = button(frame, "↘", UDim2.fromOffset(24, 24))
			resizeHandle.Name = "ResizeHandle"
			resizeHandle.Position = UDim2.new(1, -26, 1, -26)
			resizeHandle.ZIndex = frame.ZIndex + 3
			self:_bindResize(frame, resizeHandle, window)
			local body = Instance.new("Frame")
			body.Name = "Body"
			body.Size = UDim2.new(1, -8, 1, -40)
			body.Position = UDim2.fromOffset(4, 36)
			body.BackgroundTransparency = 1
			body.ZIndex = frame.ZIndex + 1
			body.Parent = frame
			if window.moduleId == "inspector" then
				self:_renderInspector(body, window)
			elseif window.moduleId == "player_view" then
				self:_renderPreview(body)
			elseif window.moduleId == "override" then
				self:_renderOverride(body, window)
			elseif window.moduleId == "queue" then
				self:_renderQueue(body)
			end
		end
	end
end

function DmWorkspacePanel:render(payload: any, userId: number, revision: number)
	self._lastPayload = payload
	self._userId = userId
	self.state = ViewModel.build(payload, userId, revision, self.pending)
	self.Root.Visible = self.state.visible == true
	if not self.Root.Visible then
		self.previewClient:invalidate()
		self.previewState = nil
		self.pending = {}
		self.quickActionVisible = false
		self.defaultOpened = false
		self.suppressLayoutSave = true
		self.host:purgeSensitive()
		self.suppressLayoutSave = false
		return
	end
	if not self.defaultOpened then
		self.defaultOpened = true
		local layout = self.preferences:get("dmWorkspaceLayout")
		if
			type(layout) ~= "table"
			or type(layout.zOrder) ~= "table"
			or #layout.zOrder == 0
			or not self.host:restoreLayout(layout)
		then
			self.host:open("inspector", "selection")
			self.host:open("player_view")
			self.host:open("queue")
		end
	end
	for commandId, _ in self.pending do
		for _, row in self.state.queue do
			if row.commandId == commandId and row.status == "projection_confirmed" then
				self.pending[commandId] = nil
			end
		end
	end
	self:_renderQuickAction()
	self:_renderWindows()
end

function DmWorkspacePanel:cancelTopContext(): boolean
	if self.quickActionVisible then
		self.quickActionVisible = false
		self:_renderQuickAction()
		return true
	end
	local focused = self.host.focusedInstanceId
	return type(focused) == "string" and self.host:close(focused)
end

return DmWorkspacePanel
