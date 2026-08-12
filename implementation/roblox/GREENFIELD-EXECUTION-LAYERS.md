# RVTT Greenfield Execution Layers

- 상태: `ACTIVE · EXECUTION_ENVIRONMENT_AUTHORITY`
- 최종 갱신일: 2026-08-13
- Architecture Coverage Gate: [`ARCHITECTURE-COVERAGE-POLICY.md`](ARCHITECTURE-COVERAGE-POLICY.md)
- Coverage Registry: [`manifests/architecture-coverage.json`](manifests/architecture-coverage.json)
- Machine-readable plan: [`manifests/execution-layers.json`](manifests/execution-layers.json)
- Module contracts: [`MODULE-CONTRACTS.md`](MODULE-CONTRACTS.md)
- System/function contracts: [`SYSTEM-FUNCTION-CONTRACTS.md`](SYSTEM-FUNCTION-CONTRACTS.md)
- Build order: [`GREENFIELD-SYSTEM-SEQUENCE.md`](GREENFIELD-SYSTEM-SEQUENCE.md)

이 문서는 **Coverage가 확인된 책임을 어디에서 구현하고 어떤 종류의 테스트로 통과시킬지**를 소유한다.

Execution Class는 Product Coverage를 대신하지 않는다.

```text
Architecture Coverage
→ System / Module / Stable Function Contract
→ Execution Class
→ 구현 Checkpoint
→ 구현 / 검증 환경
```

현재 Architecture Coverage Gate가 `BLOCKED_BY_FOUNDATION_COVERAGE_GAPS`이므로 E0 Source는 아직 시작하지 않는다.

핵심 실행 원칙:

```text
보이지 않는 순수 엔진
→ GitHub Canonical Source에서 먼저 구현·자동 테스트
→ 모든 E0 Core Engine 완료
→ CORE_ENGINE_COMPLETE

그 이후에만
→ Roblox Runtime Engine / Adapter / Controller / Manager 상세화
→ Studio/MCP Runtime Integration

그 이후에만
→ 보이는 UI·Presentation·조작감
→ Studio Play + 사용자 직접 판단
```

**`CORE_ENGINE_COMPLETE` 이전에는 어떤 Studio/MCP 구현·튜닝도 시작하지 않는다.** Runtime-coupled Engine도 E1 작업이며 예외가 아니다.

Studio를 일반 코드 에디터 대신 **Core Engine 완료 후 Roblox Runtime Integration + Presentation/Feel 검증 도구**로 사용한다.

## 1. Coverage 선행 조건

각 Execution Phase를 시작하기 전에 `architecture-coverage.json.phaseGates`를 확인한다.

```text
Phase blockedBy = []
+ Coverage Validator PASS
+ implementationGate가 해당 Phase를 허용
→ Execution Phase 진입 가능
```

OPEN Blocking Gap이 있으면 해당 Phase에 배정된 Module이 이미 Registry에 있어도 Source를 만들지 않는다.

Coverage Finding을 해소하려고 Execution Class만 바꿔 책임 누락을 숨기지 않는다. System/Module/Authority 변경이 필요하면 사용자에게 먼저 제안한다.

## 2. Checkpoint 구체화 시점

Implementation Checkpoint를 한 번에 전부 상세화하지 않는다.

```text
E0 Core Engine Checkpoint
→ Coverage Gap 해결 + Core System Boundary 확정 직후
→ E0 Source 작성 직전에 구체화

E1 Studio Runtime Checkpoint
→ 모든 E0 Checkpoint 완료 + CORE_ENGINE_COMPLETE 직후
→ Studio를 열기 전에 구체화

E2 Presentation / Feel Checkpoint
→ INTEGRATION_READY 이후
→ S1, C1, M1, X1, I1 각각 시작 직전에 JIT 구체화
```

E1 Checkpoint Freeze에서 직접 구현할 Roblox `Service / Manager / Controller / Adapter / Composition Root / Studio Harness` 목록을 확정한다. Core Engine이 아직 변하는 동안 Studio Runtime 구조를 먼저 고정하지 않는다.

## 3. 공통 Source 권위

어느 Execution Class든 최종 Source 권위는 `greenfield/src`다.

- Studio에서 만든 코드만 남기는 상태 금지.
- E1 이후 MCP를 이용해 Studio에서 빠르게 수정할 수 있지만 coherent change가 끝나면 `greenfield/src`와 즉시 정합화한다.
- 최종 완료를 Studio-only truth로 선언하지 않는다.
- Rojo로 같은 DataModel을 재현할 수 있어야 한다.

## 4. CORE_ENGINE

Roblox Workspace/서비스의 실제 결과가 없어도 correctness를 판단할 수 있는 엔진 코드다.

현재 Execution Registry의 **잠정 E0 후보**:

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

이 목록은 아직 구현 명령이 아니다. Coverage Audit의 E0 Blocker가 해소된 뒤 책임 경계를 다시 확인하고 E0 Checkpoint Freeze에서 최종화한다.

현재 E0 blocker:

```text
GAP-001 Session Policy Boundary
GAP-002 Transaction / Event / Projection Barrier
GAP-003 Runtime Object / Scene Identity
GAP-005 Navigation / Movement Boundary
GAP-007 Capability / Action Availability Projection
GAP-008 RuleExecution Boundary
```

Coverage가 READY가 된 뒤 구현 순서:

```text
E0 Checkpoint Freeze
→ System/Module/Stable Function Contract
→ greenfield/src 구현
→ repository automated test
→ negative/fail-closed test
→ 모든 E0 Checkpoint 완료
→ CORE_ENGINE_COMPLETE
```

여기서는 Studio/MCP를 사용하지 않고 사람이 Engine 함수를 클릭하며 확인하지 않는다.

대표 테스트:

- malformed command rejection
- duplicate command id
- stale revision
- authorization denial
- transactional/revision semantics according to resolved transaction architecture
- viewer disclosure filtering
- movement/interaction domain validation according to resolved capability/navigation architecture
- structured failure/result semantics

`CORE_ENGINE_COMPLETE`는 모든 E0 Module이 계약과 Repository Test Gate를 통과한 상태를 뜻한다. Studio Runtime Provider가 필요한 영역도 Request/Result Contract, Policy, Permission, Failure/Recompute Semantics처럼 Repository에서 정의 가능한 부분을 먼저 완료해야 한다.

## 5. ROBLOX_RUNTIME_ENGINE

엔진이지만 correctness가 Roblox Runtime 자체에 의존하는 경우다.

대표 사례:

- `PathfindingService`
- 실제 NavMesh와 Agent parameter
- Workspace raycast/spatial provider
- physics/collision 결과
- StreamingEnabled 영향
- DataStore/MemoryStore adapter

이 Class는 **E1에 속하며 `CORE_ENGINE_COMPLETE` 이후에만 Studio에서 구현·튜닝한다.**

```text
CORE_ENGINE_COMPLETE
→ E1 Coverage READY
→ E1 Checkpoint Freeze
→ GitHub-side Contract 준비 확인
→ Studio/MCP Runtime iteration
→ Studio automated runtime test
→ greenfield/src 정합화
→ RUNTIME_ENGINE_READY
```

Studio에서만 존재하는 엔진은 허용하지 않는다.

### Pathfinding 예

현재는 `GAP-005`가 OPEN이므로 구체 Module/API를 고정하지 않는다.

Gap 해결 뒤 Pathfinding 하나도 세 부분으로 나눈다.

**E0 Repository/Core 책임:**

- path request/response data shape
- movement permission/budget rules
- 실패 코드와 recompute 정책
- Workspace와 무관한 waypoint/plan normalization
- pure fallback/path policy가 있다면 그 알고리즘

**E1 Studio/Runtime 책임:**

- `PathfindingService` 실제 호출 또는 승인된 Runtime Navigation Provider
- NavMesh/Agent parameter 결과
- 장애물/CollisionGroup과 경로 결과
- raycast/spatial-provider 실제 결과
- 동적 장애물 재탐색

**E2 Human/Feel 책임:**

- 경로 Preview 가독성
- 클릭 후 반응
- Token 이동의 부드러움
- 사용자 의도와 실제 이동의 대응

## 6. ROBLOX_INTEGRATION

이미 검증된 Core Engine과 Roblox Runtime을 연결하는 Adapter/Composition이다.

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

E1 Coverage blocker가 없어야 하고 `CORE_ENGINE_COMPLETE`가 반드시 선행되어야 한다.

주 검증 환경은 Studio/MCP다.

```text
CORE_ENGINE_COMPLETE
→ E1 Coverage READY
→ E1 Checkpoint Freeze
→ Rojo build
→ Studio/MCP handshake
→ Studio boot
→ Runtime Engine + Remote/Player/Instance/Input 연결
→ Codex 자동 통합 테스트
→ cleanup/reconnect/error test
→ INTEGRATION_READY
```

이 단계는 원칙적으로 사용자에게 UI 평가를 요구하지 않는다.

## 7. PRESENTATION_FEEL

사람이 실제로 보고 만져야 평가 가능한 부분이다.

현재 잠정 범위:

```text
SelectionController
WorldPresenter
CameraController
MovementController
ContextActionController
```

각 Checkpoint는 E1이 끝난 뒤 하나씩 JIT 상세화한다.

```text
INTEGRATION_READY
→ 현재 Checkpoint Coverage READY
→ 현재 Checkpoint 상세 Contract 구체화
→ Presentation/Controller 연결
→ Codex Studio self-check
→ READY_FOR_USER
→ 사용자 Play
→ 수정 반복
→ 사용자 수용
→ Authority Reconciliation
→ ACCEPTED
→ 다음 Checkpoint 상세화
```

## 8. 분류 규칙

새 Module이 승인돼 생기면 구현 전에 반드시 한 Execution Class를 고른다.

판정 순서:

```text
실제 Roblox Runtime 없이 correctness를 테스트 가능한가?
YES → CORE_ENGINE
NO ↓

Roblox Runtime 결과가 필요하지만 사람의 감각 평가는 필요 없는가?
YES → ROBLOX_RUNTIME_ENGINE 또는 ROBLOX_INTEGRATION
NO ↓

화면·조작감·가독성·체감이 핵심인가?
YES → PRESENTATION_FEEL
```

`ROBLOX_RUNTIME_ENGINE`과 `ROBLOX_INTEGRATION`의 차이:

- Runtime Engine: Roblox 서비스/공간 결과 자체가 도메인/엔진 계산의 일부.
- Integration: 이미 존재하는 엔진을 Remote/Player/Input/Instance lifecycle에 연결.

분류가 `ROBLOX_RUNTIME_ENGINE`이라고 해서 E0보다 먼저 Studio에 들어갈 수 있는 것은 아니다.

## 9. 테스트 권위

```text
Architecture Coverage
= 어떤 책임/Scenario가 반드시 존재해야 하는가

CORE_ENGINE
= Repository automated tests가 1차 PASS 권위

ROBLOX_RUNTIME_ENGINE
= E0 완료 후 Repository contract tests + Studio automated runtime tests

ROBLOX_INTEGRATION
= E0 완료 후 Studio automated integration tests

PRESENTATION_FEEL
= E1 완료 후 Studio self-check + Human Acceptance
```

Console 호출은 보조 수단이다. 반복 가능한 Harness/Test가 가능한 경우 콘솔 수동 호출만으로 완료 처리하지 않는다.

## 10. 수직 개발과의 관계

수직 개발을 폐기하지 않는다.

```text
공통 Core Engine 전체 선완성
→ CORE_ENGINE_COMPLETE
→ Roblox Runtime Engine / Integration 선검증
→ INTEGRATION_READY
→ Selection vertical slice
→ Camera vertical slice
→ Move vertical slice
→ Context vertical slice
→ Interaction vertical slice
```

사용자-facing 수직 슬라이스는 E2에서 유지한다. 아직 설계가 확정되지 않은 먼 미래 시스템의 Domain/API는 추측해 구현하지 않는다.

## 11. 변경 Gate

Coverage Gap 해결, Execution Class 변경, Checkpoint 상세화 시점 또는 더 나은 구조가 Module 책임, Authority, state owner, System flow를 바꾸면 자동 적용하지 않는다. 문제·대안·영향을 사용자에게 먼저 제안한다.
