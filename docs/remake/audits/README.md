# Audit 문서

- 상태: ACTIVE
- 문서 종류: Audit Index
- 현재 단계: `IMPLEMENTATION WORKSPACE·SCRIPT MANIFEST`
- 상위 작업 순서: [`CURRENT-WORK-ORDER`](../CURRENT-WORK-ORDER.md)
- Spec 인계 상태: [`CURRENT-SPEC-WORK-ORDER`](../specs/CURRENT-SPEC-WORK-ORDER.md)
- Production Work Order: [`implementation/roblox/CURRENT-WORK-ORDER`](../../../implementation/roblox/CURRENT-WORK-ORDER.md)
- 전체 Slice Roadmap: [`SLICE-ROADMAP`](../specs/SLICE-ROADMAP.md)

Audit은 제품 동작을 새로 정의하지 않는다. 권위 문서·사용자 흐름·Policy·명세·구현 Evidence의 정합성과 완료 Gate를 판정한다.

## 현재 핵심 감사

1. [`Implementation Workspace Bootstrap Audit`](implementation-workspace-bootstrap-audit.md)
   - `implementation/roblox/` Greenfield Production Root와 Roblox Service Folder 생성
   - Script-by-Script Work Order·Manifest Gate 확정
   - Production Luau Script `NOT STARTED`
2. [`UI·UX Global Policy Completion Audit`](ui-ux-policy-completion-audit.md)
   - Visual·Interaction·Information·Feedback·Recovery·Accessibility Policy 완료
   - UI·UX Review Checklist와 Production UI Gate 확정
3. [`All-slice Specification Checkpoint Completion Audit`](all-slice-specification-checkpoint-completion-audit.md)
   - 16개 Work Order·Integration Contract·Slice Audit과 4개 Cross-Slice Checkpoint 완료
   - 통합 명세 범위 `COMPLETE`
4. [`Slice Roadmap 완전성 감사`](implementation-slice-roadmap-completeness-audit.md)
   - 16개 Slice에 Quick Flow·12개 Main Guide·Content·Release 범위 배정
5. [`Shared Spec 001·002 재검토 감사`](shared-spec-001-002-revalidation-audit.md)
   - 둘 다 `UPDATE_REQUIRED`, Slice 02 구현 전 갱신 필요
6. [`구현 명세 전 최종 문서 연결 감사`](pre-implementation-document-linkage-audit.md)
   - Root→User Flow→Guide→Authority→Spec 연결 완료

## 현재 감사 흐름

```text
UI·UX Policy Completion Audit
→ Implementation Workspace Bootstrap Audit
→ Slice 01 Script Manifest
→ Script 단위 Test·Review
→ Slice 01 Roblox Integration
→ Slice 01 Production Build Acceptance Audit
```

## Slice 감사

- [`16개 Slice Checkpoint Audit Index`](slices/README.md)
- [`4개 Cross-Slice Checkpoint와 Recovery Branch`](slice-checkpoints/README.md)

```text
Slice Contract
→ Slice Specification Checkpoint Audit
→ 4-Slice Cross Checkpoint
→ All-slice Completion Audit
→ Script Manifest·Implementation
→ Production Build Acceptance Audit
```

## Cross-Slice Checkpoint

| Checkpoint | 범위 | 결과 | Recovery Branch |
|---|---|---|---|
| A | 01–04 | PASS | `checkpoint/specs-slices-01-04-2026-08-05` |
| B | 05–08 | PASS | `checkpoint/specs-slices-05-08-2026-08-05` |
| C | 09–12 | PASS | `checkpoint/specs-slices-09-12-2026-08-05` |
| D | 13–16 | PASS | `checkpoint/specs-slices-13-16-2026-08-05` |

## 현재 구현 감사 대상

Slice 01 Script Manifest에서 다음을 확인한다.

- Roblox Service별 실제 Script 경로
- Shared·Server·Client·UI 단일 책임
- Public API·Stable Error·Registry
- Unit·Integration·Roblox Test 연결
- Schema·Migration·Version 영향
- UI·UX Policy·Checklist 적용 대상
- Rojo·Type Check·Test Runner·Studio Sync Toolchain

Manifest와 실제 Script가 통합 계약과 충돌하면 관련 Authority·Guide·Slice Contract·Audit을 `UPDATE_REQUIRED`로 되돌린다.

## 선행 완료 감사

- [`User Guide Quick Flow와 Flowchart 보완 감사`](user-guide-quick-flow-and-flowchart-audit.md)
- [`Player·DM User Guide 완료 감사`](player-and-dm-user-guide-completion-audit.md)
- [`Main System Guide 일관성과 문서 허브 완료 감사`](main-system-guide-consistency-and-document-hub-completion-audit.md)
- [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](runtime-architecture-completion-and-main-guide-readiness-audit.md)
- [`Document Migration Validation`](document-migration-validation.md)

## 문서 수명주기

- [`문서 구조와 작성 가이드`](../DOCUMENT-GUIDE.md)
- [`문서 수명주기와 Discontinuation`](../DOCUMENT-LIFECYCLE-AND-DISCONTINUATION.md)
- [`보관된 Discontinued Audits`](../archive/discontinued/audits/README.md)

`SUPERSEDED`, `DISCONTINUED`, `ARCHIVED` 문서는 현재 Authority나 완료 근거로 다시 사용하지 않는다.
