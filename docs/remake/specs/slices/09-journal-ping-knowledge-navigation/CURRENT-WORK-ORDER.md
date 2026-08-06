# Slice 09 Work Order — Journal·Ping·Knowledge Navigation

- 상태: CHECKPOINT_COMPLETE
- 문서 종류: Slice Implementation Spec Work Order
- 즉시 구현 명세 가능성: BLOCKED
- 작성일: 2026-08-05
- 전체 Roadmap: [`SLICE-ROADMAP.md`](../../SLICE-ROADMAP.md)
- 선행 Slice: [`Exploration`](../03-exploration-interaction-perception/implementation-contract.md), [`UI`](../08-player-ui-camera-presentation/implementation-contract.md)
- 통합 계약: [`implementation-contract.md`](implementation-contract.md)
- 검수 감사: [`Slice 09 Spec Checkpoint Audit`](../../../audits/slices/09-journal-ping-knowledge-navigation-spec-checkpoint-audit.md)

## 사용자 완료 결과

```text
Markdown Journal 작성·열람
→ Folder·Document·Outline 탐색
→ Search·Backlink
→ Character·Scene·Object·Coordinate Link
→ 안전한 Camera·Selection·Scene Navigation
→ Point·Path Ping 공유
```

## 명세 작업 순서

| 순서 | 상태 | 작업 | 완료 기준 |
|---:|---|---|---|
| 1 | DONE | Document·Folder·Section Identity | Rename·Move와 Heading 변경 후 Link 유지 |
| 2 | DONE | Markdown Compiler·Build | AST·Outline·Link Graph·Last Known Good 정의 |
| 3 | DONE | ACL·Permission Projection | Discover·Read·Search·Navigate·Edit 분리 |
| 4 | DONE | Search·Backlink·Index | Permission-partitioned Index와 최신 ACL 재검증 정의 |
| 5 | DONE | World Anchor·Lifecycle | Character·Scene·Object·Runtime·Coordinate Resolver 정의 |
| 6 | DONE | Safe Navigation | CameraRequest·Selection·Scene Transition Proposal 경계 정의 |
| 7 | DONE | Edit Conflict·Import·Export·Draft | optimistic concurrency와 Redacted Export 정의 |
| 8 | DONE | Point·Path Ping | Audience·Rate Limit·Validation·Presentation 정의 |
| 9 | DONE | Persistence·Disclosure·Test | Republish·Rollback·Permission 축소·Signal Failure Scenario 정의 |
| 10 | BLOCKED | Production Source Mapping | 실제 Journal·Search·Markdown·UI·Ping 구조 조사 필요 |

## 구현 시 추출할 세부 명세

```text
journal/source-identity-revision
journal/markdown-compiler-link-graph
journal/permission-projection-search
journal/anchor-resolver-navigation
journal/edit-conflict-import-export
journal/ui-draft-recovery
ping/point-path-audience-presentation
testing/journal-disclosure-regression
```

## 차단 사항

- 기존 메모장·Markdown Parser·검색 Index
- Scene별 기본 Journal 저장 구조
- World Object Link·Camera·Selection API
- Journal UI·Draft·Import·Export 구현
- Ping Signal·VFX·Rate Limit 기존 코드