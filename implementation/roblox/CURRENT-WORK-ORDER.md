# RVTT Roblox Implementation 현재 작업 순서

- 상태: `BLOCKED_BY_ARCHITECTURE_COVERAGE`
- 최종 갱신일: 2026-08-13
- 현재 실행 포인터: [`../../.github/CODEX-ACTIVE-TASK.md`](../../.github/CODEX-ACTIVE-TASK.md)
- Architecture Coverage: [`ARCHITECTURE-COVERAGE-POLICY.md`](ARCHITECTURE-COVERAGE-POLICY.md)
- Coverage Registry: [`manifests/architecture-coverage.json`](manifests/architecture-coverage.json)
- Initial Audit: [`audits/ARCHITECTURE-COVERAGE-AUDIT-001.md`](audits/ARCHITECTURE-COVERAGE-AUDIT-001.md)
- Execution Layers: [`GREENFIELD-EXECUTION-LAYERS.md`](GREENFIELD-EXECUTION-LAYERS.md)
- System Sequence: [`GREENFIELD-SYSTEM-SEQUENCE.md`](GREENFIELD-SYSTEM-SEQUENCE.md)
- Code Contract: [`MODULE-CONTRACTS.md`](MODULE-CONTRACTS.md) + [`SYSTEM-FUNCTION-CONTRACTS.md`](SYSTEM-FUNCTION-CONTRACTS.md)

## 현재 상태

지금은 Source 구현 단계가 아니다.

```text
Authority Corpus Scan
→ Capability / Scenario / Cross-cutting Coverage
→ Gap Resolution
→ Coverage Gate READY
→ E0 Repository Core Engine
→ E1 Roblox Runtime Integration
→ E2 Presentation / Feel
```

Initial Coverage Audit에서 현재 Greenfield 계획과 확정 상위 Architecture 사이의 구조적 누락을 발견했다.

## 현재 E0 Blocker

```text
GAP-001 Session Policy Boundary
GAP-002 Transaction / Event / Projection Barrier
GAP-003 Runtime Object / Scene Identity
GAP-005 Navigation / Movement Boundary
GAP-007 Capability / Action Availability Projection
GAP-008 RuleExecution Boundary
```

따라서 기존 E0 후보 Source를 지금 구현하지 않는다.

## Coverage 검사

```text
python implementation/roblox/tooling/validate_architecture_coverage.py
```

Validator PASS는 Coverage Registry 자체가 정합적이라는 뜻이다.

```text
implementationGate = BLOCKED_...
```

이면 Source는 여전히 금지한다.

Authority Corpus의 Product/ADR/Architecture/System/UI/Spec Root가 변경되면 Coverage Tree Snapshot이 달라져 CI가 실패하도록 한다. 변경 내용을 Capability/Scenario/Gap에 반영한 뒤 Snapshot을 갱신한다.

## Gap 해결 방식

Gap을 발견했다고 Codex가 새 System/Module을 자동으로 추가하지 않는다.

```text
Gap Evidence
→ 현재 누락 책임 설명
→ 최소 경계 대안
→ 미래로 미룰 깊이
→ 기존 System/Module/Function 영향
→ 사용자 결정
→ Top-down Contract Reconciliation
→ Gap RESOLVED
```

현재 권장 검토 순서:

```text
GAP-002 Transaction/Event/Projection Barrier
→ GAP-001 Session Policy
→ GAP-003 Runtime Object Identity
→ GAP-004 Spatial Query
→ Selection 재검증
→ GAP-005 Navigation/Pathfinding
→ GAP-007 Capability/Availability
→ GAP-008 RuleExecution
→ GAP-006 Interaction Query
→ GAP-009 Client ViewModel/Input Recovery
→ GAP-010 Visibility/Knowledge
```

## 기존 E0 후보

Coverage 해결 전까지 다음은 **잠정 후보**다.

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

Gap 해결 결과 책임 분할/통합/추가가 필요하면 사용자 승인 후 System/Module/Stable Function Contract를 수정한다.

## E0 진입 조건

```text
architecture-coverage.json E0 blockedBy = []
implementationGate = READY_FOR_E0
validate_architecture_coverage.py PASS
validate_greenfield_boundary.py PASS
validate_module_contracts.py PASS
validate_execution_layers.py PASS
```

그 후에만 GitHub `greenfield/src`에 Core Engine을 구현하고 `greenfield/tests`에서 자동 테스트한다.

## E1 / E2 원칙

Coverage 해제 후 개발 방식은 유지한다.

```text
E0 Repository Core Engine
→ E1 Roblox Runtime Integration
→ E2 Presentation / Feel
```

- Roblox Runtime 없이 검증 가능한 Engine은 GitHub-first.
- PathfindingService/raycast/physics 같은 Runtime Engine은 Studio/MCP 자동 검증 후 GitHub canonicalize.
- UI/조작감만 Human Checkpoint.

현재 Pathfinding은 `GAP-005`가 해결되기 전 구체 Module/API를 만들지 않는다.

## 사용자 Checkpoint 순서

```text
S1 Selection
→ C1 Camera
→ M1 Move
→ X1 Context
→ I1 Interaction
```

순서는 유지하지만 각 Checkpoint의 Coverage blocker가 모두 해소된 뒤에만 구현한다.

## 확정 Gate

```text
사용자 수용
→ Authority Reconciliation
→ Product/ADR/Architecture/System/UI/Spec
→ Architecture Coverage Capability/Scenario/Gap
→ Execution/System/Module/Function Contract
→ Canonical Source/Test
→ Promotion Commit
→ ACCEPTED
```

## 금지

- Coverage blocker를 코드로 우회.
- `UNMAPPED` Capability를 임시 Domain/helper 안에 숨겨 구현.
- 미래 P2~P10 전체 내부 API를 선행 설계.
- Legacy Source/Project 수정.
- 사용자 승인 없이 Gap 해결 Architecture 적용.
