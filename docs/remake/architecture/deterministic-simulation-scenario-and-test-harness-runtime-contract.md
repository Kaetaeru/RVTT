# Deterministic Simulation, Scenario와 Test Harness Runtime 계약

- 상태: 확정
- 문서 종류: Architecture
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 남은 기본값:
  - Pull Request 필수 Scenario Suite의 최대 실행 시간과 병렬 Worker 수
  - Bounded Interleaving Exploration의 기본 깊이·분기·상태 수 상한
  - Golden Artifact의 기본 보존 기간과 승인 절차
  - Deterministic Fixture·Artifact의 최대 직렬화 크기
  - Property·Mutation·Soak Test의 기본 반복 수와 실패 축소 Budget
  - 실제 Roblox Client·Server 통합 테스트와 Headless Harness의 분담 비율
  - 성능 회귀의 실제 시간 기준과 결정적 Logical Cost 기준 기본값
  - Production Incident Bundle에서 자동 생성할 Scenario 초안의 Redaction 수준
- 작성일: 2026-08-04
- 관련 ADR:
  - [`ADR-0033`](../decisions/ADR-0033-server-authoritative-dice-rolls-and-presentation-gated-resolution.md)
  - [`ADR-0042`](../decisions/ADR-0042-authoritative-checkpoints-command-journal-and-session-recovery.md)
  - [`ADR-0043`](../decisions/ADR-0043-encounter-turn-snapshot-timeline-and-dm-rollback.md)
  - [`ADR-0059`](../decisions/ADR-0059-versioned-command-protocol-and-projection-stream-synchronization.md)
  - [`ADR-0061`](../decisions/ADR-0061-persistent-rule-execution-orchestrator-and-nested-timing-windows.md)
  - [`ADR-0062`](../decisions/ADR-0062-ordered-reservations-and-atomic-authority-transactions.md)
  - [`ADR-0063`](../decisions/ADR-0063-manifest-chunk-snapshots-commit-journal-and-branch-recovery.md)
  - [`ADR-0069`](../decisions/ADR-0069-authoritative-roll-records-and-presentation-gated-resolution.md)
  - [`ADR-0077`](../decisions/ADR-0077-transactional-domain-events-with-outbox-and-projection-boundaries.md)
  - [`ADR-0081`](../decisions/ADR-0081-versioned-policy-composition-and-frozen-ruleset-snapshots.md)
  - [`ADR-0082`](../decisions/ADR-0082-atomic-encounter-boundary-time-advance-and-event-driven-scheduler-bridge.md)
  - [`ADR-0083`](../decisions/ADR-0083-projection-driven-ui-runtime-and-epoch-safe-client-recovery.md)
  - [`ADR-0084`](../decisions/ADR-0084-correlated-authority-traces-and-permission-aware-observability.md)
  - [`ADR-0085`](../decisions/ADR-0085-production-parity-deterministic-scenarios-and-controlled-nondeterminism.md)
- 상위 문서:
  - [`Runtime Architecture Principles`](runtime-architecture-principles.md)
  - [`Ruleset Policy Registry, Composition과 Frozen Snapshot Runtime 계약`](ruleset-policy-registry-composition-and-frozen-snapshot-runtime-contract.md)
  - [`Command Ordering, Logical Time와 Transaction Coordinator 계약`](command-ordering-logical-time-and-transaction-coordinator-contract.md)
  - [`Persistence, Snapshot, Journal과 Recovery 계약`](persistence-and-session-recovery-model.md)
  - [`Diagnostics, Observability, Correlated Trace와 Incident Runtime 계약`](diagnostics-observability-correlated-trace-and-incident-runtime-contract.md)
- 관련 Runtime:
  - [`Networking Command, Event와 Client Synchronization 계약`](networking-command-event-and-client-synchronization-contract.md)
  - [`Domain Event Runtime 계약`](domain-event-outbox-subscription-and-projection-runtime-contract.md)
  - [`Dice와 Resolution Runtime 계약`](dice-roll-check-save-attack-and-resolution-runtime-contract.md)
  - [`Game Time Runtime 계약`](game-time-calendar-duration-and-scheduler-runtime-contract.md)
  - [`UI Runtime 계약`](ui-projection-view-model-input-context-and-recovery-runtime-contract.md)
  - [`Visibility, Knowledge와 Detection Runtime 계약`](visibility-knowledge-detection-and-hover-information-runtime-contract.md)

## 1. 목적

RVTT는 동시 Command, 주사위, Scheduler, Network 재전송, 저장 실패, 재접속과 Rollback이 결합되는 서버 권위 시스템이다.

수동 플레이테스트만으로는 다음 오류를 안정적으로 재현하기 어렵다.

- 두 Actor가 같은 Item을 동시에 획득하려 함
- Encounter 전환과 이동 Commit이 같은 시점에 경쟁함
- Reaction 대기 중 Client가 연결 종료 후 재접속함
- Transaction Commit 직후 Server가 종료됨
- Rollback 이전 Event Subscriber가 새 AuthorityEpoch에서 다시 실행됨
- 8시간 휴식 중 2시간 지점의 습격을 건너뜀
- 숨은 함정의 ID·이름·실제 DC가 Projection·UI·Diagnostics에 노출됨
- Presentation 실패가 Gameplay 결과까지 실패시킴
- Policy 변경이 진행 중 RuleExecution에 조용히 섞임

따라서 이 문서는 생산 Runtime을 그대로 실행하면서 외부 비결정 요소만 통제하는 공통 Simulation과 Test Harness 계약을 정의한다.

```text
Versioned Scenario Definition
+ Immutable Fixture Manifest
+ Frozen Ruleset·Policy·Build References
+ Controlled RNG·Clock·ID·Transport·Storage Adapters
→ Production Runtime Path 실행
→ State·Event·Projection·UI·Trace Artifact
→ Semantic·Security·Recovery·Budget Assertion
```

핵심 원칙:

```text
Test Harness는 두 번째 규칙 엔진이 아니다.
```

```text
생산 Handler와 Registry를 우회하는 테스트 전용 상태 변경은 허용하지 않는다.
```

## 2. 사용자와 개발 결과

이 계약은 다음 결과를 보장한다.

- 같은 Scenario, Version과 Seed Plan은 같은 결정적 권위 결과를 만든다.
- 실패한 실행은 Seed, Fixture, Schedule과 Fault Plan으로 다시 실행할 수 있다.
- 테스트와 생산 환경이 같은 Command, RuleExecution, Transaction, Event와 Projection 구현을 사용한다.
- 동시성 오류를 현실 시간의 우연한 Thread 순서에 의존하지 않고 명시적인 Interleaving으로 재현한다.
- Rollback, Reconnect와 Server Restart를 실제 AuthorityEpoch·Snapshot·Journal 계약에 맞게 검증한다.
- Player, DM과 Observer의 Projection을 같은 Authority State에서 비교해 정보 누출을 자동 검사한다.
- VFX, UI와 Network 실패가 권위 결과를 변경하지 않는지 검증한다.
- Policy·Build Version 변경이 기존 Scenario 결과에 미치는 영향을 구조화된 Diff로 확인한다.
- Production Incident를 비밀 정보가 제거된 재현 Artifact로 변환할 수 있다.
- 테스트 실패가 단순 문자열이 아니라 Trace, State Diff, Command Result와 최소 재현 Schedule을 제공한다.

## 3. 책임 경계

### 3.1 Simulation과 Test Harness가 소유한다

- Versioned Scenario Definition과 Fixture Manifest
- Scenario Compiler와 정적 유효성 검사
- 결정적 RNG, Authority Monotonic Clock, ID Factory와 Execution Scheduler Adapter
- 가상 Network·Client·Storage·Presentation Adapter
- Command·Event·Message Delivery의 결정적 Schedule
- 등록된 Fault Point와 Fault Injection Plan
- Bounded Concurrency·Interleaving Exploration
- 생산 Runtime Bootstrap과 격리된 Simulation World
- State, Event, Projection, UI, Trace와 Budget Artifact 수집
- Semantic Assertion, Golden Diff와 Negative Disclosure Assertion
- 실패 Scenario의 Seed·Schedule·Input 축소
- CI Suite, Regression Catalog와 Test Artifact 수명주기

### 3.2 Simulation과 Test Harness가 소유하지 않는다

- 공격, 주문, 아이템, Encounter와 휴식의 실제 규칙
- Command Authorization과 Capability 적격성
- Transaction Commit과 AuthorityRevision 발급 규칙
- Projection Disclosure와 UI ViewModel의 실제 구현
- Campaign Production Snapshot의 수정
- Production RNG Seed의 공개와 장기 보존
- 실제 사용자 데이터의 자동 Fixture 변환 권한
- Production 성능 지표의 유일한 원본

Harness는 외부 Adapter와 실행 Schedule을 통제한다. Domain 판단은 생산 Runtime이 수행한다.

## 4. 생산 코드와의 동일성

### 4.1 반드시 같은 구현을 사용한다

Headless Simulation에서도 다음은 생산 Registry와 Handler를 사용한다.

```text
CommandDefinition·Handler
Authorization·Validation
RuleExecution Orchestrator
Recipe·Step Handler
Policy Composition과 Frozen Snapshot
Ordering·Transaction Coordinator
Domain Store와 Mutation
Domain Event Outbox·Subscriber
Projection Builder
UI Selector·ViewModel
Persistence Serializer·Recovery Loader
Diagnostics Span·Decision Record
```

### 4.2 교체 가능한 것은 외부 Adapter다

```text
RNG Provider
Authority Monotonic Clock
Deterministic ID Factory
Transport·Delivery Scheduler
Storage Adapter
Presentation ACK Adapter
Client Runtime Adapter
External Service Stub
```

이 Adapter도 생산 Interface 계약을 구현해야 한다.

### 4.3 금지되는 Test Hook

- HP, 위치, Inventory와 Encounter Store를 직접 수정하는 `setForTest`
- Command 검증을 건너뛰는 Test-only Command
- Transaction 없이 상태를 주입하는 Fixture Setup
- RuleExecution 결과를 임의로 반환하는 전역 Mock
- 실제 Registry와 다른 Test 전용 Policy 우선순위
- `wait()` 또는 현실 Sleep으로 동시성 순서를 맞추는 테스트
- Client가 Raw Authority Store를 직접 읽는 Assertion

초기 Fixture 구성도 Production Loader 또는 검증된 Fixture Materializer를 통해 Authoritative State를 만든다.

## 5. 결정성의 범위

동일 실행을 위해 다음 비결정 입력을 모두 명시적으로 통제한다.

```text
Random Draw
Authority Monotonic Time
Campaign Time Advance Input
ID Generation
Command Arrival Order
Runnable Task Selection
Network Delay·Drop·Duplicate·Reorder
Subscriber Delivery·Retry Order
Storage Success·Timeout·Restart Point
Presentation ACK·Timeout
Client Connection·Reconnect Timing
```

결정성에 포함하지 않는 값:

- 실제 OS Thread ID
- 실제 Wall Clock Timestamp
- 로컬 GPU Frame Time
- Roblox Instance 내부 주소
- 임시 Trace Storage Locator

이 값은 Artifact에서 정규화하거나 제외한다.

## 6. Scenario Definition

```text
SimulationScenarioDefinition
├─ scenarioId
├─ scenarioVersion
├─ titleKey
├─ purpose
├─ tags[]
├─ requiredRuntimeVersions
├─ fixtureManifestRef
├─ rulesetSnapshotRef
├─ policySnapshotRefs[]
├─ buildRefs[]
├─ participantDefinitions[]
├─ audienceDefinitions[]
├─ deterministicInputPlan
├─ actionSchedule
├─ faultPlan[]
├─ stopCondition
├─ assertionPlan[]
├─ artifactPolicy
└─ executionBudget
```

### 6.1 Scenario Identity

Scenario는 표시 제목이 아니라 안정적 ID와 Version을 가진다.

```text
scenario.concurrent.same_item_pickup
scenario.recovery.reaction_reconnect
scenario.security.hidden_trap_projection
```

기대 결과를 의미 있게 바꾸면 Scenario Version을 증가시킨다.

### 6.2 Scenario는 절차가 아니라 입력 계약이다

Scenario가 Domain 결과를 직접 명령하지 않는다.

잘못된 예:

```text
공격은 명중하고 피해 8을 적용한다.
```

올바른 예:

```text
Actor A가 Capability X를 Target B에 사용한다.
RNG Stream의 지정된 Draw가 RollPlan을 해결한다.
최종 결과가 Assertion을 만족하는지 확인한다.
```

## 7. Fixture Manifest

```text
SimulationFixtureManifest
├─ fixtureId
├─ fixtureVersion
├─ sourceRefs[]
├─ contentVersionSet
├─ rulesetSnapshotRef
├─ policySnapshotRefs[]
├─ compiledBuildRefs[]
├─ initialAuthoritySnapshotRef?
├─ materializationSteps[]
├─ secretCanaries[]
├─ integrityHash
└─ syntheticDataClassification
```

규칙:

- Fixture는 가능한 한 합성 데이터로 작성한다.
- 실제 Campaign Snapshot을 저장소에 Commit하지 않는다.
- Fixture의 Build, Policy와 Content Version을 명시적으로 고정한다.
- 초기 상태는 Production Schema와 Validation을 통과해야 한다.
- 비밀 정보 검사를 위해 의도적으로 식별 가능한 `secretCanary`를 넣을 수 있다.
- Fixture가 최신 Content로 자동 마이그레이션되어 기대 결과를 조용히 바꾸지 않는다.

Migration을 검증하는 Scenario만 명시적으로 Candidate Version으로 변환한다.

## 8. Deterministic RNG

### 8.1 Simulation RNG와 Production RNG 분리

Production은 서버 권위 RNG 정책을 사용한다. Simulation은 같은 RNG Interface에 결정적 Provider를 주입한다.

Production Incident 재현을 위해 비밀 Root Seed를 Export하지 않는다. 이미 실행된 Incident는 공개 가능한 `RollRecord`, Random Decision Record와 결과를 재생하거나 별도의 합성 Seed Scenario로 변환한다.

### 8.2 의미별 독립 Stream

하나의 전역 RNG Cursor에 모든 굴림을 연결하지 않는다.

```text
Scenario Root Seed
→ Named Random Stream
  ├─ roll:{rollSemanticKey}
  ├─ table:{tableSemanticKey}
  ├─ initiative:{encounterEntryKey}
  ├─ ai:{actorDecisionKey}
  └─ fixture:{generationKey}
```

```text
DeterministicRandomRequest
├─ streamKey
├─ drawKind
├─ drawOrdinal
├─ boundsOrDice
├─ sourceSemanticRef
└─ traceRef
```

관련 없는 다른 Stream에 Random Draw가 추가되어도 기존 굴림 결과가 연쇄적으로 밀리지 않아야 한다.

### 8.3 금지

Domain Runtime에서 다음을 직접 호출하지 않는다.

```text
math.random
Random.new without injected seed/provider
os.clock based randomization
GUID ordering as randomness
Workspace iteration order as randomness
```

## 9. Virtual Time

### 9.1 Authority Monotonic Time

Timeout, Lease, Retry와 Reaction Deadline은 `VirtualMonotonicClock`으로 제어한다.

```text
advance_monotonic_time(250ms)
→ due timeout·lease 후보 실행
```

### 9.2 Campaign Game Time

Campaign Time은 Virtual Clock이 자동으로 흘리는 값이 아니다.

```text
TimeAdvance Command 또는 Encounter Round Boundary
→ Production Game Time Runtime
→ Campaign Time Commit
```

Scenario는 필요한 입력과 Boundary만 만든다. Game Time Store를 직접 증가시키지 않는다.

### 9.3 Presentation Time

Presentation ACK, Marker와 Timeout은 별도 Virtual Presentation Clock을 사용할 수 있다. Presentation 시간 진행이 Gameplay Duration을 변경하지 않는지 검증한다.

## 10. Deterministic ID와 정렬

```text
DeterministicIdFactory
├─ namespace
├─ scenarioRunId
├─ semanticKey
├─ occurrenceOrdinal
└─ generatedStableId
```

- Domain ID 생성은 주입된 Factory를 사용한다.
- Map, Set와 Registry 순회 결과는 Canonical Stable Order로 정렬한다.
- 부동소수점 누적값을 State Hash의 원본으로 사용하지 않는다.
- 같은 의미의 입력에 동일한 Semantic Key를 사용한다.
- ID 생성 순서가 바뀌었다는 이유만으로 무관한 Domain 결과가 바뀌지 않도록 Namespace를 분리한다.

## 11. Execution Scheduler와 Action Schedule

```text
ScenarioActionSchedule
├─ steps[]
├─ barriers[]
├─ deliveryRules[]
├─ allowedNondeterministicChoices[]
└─ quiescencePolicy
```

Step 종류 예:

```text
submit_command
respond_to_prompt
advance_monotonic_time
request_time_advance
connect_client
disconnect_client
restart_server
commit_rollback
release_network_message
run_subscriber
ack_presentation
assert_checkpoint
```

Harness는 실행 가능한 Task 집합에서 다음 Task를 결정적 Schedule에 따라 선택한다. 현실 Scheduler의 우연한 순서에 의존하지 않는다.

## 12. Quiescence와 Stop Condition

Scenario 종료는 단순히 마지막 Command를 보냈다는 뜻이 아니다.

```text
SimulationQuiescence
├─ runnableAuthorityTasks = 0
├─ scheduledDeliveriesBeforeHorizon = 0
├─ unprocessedCommittedOutbox = 0
├─ dueSchedulerOccurrences = 0
├─ unresolvedTransactions = 0
├─ activeOrderingReservations = 0
└─ allowedPendingPromptsOnly
```

Reaction Prompt 대기 자체를 테스트하는 Scenario처럼 명시적으로 허용된 Pending State는 Stop Condition에 포함할 수 있다.

무한 Event Loop와 Retry Loop는 Step Budget을 넘기면 구조화된 실패로 종료한다.

## 13. 동시성과 Interleaving Exploration

### 13.1 명시적 Schedule

특정 Race를 재현할 때 정확한 순서를 작성할 수 있다.

```text
A와 B의 Item Pickup Command 수신
→ A와 B 모두 초기 Validation 완료
→ B가 Ordering Reservation 먼저 획득
→ B Commit
→ A 최신 상태 재검증
```

### 13.2 Bounded Exploration

```text
InterleavingExplorationPlan
├─ choicePoints[]
├─ maximumDepth
├─ maximumBranches
├─ stateHashPruning
├─ symmetryReductionRules[]
└─ failureShrinkPolicy
```

모든 실제 Thread 조합을 무제한 탐색하지 않는다. 등록된 Yield Point와 Conflict Key를 기준으로 의미 있는 순서만 제한적으로 탐색한다.

### 13.3 동시성 Assertion

- 하나의 ItemInstance가 두 Inventory에 동시에 존재하지 않음
- 하나의 Transaction만 충돌 자원을 Commit함
- 패배한 Command가 구조화된 Conflict 또는 Stale Result를 받음
- Ordering Reservation과 Resource Reservation이 Terminal State 후 남지 않음
- 독립 Ordering Key의 Command는 불필요하게 전역 직렬화되지 않음

## 14. Fault Injection

Fault는 등록된 Boundary에서만 주입한다.

```text
FaultPointRegistryEntry
├─ faultPointId
├─ allowedFailureKinds[]
├─ inputSchema
├─ safetyClass
├─ repeatabilityPolicy
└─ observableOutcomeContract
```

초기 Fault Point:

```text
network.before_command_delivery
network.after_receipt_before_result
network.projection_batch_drop
network.projection_batch_duplicate
subscriber.before_handle
subscriber.after_followup_submit
storage.before_chunk_write
storage.after_commit_marker
transaction.before_commit
presentation.before_ack
client.before_replica_apply
server.before_recovery_boot
rollback.after_epoch_switch
```

지원 Failure:

```text
timeout
explicit_error
drop
duplicate
reorder
delay
disconnect
restart
corrupt_optional_payload
budget_exceeded
```

권위 Mutation 중간을 임의로 Monkey Patch해 현실에 존재하지 않는 부분 상태를 만드는 Fault는 금지한다. 원자성 검사는 Transaction과 Storage의 실제 등록된 장애 지점에서 수행한다.

## 15. Network와 Client Simulation

### 15.1 Virtual Client

```text
VirtualClient
├─ userId
├─ role
├─ connectionSessionId
├─ connectionEpoch
├─ projectionCursor
├─ localCacheManifest
├─ UIWorkspaceState
├─ inputContextState
└─ transportEndpoint
```

Virtual Client도 일반 Protocol Envelope, Command, Snapshot, Event Catch-up과 UI Runtime을 사용한다.

### 15.2 검증 대상

- Command 중복 전달과 Idempotency
- Result 유실 후 상태 조회·재전송
- Projection Gap과 Catch-up
- 다른 Projection Epoch 수신 차단
- Reconnect 후 Prompt·Selection 복구
- Rollback 후 이전 버튼·Command·ViewModel 폐기
- Role·Control 변경 후 Full Resync
- 이전 Connection Epoch 메시지 무효화

Client Mock이 Server Store를 직접 읽어 UI 기대값을 만들지 않는다.

## 16. Persistence, Restart와 Rollback

### 16.1 Server Restart

```text
Authority State 진행
→ 지정된 Fault Point에서 Server 종료
→ 검증된 Snapshot + Commit Journal로 새 Runtime Boot
→ 새 AuthorityEpoch
→ Index·Projection·UI 재구성
→ Scenario 계속 실행
```

### 16.2 Rollback

Rollback Scenario는 현재 Store를 직접 과거 값으로 덮어쓰지 않는다. Production Rollback Command, Snapshot Branch와 AuthorityEpoch 전환을 사용한다.

검증:

- 이전 Epoch Command·Prompt·Subscriber·Schedule 무효화
- Campaign Game Time과 Encounter Timeline의 선택된 Snapshot 복원
- Projection Epoch 변경과 Full Resync
- Local Workspace Preference 유지
- Authority-bound UI State 폐기 후 Projection 기반 복원
- 같은 Transaction·Event·Schedule의 중복 적용 방지

## 17. Assertion과 Oracle

```text
SimulationAssertion
├─ assertionId
├─ assertionKind
├─ checkpointRef
├─ audienceRef?
├─ query
├─ expected
├─ normalizationProfile
└─ severity
```

지원 Assertion 종류:

```text
authority_state
semantic_state_digest
domain_invariant
command_terminal_result
transaction_outcome
domain_event_sequence
subscriber_delivery
projection_snapshot_or_delta
ui_view_model
trace_graph
policy_and_build_binding
resource_leak
budget
negative_disclosure
error_code
quiescence
```

### 17.1 Semantic Assertion 우선

전체 Snapshot 문자열 비교보다 다음처럼 의미를 검사한다.

```text
ItemInstance X의 Location은 정확히 하나다.
Campaign Time은 정확히 6초 증가했다.
이전 AuthorityEpoch의 Event는 새 Branch에 Follow-up Command를 만들지 않았다.
Player Projection에는 secretCanary가 없다.
```

### 17.2 Golden Artifact

복잡한 Projection·ViewModel·Trace 구조는 Versioned Golden을 사용할 수 있다.

- Schema Version과 Normalization Profile을 함께 저장한다.
- 변경 이유 없이 Golden을 일괄 갱신하지 않는다.
- 의미 변경과 단순 표현 변경을 Diff에서 구분한다.
- 비밀 Raw Authority Data가 Player Golden에 포함되지 않는지 검사한다.

## 18. Canonical State Digest

```text
ExactAuthorityDigest
→ 결정적 ID와 모든 권위 의미 상태 포함

NormalizedSemanticDigest
→ Trace ID, 저장 Locator, Wall Timestamp 등 비의미 값 제거
```

Canonicalization 규칙:

- Stable ID 순서로 정렬
- 명시된 정수·고정소수점 단위 사용
- 누락 필드와 기본값 표현 통일
- Presentation, UI Ephemeral State와 Cache 제외
- 이전 Epoch 역사 기록은 별도 Branch Digest로 구분
- Secret Data를 Artifact에 Export할 때 Classification을 유지

동일 Scenario의 Exact Digest와, 서로 다른 합법적 Interleaving의 Normalized Semantic Digest를 목적에 맞게 사용한다.

## 19. Projection과 정보 누출 검사

같은 Authority Scenario를 여러 Audience로 투영한다.

```text
DM Audience
Player A Audience
Player B Audience
Observer Audience
DM-as-Player-Preview Audience
```

Negative Disclosure Assertion은 단순히 UI 필드가 숨겨졌는지만 보지 않는다.

검사 범위:

```text
Projection Snapshot·Event 직렬화 Byte
Public Entity Reference
Hover·Selection Candidate
UI ViewModel·Tooltip·Search Result
Command Error와 Diagnostic Projection
Trace·Incident Export
Cache Key·Index Entry
Presentation Intent Parameter
```

`secretCanary`의 값, 안정적 ID, 제목, 내부 경로와 파생 가능한 관계가 권한 밖 Artifact에 존재하면 실패한다.

## 20. Metamorphic와 Differential Test

동일한 의미를 유지해야 하는 변환을 검사한다.

예:

```text
Presentation 비활성화
→ Gameplay Authority Digest 동일

Player Locale 변경
→ Gameplay Authority Digest 동일

Observer Client 추가
→ Gameplay 결과 동일

서로 독립된 Command 순서 교환
→ Normalized Semantic Digest 동일

Event Subscriber의 합법적 Retry
→ 최종 권위 상태와 Follow-up 효과 중복 없음

Policy Version 변경
→ 영향이 선언된 Domain만 Diff
```

두 Runtime Version을 비교할 때 Incident·Trace ID가 아니라 Semantic Result와 명시된 Compatibility Profile을 비교한다.

## 21. 실패 축소와 재현 Artifact

Property 또는 Interleaving Test가 실패하면 다음을 축소한다.

- Command Sequence
- Participant 수
- Fault 수
- Interleaving Choice
- Random Stream Input
- Fixture Object 수

최소 재현 Artifact:

```text
scenarioId + version
fixtureHash
ruleset·policy·build refs
rootSeed와 named stream overrides
minimal action schedule
fault plan
failed assertion
state·event·projection diff
trace and incident reference
```

Production Incident Bundle에서 Scenario를 생성할 때는 인증 정보, 전체 사용자 문서, 비밀 Campaign 원문과 Production RNG Seed를 포함하지 않는다.

## 22. Test 계층

```text
Contract Test
→ Schema, Registry, Compiler, Serializer와 Invariant

Deterministic Scenario Test
→ 단일 Runtime 또는 End-to-End 권위 흐름

Concurrency Exploration Test
→ Ordering·Transaction·Idempotency Race

Recovery Test
→ Restart·Journal·Snapshot·Rollback·Reconnect

Disclosure Test
→ Audience별 Projection·UI·Diagnostics 누출

Property·Mutation Test
→ 입력 공간과 방어 불변식 탐색

Soak·Load Test
→ 장기 Queue·Memory·Tombstone·Budget 안정성

Roblox Integration Test
→ 실제 Transport·Instance·Streaming·Client 경계
```

Headless Harness만으로 Roblox Engine Adapter 문제를 전부 검증했다고 주장하지 않는다. 반대로 모든 규칙 테스트를 실제 3D Client에서만 실행하지 않는다.

## 23. CI와 실행 등급

권장 등급:

```text
PR_REQUIRED
→ Compiler·Schema·핵심 Deterministic Regression·Disclosure Smoke

MERGE_REGRESSION
→ 주요 End-to-End·Recovery·Concurrency Scenario

NIGHTLY_EXPLORATION
→ Bounded Interleaving·Property·Mutation·Soak

RELEASE_GATE
→ 전체 Recovery·Disclosure·Migration·Roblox Integration Suite

MANUAL_INCIDENT_REPLAY
→ Sanitized Incident 기반 재현
```

실패한 Required Suite를 불안정하다는 이유로 무기한 Retry해 통과 처리하지 않는다. Flaky Test는 결정적 입력 누락 또는 외부 Adapter 오염으로 분류해 수정하거나 명시적으로 격리한다.

## 24. 성능과 Budget 검사

결정적 Scenario에서 실제 Wall Time만을 권위 기준으로 삼지 않는다.

결정적 Budget 예:

- Spatial Query 수
- Transaction Mutation·Event 수
- Subscriber Retry 수
- Projection Byte와 Record 수
- ViewModel Recompute 수
- Allocation Class와 Collection 크기
- Scheduler Step 수
- Trace Record 수

실제 Frame, CPU와 Network Latency는 별도 Benchmark·Roblox Integration 환경에서 측정한다.

두 종류를 혼합하지 않는다.

```text
Logical Cost Regression
≠ Machine-dependent Timing Regression
```

## 25. 필수 Baseline Scenario Catalog

초기 구현 전에 최소 다음 Scenario를 등록한다.

1. **같은 Item 동시 획득**
   - 정확히 하나의 Command만 Commit
   - Item Location 단일성 유지
2. **탐험 이동 중 Encounter 전환**
   - Freeze Scope와 이동·Encounter 상태 원자성
3. **Reaction 대기 중 Reconnect**
   - Prompt 복원과 중복 응답 방지
4. **Commit 직후 Server Restart**
   - 피해·자원·Event의 중복 또는 부분 적용 없음
5. **Rollback 이후 이전 Event Retry**
   - 이전 Epoch Subscriber의 Follow-up 차단
6. **8시간 휴식 중 2시간 지점 습격**
   - 중간 Checkpoint에서 시간 진행 중단
7. **숨은 함정 Hover·Search·Diagnostics**
   - Player Artifact에 Secret Canary 없음
8. **Presentation ACK 유실**
   - Gameplay Outcome 유지와 Reveal Fallback
9. **활성 실행 중 Policy 변경**
   - 진행 중 실행은 기존 Frozen Snapshot 유지
10. **Encounter Round Boundary 재시도**
    - Campaign Time은 정확히 6초 한 번만 증가
11. **Rollback 후 UI 복구**
    - 이전 Prompt·Button 폐기, Layout Preference 유지
12. **Projection Batch Drop과 Catch-up**
    - Gap 동안 입력 Gate, 복구 후 동일 ViewModel

## 26. 확장 Registry

```text
SimulationRegistry
├─ scenarioSchemaRegistry
├─ fixtureTypeRegistry
├─ deterministicAdapterRegistry
├─ faultPointRegistry
├─ assertionRegistry
├─ normalizationProfileRegistry
├─ artifactSerializerRegistry
├─ shrinkerRegistry
└─ suiteRegistry
```

새 Domain은 등록된 Fixture Builder, Assertion과 Fault Point를 추가할 수 있다. 자유 Luau Callback을 Scenario 데이터에 저장하지 않는다.

## 27. 보안과 데이터 분류

- Scenario Fixture는 합성 데이터가 기본이다.
- Production Incident 변환은 명시적인 권한과 Redaction을 요구한다.
- Player Projection Artifact에 DM Secret이 들어가면 테스트 결과 자체도 보안 Incident로 분류한다.
- Root Seed가 미래 Production Random 결과를 예측할 수 있는 구조를 만들지 않는다.
- Artifact에는 인증 Token, DataStore Credential과 개인 식별 정보를 넣지 않는다.
- Golden·Trace·Snapshot Artifact는 데이터 분류와 보존 정책을 가진다.
- Test Harness가 Production Campaign에 Command를 제출할 수 없도록 환경과 Credential을 분리한다.

## 28. 실패와 안전 상태

### Fixture Version 누락

자동으로 최신 Version을 사용하지 않고 `FIXTURE_VERSION_UNAVAILABLE`로 실패한다.

### Policy·Build Hash 불일치

Scenario를 실행하지 않고 Version Drift Diff를 제공한다.

### 결정성 위반

같은 입력을 반복 실행해 Digest·Event·Projection이 달라지면 `NONDETERMINISTIC_RUNTIME_OBSERVED` Incident를 생성한다.

### Quiescence 미도달

남은 Runnable Task, Reservation, Outbox, Prompt와 Schedule을 구조화해 보고한다.

### Fault Point 미존재

비슷한 임의 위치에 Fault를 주입하지 않고 Scenario Compile을 실패시킨다.

### Artifact Budget 초과

핵심 실패 정보와 최소 재현 자료를 우선 보존하고 Cosmetic Trace와 중복 Snapshot을 축약한다.

## 29. 역할 경계

### 콘텐츠·시스템 개발자

Scenario, Fixture와 의미 Assertion을 작성한다. 생산 규칙을 Test Harness 안에 복제하지 않는다.

### QA·플레이테스터

Scenario Suite와 Incident Replay를 실행하고 최소 재현 Artifact를 공유한다. 비밀 Raw Data 접근은 별도 권한을 따른다.

### DM·일반 플레이어

일반 제품에서는 Test Harness를 사용해 Production Campaign을 변경하지 않는다. 허용된 Support Bundle과 Error Reference만 제공할 수 있다.

### CI·System

고정 Version, Seed, Schedule과 Budget으로 Suite를 실행하고 Artifact를 보존한다. 실패를 임의 Retry로 숨기지 않는다.

## 30. 구현 분할

```text
1. Scenario·Fixture Schema와 Compiler
2. Deterministic RNG·Clock·ID Adapter
3. Headless Runtime Bootstrap과 Canonical State Digest
4. Action Schedule·Virtual Transport·Quiescence
5. Assertion·Golden·Diff Engine
6. Fault Point Registry와 Restart·Rollback Driver
7. Virtual Client·Projection·UI Harness
8. Bounded Interleaving Exploration과 Shrinker
9. Disclosure Canary Scanner와 Audience Matrix
10. CI Suite·Artifact·Incident Replay Integration
11. Roblox Integration Adapter
```

## 31. 구현 명세 준비도

이 문서는 Simulation Foundation 구현 명세를 작성할 수 있는 수준이다.

다음 구현 명세 후보:

- `specs/testing/001-scenario-fixture-schema-and-compiler.md`
- `specs/testing/002-deterministic-rng-clock-id-and-scheduler-adapters.md`
- `specs/testing/003-headless-runtime-bootstrap-state-digest-and-quiescence.md`
- `specs/testing/004-virtual-network-client-reconnect-and-projection-harness.md`
- `specs/testing/005-fault-injection-restart-rollback-and-recovery-driver.md`
- `specs/testing/006-assertion-golden-diff-and-disclosure-scanner.md`
- `specs/testing/007-bounded-interleaving-explorer-and-failure-shrinker.md`
