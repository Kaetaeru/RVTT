# UI Projection, ViewModel, Input Context와 Recovery Runtime 계약

- 상태: 확정
- 문서 종류: Architecture
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 남은 기본값:
  - 단일 Client의 동시 Panel·Modal·Tooltip 수와 ViewModel 메모리 상한
  - Projection Batch 적용 후 UI Commit 목표 시간과 저사양 Fallback 기준
  - 사용자별 Dock Layout·최근 탭·스크롤 위치 보존 기간
  - Command Pending·Retry·Timeout의 기본 표시 시간
  - Focus 복원 실패 시 기본 대상과 접근성 안내 문구
  - 재접속 후 복원할 안전한 Draft 종류와 Draft 만료 기간
  - Toast·Banner·Error Surface의 동시 표시 상한과 축약 규칙
- 작성일: 2026-08-04
- 관련 ADR:
  - [`ADR-0039`](../decisions/ADR-0039-baldurs-gate-style-combat-hud-and-contextual-action-ui.md)
  - [`ADR-0040`](../decisions/ADR-0040-official-2024-character-sheet-and-live-player-view.md)
  - [`ADR-0045`](../decisions/ADR-0045-dm-workspace-and-scene-lighting-authoring.md)
  - [`ADR-0059`](../decisions/ADR-0059-versioned-command-protocol-and-projection-stream-synchronization.md)
  - [`ADR-0070`](../decisions/ADR-0070-orthogonal-session-modes-contexts-overlays-and-transitions.md)
  - [`ADR-0071`](../decisions/ADR-0071-input-context-selection-sessions-and-frozen-bindings.md)
  - [`ADR-0074`](../decisions/ADR-0074-projection-only-camera-policies-with-separate-focus-and-follow.md)
  - [`ADR-0075`](../decisions/ADR-0075-versioned-data-driven-and-fault-isolated-presentation-runtime.md)
  - [`ADR-0081`](../decisions/ADR-0081-versioned-policy-composition-and-frozen-ruleset-snapshots.md)
  - [`ADR-0083`](../decisions/ADR-0083-projection-driven-ui-runtime-and-epoch-safe-client-recovery.md)
- 상위 문서:
  - [`Runtime Architecture Principles`](runtime-architecture-principles.md)
  - [`Networking Command, Event와 Client Synchronization 계약`](networking-command-event-and-client-synchronization-contract.md)
  - [`Session Play Mode, Context, Overlay와 Transition 계약`](session-play-mode-context-overlay-and-transition-contract.md)
  - [`Ruleset Policy Registry, Composition과 Frozen Snapshot Runtime 계약`](ruleset-policy-registry-composition-and-frozen-snapshot-runtime-contract.md)
- 관련 Runtime:
  - [`Selection Runtime 계약`](selection-targeting-preview-and-frozen-binding-runtime-contract.md)
  - [`Visibility, Knowledge와 Detection Runtime 계약`](visibility-knowledge-detection-and-hover-information-runtime-contract.md)
  - [`Camera Runtime 계약`](camera-policy-focus-follow-and-presentation-runtime-contract.md)
  - [`Presentation Runtime 계약`](presentation-recipe-playback-priority-and-extension-runtime-contract.md)
  - [`Persistence와 Session Recovery 모델`](persistence-and-session-recovery-model.md)
- 관련 UI 문서:
  - [`공통 입력 교과서`](../ui/common-input/common-input-grammar.md)
  - [`전투 HUD와 행동 UI`](../ui/combat-hud/baldurs-gate-style-combat-hud.md)
  - [`공식 2024 캐릭터 시트`](../ui/character-sheet/official-2024-character-sheet-and-live-player-ui.md)
  - [`DM 작업공간`](../ui/dm-workspace/dm-workspace-and-scene-lighting.md)

## 1. 목적

이 문서는 Combat HUD, Character Sheet, Inventory, Journal, DM Workspace, Scene Editor, Prompt, Tooltip과 설정 화면이 공유하는 Client UI Runtime 계약을 정의한다.

기본 흐름:

```text
Permission-aware Projection Snapshot·Event Batch
→ Atomic Projection Replica Commit
→ Derived ViewModel
→ UI Component Tree
→ Semantic Input Action
→ UI Intent
→ Command·Read Request·Selection·Camera·Presentation Request
```

핵심 원칙:

```text
UI는 권위 상태의 원본이 아니다.
UI는 자신에게 공개된 Projection을 표시하고 Intent를 제출한다.
```

```text
화면이 열려 있는가
≠ Gameplay Mode
≠ 권위 Overlay가 존재하는가
```

Character Sheet, Inventory, Journal과 Settings는 Client 화면 상태다. Encounter, Downtime, Selection Session, Prompt와 DM Approval은 각 Runtime의 권위 상태이며 UI는 이를 투영한다.

## 2. 사용자 결과

이 계약은 다음 경험을 보장한다.

- 같은 권위 Transaction의 HP, 자원, 상태와 Turn 변경이 UI에서 부분적으로 보이지 않는다.
- 버튼을 눌렀다는 이유만으로 Client가 HP, Inventory와 행동 횟수를 먼저 확정하지 않는다.
- 연결이 끊겼다가 돌아와도 열린 Reaction·Prompt·Selection이 서버 상태를 기준으로 다시 나타난다.
- Rollback 후 이전 Timeline의 버튼, Prompt와 Pending Command를 누를 수 없다.
- DM 전용 정보와 미발견 대상은 Client에 전달되지 않으며 UI에서 숨기는 방식에 의존하지 않는다.
- Q와 E가 동시에 여러 Panel이나 World Interaction을 실행하지 않는다.
- 텍스트 입력 중 Gameplay 단축키가 오작동하지 않는다.
- Panel 하나가 오류를 일으켜도 Gameplay Projection과 다른 UI가 가능한 범위에서 유지된다.
- 화면 배치와 접근성 설정은 재접속·Rollback 후에도 안전하게 유지된다.
- 저사양 Client에서도 대규모 Initiative·Inventory·Journal 목록을 점진적으로 표시할 수 있다.

## 3. 책임 경계

### 3.1 UI Runtime이 소유한다

- Client-safe Projection Replica의 원자적 적용
- Projection에서 파생되는 ViewModel과 Selector
- Panel·Modal·Tooltip·Toast·Banner의 Client 수명주기
- Semantic Input Context Stack과 입력 Capture
- Keyboard·Text·Pointer Focus 조정과 복원
- UI Intent Registry와 Command·Read Request 제출 Adapter
- Pending Command·Read·Prompt 표시 상태와 Reconciliation
- 사용자별 Layout, Dock, 탭, 정렬, 배율과 접근성 UI 상태
- 재접속·Resync·Rollback 시 Client UI 폐기·복원 순서
- Component Error Boundary와 안전한 Fallback
- UI 성능 Budget, Virtualization과 진단 Hook

### 3.2 UI Runtime이 소유하지 않는다

- Actor, Character, Item, Encounter, Effect와 Journal의 권위 상태
- Capability 적격성, Action Economy와 Command Authorization
- Visibility, Knowledge와 Disclosure 결정
- Selection Candidate와 Frozen Selection Binding의 권위
- Camera의 최종 정책과 Presentation Playback
- 네트워크 Projection 생성과 Snapshot Segment 공개 정책
- Gameplay Mode, Context, Overlay와 Transition State
- Rollback Branch와 AuthorityEpoch 결정

UI는 허용 여부를 설명하는 View를 표시할 수 있지만 최종 검증은 서버 Command와 Domain Runtime이 담당한다.

## 4. UI 데이터 계층

UI에서 사용하는 데이터를 다음 계층으로 분리한다.

### 4.1 Projection Replica

서버가 사용자별로 만든 Client-safe 권위 View다.

```text
ProjectionReplicaState
├─ projectionId
├─ projectionEpoch
├─ authorityEpoch
├─ baseSnapshotId
├─ appliedViewSequence
├─ segmentRevisions
├─ publicEntityViews
├─ sessionView
├─ promptViews
├─ selectionViews
├─ encounterViews
├─ characterViews
├─ journalSummaryViews
└─ integrityState
```

규칙:

- Snapshot과 Event Batch를 원자 단위로 적용한다.
- Batch 일부만 적용한 상태로 Component를 갱신하지 않는다.
- Raw Domain State나 다른 사용자의 Projection을 혼합하지 않는다.
- Projection Gap이 있으면 Authority-bound 입력을 중지한다.
- Replica는 Client Cache일 뿐 서버 권위 원본이 아니다.

### 4.2 Derived ViewModel

Projection Replica와 로컬 표시 설정으로부터 결정적으로 계산되는 읽기 전용 View다.

```text
Projection Replica
+ Locale
+ UI Scale·Accessibility Profile
+ Local Layout Context
→ Derived ViewModel
```

예:

- CombatHudViewModel
- CharacterSheetViewModel
- InventoryPanelViewModel
- PromptViewModel
- DMWorkspaceViewModel
- TooltipViewModel

ViewModel은 Store를 수정하지 않으며 Component가 서버 상태를 직접 조합하지 않게 한다.

### 4.3 Local Workspace State

Gameplay Authority와 무관한 사용자별 UI 상태다.

```text
LocalWorkspaceState
├─ dockLayout
├─ panelVisibility
├─ selectedTabs
├─ panelSizes
├─ listSortPreferences
├─ safeScrollAnchors
├─ uiScale
├─ reducedMotionPreference
├─ colorAndContrastPreference
└─ keyBindingProfileRef
```

Rollback과 AuthorityEpoch 변경 후에도 유지할 수 있다. 단, 권한이 사라진 Panel과 공개되지 않는 Entity를 강제로 다시 열지 않는다.

### 4.4 Ephemeral Interaction State

현재 Client 상호작용을 위한 일시 상태다.

```text
hover
context_menu
pointer_capture
drag_ghost
unconfirmed_range_preview
tooltip_delay
local_animation_progress
unsent_filter_text
```

Projection Epoch 변경, Resync와 관련 Scope 종료 시 폐기할 수 있다. 이를 Gameplay 저장 데이터로 승격하지 않는다.

### 4.5 Authority-bound UI State

UI가 보여 주지만 권위 원본은 다른 Runtime에 있는 상태다.

```text
PromptView
SelectionSessionView
ReactionOfferView
EncounterTurnView
DowntimeChoiceView
SceneTransitionView
CommandAuthorizationView
```

Client가 Panel을 닫아도 해당 권위 객체가 완료된 것으로 처리하지 않는다. 응답이 필요하면 명시적 Command를 제출한다.

### 4.6 Recoverable Draft

텍스트·설정·Authoring 입력 중 안전하게 복구 가능한 Draft는 별도 타입으로 관리한다.

```text
RecoverableDraft
├─ draftId
├─ draftKind
├─ basePublicRevision
├─ scopeRef
├─ localPayload
├─ rebasePolicy
├─ expiresAt
└─ sensitivityClass
```

권위 변경 후 자동 제출하지 않는다. 최신 Projection에 Rebase 가능한지 확인하고 사용자에게 복원 후보로 보여준다.

## 5. Projection 적용과 UI Commit

```text
Snapshot Segment 또는 AuthorityEventBatch 수신
→ Schema·Epoch·Sequence 검증
→ Staging Replica에 전체 적용
→ Integrity 검증
→ Replica Revision 원자 교체
→ 영향 Selector 무효화
→ ViewModel 재계산
→ 하나의 UI Commit으로 렌더
```

다음을 금지한다.

- Batch의 HP 변경을 먼저 그리고 Condition 변경을 다음 Frame에 적용
- Component마다 Projection Event를 독립 소비
- 수신 순서대로 임의 Store를 직접 변경
- Event Gap 상태에서 최신 Batch만 적용

Projection 적용이 실패하면 Last Known Good Replica를 유지하고 Sync Control을 요청한다.

## 6. ViewModel과 Selector

```text
ViewModelSelector
├─ selectorId
├─ inputProjectionKeys[]
├─ localStateKeys[]
├─ outputSchemaVersion
├─ memoizationPolicy
├─ permissionAssumption
└─ fallbackPolicy
```

규칙:

- 같은 Replica Revision과 Local State Key는 같은 ViewModel을 만든다.
- UI가 볼 수 없는 정보를 추론하기 위한 Selector를 만들지 않는다.
- 전체 Replica를 매 Frame 순회하지 않고 Dependency Key로 갱신한다.
- 큰 목록은 안정적 Public ID와 Revision으로 증분 갱신한다.
- ViewModel 오류는 해당 Panel의 Fallback으로 격리한다.

## 7. Panel과 Component Registry

### 7.1 Panel Definition

```text
PanelDefinition
├─ panelTypeId
├─ panelSchemaVersion
├─ allowedRoles[]
├─ requiredProjectionSegments[]
├─ requiredReadinessScopes[]
├─ viewModelSelectorId
├─ layoutCapabilities
├─ inputContextDefinitions[]
├─ restorationPolicy
├─ closePolicy
├─ errorBoundaryPolicy
└─ componentRootId
```

Panel 종류:

```text
persistent_hud
dockable_panel
side_sheet
nonblocking_overlay
authority_prompt
critical_modal
tooltip
toast
banner
presentation_layer
```

### 7.2 Component 경계

Component는 다음만 수행한다.

- ViewModel 렌더링
- Semantic Input Action 등록
- UI Intent 생성
- 로컬 표시 상태 변경
- 접근성·로케일 표현

Component가 RemoteEvent, Domain Service, Workspace Query와 권위 Store를 직접 호출하지 않는다.

### 7.3 Panel과 Gameplay Mode 분리

Panel 열기·닫기는 기본적으로 Local Workspace State 변경이다.

```text
Character Sheet 열기
→ Encounter 종료 아님

Inventory Panel 닫기
→ Item Transfer 취소 아님

DM Workspace Tab 전환
→ Session Base Mode 변경 아님
```

권위 Overlay가 필요하면 해당 Runtime이 Overlay Binding을 만들고 Projection으로 전달한다.

## 8. Input Context Stack

물리 키는 `SemanticInputAction`으로 변환된 뒤 Context Stack에서 처리한다.

기본 우선순위:

```text
1. Text·Search·Numeric Input Context
2. Critical Modal과 권위 Prompt Context
3. 진행 중 Drag·Selection·다단계 작업 Context
4. Focused Panel Context
5. Base Mode HUD·DM Workspace Context
6. Global Camera와 비차단 단축키 Context
```

규칙:

- 가장 위의 유효 Context 하나만 입력을 소비한다.
- 소비된 입력은 아래 Context로 전달하지 않는다.
- Component가 Q, E와 숫자 키를 직접 감시하지 않는다.
- Context 등록과 해제는 안정적 Context Token을 사용한다.
- Panel이 파괴되거나 Scope가 종료되면 소유 Context를 반드시 해제한다.
- Projection Epoch 변경 시 Authority-bound Context Token을 무효화한다.

## 9. Q, E와 주요 의미 입력

```text
Q
→ 가장 가까운 취소·거절·한 단계 뒤로

E
→ 가장 높은 우선순위의 승인·확정·실행·상호작용
```

Q 한 번은 상태 하나만 닫거나 이전 단계로 이동한다.

예:

```text
Reaction Prompt에서 Q
→ RejectReaction Command
→ Prompt Projection이 종료될 때 UI 닫힘

로컬 Tooltip에서 Q
→ Tooltip만 닫힘

Selection 중 E
→ ConfirmSelection Intent
→ 서버 Frozen Binding 검증

탐험 중 Focus 대상에서 E
→ Interact Intent
```

Prompt가 권위 객체라면 Client가 Q/E 입력 직후 로컬에서 완료 상태로 확정하지 않는다. Pending 표시 후 Command Result와 Projection을 기다린다.

`1–5` 슬롯은 현재 Context가 공개한 의미와 Label이 화면에 보일 때만 활성화한다.

## 10. Focus 모델

다음을 분리한다.

```text
Pointer Hover
Keyboard Focus
Text Input Focus
World Focus
Selection Focus
Camera Focus
```

`FocusManager`는 다음 정보를 가진다.

```text
FocusToken
├─ focusKind
├─ ownerPanelId?
├─ publicTargetRef?
├─ contextToken
├─ restoreParentToken?
├─ projectionEpoch
└─ revision
```

규칙:

- Modal을 닫으면 열기 전 Focus로 한 단계 복원한다.
- 복원 대상이 삭제·비공개·권한 상실 상태면 안전한 Panel Root로 이동한다.
- Text Focus가 활성일 때 Q/E/숫자 Gameplay 입력을 가로채지 않는다.
- Hover를 Keyboard Focus나 Action Target으로 자동 확정하지 않는다.
- Rollback 이전 Epoch의 Focus Target을 새 Entity에 재사용하지 않는다.

## 11. UI Intent Registry

UI는 의미 있는 Intent만 제출한다.

```text
UIIntentDefinition
├─ intentTypeId
├─ intentSchemaVersion
├─ sourcePanelTypes[]
├─ requiredReadinessScopes[]
├─ targetRoute
├─ commandOrReadTypeId?
├─ localOnlyHandlerId?
├─ confirmationPolicy
├─ idempotencyPolicy?
└─ auditTag
```

`targetRoute`:

```text
local_workspace
command
read_request
selection_session
camera_request
presentation_request
sync_control
```

예:

```text
OpenCharacterSheet
→ local_workspace

RequestCharacterDetails
→ read_request

EndTurn
→ command

BeginSpellTargeting
→ selection_session

FocusActor
→ camera_request
```

UI Intent Handler가 Gameplay 결과를 직접 계산하지 않는다.

## 12. Command Pending과 Reconciliation

UI는 Command 제출 상태와 Projection 적용 상태를 분리한다.

```text
local_intent_created
→ command_submitted
→ receipt_received
→ terminal_result_received
→ awaiting_projection
→ reconciled
```

실패 상태:

```text
rejected
cancelled
expired
stale_epoch
resync_required
```

규칙:

- `committed` Result를 받았다고 Client Store를 직접 수정하지 않는다.
- `projectionExpectation` 또는 관련 Transaction Projection이 적용된 뒤 `reconciled`로 처리한다.
- Projection이 먼저 도착할 수도 있으므로 `transactionId`, `serverCommandId`와 Public Revision Token으로 결합한다.
- Timeout 재전송은 같은 Idempotency Key를 사용한다.
- 거부되면 권위 값은 되돌리지 않고 로컬 Ghost·Pending 표시만 제거한다.
- Pending 중 버튼 중복 입력 정책은 Command Definition과 UI Intent Definition이 함께 결정한다.

## 13. Read Request와 Preview

Read Request는 취소 가능한 조회다.

```text
ReadRequest UI State
├─ requestId
├─ cancellationKey
├─ sourceProjectionRef
├─ dependencyRevisions[]
├─ status
└─ resultView?
```

- 최신 입력이 이전 Preview를 대체하면 이전 요청을 취소하거나 결과를 폐기한다.
- 결과가 오래된 Projection Revision에 묶였으면 `stale`로 표시하고 실행 근거로 사용하지 않는다.
- Target·Path Preview 결과는 Command 제출 시 서버가 다시 검증한다.
- 실패를 빈 목록이나 0%로 위장하지 않는다.

## 14. Authority Prompt와 Modal

### Authority Prompt

Reaction, DM Approval, Downtime Choice, Roll Reveal처럼 서버 Runtime에 존재하는 Pending Input이다.

```text
AuthorityPromptView
├─ promptId
├─ sourceExecutionRef
├─ expectedPromptRevision
├─ allowedResponses[]
├─ publicDeadlineView?
├─ defaultPolicyView?
└─ disclosureSafeDetails
```

- 닫기 버튼만으로 권위 Prompt를 취소하지 않는다.
- Q/E 또는 Option 선택은 `RespondToPrompt Command`를 제출한다.
- 이전 Revision 응답은 거부하고 최신 Prompt를 다시 표시한다.
- Deadline 표시는 서버 기준 Deadline의 투영이며 Client Timer가 만료 결과를 확정하지 않는다.

### Local Modal

설정 확인, 로컬 경고와 Panel 내 선택처럼 Client에서만 존재한다.

- Gameplay Store를 변경하지 않는다.
- Modal 종료가 Command Commit으로 오인되지 않는다.
- 위험한 Command는 Local Confirmation 후 별도 Command를 제출한다.

## 15. Error Surface와 Notification

```text
ErrorSurface
├─ field_error
├─ inline_status
├─ panel_banner
├─ global_banner
├─ toast
├─ blocking_recovery
└─ diagnostics_reference
```

구조화된 Server Error의 `userMessageKey`, `retryable`, `resyncRequired`, `fieldErrors`를 사용한다.

- Raw Stack Trace와 내부 ID를 일반 사용자에게 표시하지 않는다.
- 재시도 가능한 오류와 사용자 수정이 필요한 오류를 구분한다.
- 동일 오류를 무한 Toast로 반복하지 않는다.
- 비밀 정보가 Error Message를 통해 누출되지 않게 Projection·Disclosure 정책을 따른다.

## 16. Reconnect와 Projection Resync

```text
연결 이상 또는 Event Gap 감지
→ Authority-bound Input Gate 닫기
→ Pending UI를 frozen 상태로 표시
→ Delta Resume 또는 Full Projection Resync
→ Snapshot 원자 적용
→ ViewModel 재구성
→ Authority Prompt·Selection·Encounter View 재생성
→ 안전한 Local Workspace State 재결합
→ Focus 복원
→ Readiness Scope별 입력 재활성화
```

### 유지

- UI Scale과 접근성 설정
- Dock Layout과 Panel Size
- 안전한 탭·정렬 Preference
- Rebase 가능한 Recoverable Draft

### 폐기 또는 재생성

- Hover와 Tooltip
- Context Menu
- Drag Ghost
- 오래된 Preview Result
- 이전 Projection Epoch의 Prompt Context
- 이전 Selection Session Draft
- 처리 여부가 확인되지 않은 로컬 권위 추정값

Authority Prompt와 Selection은 Client 메모리가 아니라 새 Projection에서 복원한다.

## 17. Rollback과 AuthorityEpoch 변경

Rollback Commit 또는 Branch 전환 시:

```text
AuthorityEpoch 변경 감지
→ 이전 Epoch Command·Prompt·Selection·Prediction 차단
→ Authority-bound Context와 Focus Token 폐기
→ Pending Command 상태를 stale_epoch로 종료
→ 새 Projection Snapshot 원자 적용
→ Panel을 Public Stable Ref 기준으로 재결합
→ 유효하지 않은 대상 Panel은 안전하게 닫거나 Empty State 표시
→ 사용자 Layout·Accessibility 유지
```

다음을 금지한다.

- 이전 Epoch의 Prompt 응답 재전송
- 같은 표시 이름을 보고 새 Entity에 오래된 선택을 자동 연결
- Rollback 전 Inventory Drag를 새 Snapshot에 자동 적용
- 이전 Client Prediction을 새 Authority 위치에 합성

## 18. Scene Transition과 Role 변경

### Scene Transition

- Target Scene의 필수 Projection과 Presentation Ready 전에는 관련 Gameplay UI를 활성화하지 않는다.
- Source Scene Panel은 Transition Policy에 따라 Read-only, Placeholder 또는 Close 상태가 된다.
- Scene에 묶인 Hover·Selection·Context Menu를 폐기한다.
- Character Sheet와 Campaign Settings처럼 Scene 독립 Panel은 유지할 수 있다.

### Role·Control 변경

- Player, DM, Observer와 Controller 변경은 Projection Epoch 또는 Permission Revision으로 반영한다.
- 권한이 사라진 Panel과 Action은 즉시 비활성화하되 숨은 데이터 Cache를 유지하지 않는다.
- DM Panel을 단순히 화면에서 숨기는 방식으로 Player Client에 Raw DM Projection을 남기지 않는다.
- Control Assignment 변경 후 Hotbar와 Action Offer는 새 Projection에서 다시 만든다.

## 19. Presentation Runtime과의 경계

```text
UI State
≠ Presentation Playback State
```

UI Runtime은 Panel, 입력, ViewModel과 권위 상태 표시를 관리한다.

Presentation Runtime은 다음을 관리한다.

- UI Pulse
- Floating Text
- Roll Reveal Layer
- Camera·Screen Effect
- Transition Animation

Presentation 실패로 Panel의 권위 상태가 사라지지 않는다. Animation을 Skip해도 Prompt, Turn과 Command 결과는 유지된다.

접근성 설정은 Presentation Policy를 제한할 수 있지만 Gameplay 결과를 바꾸지 않는다.

## 20. Security와 Disclosure

- UI는 자신에게 전달된 Projection과 권한 적용 Read Result만 사용한다.
- Raw Domain Event를 받은 뒤 Client에서 숨기지 않는다.
- Tooltip, Search, Context Menu와 Error도 Disclosure 대상이다.
- 비공개 Entity의 이름·ID·목록 길이·정렬 위치를 Side Channel로 노출하지 않는다.
- Disabled 버튼 이유도 공개 가능한 범위에서만 제공한다.
- DM Debug UI는 DM Projection과 별도 Permission을 요구한다.
- Client 로그와 Crash Report에 비밀 Payload를 무제한 기록하지 않는다.

## 21. Localization과 Accessibility

UI 문자열은 Localization Key와 변수로 구성한다.

```text
localizedTextKey
arguments
numberFormatter
unitFormatter
inputBindingLabel
```

접근성 지원:

- UI Scale과 최소 글자 크기
- Keyboard Focus와 Focus Indicator
- 색상 외 상태 표현
- Reduced Motion·Flash·Camera Shake 제한
- 긴 Tooltip의 고정 보기
- 입력 재설정과 Semantic Action Label
- Screen Reader를 고려한 의미 순서 확장 가능 구조

접근성 Preference가 Gameplay Authority나 Disclosure를 우회하지 않는다.

## 22. 성능과 대규모 목록

- ViewModel Selector는 Dependency Key로 증분 갱신한다.
- Initiative, Inventory, Journal, Asset 목록은 Virtualization을 사용한다.
- 모든 Panel이 매 Frame 전체 Projection을 순회하지 않는다.
- Hover Tooltip은 필요한 상세 정보만 지연 조회한다.
- 선택적 Snapshot Segment가 없으면 Skeleton·Placeholder를 표시하고 권위 입력은 Readiness Gate를 따른다.
- UI Update Budget을 넘으면 장식·Animation을 줄이되 권위 상태 갱신을 우선한다.
- Layout Thrashing과 반복 Text Measurement를 측정한다.

## 23. Client Service 경계

```text
UIRuntime
├─ ProjectionReplicaStore
├─ ProjectionApplyCoordinator
├─ ViewModelSelectorRegistry
├─ PanelRegistry
├─ ComponentRegistry
├─ LocalWorkspaceStateStore
├─ RecoverableDraftStore
├─ SemanticInputRouter
├─ InputContextStack
├─ FocusManager
├─ UIIntentRegistry
├─ UIIntentDispatcher
├─ CommandStateTracker
├─ ReadRequestManager
├─ PromptViewCoordinator
├─ UIRecoveryCoordinator
├─ NotificationService
├─ LocalizationAdapter
├─ AccessibilityAdapter
└─ UIDiagnosticsAdapter
```

### ProjectionReplicaStore

Client-safe Projection만 보존한다. Raw Domain State와 다른 사용자의 View를 저장하지 않는다.

### ProjectionApplyCoordinator

Snapshot·Batch를 원자 적용하고 ViewModel 갱신 경계를 만든다.

### UIIntentDispatcher

Intent를 올바른 Command·Read·Selection·Camera Route로 전달한다. Domain 결과를 직접 계산하지 않는다.

### UIRecoveryCoordinator

Reconnect, Event Gap, Role Change, Scene Transition과 Rollback에서 UI State 분류별 유지·폐기·복원을 조정한다.

## 24. 저장과 Cache

서버 Gameplay Snapshot에 저장하지 않는 값:

- Panel 위치와 크기
- Tooltip 표시 여부
- Hover와 Context Menu
- 로컬 Animation Progress
- 개인 정렬·필터 Preference

사용자 Preference 저장 후보:

- UI Scale
- 접근성 설정
- Key Binding Profile
- DM Workspace Layout
- 최근 사용한 안전한 Panel Layout

Projection Replica와 ViewModel Cache는 재생성 가능하다. Cache 유실은 권위 상태 유실이 아니다.

Draft를 저장할 때는 민감도, Scope, Base Revision과 만료 정책을 명시한다.

## 25. 실패와 안전 상태

### Panel Component 오류

- 해당 Panel Error Boundary에서 격리
- 최소 Fallback과 재시도 제공
- Projection Replica는 유지
- 다른 Panel과 Gameplay Command Ingress는 영향 범위에 따라 유지

### Projection Apply 오류

- Last Known Good Replica 유지
- Authority-bound 입력 중지
- Catch-up 또는 Full Resync 요청

### ViewModel 오류

- 해당 Selector 결과 폐기
- 안전한 Empty·Error View 표시
- Raw Projection을 Component에 직접 전달하지 않음

### Focus 손실

- 안전한 Panel Root 또는 World Input Context로 이동
- 동일 입력을 다른 Context에 재전달하지 않음

### Command 결과 불명

- Idempotency Status 조회
- 관련 입력 중복 제출 제한
- Projection Reconciliation 또는 Resync

## 26. 금지 사항

- UI Component에서 RemoteEvent 직접 호출
- UI가 Character·Encounter·Inventory Store를 직접 수정
- Raw Server State를 받아 Client에서 비밀 정보 숨김
- Command Result만 보고 권위 값 직접 변경
- Projection Event Batch 일부 적용
- Panel 열림 상태를 Gameplay Mode로 사용
- Component별 Q/E 키 감시
- Text Input 중 Gameplay 입력 동시 실행
- 권위 Prompt를 로컬 Close만으로 완료 처리
- Rollback 이전 Prompt·Selection·Command Token 재사용
- Client Timer로 Reaction·Turn·Rest 만료 확정
- 표시 이름으로 Entity를 재연결
- UI 오류 때문에 Gameplay Transaction Rollback
- Presentation Animation 완료를 UI 권위 상태의 원본으로 사용

## 27. 구현 명세 분할

권장 구현 순서:

```text
1. ProjectionReplicaStore와 Atomic Apply
2. ViewModel Selector Registry
3. Semantic Input Router와 Input Context Stack
4. Focus Manager와 Panel Registry
5. UI Intent Dispatcher와 Command State Reconciliation
6. Prompt·Modal·Notification Foundation
7. Reconnect·Resync·Rollback Recovery Coordinator
8. Layout·Preference·Draft Persistence
9. Combat HUD 수직 Slice
10. Character Sheet·Inventory·DM Workspace 수직 Slice
```

## 28. Guide 상태

```text
Guide Status: NOT_READY
```

UI Runtime 상위 계약은 완료됐다. Diagnostics, Simulation, Journal 공유 계약과 Cross-System Completion Audit가 끝난 뒤 UI Main System Guide를 작성한다.
