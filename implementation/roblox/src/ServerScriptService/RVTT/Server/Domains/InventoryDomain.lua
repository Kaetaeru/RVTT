--!strict
local Helpers=require(script.Parent.DomainHelpers);local Identity=require(game:GetService("ReplicatedStorage").RVTT.Shared.Core.Identity)
local Domain={id="inventory",slice=6}
function Domain.initialState()return{items={},locations={}}end
local function move(s,id,location)s.locations[id]=location;return{item=s.items[id],location=location}end
function Domain.register(registry)
	registry:register({commandType="inventory.create_item",domainId=Domain.id,authorize=function(c)return Helpers.requireRole(c,{"dm"})end,execute=function(_,s,p)local id=Identity.new("item");s.items[id]={id=id,definitionId=p.definitionId,quantity=math.max(1,math.floor(p.quantity or 1)),revision=1};return move(s,id,p.location or {kind="ground"})end})
	registry:register({commandType="inventory.move_item",domainId=Domain.id,validate=function(p)return Helpers.hasString(p,"itemId") and type(p.location)=="table"end,execute=function(_,s,p)assert(s.items[p.itemId],"item required");return move(s,p.itemId,p.location)end})
	registry:register({commandType="inventory.equip",domainId=Domain.id,validate=function(p)return Helpers.hasString(p,"itemId") and Helpers.hasString(p,"characterId") and Helpers.hasString(p,"slot")end,execute=function(_,s,p)assert(s.items[p.itemId],"item required");return move(s,p.itemId,{kind="equipped",characterId=p.characterId,slot=p.slot})end})
end
return table.freeze(Domain)
