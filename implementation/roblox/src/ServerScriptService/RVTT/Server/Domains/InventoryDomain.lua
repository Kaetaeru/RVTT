--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Identity = require(ReplicatedStorage.RVTT.Shared.Core.Identity)
local Helpers = require(script.Parent.DomainHelpers)
local ContentDefinitionResolver = require(script.Parent.Parent.Rules.ContentDefinitionResolver)

local Domain = { id = "inventory", slice = 6 }
local ITEM_CAPABILITY_FIELDS = {
	attunable = true,
	details = true,
	equipSlot = true,
	hotbarCapable = true,
	label = true,
	transferable = true,
	usable = true,
}

function Domain.initialState()
	return { items = {}, locations = {} }
end

local function validLocation(location: any): boolean
	if type(location) ~= "table" or type(location.kind) ~= "string" then
		return false
	end
	if location.kind == "ground" then
		return location.position == nil or Helpers.isVector(location.position)
	end
	if location.kind == "inventory" then
		return type(location.characterId) == "string"
	end
	if location.kind == "equipped" then
		return type(location.characterId) == "string" and type(location.slot) == "string"
	end
	return false
end

local function canReceive(context: any, domains: any, location: any): boolean
	if context.role == "dm" or location.kind == "ground" then
		return true
	end
	return Helpers.ownsCharacter(context, domains, location.characterId)
end

local function move(state: any, itemId: string, location: any)
	state.locations[itemId] = location
	state.items[itemId].revision += 1
	return { item = state.items[itemId], location = location }
end

function Domain.register(registry: any)
	registry:register({
		commandType = "inventory.create_item",
		domainId = Domain.id,
		authorize = function(context: any)
			return Helpers.requireRole(context, { "dm" })
		end,
		validate = function(payload: any)
			return Helpers.hasString(payload, "definitionId")
				and payload.location ~= nil
				and validLocation(payload.location)
		end,
		execute = function(_: any, state: any, payload: any, domains: any)
			local itemId = Identity.new("item")
			local item = {
				id = itemId,
				definitionId = payload.definitionId,
				quantity = math.clamp(math.floor(payload.quantity or 1), 1, 9999),
				revision = 1,
			}
			local definition =
				ContentDefinitionResolver.resolve(domains, "items", payload.definitionId)
			if type(definition) == "table" then
				for field, value in Helpers.copyFields(definition, ITEM_CAPABILITY_FIELDS) do
					item[field] = value
				end
			end
			state.items[itemId] = item
			state.locations[itemId] = payload.location
			return { item = state.items[itemId], location = payload.location }
		end,
	})

	registry:register({
		commandType = "inventory.move_item",
		domainId = Domain.id,
		authorize = function(context: any, domains: any, payload: any)
			return Helpers.ownsItem(context, domains, payload.itemId)
				and validLocation(payload.location)
				and canReceive(context, domains, payload.location)
		end,
		validate = function(payload: any)
			return Helpers.hasString(payload, "itemId") and validLocation(payload.location)
		end,
		execute = function(_: any, state: any, payload: any)
			if state.items[payload.itemId] == nil then
				return Helpers.notFound("item", payload.itemId)
			end
			return move(state, payload.itemId, payload.location)
		end,
	})

	registry:register({
		commandType = "inventory.equip",
		domainId = Domain.id,
		authorize = function(context: any, domains: any, payload: any)
			return Helpers.ownsItem(context, domains, payload.itemId)
				and Helpers.ownsCharacter(context, domains, payload.characterId)
		end,
		validate = function(payload: any)
			return Helpers.hasString(payload, "itemId")
				and Helpers.hasString(payload, "characterId")
				and (payload.slot == nil or Helpers.hasString(payload, "slot", 64))
		end,
		execute = function(_: any, state: any, payload: any)
			local item = state.items[payload.itemId]
			local location = state.locations[payload.itemId]
			if item == nil or type(location) ~= "table" then
				return Helpers.notFound("item", payload.itemId)
			end
			if type(item.equipSlot) ~= "string" or item.equipSlot == "" or #item.equipSlot > 64 then
				return Helpers.conflict("item is not equippable")
			end
			if
				location.characterId ~= payload.characterId
				or (location.kind ~= "inventory" and location.kind ~= "equipped")
			then
				return Helpers.conflict("item does not belong to the requested character")
			end
			if payload.slot ~= nil and payload.slot ~= item.equipSlot then
				return Helpers.conflict("requested slot does not match the trusted item slot")
			end
			return move(state, payload.itemId, {
				kind = "equipped",
				characterId = payload.characterId,
				slot = item.equipSlot,
			})
		end,
	})

	registry:register({
		commandType = "inventory.unequip",
		domainId = Domain.id,
		authorize = function(context: any, domains: any, payload: any)
			return Helpers.ownsItem(context, domains, payload.itemId)
				and Helpers.ownsCharacter(context, domains, payload.characterId)
		end,
		validate = function(payload: any)
			return Helpers.hasString(payload, "itemId")
				and Helpers.hasString(payload, "characterId")
		end,
		execute = function(_: any, state: any, payload: any)
			local item = state.items[payload.itemId]
			local location = state.locations[payload.itemId]
			if item == nil or type(location) ~= "table" then
				return Helpers.notFound("item", payload.itemId)
			end
			if location.kind ~= "equipped" or location.characterId ~= payload.characterId then
				return Helpers.conflict("item is not equipped by the requested character")
			end
			return move(state, payload.itemId, {
				kind = "inventory",
				characterId = payload.characterId,
			})
		end,
	})

	registry:register({
		commandType = "inventory.use",
		domainId = Domain.id,
		authorize = function(context: any, domains: any, payload: any)
			return Helpers.ownsItem(context, domains, payload.itemId)
		end,
		validate = function(payload: any)
			return Helpers.hasString(payload, "itemId")
		end,
		execute = function(_: any, state: any, payload: any)
			local item = state.items[payload.itemId]
			if item == nil then
				return Helpers.notFound("item", payload.itemId)
			end
			if item.usable ~= true then
				return Helpers.conflict("item is not usable")
			end
			item.quantity = math.max(0, math.floor(item.quantity or 1) - 1)
			item.revision += 1
			local remaining = item.quantity
			if remaining == 0 then
				state.items[payload.itemId] = nil
				state.locations[payload.itemId] = nil
			end
			return { itemId = payload.itemId, remaining = remaining }
		end,
	})

	registry:register({
		commandType = "inventory.split",
		domainId = Domain.id,
		authorize = function(context: any, domains: any, payload: any)
			return Helpers.ownsItem(context, domains, payload.itemId)
		end,
		validate = function(payload: any)
			return Helpers.hasString(payload, "itemId") and Helpers.hasNumber(payload, "quantity")
		end,
		execute = function(_: any, state: any, payload: any)
			local item = state.items[payload.itemId]
			local location = state.locations[payload.itemId]
			if item == nil or type(location) ~= "table" then
				return Helpers.notFound("item", payload.itemId)
			end
			local quantity = math.floor(payload.quantity)
			if quantity < 1 or quantity >= (item.quantity or 1) then
				return Helpers.conflict("split quantity is outside the available stack")
			end
			local splitId = Identity.new("item")
			local splitItem = table.clone(item)
			splitItem.id = splitId
			splitItem.quantity = quantity
			splitItem.revision = 1
			item.quantity -= quantity
			item.revision += 1
			state.items[splitId] = splitItem
			state.locations[splitId] = table.clone(location)
			return { source = item, split = splitItem, location = state.locations[splitId] }
		end,
	})

	registry:register({
		commandType = "inventory.send",
		domainId = Domain.id,
		authorize = function(context: any, domains: any, payload: any)
			return Helpers.ownsItem(context, domains, payload.itemId)
				and Helpers.ownsCharacter(context, domains, payload.targetCharacterId)
		end,
		validate = function(payload: any)
			return Helpers.hasString(payload, "itemId")
				and Helpers.hasString(payload, "targetCharacterId")
		end,
		execute = function(_: any, state: any, payload: any)
			local item = state.items[payload.itemId]
			if item == nil then
				return Helpers.notFound("item", payload.itemId)
			end
			if item.transferable == false then
				return Helpers.conflict("item transfer is disabled")
			end
			return move(state, payload.itemId, {
				kind = "inventory",
				characterId = payload.targetCharacterId,
			})
		end,
	})

	registry:register({
		commandType = "inventory.set_attunement",
		domainId = Domain.id,
		authorize = function(context: any, domains: any, payload: any)
			return Helpers.ownsItem(context, domains, payload.itemId)
				and Helpers.ownsCharacter(context, domains, payload.characterId)
		end,
		validate = function(payload: any)
			return Helpers.hasString(payload, "itemId")
				and Helpers.hasString(payload, "characterId")
				and type(payload.attuned) == "boolean"
		end,
		execute = function(_: any, state: any, payload: any)
			local item = state.items[payload.itemId]
			local location = state.locations[payload.itemId]
			if item == nil or type(location) ~= "table" then
				return Helpers.notFound("item", payload.itemId)
			end
			if item.attunable ~= true or location.characterId ~= payload.characterId then
				return Helpers.conflict("item cannot be attuned by the requested character")
			end
			item.attunedToCharacterId = if payload.attuned then payload.characterId else nil
			item.revision += 1
			return item
		end,
	})
end

return table.freeze(Domain)
