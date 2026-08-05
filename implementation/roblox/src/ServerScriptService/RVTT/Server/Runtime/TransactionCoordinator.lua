--!strict

local DeepCopy = require(game:GetService("ReplicatedStorage").RVTT.Shared.Core.DeepCopy)
local Result = require(game:GetService("ReplicatedStorage").RVTT.Shared.Core.Result)

local TransactionCoordinator = {}
TransactionCoordinator.__index = TransactionCoordinator

function TransactionCoordinator.new(diagnostics: any): any
	return setmetatable({ diagnostics = diagnostics }, TransactionCoordinator)
end

function TransactionCoordinator.execute(
	self: any,
	authorityState: { [string]: unknown },
	operation: (draft: any) -> any
): any
	local draft = DeepCopy(authorityState) :: { [string]: unknown }
	local ok, outcome = xpcall(function()
		return operation(draft)
	end, debug.traceback)
	if not ok then
		self.diagnostics:record("error", "TRANSACTION_EXCEPTION", { trace = outcome })
		return Result.err("INTERNAL_ERROR", "error.internal", true)
	end
	if type(outcome) == "table" and outcome.ok == false then
		return outcome
	end
	if type(outcome) == "table" and outcome.ok == true then
		outcome = outcome.value
	end
	return Result.ok({ state = draft, outcome = outcome })
end

return TransactionCoordinator
