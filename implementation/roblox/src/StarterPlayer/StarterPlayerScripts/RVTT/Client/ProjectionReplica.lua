--!strict
local Signal=require(game:GetService("ReplicatedStorage").RVTT.Shared.Core.Signal);local Contract=require(game:GetService("ReplicatedStorage").RVTT.Shared.Protocol.ProjectionContract)
local Replica={};Replica.__index=Replica
function Replica.new()return setmetatable({epoch=nil,revision=-1,sequence=0,payload={},Changed=Signal.new()},Replica)end
function Replica:apply(envelope)
	if not Contract.isNewer(self.epoch,self.revision,envelope)then return false end
	if self.epoch==envelope.authorityEpoch and envelope.projectionSequence<self.sequence then return false end
	self.epoch=envelope.authorityEpoch;self.revision=envelope.revision;self.sequence=envelope.projectionSequence;self.payload=envelope.payload;self.Changed:Fire(self.payload,envelope);return true
end
return Replica
