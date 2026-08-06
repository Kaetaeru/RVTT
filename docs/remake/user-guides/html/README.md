# RVTT 전체 UI HTML 예시 · ADR-0089 재정렬

- 상태: `CURRENT · TARGET EXPERIENCE`
- 최종 갱신일: 2026-08-06
- 실행 파일: [`index.html`](index.html)
- 상위 결정: [`ADR-0089`](../../decisions/ADR-0089-observer-first-session-and-ui-surface-realignment.md)
- 구현 직전 명세: [`implementation-ready-ui-ux-and-settings-spec.md`](../../ui/shared/implementation-ready-ui-ux-and-settings-spec.md)
- 충돌 감사: [`UI HTML Authority Conflict Audit`](../../audits/ui-html-authority-conflict-and-realignment-audit.md)

```text
HTML User Guide Example
≠ Roblox Production UI
≠ Studio Runtime Evidence
≠ Release Screenshot
```

## 변경 핵심

- 최초 참가를 Character 선택이 아닌 Observer 진입으로 변경
- DM 배정 시 Owner·Controller·Player Projection 전환 표시
- Player Character Actor의 기본 의미 선택 표시
- Objective·Map·Minimap 완전 제거
- Player 하단을 통합 Character Console로 재작성
- Context Action을 작은 세로 한 열 Menu로 축소
- 물리 주사위 뒤 상단 투명 Result Notice 추가
- Official Sheet와 VTT Management Sheet 분리
- Downtime을 DM 배정 상태 화면으로 변경
- Death Save를 생존 위기 Presentation으로 변경
- Journal을 왼쪽 세로 문서 탭으로 변경
- DM Inspector를 왼쪽, 도구를 상단으로 변경
- DM Quick Action을 작은 Popover로 변경
- Scene Editor를 중앙 Viewport·왼쪽 Inspector·하단 Catalog로 변경

## 포함 화면

총 26개 화면이다.

```text
세션·공통     3
Player 전장  8
Player 관리  6
설정·복구    3
Observer     1
DM           5
```

## 사용 방법

1. `index.html`을 브라우저에서 연다.
2. 왼쪽 Navigation에서 화면을 선택한다.
3. Accent, Viewport, UI Scale과 Motion을 변경한다.
4. 화면 밖에 Focus가 있을 때 Q·E·ESC를 눌러 공통 입력 Notice를 확인한다.

## 검증 상태

- 26개 Navigation과 Screen ID 대응: 확인
- 중복 Screen ID: 없음
- Objective·Map·Minimap Navigation: 없음
- Context Action: 세로 한 열
- Scene Editor Catalog: 하단
- 로컬 Chromium Screenshot: 실행 환경 문제로 미생성
- Roblox Studio Layout·Input·Projection: 미실행
