# RVTT Current Executable Task

- executionAuthority: `ONLY_CURRENT_EXECUTABLE_TASK`
- status: `R3_SEMANTIC_AUDIT_V2_AWAITING_FINAL_VALIDATION`
- priorRepairedBaseStatus: `R3_REPAIRED_AWAITING_FREEZE_DECISION`
- commandId: `RVTT-R3-SEMANTIC-AUDIT-V2-HARDENED-002`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- sourceImplementationAllowed: `false`
- studioImplementationAllowed: `false`
- systemModel: `34_SYSTEM_V2_REPAIRED`
- requirementCapabilityCatalog: `30_REQUIREMENT_CAPABILITY_V3`
- scenarioTrace: `61_OF_61_MACHINE_READABLE`
- scenarioSemanticAudit: `V1_61_OF_61`
- scenarioSemanticAuditV2: `V2_FULL_SCHEMA_BOUND_61_OF_61`
- scenarioTraceDigest: `sha256:57e485a0cec6d753542e4bc202a881e10e2bd5ae63e314cc609c7e2d99f38140`
- semanticSchemaDigest: `sha256:bba741b54f72b1320bafa7994ca1cc009cf55b3dc909b0035fffac36560a9797`
- scenarioCombinedAuditDigest: `sha256:8d929e2fee969da391344d3877a73315c5b1a8c1cecf2055dcbe9fe40897173e`
- effectiveRecoveryScenarios: `27`
- r3BoundaryAudit: `REPAIRED_NOT_FROZEN`
- updatedAt: `2026-08-13`

`scenarioSemanticAudit: V1_61_OF_61`은 direct semantic-stage base layer다. 완전한 R3 Scenario audit 권위는 `scenarioSemanticAuditV2`다.

## 1. 기본 읽기 경로

```text
1. AGENTS.md
2. .github/CODEX-ACTIVE-TASK.md
3. implementation/roblox/IMPLEMENTATION-MODEL.md
4. implementation/roblox/SYSTEMS.md
5. implementation/roblox/manifests/implementation-system-model.json
6. implementation/roblox/manifests/scenario-semantic-audit.json
7. 필요한 Product/Accepted ADR/Architecture/UI/Scenario 원문
```

폐기된 Greenfield System/Module/Stable Function/Execution 문서는 기본 읽기 대상이 아니다.

## 2. 현재 목표

34-System 구조를 바꾸지 않는다. R3 Freeze 전에 Scenario 검증 사각지대를 완전히 닫는다.

최종 검증 대상:

```text
34 Systems / 30 Requirement Capabilities / 61 Scenarios
Scenario source body blob binding
v1 direct trace digest
v2 full semantic schema digest
entry System + Requirement expansion
recovery System + Requirement expansion
27 typed recovery Scenario
A3/A8/A7 event durability
A1 final Ready gate
Reservation taxonomy
Provider contracts
E0 before Studio sequence
Source/Studio block
```

## 3. Scenario Semantic Audit v2

```text
Base Scenario blob
+ Expanded Scenario blob
+ v1 direct trace digest
+ mutationSemantic
+ entry definitions/expansions
+ recovery definitions/expansions
+ LKG owner set
+ 61 scenario classifications
→ semanticSchemaDigest
→ combinedAuditDigest
```

Ingress:

```text
COMMAND → A2 + A1 + REQ_REQUEST_PROTOCOL + REQ_CONTROL_PERMISSION
READ_REQUEST → A2 + REQ_REQUEST_PROTOCOL
SYNC_CONTROL → A6 + A1 + REQ_SESSION_PLAYABILITY
EVENT_TRIGGER → A8 + REQ_COMMITTED_EVENT_PROPAGATION
TEST_HARNESS → S2 + REQ_DIAGNOSTICS_REPRODUCIBILITY
```

Typed recovery kinds:

```text
CLIENT_RESYNC
RECONNECT
SERVER_RESTART
ROLLBACK_BRANCH
RETRY_AFTER_RESTART
LAST_KNOWN_GOOD
CONTROL_FAILOVER
```

현재 27개 Scenario가 typed recovery pressure를 가진다. 특히 다음 세 누락을 sentinel로 강제한다.

```text
SCN_ATTACK_REACTION_RESOLUTION → RECONNECT
SCN_CHARACTER_SHEET_LIVE_DAMAGE_SYNC → CLIENT_RESYNC
SCN_SCENE_CANDIDATE_TEST_PUBLISH → LAST_KNOWN_GOOD
```

## 4. 기존 시스템 불변식

```text
A3 commit + transactional outbox
→ A8 committed-only delivery/retry/receipt
→ subscribers

A8 delivery semantics → A7 durability seam → StorageAdapter
```

```text
A7 authorityRecoveryReady
A6 projectionSyncReady
W7 sceneEssentialReady
C1 clientReplicaReady
→ A1 EffectiveGameplayReady
→ final Command gate
```

`CORE_ENGINE_COMPLETE 전 Studio/MCP 작업 금지.`

## 5. 실행 순서

```text
Scenario Semantic Audit v2 final validation
→ 사용자 R3 Freeze 결정
→ R4 E0 Checkpoint Freeze
→ R5 Dedicated Implementation Branch
→ E0 Core Engine 구현/자동 검증
→ CORE_ENGINE_COMPLETE
→ E1 Runtime Checkpoint Freeze
→ Studio/MCP Integration
→ INTEGRATION_READY
→ U0-A HTML/UI Reference Distillation
→ U0-B Product UI Shell Scaffold
→ U0-C Human Shell Review
→ UI_SHELL_READY
→ E2
```

## 6. 지금 하지 않는 것

- Source 생성.
- Studio/MCP 진입.
- R3 자동 Freeze.
- 새 System/Capability 추가.
- Module/Stable Function 대량 설계.
- 폐기 Greenfield 계약 복원.

## 7. 다음 행동

최종 HEAD에서 전체 Workflow를 한 번 검증한다. 통과해도 자동 Freeze하지 않고 사용자에게 결과를 보고한다.
