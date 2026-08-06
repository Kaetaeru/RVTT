# User Guide HTML UI Example Audit

- 상태: `COMPLETE · STATIC EXAMPLE ONLY`
- 문서 종류: User Guide HTML UI Coverage·Consistency Audit
- 감사일: 2026-08-06
- HTML Gallery: [`../user-guides/html/index.html`](../user-guides/html/index.html)
- HTML Guide: [`../user-guides/html/README.md`](../user-guides/html/README.md)
- User Guide Hub: [`../user-guides/README.md`](../user-guides/README.md)
- 구현 직전 UI·UX 명세: [`../ui/shared/implementation-ready-ui-ux-and-settings-spec.md`](../ui/shared/implementation-ready-ui-ux-and-settings-spec.md)

## 1. 목적

Player·Observer·DM User Guide에 연결된 HTML 화면 예시가 최신 UI·UX 권위 계약을 사용자 관점에서 일관되게 표현하는지 검사한다.

```text
Static HTML Coverage
≠ Roblox Source Implementation
≠ Studio Runtime Evidence
≠ Release Screenshot Verification
```

## 2. 화면 범위

| 범주 | 화면 수 | 포함 내용 |
|---|---:|---|
| 공통·진입 | 3 | Session Entry, System Menu, Component State |
| Player 전장 | 7 | Exploration, Context Action, Movement, Encounter, Targeting, Reaction, Dice |
| Player 관리 | 7 | Character, Inventory, Loot, Rest, Death, Journal, Map |
| 설정·복구 | 4 | Interface, Camera·Accessibility, Binding Conflict, Reconnect |
| Observer | 1 | 공개 정보·Camera HUD |
| DM | 6 | Live, Quick Action, Encounter·Fog, Editor, Player Preview, Rollback |
| 합계 | 28 | 전체 User Guide 화면 예시 |

판정: `PASS`

## 3. 입력 계약

HTML 예시는 다음을 공통으로 표시한다.

```text
Left Click
→ 선택 또는 클릭 전에 표시된 기본 행동

Right Click
→ Capability 기반 Context Action Table

Middle-button Drag
→ Camera Orbit

Q
→ 최상위 Context 하나만 취소·닫기·거절

E
→ 현재 공개된 Confirm 하나 제출

ESC
→ Gameplay 의미 없음
```

- 기존 Right Drag Camera 문법을 사용하지 않는다.
- Q 한 번으로 Panel·Targeting·Selection을 연쇄 종료하지 않는다.
- E가 표시되지 않은 숨은 결과를 실행한다고 설명하지 않는다.

판정: `PASS`

## 4. 권한과 정보 공개

- 권한에 없는 Action·Entity·Document는 Disabled 자리로 남기지 않는다.
- Observer 화면에 이동·공격·Item 사용 Hotbar를 제공하지 않는다.
- DM Source와 Player View Preview를 별도 화면과 Projection으로 표현한다.
- 미식별 Item, Fog와 숨은 Actor가 Player 화면에 실제 정체를 암시하지 않는다.
- Search·Count·Backlink로 비공개 Journal 존재를 암시하지 않는다.

판정: `PASS`

## 5. Authority와 Feedback

- World Action Label과 Path·Area Preview를 실행 전 정보로 표현한다.
- Pending은 제출됐으나 Projection 확인 전 상태로 표시한다.
- Dice Animation이 난수 원본이라고 설명하지 않는다.
- Reconnect 중 Last Known Good 전장과 Authority Input Gate를 구분한다.
- Rollback 후 새 AuthorityEpoch와 이전 Context 폐기를 설명한다.

판정: `PASS`

## 6. Visual·Settings

HTML Gallery는 다음 비교 기능을 제공한다.

- `gold·azure·emerald·amethyst·teal·silver` Accent
- 16:9·Compact·21:9 Viewport
- UI Scale 0.80·1.00·1.20·1.40
- Full·Reduced Motion 표시

초기 화면은 Gold, 16:9, UI Scale 1.00과 Full Motion이다.

State·Role·Danger·Warning·Pending 의미색은 User Accent와 별도 Token으로 표현한다.

판정: `PASS_WITH_RUNTIME_MEASUREMENT_REQUIRED`

## 7. 접근성

- Navigation과 Control은 Keyboard Focus Ring을 가진다.
- Disabled·Pending·Denied는 색 외 Text·Icon·Label을 함께 사용한다.
- Hover-only 설명을 요구하지 않고 역할별 Markdown Guide에서 같은 정보를 읽을 수 있다.
- Motion 축약 Control을 제공한다.
- UI Scale 변경 기능을 제공한다.

브라우저별 실제 대비, 한국어 Font와 화면 확대 상태는 Release 검증 대상이다.

판정: `PASS_WITH_RUNTIME_MEASUREMENT_REQUIRED`

## 8. 정적 구조 검사

- HTML 화면 정의: 28
- Navigation Entry: 28
- 화면 ID와 Navigation ID 일치: 확인
- 중복 화면 ID: 없음
- 역할별 Anchor Link: 작성 완료
- 단일 self-contained HTML: 확인

실행 환경의 로컬 페이지 차단 정책 때문에 자동 Browser Screenshot은 생성하지 못했다. 이는 HTML 구조 실패가 아니라 시각 QA Evidence가 아직 없다는 뜻이다.

판정: `STATIC PASS · VISUAL SCREENSHOT NOT EXECUTED`

## 9. 아직 증명되지 않은 것

- Roblox ScreenGui Layout과 실제 Pixel 결과
- Camera·Pointer·Q/E/ESC Runtime 입력
- Server Projection과 권한 미노출
- Inventory·Transfer·Rest·Rollback Transaction
- UI Scale 0.80·1.40에서 실제 Roblox Text와 Hit Target
- 실제 여섯 Accent의 Contrast
- Tooltip·Toast Timing의 조작감
- Reduced Motion·저사양 Fallback
- Player·Observer·DM 다중 Client 동시 화면

## 10. 최종 판정

```text
HTML UI Example Coverage
→ COMPLETE · 28 SCREENS

Player·Observer·DM Guide Linkage
→ COMPLETE

Input·Permission·Authority Wording
→ CONSISTENT

Static Structure
→ PASS

Browser Screenshot
→ NOT EXECUTED

Roblox Runtime·Release Verification
→ NOT EXECUTED
```

HTML Gallery는 구현과 사용자 검수를 돕는 목표 화면 Reference로 사용할 수 있다. Production Acceptance 또는 Release Evidence로 승격하려면 같은 화면의 Roblox Studio Screenshot, 역할별 Projection과 입력 로그가 필요하다.
