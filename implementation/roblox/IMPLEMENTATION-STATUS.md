# RVTT Production Implementation Status

- 상태: `IMPLEMENTED_STUDIO_BASELINE_VERIFIED`
- 작성일: 2026-08-05
- 최종 갱신일: 2026-08-06
- 범위: 16개 Slice 계약의 Greenfield Runtime·Domain·Client·UI·Test baseline
- 실행 테스트 규칙: [`EXECUTION-TEST-RULES.md`](EXECUTION-TEST-RULES.md)

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

## 기존 Studio Baseline Evidence

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

Character·Scene·Position Reconnect Recovery
→ PASS
```

위 Persistence Evidence는 기존 검증 기록이다. 현재 일반 기능 Acceptance가 DataStore를 다시 검증한다는 의미가 아니다.

## 실행 테스트 방식

```text
BATCH_ACCEPTANCE_RULE_ACTIVE
```

- 개별 수정마다 Roblox Studio Place를 게시하지 않는다.
- 일반 기능 Build와 Persistence Batch를 분리한다.
- `slice01-acceptance.project.json`은 `EnableStudioPersistence=false`다.
- 일반 기능 Build에서는 Experience 게시, DataStore 연결, 저장 대기, Stop·Play 복구를 요구하지 않는다.
- Persistence는 `persistence-acceptance.project.json`을 사용하는 별도 일괄 Gate에서 검증한다.
- 사용자에게는 저장소를 직접 갱신하고 정확한 Head를 검사하는 완전한 다중 행 Windows PowerShell 블록만 제공한다.

## Slice 01 World Interaction Delta

```text
SLICE_01_CAMERA_WASD_NO_DATASTORE_ACCEPTANCE_IMPLEMENTED_STUDIO_PENDING
```

2026-08-06 사용자 관측:

```text
Token Pick·Selection Highlight
→ PASS

Destination Marker·movement.commit
→ PASS

Server Acceptance·Projection Move
→ PASS · revision 72→73

Camera Zoom via Mouse Wheel
→ PASS

Camera Frame via F / Token Frame
→ 미확정

Camera Pan via Middle-button Drag
→ FAIL · 기존 InputObject.Delta 경로
```

기존 `[RVTT Batch Summary] passed=16 failed=0`은 Harness가 Camera 메서드를 직접 호출해 만든 허위 양성이므로 전체 사용자 흐름 PASS 근거에서 철회했다.

## Camera 입력 구현

### Middle-button Pan

- 중클릭 시작·종료는 `ContextActionService` 고우선순위 Action으로 수신
- `InputObject.Delta` 대신 `GetMouseLocation()` 절대 좌표를 `RenderStepped`에서 비교
- 실제 이동량이 있을 때만 Pan 적용
- 한 Drag 세션의 최초 성공만 구조화 로그와 Acceptance Signal로 보고
- Studio 재검증 대기

### WASD Camera Pan

WASD Character 이동 모드가 비활성화된 동안 다음 입력으로 Camera Target을 이동한다.

```text
W 전진 · A 좌측 · S 후진 · D 우측
```

- Camera-relative 평면 이동
- 대각선 입력 정규화
- TextBox 포커스 시 Camera가 WASD를 소비하지 않음
- 이동 모드 활성 시 `setMovementModeActive(true)`로 Camera WASD 해제
- 이동 모드 종료 시 `setMovementModeActive(false)`로 Camera WASD 복구
- 한 키 입력 세션의 최초 실제 Camera 변화만 `keyboard-wasd`로 보고
- Studio 검증 대기

## Acceptance Summary 계약

일반 Slice 01 Acceptance의 16개 Check에서 Persistence Restore를 제거하고 실제 WASD Camera Pan을 추가했다.

```text
camera-frame
camera-pan
camera-wasd-pan
camera-zoom
```

각 항목은 실제 입력이 Controller에 도달하고 Camera에 적용된 뒤에만 PASS한다. 일반 Build의 Summary는 Persistence PASS를 주장하지 않는다.

## Slice 01 3D World Token 구현 상태

```text
Authority·Scene·Movement Contract
→ IMPLEMENTED · VERIFIED

Projection-driven 3D Renderer
→ IMPLEMENTED · VERIFIED

Screen-space Picking Fallback
→ IMPLEMENTED · VERIFIED

Selection Highlight·Destination Marker
→ IMPLEMENTED · VERIFIED

Camera Zoom
→ IMPLEMENTED · USER VERIFIED

Camera Frame
→ IMPLEMENTED · STUDIO RETEST PENDING

Middle-button Camera Pan
→ SCREEN-POSITION CORRECTED · STUDIO RETEST PENDING

WASD Camera Pan
→ IMPLEMENTED · STUDIO PENDING

Regular Acceptance DataStore
→ DISABLED BY PROJECT CONFIG

Dedicated Persistence Batch
→ DEFERRED · SEPARATE GATE

Roblox Avatar Suppression
→ IMPLEMENTED · VERIFIED
```

## WT-PICK-01 판정

```text
RESOLVED
```

World Raycast가 `Workspace.RVTT_AcceptanceBoard.MoveSurface`를 반환하는 상황에서도 Screen-space projected bounds fallback이 Token을 선택했다. 이후 Highlight, Destination Marker, 서버 승인 revision 73, Projection 위치 갱신이 확인됐다.

## 자동 Gate

- Structure·Security·Policy Validator: PASS
- StyLua: PASS
- Selene: PASS
- Production Rojo Build: PASS
- Unit Test Place Rojo Build: PASS
- Multi-client Place Rojo Build: PASS
- Persistence Acceptance Place 정적 Build: PASS
- Slice 01 Acceptance Place Build: PASS
- Production·Test Luau Type Analysis: PASS
- Windows Acceptance Bootstrap Validation: PASS
- Remake Documentation Validation: PASS

이 결과는 정적·Build·Type Evidence이며 실제 Studio WASD·중클릭·F 동작을 대신하지 않는다.

## UI 시각 디자인 상태

현재 Production UI와 Acceptance Panel은 기능 검증용 Placeholder다. 최종 시각 디자인으로 간주하지 않는다.

- 화면 로직과 시각 표현 분리
- 공통 색상·간격·Typography Token 유지
- 기능 테스트를 상태·입력·서버 권위 기준으로 유지
- 전면 수정은 별도 `UI Visual Redesign Batch`에서 수행

## 현재 Gate

```text
WASD·Middle-button·Frame Camera 자동 Gate
→ PASSED

실제 WASD·중클릭·F·휠 Acceptance
→ PENDING

일반 Slice 01 Acceptance DataStore
→ OUT OF SCOPE

Dedicated Persistence Batch
→ DEFERRED

Slice 01 Production Build Acceptance Audit
→ BLOCKED

Slice 02 Rules·D20 Batch
→ QUEUED
```

## 아직 미검증

- Slice 01 Camera Frame·Middle-button Pan·WASD Pan 실제 사용자 입력
- 최종 OBJ·MeshPart Art Pack과 Asset QA
- Slice 01 Production Build Acceptance Audit
- Slices 02–16 사용자·보안·복구 Scenario
- DataStore Restart·Cross-server Lease·Migration·Conflict Recovery 일괄 Batch
- Navigation·Physics·Streaming·Large Scene
- 전면 UI Visual Redesign와 Accessibility User Test
- Performance·Memory·Network·Fault·Soak Evidence

## 데이터 차단

Slices 13–15의 Runtime과 Rights Gate는 구현했지만 공식 D&D 데이터는 포함하지 않았다. 승인된 Source Version·권리·배포 범위를 가진 별도 Content Pack만 등록할 수 있다.
