--!strict
return {
	{
		packageId = "rvtt.core.rules",
		version = "5.2.1-rvtt.1",
		dependencies = {},
		contentKinds = {
			"rule-packs",
			"rule-documents",
			"rule-search-index",
		},
		rightsStatus = "built_in",
		licenseId = "CC-BY-4.0",
		attributionRequired = true,
	},
	{
		packageId = "rvtt.core.baseline",
		version = "2026.08.06",
		dependencies = {
			"rvtt.core.rules",
		},
		contentKinds = {
			"token-prefabs",
			"prop-prefabs",
			"tile-prefabs",
			"volume-prefabs",
			"materials",
			"vfx",
			"ui-assets",
		},
		rightsStatus = "built_in",
		licenseId = "RVTT-PROJECT",
		attributionRequired = false,
	},
}
