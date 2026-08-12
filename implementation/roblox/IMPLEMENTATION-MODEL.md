# RVTT Implementation Model

- 상태: `ACTIVE · SYSTEM_MODEL_V2_REPAIRED · R3_VALIDATED_AWAITING_FREEZE_DECISION`
- System Authority: `SYSTEMS.md`
- Canonical Base Scenario source: `manifests/scenario-base-catalog.json`
- Canonical Expanded Scenario source: `manifests/scenario-expanded-catalog.json`
- Historical Expanded evidence: `manifests/architecture-scenarios.json`
- Direct model: `manifests/implementation-system-model.json`
- Semantic classification evidence: `manifests/scenario-semantic-audit.json` (v2)
- Effective Scenario audit: `manifests/scenario-semantic-audit-v3.json`
- Source 구현: `FORBIDDEN`
- Studio/MCP 구현: `FORBIDDEN`

## 1. 현재 기준

폐기된 Greenfield `25 modules / 10 systems / 64 stable functions / G0~G5 / WorldState.transact 중심 모델`은 새 구현의 출발점이 아니다.

```text
SYSTEM MODEL = V2 · 34 SYSTEMS · REPAIRED
REQUIREMENT CAPABILITY = V3 · 30 · MANY-TO-MANY
DIRECT SCENARIO TRACE = 61/61
Scenario Semantic Audit = V1 · 61/61 direct-stage base
SEMANTIC CLASSIFICATION = V2 · VALIDATED EVIDENCE
SEMANTIC AUDIT = V3 · VALIDATED · CLEAN SOURCE BOUND
EFFECTIVE RECOVERY SCENARIOS = 27
R3 = NOT FROZEN · VALIDATED_AWAITING_FREEZE_DECISION
SOURCE = BLOCKED
STUDIO/MCP = BLOCKED
DEDICATED IMPLEMENTATION BRANCH = NOT YET CREATED
```

v1은 `implementation-system-model.json`의 direct stage layer다. v2 `scenario-semantic-audit.json`은 61개 entry/recovery classification과 semantic schema의 immutable evidence다. 현재 완전한 R3 Scenario audit 권위는 clean Scenario sources와 v2 evidence를 묶는 v3 `scenario-semantic-audit-v3.json`이다.

## 2. Canonical Trace

```text
Product / Accepted ADR / Current Architecture / UI
→ Requirement Capability
↔ Clean Canonical Scenario body
→ direct Scenario System/Requirement/semanticStages trace
→ v2 mutation + ingress + recovery semantic classification evidence
→ v3 clean-source binding
→ R3 execution boundary
→ R4 E0 checkpoint
→ Source/Test/Runtime/Human evidence
```

Base 14 Scenario body는 `scenario-base-catalog.json`, Expanded 47 Scenario body는 `scenario-expanded-catalog.json`이 소유한다. 두 clean catalog 모두 legacy Greenfield capability/system/module 참조를 포함하지 않는다.

`architecture-coverage.json`의 Base 사본과 `architecture-scenarios.json`의 Expanded 사본/capabilityRefs는 historical evidence다. v3 validator는 historical Expanded의 `id/phase/steps/expectedOutcome/negativeCases` projection이 clean Expanded와 정확히 같은지만 확인한다.

## 3. Scenario Semantic Audit v3

현재 digest:

```text
v1 direct trace digest
sha256:57e485a0cec6d753542e4bc202a881e10e2bd5ae63e314cc609c7e2d99f38140

v2 semanticSchemaDigest
sha256:dcc766c1161332789e91aadc362c4765687af3efc2f7193cf23f748df0eb6489

v3 combinedAuditDigest
sha256:3d548607d17c7ca7fb13cb44b6b3e8f305f0cb5e5a3a46eacdae7ee19497e46e
```

v3 combined audit는 다음을 묶는다.

```text
Clean Base Scenario blob
+ Clean Expanded Scenario blob
+ v1 trace digest
+ immutable v2 classification-audit blob
+ v2 semantic schema digest
→ v3 combinedAuditDigest
```

추가 validator 규칙:

```text
Clean Base/Expanded catalog
→ capabilityRefs/systemRefs/moduleRefs/knownGapRefs 금지

Historical architecture-scenarios.json
→ historical evidence only
→ semantic body projection == clean Expanded 47 exact match
```

Ingress는 System과 Requirement를 함께 강제한다.

```text
COMMAND → A2 + A1 + REQ_REQUEST_PROTOCOL + REQ_CONTROL_PERMISSION
READ_REQUEST → A2 + REQ_REQUEST_PROTOCOL
SYNC_CONTROL → A6 + A1 + REQ_SESSION_PLAYABILITY
EVENT_TRIGGER → A8 + REQ_COMMITTED_EVENT_PROPAGATION
TEST_HARNESS → S2 + REQ_DIAGNOSTICS_REPRODUCIBILITY
```

Typed recovery는 27개 Scenario에 존재한다. 재검증 sentinel:

```text
SCN_ATTACK_REACTION_RESOLUTION → RECONNECT
SCN_CHARACTER_SHEET_LIVE_DAMAGE_SYNC → CLIENT_RESYNC
SCN_SCENE_CANDIDATE_TEST_PUBLISH → LAST_KNOWN_GOOD
SCN_DM_RECOVERY_REVIEW_BRANCH → SERVER_RESTART + ROLLBACK_BRANCH + CLIENT_RESYNC
```

`MUTATION`은 모든 transient record가 아니라 A3 transactional authoritative domain/source commit 또는 atomic commit attempt다.

## 4. Authority / Event / Ready

```text
Command
→ A2
→ A1 policy
→ Rule/Domain
→ A3 atomic commit + transactional outbox
→ A8 committed-only delivery/retry/receipt
→ A5 viewer-safe Projection
→ A6 synchronization
```

```text
A3 = outbox atomicity + committed event fact
A8 = delivery/subscription/retry/receipt/dead-letter semantics
A7 = durable persistence + restart reconstruction
A8 delivery semantics → A7 durability seam → StorageAdapter
```

```text
A7 authorityRecoveryReady
A6 projectionSyncReady
W7 sceneEssentialReady
C1 clientReplicaReady
→ A1 EffectiveGameplayReady
→ A1 only final Command gate
```

## 5. REPOSITORY_LOGIC와 E0_CORE_ENGINE

```text
REPOSITORY_LOGIC
= Roblox 없이 구현/검증 가능한 모든 production logic의 분류

E0_CORE_ENGINE
= Studio 전에 반드시 완성해야 하는 Foundation subset
```

`CORE_ENGINE_COMPLETE`는 모든 미래 Repository feature 완료가 아니다. R4에서 Freeze된 모든 E0 seam 구현과 automated negative/future-compatibility test 완료를 뜻한다.

E1 Provider가 소비할 Core contract/policy/state-machine은 반드시 E0에서 먼저 완성한다. D6 Journal, D7 Campaign Logistics, U2 Actor Authoring 전체 feature implementation은 현재 CORE_ENGINE_COMPLETE 필수가 아니다.

## 6. Reservation / Provider

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

범용 ReservationManager나 Domain별 직접 Remote/Storage authority path를 만들지 않는다.

## 7. R4 E0 Checkpoint Freeze

R3가 사용자에 의해 Freeze된 뒤에만 실제 System → Module → Stable Function을 구체화한다.

각 Checkpoint는 최소 다음을 가진다.

```text
Checkpoint ID
System / Module Scope
Stable Function Scope
Authority / State Ownership
Input / Output Contract
Current Scenario Working Set
Requirement Capability Set
Future Consumers / Future Scenario Pressure
Persistence / Recovery / Observability seams
Required Platform Provider Contracts
Forbidden Shortcuts
Explicit Deferred Non-goals
Repository Tests
Negative / Fail-closed Tests
Future Compatibility Contract Tests
Completion Condition
```

## 8. 실행 순서

```text
사용자 R3 Freeze 결정
→ R4 E0 Checkpoint Freeze
→ R5 Dedicated Implementation Branch
→ E0 Core Engine 전체 구현/자동 검증
→ CORE_ENGINE_COMPLETE
→ E1 Runtime Checkpoint Freeze
→ Studio/MCP Runtime Provider + Integration
→ INTEGRATION_READY
→ U0-A HTML/UI Reference Distillation
→ U0-B Product UI Shell Scaffold
→ U0-C Human Shell Review
→ UI_SHELL_READY
→ E2 User-facing Checkpoint JIT
→ Human Acceptance
```

**CORE_ENGINE_COMPLETE 전 Studio/MCP 작업을 시작하지 않는다.**

## 9. 검증 중 즉시 수정 규칙

현재 합의 방향 안의 명백한 stale pointer, 문서 상태 drift, validator false-green, workflow trigger 누락은 발견 즉시 수정하고 최종 HEAD에서 다시 검증한다.

Product/Accepted ADR/Authority/state ownership/System responsibility/input grammar/개발 순서 변경은 사용자에게 문제·대안·영향을 먼저 보고한다.

## 10. 금지

- 폐기된 Greenfield 계약 복원.
- legacy Scenario capability/system/module refs를 새 구현 권위로 사용.
- 사용자 승인 없이 새 System/Capability/state owner/authority/input grammar/개발 순서 변경.
- A3 Outbox와 A8 Delivery 통합.
- A6/A7/W7/C1이 final Command gate를 직접 엶.
- Scenario body 또는 semantic schema 변경 후 digest 숫자만 바꾸고 의미 재검토를 생략.
- R4 전 대량 Module/Stable Function 확정.
- CORE_ENGINE_COMPLETE 전 Studio/MCP 진입.
