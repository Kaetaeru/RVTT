# Slice 06 ADR-0092 Delta — Supply Metadata·Allocation·Reservation

- 상태: `ADDITIVE_DELTA_SPEC_COMPLETE`
- 문서 종류: Slice 06 Additive Contract
- 최종 갱신일: 2026-08-07
- 기존 통합 계약: [`implementation-contract.md`](implementation-contract.md)
- 상위 동기화 계획: [`ADR-0092-SLICE-SYNC-PLAN.md`](../../ADR-0092-SLICE-SYNC-PLAN.md)
- 상위 Product: [`Campaign Rules·Survival·Authored Actor Scope`](../../../product/campaign-rules-survival-and-authored-actor-scope.md)
- 직접 Runtime: [`Campaign Survival Logistics`](../../../architecture/campaign-survival-logistics-and-supply-settlement-runtime-contract.md)

이 Delta는 Slice 06의 Item·Container·Stack·Reservation 계약에 생존 보급용 데이터 기반을 추가한다. 하루 요구량, Campaign Time, 공급원 순서 Policy와 결핍 결과는 Slice 07과 Rule Content가 소유한다.

## 1. Slice 06 사용자 결과

DM과 Player가 보유한 Item 중 명시적으로 Supply로 정의된 항목만 보급 예측과 정산 후보가 된다.

```text
Item Definition의 Supply Metadata
→ ItemInstance·Stack Quantity
→ 접근 가능한 Container
→ 보호·예약·공개 Policy
→ Slice 07 Frozen Source Order Context
→ Allocation Candidate
→ Reservation
→ Slice 07 Settlement Commit
```

Item 이름, Thumbnail, Description과 외형만으로 음식·물을 추론하지 않는다.

## 2. 추가 범위

포함:

- Item Definition의 `SupplyMetadata`
- ItemInstance별 소비 보호·허용 Override
- Container의 Supply Source membership·ACL·공개 Policy
- Slice 07이 제공한 Frozen Source Order Context 적용
- 부분 Stack 소비 계획
- Settlement용 Item Reservation
- Allocation 결과의 결정적 정렬
- Item Quantity·Location Revision 재검증
- Retry·Restart·Rollback을 위한 Reservation·Consumption Marker

제외:

- 하루 요구량과 환경 배율 계산
- Campaign Time 진행
- Supply Source 순서 Policy와 Reorder 권위
- 결핍 Effect·Damage·Exhaustion 결정
- Campaign Rules UI
- Retroactive Reconcile 승인

## 3. Type Delta

```lua
export type SupplyMetadata = {
    supplyKind: string,
    unitsPerItem: number,
    unitDefinitionRef: string,
    consumptionPolicy: "automatic_allowed" | "confirm_required" | "manual_only" | "never",
    spoilageProfileRef: string?,
    ruleAnchorRef: string?,
}

export type SupplyProtectionState = {
    itemInstanceId: string,
    protectedFromAutomaticConsumption: boolean,
    protectionReason: string?,
    revision: number,
}

export type SupplySourceBinding = {
    sourceBindingId: string,
    sourceRef: string,
    sourceKind: "actor_inventory" | "party_container" | "vehicle_storage" | "camp_storage" | "campaign_storage",
    accessPolicyRef: string,
    disclosurePolicyRef: string,
    revision: number,
}

export type SupplyAllocationContext = {
    policySnapshotRef: string,
    sourceOrderDigest: string,
    orderedSourceBindingIds: {string},
}

export type SupplyAllocationCandidate = {
    itemInstanceId: string,
    sourceBindingId: string,
    locationBindingRevision: number,
    instanceRevision: number,
    quantityAvailable: number,
    supplyUnitsAvailable: number,
    resolvedSourceRank: number,
    sourceOrderDigest: string,
    stableSortKey: string,
}

export type SupplyItemReservation = {
    reservationId: string,
    settlementId: string,
    itemInstanceId: string,
    reservedQuantity: number,
    reservedUnits: number,
    expectedInstanceRevision: number,
    expectedLocationRevision: number,
    expectedSourceBindingRevision: number,
    expectedSourceOrderDigest: string,
    state: "reserved" | "committed" | "released" | "expired" | "invalidated",
    revision: number,
}
```

`unitsPerItem`과 `unitDefinitionRef`는 활성 Content Definition에서 온다. Client가 제출한 단위·수량을 권위 값으로 사용하지 않는다.

`SupplySourceBinding`은 membership·ACL·disclosure만 저장한다. 순서 숫자는 저장하지 않으며, `resolvedSourceRank`는 Slice 07 Frozen Policy Snapshot이 만든 `SupplyAllocationContext`에서만 온다.

## 4. 소비 후보 제외 규칙

다음은 기본 자동 Allocation 후보가 아니다.

- Quest·Key Item
- `consumptionPolicy = manual_only | never`
- 보호된 Stack
- 다른 Transaction·Activity·Cast에 예약된 Item
- 접근 권한이 없는 Container
- Player에게 비공개이며 현재 Settlement Scope에도 허용되지 않은 Source
- Identification 또는 안전 Policy가 자동 소비를 금지한 Item
- Supply Metadata가 없는 Item
- Spoilage·Condition 때문에 현재 유효하지 않은 Item

제외 사유는 DM Projection에 구조화해 제공하되 Player에게 Secret Source·Item Count를 누출하지 않는다.

## 5. 결정적 Allocation

기본 정렬 기준:

```text
Frozen Policy가 해석한 Source Rank
→ Consumption Policy
→ Spoilage·Use-by Policy
→ Stack 분할 최소화
→ Item Definition Stable ID
→ ItemInstance ID
```

Lua Table 순서, Workspace 자식 순서, UI Drag 순서와 Client 응답 도착 순서를 사용하지 않는다.

같은 Inventory Snapshot과 같은 `policySnapshotRef + sourceOrderDigest`는 같은 Allocation Plan을 생성해야 한다. Source membership이나 ACL revision이 바뀌면 Candidate Query를 다시 수행한다. Source 순서 변경은 Slice 06 명령으로 직접 적용하지 않는다.

## 6. Reservation과 Commit 경계

```text
Slice 07 Requirement Plan + Frozen Source Order Context
→ Slice 06 Candidate Query
→ Allocation Plan
→ Item·Location·Source Binding Revision 확인
→ SupplyItemReservation 생성
→ Slice 07 Time·Shortage Plan과 함께 Commit
```

성공 Commit:

- Item Quantity 감소 또는 Stack 제거
- Location Binding 유지·변경
- Reservation `committed`
- Consumption Marker와 Domain Event 기록

실패:

- Time Advance와 Item 소비를 모두 Commit하지 않는다.
- 유효한 기존 Item·Location을 유지한다.
- Reservation을 Release 또는 Invalidated 상태로 전환한다.
- 같은 Settlement ID의 Retry가 이미 Commit된 소비를 반복하지 않는다.
- `sourceOrderDigest`가 바뀐 Pending Reservation은 stale 처리하고 새 Policy Snapshot으로 다시 계획한다.

## 7. Command·Query Delta

추가 Command 또는 Domain API 후보:

- `SetSupplyProtection`
- `RegisterSupplySource`
- `UpdateSupplySourceAccessPolicy`
- `UnregisterSupplySource`
- `ReserveSupplyItems`
- `ReleaseSupplyReservation`
- `CommitSupplyConsumption`

읽기 API 후보:

- `QueryAccessibleSupplySources`
- `QuerySupplyAllocationCandidates`
- `BuildSupplyAllocationPlan`
- `GetSupplyReservationStatus`

`ReorderSupplySources`는 Slice 06 Command가 아니다. Source 순서 변경은 Slice 07의 `ProposeSupplySourcePriorityChange`를 사용해 Candidate Frozen Policy Snapshot을 생성한다.

Slice 07이 Item Store를 직접 읽거나 수정하지 않고 이 경계를 사용한다.

## 8. Projection

Player Supply Summary는 현재 Viewer에게 공개 가능한 Source만 사용한다.

```text
Authority Inventory·Container State
+ Viewer Context
+ Active Policy Snapshot
→ Supply Summary Projection
```

Player에게 보내지 않는 정보:

- Hidden Follower의 존재와 소비량
- 비공개 Container 이름·Item Count
- 다른 Player의 Private Inventory 상세
- DM 전용 보호 이유와 Source 순서 상세

DM은 전체 권위 View를 볼 수 있지만 Mandatory Audit와 Disclosure Policy를 우회하지 않는다.

## 9. Persistence·Rollback

추가 저장 대상:

- Supply Metadata Definition Version Ref
- Supply Protection State
- Supply Source Binding membership·ACL·Disclosure Revision
- 활성 Reservation과 Settlement Ref
- Reservation이 고정한 `policySnapshotRef + sourceOrderDigest`
- Consumption Marker·Item Revision

Supply Source 순서 자체는 Slice 07 Campaign Policy Snapshot에 저장한다.

Rollback은 Item Quantity·Location·Protection·Source Binding·Reservation·Consumption Marker를 같은 AuthorityEpoch Branch로 복원한다. 이전 Epoch의 Reservation Commit과 Retry를 거부한다.

## 10. 실패 코드

```text
SUPPLY_METADATA_MISSING
SUPPLY_ITEM_PROTECTED
SUPPLY_ITEM_RESERVED
SUPPLY_SOURCE_ACCESS_DENIED
SUPPLY_SOURCE_REVISION_STALE
SUPPLY_SOURCE_ORDER_STALE
SUPPLY_ITEM_REVISION_STALE
SUPPLY_ALLOCATION_INSUFFICIENT
SUPPLY_RESERVATION_CONFLICT
SUPPLY_RESERVATION_EXPIRED
SUPPLY_SETTLEMENT_ALREADY_COMMITTED
```

## 11. Test Delta

1. Supply Metadata가 없는 Item이 자동 후보에서 제외된다.
2. Quest·Protected·Reserved Item이 소비되지 않는다.
3. 동일 Inventory Snapshot과 동일 Source Order Context에서 Allocation 순서가 결정적이다.
4. 서로 다른 Source Order Digest가 다른 Allocation Plan Hash를 만든다.
5. 부분 Stack 소비 후 전체 수량이 보존된다.
6. 두 Settlement의 동일 Stack 예약은 한쪽만 성공한다.
7. Reservation 이후 Item 이동·수량·Source Binding 변경 시 Commit이 거부된다.
8. Pending Reservation 이후 Source Order Digest가 바뀌면 stale 처리된다.
9. Commit 직후 Retry가 중복 소비하지 않는다.
10. Restart 후 Reservation·Consumption Marker와 고정 Source Order Digest가 복원된다.
11. Rollback 이전 Epoch Commit이 거부된다.
12. Hidden Container·Follower Count가 Player Summary·Error에 없다.
13. 대량 Container에서 Allocation Query Budget을 측정한다.

## 12. 본 계약 흡수 Gate

다음이 확인되면 이 Delta를 `implementation-contract.md`와 Script Manifest로 흡수한다.

- 실제 Item Definition·Instance·Location Schema Mapping
- Container ACL·Projection API Mapping
- Reservation Coordinator Mapping
- Slice 07 Requirement·Settlement·Source Priority Policy API 확정
- Supply Metadata Content Version과 Migration 경로

현재 Delta 완료는 Production Runtime 구현 또는 Roblox Studio PASS가 아니다.