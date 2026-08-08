--!strict

return function(harness)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Server = game:GetService("ServerScriptService").RVTT.Server
	local RemoteBootstrap = require(Server.Networking.RemoteBootstrap)
	local Names = require(ReplicatedStorage.RVTT.Shared.Protocol.RemoteNames)

	local function clearCandidates()
		for _, child in ReplicatedStorage:GetChildren() do
			if child.Name == Names.FOLDER then
				child:Destroy()
			end
		end
	end

	clearCandidates()

	local stale = Instance.new("Folder")
	stale.Name = Names.FOLDER
	stale.Parent = ReplicatedStorage
	local staleCommand = Instance.new("RemoteEvent")
	staleCommand.Name = Names.COMMAND
	staleCommand.Parent = stale

	local duplicate = Instance.new("Folder")
	duplicate.Name = Names.FOLDER
	duplicate.Parent = ReplicatedStorage
	local wrongReceipt = Instance.new("StringValue")
	wrongReceipt.Name = Names.RECEIPT
	wrongReceipt.Parent = duplicate

	local remotes = RemoteBootstrap.create()
	harness:expect(remotes.folder:IsA("Folder"), "canonical remote folder is created")
	harness:expect(remotes.command:IsA("RemoteEvent"), "command remote is created")
	harness:expect(remotes.receipt:IsA("RemoteEvent"), "receipt remote is created")
	harness:expect(remotes.projection:IsA("RemoteEvent"), "projection remote is created")
	harness:expect(remotes.sync:IsA("RemoteFunction"), "sync remote is created")
	harness:expect(
		remotes.viewerProjectionPreview:IsA("RemoteFunction"),
		"viewer projection preview remote is created"
	)
	harness:expect(remotes.clientReady:IsA("RemoteEvent"), "client-ready remote is created")
	harness:expect(type(Names.RULE_READER_QUERY) == "string", "rule reader query has a canonical remote name")
	harness:expect(stale.Parent == nil, "stale partial folder is removed")
	harness:expect(duplicate.Parent == nil, "duplicate malformed folder is removed")

	local candidateCount = 0
	for _, child in ReplicatedStorage:GetChildren() do
		if child.Name == Names.FOLDER then
			candidateCount += 1
		end
	end
	harness:equal(candidateCount, 1, "only one canonical remote folder remains")

	local second = RemoteBootstrap.create()
	harness:expect(second.folder == remotes.folder, "complete canonical folder is reused")

	clearCandidates()

	-- Keep the focused Core Rules Reader regression in the established unit runner
	-- without requiring a second boot-time remote set in RVTT_TestMode.
	require(script.Parent["CoreRulesReader.spec"])(harness)
end
