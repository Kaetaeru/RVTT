# 33. Baldur's Gate 3형 전투 HUD와 행동 UI 모델

- 상태: 초안
- 작성일: 2026-08-03
- 관련 문서:
  - [`08. 공통 입력 교과서`](../../../common-input/common-input-grammar.md)
  - [`17. 주문 대상·범위·공간 질의 모델`](../../../../systems/rules/spell-targeting-area-and-spatial-query-model.md)
  - [`19. 트리거와 다른 턴 실행 모델`](../../../../systems/rules/feat-feature-trigger-and-cross-turn-execution-model.md)
  - [`20. 능동형 특성과 행동 내부 실행 모델`](../../../../systems/rules/active-feature-and-action-container-execution-model.md)
  - [`21. 패시브 특성 모델`](../../../../architecture/passive-modifier-and-rule-override-model.md)
  - [`22. EffectRecipe와 효과 해결·확정 모델`](../../../../architecture/effect-recipe-resolution-and-commit-model.md)
  - [`27. 주사위 굴림·연출·결과 확정 모델`](../../../../systems/combat/dice-roll-presentation-and-resolution-gating-model.md)
  - [`28. 인카운터·주도권·턴과 제어권 모델`](../../../../systems/combat/encounter-initiative-turn-and-control-authority-model.md)
  - [`30. 시야·감각·은신·탐지 모델`](../../../../systems/perception/visibility-senses-stealth-and-detection-model.md)
  - [`ADR-0039`](../../../../decisions/ADR-0039-baldurs-gate-style-combat-hud-and-contextual-action-ui.md)

## 1. 문서 목적

이 문서는 RVTT의 PC 전투 UI를 Baldur's Gate 3의 정보 배치와 행동 선택 흐름에 가깝게 구성하면서, RVTT의 서버 권위 규칙·주사위 연출·DM 진행 방식과 연결하는 구조를 정의한다.

대상:

- 상단 이니셔티브 리본
- 왼쪽 파티·제어 Actor 패널
- 하단 현재 Actor 패널
- 행동·주문·아이템 Hotbar
- 행동·보너스 행동·반응·이동력과 기타 자원 표시
- 턴 종료 제어
- 이동 경로와 목적지 표시
- 대상 윤곽, 명중률, 사거리, 시야와 엄폐 표시
- 범위·다중 대상·연쇄 대상 미리보기
- 행동 변형과 주문 슬롯 레벨 선택
- 반응·DM 승인·재굴림 팝업
- 주사위 연출 중 HUD 전환
- 전투 로그와 상세 계산
- DM의 NPC·인카운터 제어 오버레이
- Feature·Feat·주문·아이템·사용자 콘텐츠 자동 표시
- UI 저장, 재접속, 성능과 접근성

핵심 원칙:

```text
BG3형 화면 배치와 선택 흐름
+ RVTT 서버 권위 규칙
+ RVTT 공통 입력 교과서
```

```text
UI는 규칙을 실행하는 주체가 아니다.
UI는 현재 가능한 규칙 선택지를 보여주고 의미 명령을 보낸다.
```

---

## 2. 기본 화면 배치

16:9 PC 화면 기준 기본 배치:

```text
┌──────────────────────────────────────────────────────────────┐
│                    InitiativeRibbon                          │
│                                                              │
│ PartyRail              3D Battlefield              Minimap   │
│                       World Feedback                         │
│                                                   CombatLog  │
│                                                              │
│ ActiveActorPanel     ActionHotbar + ResourceRail   End Turn  │
└──────────────────────────────────────────────────────────────┘
```

UI는 화면 가장자리를 사용하고 중앙 전장을 가능한 한 비워 둔다.

기본 레이어 순서:

```text
WorldScene
→ WorldFeedbackLayer
→ PersistentHudLayer
→ TooltipLayer
→ ContextPromptLayer
→ DicePresentationLayer
→ CriticalModalLayer
```

주사위는 HUD 뒤가 아니라 HUD보다 높은 전용 로컬 프레젠테이션 레이어에서 표시한다.

---

## 3. HUD Projection 구조

클라이언트는 여러 서버 상태를 그대로 조합하지 않고, 서버가 만든 뷰 전용 Projection을 받는다.

```text
CombatHudProjection
├─ viewerId
├─ selectedActorView
├─ partyViews[]
├─ initiativeView
├─ actionBarView
├─ resourceView
├─ currentInteractionContext
├─ pendingOpportunityViews[]
├─ targetPreviewView?
├─ movementPreviewView?
├─ dicePresentationView?
├─ logDelta[]
└─ revision
```

Projection에는 해당 플레이어가 볼 수 있는 정보만 들어간다.

UI가 추론해서는 안 되는 항목:

- 적의 실제 AC
- 숨겨진 저항과 면역
- 미발견 상태
- 비밀문의 존재
- 미인지 Actor의 위치
- DM 전용 행동
- 봉인된 주사위 결과

---

## 4. InitiativeRibbon

### 4.1 표시 위치와 구조

상단 중앙에 가로 리본으로 배치한다.

```text
[PC A] [적 A] [PC B] [적 그룹] [동료]
  완료   현재턴   대기     미행동      행동불가
```

표시 요소:

- 초상화 또는 토큰 썸네일
- 진영 프레임
- 현재 턴 강조
- 이미 턴을 마친 엔트리의 어둡게 표시
- 행동 불가·무의식·사망 아이콘
- 집중과 주요 상태 아이콘
- 그룹 이니셔티브 묶음 표시
- 같은 진영 연속 턴 구간
- 대기 중인 전설적 행동·반응 표시

### 4.2 조작

자신이 제어할 수 있는 엔트리를 클릭하면 해당 Actor를 선택한다.

같은 공유 턴 그룹 안에서는 아직 행동 가능한 Actor 사이를 자유롭게 전환할 수 있다.

```text
공유 턴 그룹
→ Actor A 이동
→ Actor B 공격
→ Actor A 보너스 행동
```

그룹의 모든 Actor가 완료되기 전에는 그룹 전체가 턴 완료로 표시되지 않는다.

### 4.3 숨겨진 참가자

인지하지 못한 참가자는 실제 초상화나 이름으로 표시하지 않는다.

정책 예:

```text
fully_hidden
→ 이니셔티브 리본 항목 자체를 숨김

unknown_presence
→ 물음표 엔트리만 표시

known_presence
→ 알 수 없는 적 초상화 표시

identified
→ 실제 정보 표시
```

DM은 모든 엔트리를 볼 수 있다.

### 4.4 전투 중 합류

증원이 이니셔티브에 삽입되면 안전 경계에서 리본이 애니메이션으로 확장된다.

현재 진행 중인 공격이나 주사위 연출 도중에 리본 순서를 즉시 재정렬하지 않는다.

---

## 5. PartyRail

### 5.1 목적

화면 왼쪽에 현재 플레이어가 빠르게 선택할 수 있는 Actor를 세로로 표시한다.

대상:

- 플레이어 캐릭터
- 제어 위임된 동료 NPC
- 소환체
- 탈것 또는 특별 제어 Actor

### 5.2 표시 정보

```text
PartyActorView
├─ portrait
├─ localizedName
├─ hpRatio
├─ temporaryHp
├─ vitalState
├─ concentration
├─ majorConditions[]
├─ currentTurnState
├─ controlSource
└─ connectionState
```

HP는 빠른 판단용 비율과 간략 수치만 보여준다.

상세 내성, 능력치와 전체 효과 목록은 선택 후 상세 패널이나 시트에서 확인한다.

### 5.3 소환체와 그룹

소환체는 소유 Actor 아래에 들여쓰기하거나 접을 수 있는 하위 그룹으로 표시한다.

```text
마법사
├─ 익숙한 동물
└─ 소환 정령
```

많은 소환체가 있을 때 PartyRail이 화면 전체를 점유하지 않도록 접기와 요약 배지를 제공한다.

---

## 6. ActiveActorPanel

### 6.1 위치

화면 하단 왼쪽에 배치한다.

### 6.2 기본 정보

```text
ActiveActorPanel
├─ 큰 초상화
├─ 이름과 레벨·분류
├─ 현재 HP / 최대 HP
├─ 임시 HP
├─ 이동력
├─ 행동 경제
├─ 집중
├─ 주요 상태
├─ 현재 무기 세트
└─ 제어자 표시
```

### 6.3 HP 표시

HP 바는 다음을 구분한다.

```text
현재 HP
임시 HP
최대 HP 감소
죽음 내성 상태
안정화 상태
```

정확한 HP를 볼 권한이 없는 NPC는 단계형 표현을 사용할 수 있다.

```text
멀쩡함
부상
중상
빈사
```

### 6.4 상태 아이콘

주요 상태는 최대 개수를 제한하고 중요도 순으로 표시한다.

나머지는 `+N` 묶음에서 확인한다.

커서를 올리면 출처, 남은 기간과 규칙 효과를 보여준다.

---

## 7. ResourceRail

행동 Hotbar 주변에 현재 턴과 캐릭터 자원을 별도 표시한다.

```text
행동           ●
보너스 행동    ●
반응           ●
이동력         18 / 30 ft
주문 슬롯      ●●● / ●● / ●
직업 자원      ◆◆◇
특수 자원      아이콘 + 수치
```

### 7.1 행동 경제

행동, 보너스 행동과 반응은 단순 색상만이 아니라 모양·문자와 툴팁으로도 구분한다.

소비되면 빈 외곽선으로 변경한다.

추가 행동처럼 임시 자원이 있으면 별도 배지로 나타낸다.

### 7.2 이동력

현재 남은 거리와 기본 총 이동력을 표시한다.

Dash 등으로 추가된 이동력은 분리해서 보여줄 수 있다.

```text
기본 이동 30 ft
추가 이동 30 ft
현재 남음 42 ft
```

### 7.3 기타 자원

자원은 `ResourcePresentation` 데이터로 자동 표시한다.

```text
ResourcePresentation
├─ resourceId
├─ iconId
├─ localizedName
├─ current
├─ maximum
├─ displayMode
├─ recoverySummary
└─ priority
```

직업이나 Feat 이름으로 UI 분기하지 않는다.

---

## 8. ActionHotbar

### 8.1 기본 형태

화면 하단 중앙에 정사각형 아이콘 그리드로 배치한다.

기본은 2행이며 사용자가 1~4행으로 조절할 수 있다.

```text
[공격] [질주] [이탈] [회피] [도움] [숨기]
[주문] [특성] [물약] [두루마리] [투척] [사용]
```

### 8.2 카테고리 탭

```text
Common
Class
Spells
Items
Passives
Custom
```

필요하면 다음처럼 확장할 수 있다.

```text
Weapon
Cantrips
Prepared
Consumables
Reactions
NpcActions
```

탭은 UI 필터일 뿐 Capability의 실제 소유 구조를 바꾸지 않는다.

### 8.3 자동 생성

Hotbar 후보는 현재 Actor의 CapabilitySnapshot에서 생성한다.

```text
CapabilitySnapshot
→ CapabilityPresentationCompiler
→ ActionBarEntryView
```

따라서 다음 콘텐츠는 같은 방식으로 표시된다.

- 기본 행동
- 직업 특성
- Feat 행동
- 종족 특성
- 주문
- 무기 행동
- 무기 숙련
- 아이템 사용
- NPC 고유 행동
- DM JSON NPC 행동

### 8.4 사용자 구성

지원 기능:

- 드래그 앤 드롭
- 슬롯 잠금
- 빈 슬롯 생성
- 행 수 조절
- 아이콘 크기 조절
- 카테고리 탭별 배치
- 사용자 지정 `1–5` 빠른 슬롯
- 기본 배치로 초기화

저장 구조:

```text
UserHotbarLayout
├─ actorDefinitionId 또는 characterId
├─ categoryLayouts
├─ quickSlots[1..5]
├─ rowCount
├─ locked
└─ revision
```

Hotbar 배치는 캐릭터별로 저장한다.

### 8.5 가용성 표시

아이콘 상태:

```text
enabled
conditional
out_of_resource
invalid_context
no_valid_target
on_cooldown
suppressed
unknown
```

사용할 수 없는 이유는 하나만 보여주지 않고 우선순위가 높은 이유와 추가 이유를 툴팁에 표시한다.

예:

```text
사용할 수 없음
- 행동을 이미 사용함
- 대상이 사거리 밖임
```

`no_valid_target`은 대상 상태가 자주 바뀌는 경우 매 프레임 전체 월드를 검색해서 계산하지 않는다.

행동을 선택했을 때 후보 검색을 수행한다.

---

## 9. 행동 변형과 하위 메뉴

하나의 행동에서 여러 선택이 파생될 수 있다.

예:

- 주문 슬롯 레벨
- 무기 공격 방식
- 피해 유형 선택
- 원소 선택
- 여러 소환 형태
- 여러 EffectRecipe 변형
- 다중공격 구성

### 9.1 변형 메뉴

```text
ActionHotbar 아이콘 선택
→ VariantTray 열림
→ 1–5 또는 클릭으로 변형 선택
→ Targeting 시작
```

`VariantTray`는 Hotbar 위에 가로로 열리고 전장을 최소한으로 가린다.

### 9.2 최근 선택 기억

행동별로 마지막 변형을 기억할 수 있다.

단, 서버가 현재 허용하지 않는 변형을 자동 선택하지 않는다.

### 9.3 즉시 실행과 하위 메뉴

변형이 하나뿐이면 하위 메뉴를 생략한다.

변형이 여러 개지만 기본값이 명확한 행동은:

```text
클릭
→ 기본 변형

보조 클릭 또는 길게 누르기
→ 전체 변형 메뉴
```

방식을 선택적으로 지원할 수 있다.

---

## 10. 행동 선택 상태 기계

```text
idle
├─ actor_selected
├─ capability_selected
├─ variant_selection
├─ source_selection
├─ targeting
├─ target_sequence
├─ preview_ready
├─ confirmation_pending
├─ submitted
├─ roll_presenting
├─ resolution_pending
├─ result_presenting
└─ completed
```

### 10.1 Q 동작

```text
variant_selection
→ capability_selected로 복귀

targeting
→ 선택 대상 제거 또는 capability_selected로 복귀

target_sequence
→ 마지막 대상 하나 취소

preview_ready
→ targeting으로 복귀

idle
→ 아무 행동도 하지 않음
```

### 10.2 E 동작

```text
preview_ready
→ 행동 제출

상호작용 후보
→ 상호작용 확정

OpportunityPrompt
→ 선택한 기회 승인
```

E는 현재 화면에서 명확한 하나의 승인 의미만 가져야 한다.

### 10.3 입력 문맥 표시

화면 하단에 현재 의미를 작게 표시한다.

```text
Q 취소     E 화염구 시전     1–3 슬롯 레벨
```

---

## 11. 이동 UI

### 11.1 기본 이동

행동이 선택되지 않은 상태에서 전장 지점을 가리키면 이동 미리보기를 표시한다.

```text
현재 위치
→ 경로선
→ 중간 꺾임점
→ 목적지 링
```

### 11.2 거리 구간

경로를 구간별로 표시한다.

```text
기본 이동력 내
추가 이동이 필요한 구간
도달 불가능 구간
험지 구간
위험 구간
```

색상 외에도 선 모양과 표식을 달리한다.

### 11.3 이동 결과 미리보기

```text
소모 거리
남은 이동력
유발 가능한 기회 공격
위험 표면 진입
점프·등반 필요
문 상호작용 필요
```

기회 공격은 확정 결과가 아니라 현재 알려진 적과 규칙에 따른 위험 후보로 표시한다.

숨겨진 적의 존재를 미리 노출해서는 안 된다.

### 11.4 클릭·WASD 공통 상태

클릭 이동과 WASD 직접 이동은 같은 서버 이동 예산을 사용한다.

HUD의 남은 이동력도 동일한 `MovementBudgetProjection`을 표시한다.

---

## 12. 대상 선택 UI

### 12.1 Hover 표시

대상 위에 커서를 두면 다음을 표시할 수 있다.

```text
이름
진영
인지 가능한 HP 상태
주요 상태
거리
선택 가능 여부
```

실제 정보를 볼 권한이 없으면 제한된 정보만 표시한다.

### 12.2 윤곽

기본 범주:

```text
적대 대상
우호 대상
중립 대상
현재 선택
영향 예정
유효하지 않음
```

색상만 사용하지 않고 외곽선 패턴과 아이콘을 함께 사용한다.

### 12.3 대상 카드

행동을 선택한 동안 화면 상단 또는 대상 근처에 작은 카드가 열린다.

```text
TargetPreviewCard
├─ 대상 이름
├─ 거리
├─ 예상 명중률 또는 내성 정보
├─ 이점·불리점
├─ 엄폐
├─ 시야 상태
├─ 예상 피해·회복 범위
├─ 상태 적용 후보
└─ 사용 불가 이유
```

적 AC나 내성 수치를 직접 공개하지 않더라도 계산 결과인 예상 확률을 표시할 수 있다.

캠페인 설정으로 명중률 표시를 끌 수 있다.

---

## 13. 공격 미리보기

### 13.1 흐름

```text
공격 선택
→ 공격 프로필 또는 변형 선택
→ 대상 Hover
→ 서버 PreviewRequest
→ 명중률·사거리·엄폐·불리점 표시
→ E 또는 클릭으로 확정
→ 주사위 연출
→ 명중 결과 공개
→ 명중 시 피해 주사위 연출
```

### 13.2 예상 명중률

표시 예:

```text
75%
이점
높은 지대
대상 반엄폐
```

수정 원인은 `ModifierExplanation`에서 가져온다.

```text
ModifierExplanation
├─ sourceId
├─ localizedLabel
├─ category
├─ effectSummary
└─ visibilityPolicy
```

숨겨진 적 능력의 정확한 이름은 표시하지 않고 결과만 제한적으로 보여줄 수 있다.

### 13.3 피해 예상

```text
예상 피해 7–18
참격
추가 화염 1–4
```

저항·취약성을 알고 있는지에 따라 표시 수준을 제한한다.

```text
알고 있음
→ 저항 반영 예상치

모름
→ 원래 피해 범위만 표시
```

### 13.4 치명타

치명타 범위와 현재 확률을 규칙상 공개 가능한 경우 툴팁에서 보여준다.

화면 중앙 기본 카드에는 과도한 통계를 넣지 않는다.

---

## 14. 주문과 범위 효과 UI

### 14.1 지점 지정

범위 주문 선택 시 전장에 실제 3D 템플릿을 표시한다.

```text
sphere
cylinder
cone
line
cube
wall
custom shape
```

### 14.2 영향 대상

템플릿 내부 대상은 실시간으로 강조한다.

```text
적 3
아군 1
오브젝트 2
```

아군 피해 가능성이 있으면 별도 경고를 표시한다.

### 14.3 효과선과 차단

범위가 시각적으로 겹치더라도 Line of Effect에 막힌 대상은 다른 패턴으로 표시한다.

```text
범위 안 + 효과선 통과
→ 영향 예정

범위 안 + 효과선 차단
→ 차단됨
```

### 14.4 주문 슬롯 레벨

주문 선택 후 슬롯 레벨이 여러 개라면 `VariantTray`에서 선택한다.

```text
3레벨  4레벨  5레벨
[ 1 ]  [ 2 ]  [ 3 ]
```

각 변형에 현재 슬롯 개수와 변화하는 피해·대상 수를 표시한다.

---

## 15. 다중 대상과 순차 선택

다중 대상 행동은 선택한 대상을 화면에 번호로 표시한다.

```text
① 고블린 A
② 고블린 B
③ 고블린 C
```

HUD에는 다음을 표시한다.

```text
대상 2 / 3
Q 마지막 대상 취소
E 현재 대상으로 확정
```

동일 대상 중복 허용 여부는 TargetingPlan이 결정한다.

여러 공격이 각각 독립 굴림인 경우 하나의 합산 미리보기로 속이지 않는다.

```text
광선 1 → 대상 A
광선 2 → 대상 A
광선 3 → 대상 B
```

각 하위 공격은 실행 시 개별 RollPresentationSession을 가질 수 있다.

연출 설정에 따라 빠른 배치 굴림으로 묶을 수 있다.

---

## 16. 상호작용 UI

문, 레버, 상자, 함정과 비밀문은 현재 인식·권한·거리 조건을 만족하면 전장에 문맥 프롬프트를 표시한다.

```text
[E] 문 열기
[E] 레버 작동
[E] 상자 열기
[E] 함정 해제
```

여러 상호작용이 겹치면 작은 선택 목록을 연다.

상호작용에 판정이 필요하면:

```text
상자 선택
→ 자물쇠 따기
→ 사용할 도구·Feature 선택
→ 예상 보너스 표시
→ E 확정
→ 주사위 연출
```

흔한 문 열기는 불필요하게 Hotbar 행동을 거치지 않고 문맥 상호작용으로 실행할 수 있다.

행동 경제가 필요한 전투 문맥에서는 서버가 비용을 표시하고 검증한다.

---

## 17. 주사위 연출과 HUD

### 17.1 RollPresentation 진입

행동이 제출되고 서버가 굴림 결과를 봉인하면 HUD는 `roll_presenting` 상태로 전환한다.

```text
Hotbar
→ 입력 잠금 또는 제한

대상 카드
→ 유지

주사위
→ 카메라 뒤에서 중앙으로 진입
```

### 17.2 입력 정책

주사위 연출 중 허용:

- 카메라의 제한적 이동
- 로그 보기
- 연출 스킵
- 접근성 메뉴

기본적으로 금지:

- 새로운 행동 제출
- Actor 제어 전환
- 현재 대상 변경
- 턴 종료

### 17.3 결과 공개

```text
주사위 결과 공개
→ 명중·실패 카드 갱신
→ 후속 굴림이 있으면 다음 주사위
→ 결과 프레젠테이션
→ idle 또는 다음 선택 상태
```

주사위가 보이기 전에 대상 HP, 이니셔티브 순서나 상태 아이콘이 먼저 변하지 않는다.

---

## 18. EndTurnControl

### 18.1 기본 상태

화면 하단 오른쪽에 독립된 큰 버튼으로 표시한다.

```text
턴 종료
그룹 턴 완료
반응 건너뛰기
기회 패스
대기 취소
```

### 18.2 경고

남은 행동이나 이동이 있어도 기본적으로 턴 종료는 허용한다.

다음 상황에서는 확인 또는 차단할 수 있다.

- 필수 대상 선택 중
- 제출된 행동 해결 중
- 열린 반응창
- 아직 해결하지 않은 강제 선택
- DM이 설정한 턴 종료 확인 정책

### 18.3 턴 종료 취소

서버가 아직 다음 TurnStarted를 확정하지 않았고 정책이 허용하면 짧은 취소 창을 제공할 수 있다.

이미 다음 턴이 시작되었으면 로컬 UI만으로 되돌리지 않는다.

---

## 19. OpportunityPrompt

### 19.1 대상

- 반응
- 기회 공격
- 방어 주문
- 피해 감소
- 재굴림
- 전설적 저항
- 전설적 행동
- 준비 행동
- DM 승인
- 선택형 TriggerCapability

### 19.2 배치

화면 중앙 하단 또는 우측 중앙에 Hotbar보다 높은 레이어로 표시한다.

전장과 발생 대상이 계속 보이도록 완전한 전체 화면 모달은 피한다.

### 19.3 정보

```text
OpportunityPromptView
├─ 제목
├─ 발생 원인
├─ 원인 Actor
├─ 대상
├─ 선택지[]
├─ 비용
├─ 예상 효과
├─ 제한 시간 정책
├─ 자동 사용 설정
└─ 공개 가능한 규칙 설명
```

### 19.4 입력

```text
1–5
→ 선택지 선택

E
→ 선택지 사용

Q
→ 사용하지 않음
```

선택지가 하나면 E로 즉시 승인할 수 있다.

---

## 20. Tooltip 계층

### 20.1 간단 툴팁

짧은 hover에서:

```text
이름
행동 종류
핵심 효과
비용
사용 불가 이유
```

### 20.2 확장 툴팁

지정 키 또는 긴 hover에서:

```text
피해·회복 공식
명중·내성 방식
사거리·범위
지속 시간
집중 여부
자원 회복 조건
관련 상태
규칙 출처
```

### 20.3 중첩 키워드

툴팁 안의 상태·피해 유형·규칙 키워드에 추가 설명을 열 수 있다.

화면 밖으로 무한히 확장하지 않도록 최대 중첩 깊이와 위치 보정을 둔다.

---

## 21. CombatLog

### 21.1 위치

우측에 접을 수 있는 패널로 표시한다.

기본은 최근 결과 몇 줄만 보이고, 클릭하면 전체 로그가 열린다.

### 21.2 로그 구조

```text
CombatLogEntry
├─ timestamp
├─ encounterId
├─ executionId
├─ actorView
├─ targetViews[]
├─ summary
├─ rollBreakdown?
├─ modifierBreakdown?
├─ effectBreakdown?
├─ visibilityPolicy
└─ expandableDetails
```

### 21.3 예시

```text
야만전사가 고블린을 공격했다.
공격: 14 + 5 = 19 — 명중
피해: 1d12(8) + 3 = 11 참격
```

### 21.4 비밀 굴림

DM 비밀 굴림은 플레이어 로그에 결과를 노출하지 않는다.

정책에 따라 다음만 표시할 수 있다.

```text
판정이 발생했다.
DM이 비밀 판정을 해결했다.
아무 로그도 표시하지 않음.
```

---

## 22. DMCombatOverlay

### 22.1 기본 원칙

DM도 같은 전투 HUD를 사용한다.

NPC를 선택하면 해당 NPC의 ActiveActorPanel과 ActionHotbar가 열린다.

DM 전용 기능은 별도 오버레이에 둔다.

### 22.2 기능

```text
참가자 추가·제거
진영 변경
NPC 그룹 선택
제어권 위임·회수
이니셔티브 수정
턴 강제 종료
전투 일시정지
Actor 숨김·공개
비밀 굴림
HP·상태 RuleOverride
현재 대상 정보 공개 수준 변경
전투 종료
```

### 22.3 다중 NPC 그룹 턴

그룹 이니셔티브에서는 아직 행동 가능한 NPC가 PartyRail 대신 임시 `NpcGroupRail`로 표시될 수 있다.

```text
고블린 그룹
[고블린 A: 행동 남음]
[고블린 B: 완료]
[고블린 C: 이동 남음]
```

DM은 이 목록에서 빠르게 전환한다.

### 22.4 DM 정보와 플레이어 화면 분리

DM의 선택 윤곽, 숨겨진 TriggerVolume, Fog 편집 후보와 비밀 정보는 플레이어에게 복제하지 않는다.

---

## 23. 탐험 모드와 전투 모드

같은 HUD 구성 요소를 사용하되 전투 밖에서는 축소한다.

```text
탐험
├─ InitiativeRibbon 숨김
├─ ResourceRail 축소
├─ EndTurnControl 숨김
├─ ActionHotbar 유지 또는 축소
└─ 문맥 상호작용 강조

전투
├─ InitiativeRibbon 표시
├─ 행동 경제 표시
├─ EndTurnControl 표시
└─ 전투 대상 미리보기 활성화
```

전투 전환 시 Hotbar를 다시 생성하지 않고 현재 Actor의 Projection을 전투 문맥으로 갱신한다.

---

## 24. Feature·Feat 호환

Feature와 Feat는 UI 요소를 직접 생성하지 않고 Capability와 Presentation 데이터를 제공한다.

### 24.1 능동형 Feat

```text
Feat
→ ActionCapability 부여
→ CapabilityPresentation 제공
→ Hotbar 후보 자동 생성
```

### 24.2 패시브 토글

```text
Feat
→ ToggleCapability
→ Passives 탭에 표시
→ 활성 상태 아이콘 표시
```

### 24.3 반응

```text
Feat
→ TriggerCapability
→ ActionOpportunity 생성
→ OpportunityPrompt 자동 표시
```

### 24.4 행동 변형

```text
Feat
→ 기존 공격의 VariantCapability 추가
→ 공격 아이콘의 VariantTray에 자동 추가
```

### 24.5 문맥 수정

명중률, 비용, 사거리와 대상 가능 여부는 PreviewOutcome에 반영한다.

UI에서 특정 Feat ID를 확인해 숫자를 수정하지 않는다.

---

## 25. 아이콘과 시각 자산

Baldur's Gate 3의 구조와 정보 계층은 참고하지만 다음은 RVTT용으로 자체 제작한다.

- 아이콘
- 프레임
- 버튼 텍스처
- 초상화 프레임
- 폰트 조합
- 커서
- 상태 표시
- 진영 색상과 패턴
- 사운드
- 애니메이션

RVTT 아트 방향은 판타지 금속·석재·양피지 느낌을 사용할 수 있지만, 원본 게임 자산의 직접 복사나 추출을 전제로 하지 않는다.

---

## 26. 화면 크기와 반응형 배치

### 26.1 PC 기준

기본 설계 범위:

```text
16:9
1920×1080 기준
1280×720 최소 지원
울트라와이드 지원
```

### 26.2 축소 정책

화면이 좁아지면:

1. CombatLog 자동 접기
2. Hotbar 아이콘 축소
3. PartyRail 이름 숨김
4. InitiativeRibbon 간격 축소
5. 상태 아이콘 묶기
6. Hotbar 스크롤 허용

전장 중앙을 가리는 대형 패널로 단순 전환하지 않는다.

### 26.3 게임패드·모바일

같은 `CombatHudProjection`을 사용하지만 별도 레이아웃을 사용한다.

게임패드는 방사형 선택 UI를 고려할 수 있으나 PC Hotbar를 그대로 억지로 조작하게 하지 않는다.

모바일 지원 범위는 별도 ADR에서 확정한다.

---

## 27. UI 상태 저장

저장 대상:

```text
사용자 UI 크기
Hotbar 행 수
Hotbar 잠금
카테고리별 슬롯 배치
1–5 빠른 슬롯
CombatLog 열림 상태
Tooltip 지연 시간
주사위 연출 설정
접근성 설정
```

전투 중 임시 상태:

```text
현재 선택 Actor
현재 선택 Capability
현재 Variant
현재 대상 목록
현재 Preview revision
열린 OpportunityPrompt
```

임시 상태는 서버·클라이언트 세션 복구 규칙에 따라 재구성한다.

이미 무효화된 Preview나 대상 선택은 재접속 후 자동으로 취소한다.

---

## 28. 네트워크와 동기화

### 28.1 델타 갱신

다음 사건에서 관련 UI만 갱신한다.

```text
ActorSelected
TurnStarted
TurnEnded
ResourceChanged
ConditionChanged
CapabilityAvailabilityChanged
ControlAssignmentChanged
InitiativeOrderChanged
OpportunityOpened
OpportunityClosed
RollRevealed
EffectCommitted
```

### 28.2 낙관적 표시

허용 가능한 낙관적 표시:

- Hotbar hover
- 로컬 아이콘 강조
- 커서 위치 기반 범위 고스트
- 로컬 카메라 피드백

서버 확인이 필요한 항목:

- 행동 비용 소비
- 대상 유효성
- 이동 확정
- 주사위 결과
- HP·상태 변경
- 턴 종료
- 반응 사용

### 28.3 revision

모든 행동 제출은 Preview와 Actor 상태의 revision을 포함한다.

서버 상태가 바뀌면:

```text
PreviewStale
→ 새 미리보기 요청
→ 변경 이유 표시
```

예:

```text
대상이 이동하여 사거리 밖이 되었습니다.
다른 효과로 행동 자원이 소비되었습니다.
```

---

## 29. 오류 처리

행동 실행 실패 시 일반 오류 코드가 아니라 사용자가 이해할 수 있는 이유를 표시한다.

```text
대상이 더 이상 유효하지 않습니다.
시야가 차단되었습니다.
주문 슬롯이 부족합니다.
현재 당신이 조작할 수 없는 Actor입니다.
전투 상태가 변경되어 행동을 다시 선택해야 합니다.
```

기술적 세부는 개발 로그에 남기고 플레이어 HUD에는 내부 ID나 스택 트레이스를 노출하지 않는다.

---

## 30. 성능 기준

- 비활성 Hotbar 아이콘마다 Heartbeat 연결을 만들지 않는다.
- 모든 Actor의 명중률을 매 프레임 계산하지 않는다.
- 현재 선택 Capability와 hover 후보만 Preview를 계산한다.
- InitiativeRibbon은 참가자 변화와 상태 델타로 갱신한다.
- PartyRail과 Hotbar는 가상화 또는 재사용 가능한 UI 셀을 사용한다.
- 툴팁은 필요한 순간에 구성하고 캐시한다.
- 월드 윤곽은 선택 대상과 현재 후보만 활성화한다.
- 로그는 페이지 또는 가상 스크롤로 표시한다.
- 숨겨진 정보는 성능 최적화를 이유로 클라이언트에 미리 보내지 않는다.

---

## 31. 테스트 행렬

### 31.1 Hotbar

- Feature 획득 후 새 행동 자동 표시
- Feature 제거 후 안전한 빈 슬롯 처리
- 자원 부족 비활성화
- 패시브 토글 상태 동기화
- 사용자 슬롯 재배치 저장
- DM JSON NPC 행동 표시

### 31.2 대상 지정

- 시야가 필요한 주문
- 위치만 알면 가능한 공격
- 범위 안이지만 효과선이 차단된 대상
- 아군 피해 경고
- 다중 대상 중복 허용·불허
- 대상 이동 후 stale preview

### 31.3 주사위

- 공격 굴림 전 HP 미변경
- 명중 후 피해 굴림 생성
- 빗나감 후 피해 굴림 미생성
- 연출 스킵
- ACK 타임아웃
- 재굴림 UI

### 31.4 턴

- 개별 턴
- 공유 그룹 턴
- Actor 전환
- 남은 행동이 있는 상태에서 턴 종료
- 강제 선택 중 턴 종료 차단
- DM 강제 종료

### 31.5 반응

- 단일 반응
- 여러 반응 선택지
- 여러 플레이어의 동시 적격
- Q 거절
- 자동 사용 정책
- 연결 끊김과 타임아웃

### 31.6 정보 보안

- 미인지 적이 PartyRail·리본·hover에 노출되지 않음
- 비밀 AC와 저항 미노출
- DM 전용 행동 미노출
- 비밀 굴림 결과 미노출
- 위임된 NPC의 비밀 정보 미노출

### 31.7 화면 크기

- 1280×720
- 1920×1080
- 2560×1440
- 울트라와이드
- UI 배율 최대·최소
- CombatLog·Tooltip 동시 표시

---

## 32. 완료 조건

이 기획이 구현 완료로 인정되려면 다음을 만족해야 한다.

- 전투 중 이니셔티브 순서와 현재 턴이 항상 식별 가능하다.
- 플레이어가 제어 가능한 Actor를 왼쪽 패널이나 이니셔티브 리본에서 즉시 전환할 수 있다.
- 모든 능동형 Capability가 공통 Hotbar에 자동 표시된다.
- Feature·Feat·주문·아이템·NPC 행동 때문에 전용 HUD 실행 코드를 추가하지 않는다.
- 대상 지정 전에 사거리, 시야, 엄폐, 비용과 예상 결과를 확인할 수 있다.
- 주사위 결과가 공개되기 전에 명중·피해·이니셔티브 결과가 HUD에 먼저 반영되지 않는다.
- 반응과 턴 외 행동이 현재 턴을 파괴하지 않고 상위 문맥으로 열린다.
- DM이 같은 HUD를 이용해 NPC를 조작하고 별도 오버레이로 전투를 관리할 수 있다.
- 인지하지 못한 정보와 DM 전용 정보가 플레이어 클라이언트에 복제되지 않는다.
- 1280×720에서도 전장 중앙을 과도하게 가리지 않는다.
- 입력 문맥마다 Q, E와 활성화된 1–5의 의미가 화면에 표시된다.
