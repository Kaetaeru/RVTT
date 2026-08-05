--!strict

export type RandomSource = { NextInteger: (RandomSource, number, number) -> number }

local Dice = {}

function Dice.rollDie(sides: number, randomSource: RandomSource?): number
	assert(sides >= 2 and sides % 1 == 0, "sides must be an integer >= 2")
	local source = randomSource or Random.new()
	return source:NextInteger(1, sides)
end

function Dice.rollD20(mode: string?, randomSource: RandomSource?): (number, { number })
	local first = Dice.rollDie(20, randomSource)
	if mode == "advantage" or mode == "disadvantage" then
		local second = Dice.rollDie(20, randomSource)
		if mode == "advantage" then
			return math.max(first, second), { first, second }
		end
		return math.min(first, second), { first, second }
	end
	return first, { first }
end

function Dice.rollFormula(
	count: number,
	sides: number,
	modifier: number,
	randomSource: RandomSource?
): (number, { number })
	assert(count >= 0 and count <= 100, "invalid dice count")
	local rolls = {}
	local total = modifier
	for _ = 1, count do
		local roll = Dice.rollDie(sides, randomSource)
		table.insert(rolls, roll)
		total += roll
	end
	return total, rolls
end

return table.freeze(Dice)
