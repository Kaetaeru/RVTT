--!strict

local PreferenceSchema = require(script.Parent.PreferenceSchema)

local PreferencePresentation = {}

local rows = table.freeze({
	{ key = "uiScale", label = "UI 배율", step = 0.1 },
	{ key = "textScale", label = "텍스트 배율", step = 0.1 },
	{ key = "actionMatrixRows", label = "액션 행", step = 1 },
	{ key = "tooltipDelay", label = "도움말 지연", step = 0.25 },
	{ key = "detailedTooltipDelay", label = "상세 도움말 지연", step = 0.25 },
	{ key = "disabledReasonDelay", label = "비활성 사유 지연", step = 0.15 },
})

function PreferencePresentation.rows(): { any }
	return rows
end

function PreferencePresentation.adjust(
	key: string,
	value: any,
	delta: number
): (boolean, any, string?)
	if type(value) ~= "number" or type(delta) ~= "number" then
		return false, nil, "INVALID_PREFERENCE_VALUE"
	end
	return PreferenceSchema.normalize(key, value + delta)
end

function PreferencePresentation.nextMotion(value: any): string
	if value == "full" then
		return "reduced"
	elseif value == "reduced" then
		return "minimal"
	end
	return "full"
end

function PreferencePresentation.bindingConflicts(bindings: any): { any }
	local conflicts = {}
	if type(bindings) ~= "table" then
		return conflicts
	end
	local byBinding: { [string]: { string } } = {}
	for actionId, bindingId in bindings do
		if type(actionId) == "string" and type(bindingId) == "string" then
			byBinding[bindingId] = byBinding[bindingId] or {}
			table.insert(byBinding[bindingId], actionId)
		end
	end
	for bindingId, actionIds in byBinding do
		if #actionIds > 1 then
			table.sort(actionIds)
			table.insert(conflicts, { bindingId = bindingId, actionIds = actionIds })
		end
	end
	table.sort(conflicts, function(left, right)
		return left.bindingId < right.bindingId
	end)
	return conflicts
end

return table.freeze(PreferencePresentation)
