# RVTT System Model v1

- 상태: `ACTIVE · APPROVED_SYSTEM_AUTHORITY`
- 승인일: 2026-08-13
- Source 구현: `BLOCKED`
- Studio/MCP 구현: `BLOCKED`
- 다음 단계: `R3 · CORE_RUNTIME_PRESENTATION_BOUNDARY_FREEZE`
- 근거 감사: `audits/IMPLEMENTATION-MODEL-R2-SCENARIO-PRESSURE-001.md`

이 문서는 기존 Greenfield System/Module/Stable Function 모델을 대체하는 **현재 구현 System 권위**다.

System은 Manager, Service, Controller, ModuleScript 개수를 뜻하지 않는다. System은 제품 전체에서 독립적으로 설명 가능한 책임·상태·권위 경계다. 실제 Module/Stable Function/Studio Manager·Controller는 R4/E1에서 필요한 시점에만 구체화한다.

## 1. 비협상 원칙

```text
Product / Accepted ADR / Current Architecture
→ Capability v2
→ 33 System Model
→ Scenario Pressure
→ R3 execution boundary
→ R4 E0 checkpoint
→ Source
```

- Client는 서버 권위 규칙과 상태를 재구성하지 않는다.
- Domain은 다른 Domain Store를 직접 수정하지 않는다.
- 모든 권위 mutation은 공통 Transaction 경계를 통한다.
- Projection 생성과 네트워크 동기화는 다른 책임이다.
- Presentation 실패는 Gameplay 결과를 바꾸지 않는다.
- Runtime Object Presence와 Character/Item/Effect 원본 상태를 합치지 않는다.
- Campaign Game Time과 Downtime Activity를 합치지 않는다.
- UI/Input, Camera, Presentation Playback을 하나의 거대 Client Manager로 합치지 않는다.
- Repository Core Engine 전체 완료 전 Studio/MCP 구현을 시작하지 않는다.
- 미래 기능은 지금 구현하지 않지만, 미래 기능 때문에 공통 public boundary를 갈아엎어야 하는 구조도 허용하지 않는다.

## 2. 33 System Model

### Authority / Coordination

| ID | System | Owns | Does not own |
|---|---|---|---|
| A1 | Session & Control Policy | role/control assignment, base mode, context, overlay, transition, ready command policy | gameplay domain state, UI panel state |
| A2 | Request Runtime | versioned Command/Read lifecycle, envelope validation, idempotency/correlation entry | domain rule result, transaction commit |
| A3 | Transaction, Ordering & Outbox Runtime | ordering keys, reservation, typed preconditions, atomic commit, authority revision, commit marker, domain-event outbox | domain rule calculation, client projection |
| A4 | Cross-Domain Outcome Integration | immediate closure and deferred consequence coordination across domain plans | domain stores, independent rule engines |
| A5 | Projection Runtime | viewer context, disclosure-safe projection build, snapshot/delta model | transport sequencing, UI rendering |
| A6 | Client Synchronization Runtime | connection epoch, sequence/cursor, snapshot transfer, gap detection, resync | viewer disclosure decisions, UI ViewModel |
| A7 | Persistence & Branch Recovery | durable snapshot/journal lineage, restart reconstruction, rollback branch, authority epoch reconstruction | reconnect UI, client cache |

### World Runtime

| ID | System | Owns | Does not own |
|---|---|---|---|
| W1 | Scene Runtime & Build Activation | active compiled build binding, runtime scene snapshot/build activation and safe swap | canonical scene source editing, RuntimeObject lifecycle |
| W2 | Runtime Object & Entity Lifecycle | RuntimeObjectId/incarnation, authoritative scene presence, spawn/archive/destroy, domain bindings | Character/Item/Effect source of truth |
| W3 | Spatial Query Runtime | snapshot-bound typed spatial evidence/query | gameplay decisions, direct mutation |
| W4 | Visibility & Knowledge Runtime | detection, knowledge relation, disclosure eligibility/evidence | projection transport, UI hiding as security |
| W5 | Selection & Frozen Binding Runtime | candidate/session/targeting/preview boundary and execution-bound frozen binding | camera movement, final rule outcome |
| W6 | Navigation & Movement Runtime | planning policy, movement budget, occupancy, replan, execution/checkpoints | Roblox PathfindingService implementation detail until E1 |
| W7 | Scene Delivery & Ready Activation | artifact interest, chunk materialization/prefetch, client-ready activation gate | server authority object lifecycle |

### Rules Runtime

| ID | System | Owns | Does not own |
|---|---|---|---|
| R1 | Content & Ruleset Runtime | trusted definitions/packs/version, frozen policy/ruleset snapshot, localization identity, compile inputs | campaign-authored draft state |
| R2 | Capability & Derived Rule Query Runtime | grants, passives, overrides, derived values, effective capability and contextual availability queries | mutable Character/Encounter/Item/Effect state |
| R3 | Rule Execution & Adjudication Runtime | persistent execution, timing/reaction/prompt, resource reservation orchestration, DM adjudication | atomic commit, RNG record ownership |
| R4 | Dice & Resolution Runtime | RollIntent/Plan, server RNG, sealed result, reveal policy input, RollRecord, resolution outcome | damage/effect state commit, presentation playback |
| R5 | Effect & Ongoing Runtime | EffectInstance, condition, duration relation, concentration, aura, suppression, lifecycle | campaign clock, Character source |

### Gameplay Domains

| ID | System | Owns | Does not own |
|---|---|---|---|
| D1 | Character Runtime | Character source, compiled build, persistent character state/resources, progression activation | scene presence, encounter timeline |
| D2 | Encounter Runtime | participants, timeline, turn/action/reaction opportunities, objectives | character sheet data, campaign clock |
| D3 | Inventory & Item Runtime | ItemInstance, containers, equipment, ownership/location and world-presence binding | RuntimeObject presence lifecycle itself |
| D4 | Game Time & Scheduler Runtime | campaign chronology, time advance, duration handles, scheduled due candidates | rest eligibility, encounter turn, wall-clock timeout |
| D5 | Downtime & Activity Runtime | multi-participant activity windows, progress, long reservations, checkpoints, domain completion coordination | campaign clock authority, domain-specific completion rules |
| D6 | Journal Runtime | document source, sections, anchors, ACL/search/backlink/edit/navigation capability | camera movement, scene authority |
| D7 | Campaign Logistics Runtime | survival requirements, allocation, reservation, settlement proposal, ledger | Inventory store, Game Time store |

### Authoring

| ID | System | Owns | Does not own |
|---|---|---|---|
| U1 | Scene Authoring & Compiler | canonical scene source, editor commands, validation, candidate compile/test, last-known-good, publish proposal | active runtime build swap, runtime dynamic state |
| U2 | Actor Authoring & Publish | statblock/model draft, strict validation, campaign-local published actor definition | general trusted content catalog, spawned RuntimeObject lifecycle |

### Client / Presentation

| ID | System | Owns | Does not own |
|---|---|---|---|
| C1 | UI & Input Runtime | projection replica, ViewModel, panel lifecycle, semantic input context/focus, pending UI, client recovery state | gameplay authority, camera policy, presentation playback |
| C2 | Camera Runtime | CameraRequest policy, focus/follow/free override, restore stack, local camera projection | gameplay position/visibility/selection authority |
| C3 | Presentation Runtime | presentation source/compiler, recipe/playback, priority, marker/reveal gate, accessibility/fallback | gameplay outcome, dice result, domain state |

### Support

| ID | System | Owns | Does not own |
|---|---|---|---|
| S1 | Diagnostics & Observability Runtime | trace/span, decision record, incident, budget observation, redaction, support reference | gameplay decision and mutation |
| S2 | Deterministic Simulation Harness | scenario/fixture, controlled adapters, interleaving, fault injection, assertions/regression artifacts | second rules engine, test-only state mutation path |

## 3. 핵심 의존 방향

```text
Client Intent
→ C1 UI/Input
→ A2 Request Runtime
→ A1 Session/Control policy + domain/rule validation
→ R2/R3 or domain operation
→ R4/R5/W*/D* as required
→ A4 Cross-domain integration when multiple domains close together
→ A3 Transaction/Ordering/Outbox
→ committed state/event
→ A5 Projection
→ A6 Synchronization
→ C1 Replica/ViewModel
→ C2 Camera and/or C3 Presentation as projection/presentation requests
```

Read path:

```text
C1
→ A2 Read Request
→ snapshot-bound W3/R2/D*/A5 query
→ Read Result

Read Request는 Command를 실행하거나 상태를 변경하지 않는다.
```

Recovery path:

```text
A7 durable reconstruction
→ new AuthorityEpoch when required
→ W*/R*/D* state/index rebuild
→ A5 fresh projection
→ A6 full/catch-up sync
→ C1 atomic replica recovery
→ A1 ready gate opens gameplay input
```

## 4. Capability Catalog v2

기존 `architecture-coverage.json`의 22 Capability는 R0/R1에 사용한 **legacy coverage vocabulary**로 보존한다. 새 구현에서 사용하는 현재 Capability Catalog는 아래 34개다.

| Capability ID | System |
|---|---|
| CAP_SESSION_CONTROL_POLICY | A1 |
| CAP_REQUEST_PROTOCOL | A2 |
| CAP_TRANSACTION_COMMIT_EVENT | A3 |
| CAP_CROSS_DOMAIN_OUTCOME | A4 |
| CAP_PROJECTION_RUNTIME | A5 |
| CAP_CLIENT_SYNCHRONIZATION | A6 |
| CAP_PERSISTENCE_BRANCH_RECOVERY | A7 |
| CAP_SCENE_RUNTIME_ACTIVATION | W1 |
| CAP_RUNTIME_OBJECT_LIFECYCLE | W2 |
| CAP_SPATIAL_QUERY | W3 |
| CAP_VISIBILITY_KNOWLEDGE | W4 |
| CAP_SELECTION_TARGETING | W5 |
| CAP_NAVIGATION_MOVEMENT | W6 |
| CAP_SCENE_DELIVERY_READY | W7 |
| CAP_CONTENT_RULESET | R1 |
| CAP_DERIVED_RULE_CAPABILITY | R2 |
| CAP_CONTEXTUAL_AVAILABILITY | R2 |
| CAP_RULE_EXECUTION | R3 |
| CAP_DICE_RESOLUTION | R4 |
| CAP_EFFECT_ONGOING | R5 |
| CAP_CHARACTER_RUNTIME | D1 |
| CAP_ENCOUNTER_RUNTIME | D2 |
| CAP_INVENTORY_ITEM | D3 |
| CAP_GAME_TIME_SCHEDULER | D4 |
| CAP_DOWNTIME_ACTIVITY | D5 |
| CAP_JOURNAL_RUNTIME | D6 |
| CAP_SURVIVAL_LOGISTICS | D7 |
| CAP_SCENE_AUTHORING | U1 |
| CAP_ACTOR_AUTHORING | U2 |
| CAP_UI_INPUT_RUNTIME | C1 |
| CAP_CAMERA_RUNTIME | C2 |
| CAP_PRESENTATION_RUNTIME | C3 |
| CAP_DIAGNOSTICS_OBSERVABILITY | S1 |
| CAP_DETERMINISTIC_SIMULATION | S2 |

### Legacy 22 → Capability v2 migration

```text
CAP_SESSION_CONTROL_CONTEXT
→ CAP_SESSION_CONTROL_POLICY

CAP_COMMAND_AUTHORITY_PROTOCOL
→ CAP_REQUEST_PROTOCOL

CAP_TRANSACTION_EVENT_PROJECTION_BARRIER
→ CAP_TRANSACTION_COMMIT_EVENT
+ CAP_PROJECTION_RUNTIME

CAP_PROJECTION_DISCLOSURE_SYNC
→ CAP_PROJECTION_RUNTIME
+ CAP_CLIENT_SYNCHRONIZATION

CAP_RUNTIME_OBJECT_SCENE_IDENTITY
→ CAP_SCENE_RUNTIME_ACTIVATION
+ CAP_RUNTIME_OBJECT_LIFECYCLE

CAP_SPATIAL_QUERY
→ CAP_SPATIAL_QUERY

CAP_NAVIGATION_MOVEMENT
→ CAP_NAVIGATION_MOVEMENT

CAP_SELECTION_TARGETING
→ CAP_SELECTION_TARGETING

CAP_INTERACTION_CAPABILITY
→ CAP_CONTEXTUAL_AVAILABILITY

CAP_CHARACTER_ACTION_AVAILABILITY
→ CAP_DERIVED_RULE_CAPABILITY
+ CAP_CONTEXTUAL_AVAILABILITY

CAP_RULE_EXECUTION
→ CAP_RULE_EXECUTION

CAP_VISIBILITY_KNOWLEDGE
→ CAP_VISIBILITY_KNOWLEDGE

CAP_ENCOUNTER_ACTION_ECONOMY
→ CAP_ENCOUNTER_RUNTIME
+ CAP_CONTEXTUAL_AVAILABILITY

CAP_CHARACTER_BUILD_STATE
→ CAP_CHARACTER_RUNTIME

CAP_INVENTORY_ITEM_WORLD_PRESENCE
→ CAP_INVENTORY_ITEM
+ CAP_RUNTIME_OBJECT_LIFECYCLE when scene presence exists

CAP_TIME_DOWNTIME_PERSISTENCE
→ CAP_GAME_TIME_SCHEDULER
+ CAP_DOWNTIME_ACTIVITY
+ CAP_PERSISTENCE_BRANCH_RECOVERY

CAP_UI_PRESENTATION_CAMERA
→ CAP_UI_INPUT_RUNTIME
+ CAP_CAMERA_RUNTIME
+ CAP_PRESENTATION_RUNTIME

CAP_JOURNAL_KNOWLEDGE_NAVIGATION
→ CAP_JOURNAL_RUNTIME

CAP_CONTENT_RULESET_EXTENSION
→ CAP_CONTENT_RULESET

CAP_DIAGNOSTICS_SIMULATION_TESTING
→ CAP_DIAGNOSTICS_OBSERVABILITY
+ CAP_DETERMINISTIC_SIMULATION

CAP_SURVIVAL_LOGISTICS
→ CAP_SURVIVAL_LOGISTICS

CAP_DM_ACTOR_AUTHORING
→ CAP_ACTOR_AUTHORING
```

R2에서 legacy 22에 독립 ID가 없던 다음 책임은 v2에 명시적으로 추가됐다.

```text
CAP_CROSS_DOMAIN_OUTCOME
CAP_DICE_RESOLUTION
CAP_EFFECT_ONGOING
CAP_SCENE_AUTHORING
CAP_SCENE_DELIVERY_READY
```

## 5. 61 Scenario Trace

`audits/IMPLEMENTATION-MODEL-R2-SCENARIO-PRESSURE-001.md`에서 Base 14 + Expanded 47 = **61/61 Scenario**를 이 System Model에 재통과시켰다.

결과:

```text
Scenario reviewed = 61 / 61
Empty responsibility path = 0
Old Greenfield module assumption = 0
Approved System Model = 33 systems
```

Scenario Registry의 기존 `capabilityRefs`는 legacy 22 vocabulary로 작성된 요구사항 태그다. 새 구현의 canonical trace는 다음 순서다.

```text
Scenario
→ R2 pressure path의 System ID
→ 이 문서의 System → Capability v2 mapping
→ R3/R4 implementation boundary/checkpoint
```

따라서 구현 AI는 legacy `capabilityRefs`만 보고 책임 경계를 복원하지 않는다.

## 6. 미래 호환성 압력

E0 경계를 설계할 때 최소 다음 미래 소비를 항상 확인한다.

```text
Character creation / level-up / sheet
Encounter / reaction / ready / death save
Inventory / equipment / consumables / pickup
Spell / dice / concentration / effects
Rest / travel / crafting / survival settlement
Journal / scene authoring / live DM
Content migration / actor authoring
Reconnect / restart / rollback / branch recovery
Streaming / low-end fallback / accessibility
```

현재 Checkpoint를 빨리 통과하기 위해 위 미래 소비가 요구하는 shared seam을 feature-specific helper로 숨기면 FAIL이다.

## 7. R3 규칙

다음 단계에서는 System 전체를 억지로 한 실행환경에 배치하지 않는다. **각 System의 책임을 세 층으로 분해**한다.

```text
Repository Core Engine
= Roblox Runtime 없이 correctness를 자동 검증할 수 있는 정책/상태기계/계약/순수 계산

Roblox Runtime Engine / Adapter
= PathfindingService, raycast, physics, Instance/Player/Remote/Streaming 등 Roblox 결과가 correctness의 일부인 책임

Presentation / Human Feel
= 실제 UI/VFX/camera feel/interaction readability처럼 사람이 보고 만져야 판단 가능한 책임
```

예:

```text
W6 Navigation & Movement
Core: request/result, budget, occupancy policy, replan policy, failure semantics
Runtime: PathfindingService/NavMesh/raycast/collision provider
Presentation: preview readability, click response, movement feel
```

**R3가 끝나도 Source를 만들지 않는다.** R4 E0 Checkpoint Freeze가 끝난 뒤 전용 Implementation Branch를 만들고 Repository Core Engine부터 구현한다.
