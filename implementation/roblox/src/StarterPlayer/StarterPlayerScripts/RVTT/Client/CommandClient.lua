--!strict

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Result = require(ReplicatedStorage.RVTT.Shared.Core.Result)
local Signal = require(ReplicatedStorage.RVTT.Shared.Core.Signal)
local Version = require(ReplicatedStorage.RVTT.Shared.Core.Version)

local RETRY_INTERVAL_SECONDS = 1.5
local COMMAND_TIMEOUT_SECONDS = 8
local MAX_ATTEMPTS = 3
local SWEEP_INTERVAL_SECONDS = 0.25

export type ReceiptCallback = (message: any) -> ()
export type CommandClient = {
	remotes: any,
	replica: any,
	pending: { [string]: any },
	receiptCallback: ReceiptCallback?,
	clock: () -> number,
	running: boolean,
	receiptConnection: any?,
	Received: any,
	start: (self: CommandClient, callback: ReceiptCallback?, automaticSweep: boolean?) -> (),
	stop: (self: CommandClient) -> (),
	tick: (self: CommandClient, now: number?) -> (),
	submit: (self: CommandClient, commandType: string, payload: { [string]: unknown }) -> string,
}

local CommandClient = {}
CommandClient.__index = CommandClient
CommandClient.RETRY_INTERVAL_SECONDS = RETRY_INTERVAL_SECONDS
CommandClient.COMMAND_TIMEOUT_SECONDS = COMMAND_TIMEOUT_SECONDS
CommandClient.MAX_ATTEMPTS = MAX_ATTEMPTS

local function notify(self: CommandClient, message: any)
	self.Received:Fire(message)
	local callback = self.receiptCallback
	if callback ~= nil then
		callback(message)
	end
end

local function sendRecord(self: CommandClient, record: any)
	record.attempts += 1
	record.lastSentAt = self.clock()
	self.remotes.command:FireServer(record.envelope)
end

function CommandClient.new(
	remotes: any,
	replica: any,
	clockOverride: (() -> number)?
): CommandClient
	return setmetatable({
		remotes = remotes,
		replica = replica,
		pending = {},
		receiptCallback = nil,
		clock = clockOverride or os.clock,
		running = false,
		receiptConnection = nil,
		Received = Signal.new(),
	}, CommandClient) :: any
end

function CommandClient.start(
	self: CommandClient,
	callback: ReceiptCallback?,
	automaticSweep: boolean?
)
	if self.receiptConnection ~= nil then
		return
	end
	self.receiptCallback = callback
	self.receiptConnection = self.remotes.receipt.OnClientEvent:Connect(function(message)
		if type(message) ~= "table" then
			return
		end
		local commandId = message.commandId
		if commandId ~= nil and message.phase == "terminal" then
			self.pending[commandId] = nil
		end
		notify(self, message)
	end)

	if automaticSweep == false then
		return
	end
	self.running = true
	task.spawn(function()
		while self.running do
			task.wait(SWEEP_INTERVAL_SECONDS)
			self:tick()
		end
	end)
end

function CommandClient.stop(self: CommandClient)
	self.running = false
	local connection = self.receiptConnection
	self.receiptConnection = nil
	if connection ~= nil then
		connection:Disconnect()
	end
end

function CommandClient.tick(self: CommandClient, now: number?)
	local currentTime = now or self.clock()
	for commandId, record in self.pending do
		local age = currentTime - record.submittedAt
		if age >= COMMAND_TIMEOUT_SECONDS then
			self.pending[commandId] = nil
			notify(self, {
				commandId = commandId,
				phase = "terminal",
				result = Result.err(
					"CLIENT_TIMEOUT",
					"error.network.command_timeout",
					true,
					{ attempts = record.attempts }
				),
			})
		elseif
			currentTime - record.lastSentAt >= RETRY_INTERVAL_SECONDS
			and record.attempts < MAX_ATTEMPTS
		then
			sendRecord(self, record)
			notify(self, {
				commandId = commandId,
				phase = "retrying",
				result = Result.ok({ attempt = record.attempts }),
			})
		end
	end
end

function CommandClient.submit(
	self: CommandClient,
	commandType: string,
	payload: { [string]: unknown }
): string
	local commandId = HttpService:GenerateGUID(false)
	local envelope = {
		protocolVersion = Version.PROTOCOL,
		commandId = commandId,
		commandType = commandType,
		correlationId = commandId,
		authorityEpoch = self.replica.epoch,
		expectedRevision = if self.replica.revision >= 0 then self.replica.revision else nil,
		payload = payload,
	}
	local now = self.clock()
	local record = {
		commandType = commandType,
		submittedAt = now,
		lastSentAt = now,
		attempts = 0,
		expectedRevision = envelope.expectedRevision,
		envelope = envelope,
	}
	self.pending[commandId] = record
	sendRecord(self, record)
	return commandId
end

return CommandClient
