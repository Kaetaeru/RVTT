# RVTT Implementation Model

- 상태: `ACTIVE · SYSTEM_MODEL_V2_REPAIRED · R3_SEMANTIC_AUDIT_V2_PENDING_FINAL_VALIDATION`
- 최종 갱신일: 2026-08-13
- System Authority: [`SYSTEMS.md`](SYSTEMS.md)
- Direct System/Requirement/Scenario Trace: [`manifests/implementation-system-model.json`](manifests/implementation-system-model.json)
- Scenario Ingress/Recovery Audit: [`manifests/scenario-semantic-audit.json`](manifests/scenario-semantic-audit.json)
- Source 구현: `FORBIDDEN`
- Studio/MCP 구현: `FORBIDDEN`

## 1. 현재 기준

폐기된 Greenfield `25 modules / 10 systems / 64 stable functions / G0~G5 / WorldState.transact 중심 모델`은 새 구현의 출발점이 아니다.

현재 기준은 다음뿐이다.

```text
34 System Responsibility Model v2
30 Requirement Capability Catalog v3
61 Representative Scenarios
Scenario Semantic Audit v2
```

Requirement Capability와 System은 many-to-many다. System은 Manager/Controller/ModuleScript 개수가 아니라 책임·상태·권위 경계다.

## 2. Canonical Trace

```text
Product / Accepted ADR / Current Architecture / UI
→ Requirement Capability
↔ Scenario source body
→ direct Scenario System/Requirement trace
→ Scenario Semantic Audit v2 ingress/recovery expansion
→ R3 execution boundary
→ R4 E0 checkpoint
→ Source/Test/Runtime/Human evidence
```

`implementation-system-model.json`은 직접 참가 System/Requirement와 v1 semantic stage를 소유한다.

`scenario-semantic-audit.json`은 모든 Scenario마다 반복되는 공통 Command/Read/Sync/Event ingress와 typed Recovery boundary를 추가해 **effective semantic path**를 만든다.

## 3. Scenario Semantic Audit v2

### Body binding

다음을 하나의 검증 단위로 묶는다.

```text
Base Scenario Registry blob SHA
Expanded Scenario Registry blob SHA
Scenario Trace digest
Entry/Recovery digest
→ Combined Audit digest
```

현재 combined digest:

```text
sha256:301639d88a9e8accf6c33e7f42332a8915c558ddb752242db62619e84eccab1b
```

따라서 Scenario `steps / expectedOutcome / negativeCases`가 바뀌면 semantic re-audit 없이 통과할 수 없다.

### Entry kinds

```text
LOCAL
COMMAND
READ_REQUEST
SYNC_CONTROL
SERVER_TRIGGER
EVENT_TRIGGER
TEST_HARNESS
```

공통 expansion:

```text
COMMAND       → A2 Request + A1 Command Policy
READ_REQUEST  → A2 Read Path
SYNC_CONTROL  → A6 Sync + A1 Session Gate
EVENT_TRIGGER → A8 committed-event delivery
TEST_HARNESS  → S2 deterministic harness
```

`SERVER_TRIGGER`는 scheduler/lifecycle/policy 시작점이며 Client Command를 요구하지 않는다. `LOCAL`은 Camera/UI preference처럼 server request가 없는 시작점이다.

### Recovery kinds

```text
CLIENT_RESYNC
RECONNECT
SERVER_RESTART
ROLLBACK_BRANCH
RETRY_AFTER_RESTART
LAST_KNOWN_GOOD
CONTROL_FAILOVER
```

원본 positive/negative case를 다시 읽은 결과 **24개 Scenario**가 typed recovery pressure를 가진다. v1의 단일 `RECOVERY` 집계보다 넓다.

```text
CLIENT_RESYNC       → A6
RECONNECT           → A1 + A6
SERVER_RESTART      → A7
ROLLBACK_BRANCH     → A7 + A1
RETRY_AFTER_RESTART → A7
CONTROL_FAILOVER    → A1
LAST_KNOWN_GOOD     → 해당 source/runtime/catalog owner
```

## 4. MUTATION 의미

v1 `semanticStages[]`의 `MUTATION` 문자열은 유지하지만 의미를 좁혀 고정한다.

```text
MUTATION
= Scenario correctness가 A3 transactional authoritative domain/source commit
  또는 atomic commit attempt에 의존함
```

다음 자체는 `MUTATION`이 아니다.

```text
transient RuleExecution record
RollRecord/Event record
client-local state
sync cursor
presentation signal
read result
```

따라서 `EVENT`는 `MUTATION` 없이 존재할 수 있다. 예를 들어 hidden-DC ability check는 권위 Roll/Event를 만들 수 있지만 Character/Domain source state를 반드시 바꾸지는 않는다.

## 5. REPOSITORY_LOGIC ≠ E0_CORE_ENGINE

```text
REPOSITORY_LOGIC
= Roblox 없이 구현/검증 가능한 모든 production logic의 분류

E0_CORE_ENGINE
= Studio 전에 반드시 완성해야 하는 Foundation subset
```

`CORE_ENGINE_COMPLETE`는 모든 미래 Repository feature 완료가 아니다.

반대로 E1 Provider가 소비할 Core contract/policy/state machine은 반드시 E0에서 먼저 완성한다. 현재 pre-Studio seam set은 `implementation-system-model.json`의 `e0RequiredSystemSeams`가 소유한다.

`D6 Journal`, `D7 Campaign Logistics`, `U2 Actor Authoring` 전체 feature 구현은 현재 CORE_ENGINE_COMPLETE 필수가 아니며 R4에서 실제 선행 의존성이 증명될 때만 사용자 결정으로 승격한다.

## 6. 공통 권위 불변식

### Mutation / Event

```text
Client/DM Command
→ A2
→ A1 policy
→ Rule/Domain
→ A3 atomic commit + transactional outbox
→ A8 committed-only delivery/retry/receipt
→ subscriber
→ A5 viewer-safe Projection
→ A6 synchronization
```

A8 Handler가 상태를 바꿀 필요가 있으면 새 Command/RuleExecution을 제출한다. A8이 Store/A3 internals를 직접 수정하지 않는다.

Durability:

```text
A3 = outbox atomicity + committed event fact
A8 = delivery/subscription/retry/receipt/dead-letter semantics
A7 = durable persistence + restart reconstruction mechanism

A8 semantics → A7 persistence seam → StorageAdapter
```

A8은 StorageAdapter를 직접 사용하지 않는다.

### Ready

```text
A7 authorityRecoveryReady
A6 projectionSyncReady
W7 sceneEssentialReady
C1 clientReplicaReady
→ A1 EffectiveGameplayReady
→ A1 only final gameplay Command gate
```

### Reservation

```text
OrderingReservation              → A3
ResourceReservation              → R3 orchestration
OccupancyReservation             → W6
ActivityReservation              → D5
LogisticsAllocationReservation   → D7
```

범용 ReservationManager로 합치지 않는다.

### Shared providers

```text
AuthorityMonotonicClock
DeterministicIdFactory
RngProvider
TransportAdapter
StorageAdapter
```

S2는 같은 interface의 deterministic test adapter를 사용한다. 각 System이 임의 clock/GUID/Random/Remote/Storage authority path를 만들지 않는다.

## 7. R4 — E0 Checkpoint Freeze

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
Extension / Persistence / Recovery / Observability seams
Required Platform Provider Contracts
Forbidden Shortcuts
Explicit Deferred Non-goals
Repository Tests
Negative / Fail-closed Tests
Future Compatibility Contract Tests
Completion Condition
```

먼 미래 내부 API를 미리 대량 설계하지 않는다. 대신 미래 소비가 shared public boundary를 다시 뜯게 만드는 Checkpoint도 Freeze하지 않는다.

## 8. 실행 순서

```text
Scenario Semantic Audit v2 final validation
→ 사용자 R3 Freeze 결정
→ R4 E0 Checkpoint Freeze
→ R5 Dedicated Implementation Branch
→ E0 Core Engine 전체 구현/자동 검증
→ CORE_ENGINE_COMPLETE
→ E1 Runtime Checkpoint Freeze
→ Studio/MCP Runtime Provider + Integration
→ INTEGRATION_READY
→ U0 HTML/UI Reference Distillation
→ U0 Product UI Shell 전체 구축
→ UI_SHELL_READY
→ E2 User-facing Checkpoint JIT
→ Human Acceptance
```

**CORE_ENGINE_COMPLETE 전 Studio/MCP 작업을 시작하지 않는다.**

U0에서는 기존 HTML UI 예시와 최신 UI Authority를 먼저 글로 Distill하고, 실제 Product Surface 전체의 Shell을 만든다. 이후 throwaway Test ScreenGui 대신 Product Shell의 dev-mode Debug/Fixture Control을 사용한다.

## 9. 금지

- 폐기된 Greenfield 계약을 기본값으로 복원.
- 사용자 승인 없이 새 System/Capability/state owner/authority/input grammar/개발 순서를 변경.
- A3 Outbox와 A8 Delivery를 합침.
- A6/A7/W7/C1이 final Command gate를 직접 엶.
- Reservation 종류를 범용 Manager로 합침.
- Domain이 Transport/Storage를 직접 사용해 A2/A3/A7을 우회.
- Scenario body가 바뀌었는데 semantic audit digest만 수동 교체하고 의미 재검토를 생략.
- R4 전 대량 Module/Stable Function 확정.
- CORE_ENGINE_COMPLETE 전 Studio/MCP 진입.
- U0 이후 throwaway test UI 제작.

## 10. 현재 상태

```text
SYSTEM MODEL = V2 · 34 SYSTEMS · REPAIRED
REQUIREMENT CAPABILITY = V3 · 30 · MANY-TO-MANY
DIRECT SCENARIO TRACE = 61/61
SEMANTIC AUDIT = V2 · BODY-BOUND · ENTRY/RECOVERY TYPED
EFFECTIVE RECOVERY SCENARIOS = 24
R3 = NOT FROZEN
SOURCE = BLOCKED
STUDIO/MCP = BLOCKED
DEDICATED IMPLEMENTATION BRANCH = NOT YET CREATED
```

다음 행동은 최종 HEAD에서 기존 Coverage Validator와 새 Scenario Semantic Audit Validator를 포함한 전체 CI를 한 번 검증하는 것이다. 통과해도 R3는 자동 Freeze하지 않는다.
