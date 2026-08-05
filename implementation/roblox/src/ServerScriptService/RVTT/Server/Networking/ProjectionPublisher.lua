--!strict

local Players = game:GetService("Players")

local ProjectionPublisher = {}
ProjectionPublisher.__index = ProjectionPublisher

local function defaultViewerIdResolver(player: Player): number
	return player.UserId
end

function ProjectionPublisher.new(runtime, builder, remotes, roleResolver, viewerIdResolver)
	return setmetatable({
		runtime = runtime,
		builder = builder,
		remotes = remotes,
		roleResolver = roleResolver,
		viewerIdResolver = viewerIdResolver or defaultViewerIdResolver,
	}, ProjectionPublisher)
end

function ProjectionPublisher:publish(player: Player)
	local projection = self.builder:build(
		self.runtime:snapshot(),
		self.viewerIdResolver(player),
		self.roleResolver(player)
	)
	self.remotes.projection:FireClient(player, projection)
end

function ProjectionPublisher:publishAll()
	for _, player in Players:GetPlayers() do
		self:publish(player)
	end
end

function ProjectionPublisher:start()
	self.remotes.sync.OnServerInvoke = function(player)
		return self.builder:build(
			self.runtime:snapshot(),
			self.viewerIdResolver(player),
			self.roleResolver(player)
		)
	end
	Players.PlayerAdded:Connect(function(player)
		task.defer(function()
			self:publish(player)
		end)
	end)
end

return ProjectionPublisher
