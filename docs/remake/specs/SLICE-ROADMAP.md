# RVTT Implementation Slice Roadmap

- 상태: SPECIFICATION_CHECKPOINTS_COMPLETE
- 문서 종류: Implementation Slice Roadmap
- 최종 갱신일: 2026-08-05
- 상위 작업 순서: [`../CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)
- 현재 Spec 작업 순서: [`CURRENT-SPEC-WORK-ORDER.md`](CURRENT-SPEC-WORK-ORDER.md)
- Slice Package Index: [`slices/README.md`](slices/README.md)
- Roadmap 완전성 감사: [`Implementation Slice Roadmap 완전성 감사`](../audits/implementation-slice-roadmap-completeness-audit.md)
- 전체 명세 완료 감사: [`All-slice Specification Checkpoint Completion Audit`](../audits/all-slice-specification-checkpoint-completion-audit.md)

이 문서는 RVTT 리메이크를 사용자가 검증할 수 있는 16개 수직 Slice로 나눈 장기 순서 기준이다. 각 Slice의 상세 사용자 흐름·Type·Command·State·Projection·Persistence·Migration·Diagnostics·Test 계약은 [`slices/README.md`](slices/README.md)가 연결한 통합 계약이 소유한다.

## 1. 전체 순서와 상태

| Slice | 이름 | Specification Checkpoint | Production Readiness |
|---:|---|---|---|
| 01 | First Session Walking Skeleton | COMPLETE | BLOCKED |
| 02 | Core Rules Kernel | COMPLETE | BLOCKED |
| 03 | Exploration Interaction·Perception | COMPLETE | BLOCKED |
| 04 | Encounter Core Loop | COMPLETE | BLOCKED |
| 05 | Character Foundation·Creation | COMPLETE | BLOCKED |
| 06 | Inventory·Equipment·World Items | COMPLETE | BLOCKED |
| 07 | Rest·Time·Downtime·Progression | COMPLETE | BLOCKED |
| 08 | Player UI·Camera·Presentation | COMPLETE | BLOCKED |
| 09 | Journal·Ping·Knowledge Navigation | COMPLETE | BLOCKED |
| 10 | Scene Authoring·Compile·Publish | COMPLETE | BLOCKED |
| 11 | Live DM Workspace·Quick Actions·Recovery | COMPLETE | BLOCKED |
| 12 | Content Pack·Localization·Trusted Extension Platform | COMPLETE | BLOCKED |
| 13 | Official 2024 Character Options Content | COMPLETE | BLOCKED |
| 14 | Official 2024 Spell·Equipment·Rules Content | COMPLETE | BLOCKED |
| 15 | NPC·Monster·Campaign Authored Content | COMPLETE | BLOCKED |
| 16 | Full-session Integration·Release Hardening | COMPLETE | BLOCKED |

```text
01 Session Foundation
→ 02 Core Rules
→ 03 Exploration
→ 04 Encounter
→ 05 Character
→ 06 Inventory
→ 07 Progression·Downtime
→ 08 UI·Camera·Presentation
→ 09 Journal
→ 10 Scene Authoring
→ 11 Live DM Operation
→ 12 Content Platform
→ 13 Character Content
→ 14 Spell·Equipment Content
→ 15 NPC·Campaign Content
→ 16 Release Evidence Gate
```

## 2. Slice별 사용자 결과

1. **First Session** — Join, Character 선택, Scene 입장, 클릭 이동과 Reconnect.
2. **Core Rules** — Ability Check, Attack, Save, Damage와 Healing의 공통 Kernel.
3. **Exploration** — Hover·Selection, Door·Container·Search·Trap·Fog와 WASD 탐험.
4. **Encounter** — Initiative·Turn·Opportunity·Reaction·Objective·Rollback.
5. **Character** — Level 1 Character Source·Build·State 생성과 Sheet.
6. **Inventory** — Item 획득·장착·이전·드롭과 World Presence.
7. **Progression** — Rest·Level Up·Preparation·Crafting·Training·Travel.
8. **Client Surface** — Projection UI, Input Context, Camera와 Presentation.
9. **Journal** — Markdown·Search·World Link·Point/Path Ping.
10. **Scene Authoring** — Source 편집, Compile, Test Play와 Atomic Publish.
11. **Live DM** — Control·Quick Action·Runtime Edit·Patch·Recovery.
12. **Content Platform** — Versioned Pack·Localization·Policy·Trusted Extension.
13. **Character Content** — 공식 지원 Character Option과 Level 1–20 Coverage.
14. **Spell·Equipment Content** — 공식 지원 Spell·Item·Condition·Rule Coverage.
15. **NPC·Monster Content** — 안전한 Statblock Import·Campaign Publish·Actor Integration.
16. **Release Hardening** — 장시간 세션·Migration·Fault·Security·Performance·Runbook Gate.

## 3. 모든 Slice의 공통 레일

모든 Slice는 다음을 별도 후속 작업으로 미루지 않고 자신의 완료 조건에 포함한다.

- Stable ID·Version·Epoch·Revision·Incarnation
- Source·Build·State·Projection·Presentation 분리
- Client Intent와 Server Authority 재검증
- Ordering·Reservation·Transaction·Outbox·Projection Barrier
- Migration·Deprecation·Last Known Good·Rollback
- Loading·Waiting·Denied·Retrying·Resync·Recovery 사용자 상태
- Snapshot·Journal·Reconnect·Restart
- Correlated Trace·Stable Error·Health·Support Reference
- Viewer별 Projection·Negative Disclosure
- Deterministic Scenario·Fault Injection·Roblox Integration 경계
- 측정 기반 Performance·Memory·Network·Storage Budget

## 4. 검수 Checkpoint

- [`Checkpoint A — Slices 01–04`](../audits/slice-checkpoints/checkpoint-a-slices-01-04.md)
- [`Checkpoint B — Slices 05–08`](../audits/slice-checkpoints/checkpoint-b-slices-05-08.md)
- [`Checkpoint C — Slices 09–12`](../audits/slice-checkpoints/checkpoint-c-slices-09-12.md)
- [`Checkpoint D — Slices 13–16`](../audits/slice-checkpoints/checkpoint-d-slices-13-16.md)
- [`Checkpoint Index와 복구 Branch`](../audits/slice-checkpoints/README.md)

4개 Checkpoint는 모두 문서 검증 성공 Commit에 고정된 복구 Branch를 가진다.

## 5. 현재 차단 상태

공통 Production Blocker:

- 실제 Roblox Place 또는 Rojo Source Tree
- Server·Client·Shared·Persistence·Test Package Mapping
- Legacy Schema·Data·Migration 대상
- Roblox Integration·Profiling 환경과 측정값

Content Blocker:

- 공식 Data·Source Version·Rights Review
- Localization·Asset·Packaging·Signing·Release Pipeline

따라서 16개 Slice의 **Specification Checkpoint는 완료**됐지만 Production Implementation과 Release Readiness는 완료되지 않았다.

## 6. 다음 실제 단계

```text
Slice 01 Production Source Mapping
→ 논리 Package를 실제 Module·Schema·Test 경로에 연결
→ Legacy Migration 조사
→ Slice 01 Spec Readiness 재평가
→ 사용자 승인 후 Production Implementation
```

순서 또는 Slice 책임을 바꿀 때는 이 Roadmap, 해당 Slice 통합 계약, Cross-Slice Checkpoint와 관련 Guide 영향 지도를 함께 갱신한다.