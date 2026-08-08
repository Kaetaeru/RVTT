--!strict

return function(harness: any)
	local StarterPlayer = game:GetService("StarterPlayer")
	local Client = StarterPlayer.StarterPlayerScripts.RVTT.Client
	local InputContextStack = require(Client.InputContextStack)
	local GameplayInputGuard = require(Client.GameplayInputGuard)
	local SemanticInputRouter = require(Client.SemanticInputRouter)
	local World = Client.World
	local WorldContextActionResolver = require(World.WorldContextActionResolver)
	local WorldTokenInputController = require(World.WorldTokenInputController)

	harness:equal(
		SemanticInputRouter.semanticActionFor(Enum.UserInputType.MouseButton1, Enum.KeyCode.A),
		"PrimaryPointer",
		"left mouse maps to the primary pointer semantic action"
	)
	harness:equal(
		SemanticInputRouter.semanticActionFor(Enum.UserInputType.MouseButton2, Enum.KeyCode.A),
		"ContextActionPointer",
		"right mouse maps to the context action semantic action"
	)
	harness:equal(
		SemanticInputRouter.semanticActionFor(Enum.UserInputType.MouseButton3, Enum.KeyCode.A),
		"CameraOrbitPointer",
		"middle mouse maps to the camera orbit semantic action"
	)
	harness:equal(
		SemanticInputRouter.semanticActionFor(Enum.UserInputType.Keyboard, Enum.KeyCode.Q),
		"Cancel",
		"Q maps to semantic cancel"
	)
	harness:equal(
		SemanticInputRouter.semanticActionFor(Enum.UserInputType.Keyboard, Enum.KeyCode.E),
		"Confirm",
		"E maps to semantic confirm"
	)
	harness:equal(
		SemanticInputRouter.semanticActionFor(Enum.UserInputType.Keyboard, Enum.KeyCode.Escape),
		nil,
		"Escape has no RVTT gameplay mapping"
	)
	harness:expect(GameplayInputGuard.allows(false, nil), "unprocessed gameplay input is allowed")
	harness:expect(
		not GameplayInputGuard.allows(true, nil),
		"Roblox-processed gameplay input is paused"
	)
	local focusedTextBox = Instance.new("TextBox")
	harness:expect(
		not GameplayInputGuard.allows(false, focusedTextBox),
		"gameplay input and camera are paused while a TextBox is focused"
	)
	focusedTextBox:Destroy()

	local stack = InputContextStack.new()
	local topCancelCount = 0
	local lowerCancelCount = 0
	stack:push("world", 10, {
		Cancel = function()
			lowerCancelCount += 1
			return true
		end,
	})
	stack:push("action-table", 20, {
		Cancel = function()
			topCancelCount += 1
			return true
		end,
	})
	harness:expect(stack:dispatch("Cancel", {}), "Q is consumed by the highest active context")
	harness:equal(topCancelCount, 1, "the highest context closes exactly one stage")
	harness:equal(lowerCancelCount, 0, "one Q does not cascade into the lower context")

	local replica: any = {
		revision = 27,
		payload = {
			domains = {
				session = {
					memberships = {
						["101"] = { role = "player" },
					},
				},
				scene = {
					actors = {
						hero = {
							controllerUserId = 101,
							sourceCharacterId = "hero-character",
							position = { x = 0, y = 0, z = 0 },
						},
						ally = { controllerUserId = 101 },
						enemy = { controllerUserId = 202, disposition = "hostile" },
						neutral = { controllerUserId = 303, disposition = "neutral" },
					},
					objects = {
						chest = {
							interactionIds = { "inspect", "open", "activate", "open" },
							state = { state = "closed" },
						},
						secret = { hidden = true, interactionIds = { "inspect" } },
					},
				},
				character = {
					characters = {
						["hero-character"] = {
							attacks = { ["attack.unarmed"] = true },
						},
					},
				},
				encounter = {
					active = {
						timeline = { { actorId = "enemy" }, { actorId = "hero" } },
						cursor = 1,
						opportunities = { action = false },
						movementRemaining = 2,
					},
				},
			},
		},
	}
	local resolver = WorldContextActionResolver.new(replica, 101)
	harness:expect(resolver:isControllable("hero"), "projected controller can select its actor")
	harness:expect(
		resolver:isControllable("ally"),
		"another projected controlled actor is selectable"
	)
	harness:expect(not resolver:isControllable("enemy"), "an unauthorized actor is not selectable")
	harness:equal(
		#resolver:resolve("hero", { kind = "actor", actorId = "ally" }),
		0,
		"a controllable ally is selection, not an implicit action target"
	)
	harness:equal(
		#resolver:resolve("enemy", { kind = "actor", actorId = "hero" }),
		0,
		"an unauthorized selected actor exposes no actions"
	)
	harness:equal(
		#resolver:resolve("hero", { kind = "actor", actorId = "missing" }),
		0,
		"an unprojected actor exposes no actions"
	)

	local blockedAttack = resolver:resolve("hero", { kind = "actor", actorId = "enemy" })
	harness:equal(#blockedAttack, 1, "an authorized unavailable attack remains visible")
	harness:expect(not blockedAttack[1].enabled, "an out-of-turn attack is disabled")
	harness:expect(
		type(blockedAttack[1].disabledReason) == "string" and blockedAttack[1].disabledReason ~= "",
		"a disabled action includes a safe reason"
	)
	harness:equal(
		blockedAttack[1].projectionRevision,
		27,
		"availability carries its projection revision"
	)
	harness:equal(
		replica.payload.domains.encounter.active.cursor,
		1,
		"availability resolution does not mutate encounter authority"
	)

	replica.payload.domains.encounter.active.cursor = 2
	replica.payload.domains.encounter.active.opportunities.action = true
	local enabledAttack = resolver:resolve("hero", { kind = "actor", actorId = "enemy" })
	harness:expect(enabledAttack[1].enabled, "current-turn attack availability is enabled")
	harness:expect(enabledAttack[1].isDefault, "a projected hostile attack is the explicit default")
	harness:equal(
		resolver:defaultAction(enabledAttack),
		enabledAttack[1],
		"left click resolves the enabled deterministic default"
	)
	local neutralAttack = resolver:resolve("hero", { kind = "actor", actorId = "neutral" })
	harness:expect(
		not neutralAttack[1].isDefault,
		"friendly or neutral targets have no implicit attack"
	)
	harness:equal(
		resolver:defaultAction(neutralAttack),
		nil,
		"left click does not invent a neutral-target default"
	)

	local movement = resolver:resolve("hero", {
		kind = "surface",
		position = Vector3.new(5, 0, 0),
	})
	harness:equal(#movement, 1, "unavailable movement remains in the action table")
	harness:expect(not movement[1].enabled, "movement beyond the projected remainder is disabled")
	harness:expect(movement[1].disabledReason ~= nil, "disabled movement explains its availability")

	local objectActions = resolver:resolve("hero", { kind = "object", objectId = "chest" })
	harness:equal(
		objectActions[1].id,
		"interact:open",
		"the deterministic object default sorts first"
	)
	harness:equal(
		objectActions[2].id,
		"interact:activate",
		"interaction actions have stable ordering"
	)
	harness:equal(objectActions[3].id, "interact:inspect", "information follows interactions")
	harness:equal(
		objectActions[4].id,
		"search",
		"search follows inspect in the information category"
	)
	harness:equal(
		#resolver:resolve("hero", { kind = "object", objectId = "secret" }),
		0,
		"a hidden object is omitted for a player viewer"
	)

	local selectedActorId: string? = "hero"
	local closeReason: string? = nil
	local menuOpen = true
	local renderer: any = {
		getSelectedActorId = function()
			return selectedActorId
		end,
		setSelected = function(_, actorId)
			selectedActorId = actorId
			return true
		end,
	}
	local menu: any = {
		isOpen = function()
			return menuOpen
		end,
		close = function(_, reason)
			closeReason = reason
			menuOpen = false
		end,
	}
	local controller = WorldTokenInputController.new(renderer, replica, {}, resolver, menu, stack)
	harness:expect(
		controller:handleSemantic("PrimaryPointer", {}),
		"the action table consumes left click"
	)
	harness:equal(selectedActorId, "hero", "blocked left click preserves actor selection")
	local rightClickCount = 0
	controller._rightClick = function()
		rightClickCount += 1
	end
	harness:expect(
		controller:handleSemantic("ContextActionPointer", {}),
		"right click is consumed while the action table is open"
	)
	harness:equal(rightClickCount, 1, "right click replaces the current action-table target")
	harness:expect(controller:handleSemantic("Cancel", {}), "Q closes the action table")
	harness:equal(closeReason, "context-cancel", "the close is attributed to semantic cancel")
	harness:equal(selectedActorId, "hero", "closing the table preserves actor selection")
	harness:expect(controller:handleSemantic("Cancel", {}), "the next Q clears actor selection")
	harness:equal(selectedActorId, nil, "one later Q removes only the next context stage")
	harness:expect(
		not controller:handleSemantic("Confirm", {}),
		"E has no side effect without a confirm-owning context"
	)
	harness:expect(
		not controller:handleSemantic("CameraOrbitPointer", {}),
		"middle drag remains available to the independent camera controller"
	)
	local submissions = 0
	controller.command = {
		submit = function()
			submissions += 1
			return "unexpected"
		end,
	}
	controller:executeAction(blockedAttack[1])
	harness:equal(submissions, 0, "disabled action invocation cannot submit a command")
end
