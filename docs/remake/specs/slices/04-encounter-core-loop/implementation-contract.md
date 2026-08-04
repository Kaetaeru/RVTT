# Implementation Spec — Slice 04 Encounter Core Loop

- 상태: SPEC_CHECKPOINT_COMPLETE
- 문서 종류: Slice Integration Implementation Spec
- 구현 상태: 미구현
- 즉시 구현 명세 가능성: BLOCKED
- 작성일: 2026-08-05
- 차단 이유: 실제 Encounter·Character Vital·Game Time·Combat UI·Snapshot Source Tree를 확인하지 못했다.
- Work Order: [`CURRENT-WORK-ORDER.md`](CURRENT-WORK-ORDER.md)
- Roadmap: [`SLICE-ROADMAP.md`](../../SLICE-ROADMAP.md)
- 선행 계약: [`Core Rules`](../02-core-rules-kernel/implementation-contract.md), [`Exploration`](../03-exploration-interaction-perception/implementation-contract.md)
- 관련 Guide: [`Combat`](../../../guides/combat/README.md), [`Rules`](../../../guides/rules/README.md), [`Scene`](../../../guides/scene/README.md), [`Session`](../../../guides/session/README.md), [`UI`](../../../guides/ui/README.md), [`Character`](../../../guides/character/README.md), [`Diagnostics`](../../../guides/diagnostics/README.md)

> Encounter는 행동 규칙의 소유자가 아니라 참가자·순서·기회·이동 예산·목표와 시간 경계를 조정하는 Runtime이다.

## 1. Acceptance Flow

### Player

```text
Exploration 중 Encounter 진입
→ Initiative 공개
→ 자신의 Turn·Opportunity 확인
→ 이동·Action·Bonus Action·Reaction 실행
→ HP·Condition·Objective 결과 확인
→ Encounter 종료
→ 현재 World State로 Exploration 복귀
```

### DM

```text
Encounter Proposal 검토
→ Participant·Faction·Awareness·Objective 확정
→ Timeline과 Control 확인
→ 필요 시 Override·Pause·Adjudication
→ End Candidate 확인
→ Turn Checkpoint 선택·Rollback Review
```

## 2. 직접 권위 문서

- [`Encounter Timeline, Turn, Opportunity와 Objective`](../../../architecture/encounter-timeline-turn-opportunity-and-objective-runtime-contract.md)
- [`Encounter–Game Time Temporal Boundary`](../../../architecture/encounter-game-time-temporal-boundary-and-scheduler-integration-contract.md)
- [`Rule Runtime Orchestrator`](../../../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md)
- [`Dice Roll과 Resolution`](../../../architecture/dice-roll-check-save-attack-and-resolution-runtime-contract.md)
- [`Character Action·2024 Core Action Runtime`](../../../architecture/character-action-opportunity-and-2024-core-action-runtime-contract.md)
- [`Effect, Condition과 Ongoing Runtime`](../../../architecture/effect-condition-and-ongoing-runtime-contract.md)
- [`Runtime Navigation과 Movement Execution`](../../../architecture/runtime-navigation-path-planning-and-movement-execution-contract.md)
- [`Cross-Domain Outcome Cascade`](../../../architecture/cross-domain-outcome-cascade-and-integration-boundary-runtime-contract.md)
- [`Game Time, Calendar, Duration과 Scheduler`](../../../architecture/game-time-calendar-duration-and-scheduler-runtime-contract.md)
- [`Session Play Mode와 Transition`](../../../architecture/session-play-mode-context-overlay-and-transition-contract.md)
- [`Persistence와 Session Recovery`](../../../architecture/persistence-and-session-recovery-model.md)
- [`HP 0·Death Save·Rest와 Recovery`](../../../systems/character/zero-hit-points-death-saves-rest-and-resource-recovery-model.md)
- [`Encounter Turn Snapshot과 DM Rollback`](../../../systems/combat/encounter-turn-snapshot-and-dm-rollback-model.md)
- [`Combat HUD`](../../../ui/combat-hud/README.md)

## 3. 범위

포함:

- Encounter Proposal, preparing, active, ending, ended
- Participant·Faction·Awareness·Control Assignment
- Initiative Roll·Reveal·Tie Resolution
- Timeline Entry·Occurrence·Revision·Cursor
- Turn Start·End, Opportunity Ledger와 Movement Budget
- Action·Bonus Action·Reaction·Object Interaction Context
- 전투 클릭 이동, Trigger Checkpoint와 Reaction Bridge
- Damage·Healing·Temporary HP·VitalState·DeathSave 최소 통합
- Objective·End Candidate·Exploration Transition
- Round Time Ledger와 Scheduler Due Boundary
- Turn Checkpoint·Rollback·Reconnect·Recovery

제외:

- 모든 Class·Spell·Item Content
- AI 전술·자동 NPC 플레이
- 완성된 VFX Asset 전체
- Character 성장과 Inventory 전체 수명주기

## 4. State와 Type

```lua
export type EncounterSession = {
    encounterId: string,
    encounterIncarnation: string,
    sceneRuntimeRef: string,
    lifecycleState: "proposed" | "preparing" | "active" | "ending" | "ended",
    policySnapshotRef: string,
    participantRevision: number,
    timelineRevision: number,
    activeCursorRef: string?,
    roundNumber: number,
    objectiveRevision: number,
    authorityEpoch: string,
}

export type ParticipantBinding = {
    participantId: string,
    actorRef: string,
    factionRef: string,
    awarenessState: string,
    participationState: string,
    controllerRef: string?,
    revision: number,
}

export type TimelineEntry = {
    entryId: string,
    entryKind: "actor_turn" | "group_turn" | "hazard" | "objective" | "environment",
    subjectRefs: {string},
    initiativeEvidenceRef: string?,
    policyRef: string,
}

export type TimelineOccurrence = {
    occurrenceId: string,
    entryRef: string,
    roundNumber: number,
    state: "queued" | "starting" | "active" | "ending" | "completed" | "skipped",
    revision: number,
}

export type OpportunityLedger = {
    turnRef: string,
    action: string,
    bonusAction: string,
    reaction: string,
    objectInteraction: string,
    movementBudget: number,
    reservationRefs: {string},
    revision: number,
}
```

Character Ownership, Runtime Controller, Encounter Participant, VitalState와 Information Visibility는 서로 다른 값이다.

## 5. Encounter 시작

```text
Hostile Action·Detection·Hazard·DM Intent
→ Encounter Proposal
→ Scene·Actor Incarnation 검증
→ Participant·Faction·Awareness 후보
→ Frozen Policy Snapshot
→ preparing Commit
→ Initiative Plan·RollRecord
→ Reveal·Tie Resolution
→ Timeline Revision·첫 Cursor Commit
→ Session Base Mode Encounter 전환
```

필수 Initiative가 공개되기 전에 임시 Timeline으로 첫 Turn을 열지 않는다. 같은 Scene의 모든 Actor를 자동 참가시키지 않으며 NonParticipant의 탐험 상태와 공개 범위는 Policy를 따른다.

대표 Command:

| Command | 핵심 검증 | 결과 |
|---|---|---|
| `ProposeEncounter` | 원인 Ref, Scene, Actor, 권한 | Proposal |
| `PrepareEncounter` | DM·Policy, Participant·Objective | preparing State |
| `ActivateEncounter` | Initiative·Reveal·Timeline Ready | active State·Cursor |
| `JoinEncounter` | Actor·Awareness·Insertion Policy | 새 Timeline Revision |
| `LeaveEncounter` | 열린 Execution·Current Turn 영향 | Participant State 변경 |

## 6. Turn·Opportunity·Action

```text
Cursor가 Occurrence 선택
→ Turn Start RuleEvent
→ Turn-bound Effect·Recharge·DeathSave 처리
→ Opportunity Ledger 생성
→ awaiting_controller
→ Capability Intent
→ Opportunity Reservation
→ RuleExecution·MovementExecution
→ Commit
→ Opportunity 소비·반환
→ Turn End Gate
```

Encounter는 Capability 내용을 만들지 않는다. Action·Spell·Item·Interaction은 Slice 02·03과 후속 Character·Inventory Content에서 제공한다.

Opportunity 상태:

```text
available → reserved → consumed | released | expired
```

DM Force End, Skip, Reorder와 Grant도 직접 Store Mutation이 아니라 Versioned Command·Mandatory Audit를 사용한다.

## 7. 전투 이동·Reaction·Ready

전투 Token WASD는 금지한다.

```text
Destination Click
→ Movement Budget·Path Preview
→ Server Path·Traversal·Position Revision 검증
→ MovementExecution
→ Trigger Checkpoint
→ TimingWindow·Reaction Offer
→ Child RuleExecution
→ 위치·Budget Commit
→ 이동 재개 또는 종료
```

Reaction은 Encounter 전용 Stack이 아니다.

```text
RuleEvent
→ TimingWindow
→ 적격 Capability Offer
→ Reaction Opportunity Reservation
→ Child RuleExecution
→ 부모 실행 재개
```

Ready는 Action Opportunity를 소비해 Trigger와 Prepared Capability를 저장하고, Trigger 발생 시 Reaction Opportunity로 해제한다. D&D 2024 Core Policy에서 Delay를 기본 제공하지 않는다.

## 8. Damage·Vital·Objective

```text
Attack·Save Outcome
→ Final Damage Candidate
→ Temporary HP·Current HP·VitalState·DeathSave Provider
→ Immediate Closure Graph
→ Atomic Transaction
→ Damage·Vital·Encounter Projection Barrier
→ Concentration·Morale·Objective Follow-up
```

같은 Transaction에 포함 가능한 확정 변화:

- Temporary HP 흡수
- Current HP 변경
- Instant Death·VitalState 평가
- DeathSave Lifecycle 생성·종료
- 즉시 무효 Opportunity·Reservation 정리
- Current Turn의 입력 Gate 변경

별도 후속 실행:

- Concentration Check
- On-damage Trigger
- Morale·Surrender
- Objective Evaluation
- Turn Advance

Damage Provider가 Actor를 삭제하거나 Cursor를 이동하지 않는다.

Objective Evaluation은 Domain Event와 최신 Snapshot을 읽어 Progress와 End Candidate를 만들고, End Policy 또는 DM 확인 후 종료한다.

## 9. Round Time·Scheduler

```text
마지막 적격 Occurrence 완료
→ 열린 Execution·Reaction·Reservation 확인
→ Round End Candidate
→ Temporal Boundary Candidate
→ Encounter Round + Campaign Time + Due Staging 원자 Commit
→ Boundary Gate
→ Blocking Due 해결
→ 다음 Round
```

D&D 2024 기본 Policy에서 완결된 Round는 Campaign Time 6초를 기여하지만, 개별 Turn·Reaction·추가 Entry마다 6초를 더하지 않는다. Scheduler는 Due Occurrence를 만들 뿐 Timeline·Damage·Effect를 직접 수정하지 않는다.

## 10. Encounter 종료

```text
Objective·Escape·Surrender·DM End Candidate
→ 신규 관련 Command Gate
→ 열린 Execution·Reaction 정리
→ Partial Round Time 정산
→ Encounter-bound Opportunity·Control Cleanup
→ End Transaction
→ Session Base Mode Exploration 전환
→ Projection·HUD 전환
```

Actor 위치·HP·시체·Ground Item·Door·Trap·Knowledge와 지속 Effect는 각 Domain State로 유지한다.

## 11. Snapshot·Rollback·Recovery

Checkpoint는 Encounter State만 저장하지 않는다. 해당 시점의 다음 참조와 Commit Cursor를 포함한다.

- Timeline·Cursor·Opportunity·Objective
- Actor Position·HP·Vital·Effect·Resource
- Dynamic Scene Object·Fog·Knowledge
- Pending RuleExecution·Reaction·Reservation
- Campaign Time·Scheduler·Boundary Gate
- Control Assignment·Projection Cursor

Rollback:

```text
Checkpoint 선택
→ Current vs Target Diff·Knowledge 경고
→ DM 승인
→ Command Gate
→ Snapshot·Journal 무결성 검증
→ 새 Branch·AuthorityEpoch
→ State 복원·Derived View 재생성
→ 이전 Epoch 입력·ACK·Due 차단
→ Full Encounter Resync
```

역연산, 선택적 Roll 재사용과 현재 Branch 위에 과거 값을 덮어쓰는 방식은 금지한다.

## 12. Projection·HUD·오류

Player Projection:

- 공개 Timeline·현재 Turn·Opportunity·Movement Budget
- 자신에게 공개된 Objective·Roll·HP·Condition
- 적격 Action·Reaction Prompt

DM Projection:

- 전체 참가자·Faction·Control·Timeline 관리 View
- End Candidate·Checkpoint Diff·Override·Recovery View

Observer Projection은 공개 Policy를 따른다. 숨은 Reserve, 비공개 Objective, Secret Modifier와 DM Note를 Client Cache에 보낸 뒤 숨기지 않는다.

필수 화면 상태:

```text
Encounter 준비 중
Initiative 공개 대기
Turn Start Trigger 처리 중
Controller 대기·Disconnect
Reaction 응답 대기
Movement Trigger에서 중단
End Candidate 검토
Rollback Review·Full Resync
```

## 13. Diagnostics·Security·Budget

Trace:

```text
encounter.propose
encounter.prepare
initiative.resolve
timeline.commit
turn.start
opportunity.reserve
movement.checkpoint
reaction.offer
damage.commit
objective.evaluate
round.boundary
encounter.end
encounter.rollback
```

Security:

- Client가 Initiative Total, Opportunity, Timeline Cursor와 Damage를 확정하지 못한다.
- DM Override는 Role·Scope·Mandatory Audit를 거친다.
- Hidden Participant·Objective·Trigger가 Error·Diagnostic·Presentation에 노출되지 않는다.
- Timeout은 Server Monotonic Time을 사용하고 Campaign Time을 직접 변경하지 않는다.

측정 대상:

- Participant·Timeline Entry 수
- Turn Start·Reaction·Projection 지연
- Checkpoint·Delta 크기와 Materialization 비용
- 동일 Scene 다중 Encounter의 Temporal Boundary 조정 비용
- Combat HUD Payload·Memory·Low-end Fallback

## 14. Test 계획

1. Exploration Hostile Action→Encounter→Exploration 정상 전환.
2. Initiative Reveal 전 Turn 입력 거부.
3. Timeline 삽입·중도 합류와 완료 Occurrence 역사 유지.
4. Action·Bonus Action·Reaction Reservation 경합.
5. 전투 WASD 거부, 클릭 Movement와 Trigger Checkpoint.
6. Reaction Disconnect·Reconnect와 중복 응답 차단.
7. Damage·Temporary HP·HP 0·DeathSave 원자 Commit.
8. Damage Commit 후 Concentration·Objective Follow-up 분리.
9. Round Boundary 6초 단일 기여와 Scheduler Blocking Due.
10. Encounter End 후 World State 유지.
11. Commit 직후 Restart에서 Cursor·Execution·Time 복원.
12. Rollback 후 이전 Prompt·Due·ACK·Command 차단.
13. Player·DM·Observer Secret Canary 검사.
14. Timeline·Damage·Round Boundary Bounded Interleaving.
15. 대형 Encounter HUD·Projection·Snapshot Budget 측정.

## 15. 구현 순서와 완료 기준

```text
Lifecycle·Participant·Control
→ Initiative·Timeline·Cursor
→ Turn·Opportunity·Movement
→ Reaction·Ready Bridge
→ Damage·Vital·Objective
→ Round Time·Scheduler
→ End·Checkpoint·Rollback
→ HUD·Diagnostics·Integration Test
```

완료 기준:

- Encounter가 Action·Damage·Position Domain을 복제하지 않는다.
- Timeline과 UI 배열이 분리된다.
- RuleExecution과 MovementExecution을 재사용한다.
- HP 0·Death·Objective·Time의 원자·후속 경계가 명확하다.
- Restart·Rollback·Disclosure Test가 포함된다.

Production 구현 전에는 실제 Encounter, Vital, Time, HUD와 Snapshot Package Mapping이 필요하다.