# RVTT Current Executable Task

- executionAuthority: `ONLY_CURRENT_EXECUTABLE_TASK`
- status: `BLOCKED_BY_ARCHITECTURE_COVERAGE`
- commandId: `RVTT-GREENFIELD-FOUNDATION-EXPLORATION-001`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskMode: `ARCHITECTURE_COVERAGE_RECONCILIATION`
- buildMode: `GREENFIELD_ARCHITECTURE_FIRST`
- coverageAuthorityDoc: `implementation/roblox/ARCHITECTURE-COVERAGE-POLICY.md`
- coverageRegistry: `implementation/roblox/manifests/architecture-coverage.json`
- scenarioRegistry: `implementation/roblox/manifests/architecture-scenarios.json`
- coverageAudit: `implementation/roblox/audits/ARCHITECTURE-COVERAGE-AUDIT-001.md`
- coverageValidator: `implementation/roblox/tooling/validate_architecture_coverage.py`
- executionAuthorityDoc: `implementation/roblox/GREENFIELD-EXECUTION-LAYERS.md`
- executionRegistry: `implementation/roblox/manifests/execution-layers.json`
- preflightAuthority: `implementation/roblox/GREENFIELD-PREFLIGHT.md`
- canonicalSourceRoot: `implementation/roblox/greenfield/src`
- canonicalTestRoot: `implementation/roblox/greenfield/tests`
- greenfieldProject: `implementation/roblox/greenfield.project.json`
- sequenceAuthority: `implementation/roblox/GREENFIELD-SYSTEM-SEQUENCE.md`
- moduleContractRegistry: `implementation/roblox/manifests/module-contracts.json`
- systemFunctionContractRegistry: `implementation/roblox/manifests/system-function-contracts.json`
- acceptancePromotionGate: `implementation/roblox/AUTHORITY-RECONCILIATION-POLICY.md`
- feedbackMode: `TIGHT_USER_FEEDBACK_LOOP`
- legacySourcePolicy: `READ_ONLY_REFERENCE_LOCKED`
- legacyPlacePolicy: `DO_NOT_USE_AS_BASELINE`
- commandPath: `.github/CODEX-STUDIO-GREENFIELD-FOUNDATION-EXPLORATION-001.md`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- updatedAt: `2026-08-13`

## 현재 Handoff

**E0 Source 구현을 시작하지 않는다.**

```text
Authority Corpus
→ Capability Catalog
→ Base + Expanded Scenario Trace
→ Cross-cutting Matrix
→ Gap Resolution
→ Future Compatibility Pressure Review
→ Coverage Gate PASS
→ E0 Repository Core Engine
```

`architecture-coverage.json`의 초기 Scenario와 `architecture-scenarios.json`의 확장 Scenario를 하나의 현재 Scenario Catalog로 취급한다.

## 미래 호환성 원칙

Codex는 현재 Checkpoint만 통과하도록 Architecture를 최적화하지 않는다.

미래 Capability와 Scenario는 **지금 구현할 Scope가 아니라 지금 Architecture를 압박하는 Compatibility Constraint**다.

각 Gap Resolution과 E0 Checkpoint Freeze에서 반드시 다음을 기록한다.

```text
Current Deliverable
Future Consumers
Future Scenario Pressure
Extension Seams
State / Authority Ownership That Must Remain Stable
Protocol / Versioning / Identity Seams
Persistence / Reconnect / Rollback Seams
Observability / Failure Seams
Forbidden Shortcuts
Explicit Deferred Non-goals
Compatibility Tests or Contract Tests
```

규칙:

- 미래 기능을 지금 구현하지 않는다.
- 미래 기능이 붙을 자리를 feature-specific helper, direct store edit, client rule reconstruction, global revision shortcut, direct Remote, Studio-only state로 막지 않는다.
- 미래 Capability 지원을 위해 public core contract를 갈아엎어야 하는 구조면 Checkpoint를 Freeze하지 않는다.
- 전체 Scenario Catalog는 Planning/Checkpoint Freeze에서 스캔하고, Implementation Branch에는 현재 Checkpoint를 압박하는 Working Set만 내린다.
- 구현 중 새로운 미래 충돌이 발견되면 helper로 우회하지 않고 `ESCALATE_TO_PLANNING`한다.

대표 미래 압력:

```text
Transaction Core
← Attack/Damage
← Item Pickup / Equipment
← Character Activation / Level Up
← Rest / Crafting / Survival Settlement
← Scene / Journal concurrent edit

Capability / Availability
← Character Console Dash
← Equipment-derived attacks
← Spell preparation / casting
← Reaction / Ready
← DM actor actions

Runtime Identity
← Selection
← Interaction
← Item world presence
← Scene authoring / spawn
← Reconnect / rollback

Session Policy
← Exploration / Encounter transition
← Control takeover
← Reconnect
← modal/input context
```

## 현재 E0 Blocker

```text
GAP-001 Session Policy Boundary
GAP-002 Transaction / Event / Projection Barrier
GAP-003 Runtime Object / Scene Identity
GAP-005 Navigation / Movement Boundary
GAP-007 Capability / Action Availability Projection
GAP-008 RuleExecution Boundary
```

세부 Evidence와 다른 Phase Gap은 Coverage Registry/Audit가 소유한다.

## 다음 실행의 첫 행동

1. `AGENTS.md`와 이 파일을 읽는다.
2. Coverage Policy/Registry/Scenario/Audit를 읽고 Validator를 실행한다.
3. Coverage Authority Tree Snapshot이 현재 Checkout과 일치하는지 확인한다.
4. E0 Blocker를 의존성 순서로 검토한다.
5. 각 Gap마다 현재 문제, 최소 경계 대안, 미래 확장 영향, 기존 Contract 영향 범위를 사용자에게 제안한다.
6. 해당 Gap이 막는 현재/미래 Scenario와 `Future Consumers / Future Scenario Pressure / Extension Seams / Forbidden Shortcuts / Deferred Non-goals`를 함께 적는다.
7. 사용자 결정 전 System/Module/Stable Function 책임을 실질적으로 추가·분리·통합하지 않는다.
8. Gap을 하나씩 해결하면서 Coverage Registry와 상위 Authority/Contract를 Top-down 정합화한다.
9. 모든 E0 Checkpoint가 미래 Pressure Set을 포함한 뒤에만 Freeze한다.
10. E0 `blockedBy`가 비고 `implementationGate=READY_FOR_E0`가 된 뒤에만 Source 구현 모드로 전환한다.

## Gap Resolution 권장 순서

```text
1. GAP-002 Transaction / Event / Projection Barrier
2. GAP-001 Session Mode / Context / Transition Policy
3. GAP-003 Runtime Object / Scene Identity
4. GAP-004 Spatial Query
5. Selection Boundary 재검증
6. GAP-005 Navigation / Runtime Pathfinding Boundary
7. GAP-007 Capability / Availability / Action Opportunity
8. GAP-008 RuleExecution minimum boundary
9. GAP-006 Interaction Capability Query
10. GAP-009 Client Projection / ViewModel / Input Context Recovery
11. GAP-010 Visibility / Knowledge minimum boundary
```

이 순서는 검토 순서이며 Architecture 자동 승인 순서가 아니다.

## E0 Checkpoint 명세 필수 형식

```text
Checkpoint ID
Current Deliverable
System / Module Scope
Stable Function Scope
Authority / State Ownership
Input / Output Contract
Current Scenario Working Set
Future Consumers
Future Scenario Pressure Set
Extension Seams
Stable Ownership / Identity Seams
Persistence / Reconnect / Rollback Seams
Observability / Failure Seams
Forbidden Shortcuts
Explicit Deferred Non-goals
Repository Tests
Negative / Fail-closed Tests
Future Compatibility Contract Tests
Completion Condition
```

## 기존 E0 후보

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

Coverage Gap 해결 결과에 따라 사용자 승인 후 바뀔 수 있다. 현재 목록을 그대로 구현해서 Gap을 코드로 덮지 않는다.

## Execution Layer + U0 UI Shell 원칙

Coverage Gate 해제 뒤 실행 순서:

```text
E0 Repository Core Engine
→ CORE_ENGINE_COMPLETE
→ E1 Roblox Runtime Engine / Integration
→ INTEGRATION_READY
→ U0-A HTML/UI Reference Distillation
→ U0-B Product UI Shell Scaffold
→ U0-C Human Shell Review
→ UI_SHELL_READY
→ E2 Presentation / Feel Checkpoints
```

- `CORE_ENGINE_COMPLETE` 이전에는 Studio/MCP 구현을 시작하지 않는다.
- E1은 Runtime/Integration correctness를 자동 Harness로 검증하며, 기능 테스트용 임시 UI를 만들지 않는다.
- U0는 E1 완료 후 E2 전에 한 번 수행하는 Presentation Preparation Gate이며 별도 Execution Class가 아니다.
- U0-A 시작 시 **그 시점의 브랜치에서 실제 HTML UI 예시 파일을 다시 발견·확인**한다. 현재 경로를 추측해 고정하지 않는다.
- HTML 예시는 정보구조·시각 언어·상호작용 참고자료이며 Gameplay Authority나 State Ownership 권위가 아니다.
- HTML 예시가 있다고 기대되는데 실제 경로/내용을 확인할 수 없으면 디자인을 상상해서 진행하지 않고 `BLOCK_U0_AND_ESCALATE_TO_PLANNING`한다.
- `docs/remake/ui`의 당시 최신 UI 권위와 HTML 예시를 함께 읽고, Studio Shell을 만들기 전에 구현용 Design Distillation을 작성한다.

U0-A에서 최소한 글로 확정할 항목:

```text
Reference HTML Inventory
Product UI Surface Inventory
Design Philosophy
Information Architecture
Layout / Hierarchy Principles
Visual Language
Typography / Spacing / Color Roles
Component Primitives
Interaction / Focus / Hover / Selected / Disabled States
Loading / Empty / Error / Stale / Reconnect States
Modal / Overlay / Z-order Rules
Responsive Scale / Accessibility / Reduced Motion
Debug Fixture Policy
Roblox GUI Mapping
Explicit UI Non-goals
```

U0-B:

- 실제 제품이 사용할 Global Shell, Mode HUD, Character/Inventory/Journal/Settings, Combat, DM Workspace, Scene Authoring, Modal/Toast/Error/Recovery 등 **확인된 Surface Inventory 전체의 실제 껍데기**를 만든다.
- 기능/Gameplay Rule/Authority는 구현하지 않는다. Placeholder/Fixture는 허용한다.
- 화면별 임시 Style이 아니라 승인된 Semantic Design Token/공통 Component 방향을 따른다.

U0-C:

- 전체 Shell의 정보구조, 배치, Panel 관계, 화면 겹침, Navigation, 역할별 Surface를 사용자가 Studio에서 확인한다.
- 검토가 끝난 뒤 `UI_SHELL_READY`로 올린다.
- E2는 `UI_SHELL_READY` 전에는 시작하지 않는다.

### 테스트 UI 금지 규칙

`UI_SHELL_READY` 이후 별도 throwaway `ScreenGui`, 임시 Test Panel, 기능별 가짜 UI를 만들지 않는다.

UI가 필요한 테스트는 실제 Product Shell에 dev-mode Debug/Fixture Control을 붙인다.

```text
Presentation-only test
→ Dev Fixture Adapter
→ fake Projection / ViewModel
→ actual Product Shell

Gameplay test
→ actual Product Shell Debug Control
→ real CommandClient / Server Authority / Transaction path
```

Debug Control은:

- 실제 Product Shell 내부의 정의된 Dev Slot에서만 존재한다.
- Production에서는 비활성/제거 가능해야 한다.
- Authority/World/Domain Store를 직접 변경하지 않는다.
- 두 번째 Remote/Authority Path를 만들지 않는다.
- 제품에 필요한 Surface가 없으면 Surface Inventory와 실제 Shell에 추가한다. 제품 Surface가 아니라면 자동 Harness를 사용한다.

## Pathfinding

`GAP-005` 해결 전 구체 Module/API를 만들지 않는다. Repository-side contract/policy를 E0에서 완료하고 실제 PathfindingService/NavMesh/Raycast/Collision provider는 `CORE_ENGINE_COMPLETE` 이후 E1에서만 구현한다.

## 사용자 Checkpoint

`UI_SHELL_READY` 이후 순서:

```text
S1 Selection
→ C1 Camera
→ M1 Move
→ X1 Context
→ I1 Interaction
```

각 Checkpoint는 자신의 Coverage blocker가 없어야 구현 가능하며, 실제 Product Shell/World Presentation에 연결한다.

## 사용자 확정 처리

```text
사용자 최종 수용
→ Authority Impact Scan
→ Product / ADR / Architecture / System / UI / Spec
→ Architecture Coverage Capability / Scenario / Gap
→ Future Compatibility Pressure Set 재검사
→ Execution / System / Module / Stable Function Contract
→ Canonical Source / Tests
→ conflict re-scan
→ Promotion Commit
→ ACCEPTED
→ 다음 Checkpoint
```

## 스캔 순서

1. `AGENTS.md`
2. 이 파일
3. `implementation/roblox/ARCHITECTURE-COVERAGE-POLICY.md`
4. Coverage/Scenario Registry와 Audit
5. `implementation/roblox/GREENFIELD-EXECUTION-LAYERS.md`
6. `implementation/roblox/manifests/execution-layers.json`
7. `implementation/roblox/GREENFIELD-PREFLIGHT.md`
8. `implementation/roblox/GREENFIELD-SYSTEM-SEQUENCE.md`
9. Module/System Function Contract와 Registry
10. 현재 `commandPath`
11. `implementation/roblox/AUTHORITY-RECONCILIATION-POLICY.md`
12. Gap Evidence가 가리키는 Product/ADR/Architecture/System/UI/Spec
13. Legacy Source는 필요한 경우 읽기 참고만

## 지금 하지 않는 것

- E0 Source 구현.
- U0 UI Shell 구현 또는 Studio 진입.
- 확인되지 않은 HTML 경로/디자인을 추측해 Authority로 고정.
- Coverage Gap을 무시한 임시 System/Module 추가.
- 미래 Capability를 이유로 미래 내부 Module/API를 미리 대량 구현.
- 현재 기능만 통과하도록 public contract/state owner를 feature-specific하게 고정.
- Spatial Query 대신 Controller에서 Workspace 직접 순회.
- Context Menu를 대상 타입별 하드코딩으로 우회.
- Character/Interaction Capability를 Client가 재계산하도록 구현.
- WorldState.transact를 상위 Transaction Architecture 전체와 동일하다고 근거 없이 가정.
- MovementDomain 안에 Pathfinding/Movement Executor/Presentation 책임을 몰아넣기.
- Legacy Source/Project 수정.
- ready-for-review / merge / force push.

더 좋은 Architecture가 보이면 사용자에게 먼저 제안한다.
