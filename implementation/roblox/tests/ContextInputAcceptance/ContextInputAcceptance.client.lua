--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local rvtt = ReplicatedStorage:WaitForChild("RVTT")
local acceptanceMode = rvtt:FindFirstChild("Slice01AcceptanceMode")
if acceptanceMode == nil or not acceptanceMode:IsA("BoolValue") or not acceptanceMode.Value then
	return
end

local BatchSummary = require(ReplicatedStorage.RVTT.Shared.Diagnostics.BatchSummary)
local playerScripts = player:WaitForChild("PlayerScripts")
local clientFolder = playerScripts:WaitForChild("RVTT"):WaitForChild("Client")
local ClientRuntime = (require :: any)(clientFolder:WaitForChild("ClientRuntime"))
local client = ClientRuntime.await()
local worldTokens = client.WorldTokens

local BATCH_NAME = "contextual-pointer-actions"
local COMMAND_TIMEOUT_SECONDS = 10
local OBJECT_POSITION = Vector3.new(18, 2, -8)

local summary = BatchSummary.new(BATCH_NAME, {
	{ id = "setup-object", label = "Exploration Object Setup" },
	{ id = "camera-orbit", label = "Middle-button Camera Orbit" },
	{ id = "right-click-camera-noop", label = "Right-click Camera No-op" },
	{ id = "esc-gameplay-noop", label = "ESC Gameplay No-op" },
	{ id = "q-one-context-back", label = "Q One-context Back" },
	{ id = "move-menu", label = "Right-click Move Action Table" },
	{ id = "move-default", label = "Left-click Default Move" },
	{ id = "interact-menu", label = "Right-click Exploration Action Table" },
	{ id = "interact-default", label = "Left-click Default Interaction" },
})

local terminalResults: { [string]: any } = {}
local busy = false
local passSummaryLogged = false
local actionMenuOpen = false
local cameraInputResolutionCount = 0
local contextActionResolutionCount = 0
local lastContextCancel: { reason: any, observedAt: number, actionCount: number }? = nil

client.Command.remotes.receipt.OnClientEvent:Connect(function(message)
	if
		type(message) == "table"
		and message.phase == "terminal"
		and type(message.commandId) == "string"
	then
		terminalResults[message.commandId] = message.result
	end
end)

local function waitForTerminal(commandId: string): any
	local deadline = os.clock() + COMMAND_TIMEOUT_SECONDS
	repeat
		local result = terminalResults[commandId]
		if result ~= nil then
			terminalResults[commandId] = nil
			return result
		end
		task.wait(0.05)
	until os.clock() >= deadline
	return nil
end

local function submit(commandType: string, payload: { [string]: any }): any
	local commandId = client.Command:submit(commandType, payload)
	return waitForTerminal(commandId)
end

local function ensureSuccess(result: any, commandType: string): any
	if type(result) ~= "table" or result.ok ~= true then
		error(commandType .. " failed")
	end
	return result
end

local function outcome(result: any): any
	return type(result) == "table" and type(result.value) == "table" and result.value.outcome or nil
end

local gui = Instance.new("ScreenGui")
gui.Name = "RVTT_ContextInput_Acceptance"
gui.ResetOnSpawn = false
gui.DisplayOrder = 225
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -18, 0, 18)
panel.Size = UDim2.fromOffset(470, 520)
panel.BackgroundColor3 = Color3.fromRGB(25, 28, 34)
panel.BackgroundTransparency = 0.04
panel.BorderSizePixel = 0
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 9)
panelCorner.Parent = panel

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(16, 12)
title.Size = UDim2.new(1, -32, 0, 28)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "Context Input · Acceptance"
title.TextColor3 = Color3.fromRGB(238, 240, 244)
title.TextSize = 17
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local instructions = Instance.new("TextLabel")
instructions.Position = UDim2.fromOffset(16, 46)
instructions.Size = UDim2.new(1, -32, 0, 130)
instructions.BackgroundTransparency = 1
instructions.Font = Enum.Font.Gotham
instructions.Text = table.concat({
	"1. Select Hero · Middle-button drag = Camera Orbit",
	"2. Surface right-click → Move table → ESC(no-op) → Q(close) → surface left-click",
	"3. Blue Console right-click → action table → ESC(no-op) → Q(close) → left-click",
	"Right-click must not move the camera. G1 does not gate Player-vs-hostile attack.",
}, "\n")
instructions.TextColor3 = Color3.fromRGB(190, 197, 208)
instructions.TextSize = 12
instructions.TextWrapped = true
instructions.TextXAlignment = Enum.TextXAlignment.Left
instructions.TextYAlignment = Enum.TextYAlignment.Top
instructions.Parent = panel

local checklist = Instance.new("TextLabel")
checklist.Position = UDim2.fromOffset(16, 184)
checklist.Size = UDim2.new(1, -32, 0, 218)
checklist.BackgroundColor3 = Color3.fromRGB(19, 22, 27)
checklist.BorderSizePixel = 0
checklist.Font = Enum.Font.Code
checklist.TextColor3 = Color3.fromRGB(219, 224, 231)
checklist.TextSize = 11
checklist.TextXAlignment = Enum.TextXAlignment.Left
checklist.TextYAlignment = Enum.TextYAlignment.Top
checklist.Parent = panel

local checklistCorner = Instance.new("UICorner")
checklistCorner.CornerRadius = UDim.new(0, 5)
checklistCorner.Parent = checklist

local operation = Instance.new("TextLabel")
operation.Position = UDim2.fromOffset(16, 466)
operation.Size = UDim2.new(1, -32, 0, 38)
operation.BackgroundTransparency = 1
operation.Font = Enum.Font.Gotham
operation.Text = "Acceptance 대상 준비 중"
operation.TextColor3 = Color3.fromRGB(166, 173, 184)
operation.TextSize = 12
operation.TextWrapped = true
operation.TextXAlignment = Enum.TextXAlignment.Left
operation.Parent = panel

local function makeButton(name: string, text: string, x: number, width: number): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.Position = UDim2.fromOffset(x, 414)
	button.Size = UDim2.fromOffset(width, 38)
	button.BackgroundColor3 = Color3.fromRGB(72, 91, 122)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamMedium
	button.Text = text
	button.TextColor3 = Color3.fromRGB(238, 240, 244)
	button.TextSize = 12
	button.Parent = panel
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 5)
	corner.Parent = button
	return button
end

local explorationButton = makeButton("Exploration", "Exploration", 16, 210)
local summaryButton = makeButton("Summary", "Final Summary", 236, 218)

local function statusToken(status: string): string
	if status == "pass" then
		return "PASS"
	end
	if status == "fail" then
		return "FAIL"
	end
	return "...."
end

local function renderChecklist()
	local lines = {}
	for _, id in summary.order do
		local record = summary.checks[id]
		table.insert(
			lines,
			string.format("[%s] %-18s %s", statusToken(record.status), id, record.detail)
		)
	end
	checklist.Text = table.concat(lines, "\n")
end

local function refresh()
	renderChecklist()
	if summary:result() == "PASS" and not passSummaryLogged then
		passSummaryLogged = true
		operation.Text = "Context Input PASS · Final Summary가 Output에 기록됐습니다"
		summary:log(client.Replica.revision)
	end
end

local function pass(id: string, detail: string?)
	summary:pass(id, detail)
	refresh()
end

local function fail(id: string, detail: string?)
	summary:fail(id, detail)
	refresh()
end

local function actionIds(actions: { any }): { [string]: boolean }
	local ids = {}
	for _, action in actions do
		ids[action.id] = true
	end
	return ids
end

local function createObjectVisual(id: string)
	local existing = Workspace:FindFirstChild("RVTT_Context_Console")
	if existing ~= nil then
		existing:Destroy()
	end
	local part = Instance.new("Part")
	part.Name = "RVTT_Context_Console"
	part.Size = Vector3.new(5, 4, 5)
	part.Position = OBJECT_POSITION
	part.Anchored = true
	part.CanCollide = true
	part.CanQuery = true
	part.Material = Enum.Material.Metal
	part.Color = Color3.fromRGB(51, 116, 171)
	part:SetAttribute("RVTTObjectId", id)
	part.Parent = Workspace

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Adornee = part
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(180, 30)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
	billboard.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(22, 28, 38)
	label.BackgroundTransparency = 0.15
	label.BorderSizePixel = 0
	label.Font = Enum.Font.GothamBold
	label.Text = "Exploration Console"
	label.TextColor3 = Color3.fromRGB(238, 240, 244)
	label.TextSize = 13
	label.Parent = billboard
end

local function currentHero(): string?
	local payload = client.Replica.payload
	local domains = type(payload) == "table" and payload.domains or nil
	local session = type(domains) == "table" and domains.session or nil
	local selected = type(session) == "table" and session.selectedCharacter or nil
	local id = type(selected) == "table" and selected[tostring(player.UserId)] or nil
	return type(id) == "string" and id or nil
end

local function waitForHero(): string
	local deadline = os.clock() + 15
	repeat
		local id = currentHero()
		if id ~= nil and worldTokens.Renderer:getTokenModel(id) ~= nil then
			return id
		end
		task.wait(0.1)
	until os.clock() >= deadline
	error("Slice 01 Hero was not prepared")
end

local function prepareTargets()
	if busy then
		return
	end
	busy = true
	local ok, errorMessage = xpcall(function()
		waitForHero()

		local objectResult = ensureSuccess(
			submit("scene.spawn_object", {
				kind = "acceptance-console",
				position = { x = OBJECT_POSITION.X, y = 0, z = OBJECT_POSITION.Z },
				state = { state = "closed", locked = false },
				interactionIds = { "open", "close", "activate", "deactivate", "inspect" },
				searchDc = 1,
				knowledgeIds = {},
			}),
			"scene.spawn_object"
		)
		local objectOutcome = outcome(objectResult)
		local objectId = type(objectOutcome) == "table" and objectOutcome.id or nil
		if objectId == nil then
			error("scene.spawn_object returned no object id")
		end
		createObjectVisual(objectId)
		pass("setup-object", objectId)
		operation.Text = "G1 targets ready · Follow the visible input sequence."
	end, function(errorValue)
		return debug.traceback(tostring(errorValue))
	end)
	busy = false
	if not ok then
		operation.Text = "Acceptance 대상 준비 실패 · Output 확인"
		warn("[RVTT Context Input] event=setup-failed error=" .. tostring(errorMessage))
	end
end

worldTokens.Camera.InputResolved:Connect(function(action, source, applied, changed)
	cameraInputResolutionCount += 1
	if action == "orbit" and source == "mouse-middle-screen-delta" then
		if applied == true and changed == true then
			pass("camera-orbit", "middle-button yaw/pitch changed")
		else
			fail("camera-orbit", "middle-button orbit was not applied")
		end
	end
end)

worldTokens.ActionMenuChanged:Connect(function(open, actions, target)
	if open ~= true then
		if actionMenuOpen then
			lastContextCancel = {
				reason = target,
				observedAt = os.clock(),
				actionCount = contextActionResolutionCount,
			}
		end
		actionMenuOpen = false
		return
	end
	actionMenuOpen = true
	lastContextCancel = nil
	if type(actions) ~= "table" or type(target) ~= "table" then
		return
	end
	local ids = actionIds(actions)
	if target.kind == "surface" and ids.move then
		pass("move-menu", "move")
	elseif target.kind == "object" and ids["interact:inspect"] and ids.search then
		pass("interact-menu", "interaction table count=" .. tostring(#actions))
	end
end)

worldTokens.ContextActionResolved:Connect(function(action, _, ok, code)
	contextActionResolutionCount += 1
	if action.kind == "move" then
		if ok then
			pass("move-default", action.id)
		else
			fail("move-default", tostring(code))
		end
	elseif action.kind == "interact" then
		if ok then
			pass("interact-default", action.id)
		else
			fail("interact-default", tostring(code))
		end
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		local cameraCountBefore = cameraInputResolutionCount
		task.defer(function()
			local cameraStayedStill = cameraInputResolutionCount == cameraCountBefore
			if cameraStayedStill then
				pass(
					"right-click-camera-noop",
					"no camera input resolved; processed=" .. tostring(processed)
				)
			else
				fail("right-click-camera-noop", "right-click resolved a camera input")
			end
		end)
	elseif input.KeyCode == Enum.KeyCode.Escape and actionMenuOpen then
		local actionCountBefore = contextActionResolutionCount
		task.defer(function()
			local menuStayedOpen = worldTokens.ActionMenu:isOpen()
			local noWorldAction = contextActionResolutionCount == actionCountBefore
			if menuStayedOpen and noWorldAction then
				pass("esc-gameplay-noop", "menu remained open; processed=" .. tostring(processed))
			else
				fail(
					"esc-gameplay-noop",
					"menuOpen="
						.. tostring(menuStayedOpen)
						.. " noWorldAction="
						.. tostring(noWorldAction)
				)
			end
		end)
	elseif input.KeyCode == Enum.KeyCode.Q then
		local inputObservedAt = os.clock()
		local menuWasOpen = actionMenuOpen
		local actionCountBefore = contextActionResolutionCount
		task.defer(function()
			local close = lastContextCancel
			local productionCloseObserved = close ~= nil
				and close.reason == "context-cancel"
				and close.observedAt >= inputObservedAt - 0.25
				and close.actionCount == actionCountBefore
			local menuClosed = not worldTokens.ActionMenu:isOpen()
			local noWorldAction = contextActionResolutionCount == actionCountBefore
			if
				(menuWasOpen or productionCloseObserved)
				and productionCloseObserved
				and menuClosed
				and noWorldAction
			then
				pass("q-one-context-back", "production context-cancel closed only the action table")
			else
				fail(
					"q-one-context-back",
					string.format(
						"wasOpen=%s closeSignal=%s menuClosed=%s noWorldAction=%s processed=%s",
						tostring(menuWasOpen),
						tostring(productionCloseObserved),
						tostring(menuClosed),
						tostring(noWorldAction),
						tostring(processed)
					)
				)
			end
		end)
	end
end)

explorationButton.Activated:Connect(function()
	task.spawn(function()
		if busy then
			return
		end
		busy = true
		local result = submit("encounter.end", { reason = "acceptance-exploration" })
		busy = false
		if type(result) == "table" and result.ok == true then
			operation.Text = "탐험 모드 · Console 행동을 테스트하세요"
		else
			operation.Text = "이미 탐험 모드이거나 Encounter 종료가 불필요합니다"
		end
	end)
end)

summaryButton.Activated:Connect(function()
	summary:log(client.Replica.revision)
	operation.Text = "현재 Context Input Summary를 Output에 기록했습니다"
end)

renderChecklist()
task.spawn(prepareTargets)

print(string.format("[RVTT Context Input] event=ready batch=%s persistence=disabled", BATCH_NAME))
