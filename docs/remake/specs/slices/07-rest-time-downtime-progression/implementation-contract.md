# Implementation Spec — Slice 07 Rest·Time·Downtime·Progression

- 상태: SPEC_CHECKPOINT_COMPLETE
- 문서 종류: Slice Integration Implementation Spec
- 구현 상태: 미구현
- 즉시 구현 명세 가능성: BLOCKED
- 작성일: 2026-08-05
- 차단 이유: 실제 Campaign Time·Scheduler·Downtime Provider·Character Migration·Item Reservation 구조가 확인되지 않았다.
- Work Order: [`CURRENT-WORK-ORDER.md`](CURRENT-WORK-ORDER.md)
- Roadmap: [`SLICE-ROADMAP.md`](../../SLICE-ROADMAP.md)
- 선행 계약: [`Character`](../05-character-foundation-creation/implementation-contract.md), [`Inventory`](../06-inventory-equipment-world-items/implementation-contract.md), [`Encounter`](../04-encounter-core-loop/implementation-contract.md)
- 관련 Guide: [`Character`](../../../guides/character/README.md), [`Rules`](../../../guides/rules/README.md), [`Combat`](../../../guides/combat/README.md), [`Session`](../../../guides/session/README.md), [`UI`](../../../guides/ui/README.md), [`Diagnostics`](../../../guides/diagnostics/README.md)

> Downtime Runtime은 Character·Inventory·Spell·Rest Store를 직접 수정하지 않는다. 시간과 활동 진행을 조정하고, 각 Domain Completion Provider가 만든 결과를 하나의 Transaction으로 Commit한다.

## 1. Acceptance Flow

### Player

```text
Activity 선택
→ 참가·비용·시간 확인
→ 선택·승인 제출
→ 진행·중단·중간 사건 확인
→ Completion 결과 확인
→ Reconnect 후 진행 상태 복구
```

### DM

```text
Campaign Time·Activity Policy 확인
→ Participant·Provider·시설·비용 검토
→ Time Advance·중간 사건·Encounter 처리
→ Completion Candidate 승인
→ 실패·중단·Recovery Review
```

## 2. 직접 권위 문서

- [`Downtime Activity, Time Coordination과 Atomic Completion`](../../../architecture/downtime-activity-time-coordination-and-atomic-completion-runtime-contract.md)
- [`Game Time, Calendar, Duration과 Scheduler`](../../../architecture/game-time-calendar-duration-and-scheduler-runtime-contract.md)
- [`Character Runtime과 Compiled Character Build`](../../../architecture/character-runtime-and-compiled-character-build-contract.md)
- [`Inventory, ItemInstance와 World Presence`](../../../architecture/inventory-item-instance-and-world-presence-runtime-contract.md)
- [`Ruleset Policy Registry와 Frozen Snapshot`](../../../architecture/ruleset-policy-registry-composition-and-frozen-snapshot-runtime-contract.md)
- [`Command Ordering과 Transaction Coordinator`](../../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)
- [`Cross-Domain Outcome Cascade`](../../../architecture/cross-domain-outcome-cascade-and-integration-boundary-runtime-contract.md)
- [`Domain Event와 Projection Runtime`](../../../architecture/domain-event-outbox-subscription-and-projection-runtime-contract.md)
- [`Persistence와 Session Recovery`](../../../architecture/persistence-and-session-recovery-model.md)
- [`HP 0·Death Save·Rest·Resource Recovery`](../../../systems/character/zero-hit-points-death-saves-rest-and-resource-recovery-model.md)
- [`Spell Acquisition·Preparation·Cast Access`](../../../systems/character/spell-acquisition-preparation-and-cast-access-model.md)
- [`Spellbook Repository와 Copying`](../../../systems/character/spellbook-repository-and-copying-model.md)

## 3. 범위

포함:

- Campaign Instant·Calendar·Duration·Scheduler
- Downtime Session·Activity·Participant Window
- Eligibility·Resource·Item·Provider Reservation
- Progress·Checkpoint·Choice·DM Approval
- Short·Long Rest와 Resource Recovery
- Level Up Source·Build·State Migration
- Spell Preparation·Spellbook Repository·Copy
- Crafting·Training·Travel
- Encounter·Hazard 중단과 재개
- Cancel·Settlement·Reconnect·Restart·Rollback

제외:

- 현실 시간·Offline 시간 자동 진행
- Shop·Economy Simulation
- 전체 Activity Content·비용표
- 모든 공식 Character·Spell Option 데이터

## 4. Type와 상태

```lua
export type CampaignTimeState = {
    campaignId: string,
    campaignInstant: number,
    calendarProfileRef: string,
    timeRevision: number,
}

export type ScheduledOccurrence = {
    scheduleId: string,
    dueInstant: number,
    occurrenceKind: string,
    sourceRef: string,
    state: "scheduled" | "due" | "dispatched" | "resolved" | "cancelled",
    revision: number,
}

export type DowntimeSession = {
    downtimeSessionId: string,
    campaignId: string,
    policySnapshotRef: string,
    state: "preparing" | "active" | "suspended" | "completing" | "completed" | "cancelled",
    participantRevision: number,
    progressRevision: number,
}

export type ActivityRecord = {
    activityId: string,
    activityKind: string,
    participantRefs: {string},
    providerRef: string,
    requiredDuration: number,
    creditedDuration: number,
    checkpointRef: string?,
    reservationRefs: {string},
    state: "proposed" | "eligible" | "active" | "awaiting_choice" | "suspended" | "completion_candidate" | "completed" | "cancelled" | "failed",
    revision: number,
}
```

현실 Clock, Server Uptime와 Campaign Time을 혼용하지 않는다. Scheduler Callback이 Character·Item·Encounter Store를 직접 수정하지 않는다.

## 5. Activity 시작과 진행

```text
Activity Intent
→ Participant·Eligibility·Provider·Facility 검증
→ Frozen Policy·Content Version 고정
→ Resource·Item·Currency Reservation
→ Activity Record 생성
→ Time Advance Candidate
→ Checkpoint Commit
```

Time Advance는 중간 사건, Scheduler Due, Choice, Provider Milestone과 Encounter Proposal 경계를 건너뛰지 않는다.

```text
현재 Campaign Instant
→ 다음 Activity·Schedule·Hazard Checkpoint 계산
→ Time Advance Plan
→ Due Staging
→ Activity Progress Contribution
→ 원자 Commit
→ 후속 Command·RuleExecution
```

여러 Activity가 같은 Campaign Clock을 독립적으로 전진시키지 않는다.

## 6. Rest

Short·Long Rest는 Activity Provider다.

```text
Rest 참가자·환경·중단 Policy
→ Eligibility·Duration
→ Resource Recovery Candidate
→ Hit Dice·Spell Slot·Feature·HP 선택
→ 중간 Encounter·Hazard 처리
→ 참가자별 credited duration 재검증
→ Recovery Plan
→ Atomic Commit
```

파티가 함께 쉬어도 합류 시점과 중단 상태에 따라 참가자별 적격 결과가 다를 수 있다. 중단된 휴식을 자동 완료하거나 자동 회복하지 않는다.

## 7. Level Up

```text
Level Up Activity
→ Class·Subclass·Feat·Ability·Spell 선택
→ Candidate Character Source Revision
→ Candidate Build Compile
→ Old Build·State Compatibility
→ State Migration Plan
→ Player·DM Review
→ Source + Build Ref + State Atomic Activation
```

Compile·Migration·필수 Repository 검증이 실패하면 일부 Level, 최대 Resource 또는 Capability만 적용하지 않는다.

## 8. Spell Preparation·Spellbook

Preparation:

```text
허용 Boundary
→ Spellcasting Profile·Acquisition·Repository 조회
→ Preparation Set 선택
→ Access·Readiness 검증
→ Persistent Preparation State Proposal
→ Capability Projection 갱신
→ Commit
```

Spellbook 생성은 ItemInstance와 Repository Record를 하나의 Transaction으로 만든다. Copy는 Source Entry, Destination, 비용·재료·시간 Reservation과 Completion을 사용한다. Spellbook Item Transfer가 Repository 접근권을 바꿀 수 있으므로 Inventory와 Character Projection Barrier를 함께 사용한다.

## 9. Crafting·Training·Travel

Crafting:

```text
Recipe·Crafter·Tool·Facility
→ Input Item·Currency Reservation
→ Progress Checkpoint
→ Output Candidate·Quality 검증
→ Input 소비 + Output ItemInstance + Location Binding
→ Atomic Completion
```

Training은 Completion Provider가 Progression Change, Exceptional Grant 또는 Training Record를 제안한다. UI가 Capability를 직접 추가하지 않는다.

Travel:

```text
Route·Participant·Transport·Watch
→ Segment·Time·Resource Policy
→ 다음 사건까지 Time Advance
→ Scheduler·Hazard·Encounter
→ 재개·Arrival Plan
→ 필요 시 Scene Transition
```

Travel을 Runtime Navigation의 장시간 프레임 재생으로 구현하지 않는다.

## 10. 중단·취소·Encounter

```text
Hazard·Encounter·Facility 상실·Eligibility 변화
→ 현재 Progress Checkpoint
→ Activity suspended
→ 사건 해결
→ Character·Item·Time·Reservation 재검증
→ Progress 유지·부분 유지·초기화·취소 Policy
→ 재개 또는 Terminal Settlement
```

취소는 이미 Commit된 중간 사실을 조용히 역연산하지 않는다. Reservation Release, Partial Settlement, Forfeit와 Tombstone을 명시한다.

## 11. Command·Transaction

대표 Command:

- `StartDowntimeSession`
- `JoinActivity`
- `ReserveActivityInputs`
- `AdvanceCampaignTime`
- `SubmitActivityChoice`
- `ApproveActivityCompletion`
- `SuspendActivity`
- `ResumeActivity`
- `CancelActivity`
- `CompleteRest`
- `ActivateLevelUp`
- `ChangeSpellPreparation`

Ordering은 Campaign Time, Activity, Character, Item, Repository와 Resource Key를 결정적으로 정렬한다. 장기 대기 중 Transaction Lock을 유지하지 않고 Reservation과 Revision을 사용한다.

## 12. Persistence·Recovery·Rollback

저장:

- Campaign Time·Calendar·Scheduler Cursor
- Downtime Session·Activity·Participant·Progress
- Choice·Approval·Reservation·Provider Version
- Character Candidate Source·Build·Migration
- Item·Currency·Spellbook Repository Binding
- Outbox·Due·Completion Marker

Reconnect는 Pending Choice·Approval을 사용자별 Projection으로 재발행한다. Restart는 Snapshot과 Journal에서 Due·Progress·Reservation을 복원하고 중복 Completion을 차단한다. Rollback 후 이전 Epoch Choice·Due·Completion·Subscriber를 거부한다.

## 13. UI·Diagnostics·Security

필수 UI 상태:

```text
참가 가능·불가 이유
필요 시간·비용·시설
진행·Checkpoint
선택·DM 승인 대기
Encounter로 중단
재개 가능·재검증 필요
취소 정산
Completion 실패·Last Known Good
Reconnect·Recovery Review
```

Trace:

```text
time.advance
time.schedule_due
downtime.start
activity.reserve
activity.progress
activity.suspend
rest.complete
level_up.compile
level_up.activate
spell.prepare
spellbook.copy
craft.complete
travel.segment
```

Security:

- Client가 elapsed time, Progress, Completion과 Output을 확정하지 못한다.
- 현실 시간·Offline 시간으로 자동 보상하지 않는다.
- DM 승인과 Force Completion은 Mandatory Audit를 사용한다.
- 비공개 Spell·Item·Activity 정보는 Viewer Projection에서 제외한다.

## 14. Test 계획

1. 정상 Short·Long Rest와 참가자별 적격성.
2. Rest 중 Encounter와 Progress 재평가.
3. Level Up Compile 실패·Last Known Good 유지.
4. Level Up Source·Build·State 원자 활성화.
5. Preparation 변경과 Capability 갱신.
6. Spellbook Copy 비용·원본·Entry 원자 Commit.
7. Crafting Input·Output·Ground Presence 원자성.
8. 병렬 Activity의 Campaign Time 중복 방지.
9. Travel 중 Scheduler Due·Encounter·Scene Transition.
10. Disconnect·Restart 후 Pending Choice·Reservation 복구.
11. 중복 Completion Command 멱등 처리.
12. Rollback 이전 Due·Choice·Completion 차단.
13. Player·DM Activity Projection Disclosure.
14. 긴 Time Advance의 Checkpoint 누락 탐지.

## 15. 구현 순서와 완료 기준

```text
Campaign Time·Scheduler
→ Downtime Session·Activity
→ Reservation·Checkpoint·Interruption
→ Rest Provider
→ Level Up Migration
→ Preparation·Spellbook
→ Crafting·Training·Travel
→ Recovery·Diagnostics·Integration Test
```

완료 기준:

- 하나의 Campaign Time Authority를 사용한다.
- Downtime이 Domain Store를 직접 수정하지 않는다.
- 중단·취소·Completion이 Reservation·Transaction으로 안전하다.
- Level Up과 Crafting이 부분 적용되지 않는다.
- Restart·Rollback 후 중복 Due·Completion이 없다.

Production 구현 전 실제 Time·Scheduler·Provider·Migration·UI Mapping이 필요하다.