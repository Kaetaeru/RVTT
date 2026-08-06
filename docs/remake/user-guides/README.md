# RVTT Player·DM User Guides

- 상태: `COMPLETE · HTML_UI_EXAMPLES_ADDED`
- 문서 종류: User Guide Index
- 사용자 가이드 상태: `TARGET_EXPERIENCE`
- 최종 갱신일: 2026-08-06
- 세부 작업 순서: [`CURRENT-USER-GUIDE-WORK-ORDER.md`](CURRENT-USER-GUIDE-WORK-ORDER.md)
- 전체 UI HTML 예시: [`html/index.html`](html/index.html)
- HTML 예시 설명: [`html/README.md`](html/README.md)

이 폴더는 내부 시스템 구조가 아니라 **Player, Observer와 DM이 실제 세션에서 무엇을 보고 무엇을 하는지** 설명한다.

현재 문서는 구현 전 목표 사용자 경험이다. HTML 예시는 화면 구성과 흐름을 비교하는 정적 Reference이며 실제 Roblox Production UI, Studio Runtime Evidence 또는 Release Screenshot이 아니다.

## 처음 읽을 문서

### 1. [`한눈에 보는 세션 흐름`](QUICK-FLOW.md)

코딩 용어 없이 다음 흐름을 설명한다.

- 전체 세션 시작부터 종료까지
- Player와 DM의 기본 진행
- Exploration과 Encounter 반복
- Scene 전환
- 재접속
- DM 복구

### 2. [`전체 UI HTML 예시`](html/index.html)

28개 Player·Observer·DM 목표 화면을 같은 디자인·입력·권한 계약으로 비교한다.

브라우저에서 다음을 전환할 수 있다.

- 화면 종류와 역할
- Gold를 포함한 여섯 Accent Preset
- 16:9·Compact·21:9 화면
- UI Scale 0.80·1.00·1.20·1.40
- Full·Reduced Motion 표시

```text
Quick Flow
→ 전체 세션 이해

HTML UI Example
→ 화면 구성과 상태 비교

Player·DM Guide
→ 역할별 조작과 상황을 자세히 확인
```

## 역할별 상세 가이드

### [`Player Guide`](player/README.md)

- 세션 접속과 Character 선택
- Camera와 입력
- Exploration 이동과 상호작용
- Action·Spell·Dice·Reaction
- Encounter 진행
- Character Sheet·Inventory·Downtime
- Journal·Ping
- 재접속·동기화·Rollback 대응

역할별 HTML 화면 순서: [`Player·Observer UI 예시`](player/UI-EXAMPLES.md)

### [`DM Guide`](dm/README.md)

- Campaign과 Session 준비
- Lobby·Role·Character·Control 관리
- Live DM 진행
- Exploration·Fog·비밀 정보·판정
- Encounter 시작·진행·종료
- Quick Action과 수동 개입
- Scene Editor·Test Play·Publish
- Journal·Player View 확인
- Recovery·Rollback·세션 종료

역할별 HTML 화면 순서: [`DM UI 예시`](dm/UI-EXAMPLES.md)

## 가장 짧은 세션 흐름

### Player

```text
세션 참가
→ Character 선택
→ Gameplay Ready
→ Exploration
→ 필요하면 Encounter
→ 다시 Exploration
→ 세션 종료
```

### Observer

```text
세션 참가
→ Observer 선택
→ 공개 Scene과 정보 확인
→ Camera·Map·Journal 사용
→ 세션 종료
```

### DM

```text
Campaign과 Scene 준비
→ Player 준비 확인
→ 세션 시작
→ Exploration 진행
→ 필요하면 Encounter·Scene 전환·Pause
→ 결과 확인과 복구
→ 세션 종료
```

## 확정된 공통 입력

```text
Left Click
→ 선택 또는 클릭 전에 표시된 기본 행동

Right Click
→ Capability 기반 Context Action Table

Middle-button Drag
→ Camera Orbit

Wheel
→ Camera Zoom

Ctrl+Wheel
→ Camera Pivot Y

Q
→ 최상위 Context 하나만 취소·닫기·거절

E
→ 현재 화면에 표시된 Confirm 하나 제출

ESC
→ Gameplay 의미 없음
```

- `1–5`는 현재 화면에 Label이 표시된 경우에만 주요 선택지로 사용한다.
- Hover, Keyboard Focus, Selection, Target과 Camera Focus를 서로 구분한다.
- Camera 이동만으로 Character 위치, 선택, 시야 권한과 공개 정보가 바뀌지 않는다.
- 권한에 없는 Action·Entity·Document는 Disabled 자리로 남기지 않는다.
- Local Preview·Pending Animation은 Authority Result가 아니다.
- Player, Observer와 DM은 서로 다른 Permission-aware Projection을 본다.

## 확정된 UI 초기값

```text
Accent                = gold
UI Scale              = 1.00 · 0.80–1.40
Text Scale            = 1.00 · 0.90–1.30
Hotbar Rows           = 2 · 1–4
PartyRail             = auto
Combat Log            = recent
Minimap               = medium · camera_up
General Tooltip       = 0.25s
Detailed Tooltip      = 0.75s
Disabled Reason       = 0.15s
Motion Profile        = full
Turn Focus            = soft_notification
Edge Pan              = false
```

Camera 초기값은 FOV 50, Orbit Sensitivity 0.004 기준, WASD Pan 55 studs/s 기준, Zoom Step 5와 Distance 20–130을 사용한다. 이 수치는 Production 초기값이며 Studio 측정으로 조정할 수 있지만 입력 의미, 권한 공개와 Authority 경계는 바꾸지 않는다.

## 지원 범위

- 초기 지원 환경은 PC 키보드·마우스다.
- 기본 Ruleset은 `dnd5e-2024`다.
- 기본 표시 언어는 `ko-KR`이다.
- Player와 DM은 3D 미니어처 Token과 자유 전술 Camera를 사용한다.
- Exploration에서는 목적지 이동과 선택 Token의 직접 이동 의도를 지원한다.
- Encounter에서는 경로·거리·위험 Preview 뒤 이동한다.
- Encounter 중 WASD는 Camera 이동에 사용한다.
- 중도 참가, Role 변경, 재접속, Resync, Recovery와 DM Rollback을 목표로 한다.
- NPC 자동 대화, 음악, 환경음과 효과음은 현재 범위가 아니다.
- 모바일·게임패드·터치는 초기 지원 범위가 아니다.

## 아직 Runtime에서 확정되지 않은 것

- HTML 예시와 같은 Roblox ScreenGui의 실제 Pixel 배치
- 실제 Roblox Font와 한국어 줄바꿈
- Accent별 대비와 Focus 판독성
- Tooltip·Toast Timing의 실제 조작감
- Camera 감도·Occlusion·Motion Comfort
- UI Scale 0.80·1.40의 Layout과 Hit Target
- 저사양 Fallback과 Rendering Budget
- Player·Observer·DM 다중 Client 화면

새 User Action이나 권한 동작이 필요하면 Product·Architecture·UI·ADR을 먼저 갱신한다. 측정형 기본값 조정은 Acceptance Evidence를 남긴다.

## 문서 연결

- [`한눈에 보는 세션 흐름`](QUICK-FLOW.md)
- [`전체 UI HTML 예시`](html/index.html)
- [`Player·Observer UI 예시 지도`](player/UI-EXAMPLES.md)
- [`DM UI 예시 지도`](dm/UI-EXAMPLES.md)
- [`HTML UI Example Audit`](../audits/user-guide-html-ui-example-audit.md)
- 현재 작업 순서: [`../CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)
- Remake 문서 허브: [`../README.md`](../README.md)
- Product Authority: [`../product/README.md`](../product/README.md)
- Main System Guides: [`../guides/README.md`](../guides/README.md)
- 구현 직전 UI·UX 명세: [`../ui/shared/implementation-ready-ui-ux-and-settings-spec.md`](../ui/shared/implementation-ready-ui-ux-and-settings-spec.md)
- Implementation Specs: [`../specs/README.md`](../specs/README.md)

Quick Flow, 상세 User Guide와 HTML 예시는 쉬운 언어로 설명하는 비권위 Reference다. 충돌하면 Accepted ADR, Architecture, UI Policy와 구현 직전 UI·UX 명세가 우선한다.
