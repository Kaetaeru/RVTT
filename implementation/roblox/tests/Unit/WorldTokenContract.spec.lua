--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Contract = require(ReplicatedStorage.RVTT.Shared.World.WorldTokenContract)

return function(harness)
	local payload = {
		domains = {
			session = {
				memberships = {
					["101"] = { role = "player" },
					["202"] = { role = "dm" },
				},
			},
			character = {
				characters = {
					["character:hero"] = { name = "Acceptance Hero" },
				},
			},
			scene = {
				activeSceneId = "scene:test",
				actors = {
					["actor:hero"] = {
						id = "actor:hero",
						sourceCharacterId = "character:hero",
						ownerUserId = 101,
						controllerUserId = 101,
						position = { x = 12, y = 0, z = 8 },
						incarnation = 1,
					},
				},
			},
		},
	}
	local actor = Contract.actor(payload, "actor:hero")
	harness:expect(actor ~= nil, "world token contract resolves a projected actor")
	harness:equal(
		Contract.displayName(payload, actor),
		"Acceptance Hero",
		"character name labels the token"
	)
	harness:expect(Contract.canControl(payload, actor, 101), "owner controls the projected actor")
	harness:expect(Contract.canControl(payload, actor, 202), "DM controls the projected actor")
	harness:expect(
		not Contract.canControl(payload, actor, 303),
		"unrelated player cannot control the actor"
	)

	local position = Contract.toVector3(actor.position)
	harness:expect(position ~= nil, "finite projection position converts to Vector3")
	if position ~= nil then
		harness:equal(position.X, 12, "projected X is preserved")
		harness:equal(position.Y, 0, "projected Y is preserved")
		harness:equal(position.Z, 8, "projected Z is preserved")
		local destination = Contract.toDestination(position)
		harness:equal(destination.x, 12, "destination X is plain data")
		harness:equal(destination.z, 8, "destination Z is plain data")
	end

	harness:expect(
		Contract.toVector3({ x = 0 / 0, y = 0, z = 0 }) == nil,
		"invalid numeric projection is rejected"
	)
	harness:expect(
		string.find(Contract.fingerprint(actor), "actor:hero", 1, true) ~= nil,
		"actor fingerprint includes identity"
	)

	local surface = Instance.new("Part")
	surface:SetAttribute("RVTTMoveSurface", true)
	local child = Instance.new("Attachment")
	child.Parent = surface
	harness:expect(
		Contract.isMoveSurface(child),
		"move surface attribute is inherited from ancestors"
	)
	surface:Destroy()
end
