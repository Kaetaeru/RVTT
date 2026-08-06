--!strict

local Contract = {}

local function finite(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

function Contract.actors(payload: any): { [string]: any }
	if type(payload) ~= "table" or type(payload.domains) ~= "table" then
		return {}
	end
	local scene = payload.domains.scene
	if
		type(scene) ~= "table"
		or type(scene.activeSceneId) ~= "string"
		or type(scene.actors) ~= "table"
	then
		return {}
	end
	return scene.actors
end

function Contract.actor(payload: any, actorId: string): any?
	return Contract.actors(payload)[actorId]
end

function Contract.toVector3(position: any): Vector3?
	if type(position) ~= "table" then
		return nil
	end
	if not finite(position.x) or not finite(position.y) or not finite(position.z) then
		return nil
	end
	return Vector3.new(position.x, position.y, position.z)
end

function Contract.toDestination(position: Vector3): { x: number, y: number, z: number }
	return {
		x = position.X,
		y = position.Y,
		z = position.Z,
	}
end

function Contract.canControl(payload: any, actor: any, userId: number): boolean
	if type(actor) ~= "table" then
		return false
	end
	if actor.controllerUserId == userId or actor.ownerUserId == userId then
		return true
	end
	if type(payload) ~= "table" or type(payload.domains) ~= "table" then
		return false
	end
	local session = payload.domains.session
	if type(session) ~= "table" or type(session.memberships) ~= "table" then
		return false
	end
	local membership = session.memberships[tostring(userId)]
	return type(membership) == "table" and membership.role == "dm"
end

function Contract.displayName(payload: any, actor: any): string
	if type(actor) ~= "table" then
		return "Token"
	end
	if type(payload) == "table" and type(payload.domains) == "table" then
		local characterDomain = payload.domains.character
		if
			type(actor.sourceCharacterId) == "string"
			and type(characterDomain) == "table"
			and type(characterDomain.characters) == "table"
		then
			local character = characterDomain.characters[actor.sourceCharacterId]
			if
				type(character) == "table"
				and type(character.name) == "string"
				and #character.name > 0
			then
				return character.name
			end
		end
	end
	if type(actor.sourceNpcId) == "string" then
		return actor.sourceNpcId
	end
	if type(actor.id) == "string" then
		return actor.id
	end
	return "Token"
end

function Contract.fingerprint(actor: any): string
	if type(actor) ~= "table" then
		return "invalid"
	end
	return table.concat({
		tostring(actor.id),
		tostring(actor.sourceCharacterId),
		tostring(actor.sourceNpcId),
		tostring(actor.incarnation),
	}, "|")
end

function Contract.isMoveSurface(instance: Instance?): boolean
	local current = instance
	while current ~= nil do
		if current:GetAttribute("RVTTMoveSurface") == true then
			return true
		end
		current = current.Parent
	end
	return false
end

return table.freeze(Contract)
