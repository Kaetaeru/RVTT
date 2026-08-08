--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Identity = require(ReplicatedStorage.RVTT.Shared.Core.Identity)
local Helpers = require(script.Parent.DomainHelpers)

local Domain = { id = "session", slice = 1 }

local function publishRole(userId: number, role: string)
	local player = Players:GetPlayerByUserId(userId)
	if player ~= nil then
		player:SetAttribute("RVTT_Role", role)
	end
end

function Domain.initialState()
	return {
		campaignId = Identity.new("campaign", "default"),
		phase = "lobby",
		memberships = {},
		ready = {},
		selectedCharacter = {},
		assignmentPreviousOwner = {},
		connections = {},
		sceneId = nil,
	}
end

function Domain.register(registry: any)
	registry:register({
		commandType = "session.join",
		domainId = Domain.id,
		authorize = function(context: any)
			return Helpers.authenticated(context)
		end,
		execute = function(context: any, state: any)
			local player = context.player
			local key = tostring(context.playerId)
			state.memberships[key] = {
				userId = context.playerId,
				displayName = if player ~= nil
					then player.DisplayName
					else tostring(context.playerId),
				role = if context.role == "dm" then "dm" else "observer",
				joinedAt = os.time(),
			}
			state.connections[key] = "connected"
			publishRole(context.playerId, state.memberships[key].role)
			return { membership = state.memberships[key] }
		end,
	})

	registry:register({
		commandType = "session.assign_character",
		domainId = Domain.id,
		authorize = function(context: any)
			return Helpers.requireRole(context, { "dm" })
		end,
		validate = function(payload: any)
			return Helpers.hasNumber(payload, "userId")
				and (payload.characterId == nil or Helpers.hasString(payload, "characterId"))
		end,
		execute = function(_: any, state: any, payload: any, domains: any)
			state.assignmentPreviousOwner = state.assignmentPreviousOwner or {}
			local userId = math.floor(payload.userId)
			local key = tostring(userId)
			local membership = state.memberships[key]
			if userId <= 0 or membership == nil or membership.role == "dm" then
				return Helpers.conflict("assignable observer membership required")
			end

			local previousCharacterId = state.selectedCharacter[key]
			local characterId = payload.characterId
			if type(previousCharacterId) == "string" and previousCharacterId ~= characterId then
				local previousCharacter = domains.character.characters[previousCharacterId]
				if previousCharacter ~= nil then
					previousCharacter.ownerUserId =
						state.assignmentPreviousOwner[previousCharacterId]
					previousCharacter.revision += 1
				end
				state.assignmentPreviousOwner[previousCharacterId] = nil
			end
			if characterId ~= nil then
				local character = domains.character.characters[characterId]
				if character == nil or character.status ~= "active" then
					return Helpers.conflict("active character required")
				end
				if state.assignmentPreviousOwner[characterId] == nil then
					state.assignmentPreviousOwner[characterId] = character.ownerUserId
				end
				for assignedUserKey, assignedCharacterId in state.selectedCharacter do
					if assignedUserKey ~= key and assignedCharacterId == characterId then
						local assignedMembership = state.memberships[assignedUserKey]
						if assignedMembership ~= nil and assignedMembership.role ~= "dm" then
							assignedMembership.role = "observer"
							local assignedUserId = tonumber(assignedUserKey)
							if assignedUserId ~= nil then
								publishRole(assignedUserId, "observer")
							end
						end
						state.selectedCharacter[assignedUserKey] = nil
						state.ready[assignedUserKey] = nil
					end
				end
				character.ownerUserId = userId
				character.revision += 1
				membership.role = "player"
				state.selectedCharacter[key] = characterId
				state.ready[key] = false
			else
				membership.role = "observer"
				state.selectedCharacter[key] = nil
				state.ready[key] = nil
			end
			publishRole(userId, membership.role)

			local actors = domains.scene and domains.scene.actors
			if type(actors) == "table" then
				for _, actor in actors do
					if type(actor) == "table" and actor.controllerUserId == userId then
						actor.controllerUserId = nil
					end
					if
						type(previousCharacterId) == "string"
						and previousCharacterId ~= characterId
						and type(actor) == "table"
						and actor.sourceCharacterId == previousCharacterId
					then
						local previousCharacter = domains.character.characters[previousCharacterId]
						actor.ownerUserId = if previousCharacter ~= nil
							then previousCharacter.ownerUserId
							else nil
					end
				end
				if characterId ~= nil then
					for _, actor in actors do
						if type(actor) == "table" and actor.sourceCharacterId == characterId then
							actor.ownerUserId = userId
							actor.controllerUserId = userId
						end
					end
				end
			end

			return {
				userId = userId,
				role = membership.role,
				characterId = characterId,
				previousCharacterId = previousCharacterId,
			}
		end,
	})

	registry:register({
		commandType = "session.select_character",
		domainId = Domain.id,
		authorize = function(context: any, domains: any, payload: any)
			return Helpers.requireRole(context, { "dm" })
				and Helpers.membership(context, domains)
				and Helpers.ownsCharacter(context, domains, payload.characterId)
		end,
		validate = function(payload: any)
			return Helpers.hasString(payload, "characterId")
		end,
		execute = function(context: any, state: any, payload: any, domains: any)
			local character = domains.character.characters[payload.characterId]
			if character == nil or character.status ~= "active" then
				return Helpers.conflict("active character required")
			end
			local key = tostring(context.playerId)
			state.selectedCharacter[key] = payload.characterId
			state.ready[key] = false
			return { characterId = payload.characterId }
		end,
	})

	registry:register({
		commandType = "session.ready",
		domainId = Domain.id,
		authorize = function(context: any, domains: any)
			local membership = domains.session.memberships[tostring(context.playerId)]
			return membership ~= nil and (membership.role == "player" or membership.role == "dm")
		end,
		validate = function(payload: any)
			return type(payload.ready) == "boolean"
		end,
		execute = function(context: any, state: any, payload: any)
			local key = tostring(context.playerId)
			if state.connections[key] ~= "connected" then
				return Helpers.conflict("connected player required")
			end
			if state.selectedCharacter[key] == nil then
				return Helpers.conflict("character selection required")
			end
			state.ready[key] = payload.ready
			return { ready = payload.ready }
		end,
	})

	registry:register({
		commandType = "session.start",
		domainId = Domain.id,
		authorize = function(context: any)
			return Helpers.requireRole(context, { "dm" })
		end,
		validate = function(payload: any)
			return Helpers.hasString(payload, "sceneId")
		end,
		execute = function(_: any, state: any, payload: any)
			for userId, membership in state.memberships do
				if membership.role == "player" and state.connections[userId] == "connected" then
					if state.selectedCharacter[userId] == nil or state.ready[userId] ~= true then
						return Helpers.conflict(
							"connected players must select and ready a character"
						)
					end
				end
			end
			state.phase = "active"
			state.sceneId = payload.sceneId
			return { phase = state.phase, sceneId = state.sceneId }
		end,
	})

	registry:register({
		commandType = "session.connection",
		domainId = Domain.id,
		remoteAllowed = false,
		authorize = function(context: any)
			return Helpers.system(context)
		end,
		validate = function(payload: any)
			return type(payload.userId) == "number"
				and (payload.status == "connected" or payload.status == "disconnected")
		end,
		execute = function(_: any, state: any, payload: any)
			local key = tostring(payload.userId)
			state.connections[key] = payload.status
			if payload.status == "connected" then
				local membership = state.memberships[key]
				if membership ~= nil and type(membership.role) == "string" then
					publishRole(payload.userId, membership.role)
				end
			end
			return { userId = payload.userId, status = payload.status }
		end,
	})
end

return table.freeze(Domain)
