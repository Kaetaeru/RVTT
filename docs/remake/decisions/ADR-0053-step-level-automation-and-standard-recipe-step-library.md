# ADR-0053. Step 단위 자동화와 표준 Recipe Step Library

- 상태: 확정
- 결정일: 2026-08-03
- 즉시 구현 명세 가능성: READY
- 관련 문서:
  - [`EffectRecipe와 효과 해결·확정 모델`](../architecture/effect-recipe-resolution-and-commit-model.md)
  - [`규칙 콘텐츠 공통 실행 계약`](../architecture/rules-content-execution-and-spell-contract.md)
  - [`표준 Recipe Step Library`](../systems/rules/standard-recipe-step-library.md)

## 배경

주문, Feature, Feat, 아이템과 몬스터 능력 전체에 `Executable`, `Guided`, `Assisted` 중 하나를 붙이면 실제 실행 흐름을 정확히 표현할 수 없다.

하나의 콘텐츠 안에서도 다음이 섞일 수 있다.

- 서버가 즉시 처리할 수 있는 계산과 상태 변경
- 플레이어가 대상·위치·옵션을 선택해야 하는 과정
- DM이 자유 서술과 세계 반응을 판단해야 하는 과정

콘텐츠 전체에 하나의 자동화 수준을 붙이면 구현자가 어느 부분을 자동화해야 하는지 다시 추측해야 하고, 같은 공통 기능이 주문마다 중복 구현될 가능성이 커진다.

## 결정

### 1. 자동화 수준은 콘텐츠 전체가 아니라 Recipe Step에만 부여한다

Spell, Feature, Feat, ItemAction과 MonsterAbility는 자동화 수준을 직접 가지지 않는다.

```text
ContentDefinition
→ Recipe
→ Step[]
→ 각 Step의 automationMode
```

Step의 자동화 수준은 다음 세 값으로 고정한다.

```text
Executable
→ 필요한 입력이 이미 준비되어 있으며 서버가 권위적으로 실행한다.

Guided
→ 플레이어 또는 DM의 구조화된 선택을 받은 뒤 서버가 실행한다.

Assisted
→ 규칙만으로 결과를 확정할 수 없어 DM의 의미 판단이나 수동 결과 입력을 기다린다.
```

### 2. Step은 한 가지 명확한 책임만 가진다

하나의 Step은 가능한 한 다음 중 하나만 수행한다.

- 입력 수집
- 유효성 검사
- 계산
- 굴림
- 자원 예약·소모
- PendingEffect 생성
- 상태 확정
- 대기·반응 창 개방
- 표현 요청 생성
- 로그·감사 기록
- 정리

`SelectTargetsAndRollAndDamage`처럼 여러 규칙 단계를 숨기는 거대 Step은 표준 라이브러리에 등록하지 않는다.

### 3. Recipe는 검증 가능한 유한 그래프다

표준 제어 Step은 다음으로 제한한다.

```text
Sequence
Branch
ForEach
BoundedRepeat
SelectFirstValid
SimultaneousGroup
ReferenceSubRecipe
WaitForDecision
```

무한 반복, 임의 Luau 문자열, 설명문 파싱과 클라이언트가 선택한 분기 결과 신뢰는 허용하지 않는다.

### 4. Step은 타입 계약과 실행 특성을 등록한다

모든 StepDefinition은 최소한 다음 정보를 가진다.

```text
stepTypeId
category
inputSchema
outputSchema
automationMode
executionAuthority
sideEffectClass
rollbackPolicy
failurePolicy
allowedContexts
determinismClass
version
```

### 5. 상태 변경 Step은 직접 임의 변경하지 않는다

피해, 회복, 상태, 이동, 자원과 오브젝트 변경 Step은 기존 `PendingEffect → CommitGroup` 경계를 따른다.

```text
Step 실행
→ PendingEffect 또는 권위 Command 생성
→ 반응·Override 해결
→ CommitGroup 확정
→ 영구 상태 변경
```

프레젠테이션 Step은 규칙 상태의 권위 원본이 될 수 없다.

### 6. 공통 Step으로 표현할 수 없는 규칙은 제한된 AdvancedOperation으로 확장한다

전용 구현이 필요할 때도 주문 전체를 독립 실행기로 만들지 않는다.

```text
공통 Step
+ 등록된 AdvancedOperation Step
+ 공통 Commit 경계
```

AdvancedOperation은 다음 조건을 모두 만족해야 한다.

- 안정된 `operationId`와 버전이 있다.
- 입력·출력이 타입으로 검증된다.
- 실행 시간과 생성 효과 수에 상한이 있다.
- 서버에서만 규칙 결과를 확정한다.
- PendingEffect와 CommitGroup을 우회하지 않는다.
- 저장·롤백·재접속 시 재개 정책이 정의된다.
- 해당 기능을 일반 Step으로 분해하지 않은 이유가 문서화된다.

### 7. 콘텐츠 완료 여부는 Recipe 전체의 단일 등급이 아니라 Step 커버리지로 판단한다

콘텐츠 구현 검토 시 다음을 기록한다.

```text
모든 규칙 단계가 Step으로 표현됐는가
Guided 입력에 UI 계약이 있는가
Assisted 판단의 요청·응답·취소 흐름이 있는가
모든 상태 변경이 Commit 경계를 통과하는가
지원하지 않는 규칙 문장이 명시됐는가
```

`Assisted` Step이 포함되어 있다는 이유만으로 미완성 콘텐츠로 판단하지 않는다.

## 결과

### 장점

- 주문마다 중복되는 대상 선택, 굴림, 피해와 상태 코드를 재사용할 수 있다.
- 자동 처리와 DM 판단의 경계가 정확해진다.
- 콘텐츠 데이터 검증과 테스트 케이스 생성이 쉬워진다.
- VFX 실패와 규칙 실패를 분리할 수 있다.
- 새로운 규칙 콘텐츠가 기존 Step 조합만으로 추가될 가능성이 높아진다.

### 비용

- 초기 StepCatalog와 타입 계약을 꼼꼼히 설계해야 한다.
- 지나치게 작은 Step으로 분해하면 Recipe가 장황해질 수 있다.
- AdvancedOperation의 남용을 검토하는 규칙이 필요하다.

## 대안으로 채택하지 않은 것

### 콘텐츠 전체에 자동화 등급 하나 부여

한 콘텐츠 안의 자동·선택·DM 판단 단계를 구분하지 못하므로 채택하지 않는다.

### 모든 주문과 Feature를 전용 코드로 구현

중복, 버그 수정 비용과 규칙 일관성 문제가 커지므로 채택하지 않는다.

### 모든 규칙을 순수 데이터만으로 표현

자유도가 높은 일부 D&D 규칙을 억지로 거대한 범용 DSL에 넣게 되므로 채택하지 않는다.
