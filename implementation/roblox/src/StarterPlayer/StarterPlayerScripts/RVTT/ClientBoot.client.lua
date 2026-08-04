--!strict
local ReplicatedStorage=game:GetService("ReplicatedStorage");local Names=require(ReplicatedStorage.RVTT.Shared.Protocol.RemoteNames)
local folder=ReplicatedStorage:WaitForChild(Names.FOLDER);local remotes={command=folder:WaitForChild(Names.COMMAND),receipt=folder:WaitForChild(Names.RECEIPT),projection=folder:WaitForChild(Names.PROJECTION),sync=folder:WaitForChild(Names.SYNC),clientReady=folder:WaitForChild(Names.CLIENT_READY)}
local Client=script.Client;local Replica=require(Client.ProjectionReplica).new();local Command=require(Client.CommandClient).new(remotes,Replica);local Stack=require(Client.InputContextStack).new();local Router=require(Client.SemanticInputRouter).new(Stack)
Command:start(function(result)if not result.ok then warn("[RVTT Command]",result.error.code)end end);remotes.projection.OnClientEvent:Connect(function(envelope)Replica:apply(envelope)end)
local ok,snapshot=pcall(function()return remotes.sync:InvokeServer()end);if ok and snapshot then Replica:apply(snapshot)end;Router:start();remotes.clientReady:FireServer();_G.RVTTClient={Replica=Replica,Command=Command,Input=Stack}
local loading=_G.RVTTLoadingGui;if typeof(loading)=="Instance"then loading:Destroy()end
