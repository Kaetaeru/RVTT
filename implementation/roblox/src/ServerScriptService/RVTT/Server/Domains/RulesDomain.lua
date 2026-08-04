--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Identity = require(ReplicatedStorage.RVTT.Shared.Core.Identity)
local Result = require(ReplicatedStorage.RVTT.Shared.Core.Result)
local Helpers = require(script.Parent.DomainHelpers)
local ActorProfileResolver = require(script.Parent.Parent.Rules.ActorProfileResolver)
local RuleResolver = require(script.Parent.Parent.Rules.RuleResolver)

local Domain = { id = "rules", slice = 2 }

function Domain.initialState()
    return {
        rollRecords = {},
        actorStates = {},
        challenges = {},
        conditions = {},
    }
end

local function ensureActorState(state, actorId: string, domains)
    local existing = state.actorStates[actorId]
    if existing ~= nil then
        return existing
    end
    local profile = ActorProfileResolver.resolve(actorId, domains)
    if profile == nil then
        return nil
    end
    local actorState = {
        currentHitPoints = profile.maximumHitPoints,
        maximumHitPoints = profile.maximumHitPoints,
        temporaryHitPoints = 0,
        profileRevision = 1,
    }
    state.actorStates[actorId] = actorState
    return actorState
end

local function record(state, context, kind: string, data)
    local id = Identity.new("roll")
    state.rollRecords[id] = {
        id = id,
        commandId = context.commandId,
        kind = kind,
        data = data,
        createdAt = os.time(),
        audience = "public",
    }
    return state.rollRecords[id]
end

function Domain.register(registry)
    registry:register({
        commandType = "rules.create_challenge",
        domainId = Domain.id,
        authorize = function(context)
            return Helpers.requireRole(context, { "dm" })
        end,
        validate = function(payload)
            return Helpers.hasString(payload, "ability")
                and Helpers.hasNumber(payload, "difficultyClass")
                and payload.difficultyClass >= 1
                and payload.difficultyClass <= 40
        end,
        execute = function(_, state, payload)
            local challengeId = Identity.new("challenge")
            state.challenges[challengeId] = {
                id = challengeId,
                ability = payload.ability,
                proficient = payload.proficient == true,
                difficultyClass = math.floor(payload.difficultyClass),
                status = "open",
                labelKey = payload.labelKey,
            }
            return { challengeId = challengeId }
        end,
    })

    registry:register({
        commandType = "rules.ability_check",
        domainId = Domain.id,
        authorize = function(context, domains, payload)
            return Helpers.controlsActor(context, domains, payload.actorId)
        end,
        validate = function(payload)
            return Helpers.hasString(payload, "actorId") and Helpers.hasString(payload, "challengeId")
        end,
        execute = function(context, state, payload, domains)
            local challenge = state.challenges[payload.challengeId]
            if challenge == nil or challenge.status ~= "open" then
                return Helpers.notFound("challenge", payload.challengeId)
            end
            local profile = ActorProfileResolver.resolve(payload.actorId, domains)
            if profile == nil then
                return Helpers.notFound("actor", payload.actorId)
            end
            local resolution = RuleResolver.rollCheck(
                profile,
                challenge.ability,
                challenge.proficient,
                challenge.difficultyClass,
                nil
            )
            resolution.actorId = payload.actorId
            resolution.challengeId = payload.challengeId
            return record(state, context, "ability_check", resolution)
        end,
    })

    registry:register({
        commandType = "rules.saving_throw",
        domainId = Domain.id,
        authorize = function(context, domains, payload)
            return Helpers.controlsActor(context, domains, payload.actorId)
        end,
        validate = function(payload)
            return Helpers.hasString(payload, "actorId") and Helpers.hasString(payload, "challengeId")
        end,
        execute = function(context, state, payload, domains)
            local challenge = state.challenges[payload.challengeId]
            if challenge == nil or challenge.status ~= "open" then
                return Helpers.notFound("challenge", payload.challengeId)
            end
            local profile = ActorProfileResolver.resolve(payload.actorId, domains)
            if profile == nil then
                return Helpers.notFound("actor", payload.actorId)
            end
            local resolution = RuleResolver.rollCheck(
                profile,
                challenge.ability,
                true,
                challenge.difficultyClass,
                nil
            )
            resolution.actorId = payload.actorId
            resolution.challengeId = payload.challengeId
            return record(state, context, "saving_throw", resolution)
        end,
    })

    registry:register({
        commandType = "rules.attack",
        domainId = Domain.id,
        authorize = function(context, domains, payload)
            return Helpers.controlsActor(context, domains, payload.attackerId)
        end,
        validate = function(payload)
            return Helpers.hasString(payload, "attackerId")
                and Helpers.hasString(payload, "targetId")
                and Helpers.hasString(payload, "profileId")
        end,
        execute = function(context, state, payload, domains)
            local attackerProfile = ActorProfileResolver.resolve(payload.attackerId, domains)
            local targetProfile = ActorProfileResolver.resolve(payload.targetId, domains)
            if attackerProfile == nil then
                return Helpers.notFound("actor", payload.attackerId)
            end
            if targetProfile == nil then
                return Helpers.notFound("actor", payload.targetId)
            end
            local attackProfile = attackerProfile.attacks[payload.profileId]
            if attackProfile == nil then
                return Helpers.notFound("attack_profile", payload.profileId)
            end
            local encounter = domains.encounter.active
            if encounter ~= nil then
                local currentEntry = encounter.timeline[encounter.cursor]
                if currentEntry == nil or currentEntry.actorId ~= payload.attackerId then
                    return Helpers.conflict("attacker does not own the active turn")
                end
                if encounter.opportunities.action ~= true then
                    return Helpers.conflict("action opportunity is unavailable")
                end
            end

            local targetState = ensureActorState(state, payload.targetId, domains)
            if targetState == nil then
                return Helpers.notFound("actor_state", payload.targetId)
            end
            ensureActorState(state, payload.attackerId, domains)

            local resolution = RuleResolver.rollAttack(attackerProfile, attackProfile, targetProfile.armorClass, nil)
            if resolution.hit then
                local absorbed = math.min(targetState.temporaryHitPoints, resolution.damage)
                targetState.temporaryHitPoints -= absorbed
                targetState.currentHitPoints = math.max(
                    0,
                    targetState.currentHitPoints - (resolution.damage - absorbed)
                )
                resolution.absorbedByTemporaryHitPoints = absorbed
                resolution.targetHitPoints = targetState.currentHitPoints
            end
            if encounter ~= nil then
                encounter.opportunities.action = false
            end
            resolution.attackerId = payload.attackerId
            resolution.targetId = payload.targetId
            resolution.profileId = payload.profileId
            return record(state, context, "attack", resolution)
        end,
    })

    registry:register({
        commandType = "rules.set_actor_state",
        domainId = Domain.id,
        authorize = function(context)
            return Helpers.requireRole(context, { "dm" })
        end,
        validate = function(payload)
            return Helpers.hasString(payload, "actorId")
                and Helpers.hasNumber(payload, "currentHitPoints")
                and Helpers.hasNumber(payload, "maximumHitPoints")
        end,
        execute = function(_, state, payload, domains)
            if ActorProfileResolver.resolve(payload.actorId, domains) == nil then
                return Helpers.notFound("actor", payload.actorId)
            end
            local maximum = math.max(1, math.floor(payload.maximumHitPoints))
            state.actorStates[payload.actorId] = {
                currentHitPoints = math.clamp(math.floor(payload.currentHitPoints), 0, maximum),
                maximumHitPoints = maximum,
                temporaryHitPoints = math.max(0, math.floor(payload.temporaryHitPoints or 0)),
                profileRevision = 1,
            }
            return state.actorStates[payload.actorId]
        end,
    })
end

return table.freeze(Domain)
