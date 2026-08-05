--!strict

local Version = require(script.Parent.Parent.Core.Version)
local Result = require(script.Parent.Parent.Core.Result)
local ValueGuard = require(script.Parent.Parent.Core.ValueGuard)

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
	return ValueGuard.isBoundedString(value, maximum)
end

function Envelope.validateCommand(value: unknown)
	if type(value) ~= "table" then
		return Result.err("INVALID_ENVELOPE", "error.protocol.invalid_envelope", false)
	end

	local envelope = value :: { [string]: unknown }
	if not Version.supportsProtocol(envelope.protocolVersion) then
		return Result.err("UNSUPPORTED_VERSION", "error.protocol.unsupported_version", false)
	end
	if
		not isShortString(envelope.commandId, 128)
		or not isShortString(envelope.commandType, 128)
		or not isShortString(envelope.correlationId, 128)
		or type(envelope.payload) ~= "table"
		or not ValueGuard.isSerializable(envelope.payload)
	then
		return Result.err("INVALID_ENVELOPE", "error.protocol.invalid_envelope", false)
	end
	if envelope.authorityEpoch ~= nil and not isShortString(envelope.authorityEpoch, 160) then
		return Result.err("INVALID_ENVELOPE", "error.protocol.invalid_envelope", false)
	end
	if envelope.expectedRevision ~= nil then
		if not ValueGuard.isFiniteNumber(envelope.expectedRevision) then
			return Result.err("INVALID_ENVELOPE", "error.protocol.invalid_envelope", false)
		end

		local expectedRevision = envelope.expectedRevision :: number
		if expectedRevision < 0 or expectedRevision % 1 ~= 0 then
			return Result.err("INVALID_ENVELOPE", "error.protocol.invalid_envelope", false)
		end
	end

	return Result.ok((envelope :: any) :: CommandEnvelope)
end

return table.freeze(Envelope)
