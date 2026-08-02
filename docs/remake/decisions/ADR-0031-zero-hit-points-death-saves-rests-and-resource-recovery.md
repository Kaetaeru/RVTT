# ADR-0031: HP 0, 죽음 내성, 휴식과 자원 회복은 상태 전이와 회복 계획으로 처리한다

- 상태: 확정
- 결정일: 2026-08-03
- 관련 문서:
  - [`ADR-0025`](ADR-0025-typed-rule-events-timing-windows-and-usage-gates.md)
  - [`ADR-0028`](ADR-0028-effect-recipes-pending-effects-and-commit-groups.md)
  - [`ADR-0029`](ADR-0029-unified-effect-instances-duration-concentration-and-suppression.md)
  - [`23. 상태·지속 효과·집중 수명주기 모델`](../23-condition-ongoing-effect-duration-and-concentration-model.md)
  - [`25. HP 0·죽음 내성·휴식·자원 회복 모델`](../25-zero-hit-points-death-saves-rest-and-resource-recovery-model.md)

## 배경

HP 0 이후의 상태와 휴식 회복은 단순한 숫자 초기화가 아니다.

- HP가 0이 되면 즉사 여부, 의식불명, 안정화와 죽음 내성 상태를 판정해야 한다.
- HP 0에서 받는 피해는 일반 피해와 다른 후속 규칙을 일으킬 수 있다.
- 치유, 안정화, 자동 회복과 사망은 서로 다른 상태 전이다.
- 짧은 휴식과 긴 휴식은 시간, 방해, 활동 제한과 완료 조건을 가진다.
- Hit Dice, 주문 슬롯, Feature 사용 횟수, 아이템 충전과 종 특성 자원은 서로 다른 회복 정책을 가진다.
- 휴식 중 플레이어가 Hit Dice를 원하는 횟수만큼 순차 소비하거나 중단할 수 있다.
- 휴식 완료 효과를 항목별 즉시 적용하면 중간 실패와 재접속에서 일부만 회복되는 문제가 생긴다.

## 결정

HP 0 이후 생존 상태는 `VitalStateMachine`으로, 휴식과 자원 회복은 `RestSession`과 `RecoveryPlan`으로 처리한다.

```text
Damage Commit
→ VitalTransitionEvaluation
→ VitalState 변경 또는 사망
→ 후속 Condition·Trigger·EffectInstance 갱신
```

```text
Rest 선언
→ RestSession
→ 시간·활동·방해 추적
→ 완료 후보
→ RecoveryPlan 생성
→ 선택 입력과 자원 회복 계산
→ RecoveryCommitGroup
→ 권위 상태 확정
```

## VitalState

```text
VitalState
├─ conscious
├─ unconscious_at_zero
├─ stable_at_zero
├─ dying
├─ dead
└─ custom_registered
```

HP 값과 생존 상태를 같은 필드로 합치지 않는다.

- HP가 0이라고 항상 죽음 내성을 굴리는 것은 아니다.
- 안정화된 0 HP와 죽어가는 0 HP를 구분한다.
- 특정 Actor 유형은 죽음 내성을 사용하지 않고 즉시 사망하거나 별도 정책을 사용할 수 있다.

## VitalTransitionEvaluation

HP 변화가 확정된 뒤 규칙 세트가 상태 전이를 계산한다.

```text
VitalTransitionContext
├─ actorId
├─ previousHitPoints
├─ currentHitPoints
├─ maximumHitPoints
├─ damageApplication?
├─ healingApplication?
├─ currentVitalState
├─ actorDeathPolicy
├─ activeCapabilities
└─ rulesetSnapshot
```

가능한 결과:

- 의식 유지
- HP 0 및 의식불명
- 죽어가는 상태 시작
- 안정화
- 의식 회복
- 즉사
- 사망
- DM 판정 요청

## 죽음 내성

죽음 내성은 일반 저장 자원이나 상태 아이콘이 아니라 활성 `DeathSaveState`다.

```text
DeathSaveState
├─ actorId
├─ lifecycleId
├─ successes
├─ failures
├─ state
├─ lastRollRecordId?
├─ startedAtTurnId
└─ revision
```

새로운 죽어가는 생명주기가 시작될 때 새 `lifecycleId`를 만든다.

죽음 내성 굴림은 `TurnStarted` 또는 규칙 세트가 지정한 경계에서 `TriggerCapability`와 `EffectRecipe`로 실행한다.

특수 주사위 결과, 피해로 인한 실패 추가, 안정화와 사망 임계치는 규칙 세트의 `DeathSavePolicy`가 소유한다.

## HP 0에서의 피해와 치유

- HP 0에서 받는 피해도 먼저 일반 `PendingDamage`와 피해 파이프라인을 통과한다.
- 피해가 확정된 뒤 `DamageApplied` 사건이 현재 VitalState와 DeathSaveState를 갱신한다.
- 치유가 HP를 1 이상으로 만들면 의식 회복 후보를 생성하고 죽음 내성 생명주기를 종료한다.
- 안정화는 치유가 아니며 HP를 자동 증가시키지 않는다.
- HP 0 상태에서의 즉사 판정은 최종 피해와 최대 HP 등의 규칙 입력으로 별도 평가한다.

## 안정화

안정화는 `stable_at_zero` 상태 전이다.

```text
StabilizeEffect
→ DeathSaveState 종료 또는 비활성화
→ stable_at_zero
→ 안정화 지속 효과와 자동 회복 정책 등록
```

안정화된 대상이 피해를 받으면 규칙 세트에 따라 다시 죽어가는 상태로 전환할 수 있다.

## 사망

사망은 단순 Condition이 아니라 Actor 생명주기의 권위 상태다.

```text
DeathRecord
├─ actorId
├─ causeExecutionId?
├─ causeEffectId?
├─ occurredAtGameTime
├─ rulesetSnapshot
├─ reversiblePolicy
└─ revision
```

사망 시 다음을 결정적인 순서로 처리한다.

- 집중 종료
- 생존 중에만 유지되는 EffectInstance 종료
- 죽음 내성 상태 종료
- 행동 기회 제거
- 토큰 표현 전환
- 부활 가능 정보 보존

시체 토큰, 전리품과 장면 오브젝트 처리는 Actor·인벤토리 정책과 연결하되 캐릭터 정의를 삭제하지 않는다.

## RestSession

휴식은 즉시 실행되는 버튼이 아니라 시간 구간을 가진 세션이다.

```text
RestSession
├─ restSessionId
├─ restKind
├─ participantActorIds[]
├─ startedAtGameTime
├─ requiredDuration
├─ allowedActivityPolicy
├─ interruptionPolicy
├─ participantStates[]
├─ state
├─ completionCandidateAt?
└─ revision
```

상태:

```text
proposed
active
interrupted
completion_pending
completed
cancelled
failed
```

파티가 같은 시간 동안 쉬더라도 참가자별 완료 여부와 방해 상태를 따로 가질 수 있다.

## RecoveryPlan

휴식 완료가 가능한 시점에 각 Actor별 회복 계획을 생성한다.

```text
RecoveryPlan
├─ restSessionId
├─ actorId
├─ automaticRecoveries[]
├─ optionalRecoveryChoices[]
├─ resourceRefreshes[]
├─ effectEndings[]
├─ exhaustionChanges[]
├─ hitPointRecovery?
├─ hitDiceRecovery?
├─ validationSnapshot
└─ state
```

회복 항목은 즉시 적용하지 않고 최종 선택과 재검증 후 하나의 `RecoveryCommitGroup`으로 확정한다.

## ResourceRecoveryPolicy

모든 자원은 타입 있는 회복 정책을 가진다.

```text
ResourceRecoveryPolicy
├─ triggerKinds[]
├─ recoveryAmountExpression
├─ recoveryMode
├─ capPolicy
├─ prerequisitePredicate?
├─ choicePolicy?
└─ stackingPolicy
```

`triggerKinds` 예시:

- `short_rest_completed`
- `long_rest_completed`
- `dawn_reached`
- `initiative_started`
- `turn_started`
- `explicit_recipe`

`recoveryMode` 예시:

- `restore_to_maximum`
- `restore_amount`
- `restore_fraction`
- `recover_spent_units`
- `reroll_or_set`
- `custom_registered`

Feature마다 휴식 완료 콜백을 직접 등록하지 않는다. 중앙 회복 엔진이 활성 ResourceDefinition과 Capability를 수집한다.

## Hit Dice와 선택 회복

짧은 휴식의 Hit Dice 사용처럼 플레이어 선택이 필요한 회복은 `OptionalRecoveryChoice`로 처리한다.

```text
OptionalRecoveryChoice
├─ choiceId
├─ availableResourceId
├─ maximumSpend
├─ perUnitRecipeId
├─ repeatPolicy
├─ stopPolicy
└─ previewPolicy
```

각 사용은 별도 보류 소비와 회복 결과를 생성할 수 있지만, 휴식 완료 전에 확정된 사용은 감사 가능한 하위 CommitGroup으로 기록한다.

재접속 시 사용한 Hit Dice와 이미 적용된 회복을 중복 적용하지 않는다.

## 휴식 방해와 중단

활동이나 전투가 휴식을 무효화하는지는 `RestInterruptionPolicy`가 결정한다.

```text
RestInterruptionPolicy
├─ disallowedEvents[]
├─ toleratedActivityBudget?
├─ resumePolicy
├─ elapsedTimeRetentionPolicy
└─ consequencePolicy
```

휴식 실패 시 아직 완료되지 않은 자동 회복은 적용하지 않는다. 이미 규칙상 확정된 선택형 소비가 있다면 해당 정책에 따라 유지 또는 롤백한다.

## 효과와 휴식

`EffectInstance`의 종료 조건은 휴식 완료 사건을 구독할 수 있다.

```text
until_short_rest
until_long_rest
```

휴식이 시작됐다는 이유만으로 종료하지 않고, 해당 참가자의 휴식 완료가 확정된 뒤 종료한다.

## 서버 권한과 저장

- 서버가 HP 0 전이, 즉사, 죽음 내성 결과, 안정화와 사망을 판정한다.
- 클라이언트는 죽음 내성 성공·실패 수와 휴식 완료를 확정하지 않는다.
- DeathSaveState, RestSession, RecoveryPlan은 revision과 멱등 키를 가진다.
- 서버 재시작과 재접속 후 활성 죽음 내성, 휴식 경과, 선택 회복과 회복 예약을 복원한다.
- DM 강제 안정화, 사망, 부활, 휴식 완료와 자원 회복은 감사 로그가 있는 명시적 명령으로 처리한다.

## 결과

- HP 0, 안정화, 죽음 내성, 의식 회복과 사망을 명확한 상태 전이로 관리할 수 있다.
- 피해와 치유가 기존 EffectRecipe 파이프라인을 우회하지 않는다.
- 짧은·긴 휴식을 시간과 방해 조건이 있는 실제 세션으로 처리할 수 있다.
- 주문 슬롯, Feature 사용 횟수, Hit Dice, 아이템 충전과 기타 자원을 같은 회복 엔진에서 처리할 수 있다.
- 선택형 회복과 자동 회복을 구분하면서 부분 적용과 중복 적용을 방지할 수 있다.
- 휴식 종료 효과, 집중 종료와 부활 가능 정보를 일관되게 보존할 수 있다.