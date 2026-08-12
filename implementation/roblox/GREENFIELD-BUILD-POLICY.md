# RVTT Greenfield Build Policy

- 상태: `ACTIVE · CURRENT_IMPLEMENTATION_POLICY`
- 최종 갱신일: 2026-08-13
- Architecture Coverage: [`ARCHITECTURE-COVERAGE-POLICY.md`](ARCHITECTURE-COVERAGE-POLICY.md)
- Coverage Registry: [`manifests/architecture-coverage.json`](manifests/architecture-coverage.json)
- Execution Layers: [`GREENFIELD-EXECUTION-LAYERS.md`](GREENFIELD-EXECUTION-LAYERS.md)
- Preflight: [`GREENFIELD-PREFLIGHT.md`](GREENFIELD-PREFLIGHT.md)
- System Sequence: [`GREENFIELD-SYSTEM-SEQUENCE.md`](GREENFIELD-SYSTEM-SEQUENCE.md)
- Code Boundary: [`MODULE-CONTRACTS.md`](MODULE-CONTRACTS.md) + [`SYSTEM-FUNCTION-CONTRACTS.md`](SYSTEM-FUNCTION-CONTRACTS.md)
- Acceptance Gate: [`AUTHORITY-RECONCILIATION-POLICY.md`](AUTHORITY-RECONCILIATION-POLICY.md)

## 1. 기본 방식

새 RVTT는 **Architecture Coverage + Architecture-first Greenfield + Repository-first Engine + Studio Integration + Tight Human Feedback**으로 만든다.

```text
Product / ADR / Architecture / System / UI / Spec
→ Architecture Coverage Capability / Scenario / Cross-cutting Scan
→ 현재 Phase Blocking Gap 없음
→ System Contract
→ Module Contract
→ Stable Function Contract
→ Execution Class
→ E0 Repository Core Engine 구현·자동 테스트
→ E1 Roblox Runtime Integration Studio 자동 테스트
→ E2 Presentation / Feel
→ 사용자 직접 테스트
→ 즉시 수정 반복
→ 사용자 최종 수용
→ Authority Reconciliation
→ Promotion Commit
→ 다음 Capability
```

Studio에서 모든 엔진 코드를 순차적으로 작성하는 것이 목표가 아니다. Studio는 Roblox Runtime 연결과 사람이 직접 봐야 하는 Presentation/Feel 검증에 집중한다.

## 2. Architecture Coverage가 먼저다

Code Contract가 내부적으로 잘 맞는 것만으로 Source 구현을 시작하지 않는다.

현재 Authority에서 요구하는 Capability가 System 계획에 빠졌는지를 먼저 확인한다.

```text
Requirement
↕ Capability
↕ Scenario
↕ System
↕ Module
↕ Stable Function
↕ Source / Test
```

`architecture-coverage.json`의 현재 Phase `blockedBy`에 OPEN Gap이 있으면 해당 Phase Source를 만들지 않는다.

미래 Capability는 `DEFERRED`할 수 있다. 단 planned phase와 cross-cutting 검토를 남기고 현재 구조가 미래 Capability를 불가능하게 만들지 않는지 확인한다.

Coverage Finding은 Architecture 변경 승인 자체가 아니다. 새로운 핵심 경계가 필요하면 사용자에게 문제·대안·영향을 먼저 제안한다.

현재 Initial Audit 기준 E0는 Coverage Gap 때문에 `BLOCKED`다.

## 3. Source 권위

모든 Execution Class의 최종 Source는 `greenfield/src`다.

```text
greenfield.project.json
→ greenfield/src
→ greenfield/tests
```

- GitHub Canonical Source가 Product 구현 Truth다.
- Studio/MCP에서 수정한 Runtime-coupled code도 coherent change 뒤 즉시 GitHub와 맞춘다.
- Studio-only Production logic은 금지한다.
- Legacy `src`와 `default.project.json`은 read-only reference다.

## 4. 구현 전 Code Contract

Coverage가 READY인 현재/다음 구현 범위만 Source보다 먼저 다음을 고정한다.

```text
Architecture Coverage
→ System Contract
→ Module Contract
→ Stable Function Contract
→ Execution Class
→ Validators
```

다른 Contract-bearing Module이 호출하는 함수는 Stable Function Contract가 먼저 존재해야 한다.

private/local helper는 미리 선언하지 않는다.

Coverage가 요구하는 책임이 없는 상태에서 private helper나 임시 Domain에 그 책임을 숨겨 구현하지 않는다.

## 5. Execution Class

새 Module은 승인된 Coverage/Contract 후 구현 전에 다음 중 하나로 분류한다.

### CORE_ENGINE

Roblox Runtime 없이 correctness를 검증할 수 있는 Engine.

```text
Coverage READY
→ GitHub Source
→ Unit/Contract/Negative Tests
→ ENGINE_READY
```

현재 Execution Registry의 E0 Module 목록은 Coverage Gap 해결 전까지 잠정 후보다.

### ROBLOX_RUNTIME_ENGINE

Roblox 서비스/World 결과 자체가 Engine correctness의 일부.

```text
Coverage + Contract
→ GitHub Canonical Source
↔ Studio/MCP runtime iteration
→ Studio automated runtime test
→ RUNTIME_ENGINE_READY
```

대표: PathfindingService, raycast/spatial provider, physics/collision, streaming-sensitive behavior, DataStore adapter.

### ROBLOX_INTEGRATION

이미 존재하는 Engine을 Remote/Player/Input/Instance/lifecycle에 연결한다.

```text
Coverage READY + ENGINE_READY
→ Studio/MCP Integration
→ automated integration test
→ INTEGRATION_READY
```

### PRESENTATION_FEEL

사람이 직접 보고 만져야 평가 가능한 UI/visual/control feel.

```text
Checkpoint Coverage READY
+ ENGINE_READY + INTEGRATION_READY
→ Studio self-check
→ READY_FOR_USER
→ Human feedback
```

정확한 분류와 현재 Module mapping은 `manifests/execution-layers.json`을 따른다.

## 6. Pathfinding

Pathfinding은 통째로 한 환경에 몰지 않는다.

현재는 Coverage `GAP-005`가 OPEN이므로 구체 Module split/API를 구현하지 않는다.

Gap 해결 후 원칙:

```text
Repository
= request/result contract
  + movement permission/budget
  + failure/recompute policy
  + pure normalization/policy

Studio Runtime
= approved navigation provider / PathfindingService
  + NavMesh/Agent behavior
  + obstacle/collision/raycast
  + dynamic recompute

Human
= preview readability
  + click response
  + movement smoothness
```

## 7. 사용자 Feedback Loop

Exploration 사용자 Checkpoint 순서는 유지한다.

```text
S1 Selection
→ C1 Camera
→ M1 Move
→ X1 Context
→ I1 Interaction
```

각 Checkpoint는 자신의 Coverage Phase Gate가 READY인 뒤에만 구현한다.

Engine과 Integration은 가능한 한 Checkpoint보다 먼저 자동 검증한다.

사용자에게는 실제 화면, 입력 반응, 카메라/이동 감각, 가독성, 조작 UX를 판단하게 한다.

순수 Authority/Revision/Command 함수를 사용자에게 콘솔로 수동 검증시키지 않는다.

`READY_FOR_USER`가 되면 다음 Presentation 기능 진행을 멈춘다. 수정 요청은 같은 Checkpoint에서 즉시 반영한다.

## 8. 반복과 확정

반복 중:

- private/helper 구현은 빠르게 수정 가능.
- Stable API가 달라지면 Function Contract와 Source를 함께 맞춘다.
- Security/Authority 경계는 우회하지 않는다.
- Product/ADR/Architecture를 매 반복마다 흔들지 않는다.

사용자 최종 수용 후:

```text
Authority Impact Scan
→ Product/ADR/Architecture/System/UI/Spec
→ Architecture Coverage Capability/Scenario/Gap
→ Execution/System/Module/Function Contract
→ Source/Test
→ conflict re-scan
→ Promotion Commit
→ ACCEPTED
```

## 9. Authority 문서 변경과 Coverage

Product/ADR/Architecture/System/UI/Spec Root가 변경되면 Coverage Tree Snapshot이 달라진다.

```text
Coverage CI FAIL
→ 변경 Authority 읽기
→ Capability/Scenario/Gap 영향 검토
→ 필요한 사용자 Architecture 결정
→ Coverage Registry/Snapshot 정합화
→ CI PASS
```

SHA만 갱신하고 의미 검토를 생략하지 않는다.

## 10. Console과 Test Harness

Console 함수 호출은 디버그/관찰 보조 수단이다.

```text
콘솔에서 한 번 성공
≠ Engine Test PASS
```

- CORE_ENGINE은 repository automated tests를 우선한다.
- ROBLOX_RUNTIME_ENGINE/INTEGRATION은 Studio automated harness를 우선한다.
- PRESENTATION_FEEL만 Human Acceptance가 최종 판단이다.

## 11. Bootstrap / App

```text
ClientBootstrap.client.lua → ClientApp.start()
ServerBootstrap.server.lua → ServerApp.start()
```

Bootstrap/App은 Composition Root와 lifecycle만 담당한다. Gameplay rule, input semantics, authorization, mutation, disclosure policy를 넣지 않는다.

## 12. 기술 안전

Prototype에서도 다음은 우회하지 않는다.

- Server authority
- untrusted client input
- bounded/rate-limited Remote
- command id / epoch / revision
- viewer-safe Projection
- UI direct Remote 금지
- Bootstrap gameplay logic 금지
- lifecycle cleanup
- fail closed
- no network Instance reference
- canonical GitHub Source
- Legacy read-only boundary
- undeclared cross-module call 금지
- Coverage blocker code workaround 금지

## 13. 미래 시스템 범위

Coverage를 만든다고 P2~P10의 아직 미확정 Domain/API를 전부 선행 구현하지 않는다.

- 미래 Product Capability는 Catalog와 Scenario에서 추적할 수 있다.
- 세부 Module/Function은 해당 Phase가 가까워질 때 설계한다.
- 현재 Foundation이 반드시 공유해야 하는 공통 경계만 지금 해결한다.

## 14. 변경 Gate

Coverage Gap 해결, Execution Class, 핵심 Architecture, Authority, state owner, Module responsibility, 시스템 순서 또는 개발 방식을 바꾸려면 사용자에게 먼저 제안한다.
