# ADR-0029: 상태와 지속 효과는 통합 EffectInstance 수명주기로 관리한다

- 상태: 확정
- 결정일: 2026-08-03
- 관련 문서:
  - [`ADR-0024`](ADR-0024-hybrid-rule-recipes-and-reusable-advanced-operations.md)
  - [`ADR-0025`](ADR-0025-typed-rule-events-timing-windows-and-usage-gates.md)
  - [`ADR-0027`](ADR-0027-passive-modifiers-rule-overrides-and-conditional-activation.md)
  - [`ADR-0028`](ADR-0028-effect-recipes-pending-effects-and-commit-groups.md)
  - [`22. EffectRecipe와 효과 해결·확정 모델`](../22-effect-recipe-resolution-and-commit-model.md)
  - [`23. 상태·지속 효과·집중 수명주기 모델`](../23-condition-ongoing-effect-duration-and-concentration-model.md)

## 배경

주문, 특성, 아이템과 장면 효과는 실행이 끝난 뒤에도 규칙 상태를 남길 수 있다.

- 공식 상태를 적용한다.
- 방어도, 이동, 굴림과 행동 가능 여부를 일시적으로 바꾼다.
- 턴 시작이나 종료에 반복 피해와 내성 굴림을 발생시킨다.
- 집중이 유지되는 동안 여러 대상과 장면 오브젝트를 함께 유지한다.
- 시전자와 대상 사이의 연결, 변신, 소환체와 지속 영역을 만든다.
- 안티매직과 같은 효과가 기존 마법을 삭제하지 않고 일시적으로 억제한다.

상태, 버프, 디버프, 집중, 변신, 연결과 장면 영역을 각각 별도 런타임 시스템으로 만들면 중첩, 종료, 저장, 재접속과 정리 규칙이 서로 달라진다.

반대로 모든 것을 상태 이름과 남은 라운드 숫자만으로 저장하면 조건부 종료, 반복 내성, 억제, 자식 효과와 장면 오브젝트를 표현할 수 없다.

## 결정

실행 이후 남는 모든 규칙 효과는 공통 `EffectInstance` 수명주기를 사용한다.

```text
EffectDefinition 또는 ConditionDefinition
+ EffectRecipe의 생성 요청
→ PendingOngoingEffectCreation
→ EffectInstance
→ Capability·Trigger·SceneObject 활성화
→ 지속시간·종료 조건·억제 추적
→ EndEffectTransaction
→ 정리와 사후 사건
```

`ConditionDefinition`은 공식 상태의 규칙 내용을 정의한다. 상태가 실제 대상에게 적용되면 별도 상태 저장 체계를 만들지 않고 `effectKind = condition`인 `EffectInstance`를 생성한다.

주문 버프, 변신, 연결, 소환, 지속 영역과 기타 임시 규칙은 같은 인스턴스 계약을 사용한다.

## EffectInstance

```text
EffectInstance
├─ effectInstanceId
├─ effectKind
├─ definitionId와 version
├─ sourceExecutionId
├─ sourceActorId?
├─ ownerActorId?
├─ targetBindings[]
├─ anchorBinding?
├─ frozenParameters
├─ grantedCapabilityBindings[]
├─ triggerBindings[]
├─ ownedObjectBindings[]
├─ durationState
├─ endConditions[]
├─ stackingIdentity
├─ concentrationLink?
├─ suppressionSources[]
├─ parentEffectId?
├─ childEffectIds[]
├─ cleanupPlan
├─ lifecycleState
└─ revision
```

효과 인스턴스는 콘텐츠 정의를 복사한 캐릭터 데이터가 아니다. 정의 ID, 버전, 출처, 대상, 지속 상태와 실행 당시 고정해야 하는 파라미터만 저장한다.

## 상태 정의와 지속시간을 분리한다

`ConditionDefinition`은 중독, 기절, 넘어짐과 같은 상태가 부여하는 Capability와 규칙 태그를 정의한다.

지속시간과 제거 조건은 상태 이름 자체가 아니라 상태를 적용한 `EffectInstance`가 소유한다.

같은 상태라도 다음처럼 서로 다른 수명을 가질 수 있다.

- 다음 턴 시작까지
- 1분 동안
- 내성에 성공할 때까지
- 원인이 제거될 때까지
- 영구적으로

## DurationPolicy

지속시간은 실시간 초 카운터 하나로 처리하지 않는다.

```text
DurationPolicy
├─ instantaneous
├─ until_turn_boundary
├─ fixed_turns_or_rounds
├─ game_time_deadline
├─ until_rest
├─ concentration_bound
├─ until_successful_save
├─ until_event
├─ until_dispelled
└─ permanent
```

전투 경계 지속시간은 `turnId`, 경계 액터와 시작·종료 지점을 기준으로 한다. 분·시간 지속시간은 캠페인 게임 시간축을 사용한다.

지속시간 만료는 이벤트 큐와 인덱스로 처리하며 효과마다 프레임 루프를 만들지 않는다.

## 종료 조건

효과는 하나 이상의 타입 있는 종료 조건을 가진다.

```text
EndCondition
├─ duration_expired
├─ concentration_ended
├─ successful_save
├─ source_invalid
├─ target_invalid
├─ target_out_of_range
├─ line_of_effect_lost
├─ owner_incapacitated
├─ triggering_action_occurred
├─ dispelled
├─ explicit_recipe
└─ dm_ended
```

복수 조건은 `any`, `all` 또는 검증된 조합 정책으로 결합한다.

종료 후보가 발생하면 즉시 데이터를 삭제하지 않고 `EndEffectTransaction`으로 현재 상태와 조건을 재검증한 뒤 정리 작업을 확정한다.

## 집중

집중은 주문별 불리언이 아니라 Actor가 소유한 공통 집중 채널 상태다.

```text
ConcentrationState
├─ ownerActorId
├─ channelId
├─ rootEffectInstanceId
├─ linkedEffectInstanceIds[]
├─ startExecutionId
├─ rulesetPolicy
└─ revision
```

기본 규칙 세트는 일반적으로 하나의 집중 채널을 제공하지만, 채널 수와 예외는 `RuleOverrideCapability`가 변경할 수 있다.

새 집중 효과 시작, 기존 집중 종료와 새 효과 연결은 하나의 서버 트랜잭션으로 처리한다.

피해 이후 집중 검사는 `DamageApplied` 사건에서 생성하고, 피해 적용 단위 또는 동시 그룹을 어떻게 묶는지는 규칙 세트의 집중 검사 정책이 결정한다.

집중 종료 시 루트 효과와 연결된 자식 효과를 결정적인 순서로 정리한다.

## 부모·자식 효과

한 주문이 여러 런타임 결과를 만들 수 있으므로 효과 소유 관계를 명시한다.

예시:

```text
집중 루트 효과
├─ 대상 A의 버프 EffectInstance
├─ 대상 B의 버프 EffectInstance
├─ 지속 영역 EffectInstance
└─ 장면 오브젝트
```

부모 종료가 자식을 종료하는지는 `cleanupPlan`과 소유 정책이 정한다. 자식 하나가 먼저 종료되었다고 부모 전체가 자동 종료되는 것은 아니다.

## 중첩

중첩은 표시 이름이나 상태 문자열로 판단하지 않는다.

```text
StackingIdentity
├─ stackingKey
├─ equivalenceScope
├─ sourceOccurrenceId
└─ targetBinding
```

지원 정책 예시:

- `independent`
- `replace_existing`
- `refresh_duration`
- `extend_duration`
- `highest_potency_only`
- `merge_sources`
- `unique_by_source`
- `prohibited`

동일 상태 아이콘이 하나만 보여도 내부에는 여러 출처 인스턴스가 존재할 수 있다. 표시용 상태 집계는 권위 인스턴스를 대체하지 않는다.

## 억제와 종료를 분리한다

억제는 효과를 제거하지 않는다.

```text
EffectInstance
├─ lifecycleState: active
└─ suppressionSources[]
```

억제 출처가 하나 이상이면 해당 효과가 제공하는 Capability와 Trigger를 비활성화하거나 정의된 억제 정책을 적용한다.

```text
SuppressionPolicy
├─ capabilityBehavior
├─ triggerBehavior
├─ durationBehavior
├─ ownedObjectBehavior
└─ reactivationPolicy
```

안티매직 영역에서 나가면 억제 출처만 제거하고, 다른 억제 원인이 없으면 원래 효과를 재활성화한다.

디스펠, 지속시간 만료와 집중 종료는 억제가 아니라 실제 종료다.

## 정리 작업

종료는 단순히 인스턴스를 목록에서 삭제하는 작업이 아니다.

```text
CleanupPlan
├─ revokeGrantedCapabilities
├─ unregisterTriggers
├─ destroyOwnedSceneObjects
├─ despawnOrReleaseOwnedActors
├─ revertFormLayer
├─ releaseControlBindings
├─ endOwnedChildEffects
├─ removePresentationBindings
└─ emitEndEvents
```

정리 작업은 멱등적이어야 하며 같은 종료 요청이 재전송되어도 두 번 적용되지 않는다.

종료된 인스턴스는 로그와 중복 방지를 위해 즉시 영구 삭제하지 않고 종료 사유와 revision을 가진 기록으로 남긴다.

## 이벤트 기반 처리

반복 피해, 반복 내성, 거리 이탈과 행동 후 종료는 `TriggerCapability`를 사용한다.

```text
EffectInstance
→ TurnEnded TriggerCapability
→ 반복 내성 EffectRecipe
→ 성공 시 EndOngoingEffect
```

매 프레임 전체 효과를 순회하지 않는다.

효과 인덱스는 최소한 다음을 지원한다.

- 대상별
- 출처별
- 소유자별
- stacking key별
- 집중 채널별
- 이벤트 유형별
- 장면별
- 다음 만료 시점별

## 서버 권한과 저장

- 서버가 효과 적용 가능 여부, 면역, 중첩, 지속시간, 집중과 종료를 판정한다.
- 클라이언트는 남은 라운드, 집중 성공, 억제 여부와 종료 결과를 확정하지 않는다.
- 활성 효과는 정의 버전과 규칙 세트 버전에 고정되어 캠페인 중 콘텐츠 갱신으로 의미가 갑자기 바뀌지 않게 한다.
- 재접속과 서버 복구 시 EffectInstance, Capability, Trigger, 집중 연결과 만료 예약을 재구성한다.
- DM의 강제 종료, 연장, 억제와 복구는 감사 로그가 있는 명시적 명령으로 처리한다.

## 결과

- 공식 상태와 주문별 버프·디버프가 같은 수명주기를 사용한다.
- 집중, 반복 내성, 변신, 연결, 소환과 지속 영역을 조합할 수 있다.
- 억제와 종료를 구분하여 안티매직과 재활성화를 정확히 처리할 수 있다.
- 여러 출처의 동일 상태를 잃지 않으면서 UI에서는 하나의 집계 상태로 표시할 수 있다.
- 종료 시 Capability, Trigger, 장면 오브젝트와 자식 효과를 일관되게 정리할 수 있다.
- 프레임 폴링 없이 이벤트와 인덱스로 장기 효과를 관리할 수 있다.