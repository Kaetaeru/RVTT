--!strict

local Version = require(script.Parent.Parent.Core.Version)
local Result = require(script.Parent.Parent.Core.Result)

export type CommandEnvelope = {
	protocolVersion: number,
	commandId: string,
	commandType: string,
	correlationId: string,
	authorityEpoch: string?,
	expectedRevision: number?,
	payload: { [string]: unknown },
}

local Envelope = {}

local function isShortString(value: unknown, maximum: number): boolean
	return type(value) == "string" and #value > 0 and #value <= maximum
end

function Envelope.validateCommand(value: unknown)
	if type(value) ~= "table" then
		return Result.err("INVALID_ENVELOPE", "error.protocol.invalid_envelope", false)
	end
	local envelope = value :: { [string]: unknown }
	if not Version.supportsProtocol(envelope.protocolVersion) then
		return Result.err("UNSUPPORTED_VERSION", "error.protocol.unsupported_version", false)
	end
	if not isShortString(envelope.commandId, 128)
		or not isShortString(envelope.commandType, 128)
		or not isShortString(envelope.correlationId, 128)
		or type(envelope.payload) ~= "table"
	then
		return Result.err("INVALID_ENVELOPE", "error.protocol.invalid_envelope", false)
	end
	return Result.ok(envelope :: CommandEnvelope)
end

return table.freeze(Envelope)
