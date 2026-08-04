# Diagnostics 시스템

Command, RuleExecution, Transaction, Domain Event, Projection, UI와 Presentation을 하나의 인과 Trace로 연결하고 오류·성능·복구 상태를 설명한다.

## 관련 Main System Guide

- [`UI, Camera와 Presentation Guide`](../../guides/ui/README.md)
  - Projection Apply·ViewModel·Input·CameraRequest·Playback Trace와 Client Failure Isolation
- [`Journal과 Ping Guide`](../../guides/journal/README.md)
  - Journal Compile·Permission·Search·Anchor·Navigation Trace와 비밀 정보 Redaction
  - Ping을 비권위 Client Experience Event로 기록하고 Gameplay Trace와 분리하는 경계

## 권위 문서

- [`Diagnostics, Observability, Correlated Trace와 Incident Runtime 계약`](../../architecture/diagnostics-observability-correlated-trace-and-incident-runtime-contract.md)
  - Server 발급 Trace Context와 비동기 Causation Graph
  - Command→RuleExecution→Transaction→Event→Projection→UI 전체 Span
  - Rule·Policy·Authorization Decision Record
  - Permission-aware Diagnostic Projection과 Redaction
  - Sampling, Retention, Performance Budget와 Drop 우선순위
  - Error Incident, Health State, Support Reference와 Incident Bundle
  - Rollback·Recovery·Reconnect의 AuthorityEpoch 연결
- [`ADR-0084`](../../decisions/ADR-0084-correlated-authority-traces-and-permission-aware-observability.md)
  - 구조화된 Correlated Trace와 역할별 진단 공개를 공통 기반으로 채택

## 관련 문서

- [`Networking 계약`](../../architecture/networking-command-event-and-client-synchronization-contract.md)
  - `traceId`, `correlationId`, Command Receipt·Result와 Projection Stream
- [`Transaction Coordinator`](../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)
  - Prepare·Commit·Abort와 Ordering·Reservation 진단
- [`Domain Event Runtime`](../../architecture/domain-event-outbox-subscription-and-projection-runtime-contract.md)
  - Event Causation, Subscriber Retry, Dead Letter와 Projection 연결
- [`Ruleset Policy Runtime`](../../architecture/ruleset-policy-registry-composition-and-frozen-snapshot-runtime-contract.md)
  - 실행 당시 Policy Snapshot과 Composition Trace
- [`Rule Runtime Orchestrator`](../../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md)
  - Parent·Child Execution, TimingWindow, Prompt와 Reaction Trace
- [`UI Runtime`](../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md)
  - Replica Apply, ViewModel, Input Context, Command Reconciliation과 Error Boundary
- [`Journal Runtime`](../../architecture/journal-document-section-anchor-permission-search-and-projection-runtime-contract.md)
  - Journal Command·Compile·Permission·Search·Anchor·Navigation과 Disclosure Trace
- [`Persistence와 Recovery`](../../architecture/persistence-and-session-recovery-model.md)
  - Recovery Journal과 Observability Trace의 분리
- [`Deterministic Simulation과 Test Harness`](../../architecture/deterministic-simulation-scenario-and-test-harness-runtime-contract.md)
  - Scenario Trace Assertion, Incident Replay, 최소 재현 Schedule과 Disclosure Canary 검사

## 표준 Trace 흐름

```text
client.intent
→ network.command_ingress
→ command.authorization
→ command.validation
→ rule.execution 또는 domain.operation
→ transaction.prepare
→ transaction.commit_or_abort
→ event.outbox_append
→ event.dispatch
→ projection.build
→ projection.stream
→ client.replica_apply
→ ui.viewmodel_compute
→ ui.intent_reconcile
→ presentation.playback
```

Journal 세부 흐름:

```text
journal.command
→ journal.compile
→ journal.permission_evaluate
→ journal.index_update
→ journal.projection_build
→ journal.search_query | journal.anchor_resolve | journal.navigation_resolve
```

## 고정 경계

- Diagnostics는 Gameplay State를 직접 변경하지 않는다.
- Recovery Journal, Mandatory Audit와 Observability Trace를 같은 저장물로 취급하지 않는다.
- Client가 Server Trace ID와 Authority 결과를 확정하지 못한다.
- Raw Trace를 Player나 DM에게 그대로 제공하지 않고 역할별 Diagnostic Projection을 만든다.
- 비밀 정보는 화면뿐 아니라 Diagnostic Index와 Export 단계에서도 차단한다.
- Journal Support Trace에 권한 없는 문서 제목, Section, Anchor Target, Search Token과 숨은 좌표를 넣지 않는다.
- Ping Trace는 비권위 Experience Event이며 손실을 Authority Event Gap으로 분류하지 않는다.
- 상세 Span은 Sampling할 수 있지만 권위 실행의 Terminal Marker는 유지한다.
- Transaction Abort, Rollback, Projection Gap, Security·Disclosure 위반 후보와 Hard Budget 초과는 일반 Sampling으로 제거하지 않는다.
- Diagnostics 자체 장애는 일반 Gameplay Commit을 되돌리지 않는다.
- Mandatory Audit가 필요한 관리 Command는 Transaction·Journal 계약을 따른다.
- Latency는 Authority Monotonic Time으로 측정하며 Campaign Game Time과 혼합하지 않는다.
- 이전 AuthorityEpoch의 Trace와 Client Report가 현재 Branch Incident를 변경하지 못한다.
- Incident Bundle은 Sanitized Data만 포함하고 실행 가능한 임의 코드를 포함하지 않는다.
- Test Harness는 구조화된 Trace Hook을 검증에 사용할 수 있지만 Trace를 권위 상태나 기대 결과의 유일한 원본으로 사용하지 않는다.
- Simulation 실패 Artifact에는 최소 재현 Seed·Schedule·State Diff와 안전한 Trace Reference를 연결한다.

## 역할 경계

- 플레이어는 자신의 공개 가능한 Command 상태, 사용자 안전 오류와 Support Reference를 본다.
- DM은 현재 Campaign의 Gameplay Trace, Policy·Rule 설명과 복구 필요 Incident를 본다.
- 개발자·운영자는 허가된 기술 Span, Budget, Queue와 Sanitized Incident Bundle을 본다.
- 시스템은 Trace Context 전파, Sampling, Redaction, Incident 집계와 Health 계산을 담당한다.

## 후속 구현 명세

- `specs/diagnostics/001-trace-context-and-record-registry.md`
- `specs/diagnostics/002-server-span-collector-and-async-propagation.md`
- `specs/diagnostics/003-decision-trace-budget-and-health.md`
- `specs/diagnostics/004-permission-aware-query-and-support-reference.md`
- `specs/diagnostics/005-client-report-and-incident-bundle.md`

실제 구현 순서는 `../../CURRENT-WORK-ORDER.md`와 전체 Implementation Specs 단계에서 확정한다.
