--!strict
local Helpers=require(script.Parent.DomainHelpers);local Domain={id="ui_preferences",slice=8}
local allowed={uiScale=true,reducedMotion=true,flashLimit=true,cameraShake=true,highContrast=true,layout=true}
function Domain.initialState()return{byUser={}}end
function Domain.register(registry)
	registry:register({commandType="ui.set_preference",domainId=Domain.id,validate=function(p)return Helpers.hasString(p,"key") and allowed[p.key]==true end,execute=function(c,s,p)local key=tostring(c.playerId);s.byUser[key]=s.byUser[key]or{};s.byUser[key][p.key]=p.value;return s.byUser[key]end})
end
return table.freeze(Domain)
