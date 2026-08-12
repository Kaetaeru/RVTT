# RVTT Greenfield System Sequence

- 상태: `ACTIVE · BUILD_ORDER_AUTHORITY · EXECUTION_BLOCKED_BY_COVERAGE`
- 최종 갱신일: 2026-08-13
- Architecture Coverage: [`ARCHITECTURE-COVERAGE-POLICY.md`](ARCHITECTURE-COVERAGE-POLICY.md)
- Coverage Registry: [`manifests/architecture-coverage.json`](manifests/architecture-coverage.json)
- Execution environment authority: [`GREENFIELD-EXECUTION-LAYERS.md`](GREENFIELD-EXECUTION-LAYERS.md)
- Machine-readable execution plan: [`manifests/execution-layers.json`](manifests/execution-layers.json)
- Module contract: [`manifests/module-contracts.json`](manifests/module-contracts.json)
- 확정 동기화 Gate: [`AUTHORITY-RECONCILIATION-POLICY.md`](AUTHORITY-RECONCILIATION-POLICY.md)

이 문서는 **Coverage에서 필요성이 확인된 시스템을 어떤 의존 순서로 준비하고, 언제 구현 Checkpoint를 구체화하며, 언제 Repository에서 Studio로 넘어갈지**를 소유한다.

핵심 원칙:

```text
Planning / Coverage
→ 구현용 Authority Distillation
→ E0 Core Engine Checkpoint 구체화
→ Repository Core Engine 전체 구현·검증
→ CORE_ENGINE_COMPLETE
→ E1 Studio Runtime Checkpoint 구체화
→ 그때부터 Studio/MCP 시작
→ Runtime Engine + Roblox Integration 완료
→ INTEGRATION_READY
→ E2 사용자 Checkpoint를 하나씩 JIT 구체화
→ Studio Presentation / Feel
→ 사용자 수용
```

**Studio 작업은 `CORE_ENGINE_COMPLETE` 이전에 시작하지 않는다.**

PathfindingService, Raycast, Physics처럼 Roblox Runtime이 필요한 엔진도 예외가 아니다. Repository에서 정의 가능한 Contract·Policy·Failure Semantics를 먼저 Core Engine 단계에서 완성하고, 실제 Roblox Runtime Provider 구현·튜닝은 `CORE_ENGINE_COMPLETE` 이후 E1에서 시작한다.

현재 Initial Architecture Coverage Audit에서 Foundation 책임 누락 후보가 발견됐다. 따라서 기존 G0~G5/System 목록은 **현재 계획의 의존 그래프**로 보존하지만 Gap Resolution 전 Source 실행 명령으로 사용하지 않는다.

## 0. 전체 실행 순서와 Checkpoint 구체화 시점

| 순서 | 단계 | 무엇을 확정하는가 | Checkpoint 상세화 | Studio 사용 |
|---:|---|---|---|---|
| 0 | Architecture Coverage | Product/ADR/Scenario가 요구하는 System Boundary와 Gap | 아직 구현 Checkpoint를 세부 확정하지 않음 | 금지 |
| 1 | Implementation Authority Distillation | 구현 AI가 읽을 System Map, Scenario Working Set, Contract, Build Order | E0 후보만 정리 | 금지 |
| 2 | E0 Checkpoint Freeze | Core Engine System/Module/Stable Function과 Repository Test Gate | **E0 구현 Checkpoint를 여기서 구체화** | 금지 |
| 3 | E0 Repository Core Engine | 순수 Engine Source + Unit/Contract/Negative Test | 확정된 E0 Checkpoint대로 구현 | 금지 |
| 4 | `CORE_ENGINE_COMPLETE` | 모든 E0 Checkpoint Source/Test/Contract 완료 | E0 종료 | 금지 종료점 |
| 5 | E1 Checkpoint Freeze | Roblox Runtime Engine, Adapter, Controller/Manager/Service, Studio Test Harness | **Studio 구현 Checkpoint를 이때 처음 구체화** | 아직 실행 전 |
| 6 | E1 Roblox Runtime | Pathfinding/Raycast/Remote/Player/Instance/Input/Composition 통합 | 확정된 E1 Checkpoint대로 구현 | **여기서 최초 시작** |
| 7 | `INTEGRATION_READY` | Roblox Runtime 자동 통합 검증 완료 | E1 종료 | 사용 |
| 8 | E2 User Checkpoint JIT | Selection/Camera/Move/Context/Interaction의 실제 보이는 동작 | **각 Checkpoint 직전에 하나씩 구체화** | 사용 |
| 9 | Human Acceptance | Studio Play에서 조작감/UI/Presentation 평가 | 다음 Checkpoint는 이전 수용 후 구체화 | 사용 |

Checkpoint를 너무 일찍 상세화하지 않는다.

```text
Core Engine Checkpoint
= Coverage Gap 해결 + System Boundary 확정 직후

Studio Runtime Checkpoint
= CORE_ENGINE_COMPLETE 직후

Presentation / Feel Checkpoint
= INTEGRATION_READY 이후, 현재 사용자 Checkpoint 직전 JIT
```

이렇게 해서 미래 Studio 구조를 Core Engine이 아직 흔들리는 동안 발명하지 않고, 반대로 Core Engine 구현 중에 Studio 임시 구조가 Architecture를 끌고 가지 않게 한다.

## 1. Architecture Coverage + Preflight Gate

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

이 Gap이 OPEN인 동안 E0 Source를 구현하지 않는다.

Coverage가 READY가 된 뒤 Repository/Greenfield 경계를 확인한다.

- `greenfield.project.json`은 `greenfield/src`만 Mapping한다.
- Legacy `src`와 `default.project.json`은 read-only reference다.
- Boundary / Coverage / Module / System / Function / Execution Layer Validator가 PASS한다.
- Studio/MCP Capability 확인은 E0 시작 조건이 아니다.

Preflight는 제품 시스템 Stage가 아니다.

## 2. Implementation Authority Distillation

상세 Planning 문서는 설계 근거 저장소로 유지한다. 구현 AI의 기본 작업면에는 승인된 액기스만 내린다.

구현용 Authority는 최소한 다음을 한 방향으로 설명해야 한다.

```text
System Map
→ State / Authority Owner
→ Stable Contract
→ Scenario Working Set
→ Build Order
→ Test Gate
```

전체 61개 Scenario는 Coverage Database로 보존하되, 구현 AI는 현재 Phase를 압박하는 Scenario Working Set만 기본적으로 읽는다.

Planning Authority와 구현용 Authority가 충돌하거나 구현에 필요한 책임이 없으면 Source로 우회하지 않고 Planning으로 Escalate한다.

전용 Implementation Branch를 만들 때는 Planning 기준 SHA를 Baseline으로 기록하고, 구현 AI가 상세 Planning Tree 전체를 기본 탐색 경로로 사용하지 않게 한다.

## 3. E0 Checkpoint Freeze — Repository Core Engine

Coverage Gap Resolution이 끝나고 E0에 필요한 책임이 확정되면, **Source를 쓰기 전에 E0 구현 Checkpoint를 구체화한다.**

Checkpoint 하나는 최소 다음을 가진다.

```text
Checkpoint ID
System / Module Scope
Stable Function Scope
Authority / State Ownership
Input / Output Contract
Required Scenario Set
Repository Tests
Negative / Fail-closed Tests
Completion Condition
```

현재 Execution Registry에 분류된 E0 후보:

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

**이 목록과 순서는 Coverage Gap 해결 후 E0 Checkpoint Freeze에서 최종화한다.**

특히 다음 책임을 현재 Module에 임의로 흡수하지 않는다.

- Session Base Mode/Context/Overlay/Transition 정책
- Cross-domain Transaction/Event/Projection Barrier
- Runtime Object/Incarnation identity
- Spatial Query
- Navigation Planner/Coordinator/Executor
- Capability/Action Availability
- RuleExecution

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

은 dependency/lifecycle guard로 유지한다.

Coverage Resolution이 Stage 추가/책임 변경/순서 변경을 요구하면 자동 적용하지 않고 사용자에게 먼저 제안한다.

## 4. E0 Repository Core Engine 실행과 완료 Gate

E0에서는 Studio를 열지 않는다.

```text
E0 Checkpoint Freeze
→ greenfield/src 구현
→ repository unit/contract test
→ negative/fail-closed test
→ checkpoint별 완료
→ 모든 E0 checkpoint 완료
→ CORE_ENGINE_COMPLETE
```

`CORE_ENGINE_COMPLETE` 조건:

- Architecture Coverage의 E0 `blockedBy = []`.
- 모든 E0 System/Module/Stable Function Contract와 Source가 일치.
- 모든 E0 Repository automated tests PASS.
- authority/permission/revision/disclosure/transaction semantics가 승인된 Architecture와 일치.
- Runtime Provider가 필요한 영역도 Repository-side Contract/Policy/Failure Semantics가 완료됨.
- Studio에서 임시로 검증해야만 설명 가능한 Core 책임이 남아 있지 않음.

사람에게 Engine 함수를 Studio에서 수동 테스트시키지 않는다.

## 5. E1 Checkpoint Freeze — Studio 진입 직전

`CORE_ENGINE_COMPLETE`가 된 뒤에만 Studio Runtime 구현 계획을 상세화한다.

여기서 처음으로 다음을 확정한다.

```text
Roblox Runtime Engine Module
Runtime Adapter
Server Service / Manager
Client Controller
Composition Root
Remote / Player / Instance Binding
Studio Test Harness
Runtime Failure / Cleanup Gate
```

즉 **직접 구현할 Studio의 Controller/Manager/Service 목록은 Core Engine 완료 후 E1 Checkpoint Freeze에서 확정**한다.

현재 잠정 E1 후보:

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

Pathfinding/Spatial/Physics처럼 `ROBLOX_RUNTIME_ENGINE`으로 확정되는 Module도 E1 목록에 들어간다.

## 6. E1 — Roblox Runtime Engine + Integration

필수 흐름:

```text
CORE_ENGINE_COMPLETE
→ E1 Coverage READY
→ E1 Checkpoint Freeze
→ Rojo Build
→ Studio/MCP Capability Handshake
→ Studio Boot
→ Runtime Engine Provider 구현·튜닝
→ Remote / Player / Instance / Input Adapter 연결
→ Codex/MCP 자동 통합 테스트
→ lifecycle/error/reconnect 확인
→ INTEGRATION_READY
```

E1에서는 사용자 UX 판정을 요구하지 않는다.

### Runtime-coupled Engine

대표 후보:

```text
PathfindingService / approved navigation provider
Raycast / spatial provider
Physics / Collision
Streaming-sensitive resolution
DataStore / MemoryStore adapters
```

이들은 Roblox Runtime에서 구현·튜닝할 수 있지만 **E0 Core Engine 완료 전에는 Studio 작업을 시작하지 않는다.**

Pathfinding의 Repository-side 책임 예:

```text
Request / Result Contract
Movement permission / budget
Failure / recompute semantics
Workspace-independent normalization / policy
```

Studio-side 책임 예:

```text
PathfindingService provider
actual NavMesh / Agent behavior
obstacle / collision geometry
raycast / spatial result
runtime recompute
```

최종 Source는 항상 `greenfield/src`에 canonicalize한다.

## 7. E2 — Presentation / Feel Checkpoint JIT

`INTEGRATION_READY`가 된 뒤 사용자에게 보이는 Checkpoint를 만든다.

```text
S1_SELECTION
→ C1_CAMERA
→ M1_MOVE
→ X1_CONTEXT
→ I1_INTERACTION
```

하지만 다섯 Checkpoint의 세부 UI/Controller 행동을 한 번에 고정하지 않는다.

```text
INTEGRATION_READY
→ S1 상세 Checkpoint 구체화
→ 구현 / Studio self-check
→ READY_FOR_USER
→ 사용자 수용
→ Reconciliation / ACCEPTED
→ C1 상세 Checkpoint 구체화
→ ...
```

따라서 사용자 피드백으로 앞 단계 UX가 바뀌어도 미래 Checkpoint 문서를 연쇄적으로 다시 쓰지 않는다.

### S1 Selection

현재 잠정 흐름:

```text
SemanticInputRouter
→ SelectionController
→ local selection state
→ WorldPresenter
```

`GAP-003 Runtime Object Identity`, `GAP-004 Spatial Query`, `GAP-009 Client ViewModel/Input Recovery`, `GAP-010 Visibility/Knowledge` 해결 결과를 반영해 S1 시작 직전에 최종화한다.

### C1 Camera

Camera는 client-local Presentation/Feel이다. Input Context/Recovery 경계와 S1 수용 결과를 반영해 C1 시작 직전에 상세화한다.

### M1 Move

현재 잠정 Command 경로:

```text
MovementController
→ CommandClient
→ CommandGateway
→ CommandRuntime
→ AuthorizationService
→ MovementDomain
→ approved transaction boundary
→ ProjectionService
→ ProjectionGateway
→ ProjectionReplica
→ WorldPresenter
```

정확한 Navigation/Pathfinding/Transaction 중간 경계와 보이는 이동 UX는 M1 시작 직전에 확정한다.

### X1 Context / I1 Interaction

대상 타입별 하드코딩 메뉴나 feature-specific authority path로 구현하지 않는다.

Capability Availability / Interaction Query / RuleExecution / Visibility 경계를 재사용하고, 각각의 사용자 Checkpoint 직전에 필요한 표면만 상세화한다.

## 8. Human Checkpoint 규칙

각 사용자 Checkpoint 상태:

```text
PLANNED
IMPLEMENTING
READY_FOR_USER
ACCEPTED
BLOCKED
```

- 해당 Coverage Phase Gate가 READY여야 `IMPLEMENTING` 가능.
- `READY_FOR_USER`이면 다음 UI/Feel Checkpoint를 상세 구현하지 않는다.
- 사용자가 마음에 들지 않으면 같은 Checkpoint를 즉시 수정한다.
- Engine unit test 결과를 사용자에게 수동 검증시키지 않는다.
- 사용자가 수용해도 즉시 `ACCEPTED`로 올리지 않는다.
- Authority Reconciliation + Coverage 정합화 + Canonical Source + Focused Test + Promotion Commit 후 `ACCEPTED`다.
- 다음 Checkpoint의 상세 계약은 이전 Checkpoint가 수용되기 전에 불필요하게 선행 확정하지 않는다.

## 9. Exploration 이후 큰 제품 순서

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

각 P단계는 구현 직전 Architecture Coverage를 다시 수행하고, 해당 단계의 Core/Runtime/Presentation Checkpoint를 같은 원칙으로 JIT 상세화한다.

미래 Product Capability를 Coverage Catalog에 추적하는 것과 미래 Module/API를 미리 발명하는 것을 구분한다.

## 10. 비협상 기술 안전 규칙

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
18. `CORE_ENGINE_COMPLETE` 이전 Studio/MCP 구현을 허용하지 않는다.

## 11. 변경 Gate

Coverage Gap 해결, Execution Class, 시스템 순서, Authority, state owner, Module responsibility, Checkpoint 구체화 시점 또는 개발 방식을 바꾸려면 사용자에게 먼저 제안한다.

사용자가 승인한 실행 방식은:

```text
Coverage / Planning
→ Implementation Authority Distillation
→ E0 Checkpoint Freeze
→ Repository Core Engine COMPLETE
→ E1 Checkpoint Freeze
→ Studio Runtime Integration
→ E2 User Checkpoint JIT
→ Human Presentation / Feel
```
