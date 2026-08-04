# Rules 시스템

주문 자원과 구성요소, 대상 지정, 능동·반응·패시브 특성, 상태와 집중, Recipe Step의 시스템 동작을 다룬다.

공통 Capability·RuleExecution·Recipe 계약은 `../../architecture/`를 따른다.

거리, 영역 포함, 시야 증거, 효과선, 엄폐, 점유와 배치 판정은 [`Spatial Query Engine과 Provider 계약`](../../architecture/spatial-query-engine-and-provider-contract.md)을 따른다. Rules 문서는 공간 결과를 사용하는 규칙 의미와 사용자 흐름을 정의하며, 자체 공간 계산기를 만들지 않는다.

Capability 실행, 비용 예약, Recipe 실행, 반응·Trigger, PendingEffect와 CommitGroup의 전체 순서는 [`Rule Runtime Orchestrator와 Pending Execution 계약`](../../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md)을 따른다.

둘 이상의 Actor·Object·자원·상태를 변경하는 Commit과 Command 충돌 순서는 [`Command Ordering, Logical Time와 Transaction Coordinator 계약`](../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)을 따른다.

상태, 버프·디버프, 집중, 변신, 지속 영역, 소환과 Suppression의 권위 구조는 [`Effect, Condition과 Ongoing Runtime 계약`](../../architecture/effect-condition-and-ongoing-runtime-contract.md)을 따른다.

## 권위 문서

### 공통 실행

- [`../../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md`](../../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md)
  - 모든 공격·주문·Feature·Item·Trigger의 공통 RuleExecution 상태기계
  - 비용 예약, Recipe Runtime, RuleEvent와 중첩 TimingWindow
  - Capability Offer, Child Execution, CommitGroup과 사후 Event
  - Pending Execution 저장·재접속·Rollback과 실행 Budget
- [`../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md`](../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)
  - Ordering Key, 다중 Key Reservation과 Deadlock 방지
  - Resource Reservation과 짧은 Ordering Reservation 분리
  - Read Set·Write Set·Precondition과 Commit Graph
  - 원자적 Commit, Authority Revision, Journal과 Recovery
- [`../../architecture/effect-condition-and-ongoing-runtime-contract.md`](../../architecture/effect-condition-and-ongoing-runtime-contract.md)
  - ConditionDefinition과 OngoingEffectDefinition의 Compiled Build
  - EffectRegistry, EffectInstance Identity와 Binding
  - Duration, End Condition, Stacking, Concentration과 Suppression
  - Modifier·Capability·Trigger 기여와 Form Overlay
  - Runtime Object Ownership, Persistence, Rollback과 Projection
- [`standard-recipe-step-library.md`](standard-recipe-step-library.md)
  - 모든 주문·Feature·아이템·몬스터 능력이 사용하는 공통 Step 언어
  - Step 단위 `Executable / Guided / Assisted`
  - 입력·검증·굴림·자원·PendingEffect·Commit·프레젠테이션·로그 Step
  - 표준 SubRecipe와 제한된 AdvancedOperation 기준

### 주문

- [`spell-resource-pools-and-cast-payment-model.md`](spell-resource-pools-and-cast-payment-model.md)
- [`spell-components-and-material-inventory-contract.md`](spell-components-and-material-inventory-contract.md)
- [`spell-targeting-area-and-spatial-query-model.md`](spell-targeting-area-and-spatial-query-model.md)
  - TargetingPlan, 선택 단계, 영역 형상과 Rules 수준 AffectedSet 의미
  - 실제 Snapshot, Provider, Query Result와 실패 계약은 Architecture 문서를 따름

### 특성·Trigger·지속 효과

- [`feat-feature-trigger-and-cross-turn-execution-model.md`](feat-feature-trigger-and-cross-turn-execution-model.md)
  - RuleEvent 후보, 반응과 행동 비용 없는 Trigger의 규칙 의미
  - 실제 TimingWindow Stack과 실행 복구는 Orchestrator 계약을 따름
- [`active-feature-and-action-container-execution-model.md`](active-feature-and-action-container-execution-model.md)
- [`condition-ongoing-effect-duration-and-concentration-model.md`](condition-ongoing-effect-duration-and-concentration-model.md)
  - `SUPERSEDED`; 현재 권위는 Effect Runtime Architecture와 ADR-0065

## 추천 읽기 순서

1. `../../architecture/runtime-architecture-principles.md`
2. `../../architecture/compiled-build-and-authoritative-state-pattern.md`
3. `../../architecture/networking-command-event-and-client-synchronization-contract.md`
4. `../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md`
5. `../../architecture/spatial-query-engine-and-provider-contract.md`
6. `../../architecture/rules-content-grant-capability-model.md`
7. `../../architecture/rules-content-execution-and-spell-contract.md`
8. `../../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md`
9. `../../architecture/effect-recipe-resolution-and-commit-model.md`
10. `../../architecture/effect-condition-and-ongoing-runtime-contract.md`
11. `standard-recipe-step-library.md`
12. 대상 콘텐츠에 해당하는 세부 Rules 문서

## 고정 경계

- Capability는 사용 가능성을 설명하고 RuleExecution의 생명주기를 직접 소유하지 않는다.
- Recipe와 Step Handler는 TimingWindow Stack, 권위 Store와 Orchestrator 상태를 직접 수정하지 않는다.
- RuleEvent Handler는 부모 실행을 직접 변경하지 않고 Modifier, Override, Offer 또는 Child Execution을 사용한다.
- Reaction과 Prompt 대기는 저장 가능한 Pending Execution이며 열린 Remote 호출에 의존하지 않는다.
- 비용 예약과 실제 소비 Commit을 분리한다.
- 반응·DM 입력 대기 중 Ordering Lock을 유지하지 않는다.
- 영구 상태 변경은 PendingEffect와 CommitGroup을 사용하고 Transaction Coordinator가 원자적으로 확정한다.
- EffectInstance는 Character·Actor·Encounter에 복사하지 않고 EffectRegistry가 소유한다.
- Effect는 Character Build와 수치를 직접 덮어쓰지 않고 출처가 있는 Contribution을 제공한다.
- 집중 교체, Stack 변경과 Effect Graph 정리는 원자적 Transaction을 사용한다.
- Suppression과 Effect 종료를 구분한다.
- Commit 이후에만 Authority Revision, RuleEvent와 Client Projection을 공개한다.
- Client Animation과 주사위 물리가 권위 결과를 결정하지 않는다.
- Rollback 이후 이전 Authority Epoch의 Offer·Prompt·Reservation·Command·Timer 후보를 재사용하지 않는다.

## 구현 명세 준비도

`Rule Runtime Orchestrator`, `Command Ordering과 Transaction Coordinator`, `Effect Runtime`, `standard-recipe-step-library.md`, `001-recipe-step-runtime-foundation.md`와 `002-standard-step-handler-contracts.md`는 공통 구현 명세로 내릴 수 있는 수준이다.

다만 다음 구현 명세는 순서를 지킨다.

```text
Ordering Key Registry와 Transaction Foundation
→ RuleExecution Registry와 상태기계
→ 비용 예약과 Pending Input
→ RuleEvent·TimingWindow·Capability Offer
→ Recipe Runtime Adapter
→ PendingEffect·CommitGroup 조정
→ Effect Build·Registry·Contribution Foundation
→ Duration·Concentration·Suppression·Form Overlay
→ Journal·재접속·Rollback
→ 개별 Roll·Effect·공간 Step Handler
```
