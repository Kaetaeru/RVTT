# RVTT Implementation Model R2 Scenario Pressure Audit 001

- 상태: `DRAFT · NON_AUTHORITY · USER_APPROVAL_REQUIRED`
- 작성일: 2026-08-13
- 대상: `R2 — 61 Scenario Pressure Review`
- 기준: 기존 Greenfield System/Module/Stable Function 모델을 사용하지 않고 Product/Accepted ADR/Current Architecture/Capability/Scenario에서 책임을 다시 도출한다.
- 구현 상태: `SOURCE_BLOCKED · STUDIO_BLOCKED`

## 1. 목적

이 감사는 R1의 27개 System 후보를 61개 End-to-End Scenario에 통과시켜 다음을 찾는다.

- 책임 소유자가 비는 경로
- 한 후보 System에 서로 다른 상태/수명주기/권위가 과도하게 합쳐진 경로
- 미래 기능 때문에 공통 public boundary를 다시 뜯어야 하는 경로
- Projection/Disclosure/Concurrency/Recovery/Presentation 책임 누락
- 기존 Greenfield 이름을 무의식적으로 다시 복원하는 경로

이 문서는 System Authority가 아니다. 아래 후보는 사용자 승인 전 구현 계약으로 사용할 수 없다.

## 2. R2 결론

```text
Scenario reviewed: 61 / 61
Scenario with empty responsibility path: 0
Old Greenfield module required as assumption: 0
R1 candidate systems: 27
Strong split findings: +6
R2 candidate systems: 33
Source implementation: BLOCKED
Studio implementation: BLOCKED
```

R1의 큰 방향은 유지되지만 27개 그대로 Freeze하면 다음 책임이 과결합된다.

1. Projection 생성과 Client Stream/Resync
2. Scene Build Activation과 Runtime Object Lifecycle
3. Campaign Game Time/Scheduler와 Downtime Activity
4. UI/Input, Camera, Presentation Playback
5. Diagnostics/Observability와 Deterministic Simulation Harness

따라서 R2 권장 System Model v1은 33개 후보로 조정한다.

## 3. R2 Candidate System Model v1

### Authority / Coordination

| ID | Candidate System | 핵심 책임 |
|---|---|---|
| A1 | Session & Control Policy | role/control/base mode/context/overlay/transition/ready command policy |
| A2 | Request Runtime | versioned Command + Read Request protocol/lifecycle. Mutation과 Read semantic path는 반드시 분리 |
| A3 | Transaction, Ordering & Outbox Runtime | ordering/reservation/precondition/atomic commit/revision/journal marker/outbox |
| A4 | Cross-Domain Outcome Integration | Immediate Closure와 Deferred Consequence 조정. Domain Store를 직접 소유하지 않음 |
| A5 | Projection Runtime | viewer context, disclosure input, projection build/delta/snapshot model |
| A6 | Client Synchronization Runtime | stream sequence/cursor/snapshot transfer/gap detection/resync/connection epoch |
| A7 | Persistence & Branch Recovery | durable snapshot/journal/restart/rollback/branch/authority epoch reconstruction |

### World Runtime

| ID | Candidate System | 핵심 책임 |
|---|---|---|
| W1 | Scene Runtime & Build Activation | published compiled build binding, active scene snapshot/build swap/runtime scene activation |
| W2 | Runtime Object & Entity Lifecycle | RuntimeObjectId/incarnation/presence/spawn/archive/destroy/domain bindings |
| W3 | Spatial Query Runtime | snapshot-bound typed spatial evidence/query |
| W4 | Visibility & Knowledge Runtime | detection/knowledge/disclosure relation and negative-disclosure evidence |
| W5 | Selection & Frozen Binding Runtime | candidate/session/targeting/preview boundary/execution-bound frozen binding |
| W6 | Navigation & Movement Runtime | plan/approval/budget/occupancy/replan/execution/checkpoints |
| W7 | Scene Delivery & Ready Activation | server/client artifact interest/chunk materialization/prefetch/ready gate |

### Rules Runtime

| ID | Candidate System | 핵심 책임 |
|---|---|---|
| R1 | Content & Ruleset Runtime | trusted definitions/packs/version/frozen policy snapshot/compile inputs/localization identity |
| R2 | Capability & Derived Rule Query Runtime | grants/passives/overrides/derived values/effective capability/current availability query |
| R3 | Rule Execution & Adjudication Runtime | persistent execution/timing/reaction/prompt/resource reservation/DM adjudication |
| R4 | Dice & Resolution Runtime | RollIntent/RollPlan/server RNG/sealed result/reveal/RollRecord/outcome |
| R5 | Effect & Ongoing Runtime | EffectInstance/condition/duration/concentration/aura/suppression/lifecycle |

### Gameplay Domains

| ID | Candidate System | 핵심 책임 |
|---|---|---|
| D1 | Character Runtime | character source/compiled build/persistent state/resources/progression activation |
| D2 | Encounter Runtime | participants/timeline/turn/action opportunity/reaction opportunity/objective |
| D3 | Inventory & Item Runtime | ItemInstance/container/equipment/location/world-presence binding |
| D4 | Game Time & Scheduler Runtime | campaign chronology/time advance/duration handles/scheduled due candidates |
| D5 | Downtime & Activity Runtime | multi-participant activity windows/progress/reservations/checkpoints/domain completion coordination |
| D6 | Journal Runtime | document source/sections/anchors/ACL/search/backlink/edit/navigation capability |
| D7 | Campaign Logistics Runtime | survival requirements/allocation/reservation/settlement/ledger |

### Authoring

| ID | Candidate System | 핵심 책임 |
|---|---|---|
| U1 | Scene Authoring & Compiler | canonical scene source/editor commands/validation/candidate compile/test/LKG/publish proposal |
| U2 | Actor Authoring & Publish | statblock/model draft/strict validation/campaign-local publish/spawn definition |

### Client / Presentation

| ID | Candidate System | 핵심 책임 |
|---|---|---|
| C1 | UI & Input Runtime | projection replica/view model/panel lifecycle/semantic input context/focus/pending UI/recovery |
| C2 | Camera Runtime | CameraRequest/policy/focus/follow/free override/restore/local camera projection |
| C3 | Presentation Runtime | presentation source/compiler/recipe/playback/priority/marker/reveal gate/accessibility/fallback |

### Support

| ID | Candidate System | 핵심 책임 |
|---|---|---|
| S1 | Diagnostics & Observability Runtime | trace/span/decision record/incident/budget/redaction/support reference |
| S2 | Deterministic Simulation Harness | scenario/fixture/controlled adapters/interleaving/fault injection/assertion/regression artifacts |

## 4. Strong Split Findings

### F1 — Projection Runtime ≠ Client Synchronization Runtime

`SCN_DM_PLAYER_VIEW_PREVIEW`는 네트워크 전송 없이 실제 viewer context로 Projection Builder를 실행해야 한다. 반면 `SCN_PROJECTION_GAP_RESYNC`와 `SCN_PENDING_RESULT_PROJECTION_REORDER`는 sequence/cursor/snapshot/resync 문제다.

따라서:

```text
Authority State + Viewer Context
→ A5 Projection Runtime
→ viewer-safe Projection
→ A6 Client Synchronization Runtime
→ ordered delivery / snapshot / resync
→ C1 UI Replica
```

Projection을 Sync transport 안에 넣지 않는다.

### F2 — Scene Runtime ≠ Runtime Object Lifecycle

Scene Build는 immutable compiled definition과 active build pointer를 다루지만 Runtime Object는 spawn/archive/destroy/incarnation과 domain binding을 가진다.

`SCN_NPC_PUBLISH_SPAWN_CONTROL`, `SCN_ITEM_PICKUP`, summon/effect-created presence는 Scene Source Object가 아니어도 Runtime Object가 필요하다.

따라서 W1과 W2를 분리한다.

### F3 — Game Time/Scheduler ≠ Downtime Activity

Game Time은 campaign chronology와 scheduler를 소유한다. Downtime은 rest/travel/crafting/level-up 같은 Activity Session과 multi-participant coordination을 소유한다.

`SCN_SHORT_REST_INTERRUPTED`, `SCN_CRAFT_ITEM_ATOMIC_COMPLETION`, `SCN_TRAVEL_HAZARD_INTERRUPT_RESUME`는 두 책임을 동시에 사용하지만 동일 책임은 아니다.

따라서 D4와 D5를 분리한다.

### F4 — UI/Input ≠ Camera ≠ Presentation

UI Architecture는 Camera final policy와 Presentation Playback을 UI 소유에서 명시적으로 제외한다.

`SCN_CAMERA_LOCAL_CONTROL`은 C2만으로 Authority Command 없이 성립할 수 있다.
`SCN_ACCESSIBILITY_REDUCED_MOTION`은 C3의 playback policy와 C2의 camera hard limit을 함께 사용한다.
Dice reveal은 C3 marker/reveal gate를 사용하지만 Dice outcome 자체는 R4가 소유한다.

따라서 기존 `Client Experience Runtime` 하나를 C1/C2/C3으로 분리한다.

### F5 — Diagnostics Runtime ≠ Simulation Harness

S1은 production runtime의 비권위 observability plane이다. S2는 production path를 실행하되 RNG/Clock/Transport/Storage/Presentation adapter를 통제하는 test runtime이다.

Simulation은 Diagnostics hook을 소비하지만 동일 수명주기나 배포 책임이 아니다.

따라서 S1/S2를 분리한다.

## 5. 유지 판단

### K1 — Command와 Read는 한 Request Runtime 후보에 유지

System은 A2 하나로 유지하되 다음 경계는 비협상이다.

```text
Command
→ mutation-capable intent
→ authorization/domain execution/transaction

Read Request
→ snapshot-bound non-mutating query
→ never executes Command or writes state
```

Remote/Lane 공유 가능성은 구현 세부사항이며 semantic handler를 합치지 않는다.

### K2 — Persistence와 Branch Recovery는 한 System 후보에 유지

Snapshot, Commit Journal, restart reconstruction, rollback branch와 new AuthorityEpoch는 하나의 durable lineage를 공유한다.

Client reconnect/resync 자체는 A6가 소유하고 A7은 authoritative state reconstruction을 소유한다.

### K3 — Capability와 Derived Rule Query는 한 System 후보에 유지

R2는 파생/질의 책임이다. 다음 mutable state를 소유하지 않는다.

- Encounter Action Opportunity → D2
- Character persistent resources → D1
- Item/Equipment state → D3
- EffectInstance → R5
- Session role/control/mode → A1

R2는 이 입력들을 읽어 Effective Capability/Availability/Derived Value를 계산한다.

### K4 — Scene Authoring과 Compiler는 한 Authoring System 후보에 유지

Scene Source/Candidate/LKG/Compile Diagnostic/Publish Proposal은 하나의 authoring lineage다.

단, 실제 active runtime build swap은 W1이고 durable published pointer commit은 A3/A7 contract를 사용한다.

### K5 — Actor Authoring은 Content Runtime과 분리 유지

U2는 untrusted user/AI draft, strict schema validation, campaign-local publish라는 authoring lifecycle을 가진다.
R1은 trusted/versioned content and ruleset catalog를 제공하며 U2의 draft state를 소유하지 않는다.

## 6. 61 Scenario Pressure Map

표의 System ID는 해당 Scenario가 통과해야 하는 주요 책임 경로다. 모든 내부 helper를 나열한 것이 아니다.

### Base 14

| Scenario | Candidate pressure path |
|---|---|
| SCN_JOIN_RECONNECT_ACTIVE_SCENE | A1 → A7 → W1/W7 → A5/A6 → C1 |
| SCN_SELECT_VISIBLE_ACTOR | C1 → W3/W4 → W5 → W2 |
| SCN_CAMERA_LOCAL_CONTROL | C1 → C2 |
| SCN_CLICK_MOVE_WITH_PATH | C1 → W5/W3 → W6 → A3 → A5/A6 → C3/C1 |
| SCN_EXPLORATION_WASD_MOVE | C1/A1 → W6/W3/W2 → A3 → A5/A6 |
| SCN_CONTEXT_INTERACTION | W5/W3 → R2 → R3 → A3 → A5/A6 |
| SCN_CHARACTER_CONSOLE_DASH | D1/D2 → R2 → C1 → R3 → A3 → A5/A6 |
| SCN_HIDDEN_OBJECT_NONDISCLOSURE | W3/W4 → W5/R2 → A5 → A6/C1 |
| SCN_CONCURRENT_DOOR_INTERACTION | A2 → W2/R2/R3 → A3 → A5/A6 |
| SCN_ATTACK_REACTION_RESOLUTION | W5/R2 → R3 → R4 → A4 → D1/D2/R5 → A3 → A5/A6/C3 |
| SCN_ITEM_PICKUP | W2/R2 → D3 → A3 → A5/A6 |
| SCN_ROLLBACK_THEN_STALE_COMMAND | A7 → A6/A1 → A2/C1/W5 stale rejection |
| SCN_SURVIVAL_SETTLEMENT | D4/D7/D3 → A4 → A3 → A5/A6 |
| SCN_DM_ACTOR_DRAFT_PUBLISH_SPAWN | U2/R1 → W2 → R2/A1 → A5/A6 |

### Expanded 47

| Scenario | Candidate pressure path |
|---|---|
| SCN_CHARACTER_CREATE_LEVEL1 | C1 → D1/R1/R2 → A3 → A5/A6 |
| SCN_CHARACTER_SHEET_LIVE_DAMAGE_SYNC | D1/A3 → A5/A6 → C1 |
| SCN_CHARACTER_SHEET_VIEWER_PRIVACY | D1/W4 → A5/A6 → C1 |
| SCN_LEVEL_UP_ATOMIC_ACTIVATION | D5/D4 → D1/R1 → A3/A7 → A5/A6 |
| SCN_CHARACTER_MIGRATION_MISSING_CONTENT | R1/D1 → A7 → C1 |
| SCN_CHANGE_SPELL_PREPARATION | D5/D1 → R2 → A3 → A5/A6 |
| SCN_SPELLBOOK_COPY_AND_TRANSFER | D5/D1/D3 → A3 → A5/A6 |
| SCN_ABILITY_CHECK_WITH_HIDDEN_DC | R2/D1/W4 → R3 → R4 → A5/A6 |
| SCN_BASIC_ATTACK_DAMAGE_COMMIT | W5/W3/R2 → R3 → R4 → A4 → D1/R5 → A3 → A5/A6/C3 |
| SCN_ZERO_HP_DEATH_SAVE_RECOVERY | D1/R5/D2 → R3/R4 → A4/A3 → A5/A6 |
| SCN_CONCENTRATION_DAMAGE_CHECK | D1/R5 → A4 → R3/R4 → A3 → A5/A6 |
| SCN_READY_ACTION_TRIGGER | D2/R2 → R3 → W5 → R3 child execution → A3 |
| SCN_ENCOUNTER_LATE_JOIN | D2/A1/W4 → A3 → A5/A6 |
| SCN_ENCOUNTER_END_RETURN_EXPLORATION | D2/R3/A1 → A4/A3 → R2 → A5/A6/C1 |
| SCN_EQUIP_WEAPON_UPDATES_ACTIONS | D3/D1 → A4/A3 → R2 → A5/A6 |
| SCN_UNIDENTIFIED_ITEM_DISCLOSURE | D3/W4 → A5/A6 → C1 |
| SCN_STACK_SPLIT_TRANSFER_CONFLICT | A2 → D3 → A3 |
| SCN_SHORT_REST_INTERRUPTED | D5/D4 → D1/R3/D2 → A4/A3/A7 |
| SCN_LONG_REST_PARTICIPANT_DIFFERENCE | D5/D4/D1 → A3 → A5/A6 |
| SCN_CRAFT_ITEM_ATOMIC_COMPLETION | D5/D4/R1/D3 → A4/A3 |
| SCN_TRAVEL_HAZARD_INTERRUPT_RESUME | D5/D4/D7 → D2/A1 → W1/W7 → A3 |
| SCN_PROJECTION_GAP_RESYNC | A5 → A6 gap/resync → A1 gate → C1 |
| SCN_INPUT_CONTEXT_MODAL_BLOCKS_GAMEPLAY | A1 projection → C1 input context/focus |
| SCN_PENDING_RESULT_PROJECTION_REORDER | A2 → A3/A5 → A6 correlation → C1 reconciliation |
| SCN_ACCESSIBILITY_REDUCED_MOTION | A5 → C3 accessible playback + C2 hard camera limit + C1 preference |
| SCN_JOURNAL_SECRET_SEARCH_NONDISCLOSURE | D6/W4 → A5 → A6/C1 |
| SCN_JOURNAL_WORLD_LINK_NAVIGATION | D6 → W5/W7/A1 → C2/C1 |
| SCN_JOURNAL_EDIT_CONFLICT | A2 → D6 → A3 → compile/LKG inside D6 authoring lineage |
| SCN_POINT_PATH_PING_AUDIENCE | C1 → W3/W4 → A2 policy/rate limit → C3 signal |
| SCN_SCENE_DRAFT_COMPILE_FAIL_LKG | C1/U1 → R1/providers → S1 → keep W1 published LKG |
| SCN_SCENE_CANDIDATE_TEST_PUBLISH | U1 → S2 using W1/W2/W3/W4/W6/W7 → A3 publish → W1 future activation |
| SCN_SCENE_CONCURRENT_EDIT_CONFLICT | C1/A2 → U1 → A3 conflict/revision |
| SCN_DM_PLAYER_VIEW_PREVIEW | A1 viewer context + W4 → A5 real projection builder → C1 preview |
| SCN_DM_TAKEOVER_DISCONNECTED_ACTOR | A1 → R2 → A5/A6 → C1 |
| SCN_DM_QUICK_ACTION_HP_CONDITION | C1/A2 → R3/D1/R5 → A3 mandatory audit → A5/A6/S1 |
| SCN_DM_RUNTIME_EDIT_SOURCE_PROMOTION | W2/W1 runtime override → U1 source proposal → compile/test → A3 publish |
| SCN_DM_LIVE_PATCH_REBASE_FAIL | U1 candidate → A1 gate → W7 ready → W1/W2 rebase → retain LKG → A6/C1 |
| SCN_DM_RECOVERY_REVIEW_BRANCH | A7 candidates/branch → S1 diagnostic view → A1/A6 full resync → A5/C1 |
| SCN_CONTENT_LOCALE_CHANGE_NO_RULE_CHANGE | R1 stable ids/version + C1 locale + R3 frozen execution |
| SCN_CONTENT_PACK_DEPENDENCY_FAILURE | R1 compile/activation candidate → S1/S2 validation → retain active catalog |
| SCN_CONTENT_PACK_REMOVAL_IN_USE | R1 reference scan across D1/D3/D6/U1/U2/R3 → A7 migration lineage → A3 activation |
| SCN_OFFICIAL_CHARACTER_OPTION_LEVEL_1_TO_20 | R1 → D1 → R2 → S2 scenario coverage |
| SCN_SPELL_CAST_TARGET_RESOURCE_CONCENTRATION | R2/W5/W3 → R3 → R4/R5 → A4 → D1 → A3 → A5/A6/C3 |
| SCN_CONSUMABLE_CANCEL_RELEASE_RESERVATION | D3/R2 → R3 reservation → A3 commit/release → A5/A6 |
| SCN_NPC_JSON_IMPORT_REJECT_CODE | C1/U2 → R1 reference validation → S1 diagnostics; no active mutation |
| SCN_NPC_PUBLISH_SPAWN_CONTROL | U2 → W2 → A1/R2 → D2 optional → A5/A6 |
| SCN_FULL_SESSION_CROSS_SYSTEM_RECOVERY | A1/A2/A3/A4/A5/A6/A7 + W*/R*/D* → S1/S2 integrated evidence |

## 7. Capability Catalog Pressure

현재 22 Capability는 R2의 입력 데이터로 유효하지만 최종 System Model을 표현하기에는 일부가 과도하게 합쳐져 있거나 누락되어 있다.

사용자 승인 후 다음 refactor를 검토해야 한다. 아직 적용하지 않는다.

```text
CAP_PROJECTION_DISCLOSURE_SYNC
→ Projection Runtime
+ Client Synchronization

CAP_RUNTIME_OBJECT_SCENE_IDENTITY
→ Scene Runtime / Build Activation
+ Runtime Object / Entity Lifecycle

CAP_TIME_DOWNTIME_PERSISTENCE
→ Game Time / Scheduler
+ Downtime / Activity
+ Persistence / Branch Recovery

CAP_UI_PRESENTATION_CAMERA
→ UI / Input
+ Camera
+ Presentation Playback

CAP_DIAGNOSTICS_SIMULATION_TESTING
→ Diagnostics / Observability
+ Deterministic Simulation Harness
```

현재 Catalog에 독립 Capability로 명확히 추가 검토할 책임:

```text
Dice / Resolution
Effect / Ongoing
Cross-Domain Outcome Integration
Scene Authoring / Compilation / Publish
Scene Delivery / Ready Activation
```

Capability 이름/ID는 사용자 승인 전 만들지 않는다.

## 8. R3 진입 전 필요한 결정

R2 권장안:

```text
System Model v1 candidate = 33 systems
```

이 숫자는 Manager/Module 수가 아니다. System은 책임/상태/권위 경계이며 실제 Module/Stable Function은 R4 E0 Checkpoint 직전에 JIT로 만든다.

사용자 승인 전 금지:

- 이 33개 후보를 ACTIVE System Authority로 승격
- Capability Catalog ID 추가/분할
- System → Module mapping 생성
- Stable Function 정의
- Source 구현
- Studio/MCP 구현

사용자 승인 후 다음 순서:

```text
System Model v1 승인
→ Capability Catalog를 새 System Model에 맞춰 model-neutral하게 정리
→ 61 Scenario를 새 Capability/System trace로 재검증
→ R3 Core / Roblox Runtime / Presentation Boundary Freeze
```
