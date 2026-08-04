# Selection, Targeting, Preview와 Frozen Binding Runtime 계약

- 상태: 확정
- 문서 종류: Architecture
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 남은 기본값:
  - Candidate 탐색 반경과 화면 가중치
  - 후보 전환 기본 키 바인딩
  - Preview 갱신 주기와 대규모 후보 축약 기준
  - Selection Session timeout
  - Candidate Grouping 임계값
- 작성일: 2026-08-04
- 관련 ADR:
  - [`ADR-0023`](../decisions/ADR-0023-composable-targeting-and-spatial-query-model.md)
  - [`ADR-0055`](../decisions/ADR-0055-snapshot-bound-typed-spatial-query-and-navigation-boundary.md)
  - [`ADR-0067`](../decisions/ADR-0067-2024-core-actions-as-registered-action-capabilities.md)
  - [`ADR-0068`](../decisions/ADR-0068-2024-spell-casts-as-route-bound-pending-rule-executions.md)
  - [`ADR-0070`](../decisions/ADR-0070-orthogonal-session-modes-contexts-overlays-and-transitions.md)
  - [`ADR-0071`](../decisions/ADR-0071-input-context-selection-sessions-and-frozen-bindings.md)
- 상위 문서:
  - [`Session Play Mode, Context, Overlay와 Transition 계약`](session-play-mode-context-overlay-and-transition-contract.md)
  - [`Spatial Query Engine과 Provider 계약`](spatial-query-engine-and-provider-contract.md)
  - [`Rule Runtime Orchestrator와 Pending Execution 계약`](rule-runtime-orchestrator-and-pending-execution-contract.md)
  - [`공통 입력 교과서`](../ui/common-input/common-input-grammar.md)

## 1. 목적

이 문서는 탐험, Encounter, 주문, 공격, 아이템, 상호작용, DM 도구와 Scene Authoring에서 공통으로 사용하는 선택·대상 지정 계약을 정의한다.

핵심 흐름:

```text
Physical Input
→ Semantic Input Action
→ Input Context
→ Intent
→ Selection Session
→ Preview
→ Server Validation
→ Frozen Selection Binding
→ Command
→ RuleExecution
```

Selection은 무엇이 선택되었는지만 다루며, 이동·공격·상호작용을 직접 실행하지 않는다.

## 2. 전역 Q/E 계약

Q와 E는 Selection Navigation 키가 아니다.

```text
Q
→ Universal Back / Cancel / Reject

E
→ Universal Confirm / Approve / Execute / Interact
```

입력 문맥 스택에서 가장 위의 활성 문맥 하나만 Q 또는 E를 소비한다.

예시:

```text
주문 대상 지정 중 Q
→ 현재 Selection Step 취소
→ 주문 선택 단계로 복귀

열린 인벤토리에서 Q
→ 인벤토리 Overlay 닫기

DM 승인 요청에서 Q
→ 요청 거절

DM 승인 요청에서 E
→ 요청 승인

대상과 조건이 완성된 행동에서 E
→ Frozen Selection 생성과 실행 요청

탐험 중 상호작용 대상에 초점이 있을 때 E
→ Interact Command 요청
```

Q 한 번으로 여러 Overlay나 Selection Step을 연속 종료하지 않는다.

유효한 Q/E 동작이 없으면 아무 작업도 하지 않는다.

후보 순환은 `CycleCandidateNext`, `CycleCandidatePrevious`라는 별도 의미 입력으로 정의하며 Q/E에 바인딩하지 않는다. 기본 물리 키는 구현 명세 또는 사용자 키 설정에서 결정한다.

## 3. Input Context와 Intent

물리 키를 기능 코드가 직접 감시하지 않는다.

```text
InputContext
├─ contextId
├─ ownerRole
├─ baseModeRequirement
├─ overlayRequirement
├─ semanticActions[]
├─ priority
├─ capturePolicy
└─ revision
```

주요 Intent:

```text
inspect
interact
move
attack
cast_spell
use_item
select_option
select_area
select_path
ping
measure
dm_author
journal_link
quick_action
```

같은 문을 클릭해도 Intent에 따라 `열기`, `조사`, `공격`, `Journal Link Target`이 달라질 수 있다.

## 4. Selection Plan

Capability는 실행 전에 필요한 선택 단계를 `CompiledSelectionPlan`으로 제공한다.

```text
CompiledSelectionPlan
├─ selectionPlanId
├─ steps[]
├─ contextPolicy
├─ confirmationPolicy
├─ cancellationPolicy
├─ finalValidationPolicy
├─ freezePolicy
└─ projectionPolicy
```

Selection Step 종류:

```text
actor
runtime_object
item_presence
point
direction
path
area
surface
volume
option
number_input
text_input
execution_reference
```

## 5. Selection Session

```text
SelectionSession
├─ selectionSessionId
├─ sourceIntentId
├─ sourceCapabilityId?
├─ sourceExecutionId?
├─ controllerId
├─ baseMode
├─ contextSnapshot
├─ currentStepIndex
├─ draftBindings[]
├─ candidateState
├─ reservationId?
├─ state
└─ revision
```

상태:

```text
idle
collecting
awaiting_confirmation
frozen
submitted
cancelled
expired
invalidated
```

Selection Session은 `selection` Overlay를 사용하지만 Base Play Mode를 바꾸지 않는다.

## 6. Exploration과 Encounter 구분

같은 Selection Runtime을 사용하되 Context Policy가 다르다.

### Exploration

- 실시간 위치와 상호작용 후보를 지속 갱신할 수 있다.
- 클릭 이동과 WASD 이동 중 Inspection Selection을 허용할 수 있다.
- 문, 레버, 상자, Item Presence, 공개 Actor와 Point가 주 후보가 된다.
- E는 현재 초점 후보의 Interact 또는 완성된 선택의 Confirm으로 사용한다.
- Q는 열린 Overlay, 현재 작업 또는 Selection Step 하나를 뒤로 보낸다.

### Encounter

- 행동 Capability와 Action Opportunity가 Selection 진입을 허용해야 한다.
- 이동은 Path Preview와 Movement Budget 검증을 사용한다.
- 공격·주문·아이템 대상은 Turn, Reaction, Range와 Visibility를 재검증한다.
- Targeting 중 WASD 토큰 이동은 허용하지 않는다.
- E는 행동 실행 승인, Reaction 수락 또는 DM 승인에 사용될 수 있다.
- Q는 대상 지정 취소, Reaction 거절 또는 한 단계 복귀에 사용된다.

## 7. Candidate 생성

Selection Runtime은 Workspace를 직접 순회하지 않는다.

```text
Pointer / Focus Ray / Navigation Input
→ Spatial Query
→ Visibility Projection Filter
→ Candidate Set
→ Selection Policy
```

Candidate:

```text
SelectionCandidate
├─ binding
├─ candidateType
├─ publicMetadata
├─ eligibilityState
├─ distance
├─ screenPosition
├─ directionFromFocus
├─ reachabilitySummary
├─ visibilitySummary
├─ priorityContributions[]
└─ revisionSet
```

## 8. Hover, Focus, Selection과 Target 분리

```text
Hover
≠ Keyboard Focus
≠ Persistent Selection
≠ Action Target
```

- Hover: 포인터가 가리키는 일시적 후보
- Focus: 키보드·게임패드 탐색의 현재 후보
- Selection: Inspection이나 다중 선택에 보존된 Binding
- Target: 특정 Capability 실행에 제출될 후보

마우스 이동은 Hover를 갱신하고, 별도의 Candidate Cycle 입력은 Focus를 갱신한다. Q/E는 이 순환에 사용하지 않는다.

## 9. Candidate Navigation

후보 탐색은 Stack이 아니라 정책화된 Candidate Graph 또는 정렬 목록을 사용할 수 있다.

```text
CycleCandidateNext
CycleCandidatePrevious
NavigateCandidateLeft
NavigateCandidateRight
NavigateCandidateUp
NavigateCandidateDown
```

초기 PC 키보드·마우스 범위에서는 최소 `Next/Previous` 의미 입력만 구현해도 된다.

후보 탐색은 현재 Intent와 Context Filter를 통과한 후보만 포함한다.

예시:

```text
attack
→ 유효 공격 대상만

interact
→ 상호작용 가능한 Object와 Item Presence만

dm_author
→ 공개·숨김 Runtime Object, Gizmo, Trigger와 Volume
```

## 10. Preview

Preview는 권위 결과가 아니다.

```text
Selection Draft
+ Client-safe Spatial Snapshot
→ Preview Projection
```

Preview 예시:

- Highlight와 Outline
- Range와 Reachability
- Path와 이동 비용
- Sphere, Cone, Cube, Cylinder, Line, Emanation
- 예상 대상 집합
- 엄폐·시야·효과선 경고
- Action·Resource 비용

Preview Mesh와 Highlight는 저장하지 않는다.

## 11. Frozen Selection Binding

실행은 Client Preview를 직접 사용하지 않는다.

```text
Selection Draft
→ 최신 서버 Snapshot 재검증
→ FrozenSelectionBinding
→ RuleExecution
```

```text
FrozenSelectionBinding
├─ bindingId
├─ selectionPlanId
├─ stepBindings[]
├─ sourceExecutionId
├─ sceneId
├─ rulesetSnapshot
├─ revisionSet
├─ spatialSnapshotId
├─ visibilitySnapshotId
├─ frozenAtLogicalTime
└─ validationRecord
```

Capability별 Freeze Policy:

```text
freeze_on_declaration
revalidate_before_roll
revalidate_before_commit
recompute_area_on_trigger
track_bound_entity
```

## 12. Selection Reservation과 취소

Targeting이 실행 자원이나 Action Opportunity와 결합되면 Reservation을 가질 수 있다.

Q 취소 시:

```text
현재 Selection Step 취소
→ 필요하면 이전 Step으로 복귀
→ 최상위 Step이면 Selection Session 종료
→ 아직 Commit되지 않은 Reservation 해제
```

이미 공개·확정된 Roll이나 Commit을 Q로 되돌릴 수 없다. 해당 경우 DM Rollback이나 별도 취소 규칙을 사용한다.

## 13. 역할 경계

### PLAYER_ONLY

- 제어 중인 Actor의 공개 Capability Targeting
- 공개 Actor·Object·Point·Area 선택
- 자신의 Selection Session 취소와 확정
- 공개 후보 Inspection

### DM_ONLY

- 숨겨진 Actor·Object·Trigger·Volume 선택
- Scene Authoring 다중 선택
- Journal Link Target 작성
- 대상 적격성·공개 범위 Override
- 강제 Selection 생성과 수정
- DM 승인 요청에 E 승인, Q 거절

### SHARED

- 공개 정보 Inspection
- 공개 Point·Area Preview 확인
- Ping과 Measurement

### SYSTEM_ONLY

- Candidate Spatial Query
- Visibility Filter
- Candidate Grouping
- 서버 최종 검증
- Frozen Binding 생성
- Revision 재검증
- Projection 필터링

## 14. DM 승인 문맥

DM 승인 요청은 Selection 후보보다 높은 Input Context 우선순위를 가진다.

```text
E
→ 현재 승인 요청 승인

Q
→ 현재 승인 요청 거절
```

DM이 Scene Authoring 중이더라도 승인 문맥이 활성화되면 E/Q는 먼저 승인 요청에 적용되고, 편집 작업은 유지된다.

서버는 DM 역할, 요청 Revision과 요청 상태를 검증한다.

## 15. 열린 창과 Universal Back

Character Sheet, Inventory, Journal, Inspection Panel과 기타 Overlay는 닫기 동작을 Input Context Stack에 등록한다.

Q는 가장 위의 닫을 수 있는 상태 하나만 닫는다.

우선순위 예시:

```text
Text Input Escape
→ Modal Reject
→ Active Selection Step Cancel
→ Top Overlay Close
→ Tool Submode Exit
→ no-op
```

파괴적 변경이나 저장되지 않은 Authoring Draft가 있으면 단순 닫기 대신 확인 문맥을 열 수 있다.

## 16. 저장·복구·롤백

일반 Hover와 Inspection Selection은 영구 저장하지 않는다.

다음은 Pending RuleExecution 복구에 필요할 때 저장할 수 있다.

- Selection Session 식별자
- 완료된 Step Binding
- 현재 Step
- Reservation 참조
- Confirmation 대기 상태
- Frozen Binding
- Revision과 Build Reference

재접속 시 Pending Selection은 현재 권위 Snapshot에서 재검증하고, 유효하지 않으면 안전하게 취소한다.

전투 롤백은 권위 상태를 복원하지만 단순 UI Hover History를 복원할 의무는 없다.

## 17. 금지 사항

- Q/E를 Candidate 순환에 사용하지 않는다.
- Client Preview를 권위 Target으로 사용하지 않는다.
- Workspace Instance를 권위 Binding으로 저장하지 않는다.
- 숨겨진 Candidate를 플레이어 Client에 전송하지 않는다.
- Selection Runtime이 공격·이동·상호작용 상태를 직접 변경하지 않는다.
- DM 전용 Journal Link와 Hidden Selection을 플레이어 Context에 노출하지 않는다.
