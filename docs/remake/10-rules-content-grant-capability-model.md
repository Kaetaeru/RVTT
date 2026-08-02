# 10. 규칙 콘텐츠 Grant Graph와 실행 Capability 모델

- 상태: 초안
- 작성일: 2026-08-03
- 관련 문서:
  - [`ADR-0001`](decisions/ADR-0001-authored-rules-content.md)
  - [`ADR-0002`](decisions/ADR-0002-integrated-character-progression.md)
  - [`ADR-0003`](decisions/ADR-0003-ruleset-source-packs-localization.md)
  - [`ADR-0016`](decisions/ADR-0016-player-selected-ability-score-generation.md)
  - [`AGENTS.md`](../../AGENTS.md)

## 1. 문서 목적

종, 배경, 직업, 하위직업, 재주와 아이템은 서로 다른 방식으로 캐릭터에게 능력을 부여한다.

부여되는 결과도 단순하지 않다.

- 고정 특성
- 여러 후보 중 하나를 고르는 재주나 전투 방식
- 레벨에 따라 강화되는 특성
- 행동, 보너스 행동과 반응
- 공격이나 내성 굴림에 끼어드는 조건부 효과
- 짧은 휴식 또는 긴 휴식으로 회복되는 자원
- 주문 습득, 준비, 항상 준비와 무료 시전
- 무기별 웨폰 마스터리 선택
- 추가 공격처럼 기존 행동 규칙을 변경하는 효과
- 격노, 암습과 메타매직처럼 전용 실행 흐름이 필요한 효과

이 내용을 종, 배경과 직업 데이터 안에 각각 다른 구조로 직접 넣으면 캐릭터 생성, 레벨업, 시트, 전투와 저장이 서로 다른 규칙을 사용하게 된다.

이 문서는 다음 흐름을 하나의 공통 계약으로 정형화한다.

```text
획득 출처
→ GrantInstruction
→ Grant Graph 해석
→ ResolvedGrant
→ Capability 구성
→ 시트, 행동 UI와 규칙 엔진에서 사용
```

정확한 typed Luau 타입과 실제 파일 경로는 구현명세에서 확정한다. 이 문서는 제품 데이터 경계와 확장 원칙을 우선 정의한다.

---

## 2. 핵심 원칙

### 2.1 획득 출처와 획득 결과를 분리한다

종, 배경, 직업과 재주는 다른 콘텐츠를 부여하는 **출처**다.

부여되는 특성, 주문, 숙련과 실행 능력은 독립된 콘텐츠 정의다.

```text
BackgroundDefinition
└─ feat ID를 부여

FeatDefinition
└─ 선택, 행동, 패시브와 주문 권한을 부여
```

배경 안에 재주의 전체 데이터와 실행 로직을 복사하지 않는다.

### 2.2 캐릭터 저장 데이터에 콘텐츠 정의를 복사하지 않는다

캐릭터는 다음을 저장한다.

- 어떤 종, 배경, 직업 레벨과 재주를 선택했는가
- 선택형 부여에서 무엇을 골랐는가
- 규칙 외 보상이나 DM 예외로 무엇을 받았는가
- 각 선택이 어느 성장 단계와 출처에서 발생했는가

특성, 주문과 재주의 전체 규칙 정의는 `RulesContentCatalog`가 소유한다.

### 2.3 결정적으로 다시 만들 수 있는 고정 획득은 파생한다

직업 레벨을 보면 항상 얻는 고정 특성을 캐릭터 저장 데이터에 중복해서 나열하지 않는 방향을 기본으로 한다.

```text
저장된 전사 레벨
+ 해당 버전의 ClassDefinition
→ 고정 특성 목록 재구성
```

반면 다음은 원본 선택 데이터이므로 저장해야 한다.

- 전투 방식 선택
- 웨폰 마스터리 대상 무기 선택
- 재주 선택
- 주문 선택
- 하위직업 선택
- 선택형 숙련과 언어
- DM이 직접 부여한 예외 콘텐츠

이 원칙은 이 문서의 핵심 제안이며 후속 결정에서 최종 확정한다.

### 2.4 실행 가능한 결과는 Capability로 통일한다

특성의 이름이나 출처가 아니라 실제로 게임에 주는 기능을 `Capability`로 표현한다.

예를 들어 전사 특성, 종 특성과 재주가 모두 반응 행동을 부여할 수 있다. 출처는 다르지만 행동 시스템에는 같은 종류의 반응 Capability로 전달한다.

### 2.5 모든 규칙을 하나의 범용 데이터로 강제하지 않는다

공통 구조로 표현 가능한 피해, 회복, 자원, 숙련, 조건, 트리거와 수치 보정은 공통 프리미티브를 사용한다.

추가 공격, 행동 연쇄, 암습, 메타매직처럼 고유한 규칙은 안정된 확장 계약을 통해 전용 처리기를 사용한다.

전용 처리기도 공통 실행 트랜잭션, 자원 소비, 서버 검증, 로그와 롤백을 우회할 수 없다.

---

## 3. 전체 구조

```text
RulesContentCatalog
├─ 획득 출처
│  ├─ SpeciesDefinition
│  ├─ BackgroundDefinition
│  ├─ ClassDefinition
│  ├─ SubclassDefinition
│  ├─ FeatDefinition
│  └─ ItemDefinition
│
├─ 부여 가능한 콘텐츠
│  ├─ FeatureDefinition
│  ├─ FeatDefinition
│  ├─ SpellDefinition
│  ├─ ProficiencyDefinition
│  ├─ WeaponMasteryPropertyDefinition
│  └─ ResourceDefinition
│
└─ 실행 구성 요소
   ├─ ActionCapability
   ├─ PassiveModifierCapability
   ├─ TriggerCapability
   ├─ ResourceCapability
   ├─ ProficiencyCapability
   ├─ SpellAccessCapability
   ├─ ChoiceCapacityCapability
   ├─ RuleOverrideCapability
   └─ EffectSourceCapability
```

캐릭터 처리 흐름:

```text
Character progression source
→ Grant Graph Resolver
→ 출처와 선택 결과 검증
→ ResolvedGrant 목록
→ Capability Compiler
→ Character Capability Set
→ 시트, 행동 UI, 공격·주문·휴식·전투 시스템
```

`Character Capability Set`은 캐릭터 저장 원본이 아니다. 성장 원본, 장비와 활성 효과에서 다시 만들 수 있는 파생 런타임 결과다.

---

## 4. 획득 출처 Definition

### 4.1 SpeciesDefinition

종의 기본 정보와 다음 부여 지시를 제공한다.

- 크기와 이동 관련 기본 규칙
- 감각
- 언어 또는 언어 선택
- 종 특성
- 종이 부여하는 주문 권한
- 선택형 계통 또는 세부 유형

종 전용 실행 로직을 캐릭터 데이터에 직접 넣지 않는다.

### 4.2 BackgroundDefinition

배경은 다음을 부여할 수 있다.

- 능력치 영구 보정 선택
- 숙련
- 도구 숙련
- 시작 장비 또는 화폐 선택
- 재주

배경이 부여하는 재주는 `FeatDefinition`의 ID를 참조한다.

### 4.3 ClassDefinition

직업은 레벨별 진행표를 가진다.

```text
ClassDefinition
├─ 기본 숙련과 히트 다이스 규칙
├─ 레벨별 GrantInstruction
├─ 하위직업 선택 시점
├─ 주문 진행 규칙
├─ 자원 성장 규칙
└─ 다중직업 진입과 획득 규칙
```

같은 직업 특성이 상위 레벨에서 강화되면 별도 특성을 무조건 중복 부여하지 않고 다음 중 규칙에 맞는 방식을 선택한다.

- 기존 Feature의 단계가 상승
- 기존 Capability의 파라미터가 스케일됨
- 기존 Feature를 새 Feature로 교체
- 추가 Feature가 기존 Feature를 확장

### 4.4 SubclassDefinition

하위직업은 부모 직업 진행 위에 GrantInstruction을 추가한다.

부모 직업 데이터를 복제하지 않는다.

### 4.5 FeatDefinition

재주는 단순한 패시브 특성이 아니라 하나 이상의 선택과 기능을 묶은 획득 패키지다.

```text
FeatDefinition
├─ prerequisites
├─ repeatability
├─ choices
└─ grants
   ├─ 능력치 영구 보정
   ├─ 숙련
   ├─ 행동 또는 반응
   ├─ 패시브와 트리거
   ├─ 자원
   └─ 주문 권한
```

### 4.6 ItemDefinition

아이템은 소유만으로 기능을 부여하는지, 장착·조율·활성 상태일 때만 기능을 부여하는지 명시한다.

아이템이 부여한 Capability에는 해당 아이템 인스턴스가 출처로 연결된다.

---

## 5. GrantInstruction 종류

모든 출처가 자신의 고유 필드 이름으로 능력을 부여하지 않는다. 다음 공통 GrantInstruction 계열을 사용한다.

### 5.1 FixedGrant

조건을 충족하면 지정된 콘텐츠를 자동으로 부여한다.

```text
전사 특정 레벨 도달
→ feature.fighter.second_wind 부여
```

### 5.2 ChoiceGrant

정해진 후보군에서 지정된 수만큼 선택한다.

```text
전투 방식 후보군
→ 1개 선택
```

후보군은 긴 ID 목록 또는 콘텐츠 태그·질의로 정의할 수 있다. 최종 후보는 규칙 세트와 출처 팩 버전에 따라 결정적으로 계산되어야 한다.

### 5.3 ScaledGrant

직업 레벨, 전체 레벨, 숙련 보너스 또는 특정 Feature 단계에 따라 파라미터가 변한다.

예시:

- 사용 횟수 증가
- 피해 주사위 증가
- 선택 가능한 웨폰 마스터리 수 증가
- 대상 수 증가

현재 수치를 캐릭터 성장 원본에 직접 저장하지 않고 스케일 규칙에서 파생한다.

### 5.4 ConditionalGrant

장착 상태, 선택, 하위직업, 주문 준비 또는 다른 조건이 참일 때만 활성화한다.

조건이 거짓이 되면 획득 기록을 삭제하는 대신 ResolvedGrant를 비활성 상태로 둘 수 있다.

### 5.5 ReplaceableGrant

허용된 성장 절차에서 이전 선택을 다른 선택으로 교체할 수 있다.

예시:

- 레벨업 때 허용되는 주문 교체
- 규칙이 허용하는 웨폰 마스터리 대상 변경
- 기존 전투 방식 교체

교체는 이전 기록 삭제와 새 기록 추가가 따로 일어나지 않고 하나의 원자적 선택 변경으로 처리한다.

### 5.6 NestedGrant

부여된 콘텐츠가 다시 다른 콘텐츠와 선택을 부여한다.

```text
배경
→ 재주 부여
→ 해당 재주가 주문 선택권 부여
→ 선택한 SpellAccessCapability 생성
```

Grant Graph Resolver는 순환 참조를 탐지하고 무한 부여를 거부해야 한다.

### 5.7 ExceptionalGrant

일반 성장 규칙 밖에서 DM 보상, 서사 사건, 데이터 복구 또는 홈브루 처리로 부여한다.

이 항목은 출처에서 결정적으로 파생되지 않으므로 캐릭터에 명시적으로 저장한다.

---

## 6. GrantInstruction 공통 계약 후보

개념적인 공통 필드:

```text
grantId
kind
version
targetContentId 또는 selectionPool
count 또는 scalingRule
prerequisites
activationCondition
replacementPolicy
stackingKey
stackingPolicy
parameters
handlerId
```

- `grantId`: 해당 출처 안에서 안정적으로 유지되는 ID
- `kind`: fixed, choice, scaled, conditional, replaceable, nested 등
- `targetContentId`: 직접 부여할 콘텐츠
- `selectionPool`: 선택 가능한 콘텐츠 집합
- `prerequisites`: 선택 또는 획득 가능 조건
- `activationCondition`: 획득은 유지하되 현재 기능 활성 여부를 결정
- `replacementPolicy`: 언제 어떤 절차로 선택을 바꿀 수 있는지
- `stackingKey`: 같은 효과끼리 충돌을 판단하는 키
- `stackingPolicy`: 합산, 최대값, 교체와 같은 처리
- `parameters`: 출처가 전달하는 안전한 구성값
- `handlerId`: 공통 구성만으로 표현할 수 없는 전용 처리기

표시 문자열과 번역된 이름을 식별자로 사용하지 않는다.

---

## 7. 캐릭터에 저장하는 데이터

### 7.1 ProgressionSourceRecord

캐릭터가 어떤 성장 출처를 가지고 있는지 저장한다.

예시:

- 종
- 배경
- 직업별 레벨과 레벨 획득 순서
- 하위직업
- 직접 선택한 재주

### 7.2 ChoiceRecord

선택형 Grant의 결과를 저장한다.

개념 필드:

```text
choiceRecordId
choiceDefinitionId
sourceOccurrenceId
selectedContentIds
selectedValues
rulesetId
sourcePackId
contentVersion
createdAt
revision
```

`sourceOccurrenceId`는 같은 선택 정의가 여러 번 발생해도 어느 레벨, 재주 또는 출처에서 나온 선택인지 구분한다.

예시:

```text
전사 레벨 진행의 웨폰 마스터리 선택 슬롯
→ longsword와 longbow 선택
```

### 7.3 ExceptionalGrantRecord

DM이 일반 진행 밖에서 부여한 콘텐츠를 저장한다.

```text
exceptionalGrantId
contentId
sourceEventId 또는 reason
parameters
contentVersion
status
createdBy
createdAt
```

콘텐츠 전체 규칙은 복사하지 않는다.

### 7.4 저장하지 않는 데이터

다음은 파생 가능하므로 권위 원본으로 저장하지 않는다.

- 직업 레벨에서 자동으로 얻는 고정 Feature 목록
- 최종 Capability 목록
- 현재 활성화된 행동 버튼 목록
- 추가 공격 횟수 같은 계산 결과
- 장착 장비로 현재 활성화된 아이템 Capability 목록
- 번역된 이름과 설명

캐시는 둘 수 있지만 원본 revision이 달라지면 폐기하고 재구성해야 한다.

---

## 8. ResolvedGrant와 출처 사슬

Grant Graph Resolver는 최종 부여 결과마다 전체 출처 사슬을 보존한다.

```text
ResolvedGrant
├─ contentId
├─ sourceChain
├─ effectiveParameters
├─ definitionVersions
├─ stackingKey
├─ active
└─ inactiveReason
```

출처 사슬 예시:

```text
background.sage
→ feat.magic_initiate
→ choice.magic_initiate.cantrip.1
→ spell.example_cantrip
```

이 정보는 다음에 사용한다.

- 캐릭터 시트의 출처 표시
- 선택 교체와 재구성
- 출처 제거 시 종속 콘텐츠 정리
- 콘텐츠 팩 누락 진단
- 저장 마이그레이션
- 규칙 오류 로그

`ResolvedGrant`는 캐시이며 캐릭터 영구 저장의 주 원본이 아니다.

---

## 9. Capability 종류

### 9.1 ActionCapability

플레이어가 직접 선택해 실행하는 행동이다.

필요 정보 후보:

- 행동 경제
- 사용 가능 시점
- 대상 방식과 사거리
- 자원 비용
- 실행 정의 또는 handlerId
- UI 표시 조건

### 9.2 PassiveModifierCapability

항상 또는 조건부로 파생 수치와 규칙 계산을 바꾼다.

예시:

- AC 보정
- 이동속도 보정
- 피해 보정
- 공격 횟수 보정
- 특정 판정의 이점 또는 불리점

### 9.3 TriggerCapability

규칙 이벤트가 발생했을 때 자동 또는 선택적으로 반응한다.

예시:

- 공격 명중 후
- 능력 판정 실패 후
- 내성 굴림 실패 후
- 피해를 받기 전 또는 후
- 턴 시작과 종료
- 휴식 완료
- 장비 장착과 해제

트리거는 자유 문자열 이벤트가 아니라 중앙에서 정의한 타입 있는 규칙 이벤트와 실행 단계에 연결한다.

### 9.4 ResourceCapability

사용 횟수, 충전과 회복 규칙을 제공한다.

```text
resourceId
maximumFormula
recoveryPolicy
minimum
sharingKey
```

여러 Feature가 같은 `resourceId`를 소비할 수 있다.

### 9.5 ProficiencyCapability

기술, 내성, 무기, 방어구, 도구와 언어 숙련을 부여한다.

숙련과 전문화처럼 단계가 있는 경우 별도 숙련 등급과 중첩 정책을 가진다.

### 9.6 SpellAccessCapability

주문 자체와 그 주문을 사용할 권한을 분리한다.

최소한 다음을 표현해야 한다.

- `spellId`
- 획득 출처
- 시전 능력치
- 습득, 준비, 항상 준비 또는 일시 제공 여부
- 주문 슬롯 사용 가능 여부
- 무료 시전 횟수와 회복
- 주문 구성요소와 집중 규칙의 변경 여부
- 상위 레벨 시전 가능 여부

같은 주문이라도 직업, 종과 재주로 얻었을 때 다른 SpellAccessCapability를 가질 수 있다.

### 9.7 ChoiceCapacityCapability

현재 또는 다음 성장 절차에서 선택할 수 있는 슬롯과 선택 조건을 제공한다.

웨폰 마스터리처럼 선택 개수가 레벨에 따라 증가하고 대상 콘텐츠에 연결되는 구조에 사용한다.

### 9.8 RuleOverrideCapability

기존 공통 규칙의 결과나 절차를 명시적으로 변경한다.

예시:

- 공격 행동의 공격 횟수 변경
- 행동 경제에 추가 사용 기회 제공
- 특정 자원 소비 방식 변경
- 무기 마스터리 적용 방식 확장

임의의 코드 패치가 아니라 등록된 규칙 확장점과 우선순위를 사용한다.

### 9.9 EffectSourceCapability

피해, 회복, 상태, 이동, 소환과 영역 효과의 출처가 된다.

행동, 주문과 트리거가 실제 효과를 적용할 때 공통 효과 엔진에 전달한다.

---

## 10. Feature, Feat와 Spell의 관계

### FeatureDefinition

직업, 하위직업 또는 종에서 부여하는 이름 있는 규칙 묶음이다.

Feature는 다음 중 하나 이상을 제공할 수 있다.

- Capability
- 다른 콘텐츠 Grant
- 선택
- 스케일 규칙
- 전용 처리기

### FeatDefinition

플레이어가 선택 가능한 독립 콘텐츠이며 Feature와 비슷한 기능을 부여하지만 다음 정보가 추가로 중요하다.

- 선택 가능 조건
- 반복 선택 가능 여부
- 재주 분류
- 능력치 증가 선택
- 다른 재주와의 배타 관계

Feat를 단순히 Feature ID 목록으로 축소하지 않는다.

### SpellDefinition

주문 자체의 규칙 정의다.

- 주문 레벨과 학파
- 시전 시간
- 대상과 사거리
- 구성요소
- 지속시간과 집중
- 판정과 효과
- 상위 레벨 변화
- 실행 수준과 handlerId

캐릭터가 주문을 어떻게 얻고 사용할 수 있는지는 SpellDefinition이 아니라 SpellAccessCapability가 결정한다.

---

## 11. 웨폰 마스터리 기준 사례

웨폰 마스터리는 다음 세 요소를 분리해야 한다.

```text
WeaponDefinition
→ 해당 무기의 기본 masteryPropertyId

WeaponMasteryPropertyDefinition
→ 마스터리 속성의 규칙과 공격 파이프라인 연결

캐릭터의 Weapon Mastery Feature
→ 어떤 무기에 마스터리를 적용할 수 있는지 선택권 제공
```

### 11.1 무기 정의

각 무기는 자신의 기본 마스터리 속성을 콘텐츠 ID로 참조한다.

```text
item.weapon.example
└─ masteryPropertyId: mastery.example
```

마스터리 효과의 전체 실행 로직을 무기마다 복사하지 않는다.

### 11.2 직업 특성

전사의 웨폰 마스터리 Feature는 다음을 부여한다.

```text
ChoiceCapacityCapability
├─ 선택 가능한 대상: 조건에 맞는 무기
├─ 선택 개수: 직업 진행에 따라 파생
├─ 교체 가능 시점
└─ 선택 결과의 sourceOccurrenceId
```

캐릭터에는 선택한 `weaponId`를 저장한다. 선택 당시 마스터리 효과 사본을 저장하지 않는다.

### 11.3 공격 시 적용

공격 파이프라인은 다음을 확인한다.

```text
사용한 무기
→ 캐릭터가 해당 무기를 마스터리 대상으로 선택했는가
→ 무기의 masteryPropertyId 조회
→ 속성별 Trigger 또는 RuleOverride 적용 가능 여부 검사
→ 규칙에 맞는 시점에 실행 또는 선택 요청
```

마스터리 속성이 바뀌거나 추가되어도 전사 캐릭터 스키마에 새 필드를 추가하지 않는다.

### 11.4 전사 전용 확장

상위 전사 특성이 마스터리 적용 방식을 바꾸는 경우에는 웨폰 마스터리 코어를 클래스 이름으로 분기하지 않는다.

```text
feature.fighter.example_mastery_extension
→ RuleOverrideCapability
→ 등록된 WeaponMastery 확장점에 적용
```

이를 통해 다른 직업, 재주 또는 아이템이 같은 확장점을 사용할 수 있다.

---

## 12. 전사 특성 기준 사례

### 12.1 전투 방식

```text
Class level source
→ ChoiceGrant
→ fighting-style 후보군에서 선택
→ 선택한 Feat 또는 Feature 부여
```

전투 방식이 재주로 정의되어 있다면 직업 데이터 안에 효과를 복사하지 않고 해당 Feat ID를 부여한다.

### 12.2 재기의 바람 계열 자원과 행동

하나의 Feature가 다음을 함께 부여할 수 있다.

```text
ResourceCapability
+ ActionCapability
+ 회복 규칙
```

현재 남은 사용 횟수는 캐릭터의 persistent runtime state에 저장한다. 최대 사용 횟수는 직업 레벨과 Feature 정의에서 계산한다.

### 12.3 같은 자원을 사용하는 후속 특성

후속 전사 특성이 능력 판정 실패 뒤 재기의 바람 자원을 소비하게 한다면 새 자원을 만들지 않는다.

```text
TriggerCapability
→ 실패 이벤트 감지
→ 기존 resource.fighter.second_wind 소비 선택
→ 전용 효과 적용
```

여러 Feature가 하나의 자원을 공유할 수 있어야 한다.

### 12.4 행동 연쇄 계열

행동 연쇄는 단순히 행동창에 버튼 하나를 추가하는 것으로 끝나지 않는다.

필요한 구성:

```text
ActionCapability
+ ResourceCapability
+ RuleOverrideCapability(action economy)
+ 현재 턴 사용 상태
```

실행 시 공통 행동 경제 시스템이 추가 행동 사용 가능 상태를 생성한다. 전사 전용 모듈이 전투 런타임 값을 직접 임의 수정하지 않는다.

### 12.5 추가 공격

추가 공격은 공격 행동을 여러 개 복제하지 않는다.

```text
PassiveModifierCapability
→ attackAction.attackCount 규칙 수정
```

다중직업과 여러 출처에서 추가 공격 계열 효과가 생겼을 때는 명시적인 중첩 정책을 적용한다.

### 12.6 불굴 계열

```text
TriggerCapability: 내성 굴림 실패 후
+ ResourceCapability
+ 재굴림 또는 결과 변경 실행
```

트리거 시점, 중복 반응 방지와 자원 소비 순서를 공통 판정 트랜잭션 안에서 처리한다.

---

## 13. 중첩과 충돌 정책

Capability는 같은 이름이라는 이유로 자동 중첩하지 않는다.

지원할 정책 후보:

- `unique`: 같은 stackingKey는 하나만 활성
- `additive`: 값을 합산
- `maximum`: 가장 높은 값만 사용
- `replace`: 우선순위가 높은 정의가 교체
- `exclusive_group`: 같은 그룹에서 하나만 선택
- `custom`: 등록된 전용 결합 처리기 사용

결합 순서는 출처 팩 로딩 우연에 의존하지 않고 다음 정보로 결정적으로 계산해야 한다.

- 규칙 세트
- 명시적 우선순위
- 출처 관계
- 콘텐츠 버전
- stacking policy

`Extra Attack`처럼 일반 합산이 잘못되는 규칙은 반드시 명시적인 stackingKey와 정책을 가진다.

---

## 14. 타입 있는 규칙 이벤트

TriggerCapability가 임의 문자열 이벤트를 구독하게 하지 않는다.

중앙 규칙 엔진이 제공하는 이벤트와 단계 후보:

```text
ActionDeclared
TargetingCompleted
BeforeAttackRoll
AfterAttackRoll
AttackHit
AttackMissed
BeforeDamage
AfterDamage
AbilityCheckFailed
SavingThrowFailed
TurnStarted
TurnEnded
ShortRestCompleted
LongRestCompleted
ItemEquipped
ItemUnequipped
ConditionApplied
ConditionRemoved
```

각 이벤트는 허용된 데이터 계약과 수정 가능한 범위를 가진다.

예를 들어 `BeforeDamage` 처리기가 캐릭터 인벤토리나 씬 데이터를 무제한 변경할 수 있게 하지 않는다.

이벤트 목록과 정확한 단계는 전투·행동 명세에서 확정한다.

---

## 15. 전용 처리기 경계

공통 프리미티브로 표현하기 어려운 콘텐츠는 `handlerId`로 전용 처리기를 참조할 수 있다.

전용 처리기가 받을 수 있는 것은 제한된 규칙 컨텍스트다.

```text
RuleExecutionContext
├─ actor와 target 참조
├─ 검증된 콘텐츠와 ResolvedGrant
├─ 현재 행동·굴림 트랜잭션
├─ 자원 요청 인터페이스
├─ 효과 적용 인터페이스
├─ 선택과 DM 승인 인터페이스
├─ 구조화된 로그
└─ 취소와 롤백
```

전용 처리기는 다음을 직접 소유하지 않는다.

- RemoteEvent
- 클라이언트 입력 감시
- 캐릭터 저장 데이터 직접 수정
- Workspace 직접 변경
- 독립된 자원 저장소
- 독립된 전투 이벤트 루프
- 별도 실행 취소 시스템

처리기 실패 시 해당 실행 트랜잭션을 취소하고 이미 예약된 자원과 효과를 되돌릴 수 있어야 한다.

---

## 16. 검증 규칙

Grant Graph를 구성할 때 서버는 최소한 다음을 검증한다.

- 모든 ContentId가 현재 ruleset과 활성 출처 팩에 존재하는가
- 출처 팩 버전과 저장된 선택 버전이 호환되는가
- ChoiceRecord가 정확한 sourceOccurrenceId에 속하는가
- 선택한 콘텐츠가 해당 후보군에 포함되는가
- 선택 개수와 중복 제한이 맞는가
- 선행 조건을 충족하는가
- 교체가 허용된 시점과 방식인가
- 중첩 정책과 배타 관계가 해결 가능한가
- Grant Graph에 순환 참조가 없는가
- 필요한 전용 handler가 등록되어 있는가
- 현재 저장 데이터가 최종 Capability Set을 재구성할 수 있는가

클라이언트가 보낸 최종 Capability 목록과 최종 파생 수치를 신뢰하지 않는다.

---

## 17. UI와 시트 표현

캐릭터 시트는 Capability만 평평하게 나열하지 않는다.

사용자에게는 출처와 실제 기능을 함께 보여준다.

```text
웨폰 마스터리
출처: 전사
선택: 장검, 장궁
현재 활성: 장검 장착 중
```

```text
주문 예시
출처: 재주
시전 능력치: 지능
무료 사용: 사용 가능
주문 슬롯 사용: 가능
```

원칙:

- 같은 공유 자원은 여러 Feature 아래에서 중복 표시하지 않는다.
- 사용할 수 없는 Action은 숨기기보다 비활성 이유를 보여줄 수 있다.
- 선택 결과는 해당 출처와 성장 단계에서 수정한다.
- 규칙상 허용되지 않은 일반 시트 편집으로 ChoiceRecord를 바꾸지 않는다.
- 행동 UI는 최종 Capability Set에서 생성한다.
- Feature 설명은 출처별로 묶고 실행 버튼은 실제 Capability에 연결한다.

---

## 18. 파생과 캐시

Capability Set은 다음 변화가 있을 때 다시 계산하거나 영향 범위만 갱신한다.

- 종, 배경 또는 직업 진행 변경
- 레벨업과 선택 변경
- 재주 획득 또는 제거
- 장비 장착, 해제와 조율
- 장기 상태 효과의 시작과 종료
- 출처 팩 마이그레이션

매 프레임 전체 콘텐츠 카탈로그를 검색하지 않는다.

캐시 후보:

```text
CharacterCapabilityCache
├─ sourceRevision
├─ equipmentRevision
├─ effectRevision
├─ resolvedGrants
└─ compiledCapabilities
```

비활성 Capability는 규칙 이벤트 구독을 유지하지 않는다. 재계산 시 제거된 트리거, 연결과 임시 런타임 객체를 정리한다.

---

## 19. 오류 격리와 진단

하나의 Feature 또는 전용 처리기 오류가 캐릭터 전체와 세션을 중단시키지 않게 한다.

로그에 포함할 정보 후보:

- `contentId`
- `sourceChain`
- `handlerId`
- `characterId` 또는 `actorId`
- `executionId`
- `rulesetId`
- `sourcePackId`와 버전
- 실패한 규칙 단계
- 자원 예약과 롤백 결과

콘텐츠 정의가 잘못된 경우:

- 출처 팩 로딩 또는 Capability 구성 단계에서 오류를 표시한다.
- 해당 콘텐츠를 정상 작동하는 것처럼 노출하지 않는다.
- 캐릭터 원본 선택 기록은 삭제하지 않는다.
- 가능한 경우 읽기 전용 설명과 복구 안내를 제공한다.

---

## 20. 명시적인 비목표

- 모든 D&D 규칙을 하나의 거대한 JSON 스키마로 표현하지 않는다.
- 클래스 이름을 검사하는 중앙 `if fighter then` 분기문을 만들지 않는다.
- 캐릭터 저장 데이터에 Feature와 Spell 정의를 복사하지 않는다.
- 행동 버튼 목록을 캐릭터 기능의 원본으로 사용하지 않는다.
- 직업 전용 필드를 범용 Character 스키마에 계속 추가하지 않는다.
- 출처 팩이 캐릭터 저장소와 전투 런타임을 직접 수정하게 하지 않는다.
- 콘텐츠마다 별도 자원, 별도 이벤트 루프와 별도 저장 방식을 만들지 않는다.

---

## 21. 첫 수직 검증 후보

이 구조는 전사 일부 기능을 얇게 구현해 검증하는 것이 적절하다.

```text
전사 레벨 출처
→ 고정 Feature 파생
→ 전투 방식 ChoiceGrant
→ 재기의 바람 Action + 공유 Resource
→ 웨폰 마스터리 무기 선택 + 마스터리 속성 적용
→ 추가 공격 또는 행동 연쇄의 RuleOverride
→ 시트와 행동 UI
→ 저장과 재접속
```

여기에 주문을 부여하는 재주 하나를 추가하면 SpellAccessCapability도 함께 검증할 수 있다.

이것은 구현 착수 결정이 아니라 이후 구현명세를 나눌 때 사용할 검증 순서 제안이다.

---

## 22. 후속 결정이 필요한 항목

1. 고정 획득을 캐릭터에 저장하지 않고 항상 출처에서 파생하는 원칙의 최종 확정
2. `FeatDefinition`을 `FeatureDefinition`과 완전히 다른 타입으로 둘지 공통 상위 계약을 둘지
3. GrantInstruction과 Capability의 실제 typed Luau union
4. 타입 있는 규칙 이벤트의 정확한 목록과 단계
5. Capability별 기본 중첩 정책
6. 웨폰 마스터리 선택을 변경할 수 있는 정확한 게임 절차
7. 콘텐츠 팩 업데이트 시 기존 캐릭터가 정의 버전을 고정할지 자동 마이그레이션할지
8. 첫 수직 검증에 포함할 전사 Feature와 마스터리 속성 범위
9. 캐릭터 시트에서 Feature, 획득 출처와 실제 Action을 묶어 보여주는 방식

다음 논의에서는 먼저 **고정 획득은 출처에서 파생하고, 선택 결과와 예외 획득만 캐릭터에 저장하는가**를 확정한다.
