# RVTT Roblox Implementation 현재 작업 순서

- 상태: `READY_FOR_E0_REPOSITORY_ENGINE`
- 최종 갱신일: 2026-08-13
- 현재 실행 포인터: [`../../.github/CODEX-ACTIVE-TASK.md`](../../.github/CODEX-ACTIVE-TASK.md)
- Execution Layers: [`GREENFIELD-EXECUTION-LAYERS.md`](GREENFIELD-EXECUTION-LAYERS.md)
- System Sequence: [`GREENFIELD-SYSTEM-SEQUENCE.md`](GREENFIELD-SYSTEM-SEQUENCE.md)
- Code Contract: [`MODULE-CONTRACTS.md`](MODULE-CONTRACTS.md) + [`SYSTEM-FUNCTION-CONTRACTS.md`](SYSTEM-FUNCTION-CONTRACTS.md)

## 현재 실행 순서

```text
E0 Repository Core Engine
→ E1 Roblox Runtime Integration
→ E2 Presentation / Feel
```

## E0 — 지금 먼저 할 것

GitHub `greenfield/src`에 다음 Engine을 구현하고 `greenfield/tests`에서 자동 테스트한다.

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

Studio/MCP Handshake를 기다릴 필요가 없다.

E0 Done:

- System/Module/Stable Function Contract 일치.
- Repository automated tests PASS.
- negative/fail-closed cases PASS.
- unresolved Contract Drift 없음.

## E1 — 그 다음

Studio Integration Gate 후:

```text
CommandGateway / CommandClient
ProjectionGateway / ProjectionReplica
SemanticInputRouter / WorldSystem
ServerApp / ServerBootstrap
ClientApp / ClientBootstrap
```

Codex/MCP가 Runtime Integration을 자동 테스트한다.

사용자에게 UX 테스트를 요구하지 않는다.

PathfindingService/raycast/physics처럼 Roblox Runtime에 의존하는 Engine이 필요하면 `ROBLOX_RUNTIME_ENGINE`으로 E1에서 개발·검증하되 최종 Source는 GitHub에 canonicalize한다.

## E2 — 그 다음 사용자 기능

```text
S1 Selection
→ C1 Camera
→ M1 Move
→ X1 Context
→ I1 Interaction
```

각 기능은 Studio self-check 후 사용자에게 보여준다. 마음에 들지 않으면 같은 Checkpoint에서 즉시 수정한다.

## Pathfinding

현재는 구체 Module/API를 미리 만들지 않는다.

Movement Checkpoint 직전에:

```text
pure contract/policy
→ Repository

PathfindingService/NavMesh/Collision/Raycast
→ Studio Runtime Engine

preview/response/smoothness
→ Human Feel
```

원칙에 맞는 구체 Module split을 사용자에게 먼저 제안한다.

## 확정 Gate

```text
사용자 수용
→ Authority Reconciliation
→ Execution/System/Module/Function Contract
→ Canonical Source/Test
→ Promotion Commit
→ ACCEPTED
```

## 금지

- Studio를 pure Engine 코드 에디터로 사용하고 GitHub 구현을 미룸.
- Console 한번 성공으로 Engine PASS 선언.
- E0/E1 완료 전 user-visible feature를 우회 구현.
- Studio-only Runtime Engine Source.
- 미래 미확정 P2~P10 Domain/API 선행 구현.
- Legacy Source/Project 수정.
- 사용자 승인 없이 Execution Class/Architecture/Authority 변경.
