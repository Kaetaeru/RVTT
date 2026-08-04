# Main System Guide: Combat와 Encounter

- Guide Status: CURRENT
- 적용 시스템 상태: GUIDE_CURRENT
- 작성일: 2026-08-05
- 마지막 권위 문서 검토일: 2026-08-05
- Completion Audit: [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)
- 대체하는 Guide: 없음
- 대체된 Guide: 없음

> 이 Guide는 기존 권위 문서를 연결하고 설명한다. 새로운 규칙·결정·API·데이터 구조를 정의하지 않는다.

## 1. 시스템 목적과 사용자 결과

이 Guide는 Exploration에서 발생한 적대 행동·위험·제한 시간 사건이 Encounter로 전환되고, 참가자와 진영을 확정하고, 이니셔티브를 공개한 뒤, Timeline·Turn·Opportunity·Objective를 따라 진행하며, 공격·주문·이동·반응·피해·HP 0·죽음·시간 경계와 종료 결과를 안전하게 Commit하고, 필요하면 DM이 과거 턴 경계로 Rollback하는 전체 흐름을 설명한다.

사용자에게 보장하는 결과:

- Encounter는 Combat와 동의어가 아니며 Combat, Chase, Hazard, Escape와 Timed Objective를 같은 순서·목표 Runtime으로 처리할 수 있다.
- Encounter는 Exploration 위에 겹치는 단순 UI가 아니라 Session의 Base Play Mode다.
- Pause, Rollback Review와 DM Authoring은 Encounter 수명주기 상태가 아니라 별도 Overlay·Transition이다.
- Encounter 시작 시 Scene, Actor, Character, HP, Item과 Effect 상태를 복사하지 않고 Stable Reference와 Revision만 연결한다.
- 진행 중 Encounter는 시작 당시의 Frozen Ruleset·Encounter Policy를 유지하며 중간에 최신 설정으로 조용히 바뀌지 않는다.
- 이니셔티브 Roll이 필요한 경우 필수 결과가 공개되고 동률 처리가 끝나기 전에 임시 순서로 첫 Turn을 시작하지 않는다.
- 내부 순서는 단순 Initiative 숫자 배열이나 FIFO Queue가 아니라 Timeline Entry, Timeline Occurrence, Cursor와 Timeline Revision으로 관리한다.
- UI는 Initiative Ribbon처럼 보일 수 있지만 완료된 Occurrence의 역사 순서를 사후에 다시 쓰지 않는다.
- Encounter는 공격·주문·아이템·상호작용을 제공하지 않고 현재 Actor가 사용할 Opportunity, Movement Budget와 순서만 제공한다.
- 실제 행동 후보는 Character Action, Spell, Interaction, Inventory, Item과 Effect Capability에서 온다.
- 전투 중 토큰 WASD 이동은 금지하고 Path Preview와 Movement Budget을 사용하는 권위 클릭 이동만 허용한다.
- Dash, Difficult Terrain, Speed와 특수 이동은 Action·Effect·Navigation Contribution을 통해 같은 Movement Runtime에서 계산한다.
- Reaction과 Interrupt는 Encounter 전용 Stack을 만들지 않고 RuleEvent·TimingWindow·Child RuleExecution Graph를 사용한다.
- D&D 2024 기본 Policy에서는 Ready를 지원하고 Delay는 제공하지 않는다.
- 피해 굴림과 HP 변경을 분리하고, RollRecord가 HP·Effect·Encounter Store를 직접 수정하지 않는다.
- 최종 피해, Temporary HP, Current HP, VitalState, DeathSave Lifecycle과 확정적 Opportunity·Reservation 정리는 하나의 Cross-Domain Immediate Closure로 Commit할 수 있다.
- HP 0, 의식불명, 죽어감, 안정화, 사망과 Encounter Participant 상태를 같은 값으로 합치지 않는다.
- Actor가 사망해도 Character, Inventory, Actor Runtime Object와 시체 Presence를 자동 삭제하지 않는다.
- 피해 후 집중 내성, 사망 후 Objective·Morale 평가와 실제 Turn Cursor 진행은 Commit 이후 별도 Deferred Command 또는 RuleExecution으로 처리한다.
- Damage Provider가 Encounter Cursor를 직접 이동하거나 Encounter를 직접 종료하지 않는다.
- Objective 달성 후보가 생겨도 End Policy 또는 DM 확인을 거쳐 Encounter End Candidate와 End Transaction으로 종료한다.
- Encounter 종료 시 Actor 위치·HP·시체·바닥 Item·문·함정·지속 Effect·Knowledge를 전투 전 상태로 초기화하지 않는다.
- D&D 2024 기본 Policy에서 완전히 끝난 한 Round는 Campaign Game Time 6초이며 개별 Turn·Reaction·추가 Entry마다 6초를 더하지 않는다.
- Round 종료, Campaign Time Advance와 Scheduler Due Staging은 하나의 원자적 Temporal Boundary Transaction으로 Commit한다.
- Scheduler는 Due Occurrence를 만들 뿐 피해·Effect·Encounter Timeline을 직접 수정하지 않으며 Event Subscriber가 새 Command 또는 RuleExecution을 제출한다.
- Blocking Due와 필수 RuleExecution이 남아 있으면 Boundary Gate가 다음 Round 시작을 안전하게 막는다.
- 같은 Campaign Chronology의 여러 Encounter가 조정 없이 각각 6초를 더하지 않는다.
- 플레이어 연결 종료와 Control 위임이 Character Ownership이나 Information Visibility를 자동 변경하지 않는다.
- DM Rollback은 현재 상태를 역연산하지 않고 안전한 Encounter Checkpoint를 새 Branch·AuthorityEpoch로 복원한다.
- Rollback 이후 이전 Branch의 Command, Reaction 응답, Timeout, Due Occurrence, Roll과 Presentation ACK를 현재 Branch에 재사용하지 않는다.
- 재접속·서버 Recovery 후 Timeline, Cursor, Opportunity, Pending RuleExecution, Round Time Ledger와 현재 Projection을 권위 Snapshot에서 복원한다.
- Player, DM과 Observer는 같은 Encounter를 보더라도 각자의 Disclosure Policy에 맞는 Timeline·Objective·Roll·상태 정보만 받는다.

적용 범위:

- Encounter Proposal, Preparation, Activation, Active, Ending과 Ended 수명주기
- Combat·Chase·Hazard·Escape·Timed Objective 등 Turn 기반 Encounter
- Participant, Faction, Awareness, NonParticipant와 Control Assignment
- Initiative Policy, Roll·Reveal·Tie Resolution과 Timeline Commit
- Timeline Entry, Occurrence, Cursor, Round와 Turn Boundary
- Action Opportunity, Bonus Action, Reaction, Object Interaction과 Movement Budget Ledger
- 전투 클릭 이동, Trigger Boundary 정지와 Movement Reaction 연결
- RuleExecution·TimingWindow를 통한 Reaction, Interrupt와 Ready
- Damage·Healing·Temporary HP·VitalState·DeathSave·Death 통합
- Objective Progress, End Candidate와 Encounter End Transaction
- Round Time Ledger, Temporal Boundary, Campaign Game Time와 Scheduler Due Bridge
- 같은 Scene의 비참가자, 중도 합류, 이탈, Timeline 삽입과 Control 위임
- Pause, Timeout, DM Override와 Recovery Gate
- Encounter Turn Checkpoint, Branch Rollback과 Full Client Resync
- Player·DM·Observer Projection, Combat HUD 진입점과 진단

명시적 비범위:

- 공격·주문·Feature·Item·EffectRecipe의 세부 규칙 해결
- Character 성장 Source, 레벨업, 장비와 Inventory의 전체 수명주기
- Scene Source, Runtime Object, Navigation과 Spatial Query의 내부 구현
- Exploration의 Selection·Perception·Interaction 전체 흐름
- 모든 Encounter 종류의 콘텐츠와 Objective 데이터
- AI 전술 의사결정과 NPC 자동 플레이
- Combat HUD, Dice, Camera와 VFX의 구체적인 레이아웃·애니메이션 구현
- 실제 Roblox Module 경로와 최종 Luau Type·Schema
- Timeline Entry 수, Timeout, Batch, Snapshot 간격과 저장 보존 기간의 측정형 기본값
- 플레이어에게 이미 공개된 비밀 정보의 인간 기억 제거
- 음악과 모든 규칙 효과음

## 2. 전체 구조

### Encounter 시작

```text
Exploration의 적대 행동·탐지·Hazard·DM Start
→ Encounter Proposal
→ Participant·Faction·Awareness·Control·Objective 후보
→ Frozen Ruleset·Encounter Policy 고정
→ Initiative Roll 또는 Timeline Build
→ Reveal·Tie Resolution
→ Timeline Revision + 첫 Cursor Commit
→ Encounter Base Mode 활성
```

### 활성 Encounter

```text
Timeline Cursor
→ Timeline Occurrence
→ Turn Start Boundary
→ Opportunity Ledger·Movement Budget
→ Controller Intent
→ Action·Spell·Interaction·Inventory Capability
→ RuleExecution·MovementExecution
→ Reaction·Roll·PendingEffect
→ Cross-Domain Transaction
→ Turn End Gate
→ 다음 Occurrence 또는 Round Boundary
```

### 피해·죽음·Objective

```text
Attack·Save·Automatic Outcome
→ Final Damage Candidate
→ Temporary HP·Current HP·VitalState·DeathSave Immediate Closure
→ Authority Transaction
→ Damage·Vital Domain Event
→ Concentration·Trigger·Objective Deferred Consequence
→ End Candidate 가능
```

### Round와 Campaign Time

```text
마지막 Timeline Occurrence 완료
→ Round End Candidate
→ TemporalBoundaryCandidate
→ Encounter Time Contribution
→ Encounter Round + Campaign Time + Scheduler Due Staging 원자 Commit
→ Outbox Subscriber
→ Blocking Due Command·RuleExecution
→ Boundary Gate 해제
→ 다음 Round
```

### Encounter 종료

```text
Objective·도주·항복·DM·규칙 종료 후보
→ End Policy와 DM 확인
→ 신규 관련 Command Gate
→ 열린 실행·Reaction·Temporal Boundary 정리
→ Encounter End Cross-Domain Transaction
→ Encounter-bound Opportunity·Effect·Control 정리
→ Session Base Mode 전환
→ Projection·HUD 전환
```

### Rollback

```text
DM이 Checkpoint 선택
→ 현재 Branch와 대상 상태 Diff
→ E 승인 / Q 취소
→ 신규 Command Gate와 안전 Boundary 도달
→ 대상 Snapshot + Delta 복원
→ 새 Branch·AuthorityEpoch 활성
→ Derived View·Projection 재구성
→ Full Encounter Resync
→ 새 Branch에서 진행
```

## 3. 주요 데이터 흐름

### 3.1 Encounter Policy

```text
Ruleset Policy Pack
+ Source Pack Patch
+ Campaign·Scope Binding
→ Frozen Policy Snapshot
→ EncounterPolicySet
→ EncounterSession이 Version 고정
```

Encounter Policy는 Initiative, Timeline, Turn, Opportunity, Movement, Objective, Join·Leave, Timeout, NonParticipant, Time Advance, End와 Projection 방식을 제공한다.

Policy는 Encounter·Actor·HP Store를 직접 변경하지 않는다. Encounter Runtime이 Policy 결과를 사용해 Command와 Transaction을 만든다.

### 3.2 EncounterSession과 Domain State

```text
EncounterSession
├─ Scene Scope Reference
├─ Participant·Faction Binding
├─ Timeline·Turn·Objective State
├─ Opportunity·Movement Binding
├─ Control Assignment Reference
├─ Open RuleExecution Reference
├─ End Candidate
├─ Round Time Ledger
└─ Snapshot Cursor
```

별도 권위 원본:

- Actor 위치와 Scene Presence: Runtime Object·Navigation Domain
- HP·Temporary HP·VitalState·DeathSave: Character·Actor Domain
- Item과 Resource: Inventory·Character Domain
- 지속 Effect: EffectRegistry
- Action·Spell 실행: RuleExecution
- Campaign Game Time: Game Time Runtime

Encounter는 이 상태를 복사해 독립 원본으로 만들지 않는다.

### 3.3 Participant, Faction과 Control

```text
Actor Reference
+ Encounter Participation Policy
+ Awareness·Disclosure
→ EncounterParticipantBinding

Participant Binding
+ 관계·공유 Policy
→ FactionBinding

Actor Ownership
+ Session Role
+ 위임 Policy
→ EncounterControlAssignment
```

다음을 분리한다.

```text
Character Ownership
≠ Runtime Control Assignment
≠ Encounter Participation
≠ VitalState
≠ Information Visibility
```

### 3.4 Timeline Entry와 Occurrence

```text
Initiative Evidence·Fixed Policy·Group Policy
→ TimelineEntry Definition
→ Timeline Revision Commit
→ Round별 TimelineOccurrence
→ Stable activeCursor Reference
```

- `TimelineEntry`: 반복 가능한 Actor Turn·Group Turn·Environment·Hazard·Objective Entry 정의
- `TimelineOccurrence`: 특정 Round에서 실제로 열린 발생
- `timelineRevision`: 삽입·재정렬이 적용되는 새 Timeline 버전
- `activeCursor`: 배열 Index가 아니라 현재 Occurrence Reference

완료된 Occurrence의 과거 순서를 사후 수정하지 않는다.

### 3.5 Turn과 Opportunity

```text
TimelineOccurrence
→ ActiveTurnState
→ Opportunity Ledger
→ Action·Bonus Action·Reaction·Movement Budget
→ Capability Reservation·Consumption
```

Opportunity는 다음 상태를 가진다.

```text
available
→ reserved
→ consumed | released | expired
```

Encounter는 Opportunity를 생성·만료하고, 실제 Capability가 어떤 Opportunity를 요구하는지는 Character Action·Spell·Interaction Runtime이 선언한다.

### 3.6 Damage, Vital과 Death

```text
RollRecord·ResolutionOutcome
→ Damage Component Resolution
→ CrossDomainOutcomeCandidate
→ Damage·Vital·Effect·Encounter Provider Contribution
→ Immediate Closure Graph
→ Authority Transaction
→ Projection Barrier
```

같은 Transaction에 포함할 수 있는 확정 변화:

- Temporary HP 흡수
- Current HP 변화
- Instant Death 평가
- VitalState 변화
- DeathSave Lifecycle 생성·종료
- 즉시 무효인 Capability·Opportunity·Reservation 정리
- Encounter Participant Eligibility와 현재 Turn Gate 변화

별도 후속 실행:

- Concentration Check
- On-damage Trigger와 Reaction
- Morale·Surrender
- Objective Evaluation
- Turn Advance Command

### 3.7 Temporal Boundary

```text
Encounter Round Boundary
→ TemporalBoundaryCandidate
→ Snapshot-bound EncounterTimeAdvanceContribution
→ Encounter·Game Time·Scheduler Write Set
→ TemporalBoundaryOccurrence
→ ScheduledDueOccurrence
```

저장 대상:

- Boundary Sequence와 멱등성 Key
- RoundTimeLedger
- Campaign Time Revision
- Scheduler Cursor와 Due Lifecycle
- Boundary Gate
- Frozen Policy Reference

Due Staging은 실제 Gameplay Effect 적용이 아니다.

### 3.8 Encounter Snapshot과 Branch

```text
EncounterBaseSnapshot
+ TurnDeltaJournal
+ MaterializedTurnSnapshot
→ EncounterTurnCheckpoint
→ Rollback Diff
→ 새 Branch 복원
```

Snapshot 범위에는 Encounter 상태만이 아니라 해당 시점의 Actor, Resource, Dynamic Scene Object, Fog·Detection, Control, Resolution Ledger, Campaign Game Time, Scheduler와 Pending Execution이 포함될 수 있다.

저장하지 않는 것:

- Camera Transform
- Hover와 열린 Tooltip
- 제출 전 이동 Preview
- Dice 물리 위치
- Tween·VFX 진행률
- Client Hotbar 임시 상태

## 4. 주요 실행 흐름

### 4.1 Exploration에서 Encounter Proposal 생성

```text
적대 Action·Spell·Detection·Hazard·DM 명령
→ 원인 RuleExecution 또는 Event Commit
→ 참가자·진영·Awareness·Scene Scope 후보
→ Encounter Proposal
```

공격 버튼을 선택했다는 이유만으로 검증 전 Encounter를 즉시 시작하지 않는다. 적대 관계, 순서 필요성, 위험 Context와 Policy를 평가한다.

### 4.2 Preparation과 Participant 확정

```text
Encounter Proposal
→ Actor·Runtime Object Incarnation 검증
→ Participant·Faction·Awareness 확정
→ Controller와 비참가자 Policy 확정
→ Objective·Encounter Kind 확정
→ Frozen Policy Snapshot 고정
→ preparing 상태 Commit
```

같은 Scene의 모든 Actor를 자동 참가시키거나 정지하지 않는다.

### 4.3 Initiative Roll과 Timeline 활성화

```text
Participant Snapshot
→ Initiative Policy
→ RollPlan 또는 Fixed·Group Entry Draft
→ SealedRollResult
→ audience별 Presentation·Reveal
→ RollRecord
→ Tie Resolution
→ Timeline Revision과 첫 Cursor 원자 Commit
→ Encounter active
```

필수 이니셔티브 결과가 공개되기 전에 임시 순서를 Turn 권위로 사용하지 않는다.

### 4.4 Turn Start

```text
Timeline Cursor가 Occurrence 활성화
→ Turn Start RuleEvent
→ Turn-bound Effect·Recharge·Death Save·Usage Reset
→ 필요한 RuleExecution 완료
→ Opportunity Ledger·Movement Budget 생성
→ awaiting_controller
```

Turn Start Trigger가 미해결이면 Actor에게 일반 행동 입력을 열지 않는다.

### 4.5 행동과 상호작용

```text
Controller Intent
→ Active Turn·Control·Opportunity 검증
→ Capability Projection 재검증
→ Target·Path·Option Frozen Binding
→ Opportunity Reservation
→ RuleExecution
→ Roll·Reaction·PendingEffect
→ Commit
→ Opportunity 소비·반환
→ Turn Projection 갱신
```

문 열기, Item Pickup과 Scene Interaction도 Encounter 중 사용할 수 있지만 해당 Capability와 Opportunity 비용을 따른다.

### 4.6 전투 이동

```text
목적지 클릭
→ Path Preview
→ Movement Budget·Traversal 검증
→ MovementExecution
→ Checkpoint·Trigger Boundary
→ Opportunity Attack·Hazard TimingWindow
→ Child RuleExecution
→ 최신 위치·Budget Commit
→ 이동 재개 또는 종료
```

전투 중 WASD 토큰 이동은 지원하지 않는다. 이동 경로, 비용과 최종 위치는 Client가 확정하지 않는다.

### 4.7 Reaction, Interrupt와 Ready

```text
RuleExecution·MovementExecution
→ RuleEvent
→ TimingWindow
→ 적격 Capability Offer
→ Reaction Opportunity Reservation
→ Child RuleExecution
→ 결과 기여
→ 부모 실행 재개
```

Encounter는 Reaction Stack을 따로 소유하지 않는다.

Ready:

```text
Action Opportunity 소비
→ Trigger와 준비 행동 저장
→ 적격 Event 발생
→ Reaction Offer
→ prepared_action_release Child Execution
```

D&D 2024 기본 Policy에서 Delay는 제공하지 않는다.

### 4.8 Damage와 HP 0

```text
Attack·Save Outcome
→ Damage Roll·Component Resolution
→ 저항·면역·감소
→ Final Damage Candidate
→ Temporary HP·Current HP·VitalState·DeathSave Closure
→ Atomic Commit
→ HP·Vital·Effect·Encounter Projection Barrier
```

HP가 0이 되었다고 모든 Actor가 같은 죽음 내성을 사용하는 것은 아니다. ActorDeathPolicy가 즉사, 죽음 내성, 무력화와 의식불명 정책을 제공한다.

### 4.9 사망과 현재 Turn

```text
Death Immediate Closure
→ VitalState dead
→ DeathRecord
→ DeathSave 종료
→ 즉시 무효 Opportunity·Reservation·Capability 정리
→ Concentration·owner_dead Effect Cleanup Plan
→ Participant Eligibility와 ActiveTurn Gate 갱신
→ Commit

actor.died Event
→ Objective Evaluation·Morale·Surrender 후속 실행
→ Encounter Advance Command
```

Damage Provider는 Actor를 삭제하거나 Cursor를 직접 다음 Turn으로 옮기지 않는다.

### 4.10 Objective와 End Candidate

```text
Domain Event·최신 Snapshot
→ Objective Evaluation Command
→ Progress State 갱신
→ Success·Failure·Neutral End Candidate
→ End Policy
→ DM 확인 또는 자동 확정
```

Objective 예시는 적 무력화뿐 아니라 탈출, 호위, 생존 Round, 지역 방어, 상호작용 완료와 사건 방지를 포함한다.

### 4.11 Round End와 Campaign Time

```text
마지막 적격 Occurrence 완료
→ 열린 RuleExecution·Reaction·Reservation 확인
→ Round End Candidate
→ TemporalBoundaryCandidate
→ Frozen Time Policy로 6초 또는 Partial Round 계산
→ Encounter Round State + Campaign Time + Scheduler Due 원자 Commit
→ Boundary Gate
```

개별 Turn, 추가 Turn, Reaction, Ready, Lair·Hazard Entry와 주사위 연출은 별도 6초를 추가하지 않는다.

### 4.12 Scheduler Due와 Boundary Gate

```text
Time Advance 구간의 Schedule 조회
→ Due Occurrence Staging
→ schedule.became_due Outbox Event
→ 멱등 Subscriber
→ Encounter Command 또는 RuleExecution 제출
→ blocking | non_blocking 처리
```

Blocking Due가 Accepted·Adjudicated되지 않았거나 이전 Round의 필수 실행이 남아 있으면 다음 Round를 열지 않는다.

### 4.13 중도 합류와 Timeline 변경

```text
JoinEncounterProposal
→ Actor·Awareness·Faction·Control 검증
→ Initiative Policy
→ Timeline Insertion Plan
→ 안전 Boundary에서 새 Timeline Revision Commit
→ Participant 활성화
```

현재 공격·주문·Reaction 중간에 Timeline을 즉시 재정렬하지 않는다.

### 4.14 이탈, 항복과 Control 위임

```text
Withdraw·Escape·Surrender·DM Remove 후보
→ Participant State와 현재 Occurrence 영향 평가
→ 열린 실행·Opportunity 정리
→ 안전 Boundary에서 Commit
```

DM이 NPC를 플레이어에게 위임해도 Character Ownership과 비밀 정보 접근권은 자동 이전되지 않는다.

### 4.15 연결 종료와 Timeout

```text
Controller Disconnect
→ Reconnect Grace
→ Reminder
→ Timeout Policy
→ DM Takeover | Automation | Skip Candidate | Continue Waiting
```

Timeout은 Authority Monotonic Time을 사용하며 Campaign Game Time을 자동 진행하지 않는다. 플레이어 Turn을 무조건 Auto Pass하는 기본값을 엔진에 하드코딩하지 않는다.

### 4.16 Pause와 DM Override

```text
Encounter active
+ Pause Overlay
→ Gameplay Command Gate
```

Pause가 Pending RuleExecution, Reaction Offer와 Resource Reservation을 삭제하지 않는다.

DM의 Skip, Force End Turn, Participant 수정, Timeline Reorder, Control 위임과 Opportunity Override도 일반 Store 직접 수정이 아니라 Command·Transaction·Audit 경계를 사용한다.

### 4.17 Encounter 종료

```text
End Candidate 확정
→ 신규 관련 Command Gate
→ 열린 실행·Reaction·Turn Boundary 정리
→ Partial Round·Campaign Time 정산
→ Encounter-bound Opportunity·Effect·Control Cleanup
→ Session Base Mode 전환
→ Encounter End Transaction
→ Domain Event·Snapshot·Projection
```

Actor 위치·HP·시체·바닥 Item·Scene Object·지속 Effect·Knowledge는 해당 Domain 정책에 따라 유지한다.

### 4.18 재접속과 서버 Recovery

```text
Authority Snapshot + Commit Journal
→ EncounterSession·Timeline·Cursor 복원
→ Opportunity·Movement·Control·Objective 복원
→ Pending RuleExecution·Reaction·Reservation 복원
→ RoundTimeLedger·Scheduler·Boundary Gate 복원
→ Observer별 Encounter Projection 재생성
→ 입력 Gate 해제
```

Client의 로컬 Initiative Ribbon, Action Button, Dice Animation과 Timeout 화면을 권위 복구 원본으로 사용하지 않는다.

### 4.19 DM Rollback

```text
Checkpoint 선택
→ Current vs Target Diff와 비가역 Knowledge 경고
→ E 승인 / Q 취소
→ Encounter Command Gate
→ 진행 중 Commit 완료 또는 미Commit 실행 안전 취소
→ Snapshot·Delta 무결성 검증
→ 새 Branch·AuthorityEpoch 생성
→ Timeline·Actor·Effect·Fog·Game Time·Scheduler 복원
→ 이전 Epoch 입력 무효화
→ Projection·HUD 재구성
→ Full Encounter Resync
```

과거 Branch의 성공 Roll만 선택적으로 재사용하지 않는다. 새 Branch에서 같은 행동을 다시 선언하면 새 RuleExecution과 새 Roll을 생성한다.

## 5. 문서 관계도

### Parent Authority

- [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md) — Snapshot Query, Command Mutation, Transaction, Projection과 Roblox Instance 경계
- [`Session Play Mode, Context, Overlay와 Transition 계약`](../../architecture/session-play-mode-context-overlay-and-transition-contract.md) — Encounter Base Mode, Pause·Rollback Overlay와 Transition Gate
- [`Ruleset Policy Registry, Composition과 Frozen Snapshot`](../../architecture/ruleset-policy-registry-composition-and-frozen-snapshot-runtime-contract.md) — Encounter·Time Policy의 결정적 Composition과 Snapshot 고정
- [`Rule Runtime Orchestrator와 Pending Execution`](../../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md) — Action·Reaction·Roll·Effect 실행과 복구
- [`Command Ordering, Logical Time와 Transaction Coordinator`](../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md) — Timeline·Damage·End·Temporal Boundary의 원자적 Commit
- [`Domain Event, Outbox, Subscription과 Projection Runtime`](../../architecture/domain-event-outbox-subscription-and-projection-runtime-contract.md) — Commit 이후 Event, Scheduler Bridge와 Follow-up Command

### Child Authority

- [`Encounter Timeline, Turn, Opportunity와 Objective Runtime`](../../architecture/encounter-timeline-turn-opportunity-and-objective-runtime-contract.md) — EncounterSession, Timeline, Turn, Opportunity, Objective와 End
- [`Encounter–Game Time Temporal Boundary와 Scheduler 통합`](../../architecture/encounter-game-time-temporal-boundary-and-scheduler-integration-contract.md) — Round·Campaign Time·Due Staging의 원자적 경계
- [`Cross-Domain Outcome Cascade와 Integration Boundary Runtime`](../../architecture/cross-domain-outcome-cascade-and-integration-boundary-runtime-contract.md) — Damage·Death·Encounter End의 Immediate Closure와 Deferred Consequence
- [`Combat 시스템 인덱스`](../../systems/combat/README.md) — Combat 영역 권위 진입점과 폐기 문서 구분
- [`HP 0·죽음 내성·휴식·자원 회복 모델`](../../systems/character/zero-hit-points-death-saves-rest-and-resource-recovery-model.md) — HP 0·DeathSave·DeathRecord의 규칙 의미
- [`Encounter Turn Snapshot과 DM Rollback 모델`](../../systems/combat/encounter-turn-snapshot-and-dm-rollback-model.md) — 턴 Checkpoint·Diff·Branch 복구의 세부 모델; 최신 Epoch·Timeline Architecture가 우선
- [`Combat HUD UI`](../../ui/combat-hud/README.md) — Initiative Ribbon, Action HUD와 DM Rollback UI 진입점

### References

- [`Runtime Foundation과 Authority Guide`](../runtime/README.md) — Source·State·Command·Transaction·Projection 공통 용어
- [`Session, Networking, Persistence와 Recovery Guide`](../session/README.md) — Mode·Join·Reconnect·Snapshot·Rollback 기반
- [`Scene, Streaming, Runtime Object, Spatial Query와 Navigation Guide`](../scene/README.md) — Actor Presence, Path와 Movement 실행 기반
- [`Exploration, Selection, Interaction과 Perception Guide`](../exploration/README.md) — Encounter Proposal과 Selection·Disclosure 전환 경계
- [`Rules, Character Action, Spell, Dice와 Effect Guide`](../rules/README.md) — Capability·RuleExecution·Roll·PendingEffect·Effect 실행 기반
- [`Game Time, Calendar, Duration과 Scheduler Runtime`](../../architecture/game-time-calendar-duration-and-scheduler-runtime-contract.md) — Campaign Time, Duration와 Scheduler
- [`Dice Roll, Check, Save, Attack과 Resolution Runtime`](../../architecture/dice-roll-check-save-attack-and-resolution-runtime-contract.md) — Initiative·Attack·Death Save Roll과 공개
- [`Character Action Opportunity와 2024 Core Action Runtime`](../../architecture/character-action-opportunity-and-2024-core-action-runtime-contract.md) — Action Economy와 Opportunity 소비
- [`Effect, Condition과 Ongoing Runtime`](../../architecture/effect-condition-and-ongoing-runtime-contract.md) — Turn·Round Duration, Concentration과 Encounter-bound Effect
- [`Runtime Navigation, Path Planning과 Movement Execution`](../../architecture/runtime-navigation-path-planning-and-movement-execution-contract.md) — 전투 클릭 이동과 Trigger Checkpoint
- [`Persistence와 Session Recovery 모델`](../../architecture/persistence-and-session-recovery-model.md) — Snapshot, Journal, Recovery와 Branch
- [`UI Projection, ViewModel, Input Context와 Recovery Runtime`](../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md) — Combat HUD Projection, Prompt와 Epoch-safe UI 복구
- [`현재 Guide 작업 순서`](../CURRENT-GUIDE-WORK-ORDER.md) — Main System Guide 단계의 진행 순서

## 6. 다른 시스템과의 경계

| 인접 시스템 | Combat·Encounter가 제공하는 것 | 상대 시스템이 제공하는 것 | 권위 경계 문서 |
|---|---|---|---|
| Session Runtime | Encounter Base Mode Binding, End·Rollback 전환 후보 | Mode·Overlay·Transition Gate와 참가자 Session 상태 | Session Mode, Encounter Runtime |
| Exploration | Encounter Proposal 결과와 비참가자 정책 | 적대 행동·탐지·Hazard 원인, 참가자·Awareness 후보 | Exploration·Encounter Runtime |
| Rules·Action·Spell | Turn·Opportunity·Movement Context와 Reaction 사용 가능성 | Capability, Targeting, Roll, Effect와 RuleExecution | Rules Guide, Character Action, Rule Runtime |
| Navigation | Movement Budget과 Trigger 처리 Context | Path, 비용, Checkpoint와 권위 위치 | Navigation 계약, Encounter Runtime |
| Character·Vital | Encounter Participant Eligibility와 Turn Gate | HP, VitalState, DeathSave, DeathRecord와 ActorDeathPolicy | Cross-Domain, HP 0 모델 |
| Effect | Turn·Round Boundary와 Encounter Binding | Condition, Concentration, Duration, Cleanup와 Contribution | Effect Runtime, Cross-Domain |
| Inventory·Interaction | Opportunity와 현재 Controller Context | Item Transfer, 장비, 문·상자·Object 상태 Mutation | Character Action, Interaction·Inventory Runtime |
| Dice | Initiative·Attack·Death Save Roll Intent와 공개 시점 요구 | RollPlan, Sealed Result, RollRecord와 Outcome | Dice Runtime |
| Game Time | Round Boundary Candidate와 Time-driving Encounter Context | Campaign Instant, Time Contribution, Scheduler Due | Temporal Boundary, Game Time Runtime |
| Cross-System Integration | Damage·Death·End Outcome Candidate와 Gate 요구 | Immediate Closure, Follow-up Ledger와 Projection Barrier | Cross-Domain Runtime |
| Events | Encounter·Round·Turn·Objective·End Event Plan | Outbox, Subscriber Retry와 Event→Command Bridge | Domain Event Runtime |
| Perception·Disclosure | Hidden Reserve·Awareness·Timeline 공개 요구 | Observer별 공개 정보와 Candidate 안전성 | Encounter, Visibility Runtime |
| UI·Camera·Presentation | Player·DM·Observer Encounter Projection | Initiative Ribbon, HUD, Prompt, Dice·Camera·VFX 표현 | UI Runtime, Combat HUD |
| Persistence·Recovery | Encounter Snapshot, Timeline, Ledger와 Branch 범위 | Manifest·Chunk·Journal, Lease, Restart와 Full Resync | Persistence, Encounter Rollback |
| Diagnostics·Simulation | Initiative·Turn·Outcome·Temporal·Rollback Trace 지점 | Correlation, Incident, Deterministic Scenario와 Assertion | Diagnostics·Simulation Runtime |

고정 경계:

- Encounter가 Action, Spell, Interaction, Inventory와 Damage 규칙을 재구현하지 않는다.
- Encounter가 Actor 위치·HP·Item·Effect의 독립 복사본을 소유하지 않는다.
- Initiative UI 배열을 권위 Timeline으로 사용하지 않는다.
- Encounter가 Reaction과 Interrupt의 별도 실행 Stack을 만들지 않는다.
- Roll Runtime이 HP나 Encounter Cursor를 직접 수정하지 않는다.
- Damage Provider가 Participant 제거·Turn Advance·Encounter End를 직접 수행하지 않는다.
- HP 0, VitalState, DeathSave와 Participant State를 하나의 Enum으로 합치지 않는다.
- Objective Subscriber가 Encounter Store를 직접 수정하지 않는다.
- Encounter가 Campaign Time Store를 직접 수정하지 않는다.
- Scheduler Callback이 Timeline을 직접 삽입하지 않는다.
- Client Timeout, Animation과 현실 경과 시간이 Campaign Time을 변경하지 않는다.
- Pause를 Encounter lifecycleState로 추가하지 않는다.
- Rollback Review가 승인 전 현재 Authority Branch를 변경하지 않는다.
- Rollback을 역연산, 선택적 주사위 재사용 또는 현재 Branch의 Command 연속 실행으로 구현하지 않는다.
- Encounter 종료가 Persistent World State를 초기화하지 않는다.

## 7. 추천 읽기 순서

1. [`Runtime Foundation과 Authority Guide`](../runtime/README.md) — 공통 권위·Command·Transaction·Projection 용어
2. [`Session, Networking, Persistence와 Recovery Guide`](../session/README.md) — Encounter Base Mode, Transition과 Branch Recovery
3. [`Exploration, Selection, Interaction과 Perception Guide`](../exploration/README.md) — Encounter Proposal과 참가자·Awareness 진입
4. [`Rules, Character Action, Spell, Dice와 Effect Guide`](../rules/README.md) — Encounter가 조정하는 실제 행동·반응·피해 기반
5. [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md) — 서버 권위와 Snapshot·Mutation 불변식
6. [`ADR-0034`](../../decisions/ADR-0034-encounter-initiative-turn-order-and-control-authority.md) — Encounter·Initiative·Turn·Control Authority 결정
7. [`ADR-0079`](../../decisions/ADR-0079-policy-driven-encounter-timelines-and-opportunity-gated-turns.md) — Policy 기반 Timeline·Opportunity 결정
8. [`Encounter Timeline, Turn, Opportunity와 Objective Runtime`](../../architecture/encounter-timeline-turn-opportunity-and-objective-runtime-contract.md) — Encounter의 핵심 상태와 흐름
9. [`ADR-0069`](../../decisions/ADR-0069-authoritative-roll-records-and-presentation-gated-resolution.md) — Initiative·Attack·Death Save Roll 공개 결정
10. [`Dice Roll, Check, Save, Attack과 Resolution Runtime`](../../architecture/dice-roll-check-save-attack-and-resolution-runtime-contract.md) — Roll·Outcome 경계
11. [`ADR-0087`](../../decisions/ADR-0087-atomic-immediate-closure-and-event-driven-deferred-consequences.md) — Damage·Death·End 통합 결정
12. [`Cross-Domain Outcome Cascade와 Integration Boundary Runtime`](../../architecture/cross-domain-outcome-cascade-and-integration-boundary-runtime-contract.md) — Immediate Closure와 Deferred Consequence
13. [`HP 0·죽음 내성·휴식·자원 회복 모델`](../../systems/character/zero-hit-points-death-saves-rest-and-resource-recovery-model.md) — HP 0·DeathSave·Death 의미
14. [`ADR-0082`](../../decisions/ADR-0082-atomic-encounter-boundary-time-advance-and-event-driven-scheduler-bridge.md) — Round·Game Time·Scheduler 통합 결정
15. [`Encounter–Game Time Temporal Boundary와 Scheduler 통합`](../../architecture/encounter-game-time-temporal-boundary-and-scheduler-integration-contract.md) — Temporal Boundary와 Due Gate
16. [`Game Time, Calendar, Duration과 Scheduler Runtime`](../../architecture/game-time-calendar-duration-and-scheduler-runtime-contract.md) — 시간 축과 Duration
17. [`ADR-0043`](../../decisions/ADR-0043-encounter-turn-snapshot-timeline-and-dm-rollback.md) — Encounter 턴 Rollback 결정
18. [`Encounter Turn Snapshot과 DM Rollback 모델`](../../systems/combat/encounter-turn-snapshot-and-dm-rollback-model.md) — Checkpoint·Diff·Branch UI 흐름
19. [`Combat HUD UI`](../../ui/combat-hud/README.md) — 사용자 화면 진입점
20. [`Completion Audit`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md) — Integration 완료와 Guide 작성 가능 판정

다음 문서는 `SUPERSEDED`이므로 현재 권위 읽기 순서에서 제외한다.

- `systems/combat/encounter-initiative-turn-and-control-authority-model.md`
- `systems/combat/dice-roll-presentation-and-resolution-gating-model.md`

## 8. 구현·검증 순서

현재 Combat·Encounter 전용 `준비 완료` Implementation Spec은 아직 없다. 상위 Work Order상 Main System Guides 완료 후 다음 의존 순서로 수직 Spec을 작성한다.

```text
Encounter Policy·Identity·Persistence Foundation
→ Proposal·Participant·Faction·Control Spec
→ Initiative Roll·Reveal·Tie·Timeline Commit Spec
→ Timeline Entry·Occurrence·Cursor·Revision Spec
→ Turn State·Opportunity Ledger·Movement Budget Spec
→ Navigation·Trigger·Reaction Bridge Spec
→ Objective·Join·Leave·NonParticipant Spec
→ Damage·HP·Vital·Death Cross-Domain Closure Spec
→ Concentration·Objective·Turn Advance Follow-up Spec
→ Encounter End Transaction Spec
→ Temporal Boundary·Campaign Time Contribution Spec
→ Scheduler Due·Boundary Gate Bridge Spec
→ Encounter Checkpoint·Branch Rollback Spec
→ Player·DM·Observer Projection·Combat HUD Spec
→ Reconnect·Restart·Rollback Recovery Spec
→ Diagnostics·Deterministic Integration Scenario Spec
```

이미 준비된 공통 기반 Spec:

- [`Recipe Step Runtime Foundation`](../../specs/shared/001-recipe-step-runtime-foundation.md)
- [`Standard Recipe Step Handler Contracts`](../../specs/shared/002-standard-step-handler-contracts.md)

필수 수직 검증:

```text
Exploration 적대 행동에서 Encounter 시작
Initiative 공개 전 Turn 비활성
Timeline Insert·Reorder의 Stable Identity
Action·Reaction·Movement Opportunity 소비
Opportunity Attack 중첩 RuleExecution
Damage→HP 0→Vital·DeathSave 원자 Commit
Current Turn Actor 사망 후 안전 Turn Advance
Last Hostile Death→Objective End Candidate
Full Round→Campaign Time +6초 단일 Commit
Blocking Due가 다음 Round Gate
중도 합류·이탈·Control 위임
Reconnect 중 Reaction 복구
Commit 직후 Server Restart
Encounter End 후 Actor·Item·Effect 보존
과거 Turn Rollback→새 Epoch Full Resync
이전 Epoch Command·Due·Prompt 차단
숨은 Participant·Objective Negative Disclosure
Presentation 실패와 Gameplay Commit 격리
```

## 9. 변경 영향 지도

| 변경 유형 | 영향받는 권위 문서 | 영향받는 Specs | Guide 조치 |
|---|---|---|---|
| Encounter Policy·Initiative·Timeline 변경 | Ruleset Policy, Encounter Runtime, ADR-0034·0079 | Encounter Foundation·Timeline Specs | `UPDATE_REQUIRED` |
| Turn·Opportunity·Movement 변경 | Encounter Runtime, Character Action, Navigation | Turn·Opportunity·Movement Specs | `UPDATE_REQUIRED` |
| Reaction·Ready 실행 변경 | Rule Runtime, Character Action, Encounter Runtime | Reaction Bridge·RuleExecution Specs | `UPDATE_REQUIRED` |
| Damage·Vital·Death 경계 변경 | Dice, Cross-Domain, Character HP 0, Effect | Damage·Vital Closure Specs | `UPDATE_REQUIRED` |
| Objective·End Transaction 변경 | Encounter Runtime, Cross-Domain, Session Mode | Objective·Encounter End Specs | `UPDATE_REQUIRED` |
| Round Duration·Temporal Boundary 변경 | Encounter, Game Time, Temporal Integration, ADR-0082 | Time Contribution·Scheduler Bridge Specs | `UPDATE_REQUIRED` |
| Participant·Control·Disclosure 변경 | Encounter, Session, Visibility, Networking | Participant·Control·Projection Specs | `UPDATE_REQUIRED` |
| Rollback Snapshot·Branch 변경 | Persistence, Encounter Rollback, Networking, UI Recovery | Rollback·Recovery Specs | `UPDATE_REQUIRED` |
| Combat HUD Layout·Animation 변경 | Combat HUD, UI·Presentation Runtime | UI·Presentation Specs | 권위 의미가 같으면 필요 시 갱신 |
| Timeout·Entry Cap·Batch·보존 기간 변경 | 해당 Architecture의 측정형 기본값 | 관련 성능·운영 Specs | 의미가 바뀌지 않으면 상태 유지 가능 |

## 10. Authority Documents

### Product

- [`핵심 세션 흐름과 플레이 모드`](../../product/core-session-loop.md)

### Architecture

- [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md)
- [`Session Play Mode, Context, Overlay와 Transition`](../../architecture/session-play-mode-context-overlay-and-transition-contract.md)
- [`Ruleset Policy Registry, Composition과 Frozen Snapshot`](../../architecture/ruleset-policy-registry-composition-and-frozen-snapshot-runtime-contract.md)
- [`Encounter Timeline, Turn, Opportunity와 Objective Runtime`](../../architecture/encounter-timeline-turn-opportunity-and-objective-runtime-contract.md)
- [`Encounter–Game Time Temporal Boundary와 Scheduler 통합`](../../architecture/encounter-game-time-temporal-boundary-and-scheduler-integration-contract.md)
- [`Game Time, Calendar, Duration과 Scheduler Runtime`](../../architecture/game-time-calendar-duration-and-scheduler-runtime-contract.md)
- [`Character Action Opportunity와 2024 Core Action Runtime`](../../architecture/character-action-opportunity-and-2024-core-action-runtime-contract.md)
- [`Rule Runtime Orchestrator와 Pending Execution`](../../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md)
- [`Dice Roll, Check, Save, Attack과 Resolution Runtime`](../../architecture/dice-roll-check-save-attack-and-resolution-runtime-contract.md)
- [`Effect, Condition과 Ongoing Runtime`](../../architecture/effect-condition-and-ongoing-runtime-contract.md)
- [`Cross-Domain Outcome Cascade와 Integration Boundary Runtime`](../../architecture/cross-domain-outcome-cascade-and-integration-boundary-runtime-contract.md)
- [`Command Ordering, Logical Time와 Transaction Coordinator`](../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)
- [`Domain Event, Outbox, Subscription과 Projection Runtime`](../../architecture/domain-event-outbox-subscription-and-projection-runtime-contract.md)
- [`Persistence와 Session Recovery 모델`](../../architecture/persistence-and-session-recovery-model.md)
- [`Networking Command, Event와 Client Synchronization`](../../architecture/networking-command-event-and-client-synchronization-contract.md)
- [`UI Projection, ViewModel, Input Context와 Recovery Runtime`](../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md)
- [`Diagnostics, Observability, Correlated Trace와 Incident Runtime`](../../architecture/diagnostics-observability-correlated-trace-and-incident-runtime-contract.md)
- [`Deterministic Simulation, Scenario와 Test Harness Runtime`](../../architecture/deterministic-simulation-scenario-and-test-harness-runtime-contract.md)

### Systems·UI

- [`Combat 시스템`](../../systems/combat/README.md)
- [`Time 시스템`](../../systems/time/README.md)
- [`Cross-System Integration 시스템`](../../systems/integration/README.md)
- [`HP 0·죽음 내성·휴식·자원 회복 모델`](../../systems/character/zero-hit-points-death-saves-rest-and-resource-recovery-model.md)
- [`Encounter Turn Snapshot과 DM Rollback 모델`](../../systems/combat/encounter-turn-snapshot-and-dm-rollback-model.md)
- [`Combat HUD UI`](../../ui/combat-hud/README.md)
- [`Baldur's Gate 3형 전투 HUD와 행동 UI 모델`](../../ui/combat-hud/baldurs-gate-style-combat-hud.md)

### Specs

- [`Recipe Step Runtime Foundation`](../../specs/shared/001-recipe-step-runtime-foundation.md)
- [`Standard Recipe Step Handler Contracts`](../../specs/shared/002-standard-step-handler-contracts.md)
- Combat·Encounter 전용 Spec: Main System Guide 단계 이후 작성 예정

### Audits

- [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)

## 11. ADR References

- [`ADR-0031`](../../decisions/ADR-0031-zero-hit-points-death-saves-rests-and-resource-recovery.md) — HP 0, DeathSave, Rest와 Resource Recovery
- [`ADR-0034`](../../decisions/ADR-0034-encounter-initiative-turn-order-and-control-authority.md) — Encounter, Initiative, Turn과 Control Authority
- [`ADR-0043`](../../decisions/ADR-0043-encounter-turn-snapshot-timeline-and-dm-rollback.md) — 턴 Checkpoint Timeline과 DM Rollback
- [`ADR-0048`](../../decisions/ADR-0048-continuous-gridless-movement-pc-only-and-no-combat-wasd.md) — 연속 무격자 이동과 전투 WASD 비지원
- [`ADR-0061`](../../decisions/ADR-0061-persistent-rule-execution-orchestrator-and-nested-timing-windows.md) — Persistent RuleExecution과 중첩 TimingWindow
- [`ADR-0062`](../../decisions/ADR-0062-ordered-reservations-and-atomic-authority-transactions.md) — Reservation, Ordering과 원자적 Transaction
- [`ADR-0063`](../../decisions/ADR-0063-manifest-chunk-snapshots-commit-journal-and-branch-recovery.md) — Snapshot·Journal·Branch Recovery
- [`ADR-0069`](../../decisions/ADR-0069-authoritative-roll-records-and-presentation-gated-resolution.md) — 서버 권위 RollRecord와 Reveal Gate
- [`ADR-0070`](../../decisions/ADR-0070-orthogonal-session-modes-contexts-overlays-and-transitions.md) — Mode, Context, Overlay와 Transition 분리
- [`ADR-0076`](../../decisions/ADR-0076-real-time-exploration-with-actor-scoped-execution-and-atomic-encounter-transition.md) — Exploration에서 Encounter로의 원자 전환
- [`ADR-0077`](../../decisions/ADR-0077-transactional-domain-events-with-outbox-and-projection-boundaries.md) — Transactional Outbox와 Projection Boundary
- [`ADR-0078`](../../decisions/ADR-0078-authoritative-game-time-boundary-durations-and-scheduled-execution.md) — Game Time, Boundary Duration와 Scheduler
- [`ADR-0079`](../../decisions/ADR-0079-policy-driven-encounter-timelines-and-opportunity-gated-turns.md) — Policy 기반 Timeline과 Opportunity
- [`ADR-0081`](../../decisions/ADR-0081-versioned-policy-composition-and-frozen-ruleset-snapshots.md) — Versioned Policy Composition과 Frozen Snapshot
- [`ADR-0082`](../../decisions/ADR-0082-atomic-encounter-boundary-time-advance-and-event-driven-scheduler-bridge.md) — Encounter Boundary·Time Advance·Scheduler Bridge
- [`ADR-0087`](../../decisions/ADR-0087-atomic-immediate-closure-and-event-driven-deferred-consequences.md) — Immediate Closure와 Deferred Consequence

## 12. 알려진 비목표와 측정형 기본값

확정된 비목표:

- Encounter와 Combat를 동일시하지 않는다.
- Encounter에 공격·주문·상호작용 구현을 복제하지 않는다.
- 단순 Initiative List·FIFO Queue를 내부 권위 구조로 사용하지 않는다.
- Initiative 공개 전 Turn을 시작하지 않는다.
- 전투 중 토큰 WASD 이동을 지원하지 않는다.
- D&D 2024 기본 Policy에서 Delay를 제공하지 않는다.
- Reaction 전용 Encounter Stack을 만들지 않는다.
- Individual Turn마다 Campaign Time 6초를 추가하지 않는다.
- Scheduler Callback과 Event Subscriber가 Domain Store를 직접 수정하지 않는다.
- Damage Provider가 HP 외 Domain을 직접 순차 호출하지 않는다.
- 사망을 Character·Inventory·Runtime Object 삭제로 취급하지 않는다.
- Objective 후보만으로 무조건 Encounter를 즉시 종료하지 않는다.
- Pause를 Encounter 상태로 만들지 않는다.
- Client Dice Physics와 Animation을 규칙 권위로 사용하지 않는다.
- Rollback으로 플레이어가 이미 본 비밀을 인간 기억에서 제거할 수 있다고 가정하지 않는다.
- NPC 자동 전술 AI와 음악·효과음을 이 Guide에서 정의하지 않는다.

남은 측정형 기본값:

- Timeline Entry와 Participant 상한
- Turn Reminder·Timeout·Reconnect Grace
- 동률 Prompt와 End Candidate 확인 Timeout
- NonParticipant 기본 정책
- Objective 자동 제안·자동 종료 수준
- Partial Round의 Campaign Time 기본 반영 정책
- 한 Temporal Boundary의 Due Batch와 연쇄 깊이
- Blocking Due Recovery 전환 시간
- 같은 Instant Due 정렬과 Timeline 삽입 기본값
- Rollback Checkpoint Materialization 간격과 저장 보존 기간
- Combat HUD 정보 밀도, Animation 시간과 Dice 표시 상한
- Trace 상세 수준과 Deterministic Scenario 실행 Budget

남은 비차단 작업:

- Combat·Encounter 수직 Implementation Specs 작성
- 실제 D&D 2024 Encounter Policy Pack 데이터 작성
- Objective Profile과 Encounter Kind 콘텐츠 작성
- Combat HUD의 최종 시각 디자인과 접근성 검증
- 장시간 Encounter·대규모 소환체·다중 Due 부하 테스트

## 13. Guide 검증 체크리스트

- [x] 모든 핵심 문장이 Authority Document에 근거한다.
- [x] Encounter와 Combat, Turn과 Action, Roll과 Damage, HP와 VitalState를 분리했다.
- [x] 새로운 제품 규칙이나 Architecture 결정을 추가하지 않았다.
- [x] Parent·Children·References를 구분했다.
- [x] `SUPERSEDED` 문서를 현재 권위 읽기 순서에서 제외했다.
- [x] Initiative·Timeline·Turn·Opportunity·Reaction 흐름을 연결했다.
- [x] Damage·HP 0·Death·Objective의 Cross-Domain 경계를 연결했다.
- [x] Round·Campaign Time·Scheduler Boundary를 연결했다.
- [x] Encounter End와 Persistent World State 보존을 설명했다.
- [x] Checkpoint·Branch·AuthorityEpoch Rollback과 Recovery를 설명했다.
- [x] 현재 존재하는 Specs와 후속 Spec 순서를 구분했다.
- [x] 측정형 기본값과 비차단 작업을 별도로 기록했다.
- [x] Guide Status가 실제 상태와 일치한다.
