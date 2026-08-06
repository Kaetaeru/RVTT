# Character Runtime과 Compiled Character Build 계약

- 상태: 확정
- 문서 종류: Architecture
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 남은 기본값:
  - Character Build Cache 보존 수와 메모리 상한
  - Projection 갱신 Debounce와 Derived View Cache 기간
  - Resource 표시 정렬 기본값
  - Character Migration 자동 승인 범위
  - 대규모 Grant Graph의 Compile Budget
- 작성일: 2026-08-04
- 관련 ADR:
  - [`ADR-0011`](../decisions/ADR-0011-persistent-character-current-state.md)
  - [`ADR-0012`](../decisions/ADR-0012-campaign-scoped-character-ownership.md)
  - [`ADR-0014`](../decisions/ADR-0014-character-data-and-scene-actor-separation.md)
  - [`ADR-0017`](../decisions/ADR-0017-derived-fixed-grants-and-stored-selections.md)
  - [`ADR-0027`](../decisions/ADR-0027-passive-modifiers-rule-overrides-and-conditional-activation.md)
  - [`ADR-0031`](../decisions/ADR-0031-zero-hit-points-death-saves-rests-and-resource-recovery.md)
  - [`ADR-0040`](../decisions/ADR-0040-official-2024-character-sheet-and-live-player-view.md)
  - [`ADR-0049`](../decisions/ADR-0049-campaign-character-ownership-hot-join-and-control-assignment.md)
  - [`ADR-0064`](../decisions/ADR-0064-immutable-compiled-builds-and-versioned-authoritative-state.md)
- 상위 문서:
  - [`Compiled Build와 Authoritative State 분리 패턴`](compiled-build-and-authoritative-state-pattern.md)
  - [`Runtime Architecture Principles`](runtime-architecture-principles.md)
- 관련 문서:
  - [`Rules Content Grant와 Capability 모델`](rules-content-grant-capability-model.md)
  - [`Passive Modifier와 Rule Override 모델`](passive-modifier-and-rule-override-model.md)
  - [`Rule Runtime Orchestrator`](rule-runtime-orchestrator-and-pending-execution-contract.md)
  - [`Runtime Object System`](runtime-object-system-and-entity-lifecycle-contract.md)
  - [`Persistence, Snapshot, Journal과 Recovery`](persistence-and-session-recovery-model.md)
  - [`공식 2024 Character Sheet`](../ui/character-sheet/official-2024-character-sheet-and-live-player-ui.md)

## 1. 목적

이 문서는 D&D 2024 플레이어 캐릭터의 성장 원본, 파생 규칙 Build, 캠페인에 유지되는 현재 상태, Scene Actor Presence, Encounter 전용 상태와 Client Character View의 권위 경계를 정의한다.

Character Runtime은 행동이나 주문을 직접 실행하지 않는다. 캐릭터가 가진 Capability, Modifier, Resource Definition과 규칙 입력을 제공하며 실제 실행은 Rule Runtime과 Authority Transaction이 담당한다.

## 2. 전체 구조

```text
Character Progression Source
+ Ruleset·Source Pack Version
+ Item·Effect Activation Sources
→ Character Compiler
→ Compiled Character Build

Compiled Character Build
+ Persistent Character State
+ Scene Actor Binding·State
+ Encounter State
→ Character Runtime Snapshot
→ Rule Runtime·Projection Builder
```

각 계층은 별도 Identity와 Revision을 가진다.

## 3. Character Progression Source

다시 계산할 수 없는 성장 원본과 선택 기록이다.

```text
CharacterProgressionSource
├─ characterId
├─ campaignId
├─ identityProfile
├─ speciesSelection
├─ backgroundSelection
├─ classLevelSequence[]
├─ subclassSelections[]
├─ abilityScoreGenerationRecord
├─ featSelections[]
├─ proficiencySelections[]
├─ spellAcquisitionSelections[]
├─ weaponMasterySelections[]
├─ sourceOccurrenceChoices[]
├─ exceptionalGrants[]
├─ rulesetRef
├─ sourcePackVersionSet
└─ sourceRevision
```

고정 Feature, 최종 Capability, AC, 주문 DC와 최대 Resource를 Source에 중복 저장하지 않는다.

## 4. Compiled Character Build

Character Compiler가 Source와 고정된 콘텐츠 버전에서 만든 불변 파생 Build다.

```text
CompiledCharacterBuild
├─ characterBuildId
├─ characterId
├─ sourceRevision
├─ sourceContentHash
├─ rulesetVersion
├─ sourcePackVersionSet
├─ resolvedGrantSet
├─ capabilitySet
├─ passiveModifierGraph
├─ ruleOverrideSet
├─ proficiencySet
├─ spellAccessProfiles
├─ resourceDefinitions
├─ derivedStatisticPlan
├─ spatialBodyAndMovementProfile
├─ dependencyGraph
├─ diagnostics
└─ buildContentHash
```

Build는 현재 HP, 소비된 슬롯, 위치, Initiative와 Condition Instance를 포함하지 않는다.

## 5. Character Compiler

컴파일 흐름:

```text
Source Schema 검증
→ 콘텐츠 참조와 버전 고정
→ Grant Graph 해결
→ 선택·선행조건 검증
→ Capability 구성
→ Passive Modifier·Rule Override Graph 구성
→ Resource Definition과 최대치 식 구성
→ Derived Statistic Plan 구성
→ 의존성·순환·충돌 검증
→ Build Hash 생성
```

Compiler는 Live Character State를 수정하지 않는다.

### 5.1 Incremental Compile

변경된 Source와 의존성으로 영향 범위를 계산할 수 있다.

예:

- 준비 주문 변경: Spell Access와 관련 Capability만 재구성
- Feat 변경: 관련 Grant, Modifier, Resource와 Capability 재구성
- Class Level 추가: 이후 레벨 Grant와 Derived Dependency 재구성

부분 컴파일 결과는 전체 컴파일과 동일한 Build Hash를 생성해야 한다. 다르면 전체 컴파일로 되돌린다.

## 6. Persistent Character State

캠페인과 Scene 전환을 넘어 유지되는 현재 상태다.

```text
PersistentCharacterState
├─ characterId
├─ boundCharacterBuildId
├─ stateRevision
├─ currentHitPoints
├─ temporaryHitPoints
├─ deathSaveState
├─ exhaustionState
├─ resourceStates
├─ spellPreparationState
├─ persistentConditionInstances
├─ activeEffectBindings
├─ concentrationBinding?
├─ inventoryBinding
├─ equipmentAndAttunementState
├─ longLivedUsageGateState
└─ unresolvedMigrationRecords[]
```

`PersistentCharacterState`는 성장 Source가 아니다. Feat, Class Level과 선택 기록을 여기에 기록하지 않는다.

## 7. Scene Actor State

Character가 Scene에 존재할 때 Runtime Object의 Actor Component가 관리한다.

```text
CharacterId
→ ActorId / RuntimeObjectId
→ sceneId
→ transform
→ facing
→ Scene Presence Lifecycle
→ disclosure·perception state
→ presentation binding
```

Character State를 Actor에 복사하지 않는다. Scene 전환 시 CharacterId는 유지하고 ActorId는 새로 생성한다.

## 8. Encounter State

Encounter가 ActorId를 키로 소유한다.

```text
initiative
turn membership
action economy
movement remaining
reaction availability for current timing scope
encounter-only counters
participation state
```

전투 종료 시 장기 결과만 Authority Transaction으로 Persistent Character State나 다른 권위 Store에 반영한다.

## 9. Derived Statistics

Derived 값은 Source나 Persistent State에 권위 원본으로 저장하지 않는다.

예:

- Ability Modifier
- Proficiency Bonus
- Armor Class
- Saving Throw와 Skill Bonus
- Passive Perception·Investigation·Insight
- Spell Save DC와 Spell Attack Bonus
- 이동 속도와 감각
- Carry Capacity와 Jump 관련 규칙값
- 최대 HP와 Resource 최대치

계산 입력:

```text
Compiled Character Build
+ Persistent Character State
+ 활성 Item Source
+ 활성 Effect·Condition·Aura Source
+ Scene·Encounter Context
→ Derived Character View
```

값마다 의존성 Key와 설명 가능한 Contribution을 보존해 Character Sheet와 DM Trace에서 출처를 보여줄 수 있어야 한다.

## 10. Modifier와 Rule Override

Character Compiler는 Source에서 고정 Modifier와 Override Graph를 구성한다.

플레이 중 Item, Effect, Condition과 Aura는 활성 Source Contribution으로 결합된다.

```text
Compiled Base Contributions
+ Active Runtime Contributions
→ Modifier Resolver
→ Derived Result와 Rule Override View
```

Modifier가 HP, Resource, Actor Position과 Store를 직접 변경하지 않는다. 상태 변경이 필요한 기능은 Capability·Trigger·PendingEffect를 사용한다.

## 11. Resource Runtime 경계

Character Build는 Resource의 정의와 최대치·회복 규칙을 제공한다.

Persistent Character State는 현재값과 장기 사용 상태를 보존한다.

Rule Runtime은 Resource Reservation을 만들고 Transaction Coordinator가 소비·회복을 Commit한다.

```text
ResourceDefinition
+ Derived Maximum
+ ResourceState
+ Reservation Ledger
→ Resource Runtime View
```

HP, Hit Dice, Spell Slot, Rage, Wild Shape, Bardic Inspiration과 기타 직업 자원은 공통 Resource Primitive를 우선 사용한다.

단, Temporary HP처럼 중첩·교체 규칙이 다른 값과 Death Save처럼 별도 상태기계가 필요한 값은 같은 Primitive를 억지로 사용하지 않고 명시적 타입으로 둔다.

## 12. Capability Binding

Character는 행동 코드를 직접 소유하지 않는다.

```text
Compiled Character Build
+ 현재 Item·Effect Activation
→ Effective Capability View
→ Rule Runtime Orchestrator
```

Capability에는 출처 Identity가 유지된다.

예:

```text
capabilityId
sourceDefinitionId
sourceOccurrenceId
sourceItemInstanceId?
sourceEffectInstanceId?
activationPredicate
usageGateRefs
resourceCostRefs
recipeRef
```

Character Sheet와 Combat HUD는 같은 Effective Capability View를 사용한다.

## 13. Build 교체와 State Migration

레벨업, Feat·ASI 선택 변경, Source Pack Migration과 승인된 Character 수정은 Source 변경이다.

```text
Progression Change Proposal
→ 새 Source Revision
→ Candidate Character Build
→ Old State + New Build Migration
→ 검토·검증
→ Authority Transaction으로 Source·Build Ref·State 원자 교체
```

Migration 정책 예:

- 최대 HP 증가 시 현재 HP 유지가 기본이며 규칙이 명시하면 증가량 적용
- 사라진 Resource는 현재값과 Reservation을 검토 후 종료
- 유지되는 Resource는 Resource Identity로 현재값 보존
- 사라진 Capability의 Pending Execution은 안전 중단 또는 DM 검토
- 장비·조율 조건이 달라지면 Inventory Transaction과 함께 검증
- 누락된 콘텐츠는 Source 기록을 보존하고 `unresolved` 처리

## 14. Persistence와 Rollback

저장 대상:

- Character Progression Source와 Revision
- Source Pack Version Set
- Character Build Reference와 Hash
- Persistent Character State
- Resource Reservation과 Pending RuleExecution 참조
- 현재 Scene Actor Binding
- Encounter Snapshot에서 필요한 Actor·Encounter State

재생성 대상:

- Compiled Character Build Blob
- Capability View
- Derived Statistic View
- Modifier Cache
- Character Projection

Rollback은 선택한 Branch의 Source·Build Reference·Persistent State·Actor·Encounter State를 함께 복원해야 한다.

## 15. Projection과 Character Sheet

Client는 Raw Source, Build와 모든 비공개 State를 직접 받지 않는다.

```text
Character Runtime Snapshot
→ Ownership·Role·Disclosure 정책
→ CharacterProjection
→ Character Sheet·Combat HUD
```

Owner Player View에는 자신의 선택, 현재 자원, 설명 가능한 Derived 수치와 사용 가능한 Capability를 제공한다.

DM View에는 권위 진단, unresolved 상태와 Override 도구를 추가할 수 있다.

Observer와 다른 Player는 공개된 Profile과 Perception이 허용하는 전투 정보만 받는다.

Character Sheet의 입력은 변경 Intent이며 Source나 State 전체 복사본이 아니다.

## 16. Character 권위 서비스 경계

```text
CharacterSourceService
→ 성장 Source와 수정 Proposal

CharacterCompiler
→ 불변 Build 생성

CharacterBuildRegistry
→ Build 조회·Hash·Version

CharacterStateStore
→ Persistent Character State

CharacterRuntimeResolver
→ Build + State + Context 결합

CharacterProjectionBuilder
→ 권한별 Client View
```

Actor Lifecycle, Inventory, RuleExecution, Effect와 Encounter는 각각 자신의 권위 Service를 유지한다.

## 17. 실패 정책

- Build Compile 실패: 기존 Source·Build·State 유지
- Migration 실패: Candidate 활성화 금지, 진단과 DM 검토 제공
- 콘텐츠 누락: Source와 State 보존, 관련 Capability 비활성·unresolved 표시
- Actor Binding 누락: Character는 유지하고 Scene Presence만 복구
- Derived 계산 오류: 권위 Mutation 차단, 이전 검증 Cache 또는 안전 오류 사용
- Projection 실패: Character 권위 상태는 유지하고 재동기화

## 18. 금지 사항

- Character Sheet가 보낸 최종 AC·DC·Capability 목록 저장
- Actor에 Character HP·인벤토리 복사본을 독립 원본으로 유지
- Encounter 행동 경제를 Persistent Character State에 저장
- Compiler가 Live State를 직접 변경
- Build Table을 레벨업 중 제자리 수정
- Item·Effect Modifier가 Character Store를 직접 수정
- Source Pack 누락 시 Character 선택 기록 삭제
- Character Build 교체 후 State를 나중에 비원자적으로 보정

## 19. Guide 상태

```text
Guide Status: NOT_READY
```

Character Main System Guide는 Effect, Inventory와 Character 관련 System 기획, Specs 및 Completion Audit가 끝난 뒤 작성한다.
