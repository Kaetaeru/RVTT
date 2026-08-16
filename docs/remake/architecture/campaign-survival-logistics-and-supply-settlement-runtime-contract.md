# Campaign Survival Logistics와 Supply Settlement Runtime 계약

- 상태: 확정
- 문서 종류: Architecture
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 작성일: 2026-08-06
- 최종 갱신일: 2026-08-07
- 상위 결정: [`ADR-0092`](../decisions/ADR-0092-campaign-survival-logistics-and-dm-authored-actor-tokens.md)
- 관련 계약:
  - [`Ruleset Policy Runtime`](ruleset-policy-registry-composition-and-frozen-snapshot-runtime-contract.md)
  - [`Game Time Runtime`](game-time-calendar-duration-and-scheduler-runtime-contract.md)
  - [`Inventory Runtime`](inventory-item-instance-and-world-presence-runtime-contract.md)
  - [`Effect Runtime`](effect-condition-and-ongoing-runtime-contract.md)
  - [`Transaction Coordinator`](command-ordering-logical-time-and-transaction-coordinator-contract.md)

## 1. 목적

이 계약은 Campaign Game Time의 경과를 식량·물·탈것 사료·휴식 품질·환경 노출·탄약과 같은 선택적 세부 규칙에 연결한다.

```text
활성 Campaign Policy
+ 활성 Rule Content
+ Consumer·Inventory Snapshot
→ Supply Settlement Plan
→ Atomic Commit
```

Engine은 공식 규칙 수치를 직접 소유하지 않는다. 정확한 요구량·면제·배수·결핍 결과는 활성 Ruleset·Source Pack의 Definition과 Stable Rule Anchor에서 가져온다.

## 2. Policy Family

```text
survival.logistics.enabled
survival.food.enabled
survival.water.enabled
survival.mount_feed.enabled
survival.exposure.enabled
survival.encumbrance.enabled
survival.ammunition.enabled
survival.rest_quality.enabled
survival.spoilage.enabled
survival.settlement_mode
survival.source_priority
survival.shortage_disclosure
```

`survival.logistics.enabled=false`는 하위 Module의 미래 자동 Settlement를 차단한다. 하위 Binding과 Ledger를 삭제하지 않는다.

`survival.source_priority`는 공급원 순서의 유일한 권위다. Slice 06 Inventory는 Supply Source의 membership·ACL·disclosure·revision을 소유하지만 독립적으로 변경 가능한 priority를 저장하지 않는다. 순서 변경은 Candidate Policy Snapshot을 Compile하고 Safe Boundary에서 활성화한다.

Preset:

```text
narrative
standard
survival
custom
```

Preset은 Campaign Binding을 만드는 UI 템플릿이다. Runtime은 Preset 문자열이 아니라 Frozen Snapshot의 Family 결과를 사용한다.

## 3. 정확한 규칙 수치의 출처

```text
ConsumptionRequirementDefinition
├─ requirementId
├─ rulesetId
├─ consumerPredicateRef
├─ supplyKind
├─ settlementPeriod
├─ unitsExpressionRef
├─ modifierContributionKinds[]
├─ exemptionPredicateRef?
├─ shortageRecipeRef
├─ disclosurePolicy
├─ ruleAnchor
├─ version
└─ contentHash
```

`unitsExpressionRef`는 신뢰된 Compiled Expression이나 등록된 Evaluator만 참조한다. Campaign Setting이 임의 Luau를 주입하지 않는다.

Rule Anchor:

```text
rvtt-rule://<packageId>/<moduleId>/<documentId>#<anchorId>
```

UI는 요구량 옆에서 해당 규칙을 연다.

## 4. Supply Definition

```text
SupplyDefinition
├─ supplyDefinitionId
├─ supplyKind
├─ itemDefinitionRef
├─ unitsPerItemQuantity
├─ divisible
├─ minimumConsumptionIncrement
├─ freshnessProfileRef?
├─ qualityProfileRef?
├─ consumerCompatibilityTags[]
├─ protectedByDefault
├─ ruleAnchor?
├─ version
└─ contentHash
```

ItemInstance는 CompiledItemBuild를 통해 SupplyDefinition을 참조한다. 이름, 설명, 색상, Thumbnail 또는 Container 이름만으로 Supply를 추론하지 않는다.

## 5. Consumer

```text
SupplyConsumerBinding
├─ consumerRef
├─ consumerKind
├─ participationInterval
├─ requirementSetRef
├─ modifierContributionRefs[]
├─ exemptionRefs[]
├─ assignedSupplyGroupId?
├─ assignedContainerRefs[]
├─ ownerActorRef?
└─ disclosurePolicy
```

초기 Consumer Kind:

```text
player_character
scene_npc
follower
mount
vehicle_crew_group
campaign_group
custom_registered
```

소환 직후 사라지는 임시 Actor는 Definition이 명시적으로 요구하지 않는 한 일일 Consumer에 포함하지 않는다.

## 6. 정산 경계

```text
game_day_boundary
meal_boundary
long_rest_completion
travel_checkpoint
downtime_checkpoint
dm_explicit_settlement
custom_registered
```

기본 일일 소비는 Calendar Day 문자열이 아니라 `GameTimeInstant` 구간과 Ruleset Settlement Period를 사용한다. 부분 날짜는 버리지 않는다.

```text
LogisticsSettlementState
├─ campaignId
├─ policySnapshotRef
├─ lastSettledInstant
├─ requirementAccumulatorsByConsumer
├─ lastSettlementId?
├─ revision
└─ authorityEpoch
```

Accumulator는 고정소수점 단위로 부분 요구량을 보존한다.

## 7. Settlement Plan

```text
LogisticsSettlementPlan
├─ settlementId
├─ campaignId
├─ timeAdvanceProposalRef
├─ fromInstant
├─ toInstant
├─ policySnapshotRef
├─ sourceOrderDigest
├─ ruleContentVersionSet
├─ consumerPlans[]
├─ sourceAllocationPlans[]
├─ shortagePlans[]
├─ reservationPlan
├─ approvalMode
├─ disclosurePlan
├─ planHash
├─ authorityRevision
└─ authorityEpoch
```

```text
ConsumerSupplyPlan
├─ consumerRef
├─ requirementDefinitionRef
├─ requiredUnits
├─ carriedFractionBefore
├─ carriedFractionAfter
├─ exemptionTrace[]
├─ modifierTrace[]
├─ allocatedUnits
├─ shortageUnits
└─ consequenceRecipeRef?
```

`sourceOrderDigest`는 `policySnapshotRef`, 활성 Supply Source membership revision과 Stable 정렬 결과를 반영한다. Plan과 Reservation은 이 Digest를 고정한다.

## 8. 공급원 탐색과 우선순위

기본 후보:

```text
controlled actor inventory
assigned party supply container
assigned vehicle or mount storage
accessible camp storage
accessible campaign storage
```

Campaign Policy는 순서를 교체할 수 있다.

권위 분리:

```text
Slice 06 Inventory
→ Source membership·ACL·disclosure·revision

Slice 07 Frozen Campaign Policy
→ orderedSourceBindingIds·fallbackSourceKinds
→ sourceOrderDigest

둘을 결합
→ SupplyAllocationContext
```

Slice 06은 `SupplyAllocationContext`가 제공한 순위를 사용해 Candidate를 결정적으로 정렬한다. UI Drag 순서나 별도 `priority` 필드는 권위가 아니다.

후보 조건:

- 현재 Inventory Snapshot에서 접근 가능
- Supply Kind 호환
- Item Revision 유효
- 다른 Transaction에 Reservation되지 않음
- 보호 정책에서 자동 소비 허용
- 소유권·공유 규칙 허용
- 필요 시 소비자와 같은 Supply Group

기본 자동 소비 제외:

```text
quest_item
key_item
protected_stack
identified_as_dangerous
reserved
locked
private_unshared
consumption_disabled
```

DM은 Preview에서 명시적으로 포함할 수 있지만 Audit에 Override 이유를 남긴다.

## 9. Settlement Mode

```text
automatic
dm_confirm
manual_record_only
```

### automatic

Blocking Warning이 없으면 Time Advance Transaction과 함께 Commit한다.

### dm_confirm

Time Advance 전에 기간, Consumer별 요구량, 선택된 공급원, 소비 Stack, 예상 남은 일수, 부족량과 결과를 표시한다. DM은 `Confirm`, `Adjust Sources`, `Exclude Consumer`, `Cancel Time Advance`를 선택한다.

`Adjust Sources`가 지속 Policy 순서를 바꾸는 경우 즉시 Inventory priority를 수정하지 않는다. `ProposeSupplySourcePriorityChange`를 통해 Candidate Policy Snapshot을 만든다. 현재 Plan에만 적용되는 일회성 Override는 Plan Hash와 Mandatory Audit에 별도로 기록한다.

### manual_record_only

자동 차감과 결핍 Recipe 실행 없이 Ledger에 필요한 양과 DM의 수동 처리 결과만 기록한다.

## 10. Commit 흐름

```text
TimeAdvanceProposal
→ 다음 Scheduler·Logistics Boundary 계산
→ 해당 Checkpoint까지 Settlement Plan 작성
→ ItemInstance·Consumer·Effect Reservation
→ Policy에 따른 승인
→ Time + Inventory + Accumulator + Consequence Transaction
→ Domain Event·Projection·Ledger
```

Atomic Commit 대상:

- Campaign Game Time
- ItemInstance quantity 또는 consumed state
- Stack split·merge 결과
- LogisticsSettlementState
- Shortage Effect·RuleExecution 생성
- Audit Ledger

Commit 직전에 `policySnapshotRef`, `sourceOrderDigest`, Source Binding Revision을 모두 재검증한다.

Time Commit이 실패하면 Supply를 소비하지 않는다. Supply Reservation이 실패하면 Time Advance Plan을 재계산하거나 중단한다.

## 11. 여러 날 Advance

```text
+8일 요청
→ +1일 Supply Boundary
→ +3일 숨은 사건
→ +5일 Rest Quality Boundary
→ +8일 목표
```

각 Blocking Checkpoint까지 순차 처리한다. 3일째 사건이 여행을 중단하면 4–8일 소비를 확정하지 않는다.

반복 Settlement는 `settlementId + boundaryInstant + policySnapshotRef + sourceOrderDigest` 기반 Idempotency Key를 사용한다.

## 12. Shortage

```text
SupplyShortageRecord
├─ shortageId
├─ consumerRef
├─ supplyKind
├─ requiredUnits
├─ fulfilledUnits
├─ missingUnits
├─ interval
├─ ruleAnchor
├─ consequenceRecipeRef
├─ consequenceExecutionRef?
├─ disclosurePolicy
└─ revision
```

Client는 결핍 효과를 추론하지 않는다. 활성 Rule Content의 Recipe와 서버 RuleExecution이 결과를 만든다.

DM 선택:

- 다른 Supply Source 지정
- 수동 공급 기록
- 규칙상 면제 적용
- Shortage 수용
- Time Advance 취소
- 감사되는 Adjudication Override

## 13. Campaign 진행 중 Toggle

```text
Campaign Rule Change Proposal
→ Candidate Policy Snapshot
→ 현재 미정산 구간과 활성 Activity 영향 분석
→ 적용 경계 선택
→ Atomic Activation
```

기본 적용 경계:

```text
next_unsettled_boundary
next_time_advance
next_travel_or_rest_start
campaign_maintenance
```

Toggle Off:

- 미래 자동 Settlement 중지
- 누적 Ledger 보존
- 소비 Item 환불 없음
- 기존 Shortage Effect 자동 제거 없음

Toggle On:

- 다음 미정산 경계부터 시작
- 과거 구간 자동 소급 없음
- 선택적 Retroactive Reconcile은 별도 Preview·확인 필요

Supply Source 순서 변경:

- `ProposeSupplySourcePriorityChange`가 Candidate Snapshot과 새 `sourceOrderDigest`를 만든다.
- 이전 Digest를 참조하는 Pending Plan·Reservation은 `SETTLEMENT_PLAN_STALE`로 전환한다.
- 활성 Commit 중 Snapshot을 교체하지 않는다.
- Safe Boundary 활성화 후 Retry·Restart는 새 Snapshot으로 Allocation을 재생성한다.
- 이미 Commit된 Ledger의 Digest와 Allocation은 변경하지 않는다.

활성 Transaction이나 고정된 Travel·Rest Scope의 Snapshot을 중간 교체하지 않는다.

## 14. Projection과 UI

Player Projection:

- 공개된 활성 Module
- 자신과 공개 Party의 Supply Summary
- 현재 정책 기준 예상 보유 일수
- 다음 정산 시점
- 부족 경고와 허용된 Rule Link

DM Projection:

- 전체 Consumer와 Supply Source
- 숨은 NPC·Follower·Mount 요구량
- Policy Snapshot과 변경 영향
- Source Order Diff와 stale Plan
- 자동 제외 이유
- Shortage Consequence Preview
- Settlement Ledger와 Override Audit

`daysRemaining`은 현재 접근 가능한 Supply Units를 현재 Frozen Requirement Rate로 나눈 파생값이다. 미래 획득·상실·환경 변화를 보장하는 권위 예측이 아니다.

## 15. Domain Event

```text
logistics.settlement_planned
logistics.settlement_committed
logistics.settlement_cancelled
logistics.supply_consumed
logistics.shortage_recorded
logistics.policy_changed
logistics.reconciliation_committed
```

Event에는 `correlationId`, `policySnapshotRef`, `sourceOrderDigest`, `timeAdvanceTransactionId`, `authorityRevision`, `authorityEpoch`를 포함한다.

## 16. 실패 코드

```text
LOGISTICS_DISABLED
NO_ACTIVE_REQUIREMENT_DEFINITION
RULE_CONTENT_VERSION_MISMATCH
STALE_POLICY_SNAPSHOT
STALE_SOURCE_ORDER
STALE_INVENTORY_REVISION
SUPPLY_RESERVED
SUPPLY_SOURCE_INACCESSIBLE
PROTECTED_SUPPLY_REQUIRES_OVERRIDE
INSUFFICIENT_SUPPLY
SETTLEMENT_APPROVAL_REQUIRED
SETTLEMENT_PLAN_STALE
TIME_ADVANCE_INTERRUPTED
RETROACTIVE_RECONCILIATION_REQUIRED
```

## 17. Acceptance

- Engine에 Rule Profile별 일일 소비 수치가 하드코딩되지 않는다.
- 부분 날짜가 누락되거나 중복 소비되지 않는다.
- 여러 날 Advance가 중간 Schedule과 Settlement를 건너뛰지 않는다.
- 다중 Consumer와 여러 Container의 Allocation이 Stable 순서로 결정된다.
- Supply Source 순서의 유일한 권위는 Frozen Policy Snapshot이다.
- Pending Settlement 중 Source 순서 변경 시 기존 Plan·Reservation이 stale 처리된다.
- Safe Boundary 활성화 후 Retry·Restart가 동일 Snapshot에서 동일 Allocation을 재생성한다.
- 보호된 Item을 자동 소비하지 않는다.
- 같은 Settlement Retry가 Item을 두 번 소비하지 않는다.
- Toggle On·Off가 과거 State를 조용히 재작성하지 않는다.
- Rollback 후 Ledger·Item·Effect·Accumulator가 같은 Authority Epoch로 복원된다.
- 권한 없는 Player에게 숨은 Consumer·Container·수량이 노출되지 않는다.