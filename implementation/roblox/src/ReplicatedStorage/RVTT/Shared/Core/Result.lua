--!strict

export type Failure = {
	code: string,
	messageKey: string,
	retryable: boolean,
	details: { [string]: unknown }?,
}

export type Result<T> =
	{ ok: true, value: T }
	| { ok: false, error: Failure }

local Result = {}

function Result.ok<T>(value: T): Result<T>
	return { ok = true, value = value }
end

function Result.err<T>(code: string, messageKey: string, retryable: boolean, details: { [string]: unknown }?): Result<T>
	return {
		ok = false,
		error = {
			code = code,
			messageKey = messageKey,
			retryable = retryable,
			details = details,
		},
	}
end

function Result.map<T, U>(result: Result<T>, transform: (T) -> U): Result<U>
	if result.ok then
		return Result.ok(transform(result.value))
	end
	return result :: Result<U>
end

return table.freeze(Result)
