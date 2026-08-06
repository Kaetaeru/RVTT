# ADR-0039: 전투 HUD는 Baldur's Gate 3형 배치와 문맥 행동 흐름을 기준으로 한다

- 상태: 확정
- 결정일: 2026-08-03
- 관련 문서:
  - [`ADR-0004`](ADR-0004-baldurs-gate-style-session-interaction.md)
  - [`ADR-0010`](../ui/common-input/common-input-grammar.md)
  - [`ADR-0023`](ADR-0023-composable-targeting-and-spatial-query-model.md)
  - [`ADR-0025`](ADR-0025-typed-rule-events-timing-windows-and-usage-gates.md)
  - [`ADR-0033`](ADR-0033-server-authoritative-dice-rolls-and-presentation-gated-resolution.md)
  - [`ADR-0034`](ADR-0034-encounter-initiative-turn-order-and-control-authority.md)
  - [`ADR-0036`](ADR-0036-observer-relative-perception-senses-stealth-and-rule-points.md)
  - [`33. Baldur's Gate 3형 전투 HUD와 행동 UI 모델`](../ui/combat-hud/baldurs-gate-style-combat-hud.md)

## 배경

RVTT는 D&D 규칙을 실행하는 VTT이면서, 플레이어에게는 전술 RPG처럼 직관적으로 보여야 한다.

사용자는 Baldur's Gate 3의 PC 전투 UI를 제품 기준점으로 삼기를 원한다.

특히 다음 요소가 중요하다.

- 상단 중앙의 이니셔티브 순서
- 왼쪽 세로 파티 패널
- 하단 왼쪽의 현재 Actor 상태
- 하단 중앙의 행동·주문·아이템 Hotbar
- 하단 오른쪽의 턴 종료와 행동 자원
- 전장 위 이동 경로, 대상 윤곽, 명중률과 범위 미리보기
- 우측의 접을 수 있는 전투 로그
- 사건 발생 시 열리는 반응·승인 창
- 필요할 때만 상세 정보를 보여주는 툴팁 계층

그러나 UI가 직접 규칙을 계산하거나, 아이콘별로 전용 실행 코드를 가지면 다음 문제가 생긴다.

- Feature, Feat, 주문, 아이템과 사용자 NPC 콘텐츠가 추가될 때마다 UI 코드를 수정해야 한다.
- 서버가 허용하지 않은 행동을 클라이언트가 실행하거나 잘못 미리보기할 수 있다.
- 이니셔티브, 주사위 연출, 반응창과 대상 선택 상태가 서로 어긋날 수 있다.
- 플레이어, DM, 위임받은 NPC와 자동화 Actor가 서로 다른 UI 경로를 갖게 된다.
- UI 재배치나 접근성 설정이 규칙 코드에 영향을 준다.

Baldur's Gate 3의 화면 배치와 조작 흐름은 기준점으로 사용하되, 그래픽 자산, 로고, 아이콘, 텍스처, 폰트와 고유 아트 표현은 RVTT용으로 자체 제작한다.

## 결정

RVTT의 기본 PC 전투 HUD는 Baldur's Gate 3형 화면 배치를 사용한다.

```text
                         InitiativeRibbon

PartyRail                  3D Battlefield                 Minimap
                        Contextual World Feedback
                                                         CombatLog

ActiveActorPanel       ActionHotbar + ResourceRail       EndTurnControl
```

UI는 규칙 상태를 소유하지 않는다.

```text
서버 권위 상태
├─ EncounterSession
├─ TurnState
├─ ActionOpportunity
├─ CapabilitySnapshot
├─ TargetingPlan
├─ PreviewOutcome
├─ RollPresentationSession
└─ EffectResolutionState

→ UI Projection Model
→ 플레이어 HUD
```

UI의 모든 실행 요청은 의미 명령으로 서버에 전달한다.

```text
SelectActor
SelectCapability
SelectVariant
PreviewTarget
ConfirmAction
CancelAction
EndTurn
RespondToOpportunity
```

아이콘이 피해, 상태, 이동이나 자원을 직접 변경하지 않는다.

## 기본 화면 영역

### 상단 중앙: InitiativeRibbon

전투 참가자의 순서, 현재 턴, 턴 완료 여부, 그룹 턴과 대기 중 기회를 표시한다.

```text
InitiativeEntryView
├─ entryId
├─ portrait
├─ displayName
├─ factionStyle
├─ currentTurn
├─ completedThisRound
├─ sharedTurnGroup
├─ controllableByViewer
├─ knownConditions[]
└─ visibilityLevel
```

인지하지 못한 적은 이니셔티브 리본에 실제 정체나 초상화를 노출하지 않는다.

### 왼쪽: PartyRail

현재 플레이어가 선택하거나 조작할 수 있는 PC, 동료 NPC와 소환체를 세로 목록으로 표시한다.

소유권, 제어권과 정보 공개는 분리한다.

### 하단 왼쪽: ActiveActorPanel

현재 선택된 Actor의 초상화, HP, 임시 HP, 주요 상태, 집중, 이동력과 핵심 자원을 표시한다.

상세 캐릭터 시트 전체를 이 영역에 넣지 않는다.

### 하단 중앙: ActionHotbar

행동, 주문, 아이템, 특성, 패시브와 사용자 단축키를 하나의 Hotbar 시스템으로 표시한다.

Hotbar 항목은 `CapabilityPresentation`에서 자동 생성한다.

```text
CapabilityPresentation
├─ capabilityId
├─ iconId
├─ localizedName
├─ category
├─ resourceCostSummary
├─ availabilityState
├─ disabledReasons[]
├─ variantCount
├─ targetingSummary
├─ tooltipData
└─ preferredSlot?
```

Feature나 Feat가 새로운 ActionCapability를 부여하면 별도 HUD 코드 없이 Hotbar에 나타나야 한다.

### 하단 오른쪽: EndTurnControl

턴 종료, 그룹 턴 완료, 반응 건너뛰기와 대기 중인 승인 문맥을 명확히 표시한다.

현재 실행 중인 행동이나 필수 선택이 있으면 종료 요청 전에 경고한다.

### 전장 중앙: ContextualWorldFeedback

이동 경로, 목적지, 대상 윤곽, 사거리, 효과 범위, 엄폐, 시야, 예상 명중률, 영향을 받는 대상과 실행 불가 이유를 월드 공간에 표시한다.

### 우측: CombatLog

접을 수 있는 로그 패널로 굴림, 수정치, 이점·불리점, 피해, 상태, 자원 소비와 DM 판정을 기록한다.

### 문맥 팝업: OpportunityPrompt

반응, 전설적 행동, DM 승인, 재굴림, 피해 대체와 기타 TimingWindow 기회를 표시한다.

## 입력 교과서 연결

기존 공통 입력 교과서를 유지한다.

```text
Q
→ 현재 선택·대상 지정·하위 메뉴 취소
→ 대기 상태에서는 이전 문맥으로 복귀

E
→ 현재 미리보기 승인·행동 실행·상호작용 확정
→ 반응창에서는 사용 승인

1–5
→ 현재 HUD 문맥의 주요 빠른 슬롯
```

`1–5`는 Hotbar 전체의 고정 첫 다섯 칸이 아니라 현재 문맥에서 활성화된 주요 선택 슬롯이다.

예:

```text
일반 턴
1–5 = 사용자 지정 주요 행동

주문 변형 메뉴
1–5 = 주문 슬롯 레벨 또는 변형

반응 팝업
1–5 = 사용 가능한 반응 선택
```

ESC는 핵심 게임 입력으로 사용하지 않는다.

## 행동 선택 상태 기계

```text
idle
→ capability_selected
→ variant_selection?
→ targeting
→ preview_ready
→ confirming
→ roll_presenting?
→ resolving
→ completed
```

취소 가능한 상태에서는 Q가 한 단계만 되돌린다.

실행이 서버에 확정된 뒤에는 Q로 이미 확정된 비용과 결과를 되돌리지 않는다.

## 미리보기와 실제 결과

UI 미리보기는 권위 결과가 아니다.

```text
PreviewRequest
→ 서버가 현재 스냅샷으로 PreviewOutcome 생성
→ 클라이언트가 경로·범위·명중 예상 표시
→ ConfirmAction
→ 서버가 revision 재검증
→ 실제 Roll·Effect 실행
```

명중률, 피해 범위와 영향 대상은 현재 규칙 스냅샷에 기반한 예상치다.

주사위 결과는 ADR-0033에 따라 주사위 연출 공개 이후 확정된다.

## Hotbar 구성

기본 카테고리:

```text
Common
Class
Spells
Items
Passives
Custom
```

실제 카테고리는 직업, 장비와 캠페인 콘텐츠에 따라 확장할 수 있다.

Hotbar는 다음을 지원한다.

- 사용자 슬롯 재배치
- 잠금과 편집 모드
- 여러 줄 높이 조절
- 카테고리 필터
- 상위 행동에서 변형·주문 레벨·공격 프로필 하위 메뉴 열기
- 사용할 수 없는 행동의 비활성화와 이유 표시
- 사용 가능한 자원 수와 회복 조건 표시
- 패시브 토글 상태 표시

저장되는 것은 `capabilityId` 참조와 사용자 배치 정보다.

Capability가 사라지면 슬롯은 안전한 빈 참조 상태가 되며 다른 행동으로 잘못 연결하지 않는다.

## DM HUD

DM은 플레이어 HUD를 기반으로 사용하되 추가 오버레이를 가진다.

```text
DmCombatOverlay
├─ 참가자 추가·제거
├─ 제어권 전환
├─ 숨겨진 Actor 표시
├─ 이니셔티브 수정
├─ 강제 턴 종료
├─ 판정 보정과 결과 대체
├─ NPC 그룹 선택
├─ 비밀 굴림
└─ 공개 범위 전환
```

DM 기능은 일반 Hotbar에 무제한으로 섞지 않고 별도 권한 패널과 문맥 메뉴로 제공한다.

DM이 NPC를 선택하면 동일한 ActiveActorPanel과 ActionHotbar가 해당 NPC의 CapabilitySnapshot을 표시한다.

## 반응 UI

반응과 턴 외 행동은 현재 턴 HUD를 교체하지 않고 상위 문맥으로 열린다.

```text
OpportunityPrompt
├─ 발생 원인
├─ 관련 Actor와 대상
├─ 가능한 반응 목록
├─ 비용
├─ 예상 효과
├─ 자동 사용 정책
├─ E 승인
└─ Q 거절
```

여러 사용자가 반응할 수 있으면 각 사용자에게 허용된 정보만 전달한다.

## 대상 정보 공개

대상 HUD는 PerceptionRelation을 따른다.

```text
정확히 인식
→ 이름, 초상화, 허용된 HP·상태 정보

대략적 위치만 인식
→ 위치 마커와 제한된 설명

미인지
→ UI 없음
```

DM 전용 정보, 비밀 정체, 실제 AC, 숨겨진 저항과 미발견 상태를 클라이언트에 미리 복제하지 않는다.

## 접근성과 화면 크기

다음 설정을 지원한다.

- UI 크기 조절
- Hotbar 행 수
- 전투 로그 자동 접기
- 툴팁 지연 시간
- 색상 외 진영 구분 표시
- 화면 흔들림과 주사위 연출 감소
- 길게 누르기 대신 클릭 확정
- 중요한 오류와 사용 불가 이유의 텍스트 표시

기본 설계 대상은 PC 키보드·마우스다.

게임패드와 모바일은 같은 규칙 Projection을 사용하되 별도 입력·레이아웃 어댑터로 구현한다.

## 성능

- 매 프레임 전체 Capability 목록을 재생성하지 않는다.
- Actor 선택, 자원, 상태, 턴과 가용성 변화에 따른 델타만 갱신한다.
- 월드 미리보기는 현재 선택 행동과 후보 대상만 계산한다.
- 대상 hover는 짧은 클라이언트 캐시를 사용하되 실행 전 서버 재검증한다.
- 숨겨진 Actor와 정보는 클라이언트 최적화를 이유로 미리 복제하지 않는다.

## 결과

- 플레이어는 Baldur's Gate 3와 유사한 전술 RPG형 전투 화면을 사용한다.
- 모든 콘텐츠는 CapabilityPresentation을 통해 같은 HUD에 나타난다.
- Feature, Feat, 주문, 아이템과 사용자 NPC가 UI 전용 코드를 요구하지 않는다.
- 주사위 연출, 대상 지정, 반응과 턴 순서가 같은 서버 상태에 동기화된다.
- DM은 동일한 HUD 구조에서 NPC와 장면 규칙을 제어한다.
- 시각 자산과 브랜드 표현은 RVTT용으로 독립 제작한다.
