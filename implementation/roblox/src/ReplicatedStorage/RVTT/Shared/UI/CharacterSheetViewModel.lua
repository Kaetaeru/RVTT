--!strict

local Layout = require(script.Parent.CharacterSheetLayout)

local CharacterSheetViewModel = {
	OPEN_ACTION = "OpenCharacterSheet",
}

local function feedbackState(code: string?): string
	if code == "STALE_REVISION" or code == "STALE_EPOCH" then
		return "stale_projection"
	elseif code == "UNAUTHORIZED" then
		return "permission_revoked"
	end
	return "denied"
end

function CharacterSheetViewModel.initialFeedback(revision: number, authorityEpoch: string?): any
	return {
		state = "idle",
		baseRevision = revision,
		authorityEpoch = authorityEpoch,
	}
end

function CharacterSheetViewModel.pendingFeedback(
	actionId: string,
	commandId: string,
	baseRevision: number,
	authorityEpoch: string?
): any
	return {
		state = "pending_receipt",
		actionId = actionId,
		commandId = commandId,
		baseRevision = baseRevision,
		authorityEpoch = authorityEpoch,
	}
end

function CharacterSheetViewModel.resolveReceipt(
	current: any,
	ok: boolean,
	code: string?,
	resultRevision: number?
): any
	if ok then
		return {
			state = "accepted_awaiting_projection",
			actionId = current.actionId,
			commandId = current.commandId,
			baseRevision = current.baseRevision,
			resultRevision = resultRevision,
			authorityEpoch = current.authorityEpoch,
		}
	end
	return {
		state = feedbackState(code),
		actionId = current.actionId,
		commandId = current.commandId,
		baseRevision = current.baseRevision,
		reason = code,
		authorityEpoch = current.authorityEpoch,
	}
end

function CharacterSheetViewModel.reconcile(
	current: any,
	projection: any,
	revision: number,
	authorityEpoch: string?
): any
	if type(projection) ~= "table" or projection.canReadFullSheet ~= true then
		return {
			state = "permission_revoked",
			baseRevision = revision,
			authorityEpoch = authorityEpoch,
		}
	end
	if current.authorityEpoch ~= nil and current.authorityEpoch ~= authorityEpoch then
		return CharacterSheetViewModel.initialFeedback(revision, authorityEpoch)
	end
	if current.state == "accepted_awaiting_projection" then
		local expected = current.resultRevision
		if
			(type(expected) == "number" and revision >= expected)
			or (expected == nil and revision > current.baseRevision)
		then
			return {
				state = "reconciled",
				baseRevision = revision,
				authorityEpoch = authorityEpoch,
			}
		end
	end
	return current
end

function CharacterSheetViewModel.build(
	payload: any,
	revision: number,
	feedback: any,
	viewportWidth: number
): any
	local projection = if type(payload) == "table" then payload.characterSheet else nil
	if type(projection) ~= "table" or projection.canReadFullSheet ~= true then
		return {
			visible = false,
			canReadFullSheet = false,
			state = "permission_revoked",
			revision = revision,
			layoutMode = Layout.modeForWidth(viewportWidth),
			feedback = feedback,
		}
	end
	local state = table.clone(projection)
	state.visible = true
	state.layoutMode = Layout.modeForWidth(viewportWidth)
	state.feedback = feedback
	state.state = if projection.revision == revision then projection.state else "stale_projection"
	return state
end

function CharacterSheetViewModel.actionIntent(
	state: any,
	actionId: any,
	candidateRevision: any
): (any?, string?)
	if type(state) ~= "table" or candidateRevision ~= state.revision then
		return nil, "STALE_PROJECTION"
	end
	if state.canControl ~= true or type(state.actions) ~= "table" then
		return nil, "PERMISSION_DENIED"
	end
	for _, action in state.actions do
		if action.id == actionId then
			if action.enabled ~= true then
				return nil, "ACTION_DISABLED"
			end
			if type(action.commandType) ~= "string" or type(action.payload) ~= "table" then
				return nil, "LOCAL_ONLY"
			end
			return {
				commandType = action.commandType,
				payload = table.clone(action.payload),
			},
				nil
		end
	end
	return nil, "NOT_PROJECTED"
end

return table.freeze(CharacterSheetViewModel)
