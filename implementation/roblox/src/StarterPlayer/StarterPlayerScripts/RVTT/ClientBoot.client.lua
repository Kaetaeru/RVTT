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

local function waitForRemote(parent: Instance, name: string, className: string): Instance?
	local instance = parent:WaitForChild(name, BOOT_TIMEOUT_SECONDS)
	if instance == nil then
		failBoot("서버 초기화 실패 · 누락된 Remote: " .. name)
		return nil
	end
	if instance.ClassName ~= className then
		failBoot("서버 초기화 실패 · Remote 형식 오류: " .. name)
		return nil
	end
	return instance
end

local remoteFolder = ReplicatedStorage:WaitForChild(Names.FOLDER, BOOT_TIMEOUT_SECONDS)
if remoteFolder == nil then
	failBoot("서버 초기화 실패 · Remote 폴더를 찾지 못했습니다")
	return
end

local commandRemote = waitForRemote(remoteFolder, Names.COMMAND, "RemoteEvent")
local receiptRemote = waitForRemote(remoteFolder, Names.RECEIPT, "RemoteEvent")
local projectionRemote = waitForRemote(remoteFolder, Names.PROJECTION, "RemoteEvent")
local syncRemote = waitForRemote(remoteFolder, Names.SYNC, "RemoteFunction")
local clientReadyRemote = waitForRemote(remoteFolder, Names.CLIENT_READY, "RemoteEvent")
if
	commandRemote == nil
	or receiptRemote == nil
	or projectionRemote == nil
	or syncRemote == nil
	or clientReadyRemote == nil
then
	return
end

local remotes = {
	command = commandRemote :: RemoteEvent,
	receipt = receiptRemote :: RemoteEvent,
	projection = projectionRemote :: RemoteEvent,
	sync = syncRemote :: RemoteFunction,
	clientReady = clientReadyRemote :: RemoteEvent,
}

local clientModules = script.Parent.Client
local ProjectionReplica = require(clientModules.ProjectionReplica)
local CommandClient = require(clientModules.CommandClient)
local InputContextStack = require(clientModules.InputContextStack)
local SemanticInputRouter = require(clientModules.SemanticInputRouter)
local ClientRuntime = require(clientModules.ClientRuntime)

local replica = ProjectionReplica.new()
local command = CommandClient.new(remotes, replica)
local inputStack = InputContextStack.new()
local inputRouter = SemanticInputRouter.new(inputStack)
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
ClientRuntime.set({ Replica = replica, Command = command, Input = inputStack })

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
