--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteNames = require(ReplicatedStorage.RVTT.Shared.Protocol.RemoteNames)

local RemoteBootstrap = {}

local function ensure(className: string, parent: Instance, name: string): Instance
	local existing = parent:FindFirstChild(name)
	if existing ~= nil then
		assert(existing.ClassName == className, "remote class mismatch: " .. name)
		return existing
	end
	local instance = Instance.new(className)
	instance.Name = name
	instance.Parent = parent
	return instance
end

function RemoteBootstrap.create()
	local folder = ensure("Folder", ReplicatedStorage, RemoteNames.FOLDER) :: Folder
	return {
		folder = folder,
		command = ensure("RemoteEvent", folder, RemoteNames.COMMAND) :: RemoteEvent,
		receipt = ensure("RemoteEvent", folder, RemoteNames.RECEIPT) :: RemoteEvent,
		projection = ensure("RemoteEvent", folder, RemoteNames.PROJECTION) :: RemoteEvent,
		sync = ensure("RemoteFunction", folder, RemoteNames.SYNC) :: RemoteFunction,
		clientReady = ensure("RemoteEvent", folder, RemoteNames.CLIENT_READY) :: RemoteEvent,
	}
end

return table.freeze(RemoteBootstrap)
