--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DeepCopy = require(ReplicatedStorage.RVTT.Shared.Core.DeepCopy)
local Helpers = require(script.Parent.DomainHelpers)
local ActorProfileResolver = require(script.Parent.Parent.Rules.ActorProfileResolver)
local RuleResolver = require(script.Parent.Parent.Rules.RuleResolver)

local Domain = { id = "encounter", slice = 4 }

function Domain.initialState()
    return { active = nil, checkpoints = {}, history = {} }
end

local function currentActor(state)
    if state.active == nil then
        return nil
    end
    local entry = state.active.timeline[state.active.cursor]
    return entry and entry.actorId or nil
end

local function controllerOrDm(context, domains, actorId): boolean
    return context.role == "dm" or Helpers.controlsActor(context, domains, actorId)
end

local function checkpoint(state)
    table.insert(state.checkpoints, {
        round = state.active.round,
        cursor = state.active.cursor,
        snapshot = DeepCopy(state.active),
    })
end

local function resetTurnBudget(active, domains)
    local actorId = currentActor({ active = active })
    local profile = actorId and ActorProfileResolver.resolve(actorId, domains)
    active.movementRemaining = if profile ~= nil then profile.speedStuds else 0
    active.opportunities = { action = true, bonusAction = true, reaction = true, interaction = true }
end

function Domain.register(registry)
    registry:register({
        commandType = "encounter.start",
        domainId = Domain.id,
        authorize = function(context)
            return Helpers.requireRole(context, { "dm" })
        end,
        validate = function(payload)
            return type(payload.participants) == "table" and #payload.participants > 0
        end,
        execute = function(context, state, payload, domains)
            if state.active ~= nil then
                return Helpers.conflict("encounter is already active")
            end
            local timeline = {}
            for _, actorId in payload.participants do
                if type(actorId) ~= "string" or domains.scene.actors[actorId] == nil then
                    return Helpers.conflict("participant actor is missing")
                end
                local profile = ActorProfileResolver.resolve(actorId, domains)
                if profile == nil then
                    return Helpers.conflict("participant profile is missing")
                end
                local initiative = RuleResolver.rollInitiative(profile)
                table.insert(timeline, {
                    actorId = actorId,
                    initiative = initiative.total,
                    natural = initiative.natural,
                })
            end
            table.sort(timeline, function(left, right)
                if left.initiative == right.initiative then
                    return left.actorId < right.actorId
                end
                return left.initiative > right.initiative
            end)
            state.active = {
                id = payload.encounterId or ("encounter:" .. context.commandId),
                round = 1,
                cursor = 1,
                timeline = timeline,
                status = "active",
                objective = payload.objective,
            }
            resetTurnBudget(state.active, domains)
            checkpoint(state)
            return state.active
        end,
    })

    registry:register({
        commandType = "encounter.end_turn",
        domainId = Domain.id,
        authorize = function(context, domains)
            local active = domains.encounter.active
            if active == nil then
                return false
            end
            local actorId = currentActor(domains.encounter)
            return actorId ~= nil and controllerOrDm(context, domains, actorId)
        end,
        execute = function(_, state, _, domains)
            if state.active == nil then
                return Helpers.conflict("encounter required")
            end
            local completedActorId = currentActor(state)
            state.active.cursor += 1
            if state.active.cursor > #state.active.timeline then
                state.active.cursor = 1
                state.active.round += 1
            end
            resetTurnBudget(state.active, domains)
            table.insert(state.history, {
                kind = "turn_end",
                completedActorId = completedActorId,
                round = state.active.round,
                cursor = state.active.cursor,
            })
            checkpoint(state)
            return state.active
        end,
    })

    registry:register({
        commandType = "encounter.end",
        domainId = Domain.id,
        authorize = function(context)
            return Helpers.requireRole(context, { "dm" })
        end,
        execute = function(_, state, payload)
            if state.active == nil then
                return Helpers.conflict("encounter required")
            end
            state.active.status = "ended"
            state.active.reason = payload.reason or "dm"
            local ended = state.active
            state.active = nil
            return ended
        end,
    })

    registry:register({
        commandType = "encounter.rollback",
        domainId = Domain.id,
        refreshAuthorityEpoch = true,
        authorize = function(context)
            return Helpers.requireRole(context, { "dm" })
        end,
        validate = function(payload)
            return Helpers.hasNumber(payload, "checkpointIndex")
        end,
        execute = function(_, state, payload)
            local checkpointRecord = state.checkpoints[math.floor(payload.checkpointIndex)]
            if checkpointRecord == nil then
                return Helpers.notFound("encounter_checkpoint", tostring(payload.checkpointIndex))
            end
            state.active = DeepCopy(checkpointRecord.snapshot)
            table.insert(state.history, {
                kind = "rollback",
                checkpointIndex = math.floor(payload.checkpointIndex),
            })
            return state.active
        end,
    })
end

return table.freeze(Domain)
