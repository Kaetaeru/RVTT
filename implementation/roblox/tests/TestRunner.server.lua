--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local testMode = ReplicatedStorage:FindFirstChild("RVTT_TestMode")
local grandMode = ReplicatedStorage:FindFirstChild("RVTT_GrandMode")
local unitModeEnabled = testMode ~= nil and testMode:IsA("StringValue") and testMode.Value == "unit"
local grandModeEnabled = grandMode ~= nil
	and grandMode:IsA("StringValue")
	and grandMode.Value == "single-client"
if not unitModeEnabled and not grandModeEnabled then
	return
end

local Harness = require(script.Parent.TestHarness)
local aggregate = Harness.new()

type Spec = {
	id: string,
	name: string,
	runner: (any) -> (),
}

local specs: { Spec } = {
	{
		id = "unit-core",
		name = "Core.spec",
		runner = require(script.Parent.Unit["Core.spec"]) :: any,
	},
	{
		id = "unit-accent-theme",
		name = "AccentTheme.spec",
		runner = require(script.Parent.Unit["AccentTheme.spec"]) :: any,
	},
	{
		id = "unit-envelope",
		name = "Envelope.spec",
		runner = require(script.Parent.Unit["Envelope.spec"]) :: any,
	},
	{
		id = "unit-world-token-contract",
		name = "WorldTokenContract.spec",
		runner = require(script.Parent.Unit["WorldTokenContract.spec"]) :: any,
	},
	{
		id = "unit-world-interaction-math",
		name = "WorldInteractionMath.spec",
		runner = require(script.Parent.Unit["WorldInteractionMath.spec"]) :: any,
	},
	{
		id = "unit-batch-summary",
		name = "BatchSummary.spec",
		runner = require(script.Parent.Unit["BatchSummary.spec"]) :: any,
	},
	{
		id = "unit-remote-bootstrap",
		name = "RemoteBootstrap.spec",
		runner = require(script.Parent.Unit["RemoteBootstrap.spec"]) :: any,
	},
	{
		id = "unit-persistence",
		name = "Persistence.spec",
		runner = require(script.Parent.Unit["Persistence.spec"]) :: any,
	},
	{
		id = "unit-profile-store",
		name = "ProfileStore.spec",
		runner = require(script.Parent.Unit["ProfileStore.spec"]) :: any,
	},
	{
		id = "integration-domain-registration",
		name = "DomainRegistration.spec",
		runner = require(script.Parent.Integration["DomainRegistration.spec"]) :: any,
	},
	{
		id = "integration-authority-flow",
		name = "AuthorityFlow.spec",
		runner = require(script.Parent.Integration["AuthorityFlow.spec"]) :: any,
	},
	{
		id = "integration-security-boundary",
		name = "SecurityBoundary.spec",
		runner = require(script.Parent.Integration["SecurityBoundary.spec"]) :: any,
	},
	{
		id = "integration-projection-disclosure",
		name = "ProjectionDisclosure.spec",
		runner = require(script.Parent.Integration["ProjectionDisclosure.spec"]) :: any,
	},
	{
		id = "integration-ui-preference",
		name = "UiPreferenceFlow.spec",
		runner = require(script.Parent.Integration["UiPreferenceFlow.spec"]) :: any,
	},
	{
		id = "integration-multi-viewer",
		name = "MultiViewerFlow.spec",
		runner = require(script.Parent.Integration["MultiViewerFlow.spec"]) :: any,
	},
	{
		id = "slice01-session-flow",
		name = "Slice01Flow.spec",
		runner = require(script.Parent.Integration["Slice01Flow.spec"]) :: any,
	},
	{
		id = "slice02-core-rules",
		name = "Slice02CoreRules.spec",
		runner = require(script.Parent.Integration["Slice02CoreRules.spec"]) :: any,
	},
	{
		id = "slice03-exploration",
		name = "Slice03Exploration.spec",
		runner = require(script.Parent.Integration["Slice03Exploration.spec"]) :: any,
	},
	{
		id = "slice04-encounter",
		name = "Slice04Encounter.spec",
		runner = require(script.Parent.Integration["Slice04Encounter.spec"]) :: any,
	},
	{
		id = "slice05-character",
		name = "Slice05Character.spec",
		runner = require(script.Parent.Integration["Slice05Character.spec"]) :: any,
	},
	{
		id = "slice06-inventory",
		name = "Slice06Inventory.spec",
		runner = require(script.Parent.Integration["Slice06Inventory.spec"]) :: any,
	},
	{
		id = "slice07-time-progression",
		name = "Slice07TimeProgression.spec",
		runner = require(script.Parent.Integration["Slice07TimeProgression.spec"]) :: any,
	},
	{
		id = "slice08-ui-preference",
		name = "Slice08UiPreference.spec",
		runner = require(script.Parent.Integration["Slice08UiPreference.spec"]) :: any,
	},
	{
		id = "slice09-journal",
		name = "Slice09Journal.spec",
		runner = require(script.Parent.Integration["Slice09Journal.spec"]) :: any,
	},
	{
		id = "slice10-scene-authoring",
		name = "Slice10SceneAuthoring.spec",
		runner = require(script.Parent.Integration["Slice10SceneAuthoring.spec"]) :: any,
	},
	{
		id = "slice11-dm-workspace",
		name = "Slice11DmWorkspace.spec",
		runner = require(script.Parent.Integration["Slice11DmWorkspace.spec"]) :: any,
	},
	{
		id = "slice12-content-platform",
		name = "Slice12ContentPlatform.spec",
		runner = require(script.Parent.Integration["Slice12ContentPlatform.spec"]) :: any,
	},
}

for _, spec in specs do
	local specHarness = Harness.new()
	local ran, errorMessage = xpcall(function()
		spec.runner(specHarness)
	end, debug.traceback)
	if not ran then
		specHarness:expect(false, spec.name .. ": " .. tostring(errorMessage))
	end

	local result = if specHarness.failed == 0 then "PASS" else "FAIL"
	print(
		string.format(
			"[RVTT Spec Summary] id=%s result=%s passed=%d failed=%d",
			spec.id,
			result,
			specHarness.passed,
			specHarness.failed
		)
	)

	aggregate.passed += specHarness.passed
	aggregate.failed += specHarness.failed
	for _, failure in specHarness.failures do
		local scopedFailure = spec.id .. ": " .. failure
		table.insert(aggregate.failures, scopedFailure)
		warn("[RVTT Spec Failure]", scopedFailure)
	end
end

print(string.format("[RVTT Tests] passed=%d failed=%d", aggregate.passed, aggregate.failed))
assert(aggregate.failed == 0, "RVTT tests failed")
