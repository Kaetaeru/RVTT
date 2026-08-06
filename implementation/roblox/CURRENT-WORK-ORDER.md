# RVTT Roblox Implementation 현재 작업 순서

- 상태: `IMPLEMENTED_STUDIO_BASELINE_VERIFIED`
- 문서 종류: Production Implementation Work Order
- 최종 갱신일: 2026-08-06
- 실행 테스트 규칙: [`EXECUTION-TEST-RULES.md`](EXECUTION-TEST-RULES.md)
- 구현 상태: [`IMPLEMENTATION-STATUS.md`](IMPLEMENTATION-STATUS.md)

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

Slice 01 Token Pick·Move·Projection
→ VERIFIED IN STUDIO

Middle-button Pointer Sampling
→ IMPLEMENTED · STUDIO PENDING

WASD Camera Pan
→ IMPLEMENTED · STUDIO PENDING

Regular Slice 01 DataStore
→ DISABLED

Dedicated Persistence Batch
→ DEFERRED

현재 작업
→ Slice 01 In-memory Camera Input Acceptance
```

## 2. 실행 테스트 원칙

### 일반 기능 반복

```text
관련 기능 구현
→ 자동 회귀 테스트와 정적 CI
→ 전체 Windows PowerShell Build 블록
→ 생성된 로컬 Place Play
→ 입력·Camera·Command·Projection 검증
```

일반 기능 반복에서는 Experience 게시, DataStore 연결, 저장 대기, Stop·Play Restore를 수행하지 않는다.

### Persistence 일괄 Gate

```text
Persistence 관련 변경 축적
→ persistence-acceptance.project.json Build
→ 필요한 Experience 게시 1회
→ Load·Save·Restore·Reconnect·Migration·Recovery 일괄 검증
```

일반 기능 Acceptance와 Persistence Acceptance의 Summary와 Evidence를 섞지 않는다.

## 3. 사용자 Build 명령 계약

사용자에게 전달하는 Build 명령은 반드시 다음 요소를 모두 포함한 완전한 다중 행 Windows PowerShell 블록이다.

```text
$ErrorActionPreference
RobloxStudioBeta 종료
$HOME\RVTT 저장소 경로
planning/rvtt-remake fetch·switch·pull
정확한 7자리 Head 검사
slice01-acceptance.project.json Rojo Build
생성된 rbxlx Start-Process
```

한 줄 명령, 원격 `Invoke-Expression`, 중첩 `powershell -Command`, 인수형 Runner만 단독으로 제공하지 않는다.

## 4. 현재 작업 순서

| 순서 | 상태 | 작업 | 완료 조건 |
|---:|---|---|---|
| 1 | DONE | 전체 Contract→Script Transfer | 16개 Slice Domain·Manifest·Test Source 존재 |
| 2 | DONE | Authority·Security 보강 | Command Authorization과 서버 계산 경계 |
| 3 | DONE | 정적 Implementation CI baseline | Structure·Policy·Security Validator 성공 |
| 4 | DONE | Luau·Rojo Toolchain baseline | Build·Type Check·Formatter·Linter 성공 |
| 5 | DONE | Roblox Studio Runtime Baseline | Unit·Integration·Live DataStore·3-client 성공 |
| 6 | DONE | Accent Theme·Avatar·Persistence baseline | Visual·Input·Save·Reload·Character Suppression 확인 |
| 7 | DONE | Slice 01 Authority Acceptance | Join→Select→Ready→Scene→Move→Reconnect 상태 복구 |
| 8 | DONE | Slice 01 3D World Token Baseline | Projection Renderer·Picking·Selection·Move 확인 |
| 9 | IN_PROGRESS | Slice 01 In-memory Camera Input Acceptance | 실제 WASD·중클릭·F·휠로 Camera 변화 확인 |
| 10 | BLOCKED | Slice 01 Production Build Acceptance Audit | Camera Input Gate 완료 후 Production 경계 판정 |
| 11 | QUEUED | Slice 02 Rules·D20 Batch | 판정·Attack·Damage·Projection를 한 묶음으로 검증 |
| 12 | QUEUED | Slices 03–16 Batch Acceptance | 관련 Slice를 Milestone 단위로 묶어 검증 |
| 13 | DEFERRED | DataStore·Restart Recovery Batch | Load·Save·Restart·Lease·Migration·Conflict 일괄 검증 |
| 14 | QUEUED | UI Visual Redesign Batch | 전체 화면을 공통 Token·Component 기준으로 개편 |
| 15 | QUEUED | UI Accessibility QA | Keyboard·Focus·Contrast·User Test |
| 16 | QUEUED | Performance·Fault·Soak | 측정 Evidence와 Release Gate |

## 5. Camera 입력 계약

### WASD

WASD Character 이동 모드가 비활성화된 동안 World Camera가 W/A/S/D를 소비한다.

- W: Camera-relative forward
- A: Camera-relative left
- S: Camera-relative backward
- D: Camera-relative right
- 대각선 속도 정규화
- TextBox 포커스 시 Pass
- 이동 모드 활성 시 `setMovementModeActive(true)`로 Camera WASD 해제
- 이동 모드 종료 시 `setMovementModeActive(false)`로 Camera WASD 복구

### Middle-button

- 중클릭 시작 시 화면 Pointer 위치 저장
- `RenderStepped`에서 절대 Pointer 위치 차이 계산
- 이동량 0인 Frame은 무시
- 한 Drag 세션의 최초 성공만 구조화 로그 출력

### Frame·Zoom

- `F` 또는 Token Frame으로 선택 Token 또는 전체 Token Frame
- Mouse Wheel로 Zoom
- 실제 Camera CFrame 변화 또는 Frame 적용 후에만 Acceptance PASS

## 6. 현재 Acceptance Check

일반 Slice 01 Batch는 16개 Check를 유지한다. 기존 Persistence Restore Check는 제거하고 실제 WASD Camera Pan Check로 교체했다.

```text
camera-frame
camera-pan
camera-wasd-pan
camera-zoom
```

Persistence는 이 Summary에 포함하지 않는다.

## 7. 자동 Gate 결과

```text
Structure·Security·Policy Validator
→ PASS

StyLua·Selene
→ PASS

Production·Test·Multi-client·Persistence·Slice01 Rojo Build
→ PASS

Production·Test Luau Type Analysis
→ PASS

Documentation·Windows Bootstrap Validation
→ PASS
```

Persistence Place는 정적 Build만 확인했다. 실제 DataStore 연결은 수행하지 않았다.

## 8. 다음 Gate

```text
WASD·중클릭·F·휠 자동 Gate
→ PASSED

실제 In-memory Camera Acceptance
→ PENDING

Dedicated Persistence Batch
→ DEFERRED

Slice 01 Production Build Acceptance Audit
→ BLOCKED

Slice 02 Rules·D20 Batch
→ QUEUED
```
