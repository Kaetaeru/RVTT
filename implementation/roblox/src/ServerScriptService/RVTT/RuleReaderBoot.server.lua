--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

if ReplicatedStorage:FindFirstChild("RVTT_TestMode") ~= nil then
	return
end

local Names = require(ReplicatedStorage.RVTT.Shared.Protocol.RemoteNames)
local Server = script.Parent.Server
local RuleReaderQuery = require(Server.Networking.RuleReaderQuery)
local RuleReaderService = require(Server.Rules.RuleReaderService)
local Content = ServerStorage.RVTT.Content
local RulePackageResolver = require(Content.RulePackageResolver)
local CoreRulesPackage = require(Content.Packs["rvtt.core.rules"].RuleReaderPackage)

local projectRoot = ServerStorage:WaitForChild("RVTT")

local function configuredProfile(): string
	local value = projectRoot:FindFirstChild("RuleContentProfile")
	if value ~= nil and value:IsA("StringValue") and value.Value ~= "" then
		return value.Value
	end
	local attribute = projectRoot:GetAttribute("RuleContentProfile")
	if type(attribute) == "string" and attribute ~= "" then
		return attribute
	end
	return "public"
end

local function roleResolver(player: Player): string
	if game.PrivateServerOwnerId ~= 0 and player.UserId == game.PrivateServerOwnerId then
		return "dm"
	end
	local role = player:GetAttribute("RVTT_Role")
	if role == "dm" or role == "player" then
		return role
	end
	return "observer"
end

local function resolveProfile(): any
	-- Private profiles deliberately fail closed until the private importer supplies
	-- verified readiness evidence. Public/release/artifact resolve without it.
	return RulePackageResolver.resolve(configuredProfile(), {})
end

local function packageProvider(packageId: string): any?
	if packageId == CoreRulesPackage.packageId then
		return CoreRulesPackage
	end
	return nil
end

local remoteFolder = ReplicatedStorage:WaitForChild(Names.FOLDER, 15)
if remoteFolder == nil or not remoteFolder:IsA("Folder") then
	warn("[RVTT RuleReader] canonical remote folder unavailable")
	return
end

local remote: RemoteFunction? = nil
for _, child in remoteFolder:GetChildren() do
	if child.Name == Names.RULE_READER_QUERY then
		if remote == nil and child:IsA("RemoteFunction") then
			remote = child
		else
			child:Destroy()
		end
	end
end
if remote == nil then
	local created = Instance.new("RemoteFunction")
	created.Name = Names.RULE_READER_QUERY
	created.Parent = remoteFolder
	remote = created
end

local query = RuleReaderQuery.new(
	remote :: RemoteFunction,
	roleResolver,
	RuleReaderService,
	resolveProfile,
	packageProvider,
	nil
)
query:start()

Players.PlayerRemoving:Connect(function(_player)
	-- Query state is request-local; this connection intentionally documents that
	-- no per-player rule body cache survives a session departure on the server.
end)

print("[RVTT RuleReader] query ready profile=" .. configuredProfile())
