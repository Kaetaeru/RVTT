# ADR-0080: Downtime은 Campaign Time을 조정하는 Activity Session이며 결과는 각 Domain이 소유한다

- 상태: 확정
- 결정일: 2026-08-04
- 관련 문서:
  - [`Session Play Mode, Context, Overlay와 Transition 계약`](../architecture/session-play-mode-context-overlay-and-transition-contract.md)
  - [`Game Time, Calendar, Duration과 Scheduler Runtime 계약`](../architecture/game-time-calendar-duration-and-scheduler-runtime-contract.md)
  - [`Downtime Activity, Time Coordination과 Atomic Completion Runtime 계약`](../architecture/downtime-activity-time-coordination-and-atomic-completion-runtime-contract.md)
  - [`Character Runtime과 Compiled Character Build 계약`](../architecture/character-runtime-and-compiled-character-build-contract.md)
  - [`Command Ordering, Logical Time와 Transaction Coordinator 계약`](../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)

## 배경

RVTT의 Downtime에는 서로 다른 종류의 장기 활동이 들어간다.

- Short Rest와 Long Rest
- 레벨업과 Character Build Migration
- 주문 준비 변경과 주문책 작업
- 제작과 훈련
- 여행 시간 정산

이 기능들을 각각 독립된 UI와 Timer로 구현하면 다음 문제가 생긴다.

- 한 캐릭터에게만 시간이 흐르고 다른 캐릭터는 같은 시각에 남을 수 있다.
- 휴식과 제작을 동시에 진행할 때 시간 합산 방식이 달라진다.
- 여행 중 사건이나 휴식 방해를 건너뛸 수 있다.
- 레벨업이 Character Build를 직접 수정하고, 제작은 Inventory를 직접 수정하는 식으로 권위 경계가 깨진다.
- 장시간 진행 중 연결 종료·서버 복구·Rollback 시 선택과 재료 예약이 유실된다.
- 새 Downtime 종류를 추가할 때 Core 분기문을 계속 수정하게 된다.

## 결정

Downtime을 `Base Play Mode`로 유지하고, 모든 장기 활동을 서버 권위 `DowntimeSession`과 등록된 `DowntimeActivity`로 조정한다.

```text
Downtime Proposal
→ 참가자와 Activity 배정
→ 선택·비용·Reservation 검증
→ 동시 Activity Window 구성
→ 가장 가까운 Checkpoint까지 Campaign Time Advance
→ 중간 사건·중단·선택 해결
→ Domain Completion Plan 생성
→ Atomic Completion Transaction
```

### 1. Campaign Time은 하나다

초기 제품은 참가자별 독립 세계 시간을 만들지 않는다.

```text
A가 8시간 제작
B가 8시간 훈련
→ 같은 Downtime Window에서 병렬 진행
→ Campaign Time은 8시간 진행
```

시간을 진행하기 전에 관련 참가자에게 Activity 또는 승인된 기본 Passage Policy를 배정한다.

### 2. Downtime은 결과 규칙을 소유하지 않는다

```text
Rest Domain
→ RecoveryPlan

Character Domain
→ Progression Source, Candidate Build와 Migration

Spell Domain
→ Preparation·Repository 변경

Inventory Domain
→ 재료 소비와 Output ItemInstance

Game Time Runtime
→ 실제 시간 진행과 Scheduler
```

Downtime Runtime은 이 결과를 조정하고 한 Completion 경계에 모으지만 다른 Domain Store를 직접 수정하지 않는다.

### 3. Activity는 데이터와 Provider로 확장한다

각 Activity는 Definition, Compiled Build와 Runtime Instance로 분리한다.

```text
DowntimeActivityDefinition
→ Compiler
→ CompiledDowntimeActivityBuild
→ DowntimeActivityInstance
```

Eligibility, Time, Progress, Interruption과 Completion은 등록된 Provider가 담당한다. 임의 저장 Luau Callback은 허용하지 않는다.

### 4. 시간은 Checkpoint 단위로 진행한다

긴 휴식이나 여행을 한 번에 끝 시각까지 점프하지 않는다.

```text
요청 종료 시각
+ Scheduler Due
+ Activity Milestone
+ Rest·Travel Event
→ 가장 가까운 Checkpoint
```

중간 사건이 발생하면 Downtime을 `suspended`로 두고 사건 해결 후 남은 활동을 재검증한다.

### 5. Completion은 원자적이다

활동 시간 충족만으로 결과를 바로 적용하지 않는다.

```text
Completion Candidate
→ Domain Provider 최신 검증
→ 필수 선택 완료
→ Completion Plan
→ Ordering Reservation
→ Authority Transaction
```

제작 재료 소비와 완성품 생성, Character Source·Build·State 교체처럼 결합된 변경은 하나의 Commit으로 처리한다.

### 6. 장시간 Ordering Lock을 유지하지 않는다

진행 중에는 Item, Resource, Facility와 Activity Slot을 위한 타입 있는 Domain Reservation을 사용한다. Ordering Reservation은 Completion Commit 직전에만 짧게 획득한다.

### 7. 현실 시간은 Downtime을 완료하지 않는다

벽시계 시간이 지나거나 플레이어가 오프라인이라는 이유로 활동이 자동 완료되지 않는다. 권위 Campaign Time Advance가 Commit될 때만 Activity Progress가 진행된다.

## 결과

### 장점

- 모든 참가자의 장기 활동이 하나의 Campaign Time과 일관되게 연결된다.
- 휴식·제작·훈련·여행을 같은 Checkpoint와 중단 계약으로 처리할 수 있다.
- Character·Spell·Inventory 규칙의 권위가 각 Domain에 남는다.
- 실패 시 기존 Build·State·Item이 손상되지 않는다.
- 재접속·복구·Rollback 시 Activity와 Reservation을 복원할 수 있다.
- 새 Activity를 Registry로 추가할 수 있다.

### 비용

- 단순 버튼형 휴식보다 Session, Activity, Reservation과 Checkpoint 상태가 많아진다.
- 여러 참가자의 활동 배정과 미응답 Fallback 정책이 필요하다.
- 각 Domain은 Completion Provider와 Mutation Proposal 계약을 제공해야 한다.
- 긴 시간 진행은 중간 Checkpoint마다 재검증하므로 구현 복잡도가 증가한다.

## 거부한 대안

### 대안 A: 기능마다 자체 Timer와 완료 Handler를 둔다

거부한다. 시간 권위, 저장·복구와 중간 사건 처리가 시스템마다 달라진다.

### 대안 B: 플레이어마다 독립 Downtime Clock을 둔다

거부한다. 같은 Campaign 세계에서 Character들의 날짜와 사건 순서가 갈라진다.

### 대안 C: 활동 시작 시 비용을 전부 소비하고 종료 시 Output만 생성한다

거부한다. 중단·오류 시 입력만 사라지는 부분 성공이 발생한다.

### 대안 D: Downtime Runtime이 Character·Inventory Store를 직접 수정한다

거부한다. Domain 권위를 우회하고 규칙 중복과 순환 의존성을 만든다.

### 대안 E: 현실 시간으로 오프라인 제작·훈련을 완료한다

초기 제품에서 거부한다. 게임 세계 시간과 현실 시간이 혼합되고 DM의 사건·시간 통제권이 사라진다.

## 후속 작업

- Downtime Activity Registry와 공통 Schema Spec
- RestSession·RecoveryPlan 구현 Spec
- Character Build Migration과 Level Up Flow Spec
- Spell Preparation·Spellbook Work Completion Provider
- Crafting Input Reservation·Output Transaction Spec
- Travel Checkpoint·Encounter Resume Spec
- Downtime Planner와 DM Activity Review UI
