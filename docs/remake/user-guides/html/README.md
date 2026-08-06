# RVTT 전체 UI HTML 예시

- 상태: `CURRENT · TARGET_EXPERIENCE`
- 문서 종류: Interactive HTML User Guide Example
- 최종 갱신일: 2026-08-06
- 실행 파일: [`index.html`](index.html)
- User Guide Hub: [`../README.md`](../README.md)
- 구현 직전 UI·UX 명세: [`../../ui/shared/implementation-ready-ui-ux-and-settings-spec.md`](../../ui/shared/implementation-ready-ui-ux-and-settings-spec.md)

이 폴더는 RVTT의 Player·Observer·DM 화면을 브라우저에서 비교할 수 있는 정적 HTML 예시를 제공한다.

```text
HTML User Guide Example
≠ Roblox Production UI
≠ Studio Runtime Evidence
≠ Release Screenshot
```

## 포함 화면

### 공통·진입

- Session Entry·Character 선택
- System Menu·세션 나가기
- Tooltip·Toast·Component 상태

### Player

- Exploration HUD
- Context Action Table
- 이동 Preview
- Encounter HUD
- 공격·주문 Targeting
- Reaction Prompt
- Dice Result
- Character Sheet
- Inventory·Equipment
- Loot·Container·Transfer
- Downtime·Rest
- HP 0·Death Save
- Journal
- Map·Fog·Ping
- Interface Settings
- Camera·Accessibility Settings
- Key Binding Conflict
- Reconnect·Resync·Recovery

### Observer

- 공개 정보·Camera 중심 Observer HUD

### DM

- DM Live Workspace
- DM Quick Action
- Encounter·Fog Control
- Scene Editor·Test Play·Publish
- Player View Preview
- Recovery·Rollback Review

전체 Navigation 항목은 28개다.

## 사용 방법

1. [`index.html`](index.html)을 브라우저에서 연다.
2. 왼쪽 Navigation에서 화면을 선택한다.
3. 상단에서 Accent, Viewport, UI Scale과 Motion Profile을 바꿔 본다.
4. 화면 밖에 입력 Focus가 있을 때 `Q`, `E`, `ESC`를 눌러 공통 입력 안내를 확인한다.
5. 역할별 추천 순서는 [`Player UI 예시`](../player/UI-EXAMPLES.md)와 [`DM UI 예시`](../dm/UI-EXAMPLES.md)를 따른다.

## 고정된 공통 계약

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
→ 현재 화면에 표시된 Confirm 하나 제출

ESC
→ Gameplay 의미 없음
```

- 권한에 없는 Action·Entity·Document는 Disabled 자리로 남기지 않는다.
- Disabled는 현재 Capability에는 있으나 조건을 만족하지 못한 상태다.
- Local Preview·Pending Animation은 Authority Result가 아니다.
- Player·Observer·DM은 별도 Permission-aware Projection을 받는다.

## 검증 상태

- HTML 문서 구조와 28개 화면 Navigation 매칭: 확인
- 중복 화면 ID: 없음
- 내부 Anchor 연결: 확인
- Roblox Studio Layout·Input·Projection Runtime: 미실행
- Release Screenshot과 실제 Font·한국어 렌더링: 미검증

정적 검수 기록은 [`User Guide HTML UI Example Audit`](../../audits/user-guide-html-ui-example-audit.md)을 참고한다.
