--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

if ReplicatedStorage:FindFirstChild("RVTT_TestMode") ~= nil then
	return
end

local BOOT_TIMEOUT_SECONDS = 10
local Names = require(ReplicatedStorage.RVTT.Shared.Protocol.RemoteNames)
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local function setLoadingStatus(message: string)
	local loadingGui = playerGui:FindFirstChild("RVTT_Loading")
	local status = if loadingGui ~= nil then loadingGui:FindFirstChild("Status") else nil
	if status ~= nil and status:IsA("TextLabel") then
		status.Text = message
	end
end

local function failBoot(message: string)
	setLoadingStatus(message)
	warn("[RVTT ClientBoot]", message)
end

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

local function resolveRemoteSet(folder: Folder): any?
	local command = uniqueTypedChild(folder, Names.COMMAND, "RemoteEvent")
	local receipt = uniqueTypedChild(folder, Names.RECEIPT, "RemoteEvent")
	local projection = uniqueTypedChild(folder, Names.PROJECTION, "RemoteEvent")
	local sync = uniqueTypedChild(folder, Names.SYNC, "RemoteFunction")
	local clientReady = uniqueTypedChild(folder, Names.CLIENT_READY, "RemoteEvent")
	if
		command == nil
		or receipt == nil
		or projection == nil
		or sync == nil
		or clientReady == nil
	then
		return nil
	end
	return {
		command = command :: RemoteEvent,
		receipt = receipt :: RemoteEvent,
		projection = projection :: RemoteEvent,
		sync = sync :: RemoteFunction,
		clientReady = clientReady :: RemoteEvent,
	}
end

local function describeRemoteCandidates(): string
	local descriptions = {}
	for _, candidate in ReplicatedStorage:GetChildren() do
		if candidate.Name == Names.FOLDER then
			local children = {}
			for _, child in candidate:GetChildren() do
				table.insert(children, child.Name .. ":" .. child.ClassName)
			end
			table.sort(children)
			table.insert(
				descriptions,
				candidate.ClassName .. "[" .. table.concat(children, ",") .. "]"
			)
		end
	end
	if #descriptions == 0 then
		return "none"
	end
	return table.concat(descriptions, " | ")
end

local function waitForRemoteSet(): any?
	local deadline = os.clock() + BOOT_TIMEOUT_SECONDS
	repeat
		for _, candidate in ReplicatedStorage:GetChildren() do
			if candidate.Name == Names.FOLDER and candidate:IsA("Folder") then
				local remotes = resolveRemoteSet(candidate)
				if remotes ~= nil then
					return remotes
				end
			end
		end
		task.wait(0.05)
	until os.clock() >= deadline

	failBoot(
		"서버 초기화 실패 · 완전한 Remote 세트를 찾지 못했습니다 · candidates="
			.. describeRemoteCandidates()
	)
	return nil
end

local remotes = waitForRemoteSet()
if remotes == nil then
	return
end

local clientModules = script.Parent.Client
local ProjectionReplica = require(clientModules.ProjectionReplica)
local CommandClient = require(clientModules.CommandClient)
local InputContextStack = require(clientModules.InputContextStack)
local SemanticInputRouter = require(clientModules.SemanticInputRouter)
local ClientRuntime = require(clientModules.ClientRuntime)
local UiPreferenceStore = require(clientModules.UiPreferenceStore)
local WorldTokenRuntime = require(clientModules.World.WorldTokenRuntime)

local replica = ProjectionReplica.new()
local command = CommandClient.new(remotes, replica)
local inputStack = InputContextStack.new()
local inputRouter = SemanticInputRouter.new(inputStack)
local worldTokens = WorldTokenRuntime.new(replica, command, inputStack)
local preferences = UiPreferenceStore.new()
local syncInFlight = false

local function fullResync()
	if syncInFlight then
		return
	end
	syncInFlight = true
	local succeeded, snapshot = pcall(function()
		return remotes.sync:InvokeServer()
	end)
	syncInFlight = false
	if succeeded and snapshot ~= nil then
		replica:apply(snapshot :: any, true)
	elseif not succeeded then
		warn("[RVTT ClientBoot] full resync failed", snapshot)
	end
end

command:start(function(message)
	if message.phase == "terminal" and message.result ~= nil and not message.result.ok then
		warn("[RVTT Command]", message.result.error.code)
		if
			message.result.error.code == "STALE_EPOCH"
			or message.result.error.code == "STALE_REVISION"
		then
			task.spawn(fullResync)
		end
	end
end)

replica.GapDetected:Connect(function()
	task.spawn(fullResync)
end)
remotes.projection.OnClientEvent:Connect(function(envelope)
	replica:apply(envelope :: any, false)
end)

inputRouter:start()
worldTokens:start()
ClientRuntime.set({
	Replica = replica,
	Command = command,
	Input = inputStack,
	WorldTokens = worldTokens,
	Preferences = preferences,
})

local loadingGui = playerGui:FindFirstChild("RVTT_Loading")
if loadingGui ~= nil then
	loadingGui:Destroy()
end

remotes.clientReady:FireServer()
task.delay(2, function()
	if replica.revision < 0 then
		task.spawn(fullResync)
	end
end)

print("[RVTT ClientBoot] runtime ready")
