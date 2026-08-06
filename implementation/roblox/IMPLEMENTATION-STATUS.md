# RVTT Production Implementation Status

- 상태: `GRAND_SLICES_02_12_AUTOMATED_BASELINE_STATIC_VERIFIED`
- 작성일: 2026-08-05
- 최종 갱신일: 2026-08-06
- 범위: 16개 Slice Runtime baseline, Grand Acceptance Campaign과 Slices 02–12 자동 Authority Scenario
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

## 기존 Studio Evidence

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

## Grand Acceptance 구현

```text
Grand Manifest
→ IMPLEMENTED

Grouped Windows Runner
→ IMPLEMENTED

Shared Studio Run via runId
→ IMPLEMENTED

Recent Roblox Log Summary Collection
→ IMPLEMENTED

JSON·Markdown Consolidated Report
→ IMPLEMENTED

Grand Single-client Place
→ IMPLEMENTED · DATASTORE DISABLED

Grand Multi-client Place
→ REGISTERED

Actual Grand Campaign Runtime
→ NOT YET EXECUTED
```

현재 Runner는 첫 실패에서 중단하지 않고 가능한 모든 선택 Phase를 끝까지 실행한다. 결과는 `pass`, `fail`, `incomplete`, `prepared`, `blocked`로 분리한다.

## Grand Single-client 자동 Scenario

한 번의 Studio Play에서 기존 Unit·Integration과 함께 다음 Spec을 실행하도록 등록했다.

### Slice baseline

- Slice 02 — Ability Check·Save·Attack·HP·Authorization·Idempotency
- Slice 03 — Interaction·Locked/Hidden Object·Search·Knowledge·Fog·Restore
- Slice 04 — Encounter Lifecycle·Turn·Action·Rollback·End·Restore
- Slice 05 — Draft·Ownership·Activation·Level Up·Restore
- Slice 06 — Item Create·Move·Equip·Drop·Restore
- Slice 07 — Clock·Schedule·Activity·Completion·Restore
- Slice 08 — UI Preference Validation·User Isolation·Restore
- Slice 09 — Journal Ownership·Edit·Link·Ping·Restore
- Slice 10 — Source·Compile·Candidate Invalidation·Publish·Restore
- Slice 11 — Control·Quick Action·Runtime Patch·Recovery Request·Restore
- Slice 12 — Pack Rights·Dependency·Activation·Localization·Restore

### Grand scenario

- Cross-slice Full-session State 연결과 Snapshot Restore
- Stale Revision·Stale Epoch·Invalid Payload·Duplicate Replay
- Corrupt Snapshot 거부와 Runtime 보존
- Restore 후 AuthorityEpoch 갱신과 이전 Epoch 폐기
- Capacity Sample: Object 32·Item 32·Document 16
- Capacity `elapsedMs`와 `restoreMs` Evidence

각 Spec은 다음 구조화 로그를 출력한다.

```text
[RVTT Spec Summary] id=<id> result=PASS|FAIL passed=<n> failed=<n>
[RVTT Spec Failure] <id>: <failure>
[RVTT Tests] passed=<n> failed=<n>
```

Capacity Sample은 같은 `[RVTT Spec Summary]` 증거 토큰으로 측정값을 보고한다.

## 완료 의미

현재 Slices 02–12 상태는 다음과 같다.

```text
AUTOMATED AUTHORITY BASELINE
→ SOURCE·FORMAT·LINT·BUILD·TYPE VERIFIED
→ STUDIO RUNTIME NOT YET EXECUTED
→ FULL SLICE ACCEPTANCE NOT COMPLETE
```

자동 Scenario는 Domain Command·Authorization·State·Restore의 대표 경로를 검증한다. 실제 UI Flow, Viewer Disclosure 전체 Matrix, Human Accessibility, DataStore Restart, Network Fault와 Soak Evidence는 각 Slice의 남은 Gate다.

## 일반 기능과 Persistence 분리

`grand-single-client.project.json`과 `slice01-acceptance.project.json`은 `EnableStudioPersistence=false`를 사용한다.

일반 Grand Run:

- 입력·카메라
- Token 선택·이동
- Slices 02–12 메모리 내 Authority Scenario
- Cross-slice·Fault·Capacity Sample
- Multi-client Projection

Persistence Grand Run:

- Load·Save·Dirty·Flush
- Stop·Play Restore
- Server Restart·Reconnect
- Migration·Lease·Conflict
- Failure Recovery·Rollback

Persistence는 관련 변경을 축적한 뒤 `-IncludePersistence`로 한 번에 실행한다.

## Content Blocker

Slices 13–15는 Runtime과 Rights Gate Source는 존재하지만 공식 데이터를 포함하지 않는다.

- 승인된 Source Version
- 권리와 배포 범위
- Localization·Asset 승인
- Package·Catalog 등록

위 조건 전에는 공식 Character·Spell·Item·NPC·Monster Content를 Grand PASS 대상으로 등록하지 않는다. Monster는 승인된 공식 원본 Statblock을 그대로 사용하며 임의 CR·수치 재조정을 하지 않는다.

## 자동 Gate

- Grand Contract Validator: PASS
- Structure·Security·Policy Validator: PASS
- PowerShell Parser: PASS
- Runner SelfTest: PASS
- StyLua: PASS
- Selene: PASS
- Production·Test·Grand Single-client·Multi-client·Persistence·Slice01 Rojo Build: PASS
- Production·Test Luau Type Analysis: PASS
- Documentation Validation: PASS

위 결과는 정적·Build Evidence다. 실제 Studio Phase PASS를 대신하지 않는다.

## 아직 미검증

- 최신 Slice 01 Camera WASD·Middle-button·Frame 실제 입력
- Grand Runner의 실제 사용자 PC 순차 Studio 실행과 Log 수집
- Slices 02–12 전체 사용자·Disclosure·Recovery Scenario
- DataStore Restart·Cross-server Lease·Migration·Conflict Grand Phase
- Slices 13–15 공식 데이터·권리·Asset
- Navigation·Physics·Streaming·Large Scene
- UI Visual Redesign·Accessibility Human Review
- Network Drop·Delay·Reorder·Storage Fault Injection
- 실제 성능 Budget·Memory·Network·장시간 Soak
- Full-session Release Runbook

## 현재 Gate

```text
Grand Automated Harness Static Gate
→ PASS

Grand Runtime
→ USER EXECUTION DEFERRED

Persistence·Human UI·Full Fault·Soak
→ IMPLEMENTATION IN PROGRESS

Full Grand Campaign
→ BLOCKED UNTIL TARGET PHASES READY
```
