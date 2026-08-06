# Networking Command, Event와 Client Synchronization 계약

- 상태: 확정
- 문서 종류: Architecture
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 남은 기본값:
  - 사용자·Command Type별 Rate Limit과 Burst 상한
  - Connection별 최대 In-flight Command·Read Request 수
  - Idempotency Result Cache와 Projection Event Retention 기간
  - Snapshot Segment 목표 크기와 동시 전송 수
  - Event Gap과 Command Stream Gap 허용 Window
  - Presentation Signal의 갱신·병합 주기
  - 재접속 Grace와 Resume Token 만료 시간
- 작성일: 2026-08-03
- 관련 ADR:
  - [`ADR-0033`](../decisions/ADR-0033-server-authoritative-dice-rolls-and-presentation-gated-resolution.md)
  - [`ADR-0042`](../decisions/ADR-0042-authoritative-checkpoints-command-journal-and-session-recovery.md)
  - [`ADR-0049`](../decisions/ADR-0049-campaign-character-ownership-hot-join-and-control-assignment.md)
  - [`ADR-0054`](../decisions/ADR-0054-compiled-semantic-runtime-and-query-authority-principles.md)
  - [`ADR-0057`](../decisions/ADR-0057-canonical-scene-source-and-atomic-compiled-build-activation.md)
  - [`ADR-0058`](../decisions/ADR-0058-stable-runtime-object-identity-and-command-driven-lifecycle.md)
  - [`ADR-0059`](../decisions/ADR-0059-versioned-command-protocol-and-projection-stream-synchronization.md)
- 관련 문서:
  - [`Runtime Architecture Principles`](runtime-architecture-principles.md)
  - [`Scene Compiler와 Compiled Runtime Scene 계약`](scene-compiler-and-compiled-runtime-scene-contract.md)
  - [`Runtime Object System과 Entity Lifecycle 계약`](runtime-object-system-and-entity-lifecycle-contract.md)
  - [`저장·세션 복구 모델`](persistence-and-session-recovery-model.md)
  - [`캠페인 로비·중도 참여·소유권·제어권`](../systems/session/campaign-lobby-hot-join-ownership-and-control.md)

## 1. 목적

이 문서는 Client와 권위 Server 사이의 모든 게임 메시지가 사용하는 공통 계약을 정의한다.

대상:

- 플레이어와 DM의 권위 Command
- 상태를 바꾸지 않는 서버 Read Request
- Command 수신 확인과 최종 Result
- Commit 이후의 권위 Event Projection
- 최초 접속·중도 참여·재접속 Snapshot 동기화
- Client Ready와 입력 활성화
- Presentation 전용 신호
- 중복, 순서 역전, 연결 종료와 재전송
- Rate Limit, Payload 검증과 정보 공개
- Protocol·Schema Version과 호환성

Roblox `RemoteEvent`와 다른 전송 Primitive는 이 계약을 운반하는 Adapter다. Remote 이름, Instance 구조와 호출 방식이 게임 의미의 권위 계약이 되지 않는다.

## 2. 사용자 결과

내부 계약은 다음 결과를 보장하기 위해 존재한다.

- 클릭 한 번이 네트워크 재전송 때문에 두 번 적용되지 않는다.
- 오래된 UI와 이전 연결의 메시지가 현재 Actor나 Object를 변경하지 못한다.
- 연결이 잠시 끊겨도 전체 Scene을 무조건 처음부터 다시 받지 않는다.
- Event 하나를 놓쳤을 때 Client가 조용히 잘못된 상태로 계속 플레이하지 않는다.
- 중도 참여자는 현재 상태의 안전한 기준점부터 합류한다.
- 권위 상태 로딩이 끝나기 전에 이동·공격 Command를 보낼 수 없다.
- 비밀문, 숨겨진 함정과 DM 전용 상태가 Raw Broadcast로 Player Client에 전달되지 않는다.
- 서버가 바쁠 때 입력을 무한 대기시키지 않고 재시도 가능 여부와 이유를 알려준다.
- 토큰 이동과 UI는 반응적으로 보이지만 Client Prediction이 규칙 결과를 확정하지 않는다.
- 네트워크 오류가 발생해도 사용자는 동일 Command의 최종 처리 여부를 확인할 수 있다.

## 3. 기본 원칙

### 3.1 Client는 Intent를 보내고 Server가 결과를 계산한다

Client가 보낼 수 있는 것:

- Actor 또는 Runtime Object 선택
- 목적지와 대상 후보
- Action·Capability·Variant 선택
- 경로 선호와 사용자 입력 방향
- Prompt·Reaction 응답
- Scene Editor의 저작 의도
- 자신의 마지막 Projection Cursor와 Command 상태 조회

Client가 확정할 수 없는 것:

- 최종 위치와 경로 비용
- 명중·내성·피해 결과
- 대상 적격성, 시야와 거리
- 자원 소비량
- 문·함정·상자 상태
- RuntimeObjectId와 권위 Revision 생성
- 권위 Event 순서

### 3.2 Transport 순서가 Authority 순서가 아니다

메시지가 도착한 순서만으로 규칙 순서를 확정하지 않는다.

모든 권위 변경은 서버의 Command 검증과 Transaction Commit을 거친다. 최종 순서는 `AuthorityEpoch`, `AuthorityRevision`, `transactionId`와 Projection Stream Sequence로 표현한다.

서로 다른 Remote Lane 사이의 도착 순서에 의존하지 않는다.

### 3.3 Mutation과 Read를 분리한다

```text
Command
→ 권위 상태를 바꿀 수 있는 Intent

Read Request
→ Snapshot에 고정된 조회, 계획 또는 상세 정보 요청
```

Read Handler는 Command를 실행하거나 상태를 변경하지 않는다.

예:

```text
PreviewNavigationPath
→ Read Request

CommitActorMovement
→ Command
```

### 3.4 Push를 기본으로 하고 Polling을 예외로 둔다

권위 상태 변화는 Event Projection과 Snapshot으로 Server가 전달한다.

Client가 매 Frame 또는 짧은 주기로 전체 Actor, 문, 전투 상태를 Polling하지 않는다.

Read Request는 다음처럼 사용자가 요청한 계산이나 큰 상세 정보에 사용한다.

- 경로 Preview
- 대상 Preview
- Journal·Character 상세 페이지
- DM 검색
- 진단 Trace

## 4. 고정 Message Lane

공개 Protocol은 기능마다 Remote를 새로 만드는 대신 소수의 고정 Lane을 사용한다.

```text
Client → Server
├─ Command Lane
├─ Read Request Lane
└─ Sync Control Lane

Server → Client
├─ Command Result Lane
├─ Read Result Lane
├─ Authority Projection Lane
├─ Snapshot Segment Lane
├─ Sync Control Lane
└─ Presentation Signal Lane
```

정확한 Roblox Instance 이름과 Lane 병합 여부는 구현 명세에서 정한다. 계약상 중요한 것은 메시지 종류와 권위 의미를 섞지 않는 것이다.

### 4.1 Command Lane

권위 상태를 변경할 가능성이 있는 모든 사용자 입력을 운반한다.

### 4.2 Read Request Lane

상태를 변경하지 않는 서버 계산과 공개 가능한 상세 정보 요청을 운반한다.

### 4.3 Authority Projection Lane

Commit된 권위 상태의 사용자별 Projection Delta를 순서대로 전달한다.

### 4.4 Snapshot Segment Lane

접속·재접속·Scene 전환 시 필요한 큰 Projection Snapshot을 Manifest와 Segment로 전달한다.

### 4.5 Presentation Signal Lane

규칙상 원본이 아닌 시각 신호를 전달한다.

예:

- 토큰 이동 보간 Sample
- 주사위 연출 시작
- 카메라 제안
- VFX Cue
- Hover·Ping의 순간 표시

이 Lane의 메시지는 병합하거나 만료할 수 있다. 손실되었다고 권위 상태를 바꾸거나 복구 저널을 재생하지 않는다.

## 5. Protocol Envelope

모든 네트워크 메시지는 공통 Header를 가진다.

```text
ProtocolEnvelope
├─ protocolVersion
├─ messageTypeId
├─ messageSchemaVersion
├─ messageId
├─ connectionSessionId
├─ connectionEpoch
├─ campaignId?
├─ activeSessionId?
├─ sceneId?
├─ authorityEpoch?
├─ sentSequence
├─ correlationId?
├─ traceId?
└─ payload
```

### 5.1 connectionSessionId와 connectionEpoch

- `connectionSessionId`: 현재 접속과 Resume 흐름을 식별한다.
- `connectionEpoch`: 재접속 또는 새 Client Session이 이전 연결을 대체할 때 증가한다.

이전 Epoch의 Command, Read 응답과 Ready 신호는 구조화된 `STALE_CONNECTION_EPOCH`로 무효화한다.

### 5.2 sentSequence

Sequence는 Lane 또는 명시된 Stream 범위에서 단조 증가한다.

하나의 전역 숫자로 모든 Lane을 억지로 직렬화하지 않는다.

### 5.3 Client 시간

Client Timestamp는 지연 진단과 Presentation 보정에만 사용할 수 있다.

권위 순서, 반응 마감, 이동 거리와 자원 소비를 Client 시간으로 확정하지 않는다.

## 6. Command Registry

Command는 문자열 Remote 이름 분기나 임의 Payload Table이 아니다.

```text
CommandDefinition
├─ commandTypeId
├─ commandSchemaVersion
├─ requestSchema
├─ authorizationPolicyId
├─ readinessScope
├─ concurrencyPolicy
├─ idempotencyPolicy
├─ orderingPolicy
├─ rateLimitPolicyId
├─ executionBudget
├─ auditPolicy
└─ handlerId
```

신뢰된 Registry에 등록된 Command만 실행한다.

Command Handler는 Remote, UI와 Presentation을 직접 호출하지 않는다. 검증된 Intent를 Domain Service와 Transaction에 전달한다.

## 7. CommandEnvelope

```text
CommandEnvelope
├─ protocolHeader
├─ requestId
├─ clientCommandSequence
├─ commandTypeId
├─ commandSchemaVersion
├─ idempotencyKey
├─ actorRef?
├─ targetRefs[]?
├─ baseProjectionCursor?
├─ expectedPreconditions[]
├─ predictionId?
└─ commandPayload
```

### 7.1 requestId

현재 Client Connection에서 요청과 응답을 연결하는 ID다.

### 7.2 idempotencyKey

사용자의 하나의 논리적 행동을 식별한다.

- Timeout 후 재전송할 때 같은 Key를 사용한다.
- 같은 Key와 같은 정규화 Payload가 다시 오면 기존 Receipt·Result를 재전송한다.
- 같은 Key에 다른 Payload가 오면 `IDEMPOTENCY_KEY_PAYLOAD_MISMATCH`로 거부한다.
- Client가 Key를 권위 Object ID나 Transaction ID로 사용할 수는 없다.

Server는 성공뿐 아니라 안전하게 재생 가능한 Terminal Rejection도 일정 기간 Cache할 수 있다.

### 7.3 expectedPreconditions

모든 Command가 현재 전역 Revision과 완전히 같아야 하는 것은 아니다.

Command별로 필요한 조건만 명시한다.

예:

```text
RuntimeObjectRef의 Incarnation
Door State Revision
ActiveTurnId
ControlAssignment Revision
Inventory Container Revision
Scene BuildId
AuthorityEpoch
```

`baseProjectionCursor`는 Client가 어느 View를 보고 입력했는지 알려주는 진단·재동기화 정보다. 그것만으로 권위 상태를 신뢰하지 않는다.

### 7.4 concurrencyPolicy

```text
strict_precondition
revalidate_on_latest
merge_if_non_conflicting
append_only
server_serialized
custom_registered
```

예:

- 아이템 한 개 이전: `strict_precondition`
- 빈 공간 Ping 생성: `revalidate_on_latest`
- Journal Append: `append_only`
- 전투 Actor 이동: `server_serialized`

## 8. Command 처리 흐름

```text
1. Protocol·Schema 검증
2. Connection Epoch와 Session Role 검증
3. Payload 크기·타입·범위 검증
4. Command Sequence와 Idempotency 확인
5. Client Ready Scope 확인
6. Actor·Object Ref 해결
7. Control·Permission·Capability 검증
8. Command별 Precondition 검증
9. Rate Limit·Execution Budget 확인
10. Command Receipt 발행
11. Domain Validation과 Transaction 준비
12. Commit 또는 구조화된 거부
13. Command Result 기록
14. Authority Projection Event 생성
15. 감사·저널 기록
```

Receipt를 발행했다는 이유만으로 Commit된 것은 아니다.

## 9. Receipt와 Result

### 9.1 CommandReceipt

```text
CommandReceipt
├─ requestId
├─ idempotencyKey
├─ serverCommandId
├─ receiptStatus
├─ receivedAtServerTick
├─ queueClass?
├─ retryAfter?
└─ traceId
```

`receiptStatus`:

```text
accepted
queued
duplicate_replayed
rejected_before_execution
```

### 9.2 CommandResult

```text
CommandResult
├─ requestId
├─ serverCommandId
├─ terminalStatus
├─ transactionId?
├─ authorityEpoch
├─ authorityRevisionAfter?
├─ projectionExpectation?
├─ resultPayload?
├─ error?
└─ traceId
```

`terminalStatus`:

```text
committed
rejected
cancelled
expired
superseded
```

### 9.3 장기 실행과 Prompt

주사위 연출, 반응, DM 판정처럼 여러 입력을 기다리는 실행은 하나의 Remote 응답을 열린 채 유지하지 않는다.

```text
StartAction Command
→ committed: ActionExecution 생성
→ Execution Projection과 Prompt 전송
→ RespondToPrompt Command
→ 후속 Commit
```

각 Prompt는 안정적인 `executionId`, `promptId`, `expectedPromptRevision`과 Deadline Policy를 가진다.

## 10. 구조화된 Error

```text
ProtocolError
├─ errorCode
├─ category
├─ retryable
├─ resyncRequired
├─ userMessageKey
├─ fieldErrors[]?
├─ currentReferenceTokens[]?
├─ retryAfter?
└─ traceId
```

오류 Category 예:

```text
protocol
schema
authentication
authorization
stale_reference
precondition
rate_limit
server_busy
not_ready
not_found
conflict
internal
```

Client에 Raw Stack Trace, 내부 Module 경로와 비밀 Object ID를 보내지 않는다.

`retryable=true`라도 Client가 무한 자동 재전송하지 않는다. Idempotency Key, Retry Budget와 Backoff 정책을 따른다.

## 11. Read Request 계약

```text
ReadRequestEnvelope
├─ protocolHeader
├─ requestId
├─ readTypeId
├─ readSchemaVersion
├─ snapshotOrProjectionRef
├─ cancellationKey?
├─ resultLimit?
└─ readPayload
```

Read Request는 다음을 지킨다.

- 읽기 전용이다.
- 사용자별 Disclosure와 Perception을 적용한다.
- Snapshot 또는 View Revision에 고정한다.
- Budget과 Result Limit을 가진다.
- 오래된 Preview는 Client가 Cancellation Key로 폐기할 수 있다.
- 실패를 빈 결과로 위장하지 않는다.

`NavigationPlan`, Target Preview와 Query Trace 같은 결과는 만료 조건과 Dependency Revision을 가진다. 이후 Commit Command는 결과를 그대로 신뢰하지 않고 최신 권위 상태에서 재검증한다.

## 12. 권위 Revision과 Projection Cursor

### 12.1 Server AuthorityRevision

서버 내부의 원자적 Commit 순서다.

```text
AuthorityEpoch
+ AuthorityRevision
```

Rollback Branch, 새 서버 복구와 권위 Fork는 `AuthorityEpoch`을 변경할 수 있다.

### 12.2 Client Projection Stream

일반 Player Client는 Raw Server Event Log를 받지 않는다.

```text
ClientProjectionStream
├─ projectionId
├─ projectionEpoch
├─ audiencePolicy
├─ baseSnapshotId
├─ nextViewSequence
└─ retainedEventWindow
```

각 Client 또는 동일 공개 범위 Group은 자신의 `ViewSequence`를 가진다.

숨겨진 함정 Event와 DM 전용 상태를 제거한 뒤 남은 Projection만 순서화한다. Player에게 전역 Raw Event를 Broadcast한 뒤 UI에서 숨기지 않는다.

### 12.3 AuthorityEventBatch

```text
AuthorityEventBatch
├─ projectionId
├─ projectionEpoch
├─ viewSequenceStart
├─ viewSequenceEnd
├─ transactionId
├─ authorityEpoch
├─ publicRevisionTokens[]
├─ projectedEvents[]
├─ supersedesKeys[]?
├─ integrityHash?
└─ traceId
```

하나의 Transaction에서 Client에 공개되는 변경은 하나의 Batch로 원자 적용한다.

Client는 Batch 내부 일부만 적용하고 UI를 갱신하지 않는다.

## 13. Projection Event 규칙

Projection Event는 Domain Raw State의 무제한 복사본이 아니다.

```text
Domain Commit Event
→ Projection Builder
→ Permission·Perception·Disclosure
→ Client-safe Event
```

예:

```text
Raw: HiddenTrapStateChanged(trapId, armed=false)

미발견 Player Projection:
→ Event 없음

발견한 Player Projection:
→ KnownTrapStateUpdated(publicObjectRef, safe=true)

DM Projection:
→ FullTrapStateUpdated(runtimeObjectRef, armed=false, sourceExecutionId)
```

Projection Event Schema도 Registry, Version과 Stable Ordering을 가진다.

## 14. Event Gap과 Catch-up

Client는 마지막 적용 `projectionEpoch + viewSequence`를 추적한다.

다음 경우 State 적용을 일시 정지한다.

- 예상 Sequence보다 큰 Batch 수신
- 다른 Projection Epoch 수신
- Batch Integrity 실패
- 필요한 Runtime Object View가 존재하지 않음

흐름:

```text
Gap 감지
→ 이후 Batch Buffer
→ Sync Control로 Catch-up 요청
→ Retained Event 재전송 또는 새 Snapshot Plan
→ 연속성 검증
→ Buffer 적용
→ 입력 재활성화
```

Gap을 무시하고 최신 Event부터 적용하지 않는다.

## 15. 접속과 Protocol Negotiation

```text
Transport 연결
→ ClientHello
→ ServerHello
→ 인증·Campaign 권한 확인
→ ConnectionSession 발급
→ Protocol·Registry 호환성 확인
→ Sync Plan 생성
```

### 15.1 ClientHello

```text
ClientHello
├─ supportedProtocolVersions[]
├─ clientBuildVersion
├─ supportedRegistryVersions
├─ resumeToken?
├─ lastProjectionCursor?
└─ localPreferenceSummary?
```

Client가 보내는 Resume 정보는 Catch-up 힌트다. Server가 권위 상태로 신뢰하지 않는다.

### 15.2 ServerHello

```text
ServerHello
├─ selectedProtocolVersion
├─ serverBuildVersion
├─ connectionSessionId
├─ connectionEpoch
├─ authorityEpoch
├─ compatibilityStatus
├─ requiredRegistryVersions
├─ sessionRole
└─ syncMode
```

호환되지 않는 Client는 `UPDATE_REQUIRED` 상태로 게임 Command를 활성화하지 않는다.

## 16. Snapshot Sync

### 16.1 Projection Snapshot

Client는 서버의 전체 Raw Snapshot이 아니라 자신의 공개 범위에 맞는 Projection Snapshot을 받는다.

```text
ProjectionSnapshotManifest
├─ projectionSnapshotId
├─ projectionId
├─ projectionEpoch
├─ baseViewSequence
├─ authorityEpoch
├─ sceneBuildId
├─ requiredSegments[]
├─ optionalSegments[]
├─ segmentHashes[]
├─ totalSizeClass
└─ expiresAt
```

Segment 예:

```text
session_shell
scene_public_definition
runtime_object_directory
controlled_actor_state
encounter_state
fog_and_perception_view
interaction_view
journal_summary
presentation_seed
```

### 16.2 전송 흐름

```text
1. Server가 Sync Plan과 Manifest 전송
2. Client가 보유 Cache와 필요한 Segment 알림
3. Server가 필수 Segment 전송
4. Client가 Hash·Schema 검증
5. Server는 Base Sequence 이후 Live Event를 Buffer
6. Client가 Snapshot을 원자 적용
7. Buffered Event Catch-up
8. Client가 Authority Ready 보고
9. Command Scope 활성화
10. 선택적 Presentation Segment 계속 로드
```

Snapshot 일부가 도착했다고 기존 State와 섞어 권위 UI를 활성화하지 않는다.

### 16.3 Segment 재사용

Scene Build처럼 불변이고 공개 범위가 같은 Segment는 Content Hash로 Cache할 수 있다.

Dynamic State, Perception과 권한이 포함된 Segment를 다른 사용자와 무조건 공유하지 않는다.

## 17. Client Ready 상태

Lobby의 사용자가 누르는 `Ready`와 기술적 Client Ready를 분리한다.

```text
connected
→ protocol_ready
→ projection_syncing
→ projection_catching_up
→ authority_ready
→ presentation_ready
→ gameplay_ready
```

### authority_ready

- 필수 Projection Snapshot 적용 완료
- Event Gap 없음
- Authority·Projection Epoch 일치
- 현재 Role과 Control Assignment 확인

### presentation_ready

- 현재 Scene의 필수 시각 Object와 UI가 조작 가능한 수준으로 생성됨
- 모든 장식과 먼 Chunk가 완전히 로드될 필요는 없음

### gameplay_ready

Command별 Readiness Scope를 충족한다.

예:

- Observer Camera: `authority_ready`
- Character Sheet 열기: `authority_ready`
- Actor 이동: `authority_ready + controlled_actor_presentation + scene_navigation_view`
- 전투 대상 지정: `authority_ready + encounter_view + required_scene_presentation`

Client가 Ready라고 주장해도 Server가 Segment Ack와 Cursor를 검증한다.

## 18. 중도 참여와 재접속

### 18.1 Delta Resume

다음을 모두 만족하면 전체 Snapshot 없이 Event Catch-up을 사용할 수 있다.

- 같은 Authority Epoch
- 같은 Projection Policy와 Role
- 호환 가능한 Scene Build와 Registry
- 마지막 View Sequence가 Retention Window 안에 있음
- Client Cache Segment Hash가 유효함

### 18.2 Full Projection Resync

다음 경우 새 Projection Snapshot을 사용한다.

- Authority Epoch 변경
- Rollback Branch 전환
- Event Retention Window 초과
- Role·Control·Perception 공개 범위의 큰 변경
- Scene Build 교체
- Client Integrity 실패
- Protocol·Schema Migration 필요

### 18.3 Pending Command 복구

Reconnect Handshake에는 최근 Idempotency Key의 상태를 조회할 수 있는 범위가 포함된다.

```text
not_seen
received
queued
committed
rejected
cancelled
expired
```

Client가 Result를 받지 못하고 끊겼더라도 동일 Key로 재전송하거나 Status Query로 최종 결과를 확인한다.

### 18.4 Pending Execution 복구

Prompt, Reaction과 주사위 공개는 Runtime Execution Projection에서 복구한다.

Client가 연결 전 보낸 Prompt 응답이 Commit됐는지는 Server Command Result와 Projection으로 판정한다.

## 19. Command Ordering

### 19.1 Client Command Stream

각 Connection은 Command Sequence를 단조 증가시킨다.

- 이미 처리한 Sequence와 동일 Key: 기존 Result 재생
- 낮은 Sequence와 새로운 Key: `STALE_COMMAND_SEQUENCE`
- 예상보다 큰 Gap: 제한된 Buffer 후 `COMMAND_STREAM_GAP`
- Gap이 복구되지 않음: Command 입력 중지와 Sync 요구

### 19.2 Ordering Key

모든 Command를 하나의 긴 Queue에 넣지는 않는다.

```text
OrderingKey 예
├─ actor:{actorId}
├─ object:{runtimeObjectId}
├─ inventory:{containerId}
├─ scene_authoring:{sceneId}
├─ encounter:{encounterId}
└─ campaign_admin:{campaignId}
```

같은 Ordering Key의 충돌 Command는 직렬화한다. 서로 독립된 Key는 병렬 검증할 수 있지만 Commit은 권위 Transaction 순서를 가진다.

다중 Key Command는 안정적인 Key 정렬로 Lock·Reservation을 획득하며 순환 대기를 방지한다.

## 20. Rate Limit과 Backpressure

제한 단위:

- 사용자
- Connection
- Command·Read Type
- Actor 또는 Scene Authoring Scope
- Payload Byte와 Collection 크기
- 동시 실행 수
- 계산 Budget

서버가 처리할 수 없는 경우:

```text
RATE_LIMITED
SERVER_BUSY
QUEUE_FULL
PAYLOAD_TOO_LARGE
COMPUTE_BUDGET_EXCEEDED
```

을 구조화해 반환한다.

권위 Event는 조용히 버리지 않는다. Client가 따라오지 못하면 Event Catch-up 또는 Snapshot Resync로 전환한다.

Presentation Signal은 최신 상태가 이전 상태를 대체할 수 있을 때 병합·만료할 수 있다.

## 21. 이동과 Prediction

탐험 WASD와 부드러운 토큰 이동은 Presentation Prediction을 사용할 수 있다.

```text
Client Input
→ predictionId가 있는 Intent Command
→ 제한된 로컬 표시
→ Server 승인·권위 Movement Checkpoint
→ Projection Event
→ Prediction Reconcile
```

Client Prediction은 다음을 확정하지 않는다.

- Actor의 권위 Transform
- 이동력 소비
- 함정·반응 경계
- 다른 Actor와 점유
- Door 자동 상호작용

Movement의 연속 화면 Sample은 Presentation Lane으로 병합할 수 있다. 이동 완료·Checkpoint·중단은 Authority Projection으로 전달한다.

## 22. 주사위와 Presentation Gate

Server가 Roll을 생성·봉인하고 권위 결과를 소유한다.

```text
Roll Execution Commit
→ Authority Projection에 Roll 상태 등록
→ Presentation Signal로 연출 시작
→ Client Presentation Ack 또는 Deadline
→ Server가 Result Reveal Commit
→ Authority Projection으로 공개 결과 전달
```

Presentation Signal을 놓쳐도 Client는 Snapshot·Projection에서 현재 `revealed` 상태를 복구한다.

Client의 주사위 물리 결과와 Animation 완료 시간은 권위 Roll 값을 결정하지 않는다.

## 23. Scene Editor Networking

Scene 편집 Command도 같은 Protocol을 사용한다.

```text
PlaceAssetCommand
MoveSceneObjectsCommand
CreateWallChainCommand
ApplySemanticOverrideCommand
PublishSceneBuildCommand
```

- Drag 중 고스트는 로컬 Presentation이다.
- 확정된 편집만 Command로 전송한다.
- 다중 Object 편집은 하나의 Transaction이다.
- Command는 대상 Source Revision과 Object Revision을 Precondition으로 가진다.
- 다른 편집자와 충돌하면 일부만 적용하지 않는다.
- Build Progress와 Diagnostics는 Projection·Read Result로 전달한다.

## 24. Security와 Disclosure

### 24.1 Inbound 검증

모든 Client Payload에 적용한다.

- Schema와 Version
- 필드 타입, 문자열 길이와 배열 크기
- 수치 범위와 유한성
- ID 형식과 현재 Authority Epoch
- RuntimeObjectRef Incarnation
- Campaign·Session·Scene 소속
- Session Role과 Control Assignment
- Capability와 Action Economy
- Payload별 계산 Budget
- Rate Limit과 Abuse 신호

### 24.2 Outbound 공개

Server는 사용자별 Projection을 만들기 전에 다음을 적용한다.

- Session Role
- Character·Object 소유·제어권
- Perception과 Fog
- Secret·DM Metadata Disclosure
- Journal·Handout 접근 정책
- Observer 정책

Raw Runtime Object Directory와 Raw Domain Event를 일반 Client에 먼저 복제하지 않는다.

## 25. Network Service 경계

```text
NetworkGateway
├─ ProtocolNegotiator
├─ ConnectionSessionRegistry
├─ MessageSchemaRegistry
├─ CommandIngress
├─ ReadRequestIngress
├─ CommandRegistry
├─ AuthorizationService
├─ IdempotencyStore
├─ OrderingCoordinator
├─ RateLimitService
├─ CommandDispatcher
├─ ProjectionBuilder
├─ ProjectionStreamService
├─ SnapshotSyncService
├─ PresentationSignalRouter
├─ NetworkTraceService
└─ AbuseMonitor
```

### 25.1 NetworkGateway

Transport Adapter와 공통 Envelope 검증만 담당한다. Feature별 규칙을 구현하지 않는다.

### 25.2 CommandDispatcher

등록된 Handler로 검증된 Command를 전달한다. 직접 HP, 위치와 문 상태를 수정하지 않는다.

### 25.3 ProjectionBuilder

Domain Event와 Snapshot을 Client-safe View로 변환한다. UI Instance를 생성하지 않는다.

### 25.4 SnapshotSyncService

Manifest, Segment 전송, Ack, Catch-up과 Ready Gate를 관리한다. Scene Streaming의 실제 Chunk 우선순위는 후속 Streaming 계약이 소유한다.

## 26. Version과 Migration

Version 종류를 분리한다.

```text
protocolVersion
messageSchemaVersion
commandSchemaVersion
projectionEventSchemaVersion
snapshotSegmentSchemaVersion
registryVersionSet
clientBuildVersion
serverBuildVersion
```

Protocol Version이 같아도 특정 Command Schema Migration이 필요할 수 있다.

호환 정책:

```text
compatible
compatible_with_server_adapter
read_only_compatibility
update_required
server_maintenance
```

Client가 지원하지 않는 필수 Event 또는 Snapshot Segment가 있으면 게임 Command를 활성화하지 않는다.

## 27. 실패와 안전 상태

### Command Result 유실

- 동일 Idempotency Key 재전송
- Status 조회
- Projection에서 Commit 여부 확인

### Event Gap

- 입력 중지
- Catch-up 또는 Snapshot Resync
- 연속성 회복 후 재개

### Snapshot Segment 실패

- 해당 Segment 재요청
- 반복 실패 시 전체 Sync 재시작
- 현재 Published Authority View를 부분 활성화하지 않음

### Projection Builder 실패

- 비밀 정보가 섞인 불완전 Projection을 보내지 않음
- 해당 Audience Stream 일시 중지
- 안전한 Snapshot 재생성 또는 접속 차단

### Command Handler 내부 오류

- Transaction 미확정 또는 Rollback
- `INTERNAL_COMMAND_FAILURE` 반환
- Raw 오류 비공개
- Trace와 감사 기록

### Presentation 실패

- 권위 상태 유지
- Client가 Projection으로 재구성
- 필요할 때 Presentation Segment만 재요청

## 28. 관측과 감사

기록 대상:

```text
traceId
connectionSessionId
connectionEpoch
userId
sessionRole
requestId
idempotencyKey hash
commandTypeId
serverCommandId
transactionId
orderingKeys
receipt·result status
authorityEpoch·Revision
projectionId·ViewSequence
payload size class
queue·execution duration
retries·duplicates·rate limits
```

민감한 Payload 전체를 일반 로그에 남기지 않는다.

DM 감사 로그는 의미 Command와 결과를 보여주며 내부 Network Envelope 전체를 노출하지 않는다.

## 29. 테스트 계약

필수 테스트:

### Protocol

- 지원·미지원 Version Negotiation
- 잘못된 Schema와 과도한 Payload
- NaN·무한대·잘못된 ID
- 이전 Connection Epoch 메시지

### Idempotency와 Ordering

- 같은 Command 중복 전송
- Result 유실 후 재전송
- 같은 Key에 다른 Payload
- Sequence 중복·역전·Gap
- 같은 Actor에 동시 Command
- 다중 Ordering Key 교착 방지

### Projection

- Transaction Batch 원자 적용
- 숨겨진 Object Event 비공개
- View Sequence Gap
- Projection Epoch 변경
- Role·Perception 변경 후 새 Projection

### Sync

- 최초 접속
- Retained Event Delta Resume
- Retention 초과 Full Resync
- Snapshot Segment 손상·누락
- Snapshot 적용 중 Live Event Buffer
- Authority Ready 전 Command 거부
- Scene Build 변경 중 재접속

### Failure

- Handler 오류와 Transaction Rollback
- Server Busy와 Rate Limit
- Client가 Event를 소비하지 못함
- Projection Builder 오류
- Presentation Model 로드 실패
- 서버 복구 후 오래된 Resume Token

## 30. 비목표

- 정확한 RemoteEvent Instance 이름을 이 문서에서 고정하지 않는다.
- 일반 사용자에게 임의 Network Message와 Remote 등록 기능을 제공하지 않는다.
- 모든 Authority State를 Client에 복제한 뒤 UI에서만 숨기지 않는다.
- RemoteFunction을 권위 Mutation의 기본 호출 방식으로 사용하지 않는다.
- Transport 암호화를 게임 규칙 검증의 대체물로 취급하지 않는다.
- Client Prediction을 권위 판정으로 사용하지 않는다.
- Scene Streaming Chunk 우선순위와 Interest Management의 전체 알고리즘을 이 문서에서 확정하지 않는다.

## 31. 구현 명세 진입 조건

다음이 명세에서 타입과 모듈 단위로 고정되면 구현을 시작할 수 있다.

1. Protocol Envelope와 각 Lane Message Union
2. Command·Read·Projection Event Registry Schema
3. Connection Session과 Epoch Store
4. Idempotency Store Key와 Retention
5. Ordering Key와 Queue 계약
6. Command Receipt·Result·Error 타입
7. Projection Builder와 Event Batch 타입
8. Snapshot Manifest·Segment·Ack 타입
9. Client Ready State Machine
10. Rate Limit·Budget 기본값과 측정 항목
11. Remote Transport Adapter 경계
12. 중복·Gap·Reconnect·Disclosure 통합 테스트 Fixture
