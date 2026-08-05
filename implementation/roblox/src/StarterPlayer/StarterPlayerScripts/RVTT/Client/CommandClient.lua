--!strict

local HttpService = game:GetService("HttpService")
local Version = require(game:GetService("ReplicatedStorage").RVTT.Shared.Core.Version)

export type ReceiptCallback = (message: any) -> ()
export type CommandClient = {
	remotes: any,
	replica: any,
	pending: { [string]: any },
	receiptCallback: ReceiptCallback?,
	start: (self: CommandClient, callback: ReceiptCallback?) -> (),
	submit: (self: CommandClient, commandType: string, payload: { [string]: unknown }) -> string,
}

local CommandClient = {}
CommandClient.__index = CommandClient

function CommandClient.new(remotes: any, replica: any): CommandClient
	return setmetatable({
		remotes = remotes,
		replica = replica,
		pending = {},
		receiptCallback = nil,
	}, CommandClient) :: any
end

function CommandClient.start(self: CommandClient, callback: ReceiptCallback?)
	self.receiptCallback = callback
	self.remotes.receipt.OnClientEvent:Connect(function(message)
		if type(message) ~= "table" then
			return
		end
		local commandId = message.commandId
		if commandId ~= nil and message.phase == "terminal" then
			self.pending[commandId] = nil
		end
		if callback ~= nil then
			callback(message)
		end
	end)
end

function CommandClient.submit(
	self: CommandClient,
	commandType: string,
	payload: { [string]: unknown }
): string
	local commandId = HttpService:GenerateGUID(false)
	self.pending[commandId] = {
		commandType = commandType,
		submittedAt = os.clock(),
		expectedRevision = if self.replica.revision >= 0 then self.replica.revision else nil,
	}
	self.remotes.command:FireServer({
		protocolVersion = Version.PROTOCOL,
		commandId = commandId,
		commandType = commandType,
		correlationId = commandId,
		authorityEpoch = self.replica.epoch,
		expectedRevision = if self.replica.revision >= 0 then self.replica.revision else nil,
		payload = payload,
	})
	return commandId
end

return CommandClient
