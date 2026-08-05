--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BatchSummary = require(ReplicatedStorage.RVTT.Shared.Diagnostics.BatchSummary)

return function(harness)
	local summary = BatchSummary.new("unit-batch", {
		{ id = "boot", label = "Boot" },
		{ id = "interaction", label = "Interaction" },
	})
	harness:equal(summary:result(), "PENDING", "new Batch summary begins pending")
	summary:pass("boot", "runtime ready")
	local passed, failed, pending = summary:counts()
	harness:expect(passed == 1, "Batch summary counts passed checks")
	harness:expect(failed == 0, "Batch summary counts failed checks")
	harness:expect(pending == 1, "Batch summary counts pending checks")

	summary:fail("interaction", "pick failed\nwith detail")
	harness:equal(summary:result(), "FAIL", "one failed check fails the Batch")
	local formatted = summary:format(42)
	harness:expect(
		string.find(formatted, "batch=unit-batch", 1, true) ~= nil,
		"Batch summary includes its name"
	)
	harness:expect(
		string.find(formatted, "revision=42", 1, true) ~= nil,
		"Batch summary includes the projection revision"
	)
	harness:expect(
		string.find(formatted, "pick failed with detail", 1, true) ~= nil,
		"Batch summary sanitizes multiline details"
	)

	summary:pass("interaction", "screen fallback")
	harness:equal(summary:result(), "PASS", "all passed checks pass the Batch")
end
