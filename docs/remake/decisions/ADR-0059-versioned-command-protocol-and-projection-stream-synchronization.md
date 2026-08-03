# ADR-0059. Versioned Command Protocol과 Projection Stream 동기화

- 상태: 확정
- 작성일: 2026-08-03
- 결정 범위: Client Command, Read Request, 권위 Event Projection, 접속·재접속 동기화, Client Ready와 Presentation Signal
- 관련 문서:
  - [`Networking Command, Event와 Client Synchronization 계약`](../architecture/networking-command-event-and-client-synchronization-contract.md)
  - [`Runtime Architecture Principles`](../architecture/runtime-architecture-principles.md)
  - [`Runtime Object System과 Entity Lifecycle 계약`](../architecture/runtime-object-system-and-entity-lifecycle-contract.md)
  - [`저장·세션 복구 모델`](../architecture/persistence-and-session-recovery-model.md)
  - [`캠페인 로비·중도 참여·소유권·제어권`](../systems/session/campaign-lobby-hot-join-ownership-and-control.md)

## 배경

RVTT는 이동, 전투, 상호작용, Scene Editor, 주사위, Prompt, 중도 참여와 서버 복구를 모두 지원해야 한다.

기능별로 RemoteEvent와 Payload를 독립 설계하면 다음 문제가 생긴다.

- 같은 클릭이 재전송되어 피해·이동·아이템 이전이 두 번 적용됨
- 오래된 연결과 UI가 현재 Object에 Command를 보냄
- 서로 다른 Remote 사이의 도착 순서를 규칙 순서로 오인함
- 중도 참여와 재접속마다 전체 Raw State를 무조건 다시 전송함
- Client가 Event 하나를 놓쳐도 잘못된 상태로 계속 플레이함
- 비밀문, 함정과 DM Metadata가 Raw Broadcast로 Player에게 전달됨
- Read Preview와 실제 Mutation이 같은 Handler에서 상태를 변경함
- 서버가 바쁠 때 Queue와 Retry 정책이 기능마다 다름
- Client Version과 Message Schema가 달라도 조용히 실행됨
- Presentation Animation의 손실을 권위 State 손실로 취급함

기존 저장 계약은 AuthorityRevision, Command Journal과 Idempotency를 정의하지만 실제 Network Message, Projection Sequence, Snapshot Catch-up과 Client Ready는 전역 계약이 필요하다.

## 결정

### 1. Roblox Remote는 Transport Adapter로만 사용한다

게임 의미는 Remote 이름과 Instance 계층이 아니라 Versioned Protocol Message가 소유한다.

기능마다 임의 Remote를 추가하지 않고 Command, Read, Authority Projection, Snapshot Sync와 Presentation의 고정 Lane을 사용한다.

정확한 RemoteEvent 이름과 Lane 병합은 구현 명세에서 정할 수 있다.

### 2. Client는 Intent만 보내고 Server가 권위 결과를 계산한다

Client는 선택, 목적지, 대상 후보, 경로 선호, Prompt 응답과 Scene 편집 의도를 보낼 수 있다.

최종 위치, 거리, 명중, 피해, 자원 비용, 대상 적격성, Object State와 권위 ID는 Server가 계산하고 Commit한다.

Client Timestamp와 Prediction은 Presentation에만 사용한다.

### 3. Command와 Read Request를 분리한다

권위 상태를 변경할 수 있는 요청은 Command Registry를 통한다.

상태를 변경하지 않는 Preview, Query와 상세 정보 요청은 Read Request Registry를 통한다.

Read Handler는 Command를 실행하지 않으며, Commit Command는 오래된 Read Result를 그대로 신뢰하지 않고 최신 상태에서 재검증한다.

### 4. 모든 Message는 Versioned Protocol Envelope를 사용한다

Envelope는 Protocol·Schema Version, Message ID, Connection Session, Connection Epoch, Campaign·Session·Scene Context, Sequence와 Correlation 정보를 가진다.

서로 다른 Lane 사이의 도착 순서를 권위 순서로 사용하지 않는다.

호환되지 않는 Client는 게임 Command를 활성화하지 않는다.

### 5. Command는 Request ID, Idempotency Key와 Sequence를 가진다

같은 논리 행동의 재전송은 같은 Idempotency Key를 사용한다.

같은 Key와 같은 정규화 Payload가 다시 오면 기존 Receipt·Result를 재전송한다.

같은 Key에 다른 Payload가 오면 거부한다.

RuntimeObjectId, TransactionId와 AuthorityRevision은 Client가 생성하거나 선택하지 않는다.

### 6. 모든 Command에 전역 Revision 일치를 강제하지 않는다

Command는 자신에게 필요한 타입 있는 Precondition을 가진다.

예:

- Authority Epoch
- Runtime Object Incarnation
- Door State Revision
- Active Turn ID
- Inventory Container Revision
- Control Assignment Revision
- Scene Build ID

Command별 Concurrency Policy는 Strict, Latest Revalidation, Non-conflicting Merge, Append-only 또는 Server Serialization 중 하나를 명시한다.

### 7. Receipt와 Terminal Result를 분리한다

Receipt는 Server가 요청을 수신·Queue했음을 뜻하며 Commit을 뜻하지 않는다.

Terminal Result는 Committed, Rejected, Cancelled, Expired 또는 Superseded를 명시한다.

주사위·Reaction·DM Prompt처럼 여러 입력을 기다리는 실행은 Remote 응답을 열린 채 유지하지 않고 Server Runtime Execution과 후속 Command로 관리한다.

### 8. Server Raw Event가 아니라 사용자별 Projection Stream을 전송한다

Domain Commit은 Projection Builder를 거쳐 Role, Control, Perception, Fog와 Disclosure가 적용된 Client-safe Event가 된다.

숨겨진 함정과 비밀문 Event는 미발견 Player Stream에 포함하지 않는다.

모든 Raw Object와 State를 Broadcast한 뒤 UI에서만 숨기지 않는다.

### 9. Projection Stream은 Epoch와 View Sequence를 가진다

Client는 자신의 `projectionEpoch + viewSequence`를 추적한다.

하나의 Transaction에서 공개되는 변경은 하나의 Event Batch로 원자 적용한다.

Sequence Gap, Epoch 변경과 Integrity 실패가 발생하면 이후 적용과 권위 입력을 일시 정지하고 Catch-up 또는 Snapshot Resync를 수행한다.

### 10. Server 내부 AuthorityRevision과 Client Projection Cursor를 구분한다

AuthorityRevision은 서버의 전체 Commit 순서다.

Player Client는 공개 범위가 필터링된 Projection Cursor를 사용한다. 전역 Raw Event Sequence를 Player에게 제공해 숨겨진 활동을 유추하게 하지 않는다.

Command는 Client Projection Cursor만으로 상태를 신뢰하지 않으며 Server가 최신 권위 상태를 검증한다.

### 11. 최초 접속과 재접속은 Projection Snapshot + Event Catch-up을 사용한다

Client는 Raw Server Snapshot이 아니라 자신에게 공개 가능한 Projection Snapshot Manifest와 Segment를 받는다.

Snapshot을 원자 적용하는 동안 Base View Sequence 이후의 Event를 Buffer하고, Snapshot 적용 후 Catch-up한다.

같은 Authority Epoch와 Projection Policy이며 Event가 Retention Window 안에 있으면 Delta Resume를 허용한다.

Epoch·Role·Scene Build 변경, Retention 초과와 Integrity 실패 시 Full Projection Resync를 사용한다.

### 12. Client Ready는 기술 상태 기계다

Lobby의 사용자 Ready와 Network Ready를 분리한다.

```text
connected
→ protocol_ready
→ projection_syncing
→ projection_catching_up
→ authority_ready
→ presentation_ready
→ gameplay_ready
```

Command는 자신의 Readiness Scope가 충족되기 전에는 실행하지 않는다.

Client의 Ready 주장만 신뢰하지 않고 Server가 Segment Ack, Projection Cursor와 Role을 확인한다.

### 13. Connection Epoch로 이전 연결을 무효화한다

재접속이나 새 Client Session이 기존 연결을 대체하면 Connection Epoch를 증가시킨다.

이전 Epoch의 Command, Ready와 Read 응답은 현재 상태에 적용하지 않는다.

Authority Rollback과 서버 복구는 별도의 Authority Epoch로 오래된 권위 참조를 무효화한다.

### 14. Command Ordering은 타입 있는 Ordering Key를 사용한다

모든 Command를 하나의 전역 Queue에 넣지 않는다.

Actor, Object, Inventory, Encounter, Scene Authoring과 Campaign Admin 같은 Ordering Key별로 충돌 Command를 직렬화한다.

다중 Key Command는 안정적인 Key 순서로 Reservation을 획득한다.

최종 Mutation 순서는 Transaction Commit과 AuthorityRevision이 결정한다.

### 15. 권위 Event와 Presentation Signal을 분리한다

HP, Object State, 이동 Checkpoint, 이동 완료·중단과 Roll 공개 상태는 Authority Projection이다.

토큰 보간 Sample, VFX, Camera Cue와 주사위 Animation 시작은 Presentation Signal이다.

Presentation Signal은 병합·만료할 수 있으며 손실되어도 Snapshot과 Projection으로 현재 권위 상태를 복구한다.

### 16. Rate Limit, Payload Budget와 Backpressure를 공통 적용한다

사용자, Connection, Message Type, Actor·Object Scope, Payload Size와 Compute Budget별 상한을 둔다.

권위 Event를 조용히 버리지 않는다. Client가 따라오지 못하면 Catch-up 또는 Snapshot Resync로 전환한다.

Presentation Signal만 의미가 유지되는 범위에서 병합·만료할 수 있다.

### 17. Network Error는 구조화되고 비밀을 누출하지 않는다

Error는 Code, Category, Retryable, Resync Required, User Message Key, Retry After와 Trace ID를 가진다.

Raw Stack Trace, 내부 Module 경로, 숨겨진 Object ID와 DM 전용 상태를 Client에 반환하지 않는다.

### 18. RemoteFunction을 권위 Mutation의 기본 방식으로 사용하지 않는다

권위 Command는 비동기 Receipt·Result와 Projection을 사용한다.

장기 실행, 재접속과 중복 처리 상태를 하나의 동기 호출 Stack에 의존하지 않는다.

## 결과

- 모든 기능이 같은 Command, Read, Result와 Error 계약을 사용한다.
- 재전송과 Result 유실에도 권위 Mutation이 한 번만 적용된다.
- 오래된 Connection과 Object Ref가 안전하게 실패한다.
- 중도 참여와 재접속이 Snapshot Segment와 Event Catch-up으로 일관되게 동작한다.
- Player가 숨겨진 Raw Event와 Object State를 받지 않는다.
- Authority State와 Presentation Animation의 신뢰 수준이 분리된다.
- Scene Editor, 이동, 전투, 상호작용과 Inventory가 같은 Rate·Ordering·Audit 기반을 공유한다.
- Protocol과 Schema Migration을 기능별 Remote 교체 없이 관리할 수 있다.

## 비용과 주의점

- Protocol·Command·Projection Registry와 Schema 검증기가 필요하다.
- Idempotency Result Cache, Ordering Coordinator와 Projection Event Retention이 필요하다.
- 사용자별 Projection Snapshot과 Event Stream 생성 비용을 관리해야 한다.
- Client는 Event Batch 원자 적용, Gap 검출과 Snapshot Rebase를 구현해야 한다.
- 숨겨진 정보 공개 변화 시 Projection Stream 재생성과 Resync가 필요할 수 있다.
- Command Handler는 기존 직접 Remote 호출과 Workspace Mutation을 제거해야 한다.

## 비목표

- 정확한 RemoteEvent Instance 이름과 개수를 이 ADR에서 고정하지 않는다.
- Scene Streaming Interest Management와 Chunk 우선순위 전체를 결정하지 않는다.
- Transport 자체의 보안이 Server Rules 검증을 대체한다고 보지 않는다.
- 일반 사용자에게 임의 Protocol Message, Remote와 Command Handler 등록 기능을 제공하지 않는다.
- Client Prediction으로 권위 결과를 확정하지 않는다.
