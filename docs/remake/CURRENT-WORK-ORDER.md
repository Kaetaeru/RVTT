# RVTT Remake 현재 작업 순서

- 상태: `ACTIVE · FULL_UI_ALIGNMENT_WITH_ADR_0092_PHASED_SYNC`
- 최종 갱신일: 2026-08-06
- 최신 결정: [`ADR-0092`](decisions/ADR-0092-campaign-survival-logistics-and-dm-authored-actor-tokens.md)
- Product Scope: [`Campaign Rules·Survival·Authored Actor`](product/campaign-rules-survival-and-authored-actor-scope.md)
- Survival Runtime: [`campaign-survival-logistics-and-supply-settlement-runtime-contract.md`](architecture/campaign-survival-logistics-and-supply-settlement-runtime-contract.md)
- Actor Token Runtime: [`dm-authored-actor-token-and-statblock-import-runtime-contract.md`](architecture/dm-authored-actor-token-and-statblock-import-runtime-contract.md)
- Slice Sync: [`ADR-0092-SLICE-SYNC-PLAN.md`](specs/ADR-0092-SLICE-SYNC-PLAN.md)
- DM Guide: [`CAMPAIGN-SURVIVAL-AND-ACTOR-TOKEN-AUTHORING.md`](user-guides/dm/CAMPAIGN-SURVIVAL-AND-ACTOR-TOKEN-AUTHORING.md)
- Supplemental HTML: [`survival-and-token-authoring.html`](user-guides/html/survival-and-token-authoring.html)

## 현재 단계

```text
ADR-0088 Direct Play
→ ACCEPTED

ADR-0089 Observer-first Surface
→ ACCEPTED

ADR-0090 Console Matrix·DM Windows
→ ACCEPTED

ADR-0091 Asset·Official Sheet·Dice·Core Rules
→ ACCEPTED

ADR-0092 Survival Logistics·DM Actor Token Authoring
→ ACCEPTED · PHASED SLICE SYNC

High-Fidelity HTML
→ BASE 33 + SUPPLEMENTAL 6 SCREENS
```

## 실행 Lane A — 현재 Production 우선순위

ADR-0092가 현재 진행 중인 UI·UX 정합화와 기존 Runtime 재검증을 선점하지 않는다.

```text
Full UI·UX Source·Acceptance 정합화
→ Structure·Security·Formatter·Lint·Rojo·Luau Gate
→ Exploration·Context Input Studio Retest
→ Player·DM·Observer Role·Recovery Test
→ UI·Accessibility·Performance Evidence
→ Grand Persistence Runtime
```

실제 Script 순서는 [`implementation/roblox/CURRENT-WORK-ORDER.md`](../../implementation/roblox/CURRENT-WORK-ORDER.md)가 소유한다.

## 실행 Lane B — ADR-0092 단계적 동기화

### 완료

1. Product Authority 연결
2. Architecture·User Guide·HTML·Schema·Prompt 계약
3. 16-Slice Roadmap 책임 분배
4. Slice 06 Supply Metadata·Allocation·Reservation Delta
5. Slice 07 Campaign Policy·Settlement·Ledger Delta

### 다음 순서

```text
현재 UI·UX Gate 완료
→ Slice 06 실제 Source Mapping
→ Supply Metadata·Protection·Source·Reservation 구현
→ Slice 07 Time·Policy·Settlement·Ledger 구현
→ Slice 11 Campaign Rules·Preview·Reconcile DM Tool
→ Slice 12 Requirement·Schema·Catalog Content Platform
→ Slice 15 Model Registry·Stat Block·Template Pipeline
→ Slice 16 Full-session Evidence
```

후속 Slice의 Contract는 선행 Source와 API가 확인된 시점에 하나씩 흡수한다. 11·12·15·16을 지금 동시에 구현 Queue로 올리지 않는다.

## ADR-0092 첫 Production Gate

### Slice 06

- Versioned Supply Metadata
- Quest·Protected·Reserved·Private Item 제외
- 결정적 부분 Stack Allocation
- Item·Location Revision 기반 Reservation
- Retry·Restart·Rollback 중복 소비 방지

### Slice 07

- Narrative·Standard·Survival·Custom Candidate Snapshot
- Toggle On·Off 비소급 동작
- 3일 Advance의 일별 Supply Checkpoint
- Time·Inventory·Shortage Atomic Commit
- Hidden Consumer·Container 미노출
- Ledger·Idempotency·Recovery

### 후속 Actor Pipeline

- 빈 Actor Model Catalog Prompt 생성
- Catalog에 없는 Model ID Validation 거부
- Script·Remote·미등록 Recipe Import 거부
- Campaign Draft→Publish→SceneNpc Spawn·Migration

## 판정 경계

```text
Upper Product·Roadmap Sync
→ COMPLETE

Slice 06·07 Delta Spec
→ COMPLETE

Slice 11·12·15·16 Contract Absorption
→ QUEUED

ADR-0092 Production Runtime
→ NOT IMPLEMENTED

Roblox Studio Evidence
→ NOT PRODUCED BY THIS DOCUMENT SYNC
```

문서·HTML·Schema·GitHub Static PASS는 Roblox Runtime PASS가 아니다.
