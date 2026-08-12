# RVTT Current Executable Task

- executionAuthority: `ONLY_CURRENT_EXECUTABLE_TASK`
- status: `R3_VALIDATED_AWAITING_FREEZE_DECISION`
- commandId: `RVTT-R3-VALIDATED-AWAITING-FREEZE-005`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- sourceImplementationAllowed: `false`
- studioImplementationAllowed: `false`
- systemModel: `34_SYSTEM_V2_REPAIRED`
- requirementCapabilityCatalog: `30_REQUIREMENT_CAPABILITY_V3`
- scenarioTrace: `61_OF_61_MACHINE_READABLE`
- scenarioSemanticAudit: `V1_61_OF_61_DIRECT_TRACE`
- scenarioSemanticAuditV2: `V2_61_OF_61_CLASSIFICATION_EVIDENCE_VALIDATED`
- scenarioSemanticAuditV3: `V3_CLEAN_SOURCE_BOUND_61_OF_61_VALIDATED`
- canonicalBaseScenarioCatalog: `implementation/roblox/manifests/scenario-base-catalog.json`
- canonicalExpandedScenarioCatalog: `implementation/roblox/manifests/scenario-expanded-catalog.json`
- historicalExpandedScenarioEvidence: `implementation/roblox/manifests/architecture-scenarios.json`
- scenarioTraceDigest: `sha256:57e485a0cec6d753542e4bc202a881e10e2bd5ae63e314cc609c7e2d99f38140`
- semanticSchemaDigest: `sha256:dcc766c1161332789e91aadc362c4765687af3efc2f7193cf23f748df0eb6489`
- scenarioCombinedAuditDigestV3: `sha256:bd2db9a2d97c224c73265cd11dc6db32e81a17fc24b7fe6909254a5185196f38`
- effectiveRecoveryScenarios: `27`
- r3BoundaryAudit: `VALIDATED_NOT_FROZEN`
- updatedAt: `2026-08-13`

v1은 direct Requirement/System/semanticStages trace다. v2는 61개 entry/recovery classification과 semantic schema의 immutable evidence다. 현재 완전한 R3 Scenario audit 권위는 clean Base/Expanded source를 v2 classification evidence에 묶는 v3다.

## 1. 기본 읽기 경로

```text
1. AGENTS.md
2. .github/CODEX-ACTIVE-TASK.md
3. implementation/roblox/IMPLEMENTATION-MODEL.md
4. implementation/roblox/SYSTEMS.md
5. implementation/roblox/manifests/implementation-system-model.json
6. implementation/roblox/manifests/scenario-semantic-audit-v3.json
7. implementation/roblox/manifests/scenario-semantic-audit.json
8. implementation/roblox/manifests/scenario-base-catalog.json
9. implementation/roblox/manifests/scenario-expanded-catalog.json
10. 필요한 Product/Accepted ADR/Architecture/UI 원문
```

폐기된 Greenfield System/Module/Stable Function/Execution 문서는 기본 읽기 대상이 아니다. `architecture-coverage.json`의 legacy Base 사본과 `architecture-scenarios.json`의 legacy capabilityRefs/status도 새 구현 입력으로 사용하지 않는다.

## 2. 현재 상태

34-System / 30 Requirement / 61 Scenario R3 모델은 전수 semantic audit와 GitHub Workflow 검증을 통과한 상태를 유지한다. 이번 authority-hygiene 재검증에서는 clean Scenario source에서 남아 있던 legacy coverage metadata와 historical evidence coupling을 제거했다.

```text
34 Systems / 30 Requirement Capabilities / 61 Scenarios
Canonical Base Scenario = 14 clean body-only
Canonical Expanded Scenario = 47 clean body-only
v1 direct trace = VALIDATED
v2 semantic classification/schema = VALIDATED EVIDENCE
v3 clean source binding = VALIDATED
27 typed recovery Scenario
A3/A8/A7 event durability = VALIDATED
A1 final Ready gate = VALIDATED
Reservation taxonomy = VALIDATED
Provider contracts = VALIDATED
E0 before Studio sequence = VALIDATED
Source/Studio block = ACTIVE
R3 = VALIDATED · NOT FROZEN
```

## 3. Scenario Source Rule

Base 14의 canonical source는 `scenario-base-catalog.json`, Expanded 47의 canonical source는 `scenario-expanded-catalog.json`이다. 두 파일의 Scenario object는 `id / phase / steps / expectedOutcome / negativeCases`만 소유하며 legacy Greenfield capability/system/module/coverage status를 포함하지 않는다.

`architecture-scenarios.json`은 historical Greenfield evidence다. clean Expanded 추출 시 semantic body equivalence는 이미 검증됐으며, 이후에는 historical blob 자체를 immutable evidence로 고정한다. canonical Scenario가 정상적인 semantic re-audit를 통해 진화할 때 historical evidence를 같이 다시 쓰거나 계속 exact-match시킬 필요가 없다.

Requirement/System/direct semantic stage mapping은 `implementation-system-model.json`, entry/recovery classification과 semantic schema evidence는 v2 `scenario-semantic-audit.json`, clean-source + historical-evidence binding은 v3 `scenario-semantic-audit-v3.json`이 소유한다.

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

## 6. 검증 중 발견 사항 처리

현재 합의 방향 안의 명백한 stale pointer, legacy metadata leak, 문서 상태 drift, validator false-green, workflow trigger 누락은 발견 즉시 수정하고 최종 HEAD에서 다시 검증한다.

Product/Accepted ADR/Authority/state ownership/System responsibility/input grammar/개발 순서 변경은 이 규칙에 포함되지 않으며 사용자에게 문제·대안·영향을 먼저 보고한다.

## 7. 지금 하지 않는 것

- R3 자동 Freeze.
- Source 생성.
- Studio/MCP 진입.
- 새 System/Capability 추가.
- Module/Stable Function 대량 설계.
- 폐기 Greenfield 계약 복원.
- legacy Scenario mapping/status 재사용.
- historical evidence를 canonical Scenario 변경에 맞춰 재작성.

## 8. 다음 행동

자동으로 다음 Architecture 단계로 진행하지 않는다. 사용자 R3 Freeze 결정이 내려오면 R4 E0 Checkpoint Freeze로 이동한다.
