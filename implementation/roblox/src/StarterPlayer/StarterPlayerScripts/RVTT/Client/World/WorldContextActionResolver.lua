--!strict

local Players = game:GetService("Players")

export type Target = {
	kind: string,
	actorId: string?,
	objectId: string?,
	position: Vector3?,
	instance: Instance?,
}

export type Action = {
	id: string,
	label: string,
	kind: string,
	commandType: string,
	payload: { [string]: any },
	isDefault: boolean,
	enabled: boolean,
	disabledReason: string?,
	category: string,
	sortOrder: number,
	projectionRevision: number,
}

local Resolver = {}
Resolver.__index = Resolver

local INTERACTION_LABELS: { [string]: string } = {
	inspect = "살펴보기",
	open = "열기",
	close = "닫기",
	activate = "작동",
	deactivate = "작동 중지",
	search = "수색",
}

local INTERACTION_PRIORITY = {
	open = 10,
	activate = 20,
	inspect = 30,
	close = 40,
	deactivate = 50,
}

local CATEGORY_PRIORITY: { [string]: number } = {
	default = 0,
	action = 100,
	bonus_action = 200,
	movement = 300,
	interaction = 400,
	information = 500,
	dm = 600,
}

local function domains(replica: any): any
	local payload = replica.payload
	if type(payload) == "table" and type(payload.domains) == "table" then
		return payload.domains
	end
	return {}
end

local function membershipRole(allDomains: any, playerId: number): string?
	local session = allDomains.session
	local memberships = type(session) == "table" and session.memberships or nil
	local membership = type(memberships) == "table" and memberships[tostring(playerId)] or nil
	return type(membership) == "table" and membership.role or nil
end

local function sceneActor(allDomains: any, actorId: string): any
	local scene = allDomains.scene
	local actors = type(scene) == "table" and scene.actors or nil
	return type(actors) == "table" and actors[actorId] or nil
end

local function controlsActor(allDomains: any, playerId: number, actorId: string): boolean
	if membershipRole(allDomains, playerId) == "dm" then
		return true
	end
	local actor = sceneActor(allDomains, actorId)
	return type(actor) == "table"
		and (actor.controllerUserId == playerId or actor.ownerUserId == playerId)
end

local function activeTurn(allDomains: any, actorId: string): (boolean, any?)
	local encounter = allDomains.encounter
	local active = type(encounter) == "table" and encounter.active or nil
	if type(active) ~= "table" then
		return true, nil
	end
	local timeline = active.timeline
	local entry = type(timeline) == "table" and timeline[active.cursor] or nil
	return type(entry) == "table" and entry.actorId == actorId, active
end

local function attackProfiles(allDomains: any, actorId: string): { string }
	local actor = sceneActor(allDomains, actorId)
	if type(actor) ~= "table" then
		return {}
	end

	local attacks: any = actor.attacks
	local characterDomain = allDomains.character
	local characters = type(characterDomain) == "table" and characterDomain.characters or nil
	local character = type(characters) == "table" and characters[actor.sourceCharacterId or actorId]
		or nil
	if type(character) == "table" then
		attacks = character.attacks
		if type(attacks) ~= "table" or next(attacks) == nil then
			attacks = {
				["attack.unarmed"] = true,
			}
		end
	end

	local npcDomain = allDomains.npc_content
	local instances = type(npcDomain) == "table" and npcDomain.instances or nil
	local npc = type(instances) == "table" and instances[actor.sourceNpcId or actorId] or nil
	if type(npc) == "table" and type(npc.runtime) == "table" then
		attacks = npc.runtime.attacks
	end

	local result = {}
	if type(attacks) == "table" then
		for profileId in attacks do
			if type(profileId) == "string" then
				table.insert(result, profileId)
			end
		end
	end
	table.sort(result)
	return result
end

local function interactionIds(object: any): { string }
	local seen: { [string]: boolean } = {}
	local result = {}
	for _, interactionId in object.interactionIds or {} do
		if type(interactionId) == "string" and not seen[interactionId] then
			seen[interactionId] = true
			table.insert(result, interactionId)
		end
	end
	if not seen.inspect then
		table.insert(result, "inspect")
	end
	table.sort(result, function(left, right)
		local leftPriority = INTERACTION_PRIORITY[left] or 100
		local rightPriority = INTERACTION_PRIORITY[right] or 100
		if leftPriority == rightPriority then
			return left < right
		end
		return leftPriority < rightPriority
	end)
	return result
end

local function preferredInteraction(object: any, available: { string }): string?
	local state = type(object.state) == "table" and object.state.state or nil
	local preferred = if state == "open"
		then "close"
		elseif state == "active" then "deactivate"
		elseif state == "inactive" then "activate"
		else "open"
	for _, interactionId in available do
		if interactionId == preferred then
			return interactionId
		end
	end
	for _, interactionId in available do
		if interactionId == "inspect" then
			return interactionId
		end
	end
	return available[1]
end

local function sortActions(actions: { Action })
	table.sort(actions, function(left, right)
		if left.isDefault ~= right.isDefault then
			return left.isDefault
		end
		if left.sortOrder ~= right.sortOrder then
			return left.sortOrder < right.sortOrder
		end
		return left.id < right.id
	end)
end

function Resolver.new(replica: any, playerId: number?): any
	local localPlayer = Players.LocalPlayer
	return setmetatable({
		replica = replica,
		playerId = playerId or (if localPlayer ~= nil then localPlayer.UserId else 0),
	}, Resolver)
end

function Resolver:isControllable(actorId: string): boolean
	return controlsActor(domains(self.replica), self.playerId, actorId)
end

function Resolver:resolve(selectedActorId: string, target: Target): { Action }
	local allDomains = domains(self.replica)
	local playerId = self.playerId
	if not controlsActor(allDomains, playerId, selectedActorId) then
		return {}
	end

	local actions: { Action } = {}
	local ownsTurn, activeEncounter = activeTurn(allDomains, selectedActorId)

	if target.kind == "actor" and target.actorId ~= nil and target.actorId ~= selectedActorId then
		local targetActor = sceneActor(allDomains, target.actorId)
		if type(targetActor) ~= "table" or controlsActor(allDomains, playerId, target.actorId) then
			return actions
		end
		local enabled = true
		local disabledReason = nil
		if activeEncounter ~= nil and not ownsTurn then
			enabled = false
			disabledReason = "현재 턴이 아닙니다"
		elseif
			activeEncounter ~= nil
			and (
				type(activeEncounter.opportunities) ~= "table"
				or activeEncounter.opportunities.action ~= true
			)
		then
			enabled = false
			disabledReason = "행동을 이미 사용했습니다"
		end
		local hostile = targetActor.disposition == "hostile"
		local profiles = attackProfiles(allDomains, selectedActorId)
		for index, profileId in profiles do
			table.insert(actions, {
				id = "attack:" .. profileId,
				label = if index == 1 then "공격" else "공격 · " .. profileId,
				kind = "attack",
				commandType = "rules.attack",
				payload = {
					attackerId = selectedActorId,
					targetId = target.actorId,
					profileId = profileId,
				},
				isDefault = hostile and activeEncounter ~= nil and index == 1,
				enabled = enabled,
				disabledReason = disabledReason,
				category = "action",
				sortOrder = CATEGORY_PRIORITY.action + index,
				projectionRevision = self.replica.revision,
			})
		end
		sortActions(actions)
		return actions
	end

	if target.kind == "object" and target.objectId ~= nil then
		local scene = allDomains.scene
		local objects = type(scene) == "table" and scene.objects or nil
		local object = type(objects) == "table" and objects[target.objectId] or nil
		if type(object) ~= "table" then
			return actions
		end
		if object.hidden == true and membershipRole(allDomains, playerId) ~= "dm" then
			return actions
		end
		local available = interactionIds(object)
		local preferred = preferredInteraction(object, available)
		for _, interactionId in available do
			table.insert(actions, {
				id = "interact:" .. interactionId,
				label = INTERACTION_LABELS[interactionId] or interactionId,
				kind = "interact",
				commandType = "exploration.interact",
				payload = {
					actorId = selectedActorId,
					objectId = target.objectId,
					interactionId = interactionId,
				},
				isDefault = interactionId == preferred,
				enabled = true,
				disabledReason = nil,
				category = if interactionId == "inspect" then "information" else "interaction",
				sortOrder = if interactionId == "inspect"
					then CATEGORY_PRIORITY.information + (INTERACTION_PRIORITY[interactionId] or 100)
					else CATEGORY_PRIORITY.interaction
						+ (INTERACTION_PRIORITY[interactionId] or 100),
				projectionRevision = self.replica.revision,
			})
		end
		table.insert(actions, {
			id = "search",
			label = INTERACTION_LABELS.search,
			kind = "search",
			commandType = "exploration.search",
			payload = {
				actorId = selectedActorId,
				objectId = target.objectId,
			},
			isDefault = false,
			enabled = true,
			disabledReason = nil,
			category = "information",
			sortOrder = CATEGORY_PRIORITY.information + 200,
			projectionRevision = self.replica.revision,
		})
		sortActions(actions)
		return actions
	end

	if target.kind == "surface" and target.position ~= nil then
		local actor = sceneActor(allDomains, selectedActorId)
		local current = type(actor) == "table" and actor.position or nil
		local movementAllowed = ownsTurn
		local disabledReason = if ownsTurn then nil else "현재 턴이 아닙니다"
		if movementAllowed and activeEncounter ~= nil then
			local remaining = activeEncounter.movementRemaining
			if type(remaining) ~= "number" or type(current) ~= "table" then
				movementAllowed = false
				disabledReason = "남은 이동 거리를 확인할 수 없습니다"
			else
				local dx = target.position.X - current.x
				local dy = target.position.Y - current.y
				local dz = target.position.Z - current.z
				movementAllowed = math.sqrt(dx * dx + dy * dy + dz * dz) <= remaining
				if not movementAllowed then
					disabledReason = "남은 이동 거리가 부족합니다"
				end
			end
		end
		table.insert(actions, {
			id = "move",
			label = "이동",
			kind = "move",
			commandType = "movement.commit",
			payload = {
				actorId = selectedActorId,
				destination = {
					x = target.position.X,
					y = target.position.Y,
					z = target.position.Z,
				},
			},
			isDefault = true,
			enabled = movementAllowed,
			disabledReason = disabledReason,
			category = "movement",
			sortOrder = CATEGORY_PRIORITY.movement,
			projectionRevision = self.replica.revision,
		})
	end

	sortActions(actions)
	return actions
end

function Resolver.defaultAction(_: any, actions: { Action }): Action?
	for _, action in actions do
		if action.isDefault and action.enabled then
			return action
		end
	end
	return nil
end

return Resolver
