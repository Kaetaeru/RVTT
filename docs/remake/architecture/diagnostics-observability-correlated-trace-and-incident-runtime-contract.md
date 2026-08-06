# Diagnostics, Observability, Correlated Trace와 Incident Runtime 계약

- 상태: 확정
- 문서 종류: Architecture
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 남은 기본값:
  - 성공 Trace의 상세 Span 기본 Sampling 비율
  - Server Hot Trace Buffer의 시간·Byte·Record 상한
  - 오류·보안·Rollback Incident의 영구 보존 기간
  - 단일 Trace, Incident Bundle과 Diagnostic Read Result의 최대 크기
  - Runtime·Command·Query별 CPU·Allocation·Byte Budget 기본값
  - Client Diagnostic Report의 전송 빈도와 Offline Queue 상한
  - DM Diagnostics Panel의 기본 필터와 자동 경고 임계값
  - 개발 환경에서만 허용할 Raw Stack·Module Path 표시 수준
- 작성일: 2026-08-04
- 관련 ADR:
  - [`ADR-0042`](../decisions/ADR-0042-authoritative-checkpoints-command-journal-and-session-recovery.md)
  - [`ADR-0059`](../decisions/ADR-0059-versioned-command-protocol-and-projection-stream-synchronization.md)
  - [`ADR-0061`](../decisions/ADR-0061-persistent-rule-execution-orchestrator-and-nested-timing-windows.md)
  - [`ADR-0062`](../decisions/ADR-0062-ordered-reservations-and-atomic-authority-transactions.md)
  - [`ADR-0063`](../decisions/ADR-0063-manifest-chunk-snapshots-commit-journal-and-branch-recovery.md)
  - [`ADR-0077`](../decisions/ADR-0077-transactional-domain-events-with-outbox-and-projection-boundaries.md)
  - [`ADR-0081`](../decisions/ADR-0081-versioned-policy-composition-and-frozen-ruleset-snapshots.md)
  - [`ADR-0083`](../decisions/ADR-0083-projection-driven-ui-runtime-and-epoch-safe-client-recovery.md)
  - [`ADR-0084`](../decisions/ADR-0084-correlated-authority-traces-and-permission-aware-observability.md)
- 상위 문서:
  - [`Runtime Architecture Principles`](runtime-architecture-principles.md)
  - [`Networking Command, Event와 Client Synchronization 계약`](networking-command-event-and-client-synchronization-contract.md)
  - [`Command Ordering, Logical Time와 Transaction Coordinator 계약`](command-ordering-logical-time-and-transaction-coordinator-contract.md)
  - [`Domain Event, Outbox, Subscription과 Projection Runtime 계약`](domain-event-outbox-subscription-and-projection-runtime-contract.md)
  - [`Persistence와 Session Recovery 모델`](persistence-and-session-recovery-model.md)
- 관련 Runtime:
  - [`Ruleset Policy Runtime 계약`](ruleset-policy-registry-composition-and-frozen-snapshot-runtime-contract.md)
  - [`Rule Runtime Orchestrator 계약`](rule-runtime-orchestrator-and-pending-execution-contract.md)
  - [`UI Runtime 계약`](ui-projection-view-model-input-context-and-recovery-runtime-contract.md)
  - [`Presentation Runtime 계약`](presentation-recipe-playback-priority-and-extension-runtime-contract.md)

## 1. 목적

RVTT는 하나의 사용자 입력이 여러 Runtime을 거쳐 결과와 화면으로 나타난다.

```text
Input Intent
→ Command
→ Authorization·Validation
→ RuleExecution 또는 Domain Operation
→ Ordering·Transaction
→ State Commit + Domain Event Outbox
→ Subscriber
→ Permission-aware Projection
→ UI·Presentation
```

각 단계가 독립된 문자열 로그만 남기면 다음 질문에 답하기 어렵다.

- 공격이 왜 거절됐는가.
- 어떤 Frozen Policy Snapshot과 Modifier가 결과에 사용됐는가.
- Transaction은 Commit됐는데 UI가 왜 갱신되지 않았는가.
- Rollback 이전 Subscriber가 새 Epoch에서 다시 실행됐는가.
- 숨은 함정이나 실제 AC가 Player Diagnostic에 노출됐는가.
- 어느 Query, Subscriber, ViewModel 또는 Presentation Module이 지연을 만들었는가.
- 실패한 작업이 재시도 가능한가, Resync가 필요한가, DM 복구가 필요한가.

따라서 이 문서는 전체 실행을 하나의 인과 Graph로 연결하는 공통 Diagnostics와 Observability Runtime을 정의한다.

핵심 원칙:

```text
Diagnostics는 권위 결과를 관찰한다.
Diagnostics가 권위 결과를 만들거나 수정하지 않는다.
```

```text
Trace의 상세도
≠ 사용자가 볼 수 있는 정보의 범위
```

내부 Trace가 완전하더라도 Player·DM·Developer에게 제공하는 Diagnostic Projection은 각 역할과 Disclosure Policy에 따라 별도로 생성한다.

## 2. 사용자 결과

이 계약은 다음 결과를 보장한다.

- 사용자는 실패한 입력에 대해 안전한 오류 이유와 Support Reference를 확인할 수 있다.
- DM은 현재 Campaign 안에서 어떤 Policy, Command, RuleExecution과 Transaction이 문제를 만들었는지 추적할 수 있다.
- 개발자는 Command부터 Projection·UI까지 같은 Trace에서 병목과 단절 지점을 찾을 수 있다.
- Rollback, Reconnect와 Event Gap 이후 오래된 비동기 작업이 실행된 흔적을 식별할 수 있다.
- 비밀 정보는 Raw Trace 검색·Index·Export 단계에서도 권한 밖으로 유출되지 않는다.
- 진단 수집이 느리거나 실패해도 일반 Gameplay Commit과 Presentation이 가능한 범위에서 계속된다.
- 성능 예산 초과는 조용히 누적되지 않고 구조화된 Budget Observation으로 남는다.
- 오류를 재현할 때 현재 Ruleset·Policy·Build·AuthorityEpoch를 확인할 수 있다.
- Simulation Harness가 동일 Scenario를 실행하고 예상 Trace 불변식을 검증할 수 있다.

## 3. 책임 경계

### 3.1 Diagnostics Runtime이 소유한다

- Server가 발급하는 안정적 `traceId`, `spanId`와 인과 Link
- Command·RuleExecution·Transaction·Event·Projection·UI 단계의 공통 Trace Context
- Versioned Diagnostic Record와 Observation Registry
- 단계별 시작·종료·실패·Budget 측정
- Rule·Policy·Authorization 결정의 설명 가능한 Decision Record
- Error Incident의 생성, 분류, 중복 집계와 상태
- Trace Sampling, Retention, Buffer, Backpressure와 Degradation
- 역할·권한·Disclosure별 Diagnostic Projection과 Redaction
- Trace·Incident·Health·Budget Read Query
- Sanitized Incident Bundle과 Support Reference
- Client UI·Presentation의 비권위 Diagnostic Report 수집
- Rollback·Reconnect·Recovery를 구분하는 Epoch-aware Trace 연결
- Simulation과 플레이테스트가 사용할 구조화된 검증 Hook

### 3.2 Diagnostics Runtime이 소유하지 않는다

- Gameplay Domain State와 권위 Mutation
- Transaction Commit·Abort 결정
- Command Authorization과 규칙 적격성의 실제 판정
- 복구용 Snapshot, Commit Journal과 Domain Event Outbox
- Player에게 공개할 Gameplay Projection의 원본 생성
- UI Component, Camera와 Presentation Playback
- 서버 보안 정책과 Abuse 제재의 실제 실행
- 테스트 Scenario와 기대 결과의 정의

### 3.3 Journal, Audit와 Observability 분리

```text
Recovery Journal
→ 서버 복구와 Rollback에 필요한 권위 기록

Mandatory Audit Record
→ DM Override, 권한·보안 변경처럼 반드시 남겨야 하는 관리 기록

Observability Trace
→ 원인, 지연, 경로와 상태를 설명하는 비권위 관측 기록
```

일반 Observability Record 저장 실패는 이미 검증된 Gameplay Transaction을 실패시키지 않는다.

반면 Mandatory Audit가 필요한 관리 Command는 해당 Audit Record가 원자 Commit되지 않으면 Commit할 수 있다거나 없다고 임의 처리하지 않는다. 이 필수 기록은 Transaction·Journal 계약이 소유하며 Diagnostics는 참조만 보존한다.

## 4. Diagnostic Plane

진단 자료를 하나의 무제한 로그로 합치지 않는다.

```text
Authority Trace Plane
Rule Decision Plane
Operational Metric Plane
Security·Audit Reference Plane
Client Experience Plane
Health·Incident Plane
```

### 4.1 Authority Trace Plane

Command, RuleExecution, Transaction, Domain Event와 Projection의 인과 흐름을 기록한다.

### 4.2 Rule Decision Plane

Capability 적격성, Policy 선택, Modifier, Target Validation과 구조화된 거부 이유를 기록한다.

### 4.3 Operational Metric Plane

Latency, Queue Depth, Allocation, Payload Size, Cache Hit, Retry와 Budget 사용량을 집계한다.

### 4.4 Security·Audit Reference Plane

Authorization 거부, Rate Limit, Stale Epoch, Disclosure 위반 후보와 Mandatory Audit Record 참조를 기록한다.

### 4.5 Client Experience Plane

UI Replica 적용, ViewModel 계산, Component Error Boundary, Input Context 충돌, Presentation 누락과 Frame Budget을 기록한다.

Client가 보낸 이 자료는 비권위 관찰값이다. Client 보고를 HP, 위치, Command 성공 여부와 서버 시간의 원본으로 사용하지 않는다.

### 4.6 Health·Incident Plane

Subsystem 상태, 반복 오류, Dead Letter, 누수 후보와 운영 복구 필요 여부를 집계한다.

## 5. Trace Identity와 인과 Graph

### 5.1 Server Trace Identity

Client가 임의로 Server `traceId`를 확정하지 못한다.

```text
ClientInteractionId?
→ Network Ingress에서 검증
→ ServerTraceId 발급 또는 기존 권위 Trace에 연결
```

```text
TraceContext
├─ traceId
├─ currentSpanId
├─ parentSpanId?
├─ causationRefs[]
├─ correlationId?
├─ authorityEpoch
├─ campaignId?
├─ sessionId?
├─ sceneId?
├─ actorRefs[]?
├─ policySnapshotRef?
├─ buildRevisionRefs[]
├─ samplingClass
└─ disclosureClass
```

### 5.2 Trace는 단순 Tree가 아니다

Domain Event Fan-out, 다중 Subscriber와 Transaction Join 때문에 실행은 Graph가 될 수 있다.

```text
Command Span
→ RuleExecution Span
→ Transaction Span
→ Domain Event Span
  ├─ Projection Subscriber Span
  ├─ Scheduler Subscriber Span
  └─ Journal Subscriber Span
```

`parentSpanId`는 주 실행 경로를 표현하고, `causationRefs`는 다른 Trace·Event·Command와의 인과 연결을 표현한다.

### 5.3 Authority Identity 포함

Trace만으로 권위 객체를 대체하지 않는다. 가능한 단계에는 실제 ID와 Revision을 연결한다.

```text
commandId
executionId
transactionId
eventId
projectionId + projectionEpoch + viewSequence
runtimeObjectId + incarnation
encounterId
scheduledExecutionId
authorityEpoch + authorityRevision
```

## 6. 표준 End-to-End Span

최소 표준 단계:

```text
client.intent
network.command_ingress
command.authorization
command.validation
rule.execution
rule.timing_window
transaction.prepare
transaction.commit_or_abort
event.outbox_append
event.dispatch
projection.build
projection.stream
client.replica_apply
ui.viewmodel_compute
ui.intent_reconcile
presentation.playback
```

모든 작업이 모든 Span을 요구하지는 않는다. 단순 Read Request는 RuleExecution과 Transaction 없이 끝날 수 있다.

비동기 경계를 넘을 때 Trace Context를 명시적으로 전달한다. Roblox Task, Queue, Subscriber와 Retry가 현재 호출 Stack을 잃었다는 이유로 새 무관 Trace를 만들지 않는다.

## 7. Diagnostic Record

### 7.1 Trace Header

```text
DiagnosticTraceHeader
├─ traceId
├─ traceSchemaVersion
├─ rootKind
├─ rootReference
├─ authorityEpoch
├─ startedAtMonotonic
├─ terminalStatus?
├─ terminalAtMonotonic?
├─ policySnapshotRefs[]
├─ buildRevisionRefs[]
├─ retentionClass
├─ disclosureSummary
└─ incidentId?
```

Gameplay 시간과 성능 측정 시간을 혼합하지 않는다. Latency는 Authority Monotonic Time을 사용하고 Campaign Game Time은 Context 값으로만 기록한다.

### 7.2 Span Record

```text
DiagnosticSpanRecord
├─ spanId
├─ traceId
├─ parentSpanId?
├─ causationRefs[]
├─ spanTypeId
├─ handlerId?
├─ startMonotonic
├─ endMonotonic?
├─ status
├─ inputSummary
├─ outputSummary
├─ decisionRefs[]
├─ budgetMeasurements[]
├─ errorRef?
├─ authorityRefs[]
└─ disclosureTags[]
```

### 7.3 Observation

Span 수명주기와 별개의 구조화된 관찰값이다.

```text
DiagnosticObservation
├─ observationTypeId
├─ traceId?
├─ spanId?
├─ severity
├─ category
├─ dimensions
├─ measurement?
├─ referenceSet
├─ disclosureTags[]
└─ occurredAtMonotonic
```

문자열 메시지만 남기지 않는다. 검색·집계·테스트 가능한 안정적 Type과 Field를 사용한다.

## 8. 설명 가능한 Decision Trace

### 8.1 Command와 Authorization

```text
CommandDecisionRecord
├─ commandTypeId
├─ roleAndControlSnapshotRef
├─ readinessResult
├─ authorizationResult
├─ preconditionResults[]
├─ concurrencyPolicy
├─ rateLimitResult
├─ terminalDecision
└─ publicReasonCode
```

### 8.2 Rule과 Policy

```text
RuleDecisionRecord
├─ decisionTypeId
├─ frozenPolicySnapshotRef
├─ effectivePolicyViewHash
├─ capabilityRef?
├─ sourceContributions[]
├─ appliedModifiers[]
├─ suppressedContributions[]
├─ candidateResults[]
├─ chosenResult
├─ rejectionCodes[]
└─ disclosureTags[]
```

규칙 설명은 결과를 다시 계산하는 실행 코드가 아니다. 실제 실행 당시 사용한 Snapshot과 결정 결과를 기록한다.

### 8.3 Projection과 Disclosure

```text
ProjectionDecisionRecord
├─ sourceEventRefs[]
├─ audienceClass
├─ disclosurePolicyRef
├─ includedFieldGroups[]
├─ redactedFieldGroups[]
├─ omittedEventCount
├─ projectionBatchRef
└─ leakGuardResult
```

Player에게는 `redactedFieldGroups`의 내부 이름이나 숨은 대상 ID까지 노출하지 않는다.

## 9. 권한과 정보 공개

### 9.1 Raw Trace를 그대로 제공하지 않는다

Diagnostic Query도 일반 Gameplay Query와 같은 Permission·Disclosure 경계를 적용한다.

```text
Raw Diagnostic Record
→ Diagnostic Projection Builder
→ Role·Ownership·Control·Knowledge·Security Redaction
→ Diagnostic Read Result
```

### 9.2 기본 역할 범위

#### Player

- 자신이 제출한 Command의 수신·대기·성공·거부 상태
- 공개 가능한 사용자 메시지와 재시도·Resync 안내
- 자신에게 이미 공개된 Actor·Item·Encounter 정보
- Support Reference

다음은 볼 수 없다.

- 숨은 Actor·함정·문·DC·실제 AC와 비공개 Modifier
- 다른 사용자의 비공개 Command와 Client Report
- Raw Stack Trace, Module Path, 서버 Instance ID와 Security Rule

#### DM

- 현재 Campaign의 Gameplay Trace와 숨은 게임 정보
- Policy Composition과 Rule Decision 설명
- Participant·Encounter·Scene별 오류·성능 요약
- 복구가 필요한 Incident와 안전한 Override 경로

DM도 인증 Token, 내부 Credential, 다른 Campaign 자료와 운영자 전용 Security Detail은 볼 수 없다.

#### Developer·Operator

- 기술 Span, Handler Version, Budget, Queue와 Stack Summary
- Sanitized Payload Shape와 Build·Policy Hash
- 권한이 부여된 범위의 Incident Bundle

개발 권한이 있다는 이유로 사용자 입력 원문·개인 메모·비공개 콘텐츠를 무제한 수집하지 않는다.

### 9.3 Index도 권한 분리

Raw Trace를 하나의 검색 Index에 넣고 결과 화면에서만 숨기지 않는다.

- Player-safe Index
- DM Campaign Index
- Operator Technical Index

를 논리적으로 분리하거나, 필드 수준 Security Label을 강제하는 동등한 구조를 사용한다.

## 10. Sampling과 Retention

### 10.1 최소 Lifecycle Marker

모든 권위 Command, RuleExecution과 Transaction에는 최소한 다음 Terminal Marker를 남긴다.

```text
started
committed | rejected | cancelled | expired | aborted | failed
terminalReasonCode
traceId
primaryAuthorityRefs
```

상세 Span과 Field는 Sampling할 수 있지만 최종 처리 여부를 알 수 없는 상태로 만들지 않는다.

### 10.2 강제 보존 Class

다음은 일반 성공 Sampling으로 제거하지 않는다.

- Transaction Abort와 Partial Commit Guard 발동
- Rollback·Recovery·AuthorityEpoch 전환
- Authorization·Disclosure·Integrity 위반 후보
- Event Gap, Projection Gap과 Snapshot Integrity 실패
- Dead Letter와 반복 Subscriber 실패
- Ordering Deadlock Guard와 Reservation 누수 후보
- Budget Hard Limit 초과
- DM Override와 Mandatory Audit Reference
- 같은 Idempotency Key의 Payload 불일치

### 10.3 보존 계층

```text
Hot Ring Buffer
→ 최근 Trace의 빠른 조회

Sampled Session Trace
→ 플레이테스트 분석

Incident Record
→ 반복·중대 오류 추적

Sanitized Incident Bundle
→ 재현·리뷰·지원
```

완료된 Trace를 영구 Gameplay State에 무제한 저장하지 않는다.

## 11. Performance Budget와 Backpressure

### 11.1 Budget 종류

```text
cpu_monotonic_time
allocation_bytes
serialized_bytes
record_count
queue_depth
subscriber_retry_count
query_count
spatial_query_count
projection_build_size
client_replica_apply_time
ui_viewmodel_compute_time
presentation_playback_cost
```

각 Runtime·Command·Query·Subscriber와 UI Surface는 등록된 Budget Profile을 참조한다.

### 11.2 초과 처리

```text
Soft Limit
→ Detail 축약, Sampling 상승, 경고 Observation

Hard Limit
→ 진단 작업 중단 또는 Fallback, Incident 생성
```

Diagnostics의 자체 초과 때문에 이미 유효한 Gameplay 결과를 변경하지 않는다.

Gameplay Runtime 자체가 Hard Budget을 초과한 경우에는 해당 Runtime 계약이 정의한 안전한 실패·Timeout을 수행하고, Diagnostics는 그 결정을 기록한다.

### 11.3 Drop Policy

우선순위:

```text
Mandatory Audit Reference
Critical Incident
Terminal Authority Marker
Security·Integrity Observation
Detailed Span
Routine Success Metric
Presentation·Client Cosmetic Detail
```

낮은 우선순위 자료를 먼저 축약한다. Drop이 발생하면 `diagnostics.records_dropped` 자체 Observation을 남기되 무한 재귀를 만들지 않는다.

## 12. Error와 Incident

### 12.1 Error Record

```text
DiagnosticErrorRecord
├─ errorId
├─ stableErrorCode
├─ category
├─ severity
├─ retryable
├─ resyncRequired
├─ dmActionRequired
├─ safeUserMessageKey
├─ technicalSummary?
├─ stackFingerprint?
├─ sourceSpanRef
├─ relatedAuthorityRefs[]
├─ firstSeen
├─ lastSeen
└─ occurrenceCount
```

Raw Error String과 Stack Trace를 Stable Error Code로 사용하지 않는다.

### 12.2 Incident 수명주기

```text
open
→ acknowledged
→ mitigating
→ resolved
→ archived
```

자동 복구가 끝났더라도 반복 위험이 있으면 Incident를 바로 삭제하지 않는다.

### 12.3 오류 격리

- Client Component 오류는 해당 Error Boundary에서 Fallback UI로 전환한다.
- Presentation Module 오류는 Gameplay State를 되돌리지 않는다.
- Diagnostic Export 실패는 원본 Trace를 손상시키지 않는다.
- Subscriber 진단 실패는 Subscriber의 실제 멱등 처리 결과와 분리한다.
- Diagnostics Runtime 자체 오류는 별도 제한된 Self-health Channel에 기록한다.

## 13. Health Model

```text
SubsystemHealthState
├─ subsystemId
├─ status
├─ reasonCodes[]
├─ lastHealthyAt
├─ activeIncidentIds[]
├─ queueAndBudgetSummary
├─ dependencyHealth[]
└─ revision
```

`status`:

```text
healthy
degraded
recovering
blocked
unavailable
```

Health는 Gameplay 권위 State를 대체하지 않는다. 예를 들어 Projection Service가 `degraded`여도 Actor HP가 바뀌지 않는다. 다만 Session Runtime은 명시적 Readiness·Safety Policy에 따라 새 Command를 제한할 수 있다.

## 14. Incident Bundle

재현과 지원을 위해 구조화된 Bundle을 생성할 수 있다.

```text
DiagnosticIncidentBundle
├─ bundleSchemaVersion
├─ incidentId
├─ sanitizedTraceGraph
├─ authorityEpochAndRevisionRange
├─ policySnapshotHashes[]
├─ compiledBuildHashes[]
├─ commandAndExecutionSummaries[]
├─ transactionAndEventSummaries[]
├─ projectionIntegritySummary
├─ clientExperienceReports[]
├─ budgetAndHealthSummary
├─ deterministicSeedRefs[]?
├─ redactionManifest
└─ contentHash
```

Bundle에 Recovery Snapshot 전체, 비밀 Journal 원문, 인증 정보와 임의 Workspace Dump를 자동 포함하지 않는다.

Simulation Harness는 Bundle의 안정적 Reference와 Seed를 사용해 별도 Scenario를 구성할 수 있지만, Bundle 자체가 실행 가능한 임의 Luau를 포함해서는 안 된다.

## 15. Diagnostic Query

```text
DiagnosticReadRequest
├─ readTypeId
├─ requesterScope
├─ traceId?
├─ incidentId?
├─ authorityRef?
├─ timeRange?
├─ filters
├─ detailLevel
├─ projectionPolicyRef
└─ resultLimit
```

기본 Read 종류:

```text
get_trace_summary
get_trace_graph
explain_command_result
explain_rule_decision
explain_projection_result
get_incident
get_subsystem_health
get_budget_summary
get_recent_errors
build_sanitized_incident_bundle
```

Read는 Snapshot-bound, 권한 검증, Rate Limit과 Result Limit을 사용한다. Diagnostic Read Handler가 상태를 수정하거나 복구 Command를 자동 실행하지 않는다.

복구가 필요하면 결과에 허용된 다음 Action을 제안하고, 사용자가 별도 Command를 제출한다.

## 16. UI와 Support Reference

사용자에게 Raw Trace ID 전체를 항상 노출할 필요는 없다.

```text
SupportReference
├─ shortReferenceCode
├─ traceId 또는 incidentId의 서버 매핑
├─ expiresAt?
└─ disclosureClass
```

UI 오류 Surface는 다음을 구분한다.

```text
retry
wait
resync
reopen_view
ask_dm
report_issue
no_action_required
```

권위 결과가 불확실할 때 UI가 성공 또는 실패를 추측하지 않는다. Command Status Query와 Projection Reconciliation을 사용한다.

## 17. Client Diagnostic Report

```text
ClientDiagnosticReport
├─ clientReportId
├─ connectionSessionId
├─ connectionEpoch
├─ clientBuildVersion
├─ localTraceLink?
├─ componentOrModuleId
├─ eventType
├─ monotonicMeasurement
├─ sanitizedStateSummary
├─ deviceClassSummary
└─ integrityMetadata
```

규칙:

- Payload Schema와 크기를 검증한다.
- Rate Limit과 Abuse Guard를 적용한다.
- Client가 제출한 Authority ID와 성공 여부를 그대로 신뢰하지 않는다.
- 개인 정보와 사용자 입력 원문을 기본 수집하지 않는다.
- Offline Queue가 오래된 Connection Epoch 자료를 새 Session에 권위 사실처럼 연결하지 않는다.

## 18. Persistence, Recovery와 Rollback

### 18.1 Server Recovery

진행 중 Trace Buffer가 유실되어도 Recovery Journal과 Authority Snapshot을 통해 Gameplay를 복구할 수 있어야 한다.

Diagnostics는 복구 후 새로운 Trace에서 다음을 연결한다.

```text
recoverySourceSnapshotId
previousAuthorityEpoch
newAuthorityEpoch
lastCommittedTransactionId
recoveryReason
```

### 18.2 Rollback

Rollback 이전 Trace는 역사 기록으로 보존할 수 있지만 새 Branch의 실행으로 재분류하지 않는다.

```text
old authorityEpoch trace
→ historical_branch

new authorityEpoch trace
→ active_branch
```

이전 Epoch의 Client Report, Subscriber Retry와 Pending Export가 새 Epoch의 Incident를 잘못 닫거나 상태를 변경하지 못한다.

### 18.3 Reconnect

Client local Trace와 Server Trace는 Connection Epoch를 포함해 연결한다. 재접속 후 같은 UI Intent가 다시 제출되면 Idempotency Key와 Command Status를 기준으로 기존 Trace에 연결하거나 새 Retry Span을 만든다.

## 19. Version과 Registry

```text
DiagnosticRegistry
├─ spanTypeRegistry
├─ observationTypeRegistry
├─ errorCodeRegistry
├─ budgetProfileRegistry
├─ redactionRuleRegistry
├─ incidentRuleRegistry
└─ queryTypeRegistry
```

각 항목은 안정적 ID, Schema Version, Handler Version, Disclosure Metadata와 Migration Adapter를 가진다.

구형 Trace를 읽을 수 없다고 빈 결과로 처리하지 않는다. 지원되지 않는 Version과 부분적으로 해석 가능한 필드를 명시한다.

## 20. Extension 경계

새 Runtime은 다음 방식으로 Diagnostics에 연결한다.

- 등록된 Span Type 사용
- 구조화된 Observation 제출
- Budget Profile 참조
- Authority Reference Adapter 제공
- Redaction Metadata 선언
- Health Probe 등록

새 Runtime이 자체 Remote, 무제한 문자열 로그, 독립 Trace ID 체계와 별도 보존소를 임의로 만들지 않는다.

Extension은 다음을 할 수 없다.

- Gameplay Store 직접 수정
- Diagnostic Query 권한 우회
- Raw Payload 전체 자동 수집
- Sampling·Budget 상한 무시
- 사용자에게 Raw Stack Trace Broadcast
- 실행 가능한 임의 코드가 포함된 Incident Bundle 생성

## 21. 표준 실패 코드 범주

```text
protocol
schema
authorization
readiness
stale_epoch
stale_reference
precondition
conflict
ordering
transaction
event_dispatch
projection_integrity
recovery
budget
resource_leak
client_ui
presentation
internal
```

세부 Error Code는 Registry에서 관리한다. 사용자 문구는 Localization Key로 분리한다.

## 22. 구현 분할 기준

후속 구현 명세는 다음 수직 단위로 분할한다.

```text
Trace Context와 Record Registry
→ Server Span Collector와 Async Context Propagation
→ Decision Trace Adapter
→ Metric·Budget·Health Collector
→ Permission-aware Diagnostic Projection과 Read Query
→ Error Incident와 Support Reference
→ Client UI·Presentation Diagnostic Report
→ Incident Bundle과 Retention
→ Simulation Harness Integration Hook
```

## 23. 완료 조건

다음을 만족하면 구현 가능한 공통 계약으로 본다.

- 하나의 Command가 Projection·UI까지 같은 Trace Graph로 연결된다.
- 비동기 Subscriber와 Retry에서 Causation이 유지된다.
- Rule·Policy·Authorization 거부 이유가 구조화된다.
- Raw Trace와 역할별 Diagnostic Projection이 분리된다.
- Trace Sampling과 Drop이 권위 Terminal 상태를 숨기지 않는다.
- Diagnostics 실패가 일반 Gameplay Commit을 되돌리지 않는다.
- Mandatory Audit와 Recovery Journal을 Observability와 혼동하지 않는다.
- Budget 초과와 자체 진단 Drop이 구조화되어 보인다.
- Rollback 이후 이전 Epoch Trace와 작업이 현재 Branch를 변경하지 않는다.
- Simulation Harness가 Trace 불변식과 Incident Bundle Reference를 사용할 수 있다.

## 24. 비목표

- 외부 상용 Monitoring Vendor 확정
- 실제 Retention 수치와 Sampling 비율 확정
- 운영자용 Web Dashboard 구현
- 사용자 행동 분석과 광고용 Analytics
- Gameplay Replay를 Trace만으로 완전히 재생
- Raw Server Log를 Player에게 공개
- Diagnostics가 자동으로 DM 대신 규칙 판정을 수정

이 문서는 관측과 설명 계약을 확정한다. 구체적인 Collector 구현, 저장 Backend와 Dashboard Layout은 구현 명세에서 결정한다.
