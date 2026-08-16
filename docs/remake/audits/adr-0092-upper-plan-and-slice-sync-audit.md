# ADR-0092 상위 기획·Slice 동기화 감사

- 상태: `PASS_WITH_PHASED_RUNTIME_FOLLOW_UP`
- 문서 종류: Planning·Spec Linkage Audit
- 최종 갱신일: 2026-08-06
- 대상 결정: [`ADR-0092`](../decisions/ADR-0092-campaign-survival-logistics-and-dm-authored-actor-tokens.md)
- Product Scope: [`Campaign Rules·Survival·Authored Actor`](../product/campaign-rules-survival-and-authored-actor-scope.md)
- Slice Sync Plan: [`ADR-0092-SLICE-SYNC-PLAN`](../specs/ADR-0092-SLICE-SYNC-PLAN.md)
- Roadmap: [`SLICE-ROADMAP`](../specs/SLICE-ROADMAP.md)

## 1. 감사 목적

ADR-0092가 Architecture·User Guide·HTML·Schema에만 존재하고 상위 Product Scope와 Implementation Slice 책임에 연결되지 않은 상태를 검사했다.

감사 질문:

1. 최종 제품 범위에 Campaign Survival과 DM Actor Authoring이 명시됐는가?
2. 현재 Production 우선순위를 새 기능이 부당하게 선점하지 않는가?
3. 기존 16개 Slice 번호와 사용자 결과를 유지하는가?
4. Supply Metadata·Time Settlement·DM UI·Content Registry·Actor Publish 책임이 올바른 Slice에 배정됐는가?
5. 아직 구현하지 않은 후속 Slice를 완료로 주장하지 않는가?
6. 문서·Schema·HTML 검증과 Roblox Runtime Evidence를 분리하는가?

## 2. 발견된 연결 공백

### Gap A — Product Authority 누락

기존 Product Index는 플랫폼, 플레이어 콘텐츠, Material Component만 직접 연결했다.

누락:

- Narrative·Standard·Survival·Custom Campaign Rule Profile
- 식량·물·탈것 사료와 선택적 세부 Module
- Time Advance와 Supply Settlement
- DM Actor Model Registry·Strict Stat Block·Prompt Builder
- Campaign-local Actor Template Publish·Migration

조치:

- [`campaign-rules-survival-and-authored-actor-scope.md`](../product/campaign-rules-survival-and-authored-actor-scope.md) 생성
- [`product/README.md`](../product/README.md)에 권위 문서 등록

판정: `CLOSED`

### Gap B — 최상위 문서 상태가 현재 Production과 불일치

기존 Documentation Index는 `SLICE 01 SCRIPT MANIFEST`, `Production Luau Script NOT STARTED`로 표시했지만 실제 Production Work Order에는 16 Slice Baseline Source와 현재 Full UI·UX 정합화 작업이 기록돼 있었다.

조치:

- [`docs/remake/README.md`](../README.md)를 현재 Production Baseline·UI Alignment 상태로 갱신
- ADR-0092를 별도 Lane으로 분리

판정: `CLOSED`

### Gap C — Slice Roadmap의 ADR-0092 책임 분해 누락

기존 Roadmap은 Slice 15의 안전한 Statblock Import만 언급했다.

누락:

- Slice 06 Supply Metadata·Reservation
- Slice 07 Campaign Policy·Settlement·Ledger
- Slice 11 Campaign Rules·Preview UI
- Slice 12 Requirement·Schema·Model Catalog
- Slice 15 Model Registry·Prompt·Token Template
- Slice 16 ADR-0092 Integration Evidence

조치:

- [`SLICE-ROADMAP.md`](../specs/SLICE-ROADMAP.md)에 ADR-0092 Delta 상태와 단계 추가
- [`ADR-0092-SLICE-SYNC-PLAN.md`](../specs/ADR-0092-SLICE-SYNC-PLAN.md) 생성

판정: `CLOSED`

### Gap D — 선행 Slice 06·07의 구체 계약 누락

기존 Inventory와 Time·Downtime 계약은 일반 Item Reservation·Time Checkpoint를 가졌지만 Supply Metadata, 부분 날짜, Atomic Settlement와 Ledger를 직접 정의하지 않았다.

조치:

- [`Slice 06 ADR-0092 Delta`](../specs/slices/06-inventory-equipment-world-items/ADR-0092-DELTA.md)
- [`Slice 07 ADR-0092 Delta`](../specs/slices/07-rest-time-downtime-progression/ADR-0092-DELTA.md)
- 각 Slice Work Order에 Delta·착수 Gate 연결

판정: `CLOSED_AT_DELTA_SPEC_LEVEL`

### Gap E — 후속 Slice의 동시 착수 위험

기존 최상위 ADR-0092 Production 목록은 13개 작업을 연속 나열해 현재 UI Lane과 동시에 즉시 착수하는 것으로 해석될 수 있었다.

조치:

- 현재 Production Lane A와 ADR-0092 Lane B 분리
- 11·12·15·16은 선행 Source Mapping 후 하나씩 흡수

판정: `CLOSED`

## 3. 권위 연결 Matrix

| 요구 | Product | Architecture | Spec·Slice | UI·Guide | 상태 |
|---|---|---|---|---|---|
| Campaign Preset·Module | Product Scope | Policy·Survival Runtime | Slice 07 Delta | DM Guide·HTML | CONNECTED |
| 정확한 소비 수치 Source | Product Scope | Ruleset Policy·Survival Runtime | Slice 12 QUEUED | Rule Profile 표시 | CONNECTED · RUNTIME PENDING |
| Supply Metadata·보호 | Product Scope | Inventory·Survival Runtime | Slice 06 Delta | Inventory Summary | CONNECTED |
| 다일 Time Settlement | Product Scope | Game Time·Survival Runtime | Slice 07 Delta | Time Preview | CONNECTED |
| Mid-campaign Toggle | Product Scope | Frozen Snapshot Runtime | Slice 07 Delta | Campaign Rules | CONNECTED |
| Supply Ledger·Reconcile | Product Scope | Settlement Runtime | Slice 07 + Slice 11 QUEUED | DM Tool | CONNECTED · UI CONTRACT PENDING |
| Actor Model Registry | Product Scope | Actor Token Runtime | Slice 12·15 QUEUED | Registry HTML | CONNECTED · CONTRACT ABSORPTION PENDING |
| Strict Stat Block JSON | Product Scope | Actor Token Runtime | Slice 12·15 QUEUED | Validator HTML | CONNECTED · CONTRACT ABSORPTION PENDING |
| 전체 Model Catalog Prompt | Product Scope | Catalog Projection Runtime | Slice 12·15 QUEUED | Prompt Builder | CONNECTED · CONTRACT ABSORPTION PENDING |
| Campaign-local Publish | Product Scope | Content Pack·Actor Runtime | Slice 15 QUEUED | Actor Builder | CONNECTED · CONTRACT ABSORPTION PENDING |
| Full-session Evidence | Product Scope | Diagnostics·Persistence | Slice 16 QUEUED | User Guide 결과 | CONNECTED · RUNTIME PENDING |

## 4. Slice 경계 판정

### Slice 01

변경하지 않는다.

이유:

- Campaign ID·Authority Epoch·Projection·Persistence 기반은 재사용한다.
- Survival과 Actor Authoring을 첫 Session Walking Skeleton에 넣으면 종료 경계가 깨진다.

판정: `NO DIRECT DELTA REQUIRED`

### Slice 06

직접 책임:

- Supply Metadata
- Item·Container 공개·보호·예약
- 부분 Stack Allocation
- Settlement Item Reservation

판정: `DELTA SPEC COMPLETE`

### Slice 07

직접 책임:

- Campaign Survival Policy
- Logistics Boundary
- Requirement·Settlement·Ledger
- 비소급 Policy Change

판정: `DELTA SPEC COMPLETE`

### Slice 11

직접 책임:

- DM Campaign Rules·Preview·Ledger·Reconcile UI

선행 API가 없으므로 지금 Contract를 상세화하면 UI가 Authority를 소유하는 잘못된 추측이 생긴다.

판정: `QUEUED AFTER 06·07 SOURCE MAPPING`

### Slice 12

직접 책임:

- Requirement·Supply Unit·Shortage Recipe
- Stat Block Schema·Trusted Recipe·Model Catalog

판정: `QUEUED AFTER CONTENT REGISTRY MAPPING`

### Slice 15

직접 책임:

- Model Registry·Strict Import·Prompt Builder
- Actor Template Publish·SceneNpc Migration

판정: `QUEUED AFTER SLICE 12`

### Slice 16

직접 책임:

- Fault·Disclosure·Migration·Performance·Soak·Runbook Evidence

판정: `QUEUED AFTER RUNTIME IMPLEMENTATION`

## 5. 단계적 동기화 판정

```text
Upper Product Authority
→ PASS

Top-level Work Order
→ PASS

16-Slice Roadmap Responsibility
→ PASS

Slice 06 Delta
→ PASS

Slice 07 Delta
→ PASS

Slice 11·12·15·16 Detailed Contract
→ INTENTIONALLY QUEUED

Production Source
→ NOT MODIFIED BY THIS SYNC

Roblox Studio Runtime Evidence
→ NOT PRODUCED
```

`INTENTIONALLY QUEUED`는 누락을 성공으로 처리한 것이 아니다. 선행 Source·API가 확인되지 않은 상태에서 후속 Contract를 추측하지 않기 위한 명시적 단계 상태다.

## 6. 다음 감사 Gate

### Gate 1 — Slice 06 Source Mapping

- Item Definition·Location·Container ACL
- Reservation Coordinator
- Supply Metadata Migration
- Projection·Negative Disclosure

### Gate 2 — Slice 07 Source Mapping

- Campaign Time·Scheduler
- Frozen Policy Snapshot
- Rule Content Requirement·Shortage Recipe
- Ledger·Idempotency·Rollback

### Gate 3 — Slice 11·12 Contract Absorption

- DM Tool이 Slice 06·07 Authority API만 사용하는지
- Content Registry가 수치·Schema·Catalog Version을 소유하는지

### Gate 4 — Slice 15 Actor Pipeline

- Model Rights·Security Validation
- Strict JSON·Reference Resolver
- Prompt의 전체 Catalog·Stable Sort
- Draft·Publish·Migration 분리

### Gate 5 — Slice 16 Runtime Evidence

- 다일 Settlement·Retry·Restart·Rollback
- Hidden Consumer·Asset·Stat Negative Disclosure
- Performance·Soak·Runbook
- Roblox Studio 다중 Client Evidence

## 7. 최종 결론

ADR-0092는 Product·Architecture·Guide·Schema에서 16-Slice Roadmap까지 연결됐다. 선행 데이터·시간 기반인 Slice 06·07은 구현 가능한 Delta 수준으로 동기화했다.

후속 Slice 11·12·15·16은 책임과 착수 Gate만 고정했으며, 선행 Source Mapping 후 하나씩 본 계약에 흡수한다.

현재 결과는 상위 기획·Slice 문서 동기화 PASS다. ADR-0092 Production Runtime 또는 Roblox Studio PASS가 아니다.
