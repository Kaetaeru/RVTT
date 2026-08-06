# Slice 01 WASD Camera and No-DataStore Acceptance Audit

- 상태: `IMPLEMENTED · STUDIO PENDING`
- 기록일: 2026-08-06
- 범위: Slice 01 일반 기능 Acceptance의 Camera 입력과 Persistence 경계

## 결정

일반 Slice 01 기능 Build는 `slice01-acceptance.project.json`을 사용하며 Studio DataStore를 연결하지 않는다.

```text
EnableStudioPersistence=false
```

DataStore Load·Save·Restore·Reconnect·Migration·Recovery는 관련 변경을 모은 뒤 `persistence-acceptance.project.json`을 사용하는 별도 일괄 Batch에서 검증한다.

## Camera 입력

WASD Character 이동 모드가 비활성화된 동안 World Camera가 W/A/S/D를 Camera-relative Pan으로 처리한다.

- W: forward
- A: left
- S: backward
- D: right
- diagonal input normalized
- TextBox focus releases WASD
- `setMovementModeActive(true)` releases WASD to Character movement
- `setMovementModeActive(false)` restores Camera WASD

Middle-button Pan은 `InputObject.Delta` 대신 프레임별 절대 Pointer 위치 차이를 사용한다.

## Acceptance 변경

기존 일반 Batch의 `state-restore` Check를 제거하고 `camera-wasd-pan` Check를 추가했다.

```text
camera-frame
camera-pan
camera-wasd-pan
camera-zoom
```

일반 Batch Summary는 Persistence PASS를 주장하지 않는다.

## 사용자 실행 계약

모든 사용자 Build 명령은 다음 요소를 포함한 완전한 다중 행 Windows PowerShell 블록으로 제공한다.

- `$ErrorActionPreference = "Stop"`
- Roblox Studio 종료
- `$HOME\RVTT` 이동
- `planning/rvtt-remake` fetch·switch·pull
- 정확한 7자리 Head 검사
- `rojo build slice01-acceptance.project.json --output $output`
- `Start-Process $output`

한 줄 Bootstrap, 원격 `Invoke-Expression`, 중첩 `powershell -Command`, 인수형 Runner만 단독으로 제공하지 않는다.

## 검증 상태

자동 검증은 Structure, Policy, StyLua, Selene, Rojo Build, Luau Type Analysis를 통과해야 한다. 실제 WASD·중클릭·F·휠 동작은 사용자 Studio Evidence가 들어오기 전까지 `PENDING`이다.
