# Main System Guide: Diagnostics, Simulation과 Operations

- Guide Status: CURRENT
- 적용 시스템 상태: GUIDE_CURRENT
- 작성일: 2026-08-05
- 마지막 권위 문서 검토일: 2026-08-05
- Completion Audit: [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)
- 대체하는 Guide: 없음
- 대체된 Guide: 없음

> 이 Guide는 기존 권위 문서를 연결하고 설명한다. 새로운 규칙·결정·API·데이터 구조를 정의하지 않는다.

## 1. 시스템 목적과 사용자 결과

이 Guide는 RVTT의 한 사용자 입력이 Command·RuleExecution·Transaction·Domain Event·Projection·UI·Presentation을 통과하는 전체 경로를 구조화된 Trace로 연결하고, 오류·성능·복구 상태를 역할별로 안전하게 설명하며, 발견된 문제를 생산 Runtime과 같은 경로에서 결정적으로 재현·검증하는 흐름을 설명한다. Operations는 별도 Gameplay Authority가 아니라 Diagnostics의 Health·Incident·Support 정보와 Persistence·Session의 기존 Recovery Command를 연결하는 운영 표면이다.

사용자와 운영자에게 보장하는 결과:

- 하나의 입력이 Network Ingress부터 UI·Presentation까지 동일한 Server 발급 `traceId`, Span과 Causation Graph로 연결된다.
- Client가 Server Trace Identity, Command 성공 여부와 Authority 결과를 임의로 확정하지 못한다.
- Command Authorization, Readiness, Precondition, Policy, Modifier, Target Validation과 Projection Disclosure 결정이 구조화된 Decision Record로 남는다.
- Trace는 단일 호출 Tree에 한정되지 않고 Domain Event Fan-out, Subscriber, Retry와 Transaction Join을 타입 있는 Causation Link로 표현한다.
- Command·RuleExecution·Transaction의 상세 Span을 Sampling하더라도 최소 Terminal Marker와 핵심 Authority Reference를 유지한다.
- Transaction Abort, Rollback·Recovery, Projection Gap, Security·Disclosure 위반 후보, Dead Letter, Reservation 누수와 Hard Budget 초과를 일반 성공 Sampling으로 제거하지 않는다.
- Diagnostics는 Gameplay 결과를 관찰하며 Transaction Commit·Abort, Rule 적격성, Recovery State와 Domain Mutation을 직접 결정하지 않는다.
- 일반 Observability Trace, 권위 복구용 Recovery Journal과 DM Override·권한 변경에 필요한 Mandatory Audit Record를 서로 다른 자료로 유지한다.
- 일반 Trace 저장 실패와 Diagnostic Export 실패가 이미 검증된 Gameplay Transaction을 되돌리지 않는다.
- Raw Trace를 Player·DM·Developer에게 그대로 제공하지 않고 Role·Campaign Scope·Ownership·Knowledge·Disclosure와 Security Redaction을 적용한 Diagnostic Projection을 반환한다.
- Player는 자신의 공개 가능한 Command 상태, 안전한 오류 이유, 재시도·Resync 안내와 Support Reference만 확인한다.
- DM은 현재 Campaign의 Gameplay·Scene Authoring Trace, Policy·Rule·Compiler 설명, Health와 복구가 필요한 Incident를 확인한다.
- Developer·Operator는 권한이 부여된 기술 Span, Handler Version, Queue, Budget와 Sanitized Incident Bundle만 확인한다.
- 비밀 Actor·함정·문·DC·Modifier, Journal 원문, Secret Scene Source와 내부 Runtime ID가 Diagnostic Index·Read Result·Export를 통해 권한 밖으로 유출되지 않는다.
- Authority Trace, Rule Decision, Operational Metric, Security·Audit Reference, Client Experience와 Health·Incident 자료를 하나의 무제한 문자열 로그로 합치지 않는다.
- Runtime·Command·Query·Subscriber·UI Surface는 등록된 CPU·Allocation·Byte·Record·Queue·Retry·Query Budget Profile로 관찰된다.
- Diagnostics 자체 Budget 초과 시 Routine Success Detail과 Cosmetic Detail부터 축약하고 Critical Incident·Terminal Marker·Security Observation을 우선 보존한다.
- Diagnostic Record가 Drop되면 제한된 `diagnostics.records_dropped` Observation을 남기되 재귀적 폭주를 만들지 않는다.
- Error는 Raw 문자열이 아니라 안정적 Error Code, Category, Severity, Retry·Resync·DM Action 필요 여부와 안전한 사용자 메시지로 표현된다.
- 반복되거나 중대한 Error는 `open → acknowledged → mitigating → resolved → archived` Incident 수명주기로 집계된다.
- Subsystem Health는 `healthy`, `degraded`, `recovering`, `blocked`, `unavailable` 상태와 이유·Incident·Queue·Budget·Dependency 요약을 제공한다.
- Health는 Gameplay State를 대체하지 않으며, 실제 Command 제한은 Session Readiness·Safety Policy가 별도로 결정한다.
- Diagnostic Read는 Trace·Incident·Health·Budget을 조회하고 허용 가능한 후속 Action을 제안할 수 있지만 복구 Command를 자동 실행하지 않는다.
- UI는 `retry`, `wait`, `resync`, `reopen_view`, `ask_dm`, `report_issue`, `no_action_required`를 구분하고 권위 결과가 불확실할 때 성공·실패를 추측하지 않는다.
- Support Reference는 사용자에게 Raw Trace 전체를 노출하지 않고 서버의 Trace·Incident Mapping으로 연결한다.
- Incident Bundle은 Sanitized Trace Graph, AuthorityEpoch·Revision 범위, Policy·Build Hash, Command·Transaction·Projection·Client Experience·Budget 요약과 Redaction Manifest를 제공한다.
- Incident Bundle에 Recovery Snapshot 전체, 인증 정보, 비밀 Journal 원문, 임의 Workspace Dump와 실행 가능한 Luau를 자동 포함하지 않는다.
- Simulation은 Versioned Scenario·Fixture, Frozen Ruleset·Policy·Build Reference, 결정적 RNG·Clock·ID·Scheduler·Network·Storage Adapter로 생산 Runtime 경로를 그대로 실행한다.
- Test Harness는 별도 Gameplay 규칙 엔진, Test-only Authorization 우회, Store 직접 수정과 Transaction 없는 Fixture 주입을 사용하지 않는다.
- 같은 Scenario Version, Fixture, Seed Plan과 Action Schedule은 같은 결정적 권위 결과를 만든다.
- RNG는 Roll·Initiative·Table·AI·Fixture 등 의미별 Named Stream을 사용해 무관한 Random Draw 추가가 다른 결과를 연쇄 변경하지 않게 한다.
- Production Incident 재현을 위해 Production Root RNG Seed를 Export하지 않고 확정된 RollRecord·Decision Record 또는 합성 Seed Scenario를 사용한다.
- Timeout·Lease·Retry는 Virtual Monotonic Clock으로, Campaign Time은 실제 TimeAdvance·Encounter Boundary로, Presentation Timeout은 별도 Presentation Clock으로 검증한다.
- Command·Task·Subscriber·Network Message 순서는 현실 Sleep과 Thread 운이 아니라 명시적 Deterministic Schedule로 통제한다.
- 동시성은 정확한 Interleaving과 등록된 Yield Point·Ordering Key를 사용하는 Bounded Exploration으로 검증한다.
- Fault는 Network, Subscriber, Storage, Transaction, Presentation, Client, Restart와 Rollback의 등록된 Boundary에서만 주입한다.
- Domain Mutation 중간을 임의 Monkey Patch해 생산 시스템에 존재하지 않는 부분 상태를 만들지 않는다.
- Scenario는 Authority State뿐 아니라 Command·Transaction 결과, Event·Subscriber, Projection, UI ViewModel, Trace, Resource Leak, Budget, Quiescence와 Negative Disclosure를 함께 검사한다.
- 동일 Authority State를 DM, Player, Observer와 DM-as-Player Preview로 투영해 Secret Canary가 직렬화 Byte, ID, Index, UI, Error, Diagnostics, Cache와 Presentation Parameter에 존재하지 않는지 검사한다.
- Restart는 검증된 Snapshot과 Commit Journal, Reconnect는 Protocol·Projection Catch-up·Ready Gate, Rollback은 Branch와 새 AuthorityEpoch의 생산 절차를 사용한다.
- 이전 AuthorityEpoch의 Command·Prompt·Subscriber·Schedule·Client Report가 새 Branch의 권위 상태나 Incident를 변경하지 못한다.
- 실패한 Scenario는 Scenario·Fixture·Version·Hash, Named Stream, 최소 Action Schedule, Fault Plan, 실패 Assertion, State·Projection·Trace Diff와 최소화된 Interleaving을 보존한다.
- Headless Harness는 Production Runtime의 의미·복구·Disclosure를 검증하고, 실제 Roblox Integration Suite는 Transport·Instance·Streaming·Client 경계를 별도로 검증한다.
- PR Required, Merge Regression, Nightly Exploration, Release Gate와 Manual Incident Replay 실행 등급을 분리한다.
- Required Suite 실패를 무제한 Retry로 숨기지 않고 Flaky 결과를 결정적 입력 누락 또는 외부 Adapter 오염으로 분류한다.
- 결정적 Logical Cost와 실제 CPU·Frame·Network Latency를 분리해 성능을 검증한다.
- Server 장애 복구와 정상 종료는 Persistence 계약의 Writer Lease, Manifest·Chunk Integrity, Commit Marker, Journal Flush, 새 AuthorityEpoch와 Full Resync 절차를 사용한다.
- 자동 복구가 안전하지 않으면 `recovery_review_required` 상태에서 손상 범위와 선택 가능한 Checkpoint를 DM에게 제시하고 별도 Recovery Command를 요구한다.
- Operations 담당자가 Incident를 확인하거나 Bundle을 생성했다는 이유만으로 HP·Item·Turn·Scene·Journal과 Authoring Source가 변경되지 않는다.

적용 범위:

- Trace Context, Span, Causation Graph와 Authority Reference
- Diagnostic Record·Observation·Decision Record Registry
- Authorization·Rule·Policy·Projection 설명
- Permission-aware Diagnostic Projection·Index와 Redaction
- Sampling, Retention Class, Buffer, Backpressure와 Drop Policy
- CPU·Allocation·Byte·Queue·Retry·Query·UI·Presentation Budget
- Error Record, Incident Lifecycle와 Subsystem Health
- Diagnostic Read, Support Reference, Client Report와 Incident Bundle
- Recovery·Rollback·Reconnect의 Epoch-aware Trace 연결
- Versioned Scenario·Fixture·Frozen Reference와 Scenario Compiler
- Deterministic RNG·Clock·ID·Scheduler·Network·Storage·Client Adapter
- Action Schedule, Quiescence와 Stop Condition
- Bounded Interleaving Exploration과 Failure Shrinker
- Registered Fault Point와 Restart·Rollback Driver
- State·Event·Projection·UI·Trace·Budget·Disclosure Assertion
- Canonical State Digest, Golden Diff와 Semantic Invariant
- CI Suite, Regression Catalog, Incident Replay와 Artifact Lifecycle
- Normal Shutdown, Server Recovery, Writer Lease와 Recovery Review의 검증
- Player, DM, QA, Developer, Operator와 System 역할 경계

명시적 비범위:

- Diagnostics가 Gameplay State, Rule Result, Transaction과 Recovery State를 직접 수정하는 기능
- Trace를 Recovery Journal이나 Mandatory Audit Record의 대체 원본으로 사용하는 구조
- 외부 Monitoring Vendor, 저장 Backend와 운영자 Web Dashboard의 확정
- 실제 Sampling 비율, Retention 기간, Buffer 크기와 Budget 수치의 선결정
- 사용자 행동 분석, 광고용 Analytics와 무제한 원문 수집
- Raw Server Log·Stack·Credential·Security Rule을 Player에게 공개하는 기능
- Trace만으로 Gameplay를 완전히 재생하는 기능
- Test Harness 안에 별도 규칙 엔진이나 Test-only Mutation API를 만드는 기능
- 현실 Sleep, 전역 Random Cursor와 실제 Thread Scheduling에 의존한 재현
- Headless Harness만으로 Roblox Engine 경계를 완전히 검증했다는 주장
- Production Root RNG Seed와 실제 Campaign Snapshot을 일반 Test Artifact로 Export하는 기능
- Operations가 DM 대신 규칙 판정을 고치거나 자동 Rollback을 실행하는 기능
- 음악, NPC 대화 시스템과 모든 규칙 효과음

## 2. 전체 구조

### End-to-End Diagnostics

```text
Client Intent
→ Network Command Ingress
→ Authorization·Validation
→ RuleExecution 또는 Domain Operation
→ Ordering·Transaction
→ Domain Event·Subscriber
→ Projection·Client Replica
→ UI·Presentation
→ Correlated Trace Graph·Decision·Budget Observation
→ Permission-aware Diagnostic Projection
```

### Health·Incident·Support

```text
Error·Integrity·Budget·Queue Observation
→ Error Fingerprint·Incident Rule
→ Incident Lifecycle·Subsystem Health
→ Role별 Diagnostic Read
→ Support Reference 또는 Sanitized Incident Bundle
→ 별도 Retry·Resync·Recovery Command 제안
```

### Production-parity Simulation

```text
Versioned Scenario·Fixture
+ Frozen Ruleset·Policy·Build
+ Deterministic Input·Action Schedule·Fault Plan
→ Headless Production Runtime Boot
→ Production Command·Transaction·Event·Projection·UI 실행
→ State·Event·Projection·UI·Trace Artifact
→ Semantic·Recovery·Disclosure·Budget Assertion
→ 실패 축소·재현 Artifact
```

### Recovery Operations

```text
Health·Incident·Persistence Diagnostic
→ 최신 완료 Manifest·Commit Marker·Journal·Lease 검증
→ 자동 복구 가능성 또는 recovery_review_required 판정
→ 승인된 Recovery·Rollback·Resync Command
→ 새 AuthorityEpoch·Full Projection Resync
→ Regression Scenario와 Incident 상태 갱신
```

Diagnostics와 Simulation은 이 흐름을 관찰·검증한다. 실제 State 복구와 Branch 전환은 Persistence·Session Runtime이 소유한다.

## 3. 주요 데이터 흐름

### 3.1 Trace Context와 인과 Graph

```text
TraceContext
├─ traceId·currentSpanId·parentSpanId
├─ causationRefs·correlationId
├─ authorityEpoch
├─ campaign·session·scene Context
├─ actorRefs·policySnapshotRef
├─ buildRevisionRefs
├─ samplingClass
└─ disclosureClass
```

Server가 Trace Identity를 발급한다. 비동기 Queue·Subscriber·Retry를 넘을 때 Context를 명시적으로 전달하고, 호출 Stack이 끊어졌다는 이유로 무관한 새 Trace를 만들지 않는다.

### 3.2 Diagnostic Record와 Decision

```text
DiagnosticTraceHeader
→ Trace의 Root·Epoch·Terminal·Policy·Build·Retention 요약

DiagnosticSpanRecord
→ 단계·Handler·시작·종료·입출력 요약·Decision·Budget·Error·Authority Ref

DiagnosticObservation
→ 구조화된 Severity·Category·Dimension·Measurement·Reference

CommandDecisionRecord
→ Readiness·Authorization·Precondition·Concurrency·Rate Limit·Terminal Decision

RuleDecisionRecord
→ Frozen Policy·Capability·Modifier·Candidate·Chosen Result·Rejection

ProjectionDecisionRecord
→ Source Event·Audience·Disclosure·Included·Redacted·Leak Guard
```

Trace와 Decision은 실행 결과를 다시 계산하는 코드가 아니라 실제 실행 당시 Snapshot과 선택 결과를 설명하는 비권위 기록이다.

### 3.3 Permission-aware Diagnostic Projection

```text
Raw Diagnostic Record
+ Requester Role·Campaign Scope·Ownership·Knowledge
+ Redaction Rule·Disclosure Policy
→ Player-safe | DM Campaign | Operator Technical Projection
→ Diagnostic Read Result
```

Raw Trace를 하나의 무제한 검색 Index에 넣고 UI에서만 숨기지 않는다. 역할별 Index 또는 동일한 수준의 필드 Security Label을 강제한다.

### 3.4 Sampling, Budget와 Drop

```text
Runtime Observation
→ Budget Profile 측정
→ Soft Limit: Detail 축약·Sampling 상승·Warning
→ Hard Limit: Diagnostic Fallback·Incident
→ Priority Drop
→ Terminal Marker·Critical Incident 우선 보존
```

Gameplay Runtime 자체의 Hard Budget 초과에 대한 Timeout·Gate는 해당 Runtime 계약이 소유하고 Diagnostics는 결과를 기록한다.

### 3.5 Error, Incident와 Health

```text
DiagnosticErrorRecord
├─ stableErrorCode·category·severity
├─ retryable·resyncRequired·dmActionRequired
├─ safeUserMessageKey·technicalSummary
├─ fingerprint·Authority Ref
└─ firstSeen·lastSeen·occurrenceCount

→ Incident
→ SubsystemHealthState
→ Diagnostic Query·Support Surface
```

Health는 권위 State가 아니며 같은 Subsystem의 상태를 설명하는 운영 Projection이다.

### 3.6 Support Reference와 Incident Bundle

```text
Safe UI Error
→ SupportReference(shortReferenceCode)
→ Server Trace·Incident Mapping
→ Permission-aware Diagnostic Read

Incident
→ Sanitized Trace·Version·State Range·Budget·Client Report
→ Redaction Manifest
→ Content Hash
→ Incident Replay Scenario의 안전한 입력 근거
```

Bundle은 실행 가능한 코드나 Raw Authority Snapshot이 아니다.

### 3.7 Scenario와 Fixture

```text
SimulationScenarioDefinition
├─ stable scenarioId·scenarioVersion
├─ Fixture·Ruleset·Policy·Build Ref
├─ Participants·Audience
├─ Deterministic Input Plan
├─ Action Schedule·Fault Plan
├─ Stop Condition·Assertion Plan
└─ Artifact Policy·Execution Budget

SimulationFixtureManifest
├─ stable fixtureId·fixtureVersion
├─ Source·Content·Policy·Build Ref
├─ Materialization Steps
├─ Secret Canaries
├─ Integrity Hash
└─ Synthetic Data Classification
```

누락된 Version을 최신 값으로 자동 대체하지 않는다. Fixture는 합성 데이터가 기본이며 Production Loader·검증된 Materializer로 권위 초기 상태를 만든다.

### 3.8 Deterministic Adapter와 Schedule

```text
Controlled Adapter
├─ Named RNG Streams
├─ Authority Monotonic Clock
├─ Deterministic ID Factory
├─ Task·Message Scheduler
├─ Virtual Network·Client
├─ Storage·Restart Driver
└─ Presentation ACK Adapter

Action Schedule
→ submit command·respond prompt·advance time
→ connect·disconnect·restart·rollback
→ release message·run subscriber·ack presentation
→ assert checkpoint
```

Domain Handler, RuleExecution, Transaction, Event, Projection과 UI Selector는 Production 구현을 그대로 사용한다.

### 3.9 Assertion와 Artifact

```text
Simulation Assertion
→ Authority State·Semantic Digest·Domain Invariant
→ Command·Transaction·Event·Subscriber
→ Projection·UI·Trace·Policy·Build Binding
→ Resource Leak·Budget·Negative Disclosure·Quiescence

Failure
→ Seed·Schedule·Fault·Input 축소
→ 최소 재현 Artifact
→ Regression Catalog
```

Trace ID·Wall Timestamp·Storage Locator 같은 비의미 값은 Normalization하고 Stable ID·권위 의미 상태를 Canonical Order로 비교한다.

## 4. 주요 실행 흐름

### 4.1 성공한 Command의 End-to-End Trace

```text
Client Intent
→ Client Interaction ID
→ Server Trace 발급
→ Authorization·Validation Decision
→ RuleExecution·Transaction Span
→ Commit·Outbox·Subscriber
→ Projection Build·Stream
→ Replica Apply·ViewModel·Presentation
→ Terminal Marker와 Budget Summary
```

Presentation 또는 UI 진단 실패는 이미 Commit된 Gameplay 결과를 변경하지 않는다.

### 4.2 거부된 Command 설명

```text
Command 수신
→ Role·Control·Ready·Precondition·Policy 검사
→ 구조화된 Rejection Code
→ Player-safe Diagnostic Projection
→ Retry·Wait·Resync·Ask DM 안내
→ Support Reference
```

비공개 Target의 존재나 내부 거부 조건을 Player 오류 메시지로 공개하지 않는다.

### 4.3 Projection·UI 단절 조사

```text
Transaction Commit 확인
→ Domain Event·Projection Batch Ref 확인
→ Projection Stream·Client Cursor 확인
→ Replica Apply·ViewModel Span 확인
→ Gap·Stale Epoch·Component Error 분류
→ Catch-up·Full Resync 또는 View Reopen 제안
```

Diagnostic Read가 Client Store를 직접 수정하지 않는다. 실제 Resync는 Networking·Session Command를 사용한다.

### 4.4 Budget 초과와 Degradation

```text
Soft Budget 초과
→ Warning Observation
→ Detail 축약·Sampling 조정

Hard Diagnostic Budget 초과
→ 낮은 우선순위 Record Drop
→ Incident·Self-health 갱신

Gameplay Runtime Hard Budget 초과
→ 해당 Runtime의 안전 실패·Gate
→ Diagnostics가 결과 기록
```

### 4.5 Incident 생성과 운영 처리

```text
반복 Error·Dead Letter·Integrity·Disclosure·Budget Observation
→ Fingerprint·Incident Rule 평가
→ Incident open
→ Operator 또는 DM acknowledge
→ Mitigation Command·Recovery 계획 실행
→ Health recovering
→ 검증 Scenario·Projection·Integrity 통과
→ Incident resolved·archived
```

Incident 상태 변경이 원래 Gameplay Transaction을 다시 Commit하거나 취소하지 않는다.

### 4.6 Client Report와 Support

```text
Client Error Boundary·Presentation Failure
→ Sanitized ClientDiagnosticReport
→ Schema·Size·Rate·Connection Epoch 검증
→ Server Trace와 제한적으로 연결
→ Support Reference·Incident 후보
```

Client 보고의 Authority ID·성공 여부·시간을 그대로 신뢰하지 않는다.

### 4.7 Incident Bundle 생성

```text
허가된 Diagnostic Read
→ Incident·Trace·Version·Budget 범위 선택
→ Secret·Credential·Personal Data Redaction
→ Sanitized Bundle·Redaction Manifest·Hash
→ QA·Developer에게 허용된 Artifact 제공
```

Bundle 생성 실패가 원본 Trace와 Gameplay State를 손상시키지 않는다.

### 4.8 Scenario Compile과 Boot

```text
Scenario ID·Version 선택
→ Fixture·Ruleset·Policy·Build Hash 검증
→ Schema·Fault Point·Assertion 유효성 검사
→ 격리된 Production Runtime Boot
→ Deterministic Adapter 주입
→ Initial Authority State Materialize
```

Version이나 Fault Point가 없으면 비슷한 최신 값이나 임의 위치로 대체하지 않고 Compile을 실패시킨다.

### 4.9 결정적 정상 Scenario

```text
Action Schedule 실행
→ Runnable Task 결정적 선택
→ Command·Event·Projection·UI 처리
→ Quiescence 또는 명시 Stop Condition
→ Semantic Digest·Invariant·Budget Assertion
→ Artifact 보존
```

단순히 마지막 Command를 제출했다는 이유로 Scenario를 종료하지 않는다. 미처리 Outbox, Transaction, Reservation, Due Scheduler와 허용되지 않은 Prompt가 없어야 한다.

### 4.10 동시성 Exploration

```text
등록된 Conflict·Yield Point 수집
→ Bounded Interleaving 분기
→ Ordering·Reservation·Commit 실행
→ State Hash Pruning·Symmetry Reduction
→ 단일성·Idempotency·Leak Assertion
→ 실패 Schedule 최소화
```

독립 Ordering Key를 불필요하게 전역 직렬화하지 않았는지도 함께 검증한다.

### 4.11 Fault Injection

```text
등록된 Fault Point 도달
→ timeout·drop·duplicate·reorder·delay·disconnect·restart 등 주입
→ 생산 Error·Retry·Recovery 경로 실행
→ Authority·Projection·Incident 결과 검사
```

Transaction 중간의 임의 메모리 값을 바꾸는 방식은 사용하지 않는다.

### 4.12 Restart Recovery Scenario

```text
지정된 Commit·Storage Fault Point에서 Server 종료
→ Writer Lease·최신 완료 Manifest 탐색
→ Chunk·Journal·Commit Marker 검증
→ Snapshot Materialization·Pending Execution 복원
→ 새 AuthorityEpoch
→ Index·Projection 재생성
→ Client Full Resync
→ 중복·부분 적용·Leak Assertion
```

Commit Marker가 없는 In-flight Transaction은 폐기하고, Marker가 있는 Transaction은 결과를 복원한다.

### 4.13 Rollback Scenario

```text
Rollback Checkpoint 선택
→ 현재 Branch 동결
→ Manifest·Delta 검증
→ 새 Branch·AuthorityEpoch
→ 권위 State Materialize
→ 이전 Command·Prompt·Subscriber·Schedule 무효화
→ Full Projection Resync
→ Semantic·Disclosure·Idempotency Assertion
```

Rollback 이전 Trace는 역사 Branch로 남을 수 있지만 새 Branch Incident와 실행을 변경하지 않는다.

### 4.14 Reconnect와 Projection Gap

```text
Client Disconnect 또는 Batch Drop
→ Connection·Projection Epoch 검증
→ Snapshot·Event Catch-up 또는 Full Resync
→ Prompt·Selection·Input Context 재투영
→ 이전 Epoch UI Intent 폐기
→ 동일 ViewModel·Command 상태 Assertion
```

### 4.15 Negative Disclosure Scenario

```text
Authority Fixture에 Secret Canary 배치
→ DM·Player·Observer·Preview Projection 생성
→ Snapshot·Event·UI·Error·Diagnostic·Cache·Presentation 검사
→ 권한 밖 Canary 값·ID·관계 발견 시 Security Failure
```

화면에서 숨겼다는 사실만으로 통과하지 않는다.

### 4.16 Incident Replay와 Regression 승격

```text
Sanitized Incident Bundle
→ 합성 Fixture·Scenario 초안
→ 권한 있는 개발자가 Version·Assertion·Fault를 검토
→ 결정적 재현
→ 최소 실패 Artifact
→ Regression Catalog 등록
→ PR·Merge·Release Suite에 배치
```

Production Root Seed와 실제 사용자 원문은 Scenario에 포함하지 않는다.

### 4.17 정상 서버 종료 검증

```text
새 Command 접수 중지
→ 진행 Transaction 안전 경계
→ Pending Execution 저장 가능성 확인
→ Journal Flush·Snapshot 시도
→ Manifest 검증·Session 종료 Commit
→ Writer Lease 해제
→ 다음 Boot Recovery 검증
```

Snapshot이 시간 안에 끝나지 않아도 Journal이 내구적으로 Flush되었다면 마지막 Snapshot 이후 기록으로 복구 가능한지 확인한다.

### 4.18 Recovery Review 운영 흐름

```text
Integrity·Commit 여부 자동 판정 불가
→ recovery_review_required Incident
→ 손상 범위·후보 Checkpoint의 Permission-aware Projection
→ DM이 복구 지점 선택
→ Persistence Recovery Command
→ 새 Branch·Epoch·Full Resync
→ Integrity·Regression Scenario 검증
```

Diagnostics Panel이나 Operator Query가 직접 Store를 덮어쓰지 않는다.

## 5. 문서 관계도

### Parent Authority

- [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md) — Authority와 Projection·Presentation·Diagnostics 분리의 최상위 원칙
- [`Networking Command, Event와 Client Synchronization`](../../architecture/networking-command-event-and-client-synchronization-contract.md) — Command Receipt·Result, Projection Stream, Connection Epoch와 Resync
- [`Command Ordering, Logical Time와 Transaction Coordinator`](../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md) — Ordering·Reservation·Prepare·Commit·Abort와 동시성 경계
- [`Domain Event, Outbox, Subscription과 Projection`](../../architecture/domain-event-outbox-subscription-and-projection-runtime-contract.md) — Event Causation, Subscriber Retry·Dead Letter와 Projection Barrier
- [`Persistence, Snapshot, Journal과 Recovery`](../../architecture/persistence-and-session-recovery-model.md) — Snapshot·Commit Journal·Writer Lease·Restart·Rollback·Migration
- [`Ruleset Policy Registry, Composition과 Frozen Snapshot`](../../architecture/ruleset-policy-registry-composition-and-frozen-snapshot-runtime-contract.md) — 실행 당시 Policy Binding과 Version 재현

### Child Authority

- [`Diagnostics, Observability, Correlated Trace와 Incident Runtime 계약`](../../architecture/diagnostics-observability-correlated-trace-and-incident-runtime-contract.md) — Trace·Decision·Budget·Incident·Health·Support·Redaction의 공통 계약
- [`Deterministic Simulation, Scenario와 Test Harness Runtime 계약`](../../architecture/deterministic-simulation-scenario-and-test-harness-runtime-contract.md) — 생산 경로 기반 Scenario·Fixture·Adapter·Fault·Assertion·CI 계약
- [`Diagnostics 시스템`](../../systems/diagnostics/README.md) — Diagnostics 권위 문서와 영역별 Trace 진입점
- [`Testing과 Simulation 시스템`](../../systems/testing/README.md) — Scenario 흐름, Test 계층과 Baseline Catalog

### References

- [`Session, Networking, Persistence와 Recovery Guide`](../session/README.md) — 실제 Reconnect·Restart·Rollback·Ready Gate와 사용자 복구 흐름
- [`Runtime Foundation과 Authority Guide`](../runtime/README.md) — Command·Transaction·Event·Projection·Recovery의 공통 수명주기
- [`UI, Camera와 Presentation Guide`](../ui/README.md) — Replica·ViewModel·Error Boundary·Client Report·Presentation Failure
- [`Scene Editor와 Authoring Guide`](../scene-editor/README.md) — Tool·Compiler·Publish·Live Patch Diagnostics와 결정성 Scenario
- [`Journal과 Ping Guide`](../journal/README.md) — Permission-aware Search·Anchor·Navigation과 Diagnostic Redaction
- [`Combat와 Encounter Guide`](../combat/README.md) — Encounter Timeline·Reaction·Temporal Boundary와 Rollback Scenario
- [`Character, Inventory와 Downtime Guide`](../character/README.md) — Item Race, Recovery, Long Activity와 Atomic Completion Scenario
- [`Cross-Domain Outcome Cascade와 Integration Boundary`](../../architecture/cross-domain-outcome-cascade-and-integration-boundary-runtime-contract.md) — Immediate Closure·Deferred Consequence·Projection Barrier와 Follow-up 멱등성
- [`Visibility, Knowledge와 Detection Runtime`](../../architecture/visibility-knowledge-detection-and-hover-information-runtime-contract.md) — Audience별 Secret Canary·Disclosure 검증
- [`UI Projection, ViewModel, Input Context와 Recovery Runtime`](../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md) — Client Error Boundary, Reconciliation과 Epoch-safe 복구
- [`Scene Compiler와 Compiled Runtime Scene`](../../architecture/scene-compiler-and-compiled-runtime-scene-contract.md) — Compiler 결정성·Budget·Diagnostic·Last Known Good
- [`Dice, Check, Save, Attack과 Resolution`](../../architecture/dice-roll-check-save-attack-and-resolution-runtime-contract.md) — RollRecord와 Named RNG 재현 근거
- [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md) — Diagnostics·Simulation Architecture 완료와 Guide 준비 판정

권위 읽기 순서에서 제외:

- `SUPERSEDED`, `DISCONTINUED`, `ARCHIVED` 상태의 로그·테스트·복구 문서
- 문자열 로그만으로 Authority 결과를 확정하는 이전 관례
- Test-only Store Mutation, 전역 Random Cursor와 Sleep 기반 동시성 관례
- Raw Trace·Snapshot·Secret Data를 일반 사용자에게 직접 제공하는 설계

## 6. 다른 시스템과의 경계

| 인접 시스템 | Diagnostics·Simulation·Operations가 제공하는 것 | 상대 시스템이 제공하는 것 | 권위 경계 문서 |
|---|---|---|---|
| Networking | Ingress·Result·Projection·Reconnect Trace와 Fault Adapter | Protocol, Connection Epoch, Command Status, Catch-up·Resync | Networking 계약 |
| Transaction | Prepare·Commit·Abort·Ordering·Reservation Observation과 Race Scenario | 실제 Ordering, Reservation과 원자 Commit | Transaction 계약 |
| Rule·Policy | Decision Trace와 Frozen Version Assertion | 실제 Capability·Modifier·Policy Composition과 Rule Result | Policy·Rule Runtime |
| Domain Event | Causation·Retry·Dead Letter·Projection Gap Observation | Outbox Commit, Subscriber Delivery와 Follow-up Command | Event Runtime |
| Persistence | Integrity·Queue·Lease·Recovery Incident와 Restart Scenario | Snapshot·Journal·Commit Marker·Branch·Epoch와 Recovery 실행 | Persistence 계약 |
| Session | Health·Ready·Reconnect·Rollback Support Projection | Command Gate, Transition, Pause와 실제 Resync·Rollback Command | Session 계약·Session Guide |
| UI·Presentation | Client Report, Replica·ViewModel·Playback Trace와 Failure Scenario | 실제 UI State, Reconciliation, Camera·Presentation Playback | UI Runtime·UI Guide |
| Visibility·Journal | Disclosure Decision·Secret Canary·Negative Assertion | Knowledge·ACL·Anchor·Search의 실제 공개 판정 | Visibility·Journal Runtime |
| Scene Authoring | Tool·Compiler·Build·Publish Trace와 Determinism Test | Scene Source, Compiler, Atomic Publish와 Live Patch | Scene Compiler·Authoring Guide |
| Gameplay Domain | Span·Decision·Budget Adapter와 Semantic Assertion | HP·Item·Effect·Encounter·Time 등 실제 권위 State와 Command | 각 Domain Authority |
| Diagnostics Storage | Sampling·Retention·Incident·Read Projection | 권위 State·Recovery Journal과 Mandatory Audit의 별도 저장 | Diagnostics·Persistence 계약 |
| CI·QA | Versioned Suite, Fixture, Artifact와 Incident Replay | 실행 환경, 승인 절차와 실제 Roblox Integration | Simulation 계약 |
| Extension | 등록된 Span·Observation·Budget·Fault·Assertion 확장점 | 신뢰된 Registry·Provider·Version·Capability 정책 | Diagnostics·Simulation, 후속 Extension Guide |

고정 경계:

- Diagnostics Adapter가 Gameplay Store를 직접 수정하지 않는다.
- Diagnostic Read가 Recovery·Resync·Rollback을 자동 실행하지 않는다.
- Simulation Fixture가 Store·Scene Source를 직접 수정하지 않는다.
- Test Harness가 Production Authorization·Transaction·Projection을 우회하지 않는다.
- Client Report와 Trace가 Authority State의 원본이 아니다.
- Trace·Metric·Health·Incident와 Recovery Journal·Mandatory Audit를 하나의 저장물로 합치지 않는다.
- Headless Logical Budget과 Roblox 실제 Timing Benchmark를 동일한 결과로 취급하지 않는다.
- 이전 Epoch Trace·Artifact·Retry가 현재 Branch State와 Incident를 변경하지 않는다.

## 7. 추천 읽기 순서

1. [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md)
   - Authority와 Diagnostics·Projection·Presentation 분리를 먼저 확인한다.
2. [`ADR-0084`](../../decisions/ADR-0084-correlated-authority-traces-and-permission-aware-observability.md)
   - Server Trace, Causation Graph, Redaction, Sampling과 Journal·Audit 분리 결정을 읽는다.
3. [`Diagnostics Runtime 계약`](../../architecture/diagnostics-observability-correlated-trace-and-incident-runtime-contract.md)
   - Record·Decision·Budget·Incident·Health·Support·Recovery 연결을 읽는다.
4. [`ADR-0085`](../../decisions/ADR-0085-production-parity-deterministic-scenarios-and-controlled-nondeterminism.md)
   - 생산 경로 재사용과 외부 비결정 요소 통제 결정을 읽는다.
5. [`Simulation과 Test Harness 계약`](../../architecture/deterministic-simulation-scenario-and-test-harness-runtime-contract.md)
   - Scenario·Fixture·Adapter·Schedule·Fault·Assertion·CI를 읽는다.
6. [`Persistence와 Recovery`](../../architecture/persistence-and-session-recovery-model.md)
   - Restart·Shutdown·Lease·Commit Marker·Rollback·Recovery Review의 실제 권위 흐름을 확인한다.
7. [`Networking`](../../architecture/networking-command-event-and-client-synchronization-contract.md), [`Transaction`](../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md), [`Domain Event`](../../architecture/domain-event-outbox-subscription-and-projection-runtime-contract.md)
   - Trace와 Fault가 연결되는 생산 경계를 확인한다.
8. [`Diagnostics 시스템`](../../systems/diagnostics/README.md)과 [`Testing 시스템`](../../systems/testing/README.md)
   - 영역별 진입점, Baseline Scenario와 후속 Spec 후보를 확인한다.
9. [`Session Guide`](../session/README.md)와 [`Runtime Guide`](../runtime/README.md)
   - 운영 화면이 제안하는 실제 Recovery·Resync·Rollback Command와 Authority 수명주기를 연결한다.
10. 대상 Domain Guide
    - Combat, Character, Scene, UI, Journal 등 실제 Assertion과 공개 경계를 확인한다.
11. [`Completion Audit`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)
    - 현재 Scope의 Architecture 완료와 Implementation Specs 진입 조건을 확인한다.

## 8. 구현·검증 순서

권위 문서의 구현 분할과 의존 관계를 따르면 다음 순서로 내려간다.

```text
Trace Context·Record·Error·Budget Registry
→ Server Span Collector·Async Context Propagation
→ Command·Rule·Policy·Projection Decision Adapter
→ Permission-aware Diagnostic Projection·Read Query
→ Metric·Budget·Health·Incident·Support Reference
→ Client Report·Incident Bundle·Retention
→ Scenario·Fixture Schema·Compiler
→ Deterministic RNG·Clock·ID·Scheduler Adapter
→ Headless Production Runtime Bootstrap·Canonical Digest
→ Virtual Network·Client·Storage·Presentation Harness
→ Fault Point·Restart·Rollback·Recovery Driver
→ Assertion·Golden·Disclosure Scanner·Quiescence
→ Bounded Interleaving Exploration·Failure Shrinker
→ CI Suite·Artifact·Incident Replay Integration
→ Roblox Integration·Benchmark·Release Gate
```

필수 검증 Scenario:

- Command부터 Projection·UI까지 Trace Causation 연속성
- Async Subscriber·Retry의 Parent·Causation·Epoch 유지
- Authorization·Policy·Rule 거부 이유의 구조화
- Player·DM·Operator Diagnostic Projection Redaction
- 최소 Terminal Marker와 Critical Incident Sampling 보존
- Diagnostics Budget 초과 시 우선순위 Drop과 Gameplay 결과 불변
- Diagnostic Collector·Export·Client Report 실패 격리
- Incident Fingerprint·Lifecycle·Health 상태 전이
- Support Reference가 Raw Secret·Stack·Credential을 노출하지 않음
- Incident Bundle Redaction·Hash·Version과 실행 코드 부재
- 같은 Scenario·Version·Seed·Schedule의 Digest·Event·Projection 동일성
- Named RNG Stream 독립성
- Virtual Monotonic Time과 Campaign Time 분리
- Item 동시 획득·Ordering·Reservation Leak
- Encounter 전환과 이동 Commit Race
- Reaction 대기 중 Reconnect와 중복 Prompt 응답 차단
- Commit 직후 Restart와 부분·중복 적용 방지
- Rollback 이후 이전 Event·Prompt·Schedule 차단
- 8시간 휴식 중 Scheduler Checkpoint 중단
- Projection Batch Drop·Duplicate·Reorder와 Catch-up
- Presentation ACK 유실 후 Gameplay Outcome 유지
- Policy 변경 중 진행 실행의 Frozen Snapshot 유지
- Audience Matrix의 Secret Canary Negative Disclosure
- Journal Search·Backlink·Anchor와 Scene Authoring Diagnostic 누출 차단
- Scene Compiler Partial·Full Build 결정성
- Quiescence 미도달·Retry Loop·Dead Letter 구조화
- Normal Shutdown·Journal Flush·Lease Release와 다음 Boot 복구
- Recovery Review에서 자동 Store 수정 금지와 선택 Checkpoint 적용
- Headless Logical Cost와 Roblox 실제 Timing Regression 분리

## 9. 변경 영향 지도

| 변경 유형 | 영향받는 권위 문서 | 영향받는 Specs | Guide 조치 |
|---|---|---|---|
| Trace Context·Record·Causation | Diagnostics, Networking, Event, Transaction | 향후 Diagnostics 001·002 | `UPDATE_REQUIRED` |
| Decision·Error·Redaction | Diagnostics, Policy, Rule, Visibility, UI | 향후 Diagnostics 003·004 | `UPDATE_REQUIRED` |
| Sampling·Retention·Budget·Health | Diagnostics, Persistence, UI | 향후 Diagnostics 003·005 | 필요 시 갱신, 경계 변경 시 `UPDATE_REQUIRED` |
| Incident·Support·Bundle | Diagnostics, Persistence, Security·Disclosure | 향후 Diagnostics 004·005 | `UPDATE_REQUIRED` |
| Scenario·Fixture·Version | Simulation, Policy, Persistence | 향후 Testing 001·003 | `UPDATE_REQUIRED` |
| RNG·Clock·ID·Scheduler Adapter | Simulation, Dice, Time, Transaction | 향후 Testing 002 | `UPDATE_REQUIRED` |
| Fault Point·Restart·Rollback | Simulation, Networking, Persistence, Event | 향후 Testing 004·005 | `UPDATE_REQUIRED` |
| Assertion·Digest·Disclosure | Simulation, Visibility, UI, Journal, Diagnostics | 향후 Testing 006 | `UPDATE_REQUIRED` |
| Interleaving·Shrinker | Simulation, Transaction, Event | 향후 Testing 007 | `UPDATE_REQUIRED` |
| Recovery·Shutdown·Writer Lease | Persistence, Session, Diagnostics | 향후 Persistence·Operations Specs | `UPDATE_REQUIRED` |
| 실행 등급·수치 Budget | Simulation, Diagnostics | CI·Benchmark 설정 | 의미 경계가 같으면 필요 시 갱신 |

## 10. Authority Documents

### Product

- [`Core Session Loop`](../../product/core-session-loop.md)
- [`Platform, Movement와 Input Scope`](../../product/platform-movement-and-input-scope.md)

### Architecture

- [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md)
- [`Diagnostics, Observability, Correlated Trace와 Incident Runtime 계약`](../../architecture/diagnostics-observability-correlated-trace-and-incident-runtime-contract.md)
- [`Deterministic Simulation, Scenario와 Test Harness Runtime 계약`](../../architecture/deterministic-simulation-scenario-and-test-harness-runtime-contract.md)
- [`Networking Command, Event와 Client Synchronization 계약`](../../architecture/networking-command-event-and-client-synchronization-contract.md)
- [`Command Ordering, Logical Time와 Transaction Coordinator 계약`](../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)
- [`Domain Event, Outbox, Subscription과 Projection Runtime 계약`](../../architecture/domain-event-outbox-subscription-and-projection-runtime-contract.md)
- [`Persistence, Snapshot, Journal과 Recovery 계약`](../../architecture/persistence-and-session-recovery-model.md)
- [`Ruleset Policy Registry, Composition과 Frozen Snapshot Runtime 계약`](../../architecture/ruleset-policy-registry-composition-and-frozen-snapshot-runtime-contract.md)
- [`UI Projection, ViewModel, Input Context와 Recovery Runtime 계약`](../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md)
- [`Visibility, Knowledge와 Detection Runtime 계약`](../../architecture/visibility-knowledge-detection-and-hover-information-runtime-contract.md)
- [`Cross-Domain Outcome Cascade와 Integration Boundary Runtime 계약`](../../architecture/cross-domain-outcome-cascade-and-integration-boundary-runtime-contract.md)

### Systems·UI

- [`Diagnostics 시스템`](../../systems/diagnostics/README.md)
- [`Testing과 Simulation 시스템`](../../systems/testing/README.md)
- [`Session 시스템`](../../systems/session/README.md)
- [`Event 시스템`](../../systems/events/README.md)
- [`Cross-System Integration 시스템`](../../systems/integration/README.md)

### Specs

후속 Implementation Specs 후보:

- `specs/diagnostics/001-trace-context-and-record-registry.md`
- `specs/diagnostics/002-server-span-collector-and-async-propagation.md`
- `specs/diagnostics/003-decision-trace-budget-and-health.md`
- `specs/diagnostics/004-permission-aware-query-and-support-reference.md`
- `specs/diagnostics/005-client-report-and-incident-bundle.md`
- `specs/testing/001-scenario-fixture-schema-and-compiler.md`
- `specs/testing/002-deterministic-rng-clock-id-and-scheduler-adapters.md`
- `specs/testing/003-headless-runtime-bootstrap-state-digest-and-quiescence.md`
- `specs/testing/004-virtual-network-client-reconnect-and-projection-harness.md`
- `specs/testing/005-fault-injection-restart-rollback-and-recovery-driver.md`
- `specs/testing/006-assertion-golden-diff-and-disclosure-scanner.md`
- `specs/testing/007-bounded-interleaving-explorer-and-failure-shrinker.md`

아직 생성되지 않은 Spec 경로는 이 Guide의 Authority 링크로 취급하지 않는다.

### Audits

- [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)
- [`Runtime Architecture Integration과 Engine Completeness 감사`](../../audits/runtime-architecture-integration-and-engine-completeness-audit.md)

## 11. ADR References

- [`ADR-0084`](../../decisions/ADR-0084-correlated-authority-traces-and-permission-aware-observability.md) — Server Correlated Trace, 구조화된 Record Registry, Permission-aware Projection, Sampling·Budget과 Journal·Audit 분리
- [`ADR-0085`](../../decisions/ADR-0085-production-parity-deterministic-scenarios-and-controlled-nondeterminism.md) — 생산 Runtime 재사용, Controlled Adapter, Versioned Scenario, Fault·Disclosure·Recovery 검증
- [`ADR-0042`](../../decisions/ADR-0042-authoritative-checkpoints-command-journal-and-session-recovery.md) — 권위 Checkpoint·Command Journal과 Session Recovery
- [`ADR-0043`](../../decisions/ADR-0043-encounter-turn-snapshot-timeline-and-dm-rollback.md) — Encounter Timeline과 DM Rollback
- [`ADR-0059`](../../decisions/ADR-0059-versioned-command-protocol-and-projection-stream-synchronization.md) — Versioned Command, Projection Cursor와 Client Synchronization
- [`ADR-0062`](../../decisions/ADR-0062-ordered-reservations-and-atomic-authority-transactions.md) — Ordering·Reservation과 Atomic Transaction
- [`ADR-0063`](../../decisions/ADR-0063-manifest-chunk-snapshots-commit-journal-and-branch-recovery.md) — Manifest·Chunk Snapshot, Commit Journal과 Branch Recovery
- [`ADR-0069`](../../decisions/ADR-0069-authoritative-roll-records-and-presentation-gated-resolution.md) — RollRecord와 재현 가능한 권위 굴림 결과
- [`ADR-0077`](../../decisions/ADR-0077-transactional-domain-events-with-outbox-and-projection-boundaries.md) — Transactional Outbox, Subscriber와 Projection Boundary
- [`ADR-0081`](../../decisions/ADR-0081-versioned-policy-composition-and-frozen-ruleset-snapshots.md) — Versioned Policy Composition과 Frozen Snapshot
- [`ADR-0083`](../../decisions/ADR-0083-projection-driven-ui-runtime-and-epoch-safe-client-recovery.md) — Projection-driven UI와 Epoch-safe Recovery

## 12. 알려진 비목표와 측정형 기본값

확정된 비목표:

- Diagnostics가 권위 State와 규칙 결과를 수정하지 않는다.
- Observability를 Recovery Journal과 Mandatory Audit의 대체물로 사용하지 않는다.
- Test Harness에 두 번째 규칙 엔진과 Test-only Mutation API를 만들지 않는다.
- Raw Trace, Stack, Snapshot, Production Seed와 Secret Campaign Data를 일반 사용자나 Artifact에 무제한 제공하지 않는다.
- 운영자 Web Dashboard와 외부 Monitoring Vendor를 현재 Architecture에서 고정하지 않는다.
- Diagnostics와 Simulation을 사용자 행동 분석·광고 Analytics로 사용하지 않는다.
- Trace만으로 전체 Gameplay Replay를 재구성하지 않는다.
- Headless Test만으로 Roblox Integration 완료를 주장하지 않는다.

측정으로 정할 기본값:

- 성공 Trace 상세 Sampling 비율
- Hot Trace Buffer의 시간·Byte·Record 상한
- 오류·보안·Rollback Incident Retention 기간
- Trace·Incident Bundle·Diagnostic Read 최대 크기
- Runtime·Command·Query별 CPU·Allocation·Byte Budget
- Client Report 전송 빈도와 Offline Queue 상한
- Diagnostics Panel 필터와 자동 경고 임계값
- PR Suite 실행 시간, 병렬 Worker와 Interleaving 탐색 상한
- Fixture·Golden·Artifact 크기와 보존 기간
- Property·Mutation·Soak 반복 수와 Shrink Budget
- Headless·Roblox Integration Suite 분담
- Logical Cost와 실제 Timing Regression Threshold
- Incident Bundle→Scenario 변환 Redaction 수준

Guide 작성 이후 남은 비차단 작업:

- 위 경계를 수직 Implementation Spec으로 구체화
- Stable Error·Span·Observation·Budget·Fault·Assertion Registry 목록 작성
- Baseline Scenario Fixture·Secret Canary·Expected Invariant 작성
- 실제 Roblox Benchmark와 Integration Environment 구성
- Retention·Sampling·Budget 기본값을 측정 후 확정

## 13. Guide 검증 체크리스트

- [x] 모든 핵심 문장이 Authority Document에 근거한다.
- [x] 새로운 제품 규칙이나 Architecture 결정을 추가하지 않았다.
- [x] 모든 권위 링크가 존재한다.
- [x] Parent·Children·References를 구분했다.
- [x] 최신 ADR과 후속 Spec 후보를 반영했다.
- [x] `SUPERSEDED`, `DISCONTINUED`, `ARCHIVED` 문서를 권위 읽기 순서에서 제외했다.
- [x] Diagnostics, Recovery Journal과 Mandatory Audit의 수명주기를 분리했다.
- [x] Diagnostic Read와 실제 Recovery Command를 분리했다.
- [x] Simulation이 생산 Runtime을 우회하지 않음을 반영했다.
- [x] Fault Injection·Concurrency·Restart·Rollback·Disclosure 검증을 연결했다.
- [x] Headless Logical Cost와 Roblox 실제 Timing을 분리했다.
- [x] 권위 문서와 충돌하는 요약이 없다.
- [x] 변경 영향 지도가 최신이다.
- [x] Guide Status가 실제 상태와 일치한다.
