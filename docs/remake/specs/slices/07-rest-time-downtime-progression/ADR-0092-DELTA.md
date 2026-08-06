# Slice 07 ADR-0092 Delta — Campaign Policy·Supply Settlement·Ledger

- 상태: `ADDITIVE_DELTA_SPEC_COMPLETE`
- 문서 종류: Slice 07 Additive Contract
- 최종 갱신일: 2026-08-06
- 기존 통합 계약: [`implementation-contract.md`](implementation-contract.md)
- 상위 동기화 계획: [`ADR-0092-SLICE-SYNC-PLAN.md`](../../ADR-0092-SLICE-SYNC-PLAN.md)
- Slice 06 선행 Delta: [`Supply Metadata·Allocation·Reservation`](../06-inventory-equipment-world-items/ADR-0092-DELTA.md)
- 직접 Runtime: [`Campaign Survival Logistics`](../../../architecture/campaign-survival-logistics-and-supply-settlement-runtime-contract.md)

이 Delta는 Slice 07의 Campaign Time·Scheduler·Travel·Rest·Downtime 경계에 Campaign Survival Policy와 Supply Settlement를 연결한다.

## 1. Slice 07 사용자 결과

DM이 수일 여행·휴식·다운타임 또는 명시적 시간 진행을 요청하면 활성 Campaign Rule Profile에 따라 보급 요구량과 부족 결과를 미리 확인하고 안전하게 확정한다.

```text
Time Advance Proposal
→ Frozen Campaign Policy
→ Logistics Boundary
→ Consumer Requirement
→ Slice 06 Allocation·Reservation
→ Supply Settlement Preview
→ DM Confirm 또는 Policy Approval
→ Time·Inventory·Shortage Atomic Commit
→ Ledger·Projection
```

## 2. 추가 범위

포함:

- Narrative·Standard·Survival·Custom Preset Binding
- Food·Water·Mount Feed Module
- Exposure·Encumbrance·Ammunition·Rest Quality·Spoilage 확장 Binding
- Consumption Requirement Definition 해결
- 부분 날짜·식사·휴식 Boundary Accumulator
- Character·Follower·Mount Consumer Scope
- Supply Allocation Plan 결합
- Shortage Consequence Candidate
- Time·Inventory·Effect 결과의 Atomic Settlement
- Supply Ledger·Idempotency·Recovery
- Mid-campaign Candidate Snapshot과 Safe Boundary Activation
- Retroactive Reconcile의 권위 Proposal 경계

제외:

- Item Definition·Location·Stack Store 소유
- Campaign Rules Window Layout
- Actor Model Registry·Stat Block Authoring
- 규칙 팩에 없는 공식 수치 창작

## 3. Policy Type Delta

```lua
export type CampaignSurvivalProfile = {
    profileId: "narrative" | "standard" | "survival" | "custom",
    policySnapshotRef: string,
    moduleBindings: {[string]: string},
    activationRevision: number,
}

export type LogisticsBoundary = {
    boundaryId: string,
    startInstant: number,
    endInstant: number,
    boundaryKind: "day" | "meal" | "rest" | "travel_segment" | "custom_registered",
    accumulatorStateRef: string?,
    policySnapshotRef: string,
}

export type SupplyConsumerBinding = {
    consumerRef: string,
    consumerKind: "character" | "follower" | "mount" | "vehicle_crew" | "custom_registered",
    requirementProfileRef: string,
    visibilityPolicyRef: string,
    activeIntervalRef: string,
    revision: number,
}

export type SupplyRequirementLine = {
    consumerRef: string,
    supplyKind: string,
    requiredUnits: number,
    ruleDefinitionRef: string,
    ruleAnchorRef: string?,
    requirementDigest: string,
}

export type SupplySettlementPlan = {
    settlementId: string,
    campaignId: string,
    boundaryRefs: {string},
    policySnapshotRef: string,
    requirementLines: {SupplyRequirementLine},
    allocationPlanRef: string,
    reservationRefs: {string},
    shortagePlanRef: string?,
    planDigest: string,
    state: "proposed" | "awaiting_confirmation" | "reserved" | "committing" | "committed" | "cancelled" | "failed",
    revision: number,
}

export type SupplyLedgerEntry = {
    ledgerEntryId: string,
    settlementId: string,
    boundaryRef: string,
    policySnapshotRef: string,
    consumedItemRefs: {string},
    shortageOutcomeRefs: {string},
    authorityRevision: number,
    disclosurePolicyRef: string,
}
```

## 4. Preset 의미

```text
Narrative
→ 자동 Requirement·Consumption 없음
→ 수동 Ledger 기록 가능

Standard
→ Requirement·Shortage Preview
→ 기본 DM 확인 후 Settlement

Survival
→ 활성 Ruleset의 허용 Policy에 따라 자동 승인 가능
→ Blocking Shortage·Hazard가 있으면 Checkpoint 중단

Custom
→ Module별 Policy Binding
```

Preset 문자열 자체를 Gameplay 분기로 하드코딩하지 않는다. Frozen Policy Snapshot의 Family Binding을 해결한다.

## 5. Requirement 해결

```text
Consumer Binding
+ Boundary Duration
+ Environment·Activity Context
+ Ruleset·Source Pack Definition
+ Character·Item·Effect Contribution
→ Supply Requirement Lines
```

규칙:

- 정확한 소비량은 Versioned Definition에서 온다.
- 같은 Snapshot과 Context Digest는 같은 Requirement를 만든다.
- Definition이 없거나 Conflict가 해결되지 않으면 자동 Fallback 수치를 만들지 않는다.
- Hidden Consumer는 Authority 계산에 포함될 수 있지만 권한 없는 Player Projection에는 공개하지 않는다.
- Encounter Turn마다 하루 소비를 실행하지 않는다.

## 6. 부분 날짜와 Boundary

Time Advance는 하루 단위로만 제한하지 않는다.

```text
부분 시간 진행
→ Accumulator 누적
→ Requirement Definition이 정한 Boundary 도달
→ Settlement Candidate
```

여러 날 진행:

```text
현재 Instant
→ 다음 Scheduler Due
→ 다음 Hazard·Encounter
→ 다음 Supply Boundary
→ 가장 이른 Checkpoint까지만 Advance·Settlement
→ 상태 재검증
→ 남은 기간 재계획
```

8일 여행 요청 중 3일째 사건이 있으면 3일째 이전 Boundary까지만 Commit한다.

## 7. Atomic Settlement

하나의 Settlement Transaction은 최소 다음을 함께 검증한다.

- Campaign Time Revision
- Policy Snapshot Ref와 Activation Revision
- Consumer Binding Revision
- Requirement Plan Digest
- Slice 06 Item·Location Revision과 Reservation
- Shortage Consequence Recipe Version
- Authority Epoch와 Idempotency Key

성공:

```text
Campaign Time Advance
+ Item Quantity·Location Commit
+ Shortage Outcome Commit
+ Ledger Entry
+ Domain Event·Projection Barrier
```

실패 시 일부만 적용하지 않는다. Item Reservation을 정리하고 Campaign Time을 기존 Commit Point에 유지한다.

## 8. Shortage 결과

부족량 자체가 Effect Store를 직접 수정하지 않는다.

```text
Shortage Line
→ Registered Consequence Recipe
→ RuleExecution·Roll·Choice·DM Adjudication
→ Pending Effect·Transaction
```

- Recipe는 Ruleset Content Version을 고정한다.
- 불확실한 결과는 DM 승인 또는 Guided·Assisted 흐름을 사용한다.
- 기능을 끄더라도 이미 Commit된 결핍 Effect를 자동 제거하지 않는다.

## 9. Campaign 진행 중 변경

```text
Policy Change Proposal
→ Candidate Snapshot Compile
→ Requirement·Projection·Active Activity Impact Diff
→ Activation Boundary 선택
→ Atomic Activation
```

기본 변경 등급:

```text
새 Settlement부터 적용
현재 Time Advance 종료 후 적용
현재 Travel·Rest·Downtime 종료 후 적용
Campaign Maintenance 필요
```

기본은 비소급이다.

- 과거 Item 소비 환불 없음
- 과거 미소비 기간 자동 차감 없음
- 기존 Ledger 변경 없음
- 기존 결핍 Effect 자동 삭제 없음

## 10. Retroactive Reconcile 경계

Retroactive Reconcile은 일반 Toggle의 부작용이 아니다.

```text
기간·Policy Snapshot 선택
→ Historical Requirement 재생성
→ Item·Effect·Ledger Diff
→ 충돌·누락·권리·Version 검증
→ DM Preview·Confirm·Mandatory Audit
→ 별도 Reconcile Transaction
```

원본 Version을 찾지 못하거나 현재 Inventory와 충돌하면 자동 실행하지 않는다.

## 11. Command Delta

- `ProposeCampaignSurvivalProfileChange`
- `ActivateCampaignPolicySnapshot`
- `ProposeSupplySettlement`
- `ConfirmSupplySettlement`
- `CancelSupplySettlement`
- `ResolveSupplyShortage`
- `RequestRetroactiveSupplyReconcile`
- `ConfirmRetroactiveSupplyReconcile`

Time Advance Command는 필요할 때 Settlement Plan Ref를 요구한다. Client가 소비 결과와 Shortage 결과를 직접 제출하지 않는다.

## 12. Projection

Player:

- 자신에게 공개된 현재 Profile 요약
- 자신의 또는 공개 Party Supply 예상 일수
- 공개 가능한 부족 경고
- Time Advance 확인과 결과

DM:

- 전체 Consumer·Source·Requirement·Reservation
- Candidate Snapshot Diff
- Hidden Shortage·Environment Modifier
- Ledger·Reconcile·Audit

Observer:

- 공개된 시간·여행 진행과 Campaign Rule 요약만 제공

Count, Error, Tooltip, Loading 상태에서도 Hidden Consumer·Storage를 누출하지 않는다.

## 13. Persistence·Recovery·Rollback

저장:

- 활성 Campaign Survival Profile과 Frozen Snapshot Ref
- Boundary Accumulator
- Consumer Binding
- Pending·Committed Settlement
- Requirement·Allocation·Shortage Plan Digest
- Ledger Entry·Idempotency Marker
- Policy Change·Reconcile Record

Restart:

- Pending Reservation 상태 재검증
- 이미 Commit된 Settlement 중복 실행 차단
- Due Boundary와 Time Advance Plan 재구성

Rollback:

- Time·Inventory·Effect·Ledger·Policy Snapshot을 같은 Branch로 복원
- 이전 Epoch Settlement·Confirm·Reconcile 응답 거부

## 14. 실패 코드

```text
SURVIVAL_POLICY_CONFLICT
SURVIVAL_POLICY_MIGRATION_REQUIRED
SUPPLY_REQUIREMENT_DEFINITION_MISSING
SUPPLY_REQUIREMENT_VERSION_MISSING
SUPPLY_BOUNDARY_STALE
SUPPLY_CONSUMER_STALE
SUPPLY_ALLOCATION_STALE
SUPPLY_SETTLEMENT_CONFLICT
SUPPLY_SETTLEMENT_ALREADY_COMMITTED
SUPPLY_SHORTAGE_REQUIRES_ADJUDICATION
RETROACTIVE_RECONCILE_CONFLICT
```

## 15. Test Delta

1. Narrative Profile에서 Time Advance가 Supply를 소비하지 않는다.
2. Standard Profile이 DM 확인 전 Item·Time을 변경하지 않는다.
3. Survival Profile이 Versioned Requirement를 사용한다.
4. 부분 날짜 Accumulator가 Boundary 전 소비하지 않는다.
5. 3일 진행이 일별 Settlement와 중간 사건을 보존한다.
6. Item Reservation 실패 시 Time이 진행되지 않는다.
7. Shortage Recipe 실패 시 부분 Commit이 없다.
8. 같은 Settlement Retry가 중복 소비·Ledger를 만들지 않는다.
9. Toggle Off가 과거 소비·Effect·Ledger를 변경하지 않는다.
10. Toggle On이 과거 기간을 자동 정산하지 않는다.
11. Reconcile은 Preview·Confirm·Audit 전 Store를 변경하지 않는다.
12. Hidden Follower·Container가 Player Projection·Error에 없다.
13. Restart·Rollback 후 exact Policy·Settlement 상태 복원.
14. 대규모 Consumer·Source·다일 Advance Budget 측정.

## 16. 본 계약 흡수 Gate

다음이 확인되면 이 Delta를 `implementation-contract.md`와 Script Manifest로 흡수한다.

- 실제 Campaign Time·Scheduler·Policy Snapshot Mapping
- Slice 06 Supply Query·Reservation API
- Rule Profile Consumption Definition·Shortage Recipe Mapping
- Effect·RuleExecution Integration
- Ledger·Projection·Persistence Schema
- Slice 11 DM Preview API 경계

현재 Delta 완료는 Production Runtime 구현 또는 Roblox Studio PASS가 아니다.
