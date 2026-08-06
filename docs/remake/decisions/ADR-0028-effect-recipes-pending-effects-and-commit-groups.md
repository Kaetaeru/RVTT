# ADR-0028: EffectRecipe는 보류 효과와 명시적인 확정 그룹으로 해결한다

- 상태: 확정
- 결정일: 2026-08-03
- 관련 문서:
  - [`ADR-0024`](ADR-0024-hybrid-rule-recipes-and-reusable-advanced-operations.md)
  - [`ADR-0025`](ADR-0025-typed-rule-events-timing-windows-and-usage-gates.md)
  - [`ADR-0026`](ADR-0026-active-capabilities-action-containers-and-unit-replacements.md)
  - [`ADR-0027`](ADR-0027-passive-modifiers-rule-overrides-and-conditional-activation.md)
  - [`11. 공통 실행 계약`](../architecture/rules-content-execution-and-spell-contract.md)
  - [`19. 트리거와 다른 턴 실행 모델`](../systems/rules/feat-feature-trigger-and-cross-turn-execution-model.md)
  - [`20. 능동형 특성과 행동 내부 실행 모델`](../systems/rules/active-feature-and-action-container-execution-model.md)
  - [`21. 패시브 특성 모델`](../architecture/passive-modifier-and-rule-override-model.md)
  - [`22. EffectRecipe와 효과 해결 모델`](../architecture/effect-recipe-resolution-and-commit-model.md)

## 배경

주문, 무기 공격, 숨결 무기, 재주, 직업 특성, 아이템과 몬스터 능력은 서로 다른 출처에서 오지만 실제 결과는 반복되는 규칙 조합으로 이루어진다.

- 공격 굴림 또는 내성 굴림
- 성공·실패와 치명타 분기
- 피해, 회복과 임시 HP
- 상태 적용과 제거
- 강제 이동과 순간이동
- 자원 변화
- 지속 효과와 장면 오브젝트 생성
- 다른 특성의 반응과 부모 실행 수정

이 결과를 각 콘텐츠 처리기가 직접 HP, 위치와 상태에 적용하면 피해 감소 반응, 방어도 변경, 저항·면역, 동시 피해와 롤백을 일관되게 처리할 수 없다.

반대로 모든 효과를 하나의 거대한 원자적 트랜잭션으로 묶으면 추가 공격, 매직 미사일 투사체와 여러 대상 주문처럼 순차 또는 부분적으로 독립된 결과를 정확히 표현하기 어렵다.

## 결정

모든 실행형 콘텐츠는 타입 있는 `EffectRecipe`를 사용한다.

`EffectRecipe`는 게임 상태를 직접 수정하지 않고 먼저 굴림 결과와 `PendingEffect`를 생성한다.

```text
ResolvedTargetingPlan
+ RuleExecutionContext
+ EffectRecipe
→ RollRecord와 ResolutionOutcome
→ PendingEffect[]
→ 반응·패시브·규칙 오버라이드 적용
→ CommitGroup[]
→ 권위 상태 확정
→ 사후 RuleEvent 생성
```

## EffectRecipe

```text
EffectRecipe
├─ recipeId
├─ schemaVersion
├─ inputBindings
├─ nodes[]
├─ outputBindings
├─ commitPolicy
└─ diagnosticsProfile
```

초기 노드 범주:

- 흐름: `Sequence`, `Branch`, `ForEach`, `BoundedRepeat`, `SimultaneousGroup`
- 굴림: `AttackRoll`, `SavingThrow`, `AbilityCheck`, `DamageRoll`, `HealingRoll`
- 결과: `CreateDamage`, `CreateHealing`, `CreateTemporaryHitPoints`
- 상태: `ApplyCondition`, `RemoveCondition`, `CreateOngoingEffect`
- 공간: `CreateForcedMovement`, `CreateTeleport`, `CreateRuleSceneObject`
- 자원: `CreateResourceChange`
- 고급 연산: ADR-0024의 등록된 재사용 연산
- 판정: `RequestDMAdjudication`

그래프는 유한하고 검증 가능해야 한다. 임의 코드 실행과 제한 없는 반복을 허용하지 않는다.

## 보류 효과

효과 노드는 영구 상태를 즉시 수정하지 않고 타입 있는 의도를 생성한다.

```text
PendingEffect
├─ pendingEffectId
├─ effectKind
├─ sourceExecutionId
├─ sourceContentId
├─ sourceActorId
├─ targetBinding
├─ payload
├─ tags[]
├─ resolutionState
├─ commitGroupId
└─ revisionSnapshot
```

주요 종류:

- `PendingDamage`
- `PendingHealing`
- `PendingTemporaryHitPoints`
- `PendingConditionChange`
- `PendingMovement`
- `PendingResourceChange`
- `PendingOngoingEffectCreation`
- `PendingSceneObjectChange`

반응과 패시브는 이미 확정된 상태를 되돌리는 대신 보류 효과와 계산 문맥을 수정한다.

## 해결 단계

상위 해결 순서를 다음처럼 고정한다.

```text
1. 레시피와 규칙 버전 스냅샷
2. 입력 바인딩과 대상 재검증
3. 공격·내성·판정 굴림
4. 결과 분기와 효과량 굴림
5. 보류 효과 생성
6. 실행자 측 추가 효과와 증강 결합
7. 대상 측 면역·저항·감소와 규칙 오버라이드 적용
8. 적용 직전 TimingWindow 해결
9. CommitGroup 재검증 및 확정
10. HP 0, 집중, 상태와 영역 사건 생성
11. 사후 consequence와 표현
```

정확한 피해 계산 세부 단계는 규칙 세트의 `DamageResolutionPipeline`이 소유한다. 콘텐츠 배열 순서로 결정하지 않는다.

## 굴림 범위

같은 레시피에서도 굴림 공유 범위가 다를 수 있다.

```text
RollScope
├─ per_execution
├─ per_affected_set
├─ per_target
├─ per_effect_unit
└─ per_component
```

예를 들어 여러 대상이 같은 피해 굴림을 공유하는 주문과 대상마다 별도로 굴리는 능력을 같은 노드로 표현할 수 있다.

## 피해 구조

피해는 단일 숫자가 아니라 하나 이상의 타입 있는 구성요소로 이루어진다.

```text
PendingDamage
├─ targetId
├─ components[]
├─ applicationId
├─ simultaneousGroupId?
├─ criticalPolicy
├─ saveOutcome?
└─ damagePipelineId

DamageComponent
├─ componentId
├─ damageType
├─ amountBinding
├─ sourceBinding
├─ tags[]
└─ responsePolicy
```

검격 피해와 화염 피해가 한 명중에서 함께 발생하는 경우 하나의 피해 적용 안에 여러 구성요소를 둔다.

매직 미사일처럼 여러 독립 투사체가 동시에 맞는 경우 각 투사체는 별도 `PendingDamage`지만 같은 `simultaneousGroupId`를 가진다.

## 동시 해결과 순차 해결

`CommitGroup`이 어떤 결과를 함께 확정할지 명시한다.

```text
CommitGroup
├─ commitGroupId
├─ atomicScope
├─ pendingEffectIds[]
├─ orderingPolicy
├─ revalidationPolicy
├─ failurePolicy
└─ state
```

초기 `atomicScope`:

- `single_effect`
- `effect_unit`
- `target_resolution`
- `simultaneous_group`
- `execution_resolution`

같은 그룹의 효과는 중간 상태를 외부에 노출하지 않고 함께 확정한다.

순차 공격, 지속 영역의 반복 발동과 행동 컨테이너의 각 공격 슬롯은 별도 확정 그룹을 사용하여 이전 결과를 되돌리지 않는다.

## 공격과 내성 결과

굴림 노드는 타입 있는 `ResolutionOutcome`을 만든다.

```text
ResolutionOutcome
├─ outcomeKind
├─ rollRecordIds[]
├─ successLevel
├─ criticalState
├─ margin?
├─ targetId?
└─ ruleSnapshot
```

효과 노드는 문자열 조건 대신 이 결과를 참조한다.

```text
Branch
├─ on_hit
├─ on_miss
├─ on_save_success
├─ on_save_failure
└─ on_critical
```

치명타가 어떤 주사위와 구성요소를 증가시키는지는 각 효과의 `criticalPolicy`와 규칙 세트가 결정한다.

## 피해, 회복과 임시 HP

- 피해, 회복과 임시 HP는 서로 다른 보류 효과다.
- 피해 감소를 회복으로 흉내 내지 않는다.
- 회복은 최대 HP, 회복 금지와 현재 상태를 확정 직전에 검증한다.
- 임시 HP는 일반 회복과 합산하지 않고 규칙 세트의 교체·선택 정책을 사용한다.
- 피해는 임시 HP와 HP 적용 전에 면역, 저항, 취약성, 감소와 반응 창을 통과한다.

## 상태 효과

상태 적용은 상태 이름만 추가하지 않는다.

```text
PendingConditionChange
├─ conditionDefinitionId
├─ operation
├─ targetId
├─ sourceBinding
├─ durationPolicy
├─ endConditions[]
├─ repeatSavePolicy?
├─ stackingPolicy
└─ immunityCheckPolicy
```

상태 면역, 중첩, 지속시간, 반복 내성과 제거 조건은 상태 정의와 규칙 세트가 해결한다.

## 강제 이동

강제 이동은 위치 좌표를 직접 덮어쓰지 않는다.

```text
PendingMovement
├─ movementKind
├─ targetId
├─ vectorOrDestination
├─ distancePolicy
├─ collisionPolicy
├─ terrainPolicy
├─ triggerPolicy
├─ fallPolicy
└─ pathResult
```

밀기, 끌기, 이동 명령과 순간이동을 구분한다.

강제 이동이 영역 진입·퇴장과 추락을 발생시키는지는 `triggerPolicy`와 규칙 세트가 결정하며, 의미 내비게이션과 공간 질의를 사용한다.

## 반응과 패시브의 연결

- `TriggerCapability`는 적절한 RuleEvent와 TimingWindow에서 보류 굴림, 보류 피해 또는 부모 실행을 수정한다.
- `ContextModifierCapability`는 굴림, 피해, 회복과 이동 문맥 구성 단계에 기여한다.
- `RuleOverrideCapability`는 등록된 규칙 지점에서 허용 여부와 계산 방식을 변경한다.
- 이미 확정된 효과를 수정하려면 명시적인 consequence 또는 보상 트랜잭션이 필요하다.

## 사후 사건

상태 확정 이후에만 다음 사건을 생성한다.

- `DamageApplied`
- `HealingApplied`
- `HitPointsReachedZero`
- `ConditionApplied`
- `MovementCompleted`
- `OngoingEffectStarted`
- 집중 검사 또는 종료 후보

보류 단계의 값으로 사후 트리거를 실행하지 않는다.

## 서버 권한과 안전

- 클라이언트는 최종 피해, 성공 여부, 저항 적용 결과와 상태 변경을 제출하지 않는다.
- 서버가 레시피, 굴림, 패시브, 반응, 규칙 오버라이드와 확정 그룹을 재계산한다.
- 모든 노드는 타입, 입력·출력 바인딩과 최대 실행 수를 콘텐츠 로딩 시 검증한다.
- 실행 깊이, 반복 횟수와 생성 가능한 효과 수에 안전 상한을 둔다.
- 같은 확정 그룹은 멱등 키로 중복 적용을 막는다.
- 확정 직전 대상, 위치, HP, 상태와 revision을 다시 검증한다.

## 결과

- 주문, 공격, 종 특성, 재주와 몬스터 능력이 같은 효과 해결 엔진을 사용한다.
- 피해 감소와 방어 반응을 영구 상태 적용 전에 처리할 수 있다.
- 여러 피해 유형, 여러 투사체, 여러 대상과 동시 효과를 구분할 수 있다.
- 순차 공격과 지속 효과가 이미 확정된 결과를 불필요하게 롤백하지 않는다.
- 상태, 강제 이동, 회복과 장면 변화도 같은 보류·확정 규약을 따른다.
- 규칙별 세부 순서를 데이터와 파이프라인으로 관리하면서 서버 권위를 유지할 수 있다.