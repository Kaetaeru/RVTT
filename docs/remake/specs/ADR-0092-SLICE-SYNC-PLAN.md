# ADR-0092 Slice 동기화 계획

- 상태: ACTIVE · PHASED_SYNC
- 문서 종류: Cross-Slice Delta Plan
- 최종 갱신일: 2026-08-06
- 상위 Product: [`Campaign Rules·Survival·Authored Actor Scope`](../product/campaign-rules-survival-and-authored-actor-scope.md)
- 상위 결정: [`ADR-0092`](../decisions/ADR-0092-campaign-survival-logistics-and-dm-authored-actor-tokens.md)
- 전체 Roadmap: [`SLICE-ROADMAP.md`](SLICE-ROADMAP.md)

## 1. 목적

ADR-0092의 생존·보급과 DM 저작 Actor 기능을 기존 16개 Slice에 단계적으로 연결한다.

기존 Slice 번호와 주 사용자 결과를 바꾸지 않는다. 새 기능 전체를 Slice 01이나 하나의 후반 Slice에 몰아 넣지 않고, 데이터 원본과 Runtime 의존성 순서대로 흡수한다.

```text
기존 16 Slice Baseline
+ ADR-0092 Additive Delta
→ Slice별 Delta 문서
→ 구현 직전 실제 Source Mapping
→ 본 Integration Contract에 흡수
→ Slice Acceptance 확장
```

## 2. 동기화 원칙

1. 현재 UI·UX 정합화와 Slice 01 Runtime 재검증을 중단하지 않는다.
2. 아직 선행 Runtime이 없는 기능은 Production Queue에 바로 넣지 않는다.
3. Slice별 Delta는 해당 Slice가 소유할 데이터·Command·Acceptance만 추가한다.
4. 정확한 공식 소비 수치와 Stat Block은 Content Pack이 소유한다.
5. Slice 11의 DM UI가 Inventory·Time·Content Authority를 직접 수정하지 않는다.
6. Slice 15의 Actor 저작이 임의 Code·Remote·URL 실행 경로가 되지 않는다.
7. Slice 16 전에는 문서·HTML·Schema PASS를 Runtime PASS로 해석하지 않는다.

## 3. 단계와 책임

### Phase 0 — 상위 기획 연결

상태: `DONE`

- Product Scope에 Campaign Rule Profile과 DM 저작 Actor를 추가한다.
- 현재 Work Order와 Slice Roadmap에 순차 구현 원칙을 추가한다.
- ADR·Architecture·Product·Spec·User Guide 권위 방향을 연결한다.

### Phase 1 — Slice 06 Inventory 기반

상태: `DELTA_SPEC_ADDED`

소유 책임:

- `SupplyMetadata`가 있는 Item Definition·Build
- `supplyKind`, `supplyUnits`, `consumptionPolicy`
- Protected·Reserved·Quest·Private Container 제외
- 부분 Stack 계획과 결정적 Allocation 후보
- Supply Settlement용 Item Reservation·Revision
- 소비 Commit의 ItemInstance·Location·Quantity 원자성

비소유 책임:

- 하루 요구량 계산
- Campaign Time 진행
- 결핍 Effect 결정
- DM Campaign Rules UI

세부 Delta: [`Slice 06 ADR-0092 Delta`](slices/06-inventory-equipment-world-items/ADR-0092-DELTA.md)

### Phase 2 — Slice 07 Time·Policy·Settlement

상태: `DELTA_SPEC_ADDED`

소유 책임:

- Narrative·Standard·Survival·Custom Campaign Policy Binding
- Logistics Boundary와 부분 날짜 Accumulator
- Consumer Requirement·Allocation Plan 결합
- Time·Inventory·Shortage Atomic Settlement
- 중간 사건·Scheduler Due·Supply Boundary Checkpoint
- Settlement Ledger·Idempotency·Restart·Rollback
- Mid-campaign Candidate Snapshot·Safe Boundary·Non-retroactive Activation

비소유 책임:

- Item Definition·Location 원본
- DM Window Layout
- Actor Model·Stat Block Publish

세부 Delta: [`Slice 07 ADR-0092 Delta`](slices/07-rest-time-downtime-progression/ADR-0092-DELTA.md)

### Phase 3 — Slice 11 Live DM 도구

상태: `QUEUED_AFTER_PHASE_2_SOURCE_MAPPING`

소유 책임:

- Campaign Rules Window
- Current·Candidate Snapshot Diff
- Time Advance Supply Preview와 Source 조정
- Supply Ledger·Shortage Review
- Retroactive Reconcile의 Preview·Confirm·Mandatory Audit
- Player Audience Preview와 Hidden Consumer Negative Disclosure

착수 Gate:

- Slice 06 Supply Projection API
- Slice 07 Settlement Proposal·Ledger API
- UI·UX 정합화 Gate 완료

### Phase 4 — Slice 12 Content Platform

상태: `QUEUED_AFTER_PHASE_1_2_CONTRACT_TEST`

소유 책임:

- Consumption Requirement·Supply Unit·Shortage Recipe Definition
- Stable Rule Anchor와 Source Rights
- Actor Stat Block Schema Version
- Trusted Recipe Catalog Projection
- Actor Model Catalog Projection 계약
- Campaign-authored Data Trust Class와 Publish Package Version

착수 Gate:

- Policy Registry·Frozen Snapshot 실제 Mapping
- Content Package·Registry·Rights Pipeline Mapping

### Phase 5 — Slice 15 Actor·Token Authoring

상태: `QUEUED_AFTER_PHASE_4_REGISTRY`

소유 책임:

- Actor Model Registry Import·Validation
- Strict Stat Block JSON Parse·Schema·Reference Validation
- AI Prompt Builder용 전체 보이는 Model Catalog Export
- ActorModel·StatBlock·TokenPrefab·ActorTemplate 분리
- Campaign-local Draft·Publish
- SceneNpc Spawn·Template Version Migration
- Script·Remote·URL·미등록 Recipe 거부

착수 Gate:

- Slice 12 Catalog·Schema·Rights·Trusted Recipe Registry
- 실제 Actor Model Asset Pipeline
- SceneNpc·Runtime Object·Prefab Source Mapping

### Phase 6 — Slice 16 통합·Release

상태: `QUEUED_AFTER_PHASE_1_TO_5_RUNTIME`

추가 Release Scenario:

1. Narrative Campaign에서 Time Advance가 Supply를 소비하지 않는다.
2. Survival Campaign의 3일 진행이 일별 Boundary와 중간 사건을 보존한다.
3. Item Reservation 충돌·Retry·Restart가 중복 소비를 만들지 않는다.
4. Toggle On·Off가 과거 Item·Effect를 소급 변경하지 않는다.
5. Hidden Follower·Container가 Player Projection과 Error에 노출되지 않는다.
6. 빈 Model Catalog Prompt가 `models: []`를 포함한다.
7. 미등록 Model·Recipe·Script Field가 Import Blocker가 된다.
8. Campaign Draft→Publish→SceneNpc Spawn→Reconnect가 exact Version을 복원한다.
9. Template Migration 실패가 기존 NPC와 Last Known Good를 유지한다.
10. 장시간 Session에서 Ledger·Catalog·Preview Memory·Payload Budget을 측정한다.

## 4. 직접 변경하지 않는 Slice

다음 Slice는 ADR-0092 기능을 직접 소유하지 않지만, 기존 공통 계약을 재사용한다.

| Slice | 관계 |
|---:|---|
| 01 | Campaign·Session ID, Authority Epoch, Projection·Persistence 기반 제공. 생존 기능 구현 없음 |
| 02 | Shortage Consequence와 Actor Capability 실행 Kernel 제공 |
| 03 | Travel·Exploration Hazard가 Time Advance 중간 사건을 만들 수 있음 |
| 04 | Encounter 진입이 Time Advance를 중단하며 Day Settlement를 Turn마다 실행하지 않음 |
| 05 | Character·Follower·Mount Consumer Binding의 원본 제공 |
| 08 | Player·DM Projection과 접근성 표현 재사용 |
| 09 | Ledger·Actor·Rule Anchor Journal Link 가능 |
| 10 | Scene Actor Placement와 Model Asset Authoring 경계 연결 |
| 13 | Character Option이 Consumption Modifier를 제공할 수 있으나 Engine 수치 하드코딩 금지 |
| 14 | Item Supply Metadata와 공식 Rule Content를 Content Pack으로 제공 |

이 Slice들의 기존 Acceptance를 지금 확장하지 않는다. 직접 의존 API가 구현되는 단계에서 필요한 최소 Delta만 별도 추가한다.

## 5. Production 순서 보호

현재 Production 우선순위:

```text
Full UI·UX Source 정합화
→ Static Gate
→ 기존 Exploration·Context Input Studio Retest
→ Role·Recovery·Accessibility Evidence
```

ADR-0092는 이 작업을 선점하지 않는다.

후속 Production 순서:

```text
Slice 06 Supply Metadata·Reservation
→ Slice 07 Policy·Settlement·Ledger
→ Slice 11 DM Rules·Preview Tool
→ Slice 12 Rule·Schema·Catalog Content Platform
→ Slice 15 Model·Stat Block·Template Pipeline
→ Slice 16 Integration Evidence
```

각 단계는 이전 단계의 Source Mapping·Static Test·Authority Test가 통과한 뒤에만 다음 단계로 넘어간다.

## 6. 완료 판정

문서 동기화 완료:

- Product Scope와 Roadmap 연결
- Slice 06·07 Delta 작성
- 후속 Slice 책임·Gate 고정
- Audit와 Work Order 연결

Production 동기화 완료:

- 각 Delta가 실제 Integration Contract·Script Manifest·Source·Test에 흡수됨
- GitHub Static Gate 통과
- Roblox Studio 다중 Client Evidence 확보
- Slice 16 Release Scenario와 Runbook 검증

현재 판정:

```text
Upper Planning Sync
→ COMPLETE

Slice 06·07 Delta Spec
→ COMPLETE

Slice 11·12·15·16 Contract Absorption
→ QUEUED

Production Runtime
→ NOT IMPLEMENTED BY THIS PLAN
```
