# RVTT Greenfield System Sequence

- 상태: `ACTIVE · BUILD_ORDER_AUTHORITY · EXECUTION_BLOCKED_BY_COVERAGE`
- 최종 갱신일: 2026-08-13
- Architecture Coverage: [`ARCHITECTURE-COVERAGE-POLICY.md`](ARCHITECTURE-COVERAGE-POLICY.md)
- Coverage Registry: [`manifests/architecture-coverage.json`](manifests/architecture-coverage.json)
- Execution environment authority: [`GREENFIELD-EXECUTION-LAYERS.md`](GREENFIELD-EXECUTION-LAYERS.md)
- Machine-readable execution plan: [`manifests/execution-layers.json`](manifests/execution-layers.json)
- Module contract: [`manifests/module-contracts.json`](manifests/module-contracts.json)
- 확정 동기화 Gate: [`AUTHORITY-RECONCILIATION-POLICY.md`](AUTHORITY-RECONCILIATION-POLICY.md)

이 문서는 **Coverage에서 필요성이 확인된 시스템을 어떤 의존 순서로 준비하고 언제 사용자 기능으로 올릴지**를 소유한다.

현재 Initial Architecture Coverage Audit에서 Foundation 책임 누락 후보가 발견됐다. 따라서 아래 기존 G0~G5/System 목록은 **현재 계획의 의존 그래프**로 보존하지만 Gap Resolution 전 Source 실행 명령으로 사용하지 않는다.

```text
Architecture Coverage Gap Resolution
→ 승인된 System Sequence 정합화
→ E0 Repository Core Engine
→ E1 Roblox Runtime Integration
→ E2 Presentation / Feel Checkpoints
```

Coverage Finding 때문에 실제 Stage/System 책임을 바꿔야 하면 사용자 승인 후 이 문서를 갱신한다. Codex가 아래 순서만 보고 누락 책임을 기존 Module에 몰아넣지 않는다.

Studio는 일반 코드 작성 환경이 아니라 Roblox Runtime 검증과 사용자 경험 검증에 집중한다.

## 0. Architecture Coverage + Preflight Gate

Source 구현 전 먼저 `GREENFIELD-PREFLIGHT.md`의 P0 Architecture Coverage Gate를 통과한다.

```text
python implementation/roblox/tooling/validate_architecture_coverage.py
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

이 Gap이 OPEN인 동안 아래 E0 후보 Source를 구현하지 않는다.

Coverage가 READY가 된 뒤 Repository/Greenfield 경계를 확인한다.

- `greenfield.project.json`은 `greenfield/src`만 Mapping한다.
- Legacy `src`와 `default.project.json`은 read-only reference다.
- Boundary / Coverage / Module / System / Function / Execution Layer Validator가 PASS한다.

Studio/MCP Capability는 E1 Runtime Integration 직전에 확인한다.

Preflight는 제품 시스템 Stage가 아니다.

## 1. 현재 잠정 E0 — Repository Core Engine

현재 Execution Registry에 분류된 후보:

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

현재 의존 순서 후보:

```text
Shared Contract
→ SessionAuthority / WorldState
→ AuthorizationService
→ CommandRuntime
→ ProjectionService
→ MovementDomain / ExplorationDomain
```

**이 순서는 Coverage Gap 해결 후 재검증한다.**

특히 다음을 현재 구조에 임의로 흡수하지 않는다.

- Session Base Mode/Context/Overlay/Transition 정책
- Cross-domain Transaction/Event/Projection Barrier
- Runtime Object/Incarnation identity
- Spatial Query
- Navigation Planner/Coordinator/Executor
- Capability/Action Availability
- RuleExecution

이 책임 중 현재 Foundation에 필요한 최소 범위가 무엇인지 사용자 결정 후 System/Module Contract로 명시한다.

### 기존 G0~G5와 관계

`module-contracts.json.systemStages`의 기존 값:

```text
G0 Shared Contracts
→ G1 Server Authority Core
→ G2 Command Transport
→ G3 Projection Pipeline
→ G4 Client World Shell
→ G5 Composition Boot
```

은 현재 Greenfield 계획의 dependency/lifecycle guard로 유지된다.

Coverage Resolution이 Stage 추가/책임 변경/순서 변경을 요구하면 자동 적용하지 않고 사용자에게 먼저 제안한다.

## 2. E0 Gate — Coverage 해제 후

- Architecture Coverage의 E0 `blockedBy = []`.
- System/Module/Stable Function Contract와 Source가 일치.
- Repository automated tests PASS.
- authority/permission/revision/disclosure/transaction semantics가 승인된 Architecture와 일치.
- Movement/Exploration Domain 테스트가 승인된 Spatial/Capability/Navigation 경계를 우회하지 않음.

사람에게 Engine 함수를 하나씩 Studio에서 테스트시키지 않는다.

## 3. E1 — Roblox Runtime Integration

E0에서 테스트된 Engine을 Roblox Runtime에 연결한다.

현재 잠정 E1:

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

E1 Coverage blocker가 없어야 진입한다.

필수 흐름:

```text
CORE_ENGINE_READY
→ E1 Coverage READY
→ Rojo Build
→ Studio Boot
→ Remote / Player / Instance / Input Adapter 연결
→ Codex/MCP 자동 통합 테스트
→ lifecycle/error/reconnect 확인
→ INTEGRATION_READY
```

E1에서는 사용자 UX 판정을 요구하지 않는다.

## 4. Runtime-coupled Engine

엔진 코드라도 실제 Roblox 환경 없이는 correctness를 판단할 수 없으면 `ROBLOX_RUNTIME_ENGINE`으로 분류한다.

대표 후보:

```text
PathfindingService / approved navigation provider
Raycast / spatial provider
Physics / Collision
Streaming-sensitive resolution
DataStore / MemoryStore adapters
```

해당 Capability의 Coverage Gap과 Contract가 먼저 해결되어야 한다.

최종 Source는 항상 `greenfield/src`에 canonicalize한다.

### Pathfinding

현재 `GAP-005`가 OPEN이므로 구체 Module split/API는 확정하지 않는다.

Gap 해결 후 기본 분리 원칙:

```text
Repository
= Request/Result Contract
  + movement permission/budget
  + failure/recompute semantics
  + pure policy/normalization

Studio Runtime
= approved Roblox navigation provider
  + NavMesh/Agent behavior
  + actual obstacle/collision geometry
  + spatial/raycast behavior
  + dynamic obstruction/recompute

Human Feel
= path preview readability
  + click response
  + movement smoothness
```

## 5. E2 — Presentation / Feel

Engine과 Runtime Integration이 준비되고 각 Checkpoint Coverage가 READY인 뒤 사용자에게 보이는 수직 슬라이스를 만든다.

```text
S1_SELECTION
→ C1_CAMERA
→ M1_MOVE
→ X1_CONTEXT
→ I1_INTERACTION
```

현재 각 흐름 역시 Coverage Audit 결과에 따라 보완될 수 있다.

### S1 Selection

현재 잠정 흐름:

```text
SemanticInputRouter
→ SelectionController
→ local selection state
→ WorldPresenter
```

하지만 `GAP-003 Runtime Object Identity`, `GAP-004 Spatial Query`, `GAP-009 Client ViewModel/Input Recovery`, `GAP-010 Visibility/Knowledge`가 해결되기 전에는 구현하지 않는다.

### C1 Camera

Camera는 client-local Presentation/Feel이다. 단 Input Context/Recovery 공통 경계가 결정된 후 구현한다.

### M1 Move

현재 잠정 Command 경로는 보존한다.

```text
MovementController
→ CommandClient
→ CommandGateway
→ CommandRuntime
→ AuthorizationService
→ MovementDomain
→ WorldState / approved transaction boundary
→ ProjectionService
→ ProjectionGateway
→ ProjectionReplica
→ WorldPresenter
```

`GAP-002`, `GAP-004`, `GAP-005` 해결 결과에 따라 정확한 중간 경계는 사용자 승인 후 정합화한다.

### X1 Context / I1 Interaction

대상 타입별 하드코딩 메뉴나 feature-specific authority path로 구현하지 않는다.

`GAP-006 Interaction Capability Query`, `GAP-007 Capability Availability`, `GAP-008 RuleExecution`, `GAP-010 Visibility/Knowledge` 해결 뒤 정확한 흐름을 고정한다.

## 6. Human Checkpoint 규칙

각 사용자 Checkpoint 상태:

```text
PLANNED
IMPLEMENTING
READY_FOR_USER
ACCEPTED
BLOCKED
```

- 해당 Coverage Phase Gate가 READY여야 `IMPLEMENTING` 가능.
- `READY_FOR_USER`이면 다음 UI/Feel 기능을 진행하지 않는다.
- 사용자가 마음에 들지 않으면 같은 Checkpoint를 즉시 수정한다.
- Engine unit test 결과를 사용자에게 수동 검증시키지 않는다.
- 사용자가 수용해도 즉시 `ACCEPTED`로 올리지 않는다.
- Authority Reconciliation + Coverage 정합화 + Canonical Source + Focused Test + Promotion Commit 후 `ACCEPTED`다.

## 7. Exploration 이후 큰 제품 순서

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

이 큰 Product 순서는 현재 유지한다.

각 P단계는 구현 직전 Architecture Coverage를 다시 수행하고 필요한 Capability/Scenario를 현재 System Contract로 내린다.

미래 Product Capability를 Coverage Catalog에 추적하는 것과 미래 Module/API를 미리 발명하는 것을 구분한다.

## 8. 비협상 기술 안전 규칙

1. gameplay mutation 최종 권한은 Server다.
2. Client Role/Owner/Controller claim은 untrusted다.
3. authoritative mutation은 승인된 Command/Transaction boundary를 통과한다.
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
17. Coverage blocker를 임시 Source 구조로 우회하지 않는다.

## 9. 변경 Gate

Coverage Gap 해결, Execution Class, 시스템 순서, Authority, state owner, Module responsibility 또는 개발 방식을 바꾸려면 사용자에게 먼저 제안한다.

사용자가 승인한 실행 방식은 `Coverage → Repository Core Engine → Studio Runtime Integration → Human Presentation/Feel`이다.
