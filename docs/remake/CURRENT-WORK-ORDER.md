# RVTT Remake 현재 작업 순서

- 상태: ACTIVE
- 문서 종류: Planning·Implementation Work Order
- 최종 갱신일: 2026-08-06
- Architecture 완료 근거: [`Runtime Architecture Completion 감사`](audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)
- 전체 Slice Roadmap: [`specs/SLICE-ROADMAP.md`](specs/SLICE-ROADMAP.md)
- UI·UX Policy: [`ui/policies/README.md`](ui/policies/README.md)
- Production Workspace: [`implementation/roblox`](../../implementation/roblox/README.md)
- Production Work Order: [`Roblox Implementation Work Order`](../../implementation/roblox/CURRENT-WORK-ORDER.md)
- Grand Campaign: [`Grand Acceptance Campaign`](../../implementation/roblox/GRAND-ACCEPTANCE-CAMPAIGN.md)

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

16 Slice Production Source Baseline
→ IMPLEMENTED

Static·Toolchain CI
→ PASSED

Historical Roblox Studio Runtime Baseline
→ VERIFIED

Grand Acceptance Runner·Manifest·Grouped Runs
→ IMPLEMENTED · STATIC VERIFIED

Slices 02–12 Automated Authority Baseline
→ IMPLEMENTED · STATIC VERIFIED · STUDIO NOT EXECUTED

Cross-slice Session·Authority Fault·Capacity Sample
→ IMPLEMENTED · STATIC VERIFIED · STUDIO NOT EXECUTED

현재 작업
→ Grand Persistence·Human UI·Full Fault·Soak Phase 연결
```

## 2. 상위 작업 순서

| 순서 | 상태 | 작업 | 완료 조건 |
|---:|---|---|---|
| 1 | DONE | Product·Architecture·ADR | Runtime·Domain·Integration 권위 계약 완료 |
| 2 | DONE | Main System Guides·User Guides | Player·DM Flow와 System Guide 완료 |
| 3 | DONE | Implementation Slice Roadmap | 16개 Slice 정의·완전성 감사 |
| 4 | DONE | All-slice Specification Checkpoints | 16개 Package·Audit와 Recovery Checkpoint |
| 5 | DONE | UI·UX Global Policy Foundation | Policy·Checklist·Completion Audit |
| 6 | DONE | Production Workspace·Source Baseline | Shared·Server·Client·UI·Test Source 존재 |
| 7 | DONE | Static·Toolchain Validation | Structure·Security·StyLua·Selene·Rojo·Luau 성공 |
| 8 | DONE | Historical Studio Runtime Baseline | Unit·DataStore·3-client 기본 Evidence |
| 9 | DONE | Grand Runner Foundation | Grouped Studio Run·Log Collection·Consolidated Report |
| 10 | DONE | Slices 02–12 Automated Baseline | Domain Authority·거부·Restore 대표 Scenario 등록 |
| 11 | DONE | Cross-slice·Fault·Capacity Baseline | Full-session State·Stale/Epoch·측정 Sample 등록 |
| 12 | IN_PROGRESS | Full Grand Phase Expansion | Persistence·Human UI·Network/Storage Fault·Soak 연결 |
| 13 | BLOCKED | Slices 13–15 Content Acceptance | Source Version·Rights·Distribution·Asset 승인 필요 |
| 14 | QUEUED | Full Grand Runtime | Target Phase가 READY인 Milestone에서 사용자 실행 1회 |
| 15 | BLOCKED | Release Hardening | 16개 Build·Migration·Fault·Soak·Runbook Evidence 필요 |

## 3. Studio Evidence 해석

기존 Studio Evidence:

```text
[RVTT Tests] passed=173 failed=0
[RVTT Live DataStore] passed=10 failed=0
[RVTT MultiClient] passed=56 failed=0 clients=3 staleRetries=3
```

추가 사용자 확인:

```text
Slice 01 Token Pick·Selection·Destination·Movement·Projection
→ PASS

Camera Zoom
→ PASS

Latest Camera WASD·Middle-button·Frame
→ RETEST PENDING
```

새 Slices 02–12·Cross-slice·Fault·Capacity Source는 정적·Build·Type 검증만 완료했다. 아직 Studio Runtime Evidence가 없다.

## 4. Grand Acceptance 운영

```text
기능·복구·보안·성능 변경 축적
→ 자동 Gate
→ Grand Manifest Phase 등록
→ 하나의 Windows PowerShell 실행
→ grouped Studio Runs
→ 모든 실패 수집
→ Root Cause별 수정 Batch
→ 전체 Grand Campaign 재실행
```

현재 실행 그룹:

- `grand-single-client`: Unit·Integration, Slices 02–12 자동 Scenario, Cross-slice·Fault·Capacity, Slice 01 수동 입력
- `grand-multi-client`: DM·Player·Observer Authority·Projection
- Grand Persistence: 전용 Milestone에서만 `-IncludePersistence`

한 기능이나 한 버그 수정마다 Studio를 실행하지 않는다.

## 5. 운영 규칙

1. 가장 위의 `IN_PROGRESS` 작업을 먼저 처리한다.
2. 기획·명세와 Production Source를 분리한다.
3. 자동 Gate 실패 상태에서는 사용자 Studio 실행을 요청하지 않는다.
4. Studio Evidence 없이 Runtime PASS를 주장하지 않는다.
5. Slices 02–12 자동 baseline을 전체 Slice Acceptance로 해석하지 않는다.
6. 저장 Schema 변경에는 Migration·Version·Last Known Good가 필요하다.
7. DataStore 검사는 관련 변경을 모은 Grand Persistence Milestone에서 한 번에 한다.
8. 성능 측정 전 임의 Capacity·Timeout 수치를 완료 기준으로 확정하지 않는다.
9. Slices 13–15 공식 Content는 권리·배포 승인 전까지 Release 대상에 포함하지 않는다.
10. 공식 Monster Statblock은 승인된 원본을 그대로 사용하고 임의 CR·수치 재조정을 하지 않는다.
11. `SUPERSEDED`, `DISCONTINUED`, `ARCHIVED` 문서를 Authority로 사용하지 않는다.

## 6. 다음 단계 Gate

```text
Full Network·Storage Fault Host
→ Grand Persistence Summary·Restart Flow
→ UI·Accessibility Human Evidence Capture
→ Performance·Soak Host
→ Target Phase READY 판정
→ Full Grand Campaign 사용자 실행 1회
→ 전체 실패 Root Cause 수정
→ Full Grand Campaign 전체 재실행
→ Release Hardening
```
