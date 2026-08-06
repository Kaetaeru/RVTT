--!strict

local AccentPreference = {}

AccentPreference.KEY = "accentPaletteId"
AccentPreference.DEFAULT_ID = "gold"

local order: { string } = {
	"gold",
	"azure",
	"emerald",
	"amethyst",
	"teal",
	"silver",
}

local allowed: { [string]: boolean } = {}
for _, id in order do
	allowed[id] = true
end

function AccentPreference.isValid(value: any): boolean
	return type(value) == "string" and allowed[value] == true
end

function AccentPreference.normalize(value: any): string
	if AccentPreference.isValid(value) then
		return value
	end
	return AccentPreference.DEFAULT_ID
end

function AccentPreference.list(): { string }
	return table.clone(order)
end

return table.freeze(AccentPreference)
