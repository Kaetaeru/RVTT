# ADR-0092 단계적 Production 계획

- 상태: `QUEUED_STUDIO_FIRST`
- 최종 갱신일: 2026-08-12
- 상위 Work Order: [`CURRENT-WORK-ORDER.md`](CURRENT-WORK-ORDER.md)

ADR-0092의 제품·Authority 계약은 유지한다. 구현 방식만 Studio-first로 통일한다.

## 공통 Phase 루프

각 Phase는 다음 순서로 진행한다.

```text
관련 Slice·ADR·기존 Source 조사
→ 실제 Module·함수·Schema Mapping
→ Studio MCP에서 작은 사용자 흐름 직접 구현
→ Play·수정
→ 사용자 판단
→ Source 정규화
→ Focused Test
→ Phase Stabilization
```

후속 Phase의 제품 의미를 앞 Phase에서 임의로 확정하지 않는다.

## P1 — Slice 06 Supply Foundation

- Supply Metadata
- Protection·Consumption Policy
- Source Binding·Allocation
- Partial Stack Reservation
- Retry·Restart·Rollback 안전성
- Hidden Container Disclosure 보호

## P2 — Slice 07 Policy·Settlement

- Narrative·Standard·Survival·Custom
- Logistics Boundary
- Requirement Plan
- Atomic Time·Inventory·Shortage Settlement
- Ledger·Idempotency
- Safe Boundary·비소급 Toggle

## P3 — Slice 11 DM Tool

- Campaign Rules Window
- Policy Diff
- Time Advance Supply Preview
- Supply Ledger
- Reconcile Preview·Confirm·Audit

## P4 — Slice 12 Content Registry

- Requirement Definition
- Shortage Recipe
- Stat Block Schema
- Trusted Recipe Catalog
- Actor Model Catalog
- Campaign-authored Package Version

## P5 — Slice 15 Actor·Token Pipeline

- Actor Model Import·Security
- Strict Stat Block JSON
- AI Prompt Builder
- Template Draft·Publish
- SceneNpc Spawn·Migration

## P6 — Slice 16 Integration·Release Evidence

- Multi-client
- Retry·Restart·Rollback
- Negative Disclosure
- Draft→Publish→Spawn→Reconnect
- Migration
- Performance
- Runbook

P6의 Release Evidence를 P1–P5 개발 반복의 선행조건으로 사용하지 않는다.
