--!strict

local ManagementViewModel = {}

local function domainsOf(payload: any): any
	return if type(payload) == "table" and type(payload.domains) == "table"
		then payload.domains
		else {}
end

local function roleOf(domains: any, userId: number): string
	local session = domains.session
	local memberships = if type(session) == "table" then session.memberships else nil
	local membership = if type(memberships) == "table" then memberships[tostring(userId)] else nil
	return if type(membership) == "table" and type(membership.role) == "string"
		then membership.role
		else "observer"
end

local function sortedValues(source: any): { any }
	local values = {}
	if type(source) ~= "table" then
		return values
	end
	for _, value in source do
		if type(value) == "table" then
			table.insert(values, value)
		end
	end
	table.sort(values, function(left, right)
		local leftLabel = tostring(left.title or left.definitionId or left.name or left.id or "")
		local rightLabel =
			tostring(right.title or right.definitionId or right.name or right.id or "")
		if leftLabel == rightLabel then
			return tostring(left.id or "") < tostring(right.id or "")
		end
		return leftLabel < rightLabel
	end)
	return values
end

local function ownedCharacters(domains: any, userId: number, role: string): { [string]: any }
	local result = {}
	local character = domains.character
	local characters = if type(character) == "table" then character.characters else nil
	if type(characters) == "table" then
		for id, value in characters do
			if type(value) == "table" and (role == "dm" or value.ownerUserId == userId) then
				result[id] = value
			end
		end
	end
	return result
end

local function targetCharacterId(
	domains: any,
	userId: number,
	selectedActorId: string?,
	owned: any
): string?
	local scene = domains.scene
	local actors = if type(scene) == "table" then scene.actors else nil
	local actor = if type(actors) == "table" and type(selectedActorId) == "string"
		then actors[selectedActorId]
		else nil
	local fromActor = if type(actor) == "table" then actor.sourceCharacterId else nil
	if type(fromActor) == "string" and owned[fromActor] ~= nil then
		return fromActor
	end
	local session = domains.session
	local selected = if type(session) == "table" then session.selectedCharacter else nil
	local fromSession = if type(selected) == "table" then selected[tostring(userId)] else nil
	if type(fromSession) == "string" and owned[fromSession] ~= nil then
		return fromSession
	end
	local ids = {}
	for id in owned do
		table.insert(ids, id)
	end
	table.sort(ids)
	return ids[1]
end

local function locationLabel(location: any, characters: any): string
	if type(location) ~= "table" then
		return "위치 정보 없음"
	end
	if location.kind == "ground" then
		return "지면"
	end
	local character = characters[location.characterId]
	local name = if type(character) == "table" and type(character.name) == "string"
		then character.name
		else tostring(location.characterId or "알 수 없는 캐릭터")
	if location.kind == "equipped" then
		return string.format("%s · 장착(%s)", name, tostring(location.slot or "?"))
	end
	return name .. " · 소지품"
end

function ManagementViewModel.build(
	payload: any,
	userId: number,
	selectedActorId: string?,
	revision: number,
	selection: any?
): any
	local domains = domainsOf(payload)
	local role = roleOf(domains, userId)
	local owned = ownedCharacters(domains, userId, role)
	local targetId = targetCharacterId(domains, userId, selectedActorId, owned)
	local inventory = domains.inventory
	local locations = if type(inventory) == "table"
			and type(inventory.locations) == "table"
		then inventory.locations
		else {}
	local items = {}
	for _, item in sortedValues(if type(inventory) == "table" then inventory.items else nil) do
		local location = locations[item.id]
		local ownsCurrent = role == "dm"
			or (
				type(location) == "table"
				and type(location.characterId) == "string"
				and owned[location.characterId] ~= nil
			)
		local canMove = targetId ~= nil
			and ownsCurrent
			and not (
				type(location) == "table"
				and location.kind == "inventory"
				and location.characterId == targetId
			)
		table.insert(items, {
			id = item.id,
			label = tostring(item.definitionId or item.id),
			quantity = item.quantity,
			location = locationLabel(location, owned),
			canMoveToSelected = canMove,
			disabledReason = if canMove
				then nil
				elseif targetId == nil then "조작할 캐릭터가 없습니다"
				elseif not ownsCurrent then "이 아이템을 이동할 권한이 없습니다"
				else "이미 선택 캐릭터의 소지품에 있습니다",
		})
	end

	local journal = domains.journal
	local documents = {}
	for _, document in sortedValues(if type(journal) == "table" then journal.documents else nil) do
		table.insert(documents, {
			id = document.id,
			title = if type(document.title) == "string" and document.title ~= ""
				then document.title
				else "제목 없음",
			body = if type(document.body) == "string" then document.body else "",
			visibility = document.visibility,
			canEdit = role == "dm" or document.ownerUserId == userId,
		})
	end

	local selectedItemId = if type(selection) == "table" then selection.itemId else nil
	local selectedDocumentId = if type(selection) == "table" then selection.documentId else nil
	local itemExists = false
	for _, item in items do
		itemExists = itemExists or item.id == selectedItemId
	end
	local documentExists = false
	for _, document in documents do
		documentExists = documentExists or document.id == selectedDocumentId
	end

	return {
		revision = revision,
		role = role,
		targetCharacterId = targetId,
		items = items,
		documents = documents,
		selectedItemId = if itemExists
			then selectedItemId
			else if items[1] then items[1].id else nil,
		selectedDocumentId = if documentExists
			then selectedDocumentId
			else if documents[1] then documents[1].id else nil,
		canCreateDocument = role == "player" or role == "dm",
	}
end

function ManagementViewModel.moveIntent(
	state: any,
	itemId: any,
	candidateRevision: any
): (any?, string?)
	if type(state) ~= "table" or candidateRevision ~= state.revision then
		return nil, "STALE_PROJECTION"
	end
	for _, item in state.items do
		if item.id == itemId then
			if not item.canMoveToSelected then
				return nil, "PERMISSION_DENIED"
			end
			return {
				commandType = "inventory.move_item",
				payload = {
					itemId = item.id,
					location = { kind = "inventory", characterId = state.targetCharacterId },
				},
			},
				nil
		end
	end
	return nil, "NOT_PROJECTED"
end

function ManagementViewModel.createDocumentIntent(
	state: any,
	title: any,
	body: any,
	candidateRevision: any
): (any?, string?)
	if type(state) ~= "table" or candidateRevision ~= state.revision then
		return nil, "STALE_PROJECTION"
	end
	if
		state.canCreateDocument ~= true
		or type(title) ~= "string"
		or #title > 160
		or type(body) ~= "string"
		or #body > 20000
	then
		return nil, "INVALID_INTENT"
	end
	return {
		commandType = "journal.create",
		payload = { title = title, body = body, visibility = "private" },
	},
		nil
end

function ManagementViewModel.editDocumentIntent(
	state: any,
	documentId: any,
	title: any,
	body: any,
	candidateRevision: any
): (any?, string?)
	if type(state) ~= "table" or candidateRevision ~= state.revision then
		return nil, "STALE_PROJECTION"
	end
	for _, document in state.documents do
		if document.id == documentId then
			if document.canEdit ~= true then
				return nil, "PERMISSION_DENIED"
			end
			if
				type(title) ~= "string"
				or #title > 160
				or type(body) ~= "string"
				or #body > 20000
			then
				return nil, "INVALID_INTENT"
			end
			return {
				commandType = "journal.edit",
				payload = { documentId = document.id, title = title, body = body },
			},
				nil
		end
	end
	return nil, "NOT_PROJECTED"
end

return table.freeze(ManagementViewModel)
