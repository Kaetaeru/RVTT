--!strict

local Harness = require(script.Parent.TestHarness)
local harness = Harness.new()
local specs = {
    script.Parent.Unit["Core.spec"],
    script.Parent.Unit["Envelope.spec"],
    script.Parent.Integration["DomainRegistration.spec"],
    script.Parent.Integration["AuthorityFlow.spec"],
    script.Parent.Integration["SecurityBoundary.spec"],
    script.Parent.Integration["ProjectionDisclosure.spec"],
}

for _, module in specs do
    local required, runner = xpcall(function() return require(module) end, debug.traceback)
    if required then
        local ran, errorMessage = xpcall(function() runner(harness) end, debug.traceback)
        if not ran then harness:expect(false, module.Name .. ": " .. tostring(errorMessage)) end
    else
        harness:expect(false, module.Name .. ": " .. tostring(runner))
    end
end

print(string.format("[RVTT Tests] passed=%d failed=%d", harness.passed, harness.failed))
for _, failure in harness.failures do warn("[RVTT Tests]", failure) end
assert(harness.failed == 0, "RVTT tests failed")
