# RVTT Remake 현재 작업 순서

- 상태: ACTIVE_WITH_BLOCKER
- 문서 종류: Planning Work Order
- 최종 갱신일: 2026-08-05
- Architecture 완료 근거: [`Runtime Architecture Completion 감사`](audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)
- Guide 완료 근거: [`Main System Guide 완료 감사`](audits/main-system-guide-consistency-and-document-hub-completion-audit.md)
- User Guide 완료 근거: [`Player·DM User Guide 완료 감사`](audits/player-and-dm-user-guide-completion-audit.md)
- 문서 연결 완료 근거: [`구현 명세 전 최종 문서 연결 감사`](audits/pre-implementation-document-linkage-audit.md)
- 전체 Slice Roadmap: [`specs/SLICE-ROADMAP.md`](specs/SLICE-ROADMAP.md)
- 현재 Spec 작업 순서: [`specs/CURRENT-SPEC-WORK-ORDER.md`](specs/CURRENT-SPEC-WORK-ORDER.md)
- 전체 명세 완료 근거: [`All-slice Specification Checkpoint Completion Audit`](audits/all-slice-specification-checkpoint-completion-audit.md)

이 문서는 RVTT 리메이크의 기획·Guide·명세·구현 순서를 관리하는 단일 상위 기준이다.

## 1. 현재 단계 요약

```text
Architecture
→ DONE

12 Main System Guides
→ DONE

Player·DM User Guides·Quick Flow
→ DONE

16 Slice Specification Checkpoints
→ DONE

4 Cross-Slice Checkpoints
→ DONE

Production Source Mapping
→ IN_PROGRESS·BLOCKED

Production Implementation
→ BLOCKED
```

## 2. 상위 작업 순서

| 순서 | 상태 | 작업 | 완료 조건 |
|---:|---|---|---|
| 1 | DONE | Product·Architecture·ADR | Runtime·Domain·Integration 권위 계약 완료 |
| 2 | DONE | Main System Guides | 12개 Guide·Hub·완료 감사 |
| 3 | DONE | Player·DM User Guides·Quick Flow | 정상·역할·예외·Recovery 흐름 완료 |
| 4 | DONE | Pre-Implementation Linkage Audit | Root→Flow→Guide→Authority→Spec 연결 |
| 5 | DONE | Implementation Slice Roadmap | 16개 Slice 정의·완전성 감사 |
| 6 | DONE | All-slice Specification Checkpoints | 16개 Package·16개 Audit·4개 Checkpoint·Recovery Branch |
| 7 | IN_PROGRESS | Production Source Mapping | 실제 Repository·Place Source·Schema·Test와 Slice 계약 연결 |
| 8 | BLOCKED | Slice 01 Spec Readiness | Mapping·Migration·Budget·Test Host 연결 |
| 9 | BLOCKED | Production Implementation | 준비 완료 Slice와 사용자 명시적 구현 승인 필요 |
| 10 | BLOCKED | Slice Build Acceptance·Next Slice | Code·Migration·Roblox Test·User Acceptance 완료 |
| 11 | BLOCKED | Release Hardening | 16개 Build·Rights·Migration·Fault·Soak Evidence 필요 |

## 3. 현재 작업

```text
Slice 01 First Session Walking Skeleton
→ Production Source Mapping
```

상세 작업:

```text
Roblox Place·Rojo Source 확인
→ Server·Client·Shared Package Root
→ ID·Result·Error·Remote·Projection Registry
→ Session·Token·Permission·Scene·Movement 구현
→ Persistence Schema·Journal·Legacy Data
→ Test Runner·Virtual Client·Roblox Integration
→ 논리 계약과 실제 경로 Mapping
→ Slice 01 Readiness 재감사
```

현재 참조:

- [`Slice 01 Work Order`](specs/slices/01-first-session-walking-skeleton/CURRENT-WORK-ORDER.md)
- [`Slice 01 Integration Contract`](specs/slices/01-first-session-walking-skeleton/implementation-contract.md)
- [`Core Authority 세부 초안`](specs/runtime/001-core-authority-identity-version-and-result.md)
- [`Slice 01 Checkpoint Audit`](audits/slices/01-first-session-walking-skeleton-spec-checkpoint-audit.md)

## 4. 16개 Slice 상태

모든 Slice의 Specification Checkpoint는 완료됐고 Production Readiness는 차단됐다.

```text
01 Session
02 Core Rules
03 Exploration
04 Encounter
05 Character
06 Inventory
07 Downtime
08 UI·Camera·Presentation
09 Journal
10 Scene Authoring
11 Live DM Operation
12 Content Platform
13 Official Character Content
14 Official Spell·Equipment Content
15 NPC·Monster Content
16 Release Hardening
```

상세 패키지와 상태는 [`specs/slices/README.md`](specs/slices/README.md)를 따른다.

## 5. Recovery Checkpoint

- `checkpoint/specs-slices-01-04-2026-08-05`
- `checkpoint/specs-slices-05-08-2026-08-05`
- `checkpoint/specs-slices-09-12-2026-08-05`
- `checkpoint/specs-slices-13-16-2026-08-05`

Commit·CI 정보는 [`audits/slice-checkpoints/README.md`](audits/slice-checkpoints/README.md)에 기록됐다.

## 6. Production Blocker

공통:

- 실제 Production Source Tree와 Package 경로
- Legacy Schema·Data·Migration 대상
- Roblox Integration·Profiling 환경
- 측정형 Timeout·Queue·Payload·Snapshot·Capacity

Content:

- 공식 Data·Source Version
- Rights Review·배포 범위
- Localization·Asset·Packaging·Signing·CI

Release:

- Production Code·Migration Evidence
- Full-session·Fault·Disclosure·Security·Performance·Soak 결과
- Deployment·Rollback·Incident Runbook Drill

## 7. 운영 규칙

1. 가장 위의 `IN_PROGRESS` 작업을 먼저 처리한다.
2. 세부 단계에서는 해당 Work Order가 이 문서보다 우선한다.
3. 새 Product 동작이나 Architecture 충돌이 발견되면 권위 문서를 먼저 수정한다.
4. 통합 계약과 실제 코드 구조를 구분하며 조사하지 않은 Module 경로를 확정하지 않는다.
5. Legacy 데이터 변경에는 Migration·Deprecation·Tombstone·Last Known Good가 필요하다.
6. 테스트·측정 없이 구현·성능·안정성 완료를 주장하지 않는다.
7. Production Code는 준비 완료 Slice와 사용자의 명시적 구현 승인 후 시작한다.
8. 각 Slice는 Production Build Acceptance 후 다음 Slice로 이동한다.
9. Checkpoint Branch는 검증된 복구 기준으로 유지한다.
10. `SUPERSEDED`, `DISCONTINUED`, `ARCHIVED` 문서를 Authority로 사용하지 않는다.

## 8. 다음 단계 Gate

Slice 01 Source Mapping이 끝난 뒤:

```text
Package·Schema·Migration 세부 Spec
→ Slice 01 Spec Readiness Audit
→ 사용자 Production Implementation 승인
→ Code·Migration·Test
→ Slice 01 Build Acceptance Audit
→ Slice 02 Source Mapping
```

현재는 명세 전체를 작성한 상태이지 Production 구현이나 Release 준비가 완료된 상태가 아니다.