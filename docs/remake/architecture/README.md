# Architecture 문서

여러 기능이 공유하는 권위, 데이터와 실행 계약을 정의한다.

## 최상위 권위 문서

- [`Runtime Architecture Principles`](runtime-architecture-principles.md)
  - 사용자 경험을 상위 제약으로 둔다.
  - Scene Source, Compiled Runtime, Dynamic State와 Presentation을 분리한다.
  - Runtime 계층, Query와 Command 경계를 고정한다.
  - 모든 하위 Architecture·System·Spec 문서가 따라야 하는 공통 원칙이다.
- [`Compiled Build와 Authoritative State 분리 패턴`](compiled-build-and-authoritative-state-pattern.md)
  - Source, 불변 Compiled Build, 버전된 Authoritative State와 Projection의 공통 계층
  - Build 교체와 State Migration의 원자성
  - 도메인별로 다른 State 수명주기 유지
- [`Scene Compiler와 Compiled Runtime Scene 계약`](scene-compiler-and-compiled-runtime-scene-contract.md)
  - Canonical Scene Source, 불변 Build Package, Runtime Layer와 원자적 게시
- [`Character Runtime과 Compiled Character Build 계약`](character-runtime-and-compiled-character-build-contract.md)
  - Character Source·Build와 Persistent Character·Actor·Encounter State 분리
- [`Character Action Opportunity와 2024 Core Action Runtime 계약`](character-action-opportunity-and-2024-core-action-runtime-contract.md)
  - 2024 기본 행동 11종과 파생 행동 지원
  - Action·Bonus Action·Reaction·Movement Opportunity
  - Ready, 즉흥 행동과 DM Adjudication Pending
  - 전투·탐험의 공통 Capability·RuleExecution 경계
- [`Effect, Condition과 Ongoing Runtime 계약`](effect-condition-and-ongoing-runtime-contract.md)
  - CompiledEffectBuild, EffectInstance, Duration, Concentration, Stacking과 Suppression
- [`Inventory, ItemInstance와 World Presence Runtime 계약`](inventory-item-instance-and-world-presence-runtime-contract.md)
  - CompiledItemBuild와 권위 ItemInstance State
  - Inventory·Equipment·Container·Scene Ground의 배타적 Location Binding
  - Item Presence Runtime Object와 바닥 아이템 상호작용
  - 드롭·투척·Pickup·Stack 분할·병합의 원자적 Transfer
  - 저장·재접속·롤백·Streaming 경계
- [`Runtime Object System과 Entity Lifecycle 계약`](runtime-object-system-and-entity-lifecycle-contract.md)
  - Scene Presence의 RuntimeObjectId, Incarnation, Lifecycle, Ownership과 Presentation Materialization
- [`Networking Command, Event와 Client Synchronization 계약`](networking-command-event-and-client-synchronization-contract.md)
  - Versioned Protocol, Command·Result, Projection Stream, Snapshot Sync와 Client Ready
- [`Command Ordering, Logical Time와 Transaction Coordinator 계약`](command-ordering-logical-time-and-transaction-coordinator-contract.md)
  - Ordering Key, Reservation, Commit Graph, 원자적 Commit, Revision과 Journal
- [`Scene Streaming, Client Interest와 Ready Activation 계약`](scene-streaming-client-interest-and-ready-activation-contract.md)
  - Authority Runtime과 Client Streaming, Activation Set, Prefetch, Eviction과 Scene Transition
- [`Spatial Query Engine과 Provider 계약`](spatial-query-engine-and-provider-contract.md)
  - Snapshot-bound 공간 질의, Provider, Cache, Budget와 공개 정책
- [`Runtime Navigation, Path Planning과 Movement Execution 계약`](runtime-navigation-path-planning-and-movement-execution-contract.md)
  - Traversal Domain, Path Corridor, Clearance, Checkpoint와 Movement Execution
- [`Rule Runtime Orchestrator와 Pending Execution 계약`](rule-runtime-orchestrator-and-pending-execution-contract.md)
  - RuleExecution, 비용 예약, Recipe, TimingWindow, PendingEffect와 CommitGroup
- [`Persistence와 Session Recovery 모델`](persistence-and-session-recovery-model.md)
  - Manifest·Chunk Snapshot, Commit Journal, Recovery와 Rollback Branch

## 포함 범위

- 서버·클라이언트 책임
- Source, Compiler, Immutable Build, Authoritative State, Migration과 Projection
- Command, revision, transaction, Ordering, Reservation과 Journal
- Scene Source, Runtime Scene, Spatial Query, Navigation과 Streaming
- Character, Character Action, Effect, ItemInstance와 Runtime Object의 권위 경계
- Action·Bonus Action·Reaction·Movement Opportunity와 2024 기본 행동
- Inventory·Equipment·Container와 Scene Ground Item Presence
- Capability, RuleExecution, Recipe, TimingWindow와 PendingEffect
- 저장·복구·재접속·롤백과 Presentation 확장 계약

기능별 사용자 흐름은 `../systems/`, 화면 구조는 `../ui/`, 실제 파일 계약은 `../specs/`에 둔다.

## 작성 원칙

새 Architecture 문서는 먼저 [`Runtime Architecture Principles`](runtime-architecture-principles.md)를 따른다.

Source, Compiler, Build, Dynamic State, Migration과 Projection을 다루는 문서는 [`Compiled Build와 Authoritative State 분리 패턴`](compiled-build-and-authoritative-state-pattern.md)을 따른다.

Scene Source, Semantic Profile, Runtime Layer, Index, Chunk와 게시를 다루는 문서는 [`Scene Compiler 계약`](scene-compiler-and-compiled-runtime-scene-contract.md)을 따른다.

캐릭터 성장 원본, 파생 능력치, Capability, Resource와 Character·Actor·Encounter State를 다루는 문서는 [`Character Runtime 계약`](character-runtime-and-compiled-character-build-contract.md)을 따른다.

기본 행동, Action Economy, Bonus Action, Reaction, Ready와 즉흥 행동을 다루는 문서는 [`Character Action Runtime 계약`](character-action-opportunity-and-2024-core-action-runtime-contract.md)을 따른다.

상태, 집중, 변신, 지속 영역, 소환, Duration, Stacking과 Suppression을 다루는 문서는 [`Effect Runtime 계약`](effect-condition-and-ongoing-runtime-contract.md)을 따른다.

아이템 정의, ItemInstance, Inventory, Equipment, Container, 바닥 드롭·Pickup·투척과 Item Presence를 다루는 문서는 [`Inventory와 Item Runtime 계약`](inventory-item-instance-and-world-presence-runtime-contract.md)을 따른다.

Actor, 문, 함정, 소환체, Item Presence와 기타 Scene Presence의 생성·참조·비활성·복원·파괴를 다루는 문서는 [`Runtime Object System 계약`](runtime-object-system-and-entity-lifecycle-contract.md)을 따른다.

Remote, Client Command, Event 복제, 중도 참여, 재접속, Snapshot Sync와 Client Ready를 다루는 문서는 [`Networking 계약`](networking-command-event-and-client-synchronization-contract.md)을 따른다.

둘 이상의 권위 Store, Actor, Object, Inventory, Encounter, Scene 또는 Campaign 상태를 변경하거나 Command 충돌 순서를 다루는 문서는 [`Transaction Coordinator 계약`](command-ordering-logical-time-and-transaction-coordinator-contract.md)을 따른다.

Scene Chunk, Client Interest, Presentation Materialization, Prefetch, Eviction과 Scene Transition을 다루는 문서는 [`Scene Streaming 계약`](scene-streaming-client-interest-and-ready-activation-contract.md)을 따른다.

공간, 거리, 점유, 시야, 영역 포함, 배치와 이동 가능성을 사용하는 문서는 [`Spatial Query 계약`](spatial-query-engine-and-provider-contract.md)을 따른다.

경로 계획, 이동 비용, 중단, 점유와 위치 변경을 사용하는 문서는 [`Runtime Navigation 계약`](runtime-navigation-path-planning-and-movement-execution-contract.md)을 따른다.

Capability 실행, Recipe, RuleEvent, TimingWindow, Reaction, PendingEffect와 CommitGroup을 다루는 문서는 [`Rule Runtime Orchestrator 계약`](rule-runtime-orchestrator-and-pending-execution-contract.md)을 따른다.

동일한 결정을 여러 문서에 반복하지 않는다. 각 하위 문서는 자신의 데이터·상태·실패·성능 계약만 추가한다.