# ADR-0087: Atomic Immediate Closure와 Event-driven Deferred Consequence

- 상태: 확정
- 결정일: 2026-08-04
- 관련 문서:
  - [`Cross-Domain Outcome Cascade와 Integration Boundary Runtime 계약`](../architecture/cross-domain-outcome-cascade-and-integration-boundary-runtime-contract.md)
  - [`Transaction Coordinator 계약`](../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)
  - [`Domain Event Runtime 계약`](../architecture/domain-event-outbox-subscription-and-projection-runtime-contract.md)
  - [`Rule Runtime Orchestrator 계약`](../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md)
  - [`Diagnostics Runtime 계약`](../architecture/diagnostics-observability-correlated-trace-and-incident-runtime-contract.md)
  - [`Simulation과 Test Harness 계약`](../architecture/deterministic-simulation-scenario-and-test-harness-runtime-contract.md)

## 배경

RVTT의 주요 Domain Runtime은 자신의 권위 상태와 규칙을 독립적으로 소유한다.

그러나 하나의 결과는 여러 Domain을 동시에 변경할 수 있다.

```text
피해
→ HP
→ VitalState·DeathSave
→ Effect·Concentration
→ Encounter Turn·Objective
→ Projection·Presentation
```

```text
제작 완료
→ 재료 소비
→ ItemInstance 생성
→ Ground Presence 생성
→ Downtime Activity 완료
```

두 극단은 모두 문제가 있다.

### 모든 변화를 한 서비스가 직접 호출

- Domain Store 간 순환 의존이 생긴다.
- 부분 성공과 숨은 수정이 발생한다.
- 테스트와 복구가 어렵다.

### 모든 결과를 Commit 이후 Event Subscriber에 위임

- HP 0인데 conscious인 상태처럼 불가능한 중간 상태가 공개될 수 있다.
- 죽었지만 Action Opportunity가 남아 있는 상태가 생길 수 있다.
- 같은 원인에서 파생된 필수 변경이 중복·누락될 수 있다.

따라서 Cross-Domain 연쇄를 공통 기준으로 분류해야 한다.

## 결정

### 1. Cross-Domain 결과를 Immediate Closure와 Deferred Consequence로 분리한다

```text
Immediate Closure
→ Commit 직후 권위 상태가 유효하기 위해 반드시 필요한 결정적 변화

Deferred Consequence
→ Commit된 결과를 원인으로 새 굴림·선택·반응·판정·시간 진행이 필요한 후속 실행
```

### 2. Immediate Closure는 Root Outcome과 같은 Authority Transaction에 포함한다

예:

- 최종 피해, 임시 HP, 현재 HP와 VitalState 전이
- DeathSaveState 생성·종료
- 사망으로 즉시 무효인 Opportunity·Reservation·Capability 정리
- Encounter 종료 상태, Encounter-bound Effect와 Session Mode Binding 전환
- Character Build 활성화와 Persistent State Migration
- 제작 재료 소비와 Output Item·Ground Presence 생성

Closure Provider 하나라도 실패하면 전체 Transaction을 Abort한다.

### 3. Deferred Consequence는 Outbox와 Follow-up Ledger를 통해 새 Command 또는 RuleExecution으로 실행한다

예:

- 피해 후 집중 내성
- 사망 후 Objective·Morale·Surrender 평가
- Object 파괴 후 Journal·Search Index 재구성
- Scheduler Due 이후 Encounter Proposal

Subscriber가 다른 Store를 직접 수정하지 않는다.

### 4. Integration Coordinator는 새 Domain Store를 소유하지 않는다

Coordinator는 Provider Contribution, Ordering Key, Invariant, Commit Graph, Follow-up Intent와 Gate를 조립한다.

실제 Mutation은 각 Domain Provider가 자신의 Store에 대해 제안한다.

### 5. Damage·HP 0·Death의 유효성 Closure를 원자적으로 처리한다

정책상 허용되지 않는 다음 상태를 AuthorityRevision으로 공개하지 않는다.

```text
HP 0 + conscious
Dead + active death saves
Dead + usable action opportunity
Dead + concentration channel maintained
```

집중 내성처럼 새 굴림이 필요한 결과는 별도 RuleExecution으로 분리한다.

### 6. Encounter Cursor 이동과 Objective 판정은 소유 Runtime이 처리한다

Damage·Vital Provider가 Timeline Cursor를 직접 이동시키거나 Encounter를 종료하지 않는다.

Death Closure는 Participant·Turn Eligibility와 Gate만 갱신할 수 있다. 실제 Turn Advance와 Objective Evaluation은 Encounter Command로 실행한다.

### 7. Derived Index와 Presentation 실패는 권위 Commit을 되돌리지 않는다

Spatial·Navigation·Perception·Journal Index는 Invalidation Record에서 재구성한다.

권위 판정에 안전하지 않은 Index가 필요하면 관련 Command Scope만 Gate한다.

UI·Presentation·Diagnostics 실패는 이미 Commit된 Gameplay 결과를 변경하지 않는다.

### 8. 같은 Transaction의 Projection은 Barrier Batch로 적용한다

HP, VitalState, Effect, Opportunity와 Encounter 상태가 같은 Commit에서 바뀌면 Client는 관련 Projection Segment를 원자 Batch로 적용한다.

### 9. 모든 Follow-up은 멱등하고 Epoch-aware하다

Root Outcome과 각 Deferred Consequence는 별도 Idempotency Key를 가진다.

Rollback 이전 AuthorityEpoch의 Follow-up, ACK와 Index 완료 신호는 새 Branch에 적용하지 않는다.

### 10. Integration Contract는 Simulation Scenario로 검증한다

필수 범위:

- Damage→HP 0→DeathSave
- Instant Death→Effect·Opportunity Cleanup
- Concentration Follow-up 중복 방지
- Current Turn Actor 사망
- Encounter End State 보존
- Crafting Input·Output 원자성
- Runtime Object Lifecycle과 Index 실패
- Journal Anchor 수명주기
- Rollback 이전 Follow-up 차단
- Projection Barrier와 Presentation 실패 격리

## 선택하지 않은 대안

### 모든 연쇄를 하나의 거대 Transaction에 포함

새 굴림, Reaction, 사용자 선택과 시간 진행까지 Transaction 안에 넣으면 장기 Lock, 재진입과 복구 복잡도가 커진다.

### 모든 연쇄를 Domain Event로 지연

권위 불변식이 깨진 중간 상태가 공개될 수 있으므로 선택하지 않았다.

### Damage Service가 Character·Effect·Encounter Store를 직접 수정

소유권과 의존 방향이 무너지고 기능별 예외가 누적되므로 선택하지 않았다.

### 사망 시 Encounter에서 Actor를 즉시 삭제

Encounter 참가 기록, Character, Inventory, Corpse와 Scene Presence의 수명주기가 다르므로 선택하지 않았다.

### Derived Index 실패 시 Root Transaction Rollback

이미 Commit된 권위 상태와 외부 Event를 되돌리는 새 불일치를 만들 수 있으므로 선택하지 않았다.

### UI가 여러 Domain Event를 순서대로 조합

HP와 VitalState 같은 동일 Transaction 결과가 부분 화면으로 보일 수 있으므로 Projection Barrier를 사용한다.

## 결과

### 장점

- Cross-Domain 상태 불변식을 원자적으로 유지한다.
- Domain Service 간 직접 상호 호출을 줄인다.
- 새 굴림·선택·반응은 명시적 RuleExecution으로 추적된다.
- Retry, Restart, Rollback과 Subscriber 중복을 멱등하게 처리할 수 있다.
- Derived Index와 Presentation 장애를 Gameplay Authority에서 격리한다.
- Damage·Death·Encounter와 Downtime·Crafting이 같은 통합 원칙을 사용한다.
- Completion Audit와 Main System Guide가 공통 경계를 참조할 수 있다.

### 비용

- Outcome Provider Registry와 Integration Planner가 필요하다.
- Domain별 Immediate Closure·Deferred Consequence Adapter를 구현해야 한다.
- Follow-up Ledger, Gate와 Projection Barrier 상태를 저장·복구해야 한다.
- 단일 Domain 테스트 외에 Cross-Domain Scenario가 필요하다.

이 비용은 각 시스템이 서로를 직접 호출하거나 불가능한 중간 상태를 허용하는 비용보다 작다.
