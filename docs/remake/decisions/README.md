# Architecture Decision Records

- 상태: ACTIVE
- 문서 종류: ADR Index
- 최종 갱신일: 2026-08-06

## 현재 UI·Content 권위 결정

### [`ADR-0091 개발 에셋 레지스트리·상호작용형 2024 시트·Dice Slot Reveal·프로필 분리형 Core Rules Reader`](ADR-0091-asset-registry-interactive-sheet-dice-and-core-rules.md)

- Token·Prop·Tile·Volume·UI Asset의 Authoring Source, Server Registry와 Client-safe Runtime 위치를 고정한다.
- Official Sheet는 D&D 2024 2-page Portrait 비율을 따르고 Roll·Equip·Unequip·Prepare·Use를 실행한다.
- Dice Notice는 Natural Slot Spin에서 Formula·Adjudication으로 단계적으로 확장한다.
- Advantage·Disadvantage, Natural 1·20과 Reduced Motion을 정의한다.
- Journal에 Module·Chunk 기반 Core Rules Collection을 제공한다.
- 개발·테스트 기본은 비공개 한국어 통합판 12 Class·48 Subclass·16 Background·10 Species·75 Feat·391 Spell이다.
- Public·Release 기본은 `rvtt.core.rules` SRD 5.2.1 범위이며 Private Rule Content 누출을 Build Gate로 차단한다.
- Final UI Gap Audit로 Invite, Onboarding, Missing Asset, Rule Profile, License, Conflict 상태를 폐쇄한다.

### [`ADR-0090 Character Console 다중 행 Action Matrix와 Modular DM Tool Window`](ADR-0090-multi-row-action-matrices-and-modular-dm-tool-windows.md)

- 공격·행동과 주문을 별도 1–4행 Matrix로 표시한다.
- 핵심 Resource Rail은 Console 상단에 둔다.
- DM Tool은 독립 Window Module이며 여러 창을 동시에 연다.

### [`ADR-0089 Observer 우선 세션 진입과 전술 콘솔 중심 UI 표면`](ADR-0089-observer-first-session-and-ui-surface-realignment.md)

- 미배정 참가자는 Observer로 진입한다.
- DM 배정이 Owner·Controller·Player Projection을 전환한다.
- Owned Actor는 기본 의미 선택이다.
- Objective·Map·Minimap을 제거한다.

### [`ADR-0088 직접 플레이 포인터 문법과 피드백 연속성`](ADR-0088-direct-play-pointer-grammar-and-feedback.md)

- Left Click: 선택 또는 가시적인 기본 행동
- Right Click: Compact Capability Action Menu
- Middle Drag: Camera Orbit
- Q: Context 한 단계 취소
- E: 표시된 Confirm
- ESC: Gameplay 의미 없음

## 권위 순서

```text
CURRENT-WORK-ORDER
→ ADR-0091
→ ADR-0090
→ ADR-0089
→ ADR-0088
→ 상세 UI·System 계약
→ High-Fidelity HTML
→ Production Source·Runtime Evidence
```

최신 ADR이 충돌하는 이전 Presentation을 대체한다. 문서·HTML 완료를 Runtime PASS로 해석하지 않는다.
