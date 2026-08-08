--!strict

return function(h)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Server = game:GetService("ServerScriptService").RVTT.Server
	local RuleLink = require(ReplicatedStorage.RVTT.Shared.Rules.RuleLink)
	local Reader = require(Server.Rules.RuleReaderService)
	local ViewModel = require(ReplicatedStorage.RVTT.Shared.UI.CoreRulesReaderViewModel)

	local package: any = {
		packageId = "rvtt.core.rules",
		version = "fixture",
		locale = "ko-KR",
		license = {
			licenseId = "CC-BY-4.0",
			attributionRequired = true,
			attributionText = "fixture attribution",
		},
		modules = {},
		chunks = {},
	}
	local largeChunkIds = {}
	for index = 1, 45 do
		local chunkId = "public.chunk." .. tostring(index)
		table.insert(largeChunkIds, chunkId)
		package.chunks[chunkId] = {
			id = chunkId,
			moduleId = "public-module",
			documentId = "large-document",
			anchorId = if index == 1 then "large" else "large-" .. tostring(index),
			text = string.rep("x", 5000) .. if index == 1 then " searchable-public" else "",
			keywords = if index == 1 then { "searchable-public" } else {},
			relatedLinks = if index == 1
				then {
					"rvtt-rule://rvtt.core.rules/public-module/large-document#large",
					"rvtt-rule://rvtt.core.rules/hidden-module/hidden-document#secret",
				}
				else {},
			backlinks = {},
		}
	end
	package.chunks["hidden.chunk"] = {
		id = "hidden.chunk",
		moduleId = "hidden-module",
		documentId = "hidden-document",
		anchorId = "secret",
		text = "forbidden-needle hidden rule body",
		keywords = { "forbidden-needle" },
		relatedLinks = {},
		backlinks = {},
	}
	package.modules = {
		{
			id = "public-module",
			title = "Public Module",
			visibility = "public",
			documents = {
				{
					id = "large-document",
					title = "Large Document",
					sourceLabel = "Fixture",
					visibility = "public",
					sections = {
						{
							anchorId = "large",
							title = "Large Section",
							chunkIds = largeChunkIds,
						},
					},
				},
			},
		},
		{
			id = "hidden-module",
			title = "Hidden Module Title",
			visibility = "dm",
			documents = {
				{
					id = "hidden-document",
					title = "Hidden Document Title",
					visibility = "dm",
					sections = {
						{
							anchorId = "secret",
							title = "Secret Section",
							chunkIds = { "hidden.chunk" },
						},
					},
				},
			},
		},
	}

	local player = { userId = 101, role = "player" }
	local dm = { userId = 1, role = "dm" }
	local profile = {
		activeProfile = "public",
		basePackageId = "rvtt.core.rules",
		fallbackActive = false,
		attributionRequired = true,
	}

	local manifest = Reader.manifest(package, player, profile)
	h:equal(#manifest.modules, 1, "player manifest omits unauthorized module without placeholder")
	h:equal(manifest.modules[1].title, "Public Module", "authorized module title remains visible")
	h:equal(manifest.modules[1].documents[1].sections[1].chunkIds, nil, "manifest does not replicate chunk ids or body graph")
	h:equal(manifest.chunks, nil, "manifest never includes the large rule body")

	local totalBody = 0
	for _, chunk in package.chunks do
		totalBody += #chunk.text
	end
	h:expect(totalBody > 200000, "fixture exceeds the large-package acceptance threshold")

	local hiddenSearch = Reader.search(package, player, "forbidden-needle", 20)
	h:equal(#hiddenSearch.results, 0, "unauthorized title/count/snippet stays absent from search")
	local dmHiddenSearch = Reader.search(package, dm, "forbidden-needle", 20)
	h:equal(#dmHiddenSearch.results, 1, "authorized viewer can search the hidden module")

	local publicSearch = Reader.search(package, player, "searchable-public", 20)
	h:equal(#publicSearch.results, 1, "authorized rule content is searchable")
	h:expect(#publicSearch.results[1].snippet <= 182, "search snippet is bounded")

	local uri = RuleLink.build("rvtt.core.rules", "public-module", "large-document", "large")
	h:expect(uri ~= nil, "stable rule URI is created")
	local parsed = RuleLink.parse(uri)
	h:equal(parsed.packageId, "rvtt.core.rules", "stable URI preserves package id")
	h:equal(parsed.anchorId, "large", "stable URI preserves anchor")
	h:equal(RuleLink.parse("rvtt-rule://bad/path"), nil, "malformed rule URI fails closed")

	local opened, openError = Reader.open(package, player, uri)
	h:expect(opened ~= nil and openError == nil, "authorized stable URI opens")
	if opened ~= nil then
		h:equal(#opened.chunk.text, 5018, "open returns one chunk rather than the whole package")
		h:equal(opened.chunk.nextChunkId, "public.chunk.2", "open exposes only the adjacent lazy-load cursor")
		h:equal(#opened.chunk.relatedLinks, 1, "related links are permission filtered")
	end

	local second, secondError = Reader.chunk(package, player, "public.chunk.2")
	h:expect(second ~= nil and secondError == nil, "adjacent authorized chunk lazy-loads")
	local hiddenChunk, hiddenChunkError = Reader.chunk(package, player, "hidden.chunk")
	h:equal(hiddenChunk, nil, "unauthorized chunk returns no payload")
	h:equal(hiddenChunkError, "RULE_CHUNK_UNAVAILABLE", "unauthorized chunk uses nondisclosing failure")
	local hiddenOpen, hiddenOpenError = Reader.open(
		package,
		player,
		"rvtt-rule://rvtt.core.rules/hidden-module/hidden-document#secret"
	)
	h:equal(hiddenOpen, nil, "unauthorized stable URI returns no title or body")
	h:equal(hiddenOpenError, "RULE_LINK_UNAVAILABLE", "unauthorized link uses nondisclosing failure")

	local state = ViewModel.initial()
	ViewModel.applyManifest(state, { ok = true, value = manifest })
	h:equal(ViewModel.profileBadge(manifest), "SRD RELEASE", "public package profile badge is explicit")
	ViewModel.applyOpen(state, { ok = true, value = opened })
	h:equal(#state.chunkOrder, 1, "view model starts with one visible chunk")
	ViewModel.appendChunk(state, { ok = true, value = second }, "next")
	h:equal(#state.chunkOrder, 2, "view model appends only requested adjacent chunks")
end
