# RVTT Architecture Coverage Policy

- 상태: `ACTIVE · PRE_IMPLEMENTATION_COVERAGE_AUTHORITY`
- 최종 갱신일: 2026-08-13
- Machine-readable Registry: [`manifests/architecture-coverage.json`](manifests/architecture-coverage.json)
- Expanded Scenario Registry: [`manifests/architecture-scenarios.json`](manifests/architecture-scenarios.json)
- Validator: [`tooling/validate_architecture_coverage.py`](tooling/validate_architecture_coverage.py)
- Initial Audit: [`audits/ARCHITECTURE-COVERAGE-AUDIT-001.md`](audits/ARCHITECTURE-COVERAGE-AUDIT-001.md)
- Code Contract: [`MODULE-CONTRACTS.md`](MODULE-CONTRACTS.md) + [`SYSTEM-FUNCTION-CONTRACTS.md`](SYSTEM-FUNCTION-CONTRACTS.md)
- Execution Layer: [`GREENFIELD-EXECUTION-LAYERS.md`](GREENFIELD-EXECUTION-LAYERS.md)

이 문서는 **중요한 Product/ADR/Architecture 개념이 구현 계획에서 빠졌는지 구현 전에 추적하는 방법**을 소유한다.

기존 Contract 검증은 다음 질문에는 강하다.

```text
System이 선언됐는가?
Module 책임이 맞는가?
Stable Function 의미가 맞는가?
```

하지만 다음 질문을 자동으로 보장하지 못한다.

```text
제품이 요구하는 중요한 Capability가 System 목록에 아예 빠진 것은 아닌가?
상위 Architecture에 있는 공통 경계가 현재 E0/E1 계획에서 누락된 것은 아닌가?
사용자 Scenario를 끝까지 따라가면 중간에 소유자가 없는 단계가 생기지 않는가?
```

Architecture Coverage는 이 공백을 막는 별도 Gate다.

## 1. 전체 추적 방향

```text
Product Requirement / Accepted ADR / Current Architecture
↕
Product Capability
↕
Representative Scenario
↕
System Contract
↕
Module Contract
↕
Stable Function Contract
↕
Source
↕
Test / Runtime Evidence / Human Acceptance
```

추적은 양방향이어야 한다.

- 위에서 아래: 요구사항이 실제 System/Module/Test까지 도달하는가.
- 아래에서 위: Module/Function이 어떤 Product Capability와 Scenario를 위해 존재하는가.

Source가 있다는 이유만으로 Product Coverage가 있다고 간주하지 않는다.

## 2. Authority Corpus Snapshot

Coverage Scan은 현재 효력이 있는 다음 Root를 기본 Authority Corpus로 사용한다.

```text
docs/remake/product
docs/remake/decisions
docs/remake/architecture
docs/remake/systems
docs/remake/ui
docs/remake/specs
```

추가로 현재 Work Order와 역할·접근 Authoring Rule을 직접 추적한다.

`architecture-coverage.json`은 각 Root의 Git Tree SHA를 Snapshot으로 기록한다.

규칙:

- 위 Authority Root의 어떤 문서라도 추가·삭제·수정되면 Tree SHA가 바뀐다.
- Snapshot이 바뀌었는데 Coverage Registry를 재검토하지 않으면 Validator가 실패한다.
- 단순히 새 SHA만 복사하지 않는다. 변경된 Authority가 기존 Capability/Scenario/Gaps에 어떤 영향을 주는지 먼저 검토한다.
- Historical Archive와 User Guide는 직접 Product Authority Corpus가 아니다. 필요하면 Capability의 Evidence로 참고할 수 있으나 Coverage Source of Truth는 위 Root다.

따라서 앞으로 새 ADR이나 Architecture 문서가 생겼는데 구현 계획이 그대로인 상태를 조용히 통과시키지 않는다.

## 3. Product Capability Catalog

Capability는 화면 버튼이나 Module 이름이 아니다.

예:

```text
CAP_SELECTION_TARGETING
CAP_NAVIGATION_MOVEMENT
CAP_CHARACTER_ACTION_AVAILABILITY
CAP_TRANSACTION_EVENT_PROJECTION_BARRIER
```

각 Capability는 최소 다음을 가진다.

```text
id
title
plannedPhase
coverageState
authorityRefs
systemRefs
moduleRefs
knownGapRefs
flow
crossCutting
```

`coverageState`:

```text
MAPPED
PARTIAL
UNMAPPED
DEFERRED
```

### MAPPED

현재 구현 범위에서 필요한 System/Module 경계가 존재하고 상위 흐름과 실질적으로 대응한다.

### PARTIAL

일부 경계가 존재하지만 상위 Architecture가 요구하는 중요한 단계 또는 소유자가 빠져 있다.

### UNMAPPED

Product/Architecture Capability가 존재하지만 현재 Greenfield System/Module Contract에 대응 경계가 없다.

### DEFERRED

미래 단계의 Capability다. 지금 Module/API를 상상해서 만들지 않는다.

단, DEFERRED는 다음을 반드시 가진다.

- 어느 Phase에서 다룰지.
- 어떤 현재 공통 Boundary를 재사용해야 하는지.
- 현재 구현이 그 미래 Capability를 불가능하게 만드는 구조를 만들지 않는지.

`DEFERRED`는 `잊어도 됨`이 아니다.

## 4. Representative Scenario Trace

Capability 목록만 보면 System 사이 연결이 빠질 수 있다.

따라서 대표 Scenario를 별도 등록한다.

예:

```text
SCN_SELECT_VISIBLE_ACTOR

Primary Input
→ Spatial Query
→ Visibility Filter
→ Candidate Set
→ Selection State
→ Presenter
```

```text
SCN_CHARACTER_CONSOLE_DASH

Effective Capability
→ Action Opportunity / Context
→ Available Action Projection
→ Character Console
→ Command
→ Server Revalidation
→ RuleExecution
→ Transaction
→ Updated Projection
```

Scenario에는 최소 다음을 기록한다.

```text
id
status
phase
capabilityRefs
steps
expectedOutcome
negativeCases
```

`BLOCKED` Scenario는 구현하지 않는다. 먼저 끊어진 Capability 경계를 해결한다.

### 4.1 Scenario Catalog 확장 규칙

초기 Coverage Audit에서 만든 대표 Scenario는 `architecture-coverage.json`에 유지한다.

이미 Product/ADR/Architecture/Slice Spec에 설계되어 있지만 초기 14개에 포함되지 않은 사용자·DM·운영 흐름은 `architecture-scenarios.json`에 추가한다.

두 Registry의 Scenario는 Validator에서 하나의 Catalog로 취급한다.

```text
architecture-coverage.json.scenarios
+
architecture-scenarios.json.scenarios
=
Current Representative Scenario Catalog
```

확장 Scenario 원칙:

- 기존 설계를 사용자 또는 운영 흐름으로 추적하는 것이 목적이다.
- Scenario 추가 자체는 새 System/Module/Function Architecture 승인으로 해석하지 않는다.
- 미래 시스템은 `DEFERRED` 또는 `DEFERRED_BLOCKED_BY_GAP`로 기록할 수 있다.
- 각 Scenario는 현재 Capability Catalog에 연결한다.
- 정상 흐름만 쓰지 않고 최소 하나 이상의 실패·동시성·Disclosure·Recovery 사례를 둔다.
- 버튼 하나, 함수 하나보다 End-to-End 사용자 결과를 우선한다.
- Scenario를 작성하면서 새로운 공통 경계 누락이 발견되면 기존 절차대로 Gap을 등록하고 사용자 결정을 받는다.

현재 확장 대상에는 Character Creation·Sheet·Level Up·Inventory·Rest·Spell Preparation·Core Rules·Encounter·Journal·Scene Authoring·Live DM·Content Pack·Official Content·NPC/Monster·Release Recovery 흐름이 포함된다.

## 5. Cross-cutting Coverage Matrix

모든 Capability는 다음 질문을 명시적으로 답한다.

```text
AUTHORITY
PERMISSION
STATE_OWNERSHIP
COMMAND
PROJECTION_DISCLOSURE
PERSISTENCE
RECONNECT
ROLLBACK
MULTIPLAYER_CONCURRENCY
FAILURE
OBSERVABILITY
SECURITY
AUTOMATED_TEST
HUMAN_TEST
```

값은 `COVERED`, `PARTIAL`, `UNRESOLVED`, `DEFERRED`, `N/A`, `PLANNED`, `REQUIRED` 계열로 기록하고 이유를 함께 쓴다.

빈칸은 허용하지 않는다.

이 Matrix의 목적은 모든 기능에 Persistence나 Human Test를 강제로 추가하는 것이 아니다.

예:

```text
Camera.HUMAN_TEST
= REQUIRED

Camera.PERSISTENCE
= N/A 또는 local preference 범위

Transaction.HUMAN_TEST
= N/A

Transaction.MULTIPLAYER_CONCURRENCY
= 필수
```

중요한 것은 `생각하지 않았다`와 `검토 후 N/A/DEFERRED`를 구분하는 것이다.

## 6. Known Gap과 Phase Gate

Coverage Scan에서 누락이 발견되면 `knownGaps`에 등록한다.

Gap은 최소 다음을 가진다.

```text
id
severity
status
blockingScopes
title
evidenceRefs
requiredDecision
```

Severity:

```text
FOUNDATION_BLOCKER
INTEGRATION_BLOCKER
EXPLORATION_BLOCKER
TRACKED_DEFERRED
```

중요 원칙:

**Coverage Finding은 Architecture 변경 승인 자체가 아니다.**

```text
Coverage Scan
→ Gap 발견
→ 현재 구현 Gate BLOCKED
→ 문제 / 대안 / 영향 사용자에게 보고
→ 사용자 결정
→ 상위 Authority부터 Contract 정합화
→ Gap RESOLVED
→ Gate 재검증
```

따라서 Codex가 Gap을 발견했다는 이유로 System/Module/Authority를 독단적으로 추가·분리·통합하지 않는다.

## 7. Phase별 Gate

모든 Gap이 전체 개발을 영원히 막지는 않는다.

Registry의 `phaseGates`가 각 단계가 어떤 Gap에 의해 차단되는지 기록한다.

예:

```text
E0
→ E0에 구조적 영향을 주는 Foundation Gap만 해소 필요

S1
→ Selection에 필요한 Spatial Query / Disclosure / Runtime Identity Gap 필요

M1
→ Navigation / Pathfinding 경계 Gap 필요
```

미래 P8 Capability가 아직 `DEFERRED`라는 이유로 S1을 막지 않는다.

반대로 미래 Character Console에서만 보일 것 같던 `Capability Availability`가 현재 X1 Context Action과 공통 경계라면 현재 Gap으로 승격할 수 있다.

## 8. CI의 역할

`validate_architecture_coverage.py`는 의미를 대신 판단하지 않는다.

기계적으로 다음을 강제한다.

1. Coverage Registry와 Expanded Scenario Registry Schema·필수 필드.
2. Authority Corpus Tree/Blob Snapshot이 현재 Checkout과 일치.
3. Capability의 Authority Reference가 실제 파일을 가리킴.
4. System/Module Reference가 현재 Registry에 존재.
5. 현재 Greenfield Module이 Product Capability 또는 명시적 Infrastructure 이유에 연결됨.
6. Base+Expanded Scenario ID가 중복되지 않고 존재하는 Capability만 참조.
7. Scenario가 Steps·Expected Outcome·Negative Case를 가짐.
8. 모든 Capability가 Cross-cutting Dimension을 빠짐없이 가짐.
9. Gap과 Phase Gate Reference가 유효함.
10. OPEN Blocker가 있는데 `implementationGate=READY`로 위장하는 상태 금지.
11. BLOCKED Gate가 실제 OPEN Blocker를 가지고 있는지 확인.

CI가 할 수 없는 것:

- 문서의 모든 의미 충돌 자동 판정.
- 새 Architecture가 정말 필요한지 제품 판단.
- 사용자의 최종 UX 수용 대체.

Semantic Coverage Review는 Codex/ChatGPT가 Authority Corpus를 읽고 수행하고, Validator는 그 Review가 Registry에 반영됐는지 강제한다.

## 9. Authority 문서가 바뀔 때

Product/ADR/Architecture/System/UI/Spec이 변경되면:

```text
Authority Tree SHA 변경
→ Coverage CI FAIL
→ 변경 문서 읽기
→ 영향 Capability 검색
→ Scenario 영향 검색
→ Cross-cutting Matrix 영향 확인
→ Gap 추가/수정/해소
→ 필요한 경우 System/Module/Function 변경을 사용자에게 제안
→ Coverage Snapshot 갱신
→ Validator PASS
```

Tree SHA만 갱신하고 영향 검토를 생략하는 것은 금지한다.

## 10. 구현 직전 Coverage Handoff

각 Phase를 시작하기 직전에 Codex는 다음을 확인한다.

```text
COVERAGE PHASE
- E0 / E1 / S1 / C1 / M1 / X1 / I1 ...

REQUIRED CAPABILITIES
- ...

REPRESENTATIVE SCENARIOS
- Base + Expanded Catalog에서 현재 Phase 관련 Scenario

BLOCKING GAPS
- none 또는 Gap IDs

AUTHORITY SNAPSHOT
- PASS

COVERAGE VALIDATOR
- PASS

IMPLEMENTATION RESULT
- READY 또는 BLOCKED
```

`BLOCKING GAPS`가 있으면 Source를 시작하지 않는다.

## 11. 사용자 확정과 Authority Reconciliation

사용자가 구현 결과를 최종 수용하면 기존 Authority Reconciliation에 Coverage도 포함한다.

```text
사용자 수용
→ Authority Impact Scan
→ Product/ADR/Architecture/Spec
→ Architecture Coverage Capability/Scenario/Gap
→ Execution/System/Module/Function Contract
→ Source/Test
→ conflict re-scan
→ Promotion Commit
```

새 결정이 Capability 의미를 바꾸면 Coverage Registry를 먼저 정합화한다.

새 Capability가 생겼는데 Scenario/System/Test 연결 없이 Promotion Commit을 만들지 않는다.

## 12. 현재 상태

초기 Coverage Audit 결과 현재 E0는 `BLOCKED_BY_FOUNDATION_COVERAGE_GAPS`다.

이는 현재 구현이 실패했다는 뜻이 아니다. 아직 Source를 시작하기 전에 상위 Architecture와 Greenfield 계획 사이에서 발견한 구조적 누락을 먼저 결정해야 한다는 뜻이다.

정확한 Gap과 순서는 `architecture-coverage.json`과 Initial Audit가 소유한다.

설계된 미래 사용자·DM·운영 흐름의 대표 Scenario는 `architecture-scenarios.json`이 초기 Catalog를 확장한다.
