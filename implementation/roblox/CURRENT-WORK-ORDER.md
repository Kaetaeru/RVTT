# RVTT Roblox Implementation 현재 작업 순서

- 상태: ACTIVE
- 문서 종류: Production Implementation Work Order
- 작성일: 2026-08-05
- 상위 Workspace: [`implementation`](../README.md)
- Roblox 구조: [`README`](README.md)
- 상위 Planning Work Order: [`docs/remake/CURRENT-WORK-ORDER`](../../docs/remake/CURRENT-WORK-ORDER.md)
- Slice Roadmap: [`docs/remake/specs/SLICE-ROADMAP`](../../docs/remake/specs/SLICE-ROADMAP.md)
- Slice 01 Contract: [`First Session Walking Skeleton`](../../docs/remake/specs/slices/01-first-session-walking-skeleton/implementation-contract.md)
- UI·UX Policy: [`UI·UX Global Policies`](../../docs/remake/ui/policies/README.md)

이 문서는 실제 Roblox Source, Test와 Migration 작업의 단일 실행 순서 기준이다.

## 1. 현재 상태

```text
UI·UX Global Policy
→ COMPLETE

Roblox Service Folder Structure
→ CREATED

Luau Script
→ 0

현재 작업
→ Slice 01 Script Manifest
```

## 2. 현재 작업 순서

| 순서 | 상태 | 작업 | 산출물 | 완료 조건 |
|---:|---|---|---|---|
| 1 | DONE | UI·UX Policy Foundation | `docs/remake/ui/policies/` | Completion Audit 통과 |
| 2 | DONE | Implementation Root 분리 | `implementation/` | 기획 문서와 Production Source 분리 |
| 3 | DONE | Roblox Service Folder Bootstrap | `src/<Service>/RVTT/` | Service 책임·금지 경계 기록 |
| 4 | IN_PROGRESS | Slice 01 Script Manifest | `manifests/slice-01-script-manifest.md` | Script 순서·경로·책임·Test·Spec 연결 |
| 5 | QUEUED | Toolchain Mapping | Manifest와 `tooling/` | Rojo·Type Check·Test Runner·Studio Sync 검증 |
| 6 | QUEUED | 첫 Shared Contract Script | Manifest 첫 항목 | 단일 책임·Unit Test·Review 통과 |
| 7 | QUEUED | Slice 01 Script-by-Script 구현 | `src/`와 `tests/` | Manifest 순서대로 모든 Script DONE |
| 8 | QUEUED | Slice 01 Roblox Integration | Studio Test | Join→Move→Reconnect Flow 통과 |
| 9 | QUEUED | Slice 01 Build Acceptance Audit | `docs/remake/audits/` | Code·Migration·Test·UX Checklist 통과 |
| 10 | BLOCKED | Slice 02 구현 | 후속 Manifest | Slice 01 Build Acceptance 필요 |

## 3. Script Manifest 규칙

Manifest 없이는 Script를 추가하지 않는다.

각 항목:

```text
Order
Path
Script Class
Single Responsibility
Public API
Dependencies
Authority Boundary
Spec Trace
Test Files
Migration Impact
UI·UX Policy Impact
Status
```

상태:

```text
QUEUED
IN_PROGRESS
BLOCKED
DONE
```

가장 위의 `IN_PROGRESS` Script 하나만 작성한다.

## 4. Script 완료 Gate

한 Script를 `DONE`으로 바꾸려면:

- 실제 Roblox Service 경로에 존재한다.
- 단일 책임이 Manifest와 일치한다.
- Public API·Type·Stable Error가 정의됐다.
- Client·Server·Shared 경계를 위반하지 않는다.
- Unit Test 또는 해당 책임의 Integration Test가 있다.
- 필요한 Migration·Version 영향이 기록됐다.
- Diagnostics Hook과 Failure Isolation이 있다.
- UI Script면 UI·UX Review Checklist를 통과한다.
- 문서·Test Workflow가 성공한다.

## 5. 첫 구현 원칙

Slice 01은 다음 순서를 사용한다.

```text
Shared ID·Version·Result·Stable Error
→ Protocol Envelope·Registry
→ Server Bootstrap·Command Gate
→ Client Bootstrap·Projection Replica
→ Session Membership·Character Selection·Ready
→ Scene Entry·Controlled Actor
→ Click Movement
→ Snapshot·Journal·Reconnect
→ Integration Scenario
```

정확한 Script 분할과 경로는 `slice-01-script-manifest.md`에서 확정한다.

## 6. 금지

- 전체 Architecture를 빈 Script 수십 개로 한 번에 생성
- Manifest보다 먼저 Script 작성
- `Manager.lua`, `Handler.lua`, `Util.lua`처럼 책임 없는 이름
- 한 Script 안의 Server·Client 분기
- Client에서 Authority 결과 계산·Commit
- UI Component의 Remote 직접 호출
- Test-only 권한·Store 우회
- Studio에서 검증하지 않고 완료 선언
- Slice 01 완료 전 Slice 02 Script 병렬 시작

## 7. 다음 행동

```text
manifests/slice-01-script-manifest.md 작성
→ Toolchain 결정 항목 분리
→ 첫 Script 선정
→ 사용자에게 Manifest와 첫 Script 범위 보고
→ Script 작성 시작
```
