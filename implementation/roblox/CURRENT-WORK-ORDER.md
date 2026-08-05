# RVTT Roblox Implementation 현재 작업 순서

- 상태: `IMPLEMENTED_STUDIO_BASELINE_VERIFIED`
- 문서 종류: Production Implementation Work Order
- 최종 갱신일: 2026-08-06
- 실행 테스트 규칙: [`EXECUTION-TEST-RULES.md`](EXECUTION-TEST-RULES.md)
- Script Manifest: [`manifests/all-slices-script-manifest.md`](manifests/all-slices-script-manifest.md)
- 구현 상태: [`IMPLEMENTATION-STATUS.md`](IMPLEMENTATION-STATUS.md)
- Studio 검증 근거: [`Roblox Studio Runtime Baseline Validation Audit`](../../docs/remake/audits/roblox-studio-runtime-baseline-validation-audit.md)
- UI·UX Policy: [`UI·UX Global Policies`](../../docs/remake/ui/policies/README.md)

## 1. 현재 상태

```text
16개 Slice Script Manifest
→ DONE

Shared·Server·Client·UI·Test Source
→ IMPLEMENTED

Structure·Policy·Toolchain CI
→ PASSED

Roblox Studio Runtime Baseline
→ VERIFIED

Accent Theme Visual·Input·Persistence
→ VERIFIED IN STUDIO

Roblox Avatar Auto-Spawn Disable
→ VERIFIED IN STUDIO

Slice 01 Authority·Persistence·Reconnect
→ VERIFIED IN STUDIO

Slice 01 World Interaction Batch
→ PARTIAL STUDIO PASS · 14/16 USER-OBSERVED

현재 작업
→ Slice 01 Camera Input Correction Acceptance
```

기존 Studio Evidence:

```text
Unit·Integration
→ passed=173 failed=0

Live DataStore
→ passed=10 failed=0

3-client MultiClient
→ passed=56 failed=0 clients=3 staleRetries=3

Persistence·Accent Restore
→ PASS

Character·Scene·Position Recovery
→ PASS
```

2026-08-06 Slice 01 사용자 관측 Evidence:

```text
Token Pick·Highlight·Destination·Movement·Server Acceptance·Projection
→ PASS

Camera Zoom via Mouse Wheel
→ PASS

Camera Pan via Middle-button Drag
→ FAIL

Camera Frame via F / Token Frame
→ FAIL
```

기존 Final Summary의 `passed=16 failed=0`은 Camera Harness가 실제 입력이 아니라 `frameAll()`, `panPixels()`, `zoomBy()` 메서드를 직접 호출해 생성한 허위 양성 결과였다. 따라서 해당 Summary를 전체 사용자 흐름 PASS 근거로 사용하지 않는다.

## 2. 실행 테스트 원칙

Studio 수동 검사는 개별 수정마다 요청하지 않는다.

```text
관련 기능 여러 개 구현
→ 자동 회귀 테스트와 정적 CI
→ 구조화된 진단 로그와 Final Summary
→ 단일 Acceptance Place Build
→ 사용자 게시 1회
→ 전체 Batch 검증 1회
```

Acceptance Check는 함수 호출 가능 여부가 아니라 실제 사용자 입력과 관측 가능한 상태 변화로 판정해야 한다. 카메라 입력은 실제 `F`, 중클릭 드래그, 휠 이벤트가 Controller까지 도달하고 Camera CFrame에 반영됐을 때만 PASS다.

사용자에게 전달하는 Build 명령은 저장소에서 바로 실행 가능한 전체 Windows PowerShell 블록으로 제공한다.

## 3. 현재 작업 순서

| 순서 | 상태 | 작업 | 완료 조건 |
|---:|---|---|---|
| 1 | DONE | 전체 Contract→Script Transfer | 16개 Slice Domain·Manifest·Test Source 존재 |
| 2 | DONE | Authority·Security 보강 | Command Authorization과 서버 계산 경계 |
| 3 | DONE | 정적 Implementation CI | Structure·Policy·Security Validator 성공 |
| 4 | DONE | Luau·Rojo Toolchain 검증 | Build·Type Check·Formatter·Linter 성공 |
| 5 | DONE | Roblox Studio Runtime Baseline | Unit·Integration·Live DataStore·3-client 성공 |
| 6 | DONE | Accent Theme·Avatar·Persistence | Visual·Input·Save·Reload·Character Suppression 확인 |
| 7 | DONE | Slice 01 Authority Acceptance | Join→Select→Ready→Scene→Move→Reconnect 상태 복구 |
| 8 | DONE | Slice 01 3D World Token Baseline | Projection Renderer·Asset Resolver·월드 입력 연결 |
| 9 | DONE | Slice 01 World Interaction Implementation | Picking·Selection·Destination·Camera·Move·Diagnostics·Recovery 구현·CI PASS |
| 10 | IN_PROGRESS | Slice 01 Camera Input Correction Acceptance | 실제 F·중클릭 드래그·휠 입력으로 Camera Check 판정 |
| 11 | BLOCKED | Slice 01 Production Build Acceptance Audit | Camera Input Gate 완료 후 Production 경계 판정 |
| 12 | QUEUED | Slice 02 Rules·D20 Batch | 판정·Attack·Damage·Projection·복구를 한 묶음으로 구현·검증 |
| 13 | QUEUED | Slices 03–16 Batch Acceptance | 관련 Slice를 Milestone 단위로 묶어 검증 |
| 14 | QUEUED | DataStore·Restart Recovery Batch | Restart·Lease·Migration·Conflict 검증 |
| 15 | QUEUED | UI Visual Redesign Batch | 전체 화면을 Token·공통 Component 기준으로 일괄 개편 |
| 16 | QUEUED | UI Accessibility QA | Keyboard·Focus·Contrast·User Test |
| 17 | QUEUED | Performance·Fault·Soak | 측정 Evidence와 Release Gate |

## 4. Camera Input Correction

현재 Delta:

```text
SLICE_01_WORLD_INTERACTION_BATCH_CAMERA_INPUT_PENDING
```

원인:

```text
Acceptance Harness
→ Camera 메서드 직접 호출
→ 실제 F·중클릭 입력 미검증
→ camera-frame·camera-pan 허위 PASS

WorldCameraController
→ gameProcessedEvent=true 입력 조기 반환
→ Roblox 기본 입력이 소비한 F·중클릭 경로 무시
```

수정:

- `F`와 중클릭을 `ContextActionService` 고우선순위 Action으로 수신
- MouseMovement는 `gameProcessedEvent`와 무관하게 활성 Drag 동안 처리
- 실제 입력마다 `[RVTT WorldCamera Input]` 로그 출력
- `InputResolved` Signal에 action·source·applied·changed·processed 전달
- Acceptance Camera Check를 실제 입력 전까지 `pending`으로 유지
- 실제 입력과 Camera 변화가 확인될 때만 PASS
- `Token Frame` 버튼도 동일한 실제 입력 판정 경로 사용

## 5. 사용자 관측상 검증된 범위

```text
3D Token Projection
→ PASS

Raycast 실패 시 Screen-space Picking Fallback
→ PASS

Selection Highlight·Destination Marker
→ PASS

movement.commit 서버 권위 이동
→ PASS

Command Receipt·Revision·Projection
→ PASS

Persistence Save·Reconnect Restore
→ PASS

Roblox Avatar Suppression
→ PASS

Camera Zoom via Wheel
→ PASS

Camera Frame·Pan
→ RETEST REQUIRED
```

`WT-PICK-01`은 해결 상태를 유지한다. World Raycast가 `Workspace.RVTT_AcceptanceBoard.MoveSurface`를 반환했지만 Screen-space Token Bounds가 Actor를 선택했고 서버 승인 revision 73과 Projection 이동이 확인됐다.

## 6. UI 디자인 해석

현재 Production UI와 Acceptance Panel은 기능 검증용 Placeholder다.

- 현재 외형을 최종 디자인으로 확장하지 않는다.
- 화면 로직과 시각 표현을 분리한다.
- Production 색상·간격·Typography는 공통 Token을 사용한다.
- Acceptance 화면은 테스트 조작면으로만 사용한다.
- 전면 수정은 별도 `UI Visual Redesign` Batch에서 일괄 수행한다.
- 기능 테스트는 상태·입력·서버 권위·Persistence 계약을 기준으로 유지한다.

## 7. 다음 Gate

```text
Camera Input Correction 구현·자동 Gate
→ IN PROGRESS

실제 F·중클릭 드래그·휠 Acceptance
→ PENDING

Slice 01 Production Build Acceptance Audit
→ BLOCKED

Slice 02 Rules·D20 Batch
→ QUEUED
```
