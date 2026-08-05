--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ability = require(ReplicatedStorage.RVTT.Shared.Rules.Ability)

local ActorProfileResolver = {}

local DEFAULT_ABILITIES = {
	strength = 10,
	dexterity = 10,
	constitution = 10,
	intelligence = 10,
	wisdom = 10,
	charisma = 10,
}

local function abilitiesOrDefault(value)
	local result = table.clone(DEFAULT_ABILITIES)
	if type(value) == "table" then
		for ability, score in value do
			if result[ability] ~= nil and type(score) == "number" then
				result[ability] = score
			end
		end
	end
	return result
end

local function profileFromCharacter(character)
	local abilities = abilitiesOrDefault(character.abilities)
	local level = math.clamp(character.level or 1, 1, 20)
	local constitutionModifier = Ability.modifier(abilities.constitution)
	local dexterityModifier = Ability.modifier(abilities.dexterity)
	local maximum =
		math.max(1, 8 + constitutionModifier + (level - 1) * math.max(1, 5 + constitutionModifier))
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
	}
end

local function profileFromNpc(instance)
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
	}
end

function ActorProfileResolver.resolve(actorId: string, domains)
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
	}
end

return table.freeze(ActorProfileResolver)
