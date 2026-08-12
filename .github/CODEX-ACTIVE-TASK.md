# RVTT Current Executable Task

- executionAuthority: `ONLY_CURRENT_EXECUTABLE_TASK`
- status: `R3_SEMANTIC_AUDIT_V2_AWAITING_FINAL_VALIDATION`
- commandId: `RVTT-R3-SEMANTIC-AUDIT-V2-001`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- sourceImplementationAllowed: `false`
- studioImplementationAllowed: `false`
- systemModel: `34_SYSTEM_V2_REPAIRED`
- requirementCapabilityCatalog: `30_REQUIREMENT_CAPABILITY_V3`
- scenarioTrace: `61_OF_61_MACHINE_READABLE`
- scenarioSemanticAudit: `V2_61_OF_61_BODY_BOUND_INGRESS_RECOVERY_TYPED`
- scenarioTraceDigest: `sha256:57e485a0cec6d753542e4bc202a881e10e2bd5ae63e314cc609c7e2d99f38140`
- scenarioCombinedAuditDigest: `sha256:301639d88a9e8accf6c33e7f42332a8915c558ddb752242db62619e84eccab1b`
- effectiveRecoveryScenarios: `24`
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
6. implementation/roblox/manifests/scenario-semantic-audit.json
7. implementation/roblox/audits/IMPLEMENTATION-MODEL-R3-BOUNDARY-001.md
```

특정 책임의 상위 근거가 필요할 때만 Product/Accepted ADR/Architecture/UI와 Scenario Registry를 선택적으로 읽는다. 폐기된 Greenfield System/Module/Stable Function/Execution 문서는 기본 읽기 대상이 아니다.

## 2. 현재 목표

34-System 구조를 더 바꾸는 작업이 아니다. R3 Freeze 전에 Scenario 검증 사각지대를 닫는다.

이번 v2가 추가로 보장해야 하는 것:

```text
Scenario 원문 steps / expectedOutcome / negativeCases 변경
→ semantic re-audit 없이 통과 금지

사용자/DM Command
→ A2 Request Runtime
→ A1 final command policy

Read Request
→ A2 read path

Sync/Ready control
→ A6 + A1

Committed Event follow-up
→ A8

Recovery
→ 종류별 A1/A6/A7/LKG owner 압력
```

## 3. Scenario Semantic Audit v2

`implementation-system-model.json`은 Scenario의 직접 참가 System/Requirement와 v1 `semanticStages[]`를 유지한다.

`scenario-semantic-audit.json`은 공통 ingress/recovery boundary를 중복해서 61줄마다 적지 않고 다음 typed expansion으로 보완한다.

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

Expansion:

```text
COMMAND      → A2 + A1 + request/control requirement
READ_REQUEST → A2 + request requirement
SYNC_CONTROL → A6 + A1 + session requirement
EVENT_TRIGGER→ A8 + committed-event requirement
TEST_HARNESS → S2 + diagnostics/reproducibility requirement
```

`SERVER_TRIGGER`는 scheduler/lifecycle/policy처럼 Client Command가 없는 서버 시작점이다. `LOCAL`은 Camera/UI preference처럼 서버 요청이 필요 없는 시작점이다.

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

현재 원본 Scenario의 positive/negative path를 다시 읽어 **24개 Scenario**에 typed recovery pressure가 있다.

중요:

```text
CLIENT_RESYNC       → A6
RECONNECT           → A1 + A6
SERVER_RESTART      → A7
ROLLBACK_BRANCH     → A7 + A1
RETRY_AFTER_RESTART → A7
CONTROL_FAILOVER    → A1
LAST_KNOWN_GOOD     → 해당 source/runtime/catalog owner가 기존 good state를 유지
```

## 4. MUTATION 의미

v1의 `MUTATION` 문자열은 그대로 유지하지만 의미를 다음으로 고정한다.

```text
MUTATION
= Scenario correctness가 A3 transactional authoritative domain/source commit
  또는 atomic commit attempt에 의존함
```

다음을 뜻하지 않는다.

```text
모든 transient RuleExecution record 생성
모든 RollRecord/Event 기록
client-local state
sync cursor
presentation signal
read result
```

따라서 hidden-DC ability check처럼 권위 Roll/Event는 만들지만 Character/Domain source state를 바꾸지 않는 Scenario는 `EVENT`가 있으면서 `MUTATION`이 없을 수 있다.

## 5. Body ↔ Trace Binding

v2는 Scenario 원문 자체를 semantic audit에 묶는다.

```text
base scenario registry blob
+ expanded scenario registry blob
+ v1 scenario trace digest
+ v2 entry/recovery digest
→ combined audit digest
```

현재 combined digest:

```text
sha256:301639d88a9e8accf6c33e7f42332a8915c558ddb752242db62619e84eccab1b
```

Scenario의 `steps`, `expectedOutcome`, `negativeCases`가 바뀌면 registry blob SHA가 바뀌므로 semantic re-audit 없이 CI가 통과할 수 없다.

## 6. 기존 시스템 불변식

다음은 그대로 유지한다.

```text
A3 commit + transactional outbox
→ A8 committed-only delivery/retry/receipt
→ subscribers

A8 delivery semantics
→ A7 durability seam
→ StorageAdapter

A7 authorityRecoveryReady
A6 projectionSyncReady
W7 sceneEssentialReady
C1 clientReplicaReady
→ A1 EffectiveGameplayReady
→ final Command gate
```

Reservation과 Provider taxonomy도 변경하지 않는다.

## 7. 실행 순서

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
→ U0 HTML/UI distillation + full Product UI Shell
→ UI_SHELL_READY
→ E2 user-facing checkpoints
```

**CORE_ENGINE_COMPLETE 전 Studio/MCP 작업 금지.**

## 8. 지금 하지 않는 것

- Source 생성.
- Studio/MCP 진입.
- R3 자동 Freeze.
- 새 System/Capability 추가.
- Module/Stable Function 대량 설계.
- Controller/Manager 이름 확정.
- 폐기된 Greenfield 계약 복원.

## 9. 다음 행동

`validate_architecture_coverage.py`와 `validate_scenario_semantic_audit.py`를 포함해 최종 HEAD의 전체 CI를 한 번 실행한다.

통과해도 자동 Freeze하지 않는다. 결과를 사용자에게 보고한 뒤 사용자 결정으로만 R4로 넘어간다.
