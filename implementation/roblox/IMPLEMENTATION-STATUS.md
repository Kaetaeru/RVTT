# RVTT Production Implementation Status

- 상태: `IMPLEMENTED_STUDIO_BASELINE_VERIFIED`
- 작성일: 2026-08-05
- 최종 갱신일: 2026-08-06
- 범위: 16개 Slice 계약의 Greenfield Runtime·Domain·Client·UI·Test baseline
- 실행 테스트 규칙: [`EXECUTION-TEST-RULES.md`](EXECUTION-TEST-RULES.md)
- Studio 검증 근거: [`Roblox Studio Runtime Baseline Validation Audit`](../../docs/remake/audits/roblox-studio-runtime-baseline-validation-audit.md)

## 구현된 공통 계약

- Versioned Command Envelope와 재귀 Payload 제한
- 명시적 Command Authorization 필수 Registry
- 서버 권위 Transaction·Idempotency·Outbox·Projection
- Viewer별 Domain Projection과 DM 정보 Negative Disclosure
- Character·Actor·Item 소유권 및 Runtime Control 검증
- 서버 계산 D20·Attack·Damage·HP 변경
- AuthorityEpoch·Revision·Projection Gap·Full Resync
- Migration·DataStore Adapter·Debounced Persistence Coordinator
- Semantic Input·Client Runtime·Token 기반 UI Shell
- Roblox 기본 아바타와 RVTT Token·Character 모델 분리
- 16개 Slice Domain Command baseline
- Unit·Integration·Security·Disclosure Test Source

## 검증된 Studio Baseline

```text
Unit·Integration
→ passed=173 failed=0

Live DataStore
→ passed=10 failed=0

3-client MultiClient
→ passed=56 failed=0 clients=3 staleRetries=3

Roblox Player.Character 비생성
→ PASS

Accent Visual·Input·Persistence
→ PASS

Canonical Remote Bootstrap
→ PASS

Character·Scene·Position Reconnect Recovery
→ PASS
```

Accent 상태:

```text
ACCENT_THEME_PERSISTENCE_VERIFIED
```

## 실행 테스트 방식

```text
BATCH_ACCEPTANCE_RULE_ACTIVE
```

개별 수정마다 Roblox Studio Place를 게시하지 않는다. 관련 기능 구현과 자동 Gate를 완료한 후 단일 Acceptance Place에서 실제 사용자 입력과 관측 가능한 결과를 한 번에 판정한다.

Acceptance Harness는 메서드를 직접 호출해 사용자 입력을 대신해서는 안 된다. 실제 입력이 Controller에 도달하고 상태 또는 Camera CFrame이 바뀐 경우에만 해당 Input Check를 PASS 처리한다.

사용자에게 전달하는 실행 방법은 저장소에서 직접 실행 가능한 전체 Windows PowerShell Build 블록으로 제공한다.

## Slice 01 World Interaction Batch

현재 Delta:

```text
SLICE_01_WORLD_INTERACTION_BATCH_CAMERA_INPUT_PENDING
```

2026-08-06 사용자 관측:

```text
Token Pick·Selection Highlight
→ PASS

Destination Marker·movement.commit
→ PASS

Server Acceptance·Projection Move
→ PASS · revision 72→73

Persistence Restore·Avatar Suppression
→ PASS

Camera Zoom via Mouse Wheel
→ PASS

Camera Frame via F / Token Frame
→ FAIL

Camera Pan via Middle-button Drag
→ FAIL
```

기존 `[RVTT Batch Summary] passed=16 failed=0`은 다음 이유로 전체 사용자 흐름 PASS 근거에서 철회했다.

```text
runCameraSelfCheck()
→ frameAll() 직접 호출
→ panPixels() 직접 호출
→ zoomBy() 직접 호출
→ 실제 F·중클릭·휠 입력과 무관하게 Camera Check PASS
```

따라서 실제 사용자 관측 기준 상태는 `14/16 PASS`, Camera Frame·Pan 재검증 대기다.

### Camera Input Correction

원인:

- `UserInputService` callback에서 `gameProcessedEvent=true`일 때 즉시 반환
- Roblox 기본 입력이 소비한 `F`와 중클릭 경로가 Controller에 도달하지 않음
- Harness의 직접 메서드 호출이 입력 결함을 숨김

수정:

- `ContextActionService:BindActionAtPriority`로 `F`와 `MouseButton3` 수신
- 중클릭 Drag 중 MouseMovement는 processed 상태와 무관하게 처리
- `requestFrame()`으로 키보드와 Panel 버튼 경로 통합
- 실제 입력 결과용 `InputResolved` Signal 추가
- `[RVTT WorldCamera Input]` 및 `[RVTT Batch Camera]` 구조화 로그 추가
- Camera Check는 실제 입력 전까지 `pending`
- Frame은 실제 요청 적용, Pan·Zoom은 실제 Camera CFrame 변화까지 확인해야 PASS

## Slice 01 3D World Token 구현 상태

```text
Authority·Scene·Movement Contract
→ IMPLEMENTED · VERIFIED

Projection-driven 3D Renderer
→ IMPLEMENTED · VERIFIED

Model·MeshPart Asset Resolver
→ IMPLEMENTED

Screen-space Picking Fallback
→ IMPLEMENTED · VERIFIED

Selection Highlight·Destination Marker
→ IMPLEMENTED · VERIFIED

Camera Zoom
→ IMPLEMENTED · USER VERIFIED

Camera Frame·Pan
→ CORRECTED · STUDIO RETEST PENDING

Persistence·Reconnect Restore
→ IMPLEMENTED · VERIFIED

Roblox Avatar Suppression
→ IMPLEMENTED · VERIFIED
```

## WT-PICK-01 판정

```text
RESOLVED
```

World Raycast가 `Workspace.RVTT_AcceptanceBoard.MoveSurface`를 반환하는 상황에서도 Screen-space projected bounds fallback이 Token을 선택했다. 이후 Highlight, Destination Marker, 서버 승인 revision 73, Projection 위치 갱신이 확인됐다.

## Acceptance Harness와 Diagnostics

`slice01-acceptance.project.json`은 실제 Production Server·Client·Networking·Projection·Persistence 경로를 사용한다.

Camera Check 요구사항:

- `camera-frame`: 실제 `F` 또는 `Token Frame` 입력
- `camera-pan`: 실제 중클릭 Drag와 Camera 위치 변화
- `camera-zoom`: 실제 Mouse Wheel과 Camera 위치 변화
- 실패 시 action·source·applied·changed·processed 로그
- 세 실제 입력 Check가 완료되기 전에는 Final Summary PASS 금지

## UI 시각 디자인 상태

현재 Production UI, Acceptance Panel, primitive fallback miniature는 기능 검증용 Placeholder다. 최종 시각 디자인으로 간주하지 않는다.

- 화면 로직과 시각 표현 분리
- 공통 색상·간격·Typography Token 유지
- 기능 테스트를 상태·입력·서버 권위·Persistence 기준으로 유지
- Acceptance 화면을 Production UI 후보로 취급하지 않음
- 전면 수정은 별도 `UI Visual Redesign Batch`에서 일괄 수행

## 현재 Gate

```text
Camera Input Correction 구현·자동 Gate
→ IN PROGRESS

실제 Camera Frame·Pan·Zoom Acceptance
→ PENDING

Slice 01 Production Build Acceptance Audit
→ BLOCKED

Slice 02 Rules·D20 Batch
→ QUEUED
```

## 아직 미검증

- Slice 01 Camera Frame·Pan 실제 사용자 입력
- 최종 OBJ·MeshPart Art Pack과 Asset QA
- Slice 01 Production Build Acceptance Audit
- Slices 02–16 사용자·보안·복구 Scenario
- DataStore server restart·Cross-server Lease·Migration·Conflict Recovery
- Navigation·Physics·Streaming·Large Scene
- 전면 UI Visual Redesign와 Accessibility User Test
- Performance·Memory·Network·Fault·Soak Evidence

## 데이터 차단

Slices 13–15의 Runtime과 Rights Gate는 구현했지만 공식 D&D 데이터는 포함하지 않았다. 승인된 Source Version·권리·배포 범위를 가진 별도 Content Pack만 등록할 수 있다.
