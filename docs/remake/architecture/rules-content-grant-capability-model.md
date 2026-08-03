# 10. 규칙 콘텐츠 Grant Graph와 실행 Capability 모델

- 상태: 초안
- 작성일: 2026-08-03
- 관련 문서:
  - [`ADR-0001`](../../decisions/ADR-0001-authored-rules-content.md)
  - [`ADR-0002`](../../decisions/ADR-0002-integrated-character-progression.md)
  - [`ADR-0003`](../../decisions/ADR-0003-ruleset-source-packs-localization.md)
  - [`ADR-0016`](../../decisions/ADR-0016-player-selected-ability-score-generation.md)
  - [`ADR-0017`](../../decisions/ADR-0017-derived-fixed-grants-and-stored-selections.md)
  - [`11. 규칙 콘텐츠 공통 실행 계약`](../rules-content-execution-and-spell-contract.md)
  - [`AGENTS.md`](../../../AGENTS.md)

## 1. 문서 목적

종, 배경, 직업, 하위직업, 재주와 아이템은 서로 다른 방식으로 캐릭터에게 기능을 부여한다.

부여되는 결과는 단순한 특성 이름 목록이 아니다.

- 고정 특성
- 선택형 전투 방식과 재주
- 레벨에 따라 강화되는 특성
- 행동, 보너스 행동과 반응
- 공격과 판정에 개입하는 트리거
- 짧은 휴식과 긴 휴식으로 회복되는 자원
- 주문 습득, 준비, 항상 준비와 무료 시전
- 웨폰 마스터리 대상 무기 선택
- 추가 공격처럼 기존 규칙을 변경하는 효과
- 격노, 암습과 메타매직처럼 전용 실행 흐름이 필요한 효과

이 문서는 다음 흐름을 하나의 공통 계약으로 정형화한다.

```text
획득 출처
→ GrantInstruction
→ Grant Graph 해석
→ ResolvedGrant
→ Capability 구성
→ 시트, 행동 UI와 규칙 엔진에서 사용
```

이 문서는 **무엇을 획득하고 어떻게 파생하는가**를 다룬다.

실제 행동, 마법, 비용, 대상, 판정과 지속 효과의 실행 생명주기는 `11-rules-content-execution-and-spell-contract.md`에서 다룬다.

---

## 2. 핵심 원칙

### 2.1 획득 출처와 획득 결과를 분리한다

종, 배경, 직업과 재주는 다른 콘텐츠를 부여하는 출처다.

부여되는 특성, 주문, 숙련과 실행 기능은 독립된 콘텐츠 정의다.

```text
BackgroundDefinition
└─ feat ID를 부여

FeatDefinition
└─ 선택, 행동, 패시브와 주문 권한을 부여
```

배경 안에 재주의 전체 규칙과 실행 로직을 복사하지 않는다.

### 2.2 캐릭터 저장 데이터에 콘텐츠 정의를 복사하지 않는다

캐릭터는 다음을 저장한다.

- 어떤 종, 배경, 직업 레벨과 재주를 선택했는가
- 선택형 부여에서 무엇을 골랐는가
- 규칙 외 보상이나 DM 예외로 무엇을 받았는가
- 각 선택이 어느 성장 단계와 출처에서 발생했는가

특성, 주문과 재주의 전체 규칙 정의는 `RulesContentCatalog`가 소유한다.

### 2.3 고정 획득은 파생하고 선택과 예외만 저장한다

ADR-0017에 따라 다음 원칙을 확정한다.

직업 레벨, 종, 하위직업과 콘텐츠 정의만 보면 항상 결정되는 고정 특성은 캐릭터에 중복 저장하지 않는다.

```text
저장된 성장 출처
+ 고정된 ruleset과 출처 팩 버전
+ RulesContentCatalog
→ 고정 Feature 재구성
```

다음은 원본 선택 데이터이므로 저장한다.

- 전투 방식 선택
- 웨폰 마스터리 대상 무기 선택
- 재주 선택
- 습득, 준비와 교체한 주문
- 하위직업 선택
- 선택형 숙련과 언어
- DM이 직접 부여한 예외 콘텐츠

`ResolvedGrant`와 최종 Capability 목록은 캐시할 수 있지만 권위 원본이 아니다.

### 2.4 실제 기능은 Capability로 통일한다

특성의 이름이나 출처가 아니라 실제로 게임에 주는 기능을 `Capability`로 표현한다.

전사 특성, 종 특성과 재주가 모두 반응 행동을 부여할 수 있다. 출처는 다르지만 행동 시스템에는 같은 종류의 반응 Capability로 전달한다.

### 2.5 공통 구조와 전용 구현을 결합한다

피해, 회복, 자원, 숙련, 조건, 트리거와 수치 보정은 공통 프리미티브를 사용한다.

추가 공격, 행동 연쇄, 암습과 메타매직처럼 고유한 규칙은 등록된 확장점과 전용 처리기를 사용할 수 있다.

전용 처리기도 공통 실행 트랜잭션, 서버 검증, 자원 소비, 로그와 롤백을 우회할 수 없다.

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

`Character Capability Set`은 성장 원본, 장비와 활성 효과에서 다시 만들 수 있는 파생 런타임 결과다.

---

## 4. 획득 출처 Definition

### SpeciesDefinition

- 크기와 이동 관련 기본 규칙
- 감각
- 언어 또는 언어 선택
- 종 특성
- 종이 부여하는 주문 권한
- 선택형 계통 또는 세부 유형

### BackgroundDefinition

- 능력치 영구 보정 선택
- 숙련과 도구 숙련
- 시작 장비 또는 화폐 선택
- 재주

배경이 부여하는 재주는 `FeatDefinition` ID를 참조한다.

### ClassDefinition

```text
ClassDefinition
├─ 기본 숙련과 히트 다이스 규칙
├─ 레벨별 GrantInstruction
├─ 하위직업 선택 시점
├─ 주문 진행 규칙
├─ 자원 성장 규칙
└─ 다중직업 진입과 획득 규칙
```

같은 특성이 상위 레벨에서 강화되면 규칙에 따라 다음 중 하나를 사용한다.

- 기존 Feature 단계 상승
- Capability 파라미터 스케일
- 기존 Feature 교체
- 추가 Feature가 기존 기능 확장

### SubclassDefinition

부모 직업 진행 위에 GrantInstruction을 추가한다.

부모 직업 데이터를 복제하지 않는다.

### FeatDefinition

재주는 선택 가능한 독립 콘텐츠이자 하나 이상의 기능을 묶은 획득 패키지다.

```text
FeatDefinition
├─ prerequisites
├─ repeatability
├─ choices
└─ grants
```

### ItemDefinition

아이템은 Capability가 언제 활성화되는지 명시한다.

- 소유
- 장착
- 조율
- 손에 들기
- 사용 가능 상태
- 남은 충전

아이템이 부여한 Capability는 해당 아이템 인스턴스를 출처로 추적한다.

---

## 5. GrantInstruction 종류

### FixedGrant

조건을 충족하면 지정된 콘텐츠를 자동 부여한다.

```text
전사 특정 레벨 도달
→ feature.fighter.second_wind
```

결과는 성장 출처에서 파생하며 캐릭터에 중복 저장하지 않는다.

### ChoiceGrant

후보군에서 지정된 수만큼 선택한다.

```text
전투 방식 후보군
→ 1개 선택
```

최종 선택은 `ChoiceRecord`로 저장한다.

### ScaledGrant

직업 레벨, 전체 레벨, 숙련 보너스 또는 Feature 단계에 따라 파라미터가 변한다.

예시:

- 사용 횟수
- 피해 주사위
- 웨폰 마스터리 선택 수
- 대상 수

현재 계산값을 성장 원본에 저장하지 않는다.

### ConditionalGrant

장착, 조율, 준비, 상태 또는 다른 조건이 참일 때만 활성화한다.

조건이 거짓이 되어도 획득 기록을 삭제하지 않는다.

### ReplaceableGrant

규칙이 허용하는 절차에서 이전 선택을 교체한다.

예시:

- 레벨업 중 주문 교체
- 웨폰 마스터리 대상 변경
- 전투 방식 교체

교체는 하나의 원자적 선택 변경으로 처리한다.

### NestedGrant

부여된 콘텐츠가 다시 다른 콘텐츠와 선택을 부여한다.

```text
배경
→ 재주
→ 주문 선택권
→ SpellAccessCapability
```

Resolver는 순환 참조를 탐지한다.

### ExceptionalGrant

DM 보상, 서사 사건, 데이터 복구 또는 승인된 홈브루 획득이다.

결정적으로 파생할 수 없으므로 명시적으로 저장한다.

---

## 6. GrantInstruction 공통 계약 후보

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

- `grantId`: 출처 안에서 안정적인 ID
- `kind`: fixed, choice, scaled, conditional, replaceable, nested, exceptional
- `selectionPool`: 선택 가능한 콘텐츠 집합
- `sourceOccurrenceId`: 같은 선택이 여러 번 발생했을 때의 출처 인스턴스
- `activationCondition`: 획득은 유지하되 현재 활성 여부 결정
- `replacementPolicy`: 선택 교체 시점과 절차
- `stackingKey`: 충돌을 판정하는 규칙 키
- `stackingPolicy`: 합산, 최대값, 교체와 같은 결합 방식
- `parameters`: 검증된 구성값
- `handlerId`: 전용 파생 또는 결합 처리기

표시 문자열과 번역된 이름을 식별자로 사용하지 않는다.

---

## 7. 캐릭터에 저장하는 데이터

### ProgressionSourceRecord

- 종
- 배경
- 직업별 레벨과 획득 순서
- 하위직업
- 직접 선택한 재주

### ChoiceRecord

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

예시:

```text
전사 웨폰 마스터리 선택
→ 장검과 장궁
```

### ExceptionalGrantRecord

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

### 저장하지 않는 데이터

- 자동 획득 Feature 목록
- 최종 ResolvedGrant 목록
- 최종 Capability 목록
- 현재 행동 버튼 목록
- 추가 공격 횟수와 최대 자원 같은 파생값
- 장비에서 현재 활성화된 Capability 사본
- 번역된 이름과 설명

캐시는 원본 revision과 콘텐츠 버전이 달라지면 폐기한다.

---

## 8. ResolvedGrant와 출처 사슬

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

예시:

```text
background.sage
→ feat.magic_initiate
→ choice.magic_initiate.cantrip.1
→ spell.example_cantrip
```

출처 사슬은 다음에 사용한다.

- 시트의 출처 표시
- 선택 교체와 재구성
- 출처 제거 시 종속 콘텐츠 정리
- 콘텐츠 팩 누락 진단
- 마이그레이션
- 규칙 오류 로그

`ResolvedGrant`는 파생 캐시다.

---

## 9. Capability 종류

### ActionCapability

플레이어가 직접 선택해 실행하는 행동이다.

- 행동 경제
- 사용 시점
- 대상과 사거리
- 자원 비용
- 실행 정의 또는 handler
- UI 표시 조건

### PassiveModifierCapability

항상 또는 조건부로 파생 수치와 규칙 계산을 변경한다.

- AC와 이동속도
- 피해와 명중 보정
- 공격 횟수
- 이점과 불리점

### TriggerCapability

타입 있는 규칙 이벤트에 자동 또는 선택적으로 반응한다.

- 공격 명중 후
- 판정 또는 내성 실패 후
- 피해 전후
- 턴 시작과 종료
- 휴식 완료
- 장비 장착과 해제

### ResourceCapability

```text
resourceId
maximumFormula
recoveryPolicy
minimum
sharingKey
```

여러 Feature가 같은 자원을 소비할 수 있다.

현재 값은 persistent runtime state에 저장하고 최대값은 파생한다.

### ProficiencyCapability

기술, 내성, 무기, 방어구, 도구와 언어 숙련을 부여한다.

숙련 단계와 중첩 정책을 명시한다.

### SpellAccessCapability

주문 자체와 사용 권한을 분리한다.

- `spellId`
- 획득 출처
- 시전 능력치
- 습득, 준비, 항상 준비, 주문책 또는 일시 제공
- 주문 슬롯 사용 정책
- 무료 시전 횟수와 회복
- 상위 레벨 시전 가능 여부
- 구성요소와 의식 시전 변경

같은 주문도 출처에 따라 서로 다른 Access를 가진다.

### ChoiceCapacityCapability

현재 또는 다음 성장 절차에서 사용할 선택 슬롯을 제공한다.

웨폰 마스터리처럼 선택 개수와 후보가 레벨에 따라 달라지는 구조에 사용한다.

### RuleOverrideCapability

기존 공통 규칙의 결과나 절차를 명시적으로 변경한다.

- 공격 행동의 공격 횟수
- 추가 행동 기회
- 자원 소비 방식
- 웨폰 마스터리 적용 방식

등록된 규칙 확장점과 우선순위를 사용한다.

### EffectSourceCapability

피해, 회복, 상태, 이동, 소환과 영역 효과의 출처가 된다.

실행 계약은 11번 문서를 따른다.

---

## 10. Feature, Feat와 Spell의 관계

### FeatureDefinition

직업, 하위직업 또는 종이 부여하는 이름 있는 규칙 묶음이다.

- Capability
- 다른 콘텐츠 Grant
- 선택
- 스케일 규칙
- 전용 처리기

### FeatDefinition

`RuleContentDefinition` 공통 상위 계약을 공유하지만 별도 전문 타입으로 유지한다.

- 선택 조건
- 반복 선택 가능 여부
- 재주 분류
- 능력치 증가 선택
- 다른 재주와의 배타 관계

### SpellDefinition

주문 자체의 규칙 정의다.

- 주문 레벨과 학파
- 시전 시간
- 대상과 사거리
- 구성요소
- 지속시간과 집중
- 판정과 효과
- 상위 레벨 변화
- 실행 수준과 처리기

캐릭터가 주문을 어떻게 얻고 사용하는지는 SpellAccessCapability가 결정한다.

---

## 11. 웨폰 마스터리 기준 사례

웨폰 마스터리는 세 요소를 분리한다.

```text
WeaponDefinition
→ 무기의 기본 masteryPropertyId

WeaponMasteryPropertyDefinition
→ 마스터리 규칙과 공격 파이프라인 연결

Weapon Mastery Feature
→ 마스터리를 사용할 무기 선택권
```

### 무기 정의

각 무기는 마스터리 속성을 콘텐츠 ID로 참조한다.

마스터리 실행 로직을 무기마다 복사하지 않는다.

### 직업 특성

```text
ChoiceCapacityCapability
├─ 선택 가능한 무기 후보
├─ 레벨에 따른 선택 개수
├─ 교체 가능 시점
└─ sourceOccurrenceId
```

캐릭터에는 선택한 `weaponId`만 저장한다.

### 공격 시 적용

```text
사용 무기 확인
→ 마스터리 대상 선택 여부
→ 무기의 masteryPropertyId 조회
→ Trigger 또는 RuleOverride 적용
→ 필요한 선택과 효과 실행
```

### 전사 전용 확장

상위 특성이 적용 방식을 바꾸면 클래스 이름 중앙 분기를 만들지 않는다.

```text
feature.fighter.mastery_extension
→ RuleOverrideCapability
→ WeaponMastery 확장점
```

---

## 12. 전사 특성 기준 사례

### 전투 방식

```text
Class level source
→ ChoiceGrant
→ fighting-style 후보군
→ 선택한 Feat 또는 Feature
```

### 재기의 바람

```text
ResourceCapability
+ ActionCapability
+ 휴식 회복 규칙
```

현재 남은 횟수는 저장하고 최대 횟수는 파생한다.

### 같은 자원을 사용하는 후속 특성

```text
TriggerCapability
→ 판정 실패 감지
→ 기존 second_wind 자원 소비
→ 후속 효과
```

새 자원을 중복 생성하지 않는다.

### 행동 연쇄

```text
ActionCapability
+ ResourceCapability
+ RuleOverrideCapability(action economy)
+ 턴 사용 상태
```

전사 모듈이 전투 런타임을 직접 임의 수정하지 않는다.

### 추가 공격

공격 행동을 여러 개 복제하지 않는다.

```text
PassiveModifierCapability
→ attackAction.attackCount
```

다중직업과 여러 출처의 중첩 정책을 명시한다.

### 불굴 계열

```text
TriggerCapability: 내성 굴림 실패 후
+ ResourceCapability
+ 재굴림 또는 결과 변경
```

공통 판정 트랜잭션 안에서 처리한다.

---

## 13. 중첩과 충돌

지원 정책:

- `unique`
- `additive`
- `maximum`
- `replace`
- `exclusiveGroup`
- `refreshDuration`
- `custom`

결합 결과는 출처 팩 로딩 순서에 우연히 의존하지 않는다.

다음을 사용해 결정적으로 계산한다.

- 규칙 세트
- 명시적 우선순위
- 출처 관계
- 콘텐츠 버전
- stacking policy

추가 공격처럼 일반 합산이 잘못되는 규칙은 고유 stackingKey와 정책을 가진다.

---

## 14. 타입 있는 규칙 이벤트

TriggerCapability는 임의 문자열 이벤트를 구독하지 않는다.

이벤트 후보:

```text
ActionDeclared
TargetsLocked
BeforeAttackRoll
AfterAttackRoll
AttackHit
AttackMissed
SavingThrowFailed
BeforeDamageApplied
AfterDamageApplied
TurnStarted
TurnEnded
RestCompleted
ItemEquipped
ItemUnequipped
ConditionApplied
ConditionRemoved
```

정확한 실행 단계, 반응 창과 수정 가능 범위는 11번 문서와 전투 명세에서 확정한다.

---

## 15. 전용 처리기 경계

공통 프리미티브로 표현하기 어려운 Grant 파생과 Capability 결합은 전용 처리기를 사용할 수 있다.

허용:

- 검증된 출처와 선택 조회
- 파생 파라미터 계산
- Capability 생성
- 중첩과 충돌 해결
- 구조화된 오류 반환

금지:

- RemoteEvent 직접 생성
- 클라이언트 입력 감시
- 캐릭터 저장 데이터 직접 수정
- Workspace 직접 변경
- 독립된 자원 저장소
- 독립된 전투 이벤트 루프

실제 행동 실행 처리기는 11번 문서의 `RuleExecutionContext`를 따른다.

---

## 16. 검증

Grant Graph 구성 시 서버가 검사한다.

- 모든 ContentId가 현재 ruleset과 활성 출처 팩에 존재하는가
- 저장된 선택 버전이 호환되는가
- ChoiceRecord가 정확한 sourceOccurrenceId에 속하는가
- 선택한 콘텐츠가 후보군에 포함되는가
- 선택 개수, 중복과 선행 조건이 맞는가
- 교체가 허용된 절차인가
- 중첩과 배타 관계가 해결 가능한가
- 순환 참조가 없는가
- 필요한 handler가 등록되어 있는가
- 현재 원본 데이터에서 Capability Set을 재구성할 수 있는가

클라이언트가 보낸 최종 Capability 목록과 파생 수치를 신뢰하지 않는다.

---

## 17. UI와 시트

시트는 Capability만 평평하게 나열하지 않는다.

```text
웨폰 마스터리
출처: 전사
선택: 장검, 장궁
현재 활성: 장검 장착 중
```

```text
주문
출처: 재주
시전 능력치: 지능
무료 사용: 사용 가능
슬롯 사용: 가능
```

원칙:

- 공유 자원을 중복 표시하지 않는다.
- 사용할 수 없는 행동은 비활성 이유를 표시한다.
- 선택 결과는 해당 성장 출처에서 수정한다.
- 일반 시트 편집으로 ChoiceRecord를 우회 변경하지 않는다.
- 행동 UI는 최종 Capability Set에서 생성한다.
- Feature 설명과 실제 실행 버튼의 연결을 표시한다.

---

## 18. 파생과 캐시

다음 변화에 Capability Set을 다시 계산하거나 영향 범위만 갱신한다.

- 종, 배경과 직업 진행
- 레벨업과 선택 교체
- 재주 획득과 제거
- 장비 장착, 해제와 조율
- 장기 효과 시작과 종료
- 출처 팩 마이그레이션

```text
CharacterCapabilityCache
├─ sourceRevision
├─ equipmentRevision
├─ effectRevision
├─ contentVersionSet
├─ resolvedGrants
└─ compiledCapabilities
```

매 프레임 전체 카탈로그를 검색하지 않는다.

비활성 Capability는 이벤트 구독을 유지하지 않는다.

---

## 19. 오류 격리와 누락 콘텐츠

로그 후보:

- `contentId`
- `sourceChain`
- `handlerId`
- `characterId` 또는 `actorId`
- `rulesetId`
- `sourcePackId`와 버전
- 실패한 파생 단계

콘텐츠가 누락되거나 손상된 경우:

- 해당 Grant를 `unresolved`로 표시한다.
- Capability를 정상 작동하는 것처럼 노출하지 않는다.
- 저장된 성장 출처와 선택 기록은 삭제하지 않는다.
- 읽기 전용 설명과 복구 안내를 제공한다.

---

## 20. 명시적인 비목표

- 모든 규칙을 하나의 거대한 JSON 스키마에 강제로 넣지 않는다.
- 클래스 이름을 검사하는 중앙 거대 분기문을 만들지 않는다.
- 캐릭터 데이터에 Feature와 Spell 정의를 복사하지 않는다.
- 행동 버튼 목록을 캐릭터 기능의 원본으로 사용하지 않는다.
- 직업 전용 필드를 범용 Character 스키마에 계속 추가하지 않는다.
- 출처 팩이 캐릭터 저장소와 전투 런타임을 직접 수정하게 하지 않는다.
- 콘텐츠마다 별도 자원, 이벤트 루프와 저장 방식을 만들지 않는다.

---

## 21. 첫 수직 검증 후보

```text
전사 레벨 출처
→ 고정 Feature 파생
→ 전투 방식 ChoiceGrant
→ 재기의 바람 Action + 공유 Resource
→ 웨폰 마스터리 선택 + 속성 적용
→ 추가 공격 또는 행동 연쇄 RuleOverride
→ 시트와 행동 UI
→ 저장과 재접속
```

주문을 부여하는 재주 하나를 추가해 SpellAccessCapability까지 검증한다.

실제 행동과 마법 실행은 11번 문서의 수직 검증 순서를 따른다.

---

## 22. 우선 확정하는 방향

1. 고정 획득은 출처에서 파생하고 선택과 예외 획득만 저장한다.
2. Feature, Feat, Spell과 아이템 행동은 공통 상위 계약과 전문 타입을 함께 사용한다.
3. 획득 결과는 Capability로 컴파일한다.
4. Character Capability Set은 파생 캐시이며 저장 원본이 아니다.
5. 웨폰 마스터리 대상은 무기 ID 선택으로 저장하고 마스터리 효과는 무기 정의에서 조회한다.
6. 공유 자원은 하나의 ResourceCapability를 여러 기능이 참조한다.
7. 규칙 변경은 등록된 RuleOverride 확장점을 사용한다.
8. 선택, 중첩, 버전과 출처 사슬을 결정적으로 재구성할 수 있어야 한다.
9. 누락 콘텐츠가 있어도 원본 선택 기록을 삭제하지 않는다.
10. 실제 실행, 마법과 지속 효과는 공통 RuleExecution 계약을 사용한다.

---

## 23. 후속 결정이 필요한 항목

1. GrantInstruction과 Capability의 실제 typed Luau union
2. Capability별 기본 stacking policy
3. 웨폰 마스터리 선택을 변경하는 정확한 게임 절차
4. 콘텐츠 팩 업데이트 시 버전 고정과 마이그레이션 정책
5. 캐릭터 시트에서 Feature, 출처와 Action을 묶는 구체적인 화면
6. 첫 수직 검증에 포함할 전사 Feature와 마스터리 속성 범위
7. ExceptionalGrant의 승인, 제거와 감사 로그 정책

다음 세부 주제는 `11-rules-content-execution-and-spell-contract.md`의 후속 결정 순서를 따른다.
