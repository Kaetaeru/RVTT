# ADR-0061. 영속 RuleExecution Orchestrator와 중첩 TimingWindow

- 상태: 확정
- 작성일: 2026-08-03
- 결정 범위: Capability 실행, Recipe Runtime, RuleEvent, TimingWindow, Reaction, PendingEffect, CommitGroup, 저장·복구와 Rollback
- 관련 문서:
  - [`Rule Runtime Orchestrator와 Pending Execution 계약`](../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md)
  - [`Rules Content Grant와 Capability 모델`](../architecture/rules-content-grant-capability-model.md)
  - [`EffectRecipe와 효과 해결·확정 모델`](../architecture/effect-recipe-resolution-and-commit-model.md)
  - [`Networking Command, Event와 Client Synchronization 계약`](../architecture/networking-command-event-and-client-synchronization-contract.md)
  - [`저장·세션 복구 모델`](../architecture/persistence-and-session-recovery-model.md)

## 배경

RVTT는 공격, 주문, 특성, 아이템, 함정, 준비 행동, 반응과 자동 Trigger를 같은 규칙 기반에서 처리해야 한다.

Capability, Recipe, Step, RuleEvent, TimingWindow, PendingEffect와 CommitGroup이 각각 존재하더라도 이들을 기능 코드가 직접 연결하면 다음 문제가 발생한다.

- 공격과 주문의 반응 처리 순서가 달라짐
- Prompt 대기 중 연결 종료 시 실행이 사라짐
- 반응이 다시 반응을 만들 때 무한 중첩됨
- 비용 예약, Roll 공개와 피해 Commit 시점이 기능마다 달라짐
- 이미 적용된 효과가 서버 복구 후 다시 적용됨
- Client Animation 실패가 권위 실행 실패로 이어짐
- DM Rollback 이후 이전 Prompt 응답이 새 Timeline에 적용됨
- Child Execution이 부모 Binding과 상태를 임의 수정함
- 긴 실행이 Actor와 Encounter Lock을 계속 보유해 세션을 막음

따라서 개별 Rule 기능보다 위에 있는 공통 실행 조정 계약이 필요하다.

## 결정

### 1. 모든 규칙 행동은 서버 권위 RuleExecution으로 표현한다

능동 행동, Trigger, 자동 처리, 환경 효과와 준비 행동 발동은 고유 `executionId`를 가진 RuleExecution을 생성한다.

Client는 실행 ID, 권위 결과와 Transaction ID를 생성하지 않는다.

### 2. Rule Runtime Orchestrator가 전체 실행 생명주기를 조정한다

Orchestrator는 Capability 검증, 비용 예약, Recipe 시작, TimingWindow, Child Execution, Commit 준비, 저장·복구와 종료를 조정한다.

개별 공격, 주문과 Feature 규칙은 Recipe, Step Handler와 Domain Service가 소유한다.

Orchestrator를 모든 규칙을 직접 계산하는 거대한 Manager로 만들지 않는다.

### 3. 실행은 저장 가능한 명시적 상태기계를 가진다

기본 상태는 다음과 같다.

```text
created
→ validating
→ reserving
→ running
→ waiting_input | waiting_timing_window | waiting_child | waiting_presentation_gate
→ preparing_commit
→ committing
→ resolving_aftermath
→ completed
```

취소, 거부, 안전 실패, 만료와 대체는 구분된 터미널 상태를 사용한다.

Prompt와 Reaction 대기는 임시 Remote 호출 상태가 아니라 저장 가능한 권위 실행 상태다.

### 4. RuleEvent와 실행 Phase를 타입으로 고정한다

공격 굴림 전후, 피해 적용 직전, 이동 Reach 이탈과 같은 개입 지점은 임의 문자열 Callback이 아니라 중앙 Catalog의 RuleEvent와 Phase를 사용한다.

Event Handler가 부모 상태를 직접 수정하지 않고 TimingWindow, Modifier, Override 또는 Child Execution을 통해 개입한다.

### 5. 반응과 선택형 Trigger는 중첩 가능한 TimingWindow Stack을 사용한다

TimingWindow는 Source Event, 응답자, 후보 Capability, 공개 정보, 순서와 Deadline을 가진다.

반응이 새로운 사건을 만들면 Child Execution과 새 TimingWindow를 Stack 위에 열 수 있다.

최대 깊이, Root Budget, Cycle Key와 동일 Event 중복 방지로 무한 연쇄를 차단한다.

### 6. Trigger 후보는 Index로 조회한다

모든 Event마다 모든 Actor와 Feature를 전체 순회하지 않는다.

Grant, Event Type, Timing Point와 Actor 관계를 기준으로 후보를 찾는 Trigger Index를 사용하고, 권한·Usage Gate·공개 정보를 서버에서 다시 검증한다.

### 7. 비용은 예약과 소비 확정을 분리한다

행동, 반응, 주문 슬롯, Feature 횟수와 아이템 Charge는 실행 중 중복 사용을 막기 위해 예약할 수 있다.

실제 소비 시점은 `CostCommitPolicy`가 정의하며 선언, Roll 공개, 효과 Commit 또는 실행 완료 중 규칙에 맞는 지점에서 Commit한다.

취소 가능한 단계에서 종료되면 예약을 반환한다. 이미 규칙상 소비가 확정된 비용은 단순 실패로 되돌리지 않는다.

### 8. Recipe Runtime은 Orchestrator의 하위 실행기다

Compiled Recipe는 BindingStore와 Execution Context를 받아 실행된다.

Step Handler는 Orchestrator 상태, TimingWindow Stack과 권위 Store를 직접 변경하지 않는다.

Child Execution은 별도 BindingStore를 가지며 선언된 Typed Import·Export만 부모와 공유한다.

### 9. 영구 상태 변경은 PendingEffect와 CommitGroup만 사용한다

Recipe와 Child Execution은 PendingEffect를 생성한다.

Orchestrator는 Modifier, TimingWindow와 최신 Precondition을 반영해 CommitGroup을 구성한다.

CommitGroup은 원자적으로 성공하거나 실패한다.

여러 CommitGroup이 필요한 실행은 각 경계가 독립된 규칙상 확정 지점이어야 하고, 이미 Commit된 Group을 RecoveryRecord에 기록한다.

### 10. 부모·자식 실행은 명시적 Join Policy를 사용한다

초기 정책:

- `inline_blocking`
- `parallel_collect`
- `independent_after_commit`
- `replace_parent_path`

반응은 일반적으로 부모를 일시 중지하는 Child Execution이다. 사후 Trigger는 부모 Commit 이후 독립 실행할 수 있다.

### 11. 긴 대기 중 권위 Lock을 유지하지 않는다

입력, Reaction, DM 판정과 Presentation Gate를 기다릴 때 Ordering Lock을 계속 보유하지 않는다.

Revision Token과 Reservation을 저장하고 Lock을 해제한다. 재개 시 최신 상태를 다시 검증하고 Commit 직전에 필요한 Key를 다시 확보한다.

### 12. Presentation Gate는 공개 시점만 조정한다

주사위 Animation 같은 연출은 권위 Roll 값과 규칙 결과를 결정하지 않는다.

서버가 Roll을 생성·봉인한 뒤 Ack 또는 Deadline까지 공개만 지연할 수 있다.

Client 이탈과 연출 실패 시 서버가 결과를 공개하고 실행을 계속할 수 있다.

### 13. Pending RuleExecution은 Snapshot과 Journal로 복구한다

저장 대상에는 실행 상태, Recipe Hash, BindingStore, 비용 예약, Roll, PendingEffect, Commit된 Group, TimingWindow, Prompt와 Child Directory가 포함된다.

복구 시 이미 Commit된 Group과 처리된 응답을 다시 실행하지 않는다.

### 14. Rollback은 새 Authority Epoch에서 실행 Directory를 복원한다

현재 실행을 역연산하지 않는다.

과거 Snapshot을 새 Branch와 Authority Epoch로 활성화하고 당시 Pending Execution Directory를 복원한다.

이전 Epoch의 Prompt, Offer, Command와 비동기 작업은 거부한다.

### 15. 실행 상태는 사용자별 Projection으로 공개한다

Client는 자신의 Role, Control과 공개 범위에 맞는 Execution, Prompt와 Offer만 받는다.

숨겨진 함정의 실행 원본, 다른 사용자의 비공개 Trigger 후보와 DM 전용 판정 정보는 보내지 않는다.

## 결과

- 공격, 주문, Feature, Item과 환경 Trigger가 같은 실행 흐름을 사용한다.
- Reaction과 중첩 Trigger의 순서, 저장과 복구가 일관된다.
- 비용과 효과가 중복 Commit되는 문제를 멱등성과 Execution Record로 방지한다.
- Pending Prompt와 Reaction을 재접속 후 복구할 수 있다.
- Presentation 실패와 권위 실행 실패를 분리한다.
- Child Execution과 Binding 공유 범위가 명확해진다.
- Rule Runtime 구현 명세가 공통 상태기계와 서비스 경계를 기준으로 분할될 수 있다.

## 비용과 주의점

- RuleExecution Registry, 중앙 Scheduler, Trigger Index와 TimingWindow Coordinator가 필요하다.
- Pending Execution Snapshot과 Recovery Migration을 관리해야 한다.
- 동시에 많은 Trigger 후보가 생기는 상황의 Budget과 UX를 측정해야 한다.
- D&D의 일부 동시 처리 예외를 Ruleset Provider가 명시적으로 등록해야 한다.
- 실행 Trace가 과도하게 커지지 않도록 상세 수준과 보존 정책이 필요하다.

## 비목표

- 개별 주문, Feature와 Item의 세부 규칙을 이 ADR에서 정의하지 않는다.
- 모든 동시 처리를 하나의 전역 Priority 숫자로 고정하지 않는다.
- 자유 텍스트 DM 판단을 자동으로 권위 상태에 적용하지 않는다.
- Client 물리, Animation과 UI 상태를 RuleExecution의 권위 원본으로 사용하지 않는다.
