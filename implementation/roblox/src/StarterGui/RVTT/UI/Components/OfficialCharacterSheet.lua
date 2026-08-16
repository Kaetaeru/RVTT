--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Layout = require(ReplicatedStorage.RVTT.Shared.UI.CharacterSheetLayout)
local Tokens = require(ReplicatedStorage.RVTT.Shared.UI.DesignTokens)
local SheetItemActionPopover = require(script.Parent.SheetItemActionPopover)

local Sheet = {}
Sheet.__index = Sheet

local function decorate(frame: GuiObject, background: string)
	frame.BorderSizePixel = 0
	frame:SetAttribute("RVTTBackgroundToken", background)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Transparency = 0.35
	stroke:SetAttribute("RVTTStrokeToken", "accent")
	stroke.Parent = frame
end

local function label(parent: Instance, name: string, text: string): TextLabel
	local value = Instance.new("TextLabel")
	value.Name = name
	value.Size = UDim2.fromScale(1, 1)
	value.BackgroundTransparency = 1
	value.Font = Enum.Font.GothamMedium
	value.Text = text
	value.TextSize = Tokens.TextSize.Caption
	value.TextWrapped = true
	value.TextXAlignment = Enum.TextXAlignment.Left
	value.TextYAlignment = Enum.TextYAlignment.Top
	value:SetAttribute("RVTTTextToken", "textPrimary")
	value.Parent = parent
	return value
end

local function button(parent: Instance, name: string, text: string): TextButton
	local value = Instance.new("TextButton")
	value.Name = name
	value.Size = UDim2.fromOffset(108, 32)
	value.AutoButtonColor = false
	value.BorderSizePixel = 0
	value.Font = Enum.Font.GothamBold
	value.Text = text
	value.TextSize = Tokens.TextSize.Caption
	value.Selectable = true
	value:SetAttribute("RVTTBackgroundToken", "surfaceSoft")
	value:SetAttribute("RVTTTextToken", "textPrimary")
	value.Parent = parent
	return value
end

local function section(parent: Instance, name: string, position: UDim2, size: UDim2): Frame
	local value = Instance.new("Frame")
	value.Name = name
	value.Position = position
	value.Size = size
	decorate(value, "surfaceRaised")
	value.Parent = parent
	return value
end

local function valueText(value: any): string
	if value == nil or value == "" then
		return "—"
	end
	return tostring(value)
end

local function structuredSlots(slots: any): string
	if type(slots) ~= "table" then
		return "없음"
	end
	local rows = {}
	for level, slot in slots do
		if type(slot) == "table" then
			table.insert(
				rows,
				string.format(
					"%s레벨  %s/%s",
					tostring(level),
					valueText(slot.remaining or slot.current),
					valueText(slot.maximum or slot.max)
				)
			)
		elseif type(slot) == "number" then
			table.insert(rows, tostring(level) .. "레벨  " .. tostring(slot))
		end
	end
	table.sort(rows)
	return if #rows > 0 then table.concat(rows, "\n") else "없음"
end

local function clearDynamic(parent: Instance)
	for _, child in parent:GetChildren() do
		if child:GetAttribute("RVTTCharacterSheetDynamic") == true then
			child:Destroy()
		end
	end
end

local function projectedActionId(state: any, actionId: string): string?
	for _, action in state.actions or {} do
		if action.id == actionId and action.enabled == true then
			return actionId
		end
	end
	return nil
end

local function dynamicButton(
	parent: Instance,
	name: string,
	text: string,
	order: number,
	actionId: string?,
	callback: (string) -> ()
)
	local value = button(parent, name, text)
	value.Size = if parent.Name == "CombatActions"
		then UDim2.fromOffset(84, 30)
		else UDim2.new(1, -10, 0, 30)
	value.LayoutOrder = order
	value:SetAttribute("RVTTCharacterSheetDynamic", true)
	value.Active = actionId ~= nil
	value.Selectable = value.Active
	value:SetAttribute("RVTTBackgroundToken", if value.Active then "surfaceSoft" else "disabled")
	if actionId ~= nil then
		value:SetAttribute("RVTTActionRing", true)
		local function emphasize(active: boolean)
			value:SetAttribute(
				"RVTTBackgroundToken",
				if active then "accentSoft" else "surfaceSoft"
			)
		end
		value.MouseEnter:Connect(function()
			emphasize(true)
		end)
		value.MouseLeave:Connect(function()
			emphasize(false)
		end)
		value.SelectionGained:Connect(function()
			emphasize(true)
		end)
		value.SelectionLost:Connect(function()
			emphasize(false)
		end)
		value.Activated:Connect(function()
			callback(actionId)
		end)
	end
end

function Sheet.new(parent: Instance, onClose: () -> (), onAction: (string, number) -> ()): any
	local self: any = setmetatable({}, Sheet)
	self.state = nil
	self.page = 1
	self.onAction = onAction

	local root = Instance.new("Frame")
	root.Name = "Official2024CharacterSheetSurface"
	root.Size = UDim2.fromScale(1, 1)
	root.Active = true
	root.Visible = false
	root:SetAttribute("RVTTBackgroundToken", "canvas")
	root.BackgroundTransparency = 0.04
	root.Parent = parent
	self.Root = root

	local top = Instance.new("Frame")
	top.Name = "SheetToolbar"
	top.Size = UDim2.new(1, 0, 0, 48)
	top.BackgroundTransparency = 1
	top.Parent = root
	local close = button(top, "CloseCharacterSheet", "닫기  Q")
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -20, 0, 8)
	close.Activated:Connect(onClose)
	local feedback = label(top, "SheetFeedback", "권위 상태와 동기화됨")
	feedback.Position = UDim2.fromOffset(20, 12)
	feedback.Size = UDim2.new(1, -300, 0, 28)
	self.Feedback = feedback

	local pageTabs = Instance.new("Frame")
	pageTabs.Name = "CompactPageTabs"
	pageTabs.AnchorPoint = Vector2.new(0.5, 0)
	pageTabs.Position = UDim2.new(0.5, 0, 0, 8)
	pageTabs.Size = UDim2.fromOffset(224, 32)
	pageTabs.BackgroundTransparency = 1
	pageTabs.Parent = top
	self.PageTabs = pageTabs
	local page1Tab = button(pageTabs, "PageTab1", "1")
	page1Tab.Position = UDim2.fromOffset(0, 0)
	local page2Tab = button(pageTabs, "PageTab2", "2")
	page2Tab.Position = UDim2.fromOffset(116, 0)
	page1Tab.Activated:Connect(function()
		self.page = 1
		self:_applyResponsive()
	end)
	page2Tab.Activated:Connect(function()
		self.page = 2
		self:_applyResponsive()
	end)

	local spread = Instance.new("Frame")
	spread.Name = "TwoPageSpread"
	spread.AnchorPoint = Vector2.new(0.5, 0)
	spread.Position = UDim2.new(0.5, 0, 0, 52)
	spread.Size = UDim2.new(1, -40, 1, -68)
	spread.BackgroundTransparency = 1
	spread.Parent = root
	self.Spread = spread

	local page1 = Instance.new("Frame")
	page1.Name = "OfficialSheetPage1"
	decorate(page1, "surface")
	page1.Parent = spread
	local page1Ratio = Instance.new("UIAspectRatioConstraint")
	page1Ratio.AspectRatio = Layout.REFERENCE_PAGE_WIDTH / Layout.REFERENCE_PAGE_HEIGHT
	page1Ratio.AspectType = Enum.AspectType.FitWithinMaxSize
	page1Ratio.Parent = page1
	self.Page1 = page1

	local page1Header = section(
		page1,
		"Page1TopHeader13",
		UDim2.new(),
		UDim2.fromScale(1, Layout.PAGE_1.TOP_HEADER)
	)
	self.Identity = label(page1Header, "Identity", "")
	self.Identity.Size = UDim2.fromScale(0.36, 1)
	self.LevelXP = label(page1Header, "LevelXP", "")
	self.LevelXP.Position = UDim2.fromScale(0.36, 0)
	self.LevelXP.Size = UDim2.fromScale(0.11, 1)
	self.ArmorClassShield = label(page1Header, "ArmorClassShield", "")
	self.ArmorClassShield.Position = UDim2.fromScale(0.47, 0)
	self.ArmorClassShield.Size = UDim2.fromScale(0.10, 1)
	self.HitPointsTemp = label(page1Header, "HitPointsTemp", "")
	self.HitPointsTemp.Position = UDim2.fromScale(0.57, 0)
	self.HitPointsTemp.Size = UDim2.fromScale(0.17, 1)
	self.HitDiceHeader = label(page1Header, "HitDice", "")
	self.HitDiceHeader.Position = UDim2.fromScale(0.74, 0)
	self.HitDiceHeader.Size = UDim2.fromScale(0.12, 1)
	self.DeathSavesHeader = label(page1Header, "DeathSaves", "")
	self.DeathSavesHeader.Position = UDim2.fromScale(0.86, 0)
	self.DeathSavesHeader.Size = UDim2.fromScale(0.14, 1)
	local page1Main = section(
		page1,
		"Page1Main87",
		UDim2.fromScale(0, Layout.PAGE_1.TOP_HEADER),
		UDim2.fromScale(1, Layout.PAGE_1.MAIN)
	)
	local page1Left = section(
		page1Main,
		"Page1MainLeft35",
		UDim2.new(),
		UDim2.fromScale(Layout.PAGE_1.MAIN_LEFT, 1)
	)
	local page1Right = section(
		page1Main,
		"Page1MainRight65",
		UDim2.fromScale(Layout.PAGE_1.MAIN_LEFT, 0),
		UDim2.fromScale(Layout.PAGE_1.MAIN_RIGHT, 1)
	)

	local abilities = section(page1Left, "AbilitiesAndTraining", UDim2.new(), UDim2.fromScale(1, 1))
	self.LeftSummary = label(abilities, "ProficiencyInspirationTraining", "")
	self.LeftSummary.Size = UDim2.new(1, -10, 0, 66)
	self.LeftSummary.Position = UDim2.fromOffset(5, 5)
	local abilityRows = Instance.new("Frame")
	abilityRows.Name = "AbilitySaveSkillRows"
	abilityRows.Position = UDim2.fromOffset(0, 72)
	abilityRows.Size = UDim2.new(1, 0, 1, -72)
	abilityRows.BackgroundTransparency = 1
	abilityRows.Parent = abilities
	local abilityLayout = Instance.new("UIListLayout")
	abilityLayout.Padding = UDim.new(0, 3)
	abilityLayout.Parent = abilityRows
	self.Abilities = abilityRows
	self.Combat = label(page1Right, "CombatHeader", "")
	self.Combat.Size = UDim2.new(1, -12, 0, 40)
	self.Combat.Position = UDim2.fromOffset(6, 6)
	local combatActions = Instance.new("Frame")
	combatActions.Name = "CombatActions"
	combatActions.Position = UDim2.fromOffset(6, 46)
	combatActions.Size = UDim2.new(1, -12, 0, 30)
	combatActions.BackgroundTransparency = 1
	combatActions.Parent = page1Right
	local combatActionsLayout = Instance.new("UIListLayout")
	combatActionsLayout.FillDirection = Enum.FillDirection.Horizontal
	combatActionsLayout.Padding = UDim.new(0, 3)
	combatActionsLayout.Parent = combatActions
	self.CombatActions = combatActions
	local rightBody =
		section(page1Right, "Page1RightBody", UDim2.fromScale(0, 0.10), UDim2.fromScale(1, 0.90))
	local weapons = section(
		rightBody,
		"Weapons24",
		UDim2.new(),
		UDim2.fromScale(1, Layout.PAGE_1.RIGHT_WEAPONS)
	)
	self.Weapons = label(weapons, "Weapons", "")
	self.Weapons.Size = UDim2.new(1, -12, 0, 36)
	self.Weapons.Position = UDim2.fromOffset(6, 6)
	local weaponActions = Instance.new("Frame")
	weaponActions.Name = "WeaponActions"
	weaponActions.Position = UDim2.fromOffset(6, 42)
	weaponActions.Size = UDim2.new(1, -12, 1, -48)
	weaponActions.BackgroundTransparency = 1
	weaponActions.Parent = weapons
	local weaponActionsLayout = Instance.new("UIListLayout")
	weaponActionsLayout.Padding = UDim.new(0, 3)
	weaponActionsLayout.Parent = weaponActions
	self.WeaponActions = weaponActions
	local classFeatures = section(
		rightBody,
		"ClassFeatures43",
		UDim2.fromScale(0, Layout.PAGE_1.RIGHT_WEAPONS),
		UDim2.fromScale(1, Layout.PAGE_1.RIGHT_CLASS_FEATURES)
	)
	self.ClassFeatures = label(classFeatures, "ClassFeatures", "")
	self.ClassFeatures.Size = UDim2.new(1, -12, 0, 36)
	self.ClassFeatures.Position = UDim2.fromOffset(6, 6)
	local classFeatureActions = Instance.new("Frame")
	classFeatureActions.Name = "ClassFeatureActions"
	classFeatureActions.Position = UDim2.fromOffset(6, 42)
	classFeatureActions.Size = UDim2.new(1, -12, 1, -48)
	classFeatureActions.BackgroundTransparency = 1
	classFeatureActions.Parent = classFeatures
	local classFeatureActionsLayout = Instance.new("UIListLayout")
	classFeatureActionsLayout.Padding = UDim.new(0, 3)
	classFeatureActionsLayout.Parent = classFeatureActions
	self.ClassFeatureActions = classFeatureActions
	self.SpeciesFeats = label(
		section(
			rightBody,
			"SpeciesTraitsFeats33",
			UDim2.fromScale(0, Layout.PAGE_1.RIGHT_WEAPONS + Layout.PAGE_1.RIGHT_CLASS_FEATURES),
			UDim2.fromScale(1, Layout.PAGE_1.RIGHT_SPECIES_FEATS)
		),
		"SpeciesFeats",
		""
	)

	local page2 = Instance.new("Frame")
	page2.Name = "OfficialSheetPage2"
	decorate(page2, "surface")
	page2.Parent = spread
	local page2Ratio = Instance.new("UIAspectRatioConstraint")
	page2Ratio.AspectRatio = Layout.REFERENCE_PAGE_WIDTH / Layout.REFERENCE_PAGE_HEIGHT
	page2Ratio.AspectType = Enum.AspectType.FitWithinMaxSize
	page2Ratio.Parent = page2
	self.Page2 = page2
	local page2Left =
		section(page2, "Page2Left68", UDim2.new(), UDim2.fromScale(Layout.PAGE_2.LEFT, 1))
	local page2Right = section(
		page2,
		"Page2Right32",
		UDim2.fromScale(Layout.PAGE_2.LEFT, 0),
		UDim2.fromScale(Layout.PAGE_2.RIGHT, 1)
	)
	self.SpellAbility = label(
		section(
			page2Left,
			"SpellcastingAbility24",
			UDim2.new(),
			UDim2.fromScale(Layout.PAGE_2.SPELLCASTING_ABILITY, 0.16)
		),
		"SpellAbility",
		""
	)
	self.SpellSlots = label(
		section(
			page2Left,
			"SpellSlots76",
			UDim2.fromScale(Layout.PAGE_2.SPELLCASTING_ABILITY, 0),
			UDim2.fromScale(Layout.PAGE_2.SPELL_SLOTS, 0.16)
		),
		"SpellSlots",
		""
	)
	local spells = section(
		page2Left,
		"CantripsPreparedSpells",
		UDim2.fromScale(0, 0.16),
		UDim2.fromScale(1, 0.84)
	)
	local spellLayout = Instance.new("UIListLayout")
	spellLayout.Padding = UDim.new(0, 3)
	spellLayout.Parent = spells
	self.Spells = spells
	self.Appearance = label(
		section(
			page2Right,
			"Appearance14",
			UDim2.new(),
			UDim2.fromScale(1, Layout.PAGE_2.RIGHT_APPEARANCE)
		),
		"Appearance",
		""
	)
	self.Backstory = label(
		section(
			page2Right,
			"Backstory30",
			UDim2.fromScale(0, 0.14),
			UDim2.fromScale(1, Layout.PAGE_2.RIGHT_BACKSTORY)
		),
		"Backstory",
		""
	)
	self.Languages = label(
		section(
			page2Right,
			"Languages10",
			UDim2.fromScale(0, 0.44),
			UDim2.fromScale(1, Layout.PAGE_2.RIGHT_LANGUAGES)
		),
		"Languages",
		""
	)
	local equipment = section(
		page2Right,
		"Equipment34",
		UDim2.fromScale(0, 0.54),
		UDim2.fromScale(1, Layout.PAGE_2.RIGHT_EQUIPMENT)
	)
	self.EquipmentTitle = label(equipment, "EquipmentTitle", "장비")
	self.EquipmentTitle.Size = UDim2.new(1, -12, 0, 38)
	self.EquipmentTitle.Position = UDim2.fromOffset(6, 6)
	local equipmentRows = Instance.new("ScrollingFrame")
	equipmentRows.Name = "AllEquipmentRows"
	equipmentRows.Position = UDim2.fromOffset(6, 42)
	equipmentRows.Size = UDim2.new(1, -12, 0.42, -42)
	equipmentRows.BackgroundTransparency = 1
	equipmentRows.AutomaticCanvasSize = Enum.AutomaticSize.Y
	equipmentRows.CanvasSize = UDim2.new()
	equipmentRows.ScrollBarThickness = 4
	equipmentRows.Parent = equipment
	local equipmentLayout = Instance.new("UIListLayout")
	equipmentLayout.Padding = UDim.new(0, 3)
	equipmentLayout.Parent = equipmentRows
	self.EquipmentRows = equipmentRows
	self.SelectedItemId = nil
	self.LocalDetails = label(equipment, "EquipmentDetailsSurface", "")
	self.LocalDetails.Position = UDim2.new(0, 6, 0.42, 0)
	self.LocalDetails.Size = UDim2.new(1, -12, 0.12, 0)
	self.LocalDetails.Visible = false
	self.ItemPopover = SheetItemActionPopover.new(equipment, function(actionId: string)
		if self.state ~= nil then
			self.onAction(actionId, self.state.revision)
		end
	end, function(_: any, item: any)
		self.LocalDetails.Text = "상세 · " .. tostring(item.details or item.label or item.id)
		self.LocalDetails.Visible = true
	end)
	self.Coins = label(
		section(
			page2Right,
			"Coins12",
			UDim2.fromScale(0, 0.88),
			UDim2.fromScale(1, Layout.PAGE_2.RIGHT_COINS)
		),
		"Coins",
		""
	)

	return self
end

function Sheet._applyResponsive(self: any)
	local compact = self.state ~= nil and self.state.layoutMode == "Compact"
	self.PageTabs.Visible = compact
	if compact then
		self.Page1.Visible = self.page == 1
		self.Page2.Visible = self.page == 2
		self.Page1.Position = UDim2.fromScale(0.5, 0)
		self.Page2.Position = UDim2.fromScale(0.5, 0)
		self.Page1.AnchorPoint = Vector2.new(0.5, 0)
		self.Page2.AnchorPoint = Vector2.new(0.5, 0)
		self.Page1.Size = UDim2.fromScale(0.92, 1)
		self.Page2.Size = UDim2.fromScale(0.92, 1)
	else
		self.Page1.Visible = true
		self.Page2.Visible = true
		self.Page1.AnchorPoint = Vector2.new(0, 0.5)
		self.Page2.AnchorPoint = Vector2.new(1, 0.5)
		self.Page1.Position = UDim2.fromScale(0.02, 0.5)
		self.Page2.Position = UDim2.fromScale(0.98, 0.5)
		self.Page1.Size = UDim2.fromScale(0.47, 0.98)
		self.Page2.Size = UDim2.fromScale(0.47, 0.98)
	end
end

function Sheet.render(self: any, state: any)
	self.state = state
	if state.visible ~= true then
		self.Root.Visible = false
		return
	end
	local identity = state.identity or {}
	self.Identity.Text = string.format(
		"Character Name  %s\nBackground %s · Species %s\nClass %s · Subclass %s",
		valueText(identity.name),
		valueText(identity.background),
		valueText(identity.species),
		valueText(identity.class),
		valueText(identity.subclass)
	)
	local combat = state.combat or {}
	local vitals = state.vitals or {}
	self.LevelXP.Text = "Level/XP\n"
		.. valueText(identity.level)
		.. " / "
		.. valueText(identity.xpOrProgress)
	self.ArmorClassShield.Text = "AC Shield\n" .. valueText(combat.armorClass)
	self.HitPointsTemp.Text = "HP / Temp HP\n"
		.. valueText(vitals.hpCurrent)
		.. "/"
		.. valueText(vitals.hpMax)
		.. " +"
		.. valueText(vitals.tempHp)
	self.HitDiceHeader.Text = "Hit Dice\n"
		.. valueText(type(vitals.hitDice) == "table" and vitals.hitDice.sides or nil)
	self.DeathSavesHeader.Text = "Death Saves\n" .. valueText(vitals.deathSaves)
	self.LeftSummary.Text = string.format(
		"Proficiency Bonus %s\nInspiration %s\nTraining %s",
		valueText(state.proficiencyBonus),
		valueText(state.inspiration),
		tostring(#(state.training or {}))
	)
	clearDynamic(self.Abilities)
	for index, ability in state.abilities or {} do
		dynamicButton(
			self.Abilities,
			"Ability_" .. ability.id,
			string.format(
				"%s  %s  (%s)",
				ability.label,
				valueText(ability.score),
				valueText(ability.modifier)
			),
			index,
			ability.actionId,
			function(actionId: string)
				self.onAction(actionId, state.revision)
			end
		)
	end
	local trainingOrder = #(state.abilities or {})
	for _, save in state.saves or {} do
		trainingOrder += 1
		dynamicButton(
			self.Abilities,
			"Save_" .. save.id,
			"SAVE  " .. save.label .. "  " .. valueText(save.modifier),
			trainingOrder,
			save.actionId,
			function(actionId: string)
				self.onAction(actionId, state.revision)
			end
		)
	end
	for _, skill in state.skills or {} do
		trainingOrder += 1
		dynamicButton(
			self.Abilities,
			"Skill_" .. skill.id,
			"SKILL  " .. skill.label .. "  " .. valueText(skill.modifier),
			trainingOrder,
			skill.actionId,
			function(actionId: string)
				self.onAction(actionId, state.revision)
			end
		)
	end
	self.Combat.Text = string.format(
		"Initiative %s · Speed %s · Size %s · Passive Perception %s",
		valueText(combat.initiative),
		valueText(combat.speed),
		valueText(combat.size),
		valueText(combat.passivePerception)
	)
	clearDynamic(self.CombatActions)
	local combatActionIds = {
		{ "Initiative", "roll.initiative" },
		{ "HP -", "vitals.hp.decrease" },
		{ "HP +", "vitals.hp.increase" },
		{ "Temp +", "vitals.temp.increase" },
		{ "Inspiration", "inspiration.spend" },
		{ "Hit Die", vitals.hitDieActionId },
		{ "Death Save", vitals.deathSaveActionId },
	}
	for index, definition in combatActionIds do
		local actionId = definition[2]
		if type(actionId) == "string" and projectedActionId(state, actionId) ~= nil then
			dynamicButton(
				self.CombatActions,
				"CombatAction_" .. tostring(index),
				definition[1],
				index,
				actionId,
				function(selectedActionId: string)
					self.onAction(selectedActionId, state.revision)
				end
			)
		end
	end
	self.Weapons.Text = "무기 & 피해 캔트립\n"
		.. tostring(#(state.weaponsAndDamageCantrips or {}))
		.. "개"
	clearDynamic(self.WeaponActions)
	local weaponOrder = 0
	for _, weapon in state.weaponsAndDamageCantrips or {} do
		weaponOrder += 1
		dynamicButton(
			self.WeaponActions,
			"Attack_" .. weapon.id,
			weapon.label .. " attack",
			weaponOrder,
			weapon.attackActionId,
			function(actionId: string)
				self.onAction(actionId, state.revision)
			end
		)
		weaponOrder += 1
		dynamicButton(
			self.WeaponActions,
			"Damage_" .. weapon.id,
			weapon.label .. " damage",
			weaponOrder,
			weapon.damageActionId,
			function(actionId: string)
				self.onAction(actionId, state.revision)
			end
		)
	end
	self.ClassFeatures.Text = "직업 특성\n" .. tostring(#(state.classFeatures or {})) .. "개"
	clearDynamic(self.ClassFeatureActions)
	for index, feature in state.classFeatures or {} do
		if type(feature.actionId) == "string" then
			dynamicButton(
				self.ClassFeatureActions,
				"Feature_" .. feature.id,
				tostring(feature.label or feature.id),
				index,
				feature.actionId,
				function(actionId: string)
					self.onAction(actionId, state.revision)
				end
			)
		end
	end
	self.SpeciesFeats.Text = "종족 특성 / Feat\n"
		.. tostring(#(state.speciesTraitsAndFeats or {}))
		.. "개"
	local spellcasting = state.spellcasting or {}
	self.SpellAbility.Text = "주문 능력\n" .. valueText(spellcasting.ability)
	self.SpellSlots.Text = "주문 슬롯\n" .. structuredSlots(spellcasting.slots)
	clearDynamic(self.Spells)
	if projectedActionId(state, "roll.spell_attack") ~= nil then
		dynamicButton(
			self.Spells,
			"SpellAttack",
			"Spell attack",
			0,
			"roll.spell_attack",
			function(actionId: string)
				self.onAction(actionId, state.revision)
			end
		)
	end
	for index, spell in spellcasting.preparedSpells or {} do
		dynamicButton(
			self.Spells,
			"Spell_" .. spell.id,
			(if spell.prepared then "● " else "○ ") .. spell.label,
			index,
			spell.actionId,
			function(actionId: string)
				self.onAction(actionId, state.revision)
			end
		)
	end
	self.Appearance.Text = "외모\n" .. valueText(state.appearance)
	self.Backstory.Text = "배경 이야기와 성격\n" .. valueText(state.backstoryAndPersonality)
	self.Languages.Text = "언어\n" .. tostring(#(state.languages or {})) .. "개"
	clearDynamic(self.EquipmentRows)
	local selectedItem = nil
	for index, item in state.equipment or {} do
		if self.SelectedItemId == item.id then
			selectedItem = item
		end
		dynamicButton(
			self.EquipmentRows,
			"EquipmentRow_" .. item.id,
			item.label .. " ×" .. valueText(item.quantity),
			index,
			"local.select." .. item.id,
			function()
				self.SelectedItemId = item.id
				self.LocalDetails.Visible = false
				self.ItemPopover:render(item)
			end
		)
	end
	self.EquipmentTitle.Text = "장비 · " .. tostring(#(state.equipment or {})) .. "개"
	self.ItemPopover:render(selectedItem)
	local coinParts = {}
	for coin, amount in state.coins or {} do
		table.insert(coinParts, tostring(coin) .. " " .. tostring(amount))
	end
	table.sort(coinParts)
	self.Coins.Text = "화폐\n"
		.. if #coinParts > 0 then table.concat(coinParts, " · ") else "—"
	local feedback = state.feedback or {}
	self.Feedback.Text = "Sheet revision "
		.. tostring(state.revision)
		.. " · "
		.. tostring(feedback.state or state.state)
	self:_applyResponsive()
end

function Sheet.setVisible(self: any, visible: boolean)
	self.Root.Visible = visible and self.state ~= nil and self.state.canReadFullSheet == true
end

return table.freeze(Sheet)
