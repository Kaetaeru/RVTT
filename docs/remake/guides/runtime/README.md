# Main System Guide: Runtime Foundation과 Authority

- Guide Status: CURRENT
- 적용 시스템 상태: GUIDE_CURRENT
- 작성일: 2026-08-04
- 마지막 권위 문서 검토일: 2026-08-05
- Completion Audit: [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)
- 대체하는 Guide: 없음
- 대체된 Guide: 없음

> 이 Guide는 기존 권위 문서를 연결하고 설명한다. 새로운 규칙·결정·API·데이터 구조를 정의하지 않는다.

## 1. 시스템 목적과 사용자 결과

Runtime Foundation은 공격, 이동, Scene 편집, Character 성장처럼 특정 기능 하나가 아니다. 모든 RVTT 시스템이 같은 권위·버전·명령·저장·공개 원칙을 사용하도록 만드는 공통 기반이다.

사용자에게 보장하는 결과:

- 플레이어와 DM이 같은 행동을 두 번 제출해도 권위 결과가 중복 적용되지 않는다.
- 피해, 자원 소비, 상태 변경과 Encounter 결과가 부분적으로만 남지 않는다.
- UI, VFX, Roblox Physics와 Workspace Instance가 게임 규칙의 원본이 되지 않는다.
- 진행 중 행동은 시작 당시의 Ruleset·Policy·Build를 유지한다.
- 재접속, 서버 재시작과 Rollback 후에도 오래된 Command·Prompt·Subscriber가 새 Branch에 적용되지 않는다.
- 플레이어는 자신에게 공개 가능한 Projection만 받고, 숨은 정보는 Client·검색·진단 자료에도 포함되지 않는다.
- 오류가 발생하면 Command부터 Transaction·Event·Projection까지 같은 Trace로 추적할 수 있다.
- 테스트는 별도 규칙 엔진이 아니라 Production Runtime 경로를 그대로 실행한다.

명시적 비범위:

- D&D 개별 주문·특성·몬스터 규칙
- 화면별 배치와 시각 디자인
- 구체적인 Roblox Module·Type·Remote 이름
- 아직 확정되지 않은 Implementation Spec의 최종 파일 구조

## 2. 전체 구조

```text
Authoring·Persistent Source
→ Compiler·Resolver
→ Immutable Compiled Build

Frozen Policy Snapshot
+ Versioned Authoritative State
+ Runtime Identity·Revision
→ Runtime Snapshot
```

권위 상태 변경:

```text
Player·DM·System Intent
→ Versioned Command
→ Authorization·Validation
→ RuleExecution 또는 Domain Operation
→ Cross-Domain Outcome Plan
→ Ordering Reservation
→ Authority Transaction
→ State Commit + Journal + Domain Event Outbox
→ Permission-aware Projection
→ ViewModel·UI·Presentation
```

복구와 검증:

```text
Validated Snapshot Manifest
+ Commit Journal
+ Build·Content Migration
→ Authoritative State 재구성
→ 새 AuthorityEpoch
→ Derived Index·Projection 재생성
→ Client Resync
```

```text
Production Runtime
+ Deterministic Adapter
→ Scenario 실행
→ State·Event·Projection·Trace Assertion
```

### 핵심 구성 요소

- **Source**: DM 저작 내용, Character 성장 선택, Rules Content처럼 장기 수정 가능한 원본이다.
- **Compiled Build**: Source를 검증·정규화한 불변 실행 자료다.
- **Authoritative State**: 현재 HP, 위치, 아이템, Effect, Encounter와 같은 변경 가능한 권위 상태다.
- **Frozen Policy Snapshot**: 진행 중 실행이 사용할 Ruleset·Campaign·Scope Policy 조합이다.
- **Command**: Client·DM·System의 변경 의도를 서버에 제출하는 버전된 요청이다.
- **RuleExecution**: 선택, 굴림, 반응과 TimingWindow를 포함할 수 있는 장기 규칙 실행이다.
- **Transaction**: 여러 Domain 변경을 하나의 Commit 또는 전체 Abort로 확정한다.
- **Domain Event**: Commit이 끝난 과거 사실이며 후속 Command와 Projection의 원인이 된다.
- **Projection**: 역할·권한·지식에 맞게 만들어진 Client-safe View다.
- **Presentation**: Camera, Animation, VFX와 UI 표현이며 Gameplay Authority를 변경하지 않는다.
- **Diagnostics**: 권위 결과를 관찰하고 설명하지만 결과를 생성하거나 수정하지 않는다.

## 3. 주요 데이터 흐름

### 3.1 Source, Build와 State

```text
Editable Source
→ Compiler Validation
→ Candidate Immutable Build
→ Migration Plan
→ Atomic Activation
```

- Source와 Build를 같은 Table로 사용하지 않는다.
- Build Compile 실패 시 활성 Build와 세션은 Last Known Good를 유지한다.
- 현재 HP, 남은 자원과 활성 Effect 같은 Live State를 Build에 넣지 않는다.
- Build 교체가 State 의미를 바꾸면 명시적 Migration을 거친다.

### 3.2 Identity와 Version

장기 권위 객체는 가능한 범위에서 다음을 가진다.

```text
stableId
+ incarnation 또는 contentVersion
+ authorityEpoch
+ revision
+ lifecycleState
```

- Stable ID를 배열 위치, 표시 이름이나 Workspace 경로로 대체하지 않는다.
- 같은 ID의 새 Incarnation이 오래된 참조를 자동 승계하지 않는다.
- Rollback과 Recovery는 새 `authorityEpoch`를 발급해 이전 Branch 입력을 차단한다.

### 3.3 Policy

```text
Product Safe Default
+ Ruleset Policy Pack
+ Campaign Binding
+ Scene·Encounter·Downtime Scope Binding
→ Frozen Policy Snapshot
```

Character·Item·Effect의 일시적 Rule Override는 전역 Snapshot을 수정하지 않고 현재 Execution의 Effective Policy View에 기여한다.

### 3.4 Projection

```text
Raw Authority State
+ Role·Permission·Ownership
+ Visibility·Knowledge·Disclosure
→ Permission-aware Projection
→ Atomic Client Replica
→ Derived ViewModel
```

Client는 전체 Raw State를 받은 뒤 버튼이나 필드를 숨기는 방식으로 권한을 구현하지 않는다.

### 3.5 저장과 파생 자료

권위 저장 대상:

- Source와 활성 Build Reference
- Authoritative State와 Runtime Identity
- Pending RuleExecution과 Resource Reservation
- Encounter·Downtime·Scheduler 상태
- Commit Journal, Branch와 AuthorityEpoch

다시 만들 수 있는 파생 자료:

- Spatial·Navigation·Query Index
- Projection·ViewModel Cache
- Presentation Model, VFX, Tween과 Camera 상태
- 진단용 집계와 성능 Metric

## 4. 주요 실행 흐름

### 4.1 일반 Command

```text
Intent
→ Command Envelope 검증
→ Authorization
→ Domain Validation
→ Ordering Key 계산
→ Transaction Plan
→ 최신 Revision·Precondition 재검증
→ Atomic Commit
→ Command Result + Projection Event
```

Client Timestamp와 Remote 도착 순서는 권위 순서를 결정하지 않는다.

### 4.2 선택·굴림·반응이 있는 실행

```text
Command
→ Persistent RuleExecution
→ Selection·Roll·TimingWindow
→ Resource Reservation
→ Pending Effect·Outcome
→ Commit 직전 Ordering 재획득
→ Transaction
```

장기 대기 중에는 Ordering Lock을 유지하지 않는다. 행동·Reaction·Spell Slot 같은 사용권은 타입 있는 Resource Reservation으로 보존한다.

### 4.3 Cross-Domain 결과

```text
Root Outcome
→ Immediate Closure Planner
→ 같은 Transaction에서 유효성 불변식 확정
→ Deferred Consequence Ledger
→ Commit 이후 새 Command·RuleExecution
```

- HP 0에 따른 즉시 VitalState·행동 불가 Closure는 같은 Transaction에 포함한다.
- 집중 내성, Objective 재평가처럼 새 굴림·선택·판정이 필요한 결과는 후속 실행으로 분리한다.
- Integration Coordinator는 별도 Domain Store를 소유하지 않는다.

### 4.4 Event와 Subscriber

```text
Transaction Commit
→ Domain Event Outbox
→ 멱등 Subscriber
→ Projection 또는 Follow-up Command
```

Subscriber가 다른 Domain Store를 직접 수정하지 않는다. 재시도는 Event·Handler·AuthorityEpoch 기반 멱등성을 사용한다.

### 4.5 재접속과 Resync

```text
Connection Epoch 변경
→ 권위 입력 Gate 닫기
→ Projection Snapshot·Catch-up
→ Replica 원자 교체
→ Prompt·Selection 재Projection
→ 입력 재활성화
```

Client의 로컬 State를 서버 복구 원본으로 사용하지 않는다.

### 4.6 Rollback

```text
Rollback Review Overlay
→ 대상 Snapshot·Branch 검토
→ Rollback Commit
→ 새 AuthorityEpoch
→ Full Resync
```

Rollback은 현재 State에 역방향 Mutation을 하나씩 적용하는 기능이 아니다. 선택한 권위 Snapshot을 새 Branch에서 복원한다.

### 4.7 오류와 관측

```text
Input Intent
→ Command
→ RuleExecution
→ Transaction
→ Event
→ Projection
→ UI·Presentation
```

전체 경로는 공통 Trace Context로 연결한다. 일반 Observability 실패는 Gameplay Commit을 되돌리지 않지만, 필수 관리 Audit가 필요한 Command는 해당 Audit 경계를 따라야 한다.

## 5. 문서 관계도

### Parent Authority

- [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md) — 모든 Runtime의 서버 권위, 확장, 오류 격리와 성능 원칙
- [`Compiled Build와 Authoritative State 분리 패턴`](../../architecture/compiled-build-and-authoritative-state-pattern.md) — Source·Build·State·Migration·Projection의 공통 구조

### Child Authority

- [`Ruleset Policy Registry, Composition과 Frozen Snapshot Runtime`](../../architecture/ruleset-policy-registry-composition-and-frozen-snapshot-runtime-contract.md) — 교체형 규칙의 등록·합성·버전 고정
- [`Session Play Mode, Context, Overlay와 Transition`](../../architecture/session-play-mode-context-overlay-and-transition-contract.md) — 세션 실행 문맥과 Transition Gate
- [`Networking Command, Event와 Client Synchronization`](../../architecture/networking-command-event-and-client-synchronization-contract.md) — Command Protocol과 Projection Stream
- [`Rule Runtime Orchestrator와 Pending Execution`](../../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md) — 선택·반응·대기 가능한 규칙 실행
- [`Command Ordering, Logical Time와 Transaction Coordinator`](../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md) — Ordering·Reservation·Atomic Commit
- [`Domain Event, Outbox, Subscription과 Projection Runtime`](../../architecture/domain-event-outbox-subscription-and-projection-runtime-contract.md) — Commit 이후 Event와 Subscriber
- [`Cross-Domain Outcome Cascade와 Integration Boundary`](../../architecture/cross-domain-outcome-cascade-and-integration-boundary-runtime-contract.md) — Immediate Closure와 Deferred Consequence
- [`Persistence, Snapshot, Journal과 Recovery`](../../architecture/persistence-and-session-recovery-model.md) — 저장·Restart·Rollback·Migration
- [`UI Projection, ViewModel, Input Context와 Recovery Runtime`](../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md) — Client Replica와 UI Intent
- [`Diagnostics, Observability, Correlated Trace와 Incident Runtime`](../../architecture/diagnostics-observability-correlated-trace-and-incident-runtime-contract.md) — Trace·Incident·Budget·Redaction
- [`Deterministic Simulation, Scenario와 Test Harness Runtime`](../../architecture/deterministic-simulation-scenario-and-test-harness-runtime-contract.md) — Production-parity 검증

### References

- [`한눈에 보는 세션 흐름`](../../user-guides/QUICK-FLOW.md) — 첫 Session Slice의 사용자 목표
- [`Architecture 문서 인덱스`](../../architecture/README.md) — 현재 최상위 권위 문서 목록과 작성 원칙
- [`Integration 시스템`](../../systems/integration/README.md) — Cross-System 경계의 기능별 진입점
- [`현재 전체 작업 순서`](../../CURRENT-WORK-ORDER.md) — Guide·Spec·구현 단계 순서
- [`현재 Spec 작업 순서`](../../specs/CURRENT-SPEC-WORK-ORDER.md) — Implementation Specs의 수직 Slice 순서
- [`현재 Guide 작업 순서`](../CURRENT-GUIDE-WORK-ORDER.md) — Main System Guide 단계 기록

## 6. 다른 시스템과의 경계

| 인접 시스템 | Runtime Foundation이 제공하는 것 | 상대 시스템이 제공하는 것 | 권위 경계 문서 |
|---|---|---|---|
| Ruleset·Content | Policy Snapshot, Build·Version 원칙 | 실제 규칙 Definition·Pack·Compiler | Policy Runtime, Compiled Build 패턴 |
| Session | Command Gate, Epoch·Transition 공통 경계 | Base Mode, Context, Overlay와 참가자 상태 | Session Runtime |
| Gameplay Domain | RuleExecution·Transaction·Event 기반 | 자신의 State, 규칙과 Mutation Proposal | Rule Runtime, Transaction, Cross-Domain Integration |
| Networking | 권위 Command·Projection 원칙 | 연결, Envelope, Receipt, Catch-up과 Resync | Networking 계약 |
| Persistence | Identity·Revision·Commit 경계 | Snapshot Manifest, Chunk, Journal과 Recovery | Persistence 계약 |
| UI | Projection과 Semantic Intent | Panel, Focus, ViewModel과 사용자 입력 상태 | UI Runtime |
| Presentation | 권위 결과와 공개 가능한 Intent | Camera·VFX·Animation·표현 Queue | Presentation·Camera Runtime |
| Diagnostics | Trace Context와 Authority Reference | Span·Incident·Budget·Support Projection | Diagnostics Runtime |
| Testing | Production Registry와 권위 경로 | Deterministic Adapter, Scenario와 Assertion | Simulation Harness |

금지되는 연결:

- UI·Presentation이 Domain Store를 직접 수정
- Domain Service가 다른 Domain Store를 직접 수정
- Subscriber가 Event를 근거로 직접 State Mutation
- Client가 Roll, Physics, Timestamp 또는 Cache를 권위 결과로 확정
- Persistence Snapshot을 Workspace 복사본으로 취급
- Diagnostics와 Test Hook이 규칙 검증·Transaction을 우회

## 7. 추천 읽기 순서

1. [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md) — 전체 불변 원칙
2. [`ADR-0054`](../../decisions/ADR-0054-compiled-semantic-runtime-and-query-authority-principles.md) — Semantic Runtime과 Query Authority 방향
3. [`Compiled Build와 Authoritative State 분리 패턴`](../../architecture/compiled-build-and-authoritative-state-pattern.md) — 공통 데이터 계층
4. [`Ruleset Policy Runtime`](../../architecture/ruleset-policy-registry-composition-and-frozen-snapshot-runtime-contract.md) — 실행 규칙의 합성과 고정
5. [`Session Runtime`](../../architecture/session-play-mode-context-overlay-and-transition-contract.md) — 실행 문맥과 Transition
6. [`Networking 계약`](../../architecture/networking-command-event-and-client-synchronization-contract.md) — Intent와 Client 동기화
7. [`Rule Runtime Orchestrator`](../../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md) — 장기 규칙 실행
8. [`Transaction Coordinator`](../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md) — 원자적 변경
9. [`Domain Event Runtime`](../../architecture/domain-event-outbox-subscription-and-projection-runtime-contract.md) — Commit 이후 전달
10. [`Cross-Domain Integration`](../../architecture/cross-domain-outcome-cascade-and-integration-boundary-runtime-contract.md) — 여러 Domain 결과 연결
11. [`Persistence와 Recovery`](../../architecture/persistence-and-session-recovery-model.md) — 저장·복구·Rollback
12. [`UI Runtime`](../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md) — Projection에서 사용자 입력까지
13. [`Diagnostics Runtime`](../../architecture/diagnostics-observability-correlated-trace-and-incident-runtime-contract.md) — 원인·성능·Incident 추적
14. [`Simulation Harness`](../../architecture/deterministic-simulation-scenario-and-test-harness-runtime-contract.md) — 결정적 회귀 검증
15. [`Core Authority Identity·Version·Result Spec`](../../specs/runtime/001-core-authority-identity-version-and-result.md) — First Slice의 공통 구현 계약 초안
16. [`Completion Audit`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md) — 현재 범위의 Architecture 완료 판정

## 8. 구현·검증 순서

현재 단계에서는 실제 구현 파일 순서가 아니라, 후속 Implementation Spec이 따라야 할 확정 의존 관계만 정리한다.

```text
Identity·Revision·Registry Foundation
→ Source·Compiler·Immutable Build
→ Policy Composition·Frozen Snapshot
→ Command Protocol·Authorization
→ RuleExecution·Selection·Reservation
→ Ordering·Authority Transaction
→ Journal·Outbox·Subscriber
→ Persistence·Recovery·Epoch
→ Projection Stream·UI Replica
→ Diagnostics·Health
→ Deterministic Harness
→ Cross-Domain Integration Scenario
```

검증은 각 단계에서 단위 Schema 검사만 수행하고 끝내지 않는다. 최소한 다음 End-to-End 경로까지 확인해야 한다.

```text
Intent
→ Commit
→ Projection
→ Reconnect
→ Restart
→ Rollback
→ 동일 Scenario 재실행
```

구체적 Module·Type·Remote·Persistence Key는 `Implementation Specs` 단계가 소유한다.

## 9. 변경 영향 지도

| 변경 유형 | 영향받는 권위 문서 | 영향받는 후속 Specs | Guide 조치 |
|---|---|---|---|
| Stable ID·Revision·Epoch 변경 | Runtime Principles, Runtime Object, Networking, Persistence | Identity·Lifecycle·Recovery Specs | `UPDATE_REQUIRED` |
| Source·Build·State 경계 변경 | Compiled Build 패턴과 해당 Domain Architecture | Compiler·Migration Specs | `UPDATE_REQUIRED` |
| Policy 우선순위·Snapshot 변경 | Policy Runtime과 관련 Domain Policy | Policy Registry·Snapshot Specs | `UPDATE_REQUIRED` |
| Command Envelope·Result 변경 | Networking, UI, Diagnostics | Protocol·Client Sync Specs | `UPDATE_REQUIRED` |
| RuleExecution·Reservation 변경 | Rule Runtime, Transaction, Persistence | Execution·Prompt·Reservation Specs | `UPDATE_REQUIRED` |
| Transaction·Journal 경계 변경 | Transaction, Event, Persistence, Cross-Domain Integration | Coordinator·Outbox·Recovery Specs | `UPDATE_REQUIRED` |
| Projection·Disclosure 변경 | Event, UI, Visibility와 Domain Projection | Projection·UI Specs | `UPDATE_REQUIRED` |
| Diagnostics Sampling 수치 변경 | Diagnostics Runtime | Observability Config Specs | 필요 시 갱신 |
| Scenario Budget·반복 수 변경 | Simulation Harness | CI·Test Profile Specs | 필요 시 갱신 |

## 10. Authority Documents

### Product

- [`Platform, Movement와 Input Scope`](../../product/platform-movement-and-input-scope.md)

`DISCONTINUED`인 `product/core-session-loop.md`는 현재 Authority와 추천 읽기 순서에서 제외한다. 세션 사용자 흐름은 Quick Flow와 Player·DM User Guide를 Reference로 사용한다.

### Architecture

- [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md)
- [`Compiled Build와 Authoritative State 분리 패턴`](../../architecture/compiled-build-and-authoritative-state-pattern.md)
- [`Ruleset Policy Runtime`](../../architecture/ruleset-policy-registry-composition-and-frozen-snapshot-runtime-contract.md)
- [`Session Runtime`](../../architecture/session-play-mode-context-overlay-and-transition-contract.md)
- [`Networking 계약`](../../architecture/networking-command-event-and-client-synchronization-contract.md)
- [`Rule Runtime Orchestrator`](../../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md)
- [`Transaction Coordinator`](../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)
- [`Domain Event Runtime`](../../architecture/domain-event-outbox-subscription-and-projection-runtime-contract.md)
- [`Cross-Domain Integration`](../../architecture/cross-domain-outcome-cascade-and-integration-boundary-runtime-contract.md)
- [`Persistence와 Recovery`](../../architecture/persistence-and-session-recovery-model.md)
- [`UI Runtime`](../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md)
- [`Diagnostics Runtime`](../../architecture/diagnostics-observability-correlated-trace-and-incident-runtime-contract.md)
- [`Simulation Harness`](../../architecture/deterministic-simulation-scenario-and-test-harness-runtime-contract.md)

### Systems·UI

- [`Integration 시스템`](../../systems/integration/README.md)
- [`Events 시스템`](../../systems/events/README.md)
- [`Diagnostics 시스템`](../../systems/diagnostics/README.md)
- [`Testing 시스템`](../../systems/testing/README.md)
- [`UI 문서 인덱스`](../../ui/README.md)

### Specs

- [`현재 Spec 작업 순서`](../../specs/CURRENT-SPEC-WORK-ORDER.md)
- [`Core Authority Identity·Version·Result Spec`](../../specs/runtime/001-core-authority-identity-version-and-result.md) — `초안`, 실제 Production Source Tree 조사 전 `BLOCKED`

### Audits

- [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)
- [`구현 명세 전 최종 문서 연결 감사`](../../audits/pre-implementation-document-linkage-audit.md)

## 11. ADR References

- [`ADR-0054`](../../decisions/ADR-0054-compiled-semantic-runtime-and-query-authority-principles.md) — Semantic Build와 서버 Query Authority
- [`ADR-0057`](../../decisions/ADR-0057-canonical-scene-source-and-atomic-compiled-build-activation.md) — Canonical Source와 Atomic Build Activation
- [`ADR-0058`](../../decisions/ADR-0058-stable-runtime-object-identity-and-command-driven-lifecycle.md) — Stable Identity와 Lifecycle
- [`ADR-0059`](../../decisions/ADR-0059-versioned-command-protocol-and-projection-stream-synchronization.md) — Versioned Command와 Projection Sync
- [`ADR-0061`](../../decisions/ADR-0061-persistent-rule-execution-orchestrator-and-nested-timing-windows.md) — Persistent RuleExecution
- [`ADR-0062`](../../decisions/ADR-0062-ordered-reservations-and-atomic-authority-transactions.md) — Ordered Reservation과 Atomic Transaction
- [`ADR-0063`](../../decisions/ADR-0063-manifest-chunk-snapshots-commit-journal-and-branch-recovery.md) — Snapshot·Journal·Branch Recovery
- [`ADR-0064`](../../decisions/ADR-0064-immutable-compiled-builds-and-versioned-authoritative-state.md) — Immutable Build와 Versioned State
- [`ADR-0070`](../../decisions/ADR-0070-orthogonal-session-modes-contexts-overlays-and-transitions.md) — Session Mode·Context·Overlay·Transition 분리
- [`ADR-0077`](../../decisions/ADR-0077-transactional-domain-events-with-outbox-and-projection-boundaries.md) — Transactional Event Outbox
- [`ADR-0081`](../../decisions/ADR-0081-versioned-policy-composition-and-frozen-ruleset-snapshots.md) — Policy Composition과 Frozen Snapshot
- [`ADR-0083`](../../decisions/ADR-0083-projection-driven-ui-runtime-and-epoch-safe-client-recovery.md) — Projection-driven UI와 Epoch-safe Recovery
- [`ADR-0084`](../../decisions/ADR-0084-correlated-authority-traces-and-permission-aware-observability.md) — Correlated Trace와 Diagnostic Projection
- [`ADR-0085`](../../decisions/ADR-0085-production-parity-deterministic-scenarios-and-controlled-nondeterminism.md) — Production-parity Simulation
- [`ADR-0087`](../../decisions/ADR-0087-atomic-immediate-closure-and-event-driven-deferred-consequences.md) — Immediate Closure와 Deferred Consequence

## 12. 알려진 비목표와 측정형 기본값

비목표:

- Client Physics를 권위 판정에 사용하지 않는다.
- 모든 Command를 하나의 전역 Queue로 직렬화하지 않는다.
- 모든 Runtime을 하나의 거대 Entity Store나 Service로 합치지 않는다.
- Raw Authority State를 모든 Client에 복제하지 않는다.
- Event Subscriber와 Diagnostics Hook이 Store를 직접 수정하지 않는다.
- 테스트 편의를 위해 Production Command·Rule·Transaction 경로를 우회하지 않는다.

남은 측정형 기본값:

- Ordering Lease, Retry와 Queue 상한
- Snapshot·Journal Flush 주기와 Chunk 목표 크기
- Projection Batch·Catch-up·Resync Budget
- Trace Sampling·Retention과 Incident Bundle 크기
- Scenario Suite 실행 시간, Interleaving 깊이와 반복 수
- 개별 Registry·Cache·Index의 성능·메모리 상한

이 값들은 Architecture의 의미를 바꾸지 않는 범위에서 Implementation Spec과 플레이테스트로 확정한다.

## 13. Guide 검증 체크리스트

- [x] 모든 핵심 문장이 Authority Document에 근거한다.
- [x] 새로운 제품 규칙이나 Architecture 결정을 추가하지 않았다.
- [x] Parent·Children·References를 구분했다.
- [x] 최신 ADR-0087과 Completion Audit을 반영했다.
- [x] `SUPERSEDED`, `DISCONTINUED`, `ARCHIVED` 문서를 Authority 목록에서 제외했다.
- [x] 현재 Spec Work Order와 첫 Runtime Spec 초안을 반영했다.
- [x] 변경 영향 지도가 현재 권위 구조와 일치한다.
- [x] Guide Status가 실제 상태와 일치한다.
