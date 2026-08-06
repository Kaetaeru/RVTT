# Command Ordering, Logical Time와 Transaction Coordinator 계약

- 상태: 확정
- 문서 종류: Architecture
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 남은 기본값:
  - Ordering Reservation 기본 만료 시간
  - 단일 Transaction의 최대 Ordering Key·Mutation·Event 수
  - Commit 준비와 Journal Flush의 시간 예산
  - 충돌 재시도 횟수와 Backoff
  - 장기 실행 Reservation Lease 갱신 주기
  - Transaction Trace와 완료 기록 보존 기간
- 작성일: 2026-08-04
- 관련 ADR:
  - [`ADR-0042`](../decisions/ADR-0042-authoritative-checkpoints-command-journal-and-session-recovery.md)
  - [`ADR-0058`](../decisions/ADR-0058-stable-runtime-object-identity-and-command-driven-lifecycle.md)
  - [`ADR-0059`](../decisions/ADR-0059-versioned-command-protocol-and-projection-stream-synchronization.md)
  - [`ADR-0061`](../decisions/ADR-0061-persistent-rule-execution-orchestrator-and-nested-timing-windows.md)
  - [`ADR-0062`](../decisions/ADR-0062-ordered-reservations-and-atomic-authority-transactions.md)
- 관련 문서:
  - [`Networking Command, Event와 Client Synchronization 계약`](networking-command-event-and-client-synchronization-contract.md)
  - [`Rule Runtime Orchestrator와 Pending Execution 계약`](rule-runtime-orchestrator-and-pending-execution-contract.md)
  - [`Runtime Object System과 Entity Lifecycle 계약`](runtime-object-system-and-entity-lifecycle-contract.md)
  - [`저장·세션 복구 모델`](persistence-and-session-recovery-model.md)

## 1. 목적

이 문서는 여러 Actor, Runtime Object, Inventory, Encounter, Scene와 Campaign 상태를 동시에 변경하는 Command가 어떤 순서로 검증되고, 충돌을 피하고, 하나의 권위 결과로 Commit되는지 정의한다.

다음은 모두 같은 공통 계약을 사용한다.

- 공격과 주문의 피해·자원·상태 변경
- 아이템 이전과 장비 변경
- 문·상자·함정의 상태 전환
- Runtime Object Spawn·Archive·Destroy
- 이동 Checkpoint와 점유 변경
- Encounter Turn과 Control Assignment 변경
- Scene Transition과 Build Live Patch
- DM Override와 관리 Command

핵심 흐름:

```text
Validated Command 또는 RuleExecution
→ Ordering Key 계산
→ Reservation 획득
→ 최신 권위 상태 재검증
→ Transaction Plan 생성
→ Commit Graph 검증
→ Atomic Commit
→ Authority Revision 발행
→ Journal과 Projection Event 생성
→ Reservation 해제
```

## 2. 사용자 결과

이 계약은 다음을 보장한다.

- 같은 문, Actor, 아이템을 동시에 변경하는 요청이 임의 순서로 섞이지 않는다.
- 서로 무관한 행동은 불필요하게 하나의 전역 Queue에서 기다리지 않는다.
- 피해는 적용됐지만 주문 슬롯은 소비되지 않는 부분 성공을 허용하지 않는다.
- 반응을 기다리는 동안 서버 전체 Lock을 유지하지 않는다.
- 충돌한 요청은 조용히 덮어쓰지 않고 재검증·거부·재시도 가능한 결과를 반환한다.
- Commit이 성공한 뒤에만 Revision, Event와 Client Projection이 공개된다.
- 서버 오류와 저장 실패가 발생해도 Transaction 전 상태 또는 완전한 Commit 상태 중 하나만 남는다.
- Rollback 이후 이전 Timeline의 Reservation과 Command가 새 Authority Epoch에 적용되지 않는다.

## 3. 책임 분리

### Command Ordering Coordinator

소유:

- Command별 Ordering Key 계산 규칙
- 충돌 가능 요청의 직렬화
- 다중 Key Reservation의 안정적 획득 순서
- Lease, Timeout, 취소와 Queue 우선순위
- 동일 Key의 대기열과 공정성

소유하지 않음:

- 전투·아이템·문 규칙
- 실제 상태 Mutation
- Authority Revision 발급
- Projection 생성

### Transaction Coordinator

소유:

- Transaction ID와 상태기계
- Read Set, Write Set와 Precondition
- Domain Mutation Plan 결합
- Commit Graph와 원자적 적용
- Revision·Journal·Event 발행 경계
- 실패 시 전체 Abort와 정리

### Domain Service

소유:

- 자신의 규칙 검증
- 자신의 Mutation Proposal
- 필요한 Ordering Key·Read Set·Write Set 선언
- Commit 이후 Domain Event Payload

Domain Service는 다른 Store를 직접 수정하거나 Transaction Coordinator를 우회하지 않는다.

## 4. Logical Time

실제 시계 시간과 권위 순서를 분리한다.

```text
AuthorityEpoch
+ AuthorityRevision
+ TransactionId
+ Domain Revision Token
```

- `AuthorityEpoch`: Rollback, 서버 복구와 권위 Branch 전환을 구분한다.
- `AuthorityRevision`: 성공한 전역 권위 Commit의 단조 증가 순서다.
- `TransactionId`: 하나의 원자적 Commit 시도를 식별한다.
- Domain Revision: Runtime Object, Inventory, Encounter, Scene Dynamic State처럼 국소 상태의 변경 순서다.

Client Timestamp, Remote 도착 시각과 Roblox Frame은 권위 순서를 결정하지 않는다.

## 5. Ordering Key

Ordering Key는 충돌 가능성이 있는 Command만 직렬화한다.

초기 Namespace:

```text
actor:{actorId}
runtime_object:{runtimeObjectId}
character:{characterId}
inventory:{containerId}
item:{itemInstanceId}
encounter:{encounterId}
rule_execution:{executionId}
scene_runtime:{sceneId}
scene_authoring:{sceneId}
campaign_admin:{campaignId}
control_assignment:{actorId}
```

Command Definition은 다음을 선언한다.

```text
OrderingPolicy
├─ keyDerivation
├─ accessMode: shared_read | exclusive_write
├─ queueClass
├─ priorityPolicy
├─ leasePolicy
└─ conflictRetryPolicy
```

모든 Command를 `campaign:{id}` 하나로 직렬화하지 않는다.

## 6. 다중 Key와 Deadlock 방지

여러 Key를 변경하는 Command는 모든 Key를 안정적인 정렬 규칙으로 획득한다.

```text
namespace rank
→ canonical ID byte order
→ subkey order
```

규칙:

- 이미 일부 Key를 획득한 뒤 더 낮은 순서의 Key를 요청하지 않는다.
- 실행 중 새 Key가 필요해지면 Transaction Plan을 폐기하고 전체 Key Set으로 다시 준비한다.
- 무제한 동적 Lock 확장을 허용하지 않는다.
- Reservation 대기 중 Domain Store를 변경하지 않는다.

## 7. Reservation

Reservation은 상태 변경이 아니라 충돌 방지를 위한 임시 권리다.

```text
OrderingReservation
├─ reservationId
├─ ownerCommandId 또는 executionId
├─ authorityEpoch
├─ orderingKeys[]
├─ accessModes[]
├─ acquiredAtLogicalTick
├─ leaseExpiresAt
├─ queueClass
└─ state
```

상태:

```text
requested
→ acquired
→ released | expired | cancelled
```

장기 RuleExecution은 반응·DM 입력을 기다리는 동안 Ordering Reservation을 유지하지 않는다. 필요한 자원은 별도의 Resource Reservation으로 보존하고, Commit 직전에 Ordering Key를 다시 획득해 최신 상태를 재검증한다.

## 8. Resource Reservation과 구분

```text
Ordering Reservation
→ 동시 변경 순서를 보호
→ 짧게 유지

Resource Reservation
→ 행동, 반응, 주문 슬롯, Charge 사용권을 보존
→ Pending Execution 동안 유지 가능
```

두 Reservation을 하나의 Lock으로 합치지 않는다.

Resource Reservation도 영구 소비가 아니다.

```text
available
→ reserved(executionId)
→ committed_spent | released
```

## 9. Authority Transaction

```text
AuthorityTransaction
├─ transactionId
├─ authorityEpoch
├─ sourceCommandId?
├─ sourceExecutionId?
├─ orderingReservationId
├─ readSet[]
├─ writeSet[]
├─ preconditions[]
├─ mutationNodes[]
├─ commitEdges[]
├─ journalPolicy
├─ projectionPolicy
├─ auditContext
└─ state
```

상태:

```text
planning
→ reserving
→ validating
→ prepared
→ committing
→ committed

planning | reserving | validating | prepared
→ aborted

committing
→ committed 또는 recovery_required
```

`committing` 이후 임의 재시도를 하지 않는다. Commit Marker와 Journal을 확인해 완료·복구를 판정한다.

## 10. Read Set, Write Set와 Precondition

Domain Mutation은 자신이 읽고 쓰는 권위 항목을 선언한다.

예:

```text
Read Set
- Actor HP Revision
- 주문 슬롯 Pool Revision
- Encounter ActiveTurnId
- Target RuntimeObject Incarnation

Write Set
- Actor HP
- 주문 슬롯 Pool
- Condition Store
- Concentration State
```

Precondition은 전체 전역 Revision 일치가 아니라 필요한 타입 있는 조건만 사용한다.

Commit 직전 모든 Precondition을 다시 확인한다. 실패하면 Mutation을 일부 적용하지 않고 전체 Transaction을 Abort한다.

## 11. Commit Graph

Mutation 순서는 단순 배열 순서가 아니라 검증된 DAG로 표현한다.

```text
CommitNode
├─ nodeId
├─ domainId
├─ mutationTypeId
├─ inputRefs[]
├─ outputRefs[]
├─ readSet[]
├─ writeSet[]
├─ preconditions[]
└─ compensationPolicy
```

예:

```text
피해 계산 결과
→ HP 변경
→ HP 0 판정
→ 집중 종료
→ 집중 소유 지속 효과 종료
→ 관련 Runtime Object Cleanup
```

순환 Commit Graph는 준비 단계에서 거부한다.

하나의 Transaction 안에서 Domain Event Handler가 새 권위 Mutation을 즉시 삽입하지 않는다. 후속 규칙은 `resolving_aftermath`에서 새 Child Execution 또는 새 Transaction으로 생성한다.

## 12. Atomic Commit 경계

Commit은 다음을 하나의 권위 경계로 취급한다.

```text
1. 모든 Ordering Key와 Precondition 최종 확인
2. Commit Intent와 Transaction Plan 봉인
3. Domain Store Mutation 적용
4. Domain Revision 갱신
5. Global AuthorityRevision 발급
6. Commit Marker와 Command Journal 기록
7. Raw Domain Event Batch 생성
8. Projection Builder와 후속 Queue에 전달
9. Reservation 해제
```

Client Projection과 Presentation Signal은 Commit 이전에 성공 결과처럼 공개하지 않는다.

Store가 물리적으로 하나의 DB Transaction을 제공하지 않는 경우에도 Write-ahead Journal, Commit Marker와 결정적 Recovery Plan으로 논리적 원자성을 보장해야 한다.

## 13. Revision 발행

한 Transaction은 성공 시 하나의 `AuthorityRevisionAfter`를 가진다.

각 Domain Store는 같은 Commit에 포함된 자신의 Revision을 갱신할 수 있다.

```text
Transaction Commit
→ Domain Revision 갱신
→ AuthorityRevision 발급
→ Event Batch에 Revision Token 포함
```

부분 Mutation마다 AuthorityRevision을 따로 발급하지 않는다.

## 14. Projection과 Event

Raw Domain Event는 Commit 이후 생성한다.

```text
Committed Transaction
→ Raw Domain Event Batch
→ Rule Aftermath Queue
→ Permission·Perception·Disclosure Projection
→ Client Event Batch
→ Presentation Signal
```

Projection 실패가 권위 Commit을 되돌리지 않는다. Projection 재생성 또는 Client Resync로 복구한다.

## 15. 충돌 처리

초기 결과:

```text
committed
precondition_conflict
ordering_timeout
reservation_expired
superseded
cancelled
server_busy
recovery_required
```

정책:

- `revalidate_on_latest`: 최신 상태로 한정 재계산 가능
- `strict_precondition`: 사용자에게 상태 변경을 알리고 거부
- `server_serialized`: Queue 순서대로 실행
- `merge_if_non_conflicting`: Write Set이 겹치지 않을 때만 병합
- `append_only`: 안정적인 Sequence를 발급해 추가

자동 재시도는 멱등성 Key와 Retry Budget 안에서만 수행한다.

## 16. 취소와 Timeout

- Queue 대기 중 취소: Reservation 요청 제거
- Prepared 이전 취소: Transaction Abort와 자원 해제 정책 적용
- Commit 시작 후 취소: 불가, 최종 결과를 기다림
- Client 연결 종료: Command의 Domain Policy에 따라 계속·취소·안전 경계 대기
- Lease 만료: Ordering Reservation 해제, Prepared Plan 폐기, 최신 상태에서 재시도 필요

## 17. DM Override

DM Override도 Transaction을 우회하지 않는다.

```text
Override Command
→ 권한·이유 검증
→ 충돌 상태와 영향 Preview
→ Ordering Reservation
→ Authority Transaction
→ Audit Event
```

Override는 일반 Precondition 일부를 명시적으로 대체할 수 있지만 다음은 우회하지 못한다.

- Authority Epoch
- ID·Incarnation 무결성
- Schema와 Store 일관성
- Commit Graph 무순환
- 원자적 Journal·Revision 발행

## 18. Recovery와 Rollback

### 서버 장애

복구 시 Transaction 상태를 다음으로 판정한다.

```text
Commit Marker 없음
→ 미적용으로 Abort

Commit Marker 있음
→ 모든 Domain Store와 Journal을 동일 TransactionId로 재구성
```

Projection과 Presentation은 Commit 기록에서 재생성한다.

### DM Rollback

Rollback은 과거 Transaction을 역연산하는 Compensation 묶음이 아니다.

```text
과거 Snapshot 선택
→ 새 AuthorityEpoch·Branch 활성화
→ 이후 Transaction과 Reservation 무효화
→ 새 Projection Snapshot 생성
```

이전 Epoch의 Command, Reservation, Prompt와 비동기 작업은 거부한다.

## 19. 저장과 Journal

Journal 최소 기록:

```text
transactionId
authorityEpoch
authorityRevisionAfter
sourceCommandId 또는 executionId
orderingKeys 요약
read·write set hash
precondition 결과
mutation plan hash
commit marker
raw event batch reference
audit context
```

대형 Payload는 별도 Chunk로 저장할 수 있다.

## 20. 성능 원칙

- 전역 Lock을 정상 경로로 사용하지 않는다.
- Ordering Key는 실제 Write 충돌 범위에 맞춘다.
- 대기 중 Lock을 유지하지 않는다.
- Read-only Query는 Authority Transaction을 만들지 않는다.
- Mutation Plan은 Commit 전에 Budget과 최대 크기를 검증한다.
- 같은 Transaction에서 동일 Store를 반복 읽지 않도록 Snapshot·Read Cache를 사용할 수 있다.
- Trace는 샘플링 가능하지만 Commit Marker와 오류 기록은 보존한다.

## 21. 구조화된 오류

```text
ORDERING_KEY_INVALID
ORDERING_RESERVATION_TIMEOUT
ORDERING_RESERVATION_EXPIRED
ORDERING_DYNAMIC_KEY_EXPANSION
TRANSACTION_PRECONDITION_FAILED
TRANSACTION_WRITE_CONFLICT
TRANSACTION_GRAPH_CYCLE
TRANSACTION_BUDGET_EXCEEDED
TRANSACTION_COMMIT_FAILED
TRANSACTION_RECOVERY_REQUIRED
TRANSACTION_WRONG_AUTHORITY_EPOCH
TRANSACTION_ALREADY_COMMITTED
```

오류를 빈 성공 결과나 부분 성공으로 변환하지 않는다.

## 22. 비목표

- 모든 Command를 하나의 전역 Queue로 직렬화하지 않는다.
- 장기 Prompt 동안 Store Lock을 유지하지 않는다.
- Roblox Instance Mutation을 권위 Transaction으로 취급하지 않는다.
- Projection 전송 성공을 Commit 성공 조건으로 삼지 않는다.
- 일반 Rollback을 역방향 Compensation Transaction으로 구현하지 않는다.
- Domain Service가 다른 Store를 직접 수정하도록 허용하지 않는다.

## 23. 완료 기준

후속 구현 명세는 최소한 다음을 검증해야 한다.

1. 동일 문을 여는 두 Command가 하나씩 순서대로 처리된다.
2. 서로 다른 Object의 Command는 병렬 준비가 가능하다.
3. 다중 Inventory 이전에서 Deadlock이 발생하지 않는다.
4. 피해·자원·상태 변경이 모두 Commit되거나 모두 Abort된다.
5. 반응 대기 중 Ordering Lock이 해제되며 자원 예약은 유지된다.
6. Commit 직전 Revision 충돌이 부분 Mutation 없이 거부된다.
7. 중복 Command가 같은 Transaction Result를 재생한다.
8. Commit 후 Projection 실패를 Resync로 복구할 수 있다.
9. 서버 장애 직후 Commit Marker로 적용 여부를 판정한다.
10. Rollback 이후 이전 Epoch의 Reservation과 Command가 실패한다.
11. DM Override도 Audit 가능한 Transaction을 사용한다.
12. Transaction Trace로 충돌 Key와 실패 Precondition을 확인할 수 있다.
