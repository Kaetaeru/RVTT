--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Identity = require(ReplicatedStorage.RVTT.Shared.Core.Identity)
local Result = require(ReplicatedStorage.RVTT.Shared.Core.Result)
local Helpers = require(script.Parent.DomainHelpers)

local Domain = { id = "character", slice = 5 }
local DRAFT_FIELDS = {
	name = true,
	abilities = true,
	ancestryId = true,
	backgroundId = true,
	classId = true,
	choices = true,
}

function Domain.initialState()
	return { drafts = {}, characters = {} }
end

local function ownsDraft(context: any, domains: any, payload: any)
	return Helpers.ownsCharacter(context, domains, payload.characterId)
end

function Domain.register(registry: any)
	registry:register({
		commandType = "character.create_draft",
		domainId = Domain.id,
		authorize = function(context: any)
			return Helpers.authenticated(context)
		end,
		validate = function(payload: any)
			return payload.name == nil or type(payload.name) == "string"
		end,
		execute = function(context: any, state: any, payload: any)
			local id = Identity.new("character")
			state.drafts[id] = {
				id = id,
				ownerUserId = context.playerId,
				name = string.sub(payload.name or "", 1, 80),
				level = 1,
				abilities = {
					strength = 10,
					dexterity = 10,
					constitution = 10,
					intelligence = 10,
					wisdom = 10,
					charisma = 10,
				},
				choices = {},
				status = "draft",
				revision = 1,
			}
			return state.drafts[id]
		end,
	})

	registry:register({
		commandType = "character.update_draft",
		domainId = Domain.id,
		authorize = ownsDraft,
		validate = function(payload: any)
			return Helpers.hasString(payload, "characterId") and type(payload.patch) == "table"
		end,
		execute = function(_: any, state: any, payload: any)
			local draft = state.drafts[payload.characterId]
			if draft == nil then
				return Helpers.notFound("character_draft", payload.characterId)
			end
			local patch = Helpers.copyFields(payload.patch, DRAFT_FIELDS)
			if patch.name ~= nil then
				if type(patch.name) ~= "string" or #patch.name > 80 then
					return Result.err("VALIDATION_FAILED", "error.validation.failed", false)
				end
			end
			if patch.abilities ~= nil and not Helpers.validateAbilityScores(patch.abilities) then
				return Result.err("VALIDATION_FAILED", "error.validation.failed", false)
			end
			for key, value in patch do
				draft[key] = value
			end
			draft.revision += 1
			return draft
		end,
	})

	registry:register({
		commandType = "character.activate",
		domainId = Domain.id,
		authorize = ownsDraft,
		validate = function(payload: any)
			return Helpers.hasString(payload, "characterId")
		end,
		execute = function(_: any, state: any, payload: any)
			local draft = state.drafts[payload.characterId]
			if draft == nil then
				return Helpers.notFound("character_draft", payload.characterId)
			end
			if #draft.name == 0 or not Helpers.validateAbilityScores(draft.abilities) then
				return Helpers.conflict("character draft is incomplete")
			end
			draft.status = "active"
			draft.revision += 1
			state.characters[payload.characterId] = draft
			state.drafts[payload.characterId] = nil
			return draft
		end,
	})

	registry:register({
		commandType = "character.level_up",
		domainId = Domain.id,
		authorize = function(context: any, domains: any, payload: any)
			return Helpers.ownsCharacter(context, domains, payload.characterId)
		end,
		validate = function(payload: any)
			return Helpers.hasString(payload, "characterId") and Helpers.hasNumber(payload, "level")
		end,
		execute = function(_: any, state: any, payload: any)
			local character = state.characters[payload.characterId]
			if character == nil then
				return Helpers.notFound("character", payload.characterId)
			end
			local level = math.floor(payload.level)
			if level ~= character.level + 1 or level > 20 then
				return Helpers.conflict("invalid next level")
			end
			character.level = level
			character.choices[level] = payload.choices or {}
			character.revision += 1
			return character
		end,
	})
end

return table.freeze(Domain)
