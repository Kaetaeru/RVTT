--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteNames = require(ReplicatedStorage.RVTT.Shared.Protocol.RemoteNames)

local RemoteBootstrap = {}

local EXPECTED = {
	{ key = "command", name = RemoteNames.COMMAND, className = "RemoteEvent" },
	{ key = "receipt", name = RemoteNames.RECEIPT, className = "RemoteEvent" },
	{ key = "projection", name = RemoteNames.PROJECTION, className = "RemoteEvent" },
	{ key = "sync", name = RemoteNames.SYNC, className = "RemoteFunction" },
	{
		key = "viewerProjectionPreview",
		name = RemoteNames.VIEWER_PROJECTION_PREVIEW,
		className = "RemoteFunction",
	},
	{ key = "clientReady", name = RemoteNames.CLIENT_READY, className = "RemoteEvent" },
}

local function uniqueTypedChild(parent: Instance, name: string, className: string): Instance?
	local match = nil
	for _, child in parent:GetChildren() do
		if child.Name == name then
			if match ~= nil or child.ClassName ~= className then
				return nil
			end
			match = child
		end
	end
	return match
end

local function isCompleteFolder(instance: Instance): boolean
	if not instance:IsA("Folder") then
		return false
	end
	for _, spec in EXPECTED do
		if uniqueTypedChild(instance, spec.name, spec.className) == nil then
			return false
		end
	end
	return true
end

local function namedCandidates(): { Instance }
	local candidates = {}
	for _, child in ReplicatedStorage:GetChildren() do
		if child.Name == RemoteNames.FOLDER then
			table.insert(candidates, child)
		end
	end
	return candidates
end

local function buildCompleteFolder(): Folder
	local folder = Instance.new("Folder")
	for _, spec in EXPECTED do
		local remote = Instance.new(spec.className)
		remote.Name = spec.name
		remote.Parent = folder
	end
	return folder
end

local function requireRemote(folder: Folder, name: string, className: string): Instance
	local remote = uniqueTypedChild(folder, name, className)
	assert(remote ~= nil, "complete remote set is missing " .. name)
	return remote
end

function RemoteBootstrap.create()
	local candidates = namedCandidates()
	local folder: Folder
	if #candidates == 1 and isCompleteFolder(candidates[1]) then
		folder = candidates[1] :: Folder
	else
		folder = buildCompleteFolder()
		for _, candidate in candidates do
			candidate:Destroy()
		end
		folder.Name = RemoteNames.FOLDER
		folder.Parent = ReplicatedStorage
		print(
			string.format(
				"[RVTT Networking] published canonical remote set replaced=%d",
				#candidates
			)
		)
	end

	return {
		folder = folder,
		command = requireRemote(folder, RemoteNames.COMMAND, "RemoteEvent") :: RemoteEvent,
		receipt = requireRemote(folder, RemoteNames.RECEIPT, "RemoteEvent") :: RemoteEvent,
		projection = requireRemote(folder, RemoteNames.PROJECTION, "RemoteEvent") :: RemoteEvent,
		sync = requireRemote(folder, RemoteNames.SYNC, "RemoteFunction") :: RemoteFunction,
		viewerProjectionPreview = requireRemote(
			folder,
			RemoteNames.VIEWER_PROJECTION_PREVIEW,
			"RemoteFunction"
		) :: RemoteFunction,
		clientReady = requireRemote(folder, RemoteNames.CLIENT_READY, "RemoteEvent") :: RemoteEvent,
	}
end

return table.freeze(RemoteBootstrap)
