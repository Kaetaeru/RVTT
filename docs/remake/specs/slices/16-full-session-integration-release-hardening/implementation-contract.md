# Implementation Spec — Slice 16 Full-session Integration·Release Hardening

- 상태: SPEC_CHECKPOINT_COMPLETE
- 문서 종류: Release Integration Implementation Spec
- 구현 상태: 미구현
- 즉시 구현 명세 가능성: BLOCKED
- 작성일: 2026-08-05
- 차단 이유: Slice 01–15 Production Code·Migration·Roblox Integration Evidence가 없고 공식 Content Data·Rights Review가 미완료다.
- Work Order: [`CURRENT-WORK-ORDER.md`](CURRENT-WORK-ORDER.md)
- Roadmap: [`SLICE-ROADMAP.md`](../../SLICE-ROADMAP.md)
- 관련 Guide: [`Main System Guide Hub`](../../../guides/README.md) — 12개 Guide 전체
- 관련 Runtime: [`Diagnostics`](../../../architecture/diagnostics-observability-correlated-trace-and-incident-runtime-contract.md), [`Simulation`](../../../architecture/deterministic-simulation-scenario-and-test-harness-runtime-contract.md), [`Persistence`](../../../architecture/persistence-and-session-recovery-model.md), [`Networking`](../../../architecture/networking-command-event-and-client-synchronization-contract.md), [`Transaction`](../../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md), [`Domain Event`](../../../architecture/domain-event-outbox-subscription-and-projection-runtime-contract.md)

> 이 Slice는 새로운 Gameplay 기능을 추가하지 않는다. 앞선 Slice의 계약과 실제 구현 Evidence를 하나의 장시간 세션·Migration·Fault·Security·Performance·Operations Release Gate로 검증한다.

## 1. Release Acceptance Flow

### Player

```text
Campaign 참가·Character 선택
→ Scene 탐험·상호작용·판정
→ Encounter·Loot·Inventory
→ Rest·Level Up·Journal·Scene Transition
→ Disconnect·Reconnect
→ Server Restart 이후 Resume
→ Rollback 이후 새 Branch에서 진행
→ Session 종료·다음 Session Resume
```

### DM

```text
Content·Character·Scene 준비
→ Player Join·Control·Fog·Encounter 진행
→ Journal·Downtime·Scene Authoring·Quick Edit
→ Save·Checkpoint·Live Patch·Recovery Review
→ Rollback·Resume
→ 정상 Shutdown·다음 Boot 검증
```

Release Acceptance는 화면 동작만이 아니라 State·Event·Projection·Trace·Storage Artifact와 User Guide 결과를 함께 검증한다.

## 2. 범위

포함:

- Slice 01–15 Cross-Slice Contract·State Ownership·Version Matrix
- 전체 Player·DM Acceptance와 Failure·Recovery Suite
- Schema·Content Pack·Scene Build·Character Build Migration
- Network Drop·Duplicate·Reorder·Latency·Reconnect
- Storage Limit·Chunk·Retry·Commit Point·Restart·Recovery Review
- Player·DM·Observer·Role Change Permission Matrix
- 장시간 Session·다중 Client·대형 Scene·대규모 Content Soak
- Performance·Memory·Network·Instance·DataStore Budget
- Accessibility·Reduced Motion·Low-end Fallback·Input Context
- Security·Rate Limit·Payload·Abuse·Mandatory Audit·Incident Replay
- Deployment·Rollback·Runbook·Support Artifact·Release Checklist

제외:

- 이 단계에서 발견된 새 기능을 Release 범위에 몰래 추가
- 측정 없이 성능·안정성 통과 선언
- Rights Review 미완료 Content·Asset 배포
- 실패한 Slice를 `DEFERRED` 기록 없이 우회

## 3. Cross-Slice Contract Matrix

각 Stable Entity·State의 단일 소유자를 고정한다.

| 영역 | Authority 원본 | 주요 Version·Revision | 다른 Slice가 소유하지 않는 값 |
|---|---|---|---|
| Campaign·Session | Session State | AuthorityEpoch·Session Revision | Character Source·Scene Source |
| Character | Source·Build Ref·Persistent State | Source·Build·State Revision | Actor Transform·Item Location |
| Actor | Actor State·Scene Binding | Actor Build·Instance·Incarnation | Character Source·Encounter Timeline |
| Item | ItemInstance·Location Binding | Definition·Instance·Binding Revision | Workspace Model·Character Source |
| Scene | Scene Source·Published Build·Runtime State | Source·Build·Runtime Incarnation | Client Workspace Snapshot |
| Rules | Policy Snapshot·RuleExecution·RollRecord | Policy·Recipe·Execution Version | HP·Item·Encounter Store 직접 Mutation |
| Encounter | Timeline·Cursor·Opportunity·Objective | Timeline·Occurrence·Turn Revision | HP·Position·Item 복사본 |
| Time·Downtime | Campaign Time·Activity Record | Time·Progress·Reservation Revision | 현실 시간·Character Store 직접 Mutation |
| Journal | Document Source·Compiled Build·ACL | Source·Build·ACL Revision | Recovery Journal·Domain State |
| Client | Projection Replica·Local Preference | Projection Epoch·Sequence | Raw Authority State |

같은 의미의 ID·Revision·Error·Command·Projection Schema가 Slice마다 다른 이름이나 직렬화로 중복되지 않는지 자동 검사한다.

## 4. Full-session Scenario Catalog

최소 Release Scenario:

1. 새 Campaign·Character·Scene·Content 생성과 첫 Join.
2. Exploration 이동·Door·Search·Trap·Fog.
3. Ability Check·Attack·Save·Damage·Healing.
4. Encounter Initiative·Turn·Reaction·End.
5. Loot·Equip·Drop·Item World Presence.
6. Short·Long Rest·Level Up·Preparation·Travel.
7. Journal Search·World Link·Ping.
8. Scene Candidate Compile·Publish와 새 Session 진입.
9. Live DM Quick Edit·Control·Scene Transition.
10. Disconnect·Reconnect 중 Pending Prompt·Movement·Reaction.
11. Commit 전·중·후 Server Restart.
12. Encounter·Session Rollback과 이전 Epoch 입력 차단.
13. Normal Shutdown과 다음 Boot Resume.
14. Role Change·Observer·DM Takeover와 Disclosure.

각 Scenario는 다음 Artifact를 비교한다.

```text
Authoritative State Digest
Domain Event·Outbox Sequence
Permission-aware Projection Digest
Persistence Snapshot·Journal Marker
Correlated Trace·Decision Record
User-visible Acceptance Result
```

## 5. Migration·Upgrade Matrix

지원 변환 축:

- Schema Version
- Ruleset·Policy Snapshot Version
- Content Pack·Definition·Recipe·Handler Version
- Character Source·Build·State
- Item Definition·Instance·Location
- Scene Source·Compiled Build·Runtime Mapping
- Journal Source·Compiled Build·Anchor
- Snapshot Manifest·Chunk·Journal

```text
Current Release Data
→ Target Version Compatibility Scan
→ Candidate Migration
→ Validation·Dry Run·Diff
→ Backup·Checkpoint
→ Atomic Activation 또는 Maintenance Gate
→ Post-migration Scenario
→ Rollback 가능성 확인
```

Migration 실패 시 일부 Domain만 최신 Version으로 활성화하지 않는다. exact Version이 없으면 자동 최신 대체 대신 Maintenance·Read-only Recovery·DM Review를 사용한다.

Legacy Migration은 실제 기존 데이터 조사 후 별도 Mapping Table과 Tombstone 정책을 가진다.

## 6. Network·Storage·Restart Fault Suite

Network Fault:

- Command·Receipt·Result·Projection Drop·Duplicate·Reorder
- Latency·Burst·Reconnect·Connection Epoch 변경
- Projection Gap·Catch-up·Full Resync
- Presentation ACK 유실

Storage Fault:

- Manifest·Chunk 일부 실패
- Journal Flush·Commit Marker 경계
- DataStore Throttle·Retry·Timeout
- Writer Lease 충돌
- Snapshot 이후 Journal Replay
- 저장 한도 초과와 Chunk Split

Restart Point:

- Command 검증 전
- Transaction Prepare 중
- State Commit 직후 Outbox 전송 전
- Projection Publish 전후
- Snapshot 쓰기 중
- Migration Activation 전후

모든 Fault는 부분·중복 Commit, Reservation Leak, 이전 Epoch 재실행과 숨은 데이터 누출이 없는지 검사한다.

## 7. Permission·Disclosure Matrix

Viewer:

```text
owner_player | other_player | dm | observer | disconnected_user | role_changed_user
```

대상:

- Character Source·State·Inventory
- Hidden Actor·Secret Object·Trap·Fog·Knowledge
- Encounter Reserve·Objective·Modifier·Roll
- Journal Document·Search·Backlink·Anchor
- Scene Source·Diagnostic·Content Lineage
- DM Workspace·Recovery·Audit·Incident
- Item Identification·Loot·Spell·NPC Statblock

Secret Canary를 Raw Payload, Error, Count, Cache, Tooltip, Camera Target, VFX Anchor, Diagnostic와 Support Artifact에 삽입해 누출을 자동 탐지한다.

Role 축소와 Rollback 후 이전 Client Cache·Focus·Prompt·Read Result가 제거되는지 검증한다.

## 8. Performance·Soak·Capacity

프로파일:

- 최소 지원 PC
- 기준 PC
- 개발·운영 고성능 환경

측정 대상:

- Server Frame·Command·Transaction·Projection Latency
- Client Frame·UI Commit·Camera·Presentation Cost
- Memory·Instance·Connection·Task·Cache
- Network Payload·Batch·Catch-up·Resync
- DataStore Read·Write·Chunk·Snapshot·Journal
- Large Scene Spatial·Navigation·Streaming·Compiler
- Character·Item·Effect·Encounter·Journal·Catalog 규모

Soak:

```text
장시간 Session
+ 반복 Scene Transition·Encounter·Rest
+ Join·Leave·Reconnect
+ Save·Snapshot·Restart
+ Content·Build Version 전환
→ Leak·Drift·Queue·Retry·Dead Letter·Digest 검사
```

구체 Threshold는 실제 Profiling과 지원 환경 합의 후 Versioned Release Profile로 고정한다. Headless Logical Cost와 Roblox 실제 Timing을 같은 값으로 취급하지 않는다.

## 9. Accessibility·Low-end Gate

검사:

- Reduced Motion·Camera Shake·Flash Hard Limit
- Text Scale·Contrast·Focus·Keyboard-only 흐름
- Q·E·1–5 Context 단일 소비
- Low-end에서 필수 Prompt·Reveal·Warning 유지
- Loading·Waiting·Denied·Retrying·Resync·Recovery 안내
- 긴 Session 후 Focus·Panel·Input Leak 없음

접근성 설정은 DM·Presentation Recipe가 우회하지 못한다. Quality Degradation이 Gameplay 결과·공개 시점의 최소 판독성을 손상시키면 Release Blocker다.

## 10. Security·Abuse·Incident

검사:

- Remote·Command Permission·Revision·Payload·Rate
- Import JSON·Markdown·Content Pack·Asset Ref
- DM Override·Migration·Recovery Mandatory Audit
- Idempotency Key·Replay·Previous Epoch
- Resource Reservation Exhaustion
- Query·Search·Preview Side Channel
- Diagnostic·Incident·Support Redaction
- Trusted Extension Capability·Budget·Failure Isolation

Incident 흐름:

```text
Correlated Trace·Health·Alert
→ Redacted Incident Bundle
→ Minimal Reproduction Scenario
→ Deterministic Replay
→ Regression Catalog
→ PR·Release Suite 승격
```

Production Root Seed, Credential와 사용자 원문을 Scenario에 포함하지 않는다.

## 11. Release Artifact와 Runbook

필수 Artifact:

- Release Version·Commit·Schema·Pack·Build Matrix
- Migration Plan·Dry-run Result·Rollback Point
- Coverage Matrix·Rights Review Summary
- Deterministic·Roblox Integration·Soak Report
- Performance·Memory·Network Budget Report
- Permission·Security·Accessibility Report
- Known Issue·Deferred Slice·Risk Register
- Operational Runbook·Recovery Review 절차
- Support Reference·Incident Bundle 절차

Runbook:

- Deploy·Health Check·Canary
- Maintenance Gate·Migration
- Rollback·Branch Recovery
- DataStore·Writer Lease·Snapshot 문제
- Projection Gap·Reconnect 장애
- Content·Scene Build·Extension Failure
- Security·Disclosure Incident
- Normal Shutdown·Emergency Stop

## 12. Release Gate

Release Candidate는 다음을 모두 만족해야 한다.

- Slices 01–15 Production Build Acceptance 완료 또는 명시적 `DEFERRED`
- 모든 Active Schema·Pack·Build·Content Version 추적 가능
- 전체 Acceptance·Fault·Disclosure·Migration Suite 통과
- 지원 환경 Performance·Soak·Accessibility Gate 통과
- 알려진 데이터 손실·권한 누출·중복 Commit Blocker 없음
- Rights Review가 필요한 Content·Asset 승인 완료
- User Guide가 실제 Build 기준 `CURRENT_FOR_BUILD`
- Deployment·Rollback·Recovery Runbook 검증

실패 항목은 Severity·Owner·재현·완화·Release Decision을 기록한다. 테스트 미실행을 성공으로 해석하지 않는다.

## 13. Test·Implementation 순서

```text
Cross-Slice Schema·Ownership Matrix
→ Canonical Full-session Scenarios
→ Migration·Upgrade Matrix
→ Network·Storage·Restart Faults
→ Permission·Security Matrix
→ Performance·Soak·Accessibility
→ Incident Replay·Regression
→ Release Artifact·Runbook Drill
→ Production Completion Audit
```

Spec 완료 기준:

- 앞선 15개 Slice가 하나의 Session 흐름으로 연결된다.
- 모든 Authority 원본과 Version 소유자가 하나다.
- Migration·Fault·Disclosure·Performance·Operations Gate가 실행 가능한 형태로 정의된다.
- Release 성공을 증명할 Artifact와 Runbook이 명확하다.

현재는 명세 체크포인트만 완료됐다. Production Evidence가 없으므로 Release Ready를 주장하지 않는다.