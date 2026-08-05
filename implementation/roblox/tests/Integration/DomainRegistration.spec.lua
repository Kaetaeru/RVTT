--!strict

return function(harness)
	local Server = game:GetService("ServerScriptService").RVTT.Server
	local Registry = require(Server.Runtime.CommandRegistry).new()
	local domains = require(Server.Bootstrap.ServiceGraph).domainModules()
	for _, domain in domains do
		domain.register(Registry)
	end
	harness:expect(#domains >= 18, "all slice and slice-01 support domains registered")
	harness:expect(#Registry:list() >= 35, "command coverage")
	for commandType, descriptor in Registry:all() do
		harness:expect(
			type(descriptor.authorize) == "function",
			commandType .. " has explicit authorization"
		)
	end
end
