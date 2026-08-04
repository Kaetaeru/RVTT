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
- [`Scene Compiler와 Compiled Runtime Scene 계약`](scene-compiler-and-compiled-runtime-scene-contract.md)
- [`Character Runtime과 Compiled Character Build 계약`](character-runtime-and-compiled-character-build-contract.md)
- [`Character Action Opportunity와 2024 Core Action Runtime 계약`](character-action-opportunity-and-2024-core-action-runtime-contract.md)
- [`Spell Casting Route와 2024 Spell Runtime 계약`](spell-casting-route-and-2024-spell-runtime-contract.md)
- [`Dice Roll, Check, Save, Attack과 Resolution Runtime 계약`](dice-roll-check-save-attack-and-resolution-runtime-contract.md)
  - 서버 RollPlan, SealedRollResult와 불변 RollRecord
  - d20 Test, Advantage·Disadvantage, Modifier, Bonus Die와 Reroll
  - Attack·Check·Save·Initiative·Death Save·Damage Resolution
  - 카메라 기반 3D 주사위와 Presentation Reveal Gate
  - 비밀 굴림 Projection, 저장·재접속·Rollback
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