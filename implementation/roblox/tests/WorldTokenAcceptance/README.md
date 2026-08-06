# Slice 01 World Interaction Batch Acceptance

This test-only client validates the production World Token Command and Projection path without connecting to Studio DataStore.

## Batch scope

- automatic Session, Character, Ready, Scene, and Actor preparation
- 3D Token projection
- world Raycast picking
- screen-space projected-bounds picking fallback
- selection Highlight
- destination marker
- `movement.commit` command Receipt and revision diagnostics
- Projection-driven 3D movement
- middle-button Camera Pan
- WASD Camera Pan while WASD Character movement mode is inactive
- mouse-wheel Zoom
- `F` or Token Frame
- Roblox avatar suppression
- structured Final Batch Summary

## Persistence boundary

`slice01-acceptance.project.json` sets `EnableStudioPersistence=false`.

This regular interaction Build does not require:

- Experience publishing
- DataStore API access
- waiting for a save
- Stop and Play restore verification

Load, Save, Restore, Reconnect, Migration, and recovery are validated later in one dedicated Persistence Batch using `persistence-acceptance.project.json`.

## Windows PowerShell build

Every user-facing Build command must be supplied as a complete block in this form. Replace the build name and expected Head with the values supplied for the current gate.

```powershell
$ErrorActionPreference = "Stop"

Get-Process RobloxStudioBeta -ErrorAction SilentlyContinue |
    Stop-Process -Force

$repo = Join-Path $HOME "RVTT"
$roblox = Join-Path $repo "implementation\roblox"
$output = Join-Path $env:TEMP "RVTT-<BUILD-NAME>-<EXPECTED-HEAD>.rbxlx"

Set-Location $repo

git fetch origin
git switch planning/rvtt-remake
git pull --ff-only origin planning/rvtt-remake

$head = (git rev-parse --short HEAD).Trim()
Write-Host "현재 Head: $head"

if ($head -ne "<EXPECTED-HEAD>") {
    throw "예상 Head는 <EXPECTED-HEAD>이지만 현재 Head는 $head입니다."
}

Set-Location $roblox

Remove-Item $output -Force -ErrorAction SilentlyContinue
rojo build slice01-acceptance.project.json --output $output

Start-Process $output
```

Do not replace this block with a one-line bootstrap, remote `Invoke-Expression`, nested `powershell -Command`, or a parameter-only Runner command.

## Interaction

1. Run the complete PowerShell Build block supplied for the current Head.
2. Play the generated local Place. Publishing is not required.
3. Hold W, A, S, or D and confirm camera-relative movement.
4. Hold the middle mouse button and drag to confirm Pan.
5. Use the mouse wheel to confirm Zoom.
6. Press `F` or use Token Frame to frame the selected Token or all Tokens.
7. Click the visible 3D Token.
8. Click a different point on the board.
9. Check the final `[RVTT Batch Summary]` line.

## WASD ownership boundary

World Camera consumes WASD only while WASD Character movement mode is inactive. The movement-mode owner must call:

```lua
worldTokens.Camera:setMovementModeActive(true)
```

when Character movement starts, and:

```lua
worldTokens.Camera:setMovementModeActive(false)
```

when it ends. TextBox focus also releases WASD from Camera control.

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

- `[RVTT WorldCamera Input]`
- `[RVTT Batch Camera]`
- `[RVTT WorldToken Input]`
- `[RVTT WorldToken Command]`
- `[RVTT WorldToken Projection]`
- `[RVTT Batch Command]`
- `[RVTT Batch Move]`
