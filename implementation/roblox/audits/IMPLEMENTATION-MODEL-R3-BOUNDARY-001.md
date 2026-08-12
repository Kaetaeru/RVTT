# RVTT Implementation Model R3 Boundary Audit 001

- 상태: `DRAFT · NON_AUTHORITY · USER_APPROVAL_REQUIRED`
- 작성일: 2026-08-13
- 대상: `R3 — Core / Roblox Runtime / Presentation Boundary Freeze`
- System Authority: `implementation/roblox/SYSTEMS.md`
- 구현 상태: `SOURCE_BLOCKED · STUDIO_BLOCKED`

## 1. 목적

33-System Model v1의 책임을 구현 환경에 맞게 분해한다.

중요:

```text
System 하나 = 실행 환경 하나
```

가 아니다.

같은 System 안에서도 Roblox 없이 검증 가능한 정책은 Repository Core Engine에 두고, Roblox 결과가 correctness에 필요한 Provider만 E1 Studio Runtime으로 미룬다. 사람이 보고 만져야 판단 가능한 감각은 U0/E2 Presentation으로 미룬다.

## 2. 분류 기준

### CORE

Repository에서 Roblox 없이 자동 검증할 수 있는 책임.

- data contracts / schema
- identity, revision, epoch rules
- deterministic state machines
- policy composition
- pure queries/calculation
- orchestration
- failure semantics
- adapter interfaces
- serialization-neutral domain logic

### RUNTIME

Roblox Runtime 결과가 correctness의 일부인 Provider/Adapter.

- Player / Instance lifecycle binding
- Remote transport
- PathfindingService / NavMesh
- raycast / overlap / collision / physics
- Workspace/asset materialization
- StreamingEnabled integration
- UserInputService / ContextActionService / GUI focus bridge
- Roblox Camera / animation / audio / VFX execution
- DataStore/MemoryStore persistence adapter

### HUMAN

사람이 실제 플레이 화면에서 판단해야 하는 결과.

- visual hierarchy / layout
- path preview readability
- selection/interaction readability
- camera feel
- movement perceived intent
- VFX timing and clarity
- UI shell / accessibility feel

## 3. 전체 경계 행렬

| ID | System | CORE · E0 candidate | RUNTIME · E1 after CORE_ENGINE_COMPLETE | HUMAN · U0/E2 |
|---|---|---|---|---|
| A1 | Session & Control Policy | role/control/mode/context/overlay/transition state machine, command-policy composition, ready gating contract | Roblox Player join/leave identity events as input adapter only | mode/transition/ready messaging clarity |
| A2 | Request Runtime | protocol envelopes, schema/version validation, Command vs Read semantic split, idempotency/correlation/rate-policy interfaces, result model | RemoteEvent/RemoteFunction or lane transport adapter, connection binding | pending/retry/error wording through C1 |
| A3 | Transaction, Ordering & Outbox | ordering keys, reservation state machine, typed preconditions, transaction plan/commit, authority revision, outbox, commit marker interfaces | monotonic clock/lease provider if Roblox-coupled; durable journal sink delegated to A7 | none |
| A4 | Cross-Domain Outcome Integration | immediate closure graph, deferred consequence model, cycle/budget rules, domain proposal composition | none by default | none |
| A5 | Projection Runtime | viewer context contract, disclosure-safe builders, snapshot/delta model, projection revision, redaction rules | none by default; runtime data enters through system provider contracts | projection readability belongs to C1/C3, not A5 |
| A6 | Client Synchronization Runtime | stream/cursor/sequence, connection epoch, gap detection, snapshot segmentation, resync state machine | Remote transport, Roblox connection lifecycle, payload budget measurements | reconnect/resync feedback through C1 |
| A7 | Persistence & Branch Recovery | manifest/chunk/journal schemas, snapshot materialization logic, integrity, reconstruction, rollback branch/epoch rules, migration interfaces | DataStore/MemoryStore or approved storage adapters, server shutdown hooks | DM recovery review surface later |
| W1 | Scene Runtime & Build Activation | published build binding, active build state, runtime snapshot composition, safe build swap/rebase policy | Roblox scene materialization bindings only where required; no Instance as authority | transition/fallback visual state via W7/C3 |
| W2 | Runtime Object & Entity Lifecycle | RuntimeObjectId/incarnation, lifecycle state machine, domain bindings, tombstone/archive rules | Instance binding/materializer, physics presence adapter, Collection/Workspace hooks if used | token/object representation via C3 |
| W3 | Spatial Query Runtime | typed query/request/result contracts, snapshot binding, provider composition, disclosure-safe evidence shape, budget/failure policy | raycast/overlap/collision/geometry providers backed by Workspace/physics | debug visualization only; gameplay feel consumers elsewhere |
| W4 | Visibility & Knowledge Runtime | detection/knowledge state, disclosure policy, perception evaluation using typed spatial evidence, negative-disclosure rules | no direct Workspace access; consumes W3 provider results | fog/hover readability via C1/C3 |
| W5 | Selection & Frozen Binding Runtime | candidate/session/targeting state machine, freeze/validate binding, stale-incarnation policy | pointer/focus world-ray input enters through C1→W3 adapters; no direct input service | selection outline/preview readability via C3 |
| W6 | Navigation & Movement Runtime | request/result, traversal policy, movement budget, occupancy/reservation contract, replan/failure/interruption/checkpoint state machine | PathfindingService/NavMesh, raycast/collision, dynamic obstacle and physics providers | path preview, click response, interpolation/movement feel |
| W7 | Scene Delivery & Ready Activation | interest sets, chunk manifest, prefetch/activation/eviction policy, essential-vs-optional readiness state machine | StreamingEnabled, Instance/material asset loading, client cache/materialization adapters | streaming veil, placeholder, loading clarity |
| R1 | Content & Ruleset Runtime | stable IDs, pack/dependency/version graph, frozen ruleset/policy composition, compile/catalog rules, locale identity separation | asset/content source adapters if Roblox asset metadata is required; persistence delegated A7 | content reader/authoring surfaces later |
| R2 | Capability & Derived Rule Query Runtime | grant graph, passive/override composition, derived values, effective capability, contextual availability and explanation contracts | none by default | action/context presentation through C1 |
| R3 | Rule Execution & Adjudication Runtime | persistent execution state machine, step/timing/reaction/prompt model, reservation orchestration, adjudication contract | monotonic timeout provider; network prompt delivery through A6 | prompt/reaction interaction UX through C1/C3 |
| R4 | Dice & Resolution Runtime | RollIntent/Plan, RNG provider interface, sealed result/record, d20/check/save/attack resolution, reveal-state contract | production RNG/entropy provider if runtime-specific; presentation ACK comes through C3 adapter | dice animation/reveal timing via C3 |
| R5 | Effect & Ongoing Runtime | EffectInstance state/lifecycle, duration binding, concentration, stacking/suppression/aura contribution model | spatial aura evidence via W3; no direct Workspace access | condition/aura presentation via C1/C3 |
| D1 | Character Runtime | source/build/state models, compile/activation/migration, resources, progression contracts | persistence adapter through A7 only | sheet/console surfaces through C1 |
| D2 | Encounter Runtime | participant/timeline/turn/opportunity/objective state machine, transition policy inputs | none by default | combat HUD/turn readability through C1/C3 |
| D3 | Inventory & Item Runtime | ItemInstance/container/equipment/location/transfer invariants, world-presence binding request | W2 materializes scene presence; persistence through A7 | inventory/loot UI through C1 |
| D4 | Game Time & Scheduler Runtime | campaign chronology, time advance plan, duration handles, scheduler, due-event checkpoint model | authority monotonic wall-clock adapter only for technical leases; gameplay time stays core | calendar/time display through C1 |
| D5 | Downtime & Activity Runtime | activity-session state, participants, progress, long reservation coordination, checkpoint/completion plan | none by default | rest/travel/crafting workflow surfaces through C1 |
| D6 | Journal Runtime | document/section/anchor/ACL/search/edit/conflict/navigation-capability model | persistence/search-storage adapter as needed through A7/external interface | journal reader/editor UI through C1 |
| D7 | Campaign Logistics Runtime | survival requirement/allocation/reservation/settlement/ledger plans | none by default | DM/player preview and ledger surfaces through C1 |
| U1 | Scene Authoring & Compiler | canonical source model, editor command semantics, source revision/conflict rules, semantic compiler pipeline, candidate/LKG/publish proposal | Roblox asset geometry/metadata inspection provider, runtime candidate test adapter using production E1 providers | actual Scene Editor tools/workspace and authoring feel after integration |
| U2 | Actor Authoring & Publish | draft schema/budgets, strict validation, reference resolution, candidate/publish definition, provenance | approved Roblox model/asset registry and appearance validation adapter | actor authoring/preview UI after integration |
| C1 | UI & Input Runtime | projection replica atomic commit, ViewModel/selectors, input-context/focus state machine, pending/result reconciliation, local workspace-state contracts | UserInputService/ContextActionService/Gui focus/Roblox UI adapter; no product shell yet | U0 Product UI Shell, layout, hierarchy, actual widgets and debug fixture controls |
| C2 | Camera Runtime | CameraRequest, priority/policy/focus/follow/free-override/restore state machine and target contracts | Roblox CurrentCamera adapter, camera collision provider via W3, input adapter via C1 | camera sensitivity, easing, obstruction recovery feel, accessibility tuning |
| C3 | Presentation Runtime | recipe schema/compiler, playback plan, priority/interrupt, marker/reveal-gate state machine, accessibility/fallback policy | Roblox animation/audio/VFX/tween/lighting/camera-request adapters | VFX timing, clarity, polish, reduced-motion feel |
| S1 | Diagnostics & Observability Runtime | trace/span/correlation, decision record, incident/budget model, redaction, support reference, sink interfaces | runtime metrics/sink adapters, Roblox memory/network measurements | developer/DM diagnostic surfaces later |
| S2 | Deterministic Simulation Harness | scenario compiler, fixture model, deterministic RNG/clock/ID/transport/storage adapters, interleaving/fault plan, semantic/security assertions | E1 production-parity Roblox integration harness adapter; does not replace core harness | human acceptance harness references only |

## 4. E0 Repository Core Engine 범위 후보

R3 기준으로 **33개 System 전부가 최소 하나 이상의 Core contract/policy seam을 가진다.** 이것은 33개 System의 모든 기능을 E0에서 완성한다는 뜻이 아니다.

E0의 목적은 다음이다.

```text
나중에 E1/P3/P6/P7/P8 기능을 붙일 때
공통 권위 경계와 public contract를 갈아엎지 않도록
필요한 Core foundation을 먼저 완성한다.
```

따라서 R4에서는 33개 전체를 한 번에 Module화하지 않는다.

R4가 골라야 할 것은:

```text
어떤 Core seam이 다른 대부분의 System보다 선행해야 하는가
어떤 Core seam은 미래 Phase까지 interface만 보존하고 구현을 미룰 수 있는가
```

## 5. R3에서 확인된 Foundation 우선 Core 후보

아래는 **R4 E0 Checkpoint 후보군**이지 아직 승인된 Checkpoint가 아니다.

### F0 Authority Kernel

```text
A1 Session/Control policy core
A2 Request contracts/runtime core
A3 Transaction/Ordering/Outbox core
A4 Cross-Domain Outcome seam
A5 Projection core
A6 Sync state-machine core
A7 persistence/recovery interfaces + epoch/revision lineage seam
S1 correlation/error/diagnostic seam
```

### F1 Identity / Snapshot / Query Kernel

```text
W1 Scene runtime build/snapshot contracts
W2 Runtime Object identity/lifecycle contracts
W3 typed Spatial Query contracts/provider interface
W4 visibility/disclosure evidence seam
```

### F2 Rule / Capability Kernel

```text
R1 frozen content/ruleset identity seam
R2 capability/derived-query contracts
R3 persistent RuleExecution state-machine seam
R4 Dice/Resolution contracts + RNG provider interface
R5 EffectInstance lifecycle contracts
```

### F3 Domain Foundation

```text
D1 Character source/build/state contracts
D2 Encounter/opportunity contracts
D3 Item/container/location contracts
D4 GameTime/scheduler contracts
D5 activity coordination contracts
```

여기서 `contracts`는 먼 미래 기능을 구현한다는 뜻이 아니다. E0에서 실제로 구현할 수준은 R4에서 scenario/future-pressure 기준으로 다시 최소화한다.

## 6. E1 Roblox Runtime Provider 후보

`CORE_ENGINE_COMPLETE` 이후에만 구체화한다.

```text
Remote Transport Adapter                       ← A2/A6
Player/Connection Adapter                      ← A1/A6
Storage Adapter                                ← A7
Runtime Object Instance/Physics Binder          ← W2
Spatial Raycast/Overlap/Collision Provider      ← W3
Navigation PathfindingService/NavMesh Provider  ← W6
Scene Streaming/Materialization Adapter         ← W7
Asset Geometry/Metadata Inspection Provider     ← U1/U2
Roblox Input/GUI Focus Adapter                  ← C1
Roblox Camera Adapter                           ← C2
Animation/Audio/VFX/Lighting Playback Adapter   ← C3
Runtime Metrics Adapter                         ← S1
Roblox Production-Parity Test Adapter           ← S2
```

이 목록의 이름은 Module/Manager 이름이 아니라 **Provider responsibility**다. 실제 Studio Controller/Manager 이름은 `CORE_ENGINE_COMPLETE` 후 E1 Checkpoint Freeze에서 정한다.

## 7. U0 / E2 Human-facing 경계

`INTEGRATION_READY` 이후:

```text
U0-A HTML/UI Reference Distillation
→ U0-B 전체 Product UI Shell
→ U0-C Human Shell Review
→ UI_SHELL_READY
```

그 뒤 E2에서 시스템을 실제 Product Surface에 JIT 연결한다.

Throwaway Test ScreenGui는 만들지 않는다. UI가 필요한 테스트는 Product Shell의 dev-mode Debug/Fixture Control을 사용한다.

Human-check 대상 예:

```text
Selection/hover readability
Path preview readability
Movement response/intent
Camera feel
Combat/character/inventory/journal hierarchy
DM workspace/scene editor usability
VFX/reveal timing
Loading/reconnect/recovery clarity
Accessibility/reduced-motion behavior
```

## 8. 금지되는 경계 위반

- Core System이 Roblox Instance를 권위 원본으로 사용.
- W3 이외 System이 편의를 위해 Workspace를 직접 순회해 spatial truth를 만듦.
- W6 Core가 PathfindingService 결과 형식을 public domain contract로 노출.
- C1 UI가 rule/permission/availability를 재계산.
- C2 Camera transform이 selection/visibility/rule authority를 변경.
- C3 Presentation failure가 gameplay transaction을 rollback.
- E1 Adapter가 Core Store를 직접 수정하는 별도 authority path 생성.
- 테스트를 위해 production Command/Transaction path를 우회하는 direct setter 생성.
- Core Engine 미완료 상태에서 Studio prototype으로 architecture를 사실상 확정.

## 9. Future Scenario Compatibility Check

R3 Matrix를 61 Scenario에 대조한 결과 다음 유형 모두에 Core→Runtime→Human 경계가 존재한다.

```text
join/reconnect/recovery
selection/visibility
camera local control
click/WASD movement
interaction
attack/reaction/dice/effect
character sheet/progression
inventory/equipment/item pickup
rest/travel/crafting
journal/search/edit/navigation
scene compile/test/publish/live patch
DM takeover/override/recovery
content migration
actor authoring/spawn
long-session recovery
```

특히 다음 미래 기능은 Core public contract 재작성 없이 Provider/Domain implementation을 추가할 수 있어야 한다.

```text
Character 1→20
Encounter full action economy
Official spell/content waves
Persistence/rollback production adapters
Survival logistics
DM-authored actor pipeline
Scene authoring tool expansion
```

## 10. R3 권장 결론

```text
Boundary Model = ACCEPTABLE_FOR_R4
Source = STILL BLOCKED
Studio = STILL BLOCKED
```

권장 다음 단계:

1. 이 Boundary Matrix를 사용자 승인.
2. 승인 후 R3를 `FROZEN`으로 승격.
3. R4에서 **Foundation Core Checkpoint만** JIT로 구체화.
4. R4가 끝난 뒤 Dedicated Implementation Branch 생성.
5. 그 Branch에서 E0 Core Engine 전체 구현.
6. `CORE_ENGINE_COMPLETE` 이후에만 E1 Studio Provider/Manager/Controller 구체화.
