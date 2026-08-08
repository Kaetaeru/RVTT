--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

if ReplicatedStorage:FindFirstChild("RVTT_TestMode") ~= nil then
	return
end

local Names = require(ReplicatedStorage.RVTT.Shared.Protocol.RemoteNames)
local Server = script.Parent.Server
local RuleReaderQuery = require(Server.Networking.RuleReaderQuery)
local RuleReaderService = require(Server.Rules.RuleReaderService)
local Content = ServerStorage.RVTT.Content
local RuleRuntimePackageBinding = require(Content.RuleRuntimePackageBinding)

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
	-- Local Studio development follows the private-integrated default. The runtime
	-- binding stays fail closed until the private importer injects verified
	-- Readiness + RuleReaderPackage modules into ServerStorage.RVTTPrivateRuleContent.
	return if RunService:IsStudio() then "development" else "public"
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
	return RuleRuntimePackageBinding.resolveProfile(configuredProfile())
end

local function packageProvider(packageId: string): any?
	return RuleRuntimePackageBinding.packageForId(packageId, configuredProfile())
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

print("[RVTT RuleReader] query ready profile=" .. configuredProfile())
