--!strict

export type ScreenCandidate = {
	actorId: string,
	minimum: Vector2,
	maximum: Vector2,
	depth: number,
}

local Math = {}

function Math.screenToViewport(screenPosition: Vector2, guiInset: Vector2): Vector2
	return Vector2.new(screenPosition.X - guiInset.X, screenPosition.Y - guiInset.Y)
end

function Math.pointToRectDistanceSquared(point: Vector2, minimum: Vector2, maximum: Vector2): number
	local dx = math.max(minimum.X - point.X, 0, point.X - maximum.X)
	local dy = math.max(minimum.Y - point.Y, 0, point.Y - maximum.Y)
	return dx * dx + dy * dy
end

function Math.chooseScreenCandidate(
	point: Vector2,
	candidates: { ScreenCandidate },
	maximumDistancePixels: number
): string?
	local maximumDistanceSquared = maximumDistancePixels * maximumDistancePixels
	local bestActorId: string? = nil
	local bestDistanceSquared = math.huge
	local bestDepth = math.huge

	for _, candidate in candidates do
		if candidate.depth > 0 then
			local distanceSquared =
				Math.pointToRectDistanceSquared(point, candidate.minimum, candidate.maximum)
			if
				distanceSquared <= maximumDistanceSquared
				and (
					distanceSquared < bestDistanceSquared
					or (distanceSquared == bestDistanceSquared and candidate.depth < bestDepth)
				)
			then
				bestActorId = candidate.actorId
				bestDistanceSquared = distanceSquared
				bestDepth = candidate.depth
			end
		end
	end

	return bestActorId
end

function Math.resolvePick(rayActorId: string?, screenActorId: string?): (string?, string)
	if rayActorId ~= nil then
		return rayActorId, "ray"
	end
	if screenActorId ~= nil then
		return screenActorId, "screen"
	end
	return nil, "none"
end

function Math.keyboardPanAxis(w: boolean, a: boolean, s: boolean, d: boolean): Vector2
	local x = (if d then 1 else 0) - (if a then 1 else 0)
	local y = (if w then 1 else 0) - (if s then 1 else 0)
	local axis = Vector2.new(x, y)
	return if axis.Magnitude > 1 then axis.Unit else axis
end

function Math.boundsCorners(boundsCFrame: CFrame, boundsSize: Vector3): { Vector3 }
	local half = boundsSize * 0.5
	local corners = {}
	for _, x in { -half.X, half.X } do
		for _, y in { -half.Y, half.Y } do
			for _, z in { -half.Z, half.Z } do
				table.insert(corners, boundsCFrame:PointToWorldSpace(Vector3.new(x, y, z)))
			end
		end
	end
	return corners
end

return table.freeze(Math)
