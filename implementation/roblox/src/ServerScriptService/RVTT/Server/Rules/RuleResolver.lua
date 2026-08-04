--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ability = require(ReplicatedStorage.RVTT.Shared.Rules.Ability)
local Dice = require(ReplicatedStorage.RVTT.Shared.Rules.Dice)

local RuleResolver = {}

function RuleResolver.abilityModifier(profile, ability: string): number
    local score = profile.abilities[ability] or 10
    return Ability.modifier(score)
end

function RuleResolver.rollCheck(profile, ability: string, proficient: boolean, difficultyClass: number, mode: string?)
    local natural, rolls = Dice.rollD20(mode)
    local modifier = RuleResolver.abilityModifier(profile, ability)
    if proficient then
        modifier += profile.proficiencyBonus
    end
    local total = natural + modifier
    return {
        natural = natural,
        rolls = rolls,
        modifier = modifier,
        total = total,
        difficultyClass = difficultyClass,
        success = total >= difficultyClass,
    }
end

function RuleResolver.rollInitiative(profile)
    return RuleResolver.rollCheck(profile, "dexterity", false, 0, nil)
end

function RuleResolver.rollAttack(profile, attackProfile, armorClass: number, mode: string?)
    local natural, rolls = Dice.rollD20(mode)
    local attackModifier = RuleResolver.abilityModifier(profile, attackProfile.ability or "strength")
    if attackProfile.proficient == true then
        attackModifier += profile.proficiencyBonus
    end
    attackModifier += attackProfile.attackModifier or 0
    local total = natural + attackModifier
    local hit = natural == 20 or (natural ~= 1 and total >= armorClass)
    local critical = natural == 20
    local damageTotal = 0
    local damageRolls = {}
    if hit then
        local count = math.clamp(math.floor(attackProfile.count or 1), 0, 20)
        if critical then
            count *= 2
        end
        damageTotal, damageRolls = Dice.rollFormula(
            count,
            math.clamp(math.floor(attackProfile.sides or 4), 2, 100),
            RuleResolver.abilityModifier(profile, attackProfile.ability or "strength") + (attackProfile.damageModifier or 0)
        )
        damageTotal = math.max(0, damageTotal)
    end
    return {
        natural = natural,
        rolls = rolls,
        modifier = attackModifier,
        total = total,
        armorClass = armorClass,
        hit = hit,
        critical = critical,
        damage = damageTotal,
        damageRolls = damageRolls,
    }
end

return table.freeze(RuleResolver)
