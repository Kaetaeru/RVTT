--!strict

local values: { [string]: string } = {
	LOADING = "loading",
	EMPTY = "empty",
	READY = "ready",
	PENDING = "pending",
	PARTIAL = "partial",
	STALE = "stale",
	PERMISSION_DENIED = "permission_denied",
	NETWORK_ERROR = "network_error",
	VALIDATION_ERROR = "validation_error",
	CONFLICT = "conflict",
	RECOVERY = "recovery",
}

local allowed: { [string]: boolean } = {}
for _, value in values do
	allowed[value] = true
end

local ViewState: { [string]: any } = table.clone(values)

function ViewState.isValid(value: any): boolean
	return type(value) == "string" and allowed[value] == true
end

return table.freeze(ViewState)

