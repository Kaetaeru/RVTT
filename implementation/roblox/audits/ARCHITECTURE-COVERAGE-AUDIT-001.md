# RVTT Architecture Coverage Audit 001

- 상태: `CURRENT · PRE_IMPLEMENTATION_AUDIT`
- 작성일: 2026-08-13
- 대상 Branch: `agent/survival-logistics-token-authoring`
- Coverage Policy: [`../ARCHITECTURE-COVERAGE-POLICY.md`](../ARCHITECTURE-COVERAGE-POLICY.md)
- Coverage Registry: [`../manifests/architecture-coverage.json`](../manifests/architecture-coverage.json)
- 결론: `E0 BLOCKED · SOURCE NOT STARTED`

## 1. 감사 목적

현재 Greenfield Contract가 내부적으로 정합적인지만 보는 것이 아니라, **상위 Product·ADR·Architecture가 요구하는 핵심 Capability가 현재 System/Module 계획에서 빠졌는지** 확인했다.

이번 감사에서는 구현을 추가하지 않았다. 누락된 Architecture 경계를 발견해도 사용자 승인 없이 Module/System을 임의로 추가하지 않는다.

## 2. Authority Corpus Snapshot

검토 기준 Tree:

```text
docs/remake/product       ab4cbfe828536f6de19946f22772f92f8b679e0e
docs/remake/decisions     54125338b3af1650b4bce9d7e3ff31496ae7e03c
docs/remake/architecture  249d9a7293380c33f6d7195ddfa38da58fe86979
docs/remake/systems       742efb372264b85fa26a3f57b2541fd0405d26e2
docs/remake/ui            2effbddd018b02074daa2becc3d7d0b72e6e438b
docs/remake/specs         54da95b3aec97cef9eba8c4a698b534abc29505c
```

직접 확인한 주요 Index:

- Product README
- ADR README
- Architecture README
- Systems README
- UI README
- Implementation Specs README
- 16-Slice Roadmap

깊이 검토한 고위험 Architecture:

- Session Play Mode / Context / Overlay / Transition
- UI Projection / ViewModel / Input Context / Recovery
- Selection / Targeting / Frozen Binding
- Interaction Capability / Contextual Command
- Spatial Query Engine
- Runtime Navigation / Movement Execution
- Character Runtime / Compiled Character Build
- Character Action Opportunity / Core Action
- Rule Runtime Orchestrator / Pending Execution
- Command Ordering / Transaction Coordinator
- Domain Event / Outbox / Projection Boundary

## 3. 현재 Greenfield와 대응되는 부분

현재 25개 Module Contract는 다음 기반을 이미 명확하게 가진다.

```text
Command/Projection data contracts
Server Session role/control mapping
World actor state/revision
Authorization
Command runtime + transport
Viewer-safe projection + client replica
Semantic input router
Composition roots
Selection/Presenter
Camera
Movement domain/controller
Context/Exploration domain
```

이 기반 자체는 폐기 대상이 아니다. 문제는 일부 상위 Architecture 경계가 이 목록 사이에서 누락되거나 너무 압축돼 있다는 것이다.

## 4. 발견된 Foundation/Exploration Gap

### GAP-001 — Session Policy Boundary

상위 Architecture는 세션 상태를 다음 네 축으로 분리한다.

```text
Base Play Mode
+ Context Set
+ Overlay Stack
+ Transitional State
→ Effective Command Policy
```

현재 Greenfield에는 Role/Controller를 담당하는 `SessionAuthority`와 `SemanticInputRouter`는 있지만 이 Effective Command Policy를 소유하는 명시적 경계가 없다.

영향:

- Exploration/Encounter 입력 차이
- Selection Overlay
- Pause/Transition/Reconnect Gate
- Q/E Input Context
- Command 허용 정책

현재 결정: `FOUNDATION_BLOCKER`.

### GAP-002 — Transaction / Event / Projection Barrier

현재 계획은 크게:

```text
CommandRuntime
→ WorldState.transact
→ ProjectionService
```

형태다.

상위 Architecture는 다음 경계를 요구한다.

```text
Validated Command / RuleExecution
→ Ordering / Reservation
→ Transaction Plan
→ Atomic Commit
→ Authority Revision
→ Journal + Domain Event Outbox
→ Projection Barrier
```

`WorldState.transact` 하나가 단일 World actor mutation에는 적합할 수 있지만, 미래 Inventory·Encounter·Interaction·RuleExecution까지 포함하는 공통 원자성 경계와 동일한지 현재 Contract에는 설명이 없다.

현재 결정: `FOUNDATION_BLOCKER`.

### GAP-003 — Runtime Object / Scene Identity

현재 `WorldContract`와 `WorldState`는 Actor 중심이다.

하지만 Selection/Interaction 상위 계약은 다음을 공통 대상으로 요구한다.

```text
Actor
Runtime Object
Item Presence
Point / Area / Path
Door / Container / Trigger / Volume
```

또한 stale Runtime Object incarnation을 구분해야 한다.

현재 결정: `FOUNDATION_BLOCKER`.

### GAP-004 — Spatial Query

Selection 상위 계약은 Candidate 생성 경로를 명시한다.

```text
Pointer / Focus Ray
→ Spatial Query
→ Visibility Projection Filter
→ Candidate Set
→ Selection Policy
```

Navigation, Interaction, Perception도 같은 Spatial Query를 사용해야 한다.

현재 Greenfield에는 Spatial Query System/Module Contract가 없다.

현재 결정: `S1/M1/X1/I1 BLOCKER`.

### GAP-005 — Navigation / Movement Boundary

상위 Navigation 계약은 이동을 다음 책임으로 나눈다.

```text
Spatial Query
Navigation Planner
Movement Coordinator
Movement Executor
Presentation
```

현재는 `MovementDomain + MovementController`만 계획돼 있다.

PathfindingService와 실제 NavMesh는 Studio Runtime Engine일 수 있지만, Repository 쪽 Request/Plan/Policy/Failure/Execution 경계는 그 전에 필요하다.

현재 결정: `E0/M1 BLOCKER`.

### GAP-006 — Interaction Capability Query

현재 X1/I1은 `ContextActionController + ExplorationDomain`으로 잡혀 있다.

상위 계약은:

```text
Actor/Target/Item/Effect/Context Providers
→ Interaction Capability Query
→ Contextual Interaction Option Projection
→ Command Proposal
→ RuleExecution / DM Adjudication
```

을 요구한다.

대상 종류별 하드코딩 Context Menu를 막으려면 이 Query/Projection 경계가 명시되어야 한다.

현재 결정: `X1/I1 BLOCKER`.

### GAP-007 — Capability / Action Availability Projection

Character Console 질문에서 발견된 Gap이다.

상위 계약은 이미 다음 흐름을 정의한다.

```text
Compiled Character Build
+ Item / Effect Activation
→ Effective Capability View

Effective Capability View
+ ActionOpportunity
+ Runtime Context
→ Available Action Projection
→ Character Sheet / Combat HUD / Character Console
```

이 경계는 Character Console만의 미래 문제도 아니다. Context Interaction도 Actor가 현재 어떤 Capability를 쓸 수 있는지 알아야 한다.

현재 Greenfield에는 공통 Capability/Availability Resolver가 없다.

현재 결정: `FOUNDATION/X1/I1 + future Character Console BLOCKER`.

### GAP-008 — RuleExecution Boundary

상위 Runtime은 공격·주문·아이템·함정·상호작용이 같은 실행 흐름을 공유하도록 요구한다.

```text
Validated Intent
→ RuleExecution
→ Capability / Cost Reservation
→ Recipe / TimingWindow
→ PendingEffect
→ Transaction
→ Aftermath
```

현재 CommandRuntime은 일반 명령 실행 경계는 있지만 Persistent RuleExecution/Adjudication/Reaction/Reservation 경계는 없다.

현재 결정: `FOUNDATION/I1 BLOCKER`.

### GAP-009 — UI Projection / ViewModel / Input Context Recovery

현재 `ProjectionReplica`와 `SemanticInputRouter`는 좋은 기반이지만 상위 UI Architecture는 다음을 요구한다.

```text
Atomic Projection Replica
→ Derived ViewModel
→ UI Component
→ Semantic Input Context Stack
→ UI Intent
```

Reconnect/Rollback 시 AuthorityEpoch가 바뀌면 이전 Prompt/Selection/Input Context도 무효화해야 한다.

현재 결정: `E1/S1 BLOCKER`.

### GAP-010 — Visibility / Knowledge / Detection

현재 `ProjectionService`는 viewer-safe payload를 만든다는 계약은 있다.

하지만 Selection Candidate와 Context Action에서 어떤 Actor/Object/Capability의 존재 자체를 공개할지 결정하는 Visibility/Knowledge/Detection owner는 아직 없다.

현재 결정: `S1/X1/I1 BLOCKER`.

## 5. 추적하되 지금 구현하지 않는 Gap

### GAP-011 — Persistence / Reconnect / Rollback

현재 Foundation에서 DataStore를 끈 결정 자체는 유지한다.

다만 지금 만드는 ID, Epoch, Revision, Pending State가 나중 Recovery를 불가능하게 만들면 안 된다.

상태: `TRACKED_DEFERRED`.

### GAP-012 — Diagnostics / Deterministic Harness

현재 Validator와 Focused Test는 계속 사용한다.

전체 Correlation Trace, Virtual Clock/Network/Storage, Fault Injection과 Production Scenario Harness는 Stabilization 전에 별도 경계가 필요하다.

상태: `TRACKED_DEFERRED`.

## 6. 현재 E0 판정

현재 E0는 시작하지 않는다.

```text
E0_REPOSITORY_CORE_ENGINE
BLOCKED BY
- GAP-001
- GAP-002
- GAP-003
- GAP-005
- GAP-007
- GAP-008
```

이 의미는 `모든 미래 시스템을 지금 구현한다`가 아니다.

각 Gap에 대해 **현재 Foundation이 반드시 가져야 하는 최소 공통 경계와 미래로 미뤄도 되는 깊이**를 결정한 뒤 E0 계약을 다시 정합화한다.

## 7. 권장 해결 순서

의존성 기준으로 다음 순서가 가장 안전하다.

```text
1. Authority State / Transaction / Event Boundary
2. Session Mode / Context / Transition Policy
3. Runtime Object Identity / Scene Snapshot
4. Spatial Query
5. Selection Boundary
6. Navigation / Runtime Pathfinding Boundary
7. Capability / Availability / Action Opportunity
8. RuleExecution minimum boundary
9. Interaction Capability Query
10. Client Projection / ViewModel / Input Context Recovery
11. Visibility / Knowledge minimum boundary
```

이 순서는 해결 검토 순서다. 각 항목의 구체 Module split과 API는 사용자 승인 없이 자동 적용하지 않는다.

## 8. Coverage가 앞으로 막는 문제

앞으로 다음 상태는 자동으로 드러나야 한다.

```text
새 ADR 추가
+ Coverage Snapshot 미갱신
→ CI FAIL
```

```text
Product Capability 존재
+ System/Module 없음
→ UNMAPPED
```

```text
Module 존재
+ 어떤 Capability/Scenario에도 연결 안 됨
→ ORPHAN
```

```text
Scenario 중간 단계에 소유 System 없음
→ BLOCKED Scenario
```

```text
Persistence / Disclosure / Concurrency 등을 검토하지 않음
→ Cross-cutting Matrix 누락
```

## 9. 다음 행동

Source 구현이 아니라 Gap Resolution Architecture Review다.

첫 검토 대상은 `GAP-002 Transaction/Event Boundary`와 `GAP-001 Session Policy Boundary`다.

이 둘은 이후 Spatial Query, Movement, Capability, RuleExecution의 Authority와 Lifecycle을 결정하므로 먼저 고정해야 한다.
