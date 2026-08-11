--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local rvtt = ReplicatedStorage:WaitForChild("RVTT")
local acceptanceMode = rvtt:FindFirstChild("Slice01AcceptanceMode")
if acceptanceMode == nil or not acceptanceMode:IsA("BoolValue") or not acceptanceMode.Value then
	return
end

local BatchSummary = require(ReplicatedStorage.RVTT.Shared.Diagnostics.BatchSummary)
local G1TestConsole = (require :: any)(
	rvtt:WaitForChild("AcceptanceShared"):WaitForChild("G1TestConsole")
)
local player = Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")
local clientFolder = playerScripts:WaitForChild("RVTT"):WaitForChild("Client")
local ClientRuntime = (require :: any)(clientFolder:WaitForChild("ClientRuntime"))
local client = ClientRuntime.await()
local worldTokens = client.WorldTokens

local BATCH_NAME = "slice01-world-interaction"
local SCENE_ID = "scene:slice-01-acceptance"
local HERO_NAME = "Slice 01 Hero"
local COMMAND_TIMEOUT_SECONDS = 10

local summary = BatchSummary.new(BATCH_NAME, {
	{ id = "boot", label = "Client Runtime Boot" },
	{ id = "dm-role", label = "Acceptance DM Role" },
	{ id = "character", label = "Active Character Selection" },
	{ id = "scene", label = "Active Scene and Actor" },
	{ id = "token-projection", label = "Workspace 3D Token Projection" },
	{ id = "camera-wasd-pan", label = "3D Camera WASD Pan" },
	{ id = "avatar-suppression", label = "Roblox Avatar Suppression" },
	{ id = "camera-frame", label = "3D Camera Frame" },
	{ id = "camera-orbit", label = "3D Camera Middle-button Orbit" },
	{ id = "camera-zoom", label = "3D Camera Zoom" },
	{ id = "token-pick", label = "Ray or Screen-space Token Pick" },
	{ id = "selection-highlight", label = "Selected Token Highlight" },
	{ id = "destination-marker", label = "Board Destination Marker" },
	{ id = "move-command", label = "movement.commit Submission" },
	{ id = "command-accepted", label = "Server Command Acceptance" },
	{ id = "projection-move", label = "Server Projection Position Update" },
})
local testConsole = G1TestConsole.get()
testConsole:registerBatch(BATCH_NAME, summary)
testConsole:setOperation(
	BATCH_NAME,
	"Batch 초기화 중 · 이 Build는 DataStore를 사용하지 않습니다"
)

local function createBoard()
	local existing = Workspace:FindFirstChild("RVTT_AcceptanceBoard")
	if existing ~= nil then
		existing:Destroy()
	end
	local board = Instance.new("Folder")
	board.Name = "RVTT_AcceptanceBoard"
	board.Parent = Workspace

	local floor = Instance.new("Part")
	floor.Name = "MoveSurface"
	floor.Size = Vector3.new(120, 1, 120)
	floor.Position = Vector3.new(0, -0.5, 0)
	floor.Anchored = true
	floor.CanCollide = true
	floor.CanQuery = true
	floor.CanTouch = false
	floor.Material = Enum.Material.Slate
	floor.Color = Color3.fromRGB(45, 49, 58)
	floor:SetAttribute("RVTTMoveSurface", true)
	floor.Parent = board

	for offset = -50, 50, 10 do
		local lineX = Instance.new("Part")
		lineX.Name = "GridX"
		lineX.Size = Vector3.new(120, 0.025, 0.08)
		lineX.Position = Vector3.new(0, 0.0125, offset)
		lineX.Anchored = true
		lineX.CanCollide = false
		lineX.CanQuery = false
		lineX.CanTouch = false
		lineX.Material = Enum.Material.Neon
		lineX.Color = Color3.fromRGB(74, 80, 92)
		lineX.Parent = board

		local lineZ = Instance.new("Part")
		lineZ.Name = "GridZ"
		lineZ.Size = Vector3.new(0.08, 0.025, 120)
		lineZ.Position = Vector3.new(offset, 0.0125, 0)
		lineZ.Anchored = true
		lineZ.CanCollide = false
		lineZ.CanQuery = false
		lineZ.CanTouch = false
		lineZ.Material = Enum.Material.Neon
		lineZ.Color = Color3.fromRGB(74, 80, 92)
		lineZ.Parent = board
	end
end

createBoard()

local terminalResults: { [string]: any } = {}
local busy = false
local passSummaryLogged = false
local lastProjectedPosition = "none"
local lastPickMethod = "none"
local lastCommandId = "none"
local moveStartPosition: Vector3? = nil
local tokenPickArmed = false
local armedHeroActorId: string? = nil

local function setOperation(message: string, failed: boolean?)
	testConsole:setOperation(BATCH_NAME, message, failed)
end

local function maybeLogPass()
	if summary:result() == "PASS" and not passSummaryLogged then
		passSummaryLogged = true
		setOperation(
			"World Interaction Batch PASS · Final Summary가 Output에 기록됐습니다"
		)
		summary:log(client.Replica.revision)
	end
end

local function refresh()
	maybeLogPass()
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

local function waitForRevision(target: number)
	local deadline = os.clock() + COMMAND_TIMEOUT_SECONDS
	while client.Replica.revision < target and os.clock() < deadline do
		task.wait(0.05)
	end
end

local function submit(commandType: string, payload: { [string]: unknown }): any
	for attempt = 1, 3 do
		setOperation(string.format("%s 실행 중 · %d", commandType, attempt))
		local commandId = client.Command:submit(commandType, payload)
		local result = waitForTerminal(commandId)
		if result == nil then
			print(
				string.format(
					"[RVTT Batch Command] event=timeout type=%s commandId=%s attempt=%d",
					commandType,
					commandId,
					attempt
				)
			)
			return nil
		end
		local ok = type(result) == "table" and result.ok == true
		local code = if type(result) == "table" and type(result.error) == "table"
			then result.error.code
			else nil
		local revision = if type(result) == "table" and type(result.value) == "table"
			then result.value.revision
			else nil
		print(
			string.format(
				"[RVTT Batch Command] event=terminal type=%s commandId=%s ok=%s code=%s revision=%s attempt=%d",
				commandType,
				commandId,
				tostring(ok),
				tostring(code),
				tostring(revision),
				attempt
			)
		)
		if ok then
			if type(revision) == "number" then
				waitForRevision(revision)
			end
			return result
		end
		if code ~= "STALE_REVISION" and code ~= "STALE_EPOCH" then
			return result
		end
		task.wait(0.5)
	end
	return nil
end

local function domains(): any
	local payload = client.Replica.payload
	return if type(payload) == "table" and type(payload.domains) == "table"
		then payload.domains
		else {}
end

local function firstOwned(map: any, statusFilter: string?): (string?, any?)
	if type(map) ~= "table" then
		return nil, nil
	end
	for id, value in map do
		if
			type(id) == "string"
			and type(value) == "table"
			and value.ownerUserId == player.UserId
			and (statusFilter == nil or value.status == statusFilter)
		then
			return id, value
		end
	end
	return nil, nil
end

local function currentState(): any
	local current = domains()
	local session = if type(current.session) == "table" then current.session else {}
	local character = if type(current.character) == "table" then current.character else {}
	local scene = if type(current.scene) == "table" then current.scene else {}
	local userKey = tostring(player.UserId)
	local selectedId = if type(session.selectedCharacter) == "table"
		then session.selectedCharacter[userKey]
		else nil
	local characterId, characterRecord = firstOwned(character.characters, "active")
	if type(selectedId) == "string" and type(character.characters) == "table" then
		local selected = character.characters[selectedId]
		if type(selected) == "table" and selected.ownerUserId == player.UserId then
			characterId = selectedId
			characterRecord = selected
		end
	end
	local draftId = firstOwned(character.drafts, nil)
	local actor = if type(scene.actors) == "table" and type(characterId) == "string"
		then scene.actors[characterId]
		else nil
	return {
		session = session,
		character = character,
		scene = scene,
		membership = if type(session.memberships) == "table"
			then session.memberships[userKey]
			else nil,
		selectedId = selectedId,
		ready = type(session.ready) == "table" and session.ready[userKey] == true,
		characterId = characterId,
		characterRecord = characterRecord,
		draftId = draftId,
		actor = actor,
	}
end

local function actorPosition(state: any): Vector3?
	if type(state.actor) ~= "table" or type(state.actor.position) ~= "table" then
		return nil
	end
	local position = state.actor.position
	if
		type(position.x) ~= "number"
		or type(position.y) ~= "number"
		or type(position.z) ~= "number"
	then
		return nil
	end
	return Vector3.new(position.x, position.y, position.z)
end

local function renderState()
	local state = currentState()
	local selected = worldTokens.Renderer:getSelectedActorId()
	local position = actorPosition(state)
	local tokenModel = if type(state.characterId) == "string"
		then worldTokens.Renderer:getTokenModel(state.characterId)
		else nil
	lastProjectedPosition = if position ~= nil
		then string.format("(%.2f, %.2f, %.2f)", position.X, position.Y, position.Z)
		else "none"
	testConsole:setBatchStatus(
		BATCH_NAME,
		string.format(
			"revision=%d role=%s character=%s scene=%s\ntoken3D=%s selected=%s pick=%s arm=%s destination=%s\nposition=%s command=%s",
			client.Replica.revision,
			if type(state.membership) == "table" then tostring(state.membership.role) else "none",
			tostring(state.characterId),
			tostring(state.scene.activeSceneId),
			if tokenModel ~= nil then "PASS" else "WAIT",
			tostring(selected),
			lastPickMethod,
			if tokenPickArmed then "ARMED" else "WAIT",
			tostring(worldTokens.Renderer:getDestinationStatus()),
			lastProjectedPosition,
			lastCommandId
		)
	)
	testConsole:setActionState("Prepare", not busy)
	testConsole:setActionState("ArmTokenPick", not busy and tokenModel ~= nil)
	testConsole:setActionState("Frame", not busy and tokenModel ~= nil)
	testConsole:setActionState("FinalSummary", true)
end

local function ensureSuccess(result: any, commandType: string): any
	if type(result) ~= "table" or result.ok ~= true then
		error(commandType .. " failed")
	end
	return result
end

local function markStateChecks(state: any)
	if type(state.membership) == "table" and state.membership.role == "dm" then
		pass("dm-role", "role=dm")
	end
	if type(state.characterId) == "string" and state.selectedId == state.characterId then
		pass("character", state.characterId)
	end
	if
		state.session.phase == "active"
		and state.scene.activeSceneId == SCENE_ID
		and type(state.actor) == "table"
	then
		pass("scene", SCENE_ID)
	end
	if
		type(state.characterId) == "string"
		and worldTokens.Renderer:getTokenModel(state.characterId) ~= nil
	then
		pass("token-projection", state.characterId)
	end
end

local function prepareScene()
	local state = currentState()
	if type(state.membership) ~= "table" or state.membership.role ~= "dm" then
		ensureSuccess(submit("session.join", {}), "session.join")
		state = currentState()
	end

	local characterId = state.characterId
	if characterId == nil then
		local draftId = state.draftId
		if draftId == nil then
			local created = ensureSuccess(
				submit("character.create_draft", { name = HERO_NAME }),
				"character.create_draft"
			)
			draftId = created.value.outcome.id
		end
		ensureSuccess(submit("character.activate", { characterId = draftId }), "character.activate")
		characterId = draftId
		state = currentState()
	end

	if state.selectedId ~= characterId then
		ensureSuccess(
			submit("session.select_character", { characterId = characterId }),
			"session.select_character"
		)
		state = currentState()
	end
	if state.ready ~= true then
		ensureSuccess(submit("session.ready", { ready = true }), "session.ready")
		state = currentState()
	end
	if state.session.phase ~= "active" or state.session.sceneId ~= SCENE_ID then
		ensureSuccess(submit("session.start", { sceneId = SCENE_ID }), "session.start")
		state = currentState()
	end
	if type(state.actor) ~= "table" then
		ensureSuccess(
			submit("scene.enter", { sceneId = SCENE_ID, actorId = characterId }),
			"scene.enter"
		)
	end

	local deadline = os.clock() + COMMAND_TIMEOUT_SECONDS
	repeat
		state = currentState()
		markStateChecks(state)
		if
			type(state.characterId) == "string"
			and worldTokens.Renderer:getTokenModel(state.characterId) ~= nil
		then
			break
		end
		task.wait(0.05)
	until os.clock() >= deadline

	markStateChecks(state)
	setOperation("자동 준비 PASS · Arm Token Pick을 누른 뒤 Hero를 좌클릭하세요")
end

local function setTokenPickPending(detail: string)
	summary:pending("token-pick", detail)
	summary:pending("selection-highlight", detail)
	refresh()
end

local function invalidateTokenPickArm(reason: string)
	if not tokenPickArmed then
		return
	end
	tokenPickArmed = false
	armedHeroActorId = nil
	testConsole:setActionState("ArmTokenPick", true, "Re-arm Token Pick")
	setTokenPickPending("re-arm required: " .. reason)
	setOperation(
		"Token Pick 준비가 Replica 선택 복원으로 취소됐습니다 · 다시 Arm 하세요",
		true
	)
	renderState()
end

local function initializeCameraChecks()
	local requirements: { [string]: string } = {
		["camera-frame"] = "press F or Token Frame",
		["camera-orbit"] = "middle-click drag to orbit",
		["camera-wasd-pan"] = "press W/A/S/D outside WASD movement mode",
		["camera-zoom"] = "mouse wheel",
	}
	for id, detail in requirements do
		if summary.checks[id].status ~= "pass" then
			summary:pending(id, detail)
		end
	end
	refresh()
end

local function run(action: () -> ())
	if busy then
		return
	end
	busy = true
	renderState()
	local errorMessage: any = nil
	local succeeded = xpcall(action, function(errorValue)
		errorMessage = debug.traceback(tostring(errorValue))
	end)
	busy = false
	if not succeeded then
		setOperation("Batch 작업 실패 · Output의 첫 오류를 확인하세요", true)
		warn("[RVTT Batch] event=action-failed error=" .. tostring(errorMessage))
	end
	renderState()
	refresh()
end

testConsole:registerAction("Prepare", function()
	run(function()
		prepareScene()
		initializeCameraChecks()
	end)
end)

testConsole:registerAction("ArmTokenPick", function()
	local state = currentState()
	local heroActorId = state.characterId
	local tokenReady = type(heroActorId) == "string"
		and type(state.membership) == "table"
		and state.membership.role == "dm"
		and state.session.phase == "active"
		and state.scene.activeSceneId == SCENE_ID
		and type(state.actor) == "table"
		and worldTokens.Renderer:getTokenModel(heroActorId) ~= nil
	if not tokenReady or type(heroActorId) ~= "string" then
		setTokenPickPending("wait for automatic setup, then arm")
		setOperation("Hero Token 준비가 끝난 뒤 Arm Token Pick을 누르세요", true)
		renderState()
		return
	end

	tokenPickArmed = true
	armedHeroActorId = heroActorId
	setTokenPickPending("armed; real left-click on Hero required")
	local cleared = worldTokens.Renderer:setSelected(nil)
	if not cleared or worldTokens.Renderer:getSelectedActorId() ~= nil then
		invalidateTokenPickArm("local renderer selection did not clear")
		return
	end
	testConsole:setActionState("ArmTokenPick", true, "Token Pick Armed")
	setOperation("Token Pick ARMED · 보이는 Hero Token을 실제 좌클릭하세요")
	renderState()
end)

testConsole:registerAction("Frame", function()
	worldTokens.Camera:requestFrame("button", false)
	renderState()
end)

testConsole:registerAction("FinalSummary", function()
	summary:log(client.Replica.revision)
	setOperation("현재 Final Summary를 Output에 기록했습니다")
end)

worldTokens.Camera.InputResolved:Connect(function(action, source, applied, changed, processed)
	local id = if action == "frame"
		then "camera-frame"
		elseif action == "orbit" and source == "mouse-middle-screen-delta" then "camera-orbit"
		elseif action == "pan" and source == "keyboard-wasd" then "camera-wasd-pan"
		elseif action == "zoom" then "camera-zoom"
		else nil
	if id == nil then
		return
	end
	local passed = applied == true and (action == "frame" or changed == true)
	local detail = string.format(
		"source=%s applied=%s changed=%s processed=%s",
		tostring(source),
		tostring(applied),
		tostring(changed),
		tostring(processed)
	)
	if passed then
		pass(id, detail)
	else
		fail(id, detail)
	end
	setOperation(
		if passed
			then "카메라 실제 입력 PASS · " .. action
			else "카메라 입력 실패 · " .. action,
		not passed
	)
	print(
		string.format(
			"[RVTT Batch Camera] action=%s source=%s result=%s applied=%s changed=%s processed=%s",
			tostring(action),
			tostring(source),
			if passed then "PASS" else "FAIL",
			tostring(applied),
			tostring(changed),
			tostring(processed)
		)
	)
	renderState()
end)

worldTokens.PickResolved:Connect(function(actorId, method, selected, hitName)
	lastPickMethod = tostring(method)
	local expectedActorId = armedHeroActorId
	local realArmedPick = tokenPickArmed
		and type(expectedActorId) == "string"
		and actorId == expectedActorId
		and method == "ray"
	tokenPickArmed = false
	armedHeroActorId = nil
	testConsole:setActionState("ArmTokenPick", true, "Arm Token Pick")
	if not realArmedPick then
		setTokenPickPending("press Arm Token Pick before the real Hero click")
		setOperation(
			"Arm되지 않은 Token Pick은 G1 evidence로 기록하지 않습니다",
			true
		)
		renderState()
		return
	end
	if selected then
		pass("token-pick", string.format("method=%s hit=%s", tostring(method), tostring(hitName)))
		if worldTokens.Renderer:isSelectedHighlighted(actorId) then
			pass("selection-highlight", actorId)
		else
			fail("selection-highlight", "selection without Highlight")
		end
		setOperation("Token 선택 PASS · 바닥의 다른 위치를 클릭하세요")
	else
		fail("token-pick", string.format("method=%s actor=%s", tostring(method), tostring(actorId)))
	end
	renderState()
end)

worldTokens.SelectionChanged:Connect(function(actorId)
	if tokenPickArmed and actorId ~= nil then
		task.defer(function()
			if tokenPickArmed and worldTokens.Renderer:getSelectedActorId() ~= nil then
				invalidateTokenPickArm("selection was restored before the real Hero click")
			end
		end)
	end
end)

worldTokens.MoveRequested:Connect(function(actorId, destination, commandId, baseRevision)
	lastCommandId = tostring(commandId)
	moveStartPosition = actorPosition(currentState())
	pass(
		"move-command",
		string.format("actor=%s baseRevision=%s", tostring(actorId), tostring(baseRevision))
	)
	if worldTokens.Renderer:getDestinationStatus() == "pending" then
		pass(
			"destination-marker",
			string.format("(%.2f,%.2f,%.2f)", destination.x, destination.y, destination.z)
		)
	else
		fail("destination-marker", "pending marker missing")
	end
	setOperation("movement.commit 제출 · 서버 Receipt와 Projection 대기")
	renderState()
end)

worldTokens.MoveResolved:Connect(
	function(actorId, destination, commandId, ok, code, revision, baseRevision)
		if ok then
			pass(
				"command-accepted",
				string.format(
					"commandId=%s revision=%s base=%s",
					tostring(commandId),
					tostring(revision),
					tostring(baseRevision)
				)
			)
		else
			fail(
				"command-accepted",
				string.format("actor=%s code=%s", tostring(actorId), tostring(code))
			)
		end
		print(
			string.format(
				"[RVTT Batch Move] event=terminal actor=%s commandId=%s ok=%s code=%s revision=%s destination=(%.2f,%.2f,%.2f)",
				tostring(actorId),
				tostring(commandId),
				tostring(ok),
				tostring(code),
				tostring(revision),
				destination.x,
				destination.y,
				destination.z
			)
		)
		renderState()
	end
)

worldTokens.DestinationChanged:Connect(function(destination)
	if type(destination) == "table" and destination.status == "projected" then
		local currentPosition = actorPosition(currentState())
		local moved = currentPosition ~= nil
			and (
				moveStartPosition == nil
				or (currentPosition - moveStartPosition).Magnitude > 0.001
			)
		if moved and currentPosition ~= nil then
			pass(
				"projection-move",
				string.format(
					"revision=%s position=(%.2f,%.2f,%.2f)",
					tostring(destination.revision),
					currentPosition.X,
					currentPosition.Y,
					currentPosition.Z
				)
			)
			setOperation(
				"서버 Projection 이동 PASS · 이 Build는 메모리 상태만 검증합니다"
			)
		else
			fail("projection-move", "Projection reached unchanged position")
		end
	end
	renderState()
end)

worldTokens.Reconciled:Connect(function()
	markStateChecks(currentState())
	renderState()
end)

client.Replica.Changed:Connect(function()
	markStateChecks(currentState())
	renderState()
end)

pass("boot", "ClientRuntime ready")
if player.Character == nil then
	pass("avatar-suppression", "Player.Character=nil")
else
	fail("avatar-suppression", "Roblox Character exists")
end
initializeCameraChecks()
renderState()
refresh()

print(
	string.format(
		"[RVTT Batch] event=ready batch=%s revision=%d mode=acceptance persistence=disabled",
		BATCH_NAME,
		client.Replica.revision
	)
)

task.spawn(function()
	run(function()
		prepareScene()
		initializeCameraChecks()
	end)
end)
