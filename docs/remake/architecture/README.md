# Architecture 문서

여러 기능이 공유하는 권위, 데이터와 실행 계약을 정의한다.

## 최상위 권위 문서

- [`Runtime Architecture Principles`](runtime-architecture-principles.md)
- [`Compiled Build와 Authoritative State 분리 패턴`](compiled-build-and-authoritative-state-pattern.md)
- [`Session Play Mode, Context, Overlay와 Transition 계약`](session-play-mode-context-overlay-and-transition-contract.md)
  - Exploration·Encounter·Downtime Base Play Mode
  - Stealth·Travel·Hazard 등의 겹칠 수 있는 Context
  - Selection·DM Authoring·Pause·Presentation·Rollback Review Overlay
  - Scene Transition·Join·Reconnect·Recovery·Build Migration Gate
  - Role·Mode·Overlay·Transition을 결합한 Effective Command Policy
- [`Selection, Targeting, Preview와 Frozen Binding Runtime 계약`](selection-targeting-preview-and-frozen-binding-runtime-contract.md)
  - Input Context와 Intent에서 Selection Session으로 이어지는 공통 입력 경계
  - Exploration과 Encounter의 서로 다른 Selection Policy
  - Spatial Query 기반 Candidate, Hover·Focus·Selection·Target 분리
  - Client Preview와 서버 FrozenSelectionBinding 분리
  - Q Universal Back·Reject와 E Universal Confirm·Approve 계약
  - DM Hidden Selection·Journal Link·Authoring 권한 경계
- [`Interaction Capability, Contextual Command와 Adjudication 계약`](interaction-capability-contextual-command-and-adjudication-contract.md)
  - 행위자·대상·아이템·효과가 기여하는 Interaction Capability Query
  - Exploration 실시간 상호작용과 Encounter Action Economy 결합
  - E 기본 상호작용, Q 취소·거절과 DM 승인 문맥
  - Player Command와 DM Override의 분리
  - 문·상자·아이템·함정·환경 행동의 RuleExecution·Transaction 경계
- [`Visibility, Knowledge, Detection과 Hover Information Runtime 계약`](visibility-knowledge-detection-and-hover-information-runtime-contract.md)
  - Visible·Detected·Known·Disclosed의 독립 권위 상태
  - Observer별 Sense·Stealth·Search·Knowledge Relation
  - Fog 지형 공개와 Actor·Secret Detection의 분리
  - Player·DM·Observer 정보 Projection과 Knowledge Scope
  - Hover Information Projection과 비밀 HP·AC·Identity 차단
- [`Camera Policy, Focus, Follow와 Presentation Runtime 계약`](camera-policy-focus-follow-and-presentation-runtime-contract.md)
  - Gameplay Authority와 사용자별 Camera Projection 분리
  - CameraRequest 우선순위와 이전 상태 복원
  - Follow Target과 Focus Target의 독립 관리
  - Exploration Free Camera와 Encounter Follow + Free Override
  - DM Observe, Bookmark, Replay, Rollback과 Scene Transition
- [`Scene Compiler와 Compiled Runtime Scene 계약`](scene-compiler-and-compiled-runtime-scene-contract.md)
- [`Character Runtime과 Compiled Character Build 계약`](character-runtime-and-compiled-character-build-contract.md)
- [`Character Action Opportunity와 2024 Core Action Runtime 계약`](character-action-opportunity-and-2024-core-action-runtime-contract.md)
- [`Spell Casting Route와 2024 Spell Runtime 계약`](spell-casting-route-and-2024-spell-runtime-contract.md)
- [`Dice Roll, Check, Save, Attack과 Resolution Runtime 계약`](dice-roll-check-save-attack-and-resolution-runtime-contract.md)
- [`Effect, Condition과 Ongoing Runtime 계약`](effect-condition-and-ongoing-runtime-contract.md)
- [`Inventory, ItemInstance와 World Presence Runtime 계약`](inventory-item-instance-and-world-presence-runtime-contract.md)
- [`Runtime Object System과 Entity Lifecycle 계약`](runtime-object-system-and-entity-lifecycle-contract.md)
- [`Networking Command, Event와 Client Synchronization 계약`](networking-command-event-and-client-synchronization-contract.md)
- [`Command Ordering, Logical Time와 Transaction Coordinator 계약`](command-ordering-logical-time-and-transaction-coordinator-contract.md)
- [`Scene Streaming, Client Interest와 Ready Activation 계약`](scene-streaming-client-interest-and-ready-activation-contract.md)
- [`Spatial Query Engine과 Provider 계약`](spatial-query-engine-and-provider-contract.md)
- [`Runtime Navigation, Path Planning과 Movement Execution 계약`](runtime-navigation-path-planning-and-movement-execution-contract.md)
- [`Rule Runtime Orchestrator와 Pending Execution 계약`](rule-runtime-orchestrator-and-pending-execution-contract.md)
- [`Persistence와 Session Recovery 모델`](persistence-and-session-recovery-model.md)

## 포함 범위

- 서버·클라이언트 책임
- Source, Compiler, Immutable Build, Authoritative State, Migration과 Projection
- Session Base Mode, Context, Overlay, Transition과 Command Gate
- Input Context, Intent, Selection Session, Candidate, Preview와 Frozen Binding
- Interaction Capability, Contextual Option, DM Adjudication과 Override
- Visibility, Detection, Knowledge, Disclosure와 Hover Information Projection
- CameraRequest, Focus, Follow, Bookmark, DM Observe와 Presentation Priority
- Command, revision, transaction, Ordering, Reservation과 Journal
- Scene Source, Runtime Scene, Spatial Query, Navigation과 Streaming
- Character, Character Action, Spell, Roll Resolution, Effect, ItemInstance와 Runtime Object의 권위 경계
- Action·Bonus Action·Reaction·Movement Opportunity와 2024 기본 행동
- Spell Route, Payment, Components, Targeting, Ritual, Ready와 Concentration
- RollPlan, RollRecord, Attack·Check·Save·Damage Outcome과 Presentation Gate
- Inventory·Equipment·Container와 Scene Ground Item Presence
- Capability, RuleExecution, Recipe, TimingWindow와 PendingEffect
- 저장·복구·재접속·롤백과 Presentation 확장 계약

기능별 사용자 흐름은 `../systems/`, 화면 구조는 `../ui/`, 실제 파일 계약은 `../specs/`에 둔다.

## 작성 원칙

- 모든 Architecture 문서는 [`Runtime Architecture Principles`](runtime-architecture-principles.md)를 따른다.
- Source·Build·State·Migration을 다루면 [`Compiled Build 패턴`](compiled-build-and-authoritative-state-pattern.md)을 따른다.
- Exploration·Encounter·Downtime, Context, UI·Authoring Overlay, Scene Transition·Join·Recovery를 다루면 [`Session Runtime 계약`](session-play-mode-context-overlay-and-transition-contract.md)을 따른다.
- 클릭·Hover·Focus·대상 지정·범위 Preview·DM Hidden Selection·Q/E 승인과 취소를 다루면 [`Selection Runtime 계약`](selection-targeting-preview-and-frozen-binding-runtime-contract.md)을 따른다.
- 선택된 대상의 Open·Utilize·Pick Up·Inspect·Force Command와 DM 판정을 다루면 [`Interaction Capability 계약`](interaction-capability-contextual-command-and-adjudication-contract.md)을 따른다.
- 시야·감각·은신·Fog·발견·식별·Hover 공개 정보를 다루면 [`Visibility, Knowledge와 Detection Runtime 계약`](visibility-knowledge-detection-and-hover-information-runtime-contract.md)을 따른다.
- 자유 카메라·Follow·Focus·DM Observe·Bookmark·Replay·연출 프레이밍을 다루면 [`Camera Runtime 계약`](camera-policy-focus-follow-and-presentation-runtime-contract.md)을 따른다.
- 기본 행동과 Action Economy는 [`Character Action Runtime`](character-action-opportunity-and-2024-core-action-runtime-contract.md)을 따른다.
- 주문 시전은 [`Spell Runtime`](spell-casting-route-and-2024-spell-runtime-contract.md)을 따른다.
- 주사위, 공격 판정, 능력 판정, 내성, 이니셔티브, 죽음 내성, 피해·회복 굴림은 [`Dice와 Resolution Runtime`](dice-roll-check-save-attack-and-resolution-runtime-contract.md)을 따른다.
- 상태·집중·변신은 [`Effect Runtime`](effect-condition-and-ongoing-runtime-contract.md)을 따른다.
- ItemInstance와 바닥 Presence는 [`Inventory Runtime`](inventory-item-instance-and-world-presence-runtime-contract.md)을 따른다.
- Scene Presence Lifecycle은 [`Runtime Object System`](runtime-object-system-and-entity-lifecycle-contract.md)을 따른다.
- 원자적 상태 변경은 [`Transaction Coordinator`](command-ordering-logical-time-and-transaction-coordinator-contract.md)를 따른다.
- 공간 판정은 [`Spatial Query`](spatial-query-engine-and-provider-contract.md), 이동은 [`Runtime Navigation`](runtime-navigation-path-planning-and-movement-execution-contract.md)을 따른다.
- Capability·Recipe·TimingWindow·PendingEffect는 [`Rule Runtime Orchestrator`](rule-runtime-orchestrator-and-pending-execution-contract.md)를 따른다.

동일한 결정을 여러 문서에 반복하지 않는다. 각 하위 문서는 자신의 데이터·상태·실패·성능 계약만 추가한다.
