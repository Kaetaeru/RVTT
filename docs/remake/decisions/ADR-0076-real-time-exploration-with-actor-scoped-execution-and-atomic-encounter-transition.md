# ADR-0076: Actor 범위 실행 조정과 원자적 Encounter 전환을 사용하는 실시간 Exploration

- 상태: Accepted
- 작성일: 2026-08-04

## Context

Exploration에서는 여러 플레이어가 WASD·클릭 이동, 상호작용, 공격, 주문과 탐색을 동시에 수행할 수 있다.

이를 단순한 자유 모드로 구현하면 다음 문제가 발생한다.

- 이동과 주문이 서로 모순된 상태로 동시에 Commit됨
- 함정 발동 이후에도 Client 이동이 계속 적용됨
- 공격과 Encounter 시작 사이에 중복 행동이 들어옴
- 같은 Item·문·통로에 대한 경쟁 상태
- 장시간 행동과 Scene·Encounter 전환 충돌

반대로 Session 전체에 단일 실행 Lock을 두면 다른 플레이어의 정상 탐험까지 과도하게 정지한다.

## Decision

Exploration을 실시간 Base Play Mode로 유지하되, Actor별 실행 슬롯과 Capability별 동시 실행 정책을 사용한다.

```text
Exploration Intent
→ Actor-scoped Execution State
→ Movement / RuleExecution / Interaction
→ Transaction Commit
```

기본 실행 슬롯:

- movement
- primary rule execution
- interaction
- long action
- reaction or interrupt

Capability는 이동과의 관계를 명시한다.

```text
continue_movement
pause_movement
stop_movement
replace_movement
requires_stationary
```

Exploration에서 Encounter로 전환할 때는 다음을 하나의 전환 경계로 처리한다.

```text
참가자·진영·인지 Snapshot
+ 관련 Actor Command Gate
+ 진행 중 실행 분류
+ Initiative Roll·Reveal
+ EncounterSession Commit
```

진행 중 실행은 완료, 동결, Encounter 실행으로 변환, 규칙에 따른 취소 또는 Checkpoint Commit 중 하나로 명시적으로 분류한다.

## Consequences

### Positive

- 여러 플레이어가 불필요하게 서로를 막지 않고 동시 탐험할 수 있다.
- 이동·상호작용·주문 충돌을 일관된 방식으로 해결할 수 있다.
- 함정과 적대 행동에서 전투 전환 중 중복 Command를 막을 수 있다.
- 기존 Navigation, Interaction, RuleExecution과 Transaction Runtime을 재사용한다.
- 플레이테스트 후 Capability별 이동 중 실행 정책을 데이터로 조정할 수 있다.

### Negative

- Actor별 실행 상태와 Lock 진단이 필요하다.
- 전환 시 진행 중 실행 분류표를 각 Capability가 제공해야 한다.
- WASD Client Prediction과 서버 Checkpoint의 동기화가 필요하다.
- 동시 실행 테스트 사례가 크게 늘어난다.

## Rejected Alternatives

### Exploration에서도 Turn 사용

일반 탐험의 반응성과 다중 사용자 자유도를 지나치게 제한하므로 거부한다.

### 완전한 무제한 실시간 실행

서로 모순되는 상태와 전환 경쟁을 안전하게 해결할 수 없으므로 거부한다.

### Session 전체 Global Lock

한 Actor의 상호작용이나 함정 때문에 모든 참가자를 불필요하게 멈추므로 거부한다.

### 공격 입력 즉시 Encounter 시작

은밀한 공격, 파괴 가능한 물체 공격, 즉시 해결 가능한 장면과 DM 판정을 구분하지 못하므로 거부한다.
