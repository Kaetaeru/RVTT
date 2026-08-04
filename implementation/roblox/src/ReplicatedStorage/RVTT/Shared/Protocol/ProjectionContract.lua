--!strict

export type ProjectionEnvelope = {
	protocolVersion: number,
	authorityEpoch: string,
	revision: number,
	projectionSequence: number,
	projectionType: string,
	payload: { [string]: unknown },
}

local ProjectionContract = {}

function ProjectionContract.isNewer(currentEpoch: string?, currentRevision: number, envelope: ProjectionEnvelope): boolean
	if currentEpoch == nil or currentEpoch ~= envelope.authorityEpoch then
		return true
	end
	return envelope.revision >= currentRevision
end

return table.freeze(ProjectionContract)
