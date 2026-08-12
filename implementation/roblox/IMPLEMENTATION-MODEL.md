# RVTT Implementation Model

- 상태: `ACTIVE · SYSTEM_MODEL_V2_REPAIRED · R3_REPAIRED_AWAITING_FREEZE_DECISION`
- 최종 갱신일: 2026-08-13
- System Authority: [`SYSTEMS.md`](SYSTEMS.md)
- Machine-readable Model: [`manifests/implementation-system-model.json`](manifests/implementation-system-model.json)
- Source 구현: `FORBIDDEN`
- Studio/MCP 구현: `FORBIDDEN`

## 1. 현재 기준

기존 `25 modules / 10 systems / 64 stable functions` Greenfield 모델은 폐기된 구현 모델이다.

다음은 새 구현의 기본값이나 제약이 아니다.

- 기존 Greenfield System 이름과 경계
- 기존 Module split
- 기존 Stable Function 목록
- 기존 G0~G5 stage 구조
- 기존 E0/E1 module classification
- 기존 `WorldState.transact` 중심 mutation 모델
- 기존 Selection/Movement/Context controller wiring

현재 구현 System 권위는 `SYSTEMS.md`의 **34-System Responsibility Model v2**다.

Requirement Coverage 권위는 `implementation-system-model.json`의 **30 Requirement Capability Catalog v3**다. Requirement Capability는 System 이름의 별칭이 아니라 Product/Architecture 요구를 System에 many-to-many로 압박하는 독립 축이다.

Base 14 + Expanded 47 = **61 Scenario**는 기존 Scenario Registry에 유지하며, 새 모델의 canonical `Scenario → Requirement Capability[] → System[]` trace는 `implementation-system-model.json`에 둔다.

## 2. 완료된 단계와 R3 Self Review 수정

```text
R0 Requirement Distillation = COMPLETE
R1 System Model From Scratch = COMPLETE
R2 61 Scenario Pressure Review = COMPLETE
System Model v1 user approval = COMPLETE
R3 self review = COMPLETE
R3 repair = COMPLETE, freeze not yet granted
```

Self Review에서 발견하고 수정한 항목:

```text
1. Domain Event Delivery owner 누락
   → A8 Domain Event Delivery Runtime 추가

2. REPOSITORY_LOGIC와 E0_CORE_ENGINE 혼동
   → 분리 정의

3. E1 Provider 선행 Core seam 누락
   → W5/W6/W7/C1/C2/C3/S2 포함 E0 seam set 명시

4. Capability가 System과 사실상 1:1
   → 30 Requirement Capability many-to-many Catalog v3로 교체

5. 61 Scenario 새 trace가 사람 문서에만 존재
   → machine-readable trace 추가

6. Ready Gate 소유권 겹침
   → A6/A7/W7/C1 evidence, A1 final gate로 고정

7. Reservation 의미 충돌
   → Ordering/Resource/Occupancy/Activity/Logistics typed taxonomy 고정

8. 공통 nondeterminism/provider seam 불명확
   → Clock/ID/RNG/Transport/Storage provider contracts 고정

9. CI가 승인 문자열만 확인
   → model/count/reference/scenario/invariant 구조 검증으로 강화
```

## 3. REPOSITORY_LOGIC와 E0_CORE_ENGINE

두 용어를 절대 같은 뜻으로 사용하지 않는다.

### REPOSITORY_LOGIC

Roblox Runtime 없이 구현하고 자동 검증할 수 있는 모든 production logic의 **분류**다.

예:

- policy / state machine
- schema / contract
- deterministic orchestration
- identity / revision / epoch rules
- pure calculation
- serialization-neutral domain logic
- failure semantics
- external provider interface

`REPOSITORY_LOGIC`라고 분류되었다고 해서 전부 Studio 전에 구현해야 한다는 뜻은 아니다.

### E0_CORE_ENGINE

Studio/MCP에 들어가기 전에 반드시 완성해야 하는 **Repository Foundation subset**이다.

`CORE_ENGINE_COMPLETE`의 의미:

```text
R4에서 Freeze된 모든 E0 required seam 구현 완료
+ 자동화 negative/fail-closed test 통과
+ future compatibility contract test 통과
+ deterministic harness evidence 통과
+ Studio Provider를 숨은 Architecture 권위로 사용하지 않음
```

Character, Journal, Actor Authoring처럼 Repository에서 구현 가능한 미래 feature logic 전부를 완료했다는 뜻은 아니다.

현재 R3의 E0 pre-Studio seam set은 machine-readable manifest의 `e0RequiredSystemSeams`가 소유한다. `D6 Journal`, `D7 Campaign Logistics`, `U2 Actor Authoring` feature implementation은 현재 CORE_ENGINE_COMPLETE 필수가 아니며, R4에서 실제 선행 의존성이 증명될 때만 사용자 결정으로 승격한다.

## 4. R3 Boundary 원칙

System 전체를 한 실행 환경에 억지로 배치하지 않는다.

```text
REPOSITORY_LOGIC
= Roblox 없이 correctness 검증 가능

E0_CORE_ENGINE
= E1 전에 반드시 완성되는 Foundation subset

E1_ROBLOX_RUNTIME
= Roblox 서비스/geometry/runtime 결과가 correctness의 일부인 Provider/Adapter

HUMAN_PRESENTATION
= 실제 UI/VFX/Camera feel/interaction readability처럼 사람 검토가 필요한 결과
```

E1 Provider가 소비하는 Core contract/policy/state-machine은 반드시 E0에서 먼저 구현한다.

예:

```text
Navigation
E0: request/result, planning policy, movement budget, occupancy semantics, replan/failure/checkpoint state machine
E1: PathfindingService/NavMesh/raycast/collision/dynamic-obstacle provider
E2: path preview, response, perceived movement feel
```

## 5. 공통 권위 불변식

### Domain Event

```text
A3 Transaction commit + Outbox
→ A8 committed-only dispatch/subscription/retry/receipt
→ A5 Projection subscriber / follow-up / diagnostics
```

A8은 두 번째 Command Bus가 아니다. 상태 변경이 필요하면 새 Command/RuleExecution을 제출한다.

### Ready Gate

```text
A7 authorityRecoveryReady
A6 projectionSyncReady
W7 sceneEssentialReady
C1 clientReplicaReady
→ A1 EffectiveGameplayReady
→ A1 only final Command gate
```

### Reservation

```text
OrderingReservation              → A3
ResourceReservation              → R3 orchestration, underlying resource stays in domain
OccupancyReservation             → W6
ActivityReservation              → D5
LogisticsAllocationReservation   → D7
```

범용 ReservationManager 하나로 합치지 않는다.

### Shared Provider Contracts

```text
AuthorityMonotonicClock
DeterministicIdFactory
RngProvider
TransportAdapter
StorageAdapter
```

- Campaign Game Time은 D4이며 AuthorityMonotonicClock과 다르다.
- Domain별 Remote authority path를 만들지 않는다.
- Domain이 Storage adapter를 직접 사용해 A3/A7을 우회하지 않는다.
- S2가 동일 interface의 deterministic test adapter를 제공한다.

## 6. 실행 순서

```text
R3 repaired model validation
→ 사용자 R3 Freeze 결정
→ R4 E0 Checkpoint Freeze
→ R5 Dedicated Implementation Branch
→ E0 Core Engine 전체 구현/자동 검증
→ CORE_ENGINE_COMPLETE
→ E1 Roblox Runtime Engine / Integration Checkpoint Freeze
→ Studio/MCP Runtime Provider 구현/자동 검증
→ INTEGRATION_READY
→ U0-A HTML/UI Reference Distillation
→ U0-B Product UI Shell Scaffold
→ U0-C Human Shell Review
→ UI_SHELL_READY
→ E2 User-facing Checkpoint JIT
→ Human Acceptance
```

**Studio/MCP 작업은 E0 Core Engine 전체가 완료되고 `CORE_ENGINE_COMPLETE`가 선언된 이후에만 시작한다.**

Pathfinding/Raycast/Physics처럼 Roblox Runtime이 필요한 책임도 R4에서 Core contract/policy/failure seam을 먼저 Freeze하고 E0에서 구현한 뒤 E1 Provider를 만든다.

## 7. R4 — E0 Checkpoint Freeze

Core Engine 실제 구현 직전에만 System → Module → Stable Function을 구체화한다.

각 Checkpoint 필수:

```text
Checkpoint ID
Current Deliverable
System / Module Scope
Stable Function Scope
Authority / State Ownership
Input / Output Contract
Current Scenario Working Set
Requirement Capability Set
Future Consumers
Future Scenario Pressure Set
Extension Seams
Stable Ownership / Identity Seams
Persistence / Reconnect / Rollback Seams
Observability / Failure Seams
Required Platform Provider Contracts
Forbidden Shortcuts
Explicit Deferred Non-goals
Repository Tests
Negative / Fail-closed Tests
Future Compatibility Contract Tests
Completion Condition
```

R4는 manifest의 `e0RequiredSystemSeams`를 실제 Checkpoint 묶음으로 최소화한다. 먼 미래 feature API를 미리 대량 설계하지 않는다.

## 8. R5 — Dedicated Implementation Branch

E0 Checkpoint Freeze가 끝난 뒤 별도 구현 브랜치를 만든다.

구현 AI 기본 표면은 압축된 Pack만 사용한다.

```text
IMPLEMENTATION.md
SYSTEMS.md
implementation-system-model.json
Scenario Working Set
CONTRACTS.json
BUILD-ORDER.md
TEST-GATES.md
BASELINE.json
src/
tests/
```

`BASELINE.json`은 승인된 Planning commit SHA를 기록한다.

Planning Tree 전체는 기본 검색하지 않는다. 구현 중 미모델링 책임이나 미래 충돌이 발견되면 `ESCALATE_TO_PLANNING`한다.

## 9. U0 Product UI Shell

U0는 `INTEGRATION_READY` 뒤 E2 전에 한 번 수행한다.

- 당시 Branch에서 실제 HTML UI 예시를 다시 발견하고 읽는다.
- 최신 UI Authority와 함께 UI 종류, 정보구조, 디자인 철학, 시각 언어, 상태 표현, 접근성, Roblox GUI mapping을 글로 먼저 Distill한다.
- 실제 제품 Surface 전체의 Shell을 만든다.
- 이후 throwaway Test ScreenGui를 만들지 않는다.
- UI 테스트는 실제 Product Shell의 dev-mode Debug/Fixture Control을 사용한다.
- Gameplay Debug는 실제 Command/Server Authority/Transaction 경계를 우회하지 않는다.

## 10. 금지

- 폐기된 Greenfield Module/Function 목록을 새 모델의 출발점으로 복원.
- A3 Outbox와 A8 Event Delivery를 하나의 실패 도메인으로 합침.
- A6/A7/W7/C1이 final gameplay Command gate를 직접 열음.
- 서로 다른 Reservation을 범용 lock/reservation manager로 통합.
- 각 System이 `os.clock`/GUID/Random/Remote/Storage를 제각각 직접 사용.
- 현재 기능만 통과시키는 feature-specific shared boundary.
- 미래 기능을 핑계로 먼 미래 내부 API를 대량 선설계.
- Core Engine 완료 전 Studio/MCP 구현.
- R4 전 Module/Stable Function 대량 확정.
- UI Shell 이후 throwaway test UI.
- 사용자 승인 없이 Product/ADR/Authority/state ownership/input grammar/development sequence 변경.

## 11. 현재 상태

```text
SYSTEM MODEL = V2 · 34 SYSTEMS · REPAIRED
REQUIREMENT CAPABILITY = V3 · 30 · MANY-TO-MANY
SCENARIO TRACE = 61/61 MACHINE-READABLE
CURRENT = R3 REPAIRED · AWAITING FREEZE DECISION
SOURCE IMPLEMENTATION = FORBIDDEN
STUDIO IMPLEMENTATION = FORBIDDEN
DEDICATED IMPLEMENTATION BRANCH = NOT YET CREATED
```

## 12. R3 Semantic Audit Addendum

후속 재검증에서 machine-readable trace가 **형식적으로 유효한 것과 의미적으로 완전한 것은 다르다**는 점을 확인했다. 이에 61개 Scenario를 모두 단계 의미로 다시 감사했다.

```text
Scenario Semantic Audit = V1 · 61/61
semantic digest = sha256:57e485a0cec6d753542e4bc202a881e10e2bd5ae63e314cc609c7e2d99f38140
```

각 Scenario는 `semanticStages[]`를 가진다.

```text
READ
MUTATION
EVENT
PROJECTION
RECOVERY
HUMAN
```

불변식:

```text
MUTATION → A3 + REQ_ATOMIC_CONCURRENCY
EVENT → A3 + A8 + REQ_COMMITTED_EVENT_PROPAGATION
PROJECTION → A5 + A6 + REQ_VIEWER_SAFE_PROJECTION
RECOVERY → A6 또는 A7 + recovery/session requirement
HUMAN → C1/C2/C3/U1/U2 중 하나 이상
```

이 감사로 Actor publish/spawn, Character migration activation, Ready action, scene source commit, DM takeover, NPC publish/spawn 등에서 빠져 있던 Transaction/Event/Projection pressure를 보완했다. Restart/reconnect가 correctness에 포함되는 Rest/Craft/Travel 계열에는 Recovery pressure를 명시했다.

### A8/A7 Durability Reconciliation

Accepted Event 계약의 durable SubscriberReceipt/Outbox cursor/retry와 Persistence 계약의 storage ownership을 다음처럼 조정한다.

```text
A3
= Outbox atomicity와 committed event 사실

A8
= delivery / subscription / retry / SubscriberReceipt / dead-letter 의미

A7
= durable persistence와 restart reconstruction mechanism

A8 delivery semantics → A7 durability seam → StorageAdapter
```

- A8은 `StorageAdapter`를 직접 사용하지 않는다.
- A7은 A8의 SubscriptionDefinition, ordering scope, retry/failure policy를 소유하지 않는다.
- `STORAGE_ADAPTER` production consumer는 계속 A7 하나다.
- Durable event delivery state는 A7이 제공하는 persistence seam을 통해서만 저장·복구한다.

R3는 이 addendum 이후에도 자동 Freeze되지 않는다. 전체 Validator/CI가 최종 통과한 뒤 사용자 결정으로만 R3를 Freeze한다.
