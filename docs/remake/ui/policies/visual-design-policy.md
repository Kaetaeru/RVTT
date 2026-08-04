# RVTT Visual Design Policy

- 상태: CURRENT
- 문서 종류: Global UI Visual Policy
- 작성일: 2026-08-05
- Policy Work Order: [`CURRENT-WORK-ORDER`](CURRENT-WORK-ORDER.md)
- UI Guide: [`UI, Camera와 Presentation Guide`](../../guides/ui/README.md)
- Shared Wireframe: [`전투 HUD·Character Sheet 공통 UI`](../shared/combat-hud-character-sheet-wireframe-and-shared-ui.md)

이 문서는 RVTT의 모든 HUD, Panel, Modal, Tooltip, Toast, Editor와 DM Workspace가 공유하는 시각 언어를 정의한다.

## 1. 디자인 정체성

RVTT의 시각 방향은 다음 세 요소를 결합한다.

```text
전술 게임의 즉시 판독성
+ 판타지 장부·도구의 분위기
+ 전문 제작 도구의 높은 정보 밀도
```

핵심 문장:

> 장식은 세계관을 보조하고, 정보와 조작을 방해하지 않는다.

- 기본 화면은 어두운 중성 Surface를 사용한다.
- 판타지 장식은 Frame, Divider, Header와 강조점에 제한한다.
- 긴 본문, 수치, 목록 뒤에는 질감이나 강한 장식을 두지 않는다.
- Player와 DM 화면은 같은 Component 언어를 사용하되 DM 권한은 별도 Accent와 Label로 구분한다.
- BG3형 HUD 위계와 전술 전장 중심 구성을 참고하되 Roblox 화면에서 읽기 쉬운 간결한 형태를 우선한다.
- Scene Editor는 게임 HUD보다 장식을 줄이고 전문 도구처럼 보이게 한다.

## 2. Design Token 원칙

Component는 임의의 색·간격·폰트 크기·Corner·Stroke 값을 직접 소유하지 않는다.

```text
Semantic Token
→ Theme Resolver
→ Component Variant
→ 실제 Roblox Property
```

허용 예:

```text
Color.Surface.Panel
Spacing.M
Typography.Body
Radius.Control
Stroke.Focus
Motion.Enter
```

금지 예:

```text
Button.BackgroundColor3 = Color3.fromRGB(...)
Frame.UICorner.CornerRadius = 임의 값
화면별로 서로 다른 Error Red
```

Theme 값이 바뀌어도 Component의 의미와 상태는 유지돼야 한다.

## 3. 기본 색상 Token

아래 값은 최초 Dark Theme 기준값이다. Component는 Hex 값을 직접 참조하지 않고 Semantic Token을 사용한다.

### Surface

| Token | 기본값 | 사용 |
|---|---|---|
| `surface.canvas` | `#0B0D10` | 전체 UI 배경·차단 Overlay 아래 |
| `surface.panel` | `#171A1F` | 일반 Panel |
| `surface.elevated` | `#22262D` | Modal·Popup·선택된 Panel |
| `surface.recessed` | `#101318` | Input·List 내부·Slot |
| `surface.hover` | `#2A3038` | Hover |
| `surface.selected` | `#303A46` | 선택 상태 |
| `surface.scrim` | 검정 55% | Modal 뒤 차단 Scrim |

### Text

| Token | 기본값 | 사용 |
|---|---|---|
| `text.primary` | `#F2EFE8` | 제목·핵심 정보 |
| `text.secondary` | `#BBC0C8` | 설명·보조 수치 |
| `text.muted` | `#818894` | 비활성·메타데이터 |
| `text.inverse` | `#101318` | 밝은 강조 Surface 위 |
| `text.link` | `#77AEDD` | 탐색 가능한 링크 |

### Accent와 상태

| Token | 기본값 | 의미 |
|---|---|---|
| `accent.player` | `#5A92C8` | Player 선택·조작 |
| `accent.dm` | `#C59A52` | DM 권한·저작·Override |
| `state.info` | `#6498D0` | 정보·동기화 |
| `state.success` | `#58A875` | 성공·완료 |
| `state.warning` | `#D0A04A` | 주의·대기 위험 |
| `state.danger` | `#C75D5D` | 실패·파괴·치명 상태 |
| `state.pending` | `#9A82C8` | 제출·처리 중 |
| `state.hidden` | `#737986` | 비공개·미식별 상태의 안전한 표현 |
| `focus.ring` | `#F0C96D` | Keyboard·Critical Focus |

규칙:

- 색은 의미의 유일한 전달 수단이 아니다.
- 상태는 Icon, Label, Pattern, Stroke 또는 위치 변화 중 최소 하나를 함께 사용한다.
- Player Client에 비밀 상태를 색만 바꿔 숨기지 않는다. 공개 가능한 Projection 자체가 달라야 한다.
- `danger`는 파괴적 행동, 치명 오류와 실제 위험에만 사용한다.
- DM Accent를 일반 경고색으로 사용하지 않는다.

## 4. 타이포그래피

실제 Font Family와 Asset은 Roblox Studio에서 한국어 가독성과 렌더링을 검증한 뒤 Token 값으로 확정한다.

### 역할

| Token | 기준 크기 | 사용 |
|---|---:|---|
| `type.caption` | 12 | 짧은 메타데이터·단축키 보조 |
| `type.small` | 14 | Tooltip·보조 설명 |
| `type.body` | 16 | 기본 본문·목록 |
| `type.label` | 18 | Control·Section Label |
| `type.heading` | 22 | Panel Section |
| `type.title` | 28 | 주요 Panel Title |
| `type.display` | 36 | 큰 결과·중요 상태 |

기준:

- 12보다 작은 텍스트를 기본 정보에 사용하지 않는다.
- 긴 본문은 `body` 이상을 사용한다.
- 숫자·주사위·HP·거리 값은 자릿수 변화에도 폭이 흔들리지 않는 정렬 방식을 사용한다.
- ALL CAPS 영문을 긴 Label에 사용하지 않는다.
- 한국어 조사와 줄바꿈을 고려해 Button 폭을 고정 텍스트 길이에 맞추지 않는다.
- 한 화면에서 4개를 넘는 Font Size를 동시에 강조하지 않는다.

## 5. 간격·크기·형태

기본 단위:

```text
Base Unit = 4 px
Major Rhythm = 8 px
```

Spacing Token:

```text
XS = 4
S  = 8
M  = 12
L  = 16
XL = 24
2XL = 32
3XL = 48
```

Control 기준:

- 기본 Button·Input 높이: 40 이상
- Compact Mouse Tool Control: 32 이상
- 주요 Action Target: 44 이상
- Icon: 16, 20, 24, 32, 48 단계
- Panel 내부 Padding: 기본 16
- 촘촘한 Table·Inspector: 최소 8

Corner Radius:

```text
control = 4
panel = 8
modal = 10
pill = 높이의 50%
```

과도한 둥근 카드와 Floating Bubble을 기본 스타일로 사용하지 않는다.

## 6. Stroke·Elevation·Layer

Stroke 역할:

- 1 px: 일반 경계와 Divider
- 2 px: 선택·Focus·경고
- 3 px 이상: Critical Prompt 또는 현재 Turn처럼 매우 제한된 강조

그림자는 깊이와 겹침을 설명할 때만 사용한다. 모든 카드에 동일한 강한 그림자를 넣지 않는다.

UI Layer 순서:

```text
World Feedback
< Persistent HUD
< Docked Panel
< Floating Panel·Context Menu
< Tooltip
< Authority Prompt
< Critical Modal
< System Recovery·Disconnect Surface
```

Presentation VFX는 Critical Modal과 System Recovery Surface를 가리지 않는다.

## 7. Component 상태

모든 상호작용 Component는 필요한 범위에서 다음 상태를 명시한다.

```text
idle
hover
focused
pressed
selected
pending
success
warning
denied
disabled
stale
error
```

규칙:

- `disabled`는 이유 Tooltip 또는 인접 설명을 제공한다.
- `pending`은 중복 제출을 막되 전체 화면을 불필요하게 차단하지 않는다.
- `denied`는 사용자의 실수인지 권한·상태 문제인지 구분한다.
- `stale`은 최신 상태 갱신 또는 재선택 경로를 제공한다.
- Hover 상태만 존재하는 핵심 정보나 조작을 만들지 않는다.

## 8. Icon과 이미지

- Icon은 동일한 Stroke 두께와 광학 크기 체계를 사용한다.
- Item·Spell·Action Icon은 Frame과 상태 Badge를 분리한다.
- Icon만 있는 Button은 Tooltip, Focus Label 또는 접근 가능한 이름을 가진다.
- 같은 의미에 여러 Icon을 사용하지 않는다.
- 일반 기능에 희귀도 색·화려한 Glow를 남용하지 않는다.
- 미식별·비공개 대상은 실제 정체를 암시하는 실루엣이나 색을 사용하지 않는다.

## 9. 전장 우선 Layout

1920×1080을 기준 Viewport로 사용하되 절대 픽셀 고정이 아니라 Anchor·Constraint·Scale Token으로 구현한다.

```text
중앙 전장 안전 영역 확보
→ 지속 HUD를 가장자리에 배치
→ 상세 정보는 Panel·Tooltip·Side Sheet로 확장
```

- 중앙 전장에 지속 Panel을 두지 않는다.
- World Feedback은 대상·커서 근처에 표시하되 Token과 경로를 덮지 않는다.
- 화면이 좁아지면 정보 삭제보다 축약·접기·Scroll을 먼저 사용한다.
- Player UI Scale 0.80–1.40 범위를 지원하는 구조를 유지한다.
- DM Workspace는 Dock Layout을 사용하고 Player 전장 안전 영역을 별도 Preview할 수 있어야 한다.

## 10. Animation과 시각 변화

Motion Token 초기값:

```text
instant = 0
fast = 0.12s
normal = 0.20s
slow = 0.35s
```

이는 Gameplay Timeout이 아니라 시각 전환 기본값이며 플레이테스트에서 조정할 수 있다.

- 상태 변화는 위치·Opacity·Scale 중 최소한으로 표현한다.
- 반복 Pulse, 무한 회전, 강한 Glow를 기본 Pending 표현으로 사용하지 않는다.
- HP·Resource 변화는 이전 값과 새 값을 읽을 수 있게 표현하되 실제 Authority 적용을 Animation 완료에 의존하지 않는다.
- 중요한 결과는 Motion을 꺼도 Text·Icon·State로 이해할 수 있어야 한다.
- Reduced Motion에서는 이동·확대·Shake를 제거하고 짧은 Fade 또는 즉시 전환을 사용한다.

## 11. 금지 패턴

- 화면별 임의 Hex·Font Size·Corner 값
- 모든 정보를 Card로 감싸는 구조
- Hover해야만 비용·위험·단축키를 알 수 있는 Action
- Disabled 이유가 없는 회색 Button
- 성공·실패를 색이나 Animation만으로 전달
- Player와 DM 데이터를 같은 ViewModel에서 `Visible`만 바꾸는 방식
- 전장 중앙을 상시 가리는 큰 Panel
- Modal 위에 재생되는 비필수 VFX
- 장식 때문에 숫자·한글 획이 흐려지는 배경
- 권위 상태가 바뀌기 전에 UI가 성공 상태를 확정하는 표현

## 12. 구현 검수

새 Component는 최소한 다음을 증명해야 한다.

- Semantic Token 외 임의 스타일 값이 없다.
- 모든 상태 Variant가 정의됐다.
- 한국어 긴 Label과 수치 증가에서 Layout이 깨지지 않는다.
- UI Scale 극단값에서 핵심 조작이 남는다.
- Color-only 의미가 없다.
- Reduced Motion에서도 같은 결과를 이해할 수 있다.
- Player·DM Projection 차이가 안전하게 렌더링된다.
