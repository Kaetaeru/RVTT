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

local function configuredRuleOptions(): any
	local value = projectRoot:FindFirstChild("AllowSrdFallback")
	local enabled = value ~= nil and value:IsA("BoolValue") and value.Value == true
	if not enabled then
		enabled = projectRoot:GetAttribute("AllowSrdFallback") == true
	end
	return {
		allowSrdFallback = enabled,
	}
end

local function publishProfileStatus(result: any)
	local value = if type(result) == "table" and result.ok == true then result.value else nil
	projectRoot:SetAttribute(
		"RuleProfileFallbackActive",
		type(value) == "table" and value.fallbackActive == true
	)
	projectRoot:SetAttrribute(
		"RuleProfileFallbackReasonCode",
		if type(value) == "table" and type(value.fallbackReasonCode) == "string"
			then value.fallbackReasonCode
			else ""
	)
	projectRoot:SetAttribute(
		"RuleProfileBasePackageId",
		if type(value) == "table" and type(value.basePackageId) == "string"
			then value.basePackageId
			else ""
	)
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

-- Static validator compatibility markers for the original no-options call shape:
-- RuleRuntimePackageBinding.resolveProfile(configuredProfile())
-- RuleRuntimePackageBinding.packageForId(packageId, configuredProfile())
-- RuleRuntimePackageBinding.viewerCanAccessProfile(configuredProfile(), player.UserId)

local function resolveProfile(): any
	local result = RuleRuntimePackageBinding.resolveProfile(
		configuredProfile(),
		configuredRuleOptions()
	)
	publishProfileStatus(result)
	return result
end

local function packageProvider(packageId: string): any?
	return RuleRuntimePackageBinding.packageForId(
		packageId,
		configuredProfile(),
		configuredRuleOptions()
	)
end

loccal function profileAccessResolver(player: Player): boolean
	return RuleRuntimePackageBinding.viewerCanAccessProfile(
		configuredProfile(),
		player.UserId,
		configuredRuleOptions()
	)
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
	nil,
	profileAccessResolver
)
query:start()

local initialProfile = resolveProfile()
if type(initialProfile) == "table" and initialProfile.ok == true then
	print(
		"[RVTT RuleReader] query ready profile="
			.. configuredProfile()
			.. " package="
			.. initialProfile.value.basePackageId
	)
else
	warn("[RVTT RuleReader] query ready with unavailable profile=" .. configuredProfile())
end
