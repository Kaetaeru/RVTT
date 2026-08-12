# RVTT Current Executable Task

- executionAuthority: `ONLY_CURRENT_EXECUTABLE_TASK`
- status: `IMPLEMENTATION_MODEL_RESET`
- commandId: `RVTT-IMPLEMENTATION-MODEL-RESET-001`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskMode: `WHOLE_PRODUCT_SYSTEM_MODEL_DERIVATION`
- sourceImplementationAllowed: `false`
- studioImplementationAllowed: `false`
- updatedAt: `2026-08-13`

## 1. 기본 읽기 경로

Codex는 기본적으로 다음만 읽는다.

```text
1. AGENTS.md
2. .github/CODEX-ACTIVE-TASK.md
3. implementation/roblox/IMPLEMENTATION-MODEL.md
4. implementation/roblox/ARCHITECTURE-COVERAGE-POLICY.md
5. implementation/roblox/manifests/architecture-coverage.json
6. implementation/roblox/manifests/architecture-scenarios.json
```

그 뒤 필요한 Requirement Evidence만 Product / Accepted ADR / Current Architecture / UI에서 선택적으로 읽는다.

기존 Greenfield System/Module/Stable Function/Execution 문서는 기본 읽기 대상이 아니다.

## 2. 폐기된 구현 모델

다음은 모두 `RETIRED_IMPLEMENTATION_MODEL`이다.

```text
25-module Greenfield registry
10-system Greenfield registry
64 stable function registry
G0~G5 stage model
기존 E0/E1 module classification
기존 controller/service/manager wiring
기존 WorldState.transact 중심 mutation 구조
```

새 모델은 이것을 고치는 방식으로 만들지 않는다.

기존 이름이나 경계가 최종적으로 다시 등장할 수는 있지만, **22 Capability + 61 Scenario + 상위 Authority를 처음부터 검토한 결과로만 재채택**한다.

## 3. 현재 목표

현재 목표는 Source가 아니라 **전체 제품 System Model을 처음부터 다시 만드는 것**이다.

```text
Authority / Capability / Scenario
→ Domain responsibility extraction
→ State / Authority owner inventory
→ System Model From Scratch
→ 61 Scenario end-to-end pressure review
→ Cross-cutting review
→ Core Engine / Roblox Runtime / Presentation boundary freeze
→ E0 Checkpoint freeze
→ Dedicated Implementation Branch
```

## 4. R0 — Requirement Distillation

22 Capability와 61 Scenario를 훑어 다음을 추출한다.

```text
Domain responsibilities
Authoritative state kinds
Client-local state kinds
Identity/version/revision requirements
Command/read/projection/event flows
Concurrency/transaction requirements
Disclosure/visibility requirements
Persistence/reconnect/rollback seams
Roblox-runtime dependencies
Presentation/human-feedback dependencies
Failure/observability/security requirements
```

`architecture-coverage.json`의 과거 `systemRefs/moduleRefs`는 참고하지 않는다. 해당 필드는 이전 Greenfield 매핑 기록일 뿐이다.

## 5. R1 — System Model From Scratch

새 System마다 최소 다음을 작성한다.

```text
System ID / Name
Purpose
Owns State
Does Not Own
Authority
Inputs
Outputs
Depends On
Consumed By
Current Scenario Set
Future Scenario Pressure Set
Persistence/Reconnect/Rollback Seam
Failure/Observability Seam
Security/Disclosure Constraints
```

Manager나 Module 이름을 먼저 정하지 않는다.

System은 "어떤 책임을 누가 소유해서 결과가 나오는가"로 설명 가능해야 한다.

## 6. R2 — Scenario Pressure Review

새 System Model을 61 Scenario에 다시 대입한다.

FAIL 조건:

- Scenario 중간 단계에 소유 System이 없음.
- Client가 Server authority/rules를 재구성해야 함.
- Character/Encounter/Inventory/Rules/Persistence/DM을 붙이려면 shared public boundary를 갈아엎어야 함.
- 한 System이 UI, transport, rules, persistence 등 독립 책임을 과도하게 소유함.
- Disclosure/Concurrency/Recovery/Failure path가 없음.
- Roblox Runtime 세부 구현을 Core Engine 책임으로 잘못 끌어옴.

이 단계에서 발견한 문제는 기존 GAP 번호에 맞추기 위해 억지로 분류하지 않는다. 필요하면 새 모델 관점에서 다시 정의한다.

## 7. R3 — 실행 환경 경계

System Model이 Scenario Pressure Review를 통과한 뒤에만 실행 환경을 분류한다.

```text
Repository Core Engine
= Roblox Runtime 없이 correctness 자동 검증 가능

Roblox Runtime Engine / Integration
= Roblox 서비스/geometry/runtime 결과가 correctness에 필요

Presentation / Feel
= 사람이 보고 만져야 판단 가능
```

**Repository Core Engine 전체 완료 전 Studio/MCP 구현 금지.**

Pathfinding/Raycast/Physics도 Repository에서 contract/policy/failure seam을 먼저 완성하고 실제 provider는 이후 Studio에서 구현한다.

## 8. R4 — E0 Checkpoint Freeze

Core Engine 구현 직전에만 System → Module → Stable Function을 구체화한다.

필수 필드:

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

미래 기능 자체를 지금 구현하지 않는다. 하지만 미래 기능 때문에 public contract를 재작성해야 하는 구조도 허용하지 않는다.

## 9. R5 — Dedicated Implementation Branch

E0 Checkpoint Freeze가 끝난 뒤 별도 구현 브랜치를 만든다.

그 Branch의 기본 작업면에는 압축된 구현 Pack만 둔다.

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

구현 AI는 Planning Tree 전체를 기본 검색하지 않는다. 필요한 책임이 없거나 충돌하면 `ESCALATE_TO_PLANNING`한다.

## 10. Studio + UI 순서

```text
E0 Repository Core Engine 전체 구현/검증
→ CORE_ENGINE_COMPLETE
→ E1 Runtime Checkpoint Freeze
→ Studio/MCP Runtime Engine + Integration
→ INTEGRATION_READY
→ U0-A HTML/UI Reference Distillation
→ U0-B Product UI Shell 전체 Scaffold
→ U0-C Human Shell Review
→ UI_SHELL_READY
→ E2 User-facing Checkpoint JIT
```

U0에서는 실제 HTML 예시와 최신 UI Authority를 함께 읽어 UI Surface 종류, 철학, IA, 시각 언어, 상태 표현, 접근성, Roblox mapping을 글로 먼저 정리한다.

`UI_SHELL_READY` 이후 throwaway Test ScreenGui를 만들지 않는다.

## 11. 지금 하지 않는 것

- GAP-002를 기존 Module 구조 안에서 구현.
- 기존 Module/Function Registry를 보완.
- Source 생성.
- Studio/MCP 진입.
- 구현 브랜치 조기 생성.
- 미래 시스템 API 대량 선설계.
- 기존 이름을 기본값으로 재사용.

## 12. 다음 행동

**R0/R1 Whole-product System Model Derivation을 시작한다.**

먼저 22 Capability + 61 Scenario를 책임/상태/권위 관점으로 클러스터링하고, 사용자에게 첫 System Model Draft를 제시한다.

그 Draft는 새 Architecture 제안이므로 사용자 승인 전에는 Module/Stable Function/Source를 만들지 않는다.
