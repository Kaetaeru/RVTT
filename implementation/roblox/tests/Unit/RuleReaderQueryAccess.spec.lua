--!strict

return function(h: any)
	local Server = game:GetService("ServerScriptService").RVTT.Server
	local Query = require(Server.Networking.RuleReaderQuery)
	local remote = Instance.new("RemoteFunction")
	local serviceCalls = 0
	local service = {
		manifest = function(_package: any, _viewer: any, _profile: any): any
			serviceCalls += 1
			return { secret = "owner-only" }
		end,
		search = function(_package: any, _viewer: any, _query: string, _limit: any): any
			serviceCalls += 1
			return { results = { { snippet = "owner-only" } } }
		end,
		open = function(_package: any, _viewer: any, _uri: any): (any?, string?)
			serviceCalls += 1
			return { chunk = { text = "owner-only" } }, nil
		end,
		chunk = function(_package: any, _viewer: any, _chunkId: any): (any?, string?)
			serviceCalls += 1
			return { text = "owner-only" }, nil
		end,
	}
	local package = {
		packageId = "rvtt.test.rules.2024.integrated.ko",
	}
	local profile = {
		ok = true,
		value = {
			activeProfile = "development",
			basePackageId = "rvtt.test.rules.2024.integrated.ko",
		},
	}
	local authorized = false
	local query = Query.new(
		remote,
		function(_player: Player): string
			return "player"
		end,
		service,
		function(): any
			return profile
		end,
		function(_packageId: string): any
			return package
		end,
		function(): number
			return 0
		end,
		function(_player: Player): boolean
			return authorized
		end
	)
	local player = ({ UserId = 90125 } :: any) :: Player

	for _, request in
		{
			{ action = "manifest" },
			{ action = "search", query = "secret" },
			{
				action = "open",
				uri = "rvtt-rule://rvtt.test.rules.2024.integrated.ko/test/doc#anchor",
			},
			{ action = "chunk", chunkId = "private.test.doc.anchor.1" },
		}
	do
		local denied = query:_handle(player, request)
		h:expect(denied.ok == false, "unauthorized private query is denied")
		h:equal(
			denied.error.code,
			"RULE_PROFILE_UNAVAILABLE",
			"denial does not reveal private package state"
		)
		h:equal(denied.value, nil, "denial contains no private value")
	end
	h:equal(serviceCalls, 0, "unauthorized private viewer never reaches rule body service")

	authorized = true
	local allowed = query:_handle(player, { action = "manifest" })
	h:expect(allowed.ok == true, "explicitly authorized private viewer reaches reader service")
	h:equal(serviceCalls, 1, "authorized private viewer executes one reader service call")
	remote:Destroy()
end
