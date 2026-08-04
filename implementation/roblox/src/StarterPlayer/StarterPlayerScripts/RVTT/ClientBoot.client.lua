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

command:start(function(result)
	if not result.ok then
		warn("[RVTT Command]", result.error.code)
	end
end)

remotes.projection.OnClientEvent:Connect(function(envelope)
	replica:apply(envelope)
end)

local syncSucceeded, snapshot = pcall(function()
	return remotes.sync:InvokeServer()
end)
if syncSucceeded and snapshot ~= nil then
	replica:apply(snapshot)
end

inputRouter:start()
ClientRuntime.set({
	Replica = replica,
	Command = command,
	Input = inputStack,
})
remotes.clientReady:FireServer()

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local loadingGui = playerGui:FindFirstChild("RVTT_Loading")
if loadingGui ~= nil then
	loadingGui:Destroy()
end
