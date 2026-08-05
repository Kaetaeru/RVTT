--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local rvtt = ReplicatedStorage:WaitForChild("RVTT")
local acceptanceMode = rvtt:FindFirstChild("Slice01AcceptanceMode")
if
	acceptanceMode == nil
	or not acceptanceMode:IsA("BoolValue")
	or acceptanceMode.Value ~= true
then
	return
end

local player = Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")
local clientFolder = playerScripts:WaitForChild("RVTT"):WaitForChild("Client")
local ClientRuntime = require(clientFolder:WaitForChild("ClientRuntime"))
local client = ClientRuntime.await()

local SCENE_ID = "scene:slice-01-acceptance"
local HERO_NAME = "Slice 01 Hero"
local MOVE_A = { x = 12, y = 0, z = 8 }
local MOVE_B = { x = 24, y = 0, z = 16 }
local COMMAND_TIMEOUT_SECONDS = 10

local gui = Instance.new("ScreenGui")
gui.Name = "RVTT_Slice01_Acceptance"
gui.ResetOnSpawn = false
gui.DisplayOrder = 200
gui.Parent = player:WaitForChild("PlayerGui")

local root = Instance.new("Frame")
root.Name = "Root"
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Position = UDim2.fromScale(0.5, 0.5)
root.Size = UDim2.fromOffset(780, 570)
root.BackgroundColor3 = Color3.fromRGB(25, 28, 34)
root.BorderSizePixel = 0
root.Parent = gui

local rootCorner = Instance.new("UICorner")
rootCorner.CornerRadius = UDim.new(0, 10)
rootCorner.Parent = root

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Position = UDim2.fromOffset(20, 14)
title.Size = UDim2.new(1, -40, 0, 34)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "RVTT Slice 01 Acceptance Harness"
title.TextColor3 = Color3.fromRGB(238, 240, 244)
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = root

local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.Position = UDim2.fromOffset(20, 48)
subtitle.Size = UDim2.new(1, -40, 0, 22)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.Gotham
subtitle.Text = "Production 명령·Projection·Persistence를 그대로 사용하는 검증 전용 화면"
subtitle.TextColor3 = Color3.fromRGB(166, 173, 184)
subtitle.TextSize = 13
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = root

local left = Instance.new("Frame")
left.Name = "Steps"
left.Position = UDim2.fromOffset(20, 82)
left.Size = UDim2.fromOffset(350, 468)
left.BackgroundColor3 = Color3.fromRGB(33, 37, 45)
left.BorderSizePixel = 0
left.Parent = root

local leftCorner = Instance.new("UICorner")
leftCorner.CornerRadius = UDim.new(0, 8)
leftCorner.Parent = left

local right = Instance.new("Frame")
right.Name = "Scene"
right.Position = UDim2.fromOffset(390, 82)
right.Size = UDim2.fromOffset(370, 468)
right.BackgroundColor3 = Color3.fromRGB(33, 37, 45)
right.BorderSizePixel = 0
right.Parent = root

local rightCorner = Instance.new("UICorner")
rightCorner.CornerRadius = UDim.new(0, 8)
rightCorner.Parent = right

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "FlowStatus"
statusLabel.Position = UDim2.fromOffset(14, 12)
statusLabel.Size = UDim2.new(1, -28, 0, 136)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.Code
statusLabel.TextColor3 = Color3.fromRGB(221, 225, 232)
statusLabel.TextSize = 13
statusLabel.TextWrapped = false
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.Parent = left

local operationLabel = Instance.new("TextLabel")
operationLabel.Name = "Operation"
operationLabel.Position = UDim2.fromOffset(14, 426)
operationLabel.Size = UDim2.new(1, -28, 0, 30)
operationLabel.BackgroundTransparency = 1
operationLabel.Font = Enum.Font.Gotham
operationLabel.Text = "대기 중"
operationLabel.TextColor3 = Color3.fromRGB(166, 173, 184)
operationLabel.TextSize = 12
operationLabel.TextWrapped = true
operationLabel.TextXAlignment = Enum.TextXAlignment.Left
operationLabel.TextYAlignment = Enum.TextYAlignment.Top
operationLabel.Parent = left

local sceneTitle = Instance.new("TextLabel")
sceneTitle.Name = "SceneTitle"
sceneTitle.Position = UDim2.fromOffset(14, 12)
sceneTitle.Size = UDim2.new(1, -28, 0, 24)
sceneTitle.BackgroundTransparency = 1
sceneTitle.Font = Enum.Font.GothamBold
sceneTitle.Text = "Scene Projection"
sceneTitle.TextColor3 = Color3.fromRGB(238, 240, 244)
sceneTitle.TextSize = 16
sceneTitle.TextXAlignment = Enum.TextXAlignment.Left
sceneTitle.Parent = right

local sceneDetails = Instance.new("TextLabel")
sceneDetails.Name = "SceneDetails"
sceneDetails.Position = UDim2.fromOffset(14, 38)
sceneDetails.Size = UDim2.new(1, -28, 0, 62)
sceneDetails.BackgroundTransparency = 1
sceneDetails.Font = Enum.Font.Code
sceneDetails.TextColor3 = Color3.fromRGB(184, 191, 202)
sceneDetails.TextSize = 12
sceneDetails.TextWrapped = true
sceneDetails.TextXAlignment = Enum.TextXAlignment.Left
sceneDetails.TextYAlignment = Enum.TextYAlignment.Top
sceneDetails.Parent = right

local canvas = Instance.new("Frame")
canvas.Name = "SceneCanvas"
canvas.Position = UDim2.fromOffset(14, 106)
canvas.Size = UDim2.new(1, -28, 0, 250)
canvas.BackgroundColor3 = Color3.fromRGB(20, 23, 29)
canvas.BorderSizePixel = 0
canvas.ClipsDescendants = true
canvas.Parent = right

local canvasCorner = Instance.new("UICorner")
canvasCorner.CornerRadius = UDim.new(0, 6)
canvasCorner.Parent = canvas

local canvasHint = Instance.new("TextLabel")
canvasHint.Name = "CanvasHint"
canvasHint.Position = UDim2.fromOffset(10, 8)
canvasHint.Size = UDim2.new(1, -20, 0, 20)
canvasHint.BackgroundTransparency = 1
canvasHint.Font = Enum.Font.Gotham
canvasHint.Text = "Actor가 표시되면 토큰을 직접 선택하세요."
canvasHint.TextColor3 = Color3.fromRGB(125, 133, 146)
canvasHint.TextSize = 11
canvasHint.TextXAlignment = Enum.TextXAlignment.Left
canvasHint.Parent = canvas

local tokenButton = Instance.new("TextButton")
tokenButton.Name = "ProjectedToken"
tokenButton.AnchorPoint = Vector2.new(0.5, 0.5)
tokenButton.Size = UDim2.fromOffset(72, 72)
tokenButton.BackgroundColor3 = Color3.fromRGB(217, 184, 95)
tokenButton.BorderSizePixel = 0
tokenButton.Font = Enum.Font.GothamBold
tokenButton.Text = "TOKEN"
tokenButton.TextColor3 = Color3.fromRGB(25, 28, 34)
tokenButton.TextSize = 12
tokenButton.Visible = false
tokenButton.Parent = canvas

local tokenCorner = Instance.new("UICorner")
tokenCorner.CornerRadius = UDim.new(1, 0)
tokenCorner.Parent = tokenButton

local instruction = Instance.new("TextLabel")
instruction.Name = "Instruction"
instruction.Position = UDim2.fromOffset(14, 366)
instruction.Size = UDim2.new(1, -28, 0, 88)
instruction.BackgroundTransparency = 1
instruction.Font = Enum.Font.Gotham
instruction.Text = "순서: 왼쪽 1~6 실행 → Scene 토큰 선택 → 이동 실행 → saved 로그 확인 → Stop/Play → 복구 검증"
instruction.TextColor3 = Color3.fromRGB(184, 191, 202)
instruction.TextSize = 12
instruction.TextWrapped = true
instruction.TextXAlignment = Enum.TextXAlignment.Left
instruction.TextYAlignment = Enum.TextYAlignment.Top
instruction.Parent = right

local terminalResults: { [string]: any } = {}
local buttons: { [string]: TextButton } = {}
local selectedActorId: string? = nil
local busy = false
local render: () -> ()

client.Command.remotes.receipt.OnClientEvent:Connect(function(message)
	if type(message) ~= "table" or message.phase ~= "terminal" then
		return
	end
	if type(message.commandId) == "string" then
		terminalResults[message.commandId] = message.result
	end
end)

local function setOperation(message: string, failed: boolean?)
	operationLabel.Text = message
	operationLabel.TextColor3 = if failed == true
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

local function waitForRevision(targetRevision: number): boolean
	local deadline = os.clock() + COMMAND_TIMEOUT_SECONDS
	repeat
		if client.Replica.revision >= targetRevision then
			return true
		end
		task.wait(0.05)
	until os.clock() >= deadline
	return false
end

local function resultErrorCode(result: any): string
	if type(result) ~= "table" or type(result.error) ~= "table" then
		return "UNKNOWN"
	end
	return tostring(result.error.code)
end

local function submitCommand(commandType: string, payload: { [string]: unknown }): any
	for attempt = 1, 3 do
		setOperation(string.format("%s 실행 중 · attempt %d", commandType, attempt))
		local commandId = client.Command:submit(commandType, payload)
		local result = waitForTerminal(commandId)
		if result == nil then
			return nil
		end
		if result.ok == true then
			local value = result.value
			if type(value) == "table" and type(value.revision) == "number" then
				waitForRevision(value.revision)
			end
			return result
		end
		local code = resultErrorCode(result)
		if code ~= "STALE_REVISION" and code ~= "STALE_EPOCH" then
			return result
		end
		task.wait(0.75)
	end
	return nil
end

local function domainsFromPayload(): any
	local payload = client.Replica.payload
	if type(payload) ~= "table" or type(payload.domains) ~= "table" then
		return {}
	end
	return payload.domains
end

local function firstOwned(map: any, requiredStatus: string?): (string?, any?)
	if type(map) ~= "table" then
		return nil, nil
	end
	for id, value in map do
		if
			type(id) == "string"
			and type(value) == "table"
			and value.ownerUserId == player.UserId
			and (requiredStatus == nil or value.status == requiredStatus)
		then
			return id, value
		end
	end
	return nil, nil
end

local function currentState(): any
	local domains = domainsFromPayload()
	local session = if type(domains.session) == "table" then domains.session else {}
	local character = if type(domains.character) == "table" then domains.character else {}
	local scene = if type(domains.scene) == "table" then domains.scene else {}
	local userKey = tostring(player.UserId)
	local membership = if type(session.memberships) == "table"
		then session.memberships[userKey]
		else nil
	local selectedCharacterId = if type(session.selectedCharacter) == "table"
		then session.selectedCharacter[userKey]
		else nil
	local ready = type(session.ready) == "table" and session.ready[userKey] == true

	local activeCharacterId, activeCharacter = firstOwned(character.characters, "active")
	if
		type(selectedCharacterId) == "string"
		and type(character.characters) == "table"
		and type(character.characters[selectedCharacterId]) == "table"
		and character.characters[selectedCharacterId].ownerUserId == player.UserId
	then
		activeCharacterId = selectedCharacterId
		activeCharacter = character.characters[selectedCharacterId]
	end
	local draftId, draft = firstOwned(character.drafts, nil)
	local actor = if type(scene.actors) == "table" and type(activeCharacterId) == "string"
		then scene.actors[activeCharacterId]
		else nil
	local position = if type(actor) == "table" and type(actor.position) == "table"
		then actor.position
		else nil
	local moved = type(position) == "table"
		and type(position.x) == "number"
		and type(position.z) == "number"
		and (math.abs(position.x) > 0.01 or math.abs(position.z) > 0.01)

	return {
		membership = membership,
		roleReady = type(membership) == "table" and membership.role == "dm",
		draftId = draftId,
		draft = draft,
		characterId = activeCharacterId,
		character = activeCharacter,
		selectedCharacterId = selectedCharacterId,
		ready = ready,
		phase = session.phase,
		sessionSceneId = session.sceneId,
		activeSceneId = scene.activeSceneId,
		actor = actor,
		position = position,
		moved = moved,
	}
end

local function setButtonEnabled(button: TextButton, enabled: boolean)
	button.Active = enabled and not busy
	button.Selectable = enabled and not busy
	button.AutoButtonColor = enabled and not busy
	button.BackgroundColor3 = if enabled and not busy
		then Color3.fromRGB(72, 91, 122)
		else Color3.fromRGB(54, 59, 69)
	button.TextTransparency = if enabled and not busy then 0 else 0.45
end

local function runAction(action: () -> ())
	if busy then
		return
	end
	busy = true
	render()
	local succeeded, failure = xpcall(action, debug.traceback)
	busy = false
	if not succeeded then
		setOperation("Harness 오류: " .. tostring(failure), true)
	end
	render()
end

local function makeButton(key: string, text: string, y: number, action: () -> ())
	local button = Instance.new("TextButton")
	button.Name = key
	button.Position = UDim2.fromOffset(14, y)
	button.Size = UDim2.new(1, -28, 0, 34)
	button.BackgroundColor3 = Color3.fromRGB(72, 91, 122)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamMedium
	button.Text = text
	button.TextColor3 = Color3.fromRGB(238, 240, 244)
	button.TextSize = 13
	button.Parent = left
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 5)
	corner.Parent = button
	button.Activated:Connect(function()
		task.spawn(function()
			runAction(action)
		end)
	end)
	buttons[key] = button
end

local function reportResult(label: string, result: any)
	if result == nil then
		setOperation(label .. " 실패 · 응답 시간 초과", true)
	elseif result.ok == true then
		setOperation(label .. " 완료")
	else
		setOperation(label .. " 실패 · " .. resultErrorCode(result), true)
	end
end

makeButton("Join", "1. 세션 참가·DM 역할 갱신", 154, function()
	reportResult("세션 참가", submitCommand("session.join", {}))
end)

makeButton("Character", "2. 테스트 캐릭터 준비", 194, function()
	local state = currentState()
	if state.characterId ~= nil then
		setOperation("활성 Character가 이미 존재합니다.")
		return
	end
	local draftId = state.draftId
	if draftId == nil then
		local createResult = submitCommand("character.create_draft", { name = HERO_NAME })
		if createResult == nil or createResult.ok ~= true then
			reportResult("Character Draft 생성", createResult)
			return
		end
		local outcome = createResult.value.outcome
		if type(outcome) ~= "table" or type(outcome.id) ~= "string" then
			setOperation("Character Draft ID를 확인할 수 없습니다.", true)
			return
		end
		draftId = outcome.id
	end
	reportResult(
		"Character 활성화",
		submitCommand("character.activate", { characterId = draftId })
	)
end)

makeButton("Select", "3. Character 선택", 234, function()
	local state = currentState()
	if type(state.characterId) ~= "string" then
		setOperation("활성 Character가 필요합니다.", true)
		return
	end
	reportResult(
		"Character 선택",
		submitCommand("session.select_character", { characterId = state.characterId })
	)
end)

makeButton("Ready", "4. Ready", 274, function()
	reportResult("Ready", submitCommand("session.ready", { ready = true }))
end)

makeButton("Start", "5. Scene 시작", 314, function()
	reportResult("Scene 시작", submitCommand("session.start", { sceneId = SCENE_ID }))
end)

makeButton("Enter", "6. Scene 입장·Actor 생성", 354, function()
	local state = currentState()
	if type(state.characterId) ~= "string" then
		setOperation("선택된 Character가 필요합니다.", true)
		return
	end
	local sceneId = if type(state.sessionSceneId) == "string"
		then state.sessionSceneId
		else SCENE_ID
	reportResult(
		"Scene 입장",
		submitCommand("scene.enter", {
			sceneId = sceneId,
			actorId = state.characterId,
		})
	)
end)

makeButton("Move", "7. 선택 Token 서버 권위 이동", 394, function()
	local state = currentState()
	if type(state.actor) ~= "table" or state.actor.id ~= selectedActorId then
		setOperation("Scene Canvas에서 Token을 먼저 선택하세요.", true)
		return
	end
	local destination = MOVE_A
	if
		type(state.position) == "table"
		and type(state.position.x) == "number"
		and math.abs(state.position.x - MOVE_A.x) < 0.01
	then
		destination = MOVE_B
	end
	reportResult(
		"Token 이동",
		submitCommand("movement.commit", {
			actorId = state.actor.id,
			destination = destination,
		})
	)
end)

local verifyButton = Instance.new("TextButton")
verifyButton.Name = "VerifyRecovery"
verifyButton.Position = UDim2.fromOffset(14, 414)
verifyButton.Size = UDim2.new(1, -28, 0, 40)
verifyButton.BackgroundColor3 = Color3.fromRGB(72, 91, 122)
verifyButton.BorderSizePixel = 0
verifyButton.Font = Enum.Font.GothamBold
verifyButton.Text = "재실행 후 Character·Scene·Position 복구 검증"
verifyButton.TextColor3 = Color3.fromRGB(238, 240, 244)
verifyButton.TextSize = 12
verifyButton.Parent = right
local verifyCorner = Instance.new("UICorner")
verifyCorner.CornerRadius = UDim.new(0, 5)
verifyCorner.Parent = verifyButton
verifyButton.Activated:Connect(function()
	local state = currentState()
	local passed = state.roleReady
		and type(state.characterId) == "string"
		and state.selectedCharacterId == state.characterId
		and state.ready == true
		and state.phase == "active"
		and type(state.sessionSceneId) == "string"
		and type(state.actor) == "table"
		and state.moved == true
	if passed then
		setOperation("Reconnect Recovery PASS · Character·Scene·Position 확인")
		print("[RVTT Slice01] reconnect recovery PASS")
	else
		setOperation("Reconnect Recovery 미충족 · 왼쪽 단계와 Position을 확인하세요.", true)
	end
end)

local function pass(value: boolean): string
	return if value then "PASS" else "----"
end

render = function()
	local state = currentState()
	local joined = state.membership ~= nil
	local hasCharacter = type(state.characterId) == "string"
	local selected = hasCharacter and state.selectedCharacterId == state.characterId
	local active = state.phase == "active" and type(state.sessionSceneId) == "string"
	local entered = type(state.actor) == "table"
	local tokenSelected = entered and selectedActorId == state.actor.id

	statusLabel.Text = table.concat({
		string.format("[%s] Join·DM Role", pass(state.roleReady)),
		string.format("[%s] Active Character", pass(hasCharacter)),
		string.format("[%s] Character Select", pass(selected)),
		string.format("[%s] Ready", pass(state.ready == true)),
		string.format("[%s] Scene Active", pass(active)),
		string.format("[%s] Actor Projection", pass(entered)),
		string.format("[%s] Token Select", pass(tokenSelected)),
		string.format("[%s] Position Moved", pass(state.moved == true)),
	}, "\n")

	buttons.Join.Text = if state.roleReady
		then "1. 세션 참가·DM 역할 갱신 · PASS"
		else "1. 세션 참가·DM 역할 갱신"
	buttons.Character.Text = if hasCharacter
		then "2. 테스트 캐릭터 준비 · PASS"
		elseif state.draftId ~= nil
		then "2. Draft 활성화"
		else "2. 테스트 캐릭터 준비"
	buttons.Select.Text = if selected then "3. Character 선택 · PASS" else "3. Character 선택"
	buttons.Ready.Text = if state.ready == true then "4. Ready · PASS" else "4. Ready"
	buttons.Start.Text = if active then "5. Scene 시작 · PASS" else "5. Scene 시작"
	buttons.Enter.Text = if entered then "6. Scene 입장·Actor 생성 · PASS" else "6. Scene 입장·Actor 생성"
	buttons.Move.Text = if state.moved == true
		then "7. 선택 Token 서버 권위 이동 · PASS/재이동"
		else "7. 선택 Token 서버 권위 이동"

	setButtonEnabled(buttons.Join, not state.roleReady)
	setButtonEnabled(buttons.Character, joined and not hasCharacter)
	setButtonEnabled(buttons.Select, hasCharacter and not selected)
	setButtonEnabled(buttons.Ready, selected and state.ready ~= true)
	setButtonEnabled(buttons.Start, state.ready == true and not active)
	setButtonEnabled(buttons.Enter, active and selected and not entered)
	setButtonEnabled(buttons.Move, entered and tokenSelected)
	setButtonEnabled(verifyButton, active and entered and state.moved == true)

	local sceneId = if type(state.activeSceneId) == "string"
		then state.activeSceneId
		elseif type(state.sessionSceneId) == "string" then state.sessionSceneId
		else "none"
	local actorId = if type(state.actor) == "table" then tostring(state.actor.id) else "none"
	local positionText = "none"
	if
		type(state.position) == "table"
		and type(state.position.x) == "number"
		and type(state.position.y) == "number"
		and type(state.position.z) == "number"
	then
		positionText = string.format(
			"(%.1f, %.1f, %.1f)",
			state.position.x,
			state.position.y,
			state.position.z
		)
	end
	sceneDetails.Text = string.format(
		"scene=%s\nactor=%s\nposition=%s · revision=%d",
		sceneId,
		actorId,
		positionText,
		client.Replica.revision
	)

	if entered then
		local x = math.clamp((state.position.x + 20) / 64, 0.12, 0.88)
		local y = math.clamp((state.position.z + 20) / 56, 0.22, 0.86)
		tokenButton.Position = UDim2.fromScale(x, y)
		tokenButton.Visible = true
		tokenButton.Text = if tokenSelected then "TOKEN\nSELECTED" else "TOKEN\nCLICK"
		tokenButton.BackgroundColor3 = if tokenSelected
			then Color3.fromRGB(98, 169, 230)
			else Color3.fromRGB(217, 184, 95)
	else
		tokenButton.Visible = false
		selectedActorId = nil
	end
end

tokenButton.Activated:Connect(function()
	local state = currentState()
	if type(state.actor) ~= "table" or type(state.actor.id) ~= "string" then
		return
	end
	selectedActorId = state.actor.id
	setOperation("Token 선택 완료 · 이동 버튼을 실행하세요.")
	render()
end)

client.Replica.Changed:Connect(function()
	render()
end)

render()
print("[RVTT Slice01] acceptance harness ready")
