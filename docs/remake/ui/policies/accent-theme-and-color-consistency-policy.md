# RVTT Accent Theme and Color Consistency Policy

- 상태: CURRENT
- 문서 종류: Global UI Accent Theme Policy
- 작성일: 2026-08-05
- 최종 개정일: 2026-08-05
- 즉시 구현 명세 가능성: READY
- Policy Hub: [`UI·UX Global Policies`](README.md)
- Visual Policy: [`Visual Design Policy`](visual-design-policy.md)
- Review Checklist: [`UI·UX Review Checklist`](UI-UX-REVIEW-CHECKLIST.md)

이 문서는 RVTT의 사용자 선택형 강조 색상, 색상 일관성과 화려함의 사용 한계를 정의한다. `visual-design-policy.md`의 Semantic Token 원칙을 보충하며, 사용자 Accent Theme에 관해서는 이 문서의 최신 결정이 우선한다.

## 1. 최신 사용자 결정

```text
시각 방향
→ 깔끔하면서 화려한 디자인

색상 체계
→ 화면별 임의 색상이 아닌 일관된 Semantic Color

사용자 설정
→ 설정에서 선호 Accent Color 선택 가능

기본 Accent
→ Gold
```

핵심 문장:

> 중성 Surface 위에 하나의 일관된 Accent를 사용하고, 화려함은 중요한 순간과 경계에만 집중한다.

## 2. 디자인 정체성

RVTT의 시각 언어는 다음을 동시에 만족해야 한다.

```text
정돈된 정보 구조
+ 전술 화면의 즉시 판독성
+ 판타지 장부와 금속 장식의 고급스러움
+ 제한된 Glow·Gradient·Motion을 이용한 극적 순간
```

- 화면은 먼저 깨끗한 정렬, 여백, 계층과 가독성을 제공한다.
- 화려함은 Header, 주요 선택, 핵심 결과 공개, Dice Reveal, Level-up, Authority Prompt처럼 중요한 순간에만 사용한다.
- 모든 Button, Card와 Panel에 Glow·Gradient·Particle을 반복하지 않는다.
- 한 Surface에는 하나의 주 Accent만 지배적으로 사용한다.
- 장식은 정보와 조작보다 앞에 오지 않는다.
- 화려함의 강도는 `idle < hover < selected < critical reveal` 순으로 상승하며 상시 최대 강도를 유지하지 않는다.

## 3. 색상 계층

색상은 다음 다섯 계층으로 분리한다.

| 계층 | 소유 의미 | 사용자 Accent 영향 |
|---|---|---|
| Neutral Surface | Canvas·Panel·Input·Divider | 영향 없음 |
| User Accent | 일반 선택·주요 조작·Navigation·장식 | 사용자가 선택 |
| Role·Authority | Player·DM·Observer·권한 | 영향 없음 |
| State | Info·Success·Warning·Danger·Pending·Hidden | 영향 없음 |
| Content Semantics | 희귀도·피해 유형·조건·거리·범위 | 영향 없음 |

사용자 Accent는 일반 인터페이스의 정체성과 개인 취향을 표현한다. 다음 의미를 바꾸거나 위장해서는 안 된다.

- 성공·실패·경고·위험
- DM 권한과 Player 역할
- 비공개·미식별·Observer 상태
- Item 희귀도와 규칙 데이터
- HP·자원·이동 가능 범위
- Target 적합성·불가능 상태

사용자 Accent와 의미색이 같은 계열로 보이더라도 Icon, Label, Pattern, Stroke와 위치가 의미를 구분해야 한다.

## 4. User Accent Semantic Token

Component는 Palette ID나 Hex 값을 직접 사용하지 않는다.

```text
User Preference
→ Accent Palette Resolver
→ Semantic Accent Token
→ Component Variant
→ Roblox Property
```

필수 Token:

| Token | 사용 |
|---|---|
| `accent.user.primary` | 일반 선택·활성 Navigation·Primary Action |
| `accent.user.hover` | Hover 강조 |
| `accent.user.pressed` | Pressed·Active 상태 |
| `accent.user.soft` | 선택 배경·Subtle Fill |
| `accent.user.on` | Accent Surface 위 Text·Icon |
| `accent.user.focus` | Keyboard Focus 후보 |
| `accent.user.glow` | 제한된 장식·결과 공개 |

규칙:

- `accent.user.focus`가 배경과 충분히 구분되지 않으면 고정 접근성 `focus.ring`으로 대체한다.
- `accent.user.glow`는 Text 본문, Table 배경과 장시간 Pending에 사용하지 않는다.
- Component는 `gold`, `azure` 같은 Palette ID를 조건문으로 직접 분기하지 않는다.
- Palette는 모든 상태 Token을 완전하게 정의해야 하며 Base Color 하나에서 런타임으로 임의 파생하지 않는다.

## 5. 초기 Accent Palette

초기 구현은 검수된 Preset만 지원한다. 아래 Base 값은 Palette 식별용 기준이며 Component 직접 참조값이 아니다.

| Palette ID | 표시 이름 | Base Seed | 용도 |
|---|---|---|---|
| `gold` | 황금색 | `#D9B85F` | 기본값·전술 판타지 정체성 |
| `azure` | 푸른색 | `#62A9E6` | 차갑고 선명한 강조 |
| `emerald` | 에메랄드 | `#58B88A` | 안정적이고 자연스러운 강조 |
| `amethyst` | 자수정 | `#9B7CE0` | 신비로운 강조 |
| `teal` | 청록색 | `#4FB6B2` | 중립적이고 현대적인 강조 |
| `silver` | 은색 | `#AAB2C0` | 절제된 저채도 강조 |

기본값:

```text
uiAccentThemeId = "gold"
```

- 알 수 없거나 제거된 ID는 `gold`로 안전하게 복구한다.
- 초기 버전에는 자유 Hex·RGB·Hue Picker를 제공하지 않는다.
- 자유 색상 선택은 대비, 의미색 충돌과 모든 Component 상태를 자동 검증할 수 있을 때 별도 정책으로 검토한다.

## 6. 설정 UX

설정 경로:

```text
Settings
→ Interface
→ Accent Color
```

필수 동작:

- 현재 Palette가 선택 상태로 표시된다.
- 각 Palette는 Swatch, 이름과 Sample Component Preview를 제공한다.
- 선택하면 현재 화면에 즉시 Preview·적용한다.
- `기본값으로 복원`은 `gold`를 적용한다.
- 저장 실패가 Gameplay 진행을 막지 않는다.
- Pending Command, Modal, Focus와 Selection은 Theme 변경 중 유지된다.
- Theme 변경 때문에 화면 전체가 재생성되거나 입력 Context가 초기화되지 않는다.
- 설정 화면을 닫기 전에 적용 상태를 명확히 표시한다.

## 7. 저장·권위·재접속

Accent Theme은 사용자별 비권위 Preference다.

- Campaign, Character, Scene와 Combat Snapshot에 저장하지 않는다.
- 다른 사용자에게 복제하거나 DM이 강제로 변경하지 않는다.
- 서버 동기화를 사용할 경우 허용된 Palette ID만 검증한다.
- 저장 원본은 사용자 Preference이며 Gameplay Authority State와 분리한다.
- 저장을 읽지 못하면 `gold`를 사용하고 UI를 계속 표시한다.
- 재접속·Full Resync·Rollback은 Accent 설정을 초기화하지 않는다.
- 오래된 Preference Version이나 알 수 없는 값은 `gold`로 Migration한다.

## 8. 일관성 규칙

- 동일 Component와 상태는 모든 화면에서 같은 Accent Token을 사용한다.
- Primary Action이 여러 개 보이면 Accent 강도를 동일하게 주지 않고 실제 Primary 하나를 명확히 한다.
- Active Navigation, Selection, Focus와 Primary Action은 서로 다른 Shape·Stroke·위치도 함께 사용한다.
- 화면별 브랜드 색이나 Slice 전용 Accent를 임의로 추가하지 않는다.
- DM Workspace도 사용자의 Accent를 기본 인터페이스에 적용하지만 DM Authority 표시는 기존 권한 Token과 Label을 유지한다.
- Item·Spell·Condition 색은 사용자 Accent에 맞춰 재색칠하지 않는다.

## 9. 화려함 사용 Gate

허용되는 화려함:

- 선택된 주요 Frame의 얇은 금속성 Border
- Header·Divider의 제한된 Gradient
- Dice Result·Critical Result의 짧은 Highlight
- 주요 전환의 짧은 Glow·Light Sweep
- Tooltip이나 Panel을 가리지 않는 배경 장식

금지되는 화려함:

- 모든 Button의 상시 Glow
- 반복 Pulse·무한 반짝임·지속 Particle
- Text 뒤의 강한 Texture·Gradient
- 서로 다른 Accent가 경쟁하는 Rainbow UI
- Danger·Warning을 사용자 Accent로 대체
- Reduced Motion에서 의미를 잃는 연출
- 저사양 Fallback에서 조작 경계가 사라지는 장식

## 10. 접근성 Gate

모든 Palette는 다음을 통과해야 한다.

- Neutral Surface 전체에서 Text·Icon·Stroke 판독 가능
- `idle·hover·focused·pressed·selected·disabled` 상태 구분 가능
- 색을 보지 못해도 Icon·Label·Shape로 상태 이해 가능
- `state.danger`, `state.warning`, `state.success`와 혼동되지 않음
- UI Scale 0.80–1.40에서 Focus와 Selection 경계 유지
- Reduced Motion·Minimal Motion에서도 동일 정보 유지
- 저사양 Fallback에서도 Primary Action과 Focus가 유지

하나라도 실패하면 해당 Palette를 출시 목록에 포함하지 않는다.

## 11. 구현 검수

새 Theme Resolver와 설정 UI는 최소한 다음을 증명해야 한다.

- 기본값이 `gold`다.
- 여섯 초기 Palette가 같은 Semantic Token 계약을 구현한다.
- Component에 임의 Hex와 Palette ID 분기가 없다.
- 의미색·역할색·콘텐츠색이 Theme 변경으로 변하지 않는다.
- Theme 전환 중 Focus·Selection·Pending·Modal 상태가 유지된다.
- 재접속 후 사용자 Preference가 복구된다.
- 알 수 없는 ID가 `gold`로 복구된다.
- 각 Palette의 Screenshot과 UI·UX Checklist 결과가 존재한다.

## 12. 비범위

- 사용자 임의 RGB·Hex 입력
- 화면별 독립 Theme
- DM이 세션 참가자의 Theme을 강제 변경하는 기능
- Accent로 Gameplay 정보나 비밀 상태를 암호화하는 기능
- Theme 선택에 따른 VFX·SFX Gameplay 변경

현재 다음 구현 단계:

```text
Accent Preference Contract
→ Palette Resolver
→ Settings Surface
→ Shared Component 연결
→ Slice 01 화면 적용
→ Palette별 Visual·Accessibility Acceptance
```
