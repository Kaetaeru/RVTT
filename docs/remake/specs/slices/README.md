# Implementation Slice Specification Packages

- 상태: `COMPLETE_WITH_BLOCKERS_AND_ADR_0092_PHASED_DELTA`
- 문서 종류: Slice Specification Index
- 최종 갱신일: 2026-08-06
- 전체 Roadmap: [`../SLICE-ROADMAP.md`](../SLICE-ROADMAP.md)
- 현재 작업 순서: [`../CURRENT-SPEC-WORK-ORDER.md`](../CURRENT-SPEC-WORK-ORDER.md)
- ADR-0092 Sync Plan: [`../ADR-0092-SLICE-SYNC-PLAN.md`](../ADR-0092-SLICE-SYNC-PLAN.md)
- 전체 완료 감사: [`All-slice Specification Checkpoint Completion Audit`](../../audits/all-slice-specification-checkpoint-completion-audit.md)

16개 Slice 모두 `Work Order → Integration Contract → Checkpoint Audit` Baseline 패키지를 가진다. 모든 Baseline 계약 의미는 `SPEC_CHECKPOINT_COMPLETE`이며, 실제 Production Source·Schema·Test Mapping과 Runtime Evidence에 따라 Production Readiness를 별도로 판정한다.

ADR-0092는 기존 Baseline을 취소하지 않고 관련 Slice에 Additive Delta를 단계적으로 추가한다.

| Slice | Work Order | Integration Contract | Checkpoint Audit | Baseline Spec | ADR-0092 | Production |
|---:|---|---|---|---|---|---|
| 01 | [`First Session`](01-first-session-walking-skeleton/CURRENT-WORK-ORDER.md) | [`Contract`](01-first-session-walking-skeleton/implementation-contract.md) | [`Audit`](../../audits/slices/01-first-session-walking-skeleton-spec-checkpoint-audit.md) | COMPLETE | 기반 재사용 | BLOCKED |
| 02 | [`Core Rules`](02-core-rules-kernel/CURRENT-WORK-ORDER.md) | [`Contract`](02-core-rules-kernel/implementation-contract.md) | [`Audit`](../../audits/slices/02-core-rules-kernel-spec-checkpoint-audit.md) | COMPLETE | 후속 결과 실행 기반 | BLOCKED |
| 03 | [`Exploration`](03-exploration-interaction-perception/CURRENT-WORK-ORDER.md) | [`Contract`](03-exploration-interaction-perception/implementation-contract.md) | [`Audit`](../../audits/slices/03-exploration-interaction-perception-spec-checkpoint-audit.md) | COMPLETE | 후속 중간 사건 기반 | BLOCKED |
| 04 | [`Encounter`](04-encounter-core-loop/CURRENT-WORK-ORDER.md) | [`Contract`](04-encounter-core-loop/implementation-contract.md) | [`Audit`](../../audits/slices/04-encounter-core-loop-spec-checkpoint-audit.md) | COMPLETE | 시간 경계 재사용 | BLOCKED |
| 05 | [`Character`](05-character-foundation-creation/CURRENT-WORK-ORDER.md) | [`Contract`](05-character-foundation-creation/implementation-contract.md) | [`Audit`](../../audits/slices/05-character-foundation-creation-spec-checkpoint-audit.md) | COMPLETE | Consumer 원본 기반 | BLOCKED |
| 06 | [`Inventory`](06-inventory-equipment-world-items/CURRENT-WORK-ORDER.md) | [`Contract`](06-inventory-equipment-world-items/implementation-contract.md) | [`Audit`](../../audits/slices/06-inventory-equipment-world-items-spec-checkpoint-audit.md) | COMPLETE | [`DELTA ADDED`](06-inventory-equipment-world-items/ADR-0092-DELTA.md) | BLOCKED |
| 07 | [`Downtime`](07-rest-time-downtime-progression/CURRENT-WORK-ORDER.md) | [`Contract`](07-rest-time-downtime-progression/implementation-contract.md) | [`Audit`](../../audits/slices/07-rest-time-downtime-progression-spec-checkpoint-audit.md) | COMPLETE | [`DELTA ADDED`](07-rest-time-downtime-progression/ADR-0092-DELTA.md) | BLOCKED |
| 08 | [`UI·Camera`](08-player-ui-camera-presentation/CURRENT-WORK-ORDER.md) | [`Contract`](08-player-ui-camera-presentation/implementation-contract.md) | [`Audit`](../../audits/slices/08-player-ui-camera-presentation-spec-checkpoint-audit.md) | COMPLETE | 공통 UI 기반 | BLOCKED |
| 09 | [`Journal`](09-journal-ping-knowledge-navigation/CURRENT-WORK-ORDER.md) | [`Contract`](09-journal-ping-knowledge-navigation/implementation-contract.md) | [`Audit`](../../audits/slices/09-journal-ping-knowledge-navigation-spec-checkpoint-audit.md) | COMPLETE | 후속 Anchor 연결 | BLOCKED |
| 10 | [`Scene Authoring`](10-scene-authoring-compile-publish/CURRENT-WORK-ORDER.md) | [`Contract`](10-scene-authoring-compile-publish/implementation-contract.md) | [`Audit`](../../audits/slices/10-scene-authoring-compile-publish-spec-checkpoint-audit.md) | COMPLETE | Asset·Placement 기반 | BLOCKED |
| 11 | [`Live DM`](11-live-dm-workspace-quick-actions-recovery/CURRENT-WORK-ORDER.md) | [`Contract`](11-live-dm-workspace-quick-actions-recovery/implementation-contract.md) | [`Audit`](../../audits/slices/11-live-dm-workspace-quick-actions-recovery-spec-checkpoint-audit.md) | COMPLETE | QUEUED | BLOCKED |
| 12 | [`Content Platform`](12-content-pack-localization-trusted-extension/CURRENT-WORK-ORDER.md) | [`Contract`](12-content-pack-localization-trusted-extension/implementation-contract.md) | [`Audit`](../../audits/slices/12-content-pack-localization-trusted-extension-spec-checkpoint-audit.md) | COMPLETE | QUEUED | BLOCKED |
| 13 | [`Character Content`](13-official-2024-character-options-content/CURRENT-WORK-ORDER.md) | [`Contract`](13-official-2024-character-options-content/implementation-contract.md) | [`Audit`](../../audits/slices/13-official-2024-character-options-content-spec-checkpoint-audit.md) | COMPLETE | 후속 Content 기여 | BLOCKED |
| 14 | [`Spell·Item Content`](14-official-2024-spell-equipment-rules-content/CURRENT-WORK-ORDER.md) | [`Contract`](14-official-2024-spell-equipment-rules-content/implementation-contract.md) | [`Audit`](../../audits/slices/14-official-2024-spell-equipment-rules-content-spec-checkpoint-audit.md) | COMPLETE | 후속 Definition 기여 | BLOCKED |
| 15 | [`NPC·Monster`](15-npc-monster-campaign-authored-content/CURRENT-WORK-ORDER.md) | [`Contract`](15-npc-monster-campaign-authored-content/implementation-contract.md) | [`Audit`](../../audits/slices/15-npc-monster-campaign-authored-content-spec-checkpoint-audit.md) | COMPLETE | QUEUED | BLOCKED |
| 16 | [`Release`](16-full-session-integration-release-hardening/CURRENT-WORK-ORDER.md) | [`Contract`](16-full-session-integration-release-hardening/implementation-contract.md) | [`Audit`](../../audits/slices/16-full-session-integration-release-hardening-spec-checkpoint-audit.md) | COMPLETE | QUEUED | BLOCKED |

## ADR-0092 단계적 책임

```text
Slice 06
→ Supply Metadata·Protection·Source·Allocation·Reservation

Slice 07
→ Campaign Policy·Boundary·Requirement·Settlement·Ledger

Slice 11
→ Campaign Rules·Supply Preview·Ledger·Reconcile DM Tool

Slice 12
→ Requirement·Schema·Trusted Recipe·Model Catalog Content Platform

Slice 15
→ Model Registry·Strict JSON·Prompt·Template Publish·SceneNpc

Slice 16
→ Fault·Disclosure·Migration·Performance·Runbook Evidence
```

### 현재 완료

- Product Authority와 Roadmap 연결
- Slice 06 Additive Delta
- Slice 07 Additive Delta
- 후속 Slice의 책임과 착수 Gate

### 현재 미완료

- Slice 11·12·15·16 Integration Contract 흡수
- Script Manifest·Production Source Mapping
- Roblox Runtime·다중 Client Evidence

## 공통 해석

```text
SPEC_CHECKPOINT_COMPLETE
→ 2026-08-05 Baseline 사용자 결과·Authority·Command·State·Projection·Persistence·Migration·Diagnostics·Test 계약이 작성되고 감사됨

ADDITIVE_DELTA_SPEC_COMPLETE
→ 최신 ADR의 추가 범위가 별도 Delta로 작성됐으며 실제 Source Mapping 후 Baseline Contract·Manifest에 흡수해야 함

BLOCKED
→ Production Package·Schema·Migration·Roblox Test Host·측정값 또는 Content Rights가 준비되지 않음
```

통합 계약은 Slice Baseline 의미와 경계를 소유한다. Delta는 최신 결정의 추가 책임을 소유하며, 실제 Source Mapping 단계에서 통합 계약과 Script Manifest에 흡수한다. Delta 문서만으로 Production Ready 또는 Runtime PASS를 주장하지 않는다.
