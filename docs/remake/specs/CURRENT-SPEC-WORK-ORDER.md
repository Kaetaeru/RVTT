# RVTT Implementation Specs 현재 상태

- 상태: `BASELINE_COMPLETE · STUDIO_FIRST_HANDOFF`
- 최종 갱신일: 2026-08-12
- 상위 작업 순서: [`../CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)
- Production 작업 순서: [`implementation/roblox/CURRENT-WORK-ORDER.md`](../../../implementation/roblox/CURRENT-WORK-ORDER.md)

## 역할

이 문서는 16개 Slice Baseline Spec과 ADR-0092 Delta의 준비 상태를 기록한다. **현재 Runtime 개발 순서를 소유하지 않는다.** 실제 개발 순서는 Production Work Order와 Studio 결과가 소유한다.

## 현재 상태

```text
16 Slice Baseline
→ COMPLETE

UI·UX Global Policy
→ COMPLETE

Production Baseline Source
→ EXISTS

ADR-0092 Upper Planning
→ COMPLETE

ADR-0092 Slice 06·07 Delta
→ COMPLETE

ADR-0092 Slice 11·12·15·16
→ QUEUED
```

## Studio-first 인계

Spec은 구현자가 중요한 제품·Authority 결정을 추측하지 않을 정도로 명확해야 한다. 하지만 Studio에서 빠르게 판단 가능한 배치·감각·표현 세부를 문서만으로 과도하게 고정하지 않는다.

Production 구현은:

```text
Spec·Authority 읽기
→ 기존 Source Mapping
→ Studio MCP 직접 구현·Play
→ 사용자 판단
→ Source 정규화
→ Focused Test
```

를 따른다.

## ADR-0092 순서

1. Slice 06 — Supply Metadata·Protection·Allocation·Reservation
2. Slice 07 — Policy·Settlement·Ledger
3. Slice 11 — Campaign Rules·Supply Preview·Reconcile DM Tool
4. Slice 12 — Requirement·Schema·Catalog Content Platform
5. Slice 15 — Actor Model·Stat Block·Template Pipeline
6. Slice 16 — Integration·Fault·Disclosure·Performance·Runbook

후속 Phase의 중요한 제품 의미를 선행 Phase에서 임의로 확정하지 않는다.

## 사용자 결정 Gate

Studio 구현 중 Spec보다 나아 보이는 제품·Architecture 방향이 발견되면 해당 Spec을 바로 바꾸지 않는다. 사용자에게 대안과 영향 범위를 먼저 제안한다.
