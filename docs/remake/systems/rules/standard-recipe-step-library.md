# 표준 Recipe Step Library

- 상태: 확정
- 문서 종류: System
- 즉시 구현 명세 가능성: READY
- 작성일: 2026-08-03
- 관련 ADR:
  - [`ADR-0053`](../../decisions/ADR-0053-step-level-automation-and-standard-recipe-step-library.md)
- 상위 문서:
  - [`EffectRecipe와 효과 해결·확정 모델`](../../architecture/effect-recipe-resolution-and-commit-model.md)
  - [`규칙 콘텐츠 공통 실행 계약`](../../architecture/rules-content-execution-and-spell-contract.md)

## 1. 목적

이 문서는 주문, Feature, Feat, 아이템 행동, 몬스터 능력, 환경 효과와 DM용 규칙 행동을 구성하는 표준 Recipe Step을 정의한다.

Step Library의 목적은 모든 규칙을 설정 데이터만으로 표현하는 것이 아니다. 반복되는 규칙 동작을 공통 언어로 만들고, 정말 특수한 규칙만 제한된 AdvancedOperation으로 확장하는 것이다.

```text
ContentDefinition
→ RecipeDefinition
→ StepDefinition[]
→ StepExecutor
→ PendingEffect / Command
→ CommitGroup
```

## 2. Step과 Recipe의 경계

### Step

한 가지 명확한 작업을 수행하는 최소 실행 단위다.

예:

```text
SelectTargets
ValidateRange
RollSavingThrow
CreateDamageEffect
ApplyCondition
WaitForDMDecision
RequestPresentation
```

### Recipe

Step과 제어 흐름을 조합한 하나의 규칙 실행 절차다.

예:

```text
Fireball
├─ ReserveSpellSlot
├─ SelectPoint
├─ QueryAreaTargets
├─ ForEach target
│  ├─ RollSavingThrow
│  └─ Branch
│     ├─ success → CreateHalfDamageEffect
│     └─ failure → CreateDamageEffect
├─ CommitEffects
└─ RequestPresentation
```

### SubRecipe

여러 콘텐츠가 공유하는 검증된 Step 묶음이다.

예:

```text
StandardAttackRoll
StandardSavingThrowDamage
ConcentrationStart
ConcentrationCheckAfterDamage
StandardMeleeHitPresentation
```

## 3. 자동화 수준

자동화 수준은 Step마다 하나를 가진다.

### Executable

서버가 준비된 입력을 사용해 자동 실행한다.

예:

```text
ValidateRange
RollDamage
CreateDamageEffect
CommitEffects
```

### Guided

사용자가 구조화된 입력을 선택해야 한다.

예:

```text
SelectTargets
SelectPoint
ChooseDamageType
ChooseSpellSlotLevel
```

Guided는 자유 텍스트 판정이 아니다. 허용된 대상, 위치, 옵션과 수량을 UI에서 선택한다.

### Assisted

DM 또는 지정된 판정자가 의미를 해석하고 결과를 입력해야 한다.

예:

```text
RequestDMJudgement
ChooseNarrativeOutcome
ConfirmImprovisedEffect
```

Assisted Step도 다음을 시스템이 관리한다.

- 요청 대상
- 관련 규칙과 문맥
- 선택 가능한 구조화 결과
- 자유 메모
- 취소·시간 초과·재접속
- 결과 로그
- 이후 Recipe 재개

## 4. 공통 StepDefinition 계약

```text
StepDefinition
├─ stepTypeId
├─ version
├─ category
├─ automationMode
├─ executionAuthority
├─ inputSchema
├─ outputSchema
├─ preconditions[]
├─ sideEffectClass
├─ rollbackPolicy
├─ failurePolicy
├─ determinismClass
├─ allowedContexts[]
├─ diagnosticsProfile
└─ presentationMetadata?
```

### executionAuthority

```text
Server
→ 규칙 상태와 권위 결과를 생성한다.

ClientPresentation
→ 권위 결과를 시각적으로 표현한다.

ClientInputThenServer
→ 클라이언트가 선택을 수집하고 서버가 재검증한다.

DMInputThenServer
→ DM 판단을 수집하고 서버가 허용된 결과로 변환한다.
```

### sideEffectClass

```text
Pure
→ 입력으로 출력만 계산하며 상태를 바꾸지 않는다.

Reservation
→ 자원이나 행동 비용을 임시 예약한다.

PendingEffect
→ 확정 전 효과를 생성한다.

AuthoritativeCommand
→ 별도 권위 명령을 생성한다.

PresentationOnly
→ 규칙 상태를 바꾸지 않는다.

AuditOnly
→ 로그와 진단만 기록한다.
```

### rollbackPolicy

```text
Recompute
→ 저장하지 않고 이전 입력으로 다시 계산한다.

RestoreSnapshot
→ 스냅샷의 이전 상태로 복원한다.

CompensatingCommand
→ 역명령으로 되돌린다.

DiscardUncommitted
→ 확정되지 않은 출력만 버린다.

NotApplicable
→ 상태 변경이 없다.
```

### failurePolicy

```text
AbortRecipe
SkipStep
UseFallback
RequestNewInput
RouteToFailureBranch
EscalateToDM
PresentationOnlyContinue
```

## 5. 실행 상태

각 StepInstance는 다음 상태 중 하나를 가진다.

```text
Pending
Ready
AwaitingInput
Running
ProducedOutput
AwaitingCommit
Committed
Skipped
Cancelled
Failed
RolledBack
```

허용되는 기본 전이:

```text
Pending → Ready
Ready → AwaitingInput | Running | Skipped
AwaitingInput → Ready | Cancelled | Failed
Running → ProducedOutput | AwaitingCommit | Failed
ProducedOutput → Committed | Ready
AwaitingCommit → Committed | Cancelled | Failed
Committed → RolledBack
```

프레젠테이션 Step은 규칙 Step의 Commit을 막지 않는다. 단, 주사위 결과 공개처럼 이미 별도 정책으로 결과 확정을 지연하는 Presentation Gate는 명시적인 `WaitForPresentationGate` Step으로만 사용한다.

## 6. 바인딩과 데이터 흐름

Step은 다른 Step의 내부 상태를 직접 읽지 않는다. RecipeExecutionContext의 타입 있는 바인딩을 통해서만 값을 주고받는다.

```text
bindings.caster
bindings.selectedTargets
bindings.castLevel
bindings.attackRoll
bindings.saveResults
bindings.pendingDamageEffects
bindings.commitResult
```

바인딩은 다음 범위를 가진다.

```text
RecipeInput
StepLocal
LoopItem
SimultaneousGroup
RecipeOutput
```

같은 이름의 암묵적 덮어쓰기를 금지한다. 새 출력은 고유한 binding key를 사용하거나 명시적 `SetBinding` Step을 거친다.

## 7. 제어 흐름 Step

### Sequence

등록된 자식 Step을 순서대로 실행한다.

### Branch

타입 있는 조건 결과에 따라 하나의 경로를 선택한다.

### ForEach

검증된 유한 집합을 순회한다.

필수 입력:

```text
collection
itemBinding
maxItems
body
```

### BoundedRepeat

명시된 최대 횟수까지만 반복한다.

### SelectFirstValid

후보를 순서대로 검사해 첫 유효 후보를 선택한다.

### SimultaneousGroup

여러 굴림과 효과를 같은 동시 해결 경계로 묶는다.

### ReferenceSubRecipe

등록된 SubRecipe를 타입 있는 입력·출력 매핑으로 호출한다.

### WaitForDecision

Guided 또는 Assisted 입력을 기다린다. 대기 상태는 저장·재접속 가능해야 한다.

## 8. 입력·선택 Step

### SelectActorTargets

- 자동화: Guided
- 역할: 허용된 Actor 중 하나 이상 선택
- 주요 입력: selector, minimum, maximum, filters, rangePolicy, visibilityPolicy
- 출력: selectedActorIds
- 실패: 유효 후보 없음, 선택 수 불일치, revision 변경

### SelectPoint

- 자동화: Guided
- 역할: 월드 지점 선택
- 입력: origin, range, surfacePolicy, lineOfEffectPolicy
- 출력: selectedPoint

### SelectDirection

- 자동화: Guided
- 역할: 방향 또는 각도 선택
- 출력: selectedDirection

### SelectAreaPlacement

- 자동화: Guided
- 역할: 원뿔, 선, 구체, 원통 등 Template 배치
- 출력: areaDescriptor

### SelectOption

- 자동화: Guided
- 역할: 정의된 선택지 중 하나 또는 여러 개 선택
- 출력: selectedOptionIds

### SelectQuantity

- 자동화: Guided
- 역할: 허용 범위의 정수 수량 선택
- 출력: selectedQuantity

### AllocateUnits

- 자동화: Guided
- 역할: Magic Missile 투사체처럼 제한된 단위를 대상별로 배분
- 출력: allocationMap

### ConfirmAction

- 자동화: Guided
- 역할: 비용과 예상 결과를 확인한 뒤 E로 승인
- 출력: confirmed

### RequestDMJudgement

- 자동화: Assisted
- 역할: DM에게 의미 판단 요청
- 입력: promptKey, rulesContext, suggestedOutcomes, allowCustomOutcome
- 출력: judgementResult

### RequestPlayerDecision

- 자동화: Guided 또는 Assisted
- 역할: 반응 사용, 선택적 효과 수락 등 플레이어 결정 요청
- 출력: decisionResult

## 9. 검증 Step

### ValidateActorState

무의식, 행동 불가, 사망, 상태 제한 등을 검사한다.

### ValidateActionEconomy

행동, 보너스 행동, 반응과 이동 자원의 사용 가능 여부를 검사한다.

### ValidateResourceAvailability

주문 슬롯, 사용 횟수, 충전, 아이템 수량 등을 검사한다.

### ValidateTargetType

생물, 오브젝트, 시체, 아군, 적군 등 대상 유형을 검사한다.

### ValidateRange

연속 좌표와 `5 ft = 4 studs` 비율로 거리를 검사한다.

### ValidateVisibility

시야, 감각, 은신과 공개 상태를 검사한다.

### ValidateLineOfEffect

효과 경로와 차폐를 검사한다.

### ValidateEquipmentState

장착, 손 점유, 탄약, 무기 속성 등을 검사한다.

### ValidateConcentrationAvailability

새 집중 시작 가능 여부와 기존 집중 종료 요구를 검사한다.

### ValidateTimingWindow

현재 RuleEvent와 TimingWindow에서 사용 가능한지 검사한다.

### ValidatePermission

Owner, Controller, DM, Observer 권한을 검사한다.

### ValidateRevision

선택 이후 대상과 자원 상태가 변경되지 않았는지 검사한다.

## 10. 질의·계산 Step

### QueryAreaTargets

AreaDescriptor와 공간 질의를 사용해 후보 대상을 반환한다.

### QueryNearbyObjects

주변 SceneObject를 필터링한다.

### EvaluatePredicate

등록된 타입 있는 조건을 평가한다.

### CalculateExpression

허용된 수식 AST로 값을 계산한다. 임의 코드 실행은 금지한다.

### CalculateDistance

연속 월드 좌표의 거리와 규칙 거리 단위를 계산한다.

### CalculateDC

능력치, 숙련도, 고정값과 Override를 반영해 DC를 계산한다.

### CalculateAttackModifier

능력치, 숙련, 장비, 상태와 Override를 반영한다.

### CalculateEffectMagnitude

피해, 회복, 임시 HP, 이동 거리와 반복 횟수를 계산한다.

### ResolveDamageModifiers

저항, 면역, 취약, 피해 감소와 Override를 계산한다.

### MapOutcome

굴림 결과를 success, failure, criticalSuccess 등 표준 Outcome으로 변환한다.

### SelectValue

조건에 따라 여러 값 중 하나를 선택한다.

## 11. 굴림 Step

모든 굴림은 서버에서 결과를 생성하고 RollRecord를 남긴다.

### RollAttack

출력:

```text
rollId
total
naturalRoll
outcome
criticalState
```

### RollSavingThrow

대상별 SaveResult를 생성한다.

### RollAbilityCheck

능력 판정과 기술 판정을 처리한다.

### RollDamage

피해식을 굴려 DamagePacket을 생성한다. 아직 HP를 변경하지 않는다.

### RollHealing

회복량을 생성한다.

### RollTable

등록된 유한 테이블을 굴린다.

### RollInitiative

인카운터 참가자의 우선권 결과를 생성한다.

### RollDeathSave

죽음 내성 결과를 생성한다.

### RollConcentrationCheck

피해 이후 집중 유지 판정을 생성한다.

## 12. 비용·자원 Step

### ReserveActionCost

행동 비용을 확정 전 예약한다.

### ReserveResource

주문 슬롯, Feature 사용 횟수와 아이템 수량을 예약한다.

### ConsumeReservedCost

Commit 시 예약된 비용을 실제 차감한다.

### ReleaseReservedCost

Recipe 취소나 실패 시 예약을 해제한다.

### RestoreResource

휴식, 특성 또는 DM Override로 자원을 회복한다.

### ConvertResource

소서리 포인트와 주문 슬롯처럼 명시된 변환 규칙을 실행한다.

### SpendMovement

전투 클릭 경로 이동의 확정된 거리만 이동 자원에서 차감한다.

## 13. PendingEffect 생성 Step

이 Step들은 영구 상태를 직접 바꾸지 않고 PendingEffect를 만든다.

### CreateDamageEffect

DamagePacket과 대상을 연결한다.

### CreateHealingEffect

회복 PendingEffect를 만든다.

### CreateTemporaryHitPointsEffect

임시 HP 적용 후보를 만든다.

### CreateConditionEffect

상태, 지속시간, 출처와 중첩 정책을 포함한다.

### CreateRemoveConditionEffect

특정 상태 또는 태그 기반 상태 제거를 요청한다.

### CreateForcedMovementEffect

밀기, 끌기와 위치 교환을 생성한다.

### CreateTeleportEffect

목적지 유효성 검증이 포함된 순간이동 후보를 만든다.

### CreateResourceChangeEffect

다른 Actor의 자원 변경처럼 일반 비용 예약이 아닌 효과를 만든다.

### CreateInventoryTransferEffect

아이템, 화폐와 전리품 이전 후보를 만든다.

### CreateOwnershipChangeEffect

DM 권한이 필요한 영구 Owner 변경 후보를 만든다.

### CreateControlAssignmentEffect

현재 Controller 또는 임시 제어권 변경 후보를 만든다.

### CreateSceneObjectStateEffect

문, 레버, 상자, 함정과 조명의 상태 변경 후보를 만든다.

### CreateFogMaskEffect

DM이 승인한 Fog 공개·가림 변경을 만든다.

### CreateSpawnActorEffect

소환체와 Actor 생성 후보를 만든다.

### CreateDespawnActorEffect

소환 종료와 제거 후보를 만든다.

### CreateSceneObjectEffect

장벽, 구름, 환영과 지속 영역 오브젝트 생성 후보를 만든다.

### CreateDestroySceneObjectEffect

SceneObject 제거 후보를 만든다.

## 14. 지속 효과·집중 Step

### StartEffectInstance

지속 효과의 출처, 대상, 지속시간과 트리거를 등록한다.

### RefreshEffectDuration

허용된 중첩 정책에 따라 지속시간을 갱신한다.

### AddEffectStack

명시된 최대치 안에서 Stack을 추가한다.

### SuppressEffectInstance

효과를 삭제하지 않고 일시 비활성화한다.

### EndEffectInstance

해제, 만료, 집중 종료와 출처 소멸로 효과를 끝낸다.

### StartConcentration

기존 집중 처리 후 새 집중 연결을 만든다.

### EndConcentration

집중과 연결된 EffectInstance를 종료한다.

### ScheduleRuleEvent

턴 시작, 턴 종료, 라운드 종료와 시간 경과 이벤트를 예약한다.

### RequestRepeatSave

지정 TimingWindow에서 반복 내성을 요청한다.

## 15. 이동·공간 Step

### BuildMovementPath

클릭한 목적지까지 서버 검증용 경로를 만든다.

### ValidateMovementPath

충돌, 통과 가능성, 위험 지형과 이동 한도를 검사한다.

### CreateMoveEffect

검증된 경로 이동을 PendingEffect로 만든다.

### InterruptMovement

기회 공격, 함정과 강제 정지 지점에서 이동을 분할한다.

### PlaceAreaInstance

지속 범위와 공간 질의용 AreaInstance를 배치한다.

### RemoveAreaInstance

영역 효과를 제거한다.

### QueryEnteredExitedTargets

영역 진입·퇴장 Actor를 계산한다.

## 16. 반응·타이밍 Step

### OpenTimingWindow

규칙 이벤트에 대한 반응 후보를 수집한다.

### CollectReactionOffers

사용 가능한 반응과 패시브 개입을 정렬한다.

### WaitForReactionDecision

제한 시간과 기본 동작을 가진 반응 입력을 기다린다.

### ResolveReaction

선택된 반응 Recipe를 실행한다.

### ApplyRuleOverride

등록된 Override를 우선순위와 충돌 규칙에 따라 적용한다.

### CloseTimingWindow

더 이상 반응이 없을 때 창을 닫는다.

## 17. Commit Step

### BuildCommitGroup

관련 PendingEffect와 예약 비용을 원자적 그룹으로 묶는다.

### ValidateCommitGroup

대상 revision, 비용, 상태와 참조 무결성을 최종 검사한다.

### CommitEffects

권위 상태를 원자적으로 변경한다.

### CommitSimultaneousGroups

동시 해결 그룹의 공개·적용 순서를 보장한다.

### CancelPendingEffects

취소된 분기의 미확정 효과를 폐기한다.

### EmitPostCommitEvents

피해 적용 후 집중 판정, HP 0, 사망과 상태 트리거를 발행한다.

## 18. 프레젠테이션 Step

Presentation Step은 `PresentationRecipe`를 요청할 뿐 규칙을 확정하지 않는다.

### RequestSourcePresentation

시전자 중심 VFX와 모션을 요청한다.

### RequestTravelPresentation

투사체, 빔과 이동 궤적을 요청한다.

### RequestImpactPresentation

피격자 중심 VFX와 피격 반응을 요청한다.

### RequestCameraPresentation

화면 흔들림, 충격, 순간 확대와 카메라 이동을 요청한다.

### RequestScreenPresentation

비네트, 플래시와 오버레이를 요청한다.

### RequestWorldPresentation

지면 흔들림, 광원 펄스와 환경 연출을 요청한다.

### WaitForPresentationGate

주사위 결과 공개처럼 규칙 문서에서 허용한 경우에만 다음 공개 단계를 잠시 기다린다.

VFX 모듈 실패 시 기본 정책은 `PresentationOnlyContinue`다.

## 19. 로그·저장·정리 Step

### WriteRuleLog

현재 활성 분기의 규칙 로그를 기록한다.

### WriteAuditRecord

DM Override, Assisted 판단과 권한 변경의 감사 기록을 남긴다.

### CreateCheckpointMarker

명시적인 안전 경계에서 체크포인트 생성을 요청한다.

### PersistPendingDecision

재접속 가능한 Guided·Assisted 대기 상태를 저장한다.

### ClearTemporaryBindings

Recipe 전용 임시 값을 정리한다.

### ReleaseLocks

대상, 아이템과 자원에 잡힌 임시 잠금을 해제한다.

### FinalizeRecipe

최종 결과와 출력 바인딩을 확정한다.

## 20. 표준 SubRecipe

초기 공통 SubRecipe는 다음을 제공한다.

```text
StandardWeaponAttack
StandardSpellAttack
StandardSavingThrow
SavingThrowForHalfDamage
AttackRollAndDamage
ApplyDamageAndPostEvents
ApplyHealing
ApplyConditionWithDuration
StartConcentrationEffect
ConcentrationCheckAfterDamage
ForcedMovementWithInterrupts
TeleportToSelectedPoint
AreaSaveDamage
MultiProjectileGuaranteedHit
ReactionOfferAndResolution
StandardShortRestRecovery
StandardLongRestRecovery
StandardDeathSaveTurn
StandardLootTransfer
```

SubRecipe는 단순 복사 템플릿이 아니라 Registry에서 버전 관리되는 참조 단위다.

## 21. AdvancedOperation

표준 Step으로 자연스럽게 표현되지 않는 규칙만 사용한다.

예:

```text
ResolveWishOutcome
CreateSimulacrumSnapshot
BindCloneReturnState
ResolveDivineInterventionRequest
```

단, 위 이름이 곧 자동 지원을 의미하지 않는다. 실제 Operation은 콘텐츠 기획과 테스트가 완료된 뒤 등록한다.

AdvancedOperationDefinition:

```text
operationId
version
inputSchema
outputSchema
maxExecutionTime
maxGeneratedEffects
rollbackPolicy
persistencePolicy
requiredPermissions
handlerModuleId
rationale
```

다음은 금지한다.

- 콘텐츠 JSON 안의 임의 코드
- CommitGroup 우회
- 클라이언트 전용 규칙 결과
- 제한 없는 대상·오브젝트 생성
- 저장 불가능한 장기 대기
- 실패 시 부분 적용을 남기는 처리

## 22. Recipe 예시

### Magic Missile

```text
ValidateActorState                 Executable
ValidateResourceAvailability      Executable
ChooseSpellSlotLevel              Guided
ReserveResource                   Executable
SelectActorTargets                Guided
AllocateUnits                     Guided
ForEach allocated unit
├─ RollDamage                     Executable
└─ CreateDamageEffect             Executable
BuildCommitGroup                  Executable
CommitEffects                     Executable
RequestSourcePresentation         Executable
RequestTravelPresentation         Executable
RequestImpactPresentation         Executable
WriteRuleLog                      Executable
FinalizeRecipe                    Executable
```

### Witch Bolt 최초 시전

```text
ValidateTimingWindow              Executable
ChooseSpellSlotLevel              Guided
ReserveResource                   Executable
SelectActorTargets                Guided
ValidateRange                     Executable
RollAttack                        Executable
Branch hit
├─ RollDamage                     Executable
├─ CreateDamageEffect             Executable
├─ StartEffectInstance            Executable
└─ StartConcentration             Executable
BuildCommitGroup                  Executable
CommitEffects                     Executable
RequestTravelPresentation         Executable
FinalizeRecipe                    Executable
```

### Minor Illusion

```text
SelectPoint                       Guided
SelectOption                      Guided
CreateSceneObjectEffect           Executable
BuildCommitGroup                  Executable
CommitEffects                     Executable
RequestWorldPresentation          Executable
RequestDMJudgement                Assisted
Branch judgementResult
├─ apply structured outcome       Executable
└─ no mechanical change           Executable
WriteAuditRecord                  Executable
FinalizeRecipe                    Executable
```

### 바바리안 광분 상태의 무기 공격

공격 Recipe 자체를 복제하지 않는다.

```text
PresentationAugment from Rage
→ pre_action: 함성·오라

StandardWeaponAttack
→ 명중·피해 규칙

PresentationRecipe
→ 무기 모션·피격·카메라 충격
```

## 23. Step 등록 기준

새 Step을 표준 Library에 추가하려면 다음을 만족해야 한다.

- 최소 두 종류 이상의 콘텐츠에서 재사용될 가능성이 높다.
- 책임이 하나로 설명된다.
- 입력·출력 타입이 안정적이다.
- 실패와 롤백 정책이 명확하다.
- 서버 권위 경계를 지킨다.
- 기존 Step 조합보다 의미와 테스트가 더 명확하다.

한 콘텐츠에서만 쓰이는 매우 특수한 동작은 우선 AdvancedOperation으로 둔다. 이후 반복 사용이 확인되면 표준 Step으로 승격한다.

## 24. 콘텐츠 검증 규칙

Recipe 로딩 시 다음을 검사한다.

```text
모든 stepTypeId가 Registry에 존재
Step 버전 호환
입력·출력 binding 타입 일치
Guided Step의 UI 입력 계약 존재
Assisted Step의 판정자와 시간 초과 정책 존재
모든 반복 상한 존재
모든 Branch의 기본 경로 존재
Commit 전 상태 변경 금지
PresentationOnly Step의 규칙 출력 금지
AdvancedOperation의 권한과 상한 존재
도달 불가능 Step과 무한 순환 없음
최대 생성 효과 수 예산 준수
```

## 25. 오류 코드 범주

```text
STEP_TYPE_NOT_FOUND
STEP_VERSION_UNSUPPORTED
STEP_INPUT_BINDING_MISSING
STEP_INPUT_TYPE_MISMATCH
STEP_OUTPUT_TYPE_MISMATCH
STEP_PRECONDITION_FAILED
STEP_PERMISSION_DENIED
STEP_REVISION_MISMATCH
STEP_INPUT_CANCELLED
STEP_INPUT_TIMEOUT
STEP_EXECUTION_FAILED
STEP_EFFECT_LIMIT_EXCEEDED
STEP_LOOP_LIMIT_EXCEEDED
STEP_ADVANCED_OPERATION_REJECTED
STEP_COMMIT_VALIDATION_FAILED
STEP_PRESENTATION_FAILED
```

사용자에게는 기술 ID를 그대로 표시하지 않고 행동 가능한 메시지로 변환한다.

## 26. 성능과 안전 원칙

- Registry 조회는 전체 선형 순회를 요구하지 않는다.
- Recipe는 로드 시 사전 검증·컴파일된 실행 계획을 만든다.
- 매 프레임 Step 그래프를 재평가하지 않는다.
- 대규모 대상 처리는 제한된 배치로 수행한다.
- Step과 Recipe마다 최대 대상 수, 반복 수와 생성 효과 수를 가진다.
- Guided 입력 중 클라이언트 미리보기는 권위 결과가 아니다.
- 서버는 모든 선택과 revision을 재검증한다.
- 프레젠테이션 지연이 규칙 서버를 장시간 점유하지 않는다.

구체적인 수치 예산은 공통 구현 명세와 프로파일링 단계에서 확정한다.

## 27. 테스트 기준

### Step 단위

- 정상 입력과 출력
- 경계값
- 타입 오류
- 권한 오류
- revision 변경
- 취소와 시간 초과
- 롤백

### Recipe 통합

- 성공·실패·치명타 분기
- 다중 대상과 동시 해결
- 반응으로 결과 변경
- 자원 예약 후 취소
- 연결 종료와 재접속
- Commit 직전 대상 삭제
- Presentation 실패 후 규칙 정상 확정

### 콘텐츠 적합성

2024 기본 규칙 콘텐츠를 분류하면서 표준 Step만으로 표현 가능한지 기록한다. 표현 불가능한 규칙은 즉시 임의 코드를 넣지 않고 AdvancedOperation 후보로 등록한다.

## 28. 구현 명세로 넘길 항목

이 문서로 제품 구조는 확정되었다. 구현 명세에서는 다음을 정확히 정의한다.

```text
StepDefinition Luau type
StepRegistry API
RecipeCompiler
RecipeExecutionContext
BindingStore
StepExecutor 인터페이스
GuidedInputRequest Remote 계약
AssistedDecisionRequest Remote 계약
Pending Step 저장 형식
오류 Result 타입
테스트 폴더와 Fixture
성능 예산
```
