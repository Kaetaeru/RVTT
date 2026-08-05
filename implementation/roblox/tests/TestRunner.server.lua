--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local testMode = ReplicatedStorage:FindFirstChild("RVTT_TestMode")
if testMode == nil or not testMode:IsA("StringValue") or testMode.Value ~= "unit" then
	return
end

local Harness = require(script.Parent.TestHarness)
local harness = Harness.new()

type Spec = {
	name: string,
	runner: (any) -> (),
}

local specs: { Spec } = {
	{ name = "Core.spec", runner = require(script.Parent.Unit["Core.spec"]) :: any },
	{ name = "Envelope.spec", runner = require(script.Parent.Unit["Envelope.spec"]) :: any },
	{ name = "Persistence.spec", runner = require(script.Parent.Unit["Persistence.spec"]) :: any },
	{
		name = "ProfileStore.spec",
		runner = require(script.Parent.Unit["ProfileStore.spec"]) :: any,
	},
	{
		name = "DomainRegistration.spec",
		runner = require(script.Parent.Integration["DomainRegistration.spec"]) :: any,
	},
	{
		name = "AuthorityFlow.spec",
		runner = require(script.Parent.Integration["AuthorityFlow.spec"]) :: any,
	},
	{
		name = "SecurityBoundary.spec",
		runner = require(script.Parent.Integration["SecurityBoundary.spec"]) :: any,
	},
	{
		name = "ProjectionDisclosure.spec",
		runner = require(script.Parent.Integration["ProjectionDisclosure.spec"]) :: any,
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
