# Runtime Architecture Completion과 Main System Guide 준비도 감사

- 상태: ACTIVE
- 문서 종류: Completion Audit
- 감사일: 2026-08-04
- 감사 범위:
  - `docs/remake/architecture/`
  - `docs/remake/systems/`
  - `docs/remake/ui/`
  - `docs/remake/decisions/ADR-0054` 이후 공통 Runtime 결정
  - [`이전 Runtime 통합 감사`](runtime-architecture-integration-and-engine-completeness-audit.md)의 BLOCKER와 후속 작업
- 관련 정책:
  - [`문서 수명주기와 Discontinuation 정책`](../DOCUMENT-LIFECYCLE-AND-DISCONTINUATION.md)
- 주요 신규 근거:
  - [`Ruleset Policy Runtime`](../architecture/ruleset-policy-registry-composition-and-frozen-snapshot-runtime-contract.md)
  - [`Encounter–Game Time 통합 계약`](../architecture/encounter-game-time-temporal-boundary-and-scheduler-integration-contract.md)
  - [`UI Runtime`](../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md)
  - [`Diagnostics Runtime`](../architecture/diagnostics-observability-correlated-trace-and-incident-runtime-contract.md)
  - [`Simulation과 Test Harness`](../architecture/deterministic-simulation-scenario-and-test-harness-runtime-contract.md)
  - [`Journal Runtime`](../architecture/journal-document-section-anchor-permission-search-and-projection-runtime-contract.md)
  - [`Cross-Domain Outcome Integration`](../architecture/cross-domain-outcome-cascade-and-integration-boundary-runtime-contract.md)

## 1. 감사 목적

이 감사는 이전 감사가 `NOT READY`로 판정한 구조적 공백이 모두 해소되었는지 확인하고, 다음 세 상태를 분리해 판정한다.

```text
Architecture Completeness
Main System Guide Readiness
Implementation·Production Readiness
```

검토 질문:

1. Gameplay와 Support Runtime에 미정의 Core Engine이 남아 있는가.
2. Runtime 간 직접 순환 의존이나 중복 Authority가 남아 있는가.
3. Cross-Domain Outcome이 부분 성공 없이 처리되는가.
4. Policy, Permission, Projection, UI와 Diagnostics가 일관된 공통 경계를 사용하는가.
5. Reconnect, Restart, Rollback과 Subscriber Retry에서 수명주기가 이어지는가.
6. 동시성·정보 누출·복구 오류를 생산 경로와 같은 코드로 검증할 수 있는가.
7. Main System Guide가 더 이상 새로운 Architecture 결정을 대신 만들어야 하지 않는가.
8. 구현으로 내려가기 전에 남은 작업이 Architecture 공백인지 Implementation Spec 작업인지 구분되는가.

Audit은 새 제품 규칙을 정의하지 않는다. 감사 중 발견된 마지막 공통 결정은 별도 Cross-Domain Architecture와 ADR-0087에 먼저 반영했다.

## 2. 최종 판정

```text
Gameplay Domain Engine Completeness
→ COMPLETE FOR CURRENT PRODUCT SCOPE

Support Runtime Architecture Completeness
→ COMPLETE FOR CURRENT PRODUCT SCOPE

Cross-System Integration Architecture
→ COMPLETE WITH DEFAULTS

Main System Guide Phase
→ READY

Implementation Specs Phase
→ QUEUED AFTER GUIDES

Production Implementation
→ NOT READY YET
```

`Production Implementation → NOT READY YET`는 Architecture BLOCKER가 남았다는 의미가 아니다. 다음 단계인 Main System Guide와 수직 Implementation Spec이 아직 작성되지 않았기 때문이다.

현재 제품 범위에서 새로운 Core Engine을 추가할 근거는 발견되지 않았다.

## 3. 이전 감사 BLOCKER 해소 판정

| 이전 항목 | 후속 권위 문서 | 판정 |
|---|---|---|
| Ruleset Policy Composition과 Snapshot Runtime | Policy Registry·Composition·Frozen Snapshot 계약, ADR-0081 | `RESOLVED` |
| Encounter↔Game Time 순환 위험 | Temporal Boundary·Scheduler Integration 계약, ADR-0082 | `RESOLVED` |
| UI Runtime | Projection·ViewModel·Input Context·Recovery 계약, ADR-0083 | `RESOLVED` |
| Diagnostics와 Observability | Correlated Trace·Incident 계약, ADR-0084 | `RESOLVED` |
| Deterministic Simulation과 Test Harness | Production-parity Scenario Harness, ADR-0085 | `RESOLVED` |
| Journal Anchor·Permission·Projection | Stable Identity·Permission-partitioned Search·Safe Navigation, ADR-0086 | `RESOLVED` |
| Damage·Death·Combat 및 Cross-Domain 연결 | Outcome Cascade·Integration Boundary 계약, ADR-0087 | `RESOLVED` |

이전 감사에서 Main Guide 진입을 막던 구조적 BLOCKER는 모두 해소됐다.

## 4. 전체 Authority 흐름 감사

현재 권위 생성과 변경 흐름은 다음으로 닫힌다.

```text
Authoring Source
→ Compiler·Resolver
→ Immutable Compiled Build
+ Versioned Authoritative State
→ Runtime Snapshot
→ Permission-aware Projection
→ ViewModel·UI·Presentation
```

변경 흐름:

```text
Intent
→ Command
→ Authorization·Validation
→ RuleExecution 또는 Domain Operation
→ Cross-Domain Outcome Plan
→ Ordering·Transaction
→ State Commit + Journal + Outbox
→ Deferred Consequence Command·RuleExecution
→ Projection Barrier
→ UI·Presentation·Diagnostics
```

권위 원본 표:

| 개념 | 권위 소유자 | 판정 |
|---|---|---|
| Ruleset·Campaign·Scope Policy | Frozen Policy Snapshot | `PASS` |
| Scene 저작 원본 | Scene Source | `PASS` |
| 정적 Runtime 구조 | Immutable Compiled Build | `PASS` |
| Character 성장 원본 | Character Progression Source | `PASS` |
| HP·자원·장기 상태 | Persistent Character·Actor Domain State | `PASS` |
| Scene Presence | Runtime Object Registry | `PASS` |
| Item | ItemInstance Registry | `PASS` |
| 지속 효과 | Effect Registry | `PASS` |
| 실행 중 선택·반응·결과 | RuleExecution | `PASS` |
| Turn·Round·Opportunity | Encounter Timeline | `PASS` |
| Campaign 시간 | Campaign Game Time | `PASS` |
| 장기 활동 | DowntimeSession·Activity | `PASS` |
| 원자적 변경 | Transaction Coordinator | `PASS` |
| Commit 이후 사실 | Domain Event Outbox | `PASS` |
| Journal Source·Anchor | Journal Runtime | `PASS` |
| Client 표시 | Permission-aware Projection | `PASS` |
| 카메라·VFX·화면 배치 | Camera·Presentation·UI Runtime | `PASS` |
| 관측·지원 자료 | Diagnostics Runtime | `PASS` |

같은 상태를 둘 이상의 Runtime이 독립 원본으로 소유하는 사례는 최신 권위 문서에서 발견되지 않았다.

## 5. Runtime Dependency 감사

### 5.1 정상 단방향 의존

```text
UI
→ Projection과 Intent

Selection
→ Visibility·Spatial Query

Interaction
→ Capability Query와 Domain Command

Spell·Action
→ RuleExecution·Roll·Effect

Encounter
→ Opportunity·Boundary Context

Downtime
→ Time Coordination과 Domain Completion Plan

Presentation
→ CameraRequest·Visual Playback
```

하위 Runtime이 UI, Presentation 또는 Workspace Instance를 권위 결과로 다시 읽는 구조는 금지되어 있다.

### 5.2 통제된 반복 흐름

```text
Domain Event
→ Subscriber
→ Follow-up Command·RuleExecution
→ 새 Transaction
→ 새 Domain Event
```

이 흐름은 모듈 순환 의존이 아니라 시간상 반복 가능한 인과 흐름이다.

안전장치:

- Correlation·Causation Graph
- AuthorityEpoch 검증
- Idempotency Key
- Retry·Dead Letter
- Execution·Subscriber Budget
- Cycle Detection
- Cross-Domain Gate

판정: `PASS`

### 5.3 직접 상호 호출 위험

다음 직접 상호 호출은 최신 계약에서 금지됐다.

```text
EncounterService ↔ GameTimeService
DamageService → CharacterStore → EffectStore → EncounterStore
Journal Link → Camera·Selection 직접 조작
Scheduler Callback → Domain Store 직접 Mutation
UI Component → Gameplay Store 직접 Mutation
```

대체 경계:

- Provider Contribution과 Authority Transaction
- Boundary Port
- Command·RuleExecution
- Domain Event Outbox
- Safe Intent·Request

판정: `PASS`

## 6. Cross-Domain Outcome 감사

### 6.1 Immediate Closure

다음은 동일 Transaction으로 닫힌다.

```text
Damage
+ Temporary HP
+ Current HP
+ VitalState
+ DeathSave Lifecycle
+ 확정적 Capability·Opportunity·Reservation Closure
```

```text
Encounter End
+ Timeline·Opportunity 종료
+ Encounter-bound Effect Cleanup
+ Session Mode Binding 전환
```

```text
Build Activation
+ Source Revision
+ Build Ref
+ State Migration
```

```text
Crafting
+ Input 소비
+ Output Item
+ Container·Ground Presence
```

불가능한 중간 AuthorityRevision을 공개하지 않는 기준이 확정됐다.

판정: `PASS`

### 6.2 Deferred Consequence

다음은 Commit된 사실에서 별도 실행으로 시작한다.

- 피해 후 집중 내성
- On-damage Trigger와 Reaction
- 사망 후 Objective·Morale·Surrender 평가
- Scheduler Due 사건
- Derived Index Rebuild
- Journal Anchor Reindex
- Presentation과 UI Feedback

Root Outcome을 되돌리지 않고 필요한 Scope만 Gate할 수 있다.

판정: `PASS`

### 6.3 Damage·Death·Combat

검토 결과:

- Roll Runtime이 HP를 직접 수정하지 않는다.
- HP 0·VitalState·DeathSave Lifecycle을 같은 Closure Plan으로 묶을 수 있다.
- 사망이 Character·Inventory·Actor Presence 삭제를 의미하지 않는다.
- Damage Provider가 Encounter Cursor를 직접 이동하지 않는다.
- Objective 달성과 Encounter 종료는 Encounter Policy와 Command를 사용한다.
- Encounter 종료가 Actor HP·위치·Item·지속 Knowledge를 초기화하지 않는다.
- 집중 검사는 별도 RuleExecution으로 추적된다.

판정: `PASS`

## 7. Policy와 확장성 감사

모든 교체형 규칙은 Policy Family와 Versioned Implementation을 사용한다.

```text
Product Safe Default
+ Ruleset
+ Source Pack
+ Campaign
+ Scope
+ Dynamic Rule Contribution
+ DM Override
+ User Accessibility Limit
→ Frozen Effective Policy View
```

확인 항목:

- 진행 중 Encounter·Downtime·RuleExecution의 Snapshot 고정
- Gameplay·Disclosure·Operational·Presentation Plane 분리
- Family별 Merge·Conflict Rule
- Last Known Good와 Migration
- Source Pack Patch Target Version
- DM Override의 Scope·Reason·Expiry·Audit

판정: `PASS`

남은 수치 기본값은 구현 Spec에서 선택할 수 있으며 Architecture BLOCKER가 아니다.

## 8. Role·Permission·Disclosure 감사

기본 분리:

```text
Session Role
≠ Character Ownership
≠ Runtime Control Assignment
≠ Information Visibility
```

확인 결과:

- Player, DM, Observer와 System 권한이 최신 Runtime에 명시되어 있다.
- Client는 Raw Authority를 받은 뒤 화면에서만 숨기지 않는다.
- UI, Hover, Selection, Journal Search, Backlink와 Diagnostics는 Permission-aware Projection을 사용한다.
- 비밀 Journal 제목·Anchor·검색 Hit·결과 수가 권한 밖으로 전달되지 않는다.
- DM Player-view Preview는 선택한 Audience와 같은 Projection을 사용한다.
- DM Override는 일반 Command와 구분되고 Mandatory Audit를 요구한다.
- Camera·Presentation은 Visibility와 Authority를 우회하지 않는다.

판정: `PASS`

## 9. Lifecycle·Persistence·Rollback 감사

장기 권위 객체 공통 요소:

```text
stable identity
authorityEpoch
incarnation 또는 version
revision
explicit lifecycle state
terminal record·tombstone
snapshot·journal recovery
```

적용 범위:

- Runtime Object
- RuleExecution
- Authority Transaction
- EffectInstance
- EncounterSession
- DowntimeSession·Activity
- DurationHandle·ScheduledExecution
- ItemInstance
- Character Build·State
- Journal Document·Section·Anchor
- Cross-Domain Outcome·Deferred Consequence

확인 결과:

- Restart 후 Snapshot + Journal에서 Pending Execution·Reservation·Outbox·Gate를 복구할 수 있다.
- Rollback은 역연산이 아니라 새 Branch·AuthorityEpoch 복원이다.
- 이전 Epoch의 Command, Reaction, Scheduler Due, Follow-up, ACK와 Index 완료 신호는 무효화된다.
- Client는 Full Resync와 Projection Replica 재구성을 사용한다.
- Journal Source History는 Encounter Rollback과 분리되고 World Anchor만 새 Epoch에서 재해결된다.

판정: `PASS`

## 10. Derived Data와 Runtime Materialization 감사

Derived Data:

```text
Spatial Index
Navigation Cache
Perception Index
Projection Cache
Journal Search·Backlink Index
UI ViewModel Cache
Presentation Model
Roblox Workspace Instance
```

확인 결과:

- Derived Data는 권위 저장 원본이 아니다.
- Authority Transaction은 Mutation + Invalidation Record를 Commit한다.
- Rebuild 실패가 이미 Commit된 권위 결과를 되돌리지 않는다.
- 권위 판정에 오래된 Index를 사용할 위험이 있으면 관련 Command Scope만 Gate한다.
- Presentation Materialization 실패가 Runtime Object를 삭제하지 않는다.

판정: `PASS`

## 11. UI·Presentation·Diagnostics 감사

### UI

```text
Projection Replica
→ Derived ViewModel
→ Component
→ Semantic Input
→ Intent
```

- Projection Batch 원자 적용
- Q/E Input Context 단일 소비
- Prompt·Selection의 Authority-bound 복구
- Local Layout·Accessibility와 권위 UI 상태 분리
- Epoch 변경 시 오래된 Pending Intent 폐기

판정: `PASS`

### Presentation

- Gameplay Outcome과 Playback 분리
- Recipe·Module·Augment Registry
- 접근성·Quality Profile
- 실패·Timeout·Fallback 격리
- CameraRequest를 통한 간접 제어

판정: `PASS`

### Diagnostics

- Input부터 UI까지 Correlated Trace
- Policy·Rule·Authorization Decision Record
- 역할별 Redaction
- Recovery Journal·Mandatory Audit·Observability 분리
- Budget·Sampling·Incident Bundle

판정: `PASS`

## 12. Deterministic Testability 감사

Simulation Harness는 별도 규칙 엔진이 아니라 생산 Registry와 Handler를 사용한다.

통제 Adapter:

- RNG Stream
- Authority Monotonic Clock
- ID Factory
- Task·Message Scheduler
- Network
- Storage
- Presentation ACK
- Virtual Client

필수 검증 범위:

- 동시 Item 획득
- Encounter 전환과 이동 경쟁
- Reaction 중 Reconnect
- Commit 직후 Restart
- Rollback 이전 Subscriber·Follow-up 차단
- Downtime 중간 Encounter
- 숨은 정보 Negative Assertion
- Presentation 실패 격리
- Policy Snapshot 고정
- Round Time 중복 방지
- Cross-Domain Immediate Closure와 Projection Barrier

판정: `PASS`

실제 Scenario 파일과 CI Suite는 Implementation Specs·구현 단계에서 작성한다.

## 13. Engine Completeness 판정

현재 제품 범위의 Core·Support Engine:

```text
Ruleset Policy
Session
Exploration
Encounter
Downtime
Game Time
Selection
Interaction
Visibility·Knowledge·Detection
Character
Character Action
Spell
Dice·Resolution
Effect
Inventory
Runtime Object
Scene Compiler
Spatial Query
Navigation
Streaming
Rule Orchestrator
Transaction
Cross-Domain Integration
Domain Event
Networking
Persistence·Recovery
UI
Camera
Presentation
Journal
Diagnostics
Simulation·Test Harness
```

새 독립 Engine이 필요하다고 판정하지 않은 영역:

- NPC AI: Intent Producer
- Quest: Event Subscriber + Journal·Knowledge Domain Module
- 상점·경제: Interaction·Inventory·Downtime Module
- Audio: Presentation Module
- 절차 생성: Scene Authoring·Compiler 확장
- 핑: 입력·Network·Presentation 기능

판정:

```text
NO MISSING CORE ENGINE FOUND
```

## 14. Main System Guide 준비도

Main System Guide는 새로운 권위 결정을 만드는 문서가 아니라 다음을 통합해야 한다.

```text
사용자 흐름
+ Authority Documents 읽기 순서
+ 역할별 Command·Projection
+ 실패·복구 흐름
+ Implementation Spec 진입점
```

Guide 진입 조건:

| 조건 | 판정 |
|---|---|
| Authority Architecture 완료 | `PASS` |
| Policy Snapshot 경계 완료 | `PASS` |
| UI·Permission·Projection 완료 | `PASS` |
| 저장·복구·Rollback 완료 | `PASS` |
| Cross-Domain Integration 완료 | `PASS` |
| Diagnostics·Simulation 기준 완료 | `PASS` |
| 기존 BLOCKER 해소 | `PASS` |

최종 판정:

```text
GLOBAL MAIN SYSTEM GUIDE PHASE
→ READY
```

## 15. Guide Phase에서 해야 할 일

Guide는 영역별로 다음을 정리한다.

```text
1. 권위 원본과 Runtime Map
2. Player·DM·Observer 사용자 흐름
3. Intent→Command→Execution→Transaction→Projection 경로
4. 다른 Runtime과 Integration Boundary
5. 실패·Reconnect·Rollback·Recovery
6. UI 진입점과 Q/E Context
7. Diagnostics·Simulation 확인점
8. 구현 Spec 목록과 수직 Slice 순서
9. SUPERSEDED·DISCONTINUED 문서 제외 읽기 순서
```

권장 Guide 묶음은 후속 `CURRENT-WORK-ORDER`의 Main System Guides 항목에서 확정한다.

## 16. Implementation Specs 준비도

Architecture가 완료됐어도 바로 Production Implementation으로 내려가지 않는다.

필요 Spec 범위:

- Module·Package·Service 경계
- Luau Type와 Schema
- Registry Definition
- Command·Result·Error Code
- Network Message와 Projection Segment
- Persistence Chunk와 Migration
- Ordering Key·Transaction Node
- Trace Span·Budget
- Deterministic Scenario Fixture
- Vertical Slice Acceptance Test

판정:

```text
IMPLEMENTATION SPEC PHASE
→ READY AFTER MAIN SYSTEM GUIDES
```

## 17. 남은 비차단 항목

다음은 Architecture BLOCKER가 아니다.

- 각 계약의 수치 Budget·Timeout·Batch 기본값
- UI Layout·색상·애니메이션 상세
- 실제 Roblox Module 경로와 Naming
- DataStore Chunk 목표 크기
- 구체적인 Test 반복 횟수
- 콘텐츠 Pack별 공식 수치와 Localization
- 플레이테스트를 통한 Policy 기본값 조정

이 항목들은 Implementation Specs, UI 디자인, Content Pack과 플레이테스트에서 확정한다.

## 18. 문서 수명주기 판정

이 감사는 [`runtime-architecture-integration-and-engine-completeness-audit.md`](runtime-architecture-integration-and-engine-completeness-audit.md)를 대체한다.

이전 감사의 BLOCKER와 다음 작업 순서는 모두 해소되거나 현재 Work Order에 인계됐다.

따라서 이전 감사는 현재 판단에서 제외하고 역사 기록으로 보존한다.

## 19. 결론

RVTT 리메이크는 현재 제품 범위에서 Core Runtime Architecture와 Cross-System Integration Architecture를 완료했다.

```text
새 Core Engine 추가 단계
→ 종료

Main System Guide 통합 단계
→ 시작 가능

Implementation Specs
→ Guide 이후 가능

Production Implementation
→ 아직 시작하지 않음
```

다음 작업은 Main System Guides를 작성해 구현자가 각 영역의 권위 문서와 수직 Slice를 일관된 순서로 읽고 구현할 수 있도록 만드는 것이다.
