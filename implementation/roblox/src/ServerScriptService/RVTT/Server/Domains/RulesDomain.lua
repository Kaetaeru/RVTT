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

function Domain.register(registry: any)
	registry:register({
		commandType = "rules.sheet_roll",
		domainId = Domain.id,
		authorize = function(context: any, domains: any, payload: any)
			return Helpers.controlsActor(context, domains, payload.actorId)
		end,
		validate = function(payload: any)
			return Helpers.hasString(payload, "actorId")
				and Helpers.hasString(payload, "rollKind", 64)
				and SHEET_ROLL_KINDS[payload.rollKind] == true
				and (payload.ability == nil or Helpers.hasString(payload, "ability", 32))
		end,
		execute = function(context: any, state: any, payload: any, domains: any)
			local profile = ActorProfileResolver.resolve(payload.actorId, domains)
			if profile == nil then
				return Helpers.notFound("actor", payload.actorId)
			end
			if payload.rollKind == "hit_die" then
				local actor = domains.scene.actors[payload.actorId]
				local character = if type(actor) == "table"
						and type(actor.sourceCharacterId) == "string"
					then domains.character.characters[actor.sourceCharacterId]
					else nil
				local hitDice = if type(character) == "table" then character.hitDice else nil
				if type(hitDice) ~= "table" or type(hitDice.sides) ~= "number" then
					return Helpers.notFound("hit_dice", payload.actorId)
				end
				local modifier = RuleResolver.abilityModifier(profile, "constitution")
				local total, rolls =
					Dice.rollFormula(1, math.clamp(math.floor(hitDice.sides), 2, 100), modifier)
				return record(state, context, payload.rollKind, {
					actorId = payload.actorId,
					rollKind = payload.rollKind,
					rolls = rolls,
					modifier = modifier,
					total = math.max(0, total),
				})
			end
			if payload.rollKind == "weapon_damage" or payload.rollKind == "damage_cantrip" then
				local attack = if type(payload.profileId) == "string"
					then profile.attacks[payload.profileId]
					else nil
				if type(attack) ~= "table" then
					return Helpers.notFound("attack_profile", tostring(payload.profileId))
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
					profileId = payload.profileId,
					rolls = rolls,
					modifier = damageModifier,
					total = math.max(0, total),
				})
			end
			local natural, rolls = Dice.rollD20(payload.mode)
			local modifier = 0
			if type(payload.ability) == "string" then
				modifier = RuleResolver.abilityModifier(profile, payload.ability)
			end
			if payload.proficient == true then
				modifier += profile.proficiencyBonus
			end
			return record(state, context, payload.rollKind, {
				actorId = payload.actorId,
				rollKind = payload.rollKind,
				natural = natural,
				rolls = rolls,
				modifier = modifier,
				total = natural + modifier,
			})
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
