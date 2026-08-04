# Persistence, Snapshot, Journal과 Recovery 계약

- 상태: 확정
- 문서 종류: Architecture
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 남은 기본값:
  - 자동 Journal Flush와 Snapshot 요청의 기본 주기
  - Manifest 및 Chunk 최대 목표 크기
  - Snapshot Materialization의 최대 시간 예산
  - 활성 Journal Segment와 Encounter Timeline의 기본 보존 기간
  - 재시도 횟수, Backoff와 Save Queue 상한
  - 장기 Tombstone·감사 기록 압축 시점
  - 비활성 Campaign의 자동 Archive 시점
- 작성일: 2026-08-04
- 관련 ADR:
  - [`ADR-0042`](../decisions/ADR-0042-authoritative-checkpoints-command-journal-and-session-recovery.md)
  - [`ADR-0043`](../decisions/ADR-0043-encounter-turn-snapshot-timeline-and-dm-rollback.md)
  - [`ADR-0057`](../decisions/ADR-0057-canonical-scene-source-and-atomic-compiled-build-activation.md)
  - [`ADR-0058`](../decisions/ADR-0058-stable-runtime-object-identity-and-command-driven-lifecycle.md)
  - [`ADR-0059`](../decisions/ADR-0059-versioned-command-protocol-and-projection-stream-synchronization.md)
  - [`ADR-0061`](../decisions/ADR-0061-persistent-rule-execution-orchestrator-and-nested-timing-windows.md)
  - [`ADR-0062`](../decisions/ADR-0062-ordered-reservations-and-atomic-authority-transactions.md)
  - [`ADR-0063`](../decisions/ADR-0063-manifest-chunk-snapshots-commit-journal-and-branch-recovery.md)
- 관련 문서:
  - [`Command Ordering, Logical Time와 Transaction Coordinator 계약`](command-ordering-logical-time-and-transaction-coordinator-contract.md)
  - [`Rule Runtime Orchestrator와 Pending Execution 계약`](rule-runtime-orchestrator-and-pending-execution-contract.md)
  - [`Runtime Object System과 Entity Lifecycle 계약`](runtime-object-system-and-entity-lifecycle-contract.md)
  - [`Networking Command, Event와 Client Synchronization 계약`](networking-command-event-and-client-synchronization-contract.md)
  - [`Scene Compiler와 Compiled Runtime Scene 계약`](scene-compiler-and-compiled-runtime-scene-contract.md)
  - [`전투 턴 스냅샷 타임라인과 DM 되돌리기 모델`](../systems/combat/encounter-turn-snapshot-and-dm-rollback-model.md)

## 1. 목적

이 문서는 RVTT의 권위 상태를 장기 저장하고, 서버 장애·재접속·세션 종료·스키마 변경·DM 전투 롤백 이후에도 중복 적용이나 부분 상태 없이 복구하는 공통 계약을 정의한다.

대상:

- Campaign 영구 저장
- 활성 Session 복구
- Authority Transaction Journal
- Manifest와 Chunk 기반 Snapshot
- Pending RuleExecution과 Resource Reservation 복구
- Runtime Object Identity와 Incarnation 복구
- Scene Build·Dynamic State·Fog·Discovery 저장
- 서버 장애 판정과 Commit Marker
- 중도 참여·재접속용 Projection 재구성
- Encounter Rollback Branch
- 저장 스키마와 Content Version 마이그레이션

핵심 흐름:

```text
Authority Transaction Commit
→ Domain State와 Revision 갱신
→ Commit Journal과 Commit Marker 기록
→ Snapshot Materialization
→ Manifest와 Chunk 저장
→ 이후 Journal Segment 연결
```

복구 흐름:

```text
검증된 Snapshot Manifest
+ Snapshot 이후 Commit Journal
+ 현재 Build·Content Migration
→ Authoritative Runtime State 재구성
→ 새 AuthorityEpoch 발급
→ Index·Projection·Presentation 재생성
```

## 2. 사용자 결과

이 계약은 다음을 보장한다.

- 서버가 공격 처리 중 종료되어도 피해와 주문 슬롯 중 하나만 남지 않는다.
- 같은 Transaction, 피해, 아이템 생성과 자원 소비가 복구 중 두 번 적용되지 않는다.
- 플레이어가 재접속해도 서버 권위 상태를 다시 받으며 로컬 상태를 저장 원본으로 사용하지 않는다.
- 반응, 대상 선택 또는 DM 판정을 기다리던 RuleExecution을 안전하게 이어갈 수 있다.
- Scene가 커져 저장 한도를 넘더라도 Manifest와 Chunk로 나눠 저장·검증·복구할 수 있다.
- 전투 롤백 시 HP와 위치뿐 아니라 문, 함정, Fog, 공개된 적, Control Assignment와 Pending Execution까지 과거 상태로 돌아간다.
- Rollback 이전 Timeline의 Prompt, Command와 비동기 작업이 새 Branch에 적용되지 않는다.
- Client Presentation, Streaming Cache와 Roblox Instance 손상은 권위 저장을 훼손하지 않는다.
- 저장 실패가 발생하면 마지막 검증된 Snapshot과 Commit Journal로 복구할 수 있다.

## 3. 저장 계층의 권위 구분

### 3.1 Authoring Source

DM이 장기 편집하는 원본이다.

예:

- Campaign 설정
- Character Source와 성장 선택
- Scene Source와 Draft
- Published Build Pointer
- Asset Semantic Profile과 Content Pack 참조
- Journal과 Handout

### 3.2 Authoritative Runtime State

세션 중 서버 Transaction으로 변경되는 현재 상태다.

예:

- Actor와 Runtime Object State
- HP, 자원, Effect와 Concentration
- Encounter·Turn·Control Assignment
- 문·함정·상자·파괴 오브젝트 상태
- Fog·Discovery·Perception Knowledge
- Pending RuleExecution과 Resource Reservation
- Runtime Quick Edit Overlay

### 3.3 Derived Runtime Data

권위 상태에서 다시 만들 수 있으므로 기본 저장 원본이 아니다.

```text
Spatial Index
Navigation Cache
Query Cache
Compiled Expression Cache
Runtime Scene Provider Cache
Projection Cache
Client Interest와 Streaming Cache
Presentation Model
Tween·VFX·Camera 상태
Roblox Physics 상태
```

### 3.4 Player Preference

규칙과 별개인 사용자 개인 설정이다.

```text
UI Scale
Hotbar 배치
패널 접힘 상태
입력 설정
접근성 설정
허용된 Camera Preference
```

Campaign Snapshot과 분리된 계정 설정으로 저장한다.

## 4. 저장 단위

모든 데이터를 하나의 거대한 DataStore Value로 저장하지 않는다.

```text
CampaignPersistenceManifest
├─ campaign_core
├─ character_source_chunks[]
├─ character_runtime_chunks[]
├─ inventory_chunks[]
├─ scene_source_manifests[]
├─ scene_dynamic_state_chunks[]
├─ runtime_object_chunks[]
├─ encounter_chunks[]
├─ pending_execution_chunks[]
├─ fog_discovery_chunks[]
├─ ownership_control_chunks[]
├─ journal_segment_refs[]
├─ checkpoint_refs[]
└─ integrity_manifest
```

Chunk는 저장 한도, 갱신 빈도와 권위 경계에 따라 나눈다. Chunk 경계가 규칙 Transaction 경계가 되지는 않는다.

## 5. Campaign Persistence Manifest

```text
CampaignPersistenceManifest
├─ manifestId
├─ campaignId
├─ schemaVersion
├─ contentVersionSet
├─ authorityEpochAtCapture
├─ authorityRevision
├─ branchId
├─ snapshotId
├─ parentSnapshotId?
├─ sourceRevisionRefs
├─ publishedSceneBuildRefs
├─ baseJournalSequence
├─ chunkEntries[]
├─ journalSegmentEntries[]
├─ checkpointDirectoryRef?
├─ createdAt
├─ captureReason
├─ writerLeaseId
├─ integrityHash
└─ completionMarker
```

`completionMarker`가 없거나 Integrity 검증이 실패한 Manifest는 정상 Snapshot으로 활성화하지 않는다.

## 6. Chunk 계약

```text
PersistenceChunkEntry
├─ chunkId
├─ chunkTypeId
├─ schemaVersion
├─ contentHash
├─ byteSizeClass
├─ compressionKind
├─ encryptionPolicyRef?
├─ dependencyChunkIds[]
├─ authorityRevisionFrom
├─ authorityRevisionTo
├─ branchId
├─ storageLocator
├─ integrityHash
└─ requiredForRecovery
```

### 6.1 Chunk 원칙

- Stable ID와 Content Hash를 사용한다.
- 배열 위치나 저장 Key 생성 순서를 Identity로 사용하지 않는다.
- 필수 Chunk 하나라도 없으면 해당 Snapshot을 완전한 복구 지점으로 취급하지 않는다.
- 선택적 UI 요약이나 장기 감사 자료가 없다고 권위 복구를 실패시키지 않는다.
- 같은 Content Hash의 불변 Chunk는 재사용할 수 있다.
- 사용자별 Projection과 비밀 정보 View를 Campaign Authority Chunk와 혼합하지 않는다.

### 6.2 Chunk 작성 방식

```text
Immutable State View 캡처
→ Chunk 직렬화
→ 개별 Hash 검증
→ 임시 Locator에 저장
→ Manifest Candidate 작성
→ 모든 필수 Chunk 재검증
→ Manifest Completion Marker 기록
→ Current Snapshot Pointer 원자 교체
```

Current Pointer를 먼저 바꾸지 않는다.

## 7. Authority Snapshot

Snapshot은 특정 `AuthorityEpoch + BranchId + AuthorityRevision`의 완전한 권위 상태를 재구성할 수 있는 Manifest와 Chunk 집합이다.

Snapshot은 Roblox Workspace의 복사본이 아니다.

포함:

- Authoring Source 참조와 현재 Published Build
- Persistent Character·Inventory·Item State
- Runtime Object Directory와 Component State
- Actor, Encounter와 Turn State
- Scene Dynamic State와 Runtime Overlay
- Fog·Discovery·Knowledge State
- Pending RuleExecution과 Reservation
- Ownership·Link·Control Assignment
- Transaction·Resolution Ledger
- 필요한 Archive와 Tombstone 범위

포함하지 않음:

- Workspace Instance 경로
- MeshPart별 CFrame
- Tween 진행률
- 물리 주사위 위치
- Client Camera
- Streaming Cache
- Query·Navigation Cache
- VFX와 화면 효과

## 8. Snapshot Consistency

Snapshot 캡처를 위해 전체 게임을 장시간 정지하지 않는다.

```text
안전한 AuthorityRevision 확정
→ Immutable State View와 Chunk Revision Set 고정
→ 다음 Transaction 진행 허용
→ 고정 View를 저장 Queue에서 직렬화
```

Snapshot의 모든 Chunk는 동일한 Capture Barrier와 Branch를 참조해야 한다.

도메인별 Revision이 다를 수는 있지만 Manifest가 동일한 `authorityRevision`에서 읽은 일관된 Revision Set을 기록해야 한다.

## 9. Commit Journal

Journal은 사용자의 원시 입력이나 Store의 필드 단위 변경 목록이 아니라 **Commit된 Authority Transaction의 재생 가능한 의미 기록**이다.

```text
AuthorityCommitJournalEntry
├─ journalEntryId
├─ journalSequence
├─ transactionId
├─ transactionTypeId
├─ transactionSchemaVersion
├─ idempotencyKeys[]
├─ authorityEpoch
├─ branchId
├─ authorityRevisionBefore
├─ authorityRevisionAfter
├─ orderingKeys[]
├─ readSetDigest
├─ writeSetDigest
├─ committedMutationRecords[]
├─ domainRevisionResults[]
├─ committedEventRecords[]
├─ sourceCommandRefs[]
├─ sourceExecutionIds[]
├─ committedAt
├─ integrityHash
└─ commitMarker
```

### 9.1 Commit Marker

- Commit Marker 없음: 복구 시 미적용 Transaction으로 취급한다.
- Commit Marker 있음: 동일 `transactionId`를 다시 적용하지 않고 결과를 복구한다.
- Marker와 State가 불일치하면 자동 추측하지 않고 Recovery Audit 상태로 전환한다.

### 9.2 저장하지 않는 것

```text
클라이언트 MouseMove
Camera 이동
Hover
Tween 시작
Remote 도착 순서
Workspace Part 변경
미제출 Preview
```

## 10. Journal Segment와 압축

Journal은 무한 단일 배열이 아니라 Segment로 저장한다.

```text
JournalSegment
├─ segmentId
├─ branchId
├─ sequenceFrom
├─ sequenceTo
├─ authorityRevisionFrom
├─ authorityRevisionTo
├─ previousSegmentHash
├─ entries[]
├─ integrityHash
└─ sealed
```

검증된 Snapshot이 생성되면 그 이전 Journal은 활성 복구 경로에서 압축할 수 있다.

다만 다음은 정책에 따라 별도 보존한다.

- DM 감사 로그
- Encounter Rollback Timeline
- 경제·아이템 소유권 변경 기록
- Admin Override
- Migration 기록
- Rollback Branch 관계

## 11. Pending RuleExecution 저장

RuleExecution이 사용자 입력, TimingWindow, Child Execution 또는 Presentation Gate를 기다리는 중이어도 권위 상태다.

```text
PendingRuleExecutionSnapshot
├─ executionId
├─ rootExecutionId
├─ parentExecutionId?
├─ executionSchemaVersion
├─ recipeId
├─ recipeHash
├─ currentState
├─ currentStepRef
├─ bindingStoreSnapshot
├─ resourceReservations[]
├─ rollRecords[]
├─ pendingEffects[]
├─ committedCommitGroupIds[]
├─ timingWindowStack[]
├─ pendingInputs[]
├─ childExecutionRefs[]
├─ dependencyRevisionTokens[]
├─ executionBudgetState
├─ authorityEpoch
├─ branchId
└─ integrityHash
```

복구 시:

1. AuthorityEpoch와 Branch를 새 서버 기준으로 갱신한다.
2. Recipe와 Handler Version 호환성을 확인한다.
3. 이미 Commit된 Group은 다시 적용하지 않는다.
4. Resource Reservation을 현재 Store와 대조한다.
5. Pending Input과 TimingWindow를 새 Projection으로 다시 발행한다.
6. 이전 Connection Epoch의 응답을 거부한다.
7. 재개할 수 없으면 DM 검토 또는 정의된 안전 취소 정책을 사용한다.

## 12. Resource Reservation 저장

Ordering Reservation은 짧은 실행 순서 보호이므로 Snapshot에 장기 보존하지 않는다.

Resource Reservation은 Pending RuleExecution과 함께 보존할 수 있다.

```text
PersistedResourceReservation
├─ reservationId
├─ executionId
├─ resourceOwnerRef
├─ resourceTypeId
├─ amount
├─ spendTiming
├─ createdRevision
├─ expiresByPolicy
└─ state
```

복구 후 실제로 소비됐는지 Commit Journal과 Ledger를 먼저 확인한다.

```text
Commit 확인됨
→ spent 상태 복원

Commit 없음, 실행 재개 가능
→ reserved 상태 복원

Commit 없음, 실행 취소
→ release
```

## 13. Runtime Object 복구

Snapshot은 다음을 보존한다.

```text
RuntimeObjectId
RuntimeIncarnation
Lifecycle State
Blueprint와 Build Binding
Component Manifest
Component State Refs
Ownership와 Link
Persistence Class
Archive Record
필요한 Tombstone
```

복구 시 Workspace Model을 저장본에서 복사하지 않는다.

```text
권위 Object Directory 복원
→ Specialized Store 복원
→ Ownership·Link 검증
→ Spatial·Interaction·Rule Index 재구성
→ Disclosure Projection 생성
→ Client Presentation Materialization
```

복구된 서버는 새 `AuthorityEpoch`를 사용한다. Incarnation은 일반 서버 재시작만으로 임의 증가시키지 않지만, Archive Restore·Migration·Rebind 정책이 요구하면 증가할 수 있다.

## 14. Scene 저장과 Build

구분:

```text
Scene Source Revision
Published BuildId
Runtime Dynamic State Revision
Runtime SnapshotId
```

Compiled Build와 Index는 재생성 가능한 Artifact지만, Published Build의 Content Hash와 Version Set을 Snapshot에 기록한다.

복구 시 동일 Build를 불러올 수 없으면:

1. Source와 Compiler Version으로 동일 Build 재생성을 시도한다.
2. Content Hash 일치를 검사한다.
3. 동일성 보장이 안 되면 자동으로 다른 Build를 활성화하지 않는다.
4. Migration 또는 DM 승인 절차를 사용한다.

Runtime Quick Edit Overlay는 Source로 승격되지 않았더라도 활성 세션 복구에 필요한 경우 Session Chunk에 저장한다.

## 15. Fog, Discovery와 Knowledge

다음을 분리한다.

```text
Discovery State
→ 장기적으로 발견한 정보

Current Reveal State
→ 현재 보이는 영역

Detection·Knowledge State
→ 알려진 적, 마지막 위치와 비밀 오브젝트 발견
```

Campaign 정책에 따라 Discovery는 장기 저장하고 Current Reveal은 Scene·Session State로 저장한다.

Encounter Rollback은 사용자 요구에 따라 다음을 과거 상태로 복원한다.

- Current Reveal
- Discovery 변경
- 적의 공개 여부
- 비밀문·함정 발견 여부
- Last Known Position
- Detection Relation

이미 사람이 본 정보를 기억에서 지울 수는 없으므로 DM UI는 비가역적 지식 경고를 표시한다.

## 16. 서버 장애 복구

```text
Writer Lease 확인
→ 최신 완료 Manifest 탐색
→ Chunk Integrity 검증
→ Snapshot Materialization
→ Snapshot 이후 Journal Segment 검증
→ Commit Marker가 있는 Transaction만 재생
→ Pending Execution과 Reservation 복원
→ Index와 Projection 재생성
→ 새 AuthorityEpoch 발급
→ Client Full Resync
```

복구 중 일반 Gameplay Command를 허용하지 않는다.

### 16.1 In-flight Transaction

```text
Commit Marker 없음
→ Transaction 폐기
→ Resource Reservation과 Staging 정리

Commit Marker 있음
→ Commit 결과 복원
→ Event·Projection은 필요 시 다시 생성
```

VFX, Camera Cue와 Presentation Ack는 복구 판정에 사용하지 않는다.

## 17. 정상 서버 종료

```text
새 Gameplay Command 접수 중지
→ 진행 중 Transaction 안전 경계 대기
→ Pending Execution 저장 가능 상태 확인
→ Journal Flush
→ 필요 시 Snapshot Capture
→ Manifest 검증
→ Session 종료 상태 Commit
→ Writer Lease 해제
```

종료 시간 안에 Snapshot을 완성하지 못해도 Commit Journal이 정상 Flush되었다면 마지막 Snapshot에서 복구할 수 있다.

## 18. 단일 Writer와 Lease

같은 Campaign Authority Branch에 두 서버가 동시에 쓰지 못하게 한다.

```text
CampaignWriterLease
├─ campaignId
├─ branchId
├─ leaseId
├─ serverInstanceId
├─ acquiredAt
├─ renewedAt
├─ expiresAt
└─ authorityEpoch
```

Lease를 잃은 서버는 새 Transaction Commit을 중지한다.

Lease 만료를 근거로 다른 서버가 인계할 때 이전 서버의 늦은 Commit을 AuthorityEpoch와 Lease 검증으로 거부한다.

## 19. 재접속과 중도 참여

재접속 Client는 Persistence Snapshot을 직접 받지 않는다.

```text
서버 Authority State 복구
→ 사용자별 Projection Snapshot 생성
→ Event Catch-up
→ Streaming Activation Set 준비
→ Gameplay Ready
```

Client가 보낸 로컬 Character, Actor, Fog와 Inventory 상태는 복구 원본이 아니다.

같은 서버에 재접속할 때는 Projection Delta Resume가 가능하지만, AuthorityEpoch가 변경된 서버 복구 후에는 Full Projection Resync를 기본으로 한다.

## 20. Encounter Rollback Branch

DM 전투 롤백은 현재 State를 역연산하거나 일반 Restore Command를 여러 개 실행하는 기능이 아니다.

```text
Rollback Checkpoint 선택
→ 현재 Branch 동결
→ Checkpoint Manifest와 Delta 검증
→ 새 BranchId 생성
→ 새 AuthorityEpoch 발급
→ 과거 권위 상태 Materialize
→ 이후 Transaction 무효화 Ledger 기록
→ Pending Execution·Prompt 재구성 또는 정책상 취소
→ Projection Full Resync
→ 새 Branch에서 Encounter 재개
```

### 20.1 복원 범위

- Encounter와 Turn State
- Actor 위치·HP·자원·Effect
- Runtime Object와 Dynamic Scene State
- Inventory와 생성·소비된 Item
- Fog·Discovery·Knowledge
- Control Assignment
- Pending RuleExecution과 Reservation
- Roll·Transaction·Idempotency Ledger

### 20.2 유지하는 것

사용자 요구에 따라 일반 세션 로그는 삭제하거나 과거로 되돌리지 않는다.

대신 로그와 감사 기록에 Branch를 표시한다.

```text
이 기록은 폐기된 Branch에서 발생했습니다.
```

Client 화면의 현재 규칙 상태는 새 Branch Projection으로 교체한다.

## 21. Named Recovery Checkpoint와 Encounter Timeline

### Named Recovery Checkpoint

DM이 세션 전체 안전 경계에 이름을 붙인다.

```text
성 입장 전
보스방 문 열기 전
긴 휴식 직후
```

### Encounter Timeline

전투 시작부터 종료까지 턴 경계를 선택 가능하게 유지한다.

내부 구현은 Base Snapshot + Delta Journal + Materialized Snapshot을 사용할 수 있지만 DM에게는 완전한 턴 상태처럼 보여야 한다.

활성 전투가 끝나기 전에는 턴 선택 가능성을 없애는 압축을 하지 않는다.

## 22. 저장 실패 정책

### Journal Flush 실패

- 해당 Transaction의 영구 확인 상태를 명확히 유지한다.
- Commit Marker 내구성이 보장되지 않으면 후속 고위험 Command를 일시 차단할 수 있다.
- 무한 재시도하지 않고 Backoff와 DM 진단을 사용한다.

### Snapshot 실패

- 현재 Authority Runtime은 계속될 수 있다.
- Last Known Good Snapshot Pointer를 변경하지 않는다.
- Journal Retention을 연장한다.
- 다음 안전 경계에서 재시도한다.

### Chunk 일부 실패

- Manifest Completion Marker를 쓰지 않는다.
- 기존 완료 Snapshot을 유지한다.
- 임시 Chunk는 GC 대상에 등록한다.

### 저장 공간 한도

- Manifest와 Chunk 분할을 사용한다.
- 필수 권위 State를 조용히 생략하지 않는다.
- 장기 감사·Presentation 요약 등 선택 자료부터 정책적으로 압축한다.
- 더 이상 안전하게 저장할 수 없으면 새 위험 Command를 제한하고 DM에게 알린다.

## 23. 스키마와 Content Migration

```text
Stored Schema Version
→ Migration Plan 선택
→ 임시 Branch에서 변환
→ 참조·ID·무결성 검증
→ 현재 Ruleset·Content Version과 호환성 검사
→ Candidate Snapshot 작성
→ 검증 성공 시 활성화
```

Migration은 반복 실행에 안전해야 한다.

금지:

- Live Snapshot을 제자리에서 파괴적으로 수정
- 실패한 Migration 일부를 Current Pointer로 지정
- 누락된 Content를 임의로 다른 Definition으로 대체
- RuntimeObjectId, ItemInstanceId와 CharacterId를 이름으로 재생성

## 24. Integrity와 Recovery Audit

최소 검사:

- Manifest Completion Marker
- Chunk Hash와 Dependency
- Journal Hash Chain
- Transaction Commit Marker
- AuthorityRevision 연속성
- Branch와 AuthorityEpoch
- RuntimeObject Incarnation
- Ownership Cycle
- Strong Link 대상
- Item Ownership 단일성
- Pending Execution Recipe Hash
- Resource Reservation과 Commit Ledger 일치
- Scene Build Content Hash

자동 복구가 안전하지 않으면 `recovery_review_required`로 열고 DM에게 선택 가능한 복구 지점과 손상 범위를 보여 준다.

## 25. 보안과 공개 범위

Campaign Authority Snapshot, Raw Journal과 비밀 Object State는 Player Client에 전달하지 않는다.

백업·진단 Export도 Role과 권한을 검사한다.

Projection Snapshot은 Persistence Snapshot에서 사용자별 Disclosure를 적용해 별도로 생성한다.

## 26. Service 책임

```text
PersistenceCoordinator
├─ CampaignWriterLeaseService
├─ SnapshotCaptureCoordinator
├─ ManifestWriter
├─ ChunkStore
├─ JournalWriter
├─ JournalSegmentManager
├─ CommitDurabilityService
├─ PendingExecutionPersistenceAdapter
├─ EncounterCheckpointStore
├─ RecoveryPlanner
├─ RecoveryExecutor
├─ BranchManager
├─ MigrationRegistry
├─ IntegrityVerifier
└─ PersistenceDiagnostics
```

Persistence Service가 전투, Item, Fog와 Runtime Object 규칙을 직접 구현하지 않는다. 각 Domain은 Versioned Snapshot Adapter와 Mutation Journal Serializer를 등록한다.

## 27. 성능 원칙

- Transaction마다 전체 Snapshot을 만들지 않는다.
- Commit Journal은 작은 의미 기록으로 Append한다.
- Snapshot은 안전한 Revision View를 비동기 직렬화한다.
- 변경되지 않은 불변 Chunk는 Content Hash로 재사용할 수 있다.
- 활성 Encounter Timeline은 선택 가능성을 보장하면서 주기적으로 Materialize한다.
- 저장 Queue, Journal Lag, Chunk 크기와 복구 시간을 측정한다.
- 권위 Gameplay Thread에서 대형 JSON 직렬화와 DataStore Retry를 직접 수행하지 않는다.

## 28. 진단 UX

DM에게 내부 저장 Key보다 다음을 보여 준다.

```text
마지막 정상 저장: 라운드 3 · 전사 턴 종료
현재 변경사항: 저널에 안전하게 기록됨
새 전체 스냅샷: 생성 중
```

실패 예:

```text
전체 스냅샷 생성에 실패했습니다.
현재 세션은 마지막 정상 스냅샷과 이후 기록으로 복구할 수 있습니다.
다음 안전 지점에서 다시 시도합니다.
```

복구 검토 예:

```text
마지막 Transaction의 완료 여부를 자동으로 확인할 수 없습니다.
선택 가능한 복구 지점:
1. 라운드 4 시작
2. 라운드 3 종료
```

## 29. 완료 기준

1. Snapshot + Journal로 동일 권위 상태를 복구할 수 있다.
2. Commit Marker 없는 Transaction이 부분 적용되지 않는다.
3. 같은 Transaction과 Item 생성이 두 번 적용되지 않는다.
4. 저장 한도 초과 데이터를 Manifest와 Chunk로 분리한다.
5. Chunk 일부 실패가 Last Known Good Snapshot을 교체하지 않는다.
6. Pending RuleExecution과 Resource Reservation을 복구할 수 있다.
7. RuntimeObjectId, Incarnation과 Tombstone을 보존한다.
8. 복구 서버가 새 AuthorityEpoch를 발급한다.
9. Client는 Raw Persistence가 아닌 Projection Snapshot으로 재동기화한다.
10. Encounter Rollback이 Fog, 공개 적, 문, 함정, Control과 Pending Execution을 복원한다.
11. Rollback 이전 Branch의 Command와 Prompt를 거부한다.
12. 일반 로그는 삭제하지 않고 Branch 표시로 보존한다.
13. Migration 실패가 기존 Snapshot을 손상시키지 않는다.
14. Scene Build와 Dynamic State를 혼합하지 않는다.
15. Workspace와 Presentation을 저장 원본으로 사용하지 않는다.

## 30. 비목표

- Roblox Workspace 전체를 Save Model로 사용하지 않는다.
- 모든 Transaction마다 전체 Campaign Snapshot을 만들지 않는다.
- Client Local State를 서버 복구 원본으로 사용하지 않는다.
- Rollback을 역방향 Command 모음으로 구현하지 않는다.
- VFX·Tween·Camera와 물리 주사위 상태를 복원하지 않는다.
- 하나의 거대한 DataStore Value에 모든 Campaign 데이터를 넣지 않는다.
- 저장 실패를 조용히 무시하고 계속 위험한 Commit을 누적하지 않는다.
