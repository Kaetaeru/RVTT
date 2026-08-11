--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.RVTT.Shared.Core.Signal)
local ViewState = require(ReplicatedStorage.RVTT.Shared.UI.ViewState)

local Coordinator = {}
Coordinator.__index = Coordinator

function Coordinator.new(replica: any, requestFullSync: () -> ()): any
	local self: any = setmetatable({
		replica = replica,
		requestFullSync = requestFullSync,
		state = {
			state = if replica.revision >= 0 then ViewState.READY else ViewState.LOADING,
			message = nil,
			retryable = false,
		},
		Changed = Signal.new(),
		connections = {},
	}, Coordinator)

	table.insert(
		self.connections,
		replica.Changed:Connect(function()
			if self.state.state == ViewState.LOADING and replica.revision >= 0 then
				self:_set(ViewState.READY, nil, false)
			end
		end)
	)
	table.insert(
		self.connections,
		replica.RebuildStarted:Connect(function()
			self:_set(
				ViewState.REBUILDING,
				"최신 세션 상태를 다시 구성하고 있습니다",
				false
			)
		end)
	)
	table.insert(
		self.connections,
		replica.RebuildFinished:Connect(function()
			self:_set(ViewState.RECOVERED, "최신 세션 상태로 복구되었습니다", false)
			task.defer(function()
				if self.state.state == ViewState.RECOVERED then
					self:_set(ViewState.READY, nil, false)
				end
			end)
		end)
	)
	table.insert(
		self.connections,
		replica.RebuildFailed:Connect(function()
			self:_set(
				ViewState.NETWORK_ERROR,
				"세션 상태를 불러오지 못했습니다",
				true
			)
		end)
	)
	return self
end

function Coordinator._set(self: any, state: string, message: string?, retryable: boolean)
	self.state = { state = state, message = message, retryable = retryable }
	self.Changed:Fire(self:snapshot())
end

function Coordinator.snapshot(self: any): any
	return table.clone(self.state)
end

function Coordinator.retry(self: any): boolean
	if self.state.retryable ~= true then
		return false
	end
	self:_set(ViewState.RECOVERY, "세션 복구를 다시 시도합니다", false)
	self.requestFullSync()
	return true
end

function Coordinator.destroy(self: any)
	for _, connection in self.connections do
		connection:Disconnect()
	end
	table.clear(self.connections)
	self.Changed:Destroy()
end

return Coordinator
