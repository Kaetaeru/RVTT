# ADR-0077. Transactional Domain Event와 Outbox·Projection 경계

- 상태: 채택
- 작성일: 2026-08-04

## 배경

RVTT의 권위 상태 변경은 Command, RuleExecution과 Authority Transaction을 통해 처리된다. 그러나 Commit 이후 Presentation, Client Projection, Journal, Replay, Diagnostics와 미래 확장 시스템에 변경 사실을 전달하는 공통 계약이 없으면 Domain Runtime이 서로 직접 호출하게 된다.

또한 기존 문서에서 `Event`는 다음 서로 다른 의미로 사용되고 있었다.

- Rule Runtime의 Trigger·Timing Event
- Commit 이후의 Domain Event
- Client에 전달하는 Projection Event
- VFX와 Camera용 Presentation Signal
- 복구용 Command Journal Record

이를 하나의 Event Bus와 Payload로 합치면 Commit 전 사실이 외부에 노출되거나, 비밀 정보가 Client로 전달되거나, Subscriber 실패가 Gameplay Commit에 영향을 주는 문제가 생길 수 있다.

## 결정

RVTT는 성공한 Authority Transaction이 상태 Mutation과 `Domain Event Outbox`를 원자적으로 Commit하는 구조를 사용한다.

```text
Command / RuleExecution
→ Authority Transaction
→ State Mutation + Domain Event Outbox Commit
→ Event Dispatcher
→ Subscriber
```

다음을 명확히 분리한다.

```text
Rule Event
Domain Event
Projection Event
Presentation Signal
Journal Record
Telemetry Event
```

Domain Event는 이미 Commit된 과거 사실이며 상태 변경 요청이 아니다.

Subscriber가 추가 권위 상태 변경을 요구하면 Domain Store를 직접 수정하지 않고 새 Command 또는 RuleExecution을 제출한다.

Client는 Raw Domain Event를 받지 않는다. Domain Event와 최신 Authority State를 관찰자별 Disclosure Policy에 통과시켜 Projection Event를 생성한다.

Presentation은 공개 가능한 Projection Ref만 사용하고, 실패해도 원래 Gameplay Commit을 Rollback하지 않는다.

Event 전달은 복구 상황에서 중복될 수 있으므로 Subscriber는 Event ID 기반 멱등성을 가진다. Exactly-once Handler 실행을 전제하지 않는다.

## 이유

- 상태 Commit과 Event 발행 사이의 이중 성공·실패를 방지한다.
- Domain Runtime 간 직접 의존성을 줄인다.
- Projection과 Presentation을 Gameplay Authority에서 분리한다.
- 새 Journal·Diagnostics·Analytics·확장 Subscriber를 기존 Domain Code 수정 없이 추가할 수 있다.
- Rollback, 서버 복구와 재접속에서 Authority Epoch와 Event Cursor를 명확히 관리할 수 있다.
- 숨은 Actor, 실제 HP와 비밀 정보를 Raw Event Broadcast로 유출하지 않는다.

## 대안

### Domain Service의 직접 호출

문 상태 변경 후 Navigation, Presentation, Journal을 직접 호출하는 방식이다.

거부 이유:

- 순환 의존성과 호출 순서 결합이 커진다.
- 새 기능 추가마다 기존 Domain Service를 수정해야 한다.
- 일부 후속 호출 실패가 원래 Commit 경계와 섞인다.

### Commit 전 동기 Event Bus

Transaction 실행 중 Event Handler가 다른 Domain Mutation을 수행하는 방식이다.

거부 이유:

- 실제 Read·Write Set과 Ordering Key가 숨겨진다.
- Handler 순서에 따라 결과가 달라진다.
- Reaction·Rule Timing Event와 Commit 이후 사실이 혼합된다.

### Raw Domain Event의 Client Broadcast

거부 이유:

- 관찰자별 Visibility·Knowledge·Role 공개 경계를 보장할 수 없다.
- Client Protocol이 Domain 내부 Schema에 직접 결합된다.

### Event Sourcing을 유일한 권위 저장 방식으로 사용

거부 이유:

- 현재 RVTT의 Snapshot, Command Journal과 Chunk Recovery 계약을 불필요하게 대체한다.
- 모든 상태를 Event 재생만으로 복구할 필요가 없다.

Domain Event는 확장·Projection·진단 입력이며, 권위 복구 원본은 Snapshot과 Journal 계약을 유지한다.

## 결과

긍정적 결과:

- Transaction Commit 후 확장 가능한 후속 처리가 가능하다.
- Presentation과 Projection 실패가 Gameplay 상태를 손상하지 않는다.
- Event Schema와 Subscriber Version을 독립적으로 관리할 수 있다.
- Correlation·Causation Trace로 복잡한 실행 흐름을 추적할 수 있다.

비용:

- Event Registry, Outbox Cursor, Subscriber Receipt와 Dead Letter 관리가 필요하다.
- Subscriber는 멱등성과 Schema 호환성을 구현해야 한다.
- Projection 지연과 Backpressure를 감시해야 한다.

## 후속 요구

- Event Type Registry 구현 명세
- Transaction Outbox와 Commit Marker 결합 명세
- Projection Subscriber와 Observer Stream 명세
- Subscriber Retry·Circuit Breaker·Dead Letter 명세
- Correlation Chain Cycle Guard 명세
- Diagnostics Runtime에서 Event Lag과 실패 추적
