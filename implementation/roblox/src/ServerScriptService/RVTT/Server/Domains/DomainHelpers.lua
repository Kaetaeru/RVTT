--!strict

local Result = require(game:GetService("ReplicatedStorage").RVTT.Shared.Core.Result)

local DomainHelpers = {}

function DomainHelpers.isTable(value: unknown): boolean
	return type(value) == "table"
end

function DomainHelpers.hasString(payload: { [string]: unknown }, key: string): boolean
	local value = payload[key]
	return type(value) == "string" and #value > 0 and #value <= 256
end

function DomainHelpers.hasNumber(payload: { [string]: unknown }, key: string): boolean
	local value = payload[key]
	return type(value) == "number" and value == value
end

function DomainHelpers.requireRole(context, roles: { string }): boolean
	for _, role in roles do
		if context.role == role then
			return true
		end
	end
	return false
end

function DomainHelpers.findById(list, id: string)
	for index, value in list do
		if value.id == id then
			return value, index
		end
	end
	return nil, nil
end

function DomainHelpers.notFound(kind: string, id: string)
	return Result.err("NOT_FOUND", "error.common.not_found", false, { kind = kind, id = id })
end

return table.freeze(DomainHelpers)
