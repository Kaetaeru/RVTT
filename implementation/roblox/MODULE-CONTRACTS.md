# RVTT Module Contracts

- 상태: `ACTIVE · GREENFIELD_V3`
- 최종 갱신일: 2026-08-13
- Architecture Coverage: [`ARCHITECTURE-COVERAGE-POLICY.md`](ARCHITECTURE-COVERAGE-POLICY.md)
- Coverage Registry: [`manifests/architecture-coverage.json`](manifests/architecture-coverage.json)
- Module Registry: [`manifests/module-contracts.json`](manifests/module-contracts.json)
- System/Function Registry: [`manifests/system-function-contracts.json`](manifests/system-function-contracts.json)
- Execution Registry: [`manifests/execution-layers.json`](manifests/execution-layers.json)
- Execution Policy: [`GREENFIELD-EXECUTION-LAYERS.md`](GREENFIELD-EXECUTION-LAYERS.md)
- Validator: [`tooling/validate_architecture_coverage.py`](tooling/validate_architecture_coverage.py) + [`tooling/validate_module_contracts.py`](tooling/validate_module_contracts.py) + [`tooling/validate_execution_layers.py`](tooling/validate_execution_layers.py)

## 1. 네 Registry의 역할

```text
architecture-coverage.json
= Product Capability / Scenario / cross-cutting concern / missing boundary / phase gate

module-contracts.json
= Module / dependency / authority / state ownership / lifecycle / checkpoint

system-function-contracts.json
= System flow / invariant / Stable Function meaning

execution-layers.json
= Source authoring environment / automated verification / human-review boundary
```

각 Registry는 다른 질문에 답하며 서로 대체하지 않는다.

## 2. Source 이전 설계

현재 또는 다음 범위는 Source보다 먼저 다음을 가진다.

```text
Architecture Coverage
→ System Contract
→ Module Contract
→ Stable Function Contract
→ Execution Class
→ Source
```

Coverage는 `이 책임 자체가 빠졌는가`를 검사하고, Code Contract는 `선언된 책임의 경계가 맞는가`를 검사한다.

현재 Phase에 OPEN Blocking Gap이 있으면 Module이 이미 `PLANNED` 상태여도 Source 구현을 시작하지 않는다.

private/local helper와 정확한 내부 call graph는 Source-derived다.

## 3. Module Lifecycle

```text
PLANNED
→ IMPLEMENTED
→ ACCEPTED
→ DEPRECATED
```

- `PLANNED`: 책임/API/Execution Class가 선언됐다. 단 Coverage Gap 때문에 아직 Source 구현이 금지될 수 있다.
- `IMPLEMENTED`: 해당 Module의 필수 Source와 Execution Class verification이 완료되고 dependency/lifecycle/Coverage 조건을 충족한다.
- `ACCEPTED`: 사용자-visible Checkpoint 관련 Module은 Human Acceptance + Authority Reconciliation + Coverage 정합화 + Focused Test + Promotion Commit까지 완료했다.
- `DEPRECATED`: 현재 구조에서 사용하지 않는다.

즉 `Source file exists`만으로 `IMPLEMENTED`가 아니다.

## 4. Coverage와 Module 관계

모든 현재 Module은 최소 하나의 Product Capability에 연결되거나 명시적인 Infrastructure 이유를 가진다.

```text
Product Capability 없음
+ Infrastructure 이유 없음
→ ORPHAN MODULE
```

반대 방향도 중요하다.

```text
Current Capability 필요
+ 대응 System/Module 없음
→ UNMAPPED / PARTIAL
→ 해당 Phase BLOCKED
```

Coverage Finding은 새로운 Module을 자동 승인하지 않는다. 필요한 Module split/merge/addition이 실질적인 Architecture 변경이면 사용자 결정 후 Registry를 갱신한다.

## 5. systemStages의 의미

`module-contracts.json.systemStages`는 현재 Foundation의 **Architecture dependency / lifecycle promotion guard**다.

```text
G0 Shared Contracts
→ G1 Server Authority Core
→ G2 Command Transport
→ G3 Projection Pipeline
→ G4 Client World Shell
→ G5 Composition Boot
```

현재 Coverage Audit에서 상위 Architecture Gap이 발견됐기 때문에 이 Stage 목록은 **현재 Source 실행 명령이 아니다.** Gap Resolution 결과 Stage/System 책임 변경이 필요하면 사용자 승인 후 갱신한다.

Source authoring/test 환경의 권위는 `execution-layers.json`이다.

## 6. Execution Class

모든 현재 Module은 정확히 하나의 Execution Class를 가진다.

```text
CORE_ENGINE
ROBLOX_RUNTIME_ENGINE
ROBLOX_INTEGRATION
PRESENTATION_FEEL
```

현재 mapping은 `execution-layers.json`이 소유한다.

- CORE_ENGINE: Coverage-ready 후 GitHub repository-first + automated tests.
- ROBLOX_RUNTIME_ENGINE: Roblox runtime 의존 엔진. Studio/MCP iteration 허용, GitHub canonical.
- ROBLOX_INTEGRATION: Remote/Player/Input/Instance/composition integration. Studio automated.
- PRESENTATION_FEEL: 보이는 UX/조작감. Studio self-check + Human Acceptance.

Execution Class는 누락된 Product Responsibility를 대신하지 않는다.

## 7. Module 필드

```text
id
status
plannedPath
kind
responsibility
entryPoints
dependsOn
authority
stateOwnership
legacyCandidates
testRefs
```

Execution Class는 별도 `execution-layers.json`에서 Module ID를 기준으로 1:1 매핑한다.

`entryPoints`는 Stable Function 이름 인덱스이고 실제 함수 의미는 `system-function-contracts.json`이 소유한다.

## 8. Stable Function

다른 Contract-bearing Module이 호출하는 함수는 구현 전에 Stable Function Contract가 있어야 한다.

필수 의미:

```text
name / kind / purpose / inputs / output
authority / reads / writes / sideEffects
failureModes / idempotency / validation
permission / revisionBehavior
```

undeclared cross-module call은 `CONTRACT_DRIFT`다.

Coverage에서 필요한 책임이 아직 UNMAPPED인데 기존 Module에 임시 Stable Function을 추가해 책임을 숨기지 않는다.

## 9. Test Gate

Execution Class별 1차 검증 권위:

```text
CORE_ENGINE
→ repository automated tests

ROBLOX_RUNTIME_ENGINE
→ repository contract tests + greenfield/tests/studio runtime tests

ROBLOX_INTEGRATION
→ greenfield/tests/studio automated integration tests

PRESENTATION_FEEL
→ Studio self-check + Human Acceptance
```

이 Test Gate 전에 해당 Capability/Scenario의 Coverage Phase Gate가 READY여야 한다.

## 10. Pathfinding

Pathfinding 같은 기능은 한 덩어리로 `Studio-only` 처리하지 않는다.

현재 Coverage `GAP-005`가 OPEN이므로 구체 Module split/API는 아직 확정하지 않는다.

Gap 해결 후:

- pure request/result/policy는 CORE_ENGINE 후보.
- Roblox Navigation/PathfindingService, NavMesh, collision/raycast 결과 의존부는 ROBLOX_RUNTIME_ENGINE 후보.
- 화면 경로 표시/클릭 반응/이동 감각은 PRESENTATION_FEEL.

## 11. User Checkpoint

```text
S1 Selection
→ C1 Camera
→ M1 Move
→ X1 Context
→ I1 Interaction
```

각 Checkpoint는 `architecture-coverage.json`의 해당 Phase blocker가 없어야 구현할 수 있다.

사용자는 Presentation/Feel을 평가한다.

## 12. Source 정합화

어느 환경에서 수정했든 최종 상태는:

- Coverage Capability/Scenario와 책임 정합
- `greenfield/src` Canonical Source
- `greenfield.project.json` 재현 가능
- Contract와 Source 일치
- 해당 Execution Class Test Gate PASS

여야 한다.

Studio-only production truth는 허용하지 않는다.

## 13. Architecture 변경

Coverage Gap 해결, Execution Class 변경이 Authority, state owner, Module responsibility, System flow를 바꾸면 사용자에게 먼저 제안한다.
