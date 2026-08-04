--!strict
local Helpers=require(script.Parent.DomainHelpers); local Identity=require(game:GetService("ReplicatedStorage").RVTT.Shared.Core.Identity)
local Domain={id="character",slice=5}
function Domain.initialState() return {drafts={},characters={}} end
function Domain.register(registry)
	registry:register({commandType="character.create_draft",domainId=Domain.id,execute=function(c,s,p)local id=Identity.new("character");s.drafts[id]={id=id,ownerUserId=c.playerId,name=p.name or "",level=1,abilities=p.abilities or {},choices={},status="draft"};return s.drafts[id]end})
	registry:register({commandType="character.update_draft",domainId=Domain.id,validate=function(p)return Helpers.hasString(p,"characterId") and type(p.patch)=="table"end,execute=function(c,s,p)local d=s.drafts[p.characterId];assert(d and d.ownerUserId==c.playerId,"draft ownership required");for k,v in p.patch do d[k]=v end;return d end})
	registry:register({commandType="character.activate",domainId=Domain.id,validate=function(p)return Helpers.hasString(p,"characterId")end,execute=function(c,s,p)local d=s.drafts[p.characterId];assert(d and d.ownerUserId==c.playerId,"draft ownership required");assert(#d.name>0,"name required");d.status="active";s.characters[p.characterId]=d;s.drafts[p.characterId]=nil;return d end})
	registry:register({commandType="character.level_up",domainId=Domain.id,validate=function(p)return Helpers.hasString(p,"characterId") and type(p.level)=="number"end,execute=function(c,s,p)local d=s.characters[p.characterId];assert(d and d.ownerUserId==c.playerId,"character ownership required");assert(p.level==d.level+1 and p.level<=20,"invalid level");d.level=p.level;d.choices[p.level]=p.choices or {};return d end})
end
return table.freeze(Domain)
