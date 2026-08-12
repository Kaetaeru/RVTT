# RVTT Implementation Model

- 상태: `ACTIVE · IMPLEMENTATION_MODEL_RESET`
- 최종 갱신일: 2026-08-13
- 목적: 기존 Greenfield System/Module/Function 설계를 구현 제약에서 제거하고, 현재 Product/Accepted ADR/Architecture/Capability/Scenario에서 구현 모델을 처음부터 다시 도출한다.

## 1. 핵심 결정

현재까지의 `25 modules / 10 systems / 64 stable functions` Greenfield 모델은 **폐기된 구현 모델**이다.

다음 항목은 더 이상 새 구현의 기본값이나 제약이 아니다.

- 기존 Greenfield System 이름과 경계
- 기존 Module split
- 기존 Stable Function 목록
- 기존 G0~G5 stage 구조
- 기존 E0/E1 module classification
- 기존 `WorldState.transact` 중심 mutation 모델
- 기존 Selection/Movement/Context controller wiring

Git history와 기존 문서는 설계 과정의 참고 증거로만 남는다. 좋은 아이디어가 있더라도 새 모델에 자동 승계하지 않는다.

## 2. 새 모델의 입력 권위

새 구현 모델은 다음에서만 다시 도출한다.

```text
사용자의 최신 결정
→ Product
→ Accepted ADR
→ Current Architecture
→ Current UI/UX Authority
→ Capability Catalog
→ Representative Scenario Catalog
→ Cross-cutting Coverage
```

`architecture-coverage.json` 안의 기존 `systemRefs`와 `moduleRefs`는 과거 Greenfield 모델에 대한 기록이므로 **현재 구현 매핑 권위가 아니다**.

현재 22개 Capability와 61개 Scenario는 요구사항/압력 데이터베이스로 유지한다.

## 3. 새 모델 설계 순서

### R0 — Requirement Distillation

전체 Authority/Capability/Scenario에서 구현에 필요한 도메인 책임, 상태, 권위, 데이터 흐름, 실패 경계를 추출한다.

출력:

- Product capability inventory
- scenario pressure inventory
- state/authority inventory
- external/runtime dependency inventory
- cross-cutting constraints

### R1 — System Model From Scratch

기존 System 이름을 재사용한다고 가정하지 않고 책임 단위로 System을 새로 묶는다.

각 System은 최소 다음을 가진다.

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
Current Scenarios
Future Scenario Pressure
Persistence/Reconnect/Rollback Seam
Failure/Observability Seam
Security/Disclosure Constraints
```

Manager 수나 이름을 먼저 정하지 않는다.

### R2 — End-to-End Scenario Pressure Review

61개 Scenario를 새 System Model에 다시 통과시킨다.

검사:

- 중간 책임 소유자가 비어 있지 않은가
- 한 System이 서로 무관한 책임을 과도하게 소유하지 않는가
- 미래 Character/Encounter/Inventory/Rules/Persistence/DM 기능이 public boundary 재작성을 요구하지 않는가
- Client가 Server Authority를 재구성해야 하는 틈이 없는가
- Projection/Disclosure/Concurrency/Recovery가 빠지지 않았는가

새 구조적 문제가 발견되면 Source로 우회하지 않고 모델을 수정한다.

### R3 — Core Engine Boundary Freeze

System Model이 Scenario Pressure Review를 통과한 뒤에만 Repository Core Engine과 Roblox Runtime 경계를 나눈다.

판정:

```text
Roblox Runtime 없이 correctness를 검증할 수 있음
→ Repository Core Engine

Roblox Runtime 결과가 correctness의 일부
→ Roblox Runtime Engine / Adapter

사람이 보고 만져야 correctness를 판단
→ Presentation / Feel
```

**Studio/MCP 작업은 Repository Core Engine 전체 완료 후에만 시작한다.**

### R4 — E0 Checkpoint Freeze

Core Engine의 실제 구현 직전에만 System → Module → Stable Function을 구체화한다.

각 Checkpoint는 현재 Scope와 동시에 미래 Compatibility Constraint를 가진다.

필수:

```text
Current Deliverable
System/Module Scope
Stable Function Scope
Authority/State Ownership
Input/Output Contract
Current Scenario Working Set
Future Consumers
Future Scenario Pressure Set
Extension Seams
Forbidden Shortcuts
Explicit Deferred Non-goals
Repository Tests
Negative/Fail-closed Tests
Future Compatibility Contract Tests
Completion Condition
```

미래 기능은 지금 구현하지 않지만, 미래 기능을 붙이기 위해 현재 public contract를 갈아엎어야 하는 Checkpoint는 Freeze하지 않는다.

### R5 — Dedicated Implementation Branch

E0 System/Checkpoint가 Freeze된 뒤 별도 구현 브랜치를 만든다.

그 브랜치에서 구현 AI의 기본 읽기 표면은 압축된 구현 Pack만 사용한다.

예상 최소 표면:

```text
IMPLEMENTATION.md
SYSTEMS.md
SCENARIOS.md or machine-readable scenario working set
CONTRACTS.json
BUILD-ORDER.md
TEST-GATES.md
BASELINE.json
src/
tests/
```

Planning 문서 전체를 기본 검색 경로로 사용하지 않는다.

`BASELINE.json`에는 이 Planning Branch의 승인된 commit SHA를 기록한다.

## 4. 실행 순서

```text
R0 Requirement Distillation
→ R1 System Model From Scratch
→ R2 61 Scenario Pressure Review
→ R3 Core Engine Boundary Freeze
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

## 5. UI Shell 원칙

U0는 `INTEGRATION_READY` 뒤 E2 전에 한 번 수행한다.

- 실제 HTML UI 예시를 당시 Branch에서 다시 발견하고 읽는다.
- 최신 UI Authority와 함께 UI 종류, 정보구조, 디자인 철학, 시각 언어, 상태 표현, 접근성, Roblox GUI mapping을 글로 먼저 Distill한다.
- 실제 제품 Surface 전체의 Shell을 만든다.
- 이후 throwaway Test ScreenGui를 만들지 않는다.
- UI 테스트는 실제 Product Shell의 dev-mode Debug/Fixture Control을 사용한다.
- Gameplay Debug는 실제 Command/Server Authority/Transaction 경계를 우회하지 않는다.

## 6. 금지

- 폐기된 Greenfield Module/Function 목록을 새 모델의 출발점으로 복원.
- Gap 하나씩 기존 Module에 덧붙이는 방식으로 새 모델을 설계.
- 기존 이름이 익숙하다는 이유로 책임을 자동 승계.
- 현재 기능만 빠르게 통과시키는 feature-specific shared boundary.
- 미래 기능을 핑계로 먼 미래 내부 API를 대량 선설계.
- Core Engine 완료 전 Studio/MCP 구현.
- UI Shell 이후 throwaway test UI.
- 사용자 승인 없이 Product/ADR/Authority/state ownership/input grammar/development sequence 변경.

## 7. 현재 상태

```text
IMPLEMENTATION MODEL = RESET IN PROGRESS
SOURCE IMPLEMENTATION = FORBIDDEN
STUDIO IMPLEMENTATION = FORBIDDEN
DEDICATED IMPLEMENTATION BRANCH = NOT YET CREATED
NEXT = R0/R1 WHOLE-PRODUCT SYSTEM MODEL DERIVATION
```
