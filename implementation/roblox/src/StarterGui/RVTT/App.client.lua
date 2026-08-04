--!strict
local Players=game:GetService("Players");local Tokens=require(game:GetService("ReplicatedStorage").RVTT.Shared.UI.DesignTokens);local Components=script.UI.Components
local gui=Instance.new("ScreenGui");gui.Name="RVTT_App";gui.ResetOnSpawn=false;gui.IgnoreGuiInset=false;gui.DisplayOrder=Tokens.Layer.Hud;gui.Parent=Players.LocalPlayer:WaitForChild("PlayerGui")
local banner=require(Components.StateBanner)();banner.Parent=gui;local prompt=require(Components.ActionPrompt)();prompt.Parent=gui
local function bindClient()local client=_G.RVTTClient;if client==nil then task.wait(.1);return bindClient()end;client.Replica.Changed:Connect(function(payload,envelope)local session=payload.domains and payload.domains.session;local phase=session and session.phase or"loading";banner.Text=string.format("RVTT · %s · revision %d",phase,envelope.revision)end);client.Input:push("base_hud",10,{Cancel=function()return false end,Confirm=function()return false end})end
task.spawn(bindClient)
