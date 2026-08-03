# 34. 공식 2024 형식 캐릭터 시트와 실시간 플레이어 UI 모델

- 상태: 초안
- 작성일: 2026-08-03
- 관련 문서:
  - [`03. 캐릭터 생성과 성장`](03-character-creation-and-progression.md)
  - [`19. 트리거와 다른 턴 실행 모델`](19-feat-feature-trigger-and-cross-turn-execution-model.md)
  - [`20. 능동형 특성과 행동 내부 실행 모델`](20-active-feature-and-action-container-execution-model.md)
  - [`21. 패시브 특성 모델`](21-passive-modifier-and-rule-override-model.md)
  - [`23. 아이템 인스턴스와 장비 모델`](23-item-instance-equipment-and-inventory-model.md)
  - [`25. HP 0·죽음 내성·휴식·자원 회복 모델`](25-zero-hit-points-death-saves-rest-and-resource-recovery-model.md)
  - [`27. 주사위 굴림·연출·결과 확정 모델`](27-dice-roll-presentation-and-resolution-gating-model.md)
  - [`33. Baldur's Gate 3형 전투 HUD와 행동 UI 모델`](33-baldurs-gate-style-combat-hud-and-contextual-action-ui-model.md)
  - [`ADR-0040`](decisions/ADR-0040-official-2024-character-sheet-and-live-player-view.md)

## 1. 문서 목적

이 문서는 플레이어가 RVTT 안에서 자신의 전체 캐릭터 시트를 직접 열고 확인하며, 시트의 굴림·특성·주문·무기·장비 항목을 실제 게임 규칙과 연결하는 UI 구조를 정의한다.

기본 정보 구조는 공식 D&D 2024 캐릭터 시트의 2페이지 구성을 따른다.

```text
1페이지
→ 핵심 능력·전투 상태·공격·숙련·종족 특성·직업 특성·Feat

2페이지
→ 주문·주문 슬롯·장비·화폐·조율·언어·외모·배경과 성격
```

이 문서의 대상:

- 플레이어가 직접 여는 캐릭터 시트
- 공식 2024 시트형 2페이지 레이아웃
- 전투 HUD와 캐릭터 시트의 동시 상태 동기화
- 능력 판정, 내성 굴림, 기술 판정과 공격 굴림
- HP, 임시 HP, 죽음 내성, 명중 주사위와 영웅적 영감
- 종족 특성, 직업 특성, Feat와 사용자 정의 Feature
- 주문 준비, 주문 슬롯과 주문 시전 수치
- 장비, 화폐, 조율과 숙련
- 외모, 성격, 배경 이야기와 개인 메모
- 전투 중 시트 열기와 행동 실행
- DM 열람·수정 권한
- Feature·Feat·공식 콘텐츠·사용자 콘텐츠 자동 확장
- 저장, 재접속, 성능, 반응형 화면과 접근성

핵심 원칙:

```text
공식 시트의 정보 구조
+ RVTT 자체 그래픽
+ 서버 권위 실시간 상태
```

```text
캐릭터 시트는 데이터 원본이 아니다.
캐릭터 시트는 CharacterRecord와 규칙 스냅샷의 투영이다.
```

---

## 2. 참고 기준

공식 D&D 자료는 2024 캐릭터 시트를 공식 다운로드 항목으로 제공하며, 공식 디지털 시트는 HP, 장비, 주문과 능력을 추적하고 시트에서 굴림을 실행하는 용도로 안내된다.

RVTT가 가져오는 것은 다음이다.

- 2페이지 정보 계층
- 능력치·내성·기술의 익숙한 결합
- 핵심 전투 수치의 한눈에 보기
- 공격·특성·주문·장비의 분리
- 종이 시트와 비슷한 읽기 순서

RVTT가 그대로 복제하지 않는 것은 다음이다.

- D&D 로고
- 공식 일러스트
- 공식 장식 프레임
- 공식 고유 글꼴
- 공식 시트의 픽셀 단위 외형

시트는 RVTT 자체 디자인 시스템으로 다시 제작한다.

---

## 3. 열기 방식

캐릭터 시트를 여는 기능은 물리 키에 직접 하드코딩하지 않고 의미 동작으로 등록한다.

```text
OpenCharacterSheet
CloseCharacterSheet
ToggleCharacterSheetPage
ToggleCharacterSheetLayout
OpenCharacterSection
```

진입 경로:

- 전투 HUD의 현재 Actor 초상화 또는 시트 버튼
- 왼쪽 PartyRail의 자신의 초상화 문맥 메뉴
- 메인 게임 메뉴의 캐릭터 항목
- 사용자 지정 단축키

시트를 열 때 현재 조작 Actor가 플레이어 캐릭터가 아니면 다음 정책을 사용한다.

```text
owned_character
→ 해당 캐릭터 전체 시트

delegated_npc
→ 허용된 NPC 시트 또는 스탯블록 보기

unowned_actor
→ 공개 정보 카드만 표시
```

---

## 4. 표시 모드

### 4.1 단일 페이지

```text
single_page
```

- 한 페이지를 화면 중앙에 크게 표시한다.
- 페이지 1과 페이지 2를 버튼, 휠 또는 의미 입력으로 전환한다.
- 기본 권장 모드다.

### 4.2 양면 펼침

```text
double_spread
```

- 16:9 이상의 넓은 화면에서 두 페이지를 나란히 표시한다.
- 종이 시트를 펼쳐 둔 느낌을 제공한다.
- 작은 글자가 되지 않도록 최소 UI 배율을 만족할 때만 제공한다.

### 4.3 전투 측면 시트

```text
combat_side_sheet
```

- 전투 중 화면 한쪽에 축소된 시트를 연다.
- 전장, 이니셔티브와 주요 HUD를 동시에 볼 수 있다.
- 현재 선택 섹션만 표시한다.
- HP·자원·특성·주문 확인과 Hotbar 정리에 적합하다.

### 4.4 반응형 섹션 보기

```text
responsive_sections
```

작은 화면에서는 2페이지를 그대로 축소하지 않고 다음 섹션으로 재배열한다.

```text
요약
능력과 기술
전투
특성과 Feat
주문
장비
인물
```

정보 순서와 의미는 공식 형식을 유지한다.

---

## 5. CharacterSheetProjection

```text
CharacterSheetProjection
├─ characterIdentity
├─ progressionSummary
├─ abilitySections[6]
├─ combatSummary
├─ vitalSummary
├─ attackRows[]
├─ trainingAndProficiencies
├─ speciesTraitEntries[]
├─ classFeatureEntries[]
├─ featEntries[]
├─ spellcastingSections[]
├─ inventorySummary
├─ coinSummary
├─ attunementEntries[]
├─ languageEntries[]
├─ appearanceProfile
├─ personalityProfile
├─ backstoryProfile
├─ supplementalResources[]
├─ permissions
├─ localization
└─ revision
```

Projection은 다음 원본에서 생성된다.

```text
CharacterRecord
DerivedValueSnapshot
CapabilitySnapshot
VitalState
ResourceState
EquipmentState
InventoryState
SpellcastingState
ConditionState
PresentationMetadata
```

캐릭터 시트 전용 HP, 주문 슬롯, 특성 목록을 별도로 저장하지 않는다.

---

## 6. 1페이지 레이아웃

기본 16:9 단일 페이지 예시:

```text
┌──────────────────────────────────────────────────────────────┐
│ 이름      직업/레벨      하위직업      종족      배경       │
├──────────────┬────────────────────────┬───────────────────────┤
│ 능력치       │ 전투 핵심 수치          │ HP / 명중 주사위       │
│ 내성         │ AC 우선권 속도 크기     │ 죽음 내성 / 영감        │
│ 기술         │ 숙련 보너스 수동 지각    │                       │
├──────────────┼────────────────────────┼───────────────────────┤
│ 장비 훈련    │ 무기와 피해 캔트립       │ 종족 특성               │
│ 도구 숙련    │ 공격 / DC / 피해 / 비고  │ 직업 특성               │
│ 언어 요약    │                         │ Feat                    │
└──────────────┴────────────────────────┴───────────────────────┘
```

실제 배치는 공식 시트의 읽기 흐름을 기준으로 하되 한국어 길이와 화면 비율에 맞춰 조정한다.

---

## 7. 능력치·내성·기술

각 능력은 하나의 `AbilitySection`으로 표시한다.

```text
AbilitySection
├─ abilityId
├─ score
├─ modifier
├─ savingThrowModifier
├─ savingThrowProficiencyState
├─ skills[]
└─ activeModifiers[]
```

표시 예:

```text
힘 16
수정치 +3
내성 +5 ●
운동 +5 ●
```

숙련 표시는 다음을 구분한다.

```text
none
half_proficiency
proficient
expertise
conditional
```

수치를 선택하면 `RollAbilityCheck`, `RollSavingThrow`, `RollSkillCheck` 의미 명령을 보낸다.

```text
시트에서 은신 +7 선택
→ RollSkillCheck(stealth)
→ 서버가 현재 상태·이점·불리점·Feature 확인
→ 주사위 프레젠테이션
→ 결과 로그
```

화면에 보이는 숫자를 클라이언트가 굴림 공식으로 다시 계산하지 않는다.

수치 옆의 상세 버튼을 누르면 기여 근거를 보여준다.

```text
은신 +7
├─ 민첩 수정치 +4
├─ 숙련 보너스 +3
├─ 장비 페널티 0
└─ 활성 Feature 0
```

---

## 8. 핵심 전투 수치

```text
CombatSummary
├─ proficiencyBonus
├─ heroicInspiration
├─ armorClass
├─ initiativeModifier
├─ speedProfiles[]
├─ size
├─ passivePerception
├─ senses[]
└─ defenseBreakdown
```

이동속도는 하나의 숫자로 제한하지 않는다.

```text
보행 30 ft
비행 60 ft
수영 30 ft
등반 30 ft
```

현재 장비와 Feature가 만드는 AC 계산 근거를 상세 보기에서 확인할 수 있다.

시트에서 우선권을 선택하면 전투 시작 전에는 일반 굴림 요청이 되고, Encounter의 공식 이니셔티브 굴림 중에는 현재 InitiativeRollBatch에 연결된다.

---

## 9. HP·명중 주사위·죽음 내성

```text
VitalSummary
├─ currentHp
├─ maxHp
├─ temporaryHp
├─ vitalState
├─ hitDicePools[]
├─ deathSaveSuccesses
├─ deathSaveFailures
└─ stabilizationState
```

HP는 직접 텍스트 필드에 새 숫자를 넣는 방식이 아니다.

플레이어 기본 조작:

```text
피해 적용
회복 적용
임시 HP 적용
명중 주사위 사용
영감 사용
```

모든 변경은 서버 의미 명령과 권한 검사를 통과한다.

죽음 내성은 ADR-0031의 상태 기계 결과를 표시한다. 전투에서 자동으로 발생한 죽음 내성 결과와 시트 표시가 같은 상태를 사용한다.

DM은 권한이 있을 때 `DMAdjustVitalState`를 사용할 수 있으며 변경 로그가 남는다.

---

## 10. 무기와 피해 캔트립

```text
AttackRow
├─ presentationName
├─ sourceItemOrCapabilityId
├─ attackOrSaveKind
├─ attackBonusOrDc
├─ damageExpressions[]
├─ damageTypes[]
├─ range
├─ notes
├─ availableVariants[]
└─ availabilityState
```

공식 시트형 표:

```text
이름 | 공격 보너스/DC | 피해와 유형 | 비고
```

행 선택 시:

```text
AttackRow 선택
→ SelectCapability
→ 필요한 변형 선택
→ 캐릭터 시트 축소 또는 닫기
→ 전투 HUD TargetingPlan
```

시트에서 직접 대상을 무시하고 피해를 적용하지 않는다.

행마다 Hotbar 고정 버튼을 제공한다.

```text
PinToHotbar
UnpinFromHotbar
```

무기 교체, 장비 해제 또는 Feature 변경으로 Capability가 사라지면 Hotbar와 시트가 함께 갱신된다.

---

## 11. 숙련·종족 특성·직업 특성·Feat

```text
FeatureSheetEntry
├─ featureId
├─ sourceKind
├─ localizedName
├─ summary
├─ usageSummary?
├─ recoverySummary?
├─ activeState
├─ executableCapabilities[]
├─ passiveCapabilities[]
├─ ruleOverrides[]
├─ sourceReference
└─ visibility
```

기본 섹션:

```text
Equipment Training & Proficiencies
Species Traits
Class Features
Feats
```

각 항목은 한 줄 요약으로 표시하고 선택하면 상세 서랍을 연다.

상세 서랍:

- 전체 설명
- 현재 적용 중인 수치
- 사용 조건
- 소모 자원
- 회복 조건
- 능동 행동
- 반응 설정
- 패시브 토글
- 출처

Feat나 직업 특성이 행동을 제공하면 다음이 자동으로 나타난다.

```text
시트 Feature 항목
Hotbar 후보
반응 설정
자원 표시
툴팁
```

특정 Feature 이름을 UI 코드에서 분기하지 않는다.

---

## 12. 2페이지 레이아웃

```text
┌──────────────────────────────────────────────────────────────┐
│ 주문 시전 능력 / 수정치 / 주문 내성 DC / 주문 공격 보너스   │
├───────────────────────────────────┬──────────────────────────┤
│ 캔트립과 준비 주문                │ 주문 슬롯 1~9레벨        │
│ 시전시간 / 사거리 / C·R·M 표시    │ 총량 / 소모량             │
├───────────────────────────────────┼──────────────────────────┤
│ 장비와 화폐                        │ 외모 / 성향               │
│ 조율 아이템                        │ 성격 / 배경 이야기        │
│ 언어                               │                          │
└───────────────────────────────────┴──────────────────────────┘
```

공식 시트형 2페이지의 범주를 유지한다.

---

## 13. 주문 시전 섹션

캐릭터가 복수 주문 시전 원천을 가질 수 있으므로 단일 주문 능력치에 고정하지 않는다.

```text
SpellcastingSection
├─ sourceId
├─ spellcastingAbility
├─ spellcastingModifier
├─ spellSaveDc
├─ spellAttackBonus
├─ preparationMode
├─ spellEntries[]
├─ slotPools[]
└─ specialResources[]
```

주문 목록 행:

```text
SpellSheetEntry
├─ level
├─ name
├─ preparedState
├─ castingTime
├─ range
├─ concentration
├─ ritual
├─ requiredMaterial
├─ currentAvailability
└─ executableCapabilityId
```

시트에는 공식 형식에 맞춰 다음 표식을 사용한다.

```text
C = 집중
R = 의식
M = 특정 물질 구성요소 요구
```

표식은 자체 아이콘과 한국어 툴팁으로 표시한다.

주문 선택 흐름:

```text
주문 선택
→ 상세 정보
→ 시전 가능한 슬롯 레벨
→ Hotbar 고정 또는 지금 시전
→ TargetingPlan
```

주문 슬롯은 총량과 소모량을 표시한다.

```text
3레벨  총 3 / 소모 1
```

소모 여부를 로컬 체크박스로 임의 변경하지 않고 SpellcastingState를 갱신하는 의미 명령을 사용한다.

주문 준비 변경은 규칙상 허용되는 준비 흐름에서만 가능하다.

---

## 14. 장비·화폐·조율

### 14.1 장비

장비 표시는 `ItemInstance`를 사용한다.

```text
EquipmentSheetEntry
├─ itemInstanceId
├─ name
├─ quantity
├─ equippedState
├─ containerPath
├─ weight
├─ attunementState
├─ grantedCapabilities[]
└─ condition
```

시트에서 장비를 선택하면 다음을 할 수 있다.

- 상세 확인
- 장착·해제
- 사용
- Hotbar 고정
- 다른 컨테이너로 이동
- 허용된 대상에게 전달

모든 변경은 Inventory와 Equipment 명령을 사용한다.

### 14.2 화폐

```text
CP
SP
EP
GP
PP
```

캠페인 설정으로 사용하지 않는 화폐는 숨길 수 있지만, 기본 공식 형식에는 모두 표시한다.

### 14.3 조율

조율 슬롯과 조율 아이템을 표시한다.

```text
조율 2 / 3
├─ 불꽃의 검
└─ 보호의 반지
```

조율·해제는 휴식과 아이템 규칙을 통과해야 한다.

---

## 15. 외모·성격·배경 이야기

```text
CharacterNarrativeProfile
├─ appearance
├─ alignment
├─ personality
├─ backstory
├─ portrait
├─ personalNotes
└─ fieldVisibility
```

이 영역은 플레이어가 직접 편집 가능한 자유 서술 필드다.

저장 정책:

- 일정 시간 입력이 없을 때 자동 저장한다.
- 입력 중인 초안을 로컬에 임시 보관한다.
- 서버 저장 실패 시 원문을 잃지 않고 재시도 상태를 표시한다.
- 최대 길이와 안전한 텍스트 필터를 적용한다.
- 수정 revision을 사용해 오래된 클라이언트가 최신 내용을 덮어쓰지 않게 한다.

필드별 공개 범위:

```text
private_to_owner
owner_and_dm
party_visible
public_in_campaign
```

---

## 16. 자유 편집과 규칙 편집 분리

### 자유 편집 가능

- 외모
- 성격
- 배경 이야기
- 개인 메모
- 공개 범위
- Hotbar 정리
- UI 접힘 상태

### 규칙 흐름으로만 변경

- 능력치
- 직업과 레벨
- 하위직업
- 종족
- 배경의 규칙 구성
- 숙련
- Feat
- 습득 주문
- 최대 HP
- 주문 슬롯 최대치
- Feature와 Capability

### 런타임 명령으로 변경

- 현재 HP
- 임시 HP
- 영웅적 영감
- 죽음 내성
- 주문 슬롯 소모
- Feature 사용 횟수
- 장착 상태
- 상태 효과

UI는 변경 종류에 따라 올바른 흐름으로 보낸다.

```text
EditNarrativeField
RequestLevelUp
RequestEquipmentChange
ApplyDamage
ApplyHealing
ConsumeResource
PrepareSpell
UseFeature
```

---

## 17. 전투 HUD와 연동

시트와 HUD는 같은 Projection 기반 요소를 사용한다.

```text
Sheet AttackRow
↔ HUD Action Icon

Sheet HP
↔ ActiveActorPanel HP

Sheet Spell Slots
↔ ResourceRail

Sheet Conditions
↔ PartyRail 상태 아이콘

Sheet Features
↔ Tooltip / Reaction Configuration
```

시트에서 능력이나 행동을 선택했을 때 가능한 흐름:

```text
능력·기술
→ 바로 굴림

공격·주문·능동 Feature
→ 전투 HUD 대상 지정으로 전환

패시브 토글
→ 서버 검증 후 활성 상태 변경

반응 Feature
→ Ask / Auto / Never 설정 열기
```

전투 중 시트를 열어도 턴 시간과 Encounter는 계속 진행된다.

우선순위 UI가 발생하면:

```text
반응 요청
DM 승인
재굴림 선택
죽음 내성 결과 공개
주사위 공개
```

시트 입력을 잠시 비활성화하고 해당 창을 위에 표시한다.

---

## 18. 굴림 UX

굴릴 수 있는 숫자에는 일관된 상호작용 표시를 제공한다.

- 마우스 오버 시 주사위 아이콘
- 클릭 시 기본 굴림
- 문맥 메뉴에서 이점·불리점 요청
- DM 허용 시 상황 보너스 요청
- 굴림 전 계산 근거 미리보기

플레이어가 이점·불리점을 임의 확정하는 것이 아니라 굴림 요청 문맥을 서버에 보낸다.

```text
RollRequest
├─ characterId
├─ rollKind
├─ sourceId
├─ requestedContext
└─ clientRevision
```

서버는 Feature, 상태, 환경, DM 판정과 규칙을 합쳐 최종 RollPlan을 생성한다.

---

## 19. 상세 툴팁과 출처

시트의 모든 규칙 항목은 공통 툴팁 시스템을 사용한다.

```text
제목
분류
핵심 효과
현재 적용 수치
사용 조건
비용
회복
설명
출처
```

툴팁 안의 규칙 용어는 중첩 툴팁으로 확인할 수 있다.

공식 콘텐츠는 허용된 범위에서 출처 식별자를 표시하고, 플레이어가 소유하지 않은 원문 전체를 무단으로 복제하지 않는다.

사용자 콘텐츠에는 캠페인 출처와 제작자 정보를 표시한다.

---

## 20. SupplementalResourceStrip

공식 종이 시트에 고정 칸이 없는 직업 자원도 표시해야 한다.

```text
SupplementalResource
├─ resourceId
├─ name
├─ current
├─ maximum
├─ displayKind
├─ recoverySummary
├─ sourceFeatureId
└─ visibility
```

표시 예:

```text
격노 2 / 3
기 4 / 5
우월성 주사위 3 / 4
채널 디비니티 1 / 2
소서리 포인트 6 / 6
```

기본 페이지 상단 또는 해당 직업 Feature 섹션에 작은 자원 띠로 표시한다.

Presentation Metadata가 자원의 위치와 표현을 결정한다.

---

## 21. CustomSectionRegistry

공식 시트의 핵심 섹션은 고정하되 확장 콘텐츠가 보조 섹션을 등록할 수 있다.

```text
CharacterSheetSectionRegistration
├─ sectionId
├─ preferredPage
├─ preferredAnchor
├─ priority
├─ visibilityRule
├─ entryProvider
└─ presentationTemplate
```

허용 예:

- 변신 형태
- 동물 동료
- 제작법
- 서약 또는 후원자 정보
- 캠페인 평판
- 사용자 정의 자원

확장 섹션이 공식 핵심 영역의 수치를 덮어쓰지는 못한다.

---

## 22. DM과 다른 플레이어의 시트 보기

### 소유자

- 전체 규칙 정보
- 허용된 편집과 실행
- 개인 메모와 비공개 서술

### DM

- 전체 규칙 정보
- 숨겨진 Feature와 효과
- 권한 있는 Override
- 변경 이력
- 플레이어 화면 기준 미리보기

### 파티원

캠페인 공개 정책에 따라 다음 요약만 볼 수 있다.

- 이름과 초상화
- 직업과 레벨
- 현재 HP 표시 정책
- 공개 상태 효과
- 공개 외모와 성격

다른 플레이어에게 전체 AC, 보유 주문, 비밀 장비와 개인 메모를 기본 공개하지 않는다.

---

## 23. 저장과 재접속

서버 권위 캐릭터 상태가 원본이므로 시트 자체는 별도 전체 저장 대상이 아니다.

저장 대상:

- CharacterRecord
- 캐릭터 성장 선택
- 장비와 인벤토리
- 현재 자원과 장기 지속 상태
- 서술 필드
- 공개 범위
- Hotbar 구성
- UI 사용자 설정

세션 중 일시 상태는 Encounter와 Actor 상태에서 복구한다.

재접속 흐름:

```text
CharacterRecord 로드
→ 파생 수치 재계산
→ CapabilitySnapshot 생성
→ 런타임 상태 결합
→ CharacterSheetProjection 생성
→ 열린 페이지와 스크롤 위치 복구
```

오래된 Projection을 로컬 캐시에서 권위 상태로 사용하지 않는다.

---

## 24. 반응형 UI와 접근성

지원 설정:

- UI 배율
- 글자 크기
- 높은 대비
- 색상만 사용하지 않는 숙련 표시
- 툴팁 지연 시간
- 애니메이션 감소
- 페이지 전환 애니메이션 끄기
- 단일 페이지 강제
- 검색과 필터
- 키보드 탐색

한국어 이름이 영어보다 길어질 수 있으므로 제목 영역은 줄바꿈·축약·툴팁 정책을 가진다.

읽기 순서는 스크린 리더와 키보드 탐색에서 시각적 순서와 일치해야 한다.

---

## 25. 성능

- 시트를 닫았을 때 모든 행 UI를 계속 갱신하지 않는다.
- Projection revision이 변경된 섹션만 다시 그린다.
- 긴 주문·Feature 목록은 가상화한다.
- 아이콘과 툴팁 데이터는 공통 캐시를 사용한다.
- 파생 수치는 클라이언트에서 매 프레임 계산하지 않는다.
- 시트를 열 때 전체 규칙 엔진을 다시 실행하지 않고 최신 서버 Snapshot을 사용한다.
- 서술 입력 자동 저장은 debounce한다.

---

## 26. 오류 처리

```text
CHARACTER_SHEET_NOT_AUTHORIZED
CHARACTER_SHEET_STALE_REVISION
CHARACTER_SHEET_SECTION_UNAVAILABLE
CHARACTER_RULE_EDIT_REQUIRES_PROGRESSION_FLOW
CHARACTER_RESOURCE_CHANGE_REJECTED
CHARACTER_NARRATIVE_SAVE_FAILED
CHARACTER_CAPABILITY_NOT_CURRENTLY_AVAILABLE
```

사용자 메시지는 가능한 경우 해결 방법을 포함한다.

예:

```text
이 주문은 현재 준비되어 있지 않습니다.
주문 준비 화면에서 준비한 뒤 사용할 수 있습니다.
```

---

## 27. 테스트 매트릭스

### 기본 표시

- 1레벨 비주문 캐릭터
- 고레벨 주문 시전자
- 멀티클래스 캐릭터
- 복수 주문 시전 능력 원천
- 숙련·전문화·절반 숙련
- 복수 이동속도와 특수 감각

### 상태 동기화

- HUD에서 피해 적용 후 시트 HP 갱신
- 시트에서 주문 시전 후 HUD 슬롯 갱신
- 장비 교체 후 AC·공격·Hotbar 동시 갱신
- Feature 획득 후 시트·Hotbar·반응창 동시 반영
- 죽음 내성 굴림 후 시트 표시

### 권한

- 소유자 자유 서술 수정
- 파티원의 비공개 필드 접근 차단
- DM 읽기와 Override
- 위임 NPC와 플레이어 캐릭터 구분

### 전투

- 자신의 턴에 시트에서 공격 실행
- 다른 Actor 턴에 규칙상 불가능한 실행 차단
- 반응창 발생 시 시트 입력 잠금
- 주사위 연출 중 HP 선반영 방지
- 대상 지정 중 시트 재개·취소

### 저장

- 서술 자동 저장 실패와 재시도
- revision 충돌
- 재접속 후 열린 페이지 복구
- 레벨업 중 연결 끊김

### UI

- 16:9 단일 페이지
- 넓은 화면 양면 펼침
- 작은 화면 반응형 섹션
- 큰 글자와 높은 대비
- 긴 한국어 Feature 이름
- 수백 개 아이템과 주문 목록 가상화

---

## 28. 구현 순서

1. `CharacterSheetProjection` 읽기 모델
2. 공식 형식 1페이지 읽기 전용 UI
3. 능력·내성·기술 굴림 연결
4. HP·자원·공격 행과 HUD 동기화
5. Feature·Feat 상세 서랍과 Hotbar 고정
6. 공식 형식 2페이지와 주문 시전 섹션
7. 장비·화폐·조율 연결
8. 외모·성격·배경 이야기 편집
9. 전투 측면 시트와 반응 우선순위
10. DM 보기·Override·공개 범위
11. CustomSectionRegistry와 사용자 콘텐츠
12. 반응형 UI·접근성·성능 검증

---

## 29. 완료 기준

다음이 모두 충족되어야 캐릭터 시트 기능이 완료된 것으로 본다.

- 플레이어가 탐험과 전투 중 자신의 시트를 직접 열 수 있다.
- 공식 2024 시트의 2페이지 정보 구조를 인식할 수 있다.
- RVTT 자체 그래픽을 사용한다.
- 능력치, 내성, 기술, HP, 공격, Feature, Feat, 주문과 장비가 실제 서버 상태와 일치한다.
- 시트에서 굴림과 실행 가능한 행동을 시작할 수 있다.
- 시트와 Hotbar가 동일 Capability를 사용한다.
- 자유 서술 필드와 규칙 필드의 편집 권한이 분리된다.
- Feature, Feat와 사용자 콘텐츠가 하드코딩 없이 표시된다.
- 권한 없는 사용자가 비공개 시트 정보를 받지 않는다.
- 전투 중 반응·주사위·DM 승인 UI가 시트보다 우선한다.
- 재접속, 큰 목록, 한국어 지역화와 접근성 설정이 검증된다.
