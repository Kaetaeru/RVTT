--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Result = require(ReplicatedStorage.RVTT.Shared.Core.Result)
local ValueGuard = require(ReplicatedStorage.RVTT.Shared.Core.ValueGuard)

local DomainHelpers = {}

function DomainHelpers.isTable(value: unknown): boolean
	return type(value) == "table"
end

function DomainHelpers.hasString(
	payload: { [string]: unknown },
	key: string,
	maximum: number?
): boolean
	return ValueGuard.isBoundedString(payload[key], maximum or 256)
end

function DomainHelpers.hasNumber(payload: { [string]: unknown }, key: string): boolean
	return ValueGuard.isFiniteNumber(payload[key])
end

function DomainHelpers.isVector(value: unknown): boolean
	return ValueGuard.isVector3Record(value, 100000)
end

function DomainHelpers.authenticated(context): boolean
	return context.origin == "remote" and context.player ~= nil and context.playerId > 0
end

function DomainHelpers.system(context): boolean
	return context.origin == "system"
end

function DomainHelpers.requireRole(context, roles: { string }): boolean
	for _, role in roles do
		if context.role == role then
			return true
		end
	end
	return false
end

function DomainHelpers.dmOrSystem(context): boolean
	return context.origin == "system" or context.role == "dm"
end

function DomainHelpers.membership(context, domains): boolean
	local session = domains.session
	return session ~= nil and session.memberships[tostring(context.playerId)] ~= nil
end

function DomainHelpers.ownsCharacter(context, domains, characterId: unknown): boolean
	if context.role == "dm" then
		return true
	end
	if type(characterId) ~= "string" then
		return false
	end
	local characterDomain = domains.character
	if characterDomain == nil then
		return false
	end
	local character = characterDomain.characters[characterId] or characterDomain.drafts[characterId]
	return character ~= nil and character.ownerUserId == context.playerId
end

function DomainHelpers.controlsActor(context, domains, actorId: unknown): boolean
	if context.role == "dm" then
		return true
	end
	if type(actorId) ~= "string" then
		return false
	end
	local scene = domains.scene
	local actor = scene and scene.actors[actorId]
	return actor ~= nil
		and (actor.controllerUserId == context.playerId or actor.ownerUserId == context.playerId)
end

function DomainHelpers.ownsItem(context, domains, itemId: unknown): boolean
	if context.role == "dm" then
		return true
	end
	if type(itemId) ~= "string" then
		return false
	end
	local inventory = domains.inventory
	local location = inventory and inventory.locations[itemId]
	if location == nil then
		return false
	end
	if location.ownerUserId == context.playerId then
		return true
	end
	return location.characterId ~= nil
		and DomainHelpers.ownsCharacter(context, domains, location.characterId)
end

function DomainHelpers.copyFields(
	source: { [string]: unknown },
	allowed: { [string]: boolean }
): { [string]: unknown }
	local result = {}
	for key, value in source do
		if allowed[key] then
			result[key] = value
		end
	end
	return result
end

function DomainHelpers.validateAbilityScores(value: unknown): boolean
	if type(value) ~= "table" then
		return false
	end
	local scores = value :: { [string]: unknown }
	for _, ability in
		{ "strength", "dexterity", "constitution", "intelligence", "wisdom", "charisma" }
	do
		local score = scores[ability]
		if not ValueGuard.isFiniteNumber(score) then
			return false
		end

		local numericScore = score :: number
		if numericScore < 3 or numericScore > 20 or numericScore % 1 ~= 0 then
			return false
		end
	end
	return true
end

function DomainHelpers.notFound(kind: string, id: string)
	return Result.err(
		"NOT_FOUND",
		"error.common.not_found",
		false,
		{ kind = kind, id = id } :: { [string]: unknown }
	)
end

function DomainHelpers.conflict(reason: string)
	return Result.err(
		"CONFLICT",
		"error.common.conflict",
		false,
		{ reason = reason } :: { [string]: unknown }
	)
end

return table.freeze(DomainHelpers)
