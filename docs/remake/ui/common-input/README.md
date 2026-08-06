# Common Input UI

Q·E, Left·Right·Middle Pointer, 문맥별 1–5, Input Context Stack과 직접 플레이 피드백의 표시·우선순위를 다룬다.

## 최상위 UX 결정

- [`ADR-0088 직접 플레이 포인터 문법과 피드백 연속성`](../../decisions/ADR-0088-direct-play-pointer-grammar-and-feedback.md)

```text
왼쪽 클릭
→ 선택 또는 클릭 전에 표시된 기본 행동

오른쪽 클릭
→ Capability 기반 전체 행동표

마우스 휠 클릭 드래그
→ Camera Orbit

Q
→ 최상위 Context 하나만 닫기·취소

E
→ 현재 Preview·선택·승인·확정

ESC
→ Gameplay 의미 없음
```

- 비활성 행동: 비활성 색상 + Hover·Keyboard Focus에서 불가능 사유
- 권한 밖 행동·미인지 정보: Projection하지 않음
- 이동·대상 Preview, Selection 유지, Soft Focus, Pending·Denied·Stale 피드백

## 구현 직전 화면 명세

- [`Full UI·UX and Settings Specification`](../shared/implementation-ready-ui-ux-and-settings-spec.md)
  - Global Shell과 화면별 Input Context
  - Tooltip·Action Label·Settings·Binding 기본값
  - Inventory·Journal·Map·Recovery의 Q/E·Pointer 적용

## Main System Guide

- [`UI, Camera와 Presentation Guide`](../../guides/ui/README.md)
- [`Journal과 Ping Guide`](../../guides/journal/README.md)
- [`Exploration, Selection, Interaction과 Perception Guide`](../../guides/exploration/README.md)

## 상위 권위 계약

- [`UI Projection Runtime`](../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md)
- [`Selection Runtime`](../../architecture/selection-targeting-preview-and-frozen-binding-runtime-contract.md)
- [`Interaction Capability 계약`](../../architecture/interaction-capability-contextual-command-and-adjudication-contract.md)

## 세부 UI 문서

- [`common-input-grammar.md`](common-input-grammar.md)

## 고정 경계

- 기능 Component가 물리 키와 마우스 버튼을 직접 감시하지 않는다.
- 가장 위의 유효 Input Context 하나만 입력을 소비한다.
- ESC에는 Gameplay 의미를 부여하지 않는다.
- Q 한 번으로 여러 Context를 연속 해제하지 않는다.
- Text Input 중 Gameplay Q/E·Pointer 단축 행동·숫자 슬롯·Camera 키를 실행하지 않는다.
- Viewer 권한에 없는 행동과 미인지 정보는 Projection하지 않는다.
- 현재 불가능한 행동은 비활성 색상으로 표시하고 Hover·Focus Reason을 제공한다.
- Authority Prompt와 Command는 입력 직후 로컬에서 완료하지 않고 서버 응답과 Projection을 기다린다.
- Context 소유 Panel·Selection·Prompt가 종료되면 Context Token을 반드시 해제한다.
