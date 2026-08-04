# Testing과 Simulation 시스템

생산 Runtime 경로를 그대로 실행하는 Deterministic Scenario, Fault Injection, Concurrency, Recovery와 Disclosure Test Harness를 다룬다.

## 관련 Main System Guide

- [`UI, Camera와 Presentation Guide`](../../guides/ui/README.md)
  - Projection Batch, Prompt·Input·Camera·Presentation Failure와 Epoch-safe Recovery Scenario
- [`Journal과 Ping Guide`](../../guides/journal/README.md)
  - Document·Section Identity, Permission Search·Backlink, Anchor Lifecycle와 Safe Navigation Scenario
  - Ping Audience·Rate·Signal Loss·VFX Failure와 비권위 수명주기 검증
- [`Scene Editor와 Authoring Guide`](../../guides/scene-editor/README.md)
  - Stable Source ID·Tool Lifecycle·Migration·Undo·Build Determinism과 Publish Gate Scenario
  - Partial·Full Compile 동일성, Live Patch Rebase·Failure Recovery와 Secret Authoring Disclosure 검증

## 권위 문서

- [`Deterministic Simulation, Scenario와 Test Harness Runtime 계약`](../../architecture/deterministic-simulation-scenario-and-test-harness-runtime-contract.md)
  - Versioned Scenario와 Fixture Manifest
  - Frozen Ruleset·Policy·Build Reference
  - Deterministic RNG·Clock·ID·Execution Scheduler Adapter
  - Virtual Network·Client·Storage와 등록된 Fault Point
  - Bounded Interleaving Exploration과 Failure Shrinker
  - State·Event·Projection·UI·Trace·Budget Assertion
  - Audience Matrix와 Negative Disclosure Canary 검사
  - Restart·Reconnect·Rollback의 Production-parity 검증
- [`ADR-0085`](../../decisions/ADR-0085-production-parity-deterministic-scenarios-and-controlled-nondeterminism.md)
  - 별도 규칙 엔진 없이 생산 Runtime을 실행하고 외부 비결정 요소만 통제

## 관련 문서

- [`Diagnostics Runtime`](../../architecture/diagnostics-observability-correlated-trace-and-incident-runtime-contract.md)
  - Scenario Trace, Decision Record, Incident와 최소 재현 Artifact
- [`Transaction Coordinator`](../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)
  - Ordering Key, 원자 Commit, Race와 Reservation 누수 검사
- [`Persistence와 Recovery`](../../architecture/persistence-and-session-recovery-model.md)
  - Snapshot·Journal·Restart·Rollback Driver
- [`Networking 계약`](../../architecture/networking-command-event-and-client-synchronization-contract.md)
  - 중복·유실·순서 역전·Reconnect·Projection Gap
- [`Visibility와 Disclosure`](../../architecture/visibility-knowledge-detection-and-hover-information-runtime-contract.md)
  - Audience별 Projection과 Secret Canary 검사
- [`UI Runtime`](../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md)
  - Replica·ViewModel·Prompt·Input Context 복구 검사
- [`Journal Runtime`](../../architecture/journal-document-section-anchor-permission-search-and-projection-runtime-contract.md)
  - Stable Identity, Permission Search, Anchor Resolution, Conflict와 Rollback 검사
- [`Scene Compiler`](../../architecture/scene-compiler-and-compiled-runtime-scene-contract.md)
  - Source·Provider·Layer·Build 결정성, Diagnostic·Publish와 Live Patch 검사
- [`Scene Editor Tool Module`](../../architecture/scene-editor-tool-module-architecture.md)
  - Registry·Capability·Command·Object Schema·Migration과 Error Isolation 검사
- [`Dice와 Resolution`](../../architecture/dice-roll-check-save-attack-and-resolution-runtime-contract.md)
  - Named RNG Stream과 RollRecord 기반 재현

## 표준 Scenario 흐름

```text
Scenario·Fixture Compile
→ Frozen Version·Hash 검증
→ Headless Production Runtime Boot
→ Deterministic Adapter 연결
→ Action Schedule·Fault Plan 실행
→ Quiescence 또는 Stop Condition
→ State·Event·Projection·UI·Trace Artifact 수집
→ Semantic·Recovery·Disclosure·Budget Assertion
→ 실패 시 Schedule·Input 축소와 재현 Artifact 보존
```

## Test 계층

```text
Contract Test
Deterministic Scenario Test
Concurrency Exploration Test
Recovery Test
Disclosure Test
Property·Mutation Test
Soak·Load Test
Roblox Integration Test
```

Headless Harness와 실제 Roblox Integration Suite를 서로 대체하지 않는다.

## 고정 경계

- Test Harness는 별도 Gameplay 규칙 엔진을 만들지 않는다.
- 생산 Command, RuleExecution, Transaction, Event, Projection과 UI Selector를 그대로 사용한다.
- Fixture가 Domain Store와 Scene Source Store를 직접 수정하지 않는다.
- Test-only Authorization 우회와 Test-only Mutation Command를 만들지 않는다.
- RNG, Clock, ID, Network, Storage와 Presentation Adapter만 결정적으로 교체한다.
- 현실 Sleep과 Thread 운에 동시성 결과를 의존하지 않는다.
- Fault는 등록된 Boundary에서만 주입한다.
- Campaign Game Time은 Store 직접 수정이 아니라 실제 TimeAdvance·Encounter Boundary를 사용한다.
- Scene Build Test는 실제 Source Compiler·Provider·Manifest·Publish 경로를 사용한다.
- Partial Compile Fixture가 Full Compile과 다른 의미를 허용하지 않는다.
- Tool Preview·Ghost를 Source Commit으로 간주하지 않고 실제 Authoring Command를 실행한다.
- Production Root RNG Seed를 Artifact로 Export하지 않는다.
- 전체 Snapshot 문자열보다 Domain Invariant와 Semantic Assertion을 우선한다.
- Player Projection Test는 UI 숨김뿐 아니라 직렬화 Byte·ID·Index·Diagnostics까지 검사한다.
- Journal Disclosure Test는 제목·Section·Count·Backlink·Anchor·Search Token과 Navigation Target까지 검사한다.
- Scene Authoring Disclosure Test는 Secret Source Object·Compiler Lineage·Diagnostic·Chunk Segment까지 검사한다.
- Ping Test는 Signal 손실을 Authority Gap으로 오인하지 않고 만료·비복구를 검증한다.
- Restart와 Rollback은 Production Snapshot·Journal·AuthorityEpoch 절차를 사용한다.
- Test Harness Credential과 Production Campaign 접근 권한을 분리한다.

## 필수 Baseline Scenario

1. 같은 Item 동시 획득
2. 탐험 이동 중 Encounter 전환
3. Reaction 대기 중 Reconnect
4. Commit 직후 Server Restart
5. Rollback 이후 이전 Event Retry
6. 8시간 휴식 중 2시간 지점 습격
7. 숨은 함정 Hover·Search·Diagnostics 누출 검사
8. Presentation ACK 유실
9. 활성 실행 중 Policy 변경
10. Encounter Round Boundary 재시도와 정확히 6초 진행
11. Rollback 후 UI Prompt·Layout 복구
12. Projection Batch Drop과 Catch-up
13. Journal Rename·Section Move 후 Stable Link 유지
14. 비공개 Journal Search·Backlink·Anchor Negative Disclosure
15. Scene Republish·Rollback 후 Journal Anchor Incarnation 재검증
16. 동시 Journal 편집 Conflict와 Last-write-wins 금지
17. Ping Audience·Rate Limit·Signal Loss·만료 후 비복구
18. Stable Scene Object Move·Rename 유지와 Duplicate 새 ID
19. Tool Module 등록·Migration·Deactivate Resource Cleanup
20. Partial Compile과 Full Compile Build Hash·Semantic 동일성
21. Candidate Build 실패 후 Published Build·활성 Session 유지
22. Cross-layer 혼합 Revision·Secret Disclosure Publish 차단
23. Candidate Test Play의 Campaign Dynamic State 격리
24. 새 Build 게시 후 활성 Session 비자동 적용
25. Live Patch Rebase 실패와 이전 Build 복구
26. Runtime Quick Edit 비영구화와 명시적 Source Promotion

## 실행 등급

```text
PR_REQUIRED
MERGE_REGRESSION
NIGHTLY_EXPLORATION
RELEASE_GATE
MANUAL_INCIDENT_REPLAY
```

Required Suite 실패를 무제한 Retry로 숨기지 않는다. Flaky 결과는 결정적 입력 누락이나 외부 Adapter 오염으로 분류한다.

## 후속 구현 명세

- `specs/testing/001-scenario-fixture-schema-and-compiler.md`
- `specs/testing/002-deterministic-rng-clock-id-and-scheduler-adapters.md`
- `specs/testing/003-headless-runtime-bootstrap-state-digest-and-quiescence.md`
- `specs/testing/004-virtual-network-client-reconnect-and-projection-harness.md`
- `specs/testing/005-fault-injection-restart-rollback-and-recovery-driver.md`
- `specs/testing/006-assertion-golden-diff-and-disclosure-scanner.md`
- `specs/testing/007-bounded-interleaving-explorer-and-failure-shrinker.md`

실제 구현 순서는 `../../CURRENT-WORK-ORDER.md`와 Implementation Specs 단계에서 확정한다.

## Guide 상태

```text
Guide Status: READY_TO_WRITE
```

Deterministic Simulation·Fault Injection·Recovery·Disclosure 검증 경계는 구현 가능한 권위 계약과 Completion Audit를 충족한다. Main System Guide 작성 후 `CURRENT`로 전환한다.
