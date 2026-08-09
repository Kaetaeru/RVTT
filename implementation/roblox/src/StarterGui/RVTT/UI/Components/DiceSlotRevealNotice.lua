--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

function DiceSlotRevealNotice.new(parent: Instance, onDismiss: (string) -> ()): any
	local root = Instance.new("Frame")
	root.Name = "DiceSlotRevealNotice"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.BorderSizePixel = 0
	root.Active = false
	root.Parent = parent
	return setmetatable(
		{ Root = root, frames = {}, generations = {}, onDismiss = onDismiss },
		DiceSlotRevealNotice
	)
end

function DiceSlotRevealNotice:_renderPhase(frame: Frame, notice: any, phase: any)
	frame:SetAttribute("RVTTDiceRevealPhase", phase.name)
	frame.Visible = phase.name ~= "hidden" and phase.name ~= "dismiss"
	local naturalRow = frame:FindFirstChild("NaturalRow") :: Frame
	local formula = frame:FindFirstChild("Formula") :: TextLabel
	local total = frame:FindFirstChild("Total") :: TextLabel
	local adjudication = frame:FindFirstChild("Adjudication") :: TextLabel
	naturalRow.Visible = phase.disclosure.natural
	formula.Visible = phase.disclosure.formula
	total.Visible = phase.disclosure.total
	adjudication.Visible = phase.disclosure.adjudication
	frame:SetAttribute("RVTTReducedMotionCrossfadeSteps", phase.crossfadeSteps)
	frame:SetAttribute("RVTTNaturalOneShake", phase.shake)
	frame:SetAttribute("RVTTNaturalCriticalPulse", phase.pulse)
	if phase.name == "formula_expand" or phase.disclosure.adjudication then
		frame.Size = UDim2.fromOffset(360, 64)
	end
	formula.Text = notice.subjectLabel
		.. " · "
		.. notice.actionLabel
		.. " · "
		.. formulaText(notice)
	total.Text = "= " .. tostring(notice.total)
	adjudication.Text = notice.adjudication
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
	frame.BorderSizePixel = 0
	frame:SetAttribute("RVTTBackgroundToken", "surfaceStrong")
	frame:SetAttribute("RVTTDiceMode", notice.diceMode)
	frame:SetAttribute("RVTTStackCap", 2)
	frame.Parent = self.Root
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
		local value = label("Natural_" .. tostring(cell.index), 24)
		value.Size = UDim2.fromOffset(56, 56)
		value.Text = tostring(cell.natural)
		value.TextTransparency = 1 - cell.contrast
		value:SetAttribute("RVTTApplied", cell.applied)
		value:SetAttribute("RVTTSemanticCritical", cell.semanticCritical)
		value:SetAttribute("RVTTDiscardedContrast", cell.contrast)
		value.Parent = naturalRow
	end

	local formula = label("Formula", Tokens.TextSize.Caption)
	formula.Position = UDim2.fromOffset(layout.initialWidth + 8, 6)
	formula.Size = UDim2.fromOffset(190, 24)
	formula.TextXAlignment = Enum.TextXAlignment.Left
	formula.Parent = frame
	local total = label("Total", Tokens.TextSize.Label)
	total.Position = UDim2.fromOffset(270, 5)
	total.Size = UDim2.fromOffset(82, 26)
	total.Parent = frame
	local adjudication = label("Adjudication", Tokens.TextSize.Caption)
	adjudication.Position = UDim2.fromOffset(layout.initialWidth + 8, 34)
	adjudication.Size = UDim2.fromOffset(280, 24)
	adjudication.TextXAlignment = Enum.TextXAlignment.Left
	adjudication.Parent = frame
	return frame
end

function DiceSlotRevealNotice:_animate(frame: Frame, notice: any, reducedMotion: boolean)
	self.generations[notice.rollId] = (self.generations[notice.rollId] or 0) + 1
	local generation = self.generations[notice.rollId]
	local elapsed = 0
	for _, phase in DiceNoticeViewModel.presentationPlan(notice, reducedMotion) do
		local scheduled = phase
		task.delay(elapsed / 1000, function()
			if self.generations[notice.rollId] ~= generation or frame.Parent == nil then
				return
			end
			self:_renderPhase(frame, notice, scheduled)
			if scheduled.name == "dismiss" then
				task.delay(scheduled.durationMs / 1000, function()
					if self.generations[notice.rollId] == generation then
						self.onDismiss(notice.rollId)
					end
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
			frame:Destroy()
			self.frames[rollId] = nil
		end
	end
end

function DiceSlotRevealNotice:destroy()
	self.Root:Destroy()
end

return DiceSlotRevealNotice
