# RVTT Greenfield — Engine → Integration → Presentation 001

- 상태: `ACTIVE · CURRENT_COMMAND · READY_FOR_E0`
- Build mode: `GREENFIELD_ARCHITECTURE_FIRST`
- Execution authority: [`../implementation/roblox/GREENFIELD-EXECUTION-LAYERS.md`](../implementation/roblox/GREENFIELD-EXECUTION-LAYERS.md)
- Execution registry: `implementation/roblox/manifests/execution-layers.json`
- Sequence authority: [`../implementation/roblox/GREENFIELD-SYSTEM-SEQUENCE.md`](../implementation/roblox/GREENFIELD-SYSTEM-SEQUENCE.md)
- Code contract: [`../implementation/roblox/MODULE-CONTRACTS.md`](../implementation/roblox/MODULE-CONTRACTS.md) + [`../implementation/roblox/SYSTEM-FUNCTION-CONTRACTS.md`](../implementation/roblox/SYSTEM-FUNCTION-CONTRACTS.md)

## 목표

보이지 않는 Engine을 GitHub에서 먼저 완성·자동 테스트하고, Roblox Runtime 연결은 Studio/MCP에서 자동 통합 검증한 뒤, UI/조작감만 사용자 Checkpoint로 넘긴다.

```text
E0 Repository Core Engine
→ E1 Roblox Runtime Integration
→ E2 Presentation / Feel
```

## 0. 구현 전 읽기

1. `AGENTS.md`
2. `.github/CODEX-ACTIVE-TASK.md`
3. `implementation/roblox/GREENFIELD-EXECUTION-LAYERS.md`
4. `implementation/roblox/manifests/execution-layers.json`
5. `implementation/roblox/GREENFIELD-PREFLIGHT.md`
6. `implementation/roblox/GREENFIELD-SYSTEM-SEQUENCE.md`
7. `implementation/roblox/MODULE-CONTRACTS.md`
8. `implementation/roblox/SYSTEM-FUNCTION-CONTRACTS.md`
9. 두 Contract Registry
10. 관련 Product/ADR/Spec

## 1. E0 Repository Gate

Studio에 들어가기 전에:

```text
python implementation/roblox/tooling/validate_greenfield_boundary.py
python implementation/roblox/tooling/validate_module_contracts.py
python implementation/roblox/tooling/validate_execution_layers.py
```

PASS하면 E0를 시작한다. Studio/MCP Handshake는 E0 blocker가 아니다.

## 2. E0 Repository Core Engine

먼저 다음 Source를 `greenfield/src`에 구현한다.

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

Stable Function Contract를 그대로 구현한다.

### 필수 Repository Tests

`greenfield/tests`에 반복 가능한 test를 만든다.

- bounded envelope validation
- invalid/malformed data
- untrusted role/owner/controller claim rejection
- SessionAuthority role/control query
- WorldState snapshot/revision/transact
- failed transaction does not advance revision
- successful transaction advances revision once
- Authorization allow/deny
- duplicate commandId
- stale expected revision
- Projection disclosure filtering
- MovementDomain valid/invalid destination and permission semantics
- ExplorationDomain valid/invalid target/context semantics
- structured error/result behavior

Console에서 한 번 성공한 것은 Test PASS가 아니다.

E0 완료 보고:

```text
E0 CORE ENGINE
- source: COMPLETE
- repository tests: PASS
- negative tests: PASS
- unresolved contract drift: NONE
```

## 3. E1 Studio Integration Gate

E0 이후에만 Studio/MCP를 준비한다.

```text
rojo build implementation/roblox/greenfield.project.json --output <temp-place>
```

그 다음:

- Greenfield Place/Session identity 확인
- MCP capability 확인
- Play/Output 확인 경로 확보
- Studio automated harness 실행 가능 여부 확인

## 4. E1 Roblox Runtime Integration

다음을 연결한다.

```text
CommandGateway / CommandClient
ProjectionGateway / ProjectionReplica
SemanticInputRouter / WorldSystem
ServerApp / ServerBootstrap
ClientApp / ClientBootstrap
```

자동 통합 검증:

- Remote malformed/oversized/rate-limited input
- actual Player identity 사용
- command receipt correlation
- Projection epoch/revision
- initial/full projection
- semantic input adapter
- composition start/destroy
- duplicate start / cleanup / failure path

이 단계에서 사용자에게 UX 테스트를 요구하지 않는다.

## 5. Runtime-coupled Engine

실제 Roblox Runtime이 correctness의 일부인 Engine은 Studio에서 개발·튜닝할 수 있다.

대표:

```text
PathfindingService
Raycast
Physics / Collision
Streaming
DataStore adapter
```

규칙:

```text
Contract / pure policy
→ GitHub

Roblox service-dependent implementation
→ Studio/MCP iteration allowed
→ Studio automated runtime test
→ greenfield/src canonicalize
```

### Pathfinding

Repository에서 먼저 정의할 것:

- request/result contract
- permission/budget
- failure/recompute semantics
- pure waypoint/policy normalization

Studio에서 검증할 것:

- PathfindingService
- NavMesh/Agent parameter
- obstacle/collision/raycast
- dynamic recompute

사람에게 보여줄 것:

- path preview readability
- click response
- movement smoothness

구체 Pathfinding Module/API는 M1 직전에 사용자에게 제안·확정한다.

## 6. E2 Presentation / Feel

Engine/Integration이 준비되면 사용자-visible vertical slice를 순서대로 구현한다.

```text
S1 Selection
→ C1 Camera
→ M1 Move
→ X1 Context
→ I1 Interaction
```

### S1 Selection

```text
SemanticInputRouter
→ SelectionController
→ local selection state
→ WorldPresenter
```

Codex가 Studio self-check 후 `READY_FOR_USER`에서 멈춘다.

### C1 Camera

CameraController의 실제 orbit/pan/zoom/framing 감각을 사용자에게 테스트받는다.

### M1 Move

이미 검증된 Engine을 재사용한다.

```text
MovementController
→ CommandClient
→ CommandGateway
→ CommandRuntime
→ AuthorizationService
→ MovementDomain
→ WorldState.transact
→ ProjectionService
→ ProjectionGateway
→ ProjectionReplica
→ WorldPresenter
```

Pathfinding Runtime Engine이 필요하면 먼저 Studio automated runtime gate를 통과한다.

### X1 / I1

이미 Repository에서 검증한 ExplorationDomain과 표준 Command/Projection path를 사용한다. 사용자에게는 Context/Interaction UX를 테스트받는다.

## 7. 사용자 Feedback

```text
READY_FOR_USER
→ CHANGE_REQUESTED
→ 같은 Checkpoint 즉시 수정
→ Studio self-check
→ READY_FOR_USER
```

다음 Presentation 기능으로 피드백을 미루지 않는다.

## 8. 사용자 최종 수용

```text
Authority Impact Scan
→ Product/ADR/Architecture/Spec
→ Execution/System/Module/Function Contract
→ Source/Test 정합화
→ conflict re-scan
→ checkpoint(...) Promotion Commit
→ ACCEPTED
→ 다음 Checkpoint
```

## 9. 금지

- Pure Core Engine을 Studio에서만 구현.
- Studio Console 수동 호출만으로 Engine PASS 선언.
- E0 repository test 전 Presentation 착수.
- Runtime-coupled code를 Studio-only Source로 방치.
- 사용자에게 Engine 내부 함수 correctness를 대신 검증시킴.
- undeclared cross-module call.
- Client authoritative mutation.
- direct UI Remote.
- Bootstrap gameplay logic.
- Legacy Source/Project 수정.
- 사용자 승인 없이 Authority/Module/System/Execution Class 변경.
