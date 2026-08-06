--!strict
return function(h)
	local Shared = game:GetService("ReplicatedStorage").RVTT.Shared
	local Envelope = require(Shared.Protocol.Envelope)
	local Version = require(Shared.Core.Version)
	local valid = Envelope.validateCommand({
		protocolVersion = Version.PROTOCOL,
		commandId = "c",
		commandType = "session.join",
		correlationId = "r",
		payload = {},
	})
	h:expect(valid.ok, "valid envelope")
	local invalid = Envelope.validateCommand({})
	h:expect(not invalid.ok, "invalid envelope")
end
