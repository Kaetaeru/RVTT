# Slice Specification Checkpoint Audits

- 상태: COMPLETE_WITH_BLOCKERS
- 문서 종류: Slice Audit Index
- 작성일: 2026-08-05
- Slice Spec Index: [`../../specs/slices/README.md`](../../specs/slices/README.md)
- Cross-Slice Checkpoints: [`../slice-checkpoints/README.md`](../slice-checkpoints/README.md)
- 전체 완료 감사: [`All-slice Specification Checkpoint Completion Audit`](../all-slice-specification-checkpoint-completion-audit.md)

각 Audit은 해당 Slice의 계약 의미와 품질 Gate가 완결됐는지 검사한다. `COMPLETE_WITH_BLOCKER(S)`는 명세 감사가 완료됐지만 Production 구현 Evidence가 없음을 뜻한다.

1. [`Slice 01 — First Session`](01-first-session-walking-skeleton-spec-checkpoint-audit.md)
2. [`Slice 02 — Core Rules`](02-core-rules-kernel-spec-checkpoint-audit.md)
3. [`Slice 03 — Exploration`](03-exploration-interaction-perception-spec-checkpoint-audit.md)
4. [`Slice 04 — Encounter`](04-encounter-core-loop-spec-checkpoint-audit.md)
5. [`Slice 05 — Character`](05-character-foundation-creation-spec-checkpoint-audit.md)
6. [`Slice 06 — Inventory`](06-inventory-equipment-world-items-spec-checkpoint-audit.md)
7. [`Slice 07 — Rest·Time·Downtime`](07-rest-time-downtime-progression-spec-checkpoint-audit.md)
8. [`Slice 08 — UI·Camera·Presentation`](08-player-ui-camera-presentation-spec-checkpoint-audit.md)
9. [`Slice 09 — Journal·Ping`](09-journal-ping-knowledge-navigation-spec-checkpoint-audit.md)
10. [`Slice 10 — Scene Authoring`](10-scene-authoring-compile-publish-spec-checkpoint-audit.md)
11. [`Slice 11 — Live DM Workspace`](11-live-dm-workspace-quick-actions-recovery-spec-checkpoint-audit.md)
12. [`Slice 12 — Content Platform`](12-content-pack-localization-trusted-extension-spec-checkpoint-audit.md)
13. [`Slice 13 — Official Character Content`](13-official-2024-character-options-content-spec-checkpoint-audit.md)
14. [`Slice 14 — Official Spell·Equipment Content`](14-official-2024-spell-equipment-rules-content-spec-checkpoint-audit.md)
15. [`Slice 15 — NPC·Monster Content`](15-npc-monster-campaign-authored-content-spec-checkpoint-audit.md)
16. [`Slice 16 — Release Hardening`](16-full-session-integration-release-hardening-spec-checkpoint-audit.md)

공통 Production Blocker:

- 실제 Server·Client·Shared·Persistence·Test Source Tree
- Legacy Schema·Data Migration 대상
- Roblox Integration·Profiling 환경
- 측정형 Budget·Timeout·Capacity

추가 Content Blocker:

- 공식 Data·Source Version
- 권리·배포 허용 범위
- Asset·Localization·Release Pipeline