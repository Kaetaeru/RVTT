# RVTT Player·Observer·DM User Guides

- 상태: `CURRENT · ADR-0089 ALIGNED`
- 사용자 가이드 상태: `TARGET_EXPERIENCE`
- 최종 갱신일: 2026-08-06
- 전체 UI HTML: [`html/index.html`](html/index.html)
- HTML 설명: [`html/README.md`](html/README.md)
- 상위 결정: [`ADR-0089`](../decisions/ADR-0089-observer-first-session-and-ui-surface-realignment.md)

이 폴더는 Player·Observer·DM이 세션에서 보는 화면과 수행하는 행동을 사용자 언어로 설명한다. 구현 전 목표 경험이며 실제 Roblox Runtime 증거가 아니다.

## 처음 읽을 문서

1. [`한눈에 보는 세션 흐름`](QUICK-FLOW.md)
2. [`전체 UI HTML 예시`](html/index.html)
3. [`Player·Observer Guide`](player/README.md)
4. [`DM Guide`](dm/README.md)

## 세션 참가의 핵심

```text
세션 연결
→ Observer로 공개 Scene 확인
→ DM의 Character 배정
→ 해당 Character Owner·Controller가 됨
→ Player Projection과 Character Console 활성화
→ Owned Actor가 기본 선택
```

Player가 Entry 화면에서 Character를 직접 선택하지 않는다.

## Player 화면의 핵심

- Objective·Map·Minimap UI 없음
- 하단 Unified Character Console
- Right Click은 작은 세로 Context Action Menu
- 물리 주사위 뒤 상단 투명 Result Notice
- 공식 D&D 2024형 정보 구조의 Character Sheet
- VTT 관리형 Character·Inventory View
- Downtime 활동은 DM이 배정
- Death Save는 긴급 생존 Presentation
- Journal은 왼쪽 세로 문서 탭

## DM 화면의 핵심

- 상단: Scene·Quick Edit·Fog·Time·Encounter·Journal·Players·Rollback
- 왼쪽: Inspector
- 중앙: Live Scene
- Quick Action: 작은 문맥 Popover
- Full Scene Editor: 왼쪽 Inspector·하단 Catalog·중앙 Build Viewport

## 공통 입력

```text
Left Click
→ 선택 또는 클릭 전에 표시된 기본 행동

Right Click
→ 작은 세로 Context Action Menu

Middle-button Drag
→ Camera Orbit

Q
→ 최상위 문맥 하나 취소
→ 명시 Actor 선택을 끝내면 Owned Actor로 복귀

E
→ 현재 표시된 Confirm 하나 제출

ESC
→ Gameplay 의미 없음
```

## Runtime에서 아직 증명되지 않은 것

- Observer→Owner·Player 전환의 실제 Multi-client 동작
- Character Console의 Roblox Layout
- Official Sheet의 한국어 정보 밀도
- Dice Result Notice Timing
- Death Save Motion·Contrast
- DM Scene Editor Catalog 성능
- UI Scale 0.80·1.40와 저사양 Fallback

User Guide와 HTML이 ADR·Architecture·UI 명세와 충돌하면 상위 권위 문서가 우선한다.
