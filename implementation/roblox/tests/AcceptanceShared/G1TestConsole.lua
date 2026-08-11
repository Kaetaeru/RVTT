--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

type BatchRegistration = {
	summary: any,
	status: string,
	operation: string,
	failed: boolean,
}

type ActionRegistration = {
	button: TextButton,
	handlers: { () -> () },
}

local Console = {}
Console.__index = Console

local singleton: any = nil
local PANEL_SIZE = Vector2.new(590, 650)
local MARGIN = 8

local FLOW = {
	{
		label = "0 Projection / Runtime Ready",
		detail = "Wait for the normal Projection, Hero token, and exploration target setup.",
		required = {
			"slice01-world-interaction/boot",
			"slice01-world-interaction/dm-role",
			"slice01-world-interaction/character",
			"slice01-world-interaction/scene",
			"slice01-world-interaction/token-projection",
			"slice01-world-interaction/avatar-suppression",
			"contextual-pointer-actions/setup-object",
		},
	},
	{
		label = "1 Arm Token Pick → left-click Hero",
		detail = "Press Arm Token Pick, then use one real left-click on the Hero token.",
		required = {
			"slice01-world-interaction/token-pick",
			"slice01-world-interaction/selection-highlight",
		},
	},
	{
		label = "2 Camera: WASD Pan / Middle drag Orbit / Wheel Zoom / Frame",
		detail = "Exercise every camera input; Token Frame is available below.",
		required = {
			"slice01-world-interaction/camera-wasd-pan",
			"slice01-world-interaction/camera-frame",
			"slice01-world-interaction/camera-orbit",
			"slice01-world-interaction/camera-zoom",
			"contextual-pointer-actions/camera-orbit",
		},
	},
	{
		label = "3 Surface: right-click → ESC no-op → Q close → left-click default move",
		detail = "The pointer menu must stay open for ESC and close only for Q before the move.",
		required = {
			"contextual-pointer-actions/right-click-camera-noop",
			"contextual-pointer-actions/esc-gameplay-noop",
			"contextual-pointer-actions/q-one-context-back",
			"contextual-pointer-actions/move-menu",
			"contextual-pointer-actions/move-default",
			"slice01-world-interaction/destination-marker",
			"slice01-world-interaction/move-command",
			"slice01-world-interaction/command-accepted",
			"slice01-world-interaction/projection-move",
		},
	},
	{
		label = "4 Console: right-click → ESC no-op → Q close → left-click default interaction",
		detail = "Repeat the context flow on the blue Exploration Console.",
		required = {
			"contextual-pointer-actions/interact-menu",
			"contextual-pointer-actions/interact-default",
		},
	},
	{
		label = "5 Final Summary",
		detail = "Review details, then emit both authoritative Output summaries.",
		required = {},
	},
}

local ACTIONS = {
	{ id = "Prepare", label = "Prepare", order = 1 },
	{ id = "ArmTokenPick", label = "Arm Token Pick", order = 2 },
	{ id = "Frame", label = "Token Frame", order = 3 },
	{ id = "Exploration", label = "Exploration", order = 4 },
	{ id = "FinalSummary", label = "Final Summary", order = 5 },
}

local function makeLabel(parent: Instance, name: string, position: UDim2, size: UDim2): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Gotham
	label.TextColor3 = Color3.fromRGB(220, 225, 234)
	label.TextSize = 12
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Parent = parent
	return label
end

local function viewportSize(): Vector2
	local camera = Workspace.CurrentCamera
	return if camera ~= nil then camera.ViewportSize else Vector2.new(1280, 720)
end

local function clampPosition(position: Vector2): Vector2
	local viewport = viewportSize()
	return Vector2.new(
		math.clamp(position.X, MARGIN, math.max(MARGIN, viewport.X - PANEL_SIZE.X - MARGIN)),
		math.clamp(position.Y, MARGIN, math.max(MARGIN, viewport.Y - PANEL_SIZE.Y - MARGIN))
	)
end

local function createGui(): (
	ScreenGui,
	Frame,
	Frame,
	TextLabel,
	TextLabel,
	TextLabel,
	Frame,
	TextLabel
)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local existing = playerGui:FindFirstChild("RVTT_G1_Test_Console")
	if existing ~= nil then
		existing:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "RVTT_G1_Test_Console"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 250
	gui.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.Name = "G1TestConsole"
	panel.Position = UDim2.fromOffset(18, 18)
	panel.Size = UDim2.fromOffset(PANEL_SIZE.X, PANEL_SIZE.Y)
	panel.BackgroundColor3 = Color3.fromRGB(24, 27, 33)
	panel.BackgroundTransparency = 0.03
	panel.BorderSizePixel = 0
	panel.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 9)
	corner.Parent = panel

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(91, 101, 118)
	stroke.Transparency = 0.2
	stroke.Parent = panel

	local header = Instance.new("Frame")
	header.Name = "DragHeader"
	header.Size = UDim2.new(1, 0, 0, 44)
	header.BackgroundColor3 = Color3.fromRGB(36, 42, 52)
	header.BorderSizePixel = 0
	header.Active = true
	header.Parent = panel

	local title = makeLabel(header, "Title", UDim2.fromOffset(16, 10), UDim2.new(1, -32, 0, 26))
	title.Font = Enum.Font.GothamBold
	title.Text = "G1 Test Console  ·  drag this header"
	title.TextSize = 16

	local progress =
		makeLabel(panel, "Progress", UDim2.fromOffset(16, 54), UDim2.new(1, -32, 0, 24))
	progress.Font = Enum.Font.GothamBold

	local current =
		makeLabel(panel, "CurrentAction", UDim2.fromOffset(16, 84), UDim2.new(1, -32, 0, 76))
	current.BackgroundColor3 = Color3.fromRGB(19, 22, 27)
	current.BackgroundTransparency = 0
	current.TextSize = 13

	local operation =
		makeLabel(panel, "Operation", UDim2.fromOffset(16, 166), UDim2.new(1, -32, 0, 42))
	operation.TextColor3 = Color3.fromRGB(169, 178, 193)
	operation.Text = "Acceptance modules are starting."

	local actions = Instance.new("Frame")
	actions.Name = "Actions"
	actions.Position = UDim2.fromOffset(16, 216)
	actions.Size = UDim2.new(1, -32, 0, 78)
	actions.BackgroundTransparency = 1
	actions.Parent = panel

	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromOffset(104, 34)
	layout.CellPadding = UDim2.fromOffset(8, 8)
	layout.FillDirectionMaxCells = 5
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = actions

	local detailsTitle =
		makeLabel(panel, "DetailsTitle", UDim2.fromOffset(16, 302), UDim2.new(1, -32, 0, 22))
	detailsTitle.Font = Enum.Font.GothamBold
	detailsTitle.Text = "Evidence details (secondary)"

	local detailsScroll = Instance.new("ScrollingFrame")
	detailsScroll.Name = "EvidenceDetails"
	detailsScroll.Position = UDim2.fromOffset(16, 328)
	detailsScroll.Size = UDim2.new(1, -32, 0, 304)
	detailsScroll.BackgroundColor3 = Color3.fromRGB(19, 22, 27)
	detailsScroll.BorderSizePixel = 0
	detailsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	detailsScroll.CanvasSize = UDim2.fromOffset(0, 0)
	detailsScroll.ScrollBarThickness = 6
	detailsScroll.Parent = panel

	local details =
		makeLabel(detailsScroll, "Details", UDim2.fromOffset(8, 8), UDim2.new(1, -22, 0, 0))
	details.AutomaticSize = Enum.AutomaticSize.Y
	details.Font = Enum.Font.Code
	details.TextSize = 11
	details.TextWrapped = false

	return gui, panel, header, progress, current, operation, actions, details
end

function Console.new(): any
	local gui, panel, header, progress, current, operation, actionsFrame, details = createGui()
	local self: any = setmetatable({
		gui = gui,
		panel = panel,
		header = header,
		progress = progress,
		current = current,
		operation = operation,
		details = details,
		batches = {},
		actions = {},
		dragging = false,
		dragStart = Vector2.zero,
		panelStart = Vector2.zero,
		connections = {},
	}, Console)

	for _, definition in ACTIONS do
		local button = Instance.new("TextButton")
		button.Name = definition.id
		button.LayoutOrder = definition.order
		button.BackgroundColor3 = Color3.fromRGB(72, 91, 122)
		button.BorderSizePixel = 0
		button.Font = Enum.Font.GothamMedium
		button.Text = definition.label
		button.TextColor3 = Color3.fromRGB(238, 240, 244)
		button.TextSize = 11
		button.Selectable = false
		button.Active = false
		button.AutoButtonColor = false
		button.Parent = actionsFrame
		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 5)
		buttonCorner.Parent = button
		self.actions[definition.id] = { button = button, handlers = {} }
		button.Activated:Connect(function()
			for _, handler in self.actions[definition.id].handlers do
				task.spawn(handler)
			end
		end)
	end

	table.insert(
		self.connections,
		header.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				self.dragging = true
				self.dragStart = Vector2.new(input.Position.X, input.Position.Y)
				self.panelStart = Vector2.new(panel.Position.X.Offset, panel.Position.Y.Offset)
			end
		end)
	)
	table.insert(
		self.connections,
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				self.dragging = false
			end
		end)
	)
	table.insert(
		self.connections,
		UserInputService.InputChanged:Connect(function(input)
			if self.dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				local pointer = Vector2.new(input.Position.X, input.Position.Y)
				local nextPosition = clampPosition(self.panelStart + pointer - self.dragStart)
				panel.Position = UDim2.fromOffset(nextPosition.X, nextPosition.Y)
			end
		end)
	)

	local camera = Workspace.CurrentCamera
	if camera ~= nil then
		table.insert(
			self.connections,
			camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
				local position =
					clampPosition(Vector2.new(panel.Position.X.Offset, panel.Position.Y.Offset))
				panel.Position = UDim2.fromOffset(position.X, position.Y)
			end)
		)
	end

	self:refresh()
	return self
end

function Console.get(): any
	if singleton == nil then
		singleton = Console.new()
	end
	return singleton
end

function Console:registerBatch(batchName: string, summary: any)
	self.batches[batchName] = {
		summary = summary,
		status = "starting",
		operation = "waiting for evidence",
		failed = false,
	}
	self:refresh()
end

function Console:registerAction(actionId: string, handler: () -> ())
	local action: ActionRegistration? = self.actions[actionId]
	if action == nil then
		error("Unknown G1 Test Console action: " .. actionId)
	end
	table.insert(action.handlers, handler)
	action.button.Active = true
	action.button.AutoButtonColor = true
end

function Console:setActionState(actionId: string, enabled: boolean, label: string?)
	local action: ActionRegistration? = self.actions[actionId]
	if action == nil then
		return
	end
	if label ~= nil then
		action.button.Text = label
	end
	action.button.Active = enabled and #action.handlers > 0
	action.button.AutoButtonColor = action.button.Active
	action.button.BackgroundColor3 = if action.button.Active
		then Color3.fromRGB(72, 91, 122)
		else Color3.fromRGB(55, 57, 62)
end

function Console:setBatchStatus(batchName: string, status: string)
	local batch: BatchRegistration? = self.batches[batchName]
	if batch ~= nil then
		batch.status = status
		self:refresh()
	end
end

function Console:setOperation(batchName: string, message: string, failed: boolean?)
	local batch: BatchRegistration? = self.batches[batchName]
	if batch ~= nil then
		batch.operation = message
		batch.failed = failed == true
		self:refresh()
	end
end

function Console:_record(path: string): any?
	local separator = string.find(path, "/", 1, true)
	if separator == nil then
		return nil
	end
	local batchName = string.sub(path, 1, separator - 1)
	local checkId = string.sub(path, separator + 1)
	local batch: BatchRegistration? = self.batches[batchName]
	return if batch ~= nil then batch.summary.checks[checkId] else nil
end

function Console:_currentFlow(): (number, any)
	for index, step in FLOW do
		local complete = true
		for _, path in step.required do
			local record = self:_record(path)
			if record == nil or record.status ~= "pass" then
				complete = false
				break
			end
		end
		if not complete then
			return index, step
		end
	end
	return #FLOW, FLOW[#FLOW]
end

function Console:refresh()
	local passed = 0
	local total = 0
	local detailLines = {}
	local operationLines = {}
	local names = {}
	for name in self.batches do
		table.insert(names, name)
	end
	table.sort(names)
	for _, name in names do
		local batch: BatchRegistration = self.batches[name]
		table.insert(detailLines, string.format("[%s] %s", name, batch.status))
		for _, id in batch.summary.order do
			local record = batch.summary.checks[id]
			total += 1
			if record.status == "pass" then
				passed += 1
			end
			local token = if record.status == "pass"
				then "PASS"
				elseif record.status == "fail" then "FAIL"
				else "...."
			table.insert(detailLines, string.format("[%s] %-22s %s", token, id, record.detail))
		end
		table.insert(operationLines, string.format("%s: %s", name, batch.operation))
	end

	local flowIndex, flow = self:_currentFlow()
	local nextFlow = FLOW[math.min(flowIndex + 1, #FLOW)]
	self.progress.Text = string.format("Combined progress  %d / %d", passed, total)
	self.current.Text =
		string.format("CURRENT  %s\n%s\nNEXT  %s", flow.label, flow.detail, nextFlow.label)
	self.details.Text = table.concat(detailLines, "\n")
	self.operation.Text = table.concat(operationLines, "  ·  ")
	local anyFailure = false
	for _, batch in self.batches do
		if batch.failed then
			anyFailure = true
			break
		end
	end
	self.operation.TextColor3 = if anyFailure
		then Color3.fromRGB(232, 126, 126)
		else Color3.fromRGB(169, 178, 193)
end

return Console
