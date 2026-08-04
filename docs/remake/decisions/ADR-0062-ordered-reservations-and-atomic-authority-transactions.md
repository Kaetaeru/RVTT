# ADR-0062. 정렬된 Reservation과 원자적 Authority Transaction

- 상태: 확정
- 작성일: 2026-08-04
- 결정 범위: Command Ordering, 다중 도메인 Mutation, Logical Time, Reservation, Commit, Revision, Journal과 Recovery
- 관련 문서:
  - [`Command Ordering, Logical Time와 Transaction Coordinator 계약`](../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)
  - [`Networking Command, Event와 Client Synchronization 계약`](../architecture/networking-command-event-and-client-synchronization-contract.md)
  - [`Rule Runtime Orchestrator와 Pending Execution 계약`](../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md)
  - [`Runtime Object System과 Entity Lifecycle 계약`](../architecture/runtime-object-system-and-entity-lifecycle-contract.md)
  - [`저장·세션 복구 모델`](../architecture/persistence-and-session-recovery-model.md)

## 배경

RVTT의 하나의 행동은 여러 권위 Store를 동시에 변경할 수 있다.

예:

```text
공격
→ 행동 자원 소비
→ 대상 HP 감소
→ 상태 적용
→ 집중 종료
→ 지속 효과와 소환체 정리
→ Encounter와 로그 갱신
```

기능별 코드가 Store를 직접 수정하면 다음 문제가 생긴다.

- 피해만 적용되고 자원 소비는 실패하는 부분 성공
- 같은 문이나 아이템을 동시에 변경한 요청의 덮어쓰기
- 반응 대기 중 서버 Lock 장기 점유
- 다중 Object Lock 순서 차이로 교착
- Commit 전 Event가 Client에 보임
- 서버 장애 후 Transaction 적용 여부를 판정할 수 없음
- Rollback 이후 이전 Command가 새 Timeline에 적용됨
- 모든 요청을 전역 Queue로 직렬화해 성능과 반응성이 저하됨

## 결정

### 1. 모든 권위 Mutation은 Authority Transaction을 사용한다

Command Handler, Rule Runtime, Runtime Object Lifecycle과 Domain Service는 권위 Store를 직접 수정하지 않는다.

각 기능은 검증된 Mutation Proposal을 만들고 Transaction Coordinator가 Read Set, Write Set, Precondition과 Commit Graph를 결합해 원자적으로 Commit한다.

### 2. Command Ordering과 Transaction Commit을 분리한다

Command Ordering Coordinator는 충돌 가능한 요청의 실행 순서와 Reservation만 소유한다.

Transaction Coordinator는 상태 검증, Mutation Plan, Atomic Commit, Revision, Journal과 Event 발행 경계를 소유한다.

하나의 거대한 Manager로 합치지 않는다.

### 3. 전역 Queue 대신 타입 있는 Ordering Key를 사용한다

Actor, Runtime Object, Inventory, Encounter, Scene와 Campaign 관리 범위별 Key를 사용한다.

같은 Write 범위를 가진 Command는 직렬화하고 서로 독립된 Command는 병렬 준비를 허용한다.

### 4. 다중 Key는 안정적인 전역 순서로 획득한다

Namespace Rank와 Canonical ID 순서로 Reservation을 획득한다.

실행 중 더 낮은 순서의 Key를 추가하지 않는다. 새 Key가 필요하면 Plan을 폐기하고 전체 Key Set으로 다시 준비한다.

이를 통해 순환 대기와 교착을 방지한다.

### 5. Ordering Reservation과 Resource Reservation을 분리한다

Ordering Reservation은 짧은 동시성 보호이며 대기 중 유지하지 않는다.

Resource Reservation은 행동, 반응, 주문 슬롯과 Charge 사용권을 Pending Execution 동안 보존할 수 있다.

반응·DM 입력을 기다리는 동안 Ordering Lock을 해제하고 Commit 직전에 다시 획득해 최신 상태를 검증한다.

### 6. 권위 순서는 Logical Time으로 표현한다

권위 순서는 다음으로 표현한다.

```text
AuthorityEpoch
+ AuthorityRevision
+ TransactionId
+ Domain Revision Token
```

Client Timestamp, Remote 도착 시각, Roblox Frame과 Presentation 완료 시점은 권위 순서를 결정하지 않는다.

### 7. Mutation 순서는 검증된 Commit Graph를 사용한다

다중 Mutation은 단순 배열이나 Event Callback 순서에 의존하지 않는다.

의존 관계를 가진 DAG를 준비하고 순환, 누락된 Read·Write Set과 Budget 초과를 Commit 전에 거부한다.

Commit 중 새 Mutation을 임의 삽입하지 않는다. 후속 규칙은 Aftermath 단계의 새 Execution 또는 Transaction으로 실행한다.

### 8. Commit은 하나의 권위 경계다

성공한 Transaction은 모든 Domain Mutation, Domain Revision, 하나의 AuthorityRevision, Commit Marker, Journal과 Raw Event Batch를 하나의 논리적 Commit으로 취급한다.

부분 Mutation을 Client에 공개하지 않는다.

### 9. Event와 Projection은 Commit 이후 생성한다

Raw Domain Event는 Commit 완료 후 생성한다.

Projection과 Presentation 전송 실패는 권위 Commit을 되돌리지 않고 Event 재생성, Catch-up 또는 Snapshot Resync로 복구한다.

### 10. Commit 중 실패는 Journal과 Commit Marker로 복구한다

Commit Marker가 없으면 Transaction은 미적용으로 처리한다.

Commit Marker가 있으면 동일 TransactionId를 기준으로 Store, Journal과 Event를 완료 상태로 재구성한다.

`committing` 상태에서 불명확한 자동 재실행을 하지 않는다.

### 11. 모든 Command에 전역 Revision 일치를 요구하지 않는다

각 Transaction은 실제로 필요한 Object, Inventory, Encounter, Scene Build와 Authority Epoch Precondition만 검증한다.

충돌 정책은 `strict_precondition`, `revalidate_on_latest`, `server_serialized`, `merge_if_non_conflicting`, `append_only` 중 명시한다.

### 12. DM Override도 Transaction을 우회하지 않는다

DM은 일부 게임 규칙 Precondition을 명시적으로 Override할 수 있지만 ID, Epoch, Schema, Commit Graph, Journal과 Atomic Commit 무결성은 우회하지 못한다.

Override 이유와 영향은 Audit Event로 남긴다.

### 13. Rollback은 역방향 Transaction 묶음이 아니다

DM Rollback은 과거 Snapshot을 기반으로 새 AuthorityEpoch 또는 Branch를 활성화한다.

이후 Timeline의 Transaction, Reservation, Prompt와 비동기 작업은 Epoch 불일치로 무효화한다.

## 결과

- 여러 Domain의 상태가 모두 적용되거나 모두 적용되지 않는다.
- 같은 Object와 Inventory를 변경하는 요청이 결정적 순서로 처리된다.
- 서로 무관한 Command의 병렬 준비를 유지할 수 있다.
- 반응 대기 중 장기 Lock을 피할 수 있다.
- Revision, Journal, Event와 Projection의 공개 순서가 일관된다.
- 서버 장애 후 Commit 여부를 정확히 복구할 수 있다.
- Rollback 이후 오래된 요청이 새 Timeline에 적용되지 않는다.
- DM Override도 감사 가능하고 구조적으로 안전하다.

## 비용과 주의점

- Ordering Key Registry와 Canonical 정렬 규칙이 필요하다.
- Domain Service가 Read Set, Write Set과 Mutation Proposal을 명확히 선언해야 한다.
- Write-ahead Journal, Commit Marker와 Recovery Worker가 필요하다.
- Transaction Graph와 Budget 검증 비용이 추가된다.
- 지나치게 넓은 Ordering Key는 불필요한 직렬화를 만들고, 지나치게 좁은 Key는 충돌 누락을 만든다.
- 구현 전 충돌·장애 주입 테스트가 필요하다.

## 비목표

- 모든 Command를 하나의 전역 Lock이나 Queue로 처리하지 않는다.
- 장기 Prompt 동안 Ordering Lock을 유지하지 않는다.
- Roblox Instance 변경을 권위 Commit으로 취급하지 않는다.
- Projection 전송 성공을 Transaction 성공 조건으로 삼지 않는다.
- Rollback을 모든 Transaction의 수동 역연산으로 구현하지 않는다.
