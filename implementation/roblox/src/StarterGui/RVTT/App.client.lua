--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

if ReplicatedStorage:FindFirstChild("RVTT_TestMode") ~= nil then
	return
end

local player = Players.LocalPlayer
local SharedUI = ReplicatedStorage.RVTT.Shared.UI
local Tokens = require(SharedUI.DesignTokens)
local CharacterSheetViewModel = require(SharedUI.CharacterSheetViewModel)
local DiceNoticeViewModel = require(SharedUI.DiceNoticeViewModel)
local GameplayHudViewModel = require(SharedUI.GameplayHudViewModel)
local EntryRecoveryViewModel = require(SharedUI.EntryRecoveryViewModel)
local ManagementViewModel = require(SharedUI.ManagementViewModel)
local DmToolRegistry = require(SharedUI.DmToolRegistry)
local DmWindowHost = require(SharedUI.DmWindowHost)
local uiFolder = script.Parent.UI
local AppShell = require(uiFolder.AppShell)
local ThemeApplicator = require(uiFolder.ThemeApplicator)
local SettingsPanel = require(uiFolder.Components.SettingsPanel)
local GameplayHud = require(uiFolder.Components.GameplayHud)
local ManagementPanel = require(uiFolder.Components.ManagementPanel)
local EntryRecoveryPanel = require(uiFolder.Components.EntryRecoveryPanel)
local DmWorkspacePanel = require(uiFolder.Components.DmWorkspacePanel)
local OfficialCharacterSheet = require(uiFolder.Components.OfficialCharacterSheet)
local DiceSlotRevealNotice = require(uiFolder.Components.DiceSlotRevealNotice)
local components = uiFolder.Components

local playerScripts = player:WaitForChild("PlayerScripts")
local clientFolder = playerScripts:WaitForChild("RVTT"):WaitForChild("Client")
local ClientRuntime = require(clientFolder:WaitForChild("ClientRuntime"))
local client = ClientRuntime.await()

local gui = Instance.new("ScreenGui")
gui.Name = "RVTT_App"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 0
gui.Parent = player:WaitForChild("PlayerGui")
local shell = AppShell.new(gui)
local dmRegistry = DmToolRegistry.new()
DmWorkspacePanel.registerDefaults(dmRegistry)
local dmWindowHost = DmWindowHost.new(dmRegistry)
local dmWorkspacePanel = DmWorkspacePanel.new(
	shell:getLayer("Dm"),
	dmRegistry,
	dmWindowHost,
	client.ViewerPreview,
	client.Preferences,
	function(commandType: string, payload: any): string
		return client.Command:submit(commandType, payload)
	end
)

local banner = require(components.StateBanner)()
banner.Parent = shell:getLayer("System")

local prompt = require(components.ActionPrompt)()
prompt.Parent = shell:getLayer("Prompt")
local promptText = prompt:FindFirstChildWhichIsA("TextLabel")

local settingsButton = Instance.new("TextButton")
settingsButton.Name = "SettingsButton"
settingsButton.Size = UDim2.fromOffset(116, 40)
settingsButton.Position = UDim2.new(1, -132, 0, 16)
settingsButton.AutoButtonColor = false
settingsButton.Text = "설정"
settingsButton.TextSize = Tokens.TextSize.Body
settingsButton.BorderSizePixel = 0
settingsButton.Selectable = true
settingsButton.SelectionOrder = 1
settingsButton:SetAttribute("RVTTBackgroundToken", "accent")
settingsButton:SetAttribute("RVTTTextToken", "accentOn")
settingsButton.Parent = shell:getLayer("System")

local settingsCorner = Instance.new("UICorner")
settingsCorner.CornerRadius = Tokens.Radius.SM
settingsCorner.Parent = settingsButton
local settingsStroke = Instance.new("UIStroke")
settingsStroke.Thickness = 1
settingsStroke.Transparency = 0.12
settingsStroke:SetAttribute("RVTTStrokeToken", "focus")
settingsStroke.Parent = settingsButton

local settingsContextActive = false
local managementContextActive = false
local characterSheetContextActive = false
local managementReturnSurface = "gameplay"
local managementCommands: { [string]: any } = {}
local managementAwaitingRevision: number? = nil
local characterSheetCommands: { [string]: any } = {}
local characterSheetFeedback =
	CharacterSheetViewModel.initialFeedback(client.Replica.revision, client.Replica.epoch)
local diceNoticeState = DiceNoticeViewModel.initial(client.Replica.epoch)
local entryCommandId: string? = nil
local entryAwaitingRevision: number? = nil
local entryError: any = nil
local lastAuthorityEpoch = client.Replica.epoch
local feedback = GameplayHudViewModel.initialFeedback(client.Replica.revision)
local rawPreview = client.WorldTokens.Input:getCurrentPreview()
local currentHudState: any = nil
local settingsPanel: any
local gameplayHud: any
local managementPanel: any
local characterSheet: any
local diceNotice: any
local entryRecoveryPanel: any
local setSettingsVisible: (boolean) -> ()
local setManagementVisible: (boolean, string?) -> ()
local setCharacterSheetVisible: (boolean) -> ()
local renderHud: () -> ()
local renderManagement: () -> ()
local renderCharacterSheet: () -> ()
local renderEntryRecovery: () -> ()
local renderDiceNotices: () -> ()

local function applyPreferences()
	local preferences = client.Preferences:snapshot()
	ThemeApplicator.apply(shell.Root, preferences)
	if settingsPanel ~= nil then
		settingsPanel:setPreferences(preferences)
	end
	if characterSheet ~= nil then
		ThemeApplicator.apply(characterSheet.Root, preferences)
	end
	ThemeApplicator.apply(dmWorkspacePanel.Root, preferences)
end

local function updatePrompt(settingsVisible: boolean)
	if promptText == nil then
		return
	end
	if settingsVisible then
		promptText.Text = "Q 설정 닫기"
	elseif characterSheet ~= nil and characterSheet.Root.Visible then
		promptText.Text = "Q 캐릭터 시트 닫기"
	elseif managementPanel ~= nil and managementPanel.Root.Visible then
		promptText.Text = "Q 캐릭터 콘솔 닫기"
	elseif currentHudState ~= nil and currentHudState.preview ~= nil then
		promptText.Text = currentHudState.preview.enabled
				and "좌클릭 " .. currentHudState.preview.label .. " · 우클릭 행동"
			or currentHudState.preview.disabledReason
			or "현재 실행할 수 없습니다"
	else
		promptText.Text = "좌클릭 선택·기본 행동    우클릭 행동"
	end
end

local function submitManagement(intent: any?, errorCode: string?)
	if intent == nil then
		managementPanel:setFeedback(errorCode or "요청을 만들 수 없습니다", "warning")
		ThemeApplicator.apply(managementPanel.Root, client.Preferences:snapshot())
		return
	end
	local commandId = client.Command:submit(intent.commandType, intent.payload)
	managementCommands[commandId] = { baseRevision = client.Replica.revision }
	managementPanel:setPending(true)
	managementPanel:setFeedback("서버 응답 대기 중", "pending")
	ThemeApplicator.apply(managementPanel.Root, client.Preferences:snapshot())
end

setSettingsVisible = function(visible: boolean)
	if visible and characterSheet ~= nil and characterSheet.Root.Visible then
		setCharacterSheetVisible(false)
	end
	if visible and managementPanel ~= nil and managementPanel.Root.Visible then
		setManagementVisible(false)
	end
	settingsPanel:setVisible(visible)
	updatePrompt(visible)
	settingsButton:SetAttribute(
		"RVTTBackgroundToken",
		if visible then "accentPressed" else "accent"
	)
	ThemeApplicator.apply(settingsButton, client.Preferences:snapshot())

	if visible and not settingsContextActive then
		settingsContextActive = true
		client.Input:push("settings_modal", 100, {
			Cancel = function()
				setSettingsVisible(false)
				return true
			end,
			Confirm = function()
				return false
			end,
		})
	elseif not visible and settingsContextActive then
		settingsContextActive = false
		client.Input:remove("settings_modal")
	end
end

settingsPanel = SettingsPanel.new(function(key: string, value: any)
	client.Preferences:set(key, value)
end, function(key: string)
	client.Preferences:reset(key)
end, function()
	client.Preferences:resetAll()
end, function()
	setSettingsVisible(false)
end)
settingsPanel.Root.Parent = shell:getLayer("Overlay")

entryRecoveryPanel = EntryRecoveryPanel.new(function()
	local view = EntryRecoveryViewModel.build(
		client.Replica.payload,
		player.UserId,
		entryError or client.Recovery:snapshot(),
		entryCommandId ~= nil or entryAwaitingRevision ~= nil
	)
	local intent = EntryRecoveryViewModel.readyIntent(view, true)
	if intent == nil then
		return
	end
	entryCommandId = client.Command:submit(intent.commandType, intent.payload)
	renderEntryRecovery()
end, function()
	client.Recovery:retry()
end)
entryRecoveryPanel.EntryRoot.Parent = shell:getLayer("Session")
entryRecoveryPanel.RecoveryRoot.Parent = shell:getLayer("Recovery")

renderEntryRecovery = function()
	local view = EntryRecoveryViewModel.build(
		client.Replica.payload,
		player.UserId,
		entryError or client.Recovery:snapshot(),
		entryCommandId ~= nil or entryAwaitingRevision ~= nil
	)
	entryRecoveryPanel:render(view)
	ThemeApplicator.apply(entryRecoveryPanel.EntryRoot, client.Preferences:snapshot())
	ThemeApplicator.apply(entryRecoveryPanel.RecoveryRoot, client.Preferences:snapshot())
end

managementPanel = ManagementPanel.new(function()
	setManagementVisible(false)
end, function(itemId: string, revision: number)
	local intent, errorCode =
		ManagementViewModel.moveIntent(managementPanel.state, itemId, revision)
	submitManagement(intent, errorCode)
end, function(title: string, body: string, revision: number)
	local intent, errorCode =
		ManagementViewModel.createDocumentIntent(managementPanel.state, title, body, revision)
	submitManagement(intent, errorCode)
end, function(documentId: string, title: string, body: string, revision: number)
	local intent, errorCode = ManagementViewModel.editDocumentIntent(
		managementPanel.state,
		documentId,
		title,
		body,
		revision
	)
	submitManagement(intent, errorCode)
end)
managementPanel.Root.Parent = shell:getLayer("Management")

renderManagement = function()
	local prior = managementPanel.state
	local selection = if type(prior) == "table"
		then { itemId = prior.selectedItemId, documentId = prior.selectedDocumentId }
		else nil
	local state = ManagementViewModel.build(
		client.Replica.payload,
		player.UserId,
		client.WorldTokens.Renderer:getSelectedActorId(),
		client.Replica.revision,
		selection
	)
	managementPanel:render(state)
	if
		managementAwaitingRevision ~= nil
		and client.Replica.revision >= managementAwaitingRevision
	then
		managementAwaitingRevision = nil
		managementPanel.draft = false
		managementPanel:setPending(false)
		managementPanel:setFeedback("권한 상태에 반영되었습니다", "success")
	end
	ThemeApplicator.apply(managementPanel.Root, client.Preferences:snapshot())
end

setManagementVisible = function(visible: boolean, tab: string?)
	if visible then
		setSettingsVisible(false)
		if characterSheet ~= nil and characterSheet.Root.Visible then
			setCharacterSheetVisible(false)
		end
		managementReturnSurface = shell.surface
		if not shell:setSurface("management") then
			return
		end
		renderManagement()
		managementPanel:setVisible(true, tab)
	else
		managementPanel:setVisible(false)
		shell:setSurface(managementReturnSurface)
	end
	updatePrompt(settingsPanel:isVisible())
	if visible and not managementContextActive then
		managementContextActive = true
		client.Input:push("management_surface", 80, {
			Cancel = function()
				setManagementVisible(false)
				return true
			end,
			Confirm = function()
				return false
			end,
		})
	elseif not visible and managementContextActive then
		managementContextActive = false
		client.Input:remove("management_surface")
	end
end

local function submitCharacterSheet(actionId: string, candidateRevision: number)
	local intent, errorCode =
		CharacterSheetViewModel.actionIntent(characterSheet.state, actionId, candidateRevision)
	if intent == nil then
		characterSheetFeedback = CharacterSheetViewModel.resolveReceipt(
			CharacterSheetViewModel.pendingFeedback(
				actionId,
				"local-rejected",
				candidateRevision,
				client.Replica.epoch
			),
			false,
			errorCode,
			nil
		)
		renderCharacterSheet()
		return
	end
	local commandId = client.Command:submit(intent.commandType, intent.payload)
	local pending = CharacterSheetViewModel.pendingFeedback(
		actionId,
		commandId,
		candidateRevision,
		client.Replica.epoch
	)
	characterSheetCommands[commandId] = {
		actionId = actionId,
		baseRevision = candidateRevision,
		feedback = pending,
	}
	characterSheetFeedback = pending
	renderCharacterSheet()
end

characterSheet = OfficialCharacterSheet.new(shell:getLayer("Overlay"), function()
	setCharacterSheetVisible(false)
end, submitCharacterSheet)

diceNotice = DiceSlotRevealNotice.new(shell:getLayer("Toast"), function(rollId: string)
	diceNoticeState = DiceNoticeViewModel.complete(diceNoticeState, rollId)
	renderDiceNotices()
end)

renderDiceNotices = function()
	local payload = client.Replica.payload
	local domains = if type(payload) == "table" then (payload :: any).domains else nil
	local encounter = if type(domains) == "table" then domains.encounter else nil
	local initiativeVisible = type(encounter) == "table" and type(encounter.active) == "table"
	local preferences = client.Preferences:snapshot()
	diceNotice:render(diceNoticeState, preferences.motion ~= "full", initiativeVisible)
	ThemeApplicator.apply(diceNotice.Root, preferences)
end

renderCharacterSheet = function()
	local state = CharacterSheetViewModel.build(
		client.Replica.payload,
		client.Replica.revision,
		characterSheetFeedback,
		shell.Root.AbsoluteSize.X
	)
	characterSheet:render(state)
	if characterSheet.Root.Visible and state.canReadFullSheet ~= true then
		setCharacterSheetVisible(false)
	end
	ThemeApplicator.apply(characterSheet.Root, client.Preferences:snapshot())
end

setCharacterSheetVisible = function(visible: boolean)
	if visible then
		setSettingsVisible(false)
		if managementPanel.Root.Visible then
			setManagementVisible(false)
		end
		renderCharacterSheet()
		characterSheet:setVisible(true)
	else
		characterSheet:setVisible(false)
	end
	updatePrompt(settingsPanel:isVisible())
	if visible and characterSheet.Root.Visible and not characterSheetContextActive then
		characterSheetContextActive = true
		client.Input:push("character_sheet_surface", 85, {
			Cancel = function()
				setCharacterSheetVisible(false)
				return true
			end,
			Confirm = function()
				return false
			end,
		})
	elseif (not visible or not characterSheet.Root.Visible) and characterSheetContextActive then
		characterSheetContextActive = false
		client.Input:remove("character_sheet_surface")
	end
end

gameplayHud = GameplayHud.new(shell:getLayer("Gameplay"), shell:getLayer("Toast"), function()
	if
		currentHudState == nil
		or currentHudState.canEndTurn ~= true
		or feedback.state == "pending"
	then
		return
	end
	local baseRevision = client.Replica.revision
	local commandId = client.Command:submit("encounter.end_turn", {})
	feedback = GameplayHudViewModel.pendingFeedback("end_turn", commandId, baseRevision)
	renderHud()
end, function()
	setManagementVisible(true, "inventory")
end, function()
	setManagementVisible(true, "journal")
end, function()
	setCharacterSheetVisible(true)
end)

renderHud = function()
	local selectedActorId = client.WorldTokens.Renderer:getSelectedActorId()
	local preview = GameplayHudViewModel.preview(
		client.Replica.payload,
		selectedActorId,
		rawPreview,
		client.Replica.revision
	)
	currentHudState = GameplayHudViewModel.build(
		client.Replica.payload,
		player.UserId,
		selectedActorId,
		client.Replica.revision,
		preview,
		feedback
	)
	gameplayHud:render(currentHudState)
	updatePrompt(settingsPanel:isVisible())
	local preferences = client.Preferences:snapshot()
	ThemeApplicator.apply(gameplayHud.Root, preferences)
	ThemeApplicator.apply(gameplayHud.Initiative, preferences)
	ThemeApplicator.apply(gameplayHud.Toast, preferences)
end

client.Preferences.Changed:Connect(function()
	applyPreferences()
	renderEntryRecovery()
	renderHud()
	renderDiceNotices()
	if managementPanel.Root.Visible then
		renderManagement()
	end
end)
applyPreferences()

settingsButton.Activated:Connect(function()
	setSettingsVisible(not settingsPanel:isVisible())
end)
settingsButton.MouseEnter:Connect(function()
	if not settingsPanel:isVisible() then
		settingsButton:SetAttribute("RVTTBackgroundToken", "accentHover")
		ThemeApplicator.apply(settingsButton, client.Preferences:snapshot())
	end
end)
settingsButton.MouseLeave:Connect(function()
	settingsButton:SetAttribute(
		"RVTTBackgroundToken",
		if settingsPanel:isVisible() then "accentPressed" else "accent"
	)
	ThemeApplicator.apply(settingsButton, client.Preferences:snapshot())
end)

local function render(payload: any, envelope: any)
	local envelopeEpoch = if type(envelope) == "table" then envelope.authorityEpoch else nil
	local projectionEpoch = if type(envelopeEpoch) == "string"
		then envelopeEpoch
		else client.Replica.epoch
	local revision = if type(envelope) == "table" and type(envelope.revision) == "number"
		then envelope.revision
		else client.Replica.revision
	if type(envelopeEpoch) == "string" and envelopeEpoch ~= lastAuthorityEpoch then
		lastAuthorityEpoch = envelopeEpoch
		entryCommandId = nil
		entryAwaitingRevision = nil
		entryError = nil
		managementCommands = {}
		managementAwaitingRevision = nil
		characterSheetCommands = {}
		characterSheetFeedback = CharacterSheetViewModel.initialFeedback(revision, envelopeEpoch)
	end
	shell:applyProjection(payload, player.UserId)
	local selectedActorId = client.WorldTokens.Renderer:getSelectedActorId()
	if EntryRecoveryViewModel.validSelection(payload, player.UserId, selectedActorId) == nil then
		client.WorldTokens.Renderer:setSelected(nil)
	end

	local domains = if type(payload) == "table" then payload.domains else nil
	local session = if type(domains) == "table" then domains.session else nil
	local phase = if type(session) == "table" and type(session.phase) == "string"
		then session.phase
		else "loading"
	banner.Text = string.format(
		"RVTT · %s · %s · %s · revision %d",
		shell.role,
		shell.mode,
		phase,
		revision
	)
	feedback = GameplayHudViewModel.reconcileFeedback(feedback, revision)
	local sheetProjection = if type(payload) == "table" then payload.characterSheet else nil
	characterSheetFeedback = CharacterSheetViewModel.reconcile(
		characterSheetFeedback,
		sheetProjection,
		revision,
		envelopeEpoch
	)
	local projectedDiceNotices = if type(payload) == "table" then payload.diceNotices else nil
	diceNoticeState =
		DiceNoticeViewModel.reconcile(diceNoticeState, projectedDiceNotices, projectionEpoch)
	if entryAwaitingRevision ~= nil and revision >= entryAwaitingRevision then
		entryAwaitingRevision = nil
		entryError = nil
	end
	renderEntryRecovery()
	renderHud()
	renderDiceNotices()
	if managementPanel.Root.Visible then
		if shell.surface == "management" then
			renderManagement()
		else
			managementPanel:setVisible(false)
			if managementContextActive then
				managementContextActive = false
				client.Input:remove("management_surface")
			end
		end
	end
	if characterSheet.Root.Visible then
		renderCharacterSheet()
	end
	dmWorkspacePanel:render(payload, player.UserId, revision)
	ThemeApplicator.apply(dmWorkspacePanel.Root, client.Preferences:snapshot())
end

client.WorldTokens.SelectionChanged:Connect(function()
	renderHud()
	if managementPanel.Root.Visible then
		renderManagement()
	end
end)
client.WorldTokens.PreviewChanged:Connect(function(value)
	rawPreview = value
	renderHud()
end)
client.WorldTokens.ContextActionRequested:Connect(function(action, commandId, baseRevision)
	feedback = GameplayHudViewModel.pendingFeedback(action.kind, commandId, baseRevision)
	renderHud()
end)
client.Command.Received:Connect(function(message)
	dmWorkspacePanel:onReceipt(message)
	if
		type(message) == "table"
		and message.phase == "terminal"
		and characterSheetCommands[message.commandId] ~= nil
	then
		local commandRecord = characterSheetCommands[message.commandId]
		characterSheetCommands[message.commandId] = nil
		local result = message.result
		local code = if type(result) == "table" and type(result.error) == "table"
			then result.error.code
			else nil
		local resultRevision = if type(result) == "table"
				and type(result.value) == "table"
				and type(result.value.revision) == "number"
			then result.value.revision
			else nil
		local resolvedFeedback = CharacterSheetViewModel.resolveMatchingReceipt(
			characterSheetFeedback,
			commandRecord.feedback,
			message.commandId,
			type(result) == "table" and result.ok == true,
			code,
			resultRevision
		)
		if resolvedFeedback ~= characterSheetFeedback then
			characterSheetFeedback = resolvedFeedback
			renderCharacterSheet()
		end
		return
	end
	if
		type(message) == "table"
		and message.phase == "terminal"
		and message.commandId == entryCommandId
	then
		entryCommandId = nil
		local result = message.result
		if type(result) == "table" and result.ok == true then
			entryAwaitingRevision = if type(result.value) == "table"
					and type(result.value.revision) == "number"
				then result.value.revision
				else client.Replica.revision + 1
		else
			entryAwaitingRevision = nil
			local code = if type(result) == "table" and type(result.error) == "table"
				then result.error.code
				else nil
			entryError = EntryRecoveryViewModel.safeError(code)
		end
		renderEntryRecovery()
		return
	end
	if
		type(message) == "table"
		and message.phase == "terminal"
		and managementCommands[message.commandId]
	then
		local record = managementCommands[message.commandId]
		managementCommands[message.commandId] = nil
		local result = message.result
		if type(result) == "table" and result.ok == true then
			local resultRevision = if type(result.value) == "table"
					and type(result.value.revision) == "number"
				then result.value.revision
				else record.baseRevision + 1
			managementAwaitingRevision = resultRevision
			managementPanel:setFeedback("서버 승인 · Projection 반영 대기", "pending")
		else
			local errorCode = if type(result) == "table" and type(result.error) == "table"
				then result.error.code
				else "UNKNOWN_ERROR"
			managementPanel:setFeedback("요청 실패 · " .. tostring(errorCode), "danger")
			managementPanel:setPending(false)
		end
		ThemeApplicator.apply(managementPanel.Root, client.Preferences:snapshot())
		return
	end
	if
		type(message) ~= "table"
		or message.phase ~= "terminal"
		or message.commandId ~= feedback.commandId
		or type(message.result) ~= "table"
	then
		return
	end
	local result = message.result
	local code = if type(result.error) == "table" then result.error.code else nil
	local resultRevision = if type(result.value) == "table"
			and type(result.value.revision) == "number"
		then result.value.revision
		else nil
	feedback =
		GameplayHudViewModel.resolveFeedback(feedback, result.ok == true, code, resultRevision)
	renderHud()
end)

client.Recovery.Changed:Connect(function(state)
	if state.state == "rebuilding" or state.state == "recovery" then
		entryCommandId = nil
		entryAwaitingRevision = nil
		entryError = nil
		managementCommands = {}
		managementAwaitingRevision = nil
		managementPanel:setPending(false)
		characterSheetCommands = {}
		characterSheetFeedback =
			CharacterSheetViewModel.initialFeedback(client.Replica.revision, client.Replica.epoch)
		diceNoticeState = DiceNoticeViewModel.suspend(diceNoticeState, client.Replica.epoch)
		renderDiceNotices()
		setCharacterSheetVisible(false)
		client.ViewerPreview:invalidate()
		dmWorkspacePanel:purgeLocalState()
	elseif state.state == "recovered" then
		entryError = nil
	end
	renderEntryRecovery()
end)

client.Replica.Changed:Connect(render)
render(client.Replica.payload, { revision = client.Replica.revision })

client.Input:push("base_hud", 10, {
	Cancel = function()
		return false
	end,
	Confirm = function()
		return false
	end,
})

client.Input:push("dm_workspace", 70, {
	Cancel = function()
		if dmWorkspacePanel.Root.Visible then
			return dmWorkspacePanel:cancelTopContext()
		end
		return false
	end,
	Confirm = function()
		return false
	end,
})
