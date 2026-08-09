--!strict

local DiceNoticeProjection = {}

local function actorVisible(actor: any, viewer: any): boolean
	return type(actor) == "table"
		and (
			viewer.role == "dm"
			or actor.hidden ~= true
			or actor.ownerUserId == viewer.userId
			or actor.controllerUserId == viewer.userId
		)
end

local function audienceVisible(record: any, viewer: any): boolean
	if record.audience == "public" then
		return true
	end
	return viewer.role == "dm"
		or (record.audience == "owner" and record.ownerUserId == viewer.userId)
end

local function actorForRecord(record: any, domains: any): (any, any)
	local data = record.data
	local actorId = if type(data) == "table" then data.actorId or data.attackerId else nil
	local scene = domains.scene
	local actors = if type(scene) == "table" then scene.actors else nil
	if type(actors) == "table" and type(actorId) == "string" then
		return actors[actorId], actorId
	end
	return nil, actorId
end

local function actorLabel(actor: any, actorId: any, domains: any): string
	if type(actor) == "table" and type(actor.sourceCharacterId) == "string" then
		local characterDomain = domains.character
		local characters = if type(characterDomain) == "table"
			then characterDomain.characters
			else nil
		local character = if type(characters) == "table"
			then characters[actor.sourceCharacterId]
			else nil
		if type(character) == "table" and type(character.name) == "string" then
			return character.name
		end
	end
	return tostring(actorId)
end

local function validTiming(timing: any): boolean
	return type(timing) == "table"
		and timing.squareEnterMs == 120
		and type(timing.slotSpinMs) == "number"
		and timing.slotSpinMs >= 420
		and timing.slotSpinMs <= 720
		and timing.naturalLockMs == 180
		and timing.formulaExpandMs == 260
		and timing.adjudicationAppendMs == 180
		and type(timing.holdMs) == "number"
		and timing.holdMs >= 1600
		and timing.holdMs <= 2600
		and timing.dismissMs == 240
end

local function copyArray(source: any): { any }?
	if type(source) ~= "table" then
		return nil
	end
	local result = {}
	for index, value in source do
		if type(index) ~= "number" then
			return nil
		end
		table.insert(result, value)
	end
	return result
end

function DiceNoticeProjection.fromRecord(record: any, viewer: any, domains: any): any?
	if
		type(record) ~= "table"
		or type(record.id) ~= "string"
		or type(record.revealRevision) ~= "number"
		or not audienceVisible(record, viewer)
	then
		return nil
	end
	local actor, actorId = actorForRecord(record, domains)
	if not actorVisible(actor, viewer) then
		return nil
	end
	local notice = record.notice
	local naturalResults = if type(notice) == "table" then copyArray(notice.naturalResults) else nil
	local modifierTerms = if type(notice) == "table" then copyArray(notice.modifierTerms) else nil
	if
		type(notice) ~= "table"
		or (notice.diceMode ~= "normal" and notice.diceMode ~= "advantage" and notice.diceMode ~= "disadvantage")
		or type(naturalResults) ~= "table"
		or #naturalResults < 1
		or #naturalResults > 2
		or (notice.diceMode == "normal" and #naturalResults ~= 1)
		or (notice.diceMode ~= "normal" and #naturalResults ~= 2)
		or type(notice.appliedIndex) ~= "number"
		or notice.appliedIndex % 1 ~= 0
		or notice.appliedIndex < 1
		or notice.appliedIndex > #naturalResults
		or type(modifierTerms) ~= "table"
		or type(notice.total) ~= "number"
		or type(notice.adjudication) ~= "string"
		or (notice.semanticCritical ~= "none" and notice.semanticCritical ~= "natural_1" and notice.semanticCritical ~= "natural_20")
		or not validTiming(notice.timingProfile)
	then
		return nil
	end
	for _, value in naturalResults do
		if type(value) ~= "number" or value % 1 ~= 0 then
			return nil
		end
	end
	for _, term in modifierTerms do
		if
			type(term) ~= "table"
			or type(term.label) ~= "string"
			or type(term.value) ~= "number"
		then
			return nil
		end
	end
	local data = record.data
	return {
		rollId = record.id,
		audience = record.audience,
		diceMode = notice.diceMode,
		naturalResults = naturalResults,
		appliedIndex = notice.appliedIndex,
		modifierTerms = modifierTerms,
		total = notice.total,
		adjudication = notice.adjudication,
		semanticCritical = notice.semanticCritical,
		subjectLabel = actorLabel(actor, actorId, domains),
		actionLabel = tostring(
			if type(data) == "table"
				then data.sourceId or data.rollKind or record.kind
				else record.kind
		),
		revealRevision = record.revealRevision,
		timingProfile = table.clone(notice.timingProfile),
	}
end

function DiceNoticeProjection.build(domains: any, viewer: any): { any }
	local rules = domains.rules
	local records = if type(rules) == "table" then rules.rollRecords else nil
	local result = {}
	if type(records) ~= "table" then
		return result
	end
	for _, record in records do
		local projected = DiceNoticeProjection.fromRecord(record, viewer, domains)
		if projected ~= nil then
			table.insert(result, projected)
		end
	end
	table.sort(result, function(left: any, right: any)
		if left.revealRevision == right.revealRevision then
			return left.rollId < right.rollId
		end
		return left.revealRevision < right.revealRevision
	end)
	return result
end

return table.freeze(DiceNoticeProjection)
