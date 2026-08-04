# 구현 명세

- 상태: ACTIVE_WITH_BLOCKER
- 문서 종류: Implementation Spec Index
- 최종 갱신일: 2026-08-05
- Slice Specification Checkpoint: `16 / 16 COMPLETE`
- Cross-Slice Checkpoint: `4 / 4 COMPLETE`
- Production Readiness: `BLOCKED`

확정된 사용자 경험과 권위 문서를 실제 Module, Type, Command, Network, Persistence, Migration, Diagnostics와 Test 계약으로 변환한다.

## 핵심 진입점

- [`전체 Slice Roadmap`](SLICE-ROADMAP.md)
- [`16개 Slice Package Index`](slices/README.md)
- [`현재 Spec 작업 순서`](CURRENT-SPEC-WORK-ORDER.md)
- [`전체 명세 완료 감사`](../audits/all-slice-specification-checkpoint-completion-audit.md)
- [`16개 Slice Audit Index`](../audits/slices/README.md)
- [`4개 Cross-Slice Checkpoint·Recovery Branch`](../audits/slice-checkpoints/README.md)
- [`Implementation Spec Template`](../templates/implementation-spec-template.md)

## 완료된 명세 범위

```text
01 Session
→ 02 Core Rules
→ 03 Exploration
→ 04 Encounter
→ 05 Character
→ 06 Inventory
→ 07 Downtime
→ 08 UI·Camera·Presentation
→ 09 Journal
→ 10 Scene Authoring
→ 11 Live DM Operation
→ 12 Content Platform
→ 13 Official Character Content
→ 14 Official Spell·Equipment Content
→ 15 NPC·Monster Content
→ 16 Release Hardening
```

각 Slice는 다음 세 문서를 가진다.

```text
CURRENT-WORK-ORDER.md
→ implementation-contract.md
→ Slice Checkpoint Audit
```

통합 계약은 사용자 결과, Authority State, Type, Command, Projection, Persistence, Migration, Diagnostics, Security와 Test 경계를 소유한다.

## Checkpoint

- A: Slices 01–04 — `checkpoint/specs-slices-01-04-2026-08-05`
- B: Slices 05–08 — `checkpoint/specs-slices-05-08-2026-08-05`
- C: Slices 09–12 — `checkpoint/specs-slices-09-12-2026-08-05`
- D: Slices 13–16 — `checkpoint/specs-slices-13-16-2026-08-05`

각 Branch는 Cross-Slice Audit과 문서 검증이 성공한 정확한 Commit을 가리킨다.

## 현재 차단 사항

모든 Slice 공통:

- 실제 Roblox Place·Rojo Source Tree
- Server·Client·Shared Package Root
- Remote·Persistence·Test Registry
- Legacy Schema·Data와 Migration 대상
- 실제 Profiling 기반 Budget·Capacity

Content Slice 추가:

- 공식 Data·Source Version
- 권리·배포 허용 범위
- Localization·Asset·Packaging·Signing·CI Pipeline

Release 추가:

- Production Code·Migration
- Roblox Integration·Fault·Security·Soak Evidence
- Deployment·Rollback·Incident Runbook Drill

## 현재 작업

```text
Slice 01 Production Source Mapping
→ 논리 Package를 실제 Module·Schema·Test 경로에 연결
→ Legacy Migration 조사
→ Spec Readiness 재평가
```

따라서 `Specification Checkpoint Complete`를 `Production Ready`로 해석하지 않는다.

## 명세 작성 원칙

- User Guide는 Acceptance Flow, 직접 Authority 문서는 구현 계약 근거다.
- Guide를 Type·Schema·Command Authority로 사용하지 않는다.
- Source·Build·State·Projection·Presentation을 혼합하지 않는다.
- Client Intent와 Server Authority를 분리한다.
- Version·Migration·Recovery·Rollback을 포함한다.
- Ordering·Reservation·Transaction·Outbox·Projection Barrier를 명시한다.
- Trace·Stable Error·Health·Support Reference를 포함한다.
- Deterministic·Fault·Negative Disclosure·Roblox Integration Test를 정의한다.
- 측정 전 수치 기본값을 확정하지 않는다.
- `SUPERSEDED`, `DISCONTINUED`, `ARCHIVED` 문서를 근거로 사용하지 않는다.
- 승인된 준비 완료 Spec 없이 Production Code를 작성하지 않는다.

## 기존 Shared Spec

- [`Shared Spec Index`](shared/README.md)
- [`001 Recipe Step Runtime Foundation`](shared/001-recipe-step-runtime-foundation.md)
- [`002 Standard Step Handler Contracts`](shared/002-standard-step-handler-contracts.md)
- [`재검토 감사`](../audits/shared-spec-001-002-revalidation-audit.md)

Shared 001·002는 계속 `UPDATE_REQUIRED`이며 [`Slice 02 Core Rules Contract`](slices/02-core-rules-kernel/implementation-contract.md)에 맞춰 실제 Source Mapping 단계에서 갱신한다.