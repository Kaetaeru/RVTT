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
local G1TestConsole = (require :: any)(
	rvtt:WaitForChild("AcceptanceShared"):WaitForChild("G1TestConsole")
)
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
local testConsole = G1TestConsole.get()
testConsole:registerBatch(BATCH_NAME, summary)

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

local function refresh()
	if summary:result() == "PASS" and not passSummaryLogged then
		passSummaryLogged = true
		testConsole:setOperation(
			BATCH_NAME,
			"Context Input PASS · Final Summary가 Output에 기록됐습니다"
		)
		summary:log(client.Replica.revision)
	end
	testConsole:refresh()
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
		testConsole:setOperation(
			BATCH_NAME,
			"G1 targets ready · Follow the visible input sequence."
		)
	end, function(errorValue)
		return debug.traceback(tostring(errorValue))
	end)
	busy = false
	if not ok then
		testConsole:setOperation(
			BATCH_NAME,
			"Acceptance 대상 준비 실패 · Output 확인",
			true
		)
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

testConsole:registerAction("Exploration", function()
	if busy then
		return
	end
	busy = true
	local result = submit("encounter.end", { reason = "acceptance-exploration" })
	busy = false
	if type(result) == "table" and result.ok == true then
		testConsole:setOperation(
			BATCH_NAME,
			"탐험 모드 · Console 행동을 테스트하세요"
		)
	else
		testConsole:setOperation(
			BATCH_NAME,
			"이미 탐험 모드이거나 Encounter 종료가 불필요합니다"
		)
	end
end)

testConsole:registerAction("FinalSummary", function()
	summary:log(client.Replica.revision)
	testConsole:setOperation(
		BATCH_NAME,
		"현재 Context Input Summary를 Output에 기록했습니다"
	)
end)

testConsole:setActionState("Exploration", true)
testConsole:setActionState("FinalSummary", true)
testConsole:refresh()
task.spawn(prepareTargets)

print(string.format("[RVTT Context Input] event=ready batch=%s persistence=disabled", BATCH_NAME))
