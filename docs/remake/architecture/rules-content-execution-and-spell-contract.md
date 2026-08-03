# 11. 규칙 콘텐츠 공통 실행 계약과 마법 처리 모델

- 상태: 초안
- 작성일: 2026-08-03
- 관련 문서:
  - [`10. Grant Graph와 Capability 모델`](../rules-content-grant-capability-model.md)
  - [`ADR-0001`](../../decisions/ADR-0001-authored-rules-content.md)
  - [`ADR-0002`](../../decisions/ADR-0002-integrated-character-progression.md)
  - [`ADR-0003`](../../decisions/ADR-0003-ruleset-source-packs-localization.md)
  - [`ADR-0011`](../../decisions/ADR-0011-persistent-character-current-state.md)
  - [`ADR-0014`](../../decisions/ADR-0014-character-data-and-scene-actor-separation.md)
  - [`ADR-0017`](../../decisions/ADR-0017-derived-fixed-grants-and-stored-selections.md)
  - [`08. 공통 입력 교과서`](../../ui/common-input/common-input-grammar.md)

## 1. 문서 목적

RVTT에는 직업 특성, 하위직업 특성, 종 특성, 재주, 주문, 아이템 행동, 웨폰 마스터리와 몬스터 능력이 존재한다.

이 콘텐츠들은 획득 방식과 표시 위치는 다르지만 실제 사용 시에는 반복되는 공통 문제를 가진다.

- 언제 사용할 수 있는가
- 행동, 보너스 행동, 반응 또는 다른 비용을 무엇으로 소비하는가
- 어떤 대상, 지점, 물체와 영역을 선택하는가
- 사거리, 시야, 엄폐와 대상 조건이 유효한가
- 공격 굴림, 내성 굴림, 능력 판정과 피해를 어떻게 처리하는가
- 자원과 주문 슬롯을 언제 소비하는가
- 다른 특성, 반응과 마법이 어느 시점에 개입할 수 있는가
- 피해, 회복, 상태, 이동, 소환과 지형을 어떻게 적용하는가
- 지속시간, 집중, 턴 이벤트와 종료 조건을 어떻게 추적하는가
- 해석이 필요한 효과를 DM에게 어떻게 전달하고 확정하는가
- 실행 실패, 네트워크 지연과 재접속에서 어떤 상태를 보존하는가

콘텐츠마다 별도의 실행 체계와 저장 방식을 만들면 마법 수가 늘어날수록 시스템이 유지되지 않는다.

반대로 모든 규칙을 하나의 거대한 선언형 데이터에 억지로 넣으면 환영, 예언, 변신, 명령, 소환과 세계 이동 같은 마법을 정확하게 표현할 수 없다.

이 문서는 다음 결합 구조를 정형화한다.

```text
공통 실행 생명주기
+ 타입 있는 대상·비용·판정·효과 프리미티브
+ 제한된 규칙 확장점
+ 콘텐츠별 전용 처리기
+ DM 판정 요청
```

목표는 모든 콘텐츠를 동일하게 만드는 것이 아니다. 서로 다른 콘텐츠가 **같은 서버 권한, 트랜잭션, 상태 수명, 오류 처리와 UI 문법**을 사용하게 하는 것이다.

---

## 2. 획득과 실행을 분리한다

`Grant Graph`는 캐릭터가 어떤 기능을 가지고 있는지 결정한다.

이 문서는 그 기능을 실제로 사용할 때 무엇이 일어나는지 다룬다.

```text
성장 원본과 선택 기록
→ Grant Graph
→ Capability Set
→ 사용 가능한 행동·반응·패시브
→ RuleExecution
→ 확정된 게임 상태
```

다음 값을 서로 혼합하지 않는다.

### 콘텐츠 정의

규칙 카탈로그가 소유하는 불변에 가까운 정의다.

예시:

- `feature.fighter.second_wind`
- `spell.fireball`
- `item.action.potion_healing`
- `monster.action.goblin.scimitar`
- `mastery.push`

### 사용 권한

특정 캐릭터나 액터가 해당 콘텐츠를 어떤 방식으로 사용할 수 있는지 나타낸다.

예시:

- 직업 특성으로 얻은 행동
- 준비한 주문
- 종 특성으로 얻은 무료 시전
- 아이템 충전으로 사용하는 주문
- 몬스터 스탯블록이 제공한 행동

### 실행 인스턴스

플레이어 또는 DM이 한 번 사용하려고 선언한 실제 작업이다.

- 사용자 입력
- 선택한 대상과 지점
- 사용한 주문 슬롯과 자원
- 굴림 결과
- DM 승인 상태
- 확정된 효과

### 지속 효과 인스턴스

실행이 끝난 뒤에도 게임 세계에 남는 상태다.

- 집중 중인 주문
- 상태 효과
- 생성된 영역
- 소환된 액터
- 변신 상태
- 장기 저주와 축복

정의, 권한, 실행과 지속 효과를 하나의 데이터형에 넣지 않는다.

---

## 3. 공통 상위 계약과 전문 타입

특성, 재주, 주문, 아이템 행동과 몬스터 능력은 하나의 공통 상위 계약을 공유하되 서로 다른 전문 타입으로 유지한다.

```text
RuleContentDefinition
├─ FeatureDefinition
├─ FeatDefinition
├─ SpellDefinition
├─ ItemActionDefinition
├─ MonsterAbilityDefinition
├─ WeaponMasteryPropertyDefinition
└─ ConditionDefinition
```

공통 상위 계약은 실행과 관리에 필요한 공통 정보만 가진다.

전문 타입은 자신의 획득, 표시와 규칙 특성을 추가한다.

예를 들어 `FeatDefinition`은 선택 조건과 반복 선택 가능 여부가 중요하고, `SpellDefinition`은 주문 레벨, 구성요소, 집중과 상위 레벨 시전이 중요하다. 둘을 같은 평평한 타입으로 만들지 않는다.

---

## 4. RuleContentDefinition 공통 필드

개념적인 공통 필드:

```text
contentId
schemaVersion
rulesetId
sourcePackId
contentVersion
localizationKeys
category
tags
implementationLevel
availabilityPolicy
executionRecipe
handlerId
stackingPolicy
presentationProfileId
diagnosticsProfile
```

### 식별과 버전

- `contentId`: 언어와 파일 경로에 의존하지 않는 고정 ID
- `schemaVersion`: 정의 데이터 구조의 버전
- `rulesetId`: 적용 규칙 세트
- `sourcePackId`: 콘텐츠 출처 팩
- `contentVersion`: 규칙 정의 자체의 버전

### 표시

- 이름, 짧은 이름, 설명과 로그 문장은 번역 키로 분리한다.
- 내부 ID와 한국어 이름을 동일한 값으로 사용하지 않는다.
- 규칙 수치와 실행 순서는 번역 리소스에 넣지 않는다.

### 실행

- `implementationLevel`: 자동화 수준
- `executionRecipe`: 공통 프리미티브로 표현한 실행 절차
- `handlerId`: 고유 규칙이 필요한 제한된 전용 처리기
- `presentationProfileId`: VFX, SFX, 카메라와 로그 표현

정의가 실행 로직 전체를 캐릭터 저장 데이터에 복사하지 않는다.

---

## 5. 구현 수준

모든 실행형 콘텐츠는 실제 지원 수준을 명시한다.

### Executable: 완전 실행형

시스템이 다음을 끝까지 처리한다.

- 사용 가능 여부
- 비용과 자원
- 대상 지정
- 굴림과 결과 계산
- 효과 적용
- 지속시간과 종료
- 저장과 재접속

예시 유형:

- 단일 대상 공격
- 범위 내 내성 굴림과 피해
- 정해진 수치의 회복
- 명확한 상태 부여

### Guided: 유도 실행형

시스템이 구조화된 절차와 상태를 관리하지만 플레이어 또는 DM의 선택이 필요하다.

- 여러 효과 중 하나 선택
- 소환할 형태 선택
- 조건부 추가 피해 사용 여부
- 지정한 문구나 명령 확인
- 애매한 대상 조건을 DM이 승인

승인 이후의 자원, 굴림, 지속시간과 효과는 시스템이 계속 추적한다.

### Assisted: 판정 보조형

효과의 의미가 환경과 서사에 크게 의존한다.

시스템은 다음을 제공한다.

- 의도와 설명 입력
- 대상, 위치, 물체와 영역 선택
- 규칙상 명확한 제한 검사
- 필요한 굴림
- 임시 오브젝트, 메모, 영역과 지속시간 추적
- DM 승인, 수정과 종료

최종 세계 변화는 DM이 확정한다.

### Disabled: 비활성

정의 또는 처리기가 불완전하거나 손상되어 안전하게 실행할 수 없는 상태다.

설명만 존재하는 콘텐츠를 정상 지원 상태로 표시하지 않는다.

---

## 6. 실행 엔티티

### ActionCapability

캐릭터가 현재 사용할 수 있는 실행 진입점이다.

다음을 참조한다.

- 콘텐츠 ID
- 획득 출처
- 행동 경제
- 활성 조건
- 비용 프로필
- 대상 프로필
- 실행 레시피 또는 처리기

### RuleExecutionRequest

클라이언트가 서버에 보내는 사용 의도다.

개념 필드:

```text
executionId
actorId
capabilityId
contentId
sourceOccurrenceId
requestedMode
selectedOptions
targetIntent
clientRevision
```

클라이언트는 피해량, 성공 여부와 최종 효과를 보내지 않는다.

### RuleExecution

서버가 관리하는 한 번의 실행 상태다.

```text
RuleExecution
├─ executionId
├─ state
├─ actorId
├─ contentId와 version
├─ capability source
├─ collected inputs
├─ validation snapshot
├─ reserved costs
├─ rolls and decisions
├─ pending effects
├─ adjudication request
└─ commit result
```

### OngoingEffectInstance

실행 완료 후 남는 효과다.

```text
OngoingEffectInstance
├─ effectInstanceId
├─ sourceExecutionId
├─ sourceContentId
├─ sourceActorId
├─ ownerScope
├─ targets 또는 anchor
├─ duration state
├─ concentration link
├─ stacking key
├─ active hooks
└─ cleanup policy
```

---

## 7. 공통 실행 상태와 생명주기

모든 행동, 특성, 마법과 아이템 사용은 같은 상위 상태 흐름을 사용한다.

```text
Available
→ Declared
→ CollectingInput
→ Validating
→ AwaitingAdjudication
→ CostsReserved
→ Resolving
→ CommitPending
→ Committed
→ Presenting
→ Finished
```

모든 실행이 모든 상태를 거칠 필요는 없다.

실패와 취소 상태:

```text
Cancelled
Rejected
Invalidated
Failed
RolledBack
```

### Available

Capability Set과 현재 상태를 기준으로 사용할 수 있는 행동이 표시된다.

### Declared

플레이어가 행동을 선택했다. 아직 비용과 효과는 확정하지 않는다.

### CollectingInput

다음을 필요한 순서로 수집한다.

- 시전 또는 사용 모드
- 주문 슬롯 레벨
- 대상, 지점, 경로와 영역
- 선택 효과
- 추가 자원 사용 여부
- 자유 설명

Q는 가장 가까운 미완성 단계 하나만 취소한다.

### Validating

서버가 현재 권위 상태로 다시 검사한다.

- 사용 권한
- 현재 턴과 행동 경제
- 자원과 주문 슬롯
- 장비, 상태와 구성요소
- 대상, 사거리, 시야와 엄폐
- 씬과 전투 revision

### AwaitingAdjudication

Guided 또는 Assisted 콘텐츠가 DM 판단을 기다린다.

### CostsReserved

실행에 필요한 비용을 임시 예약한다. 아직 부분 소비를 확정하지 않는다.

### Resolving

굴림, 선택, 반응 창과 효과 계산을 수행한다.

### CommitPending

모든 결과를 하나의 변경 묶음으로 검증한다.

### Committed

자원 소비와 효과 적용을 원자적으로 확정한다.

### Presenting

확정 결과를 기준으로 로그, VFX, SFX와 카메라 연출을 실행한다.

연출 실패가 이미 확정된 규칙 결과를 되돌리지 않는다.

---

## 8. 서버 권한과 멱등성

서버는 다음을 최종 결정한다.

- 행동 사용 가능 여부
- 행동 경제와 자원 비용
- 유효 대상과 실제 영향 대상
- 굴림과 규칙 수정자
- 피해, 회복과 상태
- 지속 효과 생성과 종료
- 최종 저장 상태

모든 실행 요청은 클라이언트가 생성한 고유 `executionId`를 가진다.

서버는 같은 ID의 중복 요청을 두 번 실행하지 않는다.

실행 중 씬, 턴, 대상 또는 캐릭터 revision이 바뀌면 영향 범위에 따라 다시 검증하거나 안전하게 `Invalidated` 처리한다.

클라이언트 예측은 대상과 범위 미리보기에만 사용하고 최종 결과로 저장하지 않는다.

---

## 9. 행동 경제와 비용

비용은 하나의 숫자가 아니라 여러 종류를 가질 수 있다.

```text
ActionCost
├─ action economy
├─ movement cost
├─ spell slot
├─ character resource
├─ item charge 또는 consumable
├─ material component
├─ hit dice 또는 HP
└─ special cost
```

행동 경제 후보:

- Action
- BonusAction
- Reaction
- FreeInteraction
- Movement
- TurnLimitedUse
- ExplorationActivity
- LongCastingActivity
- Passive 또는 Triggered

콘텐츠가 전투 런타임 값을 직접 수정하지 않는다. 공통 행동 경제 서비스에 비용 예약과 추가 행동 권한을 요청한다.

### 비용 예약

대상 지정이 끝나기 전에 주문 슬롯을 소비하지 않는다.

정상 흐름:

```text
입력 수집
→ 서버 유효성 검사
→ 필요한 비용 예약
→ 굴림과 효과 해결
→ 전체 결과와 함께 비용 확정
```

### 비용 환불

- 선언 자체가 불법이면 비용을 소비하지 않는다.
- 서버 오류와 원자적 적용 실패는 예약 비용을 롤백한다.
- 합법적인 실행이 확정된 뒤 결과가 실패하거나 빗나간 것은 일반적으로 환불 사유가 아니다.
- 콘텐츠별 특별 환불 규칙은 명시적인 정책으로만 허용한다.

---

## 10. 대상 지정 공통 모델

대상 지정은 콘텐츠마다 자유 형식 좌표를 받지 않는다.

기본 대상 종류:

- Self
- SingleActor
- MultipleActors
- ActorOrObject
- SingleObject
- Point
- Area
- Line
- Cone
- Sphere
- Cylinder
- Cube
- Wall
- Path
- OriginAndDestination
- CustomGuidedSelection

### 선택 대상과 영향 대상을 구분한다

플레이어가 선택한 중심점과 실제 영향을 받는 액터 목록은 다를 수 있다.

```text
선택한 지점
→ 서버가 범위와 차단 규칙으로 영향 대상 계산
```

클라이언트가 보낸 영향 대상 배열을 그대로 신뢰하지 않는다.

### TargetProfile

개념 필드:

```text
targetMode
originPolicy
rangeFormula
geometry
maximumTargets
filterRules
lineOfSightPolicy
coverPolicy
pathPolicy
friendlyFirePolicy
selectionOrder
```

### 유효성 검사

- 대상이 현재 씬에 존재하는가
- 요구된 액터 또는 오브젝트 종류인가
- 생존, 상태와 진영 조건이 맞는가
- 사거리 안인가
- 시야와 효과 경로가 유효한가
- 같은 대상을 중복 선택하지 않았는가
- 최대 대상 수를 넘지 않았는가

정확한 D&D 거리와 엄폐 규칙은 전투 명세에서 정의하지만 모든 콘텐츠는 같은 질의 서비스를 사용한다.

---

## 11. 굴림과 판정

공통 판정 종류:

- AttackRoll
- SavingThrow
- AbilityCheck
- DamageRoll
- HealingRoll
- Contest 또는 규칙 세트가 정의한 대립 판정
- FlatCheck
- TableRoll

`RollRequest`는 다음을 포함한다.

```text
rollType
sourceActorId
targetActorId
ability 또는 defense
baseFormula
modifiers
advantageState
visibilityPolicy
purpose
executionId
```

굴림 결과는 구조화된 값으로 저장한다.

- 원본 주사위
- 적용 수정자
- 최종 합계
- 성공, 실패, 명중과 치명타
- 결과를 바꾼 특성과 반응

전투 로그 문장을 굴림 결과의 원본으로 사용하지 않는다.

---

## 12. 공통 효과 프리미티브

반복되는 효과는 공통 엔진에서 제공한다.

### 수치와 생명력

- DealDamage
- Heal
- GrantTemporaryHitPoints
- ModifyMaximumHitPoints
- ModifyResource

### 상태와 규칙

- ApplyCondition
- RemoveCondition
- AddModifier
- RemoveModifier
- GrantAdvantage 또는 Disadvantage
- AddResistance, Immunity 또는 Vulnerability

### 이동과 위치

- ForcedMove
- Teleport
- SwapPosition
- KnockProne
- ChangeMovementMode

### 공간과 환경

- CreateZone
- CreateWall
- CreateHazard
- ModifyTerrainCost
- CreateLight 또는 Darkness
- Reveal 또는 Conceal

### 액터와 오브젝트

- SummonActor
- DismissActor
- TransformActor
- CreateObject
- ModifyObjectState
- DestroyTemporaryObject

### 정보와 선택

- RevealInformation
- RequestChoice
- RequestAdjudication
- AddCampaignNote

효과 프리미티브는 서버 권한 인터페이스를 통해서만 상태를 바꾼다.

---

## 13. 실행 레시피

단순하고 반복적인 콘텐츠는 타입 있는 실행 단계로 표현한다.

개념 예시:

```text
ExecutionRecipe
├─ input steps
├─ validation steps
├─ cost profile
├─ roll steps
├─ branching steps
├─ effect operations
├─ ongoing effect blueprint
└─ presentation events
```

예시 흐름:

```text
단일 대상 선택
→ 주문 공격 굴림
→ 명중 분기
→ 피해 굴림
→ DealDamage
```

레시피 단계는 임의의 문자열 명령이 아니라 Registry에 등록된 타입 있는 노드다.

한 콘텐츠가 수백 개의 작은 전용 스크립트를 만들 필요를 줄이되, 모든 규칙을 레시피만으로 강제하지 않는다.

---

## 14. 타입 있는 규칙 이벤트와 반응 창

특성, 마법과 웨폰 마스터리는 다른 실행 중간에 개입할 수 있다.

이 개입은 임의 이벤트 문자열이나 전역 콜백으로 구현하지 않는다.

이벤트 단계 후보:

```text
ActionDeclared
TargetsLocked
BeforeCostCommit
BeforeAttackRoll
AfterAttackRoll
AttackHit
AttackMissed
BeforeSavingThrow
AfterSavingThrow
SavingThrowFailed
BeforeDamageRoll
AfterDamageRoll
BeforeDamageApplied
AfterDamageApplied
BeforeEffectApplied
AfterEffectApplied
MovementStarted
MovementEnteredArea
MovementEnded
TurnStarted
TurnEnded
RestCompleted
ConcentrationCheckRequired
ConcentrationEnded
```

각 이벤트는 다음을 정의한다.

- 읽을 수 있는 데이터
- 변경할 수 있는 데이터
- 반응 가능 대상
- 반응 우선순위
- 중첩과 반복 제한
- 시간 초과 처리

### 반응 창

반응이 가능한 이벤트가 발생하면 서버가 후보 Capability를 계산한다.

```text
이벤트 발생
→ 반응 후보 조회
→ 사용할 수 있는 후보만 플레이어에게 표시
→ 플레이어 사용 또는 넘기기
→ 서버 재검증
→ 원래 실행 재개
```

한 콘텐츠의 반응 처리기가 독립된 전투 루프를 만들지 않는다.

---

## 15. 지속 효과, 집중과 종료

### 지속시간 모델

지원할 수명 종류:

- Instant
- UntilTurnStart
- UntilTurnEnd
- RoundCount
- MinuteCount 또는 HourCount의 게임 시간
- UntilShortRest
- UntilLongRest
- UntilDispelled
- UntilCondition
- Permanent
- Adjudicated

현실 시간이 흘렀다는 이유로 게임 규칙상 효과가 자동 종료되지 않는다.

### 소유 범위

```text
ActorEffect
→ 캐릭터 또는 NPC의 상태와 함께 유지

SceneEffect
→ 영역, 소환, 임시 오브젝트와 함께 씬이 소유

CombatEffect
→ 현재 조우 안에서만 존재

CampaignEffect
→ 장기 저주, 축복과 서사 상태
```

효과의 위치와 수명을 잘못된 저장소에 넣지 않는다.

### 집중

집중은 단순한 boolean이 아니다.

```text
ConcentrationState
├─ concentratingActorId
├─ sourceExecutionId
├─ linkedEffectInstanceIds
├─ startedAtGameTime
├─ breakConditions
└─ status
```

한 집중이 여러 대상 효과와 영역을 연결할 수 있다.

새 집중을 시작하면 기존 집중 종료 절차를 먼저 적용한다.

집중이 끝나면 연결된 효과를 각자의 cleanup policy에 따라 원자적으로 종료한다.

### 중첩

지속 효과는 `stackingKey`와 정책을 가진다.

- unique
- additive
- maximum
- refreshDuration
- replace
- exclusiveGroup
- custom

표시 이름이 같다는 이유로 중첩 여부를 추측하지 않는다.

---

## 16. DM 판정 요청

Guided와 Assisted 콘텐츠는 실행 파이프라인을 벗어나 수동 처리하지 않는다.

서버는 `AdjudicationRequest`를 생성한다.

```text
AdjudicationRequest
├─ requestId
├─ executionId
├─ requester actor와 player
├─ contentId와 rules text reference
├─ declared intent
├─ selected targets, objects와 area
├─ system-validated constraints
├─ unresolved questions
├─ suggested outcomes
├─ reserved costs
└─ expiration and cancel policy
```

DM은 다음 중 하나를 선택한다.

- 승인
- 허용된 수치 또는 대상 수정 후 승인
- 추가 판정 요청
- 거절
- 실행을 판정 보조 상태로 유지

### 비용 처리

- 불법 선언을 거절한 경우 비용을 소비하지 않는다.
- 합법적인 시전 또는 능력 사용으로 승인한 시점에 비용을 확정한다.
- 효과의 강도나 서사 결과가 기대와 다르다는 이유로 비용을 자동 환불하지 않는다.

### 기록

DM 수정은 다음을 구조화해 남긴다.

- 원래 의도
- 수정된 결과
- 수정 이유 또는 판정 메모
- 승인한 DM
- 관련 실행과 효과 인스턴스

DM 판정을 자유로운 저장 데이터 직접 편집으로 대체하지 않는다.

---

## 17. 주문의 다섯 층

마법은 다음 다섯 층을 분리한다.

```text
SpellDefinition
→ 주문 자체의 규칙

SpellAccessCapability
→ 이 캐릭터가 주문을 어떻게 사용할 수 있는가

SpellSelectionState
→ 습득, 주문책, 준비와 교체 결과

SpellCastExecution
→ 이번 한 번의 실제 시전

SpellEffectInstance
→ 시전 뒤 지속되는 결과
```

### SpellDefinition

주문 자체의 공통 규칙이다.

### SpellAccessCapability

직업, 종, 재주와 아이템에 따라 다른 사용 권한이다.

같은 주문이라도 여러 Access가 동시에 존재할 수 있다.

### SpellSelectionState

캐릭터 성장 원본 또는 현재 준비 상태에 저장할 선택 결과다.

고정으로 항상 준비되는 주문은 정의에서 파생하고, 플레이어가 선택하거나 준비한 결과만 저장한다.

### SpellCastExecution

선택한 Access, 슬롯 레벨, 대상과 시전 옵션을 고정한 실행이다.

### SpellEffectInstance

집중, 영역, 소환, 변신과 장기 상태를 추적한다.

---

## 18. SpellDefinition 계약

개념 필드:

```text
spellId
spellLevel
school
tags
castingTime
reactionTrigger
ritualPolicy
rangeProfile
targetProfile
componentProfile
durationProfile
concentrationPolicy
resolutionProfile
scalingProfile
implementationLevel
executionRecipe
handlerId
presentationProfileId
```

### 시전 시간

- Action
- BonusAction
- Reaction과 정확한 trigger
- Minute 또는 Hour 단위 장기 시전
- Ritual 가능 여부

### 구성요소

- Verbal
- Somatic
- Material
- 소비되는 재료
- 가격이 있는 재료
- 주문시전 집중도구로 대체 가능한지

구성요소 검증은 인벤토리와 장비 상태를 사용한다.

### 지속시간

즉시 효과와 지속 효과를 구분한다.

### ResolutionProfile

- 공격 굴림
- 대상별 내성 굴림
- 자동 효과
- 복합 단계
- DM 판정 필요

### ScalingProfile

- 상위 슬롯 레벨
- 캐릭터 레벨
- 주문시전 능력치
- 대상 수
- 피해 또는 회복 주사위
- 지속시간과 영역 크기

현재 계산값을 주문 정의에 여러 버전으로 복사하지 않는다.

---

## 19. SpellAccessCapability 계약

같은 주문의 사용 방식은 획득 출처마다 다르다.

개념 필드:

```text
spellId
sourceChain
accessMode
castingAbility
preparationPolicy
slotPolicy
freeCastResource
upcastPolicy
componentOverrides
ritualOverride
concentrationOverrides
availabilityCondition
```

### accessMode

- Known
- Prepared
- AlwaysPrepared
- Spellbook
- Innate
- ItemGranted
- Temporary

### slotPolicy

- 일반 주문 슬롯 사용 가능
- 특정 직업 슬롯만 사용
- 무료 시전 후 슬롯 사용 가능
- 무료 시전만 가능
- 아이템 충전만 사용
- 고정 레벨 시전

같은 `spellId`라도 종 특성, 재주와 직업 주문은 서로 다른 시전 능력치와 비용 정책을 가질 수 있다.

행동 UI는 주문 이름만 기준으로 하나로 합치지 않고 사용할 Access를 명확하게 선택하거나 안전하게 묶어 보여준다.

---

## 20. 주문 시전 흐름

```text
주문 선택
→ 사용할 SpellAccess 선택
→ 시전 모드와 슬롯 레벨 선택
→ 구성요소와 시전 조건 미리 검사
→ 대상·지점·영역 선택
→ 서버 전체 검증
→ 필요하면 DM 판정
→ 슬롯·무료 시전·아이템 충전 예약
→ 반응과 방해 가능 시점 처리
→ 공격·내성·피해·선택 해결
→ 즉시 효과와 지속 효과 생성
→ 비용과 결과 원자적 확정
→ 로그와 연출
```

### 준비되지 않은 주문

SpellDefinition이 존재해도 활성 SpellAccess가 없으면 시전할 수 없다.

### 무료 시전과 슬롯 시전

무료 시전이 남아 있어도 플레이어가 슬롯 사용을 선택할 수 있는지 Access 정책으로 정한다.

### 상위 레벨 시전

클라이언트가 최종 피해 공식을 보내지 않는다.

서버가 선택한 슬롯 레벨과 ScalingProfile로 계산한다.

### 시전 도중 상태 변화

대상 이동, 침묵, 무장 해제, 집중 종료와 턴 변경이 발생하면 해당 단계에서 다시 검증한다.

---

## 21. 마법 난이도 분류

마법 수가 많더라도 주문마다 완전히 새로운 기반을 만들지 않는다.

각 주문은 주 실행 유형과 필요한 확장 수준으로 분류한다.

### A. 즉시 공격·피해·회복

구조:

```text
대상 또는 영역
→ 공격 또는 내성
→ 피해·회복
→ 선택적 상태
```

대부분 실행 레시피만으로 구현한다.

### B. 여러 모드와 선택지

시전 시 효과, 피해 유형, 대상 방식 또는 자원 사용을 선택한다.

`RequestChoice`와 결정적 분기 레시피를 사용한다.

### C. 지속 영역과 집중

영역 앵커, 진입·턴 이벤트, 반복 내성과 집중 종료가 필요하다.

`SceneEffectInstance`와 공간 질의 인덱스를 사용한다.

영역마다 독립적인 매 프레임 루프를 만들지 않는다.

### D. 소환과 생성

소환 가능한 프로필, 수량, 배치 위치, 이니셔티브, 조작 권한과 종료를 처리한다.

```text
SummonProfile
→ 허용 스탯블록과 수량
→ 배치 검증
→ SceneNpc 또는 임시 Actor 생성
→ 원본 시전과 수명 연결
```

소환수를 캐릭터 원본 데이터에 넣지 않는다.

### E. 변신과 대체 능력치

원본 캐릭터를 파괴하거나 새 캐릭터로 교체하지 않는다.

```text
TransformEffect
├─ 유지할 원본 데이터
├─ 대체할 파생 능력치와 Capability
├─ HP 처리 정책
├─ 장비 표시와 사용 정책
└─ 종료 시 복구 정책
```

변신 중에도 `characterId`와 성장 원본은 유지한다.

### F. 강제 이동과 순간이동

일반 이동과 같은 점유, 차단, 표면과 목적지 검증을 공유한다.

강제 이동과 순간이동은 이동 비용과 반응 규칙만 별도 정책으로 둔다.

### G. 환영과 창의적 형상

플레이어가 다음을 입력할 수 있다.

- 소리 또는 형상
- 설명
- 위치와 크기
- 공개 대상

시스템은 임시 환영 오브젝트, 지속시간, 집중, 조사 판정과 플레이어별 가시성을 추적한다.

환영의 설득력, 생명체 반응과 환경적 결과는 DM 판정 대상으로 둔다.

모든 환영을 일반 소환물이나 실제 벽으로 처리하지 않는다.

### H. 정보 탐지와 예언

숨겨진 정보를 클라이언트가 직접 조회하지 않는다.

서버 또는 DM이 공개 가능한 결과만 `RevealInformation`으로 전달한다.

```text
탐지 범위와 조건 검사
→ 서버가 후보 비밀 정보 조회
→ 자동 공개 가능 정보 분리
→ DM 판정이 필요한 정보 요청
→ 요청자에게만 결과 공개
```

전투 로그와 다른 플레이어에게 비밀 결과를 누출하지 않는다.

### I. 명령, 매혹과 행동 제한

대상의 전체 AI나 플레이어 입력을 전용 주문 코드가 직접 장악하지 않는다.

- 허용·금지 행동 조건
- 목표 또는 명령 텍스트
- 반복 내성 시점
- 피해 등 종료 조건
- DM 판정 지점

을 `ControlEffect`와 행동 검증 레이어에 연결한다.

자유 문장의 해석은 Guided 또는 Assisted로 처리한다.

### J. 반응, 방해와 상쇄

다른 실행을 일시정지하고 반응 창을 연다.

원래 실행과 반응 실행은 부모·자식 관계를 가진다.

반응 결과가 확정되면 원래 실행을 계속, 수정 또는 취소한다.

중첩 반응 깊이와 반복을 제한한다.

### K. 지연, 조건부 발동과 함정형 효과

시전 시 모든 결과를 즉시 적용하지 않는다.

```text
TriggerEffectInstance
├─ 발동 조건
├─ 감시할 타입 있는 이벤트
├─ 대상과 저장된 파라미터
├─ 만료 조건
└─ 발동 시 실행할 검증된 recipe
```

자유로운 매 프레임 조건 검사를 허용하지 않는다.

### L. 환경과 물체 변경

문, 불, 물, 빛, 지형과 임시 구조를 변경할 수 있다.

가능한 변화는 장면 오브젝트의 상호작용 계약과 SceneCommand를 사용한다.

규칙 콘텐츠가 Workspace Part를 직접 생성하거나 삭제하지 않는다.

해석이 필요한 대규모 변화는 DM 승인 후 SceneEffect 또는 라이브 패치로 기록한다.

### M. 장기 시전과 의식

즉시 전투 행동이 아니라 `LongCastingActivity`로 관리한다.

- 시작 시간
- 참여자
- 중단 조건
- 구성요소 예약
- 완료 시 실행

씬 전환과 세션 종료에서도 안전하게 저장하거나 명시적으로 중단한다.

### N. 죽음, 시체와 부활

대상의 생명 상태, 시체 엔티티, 시간 제한, 소비 재료와 장기 상태를 함께 처리한다.

캐릭터 삭제와 부활을 같은 의미로 사용하지 않는다.

서사 조건과 영혼의 의사처럼 시스템이 판단할 수 없는 항목은 DM 판정으로 남긴다.

### O. 장면·차원·캠페인 규모 이동

단순 Teleport 효과와 씬 전환을 구분한다.

장면 또는 캠페인 구조를 바꾸는 마법은:

- 목적지 유효성
- 파티와 대상 목록
- 현재 씬 상태 저장
- 전투 유지 여부
- DM 승인
- 실패 시 원래 씬 복구

를 포함하는 전용 Guided 또는 Assisted 흐름을 사용한다.

---

## 22. 마법 구현 계층

마법마다 필요한 코드량을 다음 네 계층으로 나눈다.

### Recipe Only

공통 대상, 굴림과 효과 노드만으로 구현한다.

### Recipe + Registered Extension

공통 레시피에 한두 개의 등록된 규칙 확장점을 사용한다.

### Dedicated Handler

복잡한 순서와 상태를 가진 신뢰된 전용 처리기를 사용한다.

전용 처리기도 공통 입력, 비용, 효과, 저장과 롤백 인터페이스를 사용한다.

### Guided 또는 Assisted Workflow

창의적 해석이나 세계 변화가 중심인 마법은 DM 판정 요청을 포함한다.

자동화 비율이 낮더라도 전용 UI, 상태 추적과 로그를 제공한다.

콘텐츠 제작자는 가장 낮은 복잡도 계층으로 정확하게 표현할 수 있는 방식을 선택한다.

---

## 23. 전용 처리기의 경계

전용 처리기는 제한된 `RuleExecutionContext`만 받는다.

허용 인터페이스:

- 현재 실행과 검증된 actor·target 조회
- 추가 입력과 선택 요청
- 굴림 요청
- 비용 예약 요청
- 효과 작업 추가
- 지속 효과 blueprint 생성
- DM 판정 요청
- 구조화된 로그
- 취소와 실패 반환

금지:

- RemoteEvent 직접 생성
- UserInputService 직접 감시
- Character 저장 데이터 직접 수정
- Workspace 직접 수정
- 독립적인 자원 저장소
- 독립적인 턴 또는 이벤트 루프
- 별도 실행 취소 체계
- 출처 팩 밖의 비공개 코어 서비스 접근

처리기 오류는 해당 실행에 격리한다.

비용과 효과를 일부만 적용한 상태로 남기지 않는다.

---

## 24. 데이터 소유권과 저장

### 캐릭터 원본

- 현재 HP와 임시 HP
- 주문 슬롯
- 직업과 특성 자원
- 집중 상태
- 캐릭터에 직접 붙은 장기 효과
- 주문 습득과 준비 선택

### CharacterActor 또는 SceneNpc

- 현재 씬 위치와 토큰 표시
- 씬 전용 가시성
- 씬 소속 액터 효과

### Scene

- 지속 영역
- 소환된 NPC와 오브젝트
- 임시 벽, 지형과 위험
- 장면에 고정된 환영과 빛

### Combat Runtime

- 현재 턴
- 행동, 보너스 행동과 반응 사용 상태
- 이번 턴 이동량
- 라운드 단위 임시 상태

### Campaign

- 장기 저주, 축복과 세계 상태
- 장면 밖에서도 유지되는 판정 결과

지속 효과는 자신의 소유 범위와 저장 정책을 정의해야 한다.

세션 종료와 재접속만으로 효과, 집중과 자원을 초기화하지 않는다.

---

## 25. UI와 입력

### 행동 목록

Capability Set에서 생성한다.

표시 정보:

- 행동 이름과 출처
- 행동 경제
- 현재 비용과 남은 자원
- 사용 가능 여부
- 비활성 이유
- 집중 중인 효과와 충돌
- DM 승인 필요 여부

### 대상 지정

- 유효 대상과 범위 미리보기
- 예상 영향 대상
- 사거리, 엄폐와 차단 이유
- 선택 단계와 남은 선택 수

미리보기는 서버 결과를 보장하지 않는다.

### Q와 E

- Q: 현재 대상, 선택 또는 미완성 실행 단계 취소
- E: 모든 필수 입력이 유효할 때 실행 확정
- DM 요청 중 Q: 거절
- DM 요청 중 E: 현재 선택 승인

텍스트와 수치 입력 중에는 게임 단축키를 실행하지 않는다.

### 주문 UI

주문 이름만 보여주지 않는다.

- 획득 출처
- 준비 또는 항상 준비 상태
- 사용할 시전 능력치
- 무료 시전과 남은 횟수
- 사용 가능한 슬롯 레벨
- 구성요소 부족
- 집중 충돌
- 의식 시전 가능 여부

---

## 26. 콘텐츠 검증

출처 팩 로딩 단계에서 모든 규칙 콘텐츠를 검사한다.

공통 검사:

- 고유 ContentId와 버전
- 유효한 ruleset과 source pack
- 번역 키
- 구현 수준
- 등록된 recipe node와 handler
- 대상과 비용 프로필
- 중첩 키와 정책
- 지속 효과의 cleanup policy
- 저장 소유 범위
- 필요한 권한과 DM 판정 지점

주문 추가 검사:

- 주문 레벨과 시전 시간
- 사거리와 대상 정의
- 구성요소
- 지속시간과 집중
- 판정 방식
- 상위 레벨 변화
- SpellAccess와 호환 가능한 시전 정책
- 재접속 후 복구 가능한 지속 상태

잘못된 정의는 로드 단계에서 비활성화한다.

전투 중 처음 사용될 때까지 오류를 숨기지 않는다.

---

## 27. 성능과 생명주기

- 비활성 Capability는 규칙 이벤트를 구독하지 않는다.
- 이벤트 후보는 이벤트 종류별 인덱스로 찾는다.
- 모든 특성과 주문을 매 이벤트마다 전체 검색하지 않는다.
- 지속 영역은 공간 인덱스와 진입·이탈 이벤트를 사용한다.
- 영역마다 매 프레임 전체 토큰을 순회하지 않는다.
- 실행 레시피는 검증된 중간 표현으로 캐시할 수 있다.
- 종료된 효과의 연결, 태스크, 공간 등록과 임시 오브젝트를 정리한다.
- 씬 언로드 시 SceneEffect를 저장 또는 정리하고 서버 루프를 남기지 않는다.
- VFX와 SFX 실패가 규칙 실행을 중단시키지 않는다.

콘텐츠별 성능 비용을 측정할 수 있어야 한다.

- 실행 시간
- 효과 대상 수
- 생성한 액터와 오브젝트 수
- 이벤트 구독 수
- 네트워크 페이로드
- 장시간 유지되는 메모리

---

## 28. 테스트 규약

모든 콘텐츠는 정의 검증 외에 자신의 구현 수준에 맞는 계약 테스트를 가진다.

### 공통 실행 테스트

- 정상 실행
- 사용할 수 없는 상태
- 잘못된 대상과 사거리
- 자원 부족
- Q 취소
- 중복 executionId
- 턴 또는 씬 revision 변경
- 반응 사용과 넘기기
- 일부 적용 실패와 롤백
- 재접속 후 상태 복구

### 지속 효과 테스트

- 정상 종료
- 집중 중단
- 해제와 제거
- 중첩과 교체
- 대상 사망 또는 씬 이탈
- 세션 종료와 재접속
- 누락 콘텐츠 버전

### 마법 범주 테스트

최소 기준 사례:

1. 단일 대상 공격 주문
2. 범위 내성 피해 주문
3. 집중 지속 영역 주문
4. 소환 주문
5. 변신 주문
6. 반응으로 다른 실행에 개입하는 주문
7. 환영 Guided 주문
8. 정보 공개 Assisted 주문
9. 장기 시전과 구성요소 소비
10. 씬 이동을 요구하는 판정 보조 주문

설명만 표시되고 실행 계약 테스트가 없는 콘텐츠를 완료로 간주하지 않는다.

---

## 29. 첫 수직 검증 순서

공통 기반을 수평으로 전부 만든 뒤 콘텐츠를 시작하지 않는다.

얇은 실행 흐름을 순서대로 검증한다.

```text
1. 단일 대상 행동
→ 대상 선택, 비용, 공격 굴림, 피해, 로그

2. 범위 주문
→ 지점, 영향 대상, 내성, 피해, 슬롯 소비

3. 집중 지속 영역
→ SceneEffect, 턴 이벤트, 집중 종료, 저장

4. 반응 주문
→ 부모 실행 일시정지, 반응 창, 실행 재개

5. 소환 주문
→ SceneNpc 생성, 조작 권한, 종료와 씬 저장

6. 환영 또는 자유 명령 주문
→ 설명 입력, DM 판정, 임시 표현과 지속시간
```

각 단계는 시트 또는 행동 UI부터 서버 적용, 로그, 저장과 재접속까지 세로로 완성한다.

---

## 30. 우선 확정하는 방향

1. 모든 규칙 콘텐츠는 공통 `RuleContentDefinition` 상위 계약을 공유하되 전문 타입을 유지한다.
2. 획득, 사용 권한, 한 번의 실행과 지속 효과를 분리한다.
3. 모든 실행은 공통 서버 권위 상태기계와 원자적 트랜잭션을 사용한다.
4. 비용은 유효성 검사 후 예약하고 결과와 함께 확정한다.
5. 대상, 굴림, 피해, 상태, 이동, 영역과 소환은 타입 있는 공통 프리미티브를 사용한다.
6. 반응과 트리거는 타입 있는 규칙 이벤트와 제한된 반응 창을 사용한다.
7. 지속 효과는 actor, scene, combat 또는 campaign 소유 범위를 명시한다.
8. 집중은 시전자와 여러 효과 인스턴스를 연결하는 정식 상태다.
9. 주문 자체와 주문 사용 권한을 분리한다.
10. 같은 주문도 획득 출처에 따라 다른 시전 능력치, 비용과 무료 시전 정책을 가질 수 있다.
11. 단순 마법은 실행 레시피로, 고유 마법은 제한된 전용 처리기로 구현한다.
12. 환영, 예언, 명령과 대규모 세계 변화는 Guided 또는 Assisted 흐름을 사용한다.
13. 판정 보조형도 전용 UI, 비용, 지속시간, 상태와 로그를 가진 실제 기능으로 구현한다.
14. 콘텐츠 오류는 로드 단계에서 찾고 해당 콘텐츠에 격리한다.
15. 설명문만 존재하는 기능을 정상 지원으로 표시하지 않는다.

---

## 31. 후속 결정이 필요한 항목

1. 실제 typed Luau `RuleContentDefinition`, `RuleExecution`과 effect union
2. 공통 실행 상태별 정확한 취소와 타임아웃 정책
3. D&D 2024의 정확한 시야, 엄폐와 범위 판정 계약
4. 타입 있는 규칙 이벤트의 최종 목록과 반응 우선순위
5. 비용 예약 이후 DM 응답이 없을 때의 처리
6. 주문 준비 상태를 영구 성장 원본과 일일 현재 상태 중 어디에 둘지에 대한 세부 계약
7. 긴 휴식 후 주문 준비 변경의 원자적 흐름
8. 소환수의 이니셔티브와 플레이어 조작 UI
9. 변신 중 HP와 장비의 정확한 공통 정책
10. 환영 오브젝트의 플레이어별 가시성 데이터 구조
11. 정보 탐지 주문이 접근할 수 있는 비밀 정보 질의 인터페이스
12. 장면·차원 이동 마법과 씬 전환 시스템의 통합 명세
13. 마법별 VFX 범위와 저사양 클라이언트 대체 표현
14. 첫 구현 범위에 포함할 주문 카테고리와 기준 주문 목록

다음 논의에서는 **주문 습득·주문책·준비·항상 준비·무료 시전을 캐릭터 데이터에 어떻게 저장하고 갱신할지**를 구체화한다.
