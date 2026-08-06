# RVTT Roblox Implementation 현재 작업 순서

- 상태: `GRAND_PRODUCTION_LEASE_FENCED_PERSISTENCE_STATIC_VERIFIED`
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

Deterministic Network·Storage Fault Host
→ IMPLEMENTED · STATIC VERIFIED · STUDIO NOT EXECUTED

Real Player Disconnect·Reconnect Host
→ IMPLEMENTED · STATIC VERIFIED · STUDIO NOT EXECUTED

BindToClose·Two-run Server Restart Host
→ IMPLEMENTED · STATIC VERIFIED · PUBLISHED STUDIO NOT EXECUTED

Injected DataStore Outage Host
→ IMPLEMENTED · STATIC VERIFIED · PUBLISHED STUDIO NOT EXECUTED

Cross-server Lease Holder·Contender Pair Host
→ IMPLEMENTED · STATIC VERIFIED · PUBLISHED STUDIO NOT EXECUTED

Production ServerBoot Lease Ownership·Atomic Fence Claim
→ IMPLEMENTED · STATIC VERIFIED · PUBLISHED STUDIO NOT EXECUTED

현재 작업
→ Production Lease Integration Acceptance Host 연결
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

사용자는 하나의 완전한 Windows PowerShell 블록을 한 번 실행한다. Runner는 같은 `runId`와 실행 계약을 공유하는 Phase를 묶고, Studio 종료 후 다음 실행 그룹으로 진행한다. `studio-published-pair`는 서로 다른 두 Place를 동시에 열고 각 Summary를 독립 판정한다.

## 3. 현재 Grand 실행 그룹

### `grand-single-client`

- 기존 Unit·Integration·Security·Disclosure Source
- Slice 01 실제 WASD·중클릭·F·휠·Token 이동 Acceptance
- Slices 02–12 서버 권위 자동 Scenario
- Cross-slice Full-session·Authority Fault
- 결정적 Network Drop·Duplicate·Hold·Reorder·Delayed Epoch
- Terminal Receipt 유실·동일 Command ID 재전송·Bounded Timeout
- Storage Failure·Ack Loss·Revision Conflict·External Winner
- Shutdown Persistence Retry와 Production Lease·Fence Unit Scenario
- Capacity Sample

### `grand-multi-client`

- DM·Player·Observer Authority
- Viewer별 Projection과 Negative Disclosure
- Stale Revision Recovery
- 기존 논리적 Connection State 전환과 Full Resync

### `grand-real-transport`

```text
DM·Player·Observer 접속
→ 실제 Player Client 창 종료
→ PlayerRemoving
→ 같은 논리 사용자 Connection=disconnected
→ Replacement Client 1개 추가
→ 새 PlayerAdded
→ 같은 논리 사용자 재가입
→ Full Sync
```

### Grand Persistence

`-IncludePersistence` 전용 Milestone에 다음 환경이 등록되어 있다.

1. Live DataStore Baseline
2. Restart Seed
   - Shutdown-only Dirty Snapshot
   - `BindToClose` Bounded Retry 저장
3. Restart Verify
   - 새 서버 Restore
   - AuthorityEpoch 교체와 이전 Epoch 거부
4. Injected DataStore Outage
   - 실제 DataStore 호출 직전에 장애를 주입
   - Retry 고갈과 Dirty 보존
   - 장애 해제 후 실제 DataStore 저장·재로드
5. Cross-server Lease Pair
   - Holder·Contender 두 Studio Place 동시 실행
   - 활성 Lease 두 번 차단
   - 만료 후 더 높은 Fencing Token으로 Contender 인수
6. Production Lease Integration Acceptance
   - 안전한 전용 Store·Key를 사용하는 실제 `ServerBoot`
   - Acquire→Atomic Fence Claim→Load
   - Commit·Fenced Flush·Release
   - 다음 Server의 더 높은 Fence Claim·Restore
   - 이전 Fence 지연 Save 거부

6번 Host는 아직 구현 중이므로 전체 Grand Persistence 사용자 실행은 보류한다.

## 4. Slices 02–12 자동 baseline 범위

| Slice | 구현된 자동 Scenario | 전체 Slice에서 아직 남은 범위 |
|---:|---|---|
| 02 | Ability Check·Save·Attack·HP·Authorization·Idempotency | 사용자 Flow·Roll Disclosure·Pending Recovery·Content Coverage |
| 03 | Interaction·Locked/Hidden Object·Search·Knowledge·Fog·Restore | 실제 Navigation·Input Context·Projection Disclosure |
| 04 | Lifecycle·Initiative·Turn·Action·Rollback·End·Restore | Reaction·Objective·Death·Restart |
| 05 | Draft Validation·Ownership·Activation·Level Up·Restore | Compiler·Review·Sheet·Actor Binding·Migration |
| 06 | Item Create·Quantity Clamp·Ownership·Move·Equip·Drop·Restore | Stack·Slot Conflict·Streaming·World Presence·UI |
| 07 | Clock·Schedule·Activity·Ownership·Completion·Restore | Rest·Resource·Crafting·Travel·Restart |
| 08 | Preference Validation·User Isolation·Restore | Replica·Semantic Input·Reconciliation·Presentation·Human Accessibility |
| 09 | Document Ownership·Edit·Structured Link·Ping·Restore | Markdown·ACL Search·Backlink·Safe Navigation |
| 10 | Source·Stable Object·Candidate Invalidation·Compile·Publish·Restore | Editor Tool·Diagnostic·Test Play·Large Scene |
| 11 | Control·Quick Action·Runtime Patch·Recovery Request·Restore | Player View·Pause·Transition·Live Patch·Operator Recovery |
| 12 | Pack Rights·Dependency·Activation·Localization·Restore | Signing·Trust Host·Budget·Migration·Removal·Catalog Load |

자동 baseline은 전체 Slice 완료 판정이 아니다.

## 5. Fault·Persistence 계약

### Deterministic Network·Storage

- Projection Drop·Duplicate·Hold·Reorder·Gap·Full Resync
- 지연된 이전 AuthorityEpoch 폐기
- Terminal Receipt 유실·Bounded Retry·Timeout
- Load·Save Failure·Commit Ack Loss·Revision Conflict·External Winner

### Real Transport·Restart

- 실제 `PlayerRemoving`·`PlayerAdded`
- 논리 사용자 Membership 중복 방지
- Shutdown-only Dirty Snapshot
- `BindToClose` 최대 5회·25초 Deadline
- 새 서버 Restore·Epoch 교체·이전 Epoch 거부

### Injected DataStore Outage

- 장애 구간은 `GetAsync`·`UpdateAsync` 호출 전에 명시적으로 주입한다.
- 주입 중에는 retryable `PERSISTENCE_FAILED`를 반환한다.
- Retry 고갈 뒤 Dirty Snapshot과 `lastSavedRevision`을 보존한다.
- 장애 해제 뒤 Production `ProfileStore`를 통해 실제 DataStore에 저장하고 재로드한다.
- 이 Host는 Roblox 플랫폼 자체 장애를 발생시키거나 증명하지 않는다.

### Lease Store·Coordinator

- Lease Record: `ownerId`, `token`, `expiresAt`, `fencingToken`
- 활성 Lease 충돌: retryable `LEASE_HELD`
- 만료·탈취 뒤 이전 소유자: `LEASE_LOST` 또는 `LEASE_EXPIRED`
- Renew는 Fencing Token을 유지한다.
- Takeover·Release 후 Reacquire는 Fencing Token을 증가시킨다.
- DataStore 호출 실패는 retryable `PERSISTENCE_FAILED`다.

### Production ServerBoot Lease Ownership

```text
Lease Acquire
→ Lease Store Remote Verify
→ Authority Document Atomic Fence Claim
→ Claim된 최신 Document Load·Restore
→ Local Lease Command Guard
→ Background Renew
→ Flush 전 Remote Verify·Write Fence
→ BindToClose Fenced Flush
→ Lease Release
```

- Persistence 활성 환경은 Lease를 얻기 전에 Authority 문서를 Load하지 않는다.
- `ProfileStore.loadFenced`는 기존 문서를 보존하면서 `persistenceFence`를 같은 `UpdateAsync`에서 Claim한다.
- Runtime으로 반환할 때 `persistenceFence`는 제거되어 Domain State와 저장 메타데이터가 분리된다.
- Claim 이후 낮은 Fencing Token, 같은 Token의 다른 소유자, Unfenced Writer는 `PERSISTENCE_FENCED`다.
- 현재 소유자도 Revision·AuthorityEpoch 단조성 검사를 우회하지 않는다.
- Remote·System Command는 Persistence 준비 전이나 Lease Lost 뒤 실행되지 않는다.
- Retryable Renew 장애는 Local Expiry 전까지만 소유권을 유지하고 Terminal Lease 오류는 즉시 Degrade한다.
- Shutdown은 Renew 중단→Fenced Flush→Release 순서다.

### Cross-server Lease Pair

- Holder와 Contender가 동일한 실제 DataStore Lease Key를 사용한다.
- Contender는 Holder 활성·갱신 기간에 두 번 차단된다.
- Holder가 갱신을 중단하고 만료되면 Contender가 더 높은 Fencing Token으로 인수한다.
- 이전 Holder는 인수 후 Lease 검증과 해제를 수행할 수 없다.
- 두 Studio Summary를 같은 `runId`에서 독립 판정한다.

### 아직 남은 Production 경계

- Production `ServerBoot` Store·Key를 안전한 Acceptance 전용 값으로 주입하는 Project Config
- 실제 Seed Server의 Command Commit·Fenced Flush·Release
- 다음 Server의 Higher Fence Claim·Restore
- Claim 이후 이전 Fence Revision 99 지연 Save 거부의 Published Evidence
- Lease 미획득·Lease Lost 사용자 상태와 운영자 Recovery UX
- Roblox 실제 Remote 지연·대역폭 Throttle
- Roblox 플랫폼 자체 DataStore 장애 Evidence
- 운영자 Recovery Runbook

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

Slices 02–12·Deterministic Fault·Real Transport·Restart
→ NEW STUDIO EVIDENCE NONE

Injected Outage·Cross-server Lease Pair
→ NEW STUDIO EVIDENCE NONE

Production Lease Ownership·Atomic Fence Claim
→ STATIC VERIFIED · NEW STUDIO EVIDENCE NONE
```

정적 Gate를 Studio Runtime PASS나 Roblox 플랫폼 장애 PASS로 해석하지 않는다.

## 7. 자동 Gate 결과

- Production Lease Contract Validator: PASS
- Grand Contract Validator: PASS
- Structure·Security·Policy Validator: PASS
- Windows PowerShell Parser·Runner SelfTest: PASS
- StyLua: PASS
- Selene: PASS
- Production·Test·Grand Single-client·Multi-client·Real Transport·Persistence·Restart Seed·Restart Verify·DataStore Outage·Lease Holder·Lease Contender·Slice01 Rojo Build: PASS
- Production·Test Luau Type Analysis: PASS
- Documentation Validation: PASS

위 결과는 Source·Build·Type Evidence다.

## 8. 다음 구현 순서

| 순서 | 상태 | 작업 | 완료 조건 |
|---:|---|---|---|
| 1 | DONE | Grand Runner Foundation | Grouped Studio Run·Log Collection·JSON/Markdown Report |
| 2 | DONE | Slices 02–12 Automated Baseline | 11개 Slice Scenario와 Spec별 Summary 등록 |
| 3 | DONE | Cross-slice·Authority Fault·Capacity | Full-session State·Stale/Epoch·측정 Sample 등록 |
| 4 | DONE | Deterministic Fault Host | Network·Storage 결정적 장애 계약 |
| 5 | DONE | Real Transport·Restart Host | 실제 Player Lifecycle·Shutdown Retry·두 서버 Restore 등록 |
| 6 | DONE | DataStore Outage·Lease Pair Host | 주입 장애 복구·Lease Fencing·두 서버 동시 Pair 등록 |
| 7 | DONE | Production Lease Ownership Integration | Acquire·Atomic Claim·Guard·Renew·Fenced Save·Flush-before-Release |
| 8 | IN_PROGRESS | Production Lease Integration Acceptance Host | 안전한 Test Key의 실제 ServerBoot Seed·Takeover·Stale Write Evidence |
| 9 | QUEUED | Persistence Grand Milestone | Live·Restart·Outage·Lease·Production Boot 일괄 게시 Studio 실행 |
| 10 | QUEUED | UI·Accessibility Evidence | Human Checklist·Screenshot Reference |
| 11 | BLOCKED | Slices 13–15 Content | Source Version·Rights·Distribution·Asset 승인 |
| 12 | QUEUED | Performance·Soak Host | 측정 Budget·다중 Client·장시간 Session |
| 13 | QUEUED | Slice 16 Release Campaign | 전체 Phase·Migration·Runbook Gate |

## 9. 다음 Gate

```text
Production Lease·Atomic Fence Claim 자동 Gate
→ PASS

Production Lease Integration Acceptance Host
→ 구현 진행

Grand Persistence Runtime
→ 사용자 실행 보류

Human UI·Soak Phase
→ 이후 연결

Full Grand Campaign
→ 실행할 대상 Phase가 READY인 Milestone에서 한 번 실행
```
