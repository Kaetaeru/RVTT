# UI HTML과 상위 권위 문서 충돌·재정렬 감사

- 상태: `COMPLETE · CORRECTIVE ADR ISSUED`
- 감사일: 2026-08-06
- 대상 HTML 기준 HEAD: `6e3626b`
- 정정 결정: [`ADR-0089`](../decisions/ADR-0089-observer-first-session-and-ui-surface-realignment.md)
- 정정 UI 명세: [`implementation-ready-ui-ux-and-settings-spec.md`](../ui/shared/implementation-ready-ui-ux-and-settings-spec.md)
- 재작성 HTML: [`User Guide HTML`](../user-guides/html/index.html)

## 1. 결론

기존 HTML은 두 종류의 충돌을 포함했다.

```text
A. 기존 상위 ADR은 이미 올바른 방향이었으나 HTML이 잘못 표현함
B. 이번 사용자 결정으로 기존 상위 문서 자체를 변경해야 함
```

HTML을 단독 수정하면 같은 문제가 반복되므로 ADR-0089와 구현 직전 명세를 먼저 갱신하고 HTML을 재작성한다.

## 2. 기존 HTML이 이미 확정된 ADR을 어긴 부분

| 영역 | 기존 권위 | 이전 HTML 문제 | 정정 |
|---|---|---|---|
| Character Sheet | ADR-0040은 공식 2024 시트의 2페이지 정보 구조와 한눈에 보는 핵심 배치를 확정 | 일반 RPG Card·Panel처럼 단순화 | Official Full Sheet를 핵심 화면으로 재작성 |
| Journal | ADR-0044는 왼쪽 문서·제목 탐색을 확정 | 중앙 Card와 오른쪽 정보 패널 중심 | 왼쪽 Vertical Document Tabs + Document Canvas |
| DM Quick Action | ADR-0047은 선택 문맥의 빠른 Overlay를 확정 | 별도 큰 창·Dashboard처럼 표현 | Cursor/Selection 인접 작은 세로 Popover |
| Combat HUD | ADR-0039는 BG3형 하단 Actor·Hotbar·Resource 읽기 흐름을 확정 | 하단 정보가 일반 Panel로 분절되고 Character Console 감각이 약함 | 연속된 Character Console로 통합 |
| Dice | ADR-0033은 물리 연출이 끝난 뒤 결과 공개를 확정 | 결과를 독립 Window/Card로 표현 | Physical Dice 뒤 Top Transparent Result Notice |

## 3. 이번 결정로 상위 계약을 변경한 부분

| 영역 | 기존 문서 상태 | 사용자 결정 | 권위 정정 |
|---|---|---|---|
| Session Entry | Character 선택·Role 선택 흐름이 남아 있음 | 최초 Observer, DM 배정 후 Owner | ADR-0089에서 Observer→Assignment→Player 전환 확정 |
| Ownership | Owner와 Controller 분리는 있었으나 Entry 전환과 결합되지 않음 | 배정 순간 Character Owner | Owner·Controller·Player Projection 원자 전환 |
| Default Actor | 명시 Selection 중심 | 다른 Actor 선택 없으면 Player Actor 기본 선택 | Effective Selection 계약 추가 |
| Objective | 상시 Tracker가 명세에 존재 | 불필요 | Player/Observer Surface와 Settings에서 제거 |
| Map·Minimap | ADR-0039·0041·Shared Spec에 존재 | 불필요 | Player/Observer UI에서 제거, World/Fog 데이터는 유지 |
| Context Action | 2열·큰 Table 가능성이 남음 | 작은 세로·간단한 Text | Compact one-column Menu 확정 |
| Character Sheet | 공식형만 상세 | 공식형 + BG형 VTT 관리 보기 | 두 View, 한 Projection 확정 |
| Downtime | Activity Planner 후속 UI가 열려 있음 | 실행은 DM 결정 | Player Launcher 제거, DM 배정/진행 확정 |
| Death Save | Domain State는 상세하지만 Presentation이 일반적 | 생존 위기처럼 긴박하게 | Urgency Overlay와 Console emergency state 확정 |
| DM Inspector | 기존 상세 문서는 오른쪽을 기본으로 사용 | 왼쪽 | Left Inspector 기본값 확정 |
| DM Tools | 도킹 Panel 중심 | Journal·Scene·Fog·Time·Encounter를 상단 | Top Authoring Strip 확정 |
| Scene Editor | 오른쪽 Inspector, Asset 창 플로팅 가능 | TaleSpire형, 왼쪽 Inspector·하단 Catalog | Viewport 중심 V2 Layout 확정 |

## 4. 유지하는 상위 규칙

다음은 변경하지 않는다.

- Q 한 단계 취소, ESC Gameplay No-op
- Left 기본 행동·Right Context·Middle Camera Orbit
- 권한 밖 Action·Document·Actor 미Projection
- Server Authoritative Command·Roll·Revision
- Owner와 Controller의 개념 분리
- Character Sheet·HUD·Inventory가 같은 Character Projection 사용
- Downtime Completion의 Domain Ownership과 Atomic Commit
- Scene Candidate Build와 Published Build 분리
- DM Quick Action도 기존 명령·감사·Undo 경계를 사용

## 5. 문서 상태 조치

### 최상위 현재 권위

- ADR-0089
- ADR-0088
- 구현 직전 UI·UX·Settings 명세

### 기존 문서

ADR-0033·0039·0040·0041·0044·0045·0047·0049·0080은 Domain·Authority 의미를 유지한다. 충돌하는 Presentation·Layout·Entry 부분만 ADR-0089가 대체한다.

`scene-editor-interaction-and-layout.md`의 오른쪽 Inspector와 플로팅 Asset 기본 배치는 현재 권위가 아니다. 새 `scene-editor-interaction-and-layout-v2.md`를 따른다.

## 6. 재작성 HTML Gate

- [x] Observer-first Entry
- [x] DM Assignment Transition
- [x] Default Owned Actor Selection
- [x] Objective·Map·Minimap 제거
- [x] Unified Character Console
- [x] Compact vertical Context Action
- [x] Top transparent Dice Result Notice
- [x] Official Sheet + VTT Management
- [x] DM-driven Downtime
- [x] Urgent Death Save
- [x] Journal left vertical tabs
- [x] DM left Inspector + top tools
- [x] Quick Action small popover
- [x] Scene Editor bottom catalog
- [ ] Roblox Studio Runtime Layout Evidence
- [ ] Player·Observer·DM Multi-client Evidence

## 7. 외부 참고 경계

- 공식 D&D 2024 Character Sheet는 정보 구조와 읽기 순서의 기준이다.
- TaleSpire는 전장 중심 Build Mode와 Catalog workflow의 참고점이다.
- 로고, 공식 장식, 고유 아트, 고유 아이콘과 픽셀 단위 외형은 복제하지 않는다.
