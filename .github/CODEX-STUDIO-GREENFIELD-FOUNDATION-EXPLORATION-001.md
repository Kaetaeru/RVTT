# RVTT Greenfield — Architecture Coverage → Engine → Integration → Presentation 001

- 상태: `ACTIVE · CURRENT_COMMAND · BLOCKED_BY_ARCHITECTURE_COVERAGE`
- Build mode: `GREENFIELD_ARCHITECTURE_FIRST`
- Coverage authority: [`../implementation/roblox/ARCHITECTURE-COVERAGE-POLICY.md`](../implementation/roblox/ARCHITECTURE-COVERAGE-POLICY.md)
- Coverage registry: `implementation/roblox/manifests/architecture-coverage.json`
- Coverage audit: [`../implementation/roblox/audits/ARCHITECTURE-COVERAGE-AUDIT-001.md`](../implementation/roblox/audits/ARCHITECTURE-COVERAGE-AUDIT-001.md)
- Execution authority: [`../implementation/roblox/GREENFIELD-EXECUTION-LAYERS.md`](../implementation/roblox/GREENFIELD-EXECUTION-LAYERS.md)
- Execution registry: `implementation/roblox/manifests/execution-layers.json`
- Sequence authority: [`../implementation/roblox/GREENFIELD-SYSTEM-SEQUENCE.md`](../implementation/roblox/GREENFIELD-SYSTEM-SEQUENCE.md)
- Code contract: [`../implementation/roblox/MODULE-CONTRACTS.md`](../implementation/roblox/MODULE-CONTRACTS.md) + [`../implementation/roblox/SYSTEM-FUNCTION-CONTRACTS.md`](../implementation/roblox/SYSTEM-FUNCTION-CONTRACTS.md)

## 목표

Source 구현 전에 현재 Product/ADR/Architecture/System/UI/Spec의 중요한 Capability가 Greenfield 계획에 빠졌는지 먼저 확인한다.

```text
Authority Corpus
→ Capability Catalog
→ Representative Scenario
→ Cross-cutting Coverage
→ Blocking Gap Resolution
→ System / Module / Stable Function Contract
→ E0 Repository Core Engine
→ E1 Roblox Runtime Integration
→ E2 Presentation / Feel
```

현재는 Coverage Gap Resolution 단계이며 E0 Source를 시작하지 않는다.

## 0. 구현 전 읽기

1. `AGENTS.md`
2. `.github/CODEX-ACTIVE-TASK.md`
3. `implementation/roblox/ARCHITECTURE-COVERAGE-POLICY.md`
4. `implementation/roblox/manifests/architecture-coverage.json`
5. `implementation/roblox/audits/ARCHITECTURE-COVERAGE-AUDIT-001.md`
6. `implementation/roblox/GREENFIELD-EXECUTION-LAYERS.md`
7. `implementation/roblox/manifests/execution-layers.json`
8. `implementation/roblox/GREENFIELD-PREFLIGHT.md`
9. `implementation/roblox/GREENFIELD-SYSTEM-SEQUENCE.md`
10. `implementation/roblox/MODULE-CONTRACTS.md`
11. `implementation/roblox/SYSTEM-FUNCTION-CONTRACTS.md`
12. 두 Code Contract Registry
13. Gap Evidence가 가리키는 Product/ADR/Architecture/System/UI/Spec

## 1. P0 Architecture Coverage Gate

먼저 실행한다.

```text
python implementation/roblox/tooling/validate_architecture_coverage.py
```

Validator가 PASS하더라도 `architecture-coverage.json.implementationGate`가 `BLOCKED_*`이면 Source를 만들지 않는다.

현재 상태:

```text
implementationGate = BLOCKED_BY_FOUNDATION_COVERAGE_GAPS
```

현재 E0 blocker:

```text
GAP-001 Session Policy Boundary
GAP-002 Transaction / Event / Projection Barrier
GAP-003 Runtime Object / Scene Identity
GAP-005 Navigation / Movement Boundary
GAP-007 Capability / Action Availability Projection
GAP-008 RuleExecution Boundary
```

## 2. 지금 수행할 작업 — Gap Resolution Review

각 Gap마다 다음 형식으로 검토한다.

```text
GAP
- 현재 누락된 책임

AUTHORITY EVIDENCE
- Product / ADR / Architecture / System / UI / Spec

MINIMUM BOUNDARY OPTIONS
- 현재 Foundation에 필요한 최소 경계 대안

DEFERRED DEPTH
- 지금 만들 필요가 없는 미래 구현 깊이

IMPACT
- System / Module / Stable Function / Execution Class / Checkpoint 영향

USER DECISION REQUIRED
- yes
```

사용자가 방향을 선택하기 전에는 System/Module/Stable Function 책임을 실질적으로 추가·분리·통합하지 않는다.

권장 검토 순서:

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

이 순서는 검토 순서일 뿐 자동 Architecture 승인 순서가 아니다.

## 3. Gap을 해결했을 때

사용자가 특정 Gap 방향을 확정하면 해당 범위에 대해서만:

```text
User Decision
→ Product / ADR / Architecture 영향 확인
→ Architecture Coverage Capability / Scenario / Gap 정합화
→ System Contract
→ Module Contract
→ Stable Function Contract
→ Execution Class
→ Validators
```

순으로 갱신한다.

Gap이 해소됐다는 이유로 미래 P2~P10의 내부 API를 한꺼번에 설계하지 않는다. 현재 Foundation/Exploration이 요구하는 최소 경계까지만 구체화한다.

## 4. E0 진입 조건

다음이 모두 충족되어야 E0 구현 명령으로 전환한다.

```text
architecture-coverage.json E0 blockedBy = []
implementationGate = READY_FOR_E0
validate_architecture_coverage.py PASS
validate_greenfield_boundary.py PASS
validate_module_contracts.py PASS
validate_execution_layers.py PASS
```

그 전에는 아래 E0 후보의 Source를 만들지 않는다.

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

이 목록 자체도 Coverage Gap Resolution 결과에 따라 사용자 승인 후 수정될 수 있다.

## 5. Coverage 해제 후 Execution 방식

Coverage Gate가 해제된 뒤의 개발 방식은 그대로다.

```text
E0 Repository Core Engine
→ E1 Roblox Runtime Integration
→ E2 Presentation / Feel
```

### CORE_ENGINE

- GitHub canonical source에서 먼저 구현.
- repository automated/negative tests.
- Human manual function testing 금지.

### ROBLOX_RUNTIME_ENGINE

- PathfindingService/raycast/physics 등 Roblox 결과가 correctness의 일부.
- Studio/MCP iteration + automated runtime test 허용.
- 최종 Source는 GitHub canonical.

### ROBLOX_INTEGRATION

- Remote/Player/Input/Instance/lifecycle 연결.
- Studio automated integration test.

### PRESENTATION_FEEL

- 실제 UI/visual/control feel.
- Studio self-check 후 사용자 Acceptance.

## 6. Pathfinding

현재 `GAP-005`가 OPEN이므로 구체 Pathfinding Module/API를 만들지 않는다.

상위 Navigation Architecture가 요구하는 Planner/Coordinator/Executor 책임과 Roblox Runtime PathfindingService 경계를 먼저 검토한다.

사용자 결정 후에만:

```text
Repository-side contract/policy
→ Roblox Runtime Engine adapter/planner integration
→ Human movement feel
```

의 정확한 Module split을 고정한다.

## 7. 사용자 Checkpoint

순서는 유지한다.

```text
S1 Selection
→ C1 Camera
→ M1 Move
→ X1 Context
→ I1 Interaction
```

하지만 각 Checkpoint는 자신의 Coverage phase blocker가 없어야 구현 가능하다.

예:

```text
S1
→ Runtime Object Identity
→ Spatial Query
→ Projection/ViewModel/Input Context
→ Visibility/Disclosure
```

같은 상위 경계가 미결이면 `SelectionController`에서 임시 Workspace 조회로 우회하지 않는다.

## 8. 사용자 최종 수용

```text
Authority Impact Scan
→ Product / ADR / Architecture / System / UI / Spec
→ Architecture Coverage Capability / Scenario / Gap
→ Execution / System / Module / Stable Function Contract
→ Source / Test 정합화
→ conflict re-scan
→ checkpoint(...) Promotion Commit
→ ACCEPTED
```

## 9. 금지

- Coverage blocker가 있는데 E0 Source 구현.
- Product Capability가 `UNMAPPED`인데 임시 helper/Domain으로 책임 숨기기.
- Spatial Query 대신 Controller가 Workspace를 직접 순회하도록 우회.
- Context Action을 대상 종류별 하드코딩 메뉴로 구현.
- Client가 Character/Interaction Capability availability를 자체 재계산.
- `WorldState.transact`가 상위 cross-domain Transaction 전체를 대체한다고 근거 없이 확정.
- MovementDomain에 Path Planner/Executor/Presentation을 임의 결합.
- Coverage Finding을 사용자 승인으로 해석해 Architecture 자동 변경.
- Legacy Source/Project 수정.
- ready-for-review / merge / force push.
