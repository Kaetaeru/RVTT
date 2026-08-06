# 구현 명세

- 상태: COMPLETE_WITH_IMPLEMENTATION_HANDOFF
- 문서 종류: Implementation Spec Index
- 최종 갱신일: 2026-08-05
- Slice Specification Checkpoint: `16 / 16 COMPLETE`
- Cross-Slice Checkpoint: `4 / 4 COMPLETE`
- UI·UX Policy Foundation: `COMPLETE`
- Greenfield Production Workspace: `BOOTSTRAPPED`
- Production Luau Script: `NOT STARTED`

확정된 사용자 경험과 권위 문서를 Module, Type, Command, Network, Persistence, Migration, Diagnostics와 Test 계약으로 변환했고, 실제 구현은 별도 `implementation/roblox/` Workspace로 인계했다.

## 핵심 진입점

- [`전체 Slice Roadmap`](SLICE-ROADMAP.md)
- [`16개 Slice Package Index`](slices/README.md)
- [`Spec 인계 상태`](CURRENT-SPEC-WORK-ORDER.md)
- [`전체 명세 완료 감사`](../audits/all-slice-specification-checkpoint-completion-audit.md)
- [`UI·UX Global Policies`](../ui/policies/README.md)
- [`UI·UX Review Checklist`](../ui/policies/UI-UX-REVIEW-CHECKLIST.md)
- [`Production Workspace`](../../../implementation/roblox/README.md)
- [`Production Work Order`](../../../implementation/roblox/CURRENT-WORK-ORDER.md)
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

## UI·UX Policy 인계

Production UI·Client Flow는 다음 전역 Policy를 먼저 따른다.

- Visual Design
- Interaction·Input
- Information Architecture·Density
- Feedback·Error·Recovery
- Accessibility·Motion

화면별 UI 문서와 Component Script는 [`UI·UX Review Checklist`](../ui/policies/UI-UX-REVIEW-CHECKLIST.md)를 통과해야 한다.

## Greenfield Production Root

사용자 결정에 따라 기존 Source Tree를 계속 찾는 대신 다음 Root에서 새 구현을 시작한다.

```text
implementation/roblox/
├─ src/<Roblox Service>/RVTT/
├─ tests/
├─ tooling/
└─ manifests/
```

- 실제 Script는 Manifest 순서대로 하나씩 작성한다.
- 빈 Framework Script를 한 번에 생성하지 않는다.
- Toolchain과 최종 Script 경로는 Slice 01 Manifest에서 검증한다.
- Production Source는 `docs/remake/`에 만들지 않는다.

## Checkpoint

- A: Slices 01–04 — `checkpoint/specs-slices-01-04-2026-08-05`
- B: Slices 05–08 — `checkpoint/specs-slices-05-08-2026-08-05`
- C: Slices 09–12 — `checkpoint/specs-slices-09-12-2026-08-05`
- D: Slices 13–16 — `checkpoint/specs-slices-13-16-2026-08-05`
- Final Spec State: `checkpoint/all-slice-specifications-2026-08-05`

## 현재 작업

```text
Slice 01 Script Manifest
→ Toolchain·Service Mapping
→ 첫 Shared Contract Script
→ 대응 Test
→ Script 단위 Review
```

현재 실행 기준은 [`implementation/roblox/CURRENT-WORK-ORDER.md`](../../../implementation/roblox/CURRENT-WORK-ORDER.md)가 소유한다.

## 남은 구현 준비 항목

- `manifests/slice-01-script-manifest.md`
- Rojo 사용 여부와 Project Mapping
- Formatter·Linter·Luau Type Check
- Test Runner와 Studio Integration
- Package·Registry 실제 Script 분할
- 저장 Schema·Migration Version Index
- UI Design Token의 실제 Roblox 표현
- 실제 Profiling 기반 Budget·Capacity

Content Slice 추가:

- 공식 Data·Source Version
- 권리·배포 허용 범위
- Localization·Asset·Packaging·Signing·CI Pipeline

## 명세·구현 원칙

- User Guide는 Acceptance Flow, 직접 Authority 문서는 구현 계약 근거다.
- Source·Build·State·Projection·Presentation을 혼합하지 않는다.
- Client Intent와 Server Authority를 분리한다.
- Version·Migration·Recovery·Rollback을 포함한다.
- Ordering·Reservation·Transaction·Outbox·Projection Barrier를 명시한다.
- Trace·Stable Error·Health·Support Reference를 포함한다.
- Deterministic·Fault·Negative Disclosure·Roblox Integration Test를 정의한다.
- 측정 전 수치 기본값을 완료값으로 확정하지 않는다.
- Script Manifest 없이 Production Script를 추가하지 않는다.
- 한 Slice Build Acceptance 전 다음 Slice 구현을 시작하지 않는다.

## 기존 Shared Spec

- [`Shared Spec Index`](shared/README.md)
- [`001 Recipe Step Runtime Foundation`](shared/001-recipe-step-runtime-foundation.md)
- [`002 Standard Step Handler Contracts`](shared/002-standard-step-handler-contracts.md)
- [`재검토 감사`](../audits/shared-spec-001-002-revalidation-audit.md)

Shared 001·002는 계속 `UPDATE_REQUIRED`이며 Slice 02 구현 전에 [`Slice 02 Core Rules Contract`](slices/02-core-rules-kernel/implementation-contract.md)에 맞춰 갱신한다.
