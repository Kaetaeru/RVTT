--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Identity = require(ReplicatedStorage.RVTT.Shared.Core.Identity)
local Dice = require(ReplicatedStorage.RVTT.Shared.Rules.Dice)
local Helpers = require(script.Parent.DomainHelpers)
local ActorProfileResolver = require(script.Parent.Parent.Rules.ActorProfileResolver)
local RuleResolver = require(script.Parent.Parent.Rules.RuleResolver)

local Domain = { id = "rules", slice = 2 }
local SHEET_ROLL_KINDS = {
	ability = true,
	saving_throw = true,
	skill = true,
	initiative = true,
	weapon_attack = true,
	weapon_damage = true,
	damage_cantrip = true,
	spell_attack = true,
	hit_die = true,
	death_save = true,
	feature_roll = true,
}
local SOURCE_REQUIRED = {
	ability = true,
	saving_throw = true,
	skill = true,
	weapon_attack = true,
	weapon_damage = true,
	damage_cantrip = true,
	feature_roll = true,
}
local CLIENT_RULE_FIELDS = {
	"ability",
	"proficient",
	"mode",
	"profileId",
	"count",
	"sides",
	"attackModifier",
	"damageModifier",
	"modifier",
	"remaining",
}

local function isFiniteInteger(value: any): boolean
	return type(value) == "number"
		and value == value
		and value > -math.huge
		and value < math.huge
		and value % 1 == 0
end

function Domain.initialState()
	return {
		rollRecords = {},
		actorStates = {},
		challenges = {},
		conditions = {},
	}
end

local function ensureActorState(state: any, actorId: string, domains: any)
	local existing = state.actorStates[actorId]
	if existing ~= nil then
		return existing
	end
	local profile = ActorProfileResolver.resolve(actorId, domains)
	if profile == nil then
		return nil
	end
	local actorState = {
		currentHitPoints = profile.maximumHitPoints,
		maximumHitPoints = profile.maximumHitPoints,
		temporaryHitPoints = 0,
		profileRevision = 1,
	}
	state.actorStates[actorId] = actorState
	return actorState
end

local function record(state: any, context: any, kind: string, data: any)
	local id = Identity.new("roll")
	state.rollRecords[id] = {
		id = id,
		commandId = context.commandId,
		kind = kind,
		data = data,
		createdAt = os.time(),
		audience = "public",
	}
	return state.rollRecords[id]
end

local function characterForActor(actorId: string, domains: any): any?
	local actor = domains.scene.actors[actorId]
	if type(actor) ~= "table" or type(actor.sourceCharacterId) ~= "string" then
		return nil
	end
	return domains.character.characters[actor.sourceCharacterId]
end

local function sheetD20(
	state: any,
	context: any,
	profile: any,
	payload: any,
	ability: string?,
	proficient: boolean,
	additionalModifier: number?
): any
	local natural, rolls = Dice.rollD20(nil)
	local modifier = if ability ~= nil then RuleResolver.abilityModifier(profile, ability) else 0
	if proficient then
		modifier += profile.proficiencyBonus
	end
	modifier += additionalModifier or 0
	return record(state, context, payload.rollKind, {
		actorId = payload.actorId,
		rollKind = payload.rollKind,
		sourceId = payload.sourceId,
		natural = natural,
		rolls = rolls,
		modifier = modifier,
		total = natural + modifier,
	})
end

function Domain.register(registry: any)
	registry:register({
		commandType = "rules.sheet_roll",
		domainId = Domain.id,
		authorize = function(context: any, domains: any, payload: any)
			return Helpers.controlsActor(context, domains, payload.actorId)
		end,
		validate = function(payload: any)
			if
				not (
					Helpers.hasString(payload, "actorId")
					and Helpers.hasString(payload, "rollKind", 64)
					and SHEET_ROLL_KINDS[payload.rollKind] == true
					and (
						SOURCE_REQUIRED[payload.rollKind] ~= true
						or Helpers.hasString(payload, "sourceId", 128)
					)
				)
			then
				return false
			end
			for _, field in CLIENT_RULE_FIELDS do
				if payload[field] ~= nil then
					return false
				end
			end
			return true
		end,
		execute = function(context: any, state: any, payload: any, domains: any)
			local profile = ActorProfileResolver.resolve(payload.actorId, domains)
			if profile == nil then
				return Helpers.notFound("actor", payload.actorId)
			end
			local character = characterForActor(payload.actorId, domains)
			if payload.rollKind == "hit_die" then
				local hitDice = if type(character) == "table" then character.hitDice else nil
				if
					type(hitDice) ~= "table"
					or not isFiniteInteger(hitDice.sides)
					or hitDice.sides < 2
					or hitDice.sides > 100
				then
					return Helpers.notFound("hit_dice", payload.actorId)
				end
				if not isFiniteInteger(hitDice.remaining) or hitDice.remaining <= 0 then
					return Helpers.conflict("hit die is unavailable")
				end
				local modifier = RuleResolver.abilityModifier(profile, "constitution")
				local total, rolls = Dice.rollFormula(1, hitDice.sides, modifier)
				hitDice.remaining -= 1
				character.revision += 1
				return record(state, context, payload.rollKind, {
					actorId = payload.actorId,
					rollKind = payload.rollKind,
					rolls = rolls,
					modifier = modifier,
					total = math.max(0, total),
					remaining = hitDice.remaining,
				})
			end
			if payload.rollKind == "weapon_damage" or payload.rollKind == "damage_cantrip" then
				local attack = profile.attacks[payload.sourceId]
				if type(attack) ~= "table" then
					return Helpers.notFound("attack_profile", tostring(payload.sourceId))
				end
				local damageModifier = RuleResolver.abilityModifier(
					profile,
					attack.ability or "strength"
				) + (attack.damageModifier or 0)
				local total, rolls = Dice.rollFormula(
					math.clamp(math.floor(attack.count or 1), 0, 20),
					math.clamp(math.floor(attack.sides or 4), 2, 100),
					damageModifier
				)
				return record(state, context, payload.rollKind, {
					actorId = payload.actorId,
					rollKind = payload.rollKind,
					sourceId = payload.sourceId,
					rolls = rolls,
					modifier = damageModifier,
					total = math.max(0, total),
				})
			end
			if payload.rollKind == "death_save" then
				local actorState = ensureActorState(state, payload.actorId, domains)
				if actorState == nil then
					return Helpers.notFound("actor_state", payload.actorId)
				end
				if actorState.currentHitPoints > 0 then
					return Helpers.conflict("death save requires zero hit points")
				end
				return sheetD20(state, context, profile, payload, nil, false, nil)
			end
			if payload.rollKind == "initiative" then
				return sheetD20(state, context, profile, payload, "dexterity", false, nil)
			end
			if payload.rollKind == "ability" then
				if type(profile.abilities[payload.sourceId]) ~= "number" then
					return Helpers.notFound("ability", payload.sourceId)
				end
				return sheetD20(state, context, profile, payload, payload.sourceId, false, nil)
			end
			if payload.rollKind == "saving_throw" or payload.rollKind == "skill" then
				local collection = if type(character) == "table"
					then character[if payload.rollKind == "skill" then "skills" else "saves"]
					else nil
				local source = if type(collection) == "table"
					then collection[payload.sourceId]
					else nil
				if type(source) ~= "table" or type(source.ability) ~= "string" then
					return Helpers.notFound(payload.rollKind, payload.sourceId)
				end
				return sheetD20(
					state,
					context,
					profile,
					payload,
					source.ability,
					source.proficient == true,
					nil
				)
			end
			if payload.rollKind == "weapon_attack" then
				local attack = profile.attacks[payload.sourceId]
				if type(attack) ~= "table" then
					return Helpers.notFound("attack_profile", payload.sourceId)
				end
				return sheetD20(
					state,
					context,
					profile,
					payload,
					attack.ability or "strength",
					attack.proficient == true,
					attack.attackModifier
				)
			end
			if payload.rollKind == "spell_attack" then
				local spellcasting = if type(character) == "table"
					then character.spellcasting
					else nil
				if type(spellcasting) ~= "table" or type(spellcasting.ability) ~= "string" then
					return Helpers.notFound("spellcasting", payload.actorId)
				end
				return sheetD20(state, context, profile, payload, spellcasting.ability, true, nil)
			end
			local features = if type(character) == "table" then character.classFeatures else nil
			local feature = if type(features) == "table" then features[payload.sourceId] else nil
			if type(feature) ~= "table" or type(feature.rollAbility) ~= "string" then
				return Helpers.notFound("feature", payload.sourceId)
			end
			return sheetD20(
				state,
				context,
				profile,
				payload,
				feature.rollAbility,
				feature.proficient == true,
				nil
			)
		end,
	})

	registry:register({
		commandType = "rules.update_vitals",
		domainId = Domain.id,
		authorize = function(context: any, domains: any, payload: any)
			return Helpers.controlsActor(context, domains, payload.actorId)
		end,
		validate = function(payload: any)
			local currentDelta = payload.deltaCurrentHitPoints
			local temporaryDelta = payload.deltaTemporaryHitPoints
			return Helpers.hasString(payload, "actorId")
				and (currentDelta == nil or Helpers.hasNumber(payload, "deltaCurrentHitPoints"))
				and (temporaryDelta == nil or Helpers.hasNumber(payload, "deltaTemporaryHitPoints"))
				and (currentDelta ~= nil or temporaryDelta ~= nil)
		end,
		execute = function(_: any, state: any, payload: any, domains: any)
			local actorState = ensureActorState(state, payload.actorId, domains)
			if actorState == nil then
				return Helpers.notFound("actor", payload.actorId)
			end
			if type(payload.deltaCurrentHitPoints) == "number" then
				actorState.currentHitPoints = math.clamp(
					actorState.currentHitPoints + math.floor(payload.deltaCurrentHitPoints),
					0,
					actorState.maximumHitPoints
				)
			end
			if type(payload.deltaTemporaryHitPoints) == "number" then
				actorState.temporaryHitPoints = math.max(
					0,
					actorState.temporaryHitPoints + math.floor(payload.deltaTemporaryHitPoints)
				)
			end
			actorState.profileRevision += 1
			return actorState
		end,
	})

	registry:register({
		commandType = "rules.create_challenge",
		domainId = Domain.id,
		authorize = function(context: any)
			return Helpers.requireRole(context, { "dm" })
		end,
		validate = function(payload: any)
			return Helpers.hasString(payload, "ability")
				and Helpers.hasNumber(payload, "difficultyClass")
				and payload.difficultyClass >= 1
				and payload.difficultyClass <= 40
		end,
		execute = function(_: any, state: any, payload: any)
			local challengeId = Identity.new("challenge")
			state.challenges[challengeId] = {
				id = challengeId,
				ability = payload.ability,
				proficient = payload.proficient == true,
				difficultyClass = math.floor(payload.difficultyClass),
				status = "open",
				labelKey = payload.labelKey,
			}
			return { challengeId = challengeId }
		end,
	})

	registry:register({
		commandType = "rules.ability_check",
		domainId = Domain.id,
		authorize = function(context: any, domains: any, payload: any)
			return Helpers.controlsActor(context, domains, payload.actorId)
		end,
		validate = function(payload: any)
			return Helpers.hasString(payload, "actorId")
				and Helpers.hasString(payload, "challengeId")
		end,
		execute = function(context: any, state: any, payload: any, domains: any)
			local challenge = state.challenges[payload.challengeId]
			if challenge == nil or challenge.status ~= "open" then
				return Helpers.notFound("challenge", payload.challengeId)
			end
			local profile = ActorProfileResolver.resolve(payload.actorId, domains)
			if profile == nil then
				return Helpers.notFound("actor", payload.actorId)
			end
			local resolution = RuleResolver.rollCheck(
				profile,
				challenge.ability,
				challenge.proficient,
				challenge.difficultyClass,
				nil
			)
			resolution.actorId = payload.actorId
			resolution.challengeId = payload.challengeId
			return record(state, context, "ability_check", resolution)
		end,
	})

	registry:register({
		commandType = "rules.saving_throw",
		domainId = Domain.id,
		authorize = function(context: any, domains: any, payload: any)
			return Helpers.controlsActor(context, domains, payload.actorId)
		end,
		validate = function(payload: any)
			return Helpers.hasString(payload, "actorId")
				and Helpers.hasString(payload, "challengeId")
		end,
		execute = function(context: any, state: any, payload: any, domains: any)
			local challenge = state.challenges[payload.challengeId]
			if challenge == nil or challenge.status ~= "open" then
				return Helpers.notFound("challenge", payload.challengeId)
			end
			local profile = ActorProfileResolver.resolve(payload.actorId, domains)
			if profile == nil then
				return Helpers.notFound("actor", payload.actorId)
			end
			local resolution = RuleResolver.rollCheck(
				profile,
				challenge.ability,
				true,
				challenge.difficultyClass,
				nil
			)
			resolution.actorId = payload.actorId
			resolution.challengeId = payload.challengeId
			return record(state, context, "saving_throw", resolution)
		end,
	})

	registry:register({
		commandType = "rules.attack",
		domainId = Domain.id,
		authorize = function(context: any, domains: any, payload: any)
			return Helpers.controlsActor(context, domains, payload.attackerId)
		end,
		validate = function(payload: any)
			return Helpers.hasString(payload, "attackerId")
				and Helpers.hasString(payload, "targetId")
				and Helpers.hasString(payload, "profileId")
		end,
		execute = function(context: any, state: any, payload: any, domains: any)
			local attackerProfile = ActorProfileResolver.resolve(payload.attackerId, domains)
			local targetProfile = ActorProfileResolver.resolve(payload.targetId, domains)
			if attackerProfile == nil then
				return Helpers.notFound("actor", payload.attackerId)
			end
			if targetProfile == nil then
				return Helpers.notFound("actor", payload.targetId)
			end
			local attackProfile = attackerProfile.attacks[payload.profileId]
			if attackProfile == nil then
				return Helpers.notFound("attack_profile", payload.profileId)
			end
			local encounter = domains.encounter.active
			if encounter ~= nil then
				local currentEntry = encounter.timeline[encounter.cursor]
				if currentEntry == nil or currentEntry.actorId ~= payload.attackerId then
					return Helpers.conflict("attacker does not own the active turn")
				end
				if encounter.opportunities.action ~= true then
					return Helpers.conflict("action opportunity is unavailable")
				end
			end

			local targetState = ensureActorState(state, payload.targetId, domains)
			if targetState == nil then
				return Helpers.notFound("actor_state", payload.targetId)
			end
			ensureActorState(state, payload.attackerId, domains)

			local resolution = RuleResolver.rollAttack(
				attackerProfile,
				attackProfile,
				targetProfile.armorClass,
				nil
			)
			if resolution.hit then
				local absorbed = math.min(targetState.temporaryHitPoints, resolution.damage)
				targetState.temporaryHitPoints -= absorbed
				targetState.currentHitPoints =
					math.max(0, targetState.currentHitPoints - (resolution.damage - absorbed))
				resolution.absorbedByTemporaryHitPoints = absorbed
				resolution.targetHitPoints = targetState.currentHitPoints
			end
			if encounter ~= nil then
				encounter.opportunities.action = false
			end
			resolution.attackerId = payload.attackerId
			resolution.targetId = payload.targetId
			resolution.profileId = payload.profileId
			return record(state, context, "attack", resolution)
		end,
	})

	registry:register({
		commandType = "rules.set_actor_state",
		domainId = Domain.id,
		authorize = function(context: any)
			return Helpers.requireRole(context, { "dm" })
		end,
		validate = function(payload: any)
			return Helpers.hasString(payload, "actorId")
				and Helpers.hasNumber(payload, "currentHitPoints")
				and Helpers.hasNumber(payload, "maximumHitPoints")
		end,
		execute = function(_: any, state: any, payload: any, domains: any)
			if ActorProfileResolver.resolve(payload.actorId, domains) == nil then
				return Helpers.notFound("actor", payload.actorId)
			end
			local maximum = math.max(1, math.floor(payload.maximumHitPoints))
			state.actorStates[payload.actorId] = {
				currentHitPoints = math.clamp(math.floor(payload.currentHitPoints), 0, maximum),
				maximumHitPoints = maximum,
				temporaryHitPoints = math.max(0, math.floor(payload.temporaryHitPoints or 0)),
				profileRevision = 1,
			}
			return state.actorStates[payload.actorId]
		end,
	})
end

return table.freeze(Domain)
