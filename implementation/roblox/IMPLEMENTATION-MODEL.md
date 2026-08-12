# RVTT Implementation Model

- 상태: `ACTIVE · SYSTEM_MODEL_V1_APPROVED · R3_BOUNDARY_FREEZE`
- 최종 갱신일: 2026-08-13
- System Authority: [`SYSTEMS.md`](SYSTEMS.md)
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

현재 구현 System 권위는 `SYSTEMS.md`의 **33-System Model v1**이다.

현재 Capability 권위는 `SYSTEMS.md`의 **Capability Catalog v2 · 34 capabilities**다.

`architecture-coverage.json`의 기존 22 Capability와 `systemRefs/moduleRefs`는 R0/R1에 사용한 legacy coverage vocabulary/evidence로 보존한다. 새 구현 책임 경계를 복원하는 권위로 사용하지 않는다.

## 2. 완료된 단계

```text
R0 Requirement Distillation = COMPLETE
R1 System Model From Scratch = COMPLETE
R2 61 Scenario Pressure Review = COMPLETE
System Model v1 user approval = COMPLETE
Capability Catalog v2 refactor = COMPLETE
```

R2 결과:

```text
Scenario reviewed = 61 / 61
Empty responsibility path = 0
Old Greenfield module assumption = 0
Approved systems = 33
```

세부 Pressure Map은 `audits/IMPLEMENTATION-MODEL-R2-SCENARIO-PRESSURE-001.md`에 있다.

## 3. 현재 단계 — R3 Core / Runtime / Presentation Boundary Freeze

R3의 목적은 **33개 System의 책임을 실행 환경별로 나누는 것**이다.

System 전체를 한 환경에 억지로 배치하지 않는다. 하나의 System이 Core 정책과 Roblox Runtime Provider, Presentation 책임을 동시에 가질 수 있다.

판정:

```text
Repository Core Engine
= Roblox Runtime 없이 correctness 자동 검증 가능
= policy / state machine / contract / pure calculation / deterministic orchestration

Roblox Runtime Engine / Adapter
= Roblox 서비스나 geometry/runtime 결과가 correctness의 일부
= PathfindingService / raycast / physics / collision / Instance / Player / Remote / Streaming / Roblox input adapter

Presentation / Human Feel
= 실제 UI / VFX / Camera feel / interaction readability처럼 사람 검토가 correctness에 필요
```

R3 출력은 각 System마다 최소 다음을 갖는다.

```text
Core responsibilities
Roblox-runtime responsibilities
Presentation/human responsibilities
External adapter seams
Forbidden cross-boundary shortcuts
Future consumers
Scenario pressure
Test evidence class
```

## 4. 실행 순서

```text
R3 Core/Runtime/Presentation Boundary Freeze
→ R4 E0 Checkpoint Freeze
→ R5 Dedicated Implementation Branch
→ E0 Repository Core Engine 전체 구현/자동 검증
→ CORE_ENGINE_COMPLETE
→ E1 Roblox Runtime Engine / Integration Checkpoint Freeze
→ Studio/MCP Runtime 구현/자동 검증
→ INTEGRATION_READY
→ U0-A HTML/UI Reference Distillation
→ U0-B Product UI Shell Scaffold
→ U0-C Human Shell Review
→ UI_SHELL_READY
→ E2 User-facing Checkpoint JIT
→ Human Acceptance
```

**Studio/MCP 작업은 Repository Core Engine 전체가 완료되고 `CORE_ENGINE_COMPLETE`가 선언된 이후에만 시작한다.**

Pathfinding/Raycast/Physics처럼 Roblox Runtime이 필요한 책임도 R3/R4에서 contract/policy/failure seam을 먼저 확정하고, 실제 Roblox Provider는 E1에서 구현한다.

## 5. R4 — E0 Checkpoint Freeze

Core Engine의 실제 구현 직전에만 System → Module → Stable Function을 구체화한다.

각 Checkpoint 필수:

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

미래 기능은 지금 구현하지 않는다. 하지만 미래 기능을 붙이기 위해 현재 public contract를 재작성해야 하는 Checkpoint도 Freeze하지 않는다.

## 6. R5 — Dedicated Implementation Branch

E0 Checkpoint Freeze가 끝난 뒤 별도 구현 브랜치를 만든다.

구현 AI 기본 표면은 압축된 Pack만 사용한다.

```text
IMPLEMENTATION.md
SYSTEMS.md
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

## 7. U0 Product UI Shell

U0는 `INTEGRATION_READY` 뒤 E2 전에 한 번 수행한다.

- 당시 Branch에서 실제 HTML UI 예시를 다시 발견하고 읽는다.
- 최신 UI Authority와 함께 UI 종류, 정보구조, 디자인 철학, 시각 언어, 상태 표현, 접근성, Roblox GUI mapping을 글로 먼저 Distill한다.
- 실제 제품 Surface 전체의 Shell을 만든다.
- 이후 throwaway Test ScreenGui를 만들지 않는다.
- UI 테스트는 실제 Product Shell의 dev-mode Debug/Fixture Control을 사용한다.
- Gameplay Debug는 실제 Command/Server Authority/Transaction 경계를 우회하지 않는다.

## 8. 금지

- 폐기된 Greenfield Module/Function 목록을 새 모델의 출발점으로 복원.
- 기존 GAP 번호를 맞추기 위해 System을 왜곡.
- 현재 기능만 통과시키는 feature-specific shared boundary.
- 미래 기능을 핑계로 먼 미래 내부 API를 대량 선설계.
- Core Engine 완료 전 Studio/MCP 구현.
- R4 전 Module/Stable Function 대량 확정.
- UI Shell 이후 throwaway test UI.
- 사용자 승인 없이 Product/ADR/Authority/state ownership/input grammar/development sequence 변경.

## 9. 현재 상태

```text
SYSTEM MODEL = V1 APPROVED
CAPABILITY CATALOG = V2 ACTIVE · 34
R2 SCENARIO REVIEW = 61/61 COMPLETE
CURRENT = R3 CORE_RUNTIME_PRESENTATION_BOUNDARY_FREEZE
SOURCE IMPLEMENTATION = FORBIDDEN
STUDIO IMPLEMENTATION = FORBIDDEN
DEDICATED IMPLEMENTATION BRANCH = NOT YET CREATED
```
