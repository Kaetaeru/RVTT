# Implementation Spec: Core Authority Identity, Version과 Result 계약

- 상태: 초안
- 문서 종류: Implementation Spec
- 구현 상태: 미구현
- 즉시 구현 가능성: BLOCKED
- 작성일: 2026-08-05
- 최종 검토일: 2026-08-05
- 차단 이유:
  - 현재 GitHub 코드 검색과 제공된 Repository 조회에서 실제 Production Module·Schema·Test 트리를 확인하지 못했다.
  - 기존 구현 재사용·대체 범위와 실제 파일 경로를 확인하기 전에는 `준비 완료`로 전환할 수 없다.
- 관련 Quick Flow 구간:
  - [`한눈에 보는 세션 흐름`](../../user-guides/QUICK-FLOW.md) — 세션 참가, 장면 입장, 탐험 이동, 재접속
- 관련 User Guide:
  - [`Player Guide`](../../user-guides/player/README.md) — 빠른 시작, Character와 Token, Control, 동기화와 재접속
  - [`DM Guide`](../../user-guides/dm/README.md) — 세션 전 준비, Lobby와 세션 시작, Player Ready와 Client Ready
- 관련 Main System Guide:
  - [`Runtime Foundation과 Authority`](../../guides/runtime/README.md)
  - [`Session, Networking, Persistence와 Recovery`](../../guides/session/README.md)
- 관련 Product·Architecture·System·UI:
  - [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md)
  - [`Compiled Build와 Authoritative State 분리 패턴`](../../architecture/compiled-build-and-authoritative-state-pattern.md)
  - [`Networking Command, Event와 Client Synchronization`](../../architecture/networking-command-event-and-client-synchronization-contract.md)
  - [`Command Ordering, Logical Time와 Transaction Coordinator`](../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)
  - [`Domain Event, Outbox, Subscription과 Projection`](../../architecture/domain-event-outbox-subscription-and-projection-runtime-contract.md)
  - [`Persistence, Snapshot, Journal과 Recovery`](../../architecture/persistence-and-session-recovery-model.md)
  - [`Diagnostics, Observability, Correlated Trace와 Incident`](../../architecture/diagnostics-observability-correlated-trace-and-incident-runtime-contract.md)
  - [`Deterministic Simulation, Scenario와 Test Harness`](../../architecture/deterministic-simulation-scenario-and-test-harness-runtime-contract.md)
- 관련 ADR:
  - [`ADR-0054`](../../decisions/ADR-0054-compiled-semantic-runtime-and-query-authority-principles.md)
  - [`ADR-0058`](../../decisions/ADR-0058-stable-runtime-object-identity-and-command-driven-lifecycle.md)
  - [`ADR-0059`](../../decisions/ADR-0059-versioned-command-protocol-and-projection-stream-synchronization.md)
  - [`ADR-0062`](../../decisions/ADR-0062-ordered-reservations-and-atomic-authority-transactions.md)
  - [`ADR-0063`](../../decisions/ADR-0063-manifest-chunk-snapshots-commit-journal-and-branch-recovery.md)
  - [`ADR-0064`](../../decisions/ADR-0064-immutable-compiled-builds-and-versioned-authoritative-state.md)
  - [`ADR-0077`](../../decisions/ADR-0077-transactional-domain-events-with-outbox-and-projection-boundaries.md)
  - [`ADR-0083`](../../decisions/ADR-0083-projection-driven-ui-runtime-and-epoch-safe-client-recovery.md)
  - [`ADR-0084`](../../decisions/ADR-0084-correlated-authority-traces-and-permission-aware-observability.md)
  - [`ADR-0085`](../../decisions/ADR-0085-production-parity-deterministic-scenarios-and-controlled-nondeterminism.md)
- 선행 명세: 없음
- 후속 명세:
  - `../networking/001-command-projection-and-resync-protocol.md`
  - `../session/001-campaign-join-character-selection-and-ready.md`
  - `../scene/001-scene-entry-essential-and-controlled-actor-bootstrap.md`
  - `../exploration/001-click-movement-plan-execution-and-reconciliation.md`
  - `../persistence/001-first-slice-snapshot-journal-and-reconnect.md`
- 대체하는 명세: 없음
- 대체된 명세: 없음

> 이 Spec은 First Session Walking Skeleton에 필요한 공통 Identity·Version·Epoch·Revision·Result·Error 계약만 정의한다. 전체 Runtime을 미리 구현하는 범용 Framework가 아니다.

## 1. 목표와 사용자 결과

### 목표

세션 참가, Character 선택, Scene 입장, 클릭 이동과 재접속이 같은 권위 Identity와 Version 규칙을 사용하도록 최소 공통 계약을 정의한다.

이 Spec 자체가 화면 기능을 완성하지는 않는다. 후속 Spec이 다음을 일관되게 구현할 수 있는 기반을 제공한다.

- 오래된 연결이나 Rollback 이전 입력 거부
- 같은 Command 재전송의 동일 결과 확인
- Character, Actor, Runtime Object와 Scene Build 참조 구분
- Commit된 Authority Revision과 Client Projection Cursor 구분
- 사용자 오류 메시지와 내부 진단 정보 분리
- 저장·복구·Migration에서 Stable Identity 유지

### Player Acceptance Flow

```text
세션 참가 요청
→ 현재 Connection Epoch와 Authority Epoch가 확인됨
→ 허용된 Character·Actor Ref가 안전하게 전달됨
→ 이동 결과가 Authority Revision으로 확정됨
→ 재접속 후 이전 Connection 입력은 거부됨
→ 현재 Epoch·Revision의 상태로 복귀함
```

### DM Acceptance Flow

```text
Player 참가·Control 상태 확인
→ 현재 Campaign·Session·Scene·Actor Identity 확인
→ Player 이동 Commit 확인
→ Disconnect·Reconnect 발생
→ 이전 연결과 현재 연결이 구분됨
→ 동일 권위 Character·Actor 상태가 유지됨
```

### 성공 기준

- Stable ID가 표시 이름, 배열 위치, Instance 경로나 Client가 생성한 임시 ID에 의존하지 않는다.
- `AuthorityEpoch`, `ConnectionEpoch`, `AuthorityRevision`, Domain Revision과 Projection Cursor가 서로 다른 의미로 유지된다.
- 모든 공개 실패는 Stable Error Code와 사용자 Message Key를 가진다.
- 내부 Diagnostic Context가 Player에게 그대로 노출되지 않는다.
- 직렬화된 Identity·Version 값이 Snapshot·Journal·Network에서 같은 의미를 가진다.

## 2. 범위와 비범위

### 이번 Spec 범위

- First Slice가 공유하는 Identity Type 규칙
- Authority·Connection Epoch
- 전역 Authority Revision과 Domain Revision Token
- Schema·Protocol·Content·Build Version Ref의 공통 표현
- Authority Object Ref의 최소 Header
- Generic `Result<T, E>`와 Stable Error 계약
- Error Definition Registry의 최소 책임
- ID·Version·Error의 직렬화·Migration 규칙
- Trace·Support Reference 연결
- Deterministic ID Factory와 Test Fixture 요구

### 비범위

- 실제 Command Envelope와 Message Lane
- Command Receipt·Terminal Result의 전체 Network Schema
- Campaign Membership·Role·Owner·Control State
- Scene Build·Runtime Object Component Schema
- Navigation Plan과 Movement Command
- Persistence Manifest·Chunk 전체 Schema
- RuleExecution·Recipe·Step Identity
- 최종 Roblox Module·Remote·DataStore 경로
- 모든 미래 Domain의 ID 목록

### 종료 경계

이 Spec 완료 시 후속 Spec은 공통 Identity와 오류 의미를 다시 정의하지 않고, 자신의 Domain Payload와 상태 전이만 추가할 수 있다.

## 3. 근거와 추적성

| 요구사항 | Quick Flow·User Guide | 직접 권위 문서 | 구현 계약 | 검증 항목 |
|---|---|---|---|---|
| 재접속 후 이전 연결 입력 거부 | Quick Flow §7, Player 빠른 시작 | Networking, Session Guide | `ConnectionEpoch` | 이전 Epoch Command 거부 |
| Rollback·Recovery 후 이전 Timeline 거부 | Player·DM Recovery | Persistence, Transaction | `AuthorityEpoch` | 새 Epoch에서 오래된 Ref 거부 |
| Commit 순서 확인 | 이동 결과·현재 상태 복귀 | Transaction, Event Runtime | `AuthorityRevision` | Commit마다 단조 증가 |
| Domain 국소 충돌 검증 | Token 위치·Control 상태 | Transaction Coordinator | `RevisionToken` | stale revision 거부 |
| Character·Token 구분 | Player Guide Character와 Token | Runtime Principles, Runtime Object 계약 | Kind별 Stable ID와 Ref | CharacterId와 ActorId 혼용 거부 |
| 사용자 오류와 내부 진단 분리 | Loading·Denied·Resync | Diagnostics Runtime | Stable Error + Message Key + Support Ref | 비밀 Context 미노출 |
| 같은 Scenario 재현 | 첫 Slice Test | Simulation Harness | Deterministic ID Factory | 같은 Seed Plan의 동일 ID Sequence |

## 4. 현재 구조 조사

### 확인 결과

- `planning/rvtt-remake` Branch에서 문서와 Validation Workflow는 확인했다.
- GitHub Repository 코드 검색에서 `ServerMain`, `TokenManager`, `RemoteEvent` 구현 파일이 확인되지 않았다.
- 일반 Rojo 진입점으로 추정할 수 있는 `default.project.json`도 해당 Branch에서 확인되지 않았다.
- 따라서 Production Source Tree가 아직 Repository에 없거나, GitHub 코드 검색으로 접근할 수 없는 별도 위치에 존재할 가능성을 구분할 수 없다.

### 현재 판정

```text
Existing Production Module Reuse
→ UNRESOLVED

Greenfield Source Layout
→ NOT YET CONFIRMED

Final Module Path
→ MUST NOT BE FIXED
```

### 준비 완료 전 추가 조사

- 실제 Roblox Place·Source 동기화 방식
- Server·Client·Shared Module 위치
- 기존 ID·Result·Error·Remote Registry
- 기존 Persistence Schema와 Migration
- 기존 Test Runner·Fixture·Diagnostics
- Legacy Token·Session·Permission Manager 재사용 여부

## 5. 전체 실행 흐름

이 Spec이 제공하는 값은 다음 전체 흐름에서 사용된다.

```text
Client Interaction
→ ConnectionSessionId·ConnectionEpoch
→ CommandId·IdempotencyKey
→ Authority Ref·Expected Revision
→ Server Validation
→ TransactionId·AuthorityRevision
→ Domain EventId
→ ProjectionId·Projection Cursor
→ User Result·Support Reference
```

### 정상 흐름

1. 서버가 Connection Session과 Epoch를 발급한다.
2. Client는 후속 Network Spec이 정의한 Envelope에 현재 Connection 식별자를 포함한다.
3. Server는 사용자 입력의 Domain Ref와 Expected Revision을 검증한다.
4. 성공한 Transaction은 새 Authority Revision을 발급한다.
5. Commit된 Event와 Projection은 같은 Authority Epoch·Revision을 참조한다.
6. 사용자 Result는 Stable Error 또는 성공 Summary와 Projection Expectation을 제공한다.

### 대기·재개 흐름

- 대기 중인 Session·Scene·Command는 생성 당시 Authority Epoch와 관련 Incarnation·Revision을 유지한다.
- 재개 시 현재 Epoch와 Ref를 재검증한다.
- Connection만 바뀌고 Authority Branch가 같다면 새 Connection Epoch로 재연결할 수 있다.

### 취소 흐름

- Client가 생성한 임시 Interaction ID를 취소할 수 있으나 Server가 발급한 Authority ID를 삭제하거나 재사용하지 않는다.
- Commit되지 않은 요청 취소와 Commit된 결과 Rollback을 같은 동작으로 처리하지 않는다.

### 재접속·복구 흐름

```text
Reconnect
→ 새 ConnectionEpoch
→ 현재 AuthorityEpoch 확인
→ 같은 Branch면 Cursor·Result Resume 후보 검사
→ Epoch가 다르면 기존 Ref·Prompt·Prediction 폐기
→ Full Resync
```

## 6. 상태와 전이

이 Spec은 Domain State Machine을 소유하지 않는다. Epoch와 Version의 유효성 전이만 정의한다.

```text
Connection Epoch N active
→ 새 연결 승인
→ Connection Epoch N+1 active
→ Epoch N message stale
```

```text
Authority Epoch A active
→ Recovery 또는 Rollback Commit
→ Authority Epoch B active
→ Epoch A command·ref·subscriber stale
```

```text
Schema Version V
→ Migration Validation
→ Schema Version V+1
→ 실패 시 Last Known Good V 유지
```

## 7. 책임과 권위 경계

| 영역 | 소유 책임 | 변경 가능한 값 | 소유하지 않는 책임 |
|---|---|---|---|
| Client | 로컬 Interaction·Prediction ID, 마지막 Projection Cursor 보관 | 자신의 비권위 UI 상태 | Authority ID·Revision·Epoch 발급 |
| Network Adapter | Envelope 직렬화·역직렬화 | Transport Sequence | Authority 순서와 Domain 결과 |
| Server Runtime | Authority ID·Epoch·Revision 발급과 검증 | 권위 Identity State | UI 문자열과 Presentation |
| Domain Service | 자신의 Stable ID·Domain Revision 의미 | 자신의 Mutation Proposal | 전역 Authority Revision 발급 |
| Transaction Coordinator | Transaction ID와 Commit Revision | Authority Revision·Commit 결과 | Domain 규칙 의미 |
| Persistence | Identity·Version 직렬화와 복구 | Snapshot·Journal Record | 새 Domain ID 의미 발명 |
| Diagnostics | Trace·Support Ref 연결 | 비권위 Observation | Gameplay Result 변경 |
| DM | 승인된 관리 Command 제출 | Command가 허용한 관리 상태 | 직접 Epoch·Revision 조작 |

### 고정 분리

```text
Source ID
≠ Compiled Build ID
≠ Runtime Presence ID
≠ Persistent Domain ID
≠ Projection ID
≠ Presentation ID
```

```text
AuthorityRevision
≠ Domain Revision
≠ Projection Sequence
≠ Client Command Sequence
≠ Wall Clock Time
```

## 8. 데이터와 Type 계약

### 8.1 Scalar 규칙

- Stable ID는 UTF-8 표시 문자열이나 파일 경로가 아니라 불투명한 ASCII ID 값이다.
- ID의 구체 생성 방식은 Deterministic ID Factory와 Production ID Factory가 같은 Interface를 구현한다.
- Epoch·Revision·Schema Version은 음수가 아닌 정수다.
- `0`의 의미는 각 Type Definition이 명시하며, `nil`과 혼용하지 않는다.
- Client가 보낸 ID는 존재·Kind·Scope·Epoch·Incarnation을 Server가 다시 검증한다.

### 8.2 기본 Type

```lua
export type StableId = string
export type AuthorityEpoch = number
export type AuthorityRevision = number
export type ConnectionEpoch = number
export type SchemaVersion = number
export type ProtocolVersion = number
export type DomainRevision = number
```

구현에서는 정수 검증을 강제한다. Luau의 `number` Type 자체가 정수를 보장한다고 가정하지 않는다.

### 8.3 Domain ID Alias

첫 Slice 최소 Alias:

```lua
export type CampaignId = StableId
export type SessionId = StableId
export type ConnectionSessionId = StableId
export type CharacterId = StableId
export type ActorId = StableId
export type SceneId = StableId
export type SceneBuildId = StableId
export type RuntimeObjectId = StableId
export type ControlAssignmentId = StableId
export type CommandId = StableId
export type TransactionId = StableId
export type EventId = StableId
export type ProjectionId = StableId
export type TraceId = StableId
export type SupportReference = StableId
```

Alias가 같은 Runtime Representation을 사용하더라도 Validator와 API는 `kind`를 확인해 혼용을 거부한다.

### 8.4 Authority Ref Header

```lua
export type AuthorityRef = {
    kind: string,
    id: StableId,
    authorityEpoch: AuthorityEpoch,
    incarnation: number?,
    expectedRevision: DomainRevision?,
}
```

규칙:

- `kind`는 등록된 Ref Kind다.
- Runtime Presence는 `incarnation`을 요구한다.
- Revision 충돌 검증이 필요한 Command는 `expectedRevision`을 요구한다.
- Character처럼 영구 Domain Identity와 Scene Actor Presence를 같은 Ref로 대체하지 않는다.
- `AuthorityRef`를 Persistence의 완전한 Domain Record로 사용하지 않는다.

### 8.5 Version Ref

```lua
export type VersionRef = {
    kind: string,
    id: StableId,
    version: string,
    contentHash: string?,
}

export type RuntimeVersionSetRef = {
    schemaVersion: SchemaVersion,
    rulesetSnapshotRef: VersionRef?,
    policySnapshotRefs: {VersionRef},
    buildRefs: {VersionRef},
    registryVersionRefs: {VersionRef},
}
```

First Slice는 필요한 Ref만 채운다. 빈 문자열을 `없음`으로 사용하지 않는다.

### 8.6 Revision Token

```lua
export type RevisionToken = {
    authorityEpoch: AuthorityEpoch,
    authorityRevisionObserved: AuthorityRevision,
    domainKind: string,
    domainId: StableId,
    domainRevision: DomainRevision,
    incarnation: number?,
}
```

`authorityRevisionObserved`는 Token을 만든 시점을 설명하며 Domain Revision을 대신하지 않는다.

### 8.7 Generic Result

```lua
export type Result<T, E> =
    { ok: true, value: T }
    | { ok: false, error: E }
```

성공 결과와 실패를 `nil` 하나로 표현하지 않는다.

### 8.8 Stable Error

```lua
export type RetryClass =
    "never"
    | "same_request"
    | "new_request_after_sync"
    | "automatic_backoff"
    | "dm_action_required"
    | "support_required"

export type ErrorCategory =
    "validation"
    | "authorization"
    | "readiness"
    | "conflict"
    | "stale_reference"
    | "rate_limit"
    | "unavailable"
    | "integrity"
    | "internal"

export type StableError = {
    code: string,
    schemaVersion: SchemaVersion,
    category: ErrorCategory,
    retryClass: RetryClass,
    userMessageKey: string,
    supportReference: SupportReference?,
    traceId: TraceId?,
    safeVariables: {[string]: string | number | boolean}?,
}
```

서버 전용 Diagnostic Record는 별도 Type을 사용한다.

```lua
export type InternalDiagnosticContext = {
    traceId: TraceId,
    errorCode: string,
    authorityEpoch: AuthorityEpoch,
    authorityRevision: AuthorityRevision?,
    refs: {AuthorityRef},
    internalMessage: string,
    stackFingerprint: string?,
    secretContext: unknown?,
}
```

`internalMessage`, Stack과 `secretContext`를 Client Error Payload에 넣지 않는다.

## 9. Command·Read·Network 계약

전체 Network Envelope는 후속 `networking/001`이 소유한다.

이 Spec이 Network에 요구하는 공통 필드:

| 필드 | 발급자 | 용도 | Client 신뢰 여부 |
|---|---|---|---|
| `connectionSessionId` | Server | 현재 연결 Scope | 제출값 재검증 |
| `connectionEpoch` | Server | 이전 연결 무효화 | 제출값 재검증 |
| `authorityEpoch` | Server | 현재 권위 Branch | Client 생성 금지 |
| `messageId` | 송신 측 | 전송 추적 | 권위 ID 아님 |
| `correlationId` | Server 또는 검증된 연결 | 흐름 연결 | Authority 결과 아님 |
| `traceId` | Server | Correlated Trace | Client가 확정하지 못함 |
| `requestId` | Client Connection Scope | 요청·응답 연결 | Authority ID 아님 |
| `idempotencyKey` | Client 논리 행동 | 중복 요청 검출 | Object ID로 사용 금지 |

후속 Spec은 Receipt와 Terminal Result를 분리해야 한다.

## 10. Registry·Module 책임

실제 Source Tree 확인 전 다음 경로는 모두 `신규 제안`이다.

```text
Shared/CoreAuthorityTypes
Shared/VersionTypes
Shared/ResultTypes
Shared/ErrorDefinitions
Server/CoreAuthority/AuthorityClock
Server/CoreAuthority/IdentityFactory
Server/CoreAuthority/ErrorRegistry
Server/CoreAuthority/ReferenceValidator
TestSupport/DeterministicIdentityFactory
```

| 제안 Package | 책임 | 공개 계약 | 소유하지 않는 책임 |
|---|---|---|---|
| CoreAuthorityTypes | 공통 Type Alias와 Ref Header | 직렬화 가능한 Type | ID 생성·검증 실행 |
| AuthorityClock | 현재 Epoch·Revision 조회, Commit Revision 발급 | 단조 증가 Authority Revision | Wall Clock·Game Time |
| IdentityFactory | Server Authority ID 생성 | Kind별 ID 생성 | Domain Record 저장 |
| ErrorRegistry | Stable Error Definition 조회 | Code→Definition | 사용자 UI Rendering |
| ReferenceValidator | Kind·Scope·Epoch·Incarnation·Revision 검증 | Typed Validation Result | Domain 적격성 계산 |
| DeterministicIdentityFactory | Scenario 입력에 따른 ID 생성 | Production Interface 호환 | Test-only Store Mutation |

### Error Definition Registry

```lua
export type ErrorDefinition = {
    code: string,
    schemaVersion: SchemaVersion,
    category: ErrorCategory,
    defaultRetryClass: RetryClass,
    userMessageKey: string,
    disclosureClass: string,
}
```

Registry는 Trusted Code에서 등록하고 Runtime 활성 전 Freeze한다.

## 11. Transaction·Ordering·Event·Projection

이 Spec은 Transaction을 실행하지 않는다.

공통 불변식:

```text
Transaction Commit
→ AuthorityRevision 발급
→ Journal·Domain Event Outbox에 같은 Epoch·Revision 기록
→ Projection이 같은 또는 이후 Revision을 참조
```

- Commit 전 Authority Revision을 외부에 성공 결과로 공개하지 않는다.
- Abort된 Transaction은 새 Authority Revision을 사용한 것으로 노출하지 않는다.
- Domain Event Ordering은 Epoch→Revision→Event Index를 사용한다.
- Projection Cursor를 Authority Revision으로 재사용하지 않는다.
- Subscriber와 Presentation이 Revision을 새로 발급하지 않는다.

## 12. Persistence·Migration·Rollback

### 저장 원본

저장 대상:

- Stable Domain ID
- Authority Epoch와 현재 Authority Revision
- Branch ID
- Schema·Content·Build·Registry Version Ref
- Domain Record의 Incarnation·Revision
- Commit Journal의 Transaction·Event Identity

저장하지 않는 파생값:

- Client Projection ID Cache
- Local Prediction ID
- Roblox Instance 경로와 주소
- UI Component ID
- Tween·VFX·Camera State

### Migration

- Serialized Type은 `schemaVersion`을 가진다.
- Migration은 `(typeId, fromVersion, toVersion)`으로 등록한다.
- Migration은 반복 실행해도 같은 결과를 내거나 이미 완료 상태를 인식한다.
- ID를 표시 이름으로 다시 생성하지 않는다.
- Stable ID 의미가 바뀌면 묵시적 변환 대신 새 Kind 또는 명시적 Mapping을 사용한다.
- 실패 시 Last Known Good Snapshot·Schema를 유지한다.

### Reconnect·Recovery

- Reconnect는 Connection Epoch를 변경하지만 같은 Authority Branch를 유지할 수 있다.
- Server Recovery는 새 Authority Epoch를 발급한다.
- Recovery 후 Derived Projection·Index는 재생성한다.
- 이전 Epoch Ref, Prompt, Subscriber와 Delayed Task를 거부한다.

### Rollback

- 선택 Snapshot을 새 Branch·Authority Epoch에서 복원한다.
- Stable Domain ID는 Snapshot 의미에 따라 복원되지만 Runtime Presence Incarnation은 복구 정책을 따른다.
- Rollback 이전 Projection·Command·Prediction ID를 현재 권위 Ref로 승격하지 않는다.

## 13. UI·입력·현지화

| 사용자 상태 | 화면 표시 요구 | 허용 입력 | 복구 안내 |
|---|---|---|---|
| Stale Connection | 이전 연결 만료 | 새 권위 Command 금지 | 재접속 진행 표시 |
| Stale Authority Epoch | 현재 상태가 교체됨 | 로컬 Prompt·Prediction 폐기 | Full Resync 표시 |
| Stale Revision | 대상이 변경됨 | 자동 재실행 금지 | 최신 상태 확인 후 재시도 |
| Unsupported Version | Client·Server Version 불일치 | Gameplay 입력 금지 | Update 또는 재접속 안내 |
| Internal Failure | 안전한 일반 오류 | 중복 제출 제한 | Support Reference 표시 |

- 사용자 문자열은 `userMessageKey`와 안전한 변수로 표시한다.
- Error Code를 그대로 기술 메시지로 보여 주지 않는다.
- DM과 Developer Diagnostic View도 Disclosure Policy를 거친다.
- Q·E·1–5의 실제 Context 의미는 후속 UI·Session Spec이 소유한다.

## 14. 실패·동시성·취소

| 상황 | 검출 위치 | 사용자 결과 | Authority 안전 상태 | Retry·Recovery |
|---|---|---|---|---|
| 잘못된 ID 형식 | Ingress Validator | 구조화된 거부 | 변경 없음 | 새 요청 |
| Kind 불일치 | Reference Validator | 대상이 올바르지 않음 | 변경 없음 | UI 최신화 |
| 오래된 Connection Epoch | Network Ingress | 연결 만료 | 변경 없음 | Reconnect |
| 오래된 Authority Epoch | Authority Gate | 상태 교체 안내 | 변경 없음 | Full Resync |
| 오래된 Incarnation | Reference Resolver | 대상이 더 이상 유효하지 않음 | 변경 없음 | 최신 Projection |
| Revision 충돌 | Domain Validation | 변경된 대상 안내 | Transaction 미Commit | 최신 상태 후 재시도 |
| 중복 ID 생성 | Identity Factory | 내부 실패 | ID 미사용 | Incident·Retry |
| Error Definition 누락 | Error Adapter | 일반 안전 오류 | Gameplay 실패 경계 유지 | Health Degraded |
| Migration 실패 | Persistence Loader | 세션 시작 차단 | Last Known Good 유지 | DM Recovery Review |

## 15. Diagnostics·Budget·Health

### Trace

Identity 관련 표준 Span:

```text
identity.issue
reference.validate
revision.precondition_check
epoch.reject_stale
schema.migrate
error.map_public
```

모든 Span은 가능한 범위에서 다음을 연결한다.

- traceId
- authorityEpoch
- authorityRevision
- connectionSessionId·connectionEpoch
- ref kind와 ID의 안전한 축약 또는 Hash
- errorCode

비밀 Object ID와 Raw Payload를 Player Diagnostic에 포함하지 않는다.

### Stable Error Code

첫 Slice Foundation 오류:

```text
IDENTITY_FORMAT_INVALID
IDENTITY_KIND_MISMATCH
IDENTITY_DUPLICATE_ISSUE
REFERENCE_NOT_FOUND
REFERENCE_INCARCERATION_STALE
REFERENCE_REVISION_STALE
CONNECTION_EPOCH_STALE
AUTHORITY_EPOCH_STALE
SCHEMA_VERSION_UNSUPPORTED
SCHEMA_MIGRATION_FAILED
ERROR_DEFINITION_MISSING
```

`REFERENCE_INCARCERATION_STALE`의 최종 영문 표기는 구현 전 용어 검토에서 `INCARNATION`으로 고정해야 한다. 현재 오타 가능성이 있으므로 준비 완료 전 Error Catalog Review 항목으로 남긴다.

### Budget와 측정

수치를 지금 확정하지 않는다.

측정 대상:

- ID 발급 처리량과 Allocation
- Ref Validation 시간
- Error Registry 조회 시간
- Serialized Ref 평균·최대 Byte
- Migration Record 수와 처리 시간
- Diagnostic Span 생성 비용

기준 Scenario는 First Slice Testing Spec에서 정의한다.

### Health Probe

```text
Ready
→ Identity Factory·Authority Clock·Error Registry·Migration Registry 정상

Degraded
→ Optional Diagnostic Export 또는 비핵심 Error Localization 일부 실패

Blocked
→ Authority Clock·Identity Factory·필수 Error Registry·필수 Migration 불가
```

## 16. 구현 순서

### 단계 0 — 실제 Repository 기준선 조사

```text
단계 목표: Production Source Tree와 기존 공통 계약 확인
변경 책임: 없음 또는 조사 기록
선행 조건: Repository·Place Source 접근
완성되는 실제 흐름: 기존 재사용·대체 대상 확정
검증 방법: 파일·Module·Schema·Test 목록과 호출자 기록
실패 시 안전 상태: Spec 초안 유지
완료 기준: 최종 Module 경로를 추측하지 않아도 됨
```

### 단계 1 — Type·Validator 최소 기반

```text
단계 목표: First Slice 공통 ID·Epoch·Revision·Result Type과 Validator
변경 책임: Shared Type, Server Validator, Unit Test
선행 조건: 단계 0
완성되는 실제 흐름: 잘못된 Ref와 Stale Epoch를 Domain 진입 전 거부
검증 방법: Type·Schema·Validator Unit Test
실패 시 안전 상태: Gameplay Command 미활성
완료 기준: Client 입력이 Authority Ref로 바로 사용되지 않음
```

### 단계 2 — Authority Clock·Identity Factory

```text
단계 목표: Server Authority ID와 Commit Revision 발급
변경 책임: Server Runtime, Deterministic Adapter
선행 조건: 단계 1
완성되는 실제 흐름: Transaction과 Scenario가 동일 Interface 사용
검증 방법: 중복·재시작·결정성 Test
실패 시 안전 상태: 새 Commit 차단
완료 기준: ID·Revision이 Client·Wall Clock·Frame 순서에 의존하지 않음
```

### 단계 3 — Error Registry·Public Adapter

```text
단계 목표: Stable Error와 사용자 Message·Support Reference 분리
변경 책임: Error Registry, Diagnostic Adapter, Localization Contract
선행 조건: 단계 1
완성되는 실제 흐름: 같은 실패가 Server·Client·Support에서 같은 Code로 연결
검증 방법: Redaction·Missing Definition·Localization Test
실패 시 안전 상태: 내부 Context 미노출 일반 오류
완료 기준: Player Payload에 Stack·Secret Context 없음
```

### 단계 4 — Persistence·Migration Adapter

```text
단계 목표: Identity·Version·Epoch 직렬화와 Migration
변경 책임: Serializer, Migration Registry, Recovery Loader
선행 조건: 단계 1·2
완성되는 실제 흐름: Snapshot·Journal에서 Ref 의미 유지
검증 방법: Round-trip·Version Upgrade·Failure Test
실패 시 안전 상태: Last Known Good 유지, Session Gate 차단
완료 기준: 표시 이름·Instance 경로로 ID 재생성하지 않음
```

## 17. Test 계획

| ID | 범주 | Scenario | 방식 | 예상 결과 |
|---|---|---|---|---|
| RT001-01 | 정상 | Kind별 ID 발급과 Ref Round-trip | Unit | 동일 Kind·ID·Epoch 유지 |
| RT001-02 | 검증 | CharacterId를 Actor Ref로 제출 | Unit | `IDENTITY_KIND_MISMATCH` |
| RT001-03 | Epoch | 이전 Connection Epoch 요청 | Integration | 상태 변경 없이 거부 |
| RT001-04 | Epoch | Rollback 이전 Authority Epoch Ref | Deterministic | Full Resync 요구, Mutation 없음 |
| RT001-05 | Revision | 이동 전 위치 Revision이 stale | Integration | Transaction 미Commit |
| RT001-06 | 중복 | 같은 Seed·Schedule의 ID 발급 | Deterministic | 같은 ID Sequence |
| RT001-07 | 동시성 | 병렬 ID 발급 | Bounded Interleaving | 중복 ID 없음 |
| RT001-08 | Migration | Schema V1→V2 반복 실행 | Integration | 동일 결과 또는 완료 인식 |
| RT001-09 | 장애 | 필수 Migration 실패 | Fault Injection | Last Known Good, Session Blocked |
| RT001-10 | 정보 누출 | 비밀 Ref가 Public Error Context에 포함 | Negative Disclosure | Ref·Payload 미노출 |
| RT001-11 | Error | 등록되지 않은 Error Code | Unit | 안전한 Internal Failure + Health Degraded |
| RT001-12 | Roblox | Client가 Instance 경로를 Ref로 제출 | Roblox Integration | Schema 거부 |

## 18. 완료 기준

- [ ] 실제 Repository Code·Schema·Test 기준선이 기록됐다.
- [ ] Stable ID와 Kind Validator가 존재한다.
- [ ] AuthorityEpoch·ConnectionEpoch·AuthorityRevision·DomainRevision이 분리된다.
- [ ] Runtime Presence Incarnation과 Persistent Domain Identity가 분리된다.
- [ ] Result와 Stable Error가 nil·자유 문자열 오류를 대체한다.
- [ ] 사용자 Error와 Internal Diagnostic Context가 분리된다.
- [ ] Identity·Version Type이 Network·Persistence에서 같은 의미를 가진다.
- [ ] Deterministic ID Factory가 Production Interface를 구현한다.
- [ ] Migration 실패 시 Last Known Good와 Session Gate가 유지된다.
- [ ] 측정 전 성능 수치를 확정하지 않았다.
- [ ] Test 계획과 Negative Disclosure 검사가 연결됐다.
- [ ] 후속 Networking·Session·Scene·Movement Spec이 공통 계약을 재정의하지 않는다.
- [ ] 문서 검증 Workflow가 성공한다.

## 19. 미결정 사항과 위험

| 항목 | 구현 차단 여부 | 확인 방법 | 결정 위치 | 후속 조치 |
|---|---|---|---|---|
| 실제 Production Source Tree | 예 | Repository·Place Source 조사 | 이 Spec §4 | 경로·재사용 대상 갱신 |
| Stable ID 문자열 Encoding | 예 | 기존 저장 호환성과 크기 측정 | Spec·Migration | 형식 확정 |
| Authority Revision 발급 저장 위치 | 예 | Transaction 구현 조사 | Transaction Spec | 단일 발급 책임 확정 |
| Domain Ref Kind Registry 위치 | 예 | 기존 Registry 조사 | 이 Spec | 중복 Registry 방지 |
| Error Code 오타·Naming Convention | 예 | Error Catalog Review | 이 Spec | `INCARNATION` 표기 확정 |
| ID·Ref 최대 Byte | 아니오 | Network·Persistence Profiling | Configuration | 측정 후 상한 확정 |
| Trace Sampling | 아니오 | Diagnostics Profiling | Diagnostics Config | 측정 후 확정 |

## 20. 변경 영향 지도

| 변경 유형 | User Guide | Main System Guide | Authority Documents | 다른 Specs·Migration |
|---|---|---|---|---|
| Epoch 의미 변경 | 재접속·Rollback 설명 | Runtime·Session | Networking·Persistence | 모든 Network·Recovery Spec |
| Stable ID Kind 추가 | 일반적으로 없음 | 해당 Domain Guide | Runtime Object·Domain 계약 | Type Registry·Migration |
| Revision 의미 변경 | 오류·재시도 UX | Runtime·Session·Scene | Transaction·Networking | Command·Projection·Movement |
| Error 공개 정책 변경 | Player·DM 오류 안내 | UI·Diagnostics | Diagnostics·UI Runtime | Localization·Support |
| Version Ref 변경 | Update·Recovery UX | Runtime·Extension | Compiled Build·Policy | Serializer·Migration |

## 21. 준비 완료 Gate

- [x] 사용자 결과와 비범위가 명확하다.
- [x] Quick Flow·User Guide·Authority 추적성이 작성됐다.
- [ ] 기존 코드·Schema·Test 조사가 완료됐다.
- [x] 공통 Identity·Epoch·Revision 의미가 분리됐다.
- [x] Result·Error·Redaction 계약이 정의됐다.
- [x] Persistence·Migration·Recovery 영향이 정의됐다.
- [x] Diagnostics·Budget·Health가 정의됐다.
- [x] Deterministic·Fault·Disclosure Test가 정의됐다.
- [ ] 최종 Module 경로와 재사용·대체 책임이 확인됐다.
- [ ] Error Catalog Naming Review가 완료됐다.
- [ ] 문서 검증 Workflow가 성공했다.

현재 판정:

```text
Spec 상태
→ 초안

즉시 구현 가능성
→ BLOCKED

차단 해소
→ 실제 Repository 구현 기준선 조사
```

## 22. 변경 기록

| 날짜 | 변경 |
|---|---|
| 2026-08-05 | First Session Walking Skeleton의 첫 Foundation Spec 초안을 작성했다. |
| 2026-08-05 | 실제 구현 트리 미확인으로 `BLOCKED`를 유지하고 Module 경로를 `신규 제안`으로 제한했다. |