# RVTT Greenfield System Sequence

- 상태: `ACTIVE · BUILD_ORDER_AUTHORITY`
- 최종 갱신일: 2026-08-13
- Execution environment authority: [`GREENFIELD-EXECUTION-LAYERS.md`](GREENFIELD-EXECUTION-LAYERS.md)
- Machine-readable execution plan: [`manifests/execution-layers.json`](manifests/execution-layers.json)
- Module contract: [`manifests/module-contracts.json`](manifests/module-contracts.json)
- 확정 동기화 Gate: [`AUTHORITY-RECONCILIATION-POLICY.md`](AUTHORITY-RECONCILIATION-POLICY.md)

이 문서는 **무엇을 어떤 의존 순서로 준비하고 언제 사용자 기능으로 올라갈지**를 소유한다.

현재 원칙은 `모든 것을 Studio에서 수직으로 하나씩 만드는 방식`이 아니다.

```text
E0 Repository Core Engine
→ E1 Roblox Runtime Integration
→ E2 Presentation / Feel Checkpoints
```

Studio는 일반 코드 작성 환경이 아니라 Roblox Runtime 검증과 사용자 경험 검증에 집중한다.

## 0. PRE-G0 Workbench Gate

구현 시작 전 Repository/Greenfield 경계를 확인한다.

- `greenfield.project.json`은 `greenfield/src`만 Mapping한다.
- Legacy `src`와 `default.project.json`은 read-only reference다.
- Boundary / Module / System / Function / Execution Layer Validator가 PASS한다.
- Greenfield Rojo Build가 성공한다.
- Studio/MCP Capability를 확인한다.

Preflight는 제품 시스템 Stage가 아니다.

## 1. E0 — Repository Core Engine

사용자가 직접 볼 필요가 없고 Roblox Runtime 없이 correctness를 검증할 수 있는 코드를 먼저 GitHub에서 구현·테스트한다.

현재 E0:

```text
Shared Contracts
- CommandEnvelope
- ProjectionEnvelope
- WorldContract

Authority / State / Command
- SessionAuthority
- WorldState
- AuthorizationService
- CommandRuntime

Core Projection / Domains
- ProjectionService
- MovementDomain
- ExplorationDomain
```

핵심 순서:

```text
Shared Contract
→ SessionAuthority / WorldState
→ AuthorizationService
→ CommandRuntime
→ ProjectionService
→ MovementDomain / ExplorationDomain
```

E0 Gate:

- Stable Function Contract와 Source가 일치한다.
- Repository automated test가 PASS한다.
- malformed/unauthorized/duplicate/stale revision이 fail closed다.
- `WorldState.transact` revision semantics가 검증된다.
- viewer disclosure policy가 테스트된다.
- Movement/Exploration Domain의 정상/실패 케이스가 테스트된다.

사람에게 이 함수들을 하나씩 Studio에서 테스트시키지 않는다.

### Module Contract의 G0~G5와 관계

`module-contracts.json.systemStages`는 Architecture dependency와 lifecycle promotion guard로 유지된다.

**Source authoring/test 환경의 현재 권위는 `execution-layers.json`이다.** 따라서 E0 Core Source는 Repository에서 먼저 작성·테스트할 수 있다. Module의 `IMPLEMENTED` 승격과 실제 wiring은 선언된 dependency가 충족될 때 수행한다.

## 2. E1 — Roblox Runtime Integration

E0에서 테스트된 Engine을 Roblox Runtime에 연결한다.

현재 E1:

```text
CommandGateway
CommandClient
ProjectionGateway
ProjectionReplica
SemanticInputRouter
WorldSystem
ServerApp / ServerBootstrap
ClientApp / ClientBootstrap
```

필수 흐름:

```text
CORE_ENGINE_READY
→ Rojo Build
→ Studio Boot
→ Remote / Player / Instance / Input Adapter 연결
→ Codex/MCP 자동 통합 테스트
→ lifecycle/error/reconnect 확인
→ INTEGRATION_READY
```

E1에서는 사용자 UX 판정을 요구하지 않는다.

검증 대상:

- Remote payload validation/rate limit
- 실제 Roblox `Player` identity 전달
- Command receipt correlation
- viewer-safe Projection 송수신
- epoch/revision regression rejection
- semantic input routing
- App/Bootstrap composition
- cleanup / double-start / partial failure

## 3. Runtime-coupled Engine 예외

엔진 코드라도 실제 Roblox 환경 없이는 correctness를 판단할 수 없으면 `ROBLOX_RUNTIME_ENGINE`으로 분류한다.

대표:

```text
PathfindingService
Raycast / spatial query
Physics / Collision
Streaming-sensitive resolution
DataStore / MemoryStore adapters
```

이 경우 Studio/MCP에서 엔진 구현·튜닝 루프를 도는 것을 허용한다.

단 최종 Source는 항상 `greenfield/src`에 canonicalize한다.

### Pathfinding의 고정 분리 원칙

```text
Repository
= Request/Result Contract
  + movement permission/budget
  + failure/recompute semantics
  + pure policy/normalization

Studio Runtime
= PathfindingService
  + NavMesh/Agent parameter
  + actual obstacle/collision geometry
  + raycast
  + dynamic obstruction/recompute

Human Feel
= path preview readability
  + click response
  + movement smoothness
```

Pathfinding의 구체 Module split/API는 Movement 구현 직전에 제안·확정한다. 현재 문서는 미리 특정 구조를 강제하지 않는다.

## 4. E2 — Presentation / Feel

Engine과 Runtime Integration이 준비된 뒤 사용자에게 보이는 수직 슬라이스를 만든다.

```text
S1_SELECTION
→ C1_CAMERA
→ M1_MOVE
→ X1_CONTEXT
→ I1_INTERACTION
```

### S1 Selection

```text
SemanticInputRouter
→ SelectionController
→ local selection state
→ WorldPresenter
→ READY_FOR_USER
```

### C1 Camera

```text
SemanticInputRouter
→ CameraController
→ local camera state
→ READY_FOR_USER
```

### M1 Move

Move 시점에는 Server Engine을 새로 만드는 것이 아니라 이미 테스트된 Engine/Integration을 사용한다.

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

Pathfinding이 필요하면 `ROBLOX_RUNTIME_ENGINE` Gate를 Movement presentation 전에 통과한다.

### X1 Context / I1 Interaction

이미 테스트된 `ExplorationDomain`과 표준 Command/Projection 경로를 사용하고, 이 단계에서는 context presentation과 실제 조작 UX를 집중 검증한다.

## 5. Human Checkpoint 규칙

각 사용자 Checkpoint 상태:

```text
PLANNED
IMPLEMENTING
READY_FOR_USER
ACCEPTED
BLOCKED
```

- `READY_FOR_USER`이면 다음 UI/Feel 기능을 진행하지 않는다.
- 사용자가 마음에 들지 않으면 같은 Checkpoint를 즉시 수정한다.
- Engine unit test 결과를 사용자에게 수동 검증시키지 않는다.
- 사용자가 수용해도 즉시 `ACCEPTED`로 올리지 않는다.
- Authority Reconciliation + Canonical Source + Focused Test + Promotion Commit 후 `ACCEPTED`다.

## 6. Exploration 이후 큰 제품 순서

```text
P0 Foundation
→ P1 Exploration Core
→ P2 Session·Role·Reconnect·Recovery
→ P3 Encounter + Character Console
→ P4 Character Data Surfaces
→ P5 DM Live Workspace
→ P6 Rules·Content Runtime
→ P7 Persistence·Migration·Rollback
→ P8 ADR-0092 Survival Logistics + Actor Authoring
→ P9 Multi-client·Disclosure·Accessibility·Performance Hardening
→ P10 Release Acceptance
```

각 P단계도 내부적으로 가능한 범위에서 동일한 순서를 쓴다.

```text
Core Engine repository-first
→ Runtime-coupled/Integration Studio automated
→ Presentation/Feel Human checkpoint
```

아직 Product 의미가 확정되지 않은 먼 미래 Domain/API를 미리 구현하지 않는다.

## 7. 비협상 기술 안전 규칙

1. gameplay mutation 최종 권한은 Server다.
2. Client Role/Owner/Controller claim은 untrusted다.
3. authoritative mutation은 단일 Command boundary를 통과한다.
4. Remote payload type/size/depth/rate를 제한한다.
5. Network에 Roblox Instance를 보내지 않는다.
6. commandId/epoch/revision을 검증한다.
7. duplicate/stale mutation은 fail closed다.
8. Projection은 viewer-safe다.
9. UI/Presenter가 Remote를 직접 소유하지 않는다.
10. Bootstrap/App은 composition/lifecycle만 담당한다.
11. lifecycle cleanup을 명시한다.
12. 오류를 조용히 삼키지 않고 structured diagnostic을 남긴다.
13. Domain/Controller가 DataStore를 직접 호출하지 않는다.
14. Studio-only production truth를 허용하지 않는다.
15. Legacy Source/Project는 read-only reference다.
16. undeclared cross-module Stable Function 호출을 허용하지 않는다.

## 8. 변경 Gate

Execution Class, 시스템 순서, Authority, state owner, Module responsibility 또는 개발 방식을 바꾸려면 사용자에게 먼저 제안한다.

사용자가 승인한 현재 방식은 `Repository Core Engine → Studio Runtime Integration → Human Presentation/Feel`이다.
