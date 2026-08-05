--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Names = require(ReplicatedStorage.RVTT.Shared.Protocol.RemoteNames)

local remoteFolder = ReplicatedStorage:WaitForChild(Names.FOLDER)
local remotes = {
	command = remoteFolder:WaitForChild(Names.COMMAND) :: RemoteEvent,
	receipt = remoteFolder:WaitForChild(Names.RECEIPT) :: RemoteEvent,
	projection = remoteFolder:WaitForChild(Names.PROJECTION) :: RemoteEvent,
	sync = remoteFolder:WaitForChild(Names.SYNC) :: RemoteFunction,
	clientReady = remoteFolder:WaitForChild(Names.CLIENT_READY) :: RemoteEvent,
}

local clientModules = script.Client
local ProjectionReplica = require(clientModules.ProjectionReplica)
local CommandClient = require(clientModules.CommandClient)
local InputContextStack = require(clientModules.InputContextStack)
local SemanticInputRouter = require(clientModules.SemanticInputRouter)
local ClientRuntime = require(clientModules.ClientRuntime)

local replica = ProjectionReplica.new()
local command = CommandClient.new(remotes, replica)
local inputStack = InputContextStack.new()
local inputRouter = SemanticInputRouter.new(inputStack)

local function fullResync()
	local succeeded, snapshot = pcall(function()
		return remotes.sync:InvokeServer()
	end)
	if succeeded and snapshot ~= nil then
		replica:apply(snapshot, true)
	end
end

command:start(function(message)
	if message.phase == "terminal" and message.result ~= nil and not message.result.ok then
		warn("[RVTT Command]", message.result.error.code)
		if
			message.result.error.code == "STALE_EPOCH"
			or message.result.error.code == "STALE_REVISION"
		then
			fullResync()
		end
	end
end)

replica.GapDetected:Connect(function()
	fullResync()
end)
remotes.projection.OnClientEvent:Connect(function(envelope)
	replica:apply(envelope, false)
end)

fullResync()
inputRouter:start()
ClientRuntime.set({ Replica = replica, Command = command, Input = inputStack })
remotes.clientReady:FireServer()

local loadingGui = Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("RVTT_Loading")
if loadingGui ~= nil then
	loadingGui:Destroy()
end
