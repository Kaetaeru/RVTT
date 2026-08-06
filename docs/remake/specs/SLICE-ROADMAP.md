# RVTT Implementation Slice Roadmap

- 상태: `SPECIFICATION_CHECKPOINTS_COMPLETE_WITH_ADR_0092_PHASED_DELTA`
- 문서 종류: Implementation Slice Roadmap
- 최종 갱신일: 2026-08-06
- 상위 작업 순서: [`../CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)
- 현재 Spec 작업 순서: [`CURRENT-SPEC-WORK-ORDER.md`](CURRENT-SPEC-WORK-ORDER.md)
- Slice Package Index: [`slices/README.md`](slices/README.md)
- ADR-0092 동기화: [`ADR-0092-SLICE-SYNC-PLAN.md`](ADR-0092-SLICE-SYNC-PLAN.md)
- Roadmap 완전성 감사: [`Implementation Slice Roadmap 완전성 감사`](../audits/implementation-slice-roadmap-completeness-audit.md)
- 전체 명세 완료 감사: [`All-slice Specification Checkpoint Completion Audit`](../audits/all-slice-specification-checkpoint-completion-audit.md)

이 문서는 RVTT 리메이크를 사용자가 검증할 수 있는 16개 수직 Slice로 나눈 장기 순서 기준이다. 각 Slice의 상세 사용자 흐름·Type·Command·State·Projection·Persistence·Migration·Diagnostics·Test 계약은 [`slices/README.md`](slices/README.md)가 연결한 통합 계약이 소유한다.

ADR-0092는 기존 16개 Slice 번호를 늘리거나 현재 Slice 01·UI 구현 순서를 선점하지 않는다. 기존 Baseline에 Additive Delta를 단계적으로 흡수한다.

## 1. 전체 순서와 상태

| Slice | 이름 | Specification Checkpoint | ADR-0092 Delta | Production Readiness |
|---:|---|---|---|---|
| 01 | First Session Walking Skeleton | COMPLETE | 기반 재사용 · 직접 확장 없음 | BLOCKED |
| 02 | Core Rules Kernel | COMPLETE | 후속 Consequence 실행 기반 | BLOCKED |
| 03 | Exploration Interaction·Perception | COMPLETE | 후속 Travel 중단 사건 기반 | BLOCKED |
| 04 | Encounter Core Loop | COMPLETE | Turn별 Day Settlement 금지 경계 | BLOCKED |
| 05 | Character Foundation·Creation | COMPLETE | 후속 Consumer Binding 기반 | BLOCKED |
| 06 | Inventory·Equipment·World Items | COMPLETE | **DELTA SPEC ADDED** | BLOCKED |
| 07 | Rest·Time·Downtime·Progression | COMPLETE | **DELTA SPEC ADDED** | BLOCKED |
| 08 | Player UI·Camera·Presentation | COMPLETE | 공통 Projection·Accessibility 재사용 | BLOCKED |
| 09 | Journal·Ping·Knowledge Navigation | COMPLETE | Ledger·Rule Anchor 연결 가능 | BLOCKED |
| 10 | Scene Authoring·Compile·Publish | COMPLETE | Model·Actor Placement 경계 재사용 | BLOCKED |
| 11 | Live DM Workspace·Quick Actions·Recovery | COMPLETE | QUEUED AFTER 06·07 SOURCE MAPPING | BLOCKED |
| 12 | Content Pack·Localization·Trusted Extension Platform | COMPLETE | QUEUED AFTER 06·07 CONTRACT TEST | BLOCKED |
| 13 | Official 2024 Character Options Content | COMPLETE | 후속 Consumption Modifier Content | BLOCKED |
| 14 | Official 2024 Spell·Equipment·Rules Content | COMPLETE | 후속 Supply·Requirement Content | BLOCKED |
| 15 | NPC·Monster·Campaign Authored Content | COMPLETE | QUEUED AFTER 12 REGISTRY | BLOCKED |
| 16 | Full-session Integration·Release Hardening | COMPLETE | QUEUED AFTER 06·07·11·12·15 RUNTIME | BLOCKED |

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
6. **Inventory** — Item 획득·장착·이전·드롭과 World Presence. ADR-0092에서는 Supply Metadata·보호·Source·Allocation·Reservation 기반을 소유한다.
7. **Progression** — Rest·Level Up·Preparation·Crafting·Training·Travel. ADR-0092에서는 Campaign Survival Policy·Logistics Boundary·Atomic Settlement·Ledger를 소유한다.
8. **Client Surface** — Projection UI, Input Context, Camera와 Presentation.
9. **Journal** — Markdown·Search·World Link·Point/Path Ping.
10. **Scene Authoring** — Source 편집, Compile, Test Play와 Atomic Publish.
11. **Live DM** — Control·Quick Action·Runtime Edit·Patch·Recovery. 후속 Delta에서 Campaign Rules·Supply Preview·Ledger·Reconcile Tool을 소유한다.
12. **Content Platform** — Versioned Pack·Localization·Policy·Trusted Extension. 후속 Delta에서 Consumption Requirement·Stat Block Schema·Trusted Recipe·Model Catalog 계약을 소유한다.
13. **Character Content** — 공식 지원 Character Option과 Level 1–20 Coverage.
14. **Spell·Equipment Content** — 공식 지원 Spell·Item·Condition·Rule Coverage와 재배포 가능한 Supply Definition을 제공한다.
15. **NPC·Monster Content** — 안전한 Statblock Import·Campaign Publish·Actor Integration. 후속 Delta에서 Actor Model Registry·Prompt Builder·Token Template·SceneNpc Migration을 완성한다.
16. **Release Hardening** — 장시간 세션·Migration·Fault·Security·Performance·Runbook Gate. ADR-0092 Full-session Scenario를 추가한다.

## 3. ADR-0092 단계적 흡수

### Phase 0 — 상위 Product·Roadmap

상태: `COMPLETE`

- Campaign Rule Profile과 DM 저작 Actor를 Product Authority에 연결한다.
- 기존 16개 Slice 책임을 유지한다.
- 현재 UI·UX Production Lane을 중단하지 않는다.

### Phase 1 — Slice 06

상태: `DELTA_SPEC_COMPLETE`

- Supply Metadata
- Protected·Reserved·Private Item 제외
- Supply Source Binding
- 결정적 부분 Stack Allocation
- Settlement Item Reservation
- Retry·Restart·Rollback Marker

### Phase 2 — Slice 07

상태: `DELTA_SPEC_COMPLETE`

- Narrative·Standard·Survival·Custom Policy
- Logistics Boundary와 부분 날짜
- Requirement·Allocation·Shortage Plan
- Time·Inventory·Effect Atomic Settlement
- Ledger·Idempotency
- Mid-campaign Candidate Snapshot·비소급 변경

### Phase 3 — Slice 11

상태: `QUEUED`

- Campaign Rules Window
- Time Advance Supply Preview
- Supply Ledger
- Retroactive Reconcile Review
- Player Audience Preview와 Negative Disclosure

착수 조건: Slice 06·07 실제 Source Mapping과 UI·UX 정합화 Gate.

### Phase 4 — Slice 12

상태: `QUEUED`

- Consumption Requirement·Supply Unit·Shortage Recipe Content
- Strict Stat Block Schema Version
- Trusted Recipe Catalog
- Actor Model Catalog Projection
- Campaign-authored Data Package·Rights

착수 조건: Policy·Content Registry 실제 Mapping.

### Phase 5 — Slice 15

상태: `QUEUED`

- Actor Model Registry
- Strict JSON Validator
- AI Prompt Builder
- ActorModel·StatBlock·TokenPrefab·ActorTemplate 분리
- Campaign-local Publish
- SceneNpc Spawn·Migration

착수 조건: Slice 12 Registry와 실제 Asset·Prefab Pipeline.

### Phase 6 — Slice 16

상태: `QUEUED`

- 3일·다일 Supply Checkpoint
- Reservation Conflict·Retry·Restart·Rollback
- Toggle 비소급
- Hidden Consumer·Container Negative Disclosure
- Empty Model Catalog Prompt
- Invalid Model·Recipe·Script Import 차단
- Draft→Publish→Spawn→Reconnect·Migration
- Performance·Soak·Runbook

## 4. 모든 Slice의 공통 레일

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

ADR-0092 공통 레일:

- Campaign Policy Snapshot과 Content Definition Version 고정
- Item·Time·Effect·Ledger Partial Commit 금지
- AI Draft·Campaign Data의 Code 실행 금지
- Rights·Provenance·Asset Registry 검증
- 공식 수치·CR 자동 창작·보정 금지

## 5. 검수 Checkpoint

- [`Checkpoint A — Slices 01–04`](../audits/slice-checkpoints/checkpoint-a-slices-01-04.md)
- [`Checkpoint B — Slices 05–08`](../audits/slice-checkpoints/checkpoint-b-slices-05-08.md)
- [`Checkpoint C — Slices 09–12`](../audits/slice-checkpoints/checkpoint-c-slices-09-12.md)
- [`Checkpoint D — Slices 13–16`](../audits/slice-checkpoints/checkpoint-d-slices-13-16.md)
- [`Checkpoint Index와 복구 Branch`](../audits/slice-checkpoints/README.md)

기존 4개 Checkpoint는 2026-08-05 Baseline 완료를 증명한다. ADR-0092 Delta는 해당 Baseline을 취소하지 않지만, 관련 Slice의 Production Acceptance 전에 별도 Delta Audit와 Contract 흡수가 필요하다.

## 6. 현재 차단 상태

공통 Production Blocker:

- 실제 Roblox Package·Schema·Test Mapping
- Legacy Schema·Data·Migration 대상
- Roblox Integration·Profiling 환경과 측정값

ADR-0092 Blocker:

- Item Supply Metadata·Reservation 실제 Mapping
- Campaign Time·Policy·Ledger 실제 Mapping
- Consumption Requirement·Shortage Recipe Content
- Actor Model Registry·Rights·Asset Pipeline
- Campaign-local Package Publish·SceneNpc Migration

Content Blocker:

- 공식 Data·Source Version·Rights Review
- Localization·Asset·Packaging·Signing·Release Pipeline

따라서 16개 Slice의 Baseline Specification Checkpoint는 완료됐지만 Production Implementation과 ADR-0092 후속 Delta 흡수는 완료되지 않았다.

## 7. 다음 실제 단계

현재 Production Lane:

```text
Full UI·UX Source·Acceptance 정합화
→ Static Gate
→ 기존 Exploration·Context Input Studio Retest
→ Role·Recovery·Accessibility Evidence
```

ADR-0092 Lane:

```text
상위 Product·Roadmap 연결
→ Slice 06·07 Delta Spec
→ 실제 Source Mapping 대기
→ Slice 06 Supply 기반
→ Slice 07 Settlement 기반
→ Slice 11·12·15·16 순차 흡수
```

순서 또는 Slice 책임을 바꿀 때는 이 Roadmap, 해당 Slice 통합 계약·Delta, Cross-Slice Checkpoint와 관련 Guide 영향 지도를 함께 갱신한다.
