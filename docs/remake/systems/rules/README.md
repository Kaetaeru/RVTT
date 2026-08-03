# Rules 시스템

주문 자원과 구성요소, 대상 지정, 능동·반응·패시브 특성, 상태와 집중, Recipe Step의 시스템 동작을 다룬다.

공통 Capability·Recipe 계약은 `../../architecture/`를 따른다.

## 권위 문서

- [`standard-recipe-step-library.md`](standard-recipe-step-library.md)
  - 모든 주문·Feature·아이템·몬스터 능력이 사용하는 공통 Step 언어
  - Step 단위 `Executable / Guided / Assisted`
  - 입력·검증·굴림·자원·PendingEffect·Commit·프레젠테이션·로그 Step
  - 표준 SubRecipe와 제한된 AdvancedOperation 기준
- [`spell-resource-pools-and-cast-payment-model.md`](spell-resource-pools-and-cast-payment-model.md)
- [`spell-components-and-material-inventory-contract.md`](spell-components-and-material-inventory-contract.md)
- [`spell-targeting-area-and-spatial-query-model.md`](spell-targeting-area-and-spatial-query-model.md)
- [`feat-feature-trigger-and-cross-turn-execution-model.md`](feat-feature-trigger-and-cross-turn-execution-model.md)
- [`active-feature-and-action-container-execution-model.md`](active-feature-and-action-container-execution-model.md)
- [`condition-ongoing-effect-duration-and-concentration-model.md`](condition-ongoing-effect-duration-and-concentration-model.md)

## 추천 읽기 순서

1. `../../architecture/rules-content-grant-capability-model.md`
2. `../../architecture/rules-content-execution-and-spell-contract.md`
3. `../../architecture/effect-recipe-resolution-and-commit-model.md`
4. `standard-recipe-step-library.md`
5. 대상 콘텐츠에 해당하는 세부 Rules 문서

## 구현 명세 준비도

`standard-recipe-step-library.md`는 `READY`다. 다음 단계에서 공통 Step 타입, Registry, RecipeCompiler, BindingStore와 실행기 계약의 구현 명세를 작성할 수 있다.
