--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DeepCopy = require(ReplicatedStorage.RVTT.Shared.Core.DeepCopy)

local DomainProjectionPolicy = {}

local function publicActor(actor)
	return {
		id = actor.id,
		sourceCharacterId = actor.sourceCharacterId,
		sourceNpcId = actor.sourceNpcId,
		ownerUserId = actor.ownerUserId,
		controllerUserId = actor.controllerUserId,
		position = actor.position,
		incarnation = actor.incarnation,
	}
end

local function projectSession(state, viewer)
	return {
		campaignId = state.campaignId,
		phase = state.phase,
		memberships = DeepCopy(state.memberships),
		ready = DeepCopy(state.ready),
		selectedCharacter = if viewer.role == "dm"
			then DeepCopy(state.selectedCharacter)
			else {
				[tostring(viewer.userId)] = state.selectedCharacter[tostring(viewer.userId)],
			},
		connections = DeepCopy(state.connections),
		sceneId = state.sceneId,
	}
end

local function projectScene(state, viewer)
	local actors = {}
	for actorId, actor in state.actors do
		if
			viewer.role == "dm"
			or actor.hidden ~= true
			or actor.ownerUserId == viewer.userId
			or actor.controllerUserId == viewer.userId
		then
			actors[actorId] = publicActor(actor)
		end
	end
	local objects = {}
	for objectId, object in state.objects do
		if viewer.role == "dm" or object.hidden ~= true then
			objects[objectId] = {
				id = object.id,
				kind = object.kind,
				position = object.position,
				state = object.state,
				interactionIds = object.interactionIds,
				incarnation = object.incarnation,
				revision = object.revision,
			}
		end
	end
	return {
		activeSceneId = state.activeSceneId,
		actors = actors,
		objects = objects,
		sceneRevision = state.sceneRevision,
	}
end

local function projectCharacter(state, viewer)
	if viewer.role == "dm" then
		return DeepCopy(state)
	end
	local drafts = {}
	local characters = {}
	for id, draft in state.drafts do
		if draft.ownerUserId == viewer.userId then
			drafts[id] = DeepCopy(draft)
		end
	end
	for id, character in state.characters do
		if character.ownerUserId == viewer.userId then
			characters[id] = DeepCopy(character)
		else
			characters[id] = {
				id = character.id,
				ownerUserId = character.ownerUserId,
				name = character.name,
				level = character.level,
				status = character.status,
			}
		end
	end
	return { drafts = drafts, characters = characters }
end

local function projectInventory(state, viewer, domains)
	if viewer.role == "dm" then
		return DeepCopy(state)
	end
	local items = {}
	local locations = {}
	for itemId, location in state.locations do
		local visible = location.kind == "ground" or location.ownerUserId == viewer.userId
		if not visible and location.characterId ~= nil then
			local character = domains.character.characters[location.characterId]
			visible = character ~= nil and character.ownerUserId == viewer.userId
		end
		if visible then
			items[itemId] = DeepCopy(state.items[itemId])
			locations[itemId] = DeepCopy(location)
		end
	end
	return { items = items, locations = locations }
end

local function projectExploration(state, viewer)
	if viewer.role == "dm" then
		return DeepCopy(state)
	end
	local knowledge = {}
	local prefix = tostring(viewer.userId) .. ":"
	for key, value in state.knowledge do
		if string.sub(key, 1, #prefix) == prefix then
			knowledge[key] = value
		end
	end
	local searches = {}
	for id, search in state.searches do
		if search.observerUserId == viewer.userId then
			searches[id] = DeepCopy(search)
		end
	end
	return {
		objectStates = DeepCopy(state.objectStates),
		knowledge = knowledge,
		searches = searches,
		fog = {},
	}
end

local function projectRules(state, viewer)
	local challenges = {}
	for challengeId, challenge in state.challenges do
		challenges[challengeId] = {
			id = challenge.id,
			ability = challenge.ability,
			proficient = challenge.proficient,
			status = challenge.status,
			labelKey = challenge.labelKey,
		}
		if viewer.role == "dm" then
			challenges[challengeId].difficultyClass = challenge.difficultyClass
		end
	end
	return {
		rollRecords = DeepCopy(state.rollRecords),
		actorStates = DeepCopy(state.actorStates),
		challenges = challenges,
		conditions = DeepCopy(state.conditions),
	}
end

local function projectJournal(state, viewer)
	local documents = {}
	for id, document in state.documents do
		if
			viewer.role == "dm"
			or document.ownerUserId == viewer.userId
			or document.visibility == "party"
			or document.visibility == "public"
		then
			documents[id] = DeepCopy(document)
		end
	end
	local now = os.time()
	local pings = {}
	for id, ping in state.pings do
		if ping.expiresAt > now then
			pings[id] = DeepCopy(ping)
		end
	end
	return { documents = documents, pings = pings }
end

function DomainProjectionPolicy.project(domainId: string, state, viewer, domains)
	if domainId == "session" then
		return projectSession(state, viewer)
	end
	if domainId == "scene" then
		return projectScene(state, viewer)
	end
	if domainId == "character" then
		return projectCharacter(state, viewer)
	end
	if domainId == "inventory" then
		return projectInventory(state, viewer, domains)
	end
	if domainId == "exploration" then
		return projectExploration(state, viewer)
	end
	if domainId == "rules" then
		return projectRules(state, viewer)
	end
	if domainId == "journal" then
		return projectJournal(state, viewer)
	end
	if domainId == "ui_preferences" then
		return {
			byUser = {
				[tostring(viewer.userId)] = DeepCopy(state.byUser[tostring(viewer.userId)] or {}),
			},
		}
	end
	if domainId == "scene_authoring" or domainId == "dm_workspace" or domainId == "release" then
		return if viewer.role == "dm" then DeepCopy(state) else {}
	end
	if domainId == "content" then
		return {
			active = DeepCopy(state.active),
			localization = DeepCopy(state.localization),
		}
	end
	if domainId == "character_content" then
		return { coverage = DeepCopy(state.coverage), rightsStatus = state.rightsStatus }
	end
	if domainId == "rules_content" then
		return { rightsStatus = state.rightsStatus }
	end
	if domainId == "npc_content" then
		return {
			instances = DeepCopy(state.instances),
			definitions = if viewer.role == "dm" then DeepCopy(state.definitions) else {},
		}
	end
	return DeepCopy(state)
end

return table.freeze(DomainProjectionPolicy)
