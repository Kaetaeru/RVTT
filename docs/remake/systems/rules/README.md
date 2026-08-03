# Rules 시스템

주문 자원과 구성요소, 대상 지정, 능동·반응·패시브 특성, 상태와 집중, Recipe Step의 시스템 동작을 다룬다.

공통 Capability·Recipe 계약은 `../../architecture/`를 따른다.

거리, 영역 포함, 시야 증거, 효과선, 엄폐, 점유와 배치 판정은 [`Spatial Query Engine과 Provider 계약`](../../architecture/spatial-query-engine-and-provider-contract.md)을 따른다. Rules 문서는 공간 결과를 사용하는 규칙 의미와 사용자 흐름을 정의하며, 자체 공간 계산기를 만들지 않는다.

## 권위 문서

- [`standard-recipe-step-library.md`](standard-recipe-step-library.md)
  - 모든 주문·Feature·아이템·몬스터 능력이 사용하는 공통 Step 언어
  - Step 단위 `Executable / Guided / Assisted`
  - 입력·검증·굴림·자원·PendingEffect·Commit·프레젠테이션·로그 Step
  - 표준 SubRecipe와 제한된 AdvancedOperation 기준
- [`spell-resource-pools-and-cast-payment-model.md`](spell-resource-pools-and-cast-payment-model.md)
- [`spell-components-and-material-inventory-contract.md`](spell-components-and-material-inventory-contract.md)
- [`spell-targeting-area-and-spatial-query-model.md`](spell-targeting-area-and-spatial-query-model.md)
  - TargetingPlan, 선택 단계, 영역 형상과 Rules 수준 AffectedSet 의미
  - 실제 Snapshot, Provider, Query Result와 실패 계약은 Architecture 문서를 따름
- [`feat-feature-trigger-and-cross-turn-execution-model.md`](feat-feature-trigger-and-cross-turn-execution-model.md)
- [`active-feature-and-action-container-execution-model.md`](active-feature-and-action-container-execution-model.md)
- [`condition-ongoing-effect-duration-and-concentration-model.md`](condition-ongoing-effect-duration-and-concentration-model.md)

## 추천 읽기 순서

1. `../../architecture/runtime-architecture-principles.md`
2. `../../architecture/spatial-query-engine-and-provider-contract.md`
3. `../../architecture/rules-content-grant-capability-model.md`
4. `../../architecture/rules-content-execution-and-spell-contract.md`
5. `../../architecture/effect-recipe-resolution-and-commit-model.md`
6. `standard-recipe-step-library.md`
7. 대상 콘텐츠에 해당하는 세부 Rules 문서

## 구현 명세 준비도

`standard-recipe-step-library.md`는 `READY`다. 다음 단계에서 공통 Step 타입, Registry, RecipeCompiler, BindingStore와 실행기 계약의 구현 명세를 작성할 수 있다.

공간 관련 Step의 구현 명세는 Runtime Navigation, Scene Compiler, Runtime Object와 Command Ordering의 선행 계약을 확인한 뒤 작성한다.
