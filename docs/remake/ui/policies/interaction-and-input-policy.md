# RVTT Interaction and Input Policy

- 상태: CURRENT
- 문서 종류: Global UX Interaction Policy
- 작성일: 2026-08-05
- 최종 개정일: 2026-08-06
- 최상위 직접 플레이 결정: [`ADR-0088`](../../decisions/ADR-0088-direct-play-pointer-grammar-and-feedback.md)
- 구현 직전 화면 명세: [`구현 직전 UI·UX와 설정 명세`](../shared/implementation-ready-ui-ux-and-settings-spec.md)
- Policy Work Order: [`CURRENT-WORK-ORDER`](CURRENT-WORK-ORDER.md)
- 공통 입력 권위: [`공통 입력 교과서`](../common-input/common-input-grammar.md)
- Selection 권위: [`Selection Runtime`](../../architecture/selection-targeting-preview-and-frozen-binding-runtime-contract.md)
- UI Runtime 권위: [`UI Projection Runtime`](../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md)

이 문서는 Player, DM, Observer, Scene Editor와 모든 Panel이 공유하는 조작 의미, 문맥, 확인·취소와 안전 정책을 정의한다.

## 1. 핵심 원칙

```text
현재 문맥과 다음 입력 결과를 먼저 보여준다.
→ 사용 가능한 행동과 비용을 보여준다.
→ 사용자가 의도를 제출한다.
→ 서버가 최신 상태에서 검증한다.
→ Projection으로 결과를 확정한다.
```

- 같은 입력은 같은 문맥에서 같은 의미를 가져야 한다.
- 사용자가 현재 무엇을 조작하고 다음 입력이 무엇을 할지 알 수 있어야 한다.
- 직접 조작은 Preview와 Pending Feedback을 만들 수 있지만 Authority를 직접 변경하지 않는다.
- 위험·비용·대상·결과 범위는 제출 전에 확인할 수 있어야 한다.
- 기능별 Component가 물리 키와 마우스 버튼을 직접 감시하지 않는다.
- Viewer 권한에 없는 행동과 미인지 정보는 Client UI Projection에 존재하지 않는다.

## 2. 입력 계층

```text
Physical Input
→ Binding Profile
→ Semantic Action
→ Input Context Stack
→ UI Intent | Selection Intent | Camera Action | Local Action
```

Input Context 우선순위:

```text
Text·Search·Numeric Input
> Critical Modal·Authority Prompt
> Drag·Targeting·다단계 작업
> Floating Panel·Context Action Table
> Focused Docked Panel
> Base Mode HUD·DM Workspace·Scene Editor
> Global Camera·비차단 단축키
```

가장 위의 유효 Context 하나만 입력을 소비한다. 입력을 처리한 뒤 아래 Context로 전달하지 않는다.

## 3. 공통 의미 입력

### Q — Cancel·Reject·Back

Q는 현재 최상위 문맥 하나만 닫거나 취소한다.

- Context Action Table 열림: Table만 닫는다.
- Targeting·Preview 중: 현재 단계만 취소하고 이전 행동 문맥으로 돌아간다.
- 반복 행동 고정 중: 반복 행동만 해제한다.
- Authority Prompt 중: 거절 Intent를 제출한다.
- Local Side Sheet·Panel Detail 중: 현재 Detail 하나만 닫는다.
- 하위 문맥 없이 Actor만 선택됨: Actor 선택을 해제한다.
- 취소 대상이 없으면 아무 행동도 하지 않는다.

Q 한 번으로 Modal, Panel, Targeting, Actor Selection과 Gameplay Mode를 연쇄 종료하지 않는다.

### E — Confirm·Execute·Interact

E는 화면에 공개된 현재 최우선 유효 행동 하나만 확정한다.

- Confirm Label이 없으면 숨은 E 행동을 실행하지 않는다.
- 대상·비용·조건이 아직 불완전하면 실행하지 않는다.
- Client는 E 입력으로 Authority 상태를 직접 변경하지 않는다.
- 파괴적 행동은 위험도 정책에 따라 추가 확인을 요구한다.

### ESC — Gameplay No-op

ESC에는 Gameplay 의미를 부여하지 않는다.

- Context Action Table, Targeting, Panel, Prompt와 Actor Selection을 ESC로 닫지 않는다.
- System Menu도 ESC에 하드코딩하지 않는다.
- 시스템 화면은 명시적 System Button 또는 재설정 가능한 Semantic Action으로 연다.

### 1–5 — 공개된 Primary Action Slot

- 화면에 Label과 현재 의미가 보일 때만 활성화한다.
- 빈 Slot에는 숨은 행동을 연결하지 않는다.
- 다섯 개를 넘는 행동은 Category, Overflow 또는 검색으로 보낸다.
- 숫자만 눌러 되돌리기 어려운 결과를 즉시 Commit하지 않는다.
- Scene Editor는 별도 결정 전까지 1–5를 점유하지 않는다.

## 4. Pointer 정책

### 4.1 Left Pointer — PrimaryPointer

World 기본 의미:

```text
선택 Actor 없음
→ 조작 가능 Actor 선택

선택 Actor 있음
→ 클릭 전에 표시된 결정적 기본 행동 요청 또는 Preview
```

우선순위:

```text
조작 가능한 다른 아군 Actor
→ 해당 Actor 선택 전환

적대 Actor + Encounter
→ 현재 기본 전투 행동

우호·중립 Actor
→ 대화·도움·상호작용

Exploration Object
→ 상태에 맞는 기본 상호작용

이동 가능 표면
→ 이동
```

기본 행동은 클릭 전에 Cursor, Outline, Action Label과 필요한 비용·유효성으로 표시한다. 최근 사용만으로 숨은 기본 행동을 자동 변경하지 않는다.

Panel 기본 의미:

- Button·Control 활성화
- Item·List Entry 선택
- 위치·대상 지정
- Drag 시작·완료
- 배치 Preview의 주요 조작

### 4.2 Right Pointer — ContextActionPointer

오른쪽 클릭은 선택 Actor와 클릭 대상을 기준으로 Capability-derived Context Action Table을 연다.

- 기본 2열 Button Table을 사용한다.
- 권한에 없는 행동은 표시하지 않는다.
- 권한에는 있으나 현재 불가능한 행동은 비활성 색상 Button으로 표시한다.
- 비활성 Button Hover·Keyboard Focus 시 커서 또는 Control 근처에 구체적인 불가능 사유를 표시한다.
- Button 옆에 가능·불가능 문장을 상시 나열하지 않는다.
- 다른 대상을 오른쪽 클릭하면 기존 Table을 새 대상의 Table로 교체한다.
- Table이 열린 동안 World 좌클릭 기본 행동은 실행하지 않는다.
- Q로 Table만 닫는다.

오른쪽 클릭은 Camera를 회전하지 않는다.

### 4.3 Middle Pointer Drag — CameraOrbitPointer

마우스 휠 클릭 드래그는 자유 전술 카메라 Yaw·Pitch Orbit에 사용한다.

- UI Control 위에서 시작한 Drag는 Camera가 소비하지 않는다.
- Pointer Capture를 잃으면 Orbit을 안전하게 종료한다.
- Context Action Table이 열려도 Middle Pointer Orbit은 유지할 수 있다.
- Camera 조작은 Selection, Targeting Authority와 정보 공개를 변경하지 않는다.

### 4.4 Hover

- Hover는 정보 Preview와 시각 강조를 제공할 수 있다.
- Hover만으로 Camera 이동, Authority Selection, Action 실행과 비밀 정보 공개를 하지 않는다.
- 핵심 정보는 Keyboard Focus 또는 Click으로도 접근 가능해야 한다.
- World Hover는 다음 Left Pointer 결과를 즉시 표시한다.

### 4.5 Drag

```text
Drag Start
→ 대상·권한·Context Token 고정
→ Local Preview
→ Drop Candidate 표시
→ Drop Intent
→ Server Revalidation
→ Projection Reconciliation
```

Drag 중 대상이 사라지거나 Revision이 바뀌면 안전하게 취소하고 이유를 보여준다. Inventory·Editor처럼 Drag를 제공하는 기능에는 Click 기반 대체 경로가 있어야 한다.

## 5. Focus 분리

다음을 하나의 상태로 합치지 않는다.

```text
Pointer Hover
Keyboard Focus
Text Input Focus
World Focus
Selection Focus
Camera Focus
```

- Keyboard Focus는 명확한 Ring과 Accessible Name을 가진다.
- Modal 종료 후 이전 Focus를 한 단계 복원한다.
- 이전 대상이 삭제·비공개·권한 상실이면 안전한 Panel Root 또는 World Context로 이동한다.
- Camera Focus는 Selection과 Authority Target을 바꾸지 않는다.
- Tooltip Reason은 Hover뿐 아니라 Keyboard Focus에서도 접근할 수 있어야 한다.

## 6. Selection과 Targeting

```text
Candidate 표시
→ 사용자 선택
→ Frozen Binding 후보
→ 비용·범위·적격성 Preview
→ 필요 시 E Confirm
→ Server 최신 Snapshot 재검증
```

- Hover, Focus, Actor Selection, Action Target을 서로 다르게 표시한다.
- 선택 대상이 여러 종류면 Type·거리·공개 상태를 함께 표시한다.
- Targeting 중 다른 Panel을 열어도 Targeting이 조용히 Commit되지 않는다.
- 최신 상태에서 부적격이 되면 `stale` 또는 `denied`로 처리하고 재선택 경로를 제공한다.
- Hidden Entity Identity를 Candidate Payload에 넣지 않는다.
- 이동, 공격과 상호작용 완료 후 행동 주체 Actor Selection을 유지한다.

## 7. Mode와 Context 가시성

사용자는 최소한 다음을 구분할 수 있어야 한다.

```text
Exploration
Encounter
Downtime
Observer
DM Live
Scene Authoring
Paused·Transition·Recovery
```

표현 수단:

- Mode·Role Badge
- 활성 Input Hint
- 선택 가능한 대상의 Cursor·Outline
- 현재 Actor·Turn·Prompt 강조
- 위험한 Mode 전환 전 Preview

Panel이 열렸다는 이유로 Gameplay Mode가 바뀌지 않는다. 턴 전환은 Camera를 강제로 이동하지 않고 HUD 강조와 Soft Focus 알림만 제공한다.

## 8. 확인 위험도

### Tier 0 — 즉시 Local

예: Panel 열기, Tab 전환, 정렬, Camera Bookmark 선택, Settings Preview.

### Tier 1 — 되돌리기 쉬운 Authority Action

예: 일반 이동, 기본 공격, 비파괴 상호작용. 클릭 전에 결과를 표시하고 한 번의 명시적 입력으로 제출한다.

### Tier 2 — 비용·상태 변경

예: Item Transfer, 제한 자원 소비, 주문 시전, 집중 종료 가능 행동. 대상·비용·예상 결과를 보여주고 E 또는 명확한 Confirm Button으로 제출한다.

### Tier 3 — 파괴·권한·Rollback

예: Character 삭제, Scene Publish, Pack 제거, 강제 종료, Rollback, 위험한 DM Override.

필수:

- 구체적인 대상과 영향 범위
- 되돌릴 수 있는지 여부
- 필요한 경우 현재 vs 결과 Diff
- 명시적인 파괴 동사
- 기본 Focus를 안전한 선택에 둠
- 입력 실수 방지를 위한 별도 Confirm 단계

단순한 “확인하시겠습니까?”만 표시하지 않는다.

## 9. Progressive Disclosure

```text
현재 결정에 필요한 정보
→ 즉시 표시

설명·근거·상세 수치
→ Tooltip·Context Card·Side Sheet

전체 기록·진단
→ Journal·Log·DM Workspace·Support Surface
```

- 초보자에게 필요한 기본 경로를 숨기지 않는다.
- 전문가용 세부 정보가 기본 행동을 밀어내지 않는다.
- 복잡한 Action은 Step을 나누되 각 Step에서 Q·E 의미를 표시한다.
- 같은 Authority 값을 여러 Panel에서 중복 편집하지 않는다.

## 10. Action 가용성과 피드백

```text
권한에 없는 Action
→ Projection하지 않음

권한에는 있으나 현재 실행 불가
→ disabled
→ 비활성 색상
→ Click 불가
→ Hover·Focus Reason

제출됨
→ pending
→ 중복 제출 차단

서버 거부
→ denied
→ 관련 Cursor·대상·Control 근처에 이유

최신 상태와 충돌
→ stale
→ Projection 갱신과 재선택 경로
```

일반 실패를 화면 중앙 Modal로 표시하지 않는다. 권위 결과는 최신 Projection에서 확인한 뒤 확정한다.

## 11. DM 상호작용

- DM Override는 일반 Store 수정이 아니라 명명된 Command로 실행한다.
- Player Route와 DM Override Route를 시각적으로 구분한다.
- Player View Preview는 Control Assignment를 변경하지 않는다.
- Quick Action에는 대상, 공개 범위, 현재 Revision과 결과 영향이 표시된다.
- 위험한 Override는 Mandatory Audit과 Tier 3 확인을 사용한다.
- 여러 Player 요청이 동시에 오면 우선순위·대상·만료를 보여주고 E/Q가 어느 요청에 적용되는지 명확히 한다.
- DM Action Table에도 Viewer Capability가 없는 Action 자리와 Count를 남기지 않는다.

## 12. Editor 상호작용

- Tool은 Selection·Placement·Snap·Preview·Inspector 공통 Host를 재사용한다.
- Tool마다 자체 입력 문법을 만들지 않는다.
- Shift는 현재 조작의 Snap 임시 해제를 의미한다.
- Ghost·Gizmo·ViewY는 Local Preview이며 Source Commit이 아니다.
- Auto Save, Compile, Publish와 Live Patch를 같은 Button 또는 상태로 합치지 않는다.
- Tool 종료 시 Connection, Ghost, Input Context와 Focus를 정리한다.
- Editor가 Right Pointer를 별도 기능에 사용할 경우 최상위 Context와 화면 Hint를 명시하며 Player Direct Play 문법을 조용히 덮어쓰지 않는다.

## 13. 금지 패턴

- Component의 `InputBegan` 직접 처리로 전역 키 충돌 생성
- ESC에 Gameplay 닫기·취소·메뉴 의미 부여
- Right Pointer로 Camera 회전
- 화면에 표시되지 않은 단축키
- Click과 E가 서로 다른 숨은 결과를 실행
- Modal 닫기만으로 Authority Prompt 완료
- Hover로 선택·카메라 이동·비밀 공개
- Disabled Action을 이유 없이 표시
- 권한 밖 Action을 회색 자리로 남김
- Drag Ghost를 실제 Item·Scene 위치로 저장
- 실패 후 사용자가 처음부터 모든 선택을 다시 해야 하는 구조
- 파괴 행동의 기본 Focus를 Confirm에 두는 구조
- Panel Open State를 Gameplay Mode로 사용
- 행동 완료마다 Actor Selection 해제
- 턴 변경마다 Camera 강제 이동

## 14. 구현 검수

- 현재 Context와 Q/E·Pointer 의미가 보인다.
- 같은 입력을 두 Context가 동시에 소비하지 않는다.
- Q가 한 단계만 취소하고 ESC는 Gameplay No-op이다.
- Left Pointer 결과가 클릭 전에 표시된다.
- Right Pointer가 Capability Action Table을 연다.
- Middle Pointer Drag가 Camera Orbit을 소유한다.
- Disabled Action은 비활성색과 Hover·Focus Reason을 가진다.
- Target·비용·영향을 제출 전에 확인할 수 있다.
- Server Revalidation과 Pending·Denied·Stale 경로가 있다.
- 행동 후 Actor Selection이 유지된다.
- Keyboard·Pointer 모두 핵심 경로를 사용할 수 있다.
- 위험 행동의 확인 Tier가 적절하다.
- DM·Player·Observer Route와 공개 범위가 Projection에서 구분된다.
