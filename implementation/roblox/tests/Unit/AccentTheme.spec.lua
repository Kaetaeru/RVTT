--!strict

return function(harness)
	local UI = game:GetService("ReplicatedStorage").RVTT.Shared.UI
	local AccentPreference = require(UI.AccentPreference)
	local AccentPalette = require(UI.AccentPalette)

	harness:equal(AccentPreference.KEY, "accentPaletteId", "accent preference key is stable")
	harness:equal(AccentPreference.DEFAULT_ID, "gold", "gold is the default accent")
	harness:equal(AccentPreference.normalize(nil), "gold", "missing accent falls back to gold")
	harness:equal(
		AccentPreference.normalize("unsupported"),
		"gold",
		"unknown accent falls back to gold"
	)

	local ids = AccentPreference.list()
	harness:equal(#ids, 6, "six reviewed accent palettes are available")
	for _, id in ids do
		harness:expect(AccentPreference.isValid(id), id .. " is an allowed accent")
		local palette = AccentPalette.resolve(id)
		harness:equal(palette.id, id, id .. " resolves to the matching palette")
		harness:expect(typeof(palette.primary) == "Color3", id .. " has a primary color")
		harness:expect(typeof(palette.on) == "Color3", id .. " has an on-accent color")
	end

	harness:equal(AccentPalette.resolve("unsupported").id, "gold", "palette resolver is safe")
	harness:expect(
		AccentPalette.resolve("gold").primary ~= AccentPalette.resolve("azure").primary,
		"palette primary colors are distinct"
	)
end
