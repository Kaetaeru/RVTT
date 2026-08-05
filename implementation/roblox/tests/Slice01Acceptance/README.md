# Slice 01 Studio Acceptance Harness

This test-only harness validates the production authority, projection, networking, and persistence path without extending the placeholder production UI.

## Project

Build `slice01-acceptance.project.json` and publish it to the existing Studio persistence test Place.

The project enables two test-only flags:

- `ServerStorage.RVTT.EnableStudioPersistence=true`
- `ServerStorage.RVTT.Slice01AcceptanceMode=true`

The second flag grants the single Studio tester the DM role only in this acceptance build. It is absent from `default.project.json`.

## Flow

1. Join the session and refresh the DM membership.
2. Create and activate a test character.
3. Select the character.
4. Mark ready.
5. Start the acceptance scene.
6. Enter the scene and project the actor.
7. Select the projected token in the scene canvas.
8. Commit a server-authoritative move.
9. Wait for the persistence save log.
10. Stop and Play again.
11. Verify character, scene, actor position, connection, avatar suppression, and Accent recovery.

The screen is an acceptance instrument, not a production visual design candidate. Production UI styling remains deferred to the separate UI Visual Redesign Gate.
