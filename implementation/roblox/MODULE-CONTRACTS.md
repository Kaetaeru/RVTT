# RVTT Module Contracts

- 상태: `ACTIVE · GREENFIELD_V3`
- 최종 갱신일: 2026-08-13
- Module Registry: [`manifests/module-contracts.json`](manifests/module-contracts.json)
- System/Function Registry: [`manifests/system-function-contracts.json`](manifests/system-function-contracts.json)
- Execution Registry: [`manifests/execution-layers.json`](manifests/execution-layers.json)
- Execution Policy: [`GREENFIELD-EXECUTION-LAYERS.md`](GREENFIELD-EXECUTION-LAYERS.md)
- Validator: [`tooling/validate_module_contracts.py`](tooling/validate_module_contracts.py) + [`tooling/validate_execution_layers.py`](tooling/validate_execution_layers.py)

## 1. 세 Registry의 역할

```text
module-contracts.json
= Module / dependency / authority / state ownership / lifecycle / checkpoint

system-function-contracts.json
= System flow / invariant / Stable Function meaning

execution-layers.json
= Source authoring environment / automated verification / human-review boundary
```

세 Registry는 서로 다른 질문에 답하며 서로 대체하지 않는다.

## 2. Source 이전 설계

현재 또는 다음 범위는 Source보다 먼저 다음을 가진다.

```text
System Contract
→ Module Contract
→ Stable Function Contract
→ Execution Class
→ Source
```

private/local helper와 정확한 내부 call graph는 Source-derived다.

## 3. Module Lifecycle

```text
PLANNED
→ IMPLEMENTED
→ ACCEPTED
→ DEPRECATED
```

- `PLANNED`: 책임/API/Execution Class가 선언됐다. Source가 없어도 된다. Repository-first Engine의 경우 wiring 전 Source와 tests가 선행 존재할 수 있다.
- `IMPLEMENTED`: 해당 Module의 필수 Source와 해당 Execution Class의 required verification이 완료되고 실제 dependency/wiring 조건을 충족한다.
- `ACCEPTED`: 사용자-visible Checkpoint 관련 Module은 Human Acceptance + Authority Reconciliation + Focused Test + Promotion Commit까지 완료했다.
- `DEPRECATED`: 현재 구조에서 사용하지 않는다.

즉 `Source file exists`만으로 `IMPLEMENTED`가 아니다.

## 4. systemStages의 의미

`module-contracts.json.systemStages`는 Foundation의 **Architecture dependency / lifecycle promotion guard**다.

```text
G0 Shared Contracts
→ G1 Server Authority Core
→ G2 Command Transport
→ G3 Projection Pipeline
→ G4 Client World Shell
→ G5 Composition Boot
```

이 값은 이제 `어느 에디터에서 Source를 먼저 작성해야 하는가`를 결정하지 않는다.

Source authoring/test 환경의 권위는 `execution-layers.json`이다.

예를 들어 `ProjectionService`와 Movement/Exploration Domain은 Repository E0에서 미리 구현·테스트할 수 있다. 실제 `IMPLEMENTED` 승격과 wiring은 Module dependency/lifecycle Gate를 만족할 때 수행한다.

## 5. Execution Class

모든 현재 Module은 정확히 하나의 Execution Class를 가진다.

```text
CORE_ENGINE
ROBLOX_RUNTIME_ENGINE
ROBLOX_INTEGRATION
PRESENTATION_FEEL
```

현재 mapping은 `execution-layers.json`이 소유한다.

- CORE_ENGINE: GitHub repository-first + automated tests.
- ROBLOX_RUNTIME_ENGINE: Roblox runtime 의존 엔진. Studio/MCP iteration 허용, GitHub canonical.
- ROBLOX_INTEGRATION: Remote/Player/Input/Instance/composition integration. Studio automated.
- PRESENTATION_FEEL: 보이는 UX/조작감. Studio self-check + Human Acceptance.

## 6. Module 필드

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

## 7. Stable Function

다른 Contract-bearing Module이 호출하는 함수는 구현 전에 Stable Function Contract가 있어야 한다.

필수 의미:

```text
name / kind / purpose / inputs / output
authority / reads / writes / sideEffects
failureModes / idempotency / validation
permission / revisionBehavior
```

undeclared cross-module call은 `CONTRACT_DRIFT`다.

## 8. Test Gate

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

`validate_execution_layers.py`는 현재 Module coverage, phase coverage, checkpoint order와 Execution Class별 test gate를 검사한다.

## 9. Pathfinding

Pathfinding 같은 기능은 한 덩어리로 `Studio-only` 처리하지 않는다.

- pure request/result/policy는 CORE_ENGINE.
- `PathfindingService`, NavMesh, collision/raycast 결과 의존부는 ROBLOX_RUNTIME_ENGINE.
- 화면 경로 표시/클릭 반응/이동 감각은 PRESENTATION_FEEL.

구체 Module split/API는 Movement 구현 직전에 사용자 결정 보호 규칙에 따라 확정한다.

## 10. User Checkpoint

```text
S1 Selection
→ C1 Camera
→ M1 Move
→ X1 Context
→ I1 Interaction
```

Engine/Integration을 사용자 Checkpoint와 같은 속도로 억지로 만들지 않는다. 가능한 보이지 않는 Engine과 Integration은 먼저 자동 검증한다.

사용자는 Presentation/Feel을 평가한다.

## 11. Source 정합화

어느 환경에서 수정했든 최종 상태는:

- `greenfield/src` Canonical Source
- `greenfield.project.json` 재현 가능
- Contract와 Source 일치
- 해당 Execution Class Test Gate PASS

여야 한다.

Studio-only production truth는 허용하지 않는다.

## 12. Architecture 변경

Execution Class 변경이 단순 테스트 위치를 넘어 Authority, state owner, Module responsibility, System flow를 바꾸면 사용자에게 먼저 제안한다.
