# RVTT Current Executable Task

- executionAuthority: `ONLY_CURRENT_EXECUTABLE_TASK`
- status: `R3_VALIDATED_AWAITING_FREEZE_DECISION`
- priorRepairedBaseStatus: `R3_REPAIRED_AWAITING_FREEZE_DECISION`
- commandId: `RVTT-R3-VALIDATED-AWAITING-FREEZE-003`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- sourceImplementationAllowed: `false`
- studioImplementationAllowed: `false`
- systemModel: `34_SYSTEM_V2_REPAIRED`
- requirementCapabilityCatalog: `30_REQUIREMENT_CAPABILITY_V3`
- scenarioTrace: `61_OF_61_MACHINE_READABLE`
- scenarioSemanticAudit: `V1_61_OF_61`
- scenarioSemanticAuditV2: `V2_FULL_SCHEMA_BOUND_61_OF_61_VALIDATED`
- canonicalBaseScenarioCatalog: `implementation/roblox/manifests/scenario-base-catalog.json`
- expandedScenarioCatalog: `implementation/roblox/manifests/architecture-scenarios.json#scenarios`
- scenarioTraceDigest: `sha256:57e485a0cec6d753542e4bc202a881e10e2bd5ae63e314cc609c7e2d99f38140`
- semanticSchemaDigest: `sha256:dcc766c1161332789e91aadc362c4765687af3efc2f7193cf23f748df0eb6489`
- scenarioCombinedAuditDigest: `sha256:2fa071defaa6ee6363378f9a31780f4d54328199fb4e21bc6eeae3c1b9e07bec`
- effectiveRecoveryScenarios: `27`
- r3BoundaryAudit: `VALIDATED_NOT_FROZEN`
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
7. implementation/roblox/manifests/scenario-base-catalog.json
8. 필요한 Expanded Scenario의 architecture-scenarios.json scenarios[]
9. 필요한 Product/Accepted ADR/Architecture/UI 원문
```

폐기된 Greenfield System/Module/Stable Function/Execution 문서는 기본 읽기 대상이 아니다. `architecture-coverage.json` 안의 legacy Base Scenario 사본과 capability/system/module refs도 새 구현 입력으로 사용하지 않는다.

## 2. 현재 상태

34-System / 30 Requirement / 61 Scenario R3 모델은 전수 semantic audit와 GitHub Workflow 검증을 통과했다.

```text
34 Systems / 30 Requirement Capabilities / 61 Scenarios
Canonical Base Scenario = 14
Expanded Scenario = 47
v1 direct trace = VALIDATED
v2 full semantic schema = VALIDATED
27 typed recovery Scenario
A3/A8/A7 event durability = VALIDATED
A1 final Ready gate = VALIDATED
Reservation taxonomy = VALIDATED
Provider contracts = VALIDATED
E0 before Studio sequence = VALIDATED
Source/Studio block = ACTIVE
R3 = NOT FROZEN
```

추가 recovery sentinel:

```text
SCN_ATTACK_REACTION_RESOLUTION → RECONNECT
SCN_CHARACTER_SHEET_LIVE_DAMAGE_SYNC → CLIENT_RESYNC
SCN_SCENE_CANDIDATE_TEST_PUBLISH → LAST_KNOWN_GOOD
SCN_DM_RECOVERY_REVIEW_BRANCH → SERVER_RESTART + ROLLBACK_BRANCH + CLIENT_RESYNC
```

## 3. Scenario Source Rule

Base 14의 canonical source는 `scenario-base-catalog.json`이다. 이 파일은 legacy Greenfield mapping을 포함하지 않는다.

Expanded 47은 현재 `architecture-scenarios.json`의 `scenarios[]`만 Scenario body source로 사용한다. 이 파일의 `baseRegistry`도 canonical Base catalog를 가리키며, legacy `capabilityRefs`는 Requirement/System mapping 권위가 아니다.

Requirement/System/semantic stage mapping은 `implementation-system-model.json`, typed ingress/recovery 의미는 `scenario-semantic-audit.json`만 소유한다.

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
사용자 R3 Freeze 결정
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

- R3 자동 Freeze.
- Source 생성.
- Studio/MCP 진입.
- 새 System/Capability 추가.
- Module/Stable Function 대량 설계.
- 폐기 Greenfield 계약 복원.
- legacy Base Scenario mapping 재사용.

## 7. 다음 행동

자동으로 진행하지 않는다. 사용자 R3 Freeze 결정이 내려오면 R4 E0 Checkpoint Freeze로 이동한다.
