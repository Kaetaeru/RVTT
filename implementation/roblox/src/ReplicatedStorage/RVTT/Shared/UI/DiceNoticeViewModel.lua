--!strict

local ViewModel = {}

ViewModel.STATE_ORDER = {
	"hidden",
	"square_enter",
	"slot_spin",
	"natural_lock",
	"formula_expand",
	"adjudication_append",
	"hold",
	"dismiss",
}
ViewModel.STACK_CAP = 2
ViewModel.NORMAL_SIZE = { width = 64, height = 64 }
ViewModel.DUAL_MIN_SIZE = { width = 148, height = 64 }
ViewModel.DISCARDED_CONTRAST = 0.5
ViewModel.SLOT_CELL_HEIGHT = 56
ViewModel.SLOT_DECORATIVE_VALUES = { 2, 7, 13, 4, 18, 9 }

local function cloneMap(source: any): any
	local result = {}
	if type(source) == "table" then
		for key, value in source do
			result[key] = value
		end
	end
	return result
end

local function cloneArray(source: any): { any }
	local result = {}
	if type(source) == "table" then
		for _, value in source do
			table.insert(result, value)
		end
	end
	return result
end

function ViewModel.initial(authorityEpoch: string?): any
	return {
		authorityEpoch = authorityEpoch,
		acknowledged = {},
		seen = {},
		lastRevealRevision = 0,
		queue = {},
		active = {},
	}
end

local function activate(state: any)
	while #state.active < ViewModel.STACK_CAP and #state.queue > 0 do
		table.insert(state.active, table.remove(state.queue, 1))
	end
end

function ViewModel.reconcile(current: any, projections: any, authorityEpoch: string?): any
	local epochChanged = current.authorityEpoch ~= authorityEpoch
	local state = {
		authorityEpoch = authorityEpoch,
		acknowledged = cloneMap(current.acknowledged),
		seen = cloneMap(current.seen),
		lastRevealRevision = if epochChanged then 0 else current.lastRevealRevision,
		queue = if epochChanged then {} else cloneArray(current.queue),
		active = if epochChanged then {} else cloneArray(current.active),
	}
	local ordered = cloneArray(projections)
	table.sort(ordered, function(left: any, right: any)
		if left.revealRevision == right.revealRevision then
			return left.rollId < right.rollId
		end
		return left.revealRevision < right.revealRevision
	end)
	for _, notice in ordered do
		if
			type(notice) == "table"
			and type(notice.rollId) == "string"
			and type(notice.revealRevision) == "number"
			and notice.revealRevision > state.lastRevealRevision
			and state.seen[notice.rollId] ~= true
			and state.acknowledged[notice.rollId] ~= true
		then
			state.seen[notice.rollId] = true
			table.insert(state.queue, notice)
		end
		if type(notice.revealRevision) == "number" then
			state.lastRevealRevision = if notice.revealRevision > state.lastRevealRevision
				then notice.revealRevision
				else state.lastRevealRevision
		end
	end
	activate(state)
	return state
end

function ViewModel.complete(current: any, rollId: string): any
	local state = {
		authorityEpoch = current.authorityEpoch,
		acknowledged = cloneMap(current.acknowledged),
		seen = cloneMap(current.seen),
		lastRevealRevision = current.lastRevealRevision,
		queue = cloneArray(current.queue),
		active = {},
	}
	state.acknowledged[rollId] = true
	for _, notice in current.active do
		if notice.rollId ~= rollId then
			table.insert(state.active, notice)
		end
	end
	activate(state)
	return state
end

function ViewModel.suspend(current: any, authorityEpoch: string?): any
	return {
		authorityEpoch = authorityEpoch,
		acknowledged = cloneMap(current.acknowledged),
		seen = cloneMap(current.seen),
		lastRevealRevision = current.lastRevealRevision,
		queue = {},
		active = {},
	}
end

function ViewModel.presentationPlan(notice: any, reducedMotion: boolean): { any }
	local timing = notice.timingProfile
	local durations = {
		hidden = 0,
		square_enter = timing.squareEnterMs,
		slot_spin = timing.slotSpinMs,
		natural_lock = timing.naturalLockMs,
		formula_expand = timing.formulaExpandMs,
		adjudication_append = timing.adjudicationAppendMs,
		hold = timing.holdMs,
		dismiss = timing.dismissMs,
	}
	local phases = {}
	for _, name in ViewModel.STATE_ORDER do
		local naturalVisible = name == "natural_lock"
			or name == "formula_expand"
			or name == "adjudication_append"
			or name == "hold"
			or name == "dismiss"
		local formulaVisible = name == "formula_expand"
			or name == "adjudication_append"
			or name == "hold"
			or name == "dismiss"
		local adjudicationVisible = name == "adjudication_append"
			or name == "hold"
			or name == "dismiss"
		table.insert(phases, {
			name = name,
			durationMs = durations[name],
			disclosure = {
				natural = naturalVisible,
				formula = formulaVisible,
				total = formulaVisible,
				adjudication = adjudicationVisible,
			},
			crossfadeSteps = if reducedMotion and name == "slot_spin" then 3 else nil,
			shake = not reducedMotion
				and name == "natural_lock"
				and notice.semanticCritical == "natural_1",
			pulse = name == "natural_lock" and notice.semanticCritical ~= "none",
		})
	end
	return phases
end

function ViewModel.animationDescriptor(notice: any, reducedMotion: boolean): any
	local critical = notice.semanticCritical == "natural_1"
		or notice.semanticCritical == "natural_20"
	return {
		slotSpin = {
			kind = if reducedMotion then "three_step_crossfade" else "vertical_numeral_strip",
			durationMs = notice.timingProfile.slotSpinMs,
			crossfadeSteps = if reducedMotion then 3 else nil,
			verticalDistance = ViewModel.SLOT_CELL_HEIGHT * (#ViewModel.SLOT_DECORATIVE_VALUES - 1),
			finalNaturalVisible = false,
		},
		naturalLock = {
			durationMs = notice.timingProfile.naturalLockMs,
			locksProjectedNatural = true,
			shakeOffsets = if critical and not reducedMotion then { 10, -7, 4, -2, 0 } else {},
			tintToken = if notice.semanticCritical == "natural_1"
				then "danger"
				elseif notice.semanticCritical == "natural_20" then "success"
				else nil,
			outlinePulse = critical,
			tintFade = critical,
		},
		formulaExpand = {
			durationMs = notice.timingProfile.formulaExpandMs,
			targetWidth = 360,
			usesTween = true,
		},
		dualApplied = {
			enabled = notice.diceMode == "advantage" or notice.diceMode == "disadvantage",
			appliedIndex = notice.appliedIndex,
			accent = true,
			scale = 1.08,
			formulaConnector = true,
		},
	}
end

function ViewModel.cells(notice: any): { any }
	local result = {}
	for index, natural in notice.naturalResults do
		local applied = index == notice.appliedIndex
		table.insert(result, {
			index = index,
			natural = natural,
			applied = applied,
			contrast = if applied then 1 else ViewModel.DISCARDED_CONTRAST,
			semanticCritical = if applied then notice.semanticCritical else "none",
		})
	end
	return result
end

function ViewModel.layout(notice: any, initiativeVisible: boolean): any
	local dual = notice.diceMode == "advantage" or notice.diceMode == "disadvantage"
	return {
		initialWidth = if dual then ViewModel.DUAL_MIN_SIZE.width else ViewModel.NORMAL_SIZE.width,
		initialHeight = 64,
		expandedWidth = 360,
		topOffset = if initiativeVisible then 126 else 18,
		stackCap = ViewModel.STACK_CAP,
	}
end

return table.freeze(ViewModel)
