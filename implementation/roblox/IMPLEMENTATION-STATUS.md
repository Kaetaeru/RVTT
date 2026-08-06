# RVTT Production Implementation Status

- 상태: `GRAND_ACCEPTANCE_FOUNDATION_IMPLEMENTED`
- 작성일: 2026-08-05
- 최종 갱신일: 2026-08-06
- 범위: 16개 Slice Runtime baseline과 Grand Acceptance Campaign Foundation
- Grand Campaign: [`GRAND-ACCEPTANCE-CAMPAIGN.md`](GRAND-ACCEPTANCE-CAMPAIGN.md)
- 실행 테스트 규칙: [`EXECUTION-TEST-RULES.md`](EXECUTION-TEST-RULES.md)

## 구현된 공통 계약

- Versioned Command Envelope와 재귀 Payload 제한
- 명시적 Command Authorization 필수 Registry
- 서버 권위 Transaction·Idempotency·Outbox·Projection
- Viewer별 Domain Projection과 DM 정보 Negative Disclosure
- Character·Actor·Item Ownership·Control 검증
- 서버 계산 D20·Attack·Damage·HP 변경
- AuthorityEpoch·Revision·Projection Gap·Full Resync
- Migration·DataStore Adapter·Persistence Coordinator
- Semantic Input·Client Runtime·Token 기반 UI Shell
- Roblox 기본 Avatar와 RVTT Token 분리
- 16개 Slice Domain Command baseline
- Unit·Integration·Security·Disclosure Test Source

## 기존 Studio Baseline Evidence

```text
[RVTT Tests] passed=173 failed=0
[RVTT Live DataStore] passed=10 failed=0
[RVTT MultiClient] passed=56 failed=0 clients=3 staleRetries=3
```

추가 사용자 관측:

```text
Slice 01 Token Pick·Highlight·Destination·Movement
→ PASS

Server Acceptance·Projection Move
→ PASS · revision 72→73

Camera Zoom
→ PASS

Camera WASD·Middle-button·Frame Correction
→ IMPLEMENTED · LATEST STUDIO RETEST PENDING
```

기존 Camera Harness의 직접 메서드 호출로 생성된 Slice 01 `16/16 PASS`는 실제 입력 Evidence에서 철회했다.

## Grand Acceptance Foundation

```text
Grand Manifest
→ IMPLEMENTED

Grand Windows Runner
→ IMPLEMENTED

Sequential Studio Phase Launch
→ IMPLEMENTED

Recent Roblox Log Summary Collection
→ IMPLEMENTED

JSON·Markdown Consolidated Report
→ IMPLEMENTED

Windows Parser·Manifest SelfTest
→ IMPLEMENTED

Actual Grand Campaign Runtime
→ NOT YET EXECUTED
```

현재 Runner는 첫 실패에서 중단하지 않고 가능한 모든 선택 Phase를 끝까지 실행한다. 결과는 다음 상태로 구분한다.

- `pass`: 기대 PASS Summary 발견
- `fail`: Summary는 발견했지만 PASS 계약 불일치 또는 Build 실패
- `incomplete`: 기대 Summary를 Log에서 찾지 못함
- `prepared`: `-NoOpen`으로 Place만 Build
- `blocked`: Harness·환경·권리·Evidence가 아직 준비되지 않음

## Grand Phase Registry

### READY

- Static and Rojo Build Gate
- Unit·Integration Baseline
- Slice 01 World Interaction
- Multi-client Authority·Projection

### DEFERRED

- Live DataStore Baseline
- Persistence Restart·Migration·Conflict Recovery

### PLANNED

- Slices 02–12 사용자·보안·복구 Harness
- UI Visual·Accessibility Evidence
- Network·Storage Fault Injection
- Performance·Soak·Capacity
- Slice 16 Full-session Release Campaign

### BLOCKED

- Slice 13 공식 Character Content
- Slice 14 공식 Spell·Equipment·Rules Content
- Slice 15 NPC·Monster·Campaign Content

Slices 13–15는 Source Version·권리·배포 범위·Asset 승인 전까지 실행 대상이 아니다.

## 일반 기능과 Persistence 분리

`slice01-acceptance.project.json`은 계속 `EnableStudioPersistence=false`를 사용한다.

일반 기능 Phase:

- 입력·카메라
- Token 선택·이동
- Command·Projection
- 메모리 내 Authority

Persistence Phase:

- Load·Save·Dirty·Flush
- Stop·Play Restore
- Server Restart·Reconnect
- Migration·Lease·Conflict
- Failure Recovery·Rollback

Persistence는 관련 변경을 축적한 뒤 Grand Campaign에서 `-IncludePersistence`를 사용해 한 번에 실행한다.

## 자동 Gate

- Structure·Security·Policy Validator
- Grand Manifest Schema·Phase Registry Validator
- PowerShell Parser
- Runner SelfTest
- StyLua
- Selene
- Production·Test·Multi-client·Persistence·Slice01 Rojo Build
- Production·Test Luau Type Analysis
- Documentation Validation

위 결과는 정적·Build Evidence다. 실제 Studio Phase PASS를 대신하지 않는다.

## 아직 미검증

- 최신 Slice 01 Camera WASD·Middle-button·Frame 실제 입력
- Grand Runner의 실제 사용자 PC 순차 Studio 실행과 Log 수집
- Slices 02–12 Grand Harness
- DataStore Restart·Cross-server Lease·Migration·Conflict Grand Phase
- Slices 13–15 공식 데이터·권리·Asset
- Navigation·Physics·Streaming·Large Scene
- UI Visual Redesign·Accessibility Human Review
- Performance·Memory·Network·Fault·Soak
- Full-session Release Runbook

## 현재 Gate

```text
Grand Acceptance Foundation 자동 Gate
→ IN PROGRESS

READY Phase Grand Runtime
→ PENDING

Persistence Grand Phase
→ DEFERRED

Slices 02–12 Harness Expansion
→ QUEUED

Full Grand Campaign
→ BLOCKED UNTIL PHASES READY
```
