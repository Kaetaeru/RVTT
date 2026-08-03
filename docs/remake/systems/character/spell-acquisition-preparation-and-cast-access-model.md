# 12. 주문 획득·준비·시전 권한 모델

- 상태: 초안
- 작성일: 2026-08-03
- 관련 문서:
  - [`10. Grant Graph와 Capability 모델`](../../../../architecture/rules-content-grant-capability-model.md)
  - [`11. 규칙 콘텐츠 공통 실행 계약과 마법 처리 모델`](../../../../architecture/rules-content-execution-and-spell-contract.md)
  - [`ADR-0011`](../../../../decisions/ADR-0011-persistent-character-current-state.md)
  - [`ADR-0017`](../../../../decisions/ADR-0017-derived-fixed-grants-and-stored-selections.md)

## 1. 문서 목적

D&D의 주문 사용은 단순히 캐릭터가 주문 ID를 보유하는 것으로 표현할 수 없다.

같은 주문이라도 다음에 따라 실제 사용법이 달라진다.

- 어떤 직업, 종, 재주, 아이템 또는 효과에서 얻었는가
- 주문을 습득해야 하는가
- 주문책과 같은 저장소에 기록해야 하는가
- 긴 휴식 등 정해진 시점에 준비해야 하는가
- 항상 준비된 주문인가
- 주문 슬롯을 사용할 수 있는가
- 무료 시전 횟수나 아이템 충전을 사용하는가
- 어떤 능력치를 주문 시전 능력치로 사용하는가
- 상위 레벨로 시전할 수 있는가
- 의식 시전이 가능한가
- 물질 구성요소, 주문시전 도구와 집중 규칙이 변경되는가

캐릭터 전체에 하나의 `knownSpells`와 하나의 `preparedSpells` 목록만 두면 다중직업, 종 주문, 재주 주문, 아이템 주문과 같은 주문의 중복 출처를 정확히 처리할 수 없다.

이 문서는 다음을 분리한다.

```text
SpellDefinition
→ 주문 자체의 규칙

SpellcastingProfile
→ 하나의 출처가 제공하는 주문 사용 체계

SpellSelectionState
→ 플레이어가 습득·기록·준비로 선택한 결과

SpellCastRoute
→ 현재 이 주문을 실제로 시전할 수 있는 한 가지 방법

SpellRuntimeState
→ 슬롯, 무료 사용 횟수와 지속 중인 시전 상태
```

정확한 typed Luau 타입과 파일 경로는 구현명세에서 확정한다.

---

## 2. 핵심 원칙

### 2.1 주문 정의와 주문 사용 권한을 분리한다

`SpellDefinition`은 주문의 공식 규칙만 소유한다.

- 주문 레벨과 학파
- 시전 시간
- 사거리와 대상
- 구성요소
- 지속시간과 집중
- 판정과 효과
- 상위 레벨 변화
- 실행 레시피 또는 전용 처리기

캐릭터가 해당 주문을 어떤 능력치로, 어떤 자원으로, 어떤 준비 규칙에 따라 사용하는지는 `SpellDefinition`에 넣지 않는다.

### 2.2 주문 출처마다 SpellcastingProfile을 가진다

하나의 주문 사용 체계를 `SpellcastingProfile`로 표현한다.

예시:

```text
전사 3 / 마법사 2 캐릭터
├─ profile: wizard-class
├─ profile: species-spellcasting
├─ profile: magic-initiate-feat
└─ profile: equipped-wand
```

프로필은 표시용 직업 탭이 아니라 주문 획득과 시전 규칙의 권한 경계다.

### 2.3 같은 주문도 출처별로 별개의 시전 경로를 가진다

한 캐릭터가 같은 주문을 마법사 직업과 재주로 모두 얻을 수 있다.

이때 주문을 중복 복사하지는 않지만 다음은 분리해야 한다.

- 주문 시전 능력치
- 무료 사용 횟수
- 주문 슬롯 사용 가능 여부
- 허용되는 주문 슬롯 풀
- 고정 시전 레벨 또는 상위 레벨 시전 여부
- 구성요소 변경
- 출처 제거 시 권한 소멸

UI에서는 같은 주문을 한 항목으로 묶어 보여줄 수 있지만 실행 시에는 특정 `SpellCastRoute`를 선택해야 한다.

### 2.4 획득, 준비와 현재 시전 가능 여부를 혼합하지 않는다

다음은 서로 다른 상태다.

```text
eligible
→ 규칙상 선택하거나 기록할 수 있음

acquired
→ 습득, 주문책 기록 또는 고정 부여로 확보함

ready
→ 준비되었거나 항상 준비되어 사용 후보가 됨

castable
→ 지금 필요한 자원, 행동, 대상과 조건까지 충족함
```

`castable`은 영구 저장값이 아니라 현재 상태에서 계산되는 결과다.

### 2.5 고정 주문 권한은 파생하고 선택 결과만 저장한다

종, 하위직업과 특성이 자동으로 부여하는 주문은 출처 정의에서 파생한다.

플레이어가 선택한 습득 주문, 주문책에 추가한 주문과 준비 목록은 저장한다.

현재 사용할 수 있는 주문 버튼 목록은 저장하지 않는다.

---

## 3. 전체 구조

```text
RulesContentCatalog
├─ SpellDefinition
├─ SpellListDefinition
├─ SpellcastingProfileDefinition
├─ SpellSlotProgressionDefinition
├─ SpellPreparationPolicyDefinition
├─ SpellRepositoryPolicyDefinition
└─ SpellCastRuleModifierDefinition

Character Progression
├─ 직업, 하위직업, 종과 재주 선택
├─ SpellChoiceRecord
├─ SpellRepositoryState
├─ SpellPreparationSet
└─ ExceptionalSpellAccessRecord

Derived Runtime
├─ ResolvedSpellcastingProfile
├─ ResolvedSpellAccess
├─ SpellCastRoute
└─ SpellActionCapability

Persistent Runtime State
├─ SpellSlotPoolState
├─ SpellResourceState
├─ ConcentrationState
└─ 지속 중인 SpellEffectInstance
```

---

## 4. SpellcastingProfile

### 4.1 역할

`SpellcastingProfile`은 하나의 출처가 제공하는 주문 획득·준비·시전 규칙을 묶는다.

개념 필드 후보:

```text
profileDefinitionId
profileOccurrenceId
sourceChain
spellListQuery
castingAbilityRule
acquisitionPolicy
repositoryPolicy
readinessPolicy
slotAccessPolicy
freeCastPolicy
ritualPolicy
upcastPolicy
componentPolicy
focusPolicy
replacementPolicy
```

- `profileDefinitionId`: 콘텐츠 카탈로그의 프로필 정의 ID
- `profileOccurrenceId`: 이 캐릭터에게 발생한 실제 출처 인스턴스 ID
- `sourceChain`: 직업, 종, 재주 또는 아이템까지의 출처 사슬
- `spellListQuery`: 이 프로필에서 선택 가능한 주문 집합
- `castingAbilityRule`: 지능, 지혜, 매력 또는 출처 선택값
- `acquisitionPolicy`: 주문을 어떻게 확보하는가
- `repositoryPolicy`: 주문책 등 별도 저장소가 필요한가
- `readinessPolicy`: 항상 준비인지, 선택 준비인지
- `slotAccessPolicy`: 어떤 슬롯 풀을 사용할 수 있는가
- `freeCastPolicy`: 무료 시전 자원과 회복 규칙
- `ritualPolicy`: 의식 시전 조건
- `upcastPolicy`: 허용되는 시전 레벨
- `componentPolicy`: 구성요소의 변경 또는 면제
- `focusPolicy`: 허용되는 주문시전 도구
- `replacementPolicy`: 선택을 언제 교체할 수 있는가

### 4.2 프로필은 가능한 경우 파생한다

마법사 직업 레벨로 생기는 프로필은 직업 진행과 콘텐츠 정의에서 파생한다.

캐릭터 저장 데이터에 프로필 정의 사본을 넣지 않는다.

단, 같은 프로필 정의가 여러 번 발생할 수 있으므로 선택 기록은 안정적인 `profileOccurrenceId`에 연결한다.

예시:

```text
class.wizard:primary
feat.magic_initiate:level_4_choice
species.example:innate_spellcasting
item_instance_123:wand_spellcasting
```

정확한 ID 생성 방식은 구현명세에서 결정적으로 고정한다.

---

## 5. 주문 획득 정책

`acquisitionPolicy`는 주문이 프로필에 들어오는 방식을 정의한다.

### 5.1 Fixed

출처가 특정 주문을 자동 부여한다.

```text
종 특성
→ 특정 캔트립 자동 부여
```

고정 부여 결과는 출처에서 파생한다.

### 5.2 ChoiceKnown

정해진 수만큼 주문을 선택하여 습득한다.

```text
알려진 주문 수 공식
+ 주문 목록
→ 플레이어가 선택한 주문 저장
```

선택 결과는 `SpellChoiceRecord`에 저장한다.

### 5.3 FullListPrepared

레벨과 규칙이 허용하는 주문 목록 전체가 준비 후보가 된다.

캐릭터는 전체 목록을 복사해 저장하지 않고 실제 준비 선택만 저장한다.

### 5.4 Repository

주문책과 같은 저장소에 기록된 주문만 준비 후보가 된다.

저장소의 각 항목은 `spellId`와 획득 기록을 가진다. 주문 전체 정의는 복사하지 않는다.

### 5.5 GrantedSelection

재주나 특성이 제한된 후보군에서 주문을 선택하도록 한다.

예시:

```text
재주
→ 특정 직업 주문 목록에서 캔트립 2개 선택
→ 1레벨 주문 1개 선택
```

선택은 해당 재주의 `profileOccurrenceId`에 연결한다.

### 5.6 ItemProvided

아이템이 보유하거나 장착·조율된 동안 주문 경로를 제공한다.

이 주문은 캐릭터의 습득 주문 목록에 들어가지 않는다.

### 5.7 Temporary

상태 효과, 장면 효과, 변신 또는 DM 판정으로 일시 제공한다.

영구 성장 데이터에 저장하지 않고 효과 인스턴스의 수명에 연결한다.

### 5.8 Exceptional

DM이 일반 규칙 밖에서 영구 또는 장기 권한을 부여한다.

`ExceptionalSpellAccessRecord`로 출처와 이유를 명시적으로 저장한다.

---

## 6. SpellChoiceRecord

플레이어가 선택한 습득 주문을 저장한다.

```text
spellChoiceRecordId
profileOccurrenceId
choiceDefinitionId
sourceOccurrenceId
selectedSpellIds
selectionContext
rulesetId
sourcePackId
contentVersion
createdAt
revision
```

원칙:

- 전역 `knownSpells` 배열을 만들지 않는다.
- 같은 주문을 여러 프로필에서 선택할 수 있다.
- 주문 교체는 기존 기록 삭제와 새 기록 추가가 아니라 원자적 revision 변경으로 처리한다.
- 선택 당시 후보군과 선행 조건을 서버가 검증한다.
- 출처가 사라지면 기록을 즉시 파괴하기보다 비활성·복구 가능 상태로 둘 수 있다.

---

## 7. 주문 저장소

### 7.1 SpellRepository 추상화

주문책, 의식서와 유사한 구조를 범용 `SpellRepository`로 표현할 수 있다.

```text
SpellRepositoryState
├─ repositoryId
├─ repositoryDefinitionId
├─ ownerScope
├─ sourceOccurrenceId
├─ entries
└─ revision
```

항목 후보:

```text
SpellRepositoryEntry
├─ entryId
├─ spellId
├─ addedByEventId
├─ acquisitionMethod
├─ contentVersion
├─ status
└─ addedAt
```

### 7.2 저장소 항목은 주문 정의 사본이 아니다

주문책에는 주문 ID와 획득 근거만 저장한다.

설명, 피해식과 실행 로직은 `SpellDefinition`에서 조회한다.

### 7.3 소유 위치는 별도 결정한다

주문 저장소가 다음 중 어디에 귀속되는지는 후속 결정이 필요하다.

- 캐릭터 자체의 영구 데이터
- 인벤토리의 특정 아이템 인스턴스
- 캐릭터 소유 저장소와 물리 아이템 표현의 결합

어느 방식이든 준비 시스템은 `repositoryId`를 통해 접근하고 주문책 로직을 캐릭터 스키마에 하드코딩하지 않는다.

---

## 8. 준비 모델

### 8.1 ReadinessPolicy

주문이 `ready` 상태가 되는 방식을 정의한다.

```text
AlwaysReady
PreparedSelection
KnownIsReady
RepositoryPreparedSelection
ItemReady
TemporaryReady
```

- `AlwaysReady`: 출처가 항상 준비 상태로 부여
- `PreparedSelection`: 전체 후보군 중 준비 목록 선택
- `KnownIsReady`: 습득한 주문은 모두 즉시 사용 후보
- `RepositoryPreparedSelection`: 저장소 항목 중 준비 목록 선택
- `ItemReady`: 아이템 조건을 충족하는 동안 사용 후보
- `TemporaryReady`: 효과 수명 동안 사용 후보

### 8.2 SpellPreparationSet

플레이어가 실제로 준비한 주문만 저장한다.

```text
preparationSetId
profileOccurrenceId
selectedSpellIds
capacityContext
changedByEventId
rulesetId
contentVersion
revision
updatedAt
```

준비 가능한 최대 개수는 저장하지 않고 능력치, 레벨과 규칙에서 계산한다.

### 8.3 항상 준비된 주문은 준비 목록에 넣지 않는다

하위직업이나 특성이 항상 준비시키는 주문은 출처에서 파생한다.

이 주문은 일반 준비 한도를 소비하지 않는다는 규칙도 출처에 포함한다.

```text
ResolvedReadiness
├─ spellId
├─ readinessSource
├─ consumesPreparationCapacity
└─ active
```

### 8.4 준비 변경은 규칙 절차를 통과한다

일반 시트 편집으로 준비 목록을 임의 변경하지 않는다.

`SpellPreparationPolicyDefinition`이 다음을 지정한다.

- 변경 가능한 시점
- 필요한 휴식 또는 절차
- 한 번에 전부 재선택하는지 일부 교체인지
- 처리 중인 전투나 집중 효과가 변경을 막는지
- 취소와 확정 시점

UI는 임시 준비 초안을 만들 수 있지만 서버 확정 전에는 실제 주문 행동 목록을 바꾸지 않는다.

---

## 9. SpellCastRoute

### 9.1 역할

`SpellCastRoute`는 현재 한 주문을 시전할 수 있는 구체적인 방법이다.

```text
SpellCastRoute
├─ routeId
├─ spellId
├─ profileOccurrenceId
├─ accessSourceChain
├─ castingAbility
├─ baseCastLevel
├─ allowedCastLevels
├─ paymentOptions
├─ ritualOption
├─ componentOverrides
├─ focusOptions
├─ dcAndAttackFormula
└─ unavailableReasons
```

이 값은 파생 런타임 결과이며 영구 저장 원본이 아니다.

### 9.2 같은 주문에 여러 경로가 존재할 수 있다

예시:

```text
주문 A
├─ 마법사 경로
│  ├─ 지능 사용
│  ├─ 공유 주문 슬롯 사용
│  └─ 상위 레벨 시전 가능
└─ 재주 경로
   ├─ 지혜 사용
   ├─ 긴 휴식당 무료 1회
   └─ 규칙이 허용하면 주문 슬롯도 사용 가능
```

플레이어가 주문을 선택하면 시스템은 가능한 경로를 비교해 기본값을 추천할 수 있지만 서버는 실제 선택된 경로를 검증해야 한다.

### 9.3 UI 표시

기본적으로 주문은 이름별로 묶어 보여준다.

출처가 하나면 바로 실행하고, 여러 경로가 있거나 결과가 달라지면 출처·비용 선택 단계를 표시한다.

```text
주문 A
├─ 무료 시전 1회 사용
└─ 2레벨 주문 슬롯 사용
```

경로 차이가 규칙 결과에 영향을 주는데 자동으로 숨겨서 선택하면 안 된다.

---

## 10. 주문 슬롯과 자원

### 10.1 주문 슬롯은 주문 목록과 별개다

주문을 알고 있거나 준비했다고 해서 슬롯이 생기는 것은 아니다.

```text
SpellAccess
→ 어떤 주문을 사용할 수 있는가

SpellSlotPool
→ 어떤 레벨의 시전 비용을 얼마나 지불할 수 있는가
```

### 10.2 SpellSlotPool

개념 구조:

```text
SpellSlotPoolDefinition
├─ poolKind
├─ maximumFormula
├─ availableLevels
├─ recoveryPolicy
├─ sharingPolicy
└─ eligibleProfileQuery
```

현재 남은 슬롯은 영구 런타임 상태에 저장한다.

```text
SpellSlotPoolState
├─ poolId
├─ spentByLevel 또는 remainingByLevel
├─ revision
└─ lastRecoveryEventId
```

### 10.3 다중직업과 독립 슬롯 풀

공유 주문 슬롯과 별도 회복 규칙을 가진 슬롯을 하나의 전역 배열에 억지로 합치지 않는다.

여러 프로필이 같은 풀에 접근할 수도 있고, 특정 프로필만 별도 풀을 사용할 수도 있다.

### 10.4 무료 시전과 아이템 충전

무료 시전은 주문 슬롯을 가짜로 추가하지 않는다.

```text
paymentOptions
├─ spellSlotPool
├─ featureResource
├─ itemCharge
├─ ritualTime
└─ noResource
```

각 비용 경로는 공통 실행 트랜잭션에서 예약·확정·롤백된다.

### 10.5 시전 레벨

주문의 기본 레벨, 선택한 슬롯 레벨과 효과 계산 레벨을 구분한다.

```text
spellLevel
castLevel
scalingLevel
```

무료 시전이나 아이템 시전은 고정 `castLevel`을 가질 수 있다.

---

## 11. 의식 시전

의식 시전은 별도의 주문 사본이 아니라 `SpellCastRoute`의 다른 비용·시간 경로다.

`ritualPolicy`는 다음을 정한다.

- 주문에 의식 태그가 필요한가
- 준비되어 있어야 하는가
- 주문책에만 있으면 되는가
- 추가 시전 시간이 얼마인가
- 주문 슬롯을 소비하지 않는가
- 전투 중 사용 가능한가

같은 주문이라도 프로필에 따라 의식 시전 가능 여부가 다를 수 있다.

---

## 12. 구성요소와 주문시전 도구

구성요소는 단순 표시 텍스트가 아니라 실행 가능 조건에 포함한다.

```text
ComponentRequirement
├─ verbal
├─ somatic
├─ material
├─ materialCost
├─ consumed
└─ specificItemRequirement
```

`SpellCastRoute`는 출처와 특성에 따른 변경을 적용한다.

예시:

- 아이템이 구성요소를 대신함
- 주문시전 도구 사용 가능
- 특정 구성요소만 면제
- 값비싼 물질은 여전히 필요
- 침묵, 손 사용 불가 또는 물품 부족으로 시전 불가

구성요소 검사는 시전 확정 전 서버 검증 단계에서 수행한다.

---

## 13. 주문 준비와 시전 가능성 계산

현재 주문 행동 목록은 다음 순서로 계산한다.

```text
캐릭터 성장 출처와 장비·효과
→ ResolvedSpellcastingProfile
→ 고정·선택·저장소 주문 해석
→ 준비 규칙 적용
→ ResolvedSpellAccess
→ 현재 슬롯·자원·행동 조건 적용
→ SpellCastRoute 목록
→ 주문 UI
```

매 프레임 전체 주문 카탈로그를 재검색하지 않는다.

다음 변경 시 영향받는 프로필만 재계산한다.

- 레벨과 직업 변경
- 주문 선택과 교체
- 주문책 항목 추가·제거
- 준비 목록 확정
- 장비 장착·해제·조율
- 무료 시전 자원 회복·소비
- 상태 효과 시작·종료
- 출처 팩 마이그레이션

슬롯 한 개 소비 때 전체 주문 권한을 재구성할 필요는 없다. 경로의 현재 비용 가능 상태만 갱신한다.

---

## 14. 저장 구분

### 14.1 성장 원본에 저장

- 플레이어가 선택한 습득 주문
- 재주와 종 선택에서 선택한 주문
- 주문 교체 기록의 현재 결과
- 하위직업 등 출처 선택
- DM의 예외 주문 권한

### 14.2 캐릭터 영구 상태에 저장

- 주문 저장소 항목
- 확정된 준비 목록
- 저장소와 준비 목록 revision

### 14.3 persistent runtime state에 저장

- 현재 남은 주문 슬롯
- 무료 시전 사용 횟수
- 아이템 충전 상태는 해당 아이템 인스턴스 상태
- 현재 집중 상태
- 휴식을 넘어 유지되는 주문 효과

### 14.4 씬 또는 전투에 저장

- 장면에 생성된 주문 영역과 소환체
- 현재 전투에서만 유효한 주문 효과
- 시전 중인 긴 행동 또는 반응 창
- 주문으로 공개된 장면 정보

### 14.5 저장하지 않음

- 현재 시전 가능한 주문 버튼 목록
- `SpellCastRoute` 캐시를 권위 원본으로 사용
- 자동으로 부여되는 항상 준비 주문 목록
- 최종 주문 공격 보너스와 주문 내성 DC
- 주문 정의 전체 사본

---

## 15. 검증 규칙

서버는 최소한 다음을 검증한다.

- `profileOccurrenceId`가 현재 캐릭터의 유효한 출처에서 파생되는가
- 선택한 주문이 해당 프로필의 후보군에 포함되는가
- 주문 레벨, 개수와 교체 규칙을 충족하는가
- 준비한 주문이 습득·저장소·전체 후보군 중 하나에서 실제로 접근 가능한가
- 항상 준비 주문을 일반 준비 한도에 잘못 포함하지 않았는가
- 선택한 시전 경로가 현재 활성 상태인가
- 해당 프로필이 선택한 슬롯 풀이나 자원을 사용할 수 있는가
- 시전 레벨과 상위 레벨 시전이 허용되는가
- 구성요소와 주문시전 도구 조건을 충족하는가
- 행동 경제, 사거리, 대상과 집중 조건을 충족하는가
- 중복 요청에서 슬롯과 무료 횟수가 두 번 소비되지 않는가

클라이언트가 보낸 `known`, `prepared`, `castable`, 주문 DC와 비용 가능 여부를 신뢰하지 않는다.

---

## 16. 오류와 출처 제거

### 16.1 콘텐츠 팩 또는 주문 정의 누락

선택 기록과 저장소 항목을 삭제하지 않는다.

- 읽기 전용 누락 상태로 표시
- 시전 경로 생성 중지
- 필요한 출처 팩과 버전 안내
- 마이그레이션 또는 복구 가능 상태 유지

### 16.2 프로필 출처 제거

직업 재구성, 재주 제거 또는 아이템 해제로 프로필이 사라질 수 있다.

- 파생된 시전 경로 제거
- 해당 프로필의 준비 목록 비활성화
- 규칙에 따라 선택 기록을 보존하거나 정식 재구성 절차에서 정리
- 이미 지속 중인 효과는 효과 규칙에 따라 종료 또는 유지

### 16.3 저장 중 충돌

준비 목록과 주문책은 revision 기반으로 변경한다.

오래된 클라이언트가 최신 준비 목록을 덮어쓰지 못하게 한다.

---

## 17. UI 원칙

### 17.1 주문 목록

사용자는 다음 상태를 구분해 볼 수 있어야 한다.

- 습득함
- 주문책에 있음
- 준비함
- 항상 준비됨
- 현재 시전 가능
- 현재 자원 부족
- 출처 또는 조건 때문에 비활성

### 17.2 출처 표시

같은 주문에 여러 출처가 있으면 출처와 사용법을 확인할 수 있어야 한다.

```text
주문 A
출처:
- 마법사: 지능, 주문 슬롯
- 재주: 지혜, 무료 사용 1회
```

### 17.3 준비 UI

- 준비 후보와 준비 결과를 분리
- 항상 준비된 주문은 별도 표시
- 준비 한도 계산 근거 표시
- 변경을 초안으로 만든 뒤 한 번에 확정
- 현재 규칙상 변경할 수 없는 이유 표시

### 17.4 시전 UI

주문 선택 후 필요한 경우 다음 순서로 진행한다.

```text
시전 경로 선택
→ 시전 레벨과 비용 선택
→ 모드 선택
→ 대상·영역 선택
→ 확인
```

단일 경로이고 선택이 없는 경우 중간 단계를 자동 생략할 수 있다.

---

## 18. 기준 사례

### 18.1 습득 주문형 직업

```text
직업 레벨
→ 선택 가능한 주문 수 파생
→ SpellChoiceRecord 저장
→ KnownIsReady
→ 공유 주문 슬롯으로 CastRoute 생성
```

### 18.2 전체 목록 준비형 직업

```text
직업 레벨과 주문 목록
→ 준비 후보 전체 파생
→ SpellPreparationSet 저장
→ 항상 준비 주문 합성
→ 주문 슬롯으로 CastRoute 생성
```

### 18.3 주문책 준비형 직업

```text
직업 시작 주문 선택
+ 게임 중 주문책 기록
→ SpellRepositoryState
→ 저장소 항목 중 준비 선택
→ 준비 주문의 CastRoute 생성
→ 프로필 규칙에 따른 의식 경로 추가
```

### 18.4 종 주문

```text
종 특성
→ 고정 또는 선택 주문 파생
→ AlwaysReady
→ 무료 시전 Resource
→ 규칙이 허용하면 슬롯 경로도 추가
```

### 18.5 주문을 부여하는 재주

```text
FeatDefinition
→ 별도 SpellcastingProfile
→ 선택 주문은 SpellChoiceRecord 저장
→ 재주가 정한 시전 능력치
→ 무료 시전과 슬롯 사용 경로를 각각 생성
```

### 18.6 마법 아이템

```text
장착·조율된 아이템 인스턴스
→ ItemProvided profile
→ 아이템 충전 상태 사용
→ 캐릭터 습득·준비 목록에는 들어가지 않음
```

### 18.7 같은 주문의 중복 출처

```text
spell.example
├─ profile.wizard
└─ profile.magic_initiate

UI: 주문 하나로 묶음
실행: 두 SpellCastRoute 중 선택
로그: 선택한 출처와 비용 기록
```

---

## 19. 명시적인 비목표

- 캐릭터 전체에 전역 `knownSpells` 하나만 두지 않는다.
- 캐릭터 전체에 전역 `preparedSpells` 하나만 두지 않는다.
- 주문 ID만 보고 시전 능력치와 자원 비용을 추측하지 않는다.
- 항상 준비된 주문을 일반 준비 선택 목록에 복사하지 않는다.
- 아이템 주문을 캐릭터의 습득 주문으로 변환하지 않는다.
- 무료 시전을 가짜 주문 슬롯으로 표현하지 않는다.
- 주문 슬롯 상태를 직업 데이터 안에 직접 넣지 않는다.
- 같은 주문의 여러 출처를 하나의 임의 출처로 합치지 않는다.
- 준비 여부와 현재 시전 가능 여부를 같은 boolean으로 처리하지 않는다.
- 클라이언트가 계산한 최종 주문 목록과 DC를 신뢰하지 않는다.

---

## 20. 후속 결정이 필요한 항목

1. `SpellcastingProfile`을 출처별 별도 프로필로 두고 같은 주문의 여러 `SpellCastRoute`를 허용하는 원칙의 최종 확정
2. 주문책을 캐릭터 소유 저장소로 둘지 실제 아이템 인스턴스에 연결할지
3. 다중직업 공유 주문 슬롯과 독립 슬롯 풀의 정확한 결합 규칙
4. 준비 변경을 휴식 흐름 안에서 어떤 UI와 트랜잭션으로 처리할지
5. 주문 선택과 교체의 레벨업 기록 구조
6. 항상 준비 주문과 준비 한도의 결합 규칙을 데이터로 표현하는 정확한 방식
7. 의식 시전의 프로필별 정책
8. 같은 주문에 여러 시전 경로가 있을 때 기본 경로 선택 UX
9. 주문 목록 후보군을 고정 ID 집합과 태그 질의 중 어떻게 배포할지
10. 첫 주문 시스템 수직 검증에 포함할 직업·종·재주·아이템 사례

다음 논의에서는 먼저 **주문 출처마다 `SpellcastingProfile`을 두고, 같은 주문이 여러 출처를 가질 경우 서로 다른 `SpellCastRoute`를 생성하는가**를 확정한다.
