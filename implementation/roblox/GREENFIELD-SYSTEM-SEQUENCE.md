# RVTT Greenfield System Sequence

- 상태: `ACTIVE · BUILD_ORDER_AUTHORITY · EXECUTION_BLOCKED_BY_COVERAGE`
- 최종 갱신일: 2026-08-13
- Architecture Coverage: [`ARCHITECTURE-COVERAGE-POLICY.md`](ARCHITECTURE-COVERAGE-POLICY.md)
- Coverage Registry: [`manifests/architecture-coverage.json`](manifests/architecture-coverage.json)
- Execution environment authority: [`GREENFIELD-EXECUTION-LAYERS.md`](GREENFIELD-EXECUTION-LAYERS.md)
- Machine-readable execution plan: [`manifests/execution-layers.json`](manifests/execution-layers.json)
- Module contract: [`manifests/module-contracts.json`](manifests/module-contracts.json)
- 확정 동기화 Gate: [`AUTHORITY-RECONCILIATION-POLICY.md`](AUTHORITY-RECONCILIATION-POLICY.md)

이 문서는 **Coverage에서 필요성이 확인된 시스템의 구현 순서, Checkpoint 구체화 시점, Repository→Studio 전환, Product UI Shell 선구축 시점**을 소유한다.

## 0. 전체 실행 순서

```text
Planning / Coverage
→ Implementation Authority Distillation
→ E0 Core Engine Checkpoint Freeze
→ Repository Core Engine 전체 구현·검증
→ CORE_ENGINE_COMPLETE
→ E1 Studio Runtime Checkpoint Freeze
→ Studio/MCP Runtime Engine + Integration
→ INTEGRATION_READY
→ U0-A HTML/UI Reference Distillation
→ U0-B Product UI Shell Scaffold
→ U0-C Human Shell Review
→ UI_SHELL_READY
→ E2 User Checkpoint JIT
→ Studio Presentation / Feel
→ Human Acceptance
```

**`CORE_ENGINE_COMPLETE` 이전에는 Studio/MCP 구현·튜닝을 시작하지 않는다.** PathfindingService, Raycast, Physics처럼 Roblox Runtime이 필요한 엔진도 예외가 아니다.

| 순서 | 단계 | Checkpoint/결과 | Studio |
|---:|---|---|---|
| 0 | Architecture Coverage | Gap/Boundary 확인 | 금지 |
| 1 | Authority Distillation | 구현 AI용 System/Scenario/Contract 압축 | 금지 |
| 2 | E0 Checkpoint Freeze | Core Engine Checkpoint 상세화 | 금지 |
| 3 | E0 Repository Core Engine | Source + Repository/Negative Test | 금지 |
| 4 | `CORE_ENGINE_COMPLETE` | E0 종료 | 금지 종료점 |
| 5 | E1 Checkpoint Freeze | Runtime Service/Manager/Controller/Adapter/Harness 상세화 | 실행 전 |
| 6 | E1 Roblox Runtime | Runtime Engine + Integration | 최초 사용 |
| 7 | `INTEGRATION_READY` | E1 자동 검증 완료 | 사용 |
| 8 | U0-A Design Distillation | HTML/UI 참고자료 → UI 종류·철학·IA·디자인 원칙 글로 확정 | 사용 |
| 9 | U0-B Product UI Shell | 전체 실제 Product Surface 껍데기 구축 | 사용 |
| 10 | U0-C Human Shell Review | 전체 Shell 구조 사용자 확인 | 사용 |
| 11 | `UI_SHELL_READY` | E2 진입 Gate | 사용 |
| 12 | E2 User Checkpoint JIT | S1/C1/M1/X1/I1 하나씩 상세화 | 사용 |
| 13 | Human Acceptance | 실제 조작감/UI/Presentation 수용 | 사용 |

Checkpoint 상세화 시점:

```text
E0 = Coverage Gap 해결 + System Boundary Freeze 뒤, Source 직전
E1 = CORE_ENGINE_COMPLETE 뒤, Studio Runtime 구현 직전
U0 = INTEGRATION_READY 뒤, E2 기능 연결 전 한 번
E2 = UI_SHELL_READY 뒤, 현재 사용자 Checkpoint 하나씩 JIT
```

## 1. Architecture Coverage + Preflight

E0 Source 전:

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

OPEN 동안 E0 Source를 만들지 않는다. Studio/MCP Capability 확인은 E0 시작 조건이 아니다.

## 2. Implementation Authority Distillation

상세 Planning 문서는 근거 저장소다. 실제 구현 AI의 기본 작업면에는 승인된 액기스만 내린다.

```text
System Map
→ State / Authority Owner
→ Stable Contract
→ Current Scenario Working Set
→ Future Scenario Pressure Set
→ Build Order
→ Test Gate
```

전체 Scenario Catalog는 Planning에서 스캔하되 구현 AI에게는 현재 Checkpoint를 압박하는 Working Set만 기본 제공한다.

## 3. E0 Checkpoint Freeze

Checkpoint 하나는 최소 다음을 가진다.

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

미래 기능은 지금 구현하지 않지만, 미래 기능을 붙이려면 현재 public contract를 갈아엎어야 하는 구조는 Freeze하지 않는다.

현재 E0 후보:

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

Coverage Resolution 후 최종화한다. Session Policy, Transaction/Event Barrier, Runtime Identity, Spatial Query, Navigation, Capability/Availability, RuleExecution 책임을 기존 Module에 임의 흡수하지 않는다.

## 4. E0 Repository Core Engine

```text
E0 Checkpoint Freeze
→ greenfield/src
→ repository unit/contract tests
→ negative/fail-closed tests
→ future compatibility contract tests
→ 모든 E0 Checkpoint 완료
→ CORE_ENGINE_COMPLETE
```

`CORE_ENGINE_COMPLETE` 조건:

- E0 Coverage `blockedBy = []`.
- System/Module/Stable Function Contract와 Source 일치.
- Repository tests PASS.
- authority/permission/revision/disclosure/transaction semantics 일치.
- Runtime Provider가 필요한 영역도 Repository-side Contract/Policy/Failure Semantics 완료.
- Studio에서 임시 검증해야만 설명 가능한 Core 책임 없음.

## 5. E1 Checkpoint Freeze + Roblox Runtime Integration

`CORE_ENGINE_COMPLETE` 뒤에만 다음을 구체화한다.

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

E1 실행:

```text
CORE_ENGINE_COMPLETE
→ E1 Coverage READY
→ E1 Checkpoint Freeze
→ Rojo Build
→ Studio/MCP Handshake
→ Runtime Engine Provider
→ Remote / Player / Instance / Input Adapter
→ automated runtime/integration tests
→ lifecycle/error/reconnect tests
→ INTEGRATION_READY
```

E1은 자동 Harness로 correctness를 검증한다. **기능 테스트를 위해 임시 UI를 만들지 않는다.**

Pathfinding/Spatial/Physics Runtime Provider도 E1에서만 Studio 구현한다.

## 6. U0 Product UI Shell Session

U0는 별도 Execution Class가 아니라 **E1과 E2 사이의 필수 Presentation Preparation Gate**다.

### U0-A — HTML/UI Reference Distillation

`INTEGRATION_READY` 이후 Studio Shell을 만들기 전에:

1. 당시 Branch에서 실제 HTML UI 예시 파일을 다시 탐색해 `Reference HTML Inventory`를 만든다.
2. `docs/remake/ui`의 최신 Global Policy, Shared UI, Character Sheet, Combat HUD, DM Workspace, Scene Editor, Common Input 등 현재 UI 권위를 읽는다.
3. HTML 예시는 **디자인·정보구조 참고**로만 사용한다. Gameplay Authority/State Ownership/Rule 권위로 사용하지 않는다.
4. 기대되는 HTML 예시를 실제로 찾거나 읽을 수 없으면 임의 디자인을 발명하지 않고 `BLOCK_U0_AND_ESCALATE_TO_PLANNING`한다.
5. 다음 내용을 구현용 글로 먼저 확정한다.

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
Responsive Scale / Accessibility
Reduced Motion Policy
Debug Fixture Policy
Roblox GUI Mapping
Explicit UI Non-goals
```

HTML을 그대로 Roblox GUI로 복사하는 것이 아니라, **왜 그런 UI 구조와 시각 규칙을 사용하는지 글로 추출한 뒤 Roblox 제약에 맞게 매핑**한다.

### U0-B — Product UI Shell Scaffold

Surface Inventory에서 확인된 실제 제품 Surface를 기능 없이 먼저 전부 자리 잡는다.

예시 범위는 당시 UI Authority를 기준으로 확정하며, 현재 알려진 축은 다음과 같다.

```text
Global App Shell / Navigation
Mode HUDs
World / Exploration HUD
Character Console
Character Sheet
Inventory / Loot
Journal / Map
Settings
Encounter / Combat HUD
DM Live Workspace
Scene Authoring
Entry / Rest / Death / Recovery
Modal / Prompt / Context Surface
Tooltip / Toast / Error / Loading / Empty State
```

규칙:

- Shell은 실제 제품 구조다. throwaway mock/test GUI가 아니다.
- 기능/규칙/권위 로직은 넣지 않는다.
- Placeholder/Fixture 데이터는 허용한다.
- Semantic Design Token과 공통 Component 방향을 사용한다.
- Viewer/Mode/Role에 따라 어떤 Surface가 존재하는지 구조를 확인할 수 있어야 한다.

### U0-C — Human Shell Review

사용자가 Studio에서 최소 다음을 확인한다.

```text
전체 Surface 누락 여부
Navigation과 Panel 관계
Mode별 HUD 전환 구조
Character/Inventory/Journal/Combat/DM/Scene 화면의 자리
Modal/Overlay/Z-order
화면 겹침과 정보 밀도
기본 Scaling/Accessibility 방향
```

수정 후 `UI_SHELL_READY`가 되어야 E2를 시작한다.

## 7. Debug / Fixture / Test UI 규칙

`UI_SHELL_READY` 이후 별도 임시 `ScreenGui`나 기능별 Test Panel을 만들지 않는다.

```text
Presentation-only test
→ Dev Fixture Adapter
→ fake Projection / ViewModel
→ actual Product Shell

Gameplay test
→ Product Shell의 dev-mode Debug Control
→ actual CommandClient
→ actual Server Authority / Transaction
```

Debug Control:

- 실제 Product Shell 내부의 Dev Slot만 사용.
- Production에서 제거/비활성화 가능.
- Authority/World/Domain Store 직접 mutation 금지.
- 별도 Remote/Authority Path 금지.
- 제품에 필요한 UI라면 Surface Inventory와 실제 Shell에 추가.
- 제품 UI가 아니라면 자동 Harness로 테스트.

## 8. E2 Presentation / Feel JIT

`UI_SHELL_READY` 이후:

```text
S1_SELECTION
→ C1_CAMERA
→ M1_MOVE
→ X1_CONTEXT
→ I1_INTERACTION
```

각 Checkpoint 직전에 해당 Coverage와 실제 Shell 연결만 상세화한다.

```text
UI_SHELL_READY
→ 현재 Checkpoint Coverage READY
→ 현재 Checkpoint Contract JIT
→ 실제 Product Shell / World Presentation 연결
→ Codex Studio self-check
→ READY_FOR_USER
→ 사용자 Play
→ 수정 반복
→ 사용자 수용
→ Authority Reconciliation
→ ACCEPTED
→ 다음 Checkpoint
```

### S1 Selection

`SemanticInputRouter → SelectionController → local selection state → WorldPresenter`. Runtime Identity, Spatial Query, ViewModel/Input Recovery, Visibility 결과를 반영해 최종화한다.

### C1 Camera

Client-local Presentation/Feel. Input Context/Recovery와 S1 결과를 반영한다.

### M1 Move

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

Navigation/Pathfinding/Transaction 경계는 M1 직전 승인된 계약을 따른다.

### X1 Context / I1 Interaction

대상 타입별 하드코딩 메뉴나 feature-specific authority path를 만들지 않고 Capability/Availability, Interaction Query, RuleExecution, Visibility 경계를 재사용한다.

## 9. Human Checkpoint 규칙

```text
PLANNED
IMPLEMENTING
READY_FOR_USER
ACCEPTED
BLOCKED
```

- Coverage Gate + `UI_SHELL_READY`가 E2 `IMPLEMENTING`의 선행 조건.
- `READY_FOR_USER` 동안 다음 Feature Checkpoint를 상세 구현하지 않는다.
- 사용자 수용 후 Authority Reconciliation + Coverage/Contract + Canonical Source + Focused Test + Promotion Commit 후 `ACCEPTED`.

## 10. Exploration 이후 큰 제품 순서

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

각 P단계도 구현 직전 Coverage와 미래 Pressure를 재검토한다. 미래 Capability 추적과 미래 내부 API 선행 설계는 구분한다.

## 11. 비협상 기술 안전 규칙

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
12. 오류는 structured diagnostic으로 남긴다.
13. Domain/Controller가 DataStore를 직접 호출하지 않는다.
14. Studio-only production truth를 허용하지 않는다.
15. Legacy Source/Project는 read-only reference다.
16. undeclared cross-module Stable Function 호출을 허용하지 않는다.
17. Coverage blocker를 임시 Source 구조로 우회하지 않는다.
18. `CORE_ENGINE_COMPLETE` 이전 Studio/MCP 구현 금지.
19. `UI_SHELL_READY` 이후 throwaway test UI 금지.
20. Debug UI의 direct authority/store mutation 금지.

## 12. 변경 Gate

Coverage Gap, Execution Class, 시스템 순서, Authority, state owner, Module responsibility, Checkpoint 구체화 시점, U0 UI Shell 정책 또는 개발 방식을 바꾸려면 사용자에게 먼저 제안한다.

현재 승인된 실행 방식:

```text
Coverage / Planning
→ Implementation Authority Distillation
→ E0 Checkpoint Freeze
→ Repository Core Engine COMPLETE
→ E1 Checkpoint Freeze
→ Studio Runtime Integration
→ U0 HTML/UI Distillation + Product UI Shell + Human Shell Review
→ UI_SHELL_READY
→ E2 User Checkpoint JIT
→ Human Presentation / Feel
```
