--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Tokens = require(ReplicatedStorage.RVTT.Shared.UI.DesignTokens)
local DiceNoticeViewModel = require(ReplicatedStorage.RVTT.Shared.UI.DiceNoticeViewModel)

local DiceSlotRevealNotice = {}
DiceSlotRevealNotice.__index = DiceSlotRevealNotice

local function label(name: string, size: number): TextLabel
	local value = Instance.new("TextLabel")
	value.Name = name
	value.BackgroundTransparency = 1
	value.BorderSizePixel = 0
	value.Font = Enum.Font.GothamBold
	value.TextSize = size
	value.TextXAlignment = Enum.TextXAlignment.Center
	value:SetAttribute("RVTTTextToken", "textPrimary")
	return value
end

local function formulaText(notice: any): string
	local terms = {}
	for _, term in notice.modifierTerms do
		table.insert(terms, string.format("%s %+d", term.label, term.value))
	end
	return table.concat(terms, "  ")
end

local function semanticColor(semanticCritical: string): Color3?
	if semanticCritical == "natural_1" then
		return Tokens.Color.Danger
	elseif semanticCritical == "natural_20" then
		return Tokens.Color.Success
	end
	return nil
end

local function child(parent: Instance, name: string): any
	return parent:FindFirstChild(name)
end

function DiceSlotRevealNotice.new(parent: Instance, onDismiss: (string) -> ()): any
	local root = Instance.new("Frame")
	root.Name = "DiceSlotRevealNotice"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.BorderSizePixel = 0
	root.Active = false
	root.Parent = parent
	return setmetatable({
		Root = root,
		frames = {},
		generations = {},
		tweens = {},
		onDismiss = onDismiss,
	}, DiceSlotRevealNotice)
end

function DiceSlotRevealNotice:_cancelTweens(rollId: string)
	local active = self.tweens[rollId]
	if type(active) == "table" then
		for _, tween in active do
			pcall(function()
				tween:Cancel()
			end)
		end
	end
	self.tweens[rollId] = {}
end

function DiceSlotRevealNotice:_tween(
	rollId: string,
	instance: Instance,
	durationMs: number,
	goal: any,
	style: Enum.EasingStyle?,
	direction: Enum.EasingDirection?
): any
	local tween = TweenService:Create(
		instance,
		TweenInfo.new(
			durationMs / 1000,
			style or Enum.EasingStyle.Quad,
			direction or Enum.EasingDirection.Out
		),
		goal
	)
	table.insert(self.tweens[rollId], tween)
	tween:Play()
	return tween
end

function DiceSlotRevealNotice:_schedule(
	rollId: string,
	generation: number,
	delaySeconds: number,
	callback: () -> ()
)
	task.delay(delaySeconds, function()
		if self.generations[rollId] == generation then
			callback()
		end
	end)
end

function DiceSlotRevealNotice:_createNaturalCell(cell: any): Frame
	local outer = Instance.new("Frame")
	outer.Name = "NaturalCell_" .. tostring(cell.index)
	outer.Size = UDim2.fromOffset(56, 56)
	outer.BackgroundTransparency = 1
	outer.BorderSizePixel = 0

	local visual = Instance.new("Frame")
	visual.Name = "Visual"
	visual.Size = UDim2.fromScale(1, 1)
	visual.BackgroundColor3 = Tokens.Color.SurfaceSoft
	visual.BackgroundTransparency = 0.25
	visual.BorderSizePixel = 0
	visual:SetAttribute("RVTTApplied", cell.applied)
	visual:SetAttribute("RVTTSemanticCritical", cell.semanticCritical)
	visual:SetAttribute("RVTTDiscardedContrast", cell.contrast)
	visual.Parent = outer

	local corner = Instance.new("UICorner")
	corner.CornerRadius = Tokens.Radius.SM
	corner.Parent = visual
	local stroke = Instance.new("UIStroke")
	stroke.Name = "AppliedAccent"
	stroke.Thickness = if cell.applied then 2 else 1
	stroke.Transparency = if cell.applied then 0.15 else 0.7
	stroke:SetAttribute("RVTTStrokeToken", if cell.applied then "accent" else "stroke")
	stroke.Parent = visual
	local scale = Instance.new("UIScale")
	scale.Name = "AppliedScale"
	scale.Scale = 1
	scale.Parent = visual

	local clip = Instance.new("Frame")
	clip.Name = "SlotClip"
	clip.Size = UDim2.fromScale(1, 1)
	clip.BackgroundTransparency = 1
	clip.BorderSizePixel = 0
	clip.ClipsDescendants = true
	clip.Parent = visual
	local strip = Instance.new("Frame")
	strip.Name = "NumeralStrip"
	strip.Size = UDim2.fromOffset(56, #DiceNoticeViewModel.SLOT_DECORATIVE_VALUES * 56)
	strip.Position = UDim2.fromOffset(0, 0)
	strip.BackgroundTransparency = 1
	strip.BorderSizePixel = 0
	strip.Visible = false
	strip.Parent = clip
	for index, decorative in DiceNoticeViewModel.SLOT_DECORATIVE_VALUES do
		local numeral = label("Decorative_" .. tostring(index), 24)
		numeral.Position = UDim2.fromOffset(0, (index - 1) * 56)
		numeral.Size = UDim2.fromOffset(56, 56)
		numeral.Text = tostring(decorative)
		numeral.TextTransparency = 1 - cell.contrast
		numeral.Parent = strip
	end
	local crossfadeA = label("CrossfadeA", 24)
	crossfadeA.Size = UDim2.fromScale(1, 1)
	crossfadeA.Text = ""
	crossfadeA.TextTransparency = 1
	crossfadeA.Visible = false
	crossfadeA.Parent = visual
	local crossfadeB = label("CrossfadeB", 24)
	crossfadeB.Size = UDim2.fromScale(1, 1)
	crossfadeB.Text = ""
	crossfadeB.TextTransparency = 1
	crossfadeB.Visible = false
	crossfadeB.Parent = visual
	local locked = label("LockedValue", 24)
	locked.Size = UDim2.fromScale(1, 1)
	locked.Text = ""
	locked.TextTransparency = 1
	locked.Parent = visual
	return outer
end

function DiceSlotRevealNotice:_createFrame(
	notice: any,
	index: number,
	initiativeVisible: boolean
): Frame
	local layout = DiceNoticeViewModel.layout(notice, initiativeVisible)
	local frame = Instance.new("Frame")
	frame.Name = "Notice_" .. notice.rollId
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = UDim2.new(0.5, 0, 0, layout.topOffset + (index - 1) * 72)
	frame.Size = UDim2.fromOffset(layout.initialWidth, layout.initialHeight)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame:SetAttribute("RVTTBackgroundToken", "surfaceStrong")
	frame:SetAttribute("RVTTDiceMode", notice.diceMode)
	frame:SetAttribute("RVTTStackCap", 2)
	frame:SetAttribute("RVTTInitialWidth", layout.initialWidth)
	frame.Parent = self.Root
	local enterScale = Instance.new("UIScale")
	enterScale.Name = "EnterScale"
	enterScale.Scale = 0.86
	enterScale.Parent = frame
	local corner = Instance.new("UICorner")
	corner.CornerRadius = Tokens.Radius.SM
	corner.Parent = frame

	local naturalRow = Instance.new("Frame")
	naturalRow.Name = "NaturalRow"
	naturalRow.BackgroundTransparency = 1
	naturalRow.Position = UDim2.fromOffset(4, 4)
	naturalRow.Size = UDim2.fromOffset(layout.initialWidth - 8, 56)
	naturalRow.Parent = frame
	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	rowLayout.Padding = UDim.new(0, 6)
	rowLayout.Parent = naturalRow
	for _, cell in DiceNoticeViewModel.cells(notice) do
		self:_createNaturalCell(cell).Parent = naturalRow
	end

	local formula = label("Formula", Tokens.TextSize.Caption)
	formula.Position = UDim2.fromOffset(layout.initialWidth + 8, 6)
	formula.Size = UDim2.fromOffset(190, 24)
	formula.TextXAlignment = Enum.TextXAlignment.Left
	formula.TextTransparency = 1
	formula.Visible = false
	formula.Parent = frame
	local total = label("Total", Tokens.TextSize.Label)
	total.Position = UDim2.fromOffset(270, 5)
	total.Size = UDim2.fromOffset(82, 26)
	total.TextTransparency = 1
	total.Visible = false
	total.Parent = frame
	local adjudication = label("Adjudication", Tokens.TextSize.Caption)
	adjudication.Position = UDim2.fromOffset(layout.initialWidth + 8, 34)
	adjudication.Size = UDim2.fromOffset(280, 24)
	adjudication.TextXAlignment = Enum.TextXAlignment.Left
	adjudication.TextTransparency = 1
	adjudication.Visible = false
	adjudication.Parent = frame

	local descriptor = DiceNoticeViewModel.animationDescriptor(notice, false)
	if descriptor.dualApplied.enabled then
		local connectorStartX = if descriptor.dualApplied.appliedIndex == 1 then 60 else 122
		local connector = Instance.new("Frame")
		connector.Name = "FormulaConnector_" .. tostring(descriptor.dualApplied.appliedIndex)
		connector.Position = UDim2.fromOffset(connectorStartX, 31)
		connector.Size = UDim2.fromOffset(0, 2)
		connector.BackgroundTransparency = 0
		connector.BorderSizePixel = 0
		connector.Visible = false
		connector:SetAttribute("RVTTBackgroundToken", "accent")
		connector:SetAttribute(
			"RVTTConnectorTargetWidth",
			layout.initialWidth + 8 - connectorStartX
		)
		connector.Parent = frame
	end
	return frame
end

function DiceSlotRevealNotice:_spinVertical(frame: Frame, notice: any, descriptor: any)
	for index, _ in notice.naturalResults do
		local naturalRow = child(frame, "NaturalRow")
		local cell = child(naturalRow, "NaturalCell_" .. tostring(index))
		local visual = child(cell, "Visual")
		local slotClip = child(visual, "SlotClip")
		local strip = child(slotClip, "NumeralStrip") :: Frame
		local crossfadeA = child(visual, "CrossfadeA") :: TextLabel
		local crossfadeB = child(visual, "CrossfadeB") :: TextLabel
		local locked = child(visual, "LockedValue") :: TextLabel
		locked.Text = ""
		locked.TextTransparency = 1
		crossfadeA.Visible = false
		crossfadeB.Visible = false
		strip:SetAttribute("RVTTSlotFlowDirection", descriptor.slotSpin.flowDirection)
		strip:SetAttribute("RVTTSlotInitialOffsetY", descriptor.slotSpin.initialOffsetY)
		strip:SetAttribute("RVTTSlotFinalOffsetY", descriptor.slotSpin.finalOffsetY)
		strip.Position = UDim2.fromOffset(0, descriptor.slotSpin.initialOffsetY)
		strip.Visible = true
		self:_tween(
			notice.rollId,
			strip,
			descriptor.slotSpin.durationMs,
			{ Position = UDim2.fromOffset(0, descriptor.slotSpin.finalOffsetY) },
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.InOut
		)
	end
end

function DiceSlotRevealNotice:_spinReduced(
	frame: Frame,
	notice: any,
	descriptor: any,
	generation: number
)
	for index, _ in notice.naturalResults do
		local naturalRow = child(frame, "NaturalRow")
		local cell = child(naturalRow, "NaturalCell_" .. tostring(index))
		local visual = child(cell, "Visual")
		local slotClip = child(visual, "SlotClip")
		local strip = child(slotClip, "NumeralStrip") :: Frame
		local crossfadeA = child(visual, "CrossfadeA") :: TextLabel
		local crossfadeB = child(visual, "CrossfadeB") :: TextLabel
		local locked = child(visual, "LockedValue") :: TextLabel
		strip.Visible = false
		locked.Visible = true
		locked.Text = ""
		locked.TextTransparency = 1
		crossfadeA.Visible = true
		crossfadeA.Text = tostring(DiceNoticeViewModel.SLOT_DECORATIVE_VALUES[1])
		crossfadeA.TextTransparency = 0
		crossfadeB.Visible = true
		crossfadeB.Text = ""
		crossfadeB.TextTransparency = 1
		visual:SetAttribute("RVTTReducedCrossfadeLayers", descriptor.slotSpin.crossfadeLayerCount)
		local transitionMs = descriptor.slotSpin.durationMs / descriptor.slotSpin.crossfadeSteps
		for step = 2, descriptor.slotSpin.crossfadeSteps do
			local decorativeStep = step
			local outgoing = if step % 2 == 0 then crossfadeA else crossfadeB
			local incoming = if step % 2 == 0 then crossfadeB else crossfadeA
			self:_schedule(notice.rollId, generation, ((step - 1) * transitionMs) / 1000, function()
				incoming.Text = tostring(DiceNoticeViewModel.SLOT_DECORATIVE_VALUES[decorativeStep])
				incoming.TextTransparency = 1
				self:_tween(notice.rollId, outgoing, transitionMs, { TextTransparency = 1 })
				self:_tween(notice.rollId, incoming, transitionMs, { TextTransparency = 0 })
			end)
		end
	end
end

function DiceSlotRevealNotice:_runDampedCritical(
	visual: Frame,
	locked: TextLabel,
	stroke: UIStroke,
	notice: any,
	descriptor: any,
	generation: number,
	color: Color3
)
	self:_tween(notice.rollId, visual, descriptor.naturalLock.durationMs, {
		BackgroundColor3 = color,
		BackgroundTransparency = 0.05,
	})
	self:_tween(notice.rollId, locked, descriptor.naturalLock.durationMs, { TextColor3 = color })
	self:_tween(
		notice.rollId,
		stroke,
		descriptor.naturalLock.durationMs,
		{ Color = color, Transparency = 0.05 }
	)
	for index, offset in descriptor.naturalLock.shakeOffsets do
		self:_schedule(notice.rollId, generation, (index - 1) * 0.03, function()
			self:_tween(
				notice.rollId,
				visual,
				30,
				{ Position = UDim2.fromOffset(offset, 0) },
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			)
		end)
	end
end

function DiceSlotRevealNotice:_runReducedCritical(
	visual: Frame,
	locked: TextLabel,
	stroke: UIStroke,
	notice: any,
	descriptor: any,
	generation: number,
	color: Color3
)
	local halfDuration = descriptor.naturalLock.durationMs / 2
	stroke.Transparency = 1
	self:_tween(notice.rollId, stroke, halfDuration, { Color = color, Transparency = 0.05 })
	self:_tween(notice.rollId, visual, halfDuration, {
		BackgroundColor3 = color,
		BackgroundTransparency = 0.1,
	})
	self:_tween(notice.rollId, locked, halfDuration, { TextColor3 = color })
	self:_schedule(notice.rollId, generation, halfDuration / 1000, function()
		self:_tween(notice.rollId, stroke, halfDuration, { Transparency = 0.65 })
		self:_tween(notice.rollId, visual, halfDuration, {
			BackgroundColor3 = Tokens.Color.SurfaceSoft,
			BackgroundTransparency = 0.25,
		})
	end)
end

function DiceSlotRevealNotice:_lockNaturals(
	frame: Frame,
	notice: any,
	descriptor: any,
	reducedMotion: boolean,
	generation: number
)
	for index, natural in notice.naturalResults do
		local naturalRow = child(frame, "NaturalRow")
		local cell = child(naturalRow, "NaturalCell_" .. tostring(index))
		local visual = child(cell, "Visual") :: Frame
		local slotClip = child(visual, "SlotClip")
		local strip = child(slotClip, "NumeralStrip") :: Frame
		local crossfadeA = child(visual, "CrossfadeA") :: TextLabel
		local crossfadeB = child(visual, "CrossfadeB") :: TextLabel
		local locked = child(visual, "LockedValue") :: TextLabel
		strip.Visible = false
		crossfadeA.Visible = false
		crossfadeB.Visible = false
		locked.Text = tostring(natural)
		locked.TextTransparency = if index == notice.appliedIndex then 0 else 0.5
		if index == notice.appliedIndex then
			local scale = child(visual, "AppliedScale") :: UIScale
			self:_tween(notice.rollId, scale, descriptor.naturalLock.durationMs, {
				Scale = if descriptor.dualApplied.enabled then descriptor.dualApplied.scale else 1,
			})
			local color = semanticColor(notice.semanticCritical)
			if color ~= nil then
				local stroke = child(visual, "AppliedAccent") :: UIStroke
				if reducedMotion then
					self:_runReducedCritical(
						visual,
						locked,
						stroke,
						notice,
						descriptor,
						generation,
						color
					)
				elseif notice.semanticCritical == "natural_1" then
					self:_runDampedCritical(
						visual,
						locked,
						stroke,
						notice,
						descriptor,
						generation,
						Tokens.Color.Danger
					)
				elseif notice.semanticCritical == "natural_20" then
					self:_runDampedCritical(
						visual,
						locked,
						stroke,
						notice,
						descriptor,
						generation,
						Tokens.Color.Success
					)
				end
			end
		end
	end
end

function DiceSlotRevealNotice:_renderPhase(
	frame: Frame,
	notice: any,
	phase: any,
	reducedMotion: boolean,
	generation: number
)
	if self.generations[notice.rollId] ~= generation or frame.Parent == nil then
		return
	end
	self:_cancelTweens(notice.rollId)
	frame:SetAttribute("RVTTDiceRevealPhase", phase.name)
	frame:SetAttribute("RVTTReducedMotionCrossfadeSteps", phase.crossfadeSteps)
	frame:SetAttribute("RVTTNaturalOneShake", phase.shake)
	frame:SetAttribute("RVTTNaturalCriticalPulse", phase.pulse)
	local descriptor = DiceNoticeViewModel.animationDescriptor(notice, reducedMotion)
	local formula = child(frame, "Formula") :: TextLabel
	local total = child(frame, "Total") :: TextLabel
	local adjudication = child(frame, "Adjudication") :: TextLabel

	if phase.name == "hidden" then
		frame.Visible = false
		return
	elseif phase.name == "square_enter" then
		frame.Visible = true
		frame.BackgroundTransparency = 1
		local enterScale = child(frame, "EnterScale") :: UIScale
		enterScale.Scale = 0.86
		self:_tween(notice.rollId, frame, phase.durationMs, { BackgroundTransparency = 0 })
		self:_tween(notice.rollId, enterScale, phase.durationMs, { Scale = 1 })
	elseif phase.name == "slot_spin" then
		if reducedMotion then
			self:_spinReduced(frame, notice, descriptor, generation)
		else
			self:_spinVertical(frame, notice, descriptor)
		end
	elseif phase.name == "natural_lock" then
		self:_lockNaturals(frame, notice, descriptor, reducedMotion, generation)
	elseif phase.name == "formula_expand" then
		formula.Text = notice.subjectLabel
			.. " · "
			.. notice.actionLabel
			.. " · "
			.. formulaText(notice)
		total.Text = "= " .. tostring(notice.total)
		formula.Visible = true
		total.Visible = true
		formula.TextTransparency = 1
		total.TextTransparency = 1
		self:_tween(notice.rollId, frame, descriptor.formulaExpand.durationMs, {
			Size = UDim2.fromOffset(descriptor.formulaExpand.targetWidth, 64),
		})
		self:_tween(
			notice.rollId,
			formula,
			descriptor.formulaExpand.durationMs,
			{ TextTransparency = 0 }
		)
		self:_tween(
			notice.rollId,
			total,
			descriptor.formulaExpand.durationMs,
			{ TextTransparency = 0 }
		)
		for _, connectorChild in frame:GetChildren() do
			if
				connectorChild:IsA("Frame")
				and string.find(connectorChild.Name, "FormulaConnector_", 1, true) == 1
			then
				local targetWidth = connectorChild:GetAttribute("RVTTConnectorTargetWidth")
				connectorChild.Visible = true
				connectorChild.Size = UDim2.fromOffset(0, 2)
				self:_tween(notice.rollId, connectorChild, descriptor.formulaExpand.durationMs, {
					Size = UDim2.fromOffset(
						if type(targetWidth) == "number" then targetWidth else 0,
						2
					),
				})
			end
		end
	elseif phase.name == "adjudication_append" then
		adjudication.Text = notice.adjudication
		adjudication.Visible = true
		adjudication.TextTransparency = 1
		self:_tween(notice.rollId, adjudication, phase.durationMs, { TextTransparency = 0 })
	elseif phase.name == "dismiss" then
		self:_tween(notice.rollId, frame, phase.durationMs, { BackgroundTransparency = 1 })
		for _, descendant in frame:GetDescendants() do
			if descendant:IsA("TextLabel") then
				self:_tween(notice.rollId, descendant, phase.durationMs, { TextTransparency = 1 })
			elseif descendant:IsA("UIStroke") then
				self:_tween(notice.rollId, descendant, phase.durationMs, { Transparency = 1 })
			end
		end
	end
end

function DiceSlotRevealNotice:_animate(frame: Frame, notice: any, reducedMotion: boolean)
	self.generations[notice.rollId] = (self.generations[notice.rollId] or 0) + 1
	local generation = self.generations[notice.rollId]
	local elapsed = 0
	for _, phase in DiceNoticeViewModel.presentationPlan(notice, reducedMotion) do
		local scheduled = phase
		self:_schedule(notice.rollId, generation, elapsed / 1000, function()
			if frame.Parent == nil then
				return
			end
			self:_renderPhase(frame, notice, scheduled, reducedMotion, generation)
			if scheduled.name == "dismiss" then
				self:_schedule(notice.rollId, generation, scheduled.durationMs / 1000, function()
					self.onDismiss(notice.rollId)
				end)
			end
		end)
		elapsed += phase.durationMs
	end
end

function DiceSlotRevealNotice:render(state: any, reducedMotion: boolean, initiativeVisible: boolean)
	local activeIds = {}
	for index, notice in state.active do
		activeIds[notice.rollId] = true
		local frame = self.frames[notice.rollId]
		if frame == nil then
			frame = self:_createFrame(notice, index, initiativeVisible)
			self.frames[notice.rollId] = frame
			self:_animate(frame, notice, reducedMotion)
		else
			local layout = DiceNoticeViewModel.layout(notice, initiativeVisible)
			frame.Position = UDim2.new(0.5, 0, 0, layout.topOffset + (index - 1) * 72)
		end
	end
	for rollId, frame in self.frames do
		if activeIds[rollId] ~= true then
			self.generations[rollId] = (self.generations[rollId] or 0) + 1
			self:_cancelTweens(rollId)
			frame:Destroy()
			self.frames[rollId] = nil
		end
	end
end

function DiceSlotRevealNotice:destroy()
	for rollId, _ in self.frames do
		self.generations[rollId] = (self.generations[rollId] or 0) + 1
		self:_cancelTweens(rollId)
	end
	self.Root:Destroy()
end

return DiceSlotRevealNotice
