# Main System Guide: UI, Camera와 Presentation

- Guide Status: CURRENT
- 적용 시스템 상태: GUIDE_CURRENT
- 작성일: 2026-08-05
- 마지막 권위 문서 검토일: 2026-08-05
- Completion Audit: [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)
- 대체하는 Guide: 없음
- 대체된 Guide: 없음

> 이 Guide는 기존 권위 문서를 연결하고 설명한다. 새로운 규칙·결정·API·데이터 구조를 정의하지 않는다.

## 1. 시스템 목적과 사용자 결과

이 Guide는 서버가 만든 사용자별 Projection이 Client에서 원자적으로 적용되고, ViewModel과 Panel·Component로 표시되며, 물리 입력이 Semantic Input과 UI Intent를 거쳐 Command·Read Request·Selection·Camera·Presentation Request로 전달되는 흐름을 설명한다. 또한 자유 전술 카메라, Focus·Follow·Bookmark·DM Observe와 공격·주문·주사위·상태·이동·UI 연출이 Gameplay Authority와 분리된 사용자별 Camera·Presentation Runtime에서 안전하게 실행·축약·생략·복구되는 구조를 통합한다.

사용자에게 보장하는 결과:

- UI는 Character, Item, Encounter, Effect, Scene와 Journal의 권위 원본이 아니며 사용자에게 공개된 Projection만 표시한다.
- 서버가 같은 Authority Transaction에서 확정한 HP, Resource, Condition, Turn과 Item 변경은 하나의 Projection Batch와 UI Commit으로 적용되어 부분적인 중간 상태가 노출되지 않는다.
- Client Component는 RemoteEvent, Domain Store와 Workspace Query를 직접 호출하지 않고 타입 있는 UI Intent를 제출한다.
- Command가 `committed` 결과를 반환해도 Client가 HP·Item·Turn·Resource를 직접 바꾸지 않고 관련 Projection이 적용될 때까지 Reconciliation한다.
- Character Sheet, Inventory, Journal, Settings와 DM Workspace Panel의 열림·닫힘은 Gameplay Mode와 다르다.
- Encounter, Downtime, Selection Session, Reaction, DM Approval과 Scene Transition 같은 권위 상태는 별도 Runtime이 소유하고 UI는 그 View를 투영한다.
- Authority Prompt는 Panel을 닫거나 Client Timer가 끝났다는 이유로 완료되지 않으며 Q·E·Option 응답 Command와 최신 Projection으로 종료된다.
- Q, E, 1–5와 Camera 입력은 기능별 Component가 직접 감시하지 않고 Semantic Input Router와 Input Context Stack을 통과한다.
- 같은 물리 입력은 가장 위의 유효 Context 하나만 소비하며 Text Input 중 Gameplay 단축키가 실행되지 않는다.
- Pointer Hover, Keyboard Focus, Text Focus, World Focus, Selection Focus와 Camera Focus를 서로 다른 상태로 관리한다.
- UI Layout, Dock, 탭, 정렬, UI Scale, Reduced Motion과 접근성 Preference는 Gameplay Authority와 분리해 안전하게 유지할 수 있다.
- Hover, Tooltip, Context Menu, Drag Ghost, Preview와 Animation Progress는 Ephemeral State이며 Snapshot의 권위 원본이 아니다.
- 재접속, Event Gap과 Full Resync 후 Projection Replica를 원자적으로 다시 만들고 Authority Prompt·Selection·Encounter View를 서버 상태에서 복원한다.
- Rollback과 Branch 전환 후 이전 AuthorityEpoch의 Prompt, Selection, Command, Preview, Focus Token과 Presentation ACK를 새 Branch에 재사용하지 않는다.
- Role·Control 변경 시 권한이 사라진 Panel과 Action을 새 Projection에서 제거하며 DM 데이터를 Player Client에 남긴 채 화면에서만 숨기지 않는다.
- Camera 위치, ViewY, Focus, Follow와 벽·지붕 가림 보정은 사용자별 Projection·Presentation이며 Actor 위치, Visibility, Knowledge, Selection과 RuleExecution을 변경하지 않는다.
- Selection, Spell, Dice, VFX와 Journal은 Roblox Camera를 직접 조작하지 않고 타입 있는 CameraRequest를 제출한다.
- Follow Target과 Focus Target을 분리해 장기 추적 대상을 유지하면서 현재 선택·공격·연출 대상을 화면에 최소한으로 보정할 수 있다.
- Hover만으로 Camera Focus를 바꾸거나 카메라를 이동시키지 않는다.
- Exploration에서는 Free Camera를 기본으로 하고 선택적으로 Actor Follow를 사용할 수 있다.
- Encounter에서는 Follow Actor와 Free Override를 함께 지원하며 전투 중 토큰 WASD 금지와 카메라 WASD 허용을 혼동하지 않는다.
- 높은 우선순위 CameraRequest가 끝나면 이전 Transform, Follow, Focus, ViewY와 자유 조작 상태를 복원한다.
- DM Observe와 Player View Preview는 Actor Control Assignment와 Character Ownership을 변경하지 않는다.
- Camera Target은 Workspace Instance가 아니라 Visibility·Permission 검사를 통과한 CameraTargetProjection 또는 안전한 Transform Snapshot이다.
- 공격, 주문, Roll Reveal, Damage, Condition, Interaction, Movement, Turn Change, Ping과 UI Feedback은 PresentationIntent에서 시작한다.
- PresentationRecipeSource는 Compiler를 거쳐 불변 CompiledPresentationRecipe가 되며 진행 중 Playback은 시작 시점의 Recipe Version과 Content Hash를 고정한다.
- Feature, Item, Effect, Critical과 Campaign Theme는 Recipe를 복제하지 않고 Slot 기반 PresentationAugment를 기여한다.
- Presentation Queue는 required_reveal, important, standard와 ambient 중요도, Audience, Visibility, Budget과 접근성 설정을 기준으로 재생·축약·병합·생략한다.
- Marker와 Client ACK는 공개 순서를 조정할 수 있지만 Roll·Damage·Effect와 다른 Gameplay Outcome을 결정하거나 변경하지 않는다.
- Client ACK가 없거나 VFX Module이 실패해도 Hard Timeout과 Fallback으로 권위 결과를 안전하게 공개하고 Gameplay를 재개한다.
- Presentation Module은 Camera를 직접 조작하지 않고 CameraRequest를 제출하며 Camera Policy가 허용·축약·거절한다.
- 숨은 Actor, 미식별 Item·Spell, DM Trigger와 Secret Object는 권한 없는 Audience의 UI·VFX·Floating Text·Camera Target에 포함하지 않는다.
- 저사양 Client는 Particle, Trail, Decal, Screen Effect와 Ambient 연출을 줄이되 결과 공개, 위험 Warning과 핵심 판독성을 유지한다.
- UI Panel, ViewModel, CameraRequest 또는 Presentation Module 하나의 실패가 Authority Transaction과 다른 Client Runtime으로 확산되지 않도록 Error Boundary와 Fallback으로 격리한다.
- 사용자의 Reduced Motion, Flash, Camera Shake와 기타 접근성 Hard Limit은 DM Presentation 요청보다 우선하며 Gameplay 결과를 바꾸지 않는다.

적용 범위:

- Permission-aware Projection Snapshot·Event Batch와 Client Projection Replica
- Atomic Projection Apply, Selector·ViewModel과 UI Commit
- Panel·Component Registry, Dockable Panel, HUD, Sheet, Modal, Prompt, Tooltip, Toast와 Banner
- Local Workspace State, Ephemeral Interaction State, Authority-bound UI State와 Recoverable Draft
- Semantic Input Action, Input Context Stack, Q·E·1–5와 Focus Manager
- UI Intent Registry, Command Pending, Read Request, Preview와 Projection Reconciliation
- Authority Prompt, Local Modal, Error Surface와 Notification
- Reconnect, Resync, Rollback, Scene Transition, Role·Control Change와 UI Recovery
- Localization, Accessibility, Virtualization과 UI Performance Budget
- Free Camera, Follow, Focus, Bookmark, ViewY와 Occlusion Correction
- Exploration·Encounter Camera Policy와 Free Override
- Selection Focus, Presentation Focus, DM Observe, Replay와 Scene Transition Camera
- CameraRequest Priority, Interrupt·Cancel Policy와 Restoration Stack
- PresentationRecipe Source·Compiler·Compiled Build와 Playback Instance
- PresentationIntent, Timeline Graph, Standard Slot와 Module Registry
- PresentationAugment, Profile Override, Queue, Budget, Marker와 Reveal Gate
- Audience별 Playback Plan, Visibility·Knowledge·Disclosure와 접근성
- Playback Failure, Fallback, Hot Swap, Recovery와 Rollback
- Combat HUD, Character Sheet, Common Input, Shared UI와 DM Workspace의 공통 Runtime 경계

명시적 비범위:

- Character, Item, Encounter, Effect, Scene, Journal과 Downtime의 Gameplay 규칙과 Store 내부 구현
- Capability 적격성, Command Authorization, Selection Candidate와 Frozen Binding의 서버 판정
- Visibility·Knowledge·Detection의 실제 권위 계산
- Scene Editor Source·Tool Module·Publish와 Live Patch의 저작 권위
- 각 화면의 최종 픽셀 디자인, 이미지 Asset과 모든 Animation Curve
- 실제 Roblox Module 경로와 최종 Luau Type·Command·Network Schema
- Camera 감도·줌 범위, UI 크기, Timeout, Queue와 Particle Budget의 측정 전 기본값
- Player Client에 비밀 데이터를 전달한 뒤 단순히 Visible=false로 숨기는 구조
- VFX·Camera·UI Animation을 Gameplay 결과의 권위 원본으로 사용하는 구조
- 음악, NPC 대화 시스템과 모든 규칙 효과음

## 2. 전체 구조

### UI Runtime

```text
Permission-aware Projection Snapshot·Event Batch
→ Staging Projection Replica
→ Schema·Epoch·Sequence·Integrity 검증
→ Atomic Replica Revision Commit
→ ViewModel Selector 무효화·재계산
→ Panel·Component UI Commit
→ Semantic Input
→ UI Intent
→ Command | Read | Selection | Camera | Presentation | Sync Route
```

### Camera Runtime

```text
User·Session·Selection·Presentation·DM Intent
→ CameraRequest
→ Audience·Target Projection·Priority·Motion Safety 검증
→ CameraPolicyResolver
→ CameraController
→ Local Camera Projection
→ 요청 종료 후 이전 Camera State 복원
```

### Presentation Runtime

```text
Authority Event·Projection·UI Intent
→ PresentationIntent
→ CompiledPresentationRecipe 조회
→ Audience·Visibility·Quality·Accessibility·Budget 적용
→ PlaybackPlan
→ Module Handler·Marker·CameraRequest·UI Feedback
→ Complete | Fallback | Skip | Timeout
```

### 공통 Client 경험

```text
Authority Transaction
→ Outbox·Projection Builder
→ 사용자별 Projection Batch
→ UI에서 현재 상태 표시
→ 필요한 Camera·Presentation 요청 재생
→ 사용자 의미 입력
→ 서버 Command·Read·Selection 재진입
```

UI, Camera와 Presentation은 같은 사용자 경험을 구성하지만 서로의 권위 상태를 대신 소유하지 않는다.

## 3. 주요 데이터 흐름

### 3.1 Projection Replica와 ViewModel

```text
ProjectionReplicaState
├─ projectionId·projectionEpoch·authorityEpoch
├─ baseSnapshotId·appliedViewSequence
├─ segmentRevisions
├─ session·prompt·selection·encounter View
├─ character·item·journal Public View
└─ integrityState

+ Locale·Accessibility·Layout Context
→ Derived ViewModel
→ UI Component
```

- Projection Replica는 Client Cache이며 Server Authority가 아니다.
- Raw Domain State와 다른 사용자의 Projection을 혼합하지 않는다.
- Event Gap이 있으면 Authority-bound 입력을 중지하고 Catch-up 또는 Full Resync를 요청한다.
- ViewModel은 같은 Replica Revision과 Local State Key에서 결정적으로 생성한다.
- Component가 여러 Projection Segment를 임의로 직접 조합하지 않도록 Selector가 화면용 View를 제공한다.

### 3.2 UI 상태 분류

```text
Local Workspace State
→ Dock Layout, Panel Visibility, Tabs, Sizes, Sort, UI Scale, Accessibility

Ephemeral Interaction State
→ Hover, Context Menu, Drag Ghost, Tooltip Delay, Local Animation, Unsent Filter

Authority-bound UI State
→ Prompt, Selection, Reaction, Turn, Downtime Choice, Transition View

Recoverable Draft
→ Base Public Revision과 Rebase Policy가 있는 안전한 로컬 입력
```

AuthorityEpoch 변경 시 Local Preference는 유지할 수 있지만 Authority-bound Token과 오래된 Preview는 폐기한다. Draft는 자동 제출하지 않고 최신 Projection에 Rebase 가능한지 검토한다.

### 3.3 Panel과 Component

```text
PanelDefinition
├─ allowedRoles
├─ requiredProjectionSegments
├─ requiredReadinessScopes
├─ viewModelSelector
├─ layoutCapabilities
├─ inputContexts
├─ restoration·close·errorBoundary Policy
└─ componentRoot
```

Panel 종류에는 Persistent HUD, Dockable Panel, Side Sheet, Nonblocking Overlay, Authority Prompt, Critical Modal, Tooltip, Toast, Banner와 Presentation Layer가 있다.

Component는 ViewModel 렌더링, Semantic Input 등록, UI Intent 생성, 로컬 표시 상태와 접근성 표현만 담당한다.

### 3.4 Semantic Input과 Context Stack

```text
Physical Input
→ Key Binding Profile
→ SemanticInputAction
→ Input Context Stack
→ 가장 위의 유효 Context 하나
→ UI Intent 또는 Local Action
```

우선순위:

```text
Text·Search·Numeric Input
> Critical Modal·Authority Prompt
> Drag·Selection·다단계 작업
> Focused Panel
> Base Mode HUD·DM Workspace
> Global Camera·비차단 단축키
```

Q는 가장 가까운 취소·거절·한 단계 뒤로, E는 가장 높은 우선순위의 승인·확정·실행·상호작용으로 해석한다. 1–5는 현재 Context가 의미와 Label을 화면에 공개했을 때만 활성화한다.

### 3.5 Focus

```text
Pointer Hover
Keyboard Focus
Text Input Focus
World Focus
Selection Focus
Camera Focus
```

`FocusToken`은 소유 Panel, Public Target, Context Token, 복원 Parent, Projection Epoch와 Revision을 가진다. Modal 종료 후 이전 Focus를 한 단계 복원하되 대상이 삭제·비공개·권한 상실 상태면 안전한 Panel Root 또는 World Context로 이동한다.

### 3.6 UI Intent와 Command State

```text
UI Intent
→ local_workspace | command | read_request | selection_session
  | camera_request | presentation_request | sync_control
```

Command UI 상태:

```text
local_intent_created
→ command_submitted
→ receipt_received
→ terminal_result_received
→ awaiting_projection
→ reconciled
```

거부·취소·만료·stale_epoch·resync_required는 권위 값을 되돌리는 단계가 아니라 로컬 Pending·Ghost·입력 Gate를 정리하는 상태다.

### 3.7 Authority Prompt와 Read Request

```text
AuthorityPromptView
├─ promptId·sourceExecutionRef
├─ expectedPromptRevision
├─ allowedResponses
├─ publicDeadlineView
└─ disclosureSafeDetails
```

Prompt 응답은 Command로 제출하고 최신 Revision을 재검증한다. Client Countdown은 안내용 Projection이며 만료를 확정하지 않는다.

Read Request와 Preview는 source Projection Revision과 Dependency Revision을 유지한다. 오래된 Target·Path·Tooltip 결과는 실행 근거가 아니며 Command 시 서버가 다시 검증한다.

### 3.8 Camera State와 Request

```text
CameraRequest
├─ requestKind·requesterKind
├─ audienceUserIds
├─ targetProjectionRef
├─ framingProfile
├─ priority·interruptPolicy
├─ durationPolicy·cancelPolicy
└─ revision
```

Camera Policy:

```text
free
follow_actor
selection_focus
presentation_focus
dm_observe
replay
scene_transition
restoring_previous
```

높은 우선순위 요청이 활성화되면 이전 Camera Transform, Follow, Focus, ViewY와 Free Override를 복원 스택에 보존한다.

### 3.9 Follow, Focus, Bookmark와 ViewY

```text
Follow Target
→ 장기 카메라 기준점

Focus Target
→ 현재 화면에 유지할 관심 대상
```

`CameraBookmark`는 Scene, Pivot, Orientation, Zoom, ViewY, 안전한 Follow Projection과 Label을 저장할 수 있다. 개인 Bookmark와 Preference는 사용자 상태이고 DM이 Campaign·Scene 진행용으로 저장한 Bookmark는 서버 저장 대상이 될 수 있다.

ViewY와 가림 보정은 사용자별 Presentation 상태다. 이미 Disclosure된 Presentation만 대상으로 하며 Visibility·Fog·Navigation·Collision Authority를 변경하지 않는다.

### 3.10 Presentation Source, Build와 Playback

```text
PresentationRecipeSource
→ Presentation Compiler
→ Immutable CompiledPresentationRecipe
→ PresentationPlaybackInstance
```

Compiled Recipe는 Timeline Graph, Parameter Schema, Module Binding, Marker Plan, Audience Policy, Quality Variant, Accessibility Policy, Fallback Plan과 Content Hash를 가진다.

새 Recipe Version을 활성화해도 진행 중 Playback은 시작 시 고정한 Version과 Hash를 유지한다.

### 3.11 PresentationIntent와 Timeline Slot

```text
PresentationIntent
├─ sourceExecution·sourceProjection
├─ targetProjectionRefs·worldBindings
├─ semanticTags·frozenParameters
├─ audienceBinding
├─ importance·timingPolicy
└─ revision
```

대표 Intent:

```text
attack | spell_cast | spell_impact | roll_reveal
damage_result | healing_result | condition_applied | condition_removed
interaction_transition | movement_event | turn_change | ping | ui_feedback
```

Recipe Timeline은 pre_action, source_signal, source_motion, source_release, travel, warning, impact, target_reaction, environment, camera, screen_overlay, ui_feedback와 post_action Slot을 사용한다.

### 3.12 Module Registry와 Augment

```text
PresentationModuleRegistry
→ Handler Version·Parameter Validator·Quality Variant·Fallback

PresentationAugment
→ before | after | parallel | replace | suppress
→ 대상 Slot에 Module 또는 SubRecipe 기여
```

Token Motion, Aura, Weapon Trail, Projectile, Beam, Impact, Hit Flash, Ground Decal, Floating Text, Highlight, CameraRequest, Shake, Screen Overlay, UI Pulse와 Turn Indicator는 Registry Module로 실행한다. 저장된 임의 Luau Callback이나 무제한 반복을 허용하지 않는다.

### 3.13 Queue, Marker와 Audience

```text
PresentationIntent
→ Queue Admission
→ Audience·Visibility·Budget·Accessibility 검사
→ PlaybackPlan
→ Marker·CameraRequest·UI Feedback
```

중요도:

```text
required_reveal > important > standard > ambient
```

Marker는 source_release, travel_arrival, impact_reveal, result_reveal, completion과 등록된 Custom Marker를 지원한다. Marker·ACK는 공개 시점을 연결할 뿐 결과를 재계산하지 않는다.

Audience별 Visibility가 다르면 서로 다른 PlaybackPlan을 만든다. 숨은 Anchor와 Secret Metadata를 권한 없는 Client에 전송하지 않는다.

## 4. 주요 실행 흐름

### 4.1 초기 접속과 UI 준비

```text
Protocol·Role·Projection Grant 확정
→ Projection Snapshot Segment 수신
→ Staging Replica 적용
→ Integrity·Epoch·Sequence 검증
→ Replica 원자 Commit
→ 필수 ViewModel·Panel 구성
→ Scene Essential·Gameplay Ready 확인
→ Authority-bound 입력 Gate 해제
```

장식 Asset이나 Ambient VFX가 늦는다는 이유로 Authority Replica를 손상시키지 않는다. 반대로 필요한 Projection Segment가 없으면 Skeleton·Placeholder를 표시하고 해당 입력 Scope를 닫는다.

### 4.2 Panel 열기와 닫기

```text
OpenCharacterSheet·OpenInventory·OpenJournal
→ Local Workspace Intent
→ Role·Projection Segment·Readiness 확인
→ ViewModel 연결
→ Panel Context·Focus Token 등록
```

Panel을 닫아도 연결된 Authority Prompt, Item Transfer, Selection과 Gameplay Mode가 자동 종료되지 않는다. 권위 객체를 취소하려면 별도 Command를 제출한다.

### 4.3 Q·E와 Input Context

```text
Physical Q·E
→ Semantic Cancel·Confirm·Interact
→ Top Input Context
→ Local Close 또는 Authority Response Intent
```

- Local Tooltip의 Q는 Tooltip만 닫는다.
- Reaction Prompt의 Q는 Reject Command를 제출하고 Projection 종료를 기다린다.
- Selection의 E는 ConfirmSelection Intent를 제출하고 서버 Frozen Binding을 기다린다.
- Text Input 중 Q·E는 문자 입력 Context가 소비한다.

하나의 입력이 Prompt, Selection, Scene Editor와 Camera에 동시에 전달되지 않는다.

### 4.4 Command 제출과 Projection Reconciliation

```text
Component UI Intent
→ UIIntentDispatcher
→ Command Envelope
→ Receipt·Terminal Result
→ ProjectionExpectation 대기
→ 관련 Projection Batch 적용
→ Pending UI reconciled
```

Command Result가 거부되면 권위값을 되돌리는 Client 보정을 하지 않고 Ghost·Pending 표시를 제거한다. 결과가 불명확하면 Idempotency Status 조회 또는 Resync를 사용한다.

### 4.5 Authority Prompt

```text
RuleExecution·Encounter·Downtime에서 Pending Input 생성
→ 사용자별 AuthorityPrompt Projection
→ Critical Prompt Panel·Input Context
→ Q·E·Option Response Command
→ Revision·Role·Deadline 서버 검증
→ RuleExecution 재개 또는 종료
→ Prompt Projection 제거
```

Prompt Panel 오류가 발생해도 권위 Prompt는 유지한다. 안전 Fallback UI나 Resync를 제공한다.

### 4.6 Selection·Preview와 UI

```text
Action·Spell·Interaction Intent
→ Selection Session Projection
→ Candidate·Preview ViewModel
→ Pointer·Keyboard 선택
→ E Confirm 또는 Q Cancel
→ Frozen Binding Command
→ 최신 서버 재검증
```

Preview는 권위 결과가 아니다. 오래된 Preview, Client Path와 표시된 Hit Chance를 Command 결과로 제출하지 않는다.

### 4.7 Exploration Camera

```text
Exploration Base Mode
→ free Camera Policy
→ 사용자 Pan·Rotate·Zoom·ViewY
→ 선택적 Follow Actor
→ Selection Focus는 화면 밖일 때 최소 보정
```

Token WASD와 Camera WASD는 Input Context에서 충돌하지 않게 분리한다. Hover는 카메라를 움직이지 않는다.

### 4.8 Encounter Camera

```text
Encounter active
→ follow_actor + free_override
→ 현재 제어 Actor Follow 후보
→ 사용자가 자유 카메라로 이탈 가능
→ Turn Change는 강제 점프 대신 복귀 제안 가능
→ Selection·Reaction·Roll·Spell은 CameraRequest 제출
```

전투 중 토큰 WASD 금지와 카메라 WASD 허용은 별개의 정책이다. 낮은 우선순위 Auto Focus는 사용자의 Free Override를 존중한다.

### 4.9 Selection·Journal·DM CameraRequest

```text
공개 Selection·Journal Link·DM Intent
→ 안전한 Camera Target Projection 생성
→ CameraRequest
→ Audience·Priority·Disclosure 검증
→ Focus·Observe·Bookmark 이동
```

DM Observe는 다른 사용자의 안전한 Projection을 미리보는 기능이며 Control Assignment를 변경하지 않는다. Player Focus 요청은 대상, 기간과 Q 취소 가능 여부를 명시한다.

### 4.10 Presentation 시작

```text
Authority Event 또는 UI Feedback
→ PresentationIntent
→ Recipe Version·Parameter·Audience 검증
→ Queue Admission
→ PlaybackPlan
→ Module·Marker 실행
```

Client가 임의 Recipe ID와 Parameter를 제출해 신뢰된 Module을 실행하지 못한다. 진행 중 Playback은 Hot Reload로 중간 교체하지 않는다.

### 4.11 Roll Reveal과 Marker Gate

```text
Sealed Roll Result 준비
→ roll_reveal PresentationIntent
→ required_reveal Playback
→ 최소 Dice·Result Presentation
→ result_reveal Marker 또는 Hard Timeout
→ RollRecord 공개·Execution 재개
```

3D Dice와 Animation은 서버 결과를 표현한다. Client 물리 결과나 Marker 실패가 Roll 값을 바꾸지 않는다.

### 4.12 공격·주문·상태 연출

```text
Committed Outcome·Projection
→ attack·spell·damage·condition PresentationIntent
→ Base Recipe + Item·Effect·Critical Augment
→ Source·Travel·Impact·Reaction·UI Slot
→ CameraRequest·Floating Text·VFX
```

Presentation은 이미 Commit된 결과를 설명한다. Damage VFX가 실패하거나 Skip돼도 HP, Effect와 Turn State는 유지된다.

### 4.13 Queue 혼잡과 품질 저하

```text
동시 Intent 증가 또는 Client Budget 초과
→ ambient 생략
→ 중복 Impact 병합
→ 먼 거리 연출 단순화
→ Screen Effect·Decal·Trail·Particle 감소
→ 핵심 Reveal·Warning 유지
```

Gameplay 진행을 Ambient Queue 때문에 무기한 기다리지 않는다.

### 4.14 Module 오류와 Fallback

```text
Presentation Module 오류
→ 해당 Module 중단
→ Fallback Module 또는 생략
→ Diagnostic Record
→ 나머지 Playback·Gameplay 계속
```

Recipe Compile 오류는 해당 Version을 비활성화하고 Last Known Good 또는 Safe Default Recipe를 사용한다. UI ViewModel·Panel 오류도 해당 Error Boundary에서 격리한다.

### 4.15 CameraRequest 종료와 복원

```text
Selection·Presentation·DM CameraRequest 완료·취소·Timeout
→ 현재 Request 제거
→ Restoration Stack 검증
→ 이전 Transform·Follow·Focus·ViewY 복원
→ 대상이 유효하지 않으면 안전한 Fallback Target
```

스트림 아웃되거나 권한이 사라진 대상을 이름만으로 다시 연결하지 않는다.

### 4.16 Reconnect와 Event Gap

```text
연결 이상·Projection Gap 감지
→ Authority-bound 입력 Gate 닫기
→ Pending UI Frozen 표시
→ Delta Resume 또는 Full Projection Resync
→ 새 Replica 원자 Commit
→ Prompt·Selection·Turn View 재생성
→ Local Layout·Accessibility 재결합
→ Camera Follow·Focus 안전성 확인
→ Pending Reveal 안전 공개 또는 재개
```

일반 Particle·Tween 진행률을 복원할 필요는 없다. 공개되지 않은 권위 결과는 Marker·Timeout 상태를 복구해 안전하게 공개해야 한다.

### 4.17 Rollback과 AuthorityEpoch 변경

```text
Rollback Commit
→ 새 AuthorityEpoch·Projection Epoch
→ 이전 Command·Prompt·Selection·Preview·Focus·ACK 폐기
→ 새 Projection Snapshot 원자 적용
→ Panel을 Public Stable Ref로 재결합
→ Camera Target 재검증
→ 이전 VFX 역재생 없이 현재 Branch 복원 연출
```

Local Layout, Accessibility와 안전한 Preference는 유지할 수 있다. 이전 Inventory Drag, Target Selection과 Pending Presentation을 새 Branch에 자동 적용하지 않는다.

### 4.18 Scene Transition

```text
Target Scene Projection·Essential Stage
→ Scene-bound UI를 Read-only·Placeholder·Close 처리
→ Hover·Selection·Context Menu 폐기
→ 안전한 Entry Camera Target 준비
→ Scene Transition CameraRequest
→ Target Scene Gameplay Ready
→ HUD·Input 재활성화
```

Character Sheet와 Campaign Settings 같은 Scene 독립 Panel은 Transition Policy에 따라 유지할 수 있다.

### 4.19 Role·Control 변경

```text
Role·Controller·Permission Revision 변경
→ 새 사용자별 Projection
→ 허용되지 않는 Panel·Action·Data 제거
→ Input Context·Focus 재계산
→ Hotbar·DM Workspace·Character View 재생성
```

DM Raw Projection을 Player Client Cache에 유지하지 않는다. DM이 Actor Controller가 되어 일반 행동을 수행할 때는 Player Command Route를 사용하고, Override는 별도 감사 경계를 따른다.

## 5. 문서 관계도

### Parent Authority

- [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md) — Projection·Command·Compiled Build·Failure Isolation과 Roblox Instance 권위 경계
- [`Networking Command, Event와 Client Synchronization`](../../architecture/networking-command-event-and-client-synchronization-contract.md) — Projection Snapshot·Batch, Sequence·Epoch, Command Result와 Readiness
- [`Session Play Mode, Context, Overlay와 Transition`](../../architecture/session-play-mode-context-overlay-and-transition-contract.md) — Base Mode와 Panel·Overlay·Transition의 분리, Input Gate와 Recovery
- [`Ruleset Policy Registry, Composition과 Frozen Snapshot`](../../architecture/ruleset-policy-registry-composition-and-frozen-snapshot-runtime-contract.md) — Gameplay·Disclosure·Presentation·Accessibility Policy Composition
- [`Visibility, Knowledge, Detection과 Hover Information`](../../architecture/visibility-knowledge-detection-and-hover-information-runtime-contract.md) — 사용자별 Disclosure, Hover와 안전한 Target Projection

### Child Authority

- [`UI Projection, ViewModel, Input Context와 Recovery Runtime`](../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md) — Projection Replica, Panel·Component, Input·Focus·Intent와 UI Recovery
- [`Camera Policy, Focus, Follow와 Presentation Runtime`](../../architecture/camera-policy-focus-follow-and-presentation-runtime-contract.md) — CameraRequest, Policy Priority, Target Projection과 Restoration
- [`Presentation Recipe, Playback Priority와 Extension Runtime`](../../architecture/presentation-recipe-playback-priority-and-extension-runtime-contract.md) — Intent, Compiled Recipe, Queue·Marker·Audience·Fallback
- [`공통 입력 교과서`](../../ui/common-input/common-input-grammar.md) — Q·E·1–5와 의미 입력 사용법
- [`전투 HUD와 행동 UI`](../../ui/combat-hud/baldurs-gate-style-combat-hud.md) — Encounter·Action·Prompt·Roll Projection 화면
- [`공식 2024 Character Sheet와 실시간 UI`](../../ui/character-sheet/official-2024-character-sheet-and-live-player-ui.md) — CharacterProjection과 변경 Intent 화면
- [`전투 HUD·Character Sheet 공통 UI 규격`](../../ui/shared/combat-hud-character-sheet-wireframe-and-shared-ui.md) — Layout·Layer·Safe Area·Responsive Component 규격
- [`DM Workspace와 Scene Lighting`](../../ui/dm-workspace/dm-workspace-and-scene-lighting.md) — Dock Panel, DM Surface와 Presentation·Authoring 경계
- [`DM Quick Action과 Context Command`](../../ui/dm-workspace/dm-quick-action-and-context-command.md) — DM UI Intent·Player Route·Override Command 분리
- [`자유 전술 카메라 모델`](../../systems/camera/free-tactical-camera-model.md) — PC 카메라 조작·Bookmark·DM 유도 기능 모델

### References

- [`Selection, Targeting, Preview와 Frozen Binding`](../../architecture/selection-targeting-preview-and-frozen-binding-runtime-contract.md) — Selection Session·Preview·Q/E와 Camera Focus 입력
- [`CameraRequest를 사용하는 Journal Runtime`](../../architecture/journal-document-section-anchor-permission-search-and-projection-runtime-contract.md) — 안전한 Journal Navigation과 World Focus
- [`Rule Runtime Orchestrator`](../../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md) — Authority Prompt, Roll Reveal와 Presentation Intent의 원인 실행
- [`Dice Roll, Check, Save, Attack과 Resolution Runtime`](../../architecture/dice-roll-check-save-attack-and-resolution-runtime-contract.md) — Sealed Roll·Reveal Gate·RollRecord와 Dice Presentation 경계
- [`Domain Event, Outbox, Subscription과 Projection Runtime`](../../architecture/domain-event-outbox-subscription-and-projection-runtime-contract.md) — Commit 이후 사용자별 Projection·Presentation Signal
- [`Persistence와 Session Recovery`](../../architecture/persistence-and-session-recovery-model.md) — AuthorityEpoch, Snapshot·Journal과 Client Full Resync
- [`Diagnostics와 Observability Runtime`](../../architecture/diagnostics-observability-correlated-trace-and-incident-runtime-contract.md) — UI·Camera·Presentation Trace와 Redaction
- [`Deterministic Simulation과 Test Harness`](../../architecture/deterministic-simulation-scenario-and-test-harness-runtime-contract.md) — Projection, ACK, Failure, Reconnect와 Disclosure 검증
- [`Scene Streaming, Client Interest와 Ready Activation`](../../architecture/scene-streaming-client-interest-and-ready-activation-contract.md) — UI·Camera Target·Presentation Asset Ready와 Streaming
- [`Combat와 Encounter Guide`](../combat/README.md) — Encounter Projection, Roll·Reaction·Rollback 사용자 흐름
- [`Character, Inventory와 Downtime Guide`](../character/README.md) — Character Sheet·Inventory·Downtime Projection과 Command 경계

권위 읽기 순서에서 제외:

- [`모듈형 VFX와 프레젠테이션 레시피 모델`](../../architecture/modular-vfx-and-presentation-recipe-model.md) — `SUPERSEDED`; 최신 Presentation Runtime 계약과 ADR-0075가 대체한다.
- [`주사위 굴림·연출·결과 확정 모델`](../../systems/combat/dice-roll-presentation-and-resolution-gating-model.md) — `SUPERSEDED`; 최신 Dice Runtime과 Rules Guide를 사용한다.
- [`인카운터·주도권·턴과 제어권 모델`](../../systems/combat/encounter-initiative-turn-and-control-authority-model.md) — `SUPERSEDED`; 최신 Encounter Runtime과 Combat Guide를 사용한다.

기존 UI 문서가 위 역사적 문서를 링크하더라도 대체된 문서가 현재 Authority로 되돌아오지 않는다.

## 6. 다른 시스템과의 경계

| 인접 시스템 | UI·Camera·Presentation이 제공하는 것 | 상대 시스템이 제공하는 것 | 권위 경계 문서 |
|---|---|---|---|
| Networking | Projection Replica 적용, Pending·Reconciliation UI, Sync Control | Snapshot·Batch·Sequence·Epoch, Command Receipt·Result와 Readiness | Networking 계약, UI Runtime |
| Session | Mode별 HUD 구성, Transition·Reconnect 화면, Local Panel 상태 | Base Mode·Overlay·Transition·Role·Control과 Command Gate | Session Mode 계약, UI Runtime |
| Rules·Dice | Action·Spell·Prompt·Roll View와 Intent, Reveal Presentation | Capability·RuleExecution·RollPlan·RollRecord·Outcome | Rules Guide, Dice Runtime, UI·Presentation Runtime |
| Encounter | Initiative·Turn·Opportunity·Reaction·Objective Projection | Timeline·Cursor·Opportunity·End·Rollback Authority | Encounter Runtime, Combat Guide, Combat HUD |
| Character·Inventory·Downtime | Sheet·Inventory·Activity View와 변경 Intent | Source·Build·State·Item·Activity·Completion Authority | Character Guide, Character Sheet, UI Runtime |
| Selection·Interaction | Candidate·Preview UI, Q/E·Pointer 입력, Camera Focus 요청 | Selection Session·Frozen Binding·Command Eligibility | Selection·Interaction Runtime, UI Runtime |
| Visibility·Knowledge | 공개 가능한 Hover·Tooltip·Camera Target·VFX Audience | Observer별 Disclosure와 Safe Projection | Visibility Runtime, Camera·Presentation Runtime |
| Scene·Streaming | Placeholder·Ready UI, Camera·Presentation Asset 요청 | Runtime Presence, Interest, Essential Activation과 Ready | Streaming 계약, UI·Camera Runtime |
| Journal·Ping | Panel, Search·Navigation Intent, Ping Presentation | Document·Section·Anchor·Permission Search, Ping Meaning | Journal Runtime, Presentation Runtime |
| Scene Editor | 공통 Panel·Input·Focus·Error Boundary | Authoring Source·Tool State·Publish·Live Patch Authority | UI Runtime, Scene Editor Runtime |
| Camera | CameraRequest UI, Bookmark·Follow·Focus 상태 표시 | Camera Policy·Target Projection·Controller와 복원 스택 | Camera Runtime |
| Presentation | Playback Layer, Skip·Quality·Accessibility Control | Recipe·Intent·Queue·Marker·Module·Fallback | Presentation Runtime |
| Diagnostics | 사용자 오류 Surface와 Support Reference | Trace·Incident·Redaction·Budget·Telemetry | Diagnostics Runtime, UI Runtime |
| Persistence·Recovery | Local Preference·Draft 재결합과 Client Resync | Authority Snapshot·Journal·Branch·Epoch | Persistence 계약, UI Runtime |

고정 경계:

- UI Component는 Domain Store와 Remote를 직접 호출하지 않는다.
- Camera CFrame과 ViewY는 Gameplay Query의 입력이 아니다.
- Presentation Playback 결과는 Authority Mutation Provider가 아니다.
- Gameplay Domain은 Client Panel 상태, Camera Position과 VFX 완료 여부를 권위 판단에 사용하지 않는다.
- Visibility Runtime이 공개하지 않은 Entity를 Tooltip, Camera Target, VFX Anchor와 Error Message로 누출하지 않는다.
- UI·Camera·Presentation 실패로 이미 Commit된 Gameplay Transaction을 Rollback하지 않는다.

## 7. 추천 읽기 순서

1. [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md)
   - Projection, Command, Compiled Build와 Client Instance의 공통 권위 원칙을 먼저 확인한다.
2. [`Networking Command, Event와 Client Synchronization`](../../architecture/networking-command-event-and-client-synchronization-contract.md)
   - Client가 어떤 Snapshot·Batch·Command Result를 받는지 이해한다.
3. [`Session Play Mode, Context, Overlay와 Transition`](../../architecture/session-play-mode-context-overlay-and-transition-contract.md)
   - Panel·Prompt·Presentation과 Gameplay Mode를 분리한다.
4. [`ADR-0083`](../../decisions/ADR-0083-projection-driven-ui-runtime-and-epoch-safe-client-recovery.md), [`ADR-0074`](../../decisions/ADR-0074-projection-only-camera-policies-with-separate-focus-and-follow.md), [`ADR-0075`](../../decisions/ADR-0075-versioned-data-driven-and-fault-isolated-presentation-runtime.md)
   - UI, Camera와 Presentation의 핵심 결정을 확인한다.
5. [`UI Runtime`](../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md)
   - Replica·ViewModel·Panel·Input·Intent·Recovery 전체 흐름을 읽는다.
6. [`Camera Runtime`](../../architecture/camera-policy-focus-follow-and-presentation-runtime-contract.md)
   - CameraRequest·Focus·Follow·Audience·복원 경계를 읽는다.
7. [`Presentation Runtime`](../../architecture/presentation-recipe-playback-priority-and-extension-runtime-contract.md)
   - Intent·Recipe·Queue·Marker·Audience·Fallback을 읽는다.
8. [`공통 입력 교과서`](../../ui/common-input/common-input-grammar.md)
   - Q·E·1–5와 물리 키·의미 입력의 사용자 규칙을 확인한다.
9. 구현 대상 화면 문서
   - Combat HUD, Character Sheet, Shared UI, DM Workspace 또는 Scene Editor UI를 선택한다.
10. 해당 Gameplay Domain의 Guide·Architecture
    - 화면이 투영하고 Intent를 보내는 실제 권위 시스템을 읽는다.
11. [`Diagnostics Runtime`](../../architecture/diagnostics-observability-correlated-trace-and-incident-runtime-contract.md)과 [`Simulation Runtime`](../../architecture/deterministic-simulation-scenario-and-test-harness-runtime-contract.md)
    - 오류 격리, 성능, 정보 누출과 Recovery 검증 기준을 확인한다.
12. [`Completion Audit`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)
    - 현재 범위의 Architecture·Guide 준비 판정을 확인한다.

## 8. 구현·검증 순서

권위 문서에서 확정된 UI 기반 순서:

```text
ProjectionReplicaStore·Atomic Apply
→ ViewModel Selector Registry
→ Semantic Input Router·Input Context Stack
→ Focus Manager·Panel Registry
→ UI Intent Dispatcher·Command Reconciliation
→ Prompt·Modal·Notification Foundation
→ Reconnect·Resync·Rollback Recovery Coordinator
→ Layout·Preference·Recoverable Draft Persistence
→ Combat HUD Vertical Slice
→ Character Sheet·Inventory·DM Workspace Vertical Slice
```

Camera 의존 순서:

```text
Safe CameraTargetProjection
→ CameraRequest Registry·Validation
→ Policy Priority·Interrupt·Cancel·Restoration Stack
→ Free·Follow·Focus Controller
→ ViewY·Occlusion·Bookmark
→ Selection·Presentation·DM Observe Bridge
→ Streaming·Scene Transition·Reconnect·Rollback Recovery
```

Presentation 의존 순서:

```text
Recipe Source Schema·Compiler·Version Registry
→ PresentationIntent·Audience Validation
→ Module Registry·Trusted Handler
→ Timeline Graph·Slot·Augment
→ Queue·Budget·Quality·Accessibility Policy
→ Marker·Reveal Gate·CameraRequest Bridge
→ Fallback·Timeout·Failure Isolation
→ Hot Swap·Recovery·Diagnostics
```

UI·Camera·Presentation을 함께 검증하는 수직 Slice:

```text
Combat Turn Projection
→ Hotbar Action Intent
→ Selection Session·Camera Focus
→ RuleExecution·Roll
→ required_reveal Dice Presentation
→ Outcome Projection Batch
→ Damage·Condition UI Commit
→ Playback Failure Fallback
→ Reconnect·Rollback Full Resync
```

현재 존재하는 Specs:

- [`Implementation Specs Index`](../../specs/README.md)

UI·Camera·Presentation 전용 Implementation Specs는 Main System Guide 단계 이후 작성한다.

필수 검증 Scenario:

- 같은 Transaction의 HP·Resource·Condition·Turn Projection 원자 적용
- Projection Event Gap과 Last Known Good Replica 유지
- Command Result와 Projection 도착 순서 역전 Reconciliation
- Authority Prompt Revision 충돌과 최신 Prompt 재표시
- Text Input·Prompt·Selection·Panel·Camera Context의 Q/E 단일 소비
- Panel 오류와 다른 HUD·Gameplay Input의 격리
- DM 데이터, Hidden Actor, Secret Anchor와 Error Message Negative Disclosure
- Role Change 후 DM Panel·Cache·Focus·Action 제거
- Reconnect 중 Prompt·Selection·Pending Command 복구
- Rollback 이전 Epoch Command·Prompt·Preview·Focus·ACK 차단
- Exploration Free Camera와 Actor Follow 전환
- Encounter Free Override가 Auto Focus보다 우선하는지 검증
- Follow·Focus Target Stream Out과 안전한 Fallback
- DM Observe가 Control Assignment를 바꾸지 않는지 검증
- Presentation Recipe Version Hot Swap 중 진행 Playback 안정성
- Module 오류·Recipe Compile 오류와 Last Known Good Fallback
- required_reveal Marker ACK 유실과 Hard Timeout
- Low-end Budget Degradation 후 Reveal·Warning 판독성
- Reduced Motion·Flash·Shake Hard Limit 준수
- Audience별 PlaybackPlan과 Hidden VFX Anchor 누출 방지
- Scene Transition 중 Projection·Camera Target·Presentation Ready Gate
- UI·Camera·Presentation Failure가 Gameplay Transaction을 Rollback하지 않는지 검증

## 9. 변경 영향 지도

| 변경 유형 | 영향받는 권위 문서 | 영향받는 Specs | Guide 조치 |
|---|---|---|---|
| Projection Replica·Batch·Epoch 구조 | Networking, UI Runtime, Persistence | 향후 UI Replica·Sync Specs | `UPDATE_REQUIRED` |
| ViewModel·Panel·Component Registry | UI Runtime, Shared UI, 화면별 UI 문서 | 향후 UI Foundation Specs | `UPDATE_REQUIRED` |
| Input Context·Q/E·Focus 의미 | UI Runtime, Selection, Common Input, Scene Editor | 향후 Input·Focus Specs | `UPDATE_REQUIRED` |
| Command Pending·Reconciliation | Networking, UI Runtime, Domain Command 계약 | 향후 UI Intent·Command Specs | `UPDATE_REQUIRED` |
| Prompt·Read Request·Draft Recovery | UI Runtime, Rule Orchestrator, Persistence | 향후 Prompt·Draft·Recovery Specs | `UPDATE_REQUIRED` |
| CameraRequest·Priority·Target Projection | Camera Runtime, Visibility, Selection, Streaming | 향후 Camera Specs | `UPDATE_REQUIRED` |
| Follow·Focus·ViewY·Bookmark 정책 | Camera Runtime, Free Camera Model, Journal | 향후 Camera Controller Specs | `UPDATE_REQUIRED` |
| Presentation Recipe·Module·Augment | Presentation Runtime, Extension 계약, Rules·Effect | 향후 Presentation Compiler·Registry Specs | `UPDATE_REQUIRED` |
| Queue·Marker·Reveal Gate·ACK | Presentation Runtime, Dice Runtime, Networking | 향후 Playback·Marker Specs | `UPDATE_REQUIRED` |
| Audience·Disclosure·Accessibility | Visibility, UI, Camera, Presentation Policy | 향후 Projection·Audience Specs | `UPDATE_REQUIRED` |
| Reconnect·Rollback·Role Change | UI Runtime, Camera Runtime, Presentation Runtime, Persistence | 향후 Client Recovery Specs | `UPDATE_REQUIRED` |
| UI Layout·Camera 감도·Particle Budget·Timeout 수치 | 각 Runtime의 `READY_WITH_DEFAULTS` 항목 | 해당 Performance·Accessibility Specs | 의미 변화가 있을 때만 갱신 |
| 화면별 Wireframe 변경 | Combat HUD, Character Sheet, Shared UI, DM Workspace | 해당 Vertical Slice UI Specs | 공통 흐름이 바뀔 때 갱신 |
| ADR 대체·문서 Lifecycle 변경 | 해당 ADR, Lifecycle 정책, Audit | 모든 영향 Spec | `UPDATE_REQUIRED` |

## 10. Authority Documents

### Product

- [`핵심 세션 흐름과 플레이 모드`](../../product/core-session-loop.md)
- [`플랫폼, 이동과 입력 범위`](../../product/platform-movement-and-input-scope.md)
- [`콘텐츠 자동화, Rollback, 저장과 비목표`](../../product/content-automation-rollback-storage-and-exclusions.md)

### Architecture

- [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md)
- [`Networking Command, Event와 Client Synchronization`](../../architecture/networking-command-event-and-client-synchronization-contract.md)
- [`Session Play Mode, Context, Overlay와 Transition`](../../architecture/session-play-mode-context-overlay-and-transition-contract.md)
- [`Ruleset Policy Registry, Composition과 Frozen Snapshot`](../../architecture/ruleset-policy-registry-composition-and-frozen-snapshot-runtime-contract.md)
- [`UI Projection, ViewModel, Input Context와 Recovery Runtime`](../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md)
- [`Camera Policy, Focus, Follow와 Presentation Runtime`](../../architecture/camera-policy-focus-follow-and-presentation-runtime-contract.md)
- [`Presentation Recipe, Playback Priority와 Extension Runtime`](../../architecture/presentation-recipe-playback-priority-and-extension-runtime-contract.md)
- [`Selection, Targeting, Preview와 Frozen Binding`](../../architecture/selection-targeting-preview-and-frozen-binding-runtime-contract.md)
- [`Visibility, Knowledge, Detection과 Hover Information`](../../architecture/visibility-knowledge-detection-and-hover-information-runtime-contract.md)
- [`Scene Streaming, Client Interest와 Ready Activation`](../../architecture/scene-streaming-client-interest-and-ready-activation-contract.md)
- [`Dice Roll, Check, Save, Attack과 Resolution Runtime`](../../architecture/dice-roll-check-save-attack-and-resolution-runtime-contract.md)
- [`Rule Runtime Orchestrator와 Pending Execution`](../../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md)
- [`Domain Event, Outbox, Subscription과 Projection Runtime`](../../architecture/domain-event-outbox-subscription-and-projection-runtime-contract.md)
- [`Persistence와 Session Recovery`](../../architecture/persistence-and-session-recovery-model.md)
- [`Journal Document, Section, Anchor, Permission, Search와 Projection`](../../architecture/journal-document-section-anchor-permission-search-and-projection-runtime-contract.md)
- [`Diagnostics, Observability, Correlated Trace와 Incident Runtime`](../../architecture/diagnostics-observability-correlated-trace-and-incident-runtime-contract.md)
- [`Deterministic Simulation, Scenario와 Test Harness Runtime`](../../architecture/deterministic-simulation-scenario-and-test-harness-runtime-contract.md)

### Systems·UI

- [`UI 문서 허브`](../../ui/README.md)
- [`Common Input UI`](../../ui/common-input/README.md)
- [`공통 입력 교과서`](../../ui/common-input/common-input-grammar.md)
- [`Combat HUD UI`](../../ui/combat-hud/README.md)
- [`Baldur's Gate 3형 전투 HUD와 행동 UI`](../../ui/combat-hud/baldurs-gate-style-combat-hud.md)
- [`Character Sheet UI`](../../ui/character-sheet/README.md)
- [`공식 2024 Character Sheet와 실시간 UI`](../../ui/character-sheet/official-2024-character-sheet-and-live-player-ui.md)
- [`Shared UI`](../../ui/shared/README.md)
- [`전투 HUD·Character Sheet 와이어프레임과 공통 UI 규격`](../../ui/shared/combat-hud-character-sheet-wireframe-and-shared-ui.md)
- [`DM Workspace UI`](../../ui/dm-workspace/README.md)
- [`DM Workspace와 Scene Lighting`](../../ui/dm-workspace/dm-workspace-and-scene-lighting.md)
- [`DM Quick Action과 Context Command`](../../ui/dm-workspace/dm-quick-action-and-context-command.md)
- [`Scene Editor UI`](../../ui/scene-editor/README.md)
- [`Camera 시스템`](../../systems/camera/README.md)
- [`자유 전술 카메라 모델`](../../systems/camera/free-tactical-camera-model.md)

### Specs

- [`Implementation Specs Index`](../../specs/README.md)
- UI·Camera·Presentation 전용 Specs: Main System Guide 단계 이후 작성 예정

### Audits

- [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)

## 11. ADR References

- [`ADR-0004`](../../decisions/ADR-0004-baldurs-gate-style-session-interaction.md) — BG3형 세션 상호작용과 화면 경험
- [`ADR-0039`](../../decisions/ADR-0039-baldurs-gate-style-combat-hud-and-contextual-action-ui.md) — Combat HUD와 Contextual Action UI
- [`ADR-0040`](../../decisions/ADR-0040-official-2024-character-sheet-and-live-player-view.md) — 공식 2024 정보 구조의 Character Sheet
- [`ADR-0041`](../../decisions/ADR-0041-shared-combat-hud-character-sheet-layout-and-ui-layering.md) — HUD·Sheet 공통 Layout과 Layer
- [`ADR-0045`](../../decisions/ADR-0045-dm-workspace-and-scene-lighting-authoring.md) — DM Workspace와 Scene Lighting Surface
- [`ADR-0046`](../../decisions/ADR-0046-modular-presentation-recipes-and-extension-contracts.md) — Modular Presentation Recipe 기반
- [`ADR-0050`](../../decisions/ADR-0050-free-tactical-camera-and-presentation-priority.md) — Free Tactical Camera와 Presentation Priority
- [`ADR-0053`](../../decisions/ADR-0053-step-level-automation-and-standard-recipe-step-library.md) — 신뢰된 Handler·등록 기반 Step 실행 원칙
- [`ADR-0059`](../../decisions/ADR-0059-versioned-command-protocol-and-projection-stream-synchronization.md) — Versioned Command와 Projection Sync
- [`ADR-0069`](../../decisions/ADR-0069-authoritative-roll-records-and-presentation-gated-resolution.md) — RollRecord와 Presentation Reveal Gate
- [`ADR-0070`](../../decisions/ADR-0070-orthogonal-session-modes-contexts-overlays-and-transitions.md) — Mode·Context·Overlay·Transition 분리
- [`ADR-0071`](../../decisions/ADR-0071-input-context-selection-sessions-and-frozen-bindings.md) — Input Context와 Selection Session
- [`ADR-0073`](../../decisions/ADR-0073-observer-relative-visibility-knowledge-and-hover-projections.md) — Observer-relative Projection과 Hover Disclosure
- [`ADR-0074`](../../decisions/ADR-0074-projection-only-camera-policies-with-separate-focus-and-follow.md) — Projection-only Camera와 Focus·Follow 분리
- [`ADR-0075`](../../decisions/ADR-0075-versioned-data-driven-and-fault-isolated-presentation-runtime.md) — Versioned Data-driven Presentation과 Failure Isolation
- [`ADR-0083`](../../decisions/ADR-0083-projection-driven-ui-runtime-and-epoch-safe-client-recovery.md) — Projection-driven UI와 Epoch-safe Recovery
- [`ADR-0084`](../../decisions/ADR-0084-correlated-authority-traces-and-permission-aware-observability.md) — UI·Camera·Presentation Trace와 Permission-aware Diagnostics
- [`ADR-0085`](../../decisions/ADR-0085-production-parity-deterministic-scenarios-and-controlled-nondeterminism.md) — Production-parity Client·ACK·Failure Scenario 검증

## 12. 알려진 비목표와 측정형 기본값

권위 문서에서 확정된 비목표:

- UI를 Gameplay Authority Store로 사용하지 않는다.
- Raw Server State나 DM Projection을 Player Client에 전달한 뒤 화면에서 숨기지 않는다.
- UI Component가 RemoteEvent·Domain Service·Workspace Query를 직접 호출하지 않는다.
- Command Result만으로 Client 권위 값을 수정하지 않는다.
- Projection Event Batch를 부분 적용하지 않는다.
- Panel 열림 상태를 Gameplay Mode 또는 Authority Overlay로 사용하지 않는다.
- Component가 Q·E·숫자 키를 직접 감시하지 않는다.
- Client Timer가 Reaction·Turn·Rest·Prompt 만료를 확정하지 않는다.
- 표시 이름으로 Rollback·Reconnect 후 Entity를 자동 재연결하지 않는다.
- Camera CFrame, ViewY와 Occlusion Presentation을 Gameplay Authority 입력으로 사용하지 않는다.
- Hover만으로 CameraRequest를 만들지 않는다.
- DM Observe를 Actor Control 이전으로 사용하지 않는다.
- Presentation Module과 VFX 완료 여부가 Roll·Damage·Effect·Movement를 결정하지 않는다.
- Workspace 전체를 검색해 숨은 Camera·VFX Anchor를 찾지 않는다.
- 진행 중 Playback의 Recipe Version을 Hot Reload로 교체하지 않는다.
- DM 요청이 User Accessibility Hard Limit을 무시하지 않는다.
- UI·Camera·Presentation 오류로 Gameplay Transaction을 Rollback하지 않는다.
- 음악과 모든 규칙 효과음을 이 Runtime 범위에 포함하지 않는다.

Implementation Spec에서 측정·확정할 기본값:

- 동시 Panel·Modal·Tooltip·Toast·Banner 수와 ViewModel Memory Budget
- Projection Batch UI Commit 목표 시간과 저사양 Fallback
- Dock Layout·탭·Scroll·Draft 보존 기간
- Pending·Retry·Timeout 표시 시간과 Notification 축약 규칙
- Focus 복원 Fallback과 접근성 안내 문구
- Camera Pan·Rotation·Zoom 감도와 제한 범위
- Selection Focus Margin과 Camera Collision 여유·복구 속도
- Bookmark 개수와 기본 단축키
- Presentation Queue 동시 실행 상한
- Quality별 Particle·Decal·Light Budget
- Camera Shake·Flash·Motion Safety 기본값
- Marker ACK Timeout과 최대 연출 지연
- Recipe Hot Reload 보존 Version 수
- UI·Camera·Presentation 전용 Implementation Spec 파일과 최종 Module·Type 배치

남은 비차단 작업:

- UI·Camera·Presentation Implementation Specs 작성
- Combat HUD·Character Sheet·Inventory·DM Workspace 수직 Slice 구현 명세
- Scene Editor UI와 Authoring Guide의 별도 통합
- Journal·Ping Guide에서 Search·Navigation·Ping Presentation 세부 연결
- Performance·Accessibility 플레이테스트와 Budget 확정
- Deterministic Client·Virtual User·ACK·Failure CI Scenario 구현

## 13. Guide 검증 체크리스트

- [x] 모든 핵심 문장이 Authority Document에 근거한다.
- [x] 새로운 제품 규칙이나 Architecture 결정을 추가하지 않았다.
- [x] 모든 링크가 존재한다.
- [x] Parent·Children·References를 구분했다.
- [x] 최신 ADR과 현재 존재하는 Specs를 반영했다.
- [x] `SUPERSEDED`, `DISCONTINUED`, `ARCHIVED` 문서를 권위 읽기 순서에서 제외했다.
- [x] UI, Camera와 Presentation의 권위 경계를 분리했다.
- [x] Reconnect·Rollback·Role Change의 Epoch-safe 복구 흐름을 반영했다.
- [x] Disclosure·Accessibility·Failure Isolation 기준을 반영했다.
- [x] 변경 영향 지도가 최신이다.
- [x] Guide Status가 실제 상태와 일치한다.
