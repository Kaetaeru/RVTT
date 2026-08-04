# ADR-0085: Production-parity Deterministic Scenario와 Controlled Nondeterminism

- 상태: 확정
- 결정일: 2026-08-04
- 관련 문서:
  - [`Deterministic Simulation, Scenario와 Test Harness Runtime 계약`](../architecture/deterministic-simulation-scenario-and-test-harness-runtime-contract.md)
  - [`Diagnostics, Observability, Correlated Trace와 Incident Runtime 계약`](../architecture/diagnostics-observability-correlated-trace-and-incident-runtime-contract.md)
  - [`Command Ordering, Logical Time와 Transaction Coordinator 계약`](../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)
  - [`Persistence, Snapshot, Journal과 Recovery 계약`](../architecture/persistence-and-session-recovery-model.md)
  - [`Networking Command, Event와 Client Synchronization 계약`](../architecture/networking-command-event-and-client-synchronization-contract.md)
  - [`Dice와 Resolution Runtime 계약`](../architecture/dice-roll-check-save-attack-and-resolution-runtime-contract.md)

## 배경

RVTT는 주사위, 동시 Command, Scheduler, Event Subscriber, Network 재전송, 재접속, 저장 실패와 Rollback이 결합되는 서버 권위 시스템이다.

수동 플레이테스트나 Runtime별 독립 Unit Test만으로는 다음 문제를 안정적으로 재현할 수 없다.

- 같은 자원을 동시에 변경하는 Race
- Commit Marker 전후 Server Restart
- 이전 AuthorityEpoch의 비동기 작업 재실행
- Projection Gap과 Reconnect 후 UI 복구
- 중간 Checkpoint가 있는 긴 시간 진행
- 숨은 정보가 Projection·UI·Diagnostics에 유출되는 문제
- Presentation 실패가 Gameplay 결과에 영향을 주는 문제
- 활성 실행 중 Policy Version 혼합

테스트 편의를 위해 별도 규칙 계산기나 Store 직접 수정 Hook을 만들면 생산 코드와 테스트 코드가 서로 다른 결과를 낼 수 있다.

또한 하나의 전역 Seed와 현실 Sleep에 의존하면 관련 없는 코드 변경만으로 모든 기대 결과가 바뀌거나 동시성 테스트가 불안정해진다.

## 결정

### 1. Test Harness는 생산 Runtime 경로를 그대로 실행한다

다음은 테스트에서도 생산과 같은 Registry와 Handler를 사용한다.

```text
Command
Authorization·Validation
RuleExecution
Policy Snapshot
Ordering·Transaction
Domain Event·Subscriber
Projection
UI ViewModel
Persistence·Recovery
Diagnostics
```

Test-only 상태 변경 Command, Store 직접 수정과 별도 규칙 엔진을 만들지 않는다.

### 2. 외부 비결정 요소만 결정적 Adapter로 교체한다

```text
RNG
Authority Monotonic Clock
ID Factory
Task·Message Delivery Scheduler
Network
Storage
Presentation ACK
Virtual Client
```

Adapter는 생산 Interface 계약을 구현하며 Scenario가 입력과 실패 시점을 명시적으로 통제한다.

### 3. Scenario, Fixture, Version과 Frozen Reference를 명시한다

각 Scenario는 안정적 ID와 Version을 가지며 다음을 고정한다.

- Fixture Manifest
- Content Version
- Ruleset·Policy Snapshot
- Compiled Build
- Participant와 Audience
- Random Stream Plan
- Action Schedule
- Fault Plan
- Assertion과 Budget

누락된 Version을 최신 값으로 자동 대체하지 않는다.

### 4. RNG는 의미별 독립 Stream을 사용한다

하나의 전역 Cursor 대신 Roll, Initiative, Table, AI 등 의미별 Named Stream을 Root Seed에서 파생한다.

관련 없는 Random Draw가 추가되어도 다른 Stream의 결과를 연쇄 변경하지 않아야 한다.

Production Incident 재현을 위해 Production Root Seed를 Export하지 않는다. 이미 확정된 RollRecord와 Random Decision을 재생하거나 합성 Scenario Seed를 사용한다.

### 5. 시간과 실행 순서를 현실 Sleep으로 제어하지 않는다

- Timeout과 Lease는 Virtual Monotonic Clock을 사용한다.
- Campaign Time은 실제 Game Time Runtime의 TimeAdvance와 Encounter Boundary를 사용한다.
- Presentation Time은 별도 Virtual Clock을 사용한다.
- Command, Task, Subscriber와 Network Message 순서는 Deterministic Scheduler가 명시한다.

### 6. 동시성은 명시적 Schedule과 제한 탐색으로 검증한다

특정 Race는 정확한 Interleaving으로 재현한다.

추가로 등록된 Yield Point, Ordering Key와 Conflict 관계를 기준으로 Bounded Interleaving Exploration을 수행한다.

현실 Thread Scheduling의 우연이나 Sleep 길이를 테스트 조건으로 사용하지 않는다.

### 7. Fault는 등록된 Boundary에서만 주입한다

Network, Subscriber, Storage, Transaction, Presentation, Client, Restart와 Rollback의 타입 있는 Fault Point를 사용한다.

Domain Mutation 중간을 임의 Monkey Patch해 생산 시스템에서 발생할 수 없는 부분 상태를 만들지 않는다.

### 8. State뿐 아니라 전체 관찰 결과를 검증한다

Scenario Assertion은 다음을 포함할 수 있다.

```text
Authority State와 Semantic Digest
Command·Transaction Result
Domain Event와 Subscriber Delivery
Projection Snapshot·Delta
UI ViewModel
Trace Graph와 Policy Binding
Reservation·Tombstone 누수
Logical Budget
Quiescence
Negative Disclosure
```

전체 문자열 Golden보다 Domain Invariant와 Semantic Assertion을 우선한다.

### 9. 정보 누출을 부정 Assertion으로 검사한다

같은 Authority Scenario를 DM, Player, Observer와 Player Preview Audience로 투영한다.

Secret Canary의 값과 ID가 Projection Byte, Hover, UI, Error, Diagnostics, Cache와 Presentation Parameter에 존재하지 않아야 한다.

UI에서 보이지 않는 것만으로 통과 처리하지 않는다.

### 10. Restart, Reconnect와 Rollback은 생산 절차를 사용한다

- Restart는 Snapshot과 Commit Journal로 새 Runtime을 Boot한다.
- Reconnect는 Protocol, Projection Catch-up과 Client Ready Gate를 사용한다.
- Rollback은 Snapshot Branch와 새 AuthorityEpoch를 사용한다.

Store를 직접 과거 값으로 덮어쓰지 않는다.

### 11. 결정적 Logical Cost와 실제 성능 시간을 분리한다

Headless Scenario는 Query 수, Event 수, Projection Byte, Retry와 Step 수 같은 결정적 비용을 검사한다.

실제 CPU, Frame과 Network Latency는 Roblox Integration·Benchmark 환경에서 별도로 측정한다.

### 12. 실패는 최소 재현 Artifact로 보존한다

실패 시 다음을 보존한다.

- Scenario·Fixture·Version·Hash
- Root Seed와 Named Stream Override
- 최소 Action Schedule과 Fault Plan
- 실패 Assertion
- State·Projection·Trace Diff
- 최소화된 Interleaving

실제 사용자 데이터와 Production RNG Seed는 자동 포함하지 않는다.

## 선택하지 않은 대안

### 별도 Simulation 규칙 엔진

생산 Runtime과 규칙·우선순위·오류 처리 방식이 달라지는 Drift가 발생하므로 선택하지 않았다.

### Store를 직접 수정하는 Fixture와 Assertion

Authorization, Transaction, Event와 Projection 경계를 우회하므로 선택하지 않았다.

### 하나의 전역 RNG Seed와 Cursor

관련 없는 Random Draw 추가가 이후 모든 결과를 변경해 Scenario 유지 비용이 과도하므로 선택하지 않았다.

### 현실 Sleep 기반 동시성 테스트

실행 환경에 따라 결과가 달라지고 실패를 재현하기 어려우므로 선택하지 않았다.

### 모든 Snapshot을 Golden 문자열로 비교

비의미 ID·정렬·표현 변경에 지나치게 민감하고 Domain Invariant를 설명하지 못하므로 선택하지 않았다.

### UI가 숨겼는지만 확인하는 보안 테스트

비밀 데이터가 이미 Client에 전달됐을 수 있으므로 선택하지 않았다.

### Production Root Seed 보존과 Export

미래 Random 결과 예측과 보안 위험이 있으므로 선택하지 않았다.

### Headless 테스트만으로 완전한 검증 주장

Roblox Transport, Instance, Streaming, Rendering과 실제 Client 문제를 놓칠 수 있으므로 선택하지 않았다.

## 결과

### 장점

- 복잡한 오류를 Seed, Schedule과 Fault Plan으로 반복 재현할 수 있다.
- 테스트와 생산 규칙의 Drift를 줄인다.
- 동시성·복구·Rollback·정보 누출을 자동 검증할 수 있다.
- 실패가 State, Projection, UI와 Trace를 포함한 설명 가능한 Artifact를 제공한다.
- Policy와 Build 변경의 실제 영향 범위를 비교할 수 있다.
- 플레이테스트에서 발견한 문제를 영구 Regression Scenario로 전환할 수 있다.

### 비용

- Runtime 전반에 RNG, Clock, ID, Transport와 Storage Adapter 주입 경계가 필요하다.
- Canonical Serialization, Semantic Digest와 Stable Ordering이 필요하다.
- Scenario, Fixture, Assertion과 Fault Point Registry를 Version 관리해야 한다.
- Virtual Client, Restart, Rollback과 Projection Harness 구현 비용이 크다.
- Headless와 실제 Roblox Integration Suite를 모두 유지해야 한다.

이 비용은 재현되지 않는 동시성·복구·정보 누출 오류를 수동으로 추적하는 비용보다 작다.
