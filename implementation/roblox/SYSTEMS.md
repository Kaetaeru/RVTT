# RVTT System Model v2

- 상태: `ACTIVE · APPROVED_SYSTEM_AUTHORITY · R3_REPAIRED_PENDING_FREEZE`
- R3 validation: `VALIDATED · AWAITING_USER_FREEZE_DECISION`
- Source 구현: `BLOCKED`
- Studio/MCP 구현: `BLOCKED`
- Direct model: `manifests/implementation-system-model.json`
- Semantic classification evidence: `manifests/scenario-semantic-audit.json` (v2)
- Effective Scenario audit: `manifests/scenario-semantic-audit-v3.json`

이 문서는 폐기된 Greenfield System/Module/Stable Function 모델을 대체하는 현재 구현 System 권위다. System은 Manager/Controller/ModuleScript 개수가 아니라 제품 전체의 책임·상태·권위 경계다.

## 1. 비협상 원칙

```text
Product / Accepted ADR / Current Architecture / UI
→ Requirement Capability
↔ Clean Scenario sources: Base 14 + Expanded 47
→ 34 System Responsibility Model
→ Scenario Semantic Audit v1 direct-stage base
→ Scenario Semantic Audit v2 classification/schema evidence
→ Scenario Semantic Audit v3 clean-source binding
→ R3 execution boundary
→ R4 E0 checkpoint
→ Source / Test / Runtime / Human evidence
```

- Requirement Capability와 System은 many-to-many다.
- 모든 권위 domain/source mutation은 A3 Transaction 경계를 통한다.
- A3 Outbox와 A8 Event Delivery를 합치지 않는다.
- A5 Projection과 A6 Synchronization을 합치지 않는다.
- A1만 final EffectiveGameplayReady / Command gate를 연다.
- Domain은 다른 Domain Store를 직접 수정하지 않는다.
- `REPOSITORY_LOGIC != E0_CORE_ENGINE`이다.
- **Repository Core Engine 전체 완료 전 Studio/MCP 구현을 시작하지 않는다.**

## 2. 34 System Responsibility Model

| ID | System | 핵심 책임 |
|---|---|---|
| A1 | Session & Control Policy | role/control/mode/context/transition, final ready/command gate |
| A2 | Request Runtime | versioned Command/Read lifecycle, validation, idempotency/correlation |
| A3 | Transaction, Ordering & Outbox Runtime | ordering, typed precondition, atomic commit, revision, transactional outbox |
| A4 | Cross-Domain Outcome Integration | immediate closure / deferred consequence coordination |
| A5 | Projection Runtime | viewer context, disclosure-safe projection build |
| A6 | Client Synchronization Runtime | epoch/sequence/cursor/snapshot/gap/resync |
| A7 | Persistence & Branch Recovery | durable lineage, restart reconstruction, rollback branch/epoch |
| A8 | Domain Event Delivery Runtime | committed delivery, subscription, retry, receipt, dead-letter isolation |
| W1 | Scene Runtime & Build Activation | active compiled build binding / runtime scene activation |
| W2 | Runtime Object & Entity Lifecycle | RuntimeObject identity/incarnation/presence/lifecycle |
| W3 | Spatial Query Runtime | snapshot-bound typed spatial evidence |
| W4 | Visibility & Knowledge Runtime | detection/knowledge/disclosure eligibility |
| W5 | Selection & Frozen Binding Runtime | selection/targeting/frozen execution binding |
| W6 | Navigation & Movement Runtime | path policy, movement budget, occupancy/replan/checkpoint |
| W7 | Scene Delivery & Ready Activation | artifact interest/materialization and sceneEssentialReady |
| R1 | Content & Ruleset Runtime | trusted definitions/version/frozen ruleset inputs |
| R2 | Capability & Derived Rule Query Runtime | grants/modifiers/effective capability/action availability |
| R3 | Rule Execution & Adjudication Runtime | persistent execution/timing/reaction/prompt/resource reservation |
| R4 | Dice & Resolution Runtime | RollPlan/RNG/sealed result/RollRecord/outcome |
| R5 | Effect & Ongoing Runtime | EffectInstance/condition/duration/concentration/aura |
| D1 | Character Runtime | character source/build/persistent state/progression |
| D2 | Encounter Runtime | participants/timeline/turn/opportunity/objective |
| D3 | Inventory & Item Runtime | item/container/equipment/ownership/location |
| D4 | Game Time & Scheduler Runtime | campaign chronology/scheduler/due candidates |
| D5 | Downtime & Activity Runtime | activity progress/checkpoints/ActivityReservation |
| D6 | Journal Runtime | documents/sections/ACL/search/edit/navigation |
| D7 | Campaign Logistics Runtime | survival allocation/reservation/settlement/ledger |
| U1 | Scene Authoring & Compiler | canonical source/candidate compile/test/LKG/publish proposal |
| U2 | Actor Authoring & Publish | actor draft/validation/campaign-local publish |
| C1 | UI & Input Runtime | replica/ViewModel/input context/focus/pending/recovery state |
| C2 | Camera Runtime | request/focus/follow/free/restore policy |
| C3 | Presentation Runtime | recipe/playback/priority/reveal/accessibility/fallback |
| S1 | Diagnostics & Observability Runtime | trace/decision/incident/budget/redaction |
| S2 | Deterministic Simulation Harness | deterministic adapters/interleaving/fault/scenario evidence |

## 3. 핵심 흐름

```text
Client Intent
→ C1
→ A2 Request Runtime
→ A1 policy
→ Rule / Domain
→ A4 when cross-domain closure is required
→ A3 Ordering + Transaction + Outbox atomic commit
→ A8 Event Delivery
→ A5 Projection
→ A6 Synchronization
→ C1 replica/view model
→ C2/C3 when presentation is needed
```

A8 Handler가 상태를 바꾸려면 새 Command/RuleExecution을 제출한다. A8은 Store나 A3 internals를 직접 수정하지 않는다.

```text
A3 = outbox atomicity + committed event fact
A8 = delivery/subscription/retry/receipt/dead-letter semantics
A7 = durable persistence + restart reconstruction mechanism
A8 delivery semantics → A7 durability seam → StorageAdapter
```

## 4. Ready / Reservation / Provider

```text
A7 authorityRecoveryReady
A6 projectionSyncReady
W7 sceneEssentialReady
C1 clientReplicaReady
→ A1 EffectiveGameplayReady
```

```text
OrderingReservation → A3
ResourceReservation → R3
OccupancyReservation → W6
ActivityReservation → D5
LogisticsAllocationReservation → D7
```

```text
AuthorityMonotonicClock
DeterministicIdFactory
RngProvider
TransportAdapter
StorageAdapter
```

## 5. Requirement Capability Catalog v3

30 Requirement Capability가 34 System을 many-to-many로 압박한다. Canonical ID/source/system refs는 `implementation-system-model.json`이 소유한다. Capability는 System 이름의 별칭이 아니다.

## 6. Scenario Semantic Audit

Clean Base 14 + Clean Expanded 47 = 61 Scenario다.

- `scenario-base-catalog.json`: canonical Base 14 body.
- `scenario-expanded-catalog.json`: canonical Expanded 47 body.
- `architecture-coverage.json`, `architecture-scenarios.json`: historical Greenfield evidence only.

`implementation-system-model.json`의 **Scenario Semantic Audit v1 · 61/61**은 direct `Requirement/System/semanticStages` base layer다. 이것만으로 완전한 R3 audit이라고 부르지 않는다.

v2 `scenario-semantic-audit.json`은 61개 entry/recovery classification, mutation semantic, ingress/recovery expansion, LKG owner set과 semantic schema를 보존하는 immutable evidence다.

현재 완전한 R3 semantic audit 권위는 **v3 `scenario-semantic-audit-v3.json`**이다. v3는 clean Base/Expanded blobs, v1 direct trace, immutable v2 audit blob, v2 semantic schema digest를 묶는다.

현재 typed recovery Scenario는 **27개**다. 특히 다음 누락을 다시 막는다.

```text
SCN_ATTACK_REACTION_RESOLUTION → RECONNECT
SCN_CHARACTER_SHEET_LIVE_DAMAGE_SYNC → CLIENT_RESYNC
SCN_SCENE_CANDIDATE_TEST_PUBLISH → LAST_KNOWN_GOOD
SCN_DM_RECOVERY_REVIEW_BRANCH → SERVER_RESTART + ROLLBACK_BRANCH + CLIENT_RESYNC
```

Ingress는 System과 Requirement를 함께 강제한다.

```text
COMMAND → A2 + A1 + REQ_REQUEST_PROTOCOL + REQ_CONTROL_PERMISSION
READ_REQUEST → A2 + REQ_REQUEST_PROTOCOL
SYNC_CONTROL → A6 + A1 + REQ_SESSION_PLAYABILITY
EVENT_TRIGGER → A8 + REQ_COMMITTED_EVENT_PROPAGATION
TEST_HARNESS → S2 + REQ_DIAGNOSTICS_REPRODUCIBILITY
```

`MUTATION`은 A3 transactional authoritative domain/source commit 또는 atomic commit attempt를 뜻한다. 모든 transient RuleExecution/Roll/Event/client-local record를 뜻하지 않는다.

## 7. E0 / Studio 순서

```text
R3 validation complete
→ 사용자 R3 Freeze
→ R4 E0 Checkpoint Freeze
→ Dedicated Implementation Branch
→ E0 Core Engine 구현/자동 검증
→ CORE_ENGINE_COMPLETE
→ E1 Runtime Checkpoint Freeze
→ Studio/MCP Runtime Provider + Integration
→ INTEGRATION_READY
→ U0-A HTML/UI Reference Distillation
→ U0-B Product UI Shell Scaffold
→ U0-C Human Shell Review
→ UI_SHELL_READY
→ E2
```

D6/D7/U2 전체 feature implementation은 현재 CORE_ENGINE_COMPLETE 필수가 아니다. E1 Provider가 소비할 Core contract/policy/state-machine은 반드시 E0에서 먼저 완성한다.
