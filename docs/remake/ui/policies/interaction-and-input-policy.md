# RVTT Interaction and Input Policy

- 상태: CURRENT
- 문서 종류: Global UX Interaction Policy
- 작성일: 2026-08-05
- Policy Work Order: [`CURRENT-WORK-ORDER`](CURRENT-WORK-ORDER.md)
- 공통 입력 권위: [`공통 입력 교과서`](../common-input/common-input-grammar.md)
- Selection 권위: [`Selection Runtime`](../../architecture/selection-targeting-preview-and-frozen-binding-runtime-contract.md)
- UI Runtime 권위: [`UI Projection Runtime`](../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md)

이 문서는 Player, DM, Scene Editor와 모든 Panel이 공유하는 조작 의미, 문맥, 확인·취소와 안전 정책을 정의한다.

## 1. 핵심 원칙

```text
현재 문맥을 먼저 보여준다.
→ 사용 가능한 행동과 비용을 보여준다.
→ 사용자가 의도를 제출한다.
→ 서버가 검증한다.
→ 최신 Projection으로 결과를 확정한다.
```

- 같은 입력은 같은 문맥에서 같은 의미를 가져야 한다.
- 사용자가 현재 무엇을 조작하고 있는지 항상 알 수 있어야 한다.
- 직접 조작은 Preview를 만들 수 있지만 Authority를 직접 변경하지 않는다.
- 위험·비용·대상·결과 범위는 제출 전에 확인할 수 있어야 한다.
- 기능별 Component가 물리 키를 직접 감시하지 않는다.

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
> Focused Panel
> Base Mode HUD·DM Workspace·Scene Editor
> Global Camera·비차단 단축키
```

가장 위의 유효 Context 하나만 입력을 소비한다. 입력을 처리한 뒤 아래 Context로 전달하지 않는다.

## 3. 공통 의미 입력

### Q — Cancel·Reject·Back

Q는 현재 문맥에서 가장 가까운 미완성 상태 하나만 취소한다.

- Targeting 중: Targeting만 취소한다.
- 다단계 Tool 중: 현재 Step 또는 Preview만 취소한다.
- Authority Prompt 중: 거절 Intent를 제출한다.
- 닫을 Local Overlay가 있을 때: 한 단계만 닫는다.
- 취소 대상이 없으면 아무 행동도 하지 않는다.

Q 한 번으로 Modal, Panel, Mode와 Tool을 연쇄 종료하지 않는다.

### E — Confirm·Execute·Interact

E는 화면에 공개된 현재 최우선 유효 행동 하나만 확정한다.

- Confirm Label이 없으면 숨은 E 행동을 실행하지 않는다.
- 대상·비용·조건이 아직 불완전하면 실행하지 않는다.
- Client는 E 입력으로 Authority 상태를 직접 변경하지 않는다.
- 파괴적 행동은 위험도 정책에 따라 추가 확인을 요구할 수 있다.

### 1–5 — 공개된 Primary Action Slot

- 화면에 Label과 현재 의미가 보일 때만 활성화한다.
- 빈 Slot에는 숨은 행동을 연결하지 않는다.
- 다섯 개를 넘는 행동은 Category, Overflow 또는 검색으로 보낸다.
- 숫자만 눌러 되돌리기 어려운 결과를 즉시 Commit하지 않는다.
- Scene Editor는 별도 결정 전까지 1–5를 점유하지 않는다.

## 4. Pointer 정책

### Left Pointer

기본 의미:

- 선택
- 위치·대상 지정
- Drag 시작·완료
- Button·Control 활성화
- 배치 Preview의 주요 조작

### Right Pointer

기본적으로 Camera 회전·조작에 우선한다. Context Menu를 사용하는 화면은 Camera Context와 충돌하지 않도록 명시적 Panel 영역에서만 사용한다.

### Hover

- Hover는 정보 Preview와 시각 강조를 제공할 수 있다.
- Hover만으로 Camera 이동, Authority Selection, Action 실행과 비밀 정보 공개를 하지 않는다.
- 핵심 정보는 Focus·Click·Keyboard로도 접근 가능해야 한다.

### Drag

```text
Drag Start
→ 대상·권한·Context Token 고정
→ Local Preview
→ Drop Candidate 표시
→ Drop Intent
→ Server Revalidation
→ Projection Reconciliation
```

Drag 중 대상이 사라지거나 Revision이 바뀌면 안전하게 취소하고 이유를 보여준다.

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

- Keyboard Focus는 명확한 Ring과 Label을 가진다.
- Modal 종료 후 이전 Focus를 한 단계 복원한다.
- 이전 대상이 삭제·비공개·권한 상실이면 안전한 Panel Root 또는 World Context로 이동한다.
- Camera Focus는 Selection과 Authority Target을 바꾸지 않는다.

## 6. Selection과 Targeting

```text
Candidate 표시
→ 사용자 선택
→ Frozen Binding 후보
→ 비용·범위·적격성 Preview
→ Confirm Intent
→ Server 최신 Snapshot 재검증
```

- Hover, Focus, Selection과 Target을 서로 다르게 표시한다.
- 선택 대상이 여러 종류면 Type·거리·공개 상태를 함께 표시한다.
- Targeting 중 다른 Panel을 열어도 Targeting이 조용히 Commit되지 않는다.
- 최신 상태에서 부적격이 되면 `stale` 또는 `denied`로 처리하고 재선택 경로를 제공한다.
- Hidden Entity Identity를 Candidate Payload에 넣지 않는다.

## 7. Mode와 Context 가시성

사용자는 최소한 다음을 구분할 수 있어야 한다.

```text
Exploration
Encounter
Downtime
Scene Authoring
DM Observe·Player Preview
Paused·Transition·Recovery
```

표현 수단:

- 화면 Header 또는 Mode Badge
- 활성 Input Hint
- 선택 가능한 대상의 Cursor·Outline
- 위험한 Mode 전환 전 Preview

Panel이 열렸다는 이유로 Gameplay Mode가 바뀌지 않는다.

## 8. 확인 위험도

### Tier 0 — 즉시 Local

예: Panel 열기, Tab 전환, 정렬, Camera Bookmark 선택.

### Tier 1 — 되돌리기 쉬운 Authority Action

예: 일반 이동, 비파괴 상호작용. 명확한 Preview 뒤 한 번의 Confirm으로 제출한다.

### Tier 2 — 비용·상태 변경

예: 자원 소비, Item Transfer, 주문 시전. 대상·비용·예상 결과를 보여주고 E 또는 명확한 Button으로 제출한다.

### Tier 3 — 파괴·권한·Rollback

예: Character 삭제, Scene Publish, Pack 제거, 강제 종료, Rollback.

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
→ Tooltip·Details·Side Sheet

전체 기록·진단
→ Journal·Log·DM Workspace·Support Surface
```

- 초보자에게 필요한 기본 경로를 숨기지 않는다.
- 전문가용 세부 정보가 기본 행동을 밀어내지 않는다.
- 복잡한 Action은 Step을 나누되 각 Step에서 Q·E 의미를 표시한다.
- 같은 선택을 여러 Panel에서 중복 편집하지 않는다.

## 10. DM 상호작용

- DM Override는 일반 Store 수정이 아니라 명명된 Command로 실행한다.
- Player Route와 DM Override Route를 시각적으로 구분한다.
- Player View Preview는 Control Assignment를 변경하지 않는다.
- Quick Action에는 대상, 공개 범위, 현재 Revision과 결과 영향이 표시된다.
- 위험한 Override는 Mandatory Audit과 Tier 3 확인을 사용한다.
- 여러 Player 요청이 동시에 오면 우선순위·대상·만료를 보여주고 E/Q가 어느 요청에 적용되는지 명확히 한다.

## 11. Editor 상호작용

- Tool은 Selection·Placement·Snap·Preview·Inspector 공통 Host를 재사용한다.
- Tool마다 자체 입력 문법을 만들지 않는다.
- Shift는 현재 조작의 Snap 임시 해제를 의미한다.
- Ghost·Gizmo·ViewY는 Local Preview이며 Source Commit이 아니다.
- Auto Save, Compile, Publish와 Live Patch를 같은 Button 또는 상태로 합치지 않는다.
- Tool 종료 시 Connection, Ghost, Input Context와 Focus를 정리한다.

## 12. 금지 패턴

- Component의 `InputBegan` 직접 처리로 전역 키 충돌 생성
- 화면에 표시되지 않은 단축키
- Click과 E가 서로 다른 숨은 결과를 실행
- Modal 닫기만으로 Authority Prompt 완료
- Hover로 선택·카메라 이동·비밀 공개
- Drag Ghost를 실제 Item·Scene 위치로 저장
- Disabled Action을 이유 없이 표시
- 실패 후 사용자가 처음부터 모든 선택을 다시 해야 하는 구조
- 파괴 행동의 기본 Focus를 Confirm에 두는 구조
- Panel Open State를 Gameplay Mode로 사용

## 13. 구현 검수

- 현재 Context와 Q/E 의미가 보인다.
- 같은 입력이 두 Context에서 동시에 실행되지 않는다.
- Target·비용·영향을 제출 전에 확인할 수 있다.
- Server Revalidation 실패 경로가 있다.
- Cancel이 한 단계만 되돌린다.
- Keyboard·Pointer 모두 핵심 경로를 사용할 수 있다.
- 위험 행동의 확인 Tier가 적절하다.
- DM·Player Route와 공개 범위가 구분된다.
