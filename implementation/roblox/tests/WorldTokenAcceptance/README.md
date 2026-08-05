# Slice 01 World Interaction Batch Acceptance

This test-only client validates the production World Token runtime against the server-authoritative Scene, Movement, Projection, and Persistence path in one Studio session.

## Batch scope

- automatic Session, Character, Ready, Scene, and Actor preparation
- 3D Token projection
- world Raycast picking
- screen-space projected-bounds picking fallback
- selection Highlight
- destination marker
- `movement.commit` command Receipt and revision diagnostics
- Projection-driven 3D movement
- camera Frame, Pan, and Zoom
- Roblox avatar suppression
- loaded Character, Scene, Position, and Token restore
- structured Final Batch Summary

## One-command launch

Paste this single command into Windows PowerShell or Windows Terminal from any directory:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/Kaetaeru/RVTT/planning/rvtt-remake/implementation/roblox/tooling/run-studio-acceptance-batch.ps1')"
```

No arguments are required. The bootstrap reads the machine-readable `acceptance-batch.json`, downloads the verified source into an isolated cache, installs the pinned Rojo build when necessary, validates, builds, closes any existing Studio process, and opens the generated Place.

The bootstrap does not require the current directory to be a repository and does not modify a local Dirty Worktree. Git is not required. Python is optional because the bootstrap contains a fallback validator. After the first successful online run, the same verified Head can be rebuilt from the Offline cache.

Unavoidable prerequisites are Windows and Roblox Studio. The first uncached run also requires internet access.

## Interaction

1. Run the one-command bootstrap above.
2. Publish the generated Place to the designated persistence test Place once.
3. Play. Session and Scene preparation run automatically.
4. Click the visible 3D Token.
5. Click a different point on the board.
6. Optionally verify middle-button drag Pan, mouse-wheel Zoom, and `F` Frame.
7. Wait for the final `[RVTT Batch Summary]` line.
8. On a first clean run, wait for the persistence save, Stop, and Play once more so `state-restore` can pass.

## Picking boundary

Picking resolves in this order:

1. queried 3D Token part or selection Hitbox hit by the world Raycast
2. projected token screen bounds near the pointer
3. board destination movement when no Token candidate is found

This ordering prevents a visible Token click from becoming a board move when the engine Raycast returns the floor behind the Token.

## Authority boundary

The client selects an Actor and proposes a destination. It does not pivot the Token optimistically. The destination marker shows request state, while the Token transform changes only when a newer server Projection contains the committed Actor position.

## Reporting

Normal success reporting requires only the final summary line and its checks. On failure, report the final summary and the first related structured line from one of these prefixes:

- `[RVTT WorldToken Input]`
- `[RVTT WorldToken Command]`
- `[RVTT WorldToken Projection]`
- `[RVTT Batch Command]`
- `[RVTT Batch Move]`
