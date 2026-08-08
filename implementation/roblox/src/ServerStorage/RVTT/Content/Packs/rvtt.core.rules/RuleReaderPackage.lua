--!strict

-- This repository-safe package contains only client-eligible metadata and a small
-- original RVTT reader guide. Full private test-rule content is imported into a
-- restricted build workspace and must never be committed here.
return table.freeze({
	schemaVersion = 1,
	packageId = "rvtt.core.rules",
	version = "5.2.1-rvtt.1",
	locale = "en-US",
	license = {
		licenseId = "CC-BY-4.0",
		attributionRequired = true,
		attributionText = "SRD 5.2.1 content is provided under CC BY 4.0.",
	},
	modules = {
		{
			id = "srd521.playing-the-game",
			title = "Playing the Game",
			visibility = "public",
			documents = {
				{
					id = "reader-guide",
					title = "Core Rules Reader",
					sourceLabel = "RVTT Core Rules",
					visibility = "public",
					sections = {
						{
							anchorId = "overview",
							title = "Reader overview",
							chunkIds = { "srd521.reader-guide.overview" },
						},
						{
							anchorId = "links",
							title = "Stable rule links",
							chunkIds = { "srd521.reader-guide.links" },
						},
					},
				},
			},
		},
	},
	chunks = {
		["srd521.reader-guide.overview"] = {
			id = "srd521.reader-guide.overview",
			moduleId = "srd521.playing-the-game",
			documentId = "reader-guide",
			anchorId = "overview",
			text = "Core Rules loads only the rule text needed for the current article view. Search results and navigation are limited to content the current viewer is allowed to read.",
			keywords = { "reader", "rules", "search", "journal" },
			relatedLinks = {},
			backlinks = {},
		},
		["srd521.reader-guide.links"] = {
			id = "srd521.reader-guide.links",
			moduleId = "srd521.playing-the-game",
			documentId = "reader-guide",
			anchorId = "links",
			text = "Rule links use a stable package, module, document, and section anchor so character sheets, actions, conditions, dice results, and DM tools can open the same authoritative location.",
			keywords = { "anchor", "link", "stable", "navigation" },
			relatedLinks = {
				"rvtt-rule://rvtt.core.rules/srd521.playing-the-game/reader-guide#overview",
			},
			backlinks = {},
		},
	},
})
