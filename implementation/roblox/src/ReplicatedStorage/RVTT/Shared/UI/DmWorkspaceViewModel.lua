--!strict

local DmWorkspaceViewModel = {}

local COMMANDS = table.freeze({
	ASSIGN_CONTROL = "dm.assign_control",
	QUICK_ACTION = "dm.quick_action",
	RUNTIME_PATCH = "dm.runtime_patch",
	REQUEST_RECOVERY = "dm.request_recovery",
})
DmWorkspaceViewModel.Commands = COMMANDS

local MAX_TERMINAL_FEEDBACK = 8
DmWorkspaceViewModel.MaxTerminalFeedback = MAX_TERMINAL_FEEDBACK

local SAFE_FAILURE_CODES: { [string]: boolean } = table.freeze({
	UNAUTHORIZED = true,
	PERMISSION_DENIED = true,
	STALE_EPOCH = true,
	STALE_REVISION = true,
	VALIDATION_FAILED = true,
	CLIENT_TIMEOUT = true,
	TIMEOUT = true,
	CONFLICT = true,
	EXPIRED = true,
	OPPORTUNITY_EXPIRED = true,
	NETWORK_ERROR = true,
})

function DmWorkspaceViewModel.safeFailureCode(code: any): string
	return if type(code) == "string" and SAFE_FAILURE_CODES[code] == true
		then code
		else "COMMAND_FAILED"
end

function DmWorkspaceViewModel.pruneTerminalFeedback(pending: any): any
	local failures = {}
	for commandId, record in pending do
		if type(record) == "table" and record.terminalFailure == true then
			table.insert(failures, {
				commandId = commandId,
				createdAt = if type(record.createdAt) == "number" then record.createdAt else 0,
			})
		end
	end
	table.sort(failures, function(left, right)
		if left.createdAt ~= right.createdAt then
			return left.createdAt > right.createdAt
		end
		return left.commandId > right.commandId
	end)
	for index = MAX_TERMINAL_FEEDBACK + 1, #failures do
		pending[failures[index].commandId] = nil
	end
	return pending
end

local function domainsOf(payload: any): any
	return if type(payload) == "table" and type(payload.domains) == "table"
		then payload.domains
		else {}
end

local function roleOf(domains: any, userId: number): string
	local session = domains.session
	local membership = if type(session) == "table" and type(session.memberships) == "table"
		then session.memberships[tostring(userId)]
		else nil
	return if type(membership) == "table" and type(membership.role) == "string"
		then membership.role
		else "observer"
end

local function appendQueue(
	rows: { any },
	id: string,
	kind: string,
	record: any,
	revision: number,
	commandId: string?
)
	table.insert(rows, {
		id = id,
		kind = kind,
		createdAt = if type(record.createdAt) == "number" then record.createdAt else 0,
		revision = if type(record.revision) == "number" then record.revision else revision,
		status = "projection_confirmed",
		commandId = commandId or record.commandId,
		target = record.target or record.targetId or record.actionId,
	})
end

function DmWorkspaceViewModel.build(
	payload: any,
	userId: number,
	revision: number,
	pending: any?
): any
	local domains = domainsOf(payload)
	if roleOf(domains, userId) ~= "dm" then
		return { visible = false, role = roleOf(domains, userId), queue = {}, viewers = {} }
	end
	local workspace = domains.dm_workspace
	if type(workspace) ~= "table" then
		return { visible = false, role = "dm", queue = {}, viewers = {} }
	end

	local rows = {}
	for _, record in workspace.quickActions or {} do
		if type(record) == "table" and type(record.commandId) == "string" then
			appendQueue(rows, "quick:" .. record.commandId, "quick_action", record, revision, nil)
		end
	end
	for targetId, record in workspace.runtimePatches or {} do
		if type(record) == "table" then
			appendQueue(
				rows,
				"patch:" .. tostring(targetId),
				"runtime_patch",
				record,
				revision,
				nil
			)
		end
	end
	for requestId, record in workspace.recoveryRequests or {} do
		if type(record) == "table" then
			local stableId = tostring(requestId)
			local commandId = if string.sub(stableId, 1, 9) == "recovery:"
				then string.sub(stableId, 10)
				else nil
			appendQueue(rows, stableId, "recovery", record, revision, commandId)
		end
	end

	local confirmedCommands = {}
	for _, row in rows do
		if type(row.commandId) == "string" then
			confirmedCommands[row.commandId] = true
		end
	end
	for commandId, record in pending or {} do
		local controlConfirmed = record.commandType == COMMANDS.ASSIGN_CONTROL
			and record.accepted == true
			and type(record.baseRevision) == "number"
			and revision > record.baseRevision
			and type(record.expectedActorId) == "string"
			and type(record.expectedControllerUserId) == "number"
			and type(workspace.control) == "table"
			and workspace.control[record.expectedActorId] == record.expectedControllerUserId
		if confirmedCommands[commandId] ~= true and controlConfirmed then
			table.insert(rows, {
				id = "control:" .. commandId,
				kind = "assign_control",
				createdAt = record.createdAt or 0,
				revision = revision,
				status = "projection_confirmed",
				commandId = commandId,
				target = record.expectedActorId,
			})
			confirmedCommands[commandId] = true
		elseif confirmedCommands[commandId] ~= true then
			table.insert(rows, {
				id = "pending:" .. commandId,
				kind = record.kind or record.commandType,
				createdAt = record.createdAt or 0,
				revision = record.baseRevision or revision,
				status = if record.terminalFailure == true
					then "terminal_failure"
					elseif record.accepted then "accepted_awaiting_projection"
					else "pending_receipt",
				commandId = commandId,
				target = record.target,
				reason = if record.terminalFailure == true
					then DmWorkspaceViewModel.safeFailureCode(record.failureCode)
					else nil,
			})
		end
	end
	table.sort(rows, function(left, right)
		if left.createdAt ~= right.createdAt then
			return left.createdAt < right.createdAt
		end
		if left.revision ~= right.revision then
			return left.revision < right.revision
		end
		return left.id < right.id
	end)

	local viewers = {}
	local session = domains.session
	for key, membership in
		if type(session) == "table" and type(session.memberships) == "table"
			then session.memberships
			else {}
	do
		local targetUserId = tonumber(key)
		if
			targetUserId ~= nil
			and type(membership) == "table"
			and (membership.role == "player" or membership.role == "observer")
		then
			table.insert(viewers, { userId = targetUserId, role = membership.role })
		end
	end
	table.sort(viewers, function(left, right)
		return left.userId < right.userId
	end)

	return {
		visible = true,
		role = "dm",
		workspace = workspace,
		queue = rows,
		viewers = viewers,
		revision = revision,
	}
end

function DmWorkspaceViewModel.intent(commandType: string, payload: any): (any?, string?)
	if commandType == COMMANDS.ASSIGN_CONTROL then
		if
			type(payload) ~= "table"
			or type(payload.actorId) ~= "string"
			or type(payload.controllerUserId) ~= "number"
		then
			return nil, "VALIDATION_FAILED"
		end
	elseif commandType == COMMANDS.QUICK_ACTION then
		if type(payload) ~= "table" or type(payload.actionId) ~= "string" then
			return nil, "VALIDATION_FAILED"
		end
	elseif commandType == COMMANDS.RUNTIME_PATCH then
		if
			type(payload) ~= "table"
			or type(payload.targetId) ~= "string"
			or type(payload.patch) ~= "table"
		then
			return nil, "VALIDATION_FAILED"
		end
	elseif commandType == COMMANDS.REQUEST_RECOVERY then
		if type(payload) ~= "table" or type(payload.target) ~= "string" then
			return nil, "VALIDATION_FAILED"
		end
	else
		return nil, "UNSUPPORTED_COMMAND"
	end
	return { commandType = commandType, payload = payload }, nil
end

return table.freeze(DmWorkspaceViewModel)
