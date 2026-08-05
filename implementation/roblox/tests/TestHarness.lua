--!strict

export type Harness = {
	passed: number,
	failed: number,
	failures: { string },
	expect: (self: Harness, condition: boolean, message: string) -> (),
	equal: (self: Harness, actual: any, expected: any, message: string?) -> (),
}

local Harness = {}
Harness.__index = Harness

function Harness.new(): Harness
	return setmetatable({
		passed = 0,
		failed = 0,
		failures = {},
	}, Harness) :: any
end

function Harness.expect(self: Harness, condition: boolean, message: string)
	if condition then
		self.passed += 1
	else
		self.failed += 1
		table.insert(self.failures, message)
	end
end

function Harness.equal(self: Harness, actual: any, expected: any, message: string?)
	self:expect(
		actual == expected,
		(message or "values differ")
			.. " expected="
			.. tostring(expected)
			.. " actual="
			.. tostring(actual)
	)
end

return Harness
