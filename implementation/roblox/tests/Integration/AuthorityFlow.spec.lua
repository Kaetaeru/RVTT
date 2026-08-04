--!strict
return function(h)
	local Server=game:GetService("ServerScriptService").RVTT.Server;local Registry=require(Server.Runtime.CommandRegistry).new();local Diagnostics=require(Server.Runtime.Diagnostics).new();local Outbox=require(Server.Runtime.EventOutbox).new();local Journal=require(Server.Persistence.SnapshotJournal).new(20);local Transactions=require(Server.Runtime.TransactionCoordinator).new(Diagnostics);local Runtime=require(Server.Runtime.AuthorityRuntime).new(Registry,Transactions,Outbox,Diagnostics,Journal)
	for _,domain in require(Server.Bootstrap.ServiceGraph).domainModules() do Runtime:installDomain(domain)end
	local context={player=nil,playerId=101,role="dm",commandId="c1",correlationId="c1"};local result=Runtime:execute(context,{commandId="c1",commandType="session.join",correlationId="c1",payload={displayName="Tester"}});h:expect(result.ok,"session join commits");h:equal(Runtime:snapshot().revision,1,"revision increments")
end
