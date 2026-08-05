--!strict

local Harness = require(script.Parent.TestHarness)
local harness = Harness.new()
local specs = {
	{ name = "Core.spec", runner = require(script.Parent.Unit["Core.spec"]) },
	{ name = "Envelope.spec", runner = require(script.Parent.Unit["Envelope.spec"]) },
	{ name = "Persistence.spec", runner = require(script.Parent.Unit["Persistence.spec"]) },
	{
		name = "DomainRegistration.spec",
		runner = require(script.Parent.Integration["DomainRegistration.spec"]),
	},
	{
		name = "AuthorityFlow.spec",
		runner = require(script.Parent.Integration["AuthorityFlow.spec"]),
	},
	{
		name = "SecurityBoundary.spec",
		runner = require(script.Parent.Integration["SecurityBoundary.spec"]),
	},
	{
		name = "ProjectionDisclosure.spec",
		runner = require(script.Parent.Integration["ProjectionDisclosure.spec"]),
	},
}

for _, spec in specs do
	local ran, errorMessage = xpcall(function()
		spec.runner(harness)
	end, debug.traceback)
	if not ran then
		harness:expect(false, spec.name .. ": " .. tostring(errorMessage))
	end
end

print(string.format("[RVTT Tests] passed=%d failed=%d", harness.passed, harness.failed))
for _, failure in harness.failures do
	warn("[RVTT Tests]", failure)
end
assert(harness.failed == 0, "RVTT tests failed")
