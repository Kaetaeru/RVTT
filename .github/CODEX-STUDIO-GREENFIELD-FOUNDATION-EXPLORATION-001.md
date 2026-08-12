# RVTT Greenfield — Architecture Coverage → Engine → Integration → UI Shell → Presentation 001

- 상태: `ACTIVE · CURRENT_COMMAND · BLOCKED_BY_ARCHITECTURE_COVERAGE`
- Build mode: `GREENFIELD_ARCHITECTURE_FIRST`
- Coverage authority: [`../implementation/roblox/ARCHITECTURE-COVERAGE-POLICY.md`](../implementation/roblox/ARCHITECTURE-COVERAGE-POLICY.md)
- Coverage registry: `implementation/roblox/manifests/architecture-coverage.json`
- Coverage audit: [`../implementation/roblox/audits/ARCHITECTURE-COVERAGE-AUDIT-001.md`](../implementation/roblox/audits/ARCHITECTURE-COVERAGE-AUDIT-001.md)
- Execution authority: [`../implementation/roblox/GREENFIELD-EXECUTION-LAYERS.md`](../implementation/roblox/GREENFIELD-EXECUTION-LAYERS.md)
- Execution registry: `implementation/roblox/manifests/execution-layers.json`
- Sequence authority: [`../implementation/roblox/GREENFIELD-SYSTEM-SEQUENCE.md`](../implementation/roblox/GREENFIELD-SYSTEM-SEQUENCE.md)
- Code contract: [`../implementation/roblox/MODULE-CONTRACTS.md`](../implementation/roblox/MODULE-CONTRACTS.md) + [`../implementation/roblox/SYSTEM-FUNCTION-CONTRACTS.md`](../implementation/roblox/SYSTEM-FUNCTION-CONTRACTS.md)

## 목표

Source 구현 전에 중요한 Capability 누락을 해결하고, 다음 실행 순서를 지킨다.

```text
Architecture Coverage
→ E0 Repository Core Engine
→ CORE_ENGINE_COMPLETE
→ E1 Roblox Runtime Engine / Integration
→ INTEGRATION_READY
→ U0 Product UI Shell Session
→ UI_SHELL_READY
→ E2 Presentation / Feel
```

현재는 Coverage Gap Resolution 단계이며 E0 Source와 Studio 작업을 시작하지 않는다.

## 0. 구현 전 읽기

1. `AGENTS.md`
2. `.github/CODEX-ACTIVE-TASK.md`
3. Coverage Policy / Coverage Registry / Scenario Registry / Audit
4. `implementation/roblox/GREENFIELD-EXECUTION-LAYERS.md`
5. `implementation/roblox/manifests/execution-layers.json`
6. `implementation/roblox/GREENFIELD-PREFLIGHT.md`
7. `implementation/roblox/GREENFIELD-SYSTEM-SEQUENCE.md`
8. Module/System Function Contracts와 Registry
9. Gap Evidence가 가리키는 Product/ADR/Architecture/System/UI/Spec

## 1. Architecture Coverage Gate

```text
python implementation/roblox/tooling/validate_architecture_coverage.py
```

현재:

```text
implementationGate = BLOCKED_BY_FOUNDATION_COVERAGE_GAPS
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

## 2. Gap Resolution Review

각 Gap:

```text
GAP
AUTHORITY EVIDENCE
CURRENT MISSING RESPONSIBILITY
MINIMUM BOUNDARY OPTIONS
CURRENT SCENARIO SET
FUTURE CONSUMERS
FUTURE SCENARIO PRESSURE
EXTENSION SEAMS
FORBIDDEN SHORTCUTS
DEFERRED NON-GOALS
CONTRACT / EXECUTION IMPACT
USER DECISION REQUIRED = yes
```

사용자 결정 전 System/Module/Stable Function 책임을 실질적으로 바꾸지 않는다.

## 3. E0 진입과 구현

다음이 모두 충족되어야 한다.

```text
E0 blockedBy = []
implementationGate = READY_FOR_E0
Coverage / Boundary / Module / Execution validators PASS
E0 Checkpoint Freeze 완료
```

E0은 GitHub canonical source + repository automated/negative/future-compatibility contract tests로 구현한다.

**`CORE_ENGINE_COMPLETE` 이전 Studio/MCP 구현 금지.**

## 4. E1 Roblox Runtime

`CORE_ENGINE_COMPLETE` 뒤에만 Studio Runtime Checkpoint를 상세화한다.

```text
Runtime Engine Module
Adapter
Server Service / Manager
Client Controller
Composition Root
Remote / Player / Instance Binding
Studio Test Harness
Runtime Failure / Cleanup Gate
```

PathfindingService/raycast/physics 등의 실제 Runtime Provider도 이때 구현한다.

E1은 자동 Harness로 검증하며 **기능 테스트용 임시 UI를 만들지 않는다.**

완료 결과:

```text
INTEGRATION_READY
```

## 5. U0 Product UI Shell Session

`INTEGRATION_READY` 뒤, E2보다 먼저 한 번 수행한다. U0는 별도 Execution Class가 아니다.

### U0-A — HTML/UI Reference Distillation

1. 당시 Branch에서 실제 HTML UI 예시 파일을 다시 탐색하고 읽는다.
2. 찾은 파일만 `Reference HTML Inventory`에 기록한다.
3. `docs/remake/ui`의 최신 UI Authority와 함께 비교한다.
4. HTML 예시는 Design/IA reference일 뿐 Gameplay Authority가 아니다.
5. 기대되는 HTML 예시를 확인하지 못하면 추측하지 않고 `BLOCK_U0_AND_ESCALATE_TO_PLANNING`한다.
6. Studio Shell 전에 다음을 글로 확정한다.

```text
Reference HTML Inventory
Product UI Surface Inventory
Design Philosophy
Information Architecture
Layout / Hierarchy Principles
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

### U0-B — 실제 Product UI Shell

확정된 Surface Inventory의 **실제 제품 껍데기 전체**를 Studio에 만든다.

- 기능/규칙/Authority 로직 없이 구조·Navigation·Panel·Modal·상태 자리만 구축.
- Placeholder/Fixture 허용.
- Semantic Design Token과 공통 Component 원칙 사용.
- throwaway Test ScreenGui 금지.

### U0-C — Human Shell Review

사용자가 전체 UI 종류, 배치, Navigation, 정보 밀도, 화면 겹침, 역할/Mode Surface, Modal 계층, Scaling/Accessibility 방향을 확인한다.

수정 완료 뒤에만:

```text
UI_SHELL_READY
```

## 6. Debug / Fixture Rule

`UI_SHELL_READY` 이후 별도 테스트 UI를 만들지 않는다.

```text
Presentation-only
→ Dev Fixture Adapter
→ fake Projection/ViewModel
→ actual Product Shell

Gameplay
→ Product Shell dev Debug Control
→ real CommandClient
→ real Server Authority / Transaction
```

Debug Control은 dev-mode only이며, direct Store/World mutation이나 별도 Remote/Authority path를 만들 수 없다.

제품 Surface가 없으면 실제 Shell에 추가하고, 제품 UI가 아니라면 자동 Harness를 사용한다.

## 7. E2 사용자 Checkpoint

`UI_SHELL_READY` 이후:

```text
S1 Selection
→ C1 Camera
→ M1 Move
→ X1 Context
→ I1 Interaction
```

각 Checkpoint는 자신의 Coverage blocker가 없어야 하며 실제 Product Shell/World Presentation에 연결한다. 임시 Workspace query, 하드코딩 Context Menu, Client-side Capability reconstruction으로 우회하지 않는다.

## 8. 사용자 최종 수용

```text
Authority Impact Scan
→ Product / ADR / Architecture / System / UI / Spec
→ Coverage Capability / Scenario / Gap
→ Future Compatibility Pressure
→ Execution / System / Module / Stable Function Contract
→ Source / Test
→ conflict re-scan
→ checkpoint(...) Promotion Commit
→ ACCEPTED
```

## 9. 금지

- Coverage blocker가 있는데 E0 Source 구현.
- `CORE_ENGINE_COMPLETE` 전 Studio/MCP 구현.
- E1에서 기능 검증용 임시 UI 생성.
- `UI_SHELL_READY` 후 throwaway Test ScreenGui 생성.
- HTML 예시 경로/스타일을 확인 없이 추측.
- Debug UI의 direct authority/store mutation 또는 별도 Remote.
- Product Capability 누락을 helper/Domain으로 숨기기.
- Spatial Query 대신 Controller Workspace 직접 순회.
- Context Action 대상 종류별 하드코딩.
- Client Character/Interaction Capability 재계산.
- MovementDomain에 Planner/Executor/Presentation 임의 결합.
- Legacy Source/Project 수정.
- ready-for-review / merge / force push.
