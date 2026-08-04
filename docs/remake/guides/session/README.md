# Main System Guide: Session, Networking, Persistence와 Recovery

- Guide Status: CURRENT
- 적용 시스템 상태: GUIDE_CURRENT
- 작성일: 2026-08-05
- 마지막 권위 문서 검토일: 2026-08-05
- Completion Audit: [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)
- 대체하는 Guide: 없음
- 대체된 Guide: 없음

> 이 Guide는 기존 권위 문서를 연결하고 설명한다. 새로운 규칙·결정·API·데이터 구조를 정의하지 않는다.

## 1. 시스템 목적과 사용자 결과

이 Guide는 사용자가 캠페인에 입장하고, Character와 Actor의 제어권을 배정받고, 현재 세션 상태를 동기화한 뒤 안전하게 플레이하며, 연결 종료·서버 장애·Scene 전환·Rollback 이후에도 현재 권위 상태로 복귀하는 전체 흐름을 설명한다.

사용자에게 보장하는 결과:

- 캠페인의 영구 Character Owner, 현재 Actor Controller와 Session Role이 서로 독립적으로 관리된다.
- 사용자가 로비에서 준비를 눌렀다는 사실과 Client가 권위 입력을 제출할 기술적 준비가 끝났다는 사실을 구분한다.
- 중도 참여자와 재접속자는 Raw Server State가 아니라 자신에게 공개 가능한 Projection Snapshot과 Event Catch-up을 받는다.
- 권위 동기화, Scene Entry Essential과 Controlled Actor 자료가 준비되기 전에는 이동·공격·상호작용 Command가 활성화되지 않는다.
- Network 재전송과 Command Result 유실이 발생해도 하나의 논리적 행동이 두 번 적용되지 않는다.
- 연결이 끊겨도 Character, Actor, HP, Effect, Encounter 참가 상태와 이미 Commit된 결과가 사라지지 않는다.
- 서버가 Transaction 중 종료되어도 Commit Marker와 Journal을 기준으로 중복 또는 부분 적용 없이 복구한다.
- Rollback은 현재 상태를 역방향으로 하나씩 수정하지 않고 선택한 Snapshot을 새 Branch와 AuthorityEpoch에서 복원한다.
- Rollback·Recovery 이전 Connection Epoch의 Command, Prompt 응답과 Subscriber가 새 권위 Branch에 적용되지 않는다.
- Client Cache, Roblox Workspace, Streaming 상태와 Presentation은 권위 저장 원본이 아니다.

적용 범위:

- Campaign Membership과 Session Role
- Character Owner와 Runtime Control Assignment
- 사용자 Ready와 기술적 Client Ready
- Lobby Start·Resume, Hot Join과 Observer
- Base Play Mode, Context, Overlay와 Transitional State
- Versioned Command, Read Request, Receipt와 Result
- Projection Snapshot, Event Catch-up, Gap과 Full Resync
- Scene Streaming Ready와 Scene Transition Gate
- Manifest·Chunk Snapshot, Commit Journal과 Pending Execution 복구
- Disconnect·Reconnect, Server Restart와 Rollback Branch

명시적 비범위:

- 개별 Gameplay 행동과 규칙 계산
- Scene Build 내부 Geometry와 Navigation 계산
- 화면별 로비·복구 UI의 구체적 배치
- 실제 Roblox Remote, Module, DataStore Key와 파일 이름
- Rate Limit, Timeout, Chunk 크기와 보존 기간의 측정형 기본값

## 2. 전체 구조

```text
Campaign Membership
+ Character Ownership
+ Session Role
+ Control Assignment
→ 참가자가 무엇을 보고 무엇을 명령할 수 있는지 결정
```

```text
Transport Connection
→ Protocol Negotiation
→ Connection Session·Epoch
→ Permission-aware Projection Snapshot
→ Event Catch-up
→ Authority Ready
→ Scene·Controlled Actor Essential Ready
→ Gameplay Ready
```

```text
Base Play Mode
+ Context Set
+ Overlay Stack
+ Transitional State
→ Effective Command Policy
```

```text
Command
→ Receipt
→ Domain·RuleExecution·Transaction
→ Terminal Result
→ Authority Projection
```

```text
Authority Transaction
→ Commit Journal + Commit Marker
→ Snapshot Manifest·Chunks
→ Server Restart·Recovery·Rollback Source
```

### 핵심 구성 요소

- **Campaign Membership**: 사용자가 특정 Campaign에 참가할 수 있는지와 기본 역할을 나타낸다.
- **Session Role**: 현재 세션에서 `DM`, `Player`, `Observer` 중 어떤 권한 범위를 갖는지 나타낸다.
- **Character Owner**: 캠페인에서 Character의 영구적 소유 관계다.
- **Control Assignment**: 현재 Session·Turn·Encounter 등의 범위에서 Actor Command를 제출할 Controller를 지정한다.
- **User Ready**: 사용자가 Character 선택과 준비를 마치고 세션 시작 의사를 표시한 상태다.
- **Client Ready**: Protocol, Projection, Authority와 Presentation 자료가 현재 Scope의 입력을 안전하게 처리할 수 있는 기술 상태다.
- **Session Runtime State**: Base Mode, Context, Overlay, Transition과 Participant Binding을 소유한다.
- **Connection Epoch**: 재접속한 새 연결이 이전 연결의 메시지를 대체하도록 구분한다.
- **Authority Epoch**: Recovery 또는 Rollback 이후 이전 Branch의 모든 비동기 입력을 차단한다.
- **Projection Cursor**: Client가 어느 공개 View까지 적용했는지 나타내며 Event Catch-up과 Gap 탐지에 사용한다.
- **Persistence Manifest**: 복구 가능한 Snapshot의 Chunk와 Version·Integrity 정보를 묶는다.
- **Commit Journal**: Commit된 Authority Transaction의 재생 가능한 의미 기록이다.

## 3. 주요 데이터 흐름

### 3.1 Membership, Ownership, Control과 Role

```text
Campaign Membership
├─ 사용자가 Campaign에 참가 가능한가
└─ 기본 Session Role 범위

Character Owner
├─ Character의 영구 캠페인 관계
└─ Session 종료와 Disconnect 후에도 유지

Control Assignment
├─ 현재 Actor에 Command를 제출할 주체
├─ Scope·Activation·Expiration·Fallback
└─ Session Runtime State

Session Role
├─ DM
├─ Player
└─ Observer
```

다음 등식은 성립하지 않는다.

```text
Character Owner
≠ 현재 Controller
≠ Session Role
≠ Information Visibility
```

Owner 변경과 Control 변경은 별도 Command, Transaction과 감사 기록을 사용한다. 연결 종료와 함께 Owner나 Actor를 삭제하지 않는다.

### 3.2 Ready State

사용자 의사 상태:

```text
not_ready
→ ready
```

기술 동기화 상태:

```text
connected
→ protocol_ready
→ projection_syncing
→ projection_catching_up
→ authority_ready
→ presentation_ready
→ gameplay_ready
```

사용자 Ready가 `true`여도 `gameplay_ready`가 아니면 권위 Gameplay Command를 제출할 수 없다. 반대로 기술 준비가 끝났어도 사용자가 로비 Ready를 누르지 않았을 수 있다.

### 3.3 Session Runtime State

```text
SessionRuntimeState
├─ sessionId
├─ authorityEpoch
├─ baseModeState
├─ contextBindings[]
├─ overlayBindings[]
├─ transitionState?
├─ pauseGateState?
├─ participantRuntimeBindings[]
├─ activeSceneBindings[]
├─ activeEncounterIds[]
├─ activeDowntimeSessionIds[]
├─ commandPolicyRevision
└─ revision
```

- Base Play Mode는 `exploration`, `encounter`, `downtime` 중 하나다.
- Context는 `stealth`, `travel`, `hazard`처럼 현재 Mode에 규칙·UI 힌트를 기여한다.
- Overlay는 Selection, DM Authoring, Pause, Rollback Review, Journal과 Sheet처럼 현재 Mode 위에 겹친다.
- Transitional State는 Join, Reconnect, Scene Transition, Snapshot Sync, Recovery, Rollback Commit과 Build Migration의 안전 Gate다.

UI Panel을 열고 닫는 행동과 Base Play Mode 전환을 동일시하지 않는다.

### 3.4 Network Message와 Command

```text
ProtocolEnvelope
+ CommandEnvelope
→ Schema·Connection Epoch·Role·Ready 검증
→ Idempotency·Precondition·Rate Limit 검증
→ Receipt
→ Domain 실행
→ Terminal Result
```

Mutation과 Read를 분리한다.

```text
Command
→ 권위 상태를 변경할 수 있는 Intent

Read Request
→ Snapshot에 고정된 조회·Preview·상세 정보 요청
```

`Receipt: accepted`는 Commit을 의미하지 않는다. 권위 결과는 `CommandResult`와 관련 Projection이 적용된 후 확인한다.

### 3.5 Projection과 Client State

```text
Raw Authority State
+ Session Role·Control·Permission
+ Visibility·Knowledge·Disclosure
→ Projection Snapshot·Event
→ Client Replica
```

Client는 다음을 저장 원본으로 사용하지 않는다.

- 로컬 Actor 위치와 HP
- Client Inventory와 Door State
- UI 버튼 활성 상태
- Streaming된 Workspace Instance
- Camera 위치와 Presentation Cache

Projection Stream에 Gap이 생기면 권위 입력을 일시 중지하고 Catch-up 또는 Full Resync를 수행한다.

### 3.6 Scene Streaming Ready

다음 상태를 하나의 `loaded` Boolean으로 합치지 않는다.

```text
Server Authority Runtime Residency
Projection Interest
Presentation Interest
Streaming Activation Set Ready
```

세션 입력 Gate에는 최소한 다음 Scope가 연결될 수 있다.

- Session Shell과 Protocol
- Scene Entry Essential
- Controlled Actor Essential
- 활성 Encounter Essential
- 열린 Prompt·Reaction 대상
- Scene Transition Target Essential

Optional Decoration 실패는 Gameplay Ready를 차단하지 않을 수 있지만, 필수 Activation Set이 준비되지 않은 상태에서 권위 이동을 열지 않는다.

### 3.7 Persistence

```text
Authoring Source
+ Authoritative Runtime State
→ 일관된 AuthorityRevision의 Immutable State View
→ Chunk 직렬화·Hash
→ Snapshot Manifest Candidate
→ 필수 Chunk 검증
→ Completion Marker
→ Current Snapshot Pointer 교체
```

Snapshot과 별도로 Commit Journal이 이어진다.

```text
Validated Snapshot
+ 이후 Commit Journal Segment
→ 현재 Authoritative State 복구
```

저장하지 않거나 다시 만드는 파생 자료:

- Spatial·Navigation·Query Index
- Projection과 ViewModel Cache
- Streaming Cache
- Presentation Model, VFX, Tween과 Camera
- Roblox Physics 상태

### 3.8 Branch와 Epoch

```text
Connection Epoch
→ 동일한 권위 Branch 안에서 새 Client 연결이 이전 연결을 대체

Authority Epoch
→ Recovery·Rollback으로 새 권위 Branch가 이전 Branch를 대체
```

같은 Authority Epoch라면 Retention Window와 Cache 무결성에 따라 Delta Resume를 시도할 수 있다. Authority Epoch가 바뀌면 Full Resync를 사용한다.

## 4. 주요 실행 흐름

### 4.1 캠페인 로비와 세션 시작

```text
Campaign 참가 권한 확인
→ Session Role 확인
→ Character Owner·Control Assignment 확인
→ 사용자 Ready 확인
→ Client Authority Ready 확인
→ 활성 Scene·Recovery 상태 확인
→ Start·Resume Transaction
→ Projection Catch-up
→ Scene·Controlled Actor Essential 준비
→ Gameplay Ready 활성화
```

DM이 준비되지 않은 사용자를 제외하고 시작할 수 있더라도, 동기화 중인 사용자와 DM 제어로 남는 Actor를 명시적으로 표시한다.

### 4.2 중도 참여

```text
Transport 연결
→ Protocol Negotiation
→ Membership·Role 검증
→ Connection Session·Epoch 발급
→ 사용자별 Projection Sync Plan
→ Snapshot Segment 수신·검증
→ Replica 원자 적용
→ Base Sequence 이후 Event Catch-up
→ Authority Ready
→ Presentation Materialization
→ 안전 경계에서 Control Assignment 활성화
→ Gameplay Ready
```

미해결 공격, Reaction, Commit과 Build 교체 중간에 새 Controller를 즉시 삽입하지 않는다. 동기화 중에는 공개 가능한 Observer View를 제공할 수 있지만 권위 입력은 안전 경계 이후에 연다.

### 4.3 일반 Command와 결과 확인

```text
UI Intent
→ Command + Idempotency Key
→ Receipt
→ Authorization·Ready·Precondition 검증
→ RuleExecution 또는 Domain Operation
→ Transaction Commit·Reject
→ Command Result
→ Projection Expectation 충족
→ UI Reconciliation
```

Timeout 후 같은 논리적 행동을 재전송할 때는 같은 Idempotency Key를 사용한다. 같은 Key와 다른 Payload는 거부한다.

### 4.4 연결 종료

```text
Connection Lost
→ Reconnect Grace
→ 진행 중 Command 상태 확인
→ Commit된 결과 유지
→ 미수신 Result 보존
→ 다음 사용자 입력 필요 지점까지 안전 진행
→ Encounter·Session Disconnect Policy
→ DM Takeover·대기·위임 선택
```

연결 종료는 다음을 변경하지 않는다.

- Character Owner
- Actor Runtime Object
- HP, 자원, Item과 Effect
- Encounter 참가 상태
- 이미 Commit된 결과

Control Assignment와 Prompt Timeout은 명시된 Policy에 따라 처리한다.

### 4.5 재접속과 Delta Resume

```text
ClientHello + Resume Token + Projection Cursor
→ 새 Connection Epoch
→ 이전 Connection Epoch 무효화
→ 최근 Command Terminal State 확인
→ Delta Resume 적격성 검사
→ Event Catch-up
→ Pending Prompt·Reaction·Roll 재Projection
→ Control Assignment 재검증
→ Gameplay Ready
```

Delta Resume 조건 예시:

- 같은 Authority Epoch
- 같은 Role·Disclosure Policy
- Event Retention Window 안의 Cursor
- 호환 가능한 Protocol·Scene Build
- 검증된 Client Cache Hash

### 4.6 Full Resync

다음 경우 Full Projection Snapshot을 사용한다.

- Authority Epoch 변경
- Event Retention Window 초과
- Projection 무결성 오류
- Role·Control·Perception 공개 범위 변경
- Scene Build 또는 Protocol·Schema Migration

```text
입력 Gate 닫기
→ 이전 Replica·Prompt·Selection의 권위 결합 상태 폐기
→ Snapshot Manifest·Segments 적용
→ Event Catch-up
→ ViewModel 재구성
→ 현재 Prompt·Control 재Projection
→ Gameplay Ready
```

### 4.7 Scene Transition

```text
Transition Proposal
→ Target Build·Disclosure 검증
→ 공개 가능한 Target Chunk Preload
→ Target Scene Entry Essential Ready
→ Source·Target Presence 이동 Transaction
→ 새 Projection Epoch·Interest 적용
→ Source Presentation 정리
→ Target Gameplay Ready
```

전환 실패 시 Actor를 두 Scene에 중복 생성하지 않는다. 필수 Target 자료가 준비되지 않았다면 Source Scene 또는 명시적 Transition Gate를 유지한다.

### 4.8 Server Restart와 Recovery

```text
Current Snapshot Pointer 조회
→ Manifest Completion·Integrity 검증
→ 필수 Chunk 로드·Migration
→ Snapshot 이후 Journal 재생
→ Commit Marker로 중복 적용 차단
→ Pending RuleExecution·Resource Reservation 복원
→ Derived Index 재구성
→ 새 AuthorityEpoch
→ Projection 재생성
→ DM Recovery Review 또는 Stable Mode
```

Marker와 State가 불일치하거나 필수 Chunk가 누락되면 자동으로 정상 세션을 열지 않고 Recovery Audit 상태로 전환한다.

### 4.9 Rollback Review와 Rollback Commit

```text
Rollback Review Overlay
→ Checkpoint·Branch 후보 탐색
→ 현재 Branch는 유지
→ DM이 Rollback Commit 승인
→ 선택 Snapshot으로 새 Branch 생성
→ 새 AuthorityEpoch
→ 권위 State·Pending Execution·Control·Fog 복원
→ Derived 자료 재구성
→ 모든 Client Full Resync
→ Stable Mode 복귀
```

Rollback Review 화면을 연 것만으로 현재 권위 상태를 변경하지 않는다. Rollback 이후 이전 Epoch의 Command·Prompt·Timer·Subscriber는 무효다.

### 4.10 Session 종료

```text
신규 Gameplay Command Gate
→ 열린 필수 Execution 정리·안전 중단
→ 마지막 Transaction·Journal Flush
→ 일관된 Snapshot Capture 요청
→ Control·Connection Runtime 종료
→ Campaign Persistent State 유지
```

세션 종료는 Character Owner와 Campaign Source를 삭제하지 않는다.

## 5. 문서 관계도

### Parent Authority

- [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md) — 서버 권위, Client 비신뢰, 오류 격리와 확장 원칙
- [`Compiled Build와 Authoritative State 분리 패턴`](../../architecture/compiled-build-and-authoritative-state-pattern.md) — Source·Build·State·Migration과 Projection 구조
- [`Command Ordering, Logical Time와 Transaction Coordinator`](../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md) — Command 결과의 원자 Commit과 Ordering

### Child Authority

- [`Session Play Mode, Context, Overlay와 Transition 계약`](../../architecture/session-play-mode-context-overlay-and-transition-contract.md) — Session Runtime State와 Effective Command Policy
- [`Networking Command, Event와 Client Synchronization 계약`](../../architecture/networking-command-event-and-client-synchronization-contract.md) — Connection Epoch, Protocol, Command와 Projection Sync
- [`Persistence, Snapshot, Journal과 Recovery 계약`](../../architecture/persistence-and-session-recovery-model.md) — Snapshot·Journal·Branch·Restart와 Rollback 복구
- [`캠페인 로비·중도 참여·소유권·제어권`](../../systems/session/campaign-lobby-hot-join-ownership-and-control.md) — 사용자 입장·Ready·Control·Disconnect·Reconnect 흐름

### References

- [`Runtime Foundation과 Authority Guide`](../runtime/README.md) — 이 Guide가 사용하는 공통 권위 용어와 전체 실행 흐름
- [`Scene Streaming, Client Interest와 Ready Activation 계약`](../../architecture/scene-streaming-client-interest-and-ready-activation-contract.md) — Scene·Controlled Actor Essential과 Transition Preload
- [`UI Projection, ViewModel, Input Context와 Recovery Runtime`](../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md) — Client Replica·Input Gate와 Reconciliation
- [`Domain Event Runtime`](../../architecture/domain-event-outbox-subscription-and-projection-runtime-contract.md) — Projection Event, Subscriber와 Catch-up의 Commit 이후 경계
- [`Deterministic Simulation과 Test Harness`](../../architecture/deterministic-simulation-scenario-and-test-harness-runtime-contract.md) — Reconnect·Restart·Rollback·Gap 회귀 Scenario
- [`Session 시스템 인덱스`](../../systems/session/README.md) — 기능별 진입점
- [`현재 Guide 작업 순서`](../CURRENT-GUIDE-WORK-ORDER.md) — Guide 단계의 현재 진행 순서

## 6. 다른 시스템과의 경계

| 인접 시스템 | Session·Network·Persistence가 제공하는 것 | 상대 시스템이 제공하는 것 | 권위 경계 문서 |
|---|---|---|---|
| Campaign·Character | Membership, Owner·Controller·Role와 저장 Scope | Character Source·Build·Persistent State | Lobby·Control 모델, Character Runtime |
| Gameplay Domain | Mode·Ready·Transition Command Gate와 Connection Context | 실제 행동 적격성, 결과와 Domain Mutation | Session Runtime, Rule Runtime, Transaction |
| Encounter·Downtime | Base Mode Binding, Participant Sync와 Recovery Gate | Timeline·Opportunity 또는 Activity·Time 상태 | Session Runtime, Encounter·Downtime Runtime |
| UI | Projection Cursor, Command Receipt·Result와 Resync 상태 | Panel·ViewModel·Focus와 Semantic Intent | Networking, UI Runtime |
| Scene Streaming | Gameplay Ready Scope와 Transition Ticket | Chunk·Activation Set·Presentation Materialization | Streaming 계약 |
| Persistence | Snapshot·Journal·Branch와 Restore Barrier | 각 Domain의 직렬화 가능한 State·Migration Adapter | Persistence 계약 |
| Domain Event | Outbox Sequence와 Projection Catch-up 기준 | Commit 이후 Event와 멱등 Subscriber | Event Runtime |
| Diagnostics | Connection·Command·Recovery Reference | Trace·Incident·Budget와 Support View | Diagnostics Runtime |
| Simulation | Production Bootstrap과 Recovery Entry Point | Virtual Network·Storage Fault와 Assertion | Simulation Harness |

고정 경계:

- Session Role이 Character Owner를 자동 변경하지 않는다.
- Controller 변경이 정보 공개 권한을 자동 이전하지 않는다.
- Networking Adapter가 Gameplay 결과를 계산하지 않는다.
- Receipt가 Transaction Commit을 대신하지 않는다.
- Projection Cursor가 Authority Revision의 원본이 아니다.
- Persistence Chunk 경계가 Transaction 경계가 아니다.
- Streaming Chunk Eviction이 Runtime Object Lifecycle을 변경하지 않는다.
- UI 로컬 상태와 Client Cache가 Recovery 원본이 아니다.
- Session Runtime이 Character·Encounter·Downtime Store를 복제하지 않는다.

## 7. 추천 읽기 순서

1. [`Runtime Foundation과 Authority Guide`](../runtime/README.md) — 공통 Source·State·Command·Transaction·Epoch 용어
2. [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md) — 전체 권위 불변식
3. [`ADR-0049`](../../decisions/ADR-0049-campaign-character-ownership-hot-join-and-control-assignment.md) — Owner·Controller·Role 분리
4. [`캠페인 로비·중도 참여·소유권·제어권`](../../systems/session/campaign-lobby-hot-join-ownership-and-control.md) — 실제 사용자 입장과 복귀 흐름
5. [`Session Play Mode, Context, Overlay와 Transition`](../../architecture/session-play-mode-context-overlay-and-transition-contract.md) — 세션 실행 상태와 Command Gate
6. [`ADR-0070`](../../decisions/ADR-0070-orthogonal-session-modes-contexts-overlays-and-transitions.md) — Mode·Context·Overlay·Transition 분리 결정
7. [`Networking Command, Event와 Client Synchronization`](../../architecture/networking-command-event-and-client-synchronization-contract.md) — Protocol과 Projection 동기화
8. [`ADR-0059`](../../decisions/ADR-0059-versioned-command-protocol-and-projection-stream-synchronization.md) — Versioned Command와 사용자별 Projection Stream
9. [`Scene Streaming, Client Interest와 Ready Activation`](../../architecture/scene-streaming-client-interest-and-ready-activation-contract.md) — Scene Entry와 Gameplay Ready
10. [`ADR-0060`](../../decisions/ADR-0060-authority-independent-interest-managed-scene-streaming.md) — Streaming과 Authority Lifecycle 분리
11. [`Persistence, Snapshot, Journal과 Recovery`](../../architecture/persistence-and-session-recovery-model.md) — Restart·Pending Execution·Branch 복구
12. [`ADR-0042`](../../decisions/ADR-0042-authoritative-checkpoints-command-journal-and-session-recovery.md) — Checkpoint와 Command Journal
13. [`ADR-0063`](../../decisions/ADR-0063-manifest-chunk-snapshots-commit-journal-and-branch-recovery.md) — Manifest·Chunk·Commit Marker와 Branch Recovery
14. [`UI Runtime`](../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md) — Client Replica와 입력 재활성화
15. [`Completion Audit`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md) — 구현 전 구조 공백 해소 판정

## 8. 구현·검증 순서

다음은 권위 문서에서 이미 드러난 의존 관계를 Spec 단계에서 분리하는 순서다.

```text
Campaign Membership·Role·Ownership Spec
→ Control Assignment와 Participant Runtime Spec
→ Protocol·Connection Epoch·Message Registry Spec
→ Projection Snapshot·Event Stream·Gap Recovery Spec
→ Session Mode·Context·Overlay·Transition Gate Spec
→ Command Receipt·Result·Idempotency Spec
→ Streaming Ready·Scene Transition Spec
→ Persistence Manifest·Chunk·Commit Journal Spec
→ Pending Execution·Reservation Recovery Spec
→ Reconnect·Restart·Rollback Full Resync Spec
→ Diagnostics·Simulation Integration Spec
```

필수 검증 흐름:

- Owner와 Controller가 다른 Character로 세션 시작
- Observer의 제한된 Projection과 Command 거부
- Authority Ready 이전 Gameplay Command 거부
- 동일 Idempotency Key 재전송과 Result 복구
- Event Gap 이후 입력 Gate와 Catch-up
- 같은 Authority Epoch에서 Delta Resume
- Authority Epoch 변경 후 Full Resync
- Reaction Prompt 중 Disconnect·Reconnect
- Commit Marker 직후 Server Restart
- 불완전 Manifest와 Chunk Integrity 실패
- Scene Transition Target Ready 실패
- Rollback 후 이전 Connection Epoch·Prompt·Subscriber 거부
- DM Takeover 후 원래 Player 재접속과 Control 재검증

Guide는 실제 Module·Remote·DataStore 분할을 정하지 않는다. 이는 Implementation Specs 단계가 소유한다.

## 9. 변경 영향 지도

| 변경 유형 | 함께 확인할 권위 문서 | 영향받을 Specs | Guide 조치 |
|---|---|---|---|
| Session Role·Owner·Control 의미 변경 | Lobby·Control 모델, Session Runtime, Networking | Membership·Authorization·Projection | `UPDATE_REQUIRED` |
| Base Mode·Context·Overlay 추가 | Session Runtime, Policy Runtime, UI Runtime | Command Gate·UI Input Context | `UPDATE_REQUIRED` |
| Protocol Envelope·Command Version 변경 | Networking, Diagnostics, Persistence | Protocol·Registry·Migration | `UPDATE_REQUIRED` |
| Ready Scope 변경 | Networking, Streaming, Session Runtime | Sync·Activation·Command Gate | `UPDATE_REQUIRED` |
| Projection Schema·Disclosure 변경 | Networking, Visibility, UI | Snapshot·Event·Client Replica | `UPDATE_REQUIRED` |
| Snapshot·Chunk·Journal Schema 변경 | Persistence, Transaction, Domain Runtime | Serializer·Migration·Recovery | `UPDATE_REQUIRED` |
| Recovery·Rollback Branch 의미 변경 | Persistence, Session Runtime, UI Runtime | Recovery Coordinator·Resync | `UPDATE_REQUIRED` |
| Timeout·Rate Limit·Retention 기본값 변경 | 해당 Architecture의 남은 기본값 | Configuration·Load Test | 필요 시 갱신 |
| Scene Transition Ready 정책 변경 | Streaming, Session Runtime, Runtime Object | Transition·Activation | `UPDATE_REQUIRED` |

## 10. Authority Documents

### Product

- 별도 세션 Product 문서를 이 Guide의 권위로 사용하지 않는다. 현재 제품 고정 전제는 [`리메이크 문서 허브`](../../README.md)에 기록되어 있다.

### Architecture

- [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md)
- [`Compiled Build와 Authoritative State 분리 패턴`](../../architecture/compiled-build-and-authoritative-state-pattern.md)
- [`Session Play Mode, Context, Overlay와 Transition`](../../architecture/session-play-mode-context-overlay-and-transition-contract.md)
- [`Networking Command, Event와 Client Synchronization`](../../architecture/networking-command-event-and-client-synchronization-contract.md)
- [`Scene Streaming, Client Interest와 Ready Activation`](../../architecture/scene-streaming-client-interest-and-ready-activation-contract.md)
- [`Persistence, Snapshot, Journal과 Recovery`](../../architecture/persistence-and-session-recovery-model.md)
- [`Command Ordering, Logical Time와 Transaction Coordinator`](../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)
- [`Domain Event Runtime`](../../architecture/domain-event-outbox-subscription-and-projection-runtime-contract.md)
- [`UI Runtime`](../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md)

### Systems·UI

- [`캠페인 로비·중도 참여·소유권·제어권`](../../systems/session/campaign-lobby-hot-join-ownership-and-control.md)
- [`Session 시스템 인덱스`](../../systems/session/README.md)
- [`전투 턴 Snapshot과 DM Rollback`](../../systems/combat/encounter-turn-snapshot-and-dm-rollback-model.md)

### Specs

- 아직 없음. 이 Guide의 구현·검증 순서를 기준으로 `specs/` 단계에서 작성한다.

### Audits

- [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)

## 11. ADR References

- [`ADR-0042`](../../decisions/ADR-0042-authoritative-checkpoints-command-journal-and-session-recovery.md) — 권위 Checkpoint, Command Journal과 Session Recovery
- [`ADR-0043`](../../decisions/ADR-0043-encounter-turn-snapshot-timeline-and-dm-rollback.md) — Encounter Timeline Snapshot과 DM Rollback
- [`ADR-0049`](../../decisions/ADR-0049-campaign-character-ownership-hot-join-and-control-assignment.md) — Character Owner, Hot Join과 Control Assignment 분리
- [`ADR-0059`](../../decisions/ADR-0059-versioned-command-protocol-and-projection-stream-synchronization.md) — Versioned Command Protocol과 Projection Stream
- [`ADR-0060`](../../decisions/ADR-0060-authority-independent-interest-managed-scene-streaming.md) — Authority와 Client Streaming 분리
- [`ADR-0062`](../../decisions/ADR-0062-ordered-reservations-and-atomic-authority-transactions.md) — Ordering·Reservation과 Atomic Transaction
- [`ADR-0063`](../../decisions/ADR-0063-manifest-chunk-snapshots-commit-journal-and-branch-recovery.md) — Manifest·Chunk Snapshot, Commit Journal과 Branch Recovery
- [`ADR-0070`](../../decisions/ADR-0070-orthogonal-session-modes-contexts-overlays-and-transitions.md) — Base Mode·Context·Overlay·Transition의 직교 분리
- [`ADR-0083`](../../decisions/ADR-0083-projection-driven-ui-runtime-and-epoch-safe-client-recovery.md) — Projection 기반 UI와 Epoch-safe Client Recovery

## 12. 알려진 비목표와 측정형 기본값

### 비목표

- 사용자 Ready와 기술 Client Ready를 하나의 Boolean으로 합치지 않는다.
- Character Owner, Actor Controller, Session Role과 Information Visibility를 하나의 필드로 합치지 않는다.
- Client Timestamp와 Remote 도착 순서로 권위 순서를 정하지 않는다.
- 중도 참여자에게 Raw Server Snapshot을 전송하지 않는다.
- Disconnect 시 Character·Actor·Encounter 참가 상태를 삭제하지 않는다.
- Client 로컬 State와 Workspace Instance를 Recovery 원본으로 사용하지 않는다.
- 모든 UI Panel과 DM 작업 상태를 새 Base Play Mode로 만들지 않는다.
- Streaming Chunk Ready를 서버 Authority Residency와 동일시하지 않는다.
- Rollback을 현재 State의 역방향 Mutation 목록으로 구현하지 않는다.

### 측정형 기본값

다음은 Architecture를 바꾸지 않는 운영·성능 기본값이며 Spec 또는 테스트에서 확정한다.

- Reconnect Grace와 Resume Token 만료 시간
- Player·Command별 Rate Limit과 In-flight 상한
- Projection Event Retention과 Gap Window
- Snapshot Segment·Persistence Chunk 목표 크기
- Journal Flush·Snapshot 요청 주기
- Save Queue, Retry와 Backoff
- Transition·Client Ready Timeout
- Disconnect 후 DM Takeover 제안 시간
- Optional Presentation Placeholder 품질과 Streaming Cache 한도
- Checkpoint·Rollback Timeline 보존 기간

## 13. Guide 검증 체크리스트

- [x] 모든 핵심 문장이 Authority Document에 근거한다.
- [x] 새로운 제품 규칙이나 Architecture 결정을 추가하지 않았다.
- [x] 모든 링크가 존재한다.
- [x] Parent·Children·References를 구분했다.
- [x] 최신 ADR과 현재 Spec 부재 상태를 반영했다.
- [x] 권위 문서와 충돌하는 요약이 없다.
- [x] 변경 영향 지도가 최신이다.
- [x] Guide Status가 실제 상태와 일치한다.
