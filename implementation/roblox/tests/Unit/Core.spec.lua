--!strict
return function(h)
	local Shared = game:GetService("ReplicatedStorage").RVTT.Shared
	local Result = require(Shared.Core.Result)
	local Identity = require(Shared.Core.Identity)
	local Ability = require(Shared.Rules.Ability)
	h:expect(Result.ok(1).ok, "Result.ok")
	h:expect(not Result.err("X", "x", false).ok, "Result.err")
	h:expect(Identity.is(Identity.new("actor"), "actor"), "identity")
	h:equal(Ability.modifier(10), 0, "ability modifier")
	h:equal(Ability.proficiencyBonus(5), 3, "proficiency")
end
