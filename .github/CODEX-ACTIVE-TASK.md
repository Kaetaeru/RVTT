# RVTT Current Executable Task

- executionAuthority: `ONLY_CURRENT_EXECUTABLE_TASK`
- status: `R3_REPAIRED_AWAITING_FREEZE_DECISION`
- commandId: `RVTT-R3-REPAIRED-VALIDATION-001`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskMode: `REPAIRED_SYSTEM_BOUNDARY_VALIDATION`
- sourceImplementationAllowed: `false`
- studioImplementationAllowed: `false`
- systemModel: `34_SYSTEM_V2_REPAIRED`
- requirementCapabilityCatalog: `30_REQUIREMENT_CAPABILITY_V3`
- scenarioTrace: `61_OF_61_MACHINE_READABLE`
- scenarioSemanticAudit: `V1_61_OF_61`
- scenarioSemanticAuditDigest: `sha256:57e485a0cec6d753542e4bc202a881e10e2bd5ae63e314cc609c7e2d99f38140`
- a8Durability: `A8_DELIVERY_VIA_A7_PERSISTENCE_SEAM`
- r3BoundaryAudit: `REPAIRED_NOT_FROZEN`
- updatedAt: `2026-08-13`

## 1. 기본 읽기 경로

Codex는 기본적으로 다음만 읽는다.

```text
1. AGENTS.md
2. .github/CODEX-ACTIVE-TASK.md
3. implementation/roblox/IMPLEMENTATION-MODEL.md
4. implementation/roblox/SYSTEMS.md
5. implementation/roblox/manifests/implementation-system-model.json
6. implementation/roblox/audits/IMPLEMENTATION-MODEL-R3-BOUNDARY-001.md
```

특정 책임의 상위 근거가 필요할 때만 Product/Accepted ADR/Architecture/UI와 기존 Scenario Registry를 선택적으로 읽는다.

폐기된 Greenfield System/Module/Stable Function/Execution 문서는 기본 읽기 대상이 아니다.

## 2. 현재 모델

```text
System Responsibility Model v2 = 34
Requirement Capability Catalog v3 = 30
Representative Scenario Trace = 61 / 61
Scenario Semantic Audit = V1 · 61/61
```

중요:

```text
Requirement Capability ≠ System alias
REPOSITORY_LOGIC ≠ E0_CORE_ENGINE
A3 Outbox ≠ A8 Event Delivery
A8 delivery semantics → A7 durability seam
Readiness evidence producer ≠ final ready gate owner
```

## 3. 현재 목표

R3 self review에서 발견한 구조 결함과 61 Scenario semantic trace 결함은 문서/manifest에 수정됐다. 현재 작업은 이 repaired model 전체를 한 번에 최종 검증하는 것이다.

검증 대상:

```text
34 unique System IDs and names
30 unique Requirement Capabilities with many-to-many System refs
61 exact Scenario traces with no missing/extra IDs
61 Scenario semanticStages and semantic digest
MUTATION → A3 + REQ_ATOMIC_CONCURRENCY
EVENT → A3 + A8 + REQ_COMMITTED_EVENT_PROPAGATION
PROJECTION → A5 + A6 + REQ_VIEWER_SAFE_PROJECTION
RECOVERY → A6 or A7 + recovery/session requirement
HUMAN → C1/C2/C3/U1/U2
A8 committed-event delivery ownership
A8 durable cursor/receipt/dead-letter state persists only through A7
STORAGE_ADAPTER production consumer remains A7 only
A1 sole final gameplay-ready gate
A6/A7/W7/C1 typed readiness evidence
Reservation taxonomy separation
Platform provider contracts
E1-consuming Core seams included in E0 pre-Studio set
Source/Studio block preserved
```

**이 검증이 끝나도 R3는 자동 FROZEN이 아니다.** 사용자 Freeze 결정이 있어야 R4로 간다.

## 4. 실행환경 의미

### REPOSITORY_LOGIC

Roblox 없이 구현 가능한 모든 production logic의 분류다.

### E0_CORE_ENGINE

Studio 전에 반드시 완성할 Foundation subset이다.

`CORE_ENGINE_COMPLETE`는 `e0RequiredSystemSeams`의 R4 계약/구현/자동 검증 완료를 뜻하며 모든 미래 Repository feature 완료를 뜻하지 않는다.

### E1_ROBLOX_RUNTIME

`CORE_ENGINE_COMPLETE` 이후에만 Roblox Provider/Adapter를 구현한다.

### HUMAN_PRESENTATION

Integration 이후 U0/E2에서 실제 UI/Camera/VFX/가독성을 검토한다.

## 5. 절대 실행 순서

```text
R3 repaired model validation
→ 사용자 R3 Freeze 결정
→ R4 E0 Checkpoint Freeze
→ R5 Dedicated Implementation Branch
→ E0 Core Engine 구현/자동 검증
→ CORE_ENGINE_COMPLETE
→ E1 Runtime Checkpoint Freeze
→ Studio/MCP Runtime Provider + Integration
→ INTEGRATION_READY
→ U0 HTML/UI distillation + full Product UI Shell
→ UI_SHELL_READY
→ E2 user-facing checkpoints
```

**CORE_ENGINE_COMPLETE 전 Studio/MCP 작업 금지.**

## 6. 구현 AI 필수 불변식

### Event

```text
A3 commit + transactional outbox
→ A8 committed-only delivery/retry/receipt
→ subscribers
```

A8은 Store를 직접 수정하지 않는다.

Durability는 다음처럼 분리한다.

```text
A3 = Outbox atomicity / committed event fact
A8 = delivery cursor / receipt / retry / dead-letter semantics
A7 = durable persistence + reconstruction mechanism

A8 delivery semantics → A7 durability seam → StorageAdapter
```

A8은 `StorageAdapter`를 직접 사용하지 않는다. A7은 A8의 Subscription/Retry 정책을 소유하지 않는다.

### Ready

```text
A7 authorityRecoveryReady
A6 projectionSyncReady
W7 sceneEssentialReady
C1 clientReplicaReady
→ A1 EffectiveGameplayReady
→ final Command gate
```

### Reservation

```text
OrderingReservation → A3
ResourceReservation → R3 orchestration
OccupancyReservation → W6
ActivityReservation → D5
LogisticsAllocationReservation → D7
```

범용 ReservationManager로 합치지 않는다.

### Shared Provider

```text
AuthorityMonotonicClock
DeterministicIdFactory
RngProvider
TransportAdapter
StorageAdapter
```

각 System이 직접 제각각의 clock/GUID/Random/Remote/Storage authority path를 만들지 않는다.

## 7. Scenario Semantic Audit v1

모든 Scenario trace는 다음 의미 단계를 명시한다.

```text
READ
MUTATION
EVENT
PROJECTION
RECOVERY
HUMAN
```

이 단계는 기능 구현 순서가 아니라 **그 Scenario가 정확하려면 반드시 지나야 하는 책임 종류**다.

```text
MUTATION
→ A3 + REQ_ATOMIC_CONCURRENCY 필수

EVENT
→ A3 + A8 + REQ_COMMITTED_EVENT_PROPAGATION 필수

PROJECTION
→ A5 + A6 + REQ_VIEWER_SAFE_PROJECTION 필수

RECOVERY
→ A6 또는 A7
+ REQ_RECOVERY_ROLLBACK 또는 REQ_SESSION_PLAYABILITY 필수

HUMAN
→ C1/C2/C3/U1/U2 중 하나 이상 필수
```

Local-only Camera/Presentation은 `PROJECTION`으로 오해하지 않는다. Commit이 실패해 상태가 바뀌지 않는 atomic attempt도 `MUTATION` 압력을 가진다. Abort된 attempt는 `EVENT`를 요구하지 않는다.

## 8. 미래 호환성

R4는 현재 기능뿐 아니라 다음 소비를 압력으로 본다.

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

미래 기능을 지금 구현하지는 않는다. 대신 미래 기능 때문에 shared public boundary를 다시 설계해야 하는 E0 Checkpoint도 Freeze하지 않는다.

## 9. 지금 하지 않는 것

- Source 생성.
- Studio/MCP 진입.
- R3 자동 Freeze.
- Module/Stable Function 대량 설계.
- Controller/Manager 이름 확정.
- 폐기된 Greenfield 계약 복원.
- UI Shell 조기 제작.

## 10. 다음 행동

**61 Scenario Semantic Audit v1을 포함한 모든 repaired model Validator/CI를 한 번 실행해 전체 정합성을 확인한다.**

통과 후 사용자에게 R3 Freeze 여부를 보고한다.
