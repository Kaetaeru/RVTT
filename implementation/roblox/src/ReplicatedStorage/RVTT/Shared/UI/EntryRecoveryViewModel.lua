--!strict

local ViewState = require(script.Parent.ViewState)

local EntryRecoveryViewModel = {}

local safeErrors: { [string]: { state: string, message: string, retryable: boolean } } = {
	STALE_EPOCH = {
		state = ViewState.STALE,
		message = "세션 상태가 변경되었습니다",
		retryable = true,
	},
	STALE_REVISION = {
		state = ViewState.STALE,
		message = "최신 상태를 다시 불러와야 합니다",
		retryable = true,
	},
	UNAUTHORIZED = {
		state = ViewState.PERMISSION_DENIED,
		message = "이 작업을 수행할 권한이 없습니다",
		retryable = false,
	},
	VALIDATION_FAILED = {
		state = ViewState.VALIDATION_ERROR,
		message = "입력값을 확인해 주세요",
		retryable = false,
	},
	CONFLICT = {
		state = ViewState.CONFLICT,
		message = "현재 세션 상태와 요청이 충돌했습니다",
		retryable = true,
	},
	CLIENT_TIMEOUT = {
		state = ViewState.NETWORK_ERROR,
		message = "서버 응답을 받지 못했습니다",
		retryable = true,
	},
}

local function domainsOf(payload: any): any
	return if type(payload) == "table" and type(payload.domains) == "table"
		then payload.domains
		else {}
end

local function membershipOf(domains: any, userId: number): any
	local session = domains.session
	local memberships = if type(session) == "table" then session.memberships else nil
	return if type(memberships) == "table" then memberships[tostring(userId)] else nil
end

function EntryRecoveryViewModel.safeError(code: any): any
	local record = if type(code) == "string" then safeErrors[code] else nil
	if record ~= nil then
		return table.clone(record)
	end
	return {
		state = ViewState.FATAL,
		message = "복구할 수 없는 오류가 발생했습니다",
		retryable = false,
	}
end

function EntryRecoveryViewModel.build(
	payload: any,
	userId: number,
	recovery: any?,
	pending: boolean?
): any
	local domains = domainsOf(payload)
	local session = domains.session
	local membership = membershipOf(domains, userId)
	local role = if type(membership) == "table"
			and (membership.role == "dm" or membership.role == "player")
		then membership.role
		else "observer"
	local key = tostring(userId)
	local selected = if type(session) == "table"
			and type(session.selectedCharacter) == "table"
		then session.selectedCharacter[key]
		else nil
	local connection = if type(session) == "table" and type(session.connections) == "table"
		then session.connections[key]
		else nil
	local phase = if type(session) == "table" and type(session.phase) == "string"
		then session.phase
		else "loading"
	local authoritativeReady = role == "player"
		and type(session) == "table"
		and type(session.ready) == "table"
		and session.ready[key] == true
	local recoveryState = if type(recovery) == "table" and type(recovery.state) == "string"
		then recovery.state
		else ViewState.READY
	local state = recoveryState
	if phase == "loading" then
		state = ViewState.LOADING
	elseif pending == true and recoveryState == ViewState.READY then
		state = ViewState.PENDING
	end

	local canReady = state == ViewState.READY
		and role == "player"
		and type(selected) == "string"
		and connection == "connected"
		and phase == "lobby"

	return {
		state = state,
		role = role,
		phase = phase,
		connected = connection == "connected",
		selectedCharacterId = selected,
		ready = authoritativeReady,
		canReady = canReady,
		canEnterGameplay = role ~= "observer" and phase == "active" and state == ViewState.READY,
		message = if type(recovery) == "table" then recovery.message else nil,
		retryable = type(recovery) == "table" and recovery.retryable == true,
	}
end

function EntryRecoveryViewModel.readyIntent(view: any, ready: boolean): (any?, string?)
	if type(view) ~= "table" or view.canReady ~= true then
		return nil, "NOT_READY"
	end
	return { commandType = "session.ready", payload = { ready = ready } }, nil
end

function EntryRecoveryViewModel.validSelection(payload: any, userId: number, actorId: any): string?
	if type(actorId) ~= "string" then
		return nil
	end
	local domains = domainsOf(payload)
	local membership = membershipOf(domains, userId)
	local role = if type(membership) == "table" then membership.role else "observer"
	local scene = domains.scene
	local actors = if type(scene) == "table" then scene.actors else nil
	local actor = if type(actors) == "table" then actors[actorId] else nil
	if type(actor) ~= "table" then
		return nil
	end
	if role == "dm" or actor.ownerUserId == userId or actor.controllerUserId == userId then
		return actorId
	end
	return nil
end

return table.freeze(EntryRecoveryViewModel)
