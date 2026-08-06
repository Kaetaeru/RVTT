# ADR-0092 단계적 Production 계획

- 상태: `QUEUED_AFTER_CURRENT_UI_ALIGNMENT`
- 문서 종류: Production Lane Plan
- 최종 갱신일: 2026-08-06
- 상위 Work Order: [`CURRENT-WORK-ORDER.md`](CURRENT-WORK-ORDER.md)
- Slice Sync: [`docs/remake/specs/ADR-0092-SLICE-SYNC-PLAN.md`](../../docs/remake/specs/ADR-0092-SLICE-SYNC-PLAN.md)
- Product Scope: [`Campaign Rules·Survival·Authored Actor`](../../docs/remake/product/campaign-rules-survival-and-authored-actor-scope.md)

## 1. 실행 원칙

ADR-0092는 현재 Full UI·UX Source·Acceptance 정합화를 중단시키지 않는다.

```text
현재 Lane
Full UI·UX Alignment
→ Static Gate
→ Studio Retest
→ Role·Recovery·Accessibility Evidence

후속 Lane
Slice 06 Supply Foundation
→ Slice 07 Settlement
→ Slice 11 DM Tool
→ Slice 12 Content Registry
→ Slice 15 Actor Pipeline
→ Slice 16 Integration Evidence
```

동시에 전체 Framework의 빈 Script를 생성하지 않는다. 각 Phase에서 실제 Package·Schema·Test Mapping을 먼저 확정한다.

## 2. Phase P1 — Slice 06 Supply Foundation

착수 Gate:

- Current UI Alignment Static Gate 완료
- Item Definition·Instance·Location 실제 Source Mapping
- Container ACL·Projection API 확인
- Reservation Coordinator 확인

Production 범위:

- Versioned `SupplyMetadata`
- Item Protection·Consumption Policy
- Supply Source Binding과 우선순위
- 결정적 Allocation Query
- 부분 Stack Reservation
- Restart·Rollback Marker

Acceptance:

- Metadata 없는 Item 자동 제외
- Quest·Protected·Reserved Item 미소비
- 동일 Snapshot 결정성
- Reservation Conflict 단일 승자
- Retry 중복 소비 없음
- Hidden Container Negative Disclosure

## 3. Phase P2 — Slice 07 Policy·Settlement

착수 Gate:

- P1 Authority·Persistence·Projection Test 통과
- Campaign Time·Scheduler 실제 Source Mapping
- Frozen Policy Snapshot Mapping
- Consumption Requirement·Shortage Recipe Fixture

Production 범위:

- Narrative·Standard·Survival·Custom Binding
- Logistics Boundary·부분 날짜 Accumulator
- Consumer Requirement Plan
- Time·Inventory·Shortage Atomic Settlement
- Ledger·Idempotency
- Candidate Snapshot·Safe Boundary·비소급 Toggle

Acceptance:

- Narrative 무소비
- Standard Confirm 전 무변경
- 3일 Advance의 Boundary·중간 사건 보존
- Item 실패 시 Time 미진행
- Toggle On·Off 비소급
- Restart·Rollback exact Settlement 복구

## 4. Phase P3 — Slice 11 DM Tool

착수 Gate:

- P1·P2 Projection·Command API 고정
- DM Modular Window와 Preference Foundation 완료

Production 범위:

- Campaign Rules Window
- Current·Candidate Snapshot Diff
- Time Advance Supply Preview
- Supply Source 조정·Protection
- Supply Ledger
- Retroactive Reconcile Preview·Confirm·Audit

DM UI는 Item·Time·Effect Store를 직접 수정하지 않고 P1·P2 Command Route만 사용한다.

## 5. Phase P4 — Slice 12 Content Registry

착수 Gate:

- Policy·Catalog·Package 실제 Source Mapping
- Rights·Provenance 검토 경로

Production 범위:

- Consumption Requirement Definition
- Supply Unit·Shortage Recipe
- Actor Stat Block Schema Registry
- Trusted Recipe Catalog Projection
- Actor Model Catalog Projection
- Campaign-authored Data Package Version

정확한 공식 수치와 규칙 Anchor는 이 Phase의 Content Definition이 소유한다.

## 6. Phase P5 — Slice 15 Actor·Token Pipeline

착수 Gate:

- P4 Schema·Catalog·Rights Registry 통과
- Actor Model Asset·Prefab·SceneNpc Source Mapping

Production 범위:

- Actor Model Import·Security·Bounds·Feet Pivot 검증
- Strict Stat Block JSON Validator
- AI Prompt Builder용 전체 보이는 Model Catalog Export
- ActorModel·StatBlock·TokenPrefab·ActorTemplate 분리
- Campaign Draft·Publish
- SceneNpc Spawn·Template Migration

Acceptance:

- Empty Catalog `models: []`
- Stable ID 정렬
- 미등록 Model·Recipe 거부
- Script·Remote·URL Field 거부
- AI Draft 자동 Publish 금지
- Migration 실패 Last Known Good 유지

## 7. Phase P6 — Slice 16 Evidence

착수 Gate:

- P1–P5 Production Source와 Static Gate 통과

필수 Evidence:

- Multi-client DM·Player·Observer
- 다일 Settlement·중간 사건
- Duplicate·Retry·Restart·Rollback
- Hidden Consumer·Container·Actor·Stat Negative Disclosure
- Draft→Publish→Spawn→Reconnect
- Template Migration 성공·실패
- Large Ledger·Catalog·Actor Scene Performance
- Runbook·Recovery Review

## 8. Manifest 정책

각 Phase 시작 시 다음 순서로 Manifest를 작성한다.

```text
관련 Slice Baseline Contract
+ ADR-0092 Delta
+ 실제 Source Tree
→ Script Manifest
→ Test Manifest
→ Migration Mapping
→ Static Gate
→ Studio Acceptance
```

P1이 완료되기 전에 P2–P5 Production Script를 미리 만들지 않는다.

## 9. 현재 판정

```text
Product·Spec Planning
→ READY

P1 Source Mapping
→ NOT STARTED

P2–P6
→ BLOCKED BY PREVIOUS PHASE

Roblox Runtime Evidence
→ NOT PRODUCED
```
