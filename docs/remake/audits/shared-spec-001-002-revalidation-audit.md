# Shared Spec 001·002 재검토 감사

- 상태: COMPLETE
- 문서 종류: Implementation Spec Revalidation Audit
- 감사일: 2026-08-05
- 상위 작업 순서: [`../CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)
- Spec 작업 순서: [`../specs/CURRENT-SPEC-WORK-ORDER.md`](../specs/CURRENT-SPEC-WORK-ORDER.md)
- 대상:
  - [`001. Recipe Step Runtime Foundation`](../specs/shared/001-recipe-step-runtime-foundation.md)
  - [`002. Standard Recipe Step Handler Contracts`](../specs/shared/002-standard-step-handler-contracts.md)

## 1. 감사 목적

Shared Spec 001·002가 작성된 뒤 Runtime Architecture, 12개 Main System Guide, Player·DM User Guide, Diagnostics, Deterministic Simulation과 Cross-System Integration 계약이 완성됐다.

이 감사는 두 초기 Spec을 최신 권위 계약과 다시 비교해 다음 중 하나로 판정한다.

```text
CURRENT
UPDATE_REQUIRED
SUPERSEDED
```

이 Audit은 Recipe Runtime의 새 구현 계약을 직접 만들지 않는다. 수정 방향과 후속 Spec 위치만 판정한다.

## 2. 비교한 최신 권위 계약

### RuleExecution과 실행 수명주기

- [`Rule Runtime Orchestrator와 Pending Execution`](../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md)
- [`Ruleset Policy Registry, Composition과 Frozen Snapshot`](../architecture/ruleset-policy-registry-composition-and-frozen-snapshot-runtime-contract.md)
- [`Rules Guide`](../guides/rules/README.md)

### Ordering·Transaction·Event·Projection

- [`Command Ordering, Logical Time와 Transaction Coordinator`](../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)
- [`Domain Event, Outbox, Subscription과 Projection`](../architecture/domain-event-outbox-subscription-and-projection-runtime-contract.md)
- [`Cross-Domain Outcome Cascade와 Integration Boundary`](../architecture/cross-domain-outcome-cascade-and-integration-boundary-runtime-contract.md)

### Session·Recovery·UI

- [`Networking Command, Event와 Client Synchronization`](../architecture/networking-command-event-and-client-synchronization-contract.md)
- [`Persistence와 Session Recovery`](../architecture/persistence-and-session-recovery-model.md)
- [`UI Projection, ViewModel, Input Context와 Recovery`](../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md)
- [`Session Guide`](../guides/session/README.md)

### Diagnostics·Simulation·Extension

- [`Diagnostics, Observability, Correlated Trace와 Incident`](../architecture/diagnostics-observability-correlated-trace-and-incident-runtime-contract.md)
- [`Deterministic Simulation, Scenario와 Test Harness`](../architecture/deterministic-simulation-scenario-and-test-harness-runtime-contract.md)
- [`Extension, Plugin과 Content Pack Guide`](../guides/extension/README.md)
- [`Presentation Recipe, Playback Priority와 Extension`](../architecture/presentation-recipe-playback-priority-and-extension-runtime-contract.md)

### 사용자 결과

- [`한눈에 보는 세션 흐름`](../user-guides/QUICK-FLOW.md)
- [`Player Guide`](../user-guides/player/README.md)
- [`DM Guide`](../user-guides/dm/README.md)

## 3. Spec 001 판정

```text
대상: Recipe Step Runtime Foundation
판정: UPDATE_REQUIRED
```

### 유지할 핵심 방향

다음 방향은 최신 Architecture와 일치하므로 폐기하지 않는다.

- 신뢰된 Step Definition과 Registry
- 콘텐츠 데이터의 임의 Luau 실행 금지
- Recipe의 정적 검증과 Compiled Form
- Binding의 Type 검증과 직렬화 가능한 대기 상태
- Client 입력을 권위 결과로 신뢰하지 않음
- Step Handler의 직접 영구 Mutation 금지
- Guided·Assisted·Timing Window 대기와 재개
- Presentation 실패와 Gameplay Commit의 분리
- 멱등성, Budget, 취소, 복구와 테스트 요구

따라서 Spec 전체를 `SUPERSEDED`로 판정하지 않는다.

### 갱신이 필요한 이유

#### 3.1 RuleExecution Orchestrator와 책임 중복

Spec 001은 자체 `ExecutionId`, 실행 상태기계, Pending Input, Timing Window, Commit 준비와 복구를 소유한다.

최신 구조에서는 다음을 `Rule Runtime Orchestrator`가 소유한다.

- RuleExecution Identity와 Incarnation
- Parent·Child Execution
- Frozen Ruleset·Policy·Recipe·Scene Snapshot Ref
- Resource Reservation
- Timing Window Stack
- Prompt·Reaction·DM Adjudication
- Pending Effect Set
- 안전 경계, 저장·복구와 Terminal State

갱신 방향:

```text
Recipe Runtime
→ RuleExecution 안의 Compiled Recipe 실행 Adapter

Recipe Step 상태
→ RuleExecution State를 대체하지 않고 하위 실행 Cursor·Frame만 제공
```

#### 3.2 권위 Context가 너무 넓음

현재 `AuthoritativeWorldView`, `AuthoritySnapshotView` 형태는 Handler가 광범위한 권위 Store를 직접 읽는 구조로 해석될 수 있다.

최신 구조는 다음을 요구한다.

- Frozen Execution Context
- Snapshot-bound Typed Query
- Domain별 제한 Provider·Resolver
- Runtime Object Ref + Incarnation + Revision
- Policy·Build·AuthorityEpoch Ref
- Query와 Mutation의 분리

갱신 방향:

- 범용 World View 제거 또는 최소 Interface로 축소
- Spatial·Character·Item·Encounter Query Provider를 명시적으로 분리
- Handler가 다른 Domain Store를 직접 조회하지 않도록 Capability 기반 Read Contract 사용

#### 3.3 CommitGroup 단독 모델이 최신 Transaction 경계를 충분히 표현하지 못함

Spec 001은 PendingEffect 수집 후 `CommitGroup`을 확정하는 흐름을 사용한다.

최신 계약은 다음 단계를 분리한다.

```text
Ordering Key
→ Ordering Reservation
→ Resource Reservation 재검증
→ Transaction Plan·Read Set·Write Set·Precondition
→ Atomic Authority Commit
→ Domain Event Outbox
→ Projection Barrier
→ Permission-aware Projection
```

갱신 방향:

- `CommitGroup`을 Transaction Coordinator의 Domain Contribution으로 정의
- Ordering Reservation과 장기 Resource Reservation을 분리
- Event Draft·Outbox·Projection Barrier를 완료 조건에 추가
- Cross-Domain Immediate Closure와 Deferred Consequence 경계 추가

#### 3.4 Version 고정이 부족함

현재 `recipeId + recipeHash`, `rulesetId`만으로는 진행 중 실행을 완전히 재현하기 어렵다.

추가로 필요한 Ref:

- Compiled Recipe Version Ref
- Frozen Ruleset Snapshot Ref
- Policy Snapshot Ref
- Registry Version Set
- Source Pack Version Set
- Scene Snapshot·Build Ref
- AuthorityEpoch와 Execution Incarnation
- Step Handler Version과 Migration Adapter

#### 3.5 Persistence·Recovery가 최신 Branch 모델보다 좁음

현재 복구 항목은 BindingStore, PendingEffect, PendingInput과 Budget 중심이다.

최신 복구 계약과 맞추려면 다음이 필요하다.

- Snapshot Manifest·Chunk 위치
- Commit Journal과 Commit Marker
- RuleExecution Record와 Reservation Set
- Event Outbox Cursor
- ConnectionEpoch·AuthorityEpoch
- Recovery 후 Projection·Prompt 재발행
- Version 불일치 시 DM Recovery Review
- Rollback Branch에서 이전 입력·Subscriber·Timer 무효화

#### 3.6 Diagnostics가 독립 문자열 로그 중심임

현재 구조화 로그 이벤트는 유용하지만 최신 Diagnostics 계약의 전체 Trace Graph를 충족하지 않는다.

추가로 필요한 것:

- Server Trace Context와 Span
- Command·Execution·Transaction·Event·Projection 인과 연결
- Policy·Authorization·Rule Decision Record
- Stable Error Registry
- 역할별 Redaction과 Support Reference
- Budget Observation과 Health Probe
- Incident·Degraded 상태

#### 3.7 테스트가 Production-parity Harness에 연결되지 않음

기존 단위·컴파일·실행·복구·보안 테스트 항목은 유지 가치가 있다.

다만 다음이 추가돼야 한다.

- Production Registry·Handler·Transaction·Projection 경로 재사용
- Deterministic RNG·Clock·ID·Task Scheduler
- Network Duplicate·Drop·Reorder
- Storage Fault와 Restart Point
- Bounded Interleaving
- Player·DM·Observer Negative Disclosure
- State·Event·Projection·Trace Artifact Assertion

#### 3.8 수치 기본값의 근거 부족

다음 표현은 측정 전 확정값으로 사용하면 안 된다.

- 일반적인 `30 Step 이하 Recipe`
- 실행 Budget의 구체 상한을 암시하는 필드
- 구현 프로파일에 둔 초기 기본값

필드는 유지할 수 있지만 실제 값은 기준 Scenario와 Profiling 절차로 확정해야 한다.

#### 3.9 사용자 Acceptance Flow와 현재 코드 조사가 없음

Spec 001은 현재 Template 이전 문서라 다음이 빠져 있다.

- Player·DM에게 보이는 Waiting·Denied·Retrying·Resync 상태
- Q·E Prompt 취소·확정 의미
- 재접속 후 Prompt·Execution 복구 경험
- 실제 저장소 Module·Schema·Test 조사
- User Guide·Main Guide 변경 영향 지도

## 4. Spec 002 판정

```text
대상: Standard Recipe Step Handler Contracts
판정: UPDATE_REQUIRED
```

### 유지할 핵심 방향

- Handler Definition과 Handler Registry 분리
- 콘텐츠가 ModuleScript 경로나 함수를 직접 지정하지 않음
- 제한된 Service Facade 사용
- Config·Input·Output·Branch·PendingEffect 검증
- Coroutine·임의 Yield 금지
- Guided·Assisted의 Serializable Suspension
- 직접 상태 Mutation·Remote·DataStore 접근 금지
- Roll Service를 통한 권위 굴림
- Handler 예외 격리와 Presentation Fallback

### 갱신이 필요한 이유

#### 4.1 Handler Context가 최신 Frozen Execution Context를 반영하지 못함

추가해야 할 Context:

- authorityEpoch
- executionIncarnation
- Frozen Ruleset·Policy Snapshot Ref
- Compiled Recipe·Handler Registry Version Set
- Scene Snapshot·Build Ref
- Trace Context
- Explicit Query Provider Set
- Domain Disclosure Classification

#### 4.2 HandlerServices가 기능적으로 너무 넓음

현재 하나의 Facade가 Roll, Spatial, Predicate, Effect, Input, Timing, Presentation, Reference와 Diagnostics를 모두 제공한다.

갱신 방향:

- Step Type Definition이 필요한 Capability만 선언
- Invoker가 최소 Provider Set만 주입
- Query Provider와 Draft Factory를 구분
- Handler가 제공받지 않은 Domain Capability에 접근할 수 없게 함
- Extension Pack별 Trusted Handler Capability Manifest와 Budget 적용

#### 4.3 Transaction·Outbox·Projection 계약이 없음

Handler는 Draft만 반환한다는 원칙은 유지한다.

다만 Draft가 다음 Adapter를 거쳐야 한다.

```text
Handler Result
→ Invoker Validation
→ RuleExecution Contribution
→ Domain Transaction Proposal
→ Event Draft
→ Projection Adapter
```

Handler가 `PresentationRequestDraft`를 권위 Branch 결과와 섞지 않도록 PresentationIntent 경계를 최신 계약에 맞춰야 한다.

#### 4.4 Version·Migration·Activation이 부족함

현재 `handlerVersion: integer`만으로는 충분하지 않다.

필요 항목:

- Handler Definition ID와 Semantic Version
- Supported Step Schema Version Range
- Registry Version Set
- Migration·Deprecation Adapter
- Candidate Registration 검증
- Core Handler와 Optional Pack 실패 격리
- Last Known Good Registry Set
- 진행 중 Execution의 Handler Version 고정

#### 4.5 Diagnostics·Health가 최신 표준보다 좁음

- Handler Span과 Parent Execution Span 연결
- Stable Error Definition Registry
- Exception Fingerprint와 Incident Aggregation
- Handler·Pack별 Budget Observation
- Repeated Failure Circuit Breaker
- 역할별 Redaction
- Support Reference

#### 4.6 근거 없는 성능 목표가 있음

`일반 Executable handler 호출 오버헤드 0.2ms 이하`는 현재 측정 근거가 없다.

판정:

```text
수치 제거
→ 기준 Scenario·Profiling 항목만 유지
→ 측정 결과를 Configuration 또는 후속 ADR로 확정
```

#### 4.7 Production-parity·보안 테스트 보강 필요

- 실제 Handler Registry와 Production Invoker 사용
- Test-only Mutation Service 금지
- Fault Injection과 Cancellation Interleaving
- Extension Pack 로드 실패·부분 Registry 실패
- 비밀 Binding·Candidate·Diagnostic 누출 검사
- Rollback 이전 Handler Resume·Prompt 거부

#### 4.8 실제 코드 조사와 User Flow 추적성 없음

Spec 002도 실제 저장소 Module 구조를 조사하기 전에 경로를 제안했다.

최신 Template에 맞춰 다음을 추가해야 한다.

- 실제 현재 Module·Registry·Remote·Test 조사
- 존재하지 않는 경로의 `신규 제안` 표시
- Guided·Assisted Prompt의 Player·DM Acceptance Flow
- Q·E·Reconnect·Resync 상태
- 변경 영향 지도

## 5. 공통 판정표

| 검사 영역 | Spec 001 | Spec 002 | 판정 |
|---|---|---|---|
| 핵심 Recipe·Handler 방향 | 유지 가능 | 유지 가능 | 폐기 불필요 |
| RuleExecution Orchestrator 정합성 | 책임 중복 | Context 부족 | 갱신 필요 |
| Frozen Version Set | 불충분 | 불충분 | 갱신 필요 |
| Ordering·Transaction | 구형 CommitGroup 중심 | Adapter 없음 | 갱신 필요 |
| Outbox·Projection Barrier | 누락 | 누락 | 갱신 필요 |
| Recovery·Epoch·Branch | 부분 반영 | 부분 반영 | 갱신 필요 |
| Diagnostics·Health | 구조화 로그 수준 | Handler Trace 수준 | 갱신 필요 |
| Deterministic Harness | 독립 테스트 목록 | 독립 테스트 목록 | 갱신 필요 |
| Extension·Migration | 부분 반영 | 불충분 | 갱신 필요 |
| User Acceptance Flow | 누락 | 누락 | 갱신 필요 |
| 실제 Code Survey | 누락 | 누락 | 갱신 필요 |
| 측정형 수치 정책 | 일부 충돌 | `0.2ms` 충돌 | 갱신 필요 |

## 6. 최종 판정

```text
Shared Spec 001
→ UPDATE_REQUIRED

Shared Spec 002
→ UPDATE_REQUIRED

SUPERSEDED
→ 아님

Production Code 근거 사용
→ 금지
```

현재 파일 상단의 `준비 완료`, `READY` 표시는 이 최신 감사와 Shared Spec Index에 의해 효력을 잃는다.

GitHub contents API는 부분 Metadata Patch를 제공하지 않으므로, 두 대형 Spec 본문은 Rules Slice의 실제 갱신 작업에서 새 Template으로 전체 재작성한다. 그 전까지는 [`Shared Spec Index`](../specs/shared/README.md)와 이 Audit의 `UPDATE_REQUIRED` 판정을 우선한다.

## 7. 후속 처리 순서

Shared 001·002는 First Session Walking Skeleton의 선행 조건이 아니다.

```text
First Session Walking Skeleton
→ Core Authority·Protocol·Session·Scene·Movement·Persistence 기반 검증
→ Character Action·Rules Slice 시작
→ RuleExecution Adapter Spec
→ Shared 001 전체 갱신
→ Shared 002 전체 갱신
→ Roll·PendingEffect·Guided·Presentation Step Spec
→ Rules Slice 통합 감사
```

### Shared 001 갱신 목표

```text
Recipe Definition·Compiled Recipe·Step Registry·Binding Frame
+ RuleExecution Adapter
+ Transaction Contribution
+ Recovery·Diagnostics·Simulation
```

### Shared 002 갱신 목표

```text
Trusted Handler Definition·Capability Manifest·Provider Set
+ Invoker Validation·Fault Isolation
+ Version·Migration·Last Known Good
+ RuleExecution·Transaction·Presentation Adapter
```

기존 파일명은 우선 유지한다. 실제 책임이 하나의 Spec으로 검증 불가능할 정도로 분리될 때만 새 Spec을 만들고 기존 문서를 `대체됨`으로 전환한다.

## 8. 완료 조건

- [x] 최신 RuleExecution 계약과 비교했다.
- [x] Ordering·Transaction·Outbox·Projection 계약과 비교했다.
- [x] Recovery·Epoch·Rollback 계약과 비교했다.
- [x] Diagnostics·Simulation·Extension 계약과 비교했다.
- [x] User Guide Acceptance Flow 누락을 확인했다.
- [x] 근거 없는 수치 기본값을 확인했다.
- [x] 두 Spec의 `UPDATE_REQUIRED` 판정을 기록했다.
- [x] First Slice와 Rules Slice의 순서를 분리했다.
- [x] Production Code 근거 사용을 차단했다.

## 9. 변경 영향

- [`Spec Work Order`](../specs/CURRENT-SPEC-WORK-ORDER.md): Shared 001·002를 Rules Slice로 배치
- [`Spec Hub`](../specs/README.md): 최신 판정과 현재 첫 Slice 표시 필요
- [`Shared Spec Index`](../specs/shared/README.md): `UPDATE_REQUIRED` 확정과 Audit 링크 필요
- [`현재 작업 순서`](../CURRENT-WORK-ORDER.md): 첫 Spec 작업으로 전환 필요

이 감사로 Product·Architecture·Main System Guide의 의미 변경은 발생하지 않았다.