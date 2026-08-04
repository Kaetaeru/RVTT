# ADR-0063. Manifest·Chunk Snapshot, Commit Journal과 Branch Recovery

- 상태: 확정
- 작성일: 2026-08-04
- 결정 범위: Campaign 저장, Snapshot, Journal, Pending Execution 복구, 서버 장애, Encounter Rollback과 Migration
- 관련 문서:
  - [`Persistence, Snapshot, Journal과 Recovery 계약`](../architecture/persistence-and-session-recovery-model.md)
  - [`Command Ordering, Logical Time와 Transaction Coordinator 계약`](../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)
  - [`Rule Runtime Orchestrator와 Pending Execution 계약`](../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md)
  - [`Runtime Object System과 Entity Lifecycle 계약`](../architecture/runtime-object-system-and-entity-lifecycle-contract.md)
  - [`Networking Command, Event와 Client Synchronization 계약`](../architecture/networking-command-event-and-client-synchronization-contract.md)
  - [`전투 턴 스냅샷 타임라인과 DM 되돌리기 모델`](../systems/combat/encounter-turn-snapshot-and-dm-rollback-model.md)

## 배경

RVTT는 장시간 Campaign, 큰 Scene, 활성 Encounter, Pending Reaction과 중도 참여를 지원한다. 저장 한도를 넘는 상태를 하나의 Value에 넣거나 Workspace를 그대로 저장하면 다음 문제가 생긴다.

- 일부 데이터만 저장되어 Snapshot이 서로 다른 Revision을 가짐
- 서버 장애 시 Transaction 적용 여부를 판정할 수 없음
- 같은 피해, 자원 소비와 Item 생성이 두 번 적용됨
- 반응이나 DM 판정 대기 상태가 유실됨
- RuntimeObjectId와 Incarnation이 바뀌어 오래된 참조가 새 Object에 연결됨
- Fog와 숨겨진 적의 공개 상태가 Rollback에서 복원되지 않음
- Client Cache와 Presentation 상태가 권위 저장에 섞임
- DataStore 크기 한도 때문에 필수 상태를 조용히 생략함
- Migration 실패가 현재 저장본을 손상시킴

## 결정

### 1. Campaign Snapshot은 Manifest와 Versioned Chunk 집합이다

모든 Campaign 상태를 하나의 거대한 저장 값으로 만들지 않는다.

Manifest는 Snapshot Identity, AuthorityRevision, Branch, Build와 Chunk 참조·Hash를 소유한다.

Chunk는 Character, Inventory, Scene Dynamic State, Runtime Object, Encounter, Pending Execution, Fog와 Journal Segment 등으로 분리한다.

### 2. Snapshot은 Completion Marker 이후에만 활성화한다

Chunk를 임시 위치에 모두 기록하고 Integrity를 확인한 뒤 Manifest Completion Marker를 기록한다.

모든 필수 Chunk가 검증되기 전에 Current Snapshot Pointer를 바꾸지 않는다.

### 3. Journal은 Commit된 Authority Transaction을 기록한다

Raw Client 입력, Workspace 필드 변경과 Presentation Event를 저장 원본으로 사용하지 않는다.

Journal Entry는 TransactionId, AuthorityRevision, Branch, Mutation Record와 Commit Marker를 가진다.

### 4. Commit Marker가 Transaction 적용 여부의 기준이다

Commit Marker가 없으면 미적용으로 취급한다.

Commit Marker가 있으면 같은 Transaction을 다시 적용하지 않고 이미 Commit된 결과를 복원한다.

Marker와 Store가 불일치하면 자동 추측하지 않고 Recovery Review를 요구한다.

### 5. Snapshot과 Journal을 함께 사용한다

```text
마지막 검증 Snapshot
+ 이후 Commit Journal
→ 현재 권위 상태
```

Transaction마다 전체 Snapshot을 만들지 않는다.

### 6. Pending RuleExecution은 저장 가능한 권위 상태다

TimingWindow, Prompt, Child Execution, BindingStore, RollRecord, PendingEffect와 Resource Reservation을 Snapshot Adapter로 저장한다.

이미 Commit된 CommitGroup은 복구 후 다시 적용하지 않는다.

### 7. Ordering Reservation과 Resource Reservation을 구분한다

Ordering Reservation은 서버 실행 순서를 위한 단기 상태이므로 장기 복구하지 않는다.

주문 슬롯, 반응과 Feature 사용 횟수 같은 Resource Reservation은 Pending Execution과 함께 복구할 수 있다.

### 8. Runtime Object Identity를 보존한다

RuntimeObjectId, Incarnation, Lifecycle, Component State, Ownership, Link, Archive와 Tombstone을 Snapshot에 포함한다.

Workspace Model과 Roblox Instance 경로는 저장하지 않는다.

### 9. Derived Runtime과 Presentation은 재생성한다

Spatial Index, Navigation Cache, Query Cache, Projection Cache, Streaming State, VFX와 Camera는 권위 저장 원본이 아니다.

복구된 Authority State에서 다시 만든다.

### 10. 복구 서버는 새 AuthorityEpoch를 발급한다

복구 전 Connection, Prompt, Command와 비동기 작업을 새 서버에 적용하지 않는다.

Client는 Raw Persistence Snapshot이 아니라 사용자별 Projection Snapshot으로 Full Resync한다.

### 11. 같은 Campaign Branch는 단일 Writer Lease를 사용한다

Lease를 잃은 서버는 새 Commit을 중지한다.

이전 서버의 늦은 Commit은 Lease와 AuthorityEpoch 검증으로 거부한다.

### 12. Encounter Rollback은 새 Branch다

현재 State를 역연산하거나 Restore Command를 연속 실행하지 않는다.

선택한 Checkpoint에서 새 BranchId와 AuthorityEpoch를 만들고 과거 상태를 Materialize한다.

이후 Timeline의 Command, Prompt와 Transaction은 새 Branch에서 무효다.

### 13. Rollback 범위에는 정보 공개 상태가 포함된다

Actor, 자원과 Encounter뿐 아니라 문·함정·Fog·Discovery·공개된 적·Last Known Position·Control Assignment와 Pending Execution을 복원한다.

일반 세션 로그는 삭제하지 않고 폐기된 Branch 표시로 유지한다.

### 14. Migration은 Candidate Snapshot을 만든다

현재 저장본을 제자리에서 파괴적으로 수정하지 않는다.

임시 Branch에서 Migration 후 Integrity와 Content 호환성을 검증하고 성공한 Candidate만 활성화한다.

### 15. 저장 실패는 Last Known Good을 교체하지 않는다

Snapshot이나 Chunk 저장 실패 시 기존 완료 Snapshot을 유지하고 Journal Retention을 연장한다.

필수 상태를 생략하거나 실패를 빈 상태로 바꾸지 않는다.

## 결과

- 저장 한도를 넘는 Campaign도 Chunk로 분리할 수 있다.
- 부분 Snapshot이 Current Pointer가 되는 것을 막는다.
- 서버 장애 후 Transaction 중복·부분 적용을 막는다.
- Pending Reaction과 DM 판정을 이어갈 수 있다.
- Runtime Object Identity와 Rollback Timeline을 안정적으로 복구한다.
- Client Cache와 Presentation 실패가 권위 저장을 훼손하지 않는다.
- Rollback에서 Fog와 숨겨진 정보 공개 상태를 복원할 수 있다.
- Migration 실패가 기존 Campaign을 손상시키지 않는다.

## 비용과 주의점

- Manifest Writer, Chunk Store, Journal Segment, Integrity Verifier와 Branch Manager가 필요하다.
- Domain별 Versioned Snapshot Adapter와 Journal Serializer가 필요하다.
- Snapshot과 Journal의 Hash·Revision 연속성을 검사해야 한다.
- Pending Execution Version 호환성 정책이 필요하다.
- Encounter Timeline 보존과 Chunk 압축의 비용을 측정해야 한다.

## 비목표

- Workspace 전체 저장
- 모든 Transaction마다 전체 Snapshot 생성
- Client Local State를 복구 원본으로 사용
- Rollback을 역방향 명령 집합으로 구현
- VFX, Tween, Camera와 물리 주사위 상태 복원
- 하나의 DataStore Value에 전체 Campaign 저장
