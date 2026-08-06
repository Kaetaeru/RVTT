# Architecture Decision Records

- 상태: ACTIVE
- 문서 종류: ADR Index
- 최종 갱신일: 2026-08-06

되돌리기 어렵거나 여러 시스템에 영향을 주는 결정을 시간순 ADR로 기록한다.

## 현재 UI·직접 플레이 권위 결정

### [`ADR-0090 Character Console Action Matrix와 Modular DM Tool Window`](ADR-0090-multi-row-action-matrices-and-modular-dm-tool-windows.md)

- 공격·행동과 주문은 별도 Action Matrix로 표시한다.
- 사용자는 Matrix 높이를 1–4행으로 설정한다.
- 작은 Action Icon은 행을 채운 뒤 오른쪽으로 이어진다.
- Hover·Keyboard Focus 시 Cursor 위에 행동 설명 Panel을 표시한다.
- 핵심 자원은 Character Console 상단 전체 폭의 Resource Rail에 둔다.
- 기억·준비 가능 주문 수와 실제 주문 슬롯을 분리한다.
- ADR-0089의 Top Strip·Left Inspector는 기본 Layout이며 고정 단일 Panel 구조가 아니다.
- ADR-0045에 따라 DM Tool은 독립 Module Window로 여러 개를 동시에 열고 Move·Resize·Dock·Close한다.

ADR-0090은 ADR-0089의 Character Console·DM Workspace 표현을 보강하고 ADR-0045의 Dockable·Floating Workspace 계약을 재확인한다.

### [`ADR-0089 Observer 우선 세션 진입과 전술 콘솔 중심 UI 표면`](ADR-0089-observer-first-session-and-ui-surface-realignment.md)

- 미배정 참가자는 Observer로 진입한다.
- DM의 Character 배정이 Owner·Controller·Player Projection을 함께 전환한다.
- Player Character Actor는 명시적 다른 선택이 없으면 기본 의미 선택이다.
- Objective·Map·Minimap Player UI를 제거한다.
- 하단은 통합 Character Console을 사용한다.
- Context Action Table은 작고 세로 한 열이다.
- 물리 주사위 뒤 상단 투명 Result Notice를 표시한다.
- 공식형 Character Sheet와 VTT 관리형 Character Sheet를 모두 제공한다.
- DM Quick Action은 큰 창이 아니라 문맥 Popover다.

ADR-0090이 Character Console 내부와 DM Window Modularity를 추가로 구체화한다.

### [`ADR-0088 직접 플레이 포인터 문법과 피드백 연속성`](ADR-0088-direct-play-pointer-grammar-and-feedback.md)

- 왼쪽 클릭: 선택 또는 가시적인 기본 행동
- 오른쪽 클릭: Capability 기반 Context Action Table
- 마우스 휠 클릭 드래그: Camera Orbit
- Q: 최상위 문맥 하나만 닫기·취소
- ESC: Gameplay 의미 없음
- 비활성 행동: 비활성 색상과 Hover·Focus 불가능 사유

## 기본 규칙

- 파일명: `ADR-XXXX-short-title.md`
- 번호는 전역에서 증가한다.
- 기존 ADR 번호를 재사용하지 않는다.
- 최신 결정이 기존 ADR을 대체하면 `superseded by`·`supersedes` 관계를 기록한다.
- 단순 기능 설명은 `systems/`, 공통 Runtime 계약은 `architecture/`, 화면 계약은 `ui/`에 둔다.
- User Guide와 HTML 예시는 ADR을 새로 만들지 않는다.

## 읽기 순서

```text
CURRENT-WORK-ORDER
→ Quick Flow와 User Guide
→ ADR-0090·ADR-0089·ADR-0088
→ 구현 직전 UI·UX 명세
→ 관련 Runtime·Domain 문서
→ Implementation Spec
```

- 현재 작업 순서: [`../CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)
- Quick Flow: [`../user-guides/QUICK-FLOW.md`](../user-guides/QUICK-FLOW.md)
- 구현 직전 UI·UX: [`../ui/shared/implementation-ready-ui-ux-and-settings-spec.md`](../ui/shared/implementation-ready-ui-ux-and-settings-spec.md)
- Character Console 상세: [`../ui/combat-hud/character-console-action-matrix-and-resource-rail.md`](../ui/combat-hud/character-console-action-matrix-and-resource-rail.md)
- DM Window Module 상세: [`../ui/dm-workspace/modular-dm-tool-window-contract.md`](../ui/dm-workspace/modular-dm-tool-window-contract.md)
- Architecture: [`../architecture/README.md`](../architecture/README.md)
- Systems: [`../systems/README.md`](../systems/README.md)
- Implementation Specs: [`../specs/README.md`](../specs/README.md)

## 권위와 수명주기

- 확정 ADR은 관련 Product·Architecture·System·UI보다 높은 결정 근거다.
- Character Console·DM Workspace 세부가 충돌하면 ADR-0090을 따른다.
- Session Entry·Ownership·전체 UI Surface가 충돌하면 ADR-0089를 따른다.
- 오래된 문서는 삭제하지 않고 Git history로 결정 변화를 보존한다.
- 문서 완료를 Runtime PASS로 해석하지 않는다.
