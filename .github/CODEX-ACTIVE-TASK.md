# RVTT Current Executable Task

- executionAuthority: `ONLY_CURRENT_EXECUTABLE_TASK`
- status: `BLOCKED_BY_ARCHITECTURE_COVERAGE`
- commandId: `RVTT-GREENFIELD-FOUNDATION-EXPLORATION-001`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskMode: `ARCHITECTURE_COVERAGE_RECONCILIATION`
- buildMode: `GREENFIELD_ARCHITECTURE_FIRST`
- coverageAuthorityDoc: `implementation/roblox/ARCHITECTURE-COVERAGE-POLICY.md`
- coverageRegistry: `implementation/roblox/manifests/architecture-coverage.json`
- scenarioRegistry: `implementation/roblox/manifests/architecture-scenarios.json`
- coverageAudit: `implementation/roblox/audits/ARCHITECTURE-COVERAGE-AUDIT-001.md`
- coverageValidator: `implementation/roblox/tooling/validate_architecture_coverage.py`
- executionAuthorityDoc: `implementation/roblox/GREENFIELD-EXECUTION-LAYERS.md`
- executionRegistry: `implementation/roblox/manifests/execution-layers.json`
- preflightAuthority: `implementation/roblox/GREENFIELD-PREFLIGHT.md`
- canonicalSourceRoot: `implementation/roblox/greenfield/src`
- canonicalTestRoot: `implementation/roblox/greenfield/tests`
- greenfieldProject: `implementation/roblox/greenfield.project.json`
- sequenceAuthority: `implementation/roblox/GREENFIELD-SYSTEM-SEQUENCE.md`
- moduleContractRegistry: `implementation/roblox/manifests/module-contracts.json`
- systemFunctionContractRegistry: `implementation/roblox/manifests/system-function-contracts.json`
- acceptancePromotionGate: `implementation/roblox/AUTHORITY-RECONCILIATION-POLICY.md`
- feedbackMode: `TIGHT_USER_FEEDBACK_LOOP`
- legacySourcePolicy: `READ_ONLY_REFERENCE_LOCKED`
- legacyPlacePolicy: `DO_NOT_USE_AS_BASELINE`
- commandPath: `.github/CODEX-STUDIO-GREENFIELD-FOUNDATION-EXPLORATION-001.md`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- updatedAt: `2026-08-13`

## 현재 Handoff

**E0 Source 구현을 시작하지 않는다.**

Initial Architecture Coverage Audit에서 상위 Product/ADR/Architecture와 현재 25개 Greenfield Module 계획 사이의 구조적 Gap이 발견됐다.

```text
Authority Corpus
→ Capability Catalog
→ Base + Expanded Scenario Trace
→ Cross-cutting Matrix
→ Gap Resolution
→ Coverage Gate PASS
→ E0 Repository Core Engine
```

`architecture-coverage.json`의 초기 Scenario와 `architecture-scenarios.json`의 확장 Scenario를 하나의 현재 Scenario Catalog로 취급한다.

## 현재 E0 Blocker

```text
GAP-001 Session Policy Boundary
GAP-002 Transaction / Event / Projection Barrier
GAP-003 Runtime Object / Scene Identity
GAP-005 Navigation / Movement Boundary
GAP-007 Capability / Action Availability Projection
GAP-008 RuleExecution Boundary
```

세부 Evidence와 다른 Phase Gap은 `architecture-coverage.json`과 `ARCHITECTURE-COVERAGE-AUDIT-001.md`가 소유한다.

## 다음 실행의 첫 행동

1. `AGENTS.md`를 읽는다.
2. 이 파일을 읽는다.
3. `ARCHITECTURE-COVERAGE-POLICY.md`를 읽는다.
4. `architecture-coverage.json`을 읽는다.
5. `architecture-scenarios.json`을 읽고 현재/미래 사용자·DM·운영 Scenario를 확인한다.
6. Initial Audit를 읽는다.
7. `validate_architecture_coverage.py`를 실행한다.
8. Coverage Authority Tree Snapshot이 현재 Checkout과 일치하는지 확인한다.
9. E0 Blocker를 의존성 순서로 검토한다.
10. 각 Gap마다 현재 문제, 최소 경계 대안, 미래 확장 영향, 기존 Contract 영향 범위를 사용자에게 제안한다.
11. 해당 Gap이 어떤 Base/Expanded Scenario를 막는지도 함께 확인한다.
12. 사용자 결정 전에는 System/Module/Stable Function 책임을 실질적으로 추가·분리·통합하지 않는다.
13. Gap을 하나씩 해결하면서 Coverage Registry와 상위 Authority/Contract를 Top-down 정합화한다.
14. E0 `blockedBy`가 비고 `implementationGate=READY_FOR_E0`가 된 뒤에만 Source 구현 모드로 전환한다.

## Gap Resolution 권장 순서

```text
1. GAP-002 Transaction / Event / Projection Barrier
2. GAP-001 Session Mode / Context / Transition Policy
3. GAP-003 Runtime Object / Scene Identity
4. GAP-004 Spatial Query
5. Selection Boundary 재검증
6. GAP-005 Navigation / Runtime Pathfinding Boundary
7. GAP-007 Capability / Availability / Action Opportunity
8. GAP-008 RuleExecution minimum boundary
9. GAP-006 Interaction Capability Query
10. GAP-009 Client Projection / ViewModel / Input Context Recovery
11. GAP-010 Visibility / Knowledge minimum boundary
```

이 순서는 **검토 순서**이며 구체 Architecture를 자동 승인하지 않는다.

## Architecture Coverage Validator

```text
python implementation/roblox/tooling/validate_architecture_coverage.py
```

Validator가 확인하는 것:

- Product/ADR/Architecture/System/UI/Spec Authority Tree Snapshot.
- Capability/Scenario/Gap reference integrity.
- Base + Expanded Scenario ID 중복과 Capability 참조.
- Scenario Steps·Expected Outcome·Negative Case 존재.
- 모든 현재 System/Module의 Product Capability mapping.
- Cross-cutting Dimension 누락.
- Phase Gate와 Gap consistency.
- OPEN Blocker가 있는데 READY로 위장한 상태.

Validator PASS는 `Gap 없음`을 뜻하지 않는다. 현재처럼 Gap이 명확히 기록되고 Gate가 정직하게 `BLOCKED`여도 Validator는 PASS할 수 있다.

## 기존 E0 후보

현재 Execution Registry에 등록된 E0 후보는 다음이다.

```text
CommandEnvelope
ProjectionEnvelope
WorldContract
SessionAuthority
WorldState
AuthorizationService
CommandRuntime
ProjectionService
MovementDomain
ExplorationDomain
```

Coverage Gap 해결 과정에서 이 목록의 System/Module 책임을 바꿔야 하면 사용자 승인 후 Contract를 수정한다.

현재 목록을 그대로 구현해서 Gap을 코드로 덮지 않는다.

## Execution Layer 원칙

Coverage Gate가 해제된 뒤에도 실행 방식은 유지한다.

```text
E0 Repository Core Engine
→ E1 Roblox Runtime Integration
→ E2 Presentation / Feel
```

- Pure engine은 GitHub-first + automated test.
- Roblox runtime-dependent engine은 Studio/MCP runtime test + GitHub canonical source.
- UI/feel은 Studio self-check + Human acceptance.

Pathfinding은 `GAP-005` 해결 전 구체 Module/API를 만들지 않는다.

## 사용자 확정 처리

Coverage Gap 해결 결정도 Authority 변경이므로 관련 현재 문서를 위에서 아래로 정합화한다.

Playable Checkpoint 최종 수용 시에는:

```text
사용자 최종 수용
→ Authority Impact Scan
→ Product / ADR / Architecture / System / UI / Spec
→ Architecture Coverage Capability / Base+Expanded Scenario / Gap
→ Execution / System / Module / Stable Function Contract
→ Canonical Source / Tests
→ conflict re-scan
→ Promotion Commit
→ ACCEPTED
→ 다음 Checkpoint
```

## 스캔 순서

1. `AGENTS.md`
2. 이 파일
3. `implementation/roblox/ARCHITECTURE-COVERAGE-POLICY.md`
4. `implementation/roblox/manifests/architecture-coverage.json`
5. `implementation/roblox/manifests/architecture-scenarios.json`
6. `implementation/roblox/audits/ARCHITECTURE-COVERAGE-AUDIT-001.md`
7. `implementation/roblox/GREENFIELD-EXECUTION-LAYERS.md`
8. `implementation/roblox/manifests/execution-layers.json`
9. `implementation/roblox/GREENFIELD-PREFLIGHT.md`
10. `implementation/roblox/GREENFIELD-SYSTEM-SEQUENCE.md`
11. `implementation/roblox/MODULE-CONTRACTS.md`
12. `implementation/roblox/SYSTEM-FUNCTION-CONTRACTS.md`
13. `implementation/roblox/manifests/module-contracts.json`
14. `implementation/roblox/manifests/system-function-contracts.json`
15. 현재 `commandPath`
16. `implementation/roblox/AUTHORITY-RECONCILIATION-POLICY.md`
17. Gap Evidence와 관련 Scenario가 가리키는 Product/ADR/Architecture/System/UI/Spec
18. Legacy Source는 필요한 경우 읽기 참고만

## 지금 하지 않는 것

- E0 Source 구현.
- Coverage Gap을 무시한 임시 System/Module 추가.
- Scenario 추가를 Architecture 승인으로 해석.
- Spatial Query 대신 Controller에서 Workspace 직접 순회.
- Context Menu를 대상 타입별 하드코딩으로 우회.
- Character/Interaction Capability를 Client가 재계산하도록 구현.
- WorldState.transact를 상위 Transaction Architecture 전체와 동일하다고 근거 없이 가정.
- MovementDomain 안에 Pathfinding/Movement Executor/Presentation 책임을 몰아넣기.
- future P2~P10 모든 내부 API를 미리 설계.
- Legacy Source/Project 수정.
- ready-for-review / merge / force push.

더 좋은 Architecture가 보이면 사용자에게 먼저 제안한다.
