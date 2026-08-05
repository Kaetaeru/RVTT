--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InteractionMath = require(ReplicatedStorage.RVTT.Shared.World.WorldInteractionMath)

return function(harness)
	local viewport = InteractionMath.screenToViewport(Vector2.new(120, 90), Vector2.new(0, 36))
	harness:expect(viewport.X == 120, "screen-to-viewport preserves X")
	harness:expect(viewport.Y == 54, "screen-to-viewport removes GUI inset")

	harness:expect(
		InteractionMath.pointToRectDistanceSquared(
			Vector2.new(12, 12),
			Vector2.new(10, 10),
			Vector2.new(20, 20)
		) == 0,
		"point inside a projected token has zero distance"
	)
	harness:expect(
		InteractionMath.pointToRectDistanceSquared(
			Vector2.new(25, 24),
			Vector2.new(10, 10),
			Vector2.new(20, 20)
		) == 41,
		"point outside a projected token uses squared edge distance"
	)

	local candidates = {
		{
			actorId = "actor:far",
			minimum = Vector2.new(100, 100),
			maximum = Vector2.new(140, 160),
			depth = 30,
		},
		{
			actorId = "actor:near",
			minimum = Vector2.new(100, 100),
			maximum = Vector2.new(140, 160),
			depth = 10,
		},
	}
	harness:equal(
		InteractionMath.chooseScreenCandidate(Vector2.new(120, 130), candidates, 18),
		"actor:near",
		"overlapping screen candidates choose the nearest visible token"
	)
	harness:expect(
		InteractionMath.chooseScreenCandidate(Vector2.new(200, 200), candidates, 18) == nil,
		"screen picking rejects points outside the fallback radius"
	)

	local actorId, method = InteractionMath.resolvePick("actor:ray", "actor:screen")
	harness:equal(actorId, "actor:ray", "world ray picking has precedence")
	harness:equal(method, "ray", "world ray picking reports its method")
	actorId, method = InteractionMath.resolvePick(nil, "actor:screen")
	harness:equal(actorId, "actor:screen", "screen bounds recover a missed world ray")
	harness:equal(method, "screen", "screen fallback reports its method")
end
