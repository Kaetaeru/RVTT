--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DeepCopy = require(ReplicatedStorage.RVTT.Shared.Core.DeepCopy)

local DomainProjectionPolicy = {}

local function actorVisible(actor: any, viewer: any): boolean
	return viewer.role == "dm"
		or actor.hidden ~= true
		or actor.ownerUserId == viewer.userId
		or actor.controllerUserId == viewer.userId
end

local function projectedActorVisible(domains: any, viewer: any, actorId: any): boolean
	if type(actorId) ~= "string" then
		return false
	end
	local scene = domains.scene
	local actors = if type(scene) == "table" then scene.actors else nil
	local actor = if type(actors) == "table" then actors[actorId] else nil
	return type(actor) == "table" and actorVisible(actor, viewer)
end

local function viewerControlsActor(domains: any, viewer: any, actorId: any): boolean
	if viewer.role == "dm" then
		return true
	end
	if type(actorId) ~= "string" then
		return false
	end
	local scene = domains.scene
	local actors = if type(scene) == "table" then scene.actors else nil
	local actor = if type(actors) == "table" then actors[actorId] else nil
	return type(actor) == "table"
		and (actor.ownerUserId == viewer.userId or actor.controllerUserId == viewer.userId)
end

local function publicActor(actor: any): any
	return {
		id = actor.id,
		sourceCharacterId = actor.sourceCharacterId,
		sourceNpcId = actor.sourceNpcId,
		ownerUserId = actor.ownerUserId,
		controllerUserId = actor.controllerUserId,
		position = actor.position,
		incarnation = actor.incarnation,
		disposition = actor.disposition,
	}
end

local function projectSession(state: any, viewer: any): any
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

local function projectScene(state: any, viewer: any): any
	local actors: { [string]: any } = {}
	for actorId, actor in state.actors do
		if actorVisible(actor, viewer) then
			actors[actorId] = publicActor(actor)
		end
	end
	local objects: { [string]: any } = {}
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

local function projectEncounter(state: any, viewer: any, domains: any): any
	if viewer.role == "dm" or type(state.active) ~= "table" then
		return if viewer.role == "dm" then DeepCopy(state) else { active = nil }
	end
	local active = state.active
	local currentEntry = if type(active.timeline) == "table"
			and type(active.cursor) == "number"
		then active.timeline[active.cursor]
		else nil
	local currentActorId = if type(currentEntry) == "table" then currentEntry.actorId else nil
	local timeline = {}
	local visibleCursor = nil
	if type(active.timeline) == "table" then
		for index, entry in active.timeline do
			if type(entry) == "table" and projectedActorVisible(domains, viewer, entry.actorId) then
				table.insert(timeline, DeepCopy(entry))
				if index == active.cursor then
					visibleCursor = #timeline
				end
			end
		end
	end
	local controlsCurrent = viewerControlsActor(domains, viewer, currentActorId)
	return {
		active = {
			id = active.id,
			round = active.round,
			status = active.status,
			timeline = timeline,
			cursor = visibleCursor,
			activeActorId = if projectedActorVisible(domains, viewer, currentActorId)
				then currentActorId
				else nil,
			opportunities = if controlsCurrent then DeepCopy(active.opportunities) else nil,
			movementRemaining = if controlsCurrent then active.movementRemaining else nil,
		},
	}
end

local function projectCharacter(state: any, viewer: any): any
	if viewer.role == "dm" then
		return DeepCopy(state)
	end
	local drafts: { [string]: any } = {}
	local characters: { [string]: any } = {}
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

local function projectInventory(state: any, viewer: any, domains: any): any
	if viewer.role == "dm" then
		return DeepCopy(state)
	end
	local items: { [string]: any } = {}
	local locations: { [string]: any } = {}
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

local function projectExploration(state: any, viewer: any): any
	if viewer.role == "dm" then
		return DeepCopy(state)
	end
	local knowledge: { [string]: any } = {}
	local prefix = tostring(viewer.userId) .. ":"
	for key, value in state.knowledge do
		if string.sub(key, 1, #prefix) == prefix then
			knowledge[key] = value
		end
	end
	local searches: { [string]: any } = {}
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

local function recordVisible(record: any, viewer: any, domains: any): boolean
	if viewer.role == "dm" or type(record) ~= "table" then
		return true
	end
	local data = record.data
	if type(data) ~= "table" then
		return true
	end
	for _, key in { "actorId", "attackerId", "targetId" } do
		local actorId = data[key]
		if actorId ~= nil and not projectedActorVisible(domains, viewer, actorId) then
			return false
		end
	end
	return true
end

local function projectRules(state: any, viewer: any, domains: any): any
	local challenges: { [string]: any } = {}
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
	local rollRecords: { [string]: any } = {}
	for recordId, record in state.rollRecords do
		if recordVisible(record, viewer, domains) then
			rollRecords[recordId] = DeepCopy(record)
		end
	end
	local actorStates: { [string]: any } = {}
	for actorId, actorState in state.actorStates do
		if projectedActorVisible(domains, viewer, actorId) then
			actorStates[actorId] = DeepCopy(actorState)
		end
	end
	local conditions: { [string]: any } = {}
	for conditionId, condition in state.conditions do
		if
			type(condition) ~= "table"
			or condition.actorId == nil
			or projectedActorVisible(domains, viewer, condition.actorId)
		then
			conditions[conditionId] = DeepCopy(condition)
		end
	end
	return {
		rollRecords = rollRecords,
		actorStates = actorStates,
		challenges = challenges,
		conditions = conditions,
	}
end

local function projectJournal(state: any, viewer: any): any
	local documents: { [string]: any } = {}
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
	local pings: { [string]: any } = {}
	for id, ping in state.pings do
		if ping.expiresAt > now then
			pings[id] = DeepCopy(ping)
		end
	end
	return { documents = documents, pings = pings }
end

function DomainProjectionPolicy.project(
	domainId: string,
	state: any,
	viewer: any,
	domains: any
): any
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
	if domainId == "encounter" then
		return projectEncounter(state, viewer, domains)
	end
	if domainId == "rules" then
		return projectRules(state, viewer, domains)
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
