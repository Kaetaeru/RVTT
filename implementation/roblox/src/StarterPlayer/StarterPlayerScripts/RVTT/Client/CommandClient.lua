--!strict
local HttpService=game:GetService("HttpService");local Version=require(game:GetService("ReplicatedStorage").RVTT.Shared.Core.Version)
local CommandClient={};CommandClient.__index=CommandClient
function CommandClient.new(remotes,replica)return setmetatable({remotes=remotes,replica=replica,receipts={},Receipt=nil},CommandClient)end
function CommandClient:start(callback)self.Receipt=callback;self.remotes.receipt.OnClientEvent:Connect(function(result)if callback then callback(result)end end)end
function CommandClient:submit(commandType,payload)
	local id=HttpService:GenerateGUID(false);self.remotes.command:FireServer({protocolVersion=Version.PROTOCOL,commandId=id,commandType=commandType,correlationId=id,authorityEpoch=self.replica.epoch,expectedRevision=self.replica.revision>=0 and self.replica.revision or nil,payload=payload});return id
end
return CommandClient
