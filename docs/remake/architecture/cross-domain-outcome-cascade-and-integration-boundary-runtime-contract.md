# Cross-Domain Outcome Cascade와 Integration Boundary Runtime 계약

- 상태: 확정
- 문서 종류: Architecture
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 남은 기본값:
  - 단일 Outcome Transaction의 최대 Domain Provider·Mutation Node·Ordering Key 수
  - Immediate Closure Graph의 최대 깊이와 확장 실패 시 DM Recovery Gate 기본값
  - Follow-up Consequence의 기본 Retry·Backoff·Dead Letter 임계값
  - Derived Index Rebuild 중 Command별 Read Degradation·Blocking 기본표
  - Death·Scene Transition 시 대규모 Child Effect·Owned Object 정리 Batch 상한
  - Cross-Domain Gate가 장시간 닫혀 있을 때 DM 경고·자동 복구 제안 시간
  - Outcome Summary Projection의 기본 세부 정보와 비밀 정보 축약 수준
  - Integration Scenario Suite의 필수 실행 시간 Budget
- 작성일: 2026-08-04
- 관련 ADR:
  - [`ADR-0028`](../decisions/ADR-0028-effect-recipes-pending-effects-and-commit-groups.md)
  - [`ADR-0031`](../decisions/ADR-0031-zero-hit-points-death-saves-rests-and-resource-recovery.md)
  - [`ADR-0042`](../decisions/ADR-0042-authoritative-checkpoints-command-journal-and-session-recovery.md)
  - [`ADR-0058`](../decisions/ADR-0058-stable-runtime-object-identity-and-command-driven-lifecycle.md)
  - [`ADR-0059`](../decisions/ADR-0059-versioned-command-protocol-and-projection-stream-synchronization.md)
  - [`ADR-0061`](../decisions/ADR-0061-persistent-rule-execution-orchestrator-and-nested-timing-windows.md)
  - [`ADR-0062`](../decisions/ADR-0062-ordered-reservations-and-atomic-authority-transactions.md)
  - [`ADR-0063`](../decisions/ADR-0063-manifest-chunk-snapshots-commit-journal-and-branch-recovery.md)
  - [`ADR-0077`](../decisions/ADR-0077-transactional-domain-events-with-outbox-and-projection-boundaries.md)
  - [`ADR-0082`](../decisions/ADR-0082-atomic-encounter-boundary-time-advance-and-event-driven-scheduler-bridge.md)
  - [`ADR-0084`](../decisions/ADR-0084-correlated-authority-traces-and-permission-aware-observability.md)
  - [`ADR-0085`](../decisions/ADR-0085-production-parity-deterministic-scenarios-and-controlled-nondeterminism.md)
  - [`ADR-0087`](../decisions/ADR-0087-atomic-immediate-closure-and-event-driven-deferred-consequences.md)
- 상위 문서:
  - [`Runtime Architecture Principles`](runtime-architecture-principles.md)
  - [`Ruleset Policy Registry, Composition과 Frozen Snapshot Runtime 계약`](ruleset-policy-registry-composition-and-frozen-snapshot-runtime-contract.md)
  - [`Rule Runtime Orchestrator와 Pending Execution 계약`](rule-runtime-orchestrator-and-pending-execution-contract.md)
  - [`Command Ordering, Logical Time와 Transaction Coordinator 계약`](command-ordering-logical-time-and-transaction-coordinator-contract.md)
  - [`Domain Event, Outbox, Subscription과 Projection Runtime 계약`](domain-event-outbox-subscription-and-projection-runtime-contract.md)
- 주요 연결 Runtime:
  - [`Dice와 Resolution Runtime 계약`](dice-roll-check-save-attack-and-resolution-runtime-contract.md)
  - [`Effect Runtime 계약`](effect-condition-and-ongoing-runtime-contract.md)
  - [`Encounter Runtime 계약`](encounter-timeline-turn-opportunity-and-objective-runtime-contract.md)
  - [`Encounter–Game Time 통합 계약`](encounter-game-time-temporal-boundary-and-scheduler-integration-contract.md)
  - [`Character Runtime 계약`](character-runtime-and-compiled-character-build-contract.md)
  - [`Inventory Runtime 계약`](inventory-item-instance-and-world-presence-runtime-contract.md)
  - [`Runtime Object Lifecycle 계약`](runtime-object-system-and-entity-lifecycle-contract.md)
  - [`Downtime Runtime 계약`](downtime-activity-time-coordination-and-atomic-completion-runtime-contract.md)
  - [`Session Runtime 계약`](session-play-mode-context-overlay-and-transition-contract.md)
  - [`UI Runtime 계약`](ui-projection-view-model-input-context-and-recovery-runtime-contract.md)
  - [`Diagnostics Runtime 계약`](diagnostics-observability-correlated-trace-and-incident-runtime-contract.md)
  - [`Simulation과 Test Harness 계약`](deterministic-simulation-scenario-and-test-harness-runtime-contract.md)

## 1. 목적

각 Runtime의 권위와 내부 계약이 분리되어 있어도 하나의 Gameplay 결과는 여러 Domain에 연쇄적으로 영향을 준다.

예시:

```text
공격 명중
→ 피해 확정
→ 임시 HP·현재 HP 변경
→ HP 0·즉사·죽음 내성 평가
→ 집중·상태·행동 가능성 변경
→ Encounter 참가자·현재 Turn·Objective 재평가
→ Event·Projection·UI·Presentation 갱신
```

```text
Downtime 레벨업 완료
→ Progression Source Revision
→ Candidate Build 활성화
→ Persistent State Migration
→ Capability·Resource·Spell Projection 재구성
```

```text
Runtime Object 파괴
→ Object Lifecycle 변경
→ 소유 Effect·Interaction Binding 정리
→ Spatial·Navigation·Perception Index 무효화
→ Journal Anchor Broken 또는 Archived 표시
```

각 Domain Service가 상대 Store를 직접 호출하면 순환 의존과 부분 성공이 발생한다. 반대로 모든 후속 결과를 Domain Event Subscriber에만 맡기면 잠시라도 불가능한 권위 상태가 외부에 공개될 수 있다.

따라서 이 문서는 Cross-Domain 결과를 다음 두 부류로 분리한다.

```text
Immediate Closure
→ 현재 결과가 유효한 권위 상태가 되기 위해 같은 Transaction에서 반드시 닫아야 하는 변화

Deferred Consequence
→ 이미 유효하게 Commit된 사실을 원인으로 새 굴림·선택·반응·DM 판정·시간 진행이 필요한 후속 실행
```

핵심 원칙:

```text
유효성 불변식을 닫는 변화는 원자적으로 Commit한다.
새로운 Gameplay 판단이 필요한 결과는 Commit 이후 새 실행으로 시작한다.
```

```text
Integration Runtime은 새로운 Domain Store를 소유하지 않는다.
Domain Provider의 Mutation Proposal과 Follow-up Intent를 조정할 뿐이다.
```

## 2. 사용자 결과

이 계약은 다음 결과를 보장한다.

- 피해가 적용됐는데 대상이 HP 0에서도 행동 가능한 상태로 잠시 노출되지 않는다.
- Actor가 사망했는데 집중, 죽음 내성, 행동 Opportunity와 현재 Turn이 서로 모순된 상태로 남지 않는다.
- 공격 결과는 Commit됐지만 관련 주문 슬롯이나 소비 자원만 사라지는 부분 성공이 발생하지 않는다.
- 집중 내성처럼 새 굴림이 필요한 결과는 피해 Transaction 안에서 임의로 숨겨 실행되지 않는다.
- Encounter 종료 시 Encounter-bound Effect와 Opportunity는 정리되지만 Actor 위치·HP·바닥 Item은 초기화되지 않는다.
- Scene Object가 파괴되어도 Journal Link가 같은 이름의 새 Object에 자동 재연결되지 않는다.
- Derived Index 갱신 실패가 이미 Commit된 권위 결과를 되돌리지 않으며, 필요한 Command만 안전하게 Gate된다.
- 재시도·Subscriber 중복·Server Restart가 같은 Outcome을 두 번 적용하지 않는다.
- Rollback 이전 Branch의 Follow-up Consequence가 새 AuthorityEpoch에 적용되지 않는다.
- Player·DM·Observer는 하나의 Outcome Summary를 보되 각자 공개 가능한 정보만 받는다.
- 모든 Cross-Domain 연쇄는 같은 Trace와 Scenario에서 재현할 수 있다.

## 3. 책임 경계

### 3.1 Integration Coordinator가 소유한다

- 하나의 Root Outcome에 참여할 Domain Provider 조회
- Immediate Closure와 Deferred Consequence 분류
- Cross-Domain Read Set·Write Set·Ordering Key 조립
- Domain Mutation Proposal의 Commit Graph 결합
- Cross-Domain Invariant 검증
- Follow-up Consequence Ledger와 Outbox Staging
- Blocking·Non-blocking Integration Gate 결정
- Outcome Summary와 Correlation Reference 생성
- 재시도·복구·Rollback 시 Outcome Occurrence 멱등성 검증
- Integration Diagnostics와 Simulation Assertion Hook

### 3.2 Integration Coordinator가 소유하지 않는다

- HP, VitalState, Effect, Encounter, Item, Runtime Object와 Character State
- 피해 감소, 죽음 내성, 집중, Objective와 Scene 전환의 실제 규칙
- Domain Mutation의 내부 Schema
- Command Authorization과 Selection
- Projection Disclosure 결정
- Presentation Playback과 UI Component
- Recovery Snapshot과 Commit Journal

### 3.3 Domain Provider가 소유한다

각 Domain은 다음 Adapter를 제공할 수 있다.

```text
CrossDomainIntegrationProvider
├─ providerId
├─ providerVersion
├─ supportedOutcomeKinds[]
├─ applicabilityResolver
├─ immediateClosurePlanner
├─ deferredConsequencePlanner
├─ invariantContributor
├─ orderingContributor
├─ projectionSummaryContributor
├─ migrationAdapter?
└─ diagnosticsProfile
```

Provider는 자신의 Store에 대한 Mutation Proposal만 만든다. 다른 Domain의 내부 상태를 직접 변경하지 않는다.

## 4. Cross-Domain Outcome

```text
CrossDomainOutcomeCandidate
├─ outcomeCandidateId
├─ outcomeKind
├─ rootCommandId?
├─ rootExecutionId?
├─ causeOccurrenceRefs[]
├─ authorityEpoch
├─ frozenPolicySnapshotRef
├─ frozenBuildRefs[]
├─ actorBindings[]
├─ targetBindings[]
├─ encounterBinding?
├─ sceneBinding?
├─ primaryOutcomePayload
├─ resolutionEvidenceRefs[]
├─ disclosureClass
└─ idempotencyKey
```

대표 `outcomeKind`:

```text
damage_application
healing_application
vital_transition
actor_death
actor_revived
resource_consumption
encounter_end
scene_transition
runtime_object_lifecycle
inventory_transfer
character_build_activation
downtime_completion
custom_registered
```

Outcome Candidate는 아직 권위 결과가 아니다. 모든 Provider Contribution과 Invariant를 조립한 뒤 Transaction이 Commit되어야 한다.

## 5. 두 종류의 연쇄

### 5.1 Immediate Closure

Immediate Closure는 Commit 직후 외부에 공개되는 권위 상태가 유효하기 위해 필요한 결정적 변화다.

조건:

- 같은 Frozen Snapshot에서 결정 가능하다.
- 새 사용자 입력·굴림·시간 진행이 필요하지 않다.
- Mutation 대상과 Ordering Key를 Commit 전에 계산할 수 있다.
- 실패하면 Root Outcome 전체를 Abort해야 한다.
- 일부만 적용한 상태를 정상 AuthorityRevision으로 공개할 수 없다.

예시:

```text
최종 피해
+ 임시 HP 흡수
+ 현재 HP 변경
+ 즉시 VitalState 전이
+ DeathSaveState 생성·종료
+ 죽음으로 인한 확정적 Capability 비활성
+ 이미 예약된 불가능한 Opportunity·Resource Reservation 정리
```

```text
Encounter 종료
+ Encounter State 종료
+ Encounter-bound Opportunity 만료
+ Encounter-bound Effect Cleanup
+ Session Mode Binding 전환
```

```text
레벨업 활성화
+ Progression Source Revision
+ Compiled Build Ref 교체
+ Persistent State Migration
+ 사라진 Resource·Capability Binding 정리
```

### 5.2 Deferred Consequence

Deferred Consequence는 이미 유효한 Commit 결과에서 시작하는 새로운 Gameplay 실행이다.

조건:

- 새 RollPlan, TimingWindow, Selection, DM Adjudication 또는 시간 진행이 필요하다.
- 결과가 실패·성공·거절·Timeout으로 갈라질 수 있다.
- 현재 Transaction의 Mutation Graph에 미리 확정할 수 없다.
- 별도 Command 또는 RuleExecution Identity가 필요하다.

예시:

```text
피해 적용
→ 집중 내성 RollExecution
```

```text
Actor 사망
→ Objective 재평가 Command
→ Encounter End Candidate 가능
```

```text
Runtime Object 파괴
→ Journal Anchor Reindex Job
→ Search·Backlink Projection 갱신
```

```text
시간 Checkpoint 도달
→ Encounter Proposal 또는 Hazard RuleExecution
```

Deferred Consequence는 Subscriber가 Store를 직접 수정하는 방식이 아니라 새 Command·RuleExecution을 제출한다.

## 6. Cross-Domain Outcome Plan

```text
CrossDomainOutcomePlan
├─ outcomePlanId
├─ candidateRef
├─ authorityEpoch
├─ policySnapshotRef
├─ participatingProviderRefs[]
├─ readSet[]
├─ writeSet[]
├─ orderingKeys[]
├─ preconditions[]
├─ primaryMutationNodes[]
├─ immediateClosureNodes[]
├─ commitEdges[]
├─ invariantChecks[]
├─ deferredConsequenceIntents[]
├─ integrationGatePlan
├─ domainEventPlan[]
├─ projectionBarrierPlan
├─ auditPlan?
├─ diagnosticsPlan
└─ state
```

상태:

```text
collecting
→ validating
→ prepared
→ committing
→ committed

collecting | validating | prepared
→ rejected | aborted

committing
→ committed | recovery_required
```

## 7. Provider 수집과 의존 방향

Provider 호출 순서는 하드코딩된 서비스 호출 체인이 아니다.

```text
Outcome Candidate
→ Provider Registry 조회
→ Applicability 평가
→ Mutation·Consequence Contribution 수집
→ Dependency DAG 검증
→ Transaction Plan 조립
```

Provider 의존은 타입 있는 요구 관계만 사용한다.

```text
requires_before_commit
requires_after_node
conflicts_with
optional_if_present
```

`DamageProvider → VitalProvider → EncounterProvider → UIService` 같은 직접 호출 체인을 만들지 않는다.

UI, Presentation, Diagnostics와 Journal Projection은 Authority Mutation Provider가 아니다.

## 8. Transaction 경계 결정 규칙

다음 질문에 하나라도 `예`라면 같은 Immediate Closure Transaction에 포함한다.

1. 해당 변화가 빠지면 Commit 직후 Domain Invariant가 깨지는가.
2. Client가 중간 상태를 보면 불가능한 행동을 제출할 수 있는가.
3. Root Outcome을 재시도할 때 별도 적용되면 중복·누락이 생기는가.
4. 결과가 이미 Frozen Snapshot과 현재 Mutation Proposal로 완전히 결정되는가.
5. 실패 시 Root Outcome도 함께 실패해야 하는가.

다음 질문에 하나라도 `예`라면 Deferred Consequence로 분리한다.

1. 새 굴림이나 Reaction TimingWindow가 필요한가.
2. Player·DM 선택 또는 외부 응답을 기다리는가.
3. Campaign Time·Authority Monotonic Time의 미래 경계가 필요한가.
4. 결과가 Commit된 새 상태를 읽어야만 결정되는가.
5. 실패해도 Root Outcome 자체는 유효하게 유지되는가.

## 9. Damage·Healing·Vital 통합

### 9.1 피해 Resolution

```text
Attack·Save·Automatic Outcome
→ Damage Component Resolution
→ 저항·면역·취약·감소
→ 임시 HP 흡수
→ Final Damage Application Candidate
```

Roll Runtime은 HP Store를 수정하지 않는다. Damage Domain Provider가 HP Mutation을 제안한다.

### 9.2 같은 Transaction에 포함되는 변화

기본 통합 경계:

```text
Final Damage
+ Temporary HP Change
+ Current HP Change
+ Maximum HP 관련 확정 변화?
+ Instant Death Evaluation
+ VitalState Transition
+ DeathSave Lifecycle 생성·갱신·종료
+ 확정적 Condition·Capability·Reservation Closure
→ 하나의 Authority Transaction
```

`HP = 0 + conscious`처럼 현재 Policy에서 허용되지 않는 중간 상태를 AuthorityRevision으로 공개하지 않는다.

### 9.3 피해 후 Deferred Consequence

```text
Damage Applied
├─ Concentration Check RuleExecution
├─ On-damage Trigger RuleExecution
├─ Retaliation·Reaction Candidate
├─ Encounter Objective Evaluation Command
└─ Presentation Intent
```

집중 검사는 피해 Transaction 안에서 숨은 Roll로 처리하지 않는다. Commit된 Damage Application을 원인으로 별도 Child RuleExecution을 연다.

다만 현재 실행이 집중 결과를 기다려야만 완료될 수 있다면 `blocking_follow_up` Gate로 Root Execution의 종료만 보류할 수 있다. 이미 Commit된 피해를 되돌리지는 않는다.

### 9.4 Healing

```text
Final Healing Candidate
→ Current HP 변경
→ HP > 0 여부
→ Dying·Stable Lifecycle 종료
→ 즉시 가능한 VitalState 전이
→ 관련 Capability 재계산
→ Atomic Commit
```

회복 후 일어나는 별도 선택·부활 판정·Effect 제거는 해당 규칙이 요구하면 Deferred Consequence다.

## 10. Death·Revival·Encounter 통합

### 10.1 Death Immediate Closure

사망이 확정되면 기본 Closure Plan은 다음을 포함한다.

```text
VitalState = dead
DeathRecord 생성
DeathSaveState 종료
죽음으로 즉시 무효인 Action·Reaction·Movement Opportunity 정리
죽음으로 유지할 수 없는 Resource Reservation 해제
Concentration Channel 종료 Plan
owner_dead End Condition을 즉시 만족한 Effect Cleanup
현재 Actor Capability·Trigger 비활성
Encounter Participant Eligibility 갱신
현재 Turn이 계속 가능한지 Gate 갱신
```

Actor, Character, Inventory와 Runtime Object를 삭제하지 않는다.

Corpse, Body Binding, Item Drop와 Actor Presentation 변경은 `ActorDeathPolicy`와 `CorpsePolicy`가 Domain Proposal로 제공한다. Core Integration이 모든 사망 Actor의 아이템을 자동으로 바닥에 떨어뜨리지 않는다.

### 10.2 Death Deferred Consequence

```text
actor.died
→ Objective Evaluation Command
→ Faction·Morale·Surrender RuleExecution
→ Encounter End Candidate
→ Quest·Journal Subscriber
→ Presentation Intent
```

Objective Evaluation이 Encounter 종료 후보를 만들 수 있지만 사망 Transaction이 Encounter를 임의 종료하지 않는다.

### 10.3 현재 Turn

사망 Actor가 현재 Turn을 소유한 경우:

```text
Death Closure Commit
→ ActiveTurn Gate closed_for_actor
→ 열린 필수 Cleanup 확인
→ Encounter Advance Command
```

Turn Cursor를 Damage Provider가 직접 이동시키지 않는다. Encounter Provider가 Closure에서 현재 Turn의 유효성만 갱신하고, 실제 Cursor 이동은 안전한 Encounter Advance Command가 처리한다.

### 10.4 Revival

부활은 DeathRecord와 현재 Actor·Character 상태를 검증하는 별도 RuleExecution이다.

Immediate Closure 예시:

```text
부활 자원 소비
+ DeathRecord에 Revival Relation 기록
+ HP·VitalState 변경
+ 부활로 종료·생성되는 Effect
+ Capability·Encounter Eligibility 재계산
→ Atomic Commit
```

Scene에 Actor Presence가 없으면 Runtime Object Materialization 또는 Scene Transition은 별도 안전 경계를 사용할 수 있다.

## 11. Encounter 종료 통합

Encounter End Candidate가 확정되면 다음을 하나의 End Transaction으로 조립한다.

```text
Encounter lifecycle = ended
Timeline·Turn·Opportunity 종료
미사용 Encounter Reservation 정리
Encounter-bound Effect Cleanup
Control Assignment 만료·복원
Round Time·Partial Round Policy 정산
Session Base Mode Binding 전환
Encounter End Domain Event Outbox
```

다음은 유지한다.

- Actor 위치·HP·VitalState
- 시체와 바닥 Item
- Encounter 종료 후에도 유지되는 Character·Actor·Campaign Effect
- Scene Object 상태
- 발견된 Knowledge
- Journal Source와 Anchor Identity

Encounter 종료로 인한 Exploration Camera·HUD 변경은 Projection·UI·Presentation 결과이지 권위 Mutation이 아니다.

## 12. Runtime Object·Scene·Derived Index 통합

### 12.1 Runtime Object Lifecycle

```text
Spawn·Suspend·Archive·Destroy Candidate
→ Runtime Object Mutation Proposal
→ Ownership·Effect·Interaction Binding Closure
→ Stable ID·Incarnation·Tombstone 갱신
→ Atomic Commit
```

Scene Workspace Instance의 생성·삭제 성공 여부는 권위 Lifecycle을 결정하지 않는다.

### 12.2 Derived Index

다음은 권위 Store가 아니라 Derived Data다.

```text
Spatial Index
Navigation Cache
Perception Candidate Index
Interaction Query Cache
Journal Reverse Anchor Index
UI ViewModel Cache
```

권위 Transaction은 다음만 원자적으로 남긴다.

```text
Authoritative Mutation
+ Index Invalidation Record
+ 필요한 Domain Event
```

Commit 이후 Index Maintainer가 영향 범위를 증분 갱신한다.

### 12.3 Index 실패와 Gate

Index 갱신 실패는 이미 Commit된 Object 파괴·이동·Scene 변경을 되돌리지 않는다.

대신 Index Health를 다음처럼 분류한다.

```text
current
degraded_read_safe
rebuild_required
blocking_for_authority_query
```

Authoritative Spatial·Navigation·Visibility 검증에 오래된 Index를 사용할 위험이 있으면 관련 Command만 Gate한다. Journal 검색이나 UI 정렬처럼 권위 결과를 만들지 않는 Query는 안전한 축약·재시도·Fallback을 사용할 수 있다.

## 13. Scene Transition과 Streaming 통합

Scene Transition은 Camera 이동이나 Workspace Model 교체가 아니다.

```text
Transition Proposal
→ 현재 Movement·RuleExecution 분류
→ 필요한 Actor·Runtime Object Transfer Plan
→ Scene Binding·Control·Effect·Knowledge Closure
→ Authority Transaction
→ Streaming·Client Ready Gate
→ 새 Scene Activation
```

Transition Transaction에 포함되는 항목은 해당 Transition Policy가 요구하는 권위 Binding이다. Presentation Materialization과 Client Chunk Ready는 Commit 이후 Gate에서 처리한다.

Client Streaming 실패 때문에 이미 Commit된 Campaign State를 자동 Rollback하지 않는다. 필수 Client가 준비되지 못하면 Observer·Reconnect·Fallback 정책을 적용한다.

## 14. Downtime·Character Build·Inventory 통합

Downtime Runtime의 Completion Plan은 이 계약의 Cross-Domain Outcome Plan을 사용할 수 있다.

### 14.1 Build Activation

```text
Progression Source Revision
+ Candidate Compiled Build Ref
+ Persistent State Migration
+ Resource·Capability·Spell Preparation Closure
+ Pending Execution Compatibility 정리
→ Atomic Commit
```

Compile·Migration 실패는 Source 일부 적용으로 이어지지 않는다.

### 14.2 Crafting

```text
입력 Item·Resource 소비
+ Output ItemInstance 생성
+ Container Binding 또는 Ground Presence
+ Activity Completion
→ Atomic Commit
```

Ground Presence 생성이 필요한 경우 Inventory Provider와 Runtime Object Provider가 같은 Transaction에 Mutation Proposal을 기여한다.

### 14.3 Rest

Rest 완료는 RecoveryPlan이 HP, Hit Dice, Spell Slot, Feature Resource와 Effect Boundary Proposal을 제공한다. Downtime은 조정자이며 회복 수치를 직접 작성하지 않는다.

휴식 종료 후 새 선택이나 주문 준비가 필요한 경우, 정책에 따라 같은 Completion Transaction의 필수 선택으로 포함하거나 별도 Blocking Follow-up으로 분리한다.

## 15. Interaction·Selection·Journal 통합

Selection과 Journal Navigation은 권위 Mutation을 직접 만들지 않는다.

```text
Projection-safe Candidate·Anchor
→ Intent
→ Command Authorization
→ Domain Outcome Candidate
```

문 열기, Item Pickup과 Actor 선택은 서로 다른 Domain Outcome을 만들 수 있지만, Selection이 해당 Store를 수정하지 않는다.

Journal Anchor 대상이 Archive·Destroy되면:

```text
Runtime Object Tombstone
→ Anchor Resolution Invalidation
→ Journal Reindex Follow-up
→ broken | archived | stale_runtime_incarnation Projection
```

동명 대상 자동 Retarget은 금지한다.

## 16. Follow-up Consequence Ledger

```text
DeferredConsequenceIntent
├─ consequenceIntentId
├─ rootOutcomePlanId
├─ rootTransactionId
├─ causeEventIds[]
├─ consequenceKind
├─ targetCommandOrExecutionType
├─ frozenContextRefs[]
├─ latestStateValidationPlan
├─ blockingPolicy
├─ idempotencyKey
├─ authorityEpoch
├─ retryPolicyRef
├─ state
└─ terminalResultRef?
```

상태:

```text
staged
→ dispatched
→ accepted
→ completed

staged | dispatched | accepted
→ retry_wait | dead_letter | invalidated | cancelled
```

Outbox와 같은 Transaction에서 `staged` 상태를 기록한다. Subscriber가 전달에 실패해도 Consequence Intent가 사라지지 않는다.

## 17. Integration Gate

모든 후속 결과가 Root Outcome을 막는 것은 아니다.

```text
non_blocking
→ Root Outcome과 현재 진행은 계속 가능

block_execution_completion
→ Root RuleExecution 종료만 대기

block_turn_advance
→ 현재 Turn의 다음 Occurrence 진행을 대기

block_mode_transition
→ Encounter End·Scene Transition·Downtime Completion을 대기

block_authority_query_scope
→ 특정 Index·Scope를 요구하는 Command만 대기
```

Gate는 Campaign 전체를 무조건 Pause하지 않는다.

Gate 해제 조건은 타입 있는 Terminal Result와 최신 AuthorityEpoch를 검증한다.

## 18. Event와 Projection Barrier

Cross-Domain Transaction은 Domain별 Event를 각각 생성할 수 있지만 하나의 AuthorityRevision과 Root Outcome Reference를 공유한다.

```text
transaction.committed
├─ damage.applied
├─ hit_points.changed
├─ vital_state.changed
├─ effect.ended
└─ encounter.participant_state_changed
```

Client Projection은 같은 Transaction의 관련 Segment를 하나의 Batch로 적용한다.

```text
ProjectionBarrierPlan
├─ authorityRevision
├─ requiredSegmentIds[]
├─ optionalSegmentIds[]
├─ audiencePolicyRefs[]
└─ timeoutFallbackPolicy
```

HP만 먼저 바뀌고 VitalState·Action 버튼이 나중에 바뀌는 화면을 정상 상태로 표시하지 않는다.

Presentation은 Commit된 Outcome Summary를 재생하며 Authority State를 결정하지 않는다.

## 19. 멱등성·재시도·복구

```text
rootOutcomeIdempotencyKey
+ authorityEpoch
+ causeOccurrenceRef
→ 하나의 Outcome Plan과 Commit
```

재시도 시:

- 이미 Commit된 Transaction이면 기존 Outcome Result를 반환한다.
- Prepared 상태면 Journal·Commit Marker로 완료 여부를 판정한다.
- Deferred Consequence는 자신의 Idempotency Key로 별도 중복 방지한다.
- 이전 AuthorityEpoch의 Consequence는 `invalidated` 처리한다.
- Subscriber 중복 전달은 새 Domain Mutation을 직접 만들지 않는다.

Server Restart 후에는 Snapshot과 Journal에서 Outcome Plan·Follow-up Ledger·Gate를 복구한다.

## 20. Rollback

Rollback은 과거 상태를 역연산하지 않는다.

```text
선택한 Snapshot·Journal Boundary
→ 새 Branch와 AuthorityEpoch
→ Domain State·Outcome Ledger·Gate 복원
→ Derived Index·Projection 재구성
```

폐기 Branch의:

- Follow-up Command
- Reaction 응답
- Index Rebuild 완료 신호
- Presentation ACK
- Client Command Result

은 새 Branch에 적용할 수 없다.

## 21. 실패 처리

### 21.1 Commit 전 실패

Provider 누락, Invariant 충돌, Ordering 실패와 Mutation Graph 오류가 발생하면 전체 Outcome을 Reject 또는 Abort한다.

부분 Mutation을 공개하지 않는다.

### 21.2 Commit 이후 Follow-up 실패

Root Outcome은 유지한다.

```text
Retry
→ Dead Letter
→ Integration Incident
→ DM Recovery Command 또는 안전한 자동 Fallback
```

Blocking Gate가 있으면 해당 Scope만 닫고 이유를 Projection한다.

### 21.3 Derived System 실패

UI, Presentation, Search Index와 Diagnostics 실패는 권위 Transaction을 되돌리지 않는다. 단, 권위 판정에 필요한 Spatial·Navigation·Visibility Index가 안전하지 않으면 관련 Command Gate를 닫는다.

## 22. 진단

모든 Outcome은 같은 Trace Graph에 다음을 남긴다.

```text
outcome.candidate
integration.provider_collect
integration.immediate_closure_plan
integration.invariant_validation
transaction.prepare
transaction.commit_or_abort
integration.follow_up_stage
integration.gate_state
projection.barrier
integration.follow_up_terminal
```

Decision Record:

- 어떤 Provider가 참여했는가
- 어떤 변화가 Immediate Closure로 분류됐는가
- 어떤 결과가 Deferred Consequence로 분리됐는가
- 어떤 Frozen Policy Snapshot이 사용됐는가
- 어떤 Invariant와 Ordering Key가 적용됐는가
- Gate가 왜 닫히거나 열렸는가
- Follow-up이 Retry·Dead Letter·Invalidated된 이유

Raw Decision Detail은 역할별 Diagnostic Projection과 Redaction을 적용한다.

## 23. Simulation 필수 Scenario

Integration 완료 판정에는 최소 다음 Scenario가 필요하다.

```text
1. 피해로 HP 0 도달과 DeathSaveState 생성이 같은 Commit에 포함된다.
2. 즉사 시 DeathRecord·집중 종료·Opportunity 정리가 부분 성공 없이 적용된다.
3. 피해 후 집중 내성이 별도 RuleExecution으로 한 번만 생성된다.
4. 현재 Turn Actor 사망 후 Turn Advance가 중복 실행되지 않는다.
5. 마지막 적 사망 후 Objective Evaluation과 Encounter End Candidate가 한 번 생성된다.
6. Encounter 종료가 Actor HP·위치·바닥 Item을 초기화하지 않는다.
7. 제작 입력 소비와 Output Item·Ground Presence 생성이 원자적으로 적용된다.
8. Runtime Object 파괴 후 Spatial Index 실패가 Object를 되살리지 않는다.
9. 오래된 Spatial Index를 요구하는 Movement Command는 Gate된다.
10. Journal Anchor는 파괴된 동명 Object에 자동 Retarget되지 않는다.
11. Rollback 이전 Follow-up Consequence가 새 Epoch에서 실행되지 않는다.
12. 같은 Transaction의 HP·Vital·Encounter Projection이 하나의 Batch로 적용된다.
13. Presentation 실패 후 Authority Outcome은 유지된다.
14. Provider 하나가 실패하면 Immediate Closure Transaction 전체가 Abort된다.
15. Dead Letter된 Blocking Follow-up이 DM Recovery Incident로 노출된다.
```

## 24. 역할 경계

### Player

- 공개된 Outcome Summary와 자신에게 필요한 Follow-up Prompt 확인
- 자신의 Reaction·선택·Recovery Command 제출
- 비공개 Provider·Objective·DC·정책 내부 정보는 열람하지 않음

### DM

- Campaign Scope의 Outcome·Gate·Dead Letter와 복구 상태 확인
- 규칙상 허용된 Override·Retry·Cancel·Force Resolution Command 제출
- Raw Store 직접 수정 없이 Transaction·Audit 경계 사용

### Observer

- 공개 가능한 Outcome과 Encounter·Scene 결과만 확인
- Follow-up Command 제출 권한 없음

### System

- Provider 수집, Plan 조립, Invariant·Ordering 검증
- Transaction·Outbox·Follow-up Ledger·Gate 관리
- Projection Barrier, Recovery와 Diagnostics 연결

## 25. 성능과 확장성

- 모든 Domain을 매 Outcome마다 전수 순회하지 않고 `outcomeKind`별 Provider Index를 사용한다.
- Provider Contribution은 명시적 Budget과 Dependency DAG를 가진다.
- 무제한 Parent·Child Effect·Owned Object 정리를 한 Transaction에서 동적 확장하지 않는다. Plan 단계에서 상한과 전체 대상 집합을 검증한다.
- Ordering Key는 실제 충돌 Scope만 포함하고 Campaign 전체 Key로 직렬화하지 않는다.
- Projection Barrier는 필요한 Segment만 묶는다.
- Non-blocking Follow-up은 Root Execution을 기다리지 않는다.
- 대규모 Index Rebuild는 영향 범위·Revision 기준으로 Batch 처리한다.
- Custom Provider는 Registry·Schema·Version·Migration·Diagnostics Profile을 가져야 한다.

## 26. 비목표

- 모든 Domain 상태를 하나의 거대한 Store나 Service로 합치지 않는다.
- 모든 후속 결과를 같은 Transaction에 강제로 넣지 않는다.
- Domain Event Subscriber가 다른 Store를 직접 수정하지 않는다.
- UI·Presentation·Workspace Instance를 Authority Mutation Provider로 사용하지 않는다.
- Derived Cache 실패를 이유로 권위 결과를 자동 Rollback하지 않는다.
- 이름·표시 문자열을 Cross-Domain Identity로 사용하지 않는다.
- DM Override가 Transaction·Permission·Audit를 우회하지 않는다.

## 27. 구현 순서 제안

```text
1. CrossDomainOutcomeCandidate와 Provider Registry Schema
2. Immediate Closure·Deferred Consequence 분류기와 Invariant Registry
3. Transaction Coordinator Integration Adapter
4. Follow-up Consequence Ledger와 Gate
5. Damage·Healing·Vital Provider
6. Death·Effect·Encounter Provider
7. Runtime Object·Index Invalidation Provider
8. Downtime·Build·Inventory Provider
9. Projection Barrier와 Outcome Summary
10. Recovery·Diagnostics·Simulation Scenario
```

실제 파일·Module·Command Schema는 Implementation Specs 단계에서 확정한다.
