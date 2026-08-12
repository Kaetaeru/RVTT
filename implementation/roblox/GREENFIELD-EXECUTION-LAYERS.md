# RVTT Greenfield Execution Layers

- 상태: `ACTIVE · EXECUTION_ENVIRONMENT_AUTHORITY`
- 최종 갱신일: 2026-08-13
- Architecture Coverage Gate: [`ARCHITECTURE-COVERAGE-POLICY.md`](ARCHITECTURE-COVERAGE-POLICY.md)
- Coverage Registry: [`manifests/architecture-coverage.json`](manifests/architecture-coverage.json)
- Machine-readable plan: [`manifests/execution-layers.json`](manifests/execution-layers.json)
- Module contracts: [`MODULE-CONTRACTS.md`](MODULE-CONTRACTS.md)
- System/function contracts: [`SYSTEM-FUNCTION-CONTRACTS.md`](SYSTEM-FUNCTION-CONTRACTS.md)
- Build order: [`GREENFIELD-SYSTEM-SEQUENCE.md`](GREENFIELD-SYSTEM-SEQUENCE.md)

이 문서는 **Coverage가 확인된 책임을 어디에서 구현하고 어떤 테스트로 통과시키며, E1 뒤 Product UI Shell을 언제 준비할지**를 소유한다.

Execution Class는 Product Coverage를 대신하지 않는다.

```text
Architecture Coverage
→ System / Module / Stable Function Contract
→ Execution Class
→ 구현 Checkpoint
→ 구현 / 검증 환경
```

현재 Coverage Gate가 `BLOCKED_BY_FOUNDATION_COVERAGE_GAPS`이므로 E0 Source는 시작하지 않는다.

## 1. 실행 환경 원칙

```text
CORE_ENGINE
→ Repository first
→ 모든 E0 완료
→ CORE_ENGINE_COMPLETE

ROBLOX_RUNTIME_ENGINE / ROBLOX_INTEGRATION
→ CORE_ENGINE_COMPLETE 이후 Studio/MCP
→ INTEGRATION_READY

U0_PRODUCT_UI_SHELL_SESSION
→ INTEGRATION_READY 이후
→ HTML/UI Design Distillation
→ 실제 Product UI Shell 전체 구축
→ Human Shell Review
→ UI_SHELL_READY

PRESENTATION_FEEL
→ UI_SHELL_READY 이후
→ 실제 Product Shell에 기능을 하나씩 JIT 연결
→ Human Acceptance
```

**`CORE_ENGINE_COMPLETE` 이전 Studio/MCP 구현·튜닝 금지.** Runtime-coupled Engine도 E1이며 예외가 아니다.

## 2. Checkpoint 구체화 시점

```text
E0 Core Engine Checkpoint
→ Coverage Gap 해결 + Core System Boundary 확정 뒤
→ Source 직전

E1 Studio Runtime Checkpoint
→ CORE_ENGINE_COMPLETE 직후
→ Studio Runtime 구현 직전

U0 Product UI Shell Session
→ INTEGRATION_READY 직후
→ E2 기능 연결 전에 한 번

E2 Presentation / Feel Checkpoint
→ UI_SHELL_READY 이후
→ S1/C1/M1/X1/I1 각각 직전 JIT
```

E1 Checkpoint Freeze에서 Runtime `Service / Manager / Controller / Adapter / Composition Root / Studio Harness`를 확정한다. U0 전에는 미래 UI Controller 내부 기능을 미리 고정하지 않는다.

## 3. 공통 Source 권위

최종 Source 권위는 `greenfield/src`다.

- Studio-only production truth 금지.
- E1/U0/E2에서 Studio 수정 후 coherent change는 `greenfield/src`에 canonicalize.
- Rojo로 같은 DataModel을 재현할 수 있어야 한다.

## 4. CORE_ENGINE

Roblox Runtime 실제 결과 없이 correctness를 판단 가능한 엔진.

현재 잠정 E0 후보:

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

Coverage Gap 해결 후 E0 Checkpoint Freeze에서 최종화한다.

```text
E0 Checkpoint Freeze
→ greenfield/src
→ repository automated tests
→ negative/fail-closed tests
→ future compatibility contract tests
→ CORE_ENGINE_COMPLETE
```

사람에게 Engine 함수 수동 테스트를 요구하지 않는다.

## 5. ROBLOX_RUNTIME_ENGINE

Roblox Runtime 자체가 correctness의 일부인 엔진.

예:

- PathfindingService/NavMesh
- Workspace raycast/spatial provider
- physics/collision
- StreamingEnabled-sensitive resolution
- DataStore/MemoryStore adapter

**E1에 속하며 `CORE_ENGINE_COMPLETE` 이후에만 Studio에서 구현·튜닝한다.**

Pathfinding도 E0에서는 Request/Result, Permission/Budget, Failure/Recompute, Workspace-independent policy를 먼저 끝내고 실제 Provider는 E1에서 구현한다.

## 6. ROBLOX_INTEGRATION

Core Engine과 Roblox Runtime을 연결하는 Adapter/Composition.

현재 잠정 범위:

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

```text
CORE_ENGINE_COMPLETE
→ E1 Coverage READY
→ E1 Checkpoint Freeze
→ Rojo build
→ Studio/MCP
→ Runtime Engine + Remote/Player/Instance/Input
→ automated runtime/integration tests
→ cleanup/reconnect/error tests
→ INTEGRATION_READY
```

E1은 사용자 UX 판정 단계가 아니며 **기능 검증용 임시 UI를 만들지 않는다.** 반복 가능한 Studio Harness를 사용한다.

## 7. U0_PRODUCT_UI_SHELL_SESSION

U0는 **별도 Execution Class가 아니다.** E1과 E2 사이의 필수 Presentation Preparation Gate다.

### U0-A HTML/UI Reference Distillation

`INTEGRATION_READY` 뒤 당시 Branch에서 실제 HTML UI 예시를 다시 탐색·확인한다.

- 확인된 파일만 `Reference HTML Inventory`에 넣는다.
- 기대되는 HTML 예시를 찾거나 읽을 수 없으면 경로/스타일을 추측하지 않고 `BLOCK_U0_AND_ESCALATE_TO_PLANNING`.
- HTML 예시는 Design/IA 참고이며 Gameplay Authority, Rule, State Ownership 권위가 아니다.
- `docs/remake/ui`의 당시 최신 UI Authority와 함께 읽는다.

Studio Shell 전에 최소 다음을 글로 확정한다.

```text
Reference HTML Inventory
Surface Inventory
Design Philosophy
Information Architecture
Layout / Hierarchy
Visual Language
Typography / Spacing / Color Roles
Component Primitives
Interaction States
Loading / Empty / Error / Disabled / Stale / Reconnect States
Modal / Overlay / Z-order
Responsive Scale / Accessibility
Reduced Motion
Debug Fixture Policy
Roblox GUI Mapping
Explicit UI Non-goals
```

현재 UI Authority는 전역 Policy, Shared UI, Common Input, Character Sheet, Combat HUD, DM Workspace, Scene Editor 등의 구분을 제공하지만 U0에서는 당시 최신 문서/HTML을 다시 읽고 Surface Inventory를 Freeze한다.

### U0-B Product UI Shell Scaffold

기능 구현 전 실제 제품 Surface의 **껍데기 전체**를 Studio에 만든다.

- 실제 제품 구조/Navigation/Panel/Modal/Role/Mode 자리.
- Placeholder/Fixture 데이터 허용.
- Gameplay Rule/Authority/Domain mutation 금지.
- Semantic Design Token/공통 Component 사용.
- throwaway mock/test ScreenGui 금지.

### U0-C Human Shell Review

사용자가 전체 UI 종류, 배치, Navigation, 정보 밀도, 화면 겹침, Modal 계층, Scaling/Accessibility 방향을 확인한다.

수정 후에만:

```text
UI_SHELL_READY
```

E2는 그 전 시작할 수 없다.

## 8. Debug / Fixture Policy

`UI_SHELL_READY` 이후 UI가 필요한 테스트는 항상 실제 Product Shell을 사용한다.

```text
Presentation-only
→ Dev Fixture Adapter
→ fake Projection/ViewModel
→ actual Product Shell

Gameplay
→ Product Shell dev Debug Control
→ actual CommandClient
→ actual server authority/transaction path
```

금지:

- 별도 throwaway Test UI.
- Debug 버튼의 direct WorldState/Domain Store mutation.
- Debug 전용 Remote/두 번째 Authority path.
- Client에서 Rule/Availability 재구성.

제품에 필요한 Surface가 없으면 실제 Surface Inventory/Shell에 추가하고, 제품 UI가 아니라면 자동 Harness를 사용한다.

## 9. PRESENTATION_FEEL

사람이 보고 만져야 평가 가능한 부분.

현재 잠정 Module:

```text
SelectionController
WorldPresenter
CameraController
MovementController
ContextActionController
```

```text
UI_SHELL_READY
→ Current Checkpoint Coverage READY
→ current Checkpoint JIT contract
→ actual Product Shell / World Presentation 연결
→ Codex Studio self-check
→ READY_FOR_USER
→ 사용자 Play
→ 수정
→ 사용자 수용
→ Authority Reconciliation
→ ACCEPTED
→ 다음 Checkpoint
```

UI/Presentation이 Remote나 Domain Store를 직접 소유하지 않는다.

## 10. 분류 규칙

```text
Roblox Runtime 없이 correctness 테스트 가능?
YES → CORE_ENGINE
NO ↓

Runtime 결과 필요, Human 감각 평가는 불필요?
YES → ROBLOX_RUNTIME_ENGINE / ROBLOX_INTEGRATION
NO ↓

화면·가독성·조작감·체감이 핵심?
YES → PRESENTATION_FEEL
```

U0는 이 네 Class 중 하나가 아니라 Presentation Preparation Gate다.

## 11. 테스트 권위

```text
Architecture Coverage
= 책임/Scenario 존재 여부

CORE_ENGINE
= Repository automated tests

ROBLOX_RUNTIME_ENGINE
= Repository contract + Studio automated runtime

ROBLOX_INTEGRATION
= Studio automated integration

U0 Product UI Shell
= HTML/UI Authority Distillation + Studio shell self-check + Human shell review

PRESENTATION_FEEL
= actual Product Shell에서 Studio self-check + Human Acceptance
```

## 12. 수직 개발

```text
공통 Core Engine 전체 선완성
→ CORE_ENGINE_COMPLETE
→ Runtime Engine / Integration 선검증
→ INTEGRATION_READY
→ U0 Product UI Shell 전체 선구축
→ UI_SHELL_READY
→ Selection
→ Camera
→ Move
→ Context
→ Interaction
```

사용자-facing 수직 슬라이스는 유지하되, **임시 테스트 UI가 슬라이스마다 새로 생기지 않도록 공통 실제 Shell을 먼저 만든다.**

## 13. 변경 Gate

Coverage Gap, Execution Class, Checkpoint 상세화 시점, U0 정책 또는 더 나은 구조가 Module 책임, Authority, State Owner, System Flow를 바꾸면 자동 적용하지 않는다. 문제·대안·영향을 사용자에게 먼저 제안한다.
