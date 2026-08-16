--!strict

local ShellContract = require(script.Parent.ShellContract)
local ViewState = require(script.Parent.ViewState)

export type Feedback = {
	state: string,
	kind: string?,
	commandId: string?,
	baseRevision: number,
	resultRevision: number?,
	reason: string?,
}

export type Preview = {
	state: string,
	kind: string,
	label: string,
	actorId: string,
	targetActorId: string?,
	targetLabel: string,
	position: Vector3?,
	distance: number?,
	remaining: number?,
	excess: number?,
	riskLabels: { string },
	enabled: boolean,
	disabledReason: string?,
	projectionRevision: number,
}

local ViewModel = {}

local function domains(payload: any): any
	return if type(payload) == "table" and type(payload.domains) == "table"
		then payload.domains
		else {}
end

local function actor(allDomains: any, actorId: string?): any
	local scene = allDomains.scene
	local actors = if type(scene) == "table" then scene.actors else nil
	return if type(actors) == "table" and type(actorId) == "string" then actors[actorId] else nil
end

local function controls(allDomains: any, userId: number, actorId: string?): boolean
	local value = actor(allDomains, actorId)
	if type(value) ~= "table" then
		return false
	end
	local session = allDomains.session
	local memberships = if type(session) == "table" then session.memberships else nil
	local membership = if type(memberships) == "table" then memberships[tostring(userId)] else nil
	if type(membership) == "table" and membership.role == "dm" then
		return true
	end
	return value.ownerUserId == userId or value.controllerUserId == userId
end

local function actorLabel(allDomains: any, actorId: string?): string
	if type(actorId) ~= "string" then
		return "선택 없음"
	end
	local value = actor(allDomains, actorId)
	if type(value) ~= "table" then
		return actorId
	end
	local characterDomain = allDomains.character
	local characters = if type(characterDomain) == "table" then characterDomain.characters else nil
	local character = if type(characters) == "table"
		then characters[value.sourceCharacterId or actorId]
		else nil
	if type(character) == "table" and type(character.name) == "string" then
		return character.name
	end
	return if type(value.name) == "string" then value.name else actorId
end

local function activeActorId(active: any): string?
	if type(active) ~= "table" then
		return nil
	end
	if type(active.activeActorId) == "string" then
		return active.activeActorId
	end
	local timeline = active.timeline
	local entry = if type(timeline) == "table" and type(active.cursor) == "number"
		then timeline[active.cursor]
		else nil
	return if type(entry) == "table" and type(entry.actorId) == "string" then entry.actorId else nil
end

local function projectedPosition(value: any): Vector3?
	if
		type(value) == "table"
		and type(value.x) == "number"
		and type(value.y) == "number"
		and type(value.z) == "number"
	then
		return Vector3.new(value.x, value.y, value.z)
	end
	return nil
end

function ViewModel.initialFeedback(revision: number): Feedback
	return {
		state = ViewState.READY,
		baseRevision = revision,
	}
end

function ViewModel.pendingFeedback(kind: string, commandId: string, baseRevision: number): Feedback
	return {
		state = ViewState.PENDING,
		kind = kind,
		commandId = commandId,
		baseRevision = baseRevision,
	}
end

local function failureState(code: string?): string
	if code == "STALE_REVISION" or code == "STALE_EPOCH" then
		return ViewState.STALE
	elseif code == "OPPORTUNITY_EXPIRED" or code == "EXPIRED" then
		return ViewState.EXPIRED
	elseif code == "UNAUTHORIZED" then
		return ViewState.PERMISSION_DENIED
	elseif code == "CLIENT_TIMEOUT" then
		return ViewState.NETWORK_ERROR
	elseif code == "VALIDATION_FAILED" then
		return ViewState.VALIDATION_ERROR
	elseif code == "CONFLICT" then
		return ViewState.CONFLICT
	end
	return ViewState.RECOVERY
end

function ViewModel.resolveFeedback(
	current: Feedback,
	ok: boolean,
	code: string?,
	resultRevision: number?
): Feedback
	if ok then
		return {
			state = ViewState.PARTIAL,
			kind = current.kind,
			commandId = current.commandId,
			baseRevision = current.baseRevision,
			resultRevision = resultRevision,
		}
	end
	return {
		state = failureState(code),
		kind = current.kind,
		commandId = current.commandId,
		baseRevision = current.baseRevision,
		resultRevision = resultRevision,
		reason = code,
	}
end

function ViewModel.reconcileFeedback(current: Feedback, revision: number): Feedback
	if
		current.state == ViewState.PARTIAL
		and (
			(type(current.resultRevision) == "number" and revision >= current.resultRevision)
			or (current.resultRevision == nil and revision > current.baseRevision)
		)
	then
		return ViewModel.initialFeedback(revision)
	end
	return current
end

function ViewModel.preview(
	payload: any,
	selectedActorId: string?,
	rawPreview: any,
	revision: number
): Preview?
	if
		type(selectedActorId) ~= "string"
		or type(rawPreview) ~= "table"
		or rawPreview.actorId ~= selectedActorId
		or type(rawPreview.action) ~= "table"
	then
		return nil
	end
	local allDomains = domains(payload)
	local selected = actor(allDomains, selectedActorId)
	if type(selected) ~= "table" then
		return nil
	end
	local action = rawPreview.action
	local target = rawPreview.target
	if type(target) ~= "table" then
		return nil
	end
	if target.kind == "actor" and type(actor(allDomains, target.actorId)) ~= "table" then
		return nil
	end
	local position = if typeof(target.position) == "Vector3" then target.position else nil
	local startPosition = projectedPosition(selected.position)
	local distance = if position ~= nil and startPosition ~= nil
		then (position - startPosition).Magnitude
		else nil
	local encounter = allDomains.encounter
	local active = if type(encounter) == "table" then encounter.active else nil
	local remaining = if type(active) == "table"
			and activeActorId(active) == selectedActorId
			and type(active.movementRemaining) == "number"
		then active.movementRemaining
		else nil
	local excess = if type(distance) == "number" and type(remaining) == "number"
		then math.max(0, distance - remaining)
		else nil
	local riskLabels = {}
	local projectedPreview = action.preview
	if type(projectedPreview) == "table" and type(projectedPreview.riskLabels) == "table" then
		for _, label in projectedPreview.riskLabels do
			if type(label) == "string" then
				table.insert(riskLabels, label)
			end
		end
	end
	local targetLabel = if type(target.actorId) == "string"
		then actorLabel(allDomains, target.actorId)
		elseif type(target.objectId) == "string" then target.objectId
		else "목적지"
	local projectionRevision = if type(action.projectionRevision) == "number"
		then action.projectionRevision
		else -1
	return {
		state = if projectionRevision == revision then ViewState.READY else ViewState.STALE,
		kind = if type(action.kind) == "string" then action.kind else "action",
		label = if type(action.label) == "string" then action.label else "행동",
		actorId = selectedActorId,
		targetActorId = if type(target.actorId) == "string" then target.actorId else nil,
		targetLabel = targetLabel,
		position = position,
		distance = distance,
		remaining = remaining,
		excess = excess,
		riskLabels = riskLabels,
		enabled = action.enabled == true and projectionRevision == revision,
		disabledReason = if projectionRevision ~= revision
			then "권위 상태가 변경되어 미리보기를 갱신해야 합니다"
			elseif type(action.disabledReason) == "string" then action.disabledReason
			else nil,
		projectionRevision = projectionRevision,
	}
end

function ViewModel.build(
	payload: any,
	userId: number,
	selectedActorId: string?,
	revision: number,
	preview: Preview?,
	feedback: Feedback
): any
	local allDomains = domains(payload)
	local context = ShellContract.resolve(payload, userId)
	local selected = actor(allDomains, selectedActorId)
	local rules = allDomains.rules
	local actorStates = if type(rules) == "table" then rules.actorStates else nil
	local hitPoints = if type(actorStates) == "table" and type(selectedActorId) == "string"
		then actorStates[selectedActorId]
		else nil
	local encounter = allDomains.encounter
	local active = if type(encounter) == "table" then encounter.active else nil
	local currentActorId = activeActorId(active)
	local timeline = {}
	if type(active) == "table" and type(active.timeline) == "table" then
		for _, entry in active.timeline do
			if type(entry) == "table" and type(actor(allDomains, entry.actorId)) == "table" then
				table.insert(timeline, {
					actorId = entry.actorId,
					label = actorLabel(allDomains, entry.actorId),
					initiative = if type(entry.initiative) == "number"
						then entry.initiative
						else nil,
					active = entry.actorId == currentActorId,
				})
			end
		end
	end
	local opportunities = if type(active) == "table" then active.opportunities else nil
	local activeControlled = controls(allDomains, userId, currentActorId)
	local resources = {}
	if activeControlled and type(opportunities) == "table" then
		for _, resource in
			{
				{ id = "action", label = "행동", key = "action" },
				{ id = "bonus_action", label = "추가 행동", key = "bonusAction" },
				{ id = "reaction", label = "반응", key = "reaction" },
			}
		do
			if type(opportunities[resource.key]) == "boolean" then
				table.insert(resources, {
					id = resource.id,
					label = resource.label,
					available = opportunities[resource.key] == true,
				})
			end
		end
		if type(active.movementRemaining) == "number" then
			table.insert(resources, {
				id = "movement",
				label = "이동",
				available = active.movementRemaining > 0,
				value = active.movementRemaining,
			})
		end
	end
	return {
		role = context.role,
		mode = context.mode,
		visible = context.surface == "gameplay",
		revision = revision,
		selectedActorId = if type(selected) == "table" then selectedActorId else nil,
		selectedActorLabel = actorLabel(
			allDomains,
			if type(selected) == "table" then selectedActorId else nil
		),
		hitPoints = if type(hitPoints) == "table" then hitPoints.currentHitPoints else nil,
		maximumHitPoints = if type(hitPoints) == "table" then hitPoints.maximumHitPoints else nil,
		activeActorId = currentActorId,
		activeActorLabel = actorLabel(allDomains, currentActorId),
		round = if type(active) == "table" and type(active.round) == "number"
			then active.round
			else nil,
		timeline = timeline,
		resources = resources,
		canEndTurn = activeControlled,
		reactionVisible = activeControlled and type(opportunities) == "table" and type(
			opportunities.reaction
		) == "boolean",
		reactionAvailable = activeControlled
			and type(opportunities) == "table"
			and opportunities.reaction == true,
		preview = preview,
		feedback = feedback,
	}
end

return table.freeze(ViewModel)
