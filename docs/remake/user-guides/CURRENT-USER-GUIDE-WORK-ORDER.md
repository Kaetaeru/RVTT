# Player·DM User Guide 현재 작업 순서

- 상태: `COMPLETE · HTML_UI_EXAMPLES_ADDED`
- 문서 종류: User Guide Work Order
- 최종 갱신일: 2026-08-06
- 상위 작업 순서: [`../CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)
- 전체 UI HTML 예시: [`html/index.html`](html/index.html)
- HTML UI 예시 감사: [`../audits/user-guide-html-ui-example-audit.md`](../audits/user-guide-html-ui-example-audit.md)
- 최초 완료 감사: [`Player·DM User Guide 완료 감사`](../audits/player-and-dm-user-guide-completion-audit.md)
- Quick Flow 감사: [`User Guide Quick Flow와 Flowchart 보완 감사`](../audits/user-guide-quick-flow-and-flowchart-audit.md)

이 문서는 Player·Observer·DM 관점의 User Guide 작성과 HTML 화면 예시 연결 순서를 기록한다.

기존 Quick Flow와 상세 Player·DM Guide에 더해, 구현 직전 UI·UX 명세의 모든 주요 화면을 한 개의 인터랙티브 HTML Gallery와 역할별 Anchor Map으로 연결했다.

## 운영 규칙

1. User Guide는 확정된 Product·Architecture·UI·ADR과 Main System Guide를 사용자 언어로 번역한다.
2. 아직 구현·검증되지 않은 기능과 HTML 화면은 `TARGET_EXPERIENCE`로 표시한다.
3. Quick Flow에는 Module, Type, Command, Schema, Transaction과 Projection 같은 구현 용어를 최소화한다.
4. 화면 위치, 입력과 수치는 Accepted ADR 또는 구현 직전 UI·UX 명세에서 확정된 값만 사용한다.
5. Player에게 공개되지 않는 DM 비밀과 내부 진단 정보를 노출하지 않는다.
6. HTML 예시를 Roblox Production UI, Studio Runtime Evidence 또는 Release Screenshot으로 표현하지 않는다.
7. 역할별 화면은 Permission-aware Projection 차이를 보여 주며 단순 `Visible` 차이로 설명하지 않는다.
8. 제품 비목표인 NPC 자동 대화, 음악, 환경음과 효과음을 지원 기능처럼 설명하지 않는다.

## 상태 값

```text
IN_PROGRESS
QUEUED
BLOCKED
DONE
UPDATE_REQUIRED
DEFERRED
```

## 완료 순서

| 순서 | 상태 | 작업 | 완료 조건 |
|---:|---|---|---|
| 1 | `DONE` | User Guide Hub와 공통 범위 | 목표 경험 상태와 Player·DM 문서 구분 확정 |
| 2 | `DONE` | Player Guide | 접속부터 종료까지 상세 Player 흐름 작성 |
| 3 | `DONE` | DM Guide | 준비부터 종료까지 상세 DM 흐름 작성 |
| 4 | `DONE` | 최초 User Guide 완료 감사 | 역할·비밀·입력·비목표 정합성 검사 |
| 5 | `DONE` | 간단한 Session Flow와 Flowchart | 전체·Player·DM 흐름과 분기 작성 |
| 6 | `DONE` | User Guide Hub·상세 Guide 연결 | Quick Flow를 첫 읽기 문서로 연결 |
| 7 | `DONE` | Quick Flow 보완 감사 | 흐름·링크·문서 검증 확인 |
| 8 | `DONE` | 전체 UI HTML Gallery | 28개 화면과 공통 Interaction Control 작성 |
| 9 | `DONE` | Player·Observer UI Anchor Map | 역할별 권장 화면 순서와 확인 사항 연결 |
| 10 | `DONE` | DM UI Anchor Map | Live·Editor·Preview·Recovery 화면 연결 |
| 11 | `DONE` | Hub·Quick Flow 최신 UX 정합화 | Pointer·Q/E·ESC·설정 기본값 갱신 |
| 12 | `DONE` | HTML UI Example Audit | 화면 수·Anchor·권한·Authority·검증 상태 기록 |

## 완료 문서

- [`한눈에 보는 세션 흐름`](QUICK-FLOW.md)
- [`User Guide Hub`](README.md)
- [`Player Guide`](player/README.md)
- [`Player·Observer UI 예시 지도`](player/UI-EXAMPLES.md)
- [`DM Guide`](dm/README.md)
- [`DM UI 예시 지도`](dm/UI-EXAMPLES.md)
- [`전체 UI HTML 예시`](html/index.html)
- [`HTML 예시 설명`](html/README.md)
- [`HTML UI Example Audit`](../audits/user-guide-html-ui-example-audit.md)

## HTML Gallery 범위

```text
공통·진입       3
Player 전장     7
Player 관리     7
설정·복구       4
Observer        1
DM              6
합계           28
```

지원하는 비교:

- Gold를 포함한 여섯 Accent Preset
- 16:9·Compact·21:9 Viewport
- UI Scale 0.80·1.00·1.20·1.40
- Full·Reduced Motion
- Q·E·ESC 입력 안내

## 공통 계약 확인

- [x] Left Click은 선택 또는 클릭 전에 표시된 기본 행동이다.
- [x] Right Click은 Capability 기반 Context Action Table이다.
- [x] Middle-button Drag는 Camera Orbit이다.
- [x] Q는 최상위 Context 하나만 취소·닫기·거절한다.
- [x] E는 현재 공개된 Confirm 하나만 제출한다.
- [x] ESC에는 Gameplay 의미가 없다.
- [x] 권한에 없는 Action·Entity·Document는 자리도 만들지 않는다.
- [x] Preview·Pending과 Authority Result를 구분한다.
- [x] Observer에 조작 Hotbar를 제공하지 않는다.
- [x] DM Source와 Player View Preview를 분리한다.
- [x] UI 초기값은 구현 직전 명세와 일치한다.
- [x] HTML 예시가 Runtime Evidence가 아님을 표시한다.

## 검증 상태

```text
User Guide Flow
→ COMPLETE

HTML UI Example Coverage
→ COMPLETE · 28 SCREENS

Role Anchor Maps
→ COMPLETE

Static Structure
→ PASS

Browser Screenshot
→ NOT EXECUTED

Roblox Studio Runtime
→ NOT EXECUTED

Release Verification
→ NOT EXECUTED
```

실제 Build 단계에서는 다음 상태로 다시 검증한다.

```text
TARGET_EXPERIENCE
→ CURRENT_FOR_BUILD
→ RELEASE_VERIFIED
```

## 다음 Gate

```text
Full UI·UX Production Source 정합화
→ Static·Toolchain Validation
→ Exploration·Context Input Studio Retest
→ Inventory·Journal·Settings Human Evidence
→ Player·Observer·DM Permission·Recovery Test
→ UI·Accessibility·Performance Evidence
→ Release Screenshot으로 HTML 예시 교체·보완
```

## 변경 기록

| 날짜 | 변경 |
|---|---|
| 2026-08-06 | 28개 전체 UI HTML 예시, Player·Observer·DM 역할별 Anchor Map, Hub·Quick Flow 정합화와 정적 감사를 완료했다. |
| 2026-08-05 | 코딩 용어 없는 Quick Flow, Flowchart, Hub 연결과 간소화 감사를 완료했다. |
| 2026-08-05 | Player Guide, DM Guide, Hub와 최초 Completion Audit을 완료했다. |
