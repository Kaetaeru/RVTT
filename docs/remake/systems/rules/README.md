# Rules 시스템

주문 자원과 구성요소, 대상 지정, 능동·반응·패시브 특성, 상태와 집중, Recipe Step의 시스템 동작을 다룬다.

공통 Capability·RuleExecution·Recipe 계약은 `../../architecture/`를 따른다.

거리, 영역 포함, 시야 증거, 효과선, 엄폐, 점유와 배치 판정은 [`Spatial Query Engine과 Provider 계약`](../../architecture/spatial-query-engine-and-provider-contract.md)을 따른다. Rules 문서는 공간 결과를 사용하는 규칙 의미와 사용자 흐름을 정의하며, 자체 공간 계산기를 만들지 않는다.

Capability 실행, 비용 예약, Recipe 실행, 반응·Trigger, PendingEffect와 CommitGroup의 전체 순서는 [`Rule Runtime Orchestrator와 Pending Execution 계약`](../../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md)을 따른다.

## 권위 문서

### 공통 실행

- [`../../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md`](../../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md)
  - 모든 공격·주문·Feature·Item·Trigger의 공통 RuleExecution 상태기계
  - 비용 예약, Recipe Runtime, RuleEvent와 중첩 TimingWindow
  - Capability Offer, Child Execution, CommitGroup과 사후 Event
  - Pending Execution 저장·재접속·Rollback과 실행 Budget
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

## 추천 읽기 순서

1. `../../architecture/runtime-architecture-principles.md`
2. `../../architecture/networking-command-event-and-client-synchronization-contract.md`
3. `../../architecture/spatial-query-engine-and-provider-contract.md`
4. `../../architecture/rules-content-grant-capability-model.md`
5. `../../architecture/rules-content-execution-and-spell-contract.md`
6. `../../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md`
7. `../../architecture/effect-recipe-resolution-and-commit-model.md`
8. `standard-recipe-step-library.md`
9. 대상 콘텐츠에 해당하는 세부 Rules 문서

## 고정 경계

- Capability는 사용 가능성을 설명하고 RuleExecution의 생명주기를 직접 소유하지 않는다.
- Recipe와 Step Handler는 TimingWindow Stack, 권위 Store와 Orchestrator 상태를 직접 수정하지 않는다.
- RuleEvent Handler는 부모 실행을 직접 변경하지 않고 Modifier, Override, Offer 또는 Child Execution을 사용한다.
- Reaction과 Prompt 대기는 저장 가능한 Pending Execution이며 열린 Remote 호출에 의존하지 않는다.
- 비용 예약과 실제 소비 Commit을 분리한다.
- 영구 상태 변경은 PendingEffect와 CommitGroup을 사용한다.
- Client Animation과 주사위 물리가 권위 결과를 결정하지 않는다.
- Rollback 이후 이전 Authority Epoch의 Offer·Prompt 응답을 재사용하지 않는다.

## 구현 명세 준비도

`Rule Runtime Orchestrator`, `standard-recipe-step-library.md`, `001-recipe-step-runtime-foundation.md`와 `002-standard-step-handler-contracts.md`는 공통 구현 명세로 내릴 수 있는 수준이다.

다만 다음 구현 명세는 순서를 지킨다.

```text
RuleExecution Registry와 상태기계
→ 비용 예약과 Pending Input
→ RuleEvent·TimingWindow·Capability Offer
→ Recipe Runtime Adapter
→ PendingEffect·CommitGroup 조정
→ 저장·재접속·Rollback
→ 개별 Roll·Effect·공간 Step Handler
```
