# RVTT Remake 현재 작업 순서

- 상태: ACTIVE
- 문서 종류: Planning·Implementation Work Order
- 최종 갱신일: 2026-08-05
- Architecture 완료 근거: [`Runtime Architecture Completion 감사`](audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)
- 전체 Slice Roadmap: [`specs/SLICE-ROADMAP.md`](specs/SLICE-ROADMAP.md)
- 전체 명세 완료 근거: [`All-slice Specification Checkpoint Completion Audit`](audits/all-slice-specification-checkpoint-completion-audit.md)
- Spec 인계 상태: [`specs/CURRENT-SPEC-WORK-ORDER.md`](specs/CURRENT-SPEC-WORK-ORDER.md)
- UI·UX Policy: [`ui/policies/README.md`](ui/policies/README.md)
- UI·UX 완료 감사: [`UI·UX Policy Completion Audit`](audits/ui-ux-policy-completion-audit.md)
- Production Workspace: [`implementation/roblox`](../../implementation/roblox/README.md)
- 현재 Production Work Order: [`Roblox Implementation Work Order`](../../implementation/roblox/CURRENT-WORK-ORDER.md)

이 문서는 RVTT 리메이크의 기획·명세·Policy·구현 순서를 관리하는 상위 기준이다.

## 1. 현재 단계 요약

```text
Product·Architecture·ADR
→ DONE

Main System Guide·Player·DM User Guide
→ DONE

16 Slice Specification Checkpoints
→ DONE

UI·UX Global Policies·Checklist
→ DONE

Greenfield Production Root
→ CREATED

Roblox Service Folder Structure
→ CREATED

현재 작업
→ Slice 01 Script Manifest

Production Luau Script
→ NOT STARTED
```

## 2. 상위 작업 순서

| 순서 | 상태 | 작업 | 완료 조건 |
|---:|---|---|---|
| 1 | DONE | Product·Architecture·ADR | Runtime·Domain·Integration 권위 계약 완료 |
| 2 | DONE | Main System Guides·User Guides | 12개 Guide와 Player·DM Flow 완료 |
| 3 | DONE | Implementation Slice Roadmap | 16개 Slice 정의·완전성 감사 |
| 4 | DONE | All-slice Specification Checkpoints | 16개 Package·Audit와 4개 Recovery Checkpoint |
| 5 | DONE | UI·UX Global Policy Foundation | 5개 Policy·Checklist·Completion Audit |
| 6 | DONE | Greenfield Implementation Workspace | `implementation/roblox/` Service Folder·책임·금지 경계 |
| 7 | IN_PROGRESS | Slice 01 Script Manifest | Script 순서·경로·책임·API·Test·Migration 연결 |
| 8 | QUEUED | Toolchain·Package Mapping | Rojo·Type Check·Test Runner·Studio Sync 검증 |
| 9 | QUEUED | Slice 01 Script-by-Script Implementation | Manifest 순서대로 Script와 Test 완료 |
| 10 | QUEUED | Slice 01 Roblox Integration·Build Acceptance | Join→Move→Reconnect와 UI·UX Checklist 통과 |
| 11 | BLOCKED | Slice 02 Implementation | Slice 01 Build Acceptance 필요 |
| 12 | BLOCKED | Release Hardening | 16개 Build·Rights·Migration·Fault·Soak Evidence 필요 |

## 3. 구현 방식

사용자의 최신 결정:

```text
기획·명세
→ docs/remake/

실제 구현
→ implementation/roblox/

구현 단위
→ Script Manifest의 가장 위 IN_PROGRESS Script 하나
```

Folder 구조:

```text
implementation/roblox/
├─ src/<Roblox Service>/RVTT/
├─ tests/
├─ tooling/
└─ manifests/
```

실제 Script는 한 파일씩 작성·Test·검수·Commit한다. 빈 Framework 수십 개를 한 번에 만들지 않는다.

## 4. UI·UX 구현 선행 Gate

모든 UI·Client Flow는 다음 Policy를 먼저 따른다.

- [`Visual Design Policy`](ui/policies/visual-design-policy.md)
- [`Interaction and Input Policy`](ui/policies/interaction-and-input-policy.md)
- [`Information Architecture and Density Policy`](ui/policies/information-architecture-and-density-policy.md)
- [`Feedback, Error and Recovery Policy`](ui/policies/feedback-error-and-recovery-policy.md)
- [`Accessibility and Motion Policy`](ui/policies/accessibility-and-motion-policy.md)
- [`UI·UX Review Checklist`](ui/policies/UI-UX-REVIEW-CHECKLIST.md)

Policy 핵심:

- Dark Tactical Fantasy + Professional Tool 시각 언어
- Semantic Design Token 강제
- Q/E·1–5·Pointer·Focus·Selection 공통 문법
- 전장 우선 정보 위계와 Progressive Disclosure
- Pending·Receipt·Projection·Error·Resync·Recovery 상태
- UI Scale·Keyboard·Reduced Motion·Flash·Camera Comfort
- Player·DM·Observer 정보의 Projection 단계 분리

## 5. 현재 작업

```text
Slice 01 First Session Walking Skeleton
→ manifests/slice-01-script-manifest.md
```

Manifest에 포함할 항목:

```text
Script 순서·경로·종류
단일 책임·Public API
의존성·Authority Boundary
연결 Spec
Unit·Integration·Roblox Test
Migration 영향
UI·UX Policy 영향
상태
```

세부 실행 기준은 [`implementation/roblox/CURRENT-WORK-ORDER.md`](../../implementation/roblox/CURRENT-WORK-ORDER.md)가 소유한다.

## 6. 운영 규칙

1. 가장 위의 `IN_PROGRESS` 작업을 먼저 처리한다.
2. 기획·명세와 Production Source를 분리한다.
3. Script Manifest 없이 Script를 추가하지 않는다.
4. 가장 위의 `IN_PROGRESS` Script 하나만 작성한다.
5. Client·Server·Shared·UI 책임을 혼합하지 않는다.
6. UI Component는 Remote·Domain Store를 직접 호출하지 않는다.
7. Legacy 또는 저장 Schema 변경에는 Migration·Version·Last Known Good가 필요하다.
8. Test·Studio 검증 없이 완료를 주장하지 않는다.
9. 한 Slice의 Build Acceptance 전 다음 Slice 구현을 시작하지 않는다.
10. `SUPERSEDED`, `DISCONTINUED`, `ARCHIVED` 문서를 Authority로 사용하지 않는다.

## 7. 다음 단계 Gate

```text
Slice 01 Script Manifest 완료
→ Toolchain·Project Mapping 확정
→ 첫 Shared Contract Script 선정
→ Script + Unit Test
→ Script 단위 Review
→ 다음 Script
```

현재는 UI·UX Policy와 구현 Folder 구조를 확정한 상태이며 Production Luau Script는 아직 작성하지 않았다.
