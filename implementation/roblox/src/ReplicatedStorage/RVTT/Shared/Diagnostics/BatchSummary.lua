--!strict

export type CheckDefinition = {
	id: string,
	label: string,
}

export type CheckStatus = "pending" | "pass" | "fail"

export type CheckRecord = {
	id: string,
	label: string,
	status: CheckStatus,
	detail: string,
}

export type Summary = {
	name: string,
	order: { string },
	checks: { [string]: CheckRecord },
	set: (self: Summary, id: string, status: CheckStatus, detail: string?) -> (),
	pass: (self: Summary, id: string, detail: string?) -> (),
	fail: (self: Summary, id: string, detail: string?) -> (),
	pending: (self: Summary, id: string, detail: string?) -> (),
	counts: (self: Summary) -> (number, number, number),
	result: (self: Summary) -> string,
	format: (self: Summary, revision: number?) -> string,
	log: (self: Summary, revision: number?) -> (),
}

local Summary = {}
Summary.__index = Summary

local function sanitize(value: string): string
	return string.gsub(value, "[\r\n]+", " ")
end

function Summary.new(name: string, definitions: { CheckDefinition }): Summary
	local order = {}
	local checks = {}
	for _, definition in definitions do
		assert(checks[definition.id] == nil, "duplicate Batch check: " .. definition.id)
		table.insert(order, definition.id)
		checks[definition.id] = {
			id = definition.id,
			label = definition.label,
			status = "pending",
			detail = "",
		}
	end
	return setmetatable({
		name = name,
		order = order,
		checks = checks,
	}, Summary) :: any
end

function Summary.set(self: Summary, id: string, status: CheckStatus, detail: string?)
	local record = self.checks[id]
	assert(record ~= nil, "unknown Batch check: " .. id)
	record.status = status
	record.detail = detail or ""
end

function Summary.pass(self: Summary, id: string, detail: string?)
	self:set(id, "pass", detail)
end

function Summary.fail(self: Summary, id: string, detail: string?)
	self:set(id, "fail", detail)
end

function Summary.pending(self: Summary, id: string, detail: string?)
	self:set(id, "pending", detail)
end

function Summary.counts(self: Summary): (number, number, number)
	local passed = 0
	local failed = 0
	local pending = 0
	for _, id in self.order do
		local status = self.checks[id].status
		if status == "pass" then
			passed += 1
		elseif status == "fail" then
			failed += 1
		else
			pending += 1
		end
	end
	return passed, failed, pending
end

function Summary.result(self: Summary): string
	local _, failed, pending = self:counts()
	if failed > 0 then
		return "FAIL"
	end
	if pending > 0 then
		return "PENDING"
	end
	return "PASS"
end

function Summary.format(self: Summary, revision: number?): string
	local passed, failed, pending = self:counts()
	local lines = {
		string.format(
			"[RVTT Batch Summary] batch=%s result=%s passed=%d failed=%d pending=%d revision=%s",
			self.name,
			self:result(),
			passed,
			failed,
			pending,
			tostring(revision)
		),
	}
	for _, id in self.order do
		local record = self.checks[id]
		table.insert(
			lines,
			string.format(
				"[RVTT Batch Check] id=%s status=%s label=%s detail=%s",
				record.id,
				string.upper(record.status),
				sanitize(record.label),
				sanitize(record.detail)
			)
		)
	end
	return table.concat(lines, "\n")
end

function Summary.log(self: Summary, revision: number?)
	print(self:format(revision))
end

return Summary
