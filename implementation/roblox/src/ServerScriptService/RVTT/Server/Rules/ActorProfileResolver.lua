--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ability = require(ReplicatedStorage.RVTT.Shared.Rules.Ability)

export type AbilityScores = { [string]: number }
export type AttackProfile = {
	label: string?,
	ability: string?,
	proficient: boolean?,
	count: number?,
	sides: number?,
	attackModifier: number?,
	damageModifier: number?,
}
export type ActorProfile = {
	source: string,
	abilities: AbilityScores,
	proficiencyBonus: number,
	armorClass: number,
	maximumHitPoints: number,
	speedStuds: number,
	attacks: { [string]: AttackProfile },
	attackSource: string,
}

local ActorProfileResolver = {}

local DEFAULT_ABILITIES: AbilityScores = {
	strength = 10,
	dexterity = 10,
	constitution = 10,
	intelligence = 10,
	wisdom = 10,
	charisma = 10,
}

local function abilitiesOrDefault(value: unknown): AbilityScores
	local result: AbilityScores = table.clone(DEFAULT_ABILITIES)
	if type(value) == "table" then
		for ability, score in value :: { [any]: any } do
			if type(ability) == "string" and result[ability] ~= nil and type(score) == "number" then
				result[ability] = score
			end
		end
	end
	return result
end

local function profileFromCharacter(character: any): ActorProfile
	local abilities = abilitiesOrDefault(character.abilities)
	local level = math.clamp(character.level or 1, 1, 20)
	local constitutionModifier = Ability.modifier(abilities.constitution)
	local dexterityModifier = Ability.modifier(abilities.dexterity)
	local maximum =
		math.max(1, 8 + constitutionModifier + (level - 1) * math.max(1, 5 + constitutionModifier))
	local hasTrustedAttacks = type(character.attacks) == "table"
	return {
		source = "character",
		abilities = abilities,
		proficiencyBonus = Ability.proficiencyBonus(level),
		armorClass = character.armorClass or (10 + dexterityModifier),
		maximumHitPoints = character.maximumHitPoints or maximum,
		speedStuds = character.speedStuds or 24,
		attacks = character.attacks or {
			["attack.unarmed"] = {
				ability = "strength",
				proficient = true,
				count = 1,
				sides = 4,
				damageModifier = 0,
			},
		},
		attackSource = if hasTrustedAttacks then "character_definition" else "fallback",
	}
end

local function profileFromNpc(instance: any): ActorProfile
	local runtime = instance.runtime or {}
	local abilities = abilitiesOrDefault(runtime.abilities)
	return {
		source = "npc",
		abilities = abilities,
		proficiencyBonus = runtime.proficiencyBonus or 2,
		armorClass = runtime.armorClass or 10,
		maximumHitPoints = runtime.maximumHitPoints or 1,
		speedStuds = runtime.speedStuds or 24,
		attacks = runtime.attacks or {},
		attackSource = if type(runtime.attacks) == "table" then "npc_runtime" else "none",
	}
end

function ActorProfileResolver.resolve(actorId: string, domains: any): ActorProfile?
	local scene = domains.scene
	local actor = scene and scene.actors[actorId]
	if actor == nil then
		return nil
	end

	local characterDomain = domains.character
	local character = characterDomain
		and characterDomain.characters[actor.sourceCharacterId or actorId]
	if character ~= nil then
		return profileFromCharacter(character)
	end

	local npcDomain = domains.npc_content
	local npc = npcDomain and npcDomain.instances[actor.sourceNpcId or actorId]
	if npc ~= nil then
		return profileFromNpc(npc)
	end

	return {
		source = "scene",
		abilities = abilitiesOrDefault(actor.abilities),
		proficiencyBonus = actor.proficiencyBonus or 2,
		armorClass = actor.armorClass or 10,
		maximumHitPoints = actor.maximumHitPoints or 1,
		speedStuds = actor.speedStuds or 24,
		attacks = actor.attacks or {},
		attackSource = if type(actor.attacks) == "table" then "scene_runtime" else "none",
	}
end

return table.freeze(ActorProfileResolver)
