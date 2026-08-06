# Slice 10 Work Order — Scene Authoring·Compile·Publish

- 상태: CHECKPOINT_COMPLETE
- 문서 종류: Slice Implementation Spec Work Order
- 즉시 구현 명세 가능성: BLOCKED
- 작성일: 2026-08-05
- 전체 Roadmap: [`SLICE-ROADMAP.md`](../../SLICE-ROADMAP.md)
- 선행 Slice: [`Scene Runtime Foundation`](../01-first-session-walking-skeleton/implementation-contract.md), [`Exploration`](../03-exploration-interaction-perception/implementation-contract.md), [`UI`](../08-player-ui-camera-presentation/implementation-contract.md)
- 통합 계약: [`implementation-contract.md`](implementation-contract.md)
- 검수 감사: [`Slice 10 Spec Checkpoint Audit`](../../../audits/slices/10-scene-authoring-compile-publish-spec-checkpoint-audit.md)

## 사용자 완료 결과

```text
Scene Source 생성·편집
→ Placement·Selection·Tool 사용
→ Semantic Compile·Diagnostic
→ Candidate Test Play
→ Review
→ Atomic Publish
→ Runtime Scene에서 사용
```

## 명세 작업 순서

| 순서 | 상태 | 작업 | 완료 기준 |
|---:|---|---|---|
| 1 | DONE | Scene Source·Stable Object ID | Source·Build·Runtime Object·Dynamic State 분리 |
| 2 | DONE | Authoring Command·History·Revision | Client Preview와 Server Source Mutation 분리 |
| 3 | DONE | Editor Core | Selection·Placement·Snap·ViewY·Ghost·Undo·Auto Save 정의 |
| 4 | DONE | Tool Registry·Capability | Module Lifecycle·Dependency·Object Schema·Migration 정의 |
| 5 | DONE | 기본 Tool·Inspector·Blueprint·Lighting | Wall·Floor·Prefab·Door·Stair·Region 작성 계약 정의 |
| 6 | DONE | Semantic Compiler·Provider | Navigation·Visibility·Interaction Layer와 결정적 Build 정의 |
| 7 | DONE | Diagnostic·Critical Route·Disclosure | Entry·Traversal·Secret·Dependency Publish Gate 정의 |
| 8 | DONE | Candidate·Test Play·Atomic Publish | Published Pointer와 Last Known Good 정의 |
| 9 | DONE | Draft·History·Reconnect·Test | Compile·Publish Race, Restart, Large Scene Budget 정의 |
| 10 | BLOCKED | Production Source Mapping | 실제 Editor·Tool·Scene Source·Compiler·Asset 구조 조사 필요 |

## 구현 시 추출할 세부 명세

```text
scene-authoring/source-schema-identity
scene-authoring/command-history-revision
scene-editor/core-selection-placement
scene-editor/tool-host-schema-migration
scene-editor/basic-tools-inspector-lighting
scene-compiler/semantic-provider-build
scene-compiler/diagnostic-test-play-publish
persistence/scene-source-history-recovery
```

## 차단 사항

- 기존 World Edit Tool·Asset Preset·DataStore 구조
- Scene Source·Workspace·Prefab Catalog Mapping
- Editor UI·Selection·Placement·Snap 구현
- Navigation·Visibility·Interaction Compiler Provider
- Published Scene·Live Runtime Legacy 데이터