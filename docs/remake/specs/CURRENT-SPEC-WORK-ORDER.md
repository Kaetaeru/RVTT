# RVTT Implementation Specs 현재 작업 순서

- 상태: COMPLETE_WITH_IMPLEMENTATION_HANDOFF
- 문서 종류: Implementation Spec Work Order
- 최종 갱신일: 2026-08-05
- 상위 작업 순서: [`../CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)
- 전체 Slice Roadmap: [`SLICE-ROADMAP.md`](SLICE-ROADMAP.md)
- Slice Package Index: [`slices/README.md`](slices/README.md)
- 전체 명세 완료 감사: [`All-slice Specification Checkpoint Completion Audit`](../audits/all-slice-specification-checkpoint-completion-audit.md)
- UI·UX Policy: [`UI·UX Global Policies`](../ui/policies/README.md)
- Production Workspace: [`implementation/roblox`](../../../implementation/roblox/README.md)
- 현재 Production Work Order: [`Roblox Implementation Work Order`](../../../implementation/roblox/CURRENT-WORK-ORDER.md)

이 문서는 16개 Slice의 통합 명세 완료와 Production Workspace 인계를 기록한다. 실제 Script 작성 순서는 `implementation/roblox/CURRENT-WORK-ORDER.md`가 소유한다.

## 1. 현재 상태

```text
16개 Slice 정의
→ DONE

16개 Work Order·Integration Contract·Checkpoint Audit
→ DONE

4개 Cross-Slice Checkpoint·Recovery Branch
→ DONE

UI·UX Global Policy·Checklist
→ DONE

Greenfield Production Root 결정
→ DONE

Roblox Service Folder Bootstrap
→ DONE

현재 구현 작업
→ Slice 01 Script Manifest
```

## 2. Greenfield 구현 결정

사용자 결정에 따라 기존 Production Source Tree를 계속 탐색해 연결하는 방식 대신 다음 Root에서 새 구현을 시작한다.

```text
implementation/roblox/
```

구조:

```text
src/<Roblox Service>/RVTT/
tests/
tooling/
manifests/
```

의미:

- 기존 문서·명세는 `docs/remake/`에 유지한다.
- 실제 Production Source와 Test는 `implementation/`에만 둔다.
- Script는 Slice Manifest 순서대로 하나씩 추가한다.
- 전체 Framework의 빈 Script를 한 번에 생성하지 않는다.
- Toolchain·Package·최종 Script 경로는 Manifest에서 실제 필요를 검증하며 확정한다.

## 3. 완료된 작업

| 순서 | 상태 | 작업 |
|---:|---|---|
| 1 | DONE | 전체 Slice Roadmap·완전성 감사 |
| 2 | DONE | Slices 01–04 명세·Checkpoint A |
| 3 | DONE | Slices 05–08 명세·Checkpoint B |
| 4 | DONE | Slices 09–12 명세·Checkpoint C |
| 5 | DONE | Slices 13–16 명세·Checkpoint D |
| 6 | DONE | All-slice Specification Completion Audit |
| 7 | DONE | UI·UX Global Policy와 Completion Audit |
| 8 | DONE | Greenfield `implementation/roblox/` Workspace Bootstrap |
| 9 | HANDOFF | Slice 01 Script Manifest와 Production 구현 |

## 4. Slice 01 인계 대상

- [`Slice 01 Work Order`](slices/01-first-session-walking-skeleton/CURRENT-WORK-ORDER.md)
- [`Slice 01 Integration Contract`](slices/01-first-session-walking-skeleton/implementation-contract.md)
- [`Core Authority 세부 초안`](runtime/001-core-authority-identity-version-and-result.md)
- [`Slice 01 Checkpoint Audit`](../audits/slices/01-first-session-walking-skeleton-spec-checkpoint-audit.md)
- [`UI·UX Review Checklist`](../ui/policies/UI-UX-REVIEW-CHECKLIST.md)
- [`Roblox Implementation Work Order`](../../../implementation/roblox/CURRENT-WORK-ORDER.md)

## 5. 다음 구현 순서

```text
Slice 01 Script Manifest
→ Toolchain·Service Mapping
→ Shared ID·Version·Result·Stable Error Script
→ Protocol·Server·Client·Session·Scene·Movement Script
→ Persistence·Reconnect
→ Roblox Integration Scenario
→ Slice 01 Build Acceptance Audit
```

Script별 정확한 경로와 API는 Manifest에서 확정한다. Integration Contract의 의미를 구현 편의로 변경하지 않는다.

## 6. 남은 Blocker

명세 의미는 완료됐지만 Production Script 착수 전에 다음을 Manifest에서 해결한다.

- Rojo 사용 여부와 Project Mapping
- Formatter·Linter·Luau Type Check
- Test Runner와 Studio Integration 방식
- Package·Registry 실제 Script 분할
- 저장 Schema·Migration Version Index
- UI Design Token의 실제 Roblox 표현
- 측정형 Timeout·Queue·Payload·Render Budget

Slices 13–15는 실제 공식 Data·Source Version·Rights Review가 추가로 필요하다.

## 7. 인계 판정

```text
통합 명세
→ COMPLETE

UI·UX Policy Foundation
→ COMPLETE

Production Workspace
→ BOOTSTRAPPED

현재 실행 기준
→ implementation/roblox/CURRENT-WORK-ORDER.md

Production Luau Script
→ NOT STARTED
```
