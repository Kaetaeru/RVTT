# Slice 01 3D World Token Acceptance

This test-only client drives the production World Token runtime against the existing server-authoritative Scene, Movement, Projection, and Persistence path.

## Interaction

1. Build `slice01-acceptance.project.json` and publish it to the existing persistence test Place.
2. Press **Scene 준비·재개** if the saved scene is not already active.
3. Click the 3D miniature in Workspace.
4. Click the board floor to send `movement.commit`.
5. Confirm that the 3D model moves only after the server Projection revision advances.
6. Wait for the persistence save log, Stop, and Play again.
7. Press **복구 검증** and confirm the same Character, Scene, Position, 3D Token, and avatar suppression.

## Asset contract

The runtime checks `ReplicatedStorage.RVTT.TokenAssets` in this order:

1. `sourceCharacterId`
2. `sourceNpcId`
3. `actorId`
4. `Default`

A matching `Model` or `MeshPart` is cloned as a visual-only, anchored, non-Humanoid token. Executable descendants are removed. If no asset exists, a primitive 3D miniature is generated as a functional placeholder.

The acceptance panel and primitive fallback are not final visual design candidates.
