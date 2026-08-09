--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ability = require(ReplicatedStorage.RVTT.Shared.Rules.Ability)
local ActorProfileResolver = require(script.Parent.Parent.Rules.ActorProfileResolver)

local CharacterSheetProjection = {}

local ABILITIES = {
	{ id = "strength", label = "근력" },
	{ id = "dexterity", label = "민첩" },
	{ id = "constitution", label = "건강" },
	{ id = "intelligence", label = "지능" },
	{ id = "wisdom", label = "지혜" },
	{ id = "charisma", label = "매력" },
}

local function sortedKeys(source: any): { string }
	local keys = {}
	if type(source) == "table" then
		for key in source do
			if type(key) == "string" then
				table.insert(keys, key)
			end
		end
	end
	table.sort(keys)
	return keys
end

local function selectedCharacterId(
	domains: any,
	viewer: any,
	requestedCharacterId: string?
): string?
	local characterDomain = domains.character
	local characters = if type(characterDomain) == "table" then characterDomain.characters else nil
	if type(characters) ~= "table" then
		return nil
	end
	if type(requestedCharacterId) == "string" then
		return requestedCharacterId
	end
	local session = domains.session
	local selected = if type(session) == "table" then session.selectedCharacter else nil
	local selectedId = if type(selected) == "table" then selected[tostring(viewer.userId)] else nil
	if type(selectedId) == "string" then
		return selectedId
	end
	for _, characterId in sortedKeys(characters) do
		local character = characters[characterId]
		if viewer.role == "dm" or character.ownerUserId == viewer.userId then
			return characterId
		end
	end
	return nil
end

local function actorIdForCharacter(domains: any, characterId: string): string?
	local scene = domains.scene
	local actors = if type(scene) == "table" then scene.actors else nil
	for _, actorId in sortedKeys(actors) do
		local actor = actors[actorId]
		if type(actor) == "table" and actor.sourceCharacterId == characterId then
			return actorId
		end
	end
	return nil
end

local function unavailable(revision: number, viewerRole: string, reason: string): any
	return {
		revision = revision,
		viewerRole = viewerRole,
		canReadFullSheet = false,
		canControl = false,
		state = "unavailable",
		reason = reason,
	}
end

local function addAction(actions: any, id: string, commandType: string, payload: any)
	table.insert(actions, {
		id = id,
		commandType = commandType,
		payload = payload,
		enabled = true,
	})
end

local function availableHitDice(hitDice: any): boolean
	return type(hitDice) == "table"
		and type(hitDice.sides) == "number"
		and hitDice.sides == hitDice.sides
		and hitDice.sides >= 2
		and hitDice.sides <= 100
		and hitDice.sides % 1 == 0
		and type(hitDice.remaining) == "number"
		and hitDice.remaining == hitDice.remaining
		and hitDice.remaining > 0
		and hitDice.remaining < math.huge
		and hitDice.remaining % 1 == 0
end

local function listFromMap(source: any): { any }
	local result = {}
	for _, id in sortedKeys(source) do
		local value = source[id]
		if type(value) == "table" then
			local copy = table.clone(value)
			copy.id = copy.id or id
			table.insert(result, copy)
		end
	end
	return result
end

local function inventoryProjection(
	domains: any,
	viewer: any,
	character: any,
	characterId: string,
	canControl: boolean,
	actions: any
): { any }
	local inventory = domains.inventory
	local items = if type(inventory) == "table" then inventory.items else nil
	local locations = if type(inventory) == "table" then inventory.locations else nil
	local result = {}
	if type(items) ~= "table" or type(locations) ~= "table" then
		return result
	end
	local hotbarPins = if type(character.hotbarPins) == "table" then character.hotbarPins else {}
	local characters = domains.character.characters
	local sendTargets = {}
	for _, targetCharacterId in sortedKeys(characters) do
		local target = characters[targetCharacterId]
		if
			targetCharacterId ~= characterId
			and type(target) == "table"
			and (viewer.role == "dm" or target.ownerUserId == viewer.userId)
		then
			table.insert(sendTargets, {
				id = targetCharacterId,
				label = tostring(target.name or targetCharacterId),
			})
		end
	end
	for _, itemId in sortedKeys(items) do
		local item = items[itemId]
		local location = locations[itemId]
		if
			type(item) == "table"
			and type(location) == "table"
			and location.characterId == characterId
		then
			local itemActions = {}
			if canControl then
				if location.kind == "equipped" then
					local id = "item." .. itemId .. ".unequip"
					addAction(actions, id, "inventory.unequip", {
						itemId = itemId,
						characterId = characterId,
					})
					table.insert(itemActions, { id = id, label = "장착 해제" })
				elseif
					type(item.equipSlot) == "string"
					and item.equipSlot ~= ""
					and #item.equipSlot <= 64
				then
					local id = "item." .. itemId .. ".equip"
					addAction(actions, id, "inventory.equip", {
						itemId = itemId,
						characterId = characterId,
					})
					table.insert(itemActions, { id = id, label = "장착" })
				end
				if item.usable == true then
					local id = "item." .. itemId .. ".use"
					addAction(actions, id, "inventory.use", { itemId = itemId })
					table.insert(itemActions, { id = id, label = "사용" })
				end
				if type(item.quantity) == "number" and item.quantity > 1 then
					local id = "item." .. itemId .. ".split"
					addAction(actions, id, "inventory.split", { itemId = itemId, quantity = 1 })
					table.insert(itemActions, { id = id, label = "나누기" })
				end
				if item.transferable ~= false then
					for _, target in sendTargets do
						local id = "item." .. itemId .. ".send." .. target.id
						addAction(actions, id, "inventory.send", {
							itemId = itemId,
							targetCharacterId = target.id,
						})
						table.insert(itemActions, {
							id = id,
							label = "보내기 → " .. target.label,
							targetPicker = true,
						})
					end
				end
				if item.attunable == true then
					local attuned = item.attunedToCharacterId == characterId
					local id = "item." .. itemId .. if attuned then ".unattune" else ".attune"
					addAction(actions, id, "inventory.set_attunement", {
						itemId = itemId,
						characterId = characterId,
						attuned = not attuned,
					})
					table.insert(
						itemActions,
						{ id = id, label = if attuned then "조율 해제" else "조율" }
					)
				end
				if item.hotbarCapable == true then
					local pinned = hotbarPins["item:" .. itemId] == true
					local id = "item." .. itemId .. if pinned then ".unpin" else ".pin"
					addAction(actions, id, "character.sheet_set_hotbar", {
						characterId = characterId,
						targetKind = "item",
						targetId = itemId,
						pinned = not pinned,
					})
					table.insert(
						itemActions,
						{ id = id, label = if pinned then "Hotbar 해제" else "Hotbar 고정" }
					)
				end
			end
			table.insert(
				itemActions,
				{ id = "item." .. itemId .. ".details", label = "상세", localOnly = true }
			)
			table.insert(result, {
				id = itemId,
				label = tostring(item.label or item.definitionId or itemId),
				details = tostring(item.details or item.definitionId or itemId),
				quantity = item.quantity,
				equipped = location.kind == "equipped",
				slot = location.slot,
				attuned = item.attunedToCharacterId == characterId,
				actions = itemActions,
			})
		end
	end
	return result
end

function CharacterSheetProjection.build(
	domains: any,
	viewer: any,
	revision: number,
	requestedCharacterId: string?
): any
	local role = if type(viewer.role) == "string" then viewer.role else "observer"
	if role ~= "player" and role ~= "dm" then
		return unavailable(revision, role, "SHEET_PERMISSION_REQUIRED")
	end
	local characterId = selectedCharacterId(domains, viewer, requestedCharacterId)
	local characterDomain = domains.character
	local characters = if type(characterDomain) == "table" then characterDomain.characters else nil
	local character = if type(characters) == "table" and type(characterId) == "string"
		then characters[characterId]
		else nil
	if type(character) ~= "table" then
		return unavailable(revision, role, "SHEET_NOT_AVAILABLE")
	end
	if role ~= "dm" and character.ownerUserId ~= viewer.userId then
		return unavailable(revision, role, "SHEET_PERMISSION_REQUIRED")
	end

	local canControl = role == "dm" or character.ownerUserId == viewer.userId
	local actorId = actorIdForCharacter(domains, characterId :: string)
	local profile = if actorId ~= nil then ActorProfileResolver.resolve(actorId, domains) else nil
	local rules = domains.rules
	local actorStates = if type(rules) == "table" then rules.actorStates else nil
	local actorState = if type(actorStates) == "table" and actorId ~= nil
		then actorStates[actorId]
		else nil
	local actions = {}
	local abilities = {}
	local abilityScores = character.abilities
	for _, definition in ABILITIES do
		local score = if type(abilityScores) == "table" then abilityScores[definition.id] else nil
		local actionId = nil
		if canControl and actorId ~= nil and type(score) == "number" then
			actionId = "roll.ability." .. definition.id
			addAction(actions, actionId, "rules.sheet_roll", {
				actorId = actorId,
				rollKind = "ability",
				sourceId = definition.id,
			})
		end
		table.insert(abilities, {
			id = definition.id,
			label = definition.label,
			score = if type(score) == "number" then score else nil,
			modifier = if type(score) == "number" then Ability.modifier(score) else nil,
			actionId = actionId,
		})
	end

	local function rollableEntries(source: any, rollKind: string): { any }
		local entries = {}
		for _, id in sortedKeys(source) do
			local value = source[id]
			if type(value) == "table" then
				local abilityId = if type(value.ability) == "string" then value.ability else nil
				local score = if abilityId ~= nil and type(abilityScores) == "table"
					then abilityScores[abilityId]
					else nil
				local modifier = if type(score) == "number" then Ability.modifier(score) else nil
				if type(modifier) == "number" and value.proficient == true and profile ~= nil then
					modifier += profile.proficiencyBonus
				end
				local actionId = nil
				if canControl and actorId ~= nil and abilityId ~= nil then
					actionId = "roll." .. rollKind .. "." .. id
					addAction(actions, actionId, "rules.sheet_roll", {
						actorId = actorId,
						rollKind = rollKind,
						sourceId = id,
					})
				end
				table.insert(entries, {
					id = id,
					label = tostring(value.label or id),
					modifier = modifier,
					actionId = actionId,
				})
			end
		end
		return entries
	end

	local saves = rollableEntries(character.saves, "saving_throw")
	local skills = rollableEntries(character.skills, "skill")
	local classFeatures = {}
	for _, featureId in sortedKeys(character.classFeatures) do
		local feature = character.classFeatures[featureId]
		if type(feature) == "table" then
			local copy = table.clone(feature)
			copy.id = copy.id or featureId
			if canControl and actorId ~= nil and type(feature.rollAbility) == "string" then
				local actionId = "roll.feature." .. featureId
				addAction(actions, actionId, "rules.sheet_roll", {
					actorId = actorId,
					rollKind = "feature_roll",
					sourceId = featureId,
				})
				copy.actionId = actionId
			end
			table.insert(classFeatures, copy)
		end
	end
	local weapons = {}
	local authoritativeAttacks = if profile ~= nil
			and profile.attackSource == "character_definition"
		then profile.attacks
		else {}
	for _, profileId in sortedKeys(authoritativeAttacks) do
		local attack = authoritativeAttacks[profileId]
		if type(attack) == "table" then
			local attackActionId = nil
			local damageActionId = nil
			if canControl and actorId ~= nil then
				attackActionId = "roll.weapon_attack." .. profileId
				damageActionId = "roll.weapon_damage." .. profileId
				addAction(actions, attackActionId, "rules.sheet_roll", {
					actorId = actorId,
					rollKind = "weapon_attack",
					sourceId = profileId,
				})
				addAction(actions, damageActionId, "rules.sheet_roll", {
					actorId = actorId,
					rollKind = "weapon_damage",
					sourceId = profileId,
				})
			end
			table.insert(weapons, {
				id = profileId,
				label = tostring(attack.label or profileId),
				attackActionId = attackActionId,
				damageActionId = damageActionId,
			})
		end
	end

	if canControl and actorId ~= nil then
		addAction(actions, "roll.initiative", "rules.sheet_roll", {
			actorId = actorId,
			rollKind = "initiative",
		})
		if type(actorState) == "table" then
			addAction(actions, "vitals.hp.decrease", "rules.update_vitals", {
				actorId = actorId,
				deltaCurrentHitPoints = -1,
			})
			addAction(actions, "vitals.hp.increase", "rules.update_vitals", {
				actorId = actorId,
				deltaCurrentHitPoints = 1,
			})
			addAction(actions, "vitals.temp.increase", "rules.update_vitals", {
				actorId = actorId,
				deltaTemporaryHitPoints = 1,
			})
			if actorState.currentHitPoints == 0 then
				addAction(actions, "roll.death_save", "rules.sheet_roll", {
					actorId = actorId,
					rollKind = "death_save",
				})
			end
		end
		local hitDice = character.hitDice
		if availableHitDice(hitDice) then
			addAction(actions, "roll.hit_die", "rules.sheet_roll", {
				actorId = actorId,
				rollKind = "hit_die",
			})
		end
	end

	if canControl and character.inspiration == true then
		addAction(actions, "inspiration.spend", "character.sheet_spend_inspiration", {
			characterId = characterId,
		})
	end

	local spellcasting: any = if type(character.spellcasting) == "table"
		then table.clone(character.spellcasting)
		else {}
	local availableSpells: any = if type(spellcasting.availableSpells) == "table"
		then spellcasting.availableSpells
		else {}
	local preparedSpells = if type(character.preparedSpells) == "table"
		then character.preparedSpells
		else {}
	local projectedSpells = {}
	if canControl and actorId ~= nil and type(spellcasting.ability) == "string" then
		addAction(actions, "roll.spell_attack", "rules.sheet_roll", {
			actorId = actorId,
			rollKind = "spell_attack",
		})
	end
	for _, spellId in sortedKeys(availableSpells) do
		local spell = availableSpells[spellId]
		local prepared = preparedSpells[spellId] == true
		local actionId = nil
		if canControl then
			actionId = "spell." .. spellId .. if prepared then ".unprepare" else ".prepare"
			addAction(actions, actionId, "character.sheet_set_prepared", {
				characterId = characterId,
				spellId = spellId,
				prepared = not prepared,
			})
		end
		table.insert(projectedSpells, {
			id = spellId,
			label = if type(spell) == "table" then tostring(spell.label or spellId) else spellId,
			prepared = prepared,
			actionId = actionId,
		})
	end
	spellcasting.preparedSpells = projectedSpells
	spellcasting.availableSpells = nil

	return {
		revision = revision,
		characterId = characterId,
		actorId = actorId,
		viewerRole = role,
		canReadFullSheet = true,
		canControl = canControl,
		state = "ready",
		identity = {
			name = character.name,
			background = character.backgroundId,
			species = character.speciesId or character.ancestryId,
			class = character.classId,
			subclass = character.subclassId,
			level = character.level,
			xpOrProgress = character.xpOrProgress,
		},
		abilities = abilities,
		saves = saves,
		skills = skills,
		proficiencyBonus = if profile ~= nil then profile.proficiencyBonus else nil,
		inspiration = character.inspiration,
		training = listFromMap(character.training),
		combat = {
			armorClass = if profile ~= nil then profile.armorClass else nil,
			initiative = if type(abilityScores) == "table"
					and type(abilityScores.dexterity) == "number"
				then Ability.modifier(abilityScores.dexterity)
				else nil,
			speed = if profile ~= nil then profile.speedStuds else nil,
			size = character.size,
			passivePerception = character.passivePerception,
			initiativeActionId = if canControl and actorId ~= nil then "roll.initiative" else nil,
		},
		vitals = {
			hpCurrent = if type(actorState) == "table" then actorState.currentHitPoints else nil,
			hpMax = if type(actorState) == "table" then actorState.maximumHitPoints else nil,
			tempHp = if type(actorState) == "table" then actorState.temporaryHitPoints else nil,
			hitDice = character.hitDice,
			hitDieActionId = if canControl
					and actorId ~= nil
					and availableHitDice(character.hitDice)
				then "roll.hit_die"
				else nil,
			deathSaveActionId = if canControl
					and actorId ~= nil
					and type(actorState) == "table"
					and actorState.currentHitPoints == 0
				then "roll.death_save"
				else nil,
			deathSaves = character.deathSaves,
		},
		weaponsAndDamageCantrips = weapons,
		classFeatures = classFeatures,
		speciesTraitsAndFeats = listFromMap(character.speciesTraitsAndFeats),
		spellcasting = spellcasting,
		appearance = character.appearance,
		backstoryAndPersonality = character.backstoryAndPersonality,
		languages = listFromMap(character.languages),
		equipment = inventoryProjection(
			domains,
			viewer,
			character,
			characterId :: string,
			canControl,
			actions
		),
		coins = if type(character.coins) == "table" then table.clone(character.coins) else {},
		attunement = character.attunement,
		actions = actions,
	}
end

return table.freeze(CharacterSheetProjection)
