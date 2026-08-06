--!strict

local Ability = {}

function Ability.modifier(score: number): number
	return math.floor((score - 10) / 2)
end

function Ability.proficiencyBonus(level: number): number
	assert(level >= 1 and level <= 20, "level must be 1..20")
	return 2 + math.floor((level - 1) / 4)
end

function Ability.test(total: number, difficultyClass: number): boolean
	return total >= difficultyClass
end

return table.freeze(Ability)
