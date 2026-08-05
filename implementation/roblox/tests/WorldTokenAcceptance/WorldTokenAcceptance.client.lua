--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local rvtt = ReplicatedStorage:WaitForChild("RVTT")
local acceptanceMode = rvtt:FindFirstChild("Slice01AcceptanceMode")
if acceptanceMode == nil or not acceptanceMode:IsA("BoolValue") or not acceptanceMode.Value then
	return
end

local player = Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")
local clientFolder = playerScripts:WaitForChild("RVTT"):WaitForChild("Client")
local ClientRuntime = (require :: any)(clientFolder:WaitForChild("ClientRuntime"))
local client = ClientRuntime.await()
local worldTokens = client.WorldTokens

local SCENE_ID = "scene:slice-01-acceptance"
local HERO_NAME = "Slice 01 Hero"
local COMMAND_TIMEOUT_SECONDS = 10

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

local camera = Workspace.CurrentCamera
if camera ~= nil then
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(Vector3.new(28, 24, 28), Vector3.new(8, 0, 8))
end

local gui = Instance.new("ScreenGui")
gui.Name = "RVTT_WorldToken_Acceptance"
gui.ResetOnSpawn = false
gui.DisplayOrder = 220
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Position = UDim2.fromOffset(18, 18)
panel.Size = UDim2.fromOffset(390, 286)
panel.BackgroundColor3 = Color3.fromRGB(25, 28, 34)
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel = 0
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 9)
panelCorner.Parent = panel

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(16, 12)
title.Size = UDim2.new(1, -32, 0, 30)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "Slice 01 · 3D World Token Acceptance"
title.TextColor3 = Color3.fromRGB(238, 240, 244)
title.TextSize = 17
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local instructions = Instance.new("TextLabel")
instructions.Position = UDim2.fromOffset(16, 44)
instructions.Size = UDim2.new(1, -32, 0, 56)
instructions.BackgroundTransparency = 1
instructions.Font = Enum.Font.Gotham
instructions.Text =
	"1) Scene 준비  2) 월드의 3D Token 클릭  3) 바닥 클릭으로 서버 권위 이동  4) 저장 후 Stop·Play 복구"
instructions.TextColor3 = Color3.fromRGB(184, 191, 202)
instructions.TextSize = 12
instructions.TextWrapped = true
instructions.TextXAlignment = Enum.TextXAlignment.Left
instructions.TextYAlignment = Enum.TextYAlignment.Top
instructions.Parent = panel

local status = Instance.new("TextLabel")
status.Position = UDim2.fromOffset(16, 102)
status.Size = UDim2.new(1, -32, 0, 92)
status.BackgroundColor3 = Color3.fromRGB(19, 22, 27)
status.BorderSizePixel = 0
status.Font = Enum.Font.Code
status.TextColor3 = Color3.fromRGB(219, 224, 231)
status.TextSize = 12
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.Parent = panel

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 5)
statusCorner.Parent = status

local operation = Instance.new("TextLabel")
operation.Position = UDim2.fromOffset(16, 252)
operation.Size = UDim2.new(1, -32, 0, 24)
operation.BackgroundTransparency = 1
operation.Font = Enum.Font.Gotham
operation.Text = "대기 중"
operation.TextColor3 = Color3.fromRGB(166, 173, 184)
operation.TextSize = 12
operation.TextXAlignment = Enum.TextXAlignment.Left
operation.Parent = panel

local function makeButton(name: string, text: string, x: number, width: number): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.Position = UDim2.fromOffset(x, 204)
	button.Size = UDim2.fromOffset(width, 36)
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

local prepareButton = makeButton("Prepare", "Scene 준비·재개", 16, 116)
local frameButton = makeButton("Frame", "Token 카메라", 140, 108)
local verifyButton = makeButton("Verify", "복구 검증", 256, 118)

local terminalResults: { [string]: any } = {}
local busy = false
local lastProjectedPosition = "none"

client.Command.remotes.receipt.OnClientEvent:Connect(function(message)
	if
		type(message) == "table"
		and message.phase == "terminal"
		and type(message.commandId) == "string"
	then
		terminalResults[message.commandId] = message.result
	end
end)

local function setOperation(message: string, failed: boolean?)
	operation.Text = message
	operation.TextColor3 = if failed == true
		then Color3.fromRGB(232, 126, 126)
		else Color3.fromRGB(166, 173, 184)
end

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
			return nil
		end
		if result.ok == true then
			if type(result.value) == "table" and type(result.value.revision) == "number" then
				waitForRevision(result.value.revision)
			end
			return result
		end
		local code = if type(result.error) == "table" then result.error.code else nil
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

local function render()
	local state = currentState()
	local selected = worldTokens.Renderer:getSelectedActorId()
	local position = actorPosition(state)
	local tokenModel = if type(state.characterId) == "string"
		then worldTokens.Renderer:getTokenModel(state.characterId)
		else nil
	lastProjectedPosition = if position ~= nil
		then string.format("(%.2f, %.2f, %.2f)", position.X, position.Y, position.Z)
		else "none"
	status.Text = string.format(
		"revision=%d  role=%s\ncharacter=%s  scene=%s\ntoken3D=%s  selected=%s\nposition=%s",
		client.Replica.revision,
		if type(state.membership) == "table" then tostring(state.membership.role) else "none",
		tostring(state.characterId),
		tostring(state.scene.activeSceneId),
		if tokenModel ~= nil then "PASS" else "WAIT",
		tostring(selected),
		lastProjectedPosition
	)
	prepareButton.Active = not busy
	frameButton.Active = not busy and position ~= nil
	verifyButton.Active = not busy
end

local function ensureSuccess(result: any, commandType: string): any
	if type(result) ~= "table" or result.ok ~= true then
		error(commandType .. " failed")
	end
	return result
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
	setOperation("Scene·3D Token 준비 PASS · Token을 클릭하세요")
end

local function run(action: () -> ())
	if busy then
		return
	end
	busy = true
	render()
	local succeeded = xpcall(action, debug.traceback)
	busy = false
	if not succeeded then
		setOperation("Acceptance 작업 실행 실패 · Output을 확인하세요", true)
	end
	render()
end

prepareButton.Activated:Connect(function()
	task.spawn(function()
		run(prepareScene)
	end)
end)

frameButton.Activated:Connect(function()
	local position = actorPosition(currentState())
	local currentCamera = Workspace.CurrentCamera
	if position ~= nil and currentCamera ~= nil then
		currentCamera.CameraType = Enum.CameraType.Scriptable
		currentCamera.CFrame =
			CFrame.lookAt(position + Vector3.new(22, 19, 22), position + Vector3.new(0, 1.2, 0))
		setOperation("3D Token 카메라 정렬")
	end
end)

verifyButton.Activated:Connect(function()
	local state = currentState()
	local position = actorPosition(state)
	local model = if type(state.characterId) == "string"
		then worldTokens.Renderer:getTokenModel(state.characterId)
		else nil
	local passed = type(state.characterId) == "string"
		and state.selectedId == state.characterId
		and state.session.phase == "active"
		and state.scene.activeSceneId == SCENE_ID
		and position ~= nil
		and model ~= nil
		and player.Character == nil
	if passed then
		setOperation("3D Token·Scene·Position·Avatar Suppression 복구 PASS")
		print("[RVTT WorldToken] reconnect recovery PASS position=" .. lastProjectedPosition)
	else
		setOperation("복구 미충족 · status와 Output을 확인하세요", true)
	end
end)

worldTokens.SelectionChanged:Connect(function(actorId)
	setOperation("3D Token 선택 actor=" .. tostring(actorId))
	render()
end)
worldTokens.MoveRequested:Connect(function(actorId, destination, commandId)
	setOperation("서버 권위 이동 요청 · " .. tostring(commandId))
	print(
		string.format(
			"[RVTT WorldToken] acceptance move actor=%s destination=(%.2f, %.2f, %.2f)",
			actorId,
			destination.x,
			destination.y,
			destination.z
		)
	)
end)
client.Replica.Changed:Connect(function()
	render()
end)

render()
print("[RVTT WorldToken] acceptance ready")
