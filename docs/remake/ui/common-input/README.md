# Common Input UI

Q·E, 세 Pointer, 문맥별 1–5, Input Context Stack과 직접 플레이 피드백의 표시·우선순위를 다룬다.

## 최상위 UX 결정

- [`ADR-0088 직접 플레이 포인터 문법과 피드백 연속성`](../../decisions/ADR-0088-direct-play-pointer-grammar-and-feedback.md)
  - 왼쪽 클릭: 선택 또는 클릭 전에 표시된 기본 행동
  - 오른쪽 클릭: Capability 기반 전체 행동표
  - 마우스 휠 클릭 드래그: 카메라 Orbit
  - Q: 최상위 문맥 하나만 닫기·취소
  - ESC: Gameplay 의미 없음
  - 비활성 행동: 비활성 색상 + Hover 시 커서 옆 불가능 사유
  - 이동·대상 Preview, 선택 유지, Soft Focus, Pending·승인·거부 피드백

## Main System Guide

- [`UI, Camera와 Presentation Guide`](../../guides/ui/README.md)
  - Physical Input→Semantic Action→Input Context→UI Intent의 공통 Client 흐름
  - Q·E·Pointer·1–5 단일 소비, Focus Token, Authority Prompt와 Epoch-safe 복구
- [`Journal과 Ping Guide`](../../guides/journal/README.md)
  - Journal 편집·검색·Link Activation 입력과 Ping 작성 Context
  - Q로 Ping Draft 취소, Targeting·Scene Edit·Text Input의 우선순위 경계
- [`Exploration, Selection, Interaction과 Perception Guide`](../../guides/exploration/README.md)
  - Physical Input에서 Semantic Action·Input Context·Selection Session으로 이어지는 흐름
  - Q·E 단일 소비, Candidate Navigation 분리와 Frozen Binding
  - Default Action·Action Table·DM Adjudication·Hover Projection과 재접속 복구 경계

## 상위 권위 계약

- [`UI Projection, ViewModel, Input Context와 Recovery Runtime 계약`](../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md)
  - Semantic Input Router, Input Context Stack과 Focus 수명주기
  - Authority Prompt·Local Modal·Panel Context 분리
  - Reconnect·Rollback 후 Context Token 폐기와 복구
- [`Selection Runtime 계약`](../../architecture/selection-targeting-preview-and-frozen-binding-runtime-contract.md)
  - Selection Session과 Frozen Binding에서의 Q/E·Pointer 의미
- [`Interaction Capability 계약`](../../architecture/interaction-capability-contextual-command-and-adjudication-contract.md)
  - Capability-derived Action Option과 서버 재검증

## 세부 UI 문서

- [`common-input-grammar.md`](common-input-grammar.md)
  - Q는 최상위 문맥 하나만 닫기·취소·거절
  - E는 승인·확정·실행·상호작용
  - 왼쪽 클릭은 선택 또는 가시적인 기본 행동
  - 오른쪽 클릭은 2열 Context Action Table
  - 중클릭 드래그는 Camera Orbit
  - 1–5는 화면에 의미가 표시된 현재 문맥의 주요 슬롯
  - 이동·대상 Preview, 선택·턴 연속성과 서버 피드백

## 고정 경계

- 기능 Component가 물리 키와 마우스 버튼을 직접 감시하지 않는다.
- 가장 위의 유효 Input Context 하나만 입력을 소비한다.
- ESC에는 Gameplay 의미를 부여하지 않는다.
- Q 한 번으로 여러 Context를 연속 해제하지 않는다.
- Text Input이 활성일 때 Gameplay Q/E·Pointer 단축 행동·숫자 슬롯·Camera 키를 실행하지 않는다.
- Viewer 권한에 없는 행동과 미인지 정보는 Projection하지 않는다.
- 현재 불가능한 행동은 비활성 색상으로 표시하고 Hover Tooltip으로 이유를 제공한다.
- Authority Prompt와 Command는 입력 직후 로컬에서 완료하지 않고 서버 응답과 Projection을 기다린다.
- Context 소유 Panel·Selection·Prompt가 종료되면 Context Token을 반드시 해제한다.
