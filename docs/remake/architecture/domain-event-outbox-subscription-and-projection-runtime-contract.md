# Domain Event, Outbox, Subscription과 Projection Runtime 계약

- 상태: 확정
- 문서 종류: Architecture
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 남은 기본값:
  - Event Outbox 단일 Commit당 최대 Event 수
  - Subscriber별 처리 시간 Budget과 Circuit Breaker 임계값
  - Durable Domain Event 보존 기간과 Compaction 정책
  - Projection Event Stream Retention과 재전송 Window
  - 비권위 Telemetry Event Sampling 기본값
  - 동일 Event에 대한 후속 Command 폭주 방지 한도
- 작성일: 2026-08-04
- 관련 ADR:
  - [`ADR-0042`](../decisions/ADR-0042-authoritative-checkpoints-command-journal-and-session-recovery.md)
  - [`ADR-0059`](../decisions/ADR-0059-versioned-command-protocol-and-projection-stream-synchronization.md)
  - [`ADR-0061`](../decisions/ADR-0061-persistent-rule-execution-orchestrator-and-nested-timing-windows.md)
  - [`ADR-0062`](../decisions/ADR-0062-ordered-reservations-and-atomic-authority-transactions.md)
  - [`ADR-0063`](../decisions/ADR-0063-manifest-chunk-snapshots-commit-journal-and-branch-recovery.md)
  - [`ADR-0075`](../decisions/ADR-0075-versioned-data-driven-and-fault-isolated-presentation-runtime.md)
  - [`ADR-0077`](../decisions/ADR-0077-transactional-domain-events-with-outbox-and-projection-boundaries.md)
- 상위 문서:
  - [`Runtime Architecture Principles`](runtime-architecture-principles.md)
  - [`Command Ordering, Logical Time와 Transaction Coordinator 계약`](command-ordering-logical-time-and-transaction-coordinator-contract.md)
  - [`Networking Command, Event와 Client Synchronization 계약`](networking-command-event-and-client-synchronization-contract.md)
  - [`Rule Runtime Orchestrator와 Pending Execution 계약`](rule-runtime-orchestrator-and-pending-execution-contract.md)
  - [`Persistence와 Session Recovery 모델`](persistence-and-session-recovery-model.md)

## 1. 목적

이 문서는 권위 상태가 Commit된 뒤 다른 Runtime, Projection, Presentation, Journal, Diagnostics와 미래 확장 기능에 변경 사실을 전달하는 공통 Event 계약을 정의한다.

핵심 흐름:

```text
Command 또는 RuleExecution
→ Authority Transaction
→ State Mutation + Domain Event Outbox 원자적 Commit
→ Event Dispatcher
→ Domain Subscriber
→ Observer별 Projection Event
→ Presentation·UI·Journal·Diagnostics
```

Event Runtime은 상태 변경을 우회하는 두 번째 Command Bus가 아니다.

## 2. Event 종류의 고정 분리

`Event`라는 이름 아래 서로 다른 의미를 섞지 않는다.

### 2.1 Rule Event

규칙 실행 도중 Trigger와 Timing Window를 여는 내부 의미 사건이다.

예시:

```text
before_attack_roll
creature_moves_out_of_reach
spell_cast_started
damage_about_to_apply
```

Rule Event는 아직 Commit되지 않은 Pending RuleExecution 안에서 사용될 수 있다. Domain Event와 동일하지 않다.

### 2.2 Domain Event

성공한 Authority Transaction이 확정한 과거 사실이다.

예시:

```text
actor.moved
actor.damage_applied
actor.zero_hp_reached
item.transferred
runtime_object.state_changed
encounter.turn_started
knowledge.discovered
```

Domain Event는 이미 Commit된 사실이며 취소하거나 같은 Event Handler 안에서 원래 Transaction을 수정할 수 없다.

### 2.3 Projection Event

Domain Event와 최신 Authority State를 관찰자별 공개 정책으로 변환한 Client-safe Delta다.

```text
Domain Event
+ Observer Context
+ Disclosure Policy
→ Projection Event
```

플레이어에게 숨겨진 Actor, 실제 HP, 비밀 DC, 미식별 Item Definition을 포함하지 않는다.

### 2.4 Presentation Signal

VFX, 카메라, UI Pulse와 같은 손실 허용 표현 신호다.

Presentation Signal이 누락되어도 권위 상태와 Projection State는 바뀌지 않는다.

### 2.5 Journal Record

복구와 감사에 사용하는 내구성 기록이다. Domain Event와 연결될 수 있지만 같은 데이터 구조로 강제하지 않는다.

### 2.6 Telemetry Event

성능, 사용성, 오류 분석을 위한 비권위 진단 데이터다. Sampling·Drop을 허용하며 Gameplay 판단에 사용하지 않는다.

## 3. 권위 경계

```text
Domain Event
= Commit된 사실의 설명
≠ 상태 변경 요청
≠ Rule Trigger 자체
≠ Client Broadcast Payload
```

규칙:

- Domain Event는 Authority Transaction Commit 전에는 외부 Subscriber에 보이지 않는다.
- Abort된 Transaction의 Event Draft는 모두 폐기한다.
- Subscriber 실패가 원래 Transaction을 Rollback시키지 않는다.
- Subscriber가 상태를 변경해야 하면 등록된 Command 또는 RuleExecution을 새 Correlation Chain으로 제출한다.
- Event Handler가 Domain Store를 직접 수정하거나 Transaction Coordinator를 우회하지 않는다.
- Client는 Domain Event 원본을 받지 않고 Projection Event만 받는다.

## 4. Domain Event Draft와 Outbox

각 Domain Mutation Proposal은 상태 변경과 함께 Event Draft를 제공할 수 있다.

```text
DomainEventDraft
├─ eventTypeId
├─ eventSchemaVersion
├─ aggregateRef
├─ semanticPayload
├─ disclosureClassification
├─ causationRef
├─ correlationId
└─ tags[]
```

Transaction Coordinator는 Commit 시 이를 정규화해 Outbox에 함께 기록한다.

```text
CommittedDomainEvent
├─ eventId
├─ eventTypeId
├─ eventSchemaVersion
├─ authorityEpoch
├─ authorityRevision
├─ transactionId
├─ eventIndexInTransaction
├─ occurredAtLogicalTime
├─ aggregateRef
├─ aggregateRevision
├─ causationId?
├─ correlationId
├─ semanticPayload
├─ disclosureClassification
├─ traceId?
└─ contentHash
```

정렬 키:

```text
AuthorityEpoch
→ AuthorityRevision
→ eventIndexInTransaction
```

실제 벽시계 시간이나 Subscriber 처리 완료 순서가 권위 Event 순서를 바꾸지 않는다.

## 5. Transactional Outbox

상태 Mutation과 Event 기록 사이의 이중 성공·실패를 허용하지 않는다.

```text
Authority State Mutation
+ Domain Event Outbox Append
+ Commit Marker
→ 하나의 Commit Graph
```

다음 상태는 금지한다.

```text
상태는 바뀌었지만 Event 없음
Event는 발행됐지만 상태 Commit 실패
같은 Commit Event가 중복 의미로 두 번 발행됨
```

Dispatcher는 Commit Marker가 확인된 Outbox Record만 전달한다.

서버 복구 시 Outbox Cursor부터 재개할 수 있으며, Subscriber는 중복 전달을 견뎌야 한다.

## 6. Event Registry

임의 문자열과 자유 형식 Table을 Event 계약으로 사용하지 않는다.

```text
DomainEventDefinition
├─ eventTypeId
├─ currentSchemaVersion
├─ payloadSchema
├─ aggregateKinds[]
├─ disclosureClassification
├─ retentionClass
├─ projectionAdapterId?
├─ presentationIntentAdapterId?
├─ migrationAdapters[]
└─ validationPolicy
```

Event Type 예시:

```text
actor.movement_checkpoint_committed
actor.damage_applied
actor.healing_applied
actor.condition_applied
actor.condition_removed
actor.zero_hp_reached
item.world_presence_created
item.transferred
runtime_object.lifecycle_changed
runtime_object.state_changed
interaction.completed
spell.cast_committed
roll.revealed
encounter.started
encounter.turn_started
encounter.turn_ended
encounter.ended
knowledge.relation_changed
scene.transition_committed
control.assignment_changed
```

Event Type는 UI 문구나 VFX Asset 이름이 아니다.

## 7. Subscriber 종류

### 7.1 Authoritative Follow-up Subscriber

새 권위 실행이 필요한지 판단한다.

예:

```text
actor.zero_hp_reached
→ 규칙상 후속 Effect 또는 Encounter 종료 후보 평가

runtime_object.state_changed
→ 필요한 Navigation Invalidation Command 제안
```

직접 상태를 바꾸지 않고 새 Command·RuleExecution을 제출한다.

### 7.2 Projection Subscriber

관찰자별 Projection Delta를 만든다.

### 7.3 Presentation Subscriber

Domain Event를 `PresentationIntent`로 변환한다. Gameplay Commit을 기다리게 하지 않는다.

### 7.4 Journal·Replay Subscriber

감사·재생·사용자 로그에 필요한 참조를 만든다. 모든 Domain Event를 사용자 로그에 그대로 노출하지 않는다.

### 7.5 Diagnostics Subscriber

Trace, 성능, 실패와 Event 폭주를 기록한다.

## 8. Subscription 계약

```text
EventSubscriptionDefinition
├─ subscriberId
├─ acceptedEventTypes[]
├─ acceptedSchemaRange
├─ filterPolicy
├─ deliveryClass
├─ orderingScope
├─ idempotencyPolicy
├─ retryPolicy
├─ failurePolicy
├─ executionBudget
└─ handlerVersion
```

`deliveryClass`:

```text
critical_durable
recoverable_durable
best_effort
local_ephemeral
```

- `critical_durable`: Projection Cursor, 복구 필수 Journal처럼 유실 불가
- `recoverable_durable`: 원본 Authority State에서 재생성 가능
- `best_effort`: Presentation·Telemetry
- `local_ephemeral`: 동일 서버의 캐시 무효화 신호

## 9. 전달 보장과 멱등성

분산·복구 환경에서 모든 Subscriber에 정확히 한 번 실행을 약속하지 않는다.

기본 보장:

```text
Outbox
→ at-least-once delivery 가능
→ subscriber idempotency 필수
```

Subscriber Receipt:

```text
SubscriberReceipt
├─ subscriberId
├─ eventId
├─ handlerVersion
├─ processedAtLogicalCursor
├─ resultHash?
└─ state
```

상태:

```text
processing
→ processed | ignored | failed_retryable | dead_lettered
```

같은 `eventId + subscriberId + handlerVersion` 조합은 중복 상태 변경을 만들지 않는다.

## 10. 순서와 병렬 처리

모든 Event를 하나의 전역 Handler Queue에서 직렬 처리하지 않는다.

Subscriber는 필요한 Ordering Scope를 선언한다.

```text
global_authority_revision
transaction
aggregate
encounter
scene
observer_projection_stream
unordered
```

예시:

- 동일 Actor의 상태 Projection은 `aggregate` 순서를 유지한다.
- 동일 Client Projection Stream은 `observer_projection_stream` 순서를 유지한다.
- 서로 무관한 VFX Intent는 병렬 처리할 수 있다.

후속 Command의 실제 순서는 Event 처리 시간이 아니라 Command Ordering Coordinator가 다시 결정한다.

## 11. Event Chain과 폭주 방지

후속 실행은 원인 관계를 유지한다.

```text
Command A
→ Transaction A
→ Event A
→ Follow-up RuleExecution B
→ Transaction B
→ Event B
```

모든 항목은 `correlationId`, `causationId`, `traceId`로 연결한다.

방어 규칙:

- 동일 Correlation Chain의 최대 후속 깊이
- 동일 Event Type 반복 횟수 제한
- Subscriber별 초당 Follow-up Command 상한
- Cycle Detection Tag
- Budget 초과 시 안전 중단과 DM·Diagnostics 알림

무한 Event → Command → Event 루프를 허용하지 않는다.

## 12. Rule Event와 Domain Event 연결

Rule Runtime의 Timing Event는 Pending Execution 내부에서 반응과 Interrupt를 해결한다.

```text
Rule Event
→ Timing Window
→ Reaction·Modifier
→ Pending Effect
→ Transaction Commit
→ Domain Event
```

아직 판정 가능한 `before_damage`를 Domain Event로 발행하지 않는다. 실제 피해가 Commit된 뒤 `actor.damage_applied`를 발행한다.

## 13. Projection Event 생성

Projection Subscriber는 Domain Event 원본 Payload를 그대로 Client에 전달하지 않는다.

```text
CommittedDomainEvent
+ Current Authority Snapshot
+ Observer Context
+ Visibility·Knowledge·Role Policy
→ ProjectionEvent
```

```text
ProjectionEvent
├─ projectionEventId
├─ observerStreamId
├─ streamSequence
├─ authorityEpoch
├─ authorityRevision
├─ projectionTypeId
├─ publicPayload
├─ sourceEventId?
└─ projectionCursor
```

한 Domain Event가 관찰자마다 다른 Projection Event를 만들거나, 어떤 관찰자에게는 아무 Event도 만들지 않을 수 있다.

예시:

```text
숨은 함정 상태 변경
→ DM: 실제 함정 상태 Delta
→ 발견한 플레이어: 공개 가능한 상태 Delta
→ 미발견 플레이어: Event 없음
```

## 14. Presentation과 Camera

Presentation Subscriber는 공개 가능한 Projection Ref만 사용해 `PresentationIntent`를 생성한다.

```text
Domain Event
→ Disclosure Filter
→ PresentationIntent
→ Presentation Runtime
→ 필요 시 CameraRequest
```

Presentation·Camera Handler는 Domain Event를 근거로 Authority State를 수정하지 않는다.

## 15. Journal, Replay와 Rollback

### Journal

Command Journal과 Domain Event Outbox는 연결되지만 책임이 다르다.

```text
Command Journal
→ 무엇을 요청하고 어떻게 Commit했는가

Domain Event
→ Commit 결과로 어떤 사실이 발생했는가
```

### Replay

Replay는 Event만으로 권위 상태를 재구성한다고 가정하지 않는다. Snapshot + Journal이 권위 복구 원본이며, Domain Event는 연출·설명·진단 재생에 사용할 수 있다.

### Rollback

Rollback은 새 `AuthorityEpoch`를 만든다. 이전 Epoch의 Event는 역사 기록으로 남지만 새 Branch에 다시 적용하지 않는다.

새 Epoch에서는 복원된 State에 맞는 Projection Snapshot과 필요한 보정 Event를 생성한다.

## 16. Schema Version과 변경

Event Producer와 Subscriber를 동시에 배포한다고 가정하지 않는다.

규칙:

- Event에 Schema Version 포함
- 호환 가능한 추가 필드는 기본값 허용
- 의미 변경은 새 Schema Version 또는 새 Event Type
- Subscriber는 허용 Version Range 선언
- 저장 Event는 Migration Adapter 또는 보존된 Handler Version으로 처리
- UI 문구 변경 때문에 Domain Event Schema를 변경하지 않음

## 17. 역할 경계

### PLAYER_ONLY

- Event 원본 생성 권한 없음
- 자신에게 Projection된 공개 Event·로그 확인

### DM_ONLY

- 권한이 있는 Audit·Trace 조회
- Event 기반 후속 제안 승인·거절
- Dead Letter 재처리와 강제 후속 Command는 관리 UI와 감사 기록을 통해 실행
- 원본 Event를 수정하지 않음

### SHARED

- 자신에게 공개된 Projection Event와 Presentation 확인

### SYSTEM_ONLY

- Domain Event Draft 검증
- Transactional Outbox Commit
- Event Dispatch와 Receipt
- Projection·Presentation Adapter 실행
- Retry·Dead Letter·Cycle Guard
- Event Schema Migration

## 18. 실패 처리

```text
Subscriber 실패
→ 원래 Authority Commit 유지
→ Subscriber 정책에 따라 Retry
→ Circuit Breaker
→ Dead Letter
→ Diagnostics·DM 알림
```

Projection Subscriber가 장시간 실패하면 해당 Client Stream을 조용히 계속 진행시키지 않고 Snapshot Resync를 요구한다.

Presentation Subscriber 실패는 생략 또는 Fallback으로 종료한다.

권위 후속 Subscriber 실패는 원래 상태를 되돌리지 않으며, 재시도 또는 명시적인 Recovery Command로 해결한다.

## 19. 성능과 Backpressure

- Event Payload에 전체 Actor·Scene Snapshot을 반복 삽입하지 않는다.
- 안정 ID, 변경 요약과 필요한 Semantic Value만 포함한다.
- 대량 이동 Checkpoint Event는 정책에 따라 병합하되 규칙 Trigger 경계를 잃지 않는다.
- Presentation·Telemetry Queue는 Budget 초과 시 Drop·Coalesce 가능하다.
- Projection Queue가 지연되면 Client를 오래된 상태로 플레이시키지 않고 Resync Gate를 사용한다.
- Critical Subscriber가 느리다고 Authority Transaction Lock을 유지하지 않는다.

## 20. 금지 사항

- Commit 전 Domain Event 외부 발행
- Event Handler에서 Domain Store 직접 Mutation
- Client에 Raw Domain Event Broadcast
- Event Bus를 동기 함수 호출 대체물로 사용
- Subscriber 완료를 기다리며 Transaction Reservation 유지
- UI 문자열·VFX Asset ID를 Domain Event Type으로 사용
- Presentation Event 유실을 Gameplay 실패로 처리
- Event만으로 Snapshot 없는 권위 복구를 강제
- 이전 Authority Epoch Event를 Rollback 후 재적용

## 21. 완료 조건

- 모든 권위 Mutation은 필요한 Domain Event를 Transaction Outbox에 함께 Commit할 수 있다.
- Rule Event, Domain Event, Projection Event, Presentation Signal과 Journal Record가 타입과 책임으로 분리된다.
- 새 Subscriber 추가 시 기존 Domain Service를 수정하지 않고 Registry 등록으로 연결할 수 있다.
- Subscriber 실패가 원래 Gameplay Commit을 손상하지 않는다.
- 관찰자별 정보 공개가 Event 단계에서도 유지된다.
- 재접속·복구·Rollback에서 Event Cursor와 Authority Epoch가 안전하게 처리된다.
- 플레이테스트 중 Journal·Presentation·Diagnostics 기능을 교체해도 Gameplay Domain Code를 수정할 필요가 없다.
