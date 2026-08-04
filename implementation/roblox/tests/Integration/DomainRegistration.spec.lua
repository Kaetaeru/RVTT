--!strict
return function(h)
	local Server=game:GetService("ServerScriptService").RVTT.Server;local Registry=require(Server.Runtime.CommandRegistry).new();local domains=require(Server.Bootstrap.ServiceGraph).domainModules();for _,domain in domains do domain.register(Registry)end
	h:expect(#domains>=16,"all slice domains registered");h:expect(#Registry:list()>=30,"command coverage")
end
