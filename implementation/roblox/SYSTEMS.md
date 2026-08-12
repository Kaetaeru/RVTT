# RVTT System Model v2

- 상태: `ACTIVE · APPROVED_SYSTEM_AUTHORITY · R3_REPAIRED_PENDING_FREEZE`
- 승인 근거: 사용자 지시 + R2 Scenario Pressure + R3 Self Review
- Source 구현: `BLOCKED`
- Studio/MCP 구현: `BLOCKED`
- Machine-readable mirror: [`manifests/implementation-system-model.json`](manifests/implementation-system-model.json)
- 다음 단계: `R3 REPAIRED MODEL VALIDATION → USER FREEZE DECISION → R4`

이 문서는 폐기된 Greenfield System/Module/Stable Function 모델을 대체하는 현재 구현 System 권위다.

System은 Manager, Service, Controller, ModuleScript 개수가 아니다. 제품 전체에서 독립적으로 설명 가능한 책임·상태·권위 경계다. 실제 Module/Stable Function과 Studio Manager/Controller 이름은 R4/E1에서 필요한 시점에만 구체화한다.

## 1. 비협상 원칙

```text
Product / Accepted ADR / Current Architecture / UI
→ Requirement Capability
↔ Representative Scenario
→ System Responsibility
→ R3 execution boundary
→ R4 E0 checkpoint
→ Source
```

- Requirement Capability와 System은 **many-to-many**다. Capability를 System 이름의 별칭으로 만들지 않는다.
- Client는 서버 권위 규칙과 상태를 재구성하지 않는다.
- Domain은 다른 Domain Store를 직접 수정하지 않는다.
- 모든 권위 mutation은 A3 Transaction 경계를 통한다.
- A3의 Outbox 기록과 A8의 committed-event delivery를 합치지 않는다.
- Projection 생성(A5)과 네트워크 동기화(A6)를 합치지 않는다.
- Presentation 실패는 Gameplay 결과를 바꾸지 않는다.
- Runtime Object Presence와 Character/Item/Effect 원본 상태를 합치지 않는다.
- Campaign Game Time과 technical monotonic time을 합치지 않는다.
- UI/Input, Camera, Presentation Playback을 하나의 거대 Client Manager로 합치지 않는다.
- `REPOSITORY_LOGIC`와 `E0_CORE_ENGINE`을 같은 뜻으로 쓰지 않는다.
- `CORE_ENGINE_COMPLETE` 전 Studio/MCP 구현을 시작하지 않는다.
- 미래 기능은 지금 구현하지 않지만 미래 기능 때문에 shared public boundary를 재작성해야 하는 구조도 허용하지 않는다.

## 2. 34 System Responsibility Model

### Authority / Coordination

| ID | System | Owns | Does not own |
|---|---|---|---|
| A1 | Session & Control Policy | role/control assignment, base mode, context, overlay, transition, **final EffectiveGameplayReady and Command gate** | gameplay domain state, UI panel state, individual readiness evidence production |
| A2 | Request Runtime | versioned Command/Read lifecycle, envelope validation, idempotency/correlation entry | domain rule result, transaction commit |
| A3 | Transaction, Ordering & Outbox Runtime | ordering keys, OrderingReservation, typed preconditions, atomic commit, authority revision, commit marker, transactional outbox append | subscriber delivery/retry, rule calculation, client projection |
| A4 | Cross-Domain Outcome Integration | immediate closure and deferred consequence coordination across domain plans | domain stores, independent rule engines |
| A5 | Projection Runtime | viewer context, disclosure-safe projection build, snapshot/delta model | transport sequencing, UI rendering, committed-event retry |
| A6 | Client Synchronization Runtime | connection epoch, sequence/cursor, snapshot transfer, gap detection, resync, `projectionSyncReady` evidence | viewer disclosure decisions, final gameplay-ready decision |
| A7 | Persistence & Branch Recovery | durable snapshot/journal lineage, restart reconstruction, rollback branch, authority epoch reconstruction, `authorityRecoveryReady` evidence | reconnect UI, final gameplay-ready decision |
| A8 | Domain Event Delivery Runtime | committed outbox dispatch, subscription registry, ordering scope, at-least-once retry, subscriber receipts, dead-letter/failure isolation | authority commit, direct domain mutation, projection disclosure policy |

### World Runtime

| ID | System | Owns | Does not own |
|---|---|---|---|
| W1 | Scene Runtime & Build Activation | active compiled build binding, runtime scene snapshot/build activation and safe swap | canonical scene source editing, RuntimeObject lifecycle |
| W2 | Runtime Object & Entity Lifecycle | RuntimeObjectId/incarnation, authoritative scene presence, spawn/archive/destroy, domain bindings | Character/Item/Effect source of truth |
| W3 | Spatial Query Runtime | snapshot-bound typed spatial evidence/query | gameplay decisions, direct mutation |
| W4 | Visibility & Knowledge Runtime | detection, knowledge relation, disclosure eligibility/evidence | projection transport, UI hiding as security |
| W5 | Selection & Frozen Binding Runtime | candidate/session/targeting/preview boundary and execution-bound frozen binding | camera movement, final rule outcome |
| W6 | Navigation & Movement Runtime | planning policy, movement budget, OccupancyReservation, replan, execution/checkpoints | Roblox PathfindingService implementation detail until E1 |
| W7 | Scene Delivery & Ready Activation | artifact interest, chunk materialization/prefetch and `sceneEssentialReady` evidence | server authority object lifecycle, final gameplay Command gate |

### Rules Runtime

| ID | System | Owns | Does not own |
|---|---|---|---|
| R1 | Content & Ruleset Runtime | trusted definitions/packs/version, frozen policy/ruleset snapshot, localization identity, compile inputs | campaign-authored draft state |
| R2 | Capability & Derived Rule Query Runtime | grants, passives, overrides, derived values, effective capability and contextual availability queries | mutable Character/Encounter/Item/Effect state |
| R3 | Rule Execution & Adjudication Runtime | persistent execution, timing/reaction/prompt, **ResourceReservation orchestration**, DM adjudication | atomic commit, OrderingReservation, RNG record ownership |
| R4 | Dice & Resolution Runtime | RollIntent/Plan, server RNG provider use, sealed result, reveal policy input, RollRecord, resolution outcome | damage/effect state commit, presentation playback |
| R5 | Effect & Ongoing Runtime | EffectInstance, condition, duration relation, concentration, aura, suppression, lifecycle | campaign clock, Character source |

### Gameplay Domains

| ID | System | Owns | Does not own |
|---|---|---|---|
| D1 | Character Runtime | Character source, compiled build, persistent character state/resources, progression activation | scene presence, encounter timeline |
| D2 | Encounter Runtime | participants, timeline, turn/action/reaction opportunities, objectives | character sheet data, campaign clock |
| D3 | Inventory & Item Runtime | ItemInstance, containers, equipment, ownership/location and world-presence binding | RuntimeObject presence lifecycle itself |
| D4 | Game Time & Scheduler Runtime | campaign chronology, time advance, duration handles, scheduled due candidates | rest eligibility, encounter turn, technical wall-clock timeout |
| D5 | Downtime & Activity Runtime | multi-participant activity windows, progress, typed ActivityReservation, checkpoints, domain completion coordination | campaign clock authority, generic lock management |
| D6 | Journal Runtime | document source, sections, anchors, ACL/search/backlink/edit/navigation capability | camera movement, scene authority |
| D7 | Campaign Logistics Runtime | survival requirements, allocation, typed LogisticsAllocationReservation, settlement proposal, ledger | Inventory store, Game Time store |

### Authoring

| ID | System | Owns | Does not own |
|---|---|---|---|
| U1 | Scene Authoring & Compiler | canonical scene source, editor commands, validation, candidate compile/test, last-known-good, publish proposal | active runtime build swap, runtime dynamic state |
| U2 | Actor Authoring & Publish | statblock/model draft, strict validation, campaign-local published actor definition | general trusted content catalog, spawned RuntimeObject lifecycle |

### Client / Presentation

| ID | System | Owns | Does not own |
|---|---|---|---|
| C1 | UI & Input Runtime | projection replica, ViewModel, panel lifecycle, semantic input context/focus, pending UI, recovery state, `clientReplicaReady` evidence | gameplay authority, final ready gate, camera policy, presentation playback |
| C2 | Camera Runtime | CameraRequest policy, focus/follow/free override, restore stack, local camera projection | gameplay position/visibility/selection authority |
| C3 | Presentation Runtime | presentation source/compiler, recipe/playback, priority, marker/reveal gate, accessibility/fallback | gameplay outcome, dice result, domain state |

### Support

| ID | System | Owns | Does not own |
|---|---|---|---|
| S1 | Diagnostics & Observability Runtime | trace/span, decision record, incident, budget observation, redaction, support reference | gameplay decision and mutation |
| S2 | Deterministic Simulation Harness | scenario/fixture, controlled adapters, interleaving, fault injection, assertions/regression artifacts | second rules engine, test-only state mutation path |

## 3. 핵심 권위 흐름

Mutation path:

```text
Client Intent
→ C1 UI/Input
→ A2 Request Runtime
→ A1 Session/Control policy + domain/rule validation
→ R2/R3 or domain operation
→ R4/R5/W*/D* as required
→ A4 when multiple domains must close together
→ A3 Ordering + Transaction + Outbox atomic commit
→ committed outbox record
→ A8 Event Delivery
→ A5 Projection subscriber and/or authorized follow-up/diagnostic subscribers
→ A6 Synchronization
→ C1 Replica/ViewModel
→ C2 Camera and/or C3 Presentation requests
```

**A8 Event Handler가 상태를 바꾸고 싶으면 새 Command/RuleExecution을 제출한다. A8이 Store나 A3 commit internals를 직접 수정하지 않는다.**

Read path:

```text
C1
→ A2 Read Request
→ snapshot-bound W3/R2/D*/A5 query
→ Read Result
```

Read Request는 Command를 실행하거나 상태를 변경하지 않는다.

Recovery/ready path:

```text
A7 reconstruction → authorityRecoveryReady
A5/A6 snapshot+sync → projectionSyncReady
W7 essential materialization → sceneEssentialReady
C1 replica commit → clientReplicaReady

all typed evidence
→ A1 EffectiveGameplayReady
→ A1 alone opens final gameplay Command gate
```

## 4. Reservation Taxonomy

`reservation`이라는 단어만으로 공통 Manager를 만들지 않는다.

```text
OrderingReservation
owner: A3
purpose: 짧은 concurrency ordering right

ResourceReservation
orchestrator: R3
underlying resource owner: Character/Encounter/Inventory 등 해당 Domain
purpose: Pending Execution 동안 소비권 보존

OccupancyReservation
owner: W6
purpose: short-horizon movement space coordination

ActivityReservation
owner: D5
purpose: 장기 Activity 참가/기여 hold

LogisticsAllocationReservation
owner: D7
purpose: survival settlement allocation hold
```

서로 수명주기, 복구 의미, commit semantics가 다르며 범용 `ReservationManager` 하나로 합치지 않는다.

## 5. Platform Provider Contracts

E0에서 공통 interface를 먼저 고정하고 Production/Test adapter를 교체 가능하게 한다.

```text
AuthorityMonotonicClock
DeterministicIdFactory
RngProvider
TransportAdapter
StorageAdapter
```

규칙:

- `AuthorityMonotonicClock`은 timeout/lease/rate-limit용이며 D4 Campaign Game Time이 아니다.
- R4만 authoritative RNG 결과를 만든다.
- A2/A6만 Transport adapter의 공통 네트워크 의미를 소유하고 Domain별 Remote authority path를 만들지 않는다.
- A7만 durable storage semantics를 소유하며 Domain이 Storage adapter로 Transaction/Recovery를 우회하지 않는다.
- S2는 같은 interface의 deterministic test adapter를 제공한다.

## 6. Requirement Capability Catalog v3

기존 `Capability Catalog v2 = System 별칭` 구조는 폐기한다.

현재 Requirement Capability는 **제품/Architecture가 보장해야 하는 결과**이고 System과 독립 축이다. 하나의 Capability는 여러 System을 압박하며 하나의 System도 여러 Capability를 만족한다.

Canonical machine-readable 목록은 `manifests/implementation-system-model.json`의 **30 Requirement Capabilities**다.

대표 예:

```text
REQ_SESSION_PLAYABILITY
→ A1 + A6 + A7 + W7 + C1

REQ_COMMITTED_EVENT_PROPAGATION
→ A3 + A8 + A5 + A7 + S1

REQ_SELECTION_TARGETING
→ C1 + W3 + W4 + W5 + R2

REQ_RULE_EXECUTION_RESOLUTION
→ R2 + R3 + R4 + A4 + A3

REQ_DIAGNOSTICS_REPRODUCIBILITY
→ S1 + S2 + A3 + A8 + A7
```

이 many-to-many 구조가 System 누락을 역으로 검증한다.

## 7. Scenario Trace

Base 14 + Expanded 47 = **61 Scenario**를 유지한다.

새 canonical trace는:

```text
Scenario
→ Requirement Capability[]
→ System Responsibility[]
→ R3 boundary
→ R4 checkpoint/evidence
```

61개 전부의 `requirementCapabilityRefs`와 `systemRefs`는 `manifests/implementation-system-model.json`에 machine-readable하게 기록한다. Legacy Scenario Registry의 `capabilityRefs`는 historical requirement vocabulary로만 보존한다.

## 8. REPOSITORY_LOGIC ≠ E0_CORE_ENGINE

```text
REPOSITORY_LOGIC
= Roblox 없이 구현/검증 가능한 모든 production logic의 분류

E0_CORE_ENGINE
= Studio에 들어가기 전에 반드시 완성해야 하는 Repository foundation subset
```

따라서 Character/Journal/Actor Authoring 같은 로직이 Repository에서 구현 가능하다는 사실만으로 전부 `CORE_ENGINE_COMPLETE` 선행 구현이 되는 것은 아니다.

현재 R3에서 E0 선행 seam은 machine-readable manifest의 `e0RequiredSystemSeams`가 소유한다. 중요한 원칙은 **E1 Provider가 소비할 Core contract/policy/state-machine은 무조건 E0에서 먼저 완성**하는 것이다.

명시적으로 E0에서 빠지면 안 되는 예:

```text
W5 Selection/Frozen Binding core
W6 Navigation request/plan/replan/occupancy core
W7 Streaming/Ready policy core
C1 Input Context/Replica/Recovery core
C2 CameraRequest policy core
C3 Presentation recipe/playback policy core
S2 deterministic harness foundation
```

`D6 Journal`, `D7 Campaign Logistics`, `U2 Actor Authoring`의 feature implementation은 현재 `CORE_ENGINE_COMPLETE` 필수 항목이 아니다. 단, R4가 실제 E1 선행 의존성을 발견하면 사용자 승인 후 E0 범위로 승격한다.

## 9. 미래 호환성 압력

E0/R4는 최소 다음 미래 소비를 항상 확인한다.

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

현재 Checkpoint를 빨리 통과하기 위해 미래 소비가 요구하는 shared seam을 feature-specific helper로 숨기면 FAIL이다.

## 10. 실행 순서

```text
R3 repaired boundary validation
→ 사용자 R3 Freeze 결정
→ R4 E0 Checkpoint Freeze
→ Dedicated Implementation Branch
→ E0 Core Engine 전체 구현/자동 검증
→ CORE_ENGINE_COMPLETE
→ E1 Runtime Checkpoint Freeze
→ Studio/MCP Runtime Provider + Integration
→ INTEGRATION_READY
→ U0 HTML/UI Distillation + Product UI Shell
→ UI_SHELL_READY
→ E2 user-facing checkpoints
```

**Repository Core Engine 전체 완료 전 Studio/MCP 구현을 시작하지 않는다.**
