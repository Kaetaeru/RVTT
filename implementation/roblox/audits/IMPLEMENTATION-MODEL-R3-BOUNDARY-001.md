# RVTT Implementation Model R3 Boundary Audit 001

- 상태: `REPAIRED · NON_FROZEN · USER_FREEZE_DECISION_REQUIRED`
- 작성일: 2026-08-13
- 대상: `R3 — Repository Logic / E0 Core / Roblox Runtime / Human Presentation Boundary`
- System Authority: `implementation/roblox/SYSTEMS.md` v2
- Machine-readable model: `implementation/roblox/manifests/implementation-system-model.json`
- 구현 상태: `SOURCE_BLOCKED · STUDIO_BLOCKED`

## 1. 목적

R2 이후 승인됐던 33-System 모델과 최초 R3 Matrix를 스스로 반대 입장에서 검토했고 다음 결함을 발견했다.

```text
Event Delivery owner 누락
REPOSITORY_LOGIC와 E0_CORE_ENGINE 의미 혼합
E1 Provider 선행 Core seam 누락
Capability와 System의 사실상 1:1 매핑
61 Scenario 새 trace의 비기계적 상태
Ready Gate 중복 소유
Reservation 의미 충돌
공통 nondeterministic provider 계약 불명확
Validator가 승인 문자열만 확인
```

이 Audit은 위 문제를 수정한 R3 경계를 기록한다. 아직 `FROZEN`이 아니며 Source/Studio 구현 권한을 열지 않는다.

## 2. 네 분류를 분리한다

### REPOSITORY_LOGIC

Roblox 없이 구현하고 correctness를 자동 검증할 수 있는 모든 production logic의 분류다.

### E0_CORE_ENGINE

Studio에 들어가기 전에 반드시 완성해야 하는 Repository Foundation subset이다.

```text
REPOSITORY_LOGIC ⊃ E0_CORE_ENGINE
```

따라서 미래 Journal/Logistics/Actor Authoring 로직이 Repository에서 구현 가능해도 자동으로 E0 완료 조건이 되지 않는다.

### E1_ROBLOX_RUNTIME

Roblox 서비스, geometry, physics, Player/Instance/Remote/Streaming/Input/Camera/asset 결과가 correctness의 일부인 Provider/Adapter다. `CORE_ENGINE_COMPLETE` 뒤에만 구현한다.

### HUMAN_PRESENTATION

실제 UI 구조, 가독성, VFX, Camera feel, 이동감처럼 사람이 실제 화면에서 판단해야 하는 결과다. Integration 뒤 U0/E2에서 다룬다.

## 3. 34-System 실행 경계 Matrix

| ID | E0 pre-Studio seam | E1 Roblox provider | Human/U0/E2 |
|---|---|---|---|
| A1 | role/control/mode/context/overlay/transition policy, readiness evidence composition, final Command gate | Player join/leave identity input adapter | mode/transition/ready messaging |
| A2 | Command/Read envelopes, schema/version, idempotency/correlation, result model, transport interface | Remote transport and connection binding | pending/retry/error wording |
| A3 | OrderingKey, OrderingReservation, typed preconditions, transaction plan/commit, revision, commit marker, transactional outbox | monotonic clock/lease adapter only as needed | none |
| A4 | immediate closure graph, deferred consequence model, budget/cycle rules, proposal composition | none by default | none |
| A5 | observer context, disclosure-safe projection build, snapshot/delta model | runtime state arrives only through public system contracts | readability belongs to C1/C3 |
| A6 | epoch/sequence/cursor/gap/resync state machine, `projectionSyncReady` evidence | Remote delivery, Roblox connection lifecycle, payload measurement | reconnect feedback via C1 |
| A7 | snapshot/journal schemas, reconstruction, rollback branch/epoch and integrity interfaces, `authorityRecoveryReady` evidence | DataStore/MemoryStore or approved storage adapter, shutdown hook | recovery review surface later |
| A8 | committed outbox dispatcher, subscription registry, ordering scope, retry/receipt/dead-letter semantics | durable/local delivery adapter if required | none |
| W1 | published build binding, active build state, runtime snapshot composition, safe swap policy | scene materialization binder where required | transition/fallback presentation |
| W2 | RuntimeObjectId/incarnation, lifecycle state machine, domain bindings, tombstone/archive | Instance/materializer/physics presence binding | token/object representation |
| W3 | typed spatial request/result, snapshot binding, provider composition, budget/failure semantics | Workspace raycast/overlap/collision/geometry providers | debug visualization only |
| W4 | visibility/detection/knowledge/disclosure policy using typed W3 evidence | no direct Workspace traversal | fog/hover readability |
| W5 | selection/targeting session, candidate policy, frozen binding, stale-incarnation rules | pointer/focus world-ray adapter enters through C1/W3 | selection/target preview readability |
| W6 | navigation request/result, planner/executor policy, movement budget, OccupancyReservation, replan/interruption/checkpoint | PathfindingService/NavMesh/raycast/collision/dynamic obstacle provider | path preview, click response, movement feel |
| W7 | interest/chunk/prefetch/activation/eviction policy, `sceneEssentialReady` evidence | StreamingEnabled, asset/chunk materialization/cache | veil/loading/placeholder clarity |
| R1 | stable IDs, pack dependency/version, frozen ruleset policy, compile/catalog contract | approved content/asset metadata adapter as required | content surfaces later |
| R2 | grant/passive/override composition, derived value/effective capability/context availability | none by default | action/context presentation |
| R3 | persistent execution/timing/reaction/prompt state machine, ResourceReservation orchestration | technical timeout provider and A6 prompt delivery | reaction/prompt UX |
| R4 | RollIntent/Plan, RNG interface, sealed result/record, d20/check/save/attack resolution | production RNG/entropy provider if runtime-specific | dice/reveal timing through C3 |
| R5 | EffectInstance lifecycle, duration binding, concentration, stacking/suppression/aura model | aura spatial evidence consumes W3 provider result | condition/aura presentation |
| D1 | minimal source/build/state/resource/progression ownership contracts required by shared rules | persistence only through A7 | sheet/console later |
| D2 | minimal participant/timeline/opportunity/objective contracts required by session/rules | none by default | combat HUD later |
| D3 | minimal Item/container/equipment/location/world-presence binding contracts | W2 materializes presence | inventory/loot later |
| D4 | campaign chronology, duration/scheduler contract; explicitly separate from monotonic clock | technical clock is not D4 | calendar/time display later |
| D5 | activity-session/participant/progress/ActivityReservation/completion-plan contracts | none by default | rest/travel/crafting workflow later |
| D6 | **deferred repository feature implementation**; preserve ownership/ACL/projection pressure only | optional storage/search adapter later | journal UI later |
| D7 | **deferred repository feature implementation**; preserve settlement/domain integration pressure only | none by default | logistics surfaces later |
| U1 | canonical scene source, editor command semantics, compile/candidate/LKG/publish contracts needed before E1 geometry inspection | Roblox asset geometry/metadata inspection and candidate runtime test adapter | actual Scene Editor later |
| U2 | **deferred repository feature implementation**; preserve draft/validation/publish ownership pressure | model/asset registry later | actor authoring UI later |
| C1 | projection replica atomic commit, ViewModel/selectors, input-context/focus/pending/recovery state machine, `clientReplicaReady` evidence | UserInputService/ContextActionService/Gui focus adapter; no product shell yet | U0 Product UI Shell and debug fixtures |
| C2 | CameraRequest priority/focus/follow/free/restore policy and target contracts | CurrentCamera/collision/input adapters | sensitivity/easing/obstruction feel |
| C3 | recipe/playback plan, priority/interrupt/marker/reveal/accessibility/fallback state machine | animation/audio/VFX/tween/lighting adapters | timing/clarity/polish/reduced motion |
| S1 | trace/span/correlation/decision/incident/redaction/sink interfaces | runtime metrics/network/memory adapters | developer/DM diagnostics later |
| S2 | scenario compiler, fixture contract, deterministic Clock/ID/RNG/Transport/Storage adapters, interleaving/fault/assertion foundation | production-parity Roblox integration harness adapter after E0 | human acceptance references only |

## 4. E0 Core Engine 완료 정의

Machine-readable `e0RequiredSystemSeams`는 다음 31 System의 **Foundation seam**을 R4에서 구체화할 대상으로 지정한다.

```text
A1 A2 A3 A4 A5 A6 A7 A8
W1 W2 W3 W4 W5 W6 W7
R1 R2 R3 R4 R5
D1 D2 D3 D4 D5
U1
C1 C2 C3
S1 S2
```

이것은 위 31 System의 모든 feature를 구현한다는 뜻이 아니다.

R4는 각 System에서 **E1 Provider 또는 여러 미래 기능이 공유하는 public seam만** Checkpoint로 Freeze한다.

현재 `CORE_ENGINE_COMPLETE` 필수 feature 구현에서 제외:

```text
D6 Journal full repository feature
D7 Campaign Logistics full repository feature
U2 Actor Authoring full repository feature
```

단, R4에서 실제 E1 선행 dependency가 증명되면 사용자 결정으로 승격한다.

## 5. Domain Event 경계 수정

기존 33-System에는 Transaction Outbox 이후의 책임 소유자가 없었다. 이를 A8로 분리한다.

```text
A3
Authority Mutation + DomainEventDraft + CommitMarker
→ atomic commit
→ CommittedDomainEvent in Outbox

A8
→ committed-only dispatch
→ SubscriptionDefinition
→ ordering scope
→ at-least-once delivery
→ SubscriberReceipt
→ retry / failure isolation / dead-letter

A5/S1/authorized follow-up subscriber
→ consume delivered event
```

불변식:

- Abort된 Event Draft는 A8에 보이지 않는다.
- Subscriber 실패가 A3 commit을 rollback하지 않는다.
- A8은 Store를 직접 수정하지 않는다.
- 후속 권위 변경은 새 Command/RuleExecution이다.
- Projection Subscriber는 Domain Event raw payload를 Client에 보내지 않는다.

## 6. Ready Gate 단일 소유

준비 상태를 `loaded=true` 하나로 합치지 않는다.

```text
A7 → authorityRecoveryReady
A6 → projectionSyncReady
W7 → sceneEssentialReady
C1 → clientReplicaReady

A1
→ required readiness evidence 조합
→ EffectiveGameplayReady
→ final gameplay Command gate
```

A6/A7/W7/C1은 증거를 만들 뿐 Gameplay Command를 직접 활성화하지 않는다.

## 7. Reservation Taxonomy

다섯 타입을 명시적으로 분리한다.

```text
OrderingReservation            A3   concurrency ordering, short-lived
ResourceReservation            R3   pending execution consumption right
OccupancyReservation           W6   movement-space coordination
ActivityReservation            D5   long-running activity hold
LogisticsAllocationReservation D7   settlement allocation hold
```

금지:

- 범용 `ReservationManager`로 수명주기 통합.
- ResourceReservation을 Ordering lock으로 사용.
- OccupancyReservation을 Authority transaction lock으로 사용.
- Domain reservation을 commit 전 실제 ownership transfer로 처리.

## 8. 공통 Provider Contract

각 System이 직접 `os.clock`, GUID, Random, Remote, DataStore를 선택하지 않는다.

```text
AuthorityMonotonicClock
DeterministicIdFactory
RngProvider
TransportAdapter
StorageAdapter
```

- technical monotonic time은 Campaign Game Time(D4)과 다르다.
- R4가 authoritative random outcome을 소유한다.
- A2/A6 transport semantics를 공유한다.
- A7 storage/recovery semantics를 소유한다.
- S2는 동일 contract의 deterministic test adapter를 제공한다.

## 9. Requirement Capability와 System 분리

최초 v2 Capability는 사실상 System label이었다. 이를 폐기하고 **Requirement Capability Catalog v3 = 30**으로 교체한다.

Requirement Capability는 제품/Architecture 결과를 나타내며 여러 System을 동시에 압박한다.

예:

```text
REQ_SESSION_PLAYABILITY
→ A1 + A6 + A7 + W7 + C1

REQ_COMMITTED_EVENT_PROPAGATION
→ A3 + A8 + A5 + A7 + S1

REQ_SELECTION_TARGETING
→ C1 + W3 + W4 + W5 + R2

REQ_RULE_EXECUTION_RESOLUTION
→ R2 + R3 + R4 + A4 + A3
```

전체 30개와 Authority sourceRefs는 `implementation-system-model.json`이 소유한다.

## 10. 61 Scenario Machine Trace

기존 Scenario 정의는 그대로 유지한다. Legacy `capabilityRefs`는 historical requirement vocabulary다.

새 canonical trace:

```text
Scenario ID
→ Requirement Capability[]
→ System[]
```

61/61 mapping은 `implementation-system-model.json`에 기록하며 Validator가 다음을 검사한다.

```text
legacy/base+expanded Scenario ID set == new Scenario Trace ID set
모든 systemRefs가 34-System set 안에 존재
모든 requirementCapabilityRefs가 30 Capability set 안에 존재
각 Scenario는 둘 다 non-empty
중복/누락 금지
```

대표 mutation Scenario에는 A8 Event Delivery가 명시되어야 한다.

## 11. Future Compatibility Pressure

R4/E0는 현재 Explorer vertical slice만 최적화하지 않는다.

최소 미래 압력:

```text
Character creation / level-up / sheet
Encounter / reaction / ready / death save
Inventory / equipment / consumables
Spell / dice / concentration / effects
Rest / travel / crafting / survival settlement
Journal / scene authoring / live DM
Content migration / actor authoring
Reconnect / restart / rollback / branch recovery
Streaming / accessibility / low-end fallback
```

미래 기능 자체는 구현하지 않되, 위 기능 때문에 공통 public boundary를 갈아엎어야 하는 R4 Checkpoint는 Freeze하지 않는다.

## 12. R3 결론

현재 결론:

```text
34-System Model v2 = REPAIRED
30 Requirement Capabilities v3 = ACTIVE
61 Scenario machine trace = PRESENT
REPOSITORY_LOGIC ≠ E0_CORE_ENGINE = DEFINED
Event Delivery / Ready / Reservation / Provider seams = DEFINED
Source = BLOCKED
Studio = BLOCKED
R3 = NOT FROZEN
```

다음은 **전체 Validator/CI를 한 번 돌려 repaired model을 self-validate**하는 것이다. 모두 통과한 뒤에만 사용자에게 R3 Freeze 여부를 다시 제안한다.

## 13. 후속 61 Scenario Semantic Audit v1

위 결론 뒤 후속 self-review에서 machine trace의 **형식적 유효성**과 **의미적 완전성**을 별도로 재검사했다. 기존 61 Scenario body의 steps, expectedOutcome, negativeCases를 기준으로 각 trace에 다음 의미 단계를 부여했다.

```text
READ
MUTATION
EVENT
PROJECTION
RECOVERY
HUMAN
```

불변식:

```text
MUTATION → A3 + REQ_ATOMIC_CONCURRENCY
EVENT → A3 + A8 + REQ_COMMITTED_EVENT_PROPAGATION
PROJECTION → A5 + A6 + REQ_VIEWER_SAFE_PROJECTION
RECOVERY → A6 또는 A7 + recovery/session requirement
HUMAN → C1/C2/C3/U1/U2 중 하나 이상
```

전수 감사에서 다음 유형의 누락을 수정했다.

```text
Actor/NPC publish+spawn
→ A3/A8 commit-event pressure 추가

Character migration / level-up / spell preparation
→ activation transaction/event/projection pressure 보완

Rollback stale command
→ authoritative projection rebuild pressure 보완

Ready action
→ transaction + projection pressure 보완

Rest / Craft / Travel restart negative cases
→ A7 recovery pressure 보완

Scene source commit / concurrent authoring
→ A2/A3/A8 command-transaction-event pressure 보완

DM takeover
→ controller assignment mutation/event pressure 보완

DM live patch rebase fail
→ atomic swap attempt이므로 A3 MUTATION pressure 유지,
   abort path이므로 EVENT는 강제하지 않음
```

최종 semantic stage 분포:

```text
READ       60
MUTATION   41
EVENT      41
PROJECTION 41
RECOVERY   17
HUMAN      33
```

Canonical semantic digest:

```text
sha256:57e485a0cec6d753542e4bc202a881e10e2bd5ae63e314cc609c7e2d99f38140
```

## 14. A8 / A7 Durability Reconciliation

Accepted Event 계약은 durable delivery class, Outbox Cursor, SubscriberReceipt, retry/dead-letter를 요구하고 Persistence 계약은 durable storage/reconstruction을 소유한다. 따라서 경계를 다음처럼 명확히 한다.

```text
A3
= Transactional Outbox atomicity + committed event fact

A8
= delivery / subscription / ordering / retry / SubscriberReceipt / dead-letter semantics

A7
= durable persistence + restart reconstruction mechanism

A8 delivery semantics → A7 durability seam → StorageAdapter
```

규칙:

- A8 durable cursor/receipt/dead-letter는 A7 persistence seam으로 저장·복구한다.
- A8은 `StorageAdapter`를 직접 사용하지 않는다.
- `STORAGE_ADAPTER` production consumer는 A7 하나다.
- A7은 A8의 SubscriptionDefinition, ordering scope, retry/failure policy를 소유하지 않는다.
- Subscriber durability failure가 A3에서 이미 Commit된 gameplay transaction을 rollback하지 않는다.

## 15. 후속 감사 결과

```text
Scenario Semantic Audit = V1 · 61/61
semantic digest = PASS
A8 delivery semantics → A7 durability seam = DEFINED
Source = BLOCKED
Studio = BLOCKED
R3 = NOT FROZEN
```

후속 감사 결과는 기존 1~12절을 덮어쓰지 않고 추가 증거로 보존한다. R3 Freeze는 사용자 결정으로만 수행한다.

## 16. Canonical Base Validator Reconciliation

Section 10의 `legacy/base+expanded` 문구는 당시 validator 상태를 보존한 역사적 기록이다. 현재 active coverage validator는 더 이상 legacy Base Scenario 사본을 active Base source로 사용하지 않는다.

현재 검증 경로:

```text
Base 14
→ scenario-base-catalog.json

Expanded 47
→ architecture-scenarios.json scenarios[]

Base 14 + Expanded 47 ID set
→ implementation-system-model.json scenarioTrace ID set과 exact match

architecture-coverage.json
→ authorityCorpus snapshot + historical Greenfield coverage evidence only
```

`architecture-scenarios.json.baseRegistry`도 `scenario-base-catalog.json`을 가리킨다. Expanded Scenario body의 의미는 변경하지 않았으며 source blob binding만 새 metadata blob에 맞춰 다시 묶었다.

```text
expandedScenarioBlobSha
93f275b373c9f88b12ed3078149ff562642a5b1d

combinedAuditDigest
sha256:2fa071defaa6ee6363378f9a31780f4d54328199fb4e21bc6eeae3c1b9e07bec
```

이 reconciliation은 System/Requirement/Scenario 의미, R3 상태, Source/Studio gate를 변경하지 않는다. 전체 CI 통과가 이 보정의 완료 조건이다.
