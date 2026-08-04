# Runtime Architecture 통합성과 Engine Completeness 감사

- 상태: ACTIVE
- 문서 종류: Audit
- 감사일: 2026-08-04
- 감사 범위: `docs/remake/architecture/`, `docs/remake/systems/`, `docs/remake/ui/`
- 관련 정책:
  - [`문서 수명주기와 Discontinuation 정책`](../DOCUMENT-LIFECYCLE-AND-DISCONTINUATION.md)
- 주요 권위 문서:
  - [`Runtime Architecture Principles`](../architecture/runtime-architecture-principles.md)
  - [`Compiled Build와 Authoritative State 분리 패턴`](../architecture/compiled-build-and-authoritative-state-pattern.md)
  - [`Session Play Mode, Context, Overlay와 Transition 계약`](../architecture/session-play-mode-context-overlay-and-transition-contract.md)
  - [`Rule Runtime Orchestrator와 Pending Execution 계약`](../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md)
  - [`Command Ordering, Logical Time와 Transaction Coordinator 계약`](../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)
  - [`Domain Event, Outbox, Subscription과 Projection Runtime 계약`](../architecture/domain-event-outbox-subscription-and-projection-runtime-contract.md)
  - [`Persistence와 Session Recovery 모델`](../architecture/persistence-and-session-recovery-model.md)

## 1. 감사 목적

이 감사는 현재까지 확정된 Runtime 계약을 전체 시스템으로 읽었을 때 다음 조건이 성립하는지 확인한다.

1. Runtime 간 의존 방향이 일관적인가.
2. 같은 상태를 둘 이상의 Runtime이 권위 원본으로 소유하지 않는가.
3. 플레이테스트 후 바뀔 가능성이 높은 규칙이 Engine Core에 하드코딩되지 않았는가.
4. Player, DM, Observer와 System의 권한 경계가 일관적인가.
5. 저장·복구·Rollback·Reconnect에서 수명주기가 끊기지 않는가.
6. 구현 전에 반드시 필요한 Engine 또는 공통 계약이 빠져 있지 않은가.

Audit은 새로운 제품 규칙을 직접 정의하지 않는다. 새 권위 결정이 필요한 항목은 별도 Architecture와 ADR로 작성해야 한다.

## 2. 최종 판정

```text
Gameplay Domain Engine Completeness
→ CONDITIONALLY COMPLETE

전체 구현 준비도
→ NOT READY
```

Exploration, Encounter, Downtime, Character Action, Spell, Resolution, Effect, Inventory, Interaction, Visibility, Navigation, Game Time, Transaction, Event와 Persistence를 연결하는 Gameplay Runtime의 주요 축은 갖춰졌다.

그러나 다음 네 가지 공통 기반은 아직 독립 권위 계약이 없다.

```text
BLOCKER 1
Ruleset Policy Composition과 Snapshot Runtime

BLOCKER 2
UI Runtime

BLOCKER 3
Diagnostics와 Observability Runtime

BLOCKER 4
Deterministic Simulation과 Test Harness
```

또한 Journal은 기능 모델은 있으나 여러 Runtime이 공유하는 Anchor·Permission·Projection 계약이 Architecture 수준으로 승격되지 않았다.

따라서 현재 상태에서 새로운 Gameplay 기능별 Engine을 계속 추가하는 것은 우선순위가 아니다. 먼저 위 공통 기반을 완성해야 한다.

## 3. 현재 권위 실행 흐름

전체 문서에서 일관되게 확인되는 정상 흐름은 다음과 같다.

```text
Authoring·Persistent Source
→ Compiler·Resolver
→ Immutable Compiled Build
+ Versioned Authoritative State
→ Runtime Snapshot
→ Permission-aware Projection
→ Presentation·UI
```

상태 변경은 다음 경로를 사용한다.

```text
Player·DM·System Intent
→ Command
→ Authorization·Validation
→ RuleExecution 또는 Domain Operation
→ Ordering Reservation
→ Authority Transaction
→ State Commit + Domain Event Outbox
→ Projection Event
→ Presentation·UI·Journal·Diagnostics
```

Session 진행은 세 Base Play Mode로 분리되어 있다.

```text
Exploration
↔ Encounter
↔ Downtime
```

Pause, Presentation, DM Authoring과 Rollback Review는 Base Mode가 아니라 Overlay다. Scene Transition, Join, Reconnect, Recovery와 Build Migration은 Transition Gate를 사용한다.

이 상위 흐름에는 치명적인 구조 충돌이 발견되지 않았다.

## 4. Runtime Dependency Audit

### 4.1 통과한 의존 경계

#### Character Action과 Spell

Character Action Runtime은 주문별 규칙을 소유하지 않고 `Magic`과 Action Opportunity를 제공한다. Spell Runtime이 SpellCastRoute와 RuleExecution을 처리한다.

```text
Character Action
→ Opportunity와 Capability 분류

Spell Runtime
→ 주문 시전 규칙과 실행
```

직접적인 양방향 의존이 필요하지 않다.

#### Interaction과 Inventory

Interaction Runtime이 Inventory Store를 직접 변경하지 않는다. Item, Tool, Key와 Equipment는 Capability Query에 기여하고, 실제 이전·소비는 Inventory Domain Transaction이 처리한다.

#### Selection과 Visibility

Selection은 공개 가능한 Candidate와 Frozen Binding을 사용하고, Visibility는 Observer별 Disclosure를 제공한다. Visibility가 Selection Session을 직접 생성하거나 변경하지 않는 한 의존 방향은 단방향으로 유지된다.

```text
Selection
→ Visibility·Knowledge Disclosure Snapshot 조회
```

#### Presentation과 Camera

Presentation Module은 Camera를 직접 조작하지 않고 CameraRequest를 제출한다. Camera Runtime은 Gameplay Authority를 변경하지 않는다.

#### Rule Event와 Domain Event

Rule Event는 Commit 전 규칙 개입 지점이고, Domain Event는 Commit된 과거 사실이다. 같은 `Event` 이름을 공유하지만 수명주기와 권위가 분리됐다.

### 4.2 통제된 반복 흐름

다음 흐름은 모듈 순환 의존이 아니라 시간상 반복 가능한 실행 흐름이다.

```text
Domain Event
→ Subscriber
→ Follow-up Command 또는 RuleExecution
→ 새 Transaction
→ 새 Domain Event
```

Domain Event 계약의 Correlation Chain, 반복 제한, Budget과 Cycle Detection을 유지하면 허용 가능하다.

### 4.3 추가 계약이 필요한 경계

#### Encounter와 Game Time

Encounter는 Round Boundary를 소유하고 Game Time에 D&D 2024 기본 6초 진행을 요청한다. Game Time Scheduler는 Encounter Boundary를 기한으로 사용할 수 있다.

두 Runtime이 서로의 내부 Store나 Service를 직접 호출하면 실제 모듈 순환이 생길 수 있다.

필요한 고정 경계:

```text
Encounter
→ TemporalBoundaryOccurrence 발행
→ Game Time이 Policy Snapshot으로 Campaign Time Advance 계산

Game Time Scheduler Due
→ Domain Event 또는 Command
→ Encounter가 최신 상태에서 처리
```

즉, `EncounterService ↔ GameTimeService` 직접 상호 호출을 금지하고 Boundary Port와 Event를 통해 연결하는 통합 계약이 필요하다.

판정: `REQUIRES_INTEGRATION_CONTRACT`

## 5. Authority Boundary Audit

### 5.1 통과

다음 권위 원본은 명확하게 분리되어 있다.

| 개념 | 권위 소유자 |
|---|---|
| Scene 저작 원본 | Scene Source |
| 정적 파생 구조 | Immutable Compiled Build |
| Actor 위치·HP·문 상태 | Domain Authoritative State |
| 행동 중간 상태 | RuleExecution |
| 원자적 변경 | Transaction Coordinator |
| Commit 이후 사실 | Domain Event Outbox |
| 세계 시간 | Campaign Game Time |
| Turn·Round 순서 | Encounter Timeline |
| Client 표시 정보 | Permission-aware Projection |
| VFX·Camera·UI | Presentation |

Workspace, UI, VFX와 Client Prediction을 권위 원본으로 사용하지 않는 원칙도 일관적이다.

### 5.2 누락: Policy 권위 소유자

현재 여러 Runtime은 교체 가능한 Policy를 선언한다.

예:

- Initiative Policy
- Turn Policy
- Action Economy Policy
- Objective·End Policy
- Round Duration Policy
- Downtime Entry·Interruption·Refund Policy
- Visibility·Disclosure Policy
- Timeout Policy
- Join·Leave Policy
- Build Migration Policy
- Presentation Quality·Accessibility Policy

하지만 다음을 공통으로 소유하는 독립 계약이 없다.

```text
Policy Definition Registry
Policy Schema와 Version
Policy Source와 Precedence
Ruleset·Campaign·Scene·Encounter·Effect Override 합성
충돌 해결과 진단
Immutable Policy Snapshot
진행 중 Execution의 Policy Version 고정
Hot Swap과 Migration
Fallback과 Last Known Good
```

각 Runtime이 자신의 방식으로 Policy 우선순위를 구현하면 같은 DM Override가 시스템마다 다르게 적용될 수 있다.

판정: `BLOCKER`

필요 문서 후보:

```text
architecture/
ruleset-policy-registry-composition-and-snapshot-runtime-contract.md

decisions/
ADR-0081-versioned-policy-composition-and-frozen-ruleset-snapshots.md
```

## 6. Policy Extraction Audit

하드코딩을 피하려는 방향은 전반적으로 잘 지켜졌다.

- D&D 2024의 1 Round = 6초는 Round Duration Policy다.
- Initiative 계산은 Initiative Policy다.
- Delay 미지원과 Ready 지원은 D&D 2024 Policy Pack의 결정이다.
- Encounter Objective와 자동 종료 여부는 Objective·End Policy다.
- Downtime 필요 시간과 환불은 Activity Policy다.
- Presentation 품질과 접근성은 Profile과 Recipe다.

문제는 Policy가 분리되어 있다는 사실이 아니라, **서로 다른 Policy Source를 어떤 순서로 합치는지 공통 계약이 없다는 것**이다.

권장 기본 합성 순서는 후속 Architecture에서 결정해야 한다.

```text
Product Safe Default
→ Ruleset Policy Pack
→ Campaign Policy
→ Scene·Encounter·Downtime Session Policy
→ Character·Item·Effect Rule Contribution
→ 명시적 DM Override
→ 사용자 접근성 제한
```

사용자 접근성 제한처럼 DM도 강제로 무시할 수 없는 정책과, 규칙상 DM이 Override할 수 있는 정책을 같은 우선순위 체계로 단순 합치면 안 된다.

## 7. Role와 Permission Audit

### 7.1 전반 판정

Player, DM, Observer와 System 분리는 대부분의 최신 Runtime에 명시되어 있다.

다음 분리도 유지된다.

```text
Character Owner
≠ Runtime Controller
≠ Session Role
≠ Information Visibility
```

DM이 Actor를 정상 조작할 때 일반 Command 경로를 사용하고, 규칙 무시가 필요한 경우에만 DM Override와 감사 로그를 사용하는 원칙도 일관적이다.

판정: `PASS_WITH_GAPS`

### 7.2 남은 공백

#### UI 권한 적용

UI가 Raw Authority State를 받은 뒤 버튼만 숨기는 방식은 금지되어야 한다. 모든 Panel, Tooltip, Search Result와 Context Menu는 Projection과 Command Authorization 결과만 사용해야 한다.

이 경계는 UI Runtime에서 공통으로 고정해야 한다.

#### Journal 권한 적용

현재 Journal 모델은 `private_dm`, `owner_and_dm`, `party`, `campaign` 권한을 정의하지만 다음 공통 계약이 부족하다.

- 문서와 Section의 안정적 Identity·Revision
- Actor·Object·Scene·Room·Camera Anchor의 타입 체계
- 대상 삭제·교체·Scene Migration 시 Link 수명주기
- 검색 Index의 권한별 분리
- Player Client에 숨은 제목·대상·검색 Hit를 전달하지 않는 Projection
- DM 전용 링크 작성과 Player 열람·탐색 권한 분리
- Journal Navigation이 Selection·Camera·Visibility에 제출하는 안전한 Intent

판정: `MAJOR CONTRACT GAP`

Journal은 별도 Gameplay Engine일 필요는 없지만 Architecture 수준의 공유 계약이 필요하다.

## 8. Lifecycle Audit

### 8.1 통과

장기 권위 객체 대부분은 다음 요소를 가진다.

```text
stable identity
authorityEpoch
incarnation 또는 version
revision
explicit lifecycle state
terminal record 또는 tombstone
snapshot·journal recovery
```

적용 대상:

- Runtime Object
- RuleExecution
- EffectInstance
- Authority Transaction
- EncounterSession
- DowntimeSession과 Activity
- DurationHandle와 ScheduledExecution
- ItemInstance
- Character Build·State

Rollback 이후 이전 Epoch의 Command, Event, Schedule와 비동기 응답을 무효화하는 원칙도 일관적이다.

### 8.2 후속 구현 요구

다음 항목은 공통 Diagnostics와 Simulation에서 검증해야 한다.

- Terminal Object의 Reservation 누수
- 취소된 Selection·Prompt·Reaction의 입력 문맥 잔존
- Rollback 후 이전 Epoch Subscriber 재실행
- Scene Transition 후 고아 Runtime Object·Effect·Journal Anchor
- Reconnect 후 중복 UI Prompt와 중복 Command 결과

판정: `PASS_REQUIRES_TESTING`

## 9. Engine Completeness Audit

### 9.1 Gameplay Engine

현재 Gameplay 실행에 필요한 주요 Engine은 갖춰졌다.

```text
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
Domain Event
Networking
Persistence·Recovery
Camera
Presentation
```

이 목록에 새로운 기능별 Engine을 계속 추가할 필요는 없다.

단, 전 Runtime의 교체형 규칙을 묶는 `Ruleset Policy Composition Runtime`은 Gameplay 기반 Engine으로 추가해야 한다.

### 9.2 구현 전에 필요한 Support Runtime

#### UI Runtime — BLOCKER

현재 UI 문서는 화면 영역과 일부 입력 문법을 정의하지만 다음 공통 Architecture가 없다.

```text
Projection
→ ViewModel
→ UI Component
→ Intent
→ Command 또는 Read Request
```

필요 범위:

- Docked·Floating·Modal·Overlay·Transient·Tooltip Panel 타입
- Panel Identity, Focus, Z-order와 수명주기
- Input Context Stack과 Q Universal Back·E Universal Confirm
- Projection Revision과 ViewModel 무효화
- Optimistic UI와 Command Result 보정
- Reconnect·Scene Transition·Rollback 시 UI 복구
- Player·DM·Observer별 UI Projection
- Accessibility와 사용자 설정

#### Diagnostics와 Observability Runtime — BLOCKER

플레이테스트 후 구조를 안전하게 수정하려면 다음 Trace를 한 흐름으로 연결해야 한다.

```text
Input Intent
→ Command
→ RuleExecution
→ Transaction
→ Domain Event
→ Projection
→ Presentation
```

필요 범위:

- correlationId·traceId 전파
- Command 거절 이유와 Contribution 설명
- 느린 Spatial Query·Compile·Projection 기록
- Reservation·Pending Execution·Subscriber 누수 감지
- 비밀 정보가 Player Projection에 포함되는지 검사
- Presentation Module 오류와 Fallback 기록
- 재현 가능한 Snapshot·AuthorityEpoch·Build Hash 묶음
- DM용 안전한 진단 화면과 비밀 정보 Redaction

#### Deterministic Simulation과 Test Harness — BLOCKER

필요 범위:

- Fake Campaign Clock와 Monotonic Clock
- 고정 RNG Seed와 Roll Record
- Test Scene·Character·Encounter Factory
- Command·Event·Reconnect·Rollback 주입
- Snapshot과 Projection Golden 비교
- 동시 Command 순서 무작위화
- Presentation 실패 주입
- Server Recovery와 Outbox 재전달 테스트

대표 필수 시나리오:

```text
같은 Item을 두 Actor가 동시에 줍는다.
Encounter 전환 순간 이동 Command가 Commit된다.
Reaction 대기 중 재접속한다.
Rollback 후 이전 Epoch Event가 재실행되지 않는다.
Downtime 8시간 진행 중 2시간 지점 Encounter가 발생한다.
숨은 Trap이 Hover·Search·Presentation으로 누출되지 않는다.
VFX 실패 후 Damage Transaction은 유지된다.
```

### 9.3 별도 Engine이 필요하지 않은 영역

현재 범위에서 다음은 독립 Core Engine이 아니라 기존 Runtime의 Producer, Subscriber, Content Pack 또는 Module로 구현할 수 있다.

- NPC AI: Intent Producer
- Quest: Domain Event Subscriber와 Journal·Knowledge Projection
- Audio: Presentation Module
- Dialogue Tree: 현재 제품 비목표
- 상점·경제: Interaction·Inventory·Downtime 위 Domain Module
- 절차 생성: Scene Authoring·Compiler 확장

## 10. 시스템별 남은 통합 문서

Core Engine이 존재하더라도 각 System Guide를 작성하기 전에 다음 통합 계약이 필요하다.

### Combat

- Damage·HP 0·Death·Effect·Encounter Integration
- Turn Snapshot·Rollback과 최신 Encounter Timeline 정합성
- Encounter↔Game Time Boundary Port

### Character

- Level Up·Spell Preparation·Rest와 Downtime Completion 연결
- Build Migration 실패·부분 선택·Reconnect 사용자 흐름

### Selection·Interaction·Visibility

- UI Runtime 기반 Hover Card·Inspection·Context Menu 수명주기
- Journal Anchor와 DM Hidden Selection 연결

### Scene·Navigation

- Authoring UI가 내부 Polygon·Clearance를 노출하지 않는 Completion Audit
- Runtime Object 상태 변경과 증분 Index 갱신의 Simulation Test

## 11. 다음 작업 순서

```text
1. Ruleset Policy Composition과 Frozen Snapshot Runtime
2. Encounter↔Game Time Temporal Boundary Integration 계약
3. UI Runtime
4. Diagnostics와 Observability Runtime
5. Deterministic Simulation과 Test Harness
6. Journal Anchor·Permission·Projection 계약
7. System별 Integration 계약과 Completion Audit
8. 완료 판정을 받은 시스템의 Main System Guide
9. 구현 Spec
10. 실제 구현
```

Policy Composition을 가장 먼저 두는 이유는 앞으로 작성할 UI, Diagnostics, Simulation과 System Guide가 모두 현재 적용 중인 Ruleset·Campaign·DM Policy Snapshot을 설명하고 재현해야 하기 때문이다.

## 12. Main System Guide 준비도

전체 Main System Guide 작성 단계로 바로 전환하는 것은 아직 이르다.

```text
Global Guide Phase
→ NOT READY
```

개별 시스템 Guide는 다음 조건을 모두 만족하면 작성할 수 있다.

1. 해당 시스템의 Authority Architecture가 `READY` 또는 `READY_WITH_DEFAULTS`다.
2. 관련 Policy Source와 Snapshot 경계가 확정됐다.
3. UI·Permission·Projection 의존성이 필요한 경우 UI Runtime이 확정됐다.
4. 저장·복구·Rollback 경로가 연결됐다.
5. 관련 Integration Audit의 BLOCKER가 없다.
6. 관련 구형 문서의 SUPERSEDED·DISCONTINUED 정리가 끝났다.

## 13. 재감사 완료 조건

다음 문서가 확정되면 이 Audit을 재검토한다.

- Ruleset Policy Composition Runtime과 ADR
- UI Runtime과 ADR
- Diagnostics·Observability Runtime과 ADR
- Simulation·Test Harness 계약
- Journal Anchor·Permission·Projection 계약
- Encounter↔Game Time Integration 계약

모든 BLOCKER가 해소되면 새 Completion Audit을 작성하고, 이 문서는 `DISCONTINUED` 또는 역사적 Audit로 이동할 수 있다.

## 14. 결론

RVTT의 Gameplay Runtime은 더 이상 큰 기능별 Engine을 무작정 추가해야 하는 단계가 아니다.

현재 가장 중요한 구조적 공백은 다음이다.

```text
교체 가능한 규칙을 일관되게 합성하는 Policy 권위
화면 전체를 같은 입력·Projection 규칙으로 묶는 UI Runtime
플레이테스트 문제를 추적하는 Diagnostics
동시성·복구·정보 누출을 재현하는 Simulation Harness
```

이 네 기반을 완료한 뒤 System Integration과 Main System Guide로 내려가는 것이 가장 안전하다.
