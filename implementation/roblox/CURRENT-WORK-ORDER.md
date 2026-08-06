# RVTT Roblox Implementation 현재 작업 순서

- 상태: `GRAND_REAL_TRANSPORT_RESTART_HOST_STATIC_VERIFIED`
- 문서 종류: Production Implementation Work Order
- 최종 갱신일: 2026-08-06
- Grand Campaign: [`GRAND-ACCEPTANCE-CAMPAIGN.md`](GRAND-ACCEPTANCE-CAMPAIGN.md)
- Grand Manifest: [`grand-acceptance-manifest.json`](grand-acceptance-manifest.json)
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
→ VERIFIED · HISTORICAL EVIDENCE

Slice 01 Token Pick·Move·Projection
→ VERIFIED IN STUDIO

WASD·Middle-button·Frame Camera Correction
→ IMPLEMENTED · LATEST STUDIO PENDING

Grand Manifest·Runner·Grouped Studio Runs·Report
→ IMPLEMENTED · STATIC VERIFIED

Slices 02–12 Automated Authority Baseline
→ IMPLEMENTED · STATIC VERIFIED · STUDIO NOT EXECUTED

Cross-slice Session·Authority Fault·Capacity Sample
→ IMPLEMENTED · STATIC VERIFIED · STUDIO NOT EXECUTED

Deterministic Network·Storage Fault Host
→ IMPLEMENTED · STATIC VERIFIED · STUDIO NOT EXECUTED

Real Player Disconnect·Reconnect Host
→ IMPLEMENTED · STATIC VERIFIED · STUDIO NOT EXECUTED

BindToClose·Two-run Server Restart Host
→ IMPLEMENTED · STATIC VERIFIED · PUBLISHED STUDIO NOT EXECUTED

현재 작업
→ Forced DataStore Outage·Cross-server Lease/Conflict Host 연결
```

## 2. 테스트 운영 방식

기능 하나나 버그 하나마다 Studio를 다시 실행하지 않는다.

```text
관련 기능 구현
→ 자동 회귀 테스트·정적 CI
→ Grand Run에 Scenario 등록
→ 여러 Slice·복구·보안·성능 변경 축적
→ Grand Acceptance Campaign 한 번 실행
→ 모든 실패 수집
→ Root Cause별 수정 Batch
→ Grand Campaign 전체 재실행
```

사용자는 하나의 완전한 Windows PowerShell 블록을 한 번 실행한다. Runner는 같은 `runId`와 Project를 사용하는 Phase를 하나의 Studio 실행으로 묶고, Studio 종료 후 다음 실행 그룹으로 진행한다.

## 3. 현재 Grand 실행 그룹

### `grand-single-client`

한 번의 로컬 Studio Play에서 다음을 함께 실행한다.

- 기존 Unit·Integration·Security·Disclosure Source
- Slice 01 실제 WASD·중클릭·F·휠·Token 이동 Acceptance
- Slices 02–12 서버 권위 자동 Scenario
- Cross-slice Full-session 자동 Scenario
- Stale Revision·Stale Epoch·Duplicate·Invalid Payload·Corrupt Restore Scenario
- 결정적 Network Drop·Duplicate·Hold·Reorder·Delayed Epoch Scenario
- Terminal Receipt 유실·동일 Command ID 재전송·Bounded Timeout Scenario
- Storage Load·Save Failure·Commit Ack Loss·Revision Conflict·External Winner Scenario
- Shutdown Persistence Retry Policy Unit Scenario
- Capacity Sample: Scene Object 32, Item 32, Journal Document 16
- `[RVTT Spec Summary]`, `[RVTT Spec Failure]`, `[RVTT Tests]`, `[RVTT Fault Host]`, `[RVTT Persistence Retry]`, Slice 01 Batch Summary

### `grand-multi-client`

별도 Studio Server·3 Clients 실행에서 다음을 확인한다.

- DM·Player·Observer Authority
- Viewer별 Projection과 Negative Disclosure
- Stale Revision Recovery
- 기존 논리적 Connection State 전환과 Full Resync

### `grand-real-transport`

별도 Local Server·3 Clients 실행에서 실제 Player Lifecycle을 확인한다.

```text
DM·Player·Observer 접속
→ 실제 Player Client 창 종료
→ PlayerRemoving
→ 같은 논리 사용자 Connection=disconnected
→ Replacement Client 1개 추가
→ 새 Player Instance PlayerAdded
→ 같은 논리 사용자 재가입
→ Full Sync
```

완료 조건:

- 실제 `PlayerRemoving`과 `PlayerAdded` 발생
- Membership는 3개로 유지
- Physical Player Instance만 교체
- Connection은 `disconnected → connected`
- 같은 서버 AuthorityEpoch 유지
- Projection Sequence 증가
- 최종 `[RVTT Real Transport] ... result=PASS ... reconnects=1`

### Grand Persistence

`-IncludePersistence`가 명시된 전용 Milestone에서만 실행한다.

1. Live DataStore Baseline
2. Restart Seed Place
   - 자동 Flush를 끈 Dirty Snapshot 준비
   - Studio 종료 시 `BindToClose`
   - Bounded Retry·Deadline으로 저장
3. Restart Verify Place
   - 새 Studio Server에서 문서 Load·Restore
   - AuthorityEpoch 교체
   - 이전 Epoch Command `STALE_EPOCH`
   - 현재 Epoch Command 1회 Commit
   - Post-restart Snapshot 저장·Checkpoint 정리

## 4. Slices 02–12 자동 baseline 범위

| Slice | 구현된 자동 Scenario | 전체 Slice에서 아직 남은 범위 |
|---:|---|---|
| 02 | Ability Check·Save·Attack·HP·Authorization·Idempotency | 사용자 Flow·Roll Disclosure·Pending Recovery·Content Coverage |
| 03 | Interaction·Locked/Hidden Object·Search·Knowledge·Fog·Restore | 실제 WASD Navigation·Input Context·Projection Disclosure |
| 04 | Lifecycle·Initiative·Turn·Action·Rollback·End·Restore | Reaction·Objective·Death·Restart |
| 05 | Draft Validation·Ownership·Activation·Level Up·Restore | Compiler·Review·Sheet·Actor Binding·Migration |
| 06 | Item Create·Quantity Clamp·Ownership·Move·Equip·Drop·Restore | Stack·Slot Conflict·Streaming·World Presence·UI |
| 07 | Clock·Schedule·Activity·Ownership·Completion·Restore | Rest·Resource·Crafting·Travel·Restart |
| 08 | Preference Validation·User Isolation·Restore | Replica·Semantic Input·Reconciliation·Presentation·Human Accessibility |
| 09 | Document Ownership·Edit·Structured Link·Ping·Restore | Markdown·ACL Search·Backlink·Safe Navigation |
| 10 | Source·Stable Object·Candidate Invalidation·Compile·Publish·Restore | Editor Tool·Diagnostic·Test Play·Large Scene |
| 11 | Control·Quick Action·Runtime Patch·Recovery Request·Restore | Player View·Pause·Transition·Live Patch·Operator Recovery |
| 12 | Pack Rights·Dependency·Activation·Localization·Restore | Signing·Trust Host·Budget·Migration·Removal·Catalog Load |

자동 baseline은 전체 Slice 완료 판정이 아니다. 각 Slice Phase는 Manifest에서 계속 `planned`로 유지하며 남은 Gate를 `blocker`에 명시한다.

## 5. Cross-slice·Fault·Capacity 계약

### Cross-slice Session

```text
Character·Session·Scene
→ UI Preference
→ Original Content Pack
→ Scene Authoring·Compile·Publish
→ Journal
→ Loot·Equip
→ Exploration Interaction
→ Rules Check
→ Encounter Start·End
→ Time Activity
→ DM Quick Action
→ Snapshot·Restore
```

모든 Domain이 하나의 Revision Stream과 AuthorityEpoch를 공유하고 복구 후에도 Domain별 상태가 유지되는지 검사한다.

### Authority Fault

- Stale Revision 거부와 현재 Revision 반환
- Stale AuthorityEpoch 거부
- Invalid Payload 거부
- 동일 Command ID Replay의 멱등성
- Corrupt Snapshot Migration 실패와 현재 Runtime 보존
- Restore 후 AuthorityEpoch 갱신
- 이전 Epoch Command 폐기

### Deterministic Network Fault Host

- Projection Drop 뒤 Sequence Gap 감지와 Full Resync
- Duplicate Projection 무시와 False Gap 방지
- Hold·Reorder·Release 뒤 연속 Sequence 복구
- 새 AuthorityEpoch 전환 뒤 지연된 이전 Epoch Packet 폐기
- Terminal Receipt 유실 시 원본 Command ID로 최대 3회 전송
- 8초 이내 Terminal Receipt 미수신 시 retryable `CLIENT_TIMEOUT`
- Timeout 또는 Terminal Receipt 뒤 Pending Command 정리

### Deterministic Storage Fault Host

- Transient Load Failure 뒤 재시도
- Commit 전 Save Failure에서 Dirty Snapshot 보존
- Commit 뒤 Ack Loss에서 동일 Revision·Epoch 재저장 멱등성
- Revision Conflict에서 저장된 Winner 보존
- 외부 최신 Revision 뒤 더 높은 Revision으로 Reconcile
- 잘못된 Load Revision을 Saved Revision으로 인정하지 않음

### Real Transport Host

- Local Server의 실제 Player Instance 종료와 교체
- `PlayerRemoving` 기반 서버 권위 Disconnect Commit
- Replacement `PlayerAdded` 기반 Connected Commit
- 같은 논리 사용자 Membership 중복 방지
- 재접속 Full Sync와 Projection Sequence 연속성
- 같은 서버 내 AuthorityEpoch 불변

### Server Restart Host

- 자동 5초 Flush 없이 Shutdown-only Dirty Snapshot 생성
- `BindToClose`에서 최대 5회, 25초 Deadline, 지수 Backoff 저장
- retryable 실패 재시도
- non-retryable 실패 즉시 종료
- Retry 고갈 시 Dirty Snapshot 보존
- 새 서버에서 실제 DataStore 문서 복구
- 복구 후 AuthorityEpoch 교체와 이전 Epoch Command 폐기
- Post-restart Revision 단조 증가

### 아직 남은 실제 Fault Host

- Roblox 실제 Remote 지연·제한·대역폭 Throttle
- 강제 DataStore Throttle·Outage
- Cross-server Lease 획득·갱신·만료·탈취
- 두 서버 동시 Revision Conflict
- 운영자 Recovery Runbook

### Capacity Sample

임의 성능 PASS 기준은 아직 두지 않는다. 다음 구조적 정합성과 실제 측정값만 수집한다.

- Scene Object 32개
- Item 32개
- Journal Document 16개
- Snapshot Revision
- Scenario 전체 `elapsedMs`
- Restore `restoreMs`
- Snapshot·Restore 후 개수 보존

## 6. 현재 Studio Evidence

```text
Unit·Integration
→ passed=173 failed=0 · HISTORICAL

Live DataStore
→ passed=10 failed=0 · HISTORICAL

3-client MultiClient
→ passed=56 failed=0 clients=3 staleRetries=3 · HISTORICAL

Slice 01 Token Pick·Move·Projection
→ USER VERIFIED

Camera Zoom
→ USER VERIFIED

Camera WASD·Middle-button·Frame
→ LATEST CORRECTION STUDIO RETEST PENDING

Slices 02–12·Cross-slice·Authority Fault·Capacity
→ NEW STUDIO EVIDENCE NONE

Deterministic Network·Storage Fault Host
→ NEW STUDIO EVIDENCE NONE

Real Player Disconnect·Reconnect Host
→ NEW STUDIO EVIDENCE NONE

BindToClose·Two-run Server Restart Host
→ NEW STUDIO EVIDENCE NONE
```

기존 Camera 메서드 직접 호출로 생성된 Slice 01 `16/16 PASS`는 실제 입력 Evidence로 사용하지 않는다.

## 7. 자동 Gate 결과

현재 Grand Harness 정적 검증:

- Grand Contract Validator: PASS
- Structure·Security·Policy Validator: PASS
- Windows PowerShell Parser: PASS
- Grand Manifest SelfTest: PASS
- StyLua: PASS
- Selene: PASS
- Production·Test·Grand Single-client·Multi-client·Real Transport·Persistence·Restart Seed·Restart Verify·Slice01 Rojo Build: PASS
- Production·Test Luau Type Analysis: PASS
- Documentation Validation: PASS

위 결과는 Source·Build·Type Evidence이며 실제 Studio Runtime PASS를 대신하지 않는다.

## 8. 다음 구현 순서

| 순서 | 상태 | 작업 | 완료 조건 |
|---:|---|---|---|
| 1 | DONE | Grand Runner Foundation | Grouped Studio Run·Log Collection·JSON/Markdown Report |
| 2 | DONE | Slices 02–12 Automated Baseline | 11개 Slice Scenario와 Spec별 Summary 등록 |
| 3 | DONE | Cross-slice Authority Scenario | Full-session State 연결과 Restore 검사 |
| 4 | DONE | Authority Fault Baseline | Stale·Duplicate·Epoch·Corrupt Restore 검사 |
| 5 | DONE | Capacity Measurement Sample | 구조적 개수와 시간 Evidence 출력 |
| 6 | DONE | Deterministic Fault Host | Network Drop·Duplicate·Reorder·Receipt Loss·Storage Failure·Ack Loss·Conflict |
| 7 | DONE | Real Transport·Restart Host | 실제 Player Lifecycle·BindToClose Retry·두 서버 Restore 등록 |
| 8 | IN_PROGRESS | DataStore Outage·Lease Host | 강제 실패·Cross-server Lease·동시 Conflict Evidence |
| 9 | QUEUED | Persistence Grand Milestone | 게시 Experience에서 Live·Seed·Verify·Outage·Lease 일괄 실행 |
| 10 | QUEUED | UI·Accessibility Evidence | Human Checklist와 Screenshot Reference 수집 |
| 11 | BLOCKED | Slices 13–15 Content | Source Version·Rights·Distribution·Asset 승인 |
| 12 | QUEUED | Performance·Soak Host | 측정 Budget·다중 Client·장시간 Session |
| 13 | QUEUED | Slice 16 Release Campaign | 전체 Phase·Migration·Runbook Gate |

## 9. 다음 Gate

```text
Real Transport·Restart Host 자동 Gate
→ PASS

실제 Studio Runtime
→ 아직 실행하지 않음

Forced DataStore Outage·Cross-server Lease Host
→ 구현 진행

Grand Persistence·Human UI·Soak Phase
→ 이후 연결

Full Grand Campaign
→ 실행할 모든 대상 Phase가 READY인 Milestone에서 한 번 실행
```
