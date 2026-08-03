# 25. HP 0·죽음 내성·휴식·자원 회복 모델

- 상태: 초안
- 작성일: 2026-08-03
- 관련 문서:
  - [`19. 트리거와 다른 턴 실행 모델`](../../../rules/feat-feature-trigger-and-cross-turn-execution-model.md)
  - [`22. EffectRecipe와 효과 해결·확정 모델`](../../../../architecture/effect-recipe-resolution-and-commit-model.md)
  - [`23. 상태·지속 효과·집중 수명주기 모델`](../../../rules/condition-ongoing-effect-duration-and-concentration-model.md)
  - [`24. 무기·아이템·공격 프로필 모델`](../../../inventory/item-weapon-attack-profile-and-mastery-model.md)
  - [`ADR-0031`](../../../../decisions/ADR-0031-zero-hit-points-death-saves-rests-and-resource-recovery.md)

## 1. 문서 목적

이 문서는 Actor의 HP가 0이 되었을 때부터 안정화, 회복, 사망 또는 부활로 이어지는 생존 상태와 짧은·긴 휴식에 의한 자원 회복 절차를 정의한다.

대상은 다음을 포함한다.

- HP 0 도달
- 즉사 판정
- 의식불명과 죽어가는 상태
- 죽음 내성 성공·실패
- HP 0에서 받는 피해
- 안정화와 안정화 후 자동 회복
- 치유로 인한 의식 회복
- 사망과 부활 가능 기록
- 짧은 휴식과 긴 휴식
- 휴식 방해와 중단
- Hit Dice 소비와 회복
- 주문 슬롯, Feature 사용 횟수, 종 특성 자원과 아이템 충전 회복
- 휴식 종료 상태와 효과 정리
- 재접속·서버 복구·DM 개입

핵심 원칙:

```text
HP 숫자
≠ 의식 상태
≠ 죽음 내성 상태
≠ 사망 상태
```

```text
휴식 버튼 클릭
≠ 즉시 전부 회복
```

---

## 2. 생존 상태 전체 구조

```text
HitPointState
├─ current
├─ maximum
├─ temporary
└─ revision

VitalState
├─ conscious
├─ unconscious_at_zero
├─ dying
├─ stable_at_zero
├─ dead
└─ custom_registered

DeathSaveState?
DeathRecord?
```

HP와 VitalState는 함께 검증되지만 별도 책임을 가진다.

### 유효성 예시

```text
HP > 0 + conscious
→ 일반적 유효 상태

HP = 0 + dying
→ 죽음 내성 진행

HP = 0 + stable_at_zero
→ 안정화됨

HP = 0 + dead
→ 사망
```

규칙 세트 또는 특수 Actor 정책이 허용하지 않는 조합은 검증 오류다.

---

## 3. ActorDeathPolicy

모든 Actor가 플레이어 캐릭터와 같은 죽음 내성을 사용하지 않는다.

```text
ActorDeathPolicy
├─ zeroHpBehavior
├─ deathSavePolicyId?
├─ instantDeathPolicyId?
├─ stabilizationPolicyId?
├─ corpsePolicyId?
├─ revivalPolicyId?
└─ dmOverridePolicy
```

`zeroHpBehavior` 예시:

```text
enter_death_saves
immediate_death
become_disabled
become_unconscious_without_saves
custom_registered
```

NPC, 소환체, 구조물과 특수 몬스터가 서로 다른 정책을 사용할 수 있다.

정책은 ActorDefinition, 캠페인 설정, Feature 또는 DM Override에서 온다.

---

## 4. HP 변화와 VitalTransition

피해와 치유는 항상 `EffectRecipe`의 보류·확정 절차를 통과한다.

```text
PendingDamage 또는 PendingHealing
→ CommitGroup
→ HitPointState 변경 확정
→ HitPointsChanged
→ VitalTransitionEvaluation
```

```text
VitalTransitionEvaluation
├─ 이전 HP와 VitalState
├─ 현재 HP
├─ 적용된 피해·치유 문맥
├─ 최대 HP
├─ ActorDeathPolicy
├─ 활성 Capability와 RuleOverride
└─ 규칙 세트 스냅샷
```

결과:

```text
VitalTransitionResult
├─ nextVitalState
├─ createDeathSaveState?
├─ updateDeathSaveState?
├─ endDeathSaveState?
├─ createDeathRecord?
├─ conditionChanges[]
├─ effectEndRequests[]
├─ emittedEvents[]
└─ diagnostics[]
```

VitalTransition은 HP Commit 이후의 별도 결정적 단계지만 같은 상위 실행에 연결된다.

---

## 5. HP 0 도달

### 일반 흐름

```text
HP가 1 이상에서 0으로 감소
→ 즉사 후보 검사
→ ActorDeathPolicy 조회
→ 죽음 내성 대상이면 dying 진입
→ DeathSaveState 생성
→ 의식불명·행동 제한 Capability 활성화
```

의식불명은 UI 플래그가 아니라 `ConditionDefinition` 또는 생존 상태가 부여하는 Capability 묶음으로 처리한다.

### 즉사

```text
InstantDeathEvaluation
├─ damageApplicationId
├─ remainingDamageAfterZero?
├─ maximumHitPoints
├─ currentVitalState
├─ damageTags[]
├─ immunityOrOverrideCapabilities[]
└─ policy
```

정확한 임계치와 예외는 `InstantDeathPolicy`가 소유한다.

즉사 판정은 원래 굴림 전 피해가 아니라 면역·저항·감소를 모두 적용한 최종 피해 결과를 사용한다.

---

## 6. DeathSaveState

```text
DeathSaveState
├─ deathSaveStateId
├─ actorId
├─ lifecycleId
├─ successes
├─ failures
├─ state
├─ startedAtTurnId
├─ rollHistoryIds[]
├─ failureSourceRecords[]
├─ lastResolvedOccurrenceId?
└─ revision
```

`state`:

```text
active
stabilized
recovered
failed_dead
ended_by_override
```

### lifecycleId

다시 HP 0이 되어 죽어가는 상태가 시작되면 새 생명주기를 만든다.

이전 성공·실패 기록은 감사 로그로 남지만 새 죽음 내성에 합산하지 않는다.

---

## 7. 죽음 내성 Trigger

죽음 내성 굴림은 Actor별 프레임 루프가 아니다.

```text
VitalState: dying
→ TriggerCapability 등록
→ TurnStarted event
→ DeathSaveTimingPolicy 확인
→ DeathSave EffectRecipe 실행
```

```text
DeathSaveRecipe
├─ RollSavingThrow 또는 등록된 특수 Roll
├─ MapOutcome
├─ CreateDeathSaveProgressChange
└─ VitalTransitionEvaluation
```

죽음 내성은 일반 내성과 같은 RollRecord 시스템을 사용하지만, 능력치 내성인지 특수 무수정 굴림인지는 규칙 세트가 정의한다.

### 중복 방지

```text
turnOccurrenceId
+ deathSaveState.lifecycleId
→ deathSaveResolutionKey
```

동일 턴 사건 재전송으로 두 번 굴리지 않는다.

---

## 8. 특수 주사위 결과

죽음 내성의 자연 주사위 결과는 최종 total과 별도로 판정할 수 있다.

```text
DeathSaveOutcomePolicy
├─ successThreshold
├─ criticalFailureNaturalValues[]
├─ criticalSuccessNaturalValues[]
├─ criticalFailureDelta
├─ criticalSuccessEffectRecipeId?
├─ successLimit
└─ failureLimit
```

예시 의미:

```text
일반 성공
→ success +1

일반 실패
→ failure +1

특정 자연 주사위 실패
→ failure 여러 개

특정 자연 주사위 성공
→ HP 회복 또는 즉시 의식 회복
```

정확한 수치는 콘텐츠 코드가 아니라 `dnd5e-2024` 규칙 세트 데이터가 제공한다.

반응과 패시브가 죽음 내성 굴림을 수정할 수 있다면 기존 `TimingWindow`, `ContextModifierCapability`와 `RuleOverrideCapability`를 사용한다.

---

## 9. 성공·실패 누적과 상태 전이

```text
PendingDeathSaveProgressChange
├─ lifecycleId
├─ successDelta
├─ failureDelta
├─ sourceRollRecordId?
├─ sourceDamageApplicationId?
└─ commitKey
```

확정 후:

```text
성공 임계치 도달
→ stable_at_zero
→ DeathSaveState.state = stabilized

실패 임계치 도달
→ dead
→ DeathRecord 생성
```

성공과 실패를 각각 별도 ResourceDefinition으로 만들지 않는다. 두 값은 동일 생명주기의 결합 상태이기 때문이다.

---

## 10. HP 0에서 받는 피해

```text
Actor HP = 0
+ PendingDamage 확정
→ DamageApplied
→ ZeroHpDamagePolicy 평가
```

```text
ZeroHpDamagePolicy
├─ failureDeltaPolicy
├─ criticalHitAdjustment?
├─ instantDeathCheck
├─ stabilizationBreakPolicy
└─ damageApplicationGroupingPolicy
```

중요한 경계:

- 피해는 먼저 면역·저항·감소와 반응을 통과한다.
- 실제 최종 피해가 0이면 피해로 인한 죽음 내성 실패를 생성하지 않을 수 있다.
- 동시에 들어온 여러 피해 구성요소가 몇 개의 실패를 만드는지는 `damageApplicationId`와 규칙 세트 정책이 결정한다.
- 공격의 치명타 상태가 추가 실패에 영향을 주는 경우, 공격 결과를 구조화된 문맥으로 전달한다.
- 안정화된 대상이 피해를 받으면 새 `DeathSaveState.lifecycleId`로 dying에 다시 진입할 수 있다.

---

## 11. 치유와 의식 회복

```text
HP 0 대상에게 PendingHealing
→ 회복 금지·최대 HP·Modifier 평가
→ HP Commit
→ HP > 0
→ VitalTransition: conscious 후보
```

회복 성공 시:

```text
DeathSaveState 종료
stable 또는 dying 해제
HP 0 전용 Condition·Capability 제거
행동 가능 여부는 남은 다른 상태를 포함해 재계산
```

죽음 내성 성공·실패는 즉시 0으로 덮어쓰기보다 해당 생명주기를 종료 기록으로 남긴다.

---

## 12. 안정화

안정화는 HP 회복이 아니다.

```text
StabilizeEffect
├─ targetId
├─ sourceExecutionId
├─ stabilizationPolicyId
└─ optionalDurationOrRecoveryPolicy
```

확정:

```text
VitalState: stable_at_zero
DeathSaveState: stabilized
현재 HP: 0 유지
```

안정화 정책은 다음을 선택적으로 제공할 수 있다.

- 일정 게임 시간 후 HP 회복 시도
- 피해를 받으면 dying 복귀
- 특정 상태에서 안정화 불가
- 반복 안정화 검사

자동 회복은 `game_time_deadline` EffectInstance 또는 예약된 EffectRecipe로 처리한다.

---

## 13. 사망

```text
DeathRecord
├─ deathRecordId
├─ actorId
├─ deathSaveLifecycleId?
├─ causeExecutionId?
├─ causeDamageApplicationId?
├─ causeTags[]
├─ occurredAtGameTime
├─ bodyBinding?
├─ revivalPolicySnapshot
└─ revision
```

사망 트랜잭션:

```text
1. VitalState를 dead로 예약
2. 집중 종료
3. 생존 의존 EffectInstance 종료
4. Trigger와 ActionCapability 비활성화
5. DeathSaveState 종료
6. 토큰·시체 표현 갱신
7. 소유 아이템과 장면 상태 정책 적용
8. DeathRecord와 사후 RuleEvent 확정
```

캐릭터 데이터와 인벤토리를 삭제하지 않는다.

부활은 DeathRecord와 현재 Actor 상태를 검증하는 별도 EffectRecipe다.

---

## 14. RestDefinition

```text
RestDefinition
├─ restKind
├─ requiredDuration
├─ eligibilityPredicate
├─ allowedActivityPolicy
├─ interruptionPolicy
├─ completionPolicy
├─ recoveryProfileId
├─ repeatRestrictionPolicy?
└─ presentationProfileId
```

초기 종류:

```text
short_rest
long_rest
special_rest
custom_registered
```

짧은 휴식과 긴 휴식의 정확한 시간, 활동 허용량과 반복 제한은 규칙 세트가 소유한다.

---

## 15. RestSession

```text
RestSession
├─ restSessionId
├─ restDefinitionId
├─ initiatorActorId
├─ participantStates[]
├─ startedAtGameTime
├─ elapsedEligibleTime
├─ activityLedger[]
├─ interruptionRecords[]
├─ completionCandidateAt?
├─ state
└─ revision
```

### ParticipantRestState

```text
ParticipantRestState
├─ actorId
├─ joinedAtGameTime
├─ eligibilityState
├─ elapsedEligibleTime
├─ interruptionBudgetUsed
├─ completionState
├─ recoveryPlanId?
└─ revision
```

파티 전체가 쉬더라도 늦게 합류하거나 전투에 참여한 Actor는 별도 결과를 가질 수 있다.

---

## 16. 휴식 시간과 활동 기록

휴식은 캠페인 게임 시간축을 사용한다.

```text
GameTimeAdvanced
→ 활성 RestSession 조회
→ 허용 활동과 방해 기록 평가
→ 참가자별 eligible time 갱신
```

`ActivityLedgerEntry`:

```text
activityKind
startedAt
endedAt
eventReferences[]
classification
participantIds[]
```

활동 예시:

- 수면
- 식사
- 경계
- 대화
- 이동
- 주문 시전
- 전투
- 강행 활동

어떤 활동이 허용되는지 설명 텍스트를 파싱하지 않고 타입과 시간 예산으로 판정한다.

---

## 17. 휴식 방해

```text
RestInterruptionPolicy
├─ hardInterruptEventTypes[]
├─ activityBudgets[]
├─ resumePolicy
├─ elapsedRetentionPolicy
├─ participantScope
└─ failureConsequences[]
```

정책 예시:

```text
reset_all_progress
retain_partial_progress
pause_until_resumed
fail_only_affected_participants
convert_to_shorter_rest
```

전투 시작 사건은 휴식 UI를 닫는 것과 별개로 서버에서 RestSession을 갱신한다.

중단된 휴식은 자동 회복을 제공하지 않는다.

---

## 18. 휴식 완료 후보

필요 시간이 충족돼도 즉시 회복하지 않는다.

```text
required duration 충족
→ completion_pending
→ 참가자 상태·현재 사건 재검증
→ RecoveryPlan 생성
→ 필수 선택 완료
→ RecoveryCommitGroup
→ completed
```

이 구조는 휴식 완료 직전에 전투가 시작되거나 캐릭터 상태가 바뀌는 경쟁 조건을 막는다.

---

## 19. RecoveryPlan

```text
RecoveryPlan
├─ recoveryPlanId
├─ restSessionId
├─ actorId
├─ automaticEntries[]
├─ optionalChoices[]
├─ resourceEntries[]
├─ hitPointEntry?
├─ hitDiceEntries[]
├─ effectEndingEntries[]
├─ conditionChangeEntries[]
├─ exhaustionEntries[]
├─ selectionRecords[]
├─ validationSnapshot
├─ state
└─ revision
```

상태:

```text
building
awaiting_choices
ready_to_commit
committed
invalidated
cancelled
```

---

## 20. ResourceDefinition과 회복 정책

```text
ResourceDefinition
├─ resourceId
├─ ownerScope
├─ maximumExpression
├─ currentValueStorage
├─ spendingPolicy
├─ recoveryPolicies[]
├─ visibilityPolicy
└─ diagnosticsProfile
```

```text
ResourceRecoveryPolicy
├─ policyId
├─ triggerKind
├─ eligibilityPredicate?
├─ recoveryMode
├─ amountExpression?
├─ capPolicy
├─ choicePolicy?
├─ priority
└─ stackingPolicy
```

### 회복 대상 예시

- 주문 슬롯
- Feature 사용 횟수
- 종 특성 사용 횟수
- 클래스 자원
- Hit Dice
- 마법 아이템 충전
- 재사용 가능한 특수 행동

### 회복 방식

```text
restore_to_maximum
restore_fixed_amount
restore_formula_amount
restore_fraction_of_maximum
recover_spent_units
set_to_rolled_amount
increment_with_cap
custom_registered
```

---

## 21. 중앙 RecoveryEngine

Feature마다 `OnLongRest()` 함수를 만들지 않는다.

```text
RecoveryEngine
├─ RestDefinition 결과
├─ Actor ResourceDefinition 목록
├─ 활성 Capability
├─ EffectInstance 종료 조건
├─ 캠페인 규칙 설정
└─ DM Override
```

처리:

```text
1. 참가자와 휴식 종류 확정
2. 적격 ResourceRecoveryPolicy 수집
3. stacking·priority 해결
4. 자동 회복 항목 생성
5. 선택 회복 항목 생성
6. 효과 종료·상태 변화 후보 생성
7. 최종 자원 상한 재검증
8. RecoveryCommitGroup 확정
```

회복 정책의 출처와 계산 근거를 로그에 남긴다.

---

## 22. Hit Dice 사용

짧은 휴식 중 Hit Dice 사용은 선택형 반복 실행이다.

```text
OptionalRecoveryChoice: spend_hit_die
├─ available pools
├─ 선택할 die pool
├─ 최대 소비량
├─ per-unit healing recipe
├─ Constitution 또는 등록 수정치
└─ stop anytime
```

실행:

```text
사용 가능한 Hit Die 선택
→ 1개 예약
→ RollHealing
→ 회복 Modifier 적용
→ HP와 Hit Die 소비 Commit
→ 현재 HP와 남은 Hit Dice 표시
→ 추가 사용 또는 종료
```

각 Hit Die 사용은 사용자가 결과를 본 뒤 다음 사용을 결정할 수 있으므로 별도 하위 CommitGroup이다.

휴식 세션과 `recoveryChoiceId + ordinal`을 멱등 키로 사용한다.

---

## 23. Hit Dice 회복

Hit Dice 최대량과 휴식 시 회복량은 규칙 세트의 ResourceRecoveryPolicy다.

```text
HitDiePool
├─ dieSize
├─ classOrSourceBinding
├─ maximum
├─ current
└─ revision
```

다중 클래스처럼 주사위 크기가 여러 종류면 하나의 숫자로 합치지 않는다.

회복 시 어떤 풀에 몇 개를 돌려놓는지 선택이 필요한 경우 `OptionalRecoveryChoice`를 생성한다.

---

## 24. HP 회복과 최대 HP 변화

휴식 완료로 HP가 회복되는 경우에도 `PendingHealing` 또는 등록된 휴식 회복 효과를 사용한다.

```text
RecoveryPlan
→ PendingHealing
→ 회복 제한과 최대 HP 재검증
→ HP Commit
```

휴식 중 최대 HP가 변경되었다면 완료 시점의 권위 `maximumHitPoints`를 사용하되, 정책상 시작 스냅샷을 써야 하는 항목은 명시적으로 고정한다.

죽어가거나 사망한 Actor가 휴식에 참가해 자동으로 회복되는지 여부는 RestDefinition과 RevivalPolicy가 결정한다. 일반 휴식 완료가 부활을 암묵적으로 수행하지 않는다.

---

## 25. 주문 슬롯과 Feature 자원

```text
ResourceRecoveryPolicy: spell_slots.long_rest
→ 적격 슬롯 풀을 최대치까지 회복
```

```text
ResourceRecoveryPolicy: feature.short_rest
→ 특정 Feature pool 회복
```

동일한 자원을 여러 Feature가 공유하면 `resourceId` 하나를 공유한다. 각 Feature별 복제된 사용 횟수를 만들지 않는다.

부분 회복, 레벨별 선택 회복과 특수 클래스 회복은 선택형 RecoveryPlan으로 표현한다.

---

## 26. 아이템 충전과 시간 기반 회복

모든 아이템 충전이 휴식으로 회복되는 것은 아니다.

```text
triggerKind
├─ short_rest_completed
├─ long_rest_completed
├─ dawn_reached
├─ dusk_reached
├─ game_time_event
└─ explicit_recipe
```

아이템 인스턴스별 충전을 회복하며, 정의의 최대 충전과 현재 InstanceModifier를 재검증한다.

일출 회복은 RestSession이 아니라 캠페인 시간 사건에서 같은 RecoveryEngine을 호출한다.

---

## 27. 휴식으로 종료되는 효과

```text
EffectInstance EndCondition
├─ until_short_rest
└─ until_long_rest
```

해당 Actor의 RestCompleted가 확정된 뒤에만 종료 후보가 된다.

종료 순서:

```text
회복 전 종료
회복과 같은 그룹
회복 후 종료
```

중 어떤 순서를 사용할지 효과 정의의 `restResolutionPhase`가 명시한다.

예를 들어 최대 자원에 영향을 주는 효과가 휴식 종료와 동시에 사라진다면 계산 순서가 결과를 바꿀 수 있으므로 암묵적으로 처리하지 않는다.

---

## 28. 탈진과 기타 장기 상태

휴식이 탈진 단계나 장기 상태를 변경하는 경우 `ConditionChangeEntry` 또는 `DerivedStateChangeEntry`를 사용한다.

```text
RecoveryPlan
→ 탈진 감소 후보
→ 음식·물·환경·캠페인 조건 검증
→ 상태 변경 Commit
```

탈진을 일반 Resource로 취급할지 상태 단계로 취급할지는 규칙 세트 정의가 결정하지만, 휴식 회복 계획에는 타입 있는 항목으로 노출한다.

---

## 29. RecoveryCommitGroup

```text
RecoveryCommitGroup
├─ commitGroupId
├─ restSessionId
├─ actorId
├─ resourceChanges[]
├─ healingEffects[]
├─ conditionChanges[]
├─ effectEndRequests[]
├─ itemInstanceChanges[]
├─ expectedRevisions[]
├─ orderingPolicy
├─ failurePolicy
└─ state
```

기본 원칙:

- 자동 회복은 참가자별 원자적 확정
- 선택형 Hit Dice 사용은 각 사용마다 별도 확정 가능
- 다른 파티원의 회복 실패가 전체 파티 결과를 되돌리지 않음
- 동일 Actor의 상호 의존 회복은 하나의 그룹에서 처리
- 실패 시 적용되지 않은 항목만 재시도 가능

---

## 30. 재접속과 서버 복구

저장 대상:

- 활성 RestSession
- 참가자별 경과 시간과 방해 기록
- DeathSaveState와 lifecycleId
- RecoveryPlan과 완료된 선택
- Hit Dice 하위 Commit 기록
- 회복 예약과 expected revision
- DeathRecord

복구:

```text
서버 시작
→ 활성 세션 로드
→ 시간축과 현재 게임 시간 재검증
→ Trigger 재등록
→ 중복 Commit 키 복원
→ UI 상태 재동기화
```

실제 벽시계가 아닌 캠페인 게임 시간 정책을 따른다.

---

## 31. DM 명령

지원 명령 예시:

```text
DMSetVitalState
DMAdjustDeathSaveProgress
DMStabilizeActor
DMDeclareDeath
DMReviveActor
DMStartRest
DMCompleteRest
DMInterruptRest
DMAdjustResource
DMGrantRecovery
```

모든 명령은:

- 대상과 이전 revision
- 변경 이유
- 규칙 자동화 우회 여부
- 이전·이후 상태
- 실행한 DM

을 감사 로그에 남긴다.

DM 명령도 내부 상태 필드를 직접 임의 수정하지 않고 동일한 전이·커밋 서비스를 사용한다.

---

## 32. UI

### HP 0 UI

플레이어에게 허용된 정보:

- 현재 HP 0 상태
- 죽음 내성 성공·실패
- 다음 굴림 시점
- 적용 가능한 반응과 수정
- 안정화 여부

숨겨야 하는 NPC 정보는 `visibilityPolicy`를 따른다.

### 휴식 UI

```text
휴식 종류
필요 시간
현재 경과
방해 기록
참가자별 완료 가능 여부
자동 회복 미리보기
선택 가능한 Hit Dice·자원 회복
```

미리보기는 서버 계산 결과이며 클라이언트가 임의 회복량을 제출하지 않는다.

---

## 33. 대표 실행 사례

### 사례 A: 피해로 HP 0

```text
Damage Commit
→ HP 0
→ 즉사 아님
→ dying
→ DeathSaveState 생성
→ 의식불명 Capability 활성
```

### 사례 B: 죽음 내성 임계 성공

```text
TurnStarted
→ 죽음 내성 RollRecord
→ 성공 누적
→ 성공 임계치
→ stable_at_zero
```

### 사례 C: HP 0에서 공격 피해

```text
PendingDamage
→ 저항·감소·반응
→ 최종 피해 Commit
→ ZeroHpDamagePolicy
→ 실패 증가 또는 즉사
```

### 사례 D: 치유로 복귀

```text
PendingHealing
→ HP 7
→ DeathSaveState 종료
→ conscious
→ HP 0 전용 제한 제거
```

### 사례 E: 짧은 휴식 Hit Dice

```text
RestSession 완료 조건 충족
→ Hit Die 1개 선택
→ 회복 굴림과 소비 확정
→ 결과 확인
→ 추가 사용
→ 휴식 완료
```

### 사례 F: 긴 휴식 자동 회복

```text
Long Rest completion_pending
→ 주문 슬롯·Feature 자원·HP·Hit Dice 정책 수집
→ until_long_rest 효과 종료 순서 계산
→ RecoveryCommitGroup
→ RestCompleted
```

### 사례 G: 휴식 중 전투

```text
CombatStarted
→ RestInterruptionPolicy
→ 참가자 경과 시간 유지 또는 초기화
→ 완료되지 않은 자동 회복 없음
```

### 사례 H: 일출 아이템 충전

```text
DawnReached
→ 아이템 ResourceRecoveryPolicy 조회
→ 충전 굴림 또는 공식 계산
→ ItemInstance charge Commit
```

---

## 34. 검증 테스트

최소 테스트:

1. HP 1에서 피해를 받아 0이 되면 새 DeathSaveState가 생성된다.
2. 즉사 조건이면 죽음 내성 없이 dead로 전이된다.
3. 같은 TurnStarted 재전송으로 죽음 내성을 두 번 굴리지 않는다.
4. 일반 성공과 실패가 올바른 생명주기에 누적된다.
5. 특수 자연 주사위 결과가 정책대로 처리된다.
6. 성공 임계치에서 안정화되고 실패 임계치에서 사망한다.
7. HP 0 피해가 최종 피해 0이면 잘못된 실패를 만들지 않는다.
8. 안정화 대상이 피해를 받아 새 dying lifecycle에 진입한다.
9. 치유로 HP가 양수가 되면 죽음 내성이 종료된다.
10. 사망 시 집중과 생존 의존 효과가 정리된다.
11. 휴식 필요 시간 전에는 자동 회복이 적용되지 않는다.
12. 방해 사건이 정책에 따라 참가자별 휴식을 중단한다.
13. Hit Dice 한 개 사용 후 결과를 보고 추가 사용을 선택할 수 있다.
14. 동일 Hit Dice 선택 재전송이 중복 소비되지 않는다.
15. 다중 클래스 Hit Dice 풀이 별도로 유지된다.
16. 긴 휴식에서 여러 ResourceRecoveryPolicy가 중첩 규칙대로 적용된다.
17. 공유 자원이 Feature별로 중복 회복되지 않는다.
18. until_long_rest 효과가 지정된 해결 단계에서 종료된다.
19. 사망 Actor가 일반 휴식만으로 부활하지 않는다.
20. 아이템 충전의 dawn 회복이 휴식과 독립적으로 작동한다.
21. 재접속 후 DeathSaveState와 RestSession이 복원된다.
22. RecoveryCommitGroup revision 충돌이 부분 중복 회복을 막는다.
23. DM 강제 변경이 같은 전이 서비스와 감사 로그를 사용한다.
24. NPC 즉사 정책과 PC 죽음 내성 정책이 독립적으로 작동한다.

---

## 35. 비목표

이 문서는 다음을 완전히 정의하지 않는다.

- 부활 주문별 세부 제한과 재료
- 시체 부패와 장기 시간 경과
- 음식·물·수면 부족의 전체 탐험 규칙
- 탈진 단계의 구체 효과
- 캠페인 달력과 일출 계산 구현
- 몬스터별 사망 연출

이들은 본 문서의 DeathRecord, RecoveryEngine, EffectInstance와 캠페인 시간축을 사용해 후속 문서에서 정의한다.

---

## 36. 구현 순서

1. `VitalState`, `ActorDeathPolicy`, `DeathSaveState` 타입
2. HP Commit 후 `VitalTransitionService`
3. 죽음 내성 Trigger와 EffectRecipe
4. HP 0 피해·치유·안정화 전이
5. DeathRecord와 사망 정리
6. `RestDefinition`, `RestSession`, 활동·방해 추적
7. `ResourceRecoveryPolicy`와 `RecoveryEngine`
8. Hit Dice 선택 회복
9. `RecoveryCommitGroup`
10. 휴식 UI, 재접속과 DM 명령

다음 설계 단계에서는 몬스터와 NPC가 사용하는 스탯블록·행동 패키지 또는 부활·탈진·탐험 시간 규칙을 선택할 수 있다.