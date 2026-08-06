# ADR-0079: Encounter는 Policy 기반 Timeline과 Opportunity Gate로 진행한다

- 상태: 확정
- 결정일: 2026-08-04
- 관련 문서:
  - [`ADR-0034`](ADR-0034-encounter-initiative-turn-order-and-control-authority.md)
  - [`ADR-0048`](ADR-0048-continuous-gridless-movement-pc-only-and-no-combat-wasd.md)
  - [`ADR-0061`](ADR-0061-persistent-rule-execution-orchestrator-and-nested-timing-windows.md)
  - [`ADR-0062`](ADR-0062-ordered-reservations-and-atomic-authority-transactions.md)
  - [`ADR-0070`](ADR-0070-orthogonal-session-modes-contexts-overlays-and-transitions.md)
  - [`ADR-0076`](ADR-0076-real-time-exploration-with-actor-scoped-execution-and-atomic-encounter-transition.md)
  - [`ADR-0078`](ADR-0078-authoritative-game-time-boundary-durations-and-scheduled-execution.md)
  - [`Encounter Timeline Runtime 계약`](../architecture/encounter-timeline-turn-opportunity-and-objective-runtime-contract.md)

## 배경

기존 Encounter 설계는 서버 권위 참가자, 이니셔티브, 턴, 제어권과 종료 흐름을 확정했다. 그러나 다음 요구를 안정적으로 수용하려면 더 명확한 상위 결정이 필요하다.

- Combat뿐 아니라 Chase, Hazard, Escape와 Timed Objective에도 같은 기반을 사용해야 한다.
- 소환체, 환경 사건, Lair Action, Hidden Reserve와 중도 합류를 순서 중간에 삽입해야 한다.
- D&D 2024의 Action Economy를 지원하되 Encounter Engine이 행동 자체를 소유하면 안 된다.
- Counterspell 연쇄와 Reaction 중첩을 Encounter 전용 Stack으로 다시 구현하면 Rule Runtime과 책임이 겹친다.
- Pause, Rollback Review와 DM Authoring은 Base Mode가 아니라 Overlay다.
- 플레이테스트 후 Initiative, Objective, Timeout과 종료 방식을 바꿀 수 있어야 한다.
- D&D 2024에서 1 Round는 약 6초지만 각 참가자의 Turn마다 6초를 더하면 안 된다.

단순한 Initiative List나 FIFO Queue는 삽입, 반복 Entry, 예약 Entry, 환경 사건과 안정적 Rollback Identity를 충분히 표현하지 못한다.

## 결정

Encounter를 서버 권위 `EncounterSession`과 Versioned `EncounterPolicySet`으로 관리한다.

```text
Encounter Proposal
→ Participant·Faction·Policy 확정
→ Initiative 또는 Timeline 구축
→ Reveal·Tie Resolution
→ Timeline Revision Commit
→ Round·Turn·Opportunity 진행
→ Objective·End Candidate
→ Encounter End Transaction
```

### 1. Encounter는 Combat가 아니다

Encounter Kind는 다음과 같이 확장할 수 있다.

```text
combat
chase
hazard
escape
timed_objective
negotiation_sequence
puzzle_sequence
custom_registered
```

Combat는 기본 Policy Profile 중 하나다.

### 2. Encounter는 행동을 제공하지 않는다

행동은 Character Action, Spell, Interaction, Inventory, Item, Feature와 Effect Capability가 제공한다.

Encounter는 다음만 확정한다.

```text
현재 Turn·Occurrence
사용 가능한 Opportunity
Movement Budget
Turn·Round Usage Gate
Objective와 Encounter Context 제한
```

### 3. Initiative는 Timeline 구축 정책이다

내부 권위 구조를 단순 List나 FIFO Queue가 아니라 `InitiativeTimeline`으로 둔다.

```text
TimelineEntry Definition
+ TimelineOccurrence
+ Stable Cursor
+ Timeline Revision
```

Timeline은 Actor Turn뿐 아니라 Environment, Lair, Hazard, Objective Checkpoint와 Scripted Event Entry를 지원한다.

삽입·재정렬은 새 Timeline Revision으로 적용하고 이미 완료된 Occurrence 역사를 다시 쓰지 않는다.

### 4. Policy를 Encounter Core에서 분리한다

```text
Initiative Policy
Timeline Policy
Turn Policy
Opportunity Policy
Movement Policy
Objective Policy
Join·Leave Policy
Timeout Policy
Control Policy
Time Advance Policy
End Policy
Projection Policy
```

진행 중 Encounter는 시작 당시 Policy Version을 고정한다. 새 Policy는 다음 Encounter부터 적용하거나 명시적 Migration을 거친다.

### 5. Reaction은 RuleExecution Graph를 사용한다

Encounter 전용 Reaction Stack이나 Interrupt Stack을 만들지 않는다.

```text
Turn
→ Root RuleExecution
→ RuleEvent·TimingWindow
→ Child RuleExecution Graph
→ Root 재개
```

Encounter는 Opportunity 소비, 현재 Turn과 열린 Execution Reference만 추적한다.

### 6. Pause는 Overlay다

`paused`를 Encounter lifecycleState로 사용하지 않는다.

```text
Encounter active
+ Pause Overlay
```

Pause가 열린 RuleExecution, Resource Reservation과 Turn State를 자동 폐기하지 않는다.

### 7. D&D 2024 시간 정책

기본 Policy Pack은 다음을 사용한다.

```text
1 Round = 6 game seconds
individual Turn = Campaign Time 추가 없음
Delay = 없음
Ready = Action Capability + Reaction Release
```

Turn·Round Boundary Duration과 초·분 단위 Duration은 별도로 유지한다.

### 8. 종료는 End Candidate와 Transaction으로 처리한다

Objective 달성, 적대 세력 무력화, 도주, 항복 또는 DM 판단이 종료 후보를 만든다.

```text
End Candidate
→ 열린 실행과 Boundary 정리
→ DM 또는 End Policy 확인
→ EncounterEndTransaction
→ Exploration 또는 지정 Mode 전환
```

HP, 위치, Item, 문 상태와 지속 효과는 각각의 Runtime 수명주기를 유지한다.

## 역할 경계

### 플레이어

- 자신이 제어하는 Actor의 Action, Movement, Ready와 Reaction Command를 제출한다.
- 공개된 Timeline, Objective, Opportunity와 결과를 확인한다.

### DM

- Encounter 생성·종료, Participant·Faction·Timeline과 Objective를 관리한다.
- Hidden Reserve, Control Delegation, Timeout, Override와 Rollback을 관리한다.

### 시스템

- Policy 실행, Roll Reveal, Timeline Commit, Turn Boundary와 Opportunity Ledger를 관리한다.
- Objective Evaluation, Projection, Snapshot, Domain Event와 Recovery를 관리한다.

### Observer

- 공개 정책에 맞는 Encounter Projection을 보지만 Gameplay Command는 제출하지 않는다.

## 거부한 대안

### 단순 Initiative List

중간 삽입, 반복 환경 Entry, 안정적 Occurrence Identity와 Timeline Revision을 충분히 표현하지 못한다.

### FIFO Initiative Queue

현재 순서를 진행하는 데는 단순하지만 재정렬, 소유자 Turn 연결, 예약 Entry와 Round Boundary 표현이 부자연스럽다.

### Encounter가 Attack·Spell·Interaction을 직접 제공

기능별 행동 Runtime과 책임이 중복되고 새 행동을 추가할 때 Encounter Core를 수정해야 한다.

### Encounter 전용 Reaction Stack

Rule Runtime의 TimingWindow와 Parent·Child Execution Graph를 중복 구현하고 복구·중첩 규칙이 갈라진다.

### 모든 Objective 달성 시 자동 종료

역할극, 항복, 증원, 후속 사건과 DM 판정을 처리하기 어렵다.

### Turn마다 Campaign Time 6초 추가

한 Round 안의 참가자 행동이 세계관상 거의 동시에 일어난다는 D&D 시간 모델과 충돌한다.

## 결과

### 장점

- Combat 외 Encounter를 같은 엔진으로 지원할 수 있다.
- Initiative와 Objective 방식을 Policy 교체로 조정할 수 있다.
- 행동·반응·시간·이동 Runtime의 책임을 중복하지 않는다.
- 중도 합류, 소환체, 환경 사건과 Rollback을 안정적으로 처리할 수 있다.
- 플레이테스트 후 Core 수정 없이 전투 흐름을 변경하기 쉽다.

### 비용

- Timeline Entry와 Occurrence를 분리해야 한다.
- Policy Version, Timeline Revision과 Migration 관리가 필요하다.
- 단순 List UI 뒤에 더 구조화된 Runtime이 필요하다.
- Objective와 End Policy의 진단 Trace를 유지해야 한다.

## 후속 작업

- Encounter Runtime 구현 Spec 작성
- 기존 초기 Encounter 모델을 `SUPERSEDED` 참고 문서로 분류
- Combat README의 권위 읽기 순서 갱신
- Game Time, Action Opportunity, RuleExecution과 Encounter 통합 테스트 작성
- 다음 시나리오의 Simulation Test 작성
  - 중도 합류 후 Timeline 삽입
  - Reaction 중 재접속
  - Round 종료 6초 반영
  - Objective 달성 후 DM 종료 보류
  - Rollback 이후 이전 Turn Command 거부
