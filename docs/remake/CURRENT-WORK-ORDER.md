# RVTT Remake 현재 작업 순서

- 상태: ACTIVE
- 문서 종류: Planning·Implementation Work Order
- 최종 갱신일: 2026-08-05
- Architecture 완료 근거: [`Runtime Architecture Completion 감사`](audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)
- 전체 Slice Roadmap: [`specs/SLICE-ROADMAP.md`](specs/SLICE-ROADMAP.md)
- 전체 명세 완료 근거: [`All-slice Specification Checkpoint Completion Audit`](audits/all-slice-specification-checkpoint-completion-audit.md)
- UI·UX Policy: [`ui/policies/README.md`](ui/policies/README.md)
- Production Workspace: [`implementation/roblox`](../../implementation/roblox/README.md)
- 현재 Production Work Order: [`Roblox Implementation Work Order`](../../implementation/roblox/CURRENT-WORK-ORDER.md)
- Studio 검증 근거: [`Roblox Studio Runtime Baseline Validation Audit`](audits/roblox-studio-runtime-baseline-validation-audit.md)

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

16 Slice Script Manifest·Production Source
→ IMPLEMENTED

Static·Toolchain CI
→ PASSED

Roblox Studio Runtime Baseline
→ VERIFIED

현재 작업
→ Slice 01 Studio Acceptance
```

## 2. 상위 작업 순서

| 순서 | 상태 | 작업 | 완료 조건 |
|---:|---|---|---|
| 1 | DONE | Product·Architecture·ADR | Runtime·Domain·Integration 권위 계약 완료 |
| 2 | DONE | Main System Guides·User Guides | 12개 Guide와 Player·DM Flow 완료 |
| 3 | DONE | Implementation Slice Roadmap | 16개 Slice 정의·완전성 감사 |
| 4 | DONE | All-slice Specification Checkpoints | 16개 Package·Audit와 4개 Recovery Checkpoint |
| 5 | DONE | UI·UX Global Policy Foundation | 5개 Policy·Checklist·Completion Audit |
| 6 | DONE | Greenfield Implementation Workspace | Roblox Service Folder·책임·금지 경계 |
| 7 | DONE | All-slice Script Manifest·Source Baseline | Shared·Server·Client·UI·Test Source 존재 |
| 8 | DONE | Static·Toolchain Validation | Structure·Security·StyLua·Selene·Rojo·Luau 성공 |
| 9 | DONE | Studio Runtime Baseline | 108+10+56 Assertions, 실패 0, 3-client 성공 |
| 10 | IN_PROGRESS | Slice 01 Studio Acceptance | Join→Select→Ready→Scene→Move→Reconnect |
| 11 | QUEUED | Slice 01 Build Acceptance Audit | Evidence·UI·UX·복구 판정 |
| 12 | QUEUED | Slices 02–16 Studio Acceptance | Slice별 사용자·보안·복구 Scenario 통과 |
| 13 | BLOCKED | Release Hardening | 16개 Build·Rights·Migration·Fault·Soak Evidence 필요 |

## 3. 현재 검증된 Baseline

2026-08-05 Roblox Studio 실행 결과:

```text
[RVTT Tests] passed=108 failed=0
[RVTT Live DataStore] passed=10 failed=0
[RVTT MultiClient] passed=56 failed=0 clients=3 staleRetries=3
```

검증된 경계:

- Unit·Integration Runtime
- 실제 DataStore 기본 저장·로드·충돌 거부·정리
- DM·Player·Observer 3-client Authority·Projection
- Concurrent Join과 Stale Revision Recovery
- Unauthorized Command 차단
- Viewer별 Private Projection
- Disconnect·Reconnect·Full Resync

## 4. 현재 작업

```text
Slice 01 First Session Walking Skeleton
→ Studio End-to-End Acceptance
```

필수 흐름:

```text
Join
→ Character Select
→ Ready
→ Scene Projection
→ Token Select
→ Server-authoritative Move
→ Disconnect
→ Reconnect
→ State Recovery
```

확인 항목:

- 사용자 화면과 Feedback
- Server Authority와 Client Projection 일치
- 오류·Stale·권한 없음·재시도 처리
- 중복 Membership·Command 없음
- Revision·AuthorityEpoch·Projection Sequence 안정성
- UI·UX Review Checklist 적용

## 5. 운영 규칙

1. 가장 위의 `IN_PROGRESS` 작업을 먼저 처리한다.
2. 기획·명세와 Production Source를 분리한다.
3. 현재 Baseline 이후 Source 또는 Test 변경 시 Studio Runner를 재실행한다.
4. 한 Slice의 Build Acceptance 전 다음 Slice Acceptance를 완료로 표시하지 않는다.
5. 저장 Schema 변경에는 Migration·Version·Last Known Good가 필요하다.
6. Test·Studio Evidence 없이 완료를 주장하지 않는다.
7. 성능 측정 없이 최적화됐다고 주장하지 않는다.
8. `SUPERSEDED`, `DISCONTINUED`, `ARCHIVED` 문서를 Authority로 사용하지 않는다.

## 6. 다음 단계 Gate

```text
Slice 01 Studio Acceptance
→ 실패 수정·재실행
→ Evidence 기록
→ Slice 01 Production Build Acceptance Audit
→ Slice 02 Studio Acceptance
```
