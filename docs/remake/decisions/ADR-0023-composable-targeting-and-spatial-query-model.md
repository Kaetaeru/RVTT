# ADR-0023: 주문 대상 지정은 조합형 선택·공간 질의 모델을 사용한다

- 상태: 확정
- 결정일: 2026-08-03
- 관련 문서:
  - [`ADR-0018`](ADR-0018-source-scoped-spellcasting-profiles.md)
  - [`ADR-0020`](ADR-0020-typed-spell-resource-pools-and-explicit-cast-payments.md)
  - [`11. 공통 실행 계약과 마법 처리 모델`](../architecture/rules-content-execution-and-spell-contract.md)
  - [`17. 주문 대상 지정·영역·공간 질의 모델`](../systems/rules/spell-targeting-area-and-spatial-query-model.md)

## 배경

주문은 겉보기에는 매우 다양한 방식으로 대상을 정한다.

- 자신 또는 접촉한 생물 하나
- 사거리 안의 생물 여러 명
- 보이는 지점 하나
- 물체, 문, 시체 또는 구조물
- 시전자에게서 뻗는 원뿔이나 선
- 지점을 중심으로 하는 구체, 원통 또는 입방체
- 여러 점으로 경로를 그리는 벽
- 첫 대상에서 다음 대상으로 이어지는 연쇄
- 선택한 지점에 소환체, 환영, 위험 지대 또는 포털 생성
- 지속 중인 영역 안에 들어오거나 턴을 시작하는 대상
- 원래 대상이 이동하거나 사라진 뒤 다시 판정해야 하는 효과

이 모든 주문을 각각 별도 UI와 별도 서버 처리기로 구현하면 콘텐츠 수에 비례해 대상 지정 코드가 늘어난다.

반대로 주문을 `single`, `aoe`, `self` 정도의 단순 분류로만 표현하면 벽, 연쇄, 다단계 선택, 지속 영역과 창의적 배치를 정확히 다룰 수 없다.

## 결정

주문과 기타 규칙 콘텐츠는 하나 이상의 `TargetingStep`으로 선택 절차를 정의한다.

```text
TargetingPlanDefinition
└─ TargetingStep[]
   ├─ EntitySelectionStep
   ├─ PointSelectionStep
   ├─ ObjectSelectionStep
   ├─ DirectionSelectionStep
   ├─ PathSelectionStep
   ├─ AreaPlacementStep
   ├─ OptionSelectionStep
   └─ DependentSelectionStep
```

각 단계는 다음을 독립적으로 정의한다.

- 무엇을 선택하는가
- 몇 개를 선택하는가
- 선택 순서와 이전 단계 의존성
- 거리, 시야, 효과선과 접근 조건
- 생물 종류, 관계, 상태와 태그 조건
- 중복 선택과 자기 자신 선택 허용 여부
- 선택 시점과 확정 시점의 재검증 정책
- 플레이어 선택, 자동 선택 또는 DM 판정 여부

공간을 사용하는 단계는 `AreaShapeDefinition`을 참조한다.

```text
AreaShapeDefinition
├─ sphere
├─ cylinder
├─ cone
├─ line
├─ cube
├─ box
├─ wall
├─ ring
├─ aura
├─ footprint
├─ path-volume
└─ custom-handler
```

영역 안에 실제로 포함되는 대상은 클라이언트가 보낸 목록을 신뢰하지 않고 서버의 `SpatialQuery`가 계산한다.

```text
확정된 선택과 형상
+ 장면 규칙 공간 데이터
+ 토큰 점유 범위
+ 시야·효과선·엄폐 정책
+ 대상 필터
→ AffectedSet
```

## 선택과 효과 대상을 분리한다

플레이어가 직접 선택한 값과 실제 효과를 받는 대상을 같은 목록으로 취급하지 않는다.

```text
SelectedReferences
→ 주문을 배치하기 위해 플레이어가 선택한 대상·지점·경로

AffectedSet
→ 공간 질의와 필터를 통과하여 실제 효과를 받는 대상
```

예를 들어 화염구는 지점을 하나 선택하지만 실제 피해 대상은 구체 안의 모든 적격 생물이다.

벽 주문은 경로를 선택하지만 효과 대상은 생성된 벽 오브젝트와 이후 벽에 접촉하거나 통과하는 대상이다.

## 단일 파이프라인

대상 지정은 다음 공통 생명주기를 사용한다.

```text
TargetingPlan 생성
→ 단계별 입력 수집
→ 클라이언트 미리보기
→ 서버 단계 검증
→ 완성된 TargetSelectionDraft 생성
→ 비용 예약 전 최종 재검증
→ SpatialQuery로 AffectedSet 계산
→ 주문 실행 트랜잭션에 고정
→ 효과 해결
```

대상 선택 중에는 권위 상태를 변경하지 않는다.

## 범위와 가시성

거리, 시야, 효과선과 엄폐는 하나의 boolean으로 합치지 않는다.

```text
TargetValidationPolicy
├─ rangePolicy
├─ visibilityPolicy
├─ lineOfEffectPolicy
├─ coverPolicy
├─ originPolicy
└─ sceneBoundaryPolicy
```

주문마다 필요한 조합을 선택한다.

- 보이는 생물이어야 함
- 보이지 않아도 위치를 알고 있으면 가능
- 효과선만 필요
- 완전 엄폐 대상 불가
- 접촉 가능해야 함
- 시전자 자신을 원점으로 사용
- 선택한 지점이나 소환체를 새 원점으로 사용

## 다단계와 연쇄

여러 대상을 순서대로 고르는 주문은 별도 주문 전용 UI를 만들지 않고 단계 의존성을 사용한다.

```text
1단계: 첫 대상 선택
2단계: 첫 대상에서 일정 거리 안의 두 번째 대상 선택
3단계: 이전에 선택하지 않은 다음 대상 선택
```

각 단계의 거리 원점과 후보군은 이전 선택 결과에서 계산할 수 있다.

자동 연쇄, 가장 가까운 대상, 무작위 대상과 같은 규칙은 `SelectionResolver`를 사용한다.

## 지속 영역과 생성 오브젝트

시전 순간의 `AffectedSet`만 저장하지 않는다.

지속 영역, 벽, 소환체, 환영과 포털은 장면에 `SceneEffectInstance` 또는 전용 장면 오브젝트를 생성한다.

```text
SceneEffectInstance
├─ sourceExecutionId
├─ shapeSnapshot
├─ placementTransform
├─ duration and concentration link
├─ occupancy and trigger policy
├─ visibility policy
└─ current revision
```

대상이 영역에 들어오거나 턴을 시작할 때는 당시 장면 상태로 새 공간 질의를 수행한다.

## 자동화 경계

대부분의 주문은 공통 선택 단계, 형상과 필터의 조합으로 처리한다.

공통 구조로 정확히 표현하기 어려운 경우에만 제한된 전용 처리기를 사용한다.

예시:

- 자유 형상의 복잡한 환영
- 세계 지도나 다른 장면을 대상으로 하는 순간이동
- 서술적 조건을 가진 예언과 탐지
- 여러 생물 사이의 임의 네트워크를 생성하는 특수 주문

전용 처리기도 공통 TargetingPlan, 서버 검증, 실행 트랜잭션, 로그와 롤백을 우회하지 않는다.

## 결과

- 단일 대상, 복수 대상, 지점, 물체, 경로와 영역 주문을 같은 계약으로 처리할 수 있다.
- 원뿔, 선, 구체, 벽과 오라가 공통 공간 질의를 사용한다.
- 연쇄와 다단계 주문을 단계 의존성으로 표현할 수 있다.
- 지속 영역은 시전 순간 대상 목록이 아니라 장면 효과로 유지된다.
- 클라이언트는 미리보기와 입력을 담당하고 최종 포함 대상은 서버가 계산한다.
- 완전히 자유로운 서술형 주문에는 여전히 DM 판정이나 전용 처리기가 필요하다.